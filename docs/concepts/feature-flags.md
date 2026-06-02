[← Concepts](README.md)

# Platform Feature Flags

SPP uses platform feature flags to decide what a custom platform advertises. Those flags control which built-in fields appear on Assets and Accounts, which workflows SPP offers, and which profile settings become relevant.

> [!IMPORTANT]
> **Feature flags are automatic.** You do not configure them manually. When you upload a script, SPP validates its operations and reserved parameter names, then derives the platform's feature flags from that content.

For operation syntax, see the [Operations Reference](../reference/operations.md). For the exact reserved parameter names SPP recognizes, see [Reserved Parameters](../reference/reserved-parameters.md). For the commands used inside `Do` blocks, see the [Commands Reference](../reference/commands/index.md).

## Quick Reference

Use this table when you want to know, "What do I add to my script to make SPP expose this capability?"

| Capability | Flag | Add this to your script |
| --- | --- | --- |
| Password workflows | `PasswordFeatureFl` | Any of: `CheckSystem`, `CheckPassword`, `ChangePassword`, `EnableAccount`, `DisableAccount`, `ElevateAccount`, `DemoteAccount`, `DiscoverSshHostKey`, `UpdateDependentSystem` |
| Account password field | `AccountPasswordFl` | `AccountPassword` parameter (Secret type) |
| Manage SSH keys | `SshKeyFeatureFl` | `CheckSshKey`, `ChangeSshKey`, or `DiscoverAuthorizedKeys` |
| Manage API keys | `ApiKeyFeatureFl` | `CheckApiKey` or `ChangeApiKey` |
| File-based workflows | `FileFeatureFl` | Nothing — always enabled |
| SSH transport fields | `SshTransportFl` | `DiscoverSshHostKey` operation, or parameters: `CheckHostKey`, `HostKey`, `UserKey`, `NewSshPrivateKey`, `NewSshKeyComment`, `NewSshKey`, `OldSshKey` |
| Discover accounts | `AccountDiscoveryFl` | `DiscoverAccounts` |
| Discover services | `ServiceDiscoveryFl` | `DiscoverServices` |
| Enable or disable accounts | `SuspendRestoreAccountFl` | `EnableAccount` or `DisableAccount` |
| Elevate or demote accounts | `ElevateDemoteAccountFl` | `ElevateAccount` or `DemoteAccount` |
| Discover local assets | `LocalAssetDiscoveryFl` | Not available for custom platforms |
| Update dependent systems | `DependentSystemFl` | `UpdateDependentSystem` |
| Custom dependency commands | `CustomDependencyUpdateFl` | `DependentCommand` parameter (String type) |
| Show the Port field | `CustomPortFl` | `Port` parameter (Integer type) |
| Show the SSL/TLS field | `UseSslFl` | `UseSsl` parameter (Boolean type) |
| Show the Timeout field | `TimeoutFl` | `Timeout` parameter (Integer type) |

## How Feature Flags Work

When you upload a custom platform script:

1. SPP validates the operations in the script.
2. SPP scans the declared parameter names for reserved names such as `AccountPassword`, `NewPassword`, `Port`, and `UseSsl`.
3. SPP computes the platform feature flags from that validation result.
4. SPP enables the matching built-in UI fields, behaviors, and workflows.

This means your script is the capability definition. If the required operation or parameter is missing, the flag is not set and the related UI or workflow does not appear.

## Complete Flag Mapping

This table documents the primary flags relevant to custom platform authors. Additional flags (such as `ClientIdFl`, `SslVerificationFl`, `WorkstationIdFl`, and `HttpProxyFl`) are derived automatically from specific reserved parameters.

| Flag | Derived From |
| --- | --- |
| `PasswordFeatureFl` | Any operation in: `CheckSystem`, `CheckPassword`, `ChangePassword`, `EnableAccount`, `DisableAccount`, `ElevateAccount`, `DemoteAccount`, `DiscoverSshHostKey`, `RetrieveSshHostKey`, `UpdateDependentSystem` |
| `SshKeyFeatureFl` | `CheckSshKey`, `ChangeSshKey`, or `DiscoverAuthorizedKeys` operation present |
| `ApiKeyFeatureFl` | `CheckApiKey` or `ChangeApiKey` operation present |
| `FileFeatureFl` | Always `true` for all custom platforms |
| `AccountPasswordFl` | `AccountPassword` parameter declared with Secret type (unless overridden by platform-level auth exclusions) |
| `SshTransportFl` | `DiscoverSshHostKey` operation, or parameters: `CheckHostKey` (Boolean), `HostKey` (String), `UserKey` (Secret), `NewSshPrivateKey` (Secret), `NewSshKeyComment` (String), `NewSshKey` (String), `OldSshKey` (String) |
| `AccountDiscoveryFl` | `DiscoverAccounts` operation present |
| `ServiceDiscoveryFl` | `DiscoverServices` operation present |
| `SuspendRestoreAccountFl` | `EnableAccount` or `DisableAccount` operation present |
| `ElevateDemoteAccountFl` | `ElevateAccount` or `DemoteAccount` operation present |
| `LocalAssetDiscoveryFl` | `DiscoverAssets` operation plus `DiscoveryQuery` parameter plus internal `IsSystemOwned` flag (**not available to custom platforms**) |
| `DependentSystemFl` | `UpdateDependentSystem` operation present |
| `CustomDependencyUpdateFl` | `DependentCommand` parameter (String type) present |
| `CustomPortFl` | `Port` parameter (Integer type) present |
| `UseSslFl` | `UseSsl` parameter (Boolean type) present |
| `TimeoutFl` | `Timeout` parameter (Integer type) present |

## What Each Flag Enables

### Password and Credential Workflows

- **`PasswordFeatureFl`**
  - Enables password verification behavior for managed accounts.
  - Makes SPP treat the platform as one that can validate an existing account password.
  - Set by any of: `CheckSystem`, `CheckPassword`, `ChangePassword`, `EnableAccount`, `DisableAccount`, `ElevateAccount`, `DemoteAccount`, `DiscoverSshHostKey`, or `UpdateDependentSystem`.

- **`AccountPasswordFl`**
  - Enables password change and rotation workflows.
  - Makes password profile and scheduled password-change settings meaningful for this platform.
  - Derived from the `AccountPassword` reserved parameter (Secret type). Unlike other flags, this is parameter-driven rather than operation-driven.

- **`SshKeyFeatureFl`**
  - Enables SSH key management behavior for accounts that use this platform.
  - Makes SSH-key-oriented workflows and related account handling available.
  - Set by `CheckSshKey`, `ChangeSshKey`, or `DiscoverAuthorizedKeys`.

- **`ApiKeyFeatureFl`**
  - Enables API key management behavior for the platform.
  - Makes API-key check and related workflows available.
  - Set by `CheckApiKey` or `ChangeApiKey`.

- **`FileFeatureFl`**
  - Keeps file-based platform capability enabled for custom platforms.
  - No special script content is required to set this flag.
  - File-specific behavior still depends on the file operations you implement.

### Discovery and SSH Transport Workflows

- **`SshTransportFl`**
  - Enables SSH transport and host-key related UI fields on the platform.
  - Set by `DiscoverSshHostKey` operation, or by SSH-related parameters: `CheckHostKey`, `HostKey`, `UserKey`, `NewSshPrivateKey`, `NewSshKeyComment`, `NewSshKey`, `OldSshKey`.

- **`AccountDiscoveryFl`**
  - Enables account discovery workflows.
  - Makes account-discovery jobs and their related discovery settings available for the platform.
  - Add `DiscoverAccounts` to emit discovered accounts.

- **`ServiceDiscoveryFl`**
  - Enables service discovery workflows.
  - Makes service-discovery behavior available where SPP supports it for the platform.
  - Add `DiscoverServices` when you need to discover Windows services, scheduled tasks, or similar service objects.

- **`LocalAssetDiscoveryFl`**
  - Would enable local asset discovery behavior.
  - Requires `DiscoverAssets` operation with the `DiscoveryQuery` parameter AND the internal `IsSystemOwned` condition.
  - Custom platforms cannot set `IsSystemOwned`. Treat this capability as unavailable for custom platform authors today.

### Access and Privilege Workflows

- **`SuspendRestoreAccountFl`**
  - Enables account enable/disable behavior.
  - Makes suspend and restore style workflows available when SPP needs to toggle account access.
  - Add `EnableAccount`, `DisableAccount`, or both.

- **`ElevateDemoteAccountFl`**
  - Enables elevate and demote workflows.
  - Makes JIT-style privilege escalation and rollback behavior available for the platform.
  - Add `ElevateAccount`, `DemoteAccount`, or both.

### Dependency Workflows

- **`DependentSystemFl`**
  - Enables dependent-system update behavior.
  - Makes dependency-related settings in change workflows meaningful for the platform.
  - Add `UpdateDependentSystem` when password changes must also update downstream systems.

- **`CustomDependencyUpdateFl`**
  - Enables custom dependency command behavior.
  - Makes the custom dependency configuration in the change profile relevant because SPP can pass `DependentCommand` values into the script.
  - Add `DependentCommand` parameter (String type) to the `UpdateDependentSystem` operation.

### Built-In Connection Fields

- **`CustomPortFl`**
  - Shows the built-in **Port** field on the asset or platform configuration.
  - Lets your script consume `Port` as a reserved connection parameter instead of inventing a custom field.
  - Add `Port` (Integer type) to any operation that needs a configurable port.

- **`UseSslFl`**
  - Shows the built-in **Use SSL** or TLS-related setting.
  - Lets administrators control HTTPS or TLS behavior through a built-in field.
  - Add `UseSsl` (Boolean type) to any operation that should honor that setting.

- **`TimeoutFl`**
  - Shows the built-in **Timeout** field.
  - Lets administrators tune connection or request timeout behavior through a built-in field.
  - Add `Timeout` (Integer type) to any operation that should use a configurable timeout.

## How to Enable a Flag

Use this checklist when a UI field or workflow is missing.

| If you want to enable... | Add to your script | Notes |
| --- | --- | --- |
| `PasswordFeatureFl` | Any of: `CheckSystem`, `CheckPassword`, `ChangePassword`, `EnableAccount`, `DisableAccount`, `ElevateAccount`, `DemoteAccount`, `DiscoverSshHostKey`, `UpdateDependentSystem` | Many operations contribute to this flag. |
| `AccountPasswordFl` | `AccountPassword` parameter (Secret type) | Derived from the parameter presence, not from a specific operation. |
| `SshKeyFeatureFl` | `CheckSshKey`, `ChangeSshKey`, or `DiscoverAuthorizedKeys` | Any of these operations enables the flag. |
| `ApiKeyFeatureFl` | `CheckApiKey` or `ChangeApiKey` | Either operation enables the flag. |
| `FileFeatureFl` | Nothing | This flag is always on. |
| `SshTransportFl` | `DiscoverSshHostKey` operation, or SSH parameters (`CheckHostKey`, `HostKey`, `UserKey`, etc.) | See [Operations Reference](../reference/operations.md#discoversshhostkey). |
| `AccountDiscoveryFl` | `DiscoverAccounts` | Use the discovery output commands documented in the [Commands Reference](../reference/commands/index.md). |
| `ServiceDiscoveryFl` | `DiscoverServices` | Pair with the right discovery output from your `Do` block. |
| `SuspendRestoreAccountFl` | `EnableAccount` or `DisableAccount` | Add both if you need full suspend/restore support. |
| `ElevateDemoteAccountFl` | `ElevateAccount` or `DemoteAccount` | Add both if you need full elevate/demote support. |
| `DependentSystemFl` | `UpdateDependentSystem` | Use this when downstream systems must be updated after a credential change. |
| `CustomDependencyUpdateFl` | `DependentCommand` parameter (String type) | `DependentCommand` must use the exact reserved name. |
| `CustomPortFl` | `Port` parameter (Integer type) | `Port` is a reserved parameter documented in [Reserved Parameters](../reference/reserved-parameters.md#core-credentials). |
| `UseSslFl` | `UseSsl` parameter (Boolean type) | Good for HTTP or TLS-aware platforms. |
| `TimeoutFl` | `Timeout` parameter (Integer type) | Common on `CheckSystem`, `CheckPassword`, and HTTP request workflows. |
| `LocalAssetDiscoveryFl` | You cannot enable this in a custom platform | Requires `DiscoverAssets` + `DiscoveryQuery` parameter + internal `IsSystemOwned` flag. |

## Troubleshooting

> [!TIP]
> When a feature flag does not appear after upload, the problem is usually the operation name or parameter name.

- **Verify the operation name is supported and spelled exactly right.** Use the [Operations Reference](../reference/operations.md).
- **Verify the parameter name is the exact reserved name SPP expects.** Use the [Reserved Parameters](../reference/reserved-parameters.md). For example, `AccountPassword` works, but a custom name such as `UserPassword` will not set `AccountPasswordFl`.
- **Check both the operation and the parameter requirement.** Some flags need only an operation, while others require a specific reserved parameter too.
- **Re-upload the script after changes.** Feature flags are recomputed during validation of the uploaded script content.
- **Check the `Do` block only after the feature prerequisites are correct.** The feature flag comes from the operation and parameter declaration, not from the detailed command logic inside `Do`.
- **For discovery and dependency workflows, confirm that your implementation also uses the correct output or command patterns.** See the [Commands Reference](../reference/commands/index.md).
- **Do not expect `LocalAssetDiscoveryFl` to appear.** That capability depends on an internal condition custom platforms cannot set.

## Notes

> [!NOTE]
> `FileFeatureFl` is always `true` for custom platforms. You do not need to add anything to your script for that flag.

> [!WARNING]
> `LocalAssetDiscoveryFl` requires `DiscoverAssets` with the `DiscoveryQuery` parameter AND an internal `IsSystemOwned` condition that custom platforms cannot set. Even if you add discovery logic, this specific flag is not currently available for custom platforms.
