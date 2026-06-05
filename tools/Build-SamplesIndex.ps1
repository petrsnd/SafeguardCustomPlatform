#requires -Version 5.1
<#
.SYNOPSIS
    Generates docs/agent-reference/samples-index.md from the contents of
    samples/ and templates/.

.DESCRIPTION
    Walks samples/ssh, samples/http, and templates/ (samples/telnet is
    excluded from the agent-facing index — telnet is out of scope for
    the agent skill system). For every JSON
    file found, emits one row in the index with the columns:

        protocol | auth-scheme | operations | OS-family | file-path | README

    Grounding rules:
      - protocol is derived from the directory path (ssh|http) for samples,
        and from filename prefix (Pattern-GenericLinux* / TemplateSsh* are
        ssh; Pattern-GenericHttp* / Pattern-GenericRestApi* / TemplateHttp*
        are http) for templates. Files that don't classify cleanly are
        emitted with protocol = "" rather than guessed.
      - operations is the intersection of top-level keys with the canonical
        operation list from schema/custom-platform-script.schema.json.
        Imports and user-defined functions never appear here.
      - auth-scheme is best-effort from the JSON content:
          HTTP: HttpAuth.Type (Basic/Digest), or "Bearer" if an
                "Authorization": "Bearer ..." header is set, or "ApiKey"
                if a non-Authorization header carries the secret, or
                "Form" if ExtractFormData appears, else blank.
          SSH:  "Interactive" if Send/Receive appear, "Batch" if
                ExecuteCommand appears without Send/Receive, "Mixed" if
                both, else blank.
      - OS-family is left blank by the build script. Phase 1 prefers
        "blank" over "guess"; OS family is hard to ground from JSON alone
        and the sample README's heading text isn't structured. Future
        phases may revisit.
      - file-path and README are filesystem facts.

    The script writes the file deterministically (sorted rows, LF line
    endings) so the CI freshness check can do a byte-for-byte compare.

.PARAMETER RepoRoot
    Path to the repository root. Defaults to the parent of this script.

.PARAMETER OutputPath
    Path to write the index. Defaults to
    docs/agent-reference/samples-index.md under -RepoRoot.

.PARAMETER CheckOnly
    If set, write to a temp file and compare against the committed copy.
    Exits 0 if identical, 1 if they differ. Used by CI.

.EXAMPLE
    ./tools/Build-SamplesIndex.ps1
    Regenerates the index in place.

.EXAMPLE
    ./tools/Build-SamplesIndex.ps1 -CheckOnly
    Used by CI to fail the build if the committed index is stale.
#>
[CmdletBinding()]
param(
    [string] $RepoRoot,
    [string] $OutputPath,
    [switch] $CheckOnly
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
    if (-not $RepoRoot) {
        $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    }
}
$RepoRoot = (Resolve-Path $RepoRoot).Path

if (-not $OutputPath) {
    $OutputPath = Join-Path $RepoRoot 'docs/agent-reference/samples-index.md'
}

$schemaPath = Join-Path $RepoRoot 'schema/custom-platform-script.schema.json'
if (-not (Test-Path $schemaPath)) {
    throw "Schema not found at $schemaPath. Cannot ground the operation list."
}

# Canonical operation list -- intersect-only against this set so user-defined
# functions and imported helpers never leak into the operations column.
$schema = Get-Content $schemaPath -Raw | ConvertFrom-Json
$nonOperationProps = @('$schema', 'Id', 'BackEnd', 'Meta', 'Imports', 'Import', 'Functions')
$canonicalOperations = @($schema.properties.PSObject.Properties.Name |
    Where-Object { $_ -notin $nonOperationProps })

function Get-Protocol {
    param([string] $RelativePath)

    $parts = $RelativePath -split '[\\/]'

    if ($parts[0] -eq 'samples') {
        switch ($parts[1]) {
            'ssh'    { return 'ssh' }
            'http'   { return 'http' }
            'telnet' { return 'telnet' } # filtered out before emission
            default  { return '' }
        }
    }

    if ($parts[0] -eq 'templates') {
        $name = [System.IO.Path]::GetFileName($RelativePath)
        if ($name -match '^(Pattern-GenericLinux|Pattern-WindowsSsh|TemplateSsh)') {
            return 'ssh'
        }
        if ($name -match '^(Pattern-GenericHttp|Pattern-GenericRestApi|TemplateHttp)') {
            return 'http'
        }
        return ''
    }

    return ''
}

function Get-OperationsList {
    param($Json)

    if ($null -eq $Json) { return @() }
    $names = $Json.PSObject.Properties.Name
    $ops = @($names | Where-Object { $canonicalOperations -contains $_ })
    return ,$ops
}

function Get-AuthScheme {
    param(
        [string] $Protocol,
        [string] $RawJson
    )

    if ($Protocol -eq 'http') {
        $schemes = @()

        $basicMatch = [regex]::Match($RawJson, '"HttpAuth"\s*:\s*\{[^}]*"Type"\s*:\s*"([^"]+)"')
        if ($basicMatch.Success) {
            $schemes += $basicMatch.Groups[1].Value
        }

        if ($RawJson -match '"Authorization"\s*:\s*"Bearer\b') {
            $schemes += 'Bearer'
        }

        # Custom header carrying a secret (e.g., x-api-key, X-Auth-Token).
        # We only flag this when no Authorization header was already classified,
        # to avoid double-labeling Bearer flows that also set other headers.
        if ($schemes.Count -eq 0 -and
            $RawJson -match '"AddHeaders"\s*:\s*\{[^}]*(?i)(api[-_ ]?key|x-auth-token|api-token)') {
            $schemes += 'ApiKey'
        }

        if ($RawJson -match '\bExtractFormData\b') {
            $schemes += 'Form'
        }

        $schemes = @($schemes | Select-Object -Unique)
        return ($schemes -join '+')
    }

    if ($Protocol -eq 'ssh') {
        $hasInteractive = ($RawJson -match '"Send"\s*:') -and ($RawJson -match '"Receive"\s*:')
        $hasBatch = $RawJson -match '"ExecuteCommand"\s*:'

        if ($hasInteractive -and $hasBatch) { return 'Mixed' }
        if ($hasInteractive) { return 'Interactive' }
        if ($hasBatch) { return 'Batch' }
        return ''
    }

    return ''
}

function Find-ReadmePath {
    param(
        [string] $JsonAbsolutePath,
        [string] $RepoRootPath
    )

    $dir = Split-Path -Parent $JsonAbsolutePath
    $candidate = Join-Path $dir 'README.md'
    if (Test-Path $candidate) {
        $rel = (Resolve-Path $candidate).Path.Substring($RepoRootPath.Length).TrimStart('\','/')
        return ($rel -replace '\\', '/')
    }
    return ''
}

function ConvertTo-RelativePath {
    param(
        [string] $AbsolutePath,
        [string] $RepoRootPath
    )
    $rel = $AbsolutePath.Substring($RepoRootPath.Length).TrimStart('\','/')
    return ($rel -replace '\\', '/')
}

# Collect every JSON under samples/ and templates/.
$samplesRoot = Join-Path $RepoRoot 'samples'
$templatesRoot = Join-Path $RepoRoot 'templates'

$jsonFiles = @()
if (Test-Path $samplesRoot)   { $jsonFiles += Get-ChildItem -Path $samplesRoot   -Filter '*.json' -Recurse -File }
if (Test-Path $templatesRoot) { $jsonFiles += Get-ChildItem -Path $templatesRoot -Filter '*.json' -Recurse -File }

$rows = @()
foreach ($file in $jsonFiles) {
    $rel = ConvertTo-RelativePath -AbsolutePath $file.FullName -RepoRootPath $RepoRoot
    $protocol = Get-Protocol -RelativePath $rel

    # Telnet samples are out of scope for the agent-facing index.
    if ($protocol -eq 'telnet') { continue }

    $raw = Get-Content $file.FullName -Raw
    try {
        $json = $raw | ConvertFrom-Json
    } catch {
        Write-Warning "Skipping $rel — invalid JSON: $_"
        continue
    }

    $ops = Get-OperationsList -Json $json
    $opsCell = if ($ops.Count -gt 0) { ($ops -join ', ') } else { '' }

    $auth = Get-AuthScheme -Protocol $protocol -RawJson $raw
    $readme = Find-ReadmePath -JsonAbsolutePath $file.FullName -RepoRootPath $RepoRoot

    $rows += [pscustomobject]@{
        Kind       = if ($rel.StartsWith('samples/')) { 'samples' } else { 'templates' }
        Protocol   = $protocol
        AuthScheme = $auth
        Operations = $opsCell
        OsFamily   = ''  # intentionally blank — see header note
        FilePath   = $rel
        Readme     = $readme
    }
}

$rows = $rows | Sort-Object Kind, Protocol, FilePath

function Format-Cell {
    param([string] $Value)
    if ([string]::IsNullOrEmpty($Value)) { return '—' }
    return $Value
}

function Format-Row {
    param([pscustomobject] $Row)
    # Use repo-relative links from docs/agent-reference/ so they resolve on
    # GitHub and on disk. From docs/agent-reference/, "../../" reaches repo root.
    $fileLink = if ($Row.FilePath) { "[``$($Row.FilePath)``](../../$($Row.FilePath))" } else { '—' }
    $readmeLink = if ($Row.Readme) { "[README](../../$($Row.Readme))" } else { '—' }

    return "| {0} | {1} | {2} | {3} | {4} | {5} |" -f `
        (Format-Cell $Row.Protocol),
        (Format-Cell $Row.AuthScheme),
        (Format-Cell $Row.Operations),
        (Format-Cell $Row.OsFamily),
        $fileLink,
        $readmeLink
}

$sampleRows   = $rows | Where-Object { $_.Kind -eq 'samples' }
$templateRows = $rows | Where-Object { $_.Kind -eq 'templates' }

$header = @'
[← Agent reference](README.md)

# Samples and templates index

**Generated file. Do not edit by hand.** Regenerate with:

```powershell
./tools/Build-SamplesIndex.ps1
```

CI runs the same script with `-CheckOnly` and fails the build if the committed copy differs.

## Conventions

- **protocol** — derived from the directory (`samples/ssh/`, `samples/http/`) or the template filename (`Pattern-GenericLinux*` / `Pattern-WindowsSsh*` / `TemplateSsh*` → ssh; `Pattern-GenericHttp*` / `Pattern-GenericRestApi*` / `TemplateHttp*` → http).
- **auth-scheme** — best-effort from JSON content. HTTP: from `HttpAuth.Type`, an `Authorization: Bearer` header, an API-key-shaped custom header, or `ExtractFormData`. SSH: `Interactive` (Send/Receive), `Batch` (ExecuteCommand), or `Mixed`. Blank when undetermined.
- **operations** — intersection of top-level keys with the canonical operation list from `schema/custom-platform-script.schema.json`. Imports and user-defined functions never appear here.
- **OS-family** — intentionally blank. Phase 1 prefers blank over guessed values; revisit in a later phase if needed.
- **file-path** and **README** — filesystem facts. `—` means the field could not be determined.
- `samples/telnet/` is excluded — telnet is out of scope for the agent skill system. The samples remain in the repo for human reference.

## Samples

| protocol | auth-scheme | operations | OS-family | file-path | README |
| --- | --- | --- | --- | --- | --- |
'@

$middle = @'

## Templates

| protocol | auth-scheme | operations | OS-family | file-path | README |
| --- | --- | --- | --- | --- | --- |
'@

$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine($header.TrimEnd())
foreach ($r in $sampleRows) {
    $null = $sb.AppendLine((Format-Row -Row $r))
}
$null = $sb.AppendLine($middle.TrimEnd())
foreach ($r in $templateRows) {
    $null = $sb.AppendLine((Format-Row -Row $r))
}

$content = $sb.ToString()

# Normalize to LF line endings for deterministic CI compare.
$content = $content -replace "`r`n", "`n"

if ($CheckOnly) {
    if (-not (Test-Path $OutputPath)) {
        Write-Host "samples-index.md does not exist; regenerate with ./tools/Build-SamplesIndex.ps1" -ForegroundColor Red
        exit 1
    }
    $existing = (Get-Content $OutputPath -Raw) -replace "`r`n", "`n"
    if ($existing -ne $content) {
        Write-Host "samples-index.md is stale; regenerate with ./tools/Build-SamplesIndex.ps1" -ForegroundColor Red
        # Surface a small diff hint by comparing line counts.
        $existingLines = ($existing -split "`n").Count
        $newLines = ($content -split "`n").Count
        Write-Host "  committed: $existingLines lines; regenerated: $newLines lines"
        exit 1
    }
    Write-Host "samples-index.md is up to date."
    exit 0
}

# Write atomically with LF endings.
$outDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
[System.IO.File]::WriteAllText($OutputPath, $content)
Write-Host "Wrote $OutputPath"
