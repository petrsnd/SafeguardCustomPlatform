---
name: target-probing
description: >-
  Use when the agent must learn how a live target system actually behaves
  before authoring or revising a custom platform script. Covers per-protocol
  recon recipes (SSH and HTTP) run from the operator's local shell with a
  seed credential, the probe-safety contract (read-only by default,
  per-probe consent for destructive probes, rate limits, no-production
  guard), and the structured evidence artifact consumed by
  strategy-selection and script-authoring.
---

# target-probing

## Pre-flight

Before running any probe, consult [`AGENTS.md`](../../../AGENTS.md) for the active workflow algorithm and the iterative debug-loop budget. Probing happens once per workflow at the start (or when prior assumptions have been invalidated). It is not a free retry mechanism.

## Scope

Local-shell recon recipes against a live target with a seed credential. SSH and HTTP only — telnet/TN3270 is out of scope (`agent-skills-plan.md` §2). Probing produces a structured **evidence artifact** that conforms to [`.agents/schemas/evidence.schema.json`](../../../.agents/schemas/evidence.schema.json) and is consumed by [`strategy-selection`](../strategy-selection/SKILL.md) and [`script-authoring`](../script-authoring/SKILL.md).

This skill calls `ssh`, `curl`/`Invoke-WebRequest`, etc. directly from the operator's machine. It does **not** mediate probes through SPP.

## Modes

- **probe-only**, **full-loop** — operational.
- **author-only** — fails closed. There is no offline form of probing.

## Probe-safety contract (mandatory)

All six items below are non-negotiable. They restate `agent-skills-plan.md` §5 in skill-local form so the agent enforces them at execution time, not just at planning time.

1. **Read-only by default.** Probes that only observe — banner grab, `WWW-Authenticate` header inspection, `whoami`, `id`, `uname`, GET on a documented API endpoint, login-form HTML inspection — run without per-probe confirmation.
2. **Destructive probes require explicit per-probe operator opt-in.** Any probe that mutates target state — password change/rotation, key install, account create/delete, sudo escalation that writes, POST/PUT/DELETE against undocumented endpoints — is presented to the operator with a one-line *"what this will do, what could go wrong"* summary and proceeds only on explicit consent. Consent is **per probe, not per session**. Record the consent timestamp and the summary that was shown in the evidence artifact (`probeRecord.consent.grantedAt`, `probeRecord.consent.summaryShown` — see [`.agents/schemas/evidence.schema.json`](../../../.agents/schemas/evidence.schema.json) lines 173–188).
3. **Rate limits.** Hard cap of 3 authentication attempts per minute per target. Back off on any auth failure rather than retrying. The cap exists to avoid tripping account-lockout policies and IDS, not as a guideline to be ignored when "just one more try" looks productive.
4. **No production targets.** This skill refuses to run if the operator has not affirmed the target is non-production. The affirmation is captured as `target.nonProductionAffirmed: true` in the evidence artifact (schema line 40). The affirmation is a soft control: it places responsibility on the operator. The agent does not (and cannot) independently verify environment classification.
5. **Pre-flight echo.** Before the first probe of a session, print the planned probe sequence, the seed account name (not the secret), and the target host, and wait for an explicit "go" from the operator.
6. **Fail-closed on lockout / throttle / MFA signals.** If any probe response indicates lockout, throttling, or MFA challenge, stop probing immediately and surface to the operator. Do not continue down the playbook. Record `probeRun.haltedReason` accordingly (`lockout-signal | throttle-signal | mfa-challenge | rate-limit-exceeded | operator-stop | operator-denied-destructive | error`; enum at schema lines 92–103).

If the agent cannot satisfy any of the six items, it stops and asks. Bypassing the contract is never acceptable, even when the operator nominally consents to skip it — the contract exists precisely to catch the consequences of "this will be fine" decisions.

## Evidence artifact

Every probing session produces one evidence artifact, conforming to [`.agents/schemas/evidence.schema.json`](../../../.agents/schemas/evidence.schema.json). Required fields: `schemaVersion` (`"0.1"`), `protocol` (`ssh` or `http`), `target` (with `host` and `nonProductionAffirmed`), `seed` (account name and `credentialKind` — never the secret), and `probeRun` (with `startedAt` and an ordered `probes` array).

**Secrets never appear in evidence.** The `seed.accountName` field is required; there is no field for the secret. `probeRecord.command` substitutes a placeholder for any credential. This is enforced by the schema's `additionalProperties: false` at the top level — invented secret-bearing fields fail validation.

Protocol-specific findings live under `sshFindings` or `httpFindings`. The v0 schema marks the internal shapes of these as TODO and intentionally permissive; this skill is the first consumer to populate them. When the playbooks below settle on a final shape, propose a schema bump as a follow-up — do not silently invent fields the schema rejects.

`strategyHints` is optional. Use it sparingly: it signals to `strategy-selection` that probing strongly favours one of the six authoring patterns. The `rationale` must cite a specific `probeRecord.id`, not a generic statement.

## Pre-flight echo template

Before the first probe of a session, print and wait for "go":

```
Target:        <host>[:<port>]
Protocol:      <ssh | http>
Seed account:  <accountName>           (secret not echoed)
Non-production: <yes / NOT AFFIRMED>
Planned probes (in order):
  1. <category> — <one-line description> — <read-only | destructive>
  2. ...
```

If `nonProductionAffirmed` is not yet true, the echo block stops at that line and asks the operator to affirm. Do not proceed without the affirmation.

## SSH playbook

Categories the playbook covers, all `read-only` by default. Each maps to a `probeRecord.category` value (schema line 156–167) and contributes to `sshFindings` (schema lines 206–231).

### `prompt` — what does the shell look like?

`ssh -o StrictHostKeyChecking=accept-new <user>@<host>` and observe:

- The login banner / motd (free text before the first prompt). Captured into `sshFindings.shellPrompt`.
- The shell prompt format (`$`, `#`, vendor menu, custom PS1). The prompt format dictates the `Receive` regex shape in `ssh-interactive`.
- Whether a banner runs *between* connect and the prompt — that affects whether the script needs an initial banner-flushing `Receive`.

### `batch-mode` — does `ExecuteCommand`-style work?

`ssh <user>@<host> 'echo OK; id'` and check whether stdout returns cleanly without a PTY. If yes, `ssh-batch` is viable; if the target rejects it (`PTY allocation request failed`, vendor CLI that requires a terminal), only `ssh-interactive` is viable. Captured into `sshFindings.batchModeSupported`.

### `sudo` — escalation behavior

Read-only probes only: `sudo -n true` (does not prompt) and `sudo -l` (lists permissions). Captured into `sshFindings.sudoBehavior`.

A probe that runs a privileged command (`sudo something-that-mutates`) is **destructive** and requires per-probe consent.

### `password-change` — which command path?

Read-only: which password-change tooling is available (`which passwd chpasswd`), and whether the account is self-managed vs service-managed. Identifying the tool is read-only; **actually changing a password is destructive**.

When the operator opts in to a destructive password-change probe, present the one-line summary explicitly: *"This will rotate the seed account password to a new value; the operator must capture the new value or the account will become unrecoverable from this agent."*

Captured into `sshFindings.passwordChangeCommand`.

## HTTP playbook

Categories, all `read-only` by default. Each maps to a `probeRecord.category` value (schema lines 156–167) and contributes to `httpFindings` (schema lines 233–258).

### `auth-scheme` — what does the server want?

`curl -i <baseUrl>/<known-protected-endpoint>` (without credentials) and inspect:

- Status code (typically 401 for API endpoints, 30x with `Location: /login` for form-fill targets).
- `WWW-Authenticate` header — distinguishes Basic from Bearer/OAuth-style challenges.
- Body content type (JSON error vs HTML login page).

Captured into `httpFindings.authScheme`.

### `login-form` — when there is no API

GET the login page and read the rendered HTML. Extract: form `action` URL, field names (username/password and any hidden fields), CSRF tokens, redirect chain on submission. Read-only; does not require credentials. Captured into `httpFindings.loginForm`.

### `cookie` — session shape

GET → POST a single round-trip with the seed credential (still subject to the rate limit), inspect the `Set-Cookie` headers and whether subsequent calls succeed without re-auth. The `POST` to a login endpoint is read-only by intent — it does not mutate target state in the sense the contract guards against — but it counts toward the auth-attempt rate cap. Captured into `httpFindings.cookieBehavior`.

### `api-discovery` — what endpoints exist?

GET against documented endpoints from vendor docs (see [`docs/agent-reference/vendor-doc-search-recipes.md`](../../../docs/agent-reference/vendor-doc-search-recipes.md)) for user lookup, password change, key rotation. Confirm the operations the script will need actually exist and what they require.

Do **not** speculatively POST/PUT/DELETE against undocumented endpoints — that is destructive (see contract item 2). Captured into `httpFindings.apiDiscovery`.

## Halt signals

The skill stops probing and sets `probeRun.haltedReason` (schema lines 92–103) when any of these occur:

- HTTP `429 Too Many Requests`, vendor-specific throttle headers (`Retry-After`, `X-RateLimit-Remaining: 0`).
- Lockout indicators: HTTP `423 Locked`, body text matching `account locked`/`account disabled`, SSH connection close immediately after username.
- MFA challenges: HTTP body containing a one-time-password prompt, SSH server prompting for `Verification code:` after the password.
- Operator says stop.

After a halt, the agent does not retry the same probe. It surfaces the halt to the operator and waits for guidance.

## Output handoff

When probing concludes:

1. Validate the evidence artifact against [`.agents/schemas/evidence.schema.json`](../../../.agents/schemas/evidence.schema.json) before handing it off (any JSON Schema validator works; the schema is draft-07).
2. Pass the artifact to [`strategy-selection`](../strategy-selection/SKILL.md). That skill is the next stop, not `script-authoring` — pattern selection happens with vendor docs + evidence in one place, not piecemeal.
3. Save the artifact alongside the workflow's other working files so a future iteration can re-read it without re-probing.

