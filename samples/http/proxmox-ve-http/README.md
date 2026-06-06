[← HTTP Samples](../README.md)

# Proxmox VE Password Management (Ticket-Cookie + CSRF API)

This sample manages Proxmox VE user passwords through the Proxmox REST API using the ticket-cookie authentication flow. A privileged service account in the `@pve` realm rotates another `@pve` user's password via `PUT /access/password`, paired with a CSRF prevention token on write operations.

**Platform Script:** [`ProxmoxVE-HTTP.json`](./ProxmoxVE-HTTP.json)

## Target System

Proxmox VE 7.x and 8.x clusters or single nodes, managed via the REST API on port 8006 (default). Only users in the **`@pve` realm** (Proxmox-internal authentication) are supported; see [Limitations](#limitations).

## Operations Implemented

| Operation | Description |
| --- | --- |
| `CheckSystem` | Authenticates the service account, then `GET /api2/json/version` to confirm connectivity and that the held ticket is valid. |
| `CheckPassword` | Calls `POST /api2/json/access/ticket` *as the managed account* with the SPP-held credentials. A successful login (HTTP 200 with a ticket in the response envelope) confirms the password matches. |
| `ChangePassword` | Authenticates the service account, then `PUT /api2/json/access/password` with `userid=<managed account>`, `password=<new password>`, and `confirmation-password=<service-account password>`. The CSRF prevention token is sent in the `CSRFPreventionToken` header. |

## Prerequisites

- A Proxmox VE node reachable from SPP on port 8006 (or whatever port the asset specifies)
- A service account in the `@pve` realm:
  - For **service-account mode** (one account rotating another): the service account needs `Realm.AllocateUser` on `/access/realm/pve` — the built-in `PVEUserAdmin` role grants this. The standard `User.Modify` privilege alone is **not** sufficient for cross-user password changes via the API.
  - For **self-managed mode** (the account rotates its own password): no special privilege is required — Proxmox always allows users to change their own password.
- Managed user accounts must also live in the `@pve` realm.

## Deployment

1. Upload the script: `Import-SafeguardCustomPlatformScript -FilePath ./ProxmoxVE-HTTP.json`
2. Create a custom platform using this script. Display name is the operator's choice (e.g. `Proxmox VE`).
3. Create an asset using the platform with:
   - `NetworkAddress`: hostname or IP of the Proxmox node (e.g. `pve01.lab.local` or `172.17.117.52`)
   - `Port`: `8006` (default) or your configured port
   - `VerifySslCertificate`: set to `false` for clusters using the auto-generated self-signed cluster CA cert. The script reads this via the reserved `SkipServerCertValidation` parameter — no per-operation override is needed.
4. Configure the service account: a `@pve` user whose name in SPP includes the realm suffix (e.g. `svc-pve@pve`).
5. Add managed accounts: each as a `@pve` user (e.g. `pveuser1@pve`).
6. Test with `Test-SafeguardAssetAccountPassword -ExtendedLogging`.

## How It Works

The script uses Proxmox's ticket-cookie authentication flow, which is a two-step pattern:

1. **Login** (`POST /api2/json/access/ticket`): the script sends `username=<service-account>@pve&password=<service-account-password>` as `application/x-www-form-urlencoded`. The response envelope is `{"data":{"ticket":"PVE:...","CSRFPreventionToken":"...","username":"..."}}`. Both values are extracted to script variables.
2. **Subsequent calls** send `Cookie: PVEAuthCookie=<ticket>` on every request. Write verbs (POST, PUT, DELETE) additionally send `CSRFPreventionToken: <token>` as a header — Proxmox rejects writes without it even with a valid ticket.

`CheckPassword` is implemented by authenticating *as the managed account directly* — a successful ticket response proves the password works. The script does not call the service account during `CheckPassword`.

`ChangePassword` requires a wrinkle the Proxmox REST docs don't emphasize: **cross-user password changes require the `confirmation-password` form field**, set to the caller's (service account's) own password. Without it the API returns `401 Unauthorized`. Same-user changes do not need it, but this script always operates cross-user.

Form bodies are built via the `SetFormValue` component (one per field) and attached via `Request.Content.ContentObjectName`. The undocumented `Request.Content.Value` field is **not** used — it double-encodes URL-escaped characters and corrupts the body.

## Parameters

- `Address` (reserved): asset `NetworkAddress`. Required.
- `Port` (reserved): TCP port. Default `8006`.
- `Timeout` (reserved): per-request timeout in seconds. Default `30`.
- `SkipServerCertValidation` (reserved): when `true`, the script passes `IgnoreServerCertAuthentication: true` to every `Request` block. Auto-sourced from the asset's `VerifySslCertificate` flag (inverted) — operators toggle the asset setting, not a custom parameter.
- `FuncUserName` (reserved): service-account name including realm suffix (e.g. `svc-pve@pve`). Auto-sourced from `Asset.ServiceAccount.Name`.
- `FuncPassword` (reserved, Secret): service-account password. Auto-sourced from the vault.
- `AccountUserName` (reserved): managed-account name including realm suffix (e.g. `pveuser1@pve`).
- `AccountPassword` (reserved, Secret): current managed-account password (used by `CheckPassword`).
- `NewPassword` (reserved, Secret): SPP-generated new password (used by `ChangePassword`).

No custom parameters. The full credential set comes from reserved parameters auto-bound by SPP.

## Limitations

- **`@pve` realm only.** Users in `@pam` (the host's OS PAM stack) cannot be rotated via the Proxmox API regardless of API-level privileges — the Proxmox API call returns an error directing the caller to use `passwd` on the host. Rotating `@pam` users requires SSH-to-the-host + `sudo passwd <user>`, which is a separate platform (not yet shipped).
- **Both self-managed and service-account modes are tested live against an appliance.** In service-account mode a privileged user (e.g. holding `PVEUserAdmin` on `/access/realm/pve`) rotates another `@pve` user's password. In self-managed mode the account rotates its own password; Proxmox always allows users to change their own password, so the `Realm.AllocateUser` privilege requirement does not apply. The same script handles both — SPP supplies the credentials such that `%FuncUserName%`/`%FuncPassword%` and `%AccountUserName%`/`%AccountPassword%` resolve to the same identity in self-managed mode, and the API accepts the `confirmation-password` field as benign on a same-user change.
- **Ticket lifetime is ~2 hours.** Each operation fetches a fresh ticket; the script does not persist tickets across SPP operations. Self-rotation invalidates the ticket held during the change, but since the next operation re-authenticates, this is not observable.
- **`401 Unauthorized` responses do not carry `WWW-Authenticate`.** Proxmox does not advertise the auth scheme on failure, which means generic HTTP debugging tools may misclassify the failure mode. The script does not rely on the header.
- **No support for `DiscoverAccounts`.** The script does not enumerate Proxmox users; the operator adds managed accounts explicitly.
- **No API token support.** Proxmox also offers token-based auth (`Authorization: PVEAPIToken=user@realm!tokenid=UUID`). That is a different sample and not implemented here.

## Related

- [HTTP Platforms Guide](../../../docs/guides/http-platforms.md)
- [Commands: Request](../../../docs/reference/commands/request.md)
- [Commands: Forms (`SetFormValue`)](../../../docs/reference/commands/forms.md)
- [Reserved Parameters](../../../docs/reference/reserved-parameters.md)
- [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/) (external)
