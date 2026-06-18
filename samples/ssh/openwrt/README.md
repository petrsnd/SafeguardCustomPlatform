[← SSH Samples](../README.md)

# OpenWrt (dropbear / BusyBox)

This sample manages local accounts on [OpenWrt](https://openwrt.org/) routers and embedded
devices over SSH. OpenWrt ships a [dropbear](https://matt.ucc.asn.au/dropbear/dropbear.html)
SSH server and a [BusyBox](https://busybox.net/) `ash` shell, so the login flow, `passwd`
prompts, and authorized-key store all differ from a standard OpenSSH/bash host. It supports
password check/change and the full SSH authorized-key lifecycle for the managed account.

**Platform Script:** [`OpenWrtSsh.json`](./OpenWrtSsh.json)

## Target System

An OpenWrt host (tested against OpenWrt 25.12.x) reachable over SSH with `root` login enabled
(`config dropbear` option `RootPasswordAuth 'on'`). The managed account is typically `root`,
which on OpenWrt is the single privileged local account.

## Operations Implemented

| Operation | Description |
| --- | --- |
| `CheckSystem` | Verifies the service account can log in and read `/etc/shadow`. |
| `CheckPassword` | Validates a managed-account password against its `/etc/shadow` hash. |
| `ChangePassword` | Changes the managed-account password with BusyBox interactive `passwd`. |
| `CheckSshKey` | Reports whether `OldSshKey` is installed in the dropbear authorized-keys store. |
| `ChangeSshKey` | Installs `NewSshKey`, optionally tests `NewSshPrivateKey`, then removes `OldSshKey`. |
| `DiscoverAuthorizedKeys` | Reads the dropbear authorized-keys file and emits discovered SSH keys. |
| `DiscoverSshHostKey` | Retrieves the SSH host key for the target asset. |

## OpenWrt / BusyBox differences from the generic Linux samples

This script is derived from [`generic-linux-ssh-keys`](../generic-linux-ssh-keys/) with the
following adaptations:

- **No `sudo`.** OpenWrt has no `sudo` by default and the managed account is `root`, so the
  `DelegationPrefix` parameter defaults to empty and every reference uses the null-safe form
  `%DelegationPrefix::$%` (a bare `%DelegationPrefix%` throws `VariableIsNullException` when
  the value is empty/null).
- **BusyBox `passwd` prompts.** Running `passwd` as `root` prompts `New password:` then
  `Retype password:` (not `Retype new password:`) and never asks for the current password.
  The `ChangeUserPassword` send/receive sequence matches these prompts.
- **dropbear authorized-keys path.** Keys live in `/etc/dropbear/authorized_keys` (file mode
  `600`, directory mode `700`), not `~/.ssh/authorized_keys`. `DiscoverSshKeyConfiguration`
  hardcodes this path instead of probing `sshd -T -C`, which dropbear does not provide.
- **`grep -E`** is used in place of GNU `egrep`, and `stty` is not present on BusyBox (the
  shell-init `stty -echo` is best-effort and its absence is harmless).

## Prerequisites

- An OpenWrt host reachable over SSH with root password authentication enabled
- A service account (`root`) that can read `/etc/shadow` and write `/etc/dropbear/authorized_keys`
- For key operations: managed accounts whose keys are stored in `/etc/dropbear/authorized_keys`

## Deployment

1. Upload the script: `Import-SafeguardCustomPlatformScript -FilePath ./OpenWrtSsh.json`
2. Create a custom platform using this script
3. Create an asset using the platform (accept the SSH host key)
4. Configure the service account and managed account (`root`)
5. Test with `Test-SafeguardAssetAccountPassword -ExtendedLogging`

## Parameters

- `OldSshKey` — Existing public key to verify or remove
- `NewSshKey` — New public key to install
- `NewSshPrivateKey` — Optional private key used to test the newly installed public key
- `DelegationPrefix` — Privilege-elevation command; defaults to empty on OpenWrt
- `UserKey` — Optional SSH private key for the service-account login

## Limitations

- Targets the dropbear authorized-keys store (`/etc/dropbear/authorized_keys`) only; does not
  support OpenSSH `AuthorizedKeysFile` template resolution
- Does not implement a standalone `RemoveAuthorizedKey` operation
- Key parsing is limited to the key types handled in `ParseKey`
- Assumes the managed account can read `/etc/shadow` directly (root, no delegation)

## Related

- [SSH Key Management Guide](../../../docs/guides/ssh-key-management.md)
- [SSH Platforms Guide](../../../docs/guides/ssh-platforms.md)
- [generic-linux-ssh-keys](../generic-linux-ssh-keys/) — the OpenSSH/bash base this sample adapts
- [SPP Compatibility Matrix](../../../docs/reference/compatibility.md)
