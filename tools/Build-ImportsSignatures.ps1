[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $HerculesImportsPath,

    [string] $OutputPath = (Join-Path $PSScriptRoot '..\docs\agent-reference\imports-signatures.md'),

    [string[]] $Libraries = @(
        'LinuxSshLogin','LinuxSshFunctions','DiscoverSshHostKey','TestLoginSsh','ChangeSshKeyCommon',
        'UnixShellAuthorizedKeys','UnixShellAuthorizedKeysOpenSsh','UnixShellChangeSshKey','UnixShellChangeSshKeyOpenSsh',
        'UnixShellDiscoverAccounts','UnixShellSshFunctions','ResolveAssetName','ReturnOperationResultSsh',
        'WindowsSshFunctions','WindowsSshFunctionsDiscovery','WindowsSshFunctionsSshKey','UnixUpdateCustomDependency'
    )
)

$ErrorActionPreference = 'Stop'

# ------- helpers --------------------------------------------------------------

# Tokens that are NEVER caller-scope variables: C# keywords, common BCL types
# and methods that appear inside %{ ... }% expressions or "If" predicates.
$script:ExpressionNoise = @(
    'true','false','null',
    'string','int','long','double','bool','var','new','typeof','as','is','this',
    'if','else','return','public','private','protected','internal',
    'String','Int32','Int64','Double','Boolean','Math','Regex','Convert','DateTime','TimeSpan','Guid',
    'IsNullOrEmpty','IsNullOrWhiteSpace','PadLeft','PadRight','Trim','TrimStart','TrimEnd',
    'Length','Equals','StartsWith','EndsWith','Contains','IndexOf','LastIndexOf',
    'IsMatch','Match','Matches','Replace','Split','Substring','ToLower','ToUpper','ToString','ToInt32','ToInt64',
    'Parse','TryParse','Format','Join','Count','Any','All','First','FirstOrDefault','Where','Select','Cast','OfType','ToArray','ToList',
    'Now','UtcNow','TotalSeconds','TotalMilliseconds','AddSeconds','AddMinutes','Ticks',
    'Min','Max','Abs','Floor','Ceiling','Round','Pow','Sqrt',
    # Regex / RegexOptions API surface
    'Capture','Captures','Group','Groups','Index','Value','Success','NextMatch',
    'Multiline','Singleline','IgnoreCase','ExplicitCapture','Compiled','RegexOptions','Options',
    # Result-object members the engine attaches to ExecuteCommand etc.
    'CmdResponse','CmdTimedOut','ExitCode','Output','StdOut','StdErr',
    # LINQ-ish / lambda noise
    'Where','Select','Aggregate','Sum','Distinct'
) | ForEach-Object { $_.ToLowerInvariant() } | Sort-Object -Unique

function Get-ParameterRecord {
    param($paramObj)
    # Each entry shape: { "ParamName": { "Type": "...", "Required": ..., ... } }
    $key = ($paramObj.PSObject.Properties | Select-Object -First 1).Name
    $info = $paramObj.$key
    [pscustomobject]@{
        Name        = $key
        Type        = $info.Type
        Required    = if ($null -ne $info.Required) { [bool]$info.Required } else { $true }
        Default     = $info.DefaultValue
        Description = $info.Description
    }
}

function Get-IdentifiersFromExpression {
    param([string] $Text)
    if (-not $Text) { return @() }
    $stripped = $Text
    # Strip JSON-escaped string literals first (these survive ConvertTo-Json)
    $stripped = [regex]::Replace($stripped, '@\\"[^"\\\\]*(?:\\\\.[^"\\\\]*)*\\"', ' ')
    $stripped = [regex]::Replace($stripped, '\\"[^"\\\\]*(?:\\\\.[^"\\\\]*)*\\"', ' ')
    # Strip raw C# string literals
    $stripped = [regex]::Replace($stripped, '@"[^"]*"', ' ')
    $stripped = [regex]::Replace($stripped, '"[^"\\]*(?:\\.[^"\\]*)*"', ' ')
    # Strip member access: anything immediately preceded by a dot is a member,
    # not a script variable.
    $stripped = [regex]::Replace($stripped, '\.[A-Za-z_][A-Za-z0-9_]*', ' ')
    # Strip `new TypeName` constructor names — TypeName is a class, not a script var.
    $stripped = [regex]::Replace($stripped, '\bnew\s+[A-Za-z_][A-Za-z0-9_]*', ' ')
    # Strip generic type arguments e.g. `Cast<Match>` -> drop "Match"
    $stripped = [regex]::Replace($stripped, '<[^>]+>', ' ')

    # Detect lambda parameter names — these are local to the expression and
    # not script variables. We collect them up front so we can also exclude
    # references to them from inside the lambda body.
    $lambdaParams = New-Object System.Collections.Generic.HashSet[string]
    foreach ($m in [regex]::Matches($stripped, '\(([A-Za-z_][A-Za-z0-9_]*(?:\s*,\s*[A-Za-z_][A-Za-z0-9_]*)*)\)\s*=>')) {
        foreach ($p in ($m.Groups[1].Value -split '\s*,\s*')) {
            if ($p) { $null = $lambdaParams.Add($p) }
        }
    }
    foreach ($m in [regex]::Matches($stripped, '\b([A-Za-z_][A-Za-z0-9_]*)\s*=>')) {
        $null = $lambdaParams.Add($m.Groups[1].Value)
    }

    # Now extract bare identifiers
    $idRegex = [regex]'\b([A-Za-z_][A-Za-z0-9_]*)\b'
    $tokens = @()
    foreach ($m in $idRegex.Matches($stripped)) {
        $tok = $m.Groups[1].Value
        if ($tok.ToLowerInvariant() -in $script:ExpressionNoise) { continue }
        if ($lambdaParams.Contains($tok)) { continue }
        # Skip single-letter lowercase identifiers — almost always lambda iter
        # vars (`m =>`, `x =>`).
        if ($tok.Length -eq 1 -and $tok -cmatch '^[a-z]$') { continue }
        $tokens += $tok
    }
    return $tokens
}

function Get-FunctionMetadata {
    param($fn, $libraryName)

    # Serialize body once for regex scanning
    $bodyJson = $fn | ConvertTo-Json -Depth 64 -Compress

    $params = @()
    if ($fn.Parameters) {
        foreach ($p in $fn.Parameters) { $params += Get-ParameterRecord $p }
    }

    # %VarName% and %VarName::$% references (ignore the ::$ modifier)
    $varRefs = New-Object System.Collections.Generic.HashSet[string]
    foreach ($m in [regex]::Matches($bodyJson, '%([A-Za-z_][A-Za-z0-9_]*)(?:::\$)?%')) {
        $null = $varRefs.Add($m.Groups[1].Value)
    }

    # %{ ... }% inline expressions — extract identifiers
    foreach ($m in [regex]::Matches($bodyJson, '%\{([^}]+)\}%')) {
        foreach ($id in Get-IdentifiersFromExpression $m.Groups[1].Value) {
            $null = $varRefs.Add($id)
        }
    }

    # "If": "..." predicates — whole string is an expression
    foreach ($m in [regex]::Matches($bodyJson, '"If"\s*:\s*"((?:[^"\\]|\\.)*)"')) {
        $expr = $m.Groups[1].Value -replace '\\"','"'
        foreach ($id in Get-IdentifiersFromExpression $expr) {
            $null = $varRefs.Add($id)
        }
    }

    # Function calls inside this body
    $calls = New-Object System.Collections.Generic.HashSet[string]
    foreach ($m in [regex]::Matches($bodyJson, '"Function"\s*:\s*\{\s*"Name"\s*:\s*"([^"]+)"')) {
        $null = $calls.Add($m.Groups[1].Value)
    }

    # Locally-set variables (so we don't list them as caller-scope reads when the
    # function reads its own writes)
    $localSets = New-Object System.Collections.Generic.HashSet[string]
    foreach ($m in [regex]::Matches($bodyJson, '"SetItem"\s*:\s*\{\s*"Name"\s*:\s*"([^"]+)"')) {
        $null = $localSets.Add($m.Groups[1].Value)
    }
    foreach ($m in [regex]::Matches($bodyJson, '"BufferName"\s*:\s*"([^"]+)"')) {
        $null = $localSets.Add($m.Groups[1].Value)
    }
    foreach ($m in [regex]::Matches($bodyJson, '"ResultVariable"\s*:\s*"([^"]+)"')) {
        $null = $localSets.Add($m.Groups[1].Value)
    }
    foreach ($m in [regex]::Matches($bodyJson, '"ConnectionObjectName"\s*:\s*"([^"]+)"')) {
        $null = $localSets.Add($m.Groups[1].Value)
    }

    # Returns — capture literal Return.Value tokens (best-effort summary)
    $returns = New-Object System.Collections.Generic.HashSet[string]
    foreach ($m in [regex]::Matches($bodyJson, '"Return"\s*:\s*\{\s*"Value"\s*:\s*"((?:[^"\\]|\\.)*)"')) {
        $null = $returns.Add($m.Groups[1].Value)
    }
    foreach ($m in [regex]::Matches($bodyJson, '"Return"\s*:\s*\{\s*"Value"\s*:\s*(true|false|null|\d+)')) {
        $null = $returns.Add($m.Groups[1].Value)
    }

    $declared = @($params | ForEach-Object { $_.Name })
    $callerScope = @($varRefs) |
        Where-Object { $_ -notin $declared -and -not $localSets.Contains($_) } |
        Sort-Object

    [pscustomobject]@{
        Library              = $libraryName
        Name                 = $fn.Name
        Parameters           = $params
        ReadsFromCallerScope = $callerScope
        Calls                = @($calls) | Sort-Object
        SetsLocally          = @($localSets) | Sort-Object
        Returns              = @($returns) | Sort-Object
    }
}

function Format-ParametersInline {
    param($Params)
    if (-not $Params -or $Params.Count -eq 0) { return '_(none)_' }
    ($Params | ForEach-Object {
        $req = if ($_.Required) { '' } else { '?' }
        $def = if ($null -ne $_.Default) { " = $($_.Default)" } else { '' }
        "{0}{1}: {2}{3}" -f $_.Name, $req, $_.Type, $def
    }) -join ', '
}

function Format-ListInline {
    param($Items)
    if (-not $Items -or $Items.Count -eq 0) { return '_(none)_' }
    '`' + ($Items -join '`, `') + '`'
}

# ------- main -----------------------------------------------------------------

$missing = @()
$libraryData = @()
foreach ($lib in $Libraries) {
    $path = Join-Path $HerculesImportsPath "$lib.json"
    if (-not (Test-Path -LiteralPath $path)) { $missing += $lib; continue }
    $j = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $functions = @()
    foreach ($fn in $j.Functions) { $functions += Get-FunctionMetadata $fn $lib }
    $libraryData += [pscustomobject]@{ Name = $lib; Functions = $functions }
}
if ($missing.Count -gt 0) {
    throw "Missing import library files: $($missing -join ', ')"
}

# ------- emit markdown --------------------------------------------------------

$out = New-Object System.Collections.Generic.List[string]
$out.Add('[← Agent Reference](README.md)')
$out.Add('')
$out.Add('# System Import Library Function Signatures')
$out.Add('')
$out.Add('> **Generated** — do not hand-edit. Regenerate with `tools/Build-ImportsSignatures.ps1` against the appliance source.')
$out.Add('')
$out.Add('This is the agent-facing companion to [`docs/reference/imports.md`](../reference/imports.md). The human-facing reference describes what each library is *for*; this file describes the *exact call signature* of every function the libraries expose, mined from the Hercules platform-script engine source.')
$out.Add('')
$out.Add('## How to read this reference')
$out.Add('')
$out.Add('Each function entry lists:')
$out.Add('')
$out.Add('- **Parameters** — positional arguments you pass via the `Function` command''s `Parameters` array, in declaration order. Optional parameters are marked with `?`. Pass `""` (empty string) or omit trailing optionals.')
$out.Add('- **Caller-scope reads** — `%VarName%` references the function makes to variables that are **not** declared as its parameters. The calling operation must declare these as operation parameters or `SetItem` them before calling. (Some of these are runtime-supplied — see the [Common script context variables](#common-script-context-variables) section.)')
$out.Add('- **Calls** — other functions this one invokes. If a called function lives in a different library, you must add that library to your `Imports`.')
$out.Add('- **Sets locally** — variable names this function writes via `SetItem`, `BufferName`, `ResultVariable`, or `ConnectionObjectName`. Where the same name appears as a parameter, the function shadows the parameter locally; where it does not, the variable may leak to caller scope (script-engine semantics).')
$out.Add('- **Returns** — literal values the function returns, when statically determinable. A blank entry usually means the function returns void or returns an expression whose value depends on runtime state.')
$out.Add('')
$out.Add('### Calling positional functions')
$out.Add('')
$out.Add('Pass arguments as an ordered array of `%VariableName%` (or `%VariableName::$%` for secrets). The array length must match the number of declared parameters; the engine rejects calls with too few or too many arguments.')
$out.Add('')
$out.Add('```json')
$out.Add('{')
$out.Add('  "Function": {')
$out.Add('    "Name": "LoginSsh",')
$out.Add('    "Parameters": [ "%FuncUserName%", "%FuncPassword::$%", "%UserKey::$%", "" ],')
$out.Add('    "ResultVariable": "LoginResult"')
$out.Add('  }')
$out.Add('}')
$out.Add('```')
$out.Add('')
$out.Add('### Calling 0-parameter functions')
$out.Add('')
$out.Add('Several library functions declare zero parameters but still rely on caller-scope variables. Your operation must declare those variables (typically as operation parameters such as `FuncUserName`, `FuncPassword`, `NewPassword`, `Account`) before calling. The function reads them by name from the surrounding scope.')
$out.Add('')
$out.Add('```json')
$out.Add('{ "Function": { "Name": "ValidatePassword", "ResultVariable": "ValidateResult" } }')
$out.Add('```')
$out.Add('')
$out.Add('## Common script context variables')
$out.Add('')
$out.Add('Variables every operation receives or commonly declares; library functions reference these freely without declaring them as parameters:')
$out.Add('')
$out.Add('| Variable | Source | Purpose |')
$out.Add('| --- | --- | --- |')
$out.Add('| `Address` | Operation parameter (required) | Network address of the target asset. |')
$out.Add('| `AssetName` | Operation parameter | Display name of the asset; falls back to `Address`. |')
$out.Add('| `Port` | Operation parameter | Network port. SSH operations typically default to 22. |')
$out.Add('| `Timeout` | Operation parameter | Operation timeout in seconds. |')
$out.Add('| `RequestTerminal` | Operation parameter | Whether the SSH `Connect` requests a PTY. |')
$out.Add('| `CheckHostKey` | Operation parameter | Whether to verify the SSH host key on connect. |')
$out.Add('| `HostKey` | Operation parameter (Secret) | Stored host key when `CheckHostKey` is true. |')
$out.Add('| `DelegationPrefix` | Operation parameter (Secret) | Optional shell prefix to elevate before commands. |')
$out.Add('| `FuncUserName` | Operation parameter | The user the operation logs in as. |')
$out.Add('| `FuncPassword` | Operation parameter (Secret) | Password for `FuncUserName`. |')
$out.Add('| `UserKey` | Operation parameter (Secret) | SSH private key for `FuncUserName`. |')
$out.Add('| `NewPassword` | Operation parameter (Secret) | New password supplied by SPP for `ChangePassword` operations. |')
$out.Add('| `Account` / `AccountUserName` | Operation parameter | The managed account whose credential is being checked or rotated. Some libraries read one or the other. |')
$out.Add('| `ConnectSsh` | Set by `LoginSsh` (Global) | The SSH connection object used by subsequent `Send` / `Receive` / `Disconnect` commands. |')
$out.Add('| `Exception` | Engine | Set inside `Catch` blocks when an error is caught. |')
$out.Add('')
$out.Add('## Library index')
$out.Add('')
$out.Add('| Library | Function count |')
$out.Add('| --- | ---: |')
foreach ($lib in $libraryData) {
    $out.Add(("| [``{0}``](#library-{1}) | {2} |" -f $lib.Name, $lib.Name.ToLowerInvariant(), $lib.Functions.Count))
}
$out.Add('')

# Per-library sections
foreach ($lib in $libraryData) {
    $anchor = $lib.Name.ToLowerInvariant()
    $out.Add(("## Library: ``{0}`` <a id=""library-{1}""></a>" -f $lib.Name, $anchor))
    $out.Add('')

    # Quick table
    $out.Add('| Function | Parameters | Calls | Caller-scope reads |')
    $out.Add('| --- | --- | --- | --- |')
    foreach ($fn in $lib.Functions) {
        $paramSummary = if ($fn.Parameters.Count -eq 0) { '_(none)_' }
                        else { ($fn.Parameters | ForEach-Object { if ($_.Required) { $_.Name } else { $_.Name + '?' } }) -join ', ' }
        $callSummary = if (-not $fn.Calls -or $fn.Calls.Count -eq 0) { '_(none)_' }
                       elseif ($fn.Calls.Count -le 4) { '`' + ($fn.Calls -join '`, `') + '`' }
                       else { ('`{0}`, `{1}`, ...({2} more)' -f $fn.Calls[0], $fn.Calls[1], ($fn.Calls.Count - 2)) }
        $readSummary = if (-not $fn.ReadsFromCallerScope -or $fn.ReadsFromCallerScope.Count -eq 0) { '_(none)_' }
                       elseif ($fn.ReadsFromCallerScope.Count -le 6) { '`' + ($fn.ReadsFromCallerScope -join '`, `') + '`' }
                       else { ('`{0}`, `{1}`, ...({2} more)' -f $fn.ReadsFromCallerScope[0], $fn.ReadsFromCallerScope[1], ($fn.ReadsFromCallerScope.Count - 2)) }
        $out.Add(("| [``{0}``](#fn-{1}-{2}) | {3} | {4} | {5} |" -f $fn.Name, $anchor, $fn.Name.ToLowerInvariant(), $paramSummary, $callSummary, $readSummary))
    }
    $out.Add('')

    # Full detail
    foreach ($fn in $lib.Functions) {
        $out.Add(("### ``{0}`` <a id=""fn-{1}-{2}""></a>" -f $fn.Name, $anchor, $fn.Name.ToLowerInvariant()))
        $out.Add('')
        $out.Add(("**Signature:** ``{0}({1})``" -f $fn.Name, (Format-ParametersInline $fn.Parameters)))
        $out.Add('')
        if ($fn.Parameters.Count -gt 0) {
            $out.Add('**Parameters:**')
            $out.Add('')
            foreach ($p in $fn.Parameters) {
                $req = if ($p.Required) { 'required' } else { 'optional' }
                $bits = @($p.Type, $req)
                if ($null -ne $p.Default) { $bits += "default: $($p.Default)" }
                $line = ("- ``{0}`` ({1})" -f $p.Name, ($bits -join ', '))
                if ($p.Description) { $line += " — $($p.Description)" }
                $out.Add($line)
            }
            $out.Add('')
        }
        $out.Add(("**Caller-scope reads:** {0}" -f (Format-ListInline $fn.ReadsFromCallerScope)))
        $out.Add('')
        $out.Add(("**Calls:** {0}" -f (Format-ListInline $fn.Calls)))
        $out.Add('')
        $out.Add(("**Sets locally:** {0}" -f (Format-ListInline $fn.SetsLocally)))
        $out.Add('')
        $out.Add(("**Returns:** {0}" -f (Format-ListInline $fn.Returns)))
        $out.Add('')
    }
}

$out.Add('---')
$out.Add('')
$out.Add(("_Generated {0} from Hercules sources at_ `{1}`." -f (Get-Date -Format 'yyyy-MM-dd'), $HerculesImportsPath))
$out.Add('')

$outDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$out -join "`n" | Set-Content -LiteralPath $OutputPath -Encoding UTF8

Write-Host ("Wrote {0} ({1} libraries, {2} functions)." -f `
    $OutputPath, $libraryData.Count, ($libraryData | ForEach-Object { $_.Functions.Count } | Measure-Object -Sum).Sum)
