# OpenBSD custom platform

Tested against **OpenBSD 7.9 amd64** with `sshd(8)` and `doas(1)` in their default configurations.

## Operations

| Operation | Notes |
| --- | --- |
| `CheckSystem` | Verifies the service account can read `/etc/master.passwd` via `doas`. |
| `CheckPassword` | Reads the bcrypt hash field from `/etc/master.passwd` (root-only via `doas`), then verifies with `ComparePasswordHash`. |
| `ChangePassword` | Runs `doas passwd <user>`; the script handles the doas prompt, then `New password:` and `Retype new password:`. |
| `DiscoverAccounts` | Enumerates non-system users from `/etc/passwd` (uid >= 1000, uid < 60000). |
| `DiscoverSshHostKey` | Standard SSH host-key discovery. |

## Service-account requirements

- A local UNIX account (any name) with `doas` permission to run `passwd` and read `/etc/master.passwd` as root.
- Minimal `/etc/doas.conf` that works:

  ```
  permit persist :wheel
  ```

  Add the service-account user to the `wheel` group. The `persist` keyword caches authentication for ~5 minutes, which lets the script run multiple `doas` calls without re-prompting.

- For a tighter, password-less variant restricted to the operations Safeguard needs:

  ```
  permit nopass <svcacct> cmd passwd
  permit nopass <svcacct> cmd grep args ^[^:]*: /etc/master.passwd
  ```

## OpenBSD-specific divergences from `samples/ssh/generic-linux-with-discovery`

The script is derived from `GenericLinuxWithDiscovery` with these adaptations:

| What | Why |
| --- | --- |
| `DelegationPrefix` default is `doas` (not `sudo`). | OpenBSD ships `doas`; `sudo` is not installed by default. |
| Prompt regex is `doas\s+\([^)]+\)\s+password:` everywhere. | doas prints `doas (user@host) password:`. `SUDO_PROMPT` env var has no effect on doas. |
| Password hash is read from `/etc/master.passwd` (not `/etc/shadow`). | BSDs store hashes in `master.passwd`; `/etc/passwd` only contains a `*` placeholder. |
| Hash field is extracted via `cut -d: -f2` and matched with a `\$[0-9a-z]+\$[^\s]+` regex, then passed to `ComparePasswordHash`. | OpenBSD uses bcrypt (`$2b$...`); `master.passwd` has a different column layout than Linux shadow, so `CompareShadowHash`'s built-in extraction does not apply. |
| `ChangeUserPassword` has no "current password" branch. | `doas passwd <user>` runs as root and never prompts for the user's existing password. |
| Discovery filter is `uid>=1000 && uid<60000` (not the generic `^[^:#]` line filter). | OpenBSD system users use uids below 1000; `nobody` is uid 32767. Filter still surfaces `nobody` — narrow further with a shell filter (e.g. `$7 !~ /nologin/`) if undesired. |
| `SetUpEnvironment` no longer exports `SUDO_PROMPT`. | doas ignores it. |

## Verified iteration

Built and tested end-to-end on `OpenBSD 7.9 GENERIC#399 amd64`. All four operations passed on the first import; no debug iterations were needed.
