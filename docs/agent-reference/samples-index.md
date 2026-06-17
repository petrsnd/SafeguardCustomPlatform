[← Agent reference](README.md)

# Samples and templates index

**Generated file. Do not edit by hand.** Regenerate with:

```powershell
./tools/Build-SamplesIndex.ps1
```

CI runs the same script with `-CheckOnly` and fails the build if the committed copy differs.

## Conventions

- **protocol** — derived from the directory (`samples/ssh/`, `samples/http/`) or the template filename (`Pattern-GenericLinux*` / `Pattern-WindowsSsh*` / `TemplateSsh*` → ssh; `Pattern-GenericHttp*` / `Pattern-GenericRestApi*` / `TemplateHttp*` → http).
- **auth-scheme** — best-effort from JSON content. HTTP: from `HttpAuth.Type`, an `Authorization: Bearer` header, an API-key-shaped custom header, or `ExtractFormData`. SSH: `Interactive` (Send/Receive), `Batch` (ExecuteCommand), or `Mixed`. Blank when undetermined.
- **operations** — intersection of top-level keys with the canonical operation list from `schema/custom-platform-script.schema.json`. Imports and user-defined functions never appear here.
- **OS-family** — intentionally blank. The build script prefers blank over guessed values; revisit once a reliable detection heuristic exists.
- **file-path** and **README** — filesystem facts. `—` means the field could not be determined.
- `samples/telnet/` is excluded — telnet is out of scope for the agent skill system. The samples remain in the repo for human reference.

## Samples

| protocol | auth-scheme | operations | OS-family | file-path | README |
| --- | --- | --- | --- | --- | --- |
| http | Form | CheckPassword, ChangePassword | — | [`samples/http/facebook/CustomFacebook.json`](../../samples/http/facebook/CustomFacebook.json) | [README](../../samples/http/facebook/README.md) |
| http | — | CheckSystem, CheckPassword, ChangePassword | — | [`samples/http/forgerock-openam/Forgerock_OpenAM.json`](../../samples/http/forgerock-openam/Forgerock_OpenAM.json) | [README](../../samples/http/forgerock-openam/README.md) |
| http | — | CheckSystem, CheckPassword, ChangePassword, EnableAccount, DisableAccount, DiscoverAccounts | — | [`samples/http/okta-discovery/Okta_WithDiscoveryAndGroupMembershipRestore.json`](../../samples/http/okta-discovery/Okta_WithDiscoveryAndGroupMembershipRestore.json) | [README](../../samples/http/okta-discovery/README.md) |
| http | Basic+Bearer | CheckSystem, ChangePassword, EnableAccount, DisableAccount, ElevateAccount, DemoteAccount | — | [`samples/http/onelogin-jit/OneLogin_GRC_JIT_addon.json`](../../samples/http/onelogin-jit/OneLogin_GRC_JIT_addon.json) | [README](../../samples/http/onelogin-jit/README.md) |
| http | — | CheckSystem, CheckPassword, ChangePassword | — | [`samples/http/proxmox-ve-http/ProxmoxVE-HTTP.json`](../../samples/http/proxmox-ve-http/ProxmoxVE-HTTP.json) | [README](../../samples/http/proxmox-ve-http/README.md) |
| http | Form | CheckPassword, ChangePassword | — | [`samples/http/twitter/CustomTwitter.json`](../../samples/http/twitter/CustomTwitter.json) | [README](../../samples/http/twitter/README.md) |
| http | Basic | CheckSystem, CheckPassword, ChangePassword | — | [`samples/http/wordpress/WordPressHttp.json`](../../samples/http/wordpress/WordPressHttp.json) | [README](../../samples/http/wordpress/README.md) |
| ssh | Interactive | CheckSystem, CheckPassword, ChangePassword, DiscoverSshHostKey, ChangeSshKey, CheckSshKey, DiscoverAuthorizedKeys | — | [`samples/ssh/generic-linux-ssh-keys/GenericLinuxWithSSHKeySupport.json`](../../samples/ssh/generic-linux-ssh-keys/GenericLinuxWithSSHKeySupport.json) | [README](../../samples/ssh/generic-linux-ssh-keys/README.md) |
| ssh | Interactive | CheckSystem, CheckPassword, ChangePassword, DiscoverSshHostKey | — | [`samples/ssh/generic-linux-with-ad/GenericLinuxWithAD.json`](../../samples/ssh/generic-linux-with-ad/GenericLinuxWithAD.json) | [README](../../samples/ssh/generic-linux-with-ad/README.md) |
| ssh | Interactive | CheckSystem, CheckPassword, ChangePassword, DiscoverSshHostKey, DiscoverAccounts | — | [`samples/ssh/generic-linux-with-discovery/GenericLinuxWithDiscovery.json`](../../samples/ssh/generic-linux-with-discovery/GenericLinuxWithDiscovery.json) | [README](../../samples/ssh/generic-linux-with-discovery/README.md) |
| ssh | Interactive | CheckSystem, CheckPassword, ChangePassword, DiscoverSshHostKey | — | [`samples/ssh/generic-linux/GenericLinux.json`](../../samples/ssh/generic-linux/GenericLinux.json) | [README](../../samples/ssh/generic-linux/README.md) |
| ssh | Interactive | CheckSystem, CheckPassword, ChangePassword, DiscoverSshHostKey | — | [`samples/ssh/linux-app-text-config/LinuxApplicationTextConfig.json`](../../samples/ssh/linux-app-text-config/LinuxApplicationTextConfig.json) | [README](../../samples/ssh/linux-app-text-config/README.md) |
| ssh | Batch | DiscoverSshHostKey, CheckSystem, CheckPassword, ChangePassword | — | [`samples/ssh/linux-ssh-batch-mode/LinuxSshBatchModeExample.json`](../../samples/ssh/linux-ssh-batch-mode/LinuxSshBatchModeExample.json) | [README](../../samples/ssh/linux-ssh-batch-mode/README.md) |
| ssh | Interactive | CheckSystem, CheckPassword, ChangePassword, DiscoverSshHostKey, DiscoverAccounts | — | [`samples/ssh/openbsd/OpenBSD.json`](../../samples/ssh/openbsd/OpenBSD.json) | — |
| ssh | Batch | DiscoverSshHostKey, CheckSystem, CheckPassword, ChangePassword | — | [`samples/ssh/restricted-authorized-key/RestrictedAuthorizedKeyExample.json`](../../samples/ssh/restricted-authorized-key/RestrictedAuthorizedKeyExample.json) | [README](../../samples/ssh/restricted-authorized-key/README.md) |
| ssh | Interactive | CheckSystem, CheckPassword, ChangePassword, DiscoverSshHostKey, DiscoverAccounts | — | [`samples/ssh/vcenter-appliance/vCenterServerAppliance.json`](../../samples/ssh/vcenter-appliance/vCenterServerAppliance.json) | [README](../../samples/ssh/vcenter-appliance/README.md) |

## Templates

| protocol | auth-scheme | operations | OS-family | file-path | README |
| --- | --- | --- | --- | --- | --- |
| — | — | CheckSystem, DiscoverSshHostKey, CheckPassword, ChangePassword | — | [`templates/Pattern-SshBatchShadowCompare.json`](../../templates/Pattern-SshBatchShadowCompare.json) | [README](../../templates/README.md) |
| http | — | CheckSystem, DiscoverAccounts | — | [`templates/Pattern-GenericHttpAccountDiscovery.json`](../../templates/Pattern-GenericHttpAccountDiscovery.json) | [README](../../templates/README.md) |
| http | Basic | CheckSystem, ElevateAccount, DemoteAccount | — | [`templates/Pattern-GenericHttpJitElevation.json`](../../templates/Pattern-GenericHttpJitElevation.json) | [README](../../templates/README.md) |
| http | Basic | CheckSystem, CheckPassword, ChangePassword, DiscoverAccounts | — | [`templates/Pattern-GenericRestApiBasicAuth.json`](../../templates/Pattern-GenericRestApiBasicAuth.json) | [README](../../templates/README.md) |
| http | Bearer | CheckSystem, CheckPassword, ChangePassword | — | [`templates/Pattern-GenericRestApiBearerToken.json`](../../templates/Pattern-GenericRestApiBearerToken.json) | [README](../../templates/README.md) |
| http | Bearer | CheckSystem, CheckApiKey, ChangeApiKey | — | [`templates/Pattern-GenericRestApiKeyRotation.json`](../../templates/Pattern-GenericRestApiKeyRotation.json) | [README](../../templates/README.md) |
| http | Bearer | CheckSystem | — | [`templates/TemplateHttpMinimal.json`](../../templates/TemplateHttpMinimal.json) | [README](../../templates/README.md) |
| ssh | Batch | CheckSystem, UpdateDependentSystem | — | [`templates/Pattern-GenericLinuxDependentSystem.json`](../../templates/Pattern-GenericLinuxDependentSystem.json) | [README](../../templates/README.md) |
| ssh | Batch | CheckSystem, CheckFile, ChangeFile | — | [`templates/Pattern-GenericLinuxFileManagement.json`](../../templates/Pattern-GenericLinuxFileManagement.json) | [README](../../templates/README.md) |
| ssh | Interactive | CheckSystem, CheckPassword, ChangePassword, DiscoverAccounts, DiscoverSshHostKey, CheckSshKey, ChangeSshKey, EnableAccount, DisableAccount | — | [`templates/Pattern-GenericLinuxFull.json`](../../templates/Pattern-GenericLinuxFull.json) | [README](../../templates/README.md) |
| ssh | Batch | CheckSystem, DiscoverServices | — | [`templates/Pattern-GenericLinuxServiceDiscovery.json`](../../templates/Pattern-GenericLinuxServiceDiscovery.json) | [README](../../templates/README.md) |
| ssh | — | CheckSystem, ChangePassword, CheckPassword | — | [`templates/Pattern-WindowsSshBasic.json`](../../templates/Pattern-WindowsSshBasic.json) | [README](../../templates/README.md) |
| ssh | Interactive | CheckSystem | — | [`templates/TemplateSshMinimal.json`](../../templates/TemplateSshMinimal.json) | [README](../../templates/README.md) |
