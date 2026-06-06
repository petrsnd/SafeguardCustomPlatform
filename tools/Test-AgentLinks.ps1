#requires -Version 5.1
<#
.SYNOPSIS
    Validates that every relative markdown link in AGENTS.md, every
    .agents/skills/<skill>/SKILL.md, and every docs/agent-reference/*.md
    file resolves to a real file on disk.

.DESCRIPTION
    The agent skill system depends on agents being able to follow
    citations from AGENTS.md and SKILL.md files. A broken citation makes
    the affected skill silently unreliable. CI runs this script on every
    pull request and fails the build on any unresolved relative link.

    Rules:
      - Absolute URLs (http://, https://, mailto:) are skipped.
      - Anchors (#fragment) and query strings (?...) are stripped before
        resolving.
      - Paths are resolved relative to the markdown file that contains
        the link.
      - In-page anchors (links starting with '#') are skipped — anchor
        validity is not currently in scope.

    The script exits 0 on success, 1 on any broken link.

.PARAMETER RepoRoot
    Path to the repository root. Defaults to the parent of this script.
#>
[CmdletBinding()]
param(
    [string] $RepoRoot
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
    if (-not $RepoRoot) {
        $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    }
}
$RepoRoot = (Resolve-Path $RepoRoot).Path

# Gather the files this check covers.
$targets = @()
$agentsMd = Join-Path $RepoRoot 'AGENTS.md'
if (Test-Path $agentsMd) { $targets += Get-Item $agentsMd }

$skillsRoot = Join-Path $RepoRoot '.agents/skills'
if (Test-Path $skillsRoot) {
    $targets += Get-ChildItem -Path $skillsRoot -Filter 'SKILL.md' -Recurse -File
}

$refRoot = Join-Path $RepoRoot 'docs/agent-reference'
if (Test-Path $refRoot) {
    $targets += Get-ChildItem -Path $refRoot -Filter '*.md' -Recurse -File
}

if ($targets.Count -eq 0) {
    Write-Host 'No agent-facing markdown files found; nothing to check.'
    exit 0
}

# Markdown inline links: [text](target). Image links [! ...] start with !,
# but the link target shape is identical so this regex matches both.
$linkPattern = '\[(?<text>[^\]]*)\]\((?<target>[^)\s]+)(?:\s+"[^"]*")?\)'
$broken = @()

foreach ($file in $targets) {
    $content = Get-Content $file.FullName -Raw
    $fileDir = Split-Path -Parent $file.FullName
    $relFile = $file.FullName.Substring($RepoRoot.Length).TrimStart('\','/') -replace '\\','/'

    $matches = [regex]::Matches($content, $linkPattern)
    foreach ($m in $matches) {
        $target = $m.Groups['target'].Value.Trim()

        # Skip absolute URLs and mailto.
        if ($target -match '^(https?:|mailto:|ftp:|tel:)') { continue }

        # Skip in-page anchors.
        if ($target.StartsWith('#')) { continue }

        # Strip anchor and query for filesystem resolution.
        $path = $target -replace '#.*$', '' -replace '\?.*$', ''
        if (-not $path) { continue }

        # Resolve relative to the file that contains the link.
        $candidate = Join-Path $fileDir $path
        try {
            $resolved = (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).Path
            if (-not (Test-Path -LiteralPath $resolved)) {
                $broken += [pscustomobject]@{ File = $relFile; Link = $target }
            }
        } catch {
            $broken += [pscustomobject]@{ File = $relFile; Link = $target }
        }
    }
}

if ($broken.Count -gt 0) {
    Write-Host "Broken links found:" -ForegroundColor Red
    foreach ($b in $broken) {
        Write-Host ("  {0} -> {1}" -f $b.File, $b.Link) -ForegroundColor Red
    }
    exit 1
}

Write-Host ("Checked {0} agent-facing files; all relative links resolve." -f $targets.Count)
exit 0
