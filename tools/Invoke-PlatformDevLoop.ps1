<#
.SYNOPSIS
Run the custom-platform dev loop: validate -> import -> trigger -> fetch task log.

.DESCRIPTION
Wraps the agent-facing iterative loop into a single call that emits a single
structured JSON document on stdout and exits with a phase-indexed exit code.
Designed to be called by the safeguard-ps-operations agent skill and
by humans during day-to-day authoring.

Four modes, selected by mutually-exclusive switches:

    -SchemaOnly     local Test-Json against schema/. No appliance contact.
    -ValidateOnly   schema + Test-SafeguardCustomPlatformScript on the appliance.
    -NoTrigger      validate + Import-SafeguardCustomPlatformScript.
    (default)       full loop: validate + import + trigger + fetch task log.

Output contract (always one JSON object on stdout):

    {
      "mode": "SchemaOnly|ValidateOnly|NoTrigger|FullLoop",
      "scriptFile": "...",
      "platform": "..." | null,
      "operation": "CheckPassword|ChangePassword" | null,
      "account": "..." | null,
      "phases": [
        { "name": "validate"|"import"|"trigger"|"log",
          "status": "success"|"failed"|"skipped",
          "durationMs": <int>,
          "error": "..." | null,
          "data": <cmdlet response> | null }
      ],
      "exitCode": <int>,
      "startedAt": "<ISO8601>",
      "endedAt": "<ISO8601>"
    }

Exit codes:
    0  full success (or all-skipped is a programmer error, not 0)
    1  validate phase failed
    2  import phase failed
    3  trigger phase failed
    4  log fetch failed

The script throws (no JSON written) only for programmer errors:
    - required parameter missing for the chosen mode
    - input script file not readable
    - schema file not found
    - no Connect-Safeguard session and no -AccessToken when appliance contact
      is required

Programmer-error throws produce a non-zero PowerShell exit but no JSON
on stdout, so callers can distinguish "tool misuse" from "loop failure".

.PARAMETER ScriptFile
Path to the custom platform JSON script. Required for every mode.

.PARAMETER SchemaOnly
Run only local JSON Schema validation against -SchemaFile. No appliance contact.

.PARAMETER ValidateOnly
Run schema validation and Test-SafeguardCustomPlatformScript only. No import,
no trigger.

.PARAMETER NoTrigger
Run schema + Test + Import. Skip trigger and log fetch.

.PARAMETER PlatformToEdit
Custom platform name or numeric ID to import the script into. Required for
-NoTrigger and full-loop modes.

.PARAMETER Operation
Trigger to run in full-loop mode. CheckPassword maps to
Test-SafeguardAssetAccountPassword; ChangePassword maps to
Invoke-SafeguardAssetAccountPasswordChange. Both pass -ExtendedLogging so a
task log is produced.

.PARAMETER AccountToUse
Account ID or name to run the trigger against. Required for full-loop.

.PARAMETER AssetToUse
Optional asset name or ID disambiguator. Passed straight through to the
underlying safeguard-ps cmdlet.

.PARAMETER AssetPartition
Optional asset-partition name or ID. Passed through.

.PARAMETER AssetPartitionId
Optional asset-partition numeric ID (overrides -AssetPartition). Passed through.

.PARAMETER SchemaFile
Override path to the JSON Schema. Defaults to
<repo>/schema/custom-platform-script.schema.json relative to this script.

.PARAMETER Appliance
Pass-through for safeguard-ps cmdlets. Usually unset; the cached
$Global:SafeguardSession from Connect-Safeguard -DeviceCode (or -Browser) is used instead.

.PARAMETER AccessToken
Pass-through bearer token for safeguard-ps cmdlets. Usually unset.

.PARAMETER Insecure
Pass-through. Skip SSL verification on the appliance.

.EXAMPLE
PS> Invoke-PlatformDevLoop.ps1 -ScriptFile .\samples\ssh\generic-linux\GenericLinux.json -SchemaOnly

.EXAMPLE
PS> Invoke-PlatformDevLoop.ps1 -ScriptFile .\my.json -ValidateOnly -Insecure

.EXAMPLE
PS> Invoke-PlatformDevLoop.ps1 -ScriptFile .\my.json -PlatformToEdit "My Custom Linux" `
        -Operation CheckPassword -AccountToUse oracle -Insecure
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ScriptFile,

    [switch]$SchemaOnly,
    [switch]$ValidateOnly,
    [switch]$NoTrigger,

    [object]$PlatformToEdit,

    [ValidateSet('CheckPassword','ChangePassword')]
    [string]$Operation,

    [object]$AccountToUse,
    [object]$AssetToUse,
    [object]$AssetPartition,
    [int]$AssetPartitionId,

    [string]$SchemaFile,

    [string]$Appliance,
    [object]$AccessToken,
    [switch]$Insecure
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---- PowerShell version preference ----------------------------------------
# safeguard-ps targets PS 7. Several cmdlets emit cleaner error records there
# and avoid Windows-PowerShell-only quirks. Warn (don't block) on PS 5.1.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "Running on PowerShell $($PSVersionTable.PSVersion). PowerShell 7+ is recommended for safeguard-ps; continuing anyway."
}

# ---- minimum module version ------------------------------------------------
# safeguard-ps 8.4.3 added -ExtendedLogging to Invoke-SafeguardAssetSshHostKeyDiscovery,
# which the new-platform workflow relies on to capture a persistent task log when
# host-key discovery fails (see docs/agent-reference/failure-patterns.md). Earlier
# versions emit only the surface 60307 error with no task log.
$script:MinSafeguardPsVersion = [Version]'8.4.3'
$installedVersions = @(Get-Module -ListAvailable -Name safeguard-ps |
    Sort-Object Version -Descending |
    Select-Object -ExpandProperty Version)
if (-not $installedVersions -or $installedVersions[0] -lt $script:MinSafeguardPsVersion) {
    $have = if ($installedVersions) { $installedVersions[0] } else { '<not installed>' }
    throw "Invoke-PlatformDevLoop.ps1 requires safeguard-ps >= $($script:MinSafeguardPsVersion); found $have. Run: Install-Module safeguard-ps -Scope CurrentUser -Force"
}

# ---- helpers ---------------------------------------------------------------

function Write-StatusLine {
    param([string]$Message)
    # All progress text goes to stderr so stdout stays a single JSON document.
    [Console]::Error.WriteLine($Message)
}

function New-PhaseResult {
    param([string]$Name)
    [ordered]@{
        name       = $Name
        status     = 'skipped'
        durationMs = 0
        error      = $null
        data       = $null
    }
}

function Set-PhaseSuccess {
    param($Phase, [int]$DurationMs, $Data)
    $Phase.status = 'success'
    $Phase.durationMs = $DurationMs
    $Phase.data = $Data
}

function Set-PhaseFailure {
    param($Phase, [int]$DurationMs, [string]$ErrorMessage, $Data = $null)
    $Phase.status = 'failed'
    $Phase.durationMs = $DurationMs
    $Phase.error = $ErrorMessage
    $Phase.data = $Data
}

function Get-TaskIdFromInformationMessages {
    param([string[]]$Messages)
    # safeguard-ps's Wait-LongRunningTask emits this exact line via Write-Host
    # (Information stream) when a triggered task with extendedLogging completes
    # or fails:
    #     "See extended logs: Get-SafeguardTaskLog <GUID>"
    # Source: safeguard-ps Wait-LongRunningTask (the two extendedLogging
    # branches that emit "See extended logs:"); verified against v8.4.3.
    # The GUID is not exposed on the cmdlet's return value (which is a
    # human-readable multi-line string), so capturing Information messages and
    # regex-matching this line is the grounded extraction path.
    if (-not $Messages) { return $null }
    foreach ($msg in $Messages) {
        if ($msg -match 'Get-SafeguardTaskLog\s+([0-9a-fA-F-]{36})') {
            return $matches[1]
        }
    }
    return $null
}

function Test-ApplianceConnection {
    param([string]$Token)
    if ($Token) { return $true }
    try {
        $session = Get-Variable -Name SafeguardSession -Scope Global -ErrorAction Stop -ValueOnly
        return [bool]$session
    } catch {
        return $false
    }
}

# ---- mode resolution and parameter validation ------------------------------

# Mutually exclusive switches.
$flagCount = @($SchemaOnly, $ValidateOnly, $NoTrigger | Where-Object { $_ }).Count
if ($flagCount -gt 1) {
    throw "Specify at most one of -SchemaOnly, -ValidateOnly, -NoTrigger."
}

$mode = if ($SchemaOnly)   { 'SchemaOnly' }
        elseif ($ValidateOnly) { 'ValidateOnly' }
        elseif ($NoTrigger)    { 'NoTrigger' }
        else                   { 'FullLoop' }

if (-not (Test-Path -LiteralPath $ScriptFile -PathType Leaf)) {
    throw "ScriptFile not found or not readable: $ScriptFile"
}
$ScriptFile = (Resolve-Path -LiteralPath $ScriptFile).ProviderPath

if (-not $SchemaFile) {
    $SchemaFile = Join-Path $PSScriptRoot '..\schema\custom-platform-script.schema.json'
}
if (-not (Test-Path -LiteralPath $SchemaFile -PathType Leaf)) {
    throw "SchemaFile not found: $SchemaFile"
}
$SchemaFile = (Resolve-Path -LiteralPath $SchemaFile).ProviderPath

$needsAppliance = $mode -in @('ValidateOnly','NoTrigger','FullLoop')
$needsPlatform  = $mode -in @('NoTrigger','FullLoop')
$needsTrigger   = $mode -eq 'FullLoop'

if ($needsAppliance -and -not (Test-ApplianceConnection -Token $AccessToken)) {
    throw "Mode '$mode' requires an active Safeguard session. Run Connect-Safeguard -DeviceCode (or -Browser) first, or pass -AccessToken."
}
if ($needsPlatform -and -not $PlatformToEdit) {
    throw "Mode '$mode' requires -PlatformToEdit (custom platform name or ID)."
}
if ($needsTrigger -and -not $Operation) {
    throw "Mode 'FullLoop' requires -Operation (CheckPassword or ChangePassword)."
}
if ($needsTrigger -and -not $AccountToUse) {
    throw "Mode 'FullLoop' requires -AccountToUse."
}

# ---- pass-through builder for safeguard-ps cmdlets -------------------------

$applianceArgs = @{}
if ($Appliance)   { $applianceArgs.Appliance   = $Appliance }
if ($AccessToken) { $applianceArgs.AccessToken = $AccessToken }
if ($Insecure)    { $applianceArgs.Insecure    = $true }

# ---- phase records ---------------------------------------------------------

$validatePhase = New-PhaseResult -Name 'validate'
$importPhase   = New-PhaseResult -Name 'import'
$triggerPhase  = New-PhaseResult -Name 'trigger'
$logPhase      = New-PhaseResult -Name 'log'

$startedAt = Get-Date
$exitCode = 0

# ---- phase 1: validate -----------------------------------------------------

Write-StatusLine "[validate] schema=$SchemaFile script=$ScriptFile"
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $scriptText = Get-Content -LiteralPath $ScriptFile -Raw
    # Test-Json throws with a useful message; capture it.
    $null = $scriptText | Test-Json -SchemaFile $SchemaFile -ErrorAction Stop
    $localPreview = $null
    if ($mode -eq 'SchemaOnly') {
        Set-PhaseSuccess -Phase $validatePhase -DurationMs $sw.ElapsedMilliseconds -Data @{ schemaOnly = $true }
    }
    else {
        Write-StatusLine "[validate] calling Test-SafeguardCustomPlatformScript"
        $apiPreview = Test-SafeguardCustomPlatformScript @applianceArgs -ScriptFile $ScriptFile
        Set-PhaseSuccess -Phase $validatePhase -DurationMs $sw.ElapsedMilliseconds -Data $apiPreview
    }
}
catch {
    Set-PhaseFailure -Phase $validatePhase -DurationMs $sw.ElapsedMilliseconds -ErrorMessage $_.Exception.Message
    $exitCode = 1
}
finally {
    $sw.Stop()
}

# ---- phase 2: import -------------------------------------------------------

if ($exitCode -eq 0 -and $mode -in @('NoTrigger','FullLoop')) {
    Write-StatusLine "[import] platform=$PlatformToEdit"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $imported = Import-SafeguardCustomPlatformScript @applianceArgs -PlatformToEdit $PlatformToEdit -ScriptFile $ScriptFile
        Set-PhaseSuccess -Phase $importPhase -DurationMs $sw.ElapsedMilliseconds -Data $imported
    }
    catch {
        Set-PhaseFailure -Phase $importPhase -DurationMs $sw.ElapsedMilliseconds -ErrorMessage $_.Exception.Message
        $exitCode = 2
    }
    finally {
        $sw.Stop()
    }
}

# ---- phase 3: trigger ------------------------------------------------------

$triggerInfo = $null   # Information-stream messages captured from the trigger cmdlet
$triggerText = $null   # Cmdlet return value (multi-line human-readable status string)
$triggerTaskId = $null
$triggerFailureLog = $null  # Structured log array attached to SafeguardLongRunningTaskException
if ($exitCode -eq 0 -and $mode -eq 'FullLoop') {
    Write-StatusLine "[trigger] op=$Operation account=$AccountToUse"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $triggerArgs = @{} + $applianceArgs
        $triggerArgs.AccountToUse    = $AccountToUse
        $triggerArgs.ExtendedLogging = $true
        if ($PSBoundParameters.ContainsKey('AssetToUse'))        { $triggerArgs.AssetToUse        = $AssetToUse }
        if ($PSBoundParameters.ContainsKey('AssetPartition'))    { $triggerArgs.AssetPartition    = $AssetPartition }
        if ($PSBoundParameters.ContainsKey('AssetPartitionId'))  { $triggerArgs.AssetPartitionId  = $AssetPartitionId }

        # Wait-LongRunningTask in safeguard-ps writes the "See extended logs: ..."
        # line via Write-Host (Information stream, 6). -InformationVariable captures
        # those records without polluting stdout.
        $invokeArgs = @{} + $triggerArgs
        $invokeArgs.InformationVariable = 'devloopTriggerInfo'
        $invokeArgs.InformationAction   = 'SilentlyContinue'

        switch ($Operation) {
            'CheckPassword'  { $triggerText = Test-SafeguardAssetAccountPassword       @invokeArgs }
            'ChangePassword' { $triggerText = Invoke-SafeguardAssetAccountPasswordChange @invokeArgs }
        }

        $triggerInfo = @($devloopTriggerInfo | ForEach-Object { $_.MessageData.ToString() })
        $triggerTaskId = Get-TaskIdFromInformationMessages -Messages $triggerInfo

        Set-PhaseSuccess -Phase $triggerPhase -DurationMs $sw.ElapsedMilliseconds -Data ([ordered]@{
            taskId             = $triggerTaskId
            outputText         = $triggerText
            informationStream  = $triggerInfo
        })
    }
    catch {
        # Capture whatever Information records were emitted before the throw (the
        # "See extended logs: ..." line is emitted before the exception in
        # Wait-LongRunningTask's failure path).
        try { $triggerInfo = @($devloopTriggerInfo | ForEach-Object { $_.MessageData.ToString() }) } catch { $triggerInfo = @() }
        $triggerTaskId = Get-TaskIdFromInformationMessages -Messages $triggerInfo

        # SafeguardLongRunningTaskException carries the structured log array.
        $exData = $null
        $ex = $_.Exception
        try {
            if ($ex.PSObject.Properties['TaskLog'] -and $ex.TaskLog) {
                $exData = @($ex.TaskLog | ForEach-Object {
                    [ordered]@{ Timestamp = $_.Timestamp; Status = $_.Status; Message = $_.Message }
                })
                $triggerFailureLog = $exData
            }
        } catch { }

        Set-PhaseFailure -Phase $triggerPhase -DurationMs $sw.ElapsedMilliseconds -ErrorMessage $ex.Message -Data ([ordered]@{
            taskId             = $triggerTaskId
            informationStream  = $triggerInfo
            taskLog            = $triggerFailureLog
        })
        $exitCode = 3
    }
    finally {
        $sw.Stop()
    }
}

# ---- phase 4: log fetch ----------------------------------------------------

# In the trigger-failure path we still try the log fetch if we got a task ID,
# because the extended log is the most useful artifact for an agent to analyze.
# Exit code reflects the trigger failure (3), not the log fetch.
if ($mode -eq 'FullLoop' -and ($exitCode -eq 0 -or ($exitCode -eq 3 -and $triggerTaskId))) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        if (-not $triggerTaskId) {
            throw "Could not extract a task ID from the trigger Information stream. Expected a 'See extended logs: Get-SafeguardTaskLog <GUID>' message but none was captured."
        }
        Write-StatusLine "[log] taskId=$triggerTaskId"
        $log = Get-SafeguardTaskLog @applianceArgs -TaskId $triggerTaskId
        Set-PhaseSuccess -Phase $logPhase -DurationMs $sw.ElapsedMilliseconds -Data ([ordered]@{
            taskId = $triggerTaskId
            log    = $log
        })
    }
    catch {
        Set-PhaseFailure -Phase $logPhase -DurationMs $sw.ElapsedMilliseconds -ErrorMessage $_.Exception.Message
        if ($exitCode -eq 0) { $exitCode = 4 }
    }
    finally {
        $sw.Stop()
    }
}

# ---- emit result -----------------------------------------------------------

$endedAt = Get-Date

$result = [ordered]@{
    mode       = $mode
    scriptFile = $ScriptFile
    schemaFile = $SchemaFile
    platform   = if ($PlatformToEdit) { $PlatformToEdit } else { $null }
    operation  = if ($Operation)      { $Operation }      else { $null }
    account    = if ($AccountToUse)   { $AccountToUse }   else { $null }
    phases     = @($validatePhase, $importPhase, $triggerPhase, $logPhase)
    exitCode   = $exitCode
    startedAt  = $startedAt.ToUniversalTime().ToString('o')
    endedAt    = $endedAt.ToUniversalTime().ToString('o')
}

# Depth 100 because task-log JSON nests deeply (per-command Input/Output records).
$result | ConvertTo-Json -Depth 100

exit $exitCode
