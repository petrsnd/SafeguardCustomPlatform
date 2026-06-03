---
name: script-authoring
description: >-
  Use when drafting or revising the custom-platform JSON itself. Six
  pattern recipes (ssh-interactive, ssh-batch, http-api-basic,
  http-api-bearer, http-api-key, http-form-fill) cite schema, samples,
  and templates and cover Do blocks, status messages, custom parameters,
  and reserved variables. Mandates the fast inner loop: local schema
  validation against schema/ before any appliance round-trip. SchemaOnly
  green is necessary but not sufficient — cross-reference samples for
  analogous patterns before declaring ready.
---

# script-authoring

## Pre-flight

Before drafting or revising any platform JSON, consult [`AGENTS.md`](../../../AGENTS.md) for the active workflow algorithm (new-platform vs enhance-platform) and the iterative debug-loop budget. If the operator skipped target probing or strategy selection and went straight to "write me the JSON", surface that — the wrong pattern compiles cleanly but fails on the appliance.

## Scope

Six pattern sub-recipes cover the supported transports:

- [`ssh-interactive`](#ssh-interactive)
- [`ssh-batch`](#ssh-batch)
- [`http-api-basic`](#http-api-basic)
- [`http-api-bearer`](#http-api-bearer)
- [`http-api-key`](#http-api-key)
- [`http-form-fill`](#http-form-fill)

Telnet/TN3270 is out of scope (`agent-skills-plan.md` §2). The recipes below are starting points; pick one based on [`strategy-selection`](../strategy-selection/SKILL.md) output and adapt it.

## Modes

`author-only`, `probe-only`, `full-loop`. The skill never directly contacts the appliance — it produces JSON and hands off to [`safeguard-ps-operations`](../safeguard-ps-operations/SKILL.md).

## Authoritative inputs

- The platform-script JSON Schema: [`schema/custom-platform-script.schema.json`](../../../schema/custom-platform-script.schema.json). The schema is intentionally permissive ("Provides autocomplete and hover help for editors while remaining permissive enough to allow valid edge-case scripts" — schema description, line 5).
- The samples and templates index: [`docs/agent-reference/samples-index.md`](../../../docs/agent-reference/samples-index.md). Look up a starting point by `(protocol, auth-scheme, operations)` — do not walk `samples/` from scratch.
- Reference for individual scripting commands lives under [`docs/reference/commands/`](../../../docs/reference/commands/). Prefer those pages over guessing command shapes.
- Reserved variables and custom parameter conventions: [`docs/reference/reserved-parameters.md`](../../../docs/reference/reserved-parameters.md), [`docs/reference/variables.md`](../../../docs/reference/variables.md), [`docs/reference/custom-parameters.md`](../../../docs/reference/custom-parameters.md).
- Status message taxonomy: [`docs/reference/status-messages.md`](../../../docs/reference/status-messages.md).

## Mandatory: fast inner loop first

Local JSON Schema validation runs **before** any appliance round-trip:

```powershell
./tools/Invoke-PlatformDevLoop.ps1 -ScriptFile <draft.json> -SchemaOnly
```

Sub-second, no appliance contact, exit `0` on pass and `1` on schema rejection. Only after this passes does the agent move to `-ValidateOnly` (server dry-run) and then to import + trigger.

### `SchemaOnly` is necessary, not sufficient

A green local schema check proves the JSON parses and conforms to the schema. It does **not** catch:

- Undefined variables referenced inside `Do` blocks (`%FuncUserName%` vs `%FuncUsername%`, etc. — the schema does not parse `%…%` substitutions).
- Regex in `ExpectRegex` / `Condition.If` that compiles but does not match real target output.
- `Send` / `Receive` ordering that drifts out of sync with the actual prompt.
- Status messages emitted in the wrong order or at the wrong phase.

Before declaring a draft "ready to import," cross-reference an analogous sample from `samples-index.md`. If a sample uses a construct your draft does not (e.g., a `Try`/`Catch` around `Disconnect`, a `Receive` flush of the login banner, a `Headers` block before `HttpAuth`), surface that divergence to the operator rather than silently omitting it. The `agent-skills-plan.md` §5 rule is explicit: *"if a sample uses a construct the draft doesn't, surface the divergence."*

## Conventions all six patterns share

- **Top-level shape.** `Id`, `BackEnd: "Scriptable"`, optional `Meta`, optional `Imports`, then one object per operation (`CheckSystem`, `CheckPassword`, `ChangePassword`, …). Operation objects contain `Parameters` (array of single-key objects) and `Do` (array of command objects). See [`schema/custom-platform-script.schema.json`](../../../schema/custom-platform-script.schema.json) lines 14–80 for the top-level fields, and [`docs/reference/script-structure.md`](../../../docs/reference/script-structure.md) for prose.
- **Reserved parameters** are not declared by the script — SPP injects them. Custom parameters are declared in `Parameters` and addressed as `%Name%`. See [`docs/reference/reserved-parameters.md`](../../../docs/reference/reserved-parameters.md) and [`docs/reference/custom-parameters.md`](../../../docs/reference/custom-parameters.md).
- **Secrets.** Any parameter that holds a credential MUST be `Type: "Secret"` so SPP redacts it in task logs (see the redaction note in [`safeguard-ps-operations`](../safeguard-ps-operations/SKILL.md) and [`tools/README.md`](../../../tools/README.md), "Secret handling"). Use the `::$` modifier (`%FuncPassword::$%`) where the templates and samples do; do not invent a different escape.
- **`Try` / `Catch`.** Wrap fallible operations (network calls, command execution, parses) so a clean `Disconnect` still runs and a structured `Return`/`Throw` is produced. Both [`templates/TemplateSshMinimal.json`](../../../templates/TemplateSshMinimal.json) and [`templates/TemplateHttpMinimal.json`](../../../templates/TemplateHttpMinimal.json) demonstrate this shape end-to-end.
- **Return values.** End each operation with `Return` (typically `%CheckResult%` or a discovery payload). Never let an operation fall off the end of `Do` without a return.
- **Status messages.** Emit them via the supported logging commands (see [`docs/reference/status-messages.md`](../../../docs/reference/status-messages.md)) — they end up in the task log and are how [`task-log-analysis`](../task-log-analysis/SKILL.md) knows how far the script got.

If a `Do`-block construct does not appear in any sample or template, **stop and ask** before adding it. The grounding rule applies inside the JSON, not just around it.

## Pattern recipes

### ssh-interactive

**Use when** the target presents a shell prompt, banner, or appliance CLI; password change goes through interactive prompts (`passwd`); sudo may prompt.

**Starter:** [`templates/TemplateSshMinimal.json`](../../../templates/TemplateSshMinimal.json) — minimum viable `CheckSystem` using `Connect` + `Send` + `Receive`. Wraps the work in `Try`/`Catch` and unconditionally `Disconnect`s.

**Closest production sample:** [`samples/ssh/generic-linux/GenericLinux.json`](../../../samples/ssh/generic-linux/GenericLinux.json) — full `CheckSystem`, `CheckPassword`, `ChangePassword`, `DiscoverSshHostKey`. Mid-complexity sample with prompt flushing and unique success markers (e.g., `INIT_CHECK=$?` style).

**Key shapes (verified in the sample/template above):**

- `Connect`: `Type: "Ssh"`, `RequestTerminal: true` (default), `NetworkAddress`, `Port`, `Login`, `Password`/`UserKey`, `CheckHostKey`/`HostKey`, `Timeout`. The connection is named via `ConnectionObjectName` (e.g., `"Global:ConnectSsh"`); subsequent `Send`/`Receive` reference the unscoped name (`"ConnectSsh"`).
- `Send` writes a single line; pair with `Receive` using `ExpectRegex` to anchor on the prompt or a unique marker.
- `Disconnect` always inside its own `Try`/`Catch` so a hung session does not mask the operation result.

**Common pitfalls:** unflushed banners (the first `Receive` after `Connect` is often the banner, not the prompt); over-broad `ExpectRegex` that matches `passwd:` inside an error sentence; putting `Disconnect` after `Return`.

Reference: [`docs/guides/ssh-platforms.md`](../../../docs/guides/ssh-platforms.md), [`docs/reference/commands/connect.md`](../../../docs/reference/commands/connect.md), [`docs/reference/commands/send-receive.md`](../../../docs/reference/commands/send-receive.md).

### ssh-batch

**Use when** the target accepts `ssh user@host '<command>'` cleanly: stdout/stderr/exit-code returned without a PTY.

**Closest production sample:** [`samples/ssh/linux-ssh-batch-mode/LinuxSshBatchModeExample.json`](../../../samples/ssh/linux-ssh-batch-mode/LinuxSshBatchModeExample.json). The `Connect` block sets `RequestTerminal: false` (line 162) and the loop uses `ExecuteCommand` with `BufferName`, `StderrBufferName`, and `ExitStatusBufferName` (lines 205–211, 235–241).

**Key shapes:**

- `Connect`: same as `ssh-interactive` but `RequestTerminal: false`.
- `ExecuteCommand`: `ConnectionObjectName`, `Command`, `Stdin` (optional), `BufferName` for stdout, `StderrBufferName`, `ExitStatusBufferName`. Inspect the exit-status variable in a `Condition` block, not by parsing stderr.
- `CommandContainsSecret` / `InputContainsSecret` mark whether the `Command`/`Stdin` carries a secret so SPP can redact in task logs.

**Common pitfalls:** assuming PTY-style behavior (interactive `passwd` does not work over batch mode — use `chpasswd` or vendor-specific batch commands); forgetting to check the exit-status buffer.

Reference: [`docs/guides/ssh-platforms.md`](../../../docs/guides/ssh-platforms.md) ("Batch mode" section), [`docs/reference/commands/execute-command.md`](../../../docs/reference/commands/execute-command.md).

### http-api-basic

**Use when** vendor docs or a `WWW-Authenticate: Basic …` response indicate HTTP Basic on every call.

**Starter:** [`templates/Pattern-GenericRestApiBasicAuth.json`](../../../templates/Pattern-GenericRestApiBasicAuth.json).

**Closest production sample:** [`samples/http/wordpress/WordPressHttp.json`](../../../samples/http/wordpress/WordPressHttp.json). The pattern is `BaseAddress` → `NewHttpRequest` → `HttpAuth` → `Request`; verified at lines 33–40 and again at 78–82, 128–132 of that sample.

**Key shapes (verified in the sample):**

```jsonc
{ "HttpAuth": {
    "RequestObjectName": "SystemRequest",
    "Type": "Basic",
    "Credentials": { "Login": "%FuncUsername%", "Password": "%FuncPassword%" } } }
```

Set Basic auth per-request, not once globally. This matches the sample and avoids leaking the service-account credential into requests that should target the managed account.

Reference: [`docs/guides/http-platforms.md`](../../../docs/guides/http-platforms.md), [`docs/reference/commands/http-auth.md`](../../../docs/reference/commands/http-auth.md), [`docs/reference/commands/http-setup.md`](../../../docs/reference/commands/http-setup.md), [`docs/reference/commands/request.md`](../../../docs/reference/commands/request.md).

### http-api-bearer

**Use when** vendor docs describe an OAuth2 / token-exchange endpoint and subsequent calls send `Authorization: Bearer …`.

**Starter:** [`templates/Pattern-GenericRestApiBearerToken.json`](../../../templates/Pattern-GenericRestApiBearerToken.json).

**Closest production sample:** [`samples/http/onelogin-jit/OneLogin_GRC_JIT_addon.json`](../../../samples/http/onelogin-jit/OneLogin_GRC_JIT_addon.json). It interleaves `HttpAuth Basic` (when calling the token endpoint with client credentials, lines 2275–2278) with `Authorization: Bearer %AccessToken%` headers on subsequent calls (lines 1228, 1361, 1510, 1672, 1834, 2002, 2135).

**Key shapes:**

- POST to the token endpoint (often `HttpAuth` `Basic` with client id/secret, sometimes form-encoded body).
- Parse the response with `ExtractJsonObject` to capture `AccessToken` (or vendor-specific field).
- Build a fresh `NewHttpRequest` for each subsequent call; attach `Authorization: Bearer %AccessToken%` via the `Headers.AddHeaders` map.

Do not reuse the same `RequestObjectName` for token-fetch and operation calls — Basic auth and Bearer auth have different `HttpAuth`/`Headers` configurations and crossing them is a common source of 401s.

Reference: [`docs/guides/http-platforms.md`](../../../docs/guides/http-platforms.md) ("Bearer/OAuth2" section), [`docs/reference/commands/http-auth.md`](../../../docs/reference/commands/http-auth.md), [`docs/reference/commands/json.md`](../../../docs/reference/commands/json.md).

### http-api-key

**Use when** the API takes a static key in a custom header (e.g., `X-API-Key`, `X-Auth-Token`) instead of `Authorization`.

**Starter:** [`templates/Pattern-GenericRestApiKeyRotation.json`](../../../templates/Pattern-GenericRestApiKeyRotation.json) — also covers the `CheckApiKey` / `ChangeApiKey` operation pair. The custom-header shape lives at lines 184–190 of that file:

```jsonc
{ "Headers": {
    "RequestObjectName": "CheckApiKeyRequest",
    "AddHeaders": {
      "Accept": "application/json",
      "X-API-Key": "%ApiKey%" } } }
```

**Key shapes:**

- Use `Headers` / `AddHeaders` rather than `HttpAuth` — there is no `HttpAuth` type for arbitrary header schemes.
- Declare the key as `Type: "Secret"` in `Parameters` so SPP redacts it in task logs.
- For rotation, pair with [`docs/guides/api-key-management.md`](../../../docs/guides/api-key-management.md) — the script must implement `CheckApiKey` + `ChangeApiKey`, and the operations the platform exposes change accordingly.

Reference: [`docs/guides/api-key-management.md`](../../../docs/guides/api-key-management.md), [`docs/reference/commands/http-setup.md`](../../../docs/reference/commands/http-setup.md).

### http-form-fill

**Use when** the target only has an HTML login form (no API).

**Closest production sample:** [`samples/http/facebook/CustomFacebook.json`](../../../samples/http/facebook/CustomFacebook.json). The pattern uses `ExtractFormData` to walk the rendered form (lines 112, 195, 250) and `Request` with `ContentType: "application/x-www-form-urlencoded"` to submit it (lines 137, 222, 277). Cookies persist by default across requests on the same `RequestObjectName`.

**Key shapes:**

- GET the login page; `ExtractFormData` to capture hidden fields (CSRF tokens, lifecycle cookies).
- Mutate the extracted form object (set username/password fields), POST it back with the right `ContentType`.
- Handle multi-step flows (login → password-change page → submit) as separate `Request` + `ExtractFormData` cycles. Do not assume a single round-trip works.
- Watch for redirects; some forms set the session cookie on a 30x response, so do not abort on redirect.

**Common pitfalls:** matching field names that the vendor changes between releases (treat the form structure as observed, not assumed); skipping CSRF tokens; reusing a `RequestObjectName` across login domains and losing cookies.

Reference: [`docs/guides/http-platforms.md`](../../../docs/guides/http-platforms.md) ("Form-fill" section), [`docs/reference/commands/forms.md`](../../../docs/reference/commands/forms.md), [`docs/reference/commands/cookies.md`](../../../docs/reference/commands/cookies.md), [`docs/quick-start/http-form-fill.md`](../../../docs/quick-start/http-form-fill.md).

## After authoring

1. Run `Invoke-PlatformDevLoop.ps1 -SchemaOnly` against the draft. Iterate on schema errors until clean.
2. Cross-reference the chosen pattern's analogous sample. Note any structural divergences and surface them.
3. Hand off to [`safeguard-ps-operations`](../safeguard-ps-operations/SKILL.md) for `-ValidateOnly` and onward. Do not call the appliance from this skill.
4. When the trigger fails, route the task log to [`task-log-analysis`](../task-log-analysis/SKILL.md) — do not jump straight back into editing the JSON without classifying the failure.

