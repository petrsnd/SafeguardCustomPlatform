[← Agent reference](README.md)

# Strategy decision tree (SSH and HTTP)

Backs the `strategy-selection` skill. Maps `(protocol, vendor docs, probe evidence)` to a recommended authoring pattern from the four covered by the `script-authoring` skill:

- `ssh-interactive`
- `ssh-batch`
- `http-api`
- `http-form-fill`

Telnet/TN3270 are out of scope for the agent skill system. The repository's human-facing telnet material remains under `samples/telnet/` and `docs/`.

## Source documents

This table is built from the following repo files. When in doubt, read the source rather than relying on this summary.

| Source | Why it matters |
| --- | --- |
| [`docs/guides/ssh-platforms.md`](../guides/ssh-platforms.md) | Authoritative on the SSH interactive-vs-batch decision and the connection/login patterns. |
| [`docs/guides/http-platforms.md`](../guides/http-platforms.md) | Authoritative on HTTP authentication patterns: Basic, Bearer/OAuth2, API keys in headers, cookie/form-fill. |
| [`docs/guides/ssh-key-management.md`](../guides/ssh-key-management.md) | Disambiguates password vs SSH-key flows when the service-account credential is a key. |
| [`docs/guides/api-key-management.md`](../guides/api-key-management.md) | Disambiguates password vs API-key flows on HTTP targets. |
| [`docs/guides/jit-elevation.md`](../guides/jit-elevation.md) | Operation-shape guidance when the target supports Elevate/Demote rather than (or in addition to) password rotation. |
| [`docs/guides/account-discovery.md`](../guides/account-discovery.md) | Operation-shape guidance when discovery is required. |
| [`docs/reference/imports.md`](../reference/imports.md) | Lists the system import libraries Safeguard provides. The decision below influences which imports the script will pull in. |
| [`samples-index.md`](samples-index.md) | Concrete starting points keyed by protocol and auth-scheme. |

## Top-level decision

| Question | If yes | If no |
| --- | --- | --- |
| Does the target system expose a documented HTTP/REST API for the operations the agent must implement? | Use an HTTP pattern. Continue at [HTTP branch](#http-branch). | Use an SSH pattern. Continue at [SSH branch](#ssh-branch). |

If the target exposes both a CLI/SSH path and an HTTP API, **prefer HTTP** when the API covers the required operations end-to-end without shell access. APIs tend to produce stabler scripts than shell-prompt scraping. Surface this trade-off to the user before committing if both paths look viable.

## SSH branch

Reference: [`docs/guides/ssh-platforms.md` § Choosing an SSH pattern](../guides/ssh-platforms.md#choosing-an-ssh-pattern).

| Probe / vendor evidence | Recommended pattern | Notes |
| --- | --- | --- |
| The target accepts `ssh user@host '<command>'`-style remote command execution and returns stdout/stderr/exit-code cleanly; no PTY needed. | `ssh-batch` | Set `RequestTerminal: false`. Capture `BufferName`, `StderrBufferName`, `ExitStatusBufferName`. See `samples/ssh/linux-ssh-batch-mode/` and `samples/ssh/restricted-authorized-key/`. |
| The target presents a shell prompt, banner, or an appliance CLI menu; password change goes through `passwd` with interactive prompts; sudo prompts may appear. | `ssh-interactive` | Use `Connect` + `Send` + `Receive` + `Disconnect`, `RequestTerminal: true`. Flush banners; use unique markers (e.g., `INIT_CHECK=$?`). See `samples/ssh/generic-linux/`. |
| Mixed: the agent needs interactive flow for password change but plain `ExecuteCommand` for discovery. | `ssh-interactive` for the interactive operations, `ssh-batch` shape inside discovery operations. | Mixed scripts exist (see operations column in `samples-index.md`). Keep `Connect`/`Disconnect` consistent per operation. |

### SSH credential intent

| Service-account credential kind (declared by operator) | Influence on pattern |
| --- | --- |
| Password | Either `ssh-interactive` or `ssh-batch` is fine; choose by prompt behavior above. |
| SSH key | Pass `UserKey` on `Connect`. Often pairs with `ssh-batch`. See `samples/ssh/restricted-authorized-key/` and [`docs/guides/ssh-key-management.md`](../guides/ssh-key-management.md). |

### When to ask vs decide (SSH)

- **Ask** if the target's prompt style cannot be observed (probe-only mode without console output, or operator hasn't run a probe yet).
- **Ask** if the operator has not stated whether the seed is password or SSH key.
- **Decide** if probe evidence directly shows interactive prompts (→ `ssh-interactive`) or clean `ExecuteCommand` behavior (→ `ssh-batch`).

## HTTP branch

Reference: [`docs/guides/http-platforms.md` § Authentication patterns](../guides/http-platforms.md#authentication-patterns).

| Probe / vendor evidence | Recommended pattern | Notes |
| --- | --- | --- |
| Vendor docs describe a documented HTTP/REST API for the operations the script must implement, regardless of auth scheme. | `http-api` | Pick auth shape from the sub-table below. See `samples/http/` and templates `Pattern-GenericRestApiBasicAuth.json`, `Pattern-GenericRestApiBearerToken.json`, `Pattern-GenericRestApiKeyRotation.json`. |
| The target only has an HTML login form (no API), the operator can provide credentials, and operations work by submitting forms. | `http-form-fill` | Use `ExtractFormData` to walk the form, `Request` with `application/x-www-form-urlencoded`, and rely on default cookie persistence. See `samples/http/facebook/` and `samples/http/twitter/`. |

### `http-api` auth shape

Pick a bucket, then a specific scheme. The bucket determines whether the script uses `HttpAuth` or builds the header itself via `Headers`/`AddHeaders`.

| Probe / vendor evidence | Bucket | Scheme | Notes |
| --- | --- | --- | --- |
| `WWW-Authenticate: Basic …` response, or vendor docs describe HTTP Basic on every call. | HttpAuth-managed | `Basic` | `HttpAuth` `Type: "Basic"` per request. See `samples/http/wordpress/`. |
| Vendor docs describe HTTP Digest. | HttpAuth-managed | `Digest` | Same shape as Basic with `Type: "Digest"`. Rare in modern self-hosted products; verify the runtime supports the scheme. |
| Vendor docs or probe evidence show `Authorization: Bearer …` on operation calls. | Script-managed header | `Bearer` | `Headers.AddHeaders` with `Authorization: Bearer %Token%`. See `samples/http/onelogin-jit/`. |
| Vendor docs show a custom `Authorization` scheme such as `PVEAPIToken=…` (Proxmox token-auth path), `Token …`, or other vendor-specific prefix. | Script-managed header | Custom `Authorization` scheme | Same as Bearer but with the vendor's scheme name. Treat as Bearer-shaped for authoring purposes. |
| Vendor docs describe a static API key passed in a custom header (e.g., `X-API-Key`, `X-Vault-Token`, `X-Auth-Token`). | Script-managed header | Custom-header API key | `Headers.AddHeaders` with the named header. Pair with [`docs/guides/api-key-management.md`](../guides/api-key-management.md) when the same script must rotate the key. |
| Vendor docs describe a session-cookie auth flow: a login endpoint returns an opaque session token that is then sent back as a `Cookie:` header on every subsequent call (often paired with a secondary CSRF/XSRF header on write verbs). The Proxmox VE **ticket-cookie** path is canonical — `POST /access/ticket` returns `data.ticket` and `data.CSRFPreventionToken`; subsequent calls send `Cookie: PVEAuthCookie=<ticket>` and write calls additionally send `CSRFPreventionToken: <token>`. See [`samples/http/proxmox-ve-http/`](../../samples/http/proxmox-ve-http/). | Script-managed header | Session cookie (+ CSRF header on writes) | Two-step by definition (the cookie is fetched, not pre-held). `Headers.AddHeaders` with `Cookie: <name>=%Token%` on every call; add the CSRF header on writes only. Form bodies for the login post **must** use `SetFormValue` + `Request.Content.ContentObjectName` — pre-built body strings via `Request.Content.Value` re-encode unpredictably (see `failure-patterns.md`). Beware native-cookie-jar interactions: if you also set `PersistCookies: true` (default), the engine may inject a session cookie from a prior call alongside the script-set `Cookie` header — pick one mechanism and stick to it. |

### `http-api` one-step vs two-step

Orthogonal to the bucket above:

| Probe / vendor evidence | One-step or two-step | Notes |
| --- | --- | --- |
| The operator already holds the credential the script presents on every call (long-lived API key, static PAT, root API token). | One-step | Apply auth shape directly on the operation request. |
| Vendor docs describe a token endpoint that exchanges credentials for a short-lived access token (OAuth2 client_credentials, login + token endpoints). | Two-step | POST to the token endpoint (often HttpAuth-managed `Basic` with client id/secret, sometimes form-encoded), `ExtractJsonObject` to capture the token, then attach via script-managed `Headers` on operation calls. Do **not** reuse the same `RequestObjectName` for token-fetch and operation calls. |

### HTTP credential intent

| Service-account credential kind | Influence on pattern |
| --- | --- |
| Password | Likely `http-api` with HttpAuth-managed `Basic`/`Digest`, or `http-form-fill` if there's no API. If the API documents a token endpoint that exchanges a password for a token, that is `http-api` two-step Bearer. |
| API key | Likely `http-api` with script-managed-header — the specific scheme depends on whether the vendor uses `Authorization` (Bearer-shaped) or a custom header. Unless the API explicitly accepts the key as a Bearer token, pick by what vendor docs say verbatim. |
| Bearer token (operator already holds) | `http-api` one-step Bearer. Consider whether the script should refresh; if not, document the assumption. |

### When to ask vs decide (HTTP)

- **Ask** if no vendor documentation has been supplied (URL or pasted excerpt) and probe evidence is ambiguous.
- **Ask** if the API supports multiple schemes and the choice has security implications (e.g., Basic vs Bearer when both are documented).
- **Decide** when vendor docs explicitly call out one scheme and probe evidence (auth-scheme detection, redirect chain) corroborates it.

## Self-managed vs service-account

This dimension is orthogonal to the patterns above and influences which operations the script must implement, not which transport pattern to use.

| Mode | Symptom | Implication |
| --- | --- | --- |
| Self-managed | The managed account can change its own credential (e.g., `passwd` for the same user, `PATCH /me`). | `ChangePassword` uses `%FuncUserName%`/`%FuncPassword%` directly; no separate service account. |
| Service-account | A privileged service account changes the managed account's credential (e.g., `chpasswd` as root, `PATCH /users/{id}` as admin). | The script needs both the managed account context and the service-account context; `LoginSsh`/`LogoutSsh` may run as the service account. |

Decide based on vendor docs and probe evidence, not assumption. When in doubt, ask the operator which mode the deployment will use.

## Vendor documentation inputs

`strategy-selection` accepts both fetched URLs and vendor-doc excerpts pasted into the conversation. See [`vendor-doc-search-recipes.md`](vendor-doc-search-recipes.md) for query templates and the normalization recipe.
