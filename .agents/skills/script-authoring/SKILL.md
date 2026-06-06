---
name: script-authoring
description: >-
  Use when drafting or revising the custom-platform JSON itself. Four
  pattern recipes (ssh-interactive, ssh-batch, http-api, http-form-fill)
  cite schema, samples, and templates and cover Do blocks, status
  messages, custom parameters, and reserved variables. The http-api
  recipe spans every auth shape the API documents — Basic/Digest via
  HttpAuth, or Bearer / custom Authorization scheme / custom-header API
  key via script-built Headers — plus one-step vs two-step token fetch.
  Mandates the fast inner loop: local schema validation against schema/
  before any appliance round-trip. SchemaOnly green is necessary but not
  sufficient — cross-reference samples for analogous patterns before
  declaring ready.
---

# script-authoring

## Pre-flight

Before drafting or revising any platform JSON, consult [`AGENTS.md`](../../../AGENTS.md) for the active workflow algorithm (new-platform vs enhance-platform) and the iterative debug-loop budget. If the operator skipped target probing or strategy selection and went straight to "write me the JSON", surface that — the wrong pattern compiles cleanly but fails on the appliance.

## Scope

Four pattern sub-recipes cover the supported transports:

- [`ssh-interactive`](#ssh-interactive)
- [`ssh-batch`](#ssh-batch)
- [`http-api`](#http-api)
- [`http-form-fill`](#http-form-fill)

Telnet/TN3270 is out of scope for the agent skill system. The recipes below are starting points; pick one based on [`strategy-selection`](../strategy-selection/SKILL.md) output and adapt it.

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

Before declaring a draft "ready to import," cross-reference an analogous sample from `samples-index.md`. If a sample uses a construct your draft does not (e.g., a `Try`/`Catch` around `Disconnect`, a `Receive` flush of the login banner, a `Headers` block before `HttpAuth`), surface that divergence to the operator rather than silently omitting it.

## Conventions all four patterns share

- **Top-level shape.** `Id`, `BackEnd: "Scriptable"`, optional `Meta`, optional `Imports`, then one object per operation (`CheckSystem`, `CheckPassword`, `ChangePassword`, …). Operation objects contain `Parameters` (array of single-key objects) and `Do` (array of command objects). See [`schema/custom-platform-script.schema.json`](../../../schema/custom-platform-script.schema.json) lines 14–80 for the top-level fields, and [`docs/reference/script-structure.md`](../../../docs/reference/script-structure.md) for prose.
- **Reserved parameters** are not declared by the script — SPP injects them. Custom parameters are declared in `Parameters` and addressed as `%Name%`. See [`docs/reference/reserved-parameters.md`](../../../docs/reference/reserved-parameters.md) and [`docs/reference/custom-parameters.md`](../../../docs/reference/custom-parameters.md).
- **Before declaring a custom parameter, grep [`docs/reference/reserved-parameters.md`](../../../docs/reference/reserved-parameters.md) for the concept.** Reserved names like `SkipServerCertValidation`, `UseSsl`, `CheckHostKey`, `HostKey`, `HttpProxyUri`/`Port`/`UserName`/`Password`, and `TacacsSecret` are **auto-sourced from the asset's settings** — declare them in the operation's `Parameters` array exactly like a custom param and SPP populates them at runtime with zero `-CustomScriptParameters` plumbing at onboarding. Inventing a custom name for any of these concepts (e.g. declaring your own `IgnoreCert` Boolean) works in isolation but forces every onboarding operator to remember the override forever. Always prefer the reserved name.
- **Secrets.** Any parameter that holds a credential MUST be `Type: "Secret"` so SPP redacts it in task logs (see the redaction note in [`safeguard-ps-operations`](../safeguard-ps-operations/SKILL.md) and [`tools/README.md`](../../../tools/README.md), "Secret handling"). Use the `::$` modifier (`%FuncPassword::$%`) where the templates and samples do; do not invent a different escape.
- **`Try` / `Catch`.** Wrap fallible operations (network calls, command execution, parses) so a clean `Disconnect` still runs and a structured `Return`/`Throw` is produced. Both [`templates/TemplateSshMinimal.json`](../../../templates/TemplateSshMinimal.json) and [`templates/TemplateHttpMinimal.json`](../../../templates/TemplateHttpMinimal.json) demonstrate this shape end-to-end.
- **Return values.** End each operation with `Return` (typically `%CheckResult%` or a discovery payload). Never let an operation fall off the end of `Do` without a return.
- **Status messages.** Emit them via the supported logging commands (see [`docs/reference/status-messages.md`](../../../docs/reference/status-messages.md)) — they end up in the task log and are how [`task-log-analysis`](../task-log-analysis/SKILL.md) knows how far the script got.

If a `Do`-block construct does not appear in any sample or template, **stop and ask** before adding it. The grounding rule applies inside the JSON, not just around it.

### Bake diagnostics in on the first try

Every appliance round-trip (validate → import → trigger → fetch task log) costs the operator real time. Treat it as the most expensive resource in the loop. Before a trigger, mentally walk through every failure branch the script can take and ask: *if this fails, will the task log tell me **why**, or will I need another iteration to find out?* If the answer is "another iteration", instrument the script before triggering — not after the first failure surprises you.

Concrete rules for any `Send`/`ExecuteCommand` block whose output is parsed:

- **Capture stderr.** Use `2>&1` (combine streams) for shell pipelines whose output you parse. Never `2>/dev/null`. Never bare stdout-only on a command that can fail. The actual diagnostic almost always comes out on stderr.
- **Capture exit codes explicitly.** Prefer `cmd 2>&1; echo MARKER_RC_$?\n` over `cmd && echo OK || echo FAIL`. The numeric code distinguishes auth failure from permission failure from syntax failure without another round trip; the binary OK/FAIL form throws that information away.
- **Suppress sudo's password prompt** with `-S -p ''` when piping a password into sudo. Without `-p ''`, sudo's prompt text leaks into the captured buffer and pollutes the regex / parse logic of whatever command follows.
- **Terminate `Send` buffers with `\n`.** A PTY shell will not execute a typed line until it sees a newline. A `Send` without `\n` causes the next `Receive` to time out (or match echo) — a silent class of bug that costs an entire iteration to diagnose.
- **Echo the parsed buffer back** via `WriteResponseObject` (or the equivalent diagnostic command) so it lands in the task log. Without this, parse-condition failures in `Condition` blocks produce a `Returning false` with no visible reason — another wasted iteration.

### When two iterations fail with the same signature, stop drafting and grep

If iteration N+1 fails with the same classified phase and substantively the same signature as iteration N (same `Status` enum value, same parse failure in the same `Receive`, same regex that did not fire), switch from drafting to sample-mining:

1. Run `grep -rn "<construct>" samples/<protocol>/` for the construct that is failing — `passwd`, `chpasswd`, `Bearer`, `HttpAuth`, `ExtractJsonObject` against a similar response shape, etc.
2. **Read the matching sample's full operation in context**, not just the line that grep returned. The shape around the line — what `Receive` precedes it, which buffer is marked `ContainsSecret`, whether the surrounding command has quotes — is usually what makes the sample work.
3. Port the working shape into the draft as a single change. Trigger. If the new failure is in a different phase, the port worked; iterate from there.

### Function-call signatures: copy from samples, do not infer

When emitting a `Function` call — whether to a locally-defined function, an imported library function, or anything else with a name and `Parameters` array — the agent **must** find at least one working call site for that function in `samples/` and copy the `Parameters` array shape verbatim.

- The call's `Parameters` field is a positional array; calls do not name their arguments. Order matters; arity matters.
- Public prose docs (e.g., [`docs/reference/imports.md`](../../../docs/reference/imports.md)) list library and function names but **deliberately do not document call signatures**. That is not an oversight — the deployed appliance's view of an imported function's arity can drift from any external reference, including the upstream source it was built from. Samples are the only source of call shapes that round-trip through CI against shipped appliances.
- Search the whole `samples/` tree, not just the closest production sample for the active pattern. A function may be imported by several samples in different sub-trees.
- If no sample exercises the call you need, **stop and ask** the operator. The fallback is empirical probing via `Test-SafeguardCustomPlatformScript`: submit a call with a deliberate-arity guess and read the appliance's `expects N parameters` error literally. The appliance is authoritative for its own deployed signature. That probe is a [`safeguard-ps-operations`](../safeguard-ps-operations/SKILL.md) action, not this skill's.
- Do not pad with `""` to match a guessed arity, do not reorder a sample's call to "look more logical," and do not infer a parameter from a function name.

If a sample's call site uses 3 args and another uses 4, that is a real signal: either the function is overloaded, or one of those samples shadows the import with a locally-defined function of the same name. Read the sample's `Imports` and `Functions` blocks before copying — the right call site is the one whose enclosing script imports the same library yours does.

## Pattern recipes

### SSH operations checklist (applies to both ssh-interactive and ssh-batch)

Every SSH platform meant for asset onboarding **must** include a `DiscoverSshHostKey` operation. The appliance classifies a platform as SSH-capable by inspecting its operation set (Hercules runtime check, not the schema) and refuses host-key flows on platforms that lack it — surfaces as `60306: Platform does not support SSH authentication` from `New-SafeguardCustomPlatformAsset`. Copy the shape from [`samples/ssh/generic-linux/GenericLinux.json`](../../../samples/ssh/generic-linux/GenericLinux.json); do not set `SoftwareVersionVariableName` on the command (no on-disk sample does, and the runtime silently fails on it via 60307).

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

#### `CheckPassword` on Linux: pass the whole shadow line to `CompareShadowHash`

The authoritative pattern (matches the Hercules `LinuxSshFunctions.json` import that ships with the appliance) is in [`samples/ssh/generic-linux/GenericLinux.json`](../../../samples/ssh/generic-linux/GenericLinux.json) lines 220–245:

1. `ExecuteCommand`: `sudo -S /usr/bin/getent shadow %AccountUserName%` (batch mode has no PTY, so `-S` is required).
2. Capture the whole stdout buffer into `%AccountEntry%`.
3. `CompareShadowHash` with `SaltedHash: "%AccountEntry%"` — **pass the whole shadow line, not a pre-extracted field**. The component handler splits on `:` and pulls field[1] internally (verified in Hercules `Source/Hercules.WebService/Common/Crypt/PasswordHash.cs` `CheckPasswordAgainstShadowEntry`).
4. `Condition` on `PasswordHashMatched == true` → `Return true`; else `Return false`.
5. Wrap the whole sequence in `Try`/`Catch`; the `Catch` is the **fallback** for environments where `getent` is unavailable (locked-down sudo, no shadow read), not a hash-format workaround.

**Do not pre-split the shadow line in a `SetItem` expression** (`ShadowLine.Split(':')[1]`). Two compounding reasons:

- It is unnecessary — `CompareShadowHash` does the split itself.
- It triggers a Z.Expressions overload-ambiguity error on `string.Split(char)` (catalogued in [`docs/agent-reference/failure-patterns.md`](../../../docs/agent-reference/failure-patterns.md)), and the resulting `Try`/`Catch` fallback emits a sentinel verdict that looks like a target-state mismatch but is really a script bug.

`CompareShadowHash` understands yescrypt (`$y$j9T$…`, default on Ubuntu 22.04+ / Debian 12+), bcrypt, SHA-512, SHA-256, MD5, and AIX SSHA. There is no hash-format reason to abandon it for an auth-by-login primary; auth-by-login is the documented `Catch` fallback only.

Reference: [`docs/guides/ssh-platforms.md`](../../../docs/guides/ssh-platforms.md) ("Batch mode" section), [`docs/reference/commands/execute-command.md`](../../../docs/reference/commands/execute-command.md).

#### Catch blocks must log before falling back

Any `Try`/`Catch` whose `Catch` produces a verdict (rather than re-raising) **must log the caught exception** via `WriteResponseObject` (or a `Status` message that includes the exception text) before emitting the fallback value. Otherwise the next agent reads a clean verdict — `PasswordMismatch`, `false`, `Error` — and attributes it to target state when the actual cause was a script-side bug the catch swallowed. A Z.Expressions overload error in a pre-split `SetItem`, for example, will surface as a bare `PasswordMismatch` unless the catch emits the inner exception text.

### http-api

**Use when** the target exposes a documented HTTP/REST API and the script presents a credential the operator already holds (token, password, API key, anything else).

The script shape is the same regardless of auth scheme: `BaseAddress` → `NewHttpRequest` → (auth setup) → `Request` → `ExtractJsonObject` → `Status`. What varies is two orthogonal choices the recipe makes you spell out: **auth shape** and **one-step vs two-step**.

#### Auth shape — pick a bucket, then a specific scheme

The first decision is *who handles the auth dance*:

| Bucket | What the script does | Auth schemes |
| --- | --- | --- |
| **HttpAuth-managed** | Hand SPP a username/password and an auth `Type`; the runtime builds the header. | `Basic`, `Digest` |
| **Script-managed header** | Build the header value yourself and attach it via `Headers`/`AddHeaders`. | `Authorization: Bearer <token>`, custom `Authorization` schemes (`PVEAPIToken=…`, `Token …`, vendor-specific), custom-header API keys (`X-API-Key`, `X-Vault-Token`, `X-Auth-Token`, …) |

**HttpAuth-managed (Basic, Digest).** Set per-request, not once globally; this matches the existing samples and avoids leaking the service-account credential into requests that should target the managed account.

```jsonc
{ "HttpAuth": {
    "RequestObjectName": "SystemRequest",
    "Type": "Basic",
    "Credentials": { "Login": "%FuncUsername%", "Password": "%FuncPassword%" } } }
```

Closest production sample for Basic: [`samples/http/wordpress/WordPressHttp.json`](../../../samples/http/wordpress/WordPressHttp.json) (lines 33–40, 78–82, 128–132). Starter template: [`templates/Pattern-GenericRestApiBasicAuth.json`](../../../templates/Pattern-GenericRestApiBasicAuth.json). For Digest the shape is identical with `Type: "Digest"`; clean self-hostable Digest targets are rare in 2025, so verify the runtime supports the scheme against the deployed appliance version before committing.

**Script-managed header (Bearer, custom Authorization scheme, custom-header API key).** Use `Headers`/`AddHeaders`, not `HttpAuth`. There is no `HttpAuth` `Type` for arbitrary header shapes.

```jsonc
{ "Headers": {
    "RequestObjectName": "CheckRequest",
    "AddHeaders": {
      "Accept": "application/json",
      "Authorization": "Bearer %AccessToken%" } } }
```

Swap `Authorization: Bearer <token>` for whatever the vendor actually uses. Two common variants:

- **Bearer or custom `Authorization` scheme** (`Authorization: Bearer <token>`, `Authorization: PVEAPIToken=user@realm!tokenid=UUID`, `Authorization: Token …`). Closest production sample: [`samples/http/onelogin-jit/OneLogin_GRC_JIT_addon.json`](../../../samples/http/onelogin-jit/OneLogin_GRC_JIT_addon.json) (Bearer header at lines 1228, 1361, 1510, 1672, 1834, 2002, 2135). Starter template: [`templates/Pattern-GenericRestApiBearerToken.json`](../../../templates/Pattern-GenericRestApiBearerToken.json).
- **Custom-header API key** (`X-API-Key: %ApiKey%`, `X-Vault-Token: %Token%`, `X-Auth-Token: …`). See lines 184–190 of [`templates/Pattern-GenericRestApiKeyRotation.json`](../../../templates/Pattern-GenericRestApiKeyRotation.json). That template also covers the `CheckApiKey` / `ChangeApiKey` operation pair for when the script must rotate the key itself; pair with [`docs/guides/api-key-management.md`](../../../docs/guides/api-key-management.md).

Whichever bucket you're in, declare the credential as `Type: "Secret"` in `Parameters` so SPP redacts it in task logs.

#### One-step vs two-step

Orthogonal to the bucket above:

- **One-step** — the operator already holds the credential the script presents on every operation call. HttpAuth-managed shapes are almost always one-step. Script-managed-header shapes are one-step when the credential is a long-lived API key or PAT.
- **Two-step** — the script POSTs credentials (often HttpAuth-managed `Basic` with client id/secret, sometimes form-encoded) to a token endpoint, parses the response with `ExtractJsonObject` to capture an access token, then attaches that token via script-managed `Headers` on every subsequent operation call. The `samples/http/onelogin-jit/` sample is the canonical example, interleaving `HttpAuth Basic` on the token call (lines 2275–2278) with `Authorization: Bearer %AccessToken%` on the operation calls.

Two-step gotcha: do **not** reuse the same `RequestObjectName` for the token-fetch and the operation calls. The two have different `HttpAuth`/`Headers` configurations and crossing them is a common source of 401s. Build a fresh `NewHttpRequest` for each.

Reference: [`docs/guides/http-platforms.md`](../../../docs/guides/http-platforms.md), [`docs/reference/commands/http-auth.md`](../../../docs/reference/commands/http-auth.md), [`docs/reference/commands/http-setup.md`](../../../docs/reference/commands/http-setup.md), [`docs/reference/commands/request.md`](../../../docs/reference/commands/request.md), [`docs/reference/commands/json.md`](../../../docs/reference/commands/json.md), [`docs/guides/api-key-management.md`](../../../docs/guides/api-key-management.md).

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

