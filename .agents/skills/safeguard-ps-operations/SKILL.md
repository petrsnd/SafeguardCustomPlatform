---
name: safeguard-ps-operations
description: >-
  Use when the agent must drive a live SPP appliance through safeguard-ps
  to validate, import, trigger, and inspect a custom platform script.
  Covers Connect-Safeguard -Browser auth, the cmdlet menu
  (Test- / Import- / Export- / asset / account / trigger), idempotency,
  extended-logging triggers, task-log JSON retrieval, and how to call
  tools/Invoke-PlatformDevLoop.ps1 instead of re-implementing the loop.
  All cmdlet syntax must be sourced from Get-Help <Cmdlet> -Full against
  the installed module, never paraphrased from memory.
---

# safeguard-ps-operations

## Pre-flight

Before invoking any cmdlet covered by this skill, consult [`AGENTS.md`](../../../AGENTS.md) for the active workflow algorithm (new-platform vs enhance-platform) and the iterative debug-loop budget. Single-skill entry points (e.g., "just import this script") still run inside one of those workflows; do not bypass the orchestration layer.

## Scope

This skill is the `safeguard-ps` wrapper. It owns:

- Authenticating to a Safeguard for Privileged Passwords (SPP) appliance.
- Validating, importing, and exporting custom platform scripts.
- Creating or updating the asset and account used for testing.
- Triggering operations (`CheckPassword`, `ChangePassword`, …) with extended logging.
- Fetching the resulting task-log JSON for [`task-log-analysis`](../task-log-analysis/SKILL.md).

It is the **only** skill that directly calls `safeguard-ps`. Other skills request operations through this one.

## Modes

- **full-loop** — every operation in this skill is in scope.
- **author-only** — only `Test-SafeguardCustomPlatformScript` and `Export-SafeguardCustomPlatformScript` (when applied to a local file via `-OutFile`) are usable; everything else requires an appliance and **fails closed** with a clear message.
- **probe-only** — fails closed. Use [`target-probing`](../target-probing/SKILL.md) instead.

## Grounding rule (mandatory)

Every cmdlet, parameter name, and parameter-set described to the operator MUST come from `Get-Help <Cmdlet> -Full` against the **installed** `safeguard-ps` module. Do not paraphrase from memory, vendor docs, or prior conversations.

When the agent does not already have `Get-Help` output for a cmdlet it is about to call, it asks the operator to run, e.g.:

```powershell
Get-Help Import-SafeguardCustomPlatformScript -Full
Get-Help Test-SafeguardAssetAccountPassword   -Full
```

and pastes the output back. Use that output as the source of truth.

## Authentication

Connect with `-Browser` (PKCE) only. No password-in-script recipes; no `-Username`/`-Password` parameters in agent flows.

```powershell
Connect-Safeguard -Appliance <host> [-Insecure] -Browser
```

This pattern is verified in [`tools/README.md`](../../../tools/README.md) ("Authentication" section) and is what `tools/Invoke-PlatformDevLoop.ps1` expects via the cached `$Global:SafeguardSession`. The dev-loop wrapper itself does not call `Connect-Safeguard`; the operator connects once at the start of the session.

After connecting, treat the session as opaque. Never log `$Global:SafeguardSession`, the access token, or any password parameter.

## Cmdlet menu

The cmdlets this skill calls, all sourced from `Get-Help`. The shapes below are recap; consult `Get-Help` for parameter details.

| Cmdlet | Purpose | Used by |
| --- | --- | --- |
| `Connect-Safeguard -Browser` | PKCE login. Caches `$Global:SafeguardSession`. | Skill bootstrap. |
| `Test-SafeguardCustomPlatformScript` | Server-side dry-run of a script. POSTs to `Core/Platforms/ValidateScript/Raw`; returns the platform-preview object the script would produce. | `Invoke-PlatformDevLoop.ps1` validate phase. |
| `Import-SafeguardCustomPlatformScript` | PUTs the script to `Core/Platforms/{Id}/Script/Raw`, then re-reads the platform via `Get-SafeguardCustomPlatform`. | `Invoke-PlatformDevLoop.ps1` import phase. |
| `Export-SafeguardCustomPlatformScript` | Pulls the deployed JSON back. **Source of truth for the enhance-platform workflow** — on-disk samples are starting points and may have drifted. | Manual call before authoring an enhancement. |
| `Get-SafeguardCustomPlatform` | Looks up a platform by name or ID. Used to confirm the platform exists before import. | Idempotency checks. |
| `Test-SafeguardAssetAccountPassword` | Triggers `CheckPassword` (`POST Core/v4/AssetAccounts/{id}/CheckPassword?extendedLogging=true`). | `Invoke-PlatformDevLoop.ps1` trigger phase. |
| `Invoke-SafeguardAssetAccountPasswordChange` | Triggers `ChangePassword` (`POST Core/v4/AssetAccounts/{id}/ChangePassword?extendedLogging=true`). | `Invoke-PlatformDevLoop.ps1` trigger phase. |
| `Get-SafeguardTaskLog` | Pulls the extended task log. Without `-LogName`, iterates available logs and emits a synthetic `--- <logName> ---` separator entry between sections. | `Invoke-PlatformDevLoop.ps1` log phase. |

Endpoint paths and the separator/redaction behavior are documented with appliance-source citations in [`tools/README.md`](../../../tools/README.md) ("Cmdlet citations" and `phases[3] data` sections).

Asset and account create/update cmdlets (`New-SafeguardAsset`, `Edit-SafeguardAsset`, `New-SafeguardAssetAccount`, `Edit-SafeguardAssetAccount`) are out of this skill's mandatory loop — operators usually create those once, by hand, against the test appliance. If the workflow needs them, source their syntax from `Get-Help` at use time and treat create-or-update as **idempotent**: look up first, edit if it exists, create if it does not. Do not re-create on every iteration.

## Always trigger with extended logging

Every trigger cmdlet must pass `-ExtendedLogging`. The `See extended logs: Get-SafeguardTaskLog <GUID>` line that the dev-loop script regex-matches to extract the task ID is **only emitted when `-ExtendedLogging` is set** (see `tools/Invoke-PlatformDevLoop.ps1` lines 178–196 for the extraction logic and lines 282–298 of [`tools/README.md`](../../../tools/README.md) for the appliance-side rationale).

If the operator triggered an operation without `-ExtendedLogging`, the task ID cannot be reliably recovered; ask them to re-trigger.

## Use `Invoke-PlatformDevLoop.ps1` instead of re-implementing the loop

The standard validate → import → trigger → log path is implemented once, in [`tools/Invoke-PlatformDevLoop.ps1`](../../../tools/Invoke-PlatformDevLoop.ps1). This skill calls that script rather than chaining cmdlets in prose.

| Sub-phase needed | Switch | Appliance contact |
| --- | --- | --- |
| Local schema check only (fast inner loop) | `-SchemaOnly` | none |
| Schema + appliance dry-run (no writes) | `-ValidateOnly` | yes |
| Schema + appliance dry-run + import (no trigger) | `-NoTrigger` | yes |
| Full loop incl. trigger and task-log fetch | _(default)_ | yes |

Output contract (one JSON document on stdout, phase-indexed exit code, programmer errors throw without JSON) is documented in [`tools/README.md`](../../../tools/README.md) ("Output JSON shape", "Exit-code contract"). The exit-code semantics are: `0` full success, `1` validate, `2` import, `3` trigger, `4` log fetch (script header lines 38–43, body block at lines 269–407).

When a hand-rolled cmdlet sequence is unavoidable (e.g., a one-off `Export-…` to capture deployed JSON), still emit progress to stderr and any structured result to stdout so callers can parse cleanly.

## Idempotency conventions

- **Platform lookups before import.** `Import-SafeguardCustomPlatformScript -PlatformToEdit <name|id>` errors with `Unable to find custom platform matching '<name>'` if the platform does not exist; the dev-loop wrapper surfaces this verbatim as the `import` phase error (see real failure example in [`tools/README.md`](../../../tools/README.md), exit-2 block). Confirm the platform exists once at the start of a session, then re-use the name.
- **Asset / account.** Look up by name or ID; edit if found; create otherwise. Do not delete-then-create.
- **Triggers** are not idempotent in the strict sense (each run produces a new task log), but re-triggering after a failed run is safe — the prior task log persists.

## Error semantics this skill recognises

The dev-loop wrapper distinguishes three failure shapes:

1. **Programmer error** — the script throws and writes nothing to stdout. Examples: missing required parameter for the chosen mode, no active session, schema file not found. The agent treats these as bugs in its own invocation and fixes the call rather than re-running.
2. **Operational failure** — the script writes its JSON document and exits with a phase index (1–4). The agent reads the JSON, identifies the failed phase, and routes the result to the right next step (validate → script-authoring; import → check the platform name; trigger / log → [`task-log-analysis`](../task-log-analysis/SKILL.md)).
3. **Trigger failure with task log** — `safeguard-ps` raises `Ex.SafeguardLongRunningTaskException` carrying a typed `TaskLog` array. The wrapper surfaces this as `phases[2].status = "failed"` plus a structured `taskLog` field. A real failure example is captured in [`tools/README.md`](../../../tools/README.md) (`phases[2] data`, "Real failure-path output"). Even on trigger failure the wrapper still attempts the log fetch when a task GUID was extractable, so `phases[3]` is usually populated and the exit code stays `3`.

## Secret handling

- Do not write secret parameter values into evidence, status messages, or operator-visible output.
- SPP server-side already redacts known credential parameters as the literal string `**secret**` in returned task logs (constant `Hercules\Source\Hercules.DevKit\Constants\ParameterConstants.cs:5`, cited in [`tools/README.md`](../../../tools/README.md), "Secret handling"). Do not attempt to recover real values from these markers.
- Custom-script authors who add new secret parameters must declare them with `Type: "Secret"` so the same redaction applies — see [`script-authoring`](../script-authoring/SKILL.md).

## Failing closed

This skill refuses to run any operation that requires appliance contact when the active mode is `author-only` or `probe-only`, or when there is no `Connect-Safeguard` session and no `-AccessToken` was supplied. The dev-loop wrapper enforces the same check at lines 235–250 of `tools/Invoke-PlatformDevLoop.ps1`. Surface the missing prerequisite to the operator; do not attempt a workaround.

