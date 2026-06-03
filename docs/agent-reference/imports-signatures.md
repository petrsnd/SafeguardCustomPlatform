[← Agent Reference](README.md)

# System Import Library Function Signatures

> **Generated** — do not hand-edit. Regenerate with `tools/Build-ImportsSignatures.ps1` against the appliance source.

This is the agent-facing companion to [`docs/reference/imports.md`](../reference/imports.md). The human-facing reference describes what each library is *for*; this file describes the *exact call signature* of every function the libraries expose, mined from the Hercules platform-script engine source.

## How to read this reference

Each function entry lists:

- **Parameters** — positional arguments you pass via the `Function` command's `Parameters` array, in declaration order. Optional parameters are marked with `?`. Pass `""` (empty string) or omit trailing optionals.
- **Caller-scope reads** — `%VarName%` references the function makes to variables that are **not** declared as its parameters. The calling operation must declare these as operation parameters or `SetItem` them before calling. (Some of these are runtime-supplied — see the [Common script context variables](#common-script-context-variables) section.)
- **Calls** — other functions this one invokes. If a called function lives in a different library, you must add that library to your `Imports`.
- **Sets locally** — variable names this function writes via `SetItem`, `BufferName`, `ResultVariable`, or `ConnectionObjectName`. Where the same name appears as a parameter, the function shadows the parameter locally; where it does not, the variable may leak to caller scope (script-engine semantics).
- **Returns** — literal values the function returns, when statically determinable. A blank entry usually means the function returns void or returns an expression whose value depends on runtime state.

### Calling positional functions

Pass arguments as an ordered array of `%VariableName%` (or `%VariableName::$%` for secrets). The array length must match the number of declared parameters; the engine rejects calls with too few or too many arguments.

```json
{
  "Function": {
    "Name": "LoginSsh",
    "Parameters": [ "%FuncUserName%", "%FuncPassword::$%", "%UserKey::$%", "" ],
    "ResultVariable": "LoginResult"
  }
}
```

### Calling 0-parameter functions

Several library functions declare zero parameters but still rely on caller-scope variables. Your operation must declare those variables (typically as operation parameters such as `FuncUserName`, `FuncPassword`, `NewPassword`, `Account`) before calling. The function reads them by name from the surrounding scope.

```json
{ "Function": { "Name": "ValidatePassword", "ResultVariable": "ValidateResult" } }
```

## Common script context variables

Variables every operation receives or commonly declares; library functions reference these freely without declaring them as parameters:

| Variable | Source | Purpose |
| --- | --- | --- |
| `Address` | Operation parameter (required) | Network address of the target asset. |
| `AssetName` | Operation parameter | Display name of the asset; falls back to `Address`. |
| `Port` | Operation parameter | Network port. SSH operations typically default to 22. |
| `Timeout` | Operation parameter | Operation timeout in seconds. |
| `RequestTerminal` | Operation parameter | Whether the SSH `Connect` requests a PTY. |
| `CheckHostKey` | Operation parameter | Whether to verify the SSH host key on connect. |
| `HostKey` | Operation parameter (Secret) | Stored host key when `CheckHostKey` is true. |
| `DelegationPrefix` | Operation parameter (Secret) | Optional shell prefix to elevate before commands. |
| `FuncUserName` | Operation parameter | The user the operation logs in as. |
| `FuncPassword` | Operation parameter (Secret) | Password for `FuncUserName`. |
| `UserKey` | Operation parameter (Secret) | SSH private key for `FuncUserName`. |
| `NewPassword` | Operation parameter (Secret) | New password supplied by SPP for `ChangePassword` operations. |
| `Account` / `AccountUserName` | Operation parameter | The managed account whose credential is being checked or rotated. Some libraries read one or the other. |
| `ConnectSsh` | Set by `LoginSsh` (Global) | The SSH connection object used by subsequent `Send` / `Receive` / `Disconnect` commands. |
| `Exception` | Engine | Set inside `Catch` blocks when an error is caught. |

## Library index

| Library | Function count |
| --- | ---: |
| [`LinuxSshLogin`](#library-linuxsshlogin) | 27 |
| [`LinuxSshFunctions`](#library-linuxsshfunctions) | 6 |
| [`DiscoverSshHostKey`](#library-discoversshhostkey) | 1 |
| [`TestLoginSsh`](#library-testloginssh) | 2 |
| [`ChangeSshKeyCommon`](#library-changesshkeycommon) | 11 |
| [`UnixShellAuthorizedKeys`](#library-unixshellauthorizedkeys) | 14 |
| [`UnixShellAuthorizedKeysOpenSsh`](#library-unixshellauthorizedkeysopenssh) | 16 |
| [`UnixShellChangeSshKey`](#library-unixshellchangesshkey) | 4 |
| [`UnixShellChangeSshKeyOpenSsh`](#library-unixshellchangesshkeyopenssh) | 11 |
| [`UnixShellDiscoverAccounts`](#library-unixshelldiscoveraccounts) | 2 |
| [`UnixShellSshFunctions`](#library-unixshellsshfunctions) | 2 |
| [`ResolveAssetName`](#library-resolveassetname) | 1 |
| [`ReturnOperationResultSsh`](#library-returnoperationresultssh) | 1 |
| [`WindowsSshFunctions`](#library-windowssshfunctions) | 14 |
| [`WindowsSshFunctionsDiscovery`](#library-windowssshfunctionsdiscovery) | 39 |
| [`WindowsSshFunctionsSshKey`](#library-windowssshfunctionssshkey) | 33 |
| [`UnixUpdateCustomDependency`](#library-unixupdatecustomdependency) | 4 |

## Library: `LinuxSshLogin` <a id="library-linuxsshlogin"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`LoginSsh`](#fn-linuxsshlogin-loginssh) | UserName, Password?, LoginKey?, UserDomain? | `LogoutSsh` | `Address`, `AssetName`, ...(6 more) |
| [`LogoutSsh`](#fn-linuxsshlogin-logoutssh) | _(none)_ | _(none)_ | _(none)_ |
| [`SetUpEnvironment`](#fn-linuxsshlogin-setupenvironment) | _(none)_ | _(none)_ | _(none)_ |
| [`InitializeServiceAccountLoginVariables`](#fn-linuxsshlogin-initializeserviceaccountloginvariables) | _(none)_ | _(none)_ | `FuncPassword`, `FuncUserName` |
| [`VerifyDelegationPrefix`](#fn-linuxsshlogin-verifydelegationprefix) | _(none)_ | `ResolveAssetNameIfEmpty` | _(none)_ |
| [`VerifyStringForInvalidCharacters`](#fn-linuxsshlogin-verifystringforinvalidcharacters) | StringToVerify?, InvalidCharacters | _(none)_ | _(none)_ |
| [`VerifyAccountPassword`](#fn-linuxsshlogin-verifyaccountpassword) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `AccountPassword` |
| [`VerifyNewPassword`](#fn-linuxsshlogin-verifynewpassword) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `NewPassword` |
| [`VerifyFuncPassword`](#fn-linuxsshlogin-verifyfuncpassword) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `FuncPassword` |
| [`VerifyAccountUserName`](#fn-linuxsshlogin-verifyaccountusername) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `AccountUserName` |
| [`VerifyEnablePassword`](#fn-linuxsshlogin-verifyenablepassword) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `EnablePassword` |
| [`VerifyFuncUserName`](#fn-linuxsshlogin-verifyfuncusername) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `FuncUserName` |
| [`VerifyOldSshKey`](#fn-linuxsshlogin-verifyoldsshkey) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `OldSshKey` |
| [`VerifyNewSshKey`](#fn-linuxsshlogin-verifynewsshkey) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `NewSshKey` |
| [`VerifyNewSshKeyComment`](#fn-linuxsshlogin-verifynewsshkeycomment) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `NewSshKeyComment` |
| [`VerifyFuncUserNetBiosName`](#fn-linuxsshlogin-verifyfuncusernetbiosname) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `FuncUserNetBiosName` |
| [`VerifyDependentSshKey`](#fn-linuxsshlogin-verifydependentsshkey) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `DependentSshKey` |
| [`VerifyDependentSshKeyComment`](#fn-linuxsshlogin-verifydependentsshkeycomment) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `DependentSshKeyComment` |
| [`VerifyDependentSshPrivateKey`](#fn-linuxsshlogin-verifydependentsshprivatekey) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `DependentSshPrivateKey` |
| [`VerifyDependentCommand`](#fn-linuxsshlogin-verifydependentcommand) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `DependentCommand` |
| [`VerifyCommandArguments`](#fn-linuxsshlogin-verifycommandarguments) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `CommandArguments` |
| [`VerifyFuncUserDomain`](#fn-linuxsshlogin-verifyfuncuserdomain) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `FuncUserDomain` |
| [`VerifyDependentUsername`](#fn-linuxsshlogin-verifydependentusername) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `DependentUsername` |
| [`VerifyDependentPassword`](#fn-linuxsshlogin-verifydependentpassword) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `DependentPassword`, `DependentUsername` |
| [`VerifyUserDomain`](#fn-linuxsshlogin-verifyuserdomain) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `DomainName` |
| [`VerifyNetBiosName`](#fn-linuxsshlogin-verifynetbiosname) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `NetBiosName` |
| [`VerifyAdminGroupName`](#fn-linuxsshlogin-verifyadmingroupname) | InvalidCharacters | `VerifyStringForInvalidCharacters` | `AdminGroupName` |

### `LoginSsh` <a id="fn-linuxsshlogin-loginssh"></a>

**Signature:** `LoginSsh(UserName: String, Password?: Secret, LoginKey?: Secret, UserDomain?: String)`

**Parameters:**

- `UserName` (String, required)
- `Password` (Secret, optional)
- `LoginKey` (Secret, optional)
- `UserDomain` (String, optional)

**Caller-scope reads:** `Address`, `AssetName`, `CheckHostKey`, `Exception`, `HostKey`, `Port`, `RequestTerminal`, `Timeout`

**Calls:** `LogoutSsh`

**Sets locally:** `ConnectSsh`, `Global:ConnectSsh`, `LoginCheckBuffer`, `UserName`

**Returns:** `false`, `true`

### `LogoutSsh` <a id="fn-linuxsshlogin-logoutssh"></a>

**Signature:** `LogoutSsh(_(none)_)`

**Caller-scope reads:** _(none)_

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`

**Returns:** `true`

### `SetUpEnvironment` <a id="fn-linuxsshlogin-setupenvironment"></a>

**Signature:** `SetUpEnvironment(_(none)_)`

**Caller-scope reads:** _(none)_

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`, `FlushBuffer`

**Returns:** `true`

### `InitializeServiceAccountLoginVariables` <a id="fn-linuxsshlogin-initializeserviceaccountloginvariables"></a>

**Signature:** `InitializeServiceAccountLoginVariables(_(none)_)`

**Caller-scope reads:** `FuncPassword`, `FuncUserName`

**Calls:** _(none)_

**Sets locally:** `Global:LoginPassword`, `Global:LoginUserName`

**Returns:** _(none)_

### `VerifyDelegationPrefix` <a id="fn-linuxsshlogin-verifydelegationprefix"></a>

**Signature:** `VerifyDelegationPrefix(_(none)_)`

**Caller-scope reads:** _(none)_

**Calls:** `ResolveAssetNameIfEmpty`

**Sets locally:** `DelegationPrefix`

**Returns:** _(none)_

### `VerifyStringForInvalidCharacters` <a id="fn-linuxsshlogin-verifystringforinvalidcharacters"></a>

**Signature:** `VerifyStringForInvalidCharacters(StringToVerify?: String, InvalidCharacters: String)`

**Parameters:**

- `StringToVerify` (String, optional)
- `InvalidCharacters` (String, required)

**Caller-scope reads:** _(none)_

**Calls:** _(none)_

**Sets locally:** _(none)_

**Returns:** `false`, `true`

### `VerifyAccountPassword` <a id="fn-linuxsshlogin-verifyaccountpassword"></a>

**Signature:** `VerifyAccountPassword(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `AccountPassword`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyNewPassword` <a id="fn-linuxsshlogin-verifynewpassword"></a>

**Signature:** `VerifyNewPassword(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `NewPassword`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyFuncPassword` <a id="fn-linuxsshlogin-verifyfuncpassword"></a>

**Signature:** `VerifyFuncPassword(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `FuncPassword`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyAccountUserName` <a id="fn-linuxsshlogin-verifyaccountusername"></a>

**Signature:** `VerifyAccountUserName(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `AccountUserName`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyEnablePassword` <a id="fn-linuxsshlogin-verifyenablepassword"></a>

**Signature:** `VerifyEnablePassword(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `EnablePassword`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyFuncUserName` <a id="fn-linuxsshlogin-verifyfuncusername"></a>

**Signature:** `VerifyFuncUserName(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `FuncUserName`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyOldSshKey` <a id="fn-linuxsshlogin-verifyoldsshkey"></a>

**Signature:** `VerifyOldSshKey(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `OldSshKey`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyNewSshKey` <a id="fn-linuxsshlogin-verifynewsshkey"></a>

**Signature:** `VerifyNewSshKey(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `NewSshKey`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyNewSshKeyComment` <a id="fn-linuxsshlogin-verifynewsshkeycomment"></a>

**Signature:** `VerifyNewSshKeyComment(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `NewSshKeyComment`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyFuncUserNetBiosName` <a id="fn-linuxsshlogin-verifyfuncusernetbiosname"></a>

**Signature:** `VerifyFuncUserNetBiosName(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `FuncUserNetBiosName`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyDependentSshKey` <a id="fn-linuxsshlogin-verifydependentsshkey"></a>

**Signature:** `VerifyDependentSshKey(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `DependentSshKey`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyDependentSshKeyComment` <a id="fn-linuxsshlogin-verifydependentsshkeycomment"></a>

**Signature:** `VerifyDependentSshKeyComment(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `DependentSshKeyComment`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyDependentSshPrivateKey` <a id="fn-linuxsshlogin-verifydependentsshprivatekey"></a>

**Signature:** `VerifyDependentSshPrivateKey(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `DependentSshPrivateKey`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyDependentCommand` <a id="fn-linuxsshlogin-verifydependentcommand"></a>

**Signature:** `VerifyDependentCommand(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `DependentCommand`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyCommandArguments` <a id="fn-linuxsshlogin-verifycommandarguments"></a>

**Signature:** `VerifyCommandArguments(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `CommandArguments`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyFuncUserDomain` <a id="fn-linuxsshlogin-verifyfuncuserdomain"></a>

**Signature:** `VerifyFuncUserDomain(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `FuncUserDomain`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyDependentUsername` <a id="fn-linuxsshlogin-verifydependentusername"></a>

**Signature:** `VerifyDependentUsername(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `DependentUsername`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyDependentPassword` <a id="fn-linuxsshlogin-verifydependentpassword"></a>

**Signature:** `VerifyDependentPassword(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `DependentPassword`, `DependentUsername`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyUserDomain` <a id="fn-linuxsshlogin-verifyuserdomain"></a>

**Signature:** `VerifyUserDomain(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `DomainName`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyNetBiosName` <a id="fn-linuxsshlogin-verifynetbiosname"></a>

**Signature:** `VerifyNetBiosName(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `NetBiosName`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

### `VerifyAdminGroupName` <a id="fn-linuxsshlogin-verifyadmingroupname"></a>

**Signature:** `VerifyAdminGroupName(InvalidCharacters: String)`

**Parameters:**

- `InvalidCharacters` (String, required)

**Caller-scope reads:** `AdminGroupName`

**Calls:** `VerifyStringForInvalidCharacters`

**Sets locally:** `VerifyResult`

**Returns:** `true`

## Library: `LinuxSshFunctions` <a id="library-linuxsshfunctions"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`ValidateAccount`](#fn-linuxsshfunctions-validateaccount) | _(none)_ | _(none)_ | `Address`, `AssetName`, `DelegationPrefix`, `FuncPassword` |
| [`ValidatePassword`](#fn-linuxsshfunctions-validatepassword) | _(none)_ | `TestLoginSsh` | `AccountPassword`, `AccountUserName`, `DelegationPrefix`, `FuncPassword`, `FuncUserName`, `SudoPassPrompt` |
| [`ChangeUserPassword`](#fn-linuxsshfunctions-changeuserpassword) | _(none)_ | _(none)_ | `AccountPassword`, `AccountUserName`, ...(6 more) |
| [`ChangeAccountMode`](#fn-linuxsshfunctions-changeaccountmode) | AccountMode | _(none)_ | `AccountUserName`, `DelegationPrefix`, `FuncPassword` |
| [`ChangeAccountMembershipList`](#fn-linuxsshfunctions-changeaccountmembershiplist) | AccountMode, Groups, Cmd | `ChangeAccountMembership` | `AccountUserName`, `Group` |
| [`ChangeAccountMembership`](#fn-linuxsshfunctions-changeaccountmembership) | AccountMode, Group, Cmd | _(none)_ | `AccountUserName`, `DelegationPrefix`, `FuncPassword` |

### `ValidateAccount` <a id="fn-linuxsshfunctions-validateaccount"></a>

**Signature:** `ValidateAccount(_(none)_)`

**Caller-scope reads:** `Address`, `AssetName`, `DelegationPrefix`, `FuncPassword`

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`, `ReturnStatus`

**Returns:** `false`, `true`

### `ValidatePassword` <a id="fn-linuxsshfunctions-validatepassword"></a>

**Signature:** `ValidatePassword(_(none)_)`

**Caller-scope reads:** `AccountPassword`, `AccountUserName`, `DelegationPrefix`, `FuncPassword`, `FuncUserName`, `SudoPassPrompt`

**Calls:** `TestLoginSsh`

**Sets locally:** `AccountEntry`, `ConnectSsh`, `GLOBAL:SudoPassPrompt`, `PasswordHashMatched`, `ReturnStatus`

**Returns:** `%PasswordHashMatched%`

### `ChangeUserPassword` <a id="fn-linuxsshfunctions-changeuserpassword"></a>

**Signature:** `ChangeUserPassword(_(none)_)`

**Caller-scope reads:** `AccountPassword`, `AccountUserName`, `AssetName`, `DelegationPrefix`, `FuncPassword`, `FuncUserName`, `NewPassword`, `SudoPassPrompt`

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`, `GLOBAL:SudoPassPrompt`, `PasswdAttempt`, `RanPasswd`, `ReturnStatus`

**Returns:** `false`, `true`

### `ChangeAccountMode` <a id="fn-linuxsshfunctions-changeaccountmode"></a>

**Signature:** `ChangeAccountMode(AccountMode: String)`

**Parameters:**

- `AccountMode` (String, required)

**Caller-scope reads:** `AccountUserName`, `DelegationPrefix`, `FuncPassword`

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`, `ReturnStatus`

**Returns:** `false`, `true`

### `ChangeAccountMembershipList` <a id="fn-linuxsshfunctions-changeaccountmembershiplist"></a>

**Signature:** `ChangeAccountMembershipList(AccountMode: String, Groups: array, Cmd: string)`

**Parameters:**

- `AccountMode` (String, required)
- `Groups` (array, required)
- `Cmd` (string, required)

**Caller-scope reads:** `AccountUserName`, `Group`

**Calls:** `ChangeAccountMembership`

**Sets locally:** `Result`

**Returns:** `true`

### `ChangeAccountMembership` <a id="fn-linuxsshfunctions-changeaccountmembership"></a>

**Signature:** `ChangeAccountMembership(AccountMode: String, Group: string, Cmd: string)`

**Parameters:**

- `AccountMode` (String, required)
- `Group` (string, required)
- `Cmd` (string, required)

**Caller-scope reads:** `AccountUserName`, `DelegationPrefix`, `FuncPassword`

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`, `ReturnStatus`

**Returns:** `false`, `true`

## Library: `DiscoverSshHostKey` <a id="library-discoversshhostkey"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`DiscoverHostKeyForAsset`](#fn-discoversshhostkey-discoverhostkeyforasset) | _(none)_ | `ResolveAssetNameIfEmpty` | `Address`, `AssetName`, `Exception`, `HostKey`, `Port`, `Timeout` |

### `DiscoverHostKeyForAsset` <a id="fn-discoversshhostkey-discoverhostkeyforasset"></a>

**Signature:** `DiscoverHostKeyForAsset(_(none)_)`

**Caller-scope reads:** `Address`, `AssetName`, `Exception`, `HostKey`, `Port`, `Timeout`

**Calls:** `ResolveAssetNameIfEmpty`

**Sets locally:** _(none)_

**Returns:** _(none)_

## Library: `TestLoginSsh` <a id="library-testloginssh"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`TestLoginSsh`](#fn-testloginssh-testloginssh) | _(none)_ | _(none)_ | `AccountPassword`, `AccountUserName`, `Address`, `CheckHostKey`, `HostKey`, `Port` |
| [`TestNewKey`](#fn-testloginssh-testnewkey) | TestUser, TestKey | _(none)_ | `Address`, `Exception`, `HostKey`, `Port` |

### `TestLoginSsh` <a id="fn-testloginssh-testloginssh"></a>

**Signature:** `TestLoginSsh(_(none)_)`

**Caller-scope reads:** `AccountPassword`, `AccountUserName`, `Address`, `CheckHostKey`, `HostKey`, `Port`

**Calls:** _(none)_

**Sets locally:** `Global:TestConnectSsh`, `TestConnectSsh`

**Returns:** `false`, `true`

### `TestNewKey` <a id="fn-testloginssh-testnewkey"></a>

**Signature:** `TestNewKey(TestUser: string, TestKey: string)`

**Parameters:**

- `TestUser` (string, required)
- `TestKey` (string, required)

**Caller-scope reads:** `Address`, `Exception`, `HostKey`, `Port`

**Calls:** _(none)_

**Sets locally:** `Global:TestConnectSsh`, `TestConnectSsh`

**Returns:** `true`

## Library: `ChangeSshKeyCommon` <a id="library-changesshkeycommon"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`CheckKeyChangeRequired`](#fn-changesshkeycommon-checkkeychangerequired) | OldKey, NewKey, Replace | _(none)_ | `NewSshPrivateKey` |
| [`CheckKeyVars`](#fn-changesshkeycommon-checkkeyvars) | _(none)_ | _(none)_ | `AddKey`, `NewSshKey`, `NewSshPrivateKey`, `RemoveKey` |
| [`ConverseResponse`](#fn-changesshkeycommon-converseresponse) | ConvDescription, Line, Expect, ThrowOnMismatch, PermissionErrorOnMismatch, ReceiveCheck | _(none)_ | `DelegationPrefix`, `FuncPassword` |
| [`GetOptionalVariableFromResponse`](#fn-changesshkeycommon-getoptionalvariablefromresponse) | ConvDescription, Line, ReplaceRegex?, ThrowOnMismatch | _(none)_ | `DelegationPrefix`, `FuncPassword` |
| [`GetVariableFromResponse`](#fn-changesshkeycommon-getvariablefromresponse) | ConvDescription, Line, ReplaceRegex | `GetOptionalVariableFromResponse` | _(none)_ |
| [`InitUserVars`](#fn-changesshkeycommon-inituservars) | _(none)_ | _(none)_ | `AccountUserName`, `FuncUserName`, `TargetUser`, `TargetUserShortName` |
| [`ExtractVariableFromLine`](#fn-changesshkeycommon-extractvariablefromline) | Desc, Line, ReplaceRegex | _(none)_ | _(none)_ |
| [`Converse`](#fn-changesshkeycommon-converse) | ConvDescription, Line, Expect, ThrowOnMismatch, PermissionErrorOnMismatch, ReceiveCheck | `ConverseResponse` | _(none)_ |
| [`AssignSshKeyToShellVariable`](#fn-changesshkeycommon-assignsshkeytoshellvariable) | Key, Comment?, ShellVariableName | `EscapeSingleQuoteFromString`, `GetVariableFromResponse` | `ChunkSize`, `FullKey`, `KeyChunk`, `KeyChunkVariableName`, `KeyChunkVariableNames`, `KeyLength` |
| [`EscapeSingleQuoteFromString`](#fn-changesshkeycommon-escapesinglequotefromstring) | ThisString | _(none)_ | `Config` |
| [`ValidateBase64String`](#fn-changesshkeycommon-validatebase64string) | EncodedString | _(none)_ | _(none)_ |

### `CheckKeyChangeRequired` <a id="fn-changesshkeycommon-checkkeychangerequired"></a>

**Signature:** `CheckKeyChangeRequired(OldKey: string, NewKey: string, Replace: boolean)`

**Parameters:**

- `OldKey` (string, required)
- `NewKey` (string, required)
- `Replace` (boolean, required)

**Caller-scope reads:** `NewSshPrivateKey`

**Calls:** _(none)_

**Sets locally:** `Action`

**Returns:** `%{ Action }%`

### `CheckKeyVars` <a id="fn-changesshkeycommon-checkkeyvars"></a>

**Signature:** `CheckKeyVars(_(none)_)`

**Caller-scope reads:** `AddKey`, `NewSshKey`, `NewSshPrivateKey`, `RemoveKey`

**Calls:** _(none)_

**Sets locally:** `GLOBAL:AddKey`, `GLOBAL:RemoveKey`, `OldSshKey`, `ReplaceExistingKeys`

**Returns:** `false`, `true`

### `ConverseResponse` <a id="fn-changesshkeycommon-converseresponse"></a>

**Signature:** `ConverseResponse(ConvDescription: string, Line: string, Expect: string, ThrowOnMismatch: boolean, PermissionErrorOnMismatch: boolean, ReceiveCheck: string)`

**Parameters:**

- `ConvDescription` (string, required)
- `Line` (string, required)
- `Expect` (string, required)
- `ThrowOnMismatch` (boolean, required)
- `PermissionErrorOnMismatch` (boolean, required)
- `ReceiveCheck` (string, required)

**Caller-scope reads:** `DelegationPrefix`, `FuncPassword`

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`, `ReturnLine`

**Returns:** _(none)_

### `GetOptionalVariableFromResponse` <a id="fn-changesshkeycommon-getoptionalvariablefromresponse"></a>

**Signature:** `GetOptionalVariableFromResponse(ConvDescription: string, Line: string, ReplaceRegex?: string, ThrowOnMismatch: boolean)`

**Parameters:**

- `ConvDescription` (string, required)
- `Line` (string, required)
- `ReplaceRegex` (string, optional)
- `ThrowOnMismatch` (boolean, required)

**Caller-scope reads:** `DelegationPrefix`, `FuncPassword`

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`, `ReturnLine`, `tmpvar`

**Returns:** ``, `%{ tmpvar.Value }%`

### `GetVariableFromResponse` <a id="fn-changesshkeycommon-getvariablefromresponse"></a>

**Signature:** `GetVariableFromResponse(ConvDescription: string, Line: string, ReplaceRegex: string)`

**Parameters:**

- `ConvDescription` (string, required)
- `Line` (string, required)
- `ReplaceRegex` (string, required)

**Caller-scope reads:** _(none)_

**Calls:** `GetOptionalVariableFromResponse`

**Sets locally:** `ReturnLine`

**Returns:** `%ReturnLine%`

### `InitUserVars` <a id="fn-changesshkeycommon-inituservars"></a>

**Signature:** `InitUserVars(_(none)_)`

**Caller-scope reads:** `AccountUserName`, `FuncUserName`, `TargetUser`, `TargetUserShortName`

**Calls:** _(none)_

**Sets locally:** `GLOBAL:PrivElevationCmd`, `GLOBAL:TargetUser`, `GLOBAL:TargetUserShortName`, `IsDomainUser`

**Returns:** _(none)_

### `ExtractVariableFromLine` <a id="fn-changesshkeycommon-extractvariablefromline"></a>

**Signature:** `ExtractVariableFromLine(Desc: string, Line: secret, ReplaceRegex: string)`

**Parameters:**

- `Desc` (string, required)
- `Line` (secret, required)
- `ReplaceRegex` (string, required)

**Caller-scope reads:** _(none)_

**Calls:** _(none)_

**Sets locally:** `tmpvar`

**Returns:** ``, `%{ tmpvar.Value }%`

### `Converse` <a id="fn-changesshkeycommon-converse"></a>

**Signature:** `Converse(ConvDescription: string, Line: string, Expect: string, ThrowOnMismatch: boolean, PermissionErrorOnMismatch: boolean, ReceiveCheck: string)`

**Parameters:**

- `ConvDescription` (string, required)
- `Line` (string, required)
- `Expect` (string, required)
- `ThrowOnMismatch` (boolean, required)
- `PermissionErrorOnMismatch` (boolean, required)
- `ReceiveCheck` (string, required)

**Caller-scope reads:** _(none)_

**Calls:** `ConverseResponse`

**Sets locally:** `Response`

**Returns:** `%{ Response.Result }%`

### `AssignSshKeyToShellVariable` <a id="fn-changesshkeycommon-assignsshkeytoshellvariable"></a>

**Signature:** `AssignSshKeyToShellVariable(Key: string, Comment?: string = , ShellVariableName: string)`

**Parameters:**

- `Key` (string, required)
- `Comment` (string, optional, default: )
- `ShellVariableName` (string, required)

**Caller-scope reads:** `ChunkSize`, `FullKey`, `KeyChunk`, `KeyChunkVariableName`, `KeyChunkVariableNames`, `KeyLength`

**Calls:** `EscapeSingleQuoteFromString`, `GetVariableFromResponse`

**Sets locally:** `%SshKeyFromShellVariableResponse%`, `AllKeyChunkVariablesInOneString`, `ConnectSsh`, `FlushBuffer`, `GLOBAL:Chunks`, `GLOBAL:ChunkSize`, `GLOBAL:Count`, `GLOBAL:FullKey`, `GLOBAL:Index`, `GLOBAL:KeyChunk`, `GLOBAL:KeyChunkVariableName`, `GLOBAL:KeyChunkVariableNames`, `GLOBAL:KeyLength`, `SshKeyFromShellVariableResponse`

**Returns:** `$%ShellVariableName%`

### `EscapeSingleQuoteFromString` <a id="fn-changesshkeycommon-escapesinglequotefromstring"></a>

**Signature:** `EscapeSingleQuoteFromString(ThisString: string)`

**Parameters:**

- `ThisString` (string, required)

**Caller-scope reads:** `Config`

**Calls:** _(none)_

**Sets locally:** _(none)_

**Returns:** `%ThisString%`

### `ValidateBase64String` <a id="fn-changesshkeycommon-validatebase64string"></a>

**Signature:** `ValidateBase64String(EncodedString: string)`

**Parameters:**

- `EncodedString` (string, required)

**Caller-scope reads:** _(none)_

**Calls:** _(none)_

**Sets locally:** _(none)_

**Returns:** `false`, `true`

## Library: `UnixShellAuthorizedKeys` <a id="library-unixshellauthorizedkeys"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`LoginForOperation`](#fn-unixshellauthorizedkeys-loginforoperation) | _(none)_ | `LoginSsh`, `SetUpEnvironment`, `VerifyDelegationPrefix` | `FuncPassword`, `FuncUserDomain`, `FuncUserName`, `UserKey` |
| [`InitTargetUser`](#fn-unixshellauthorizedkeys-inittargetuser) | Config | _(none)_ | `AccountUserName`, `FuncUserName` |
| [`GetUserInfo`](#fn-unixshellauthorizedkeys-getuserinfo) | Config, Platform | `Converse`, `GetOptionalVariableFromResponse`, `GetVariableFromResponse` | `Exception` |
| [`GetUsersKeystore`](#fn-unixshellauthorizedkeys-getuserskeystore) | Config | `GetUsersKeystoreListOpenSsh`, `GetUsersKeystoreListTectia` | _(none)_ |
| [`GetSshdConfiguration`](#fn-unixshellauthorizedkeys-getsshdconfiguration) | Config, Platform | `GetSshdConfigurationOpenSsh`, `GetSshdConfigurationTectia` | _(none)_ |
| [`GetAuthKeys`](#fn-unixshellauthorizedkeys-getauthkeys) | Config | `GetAuthKeysOpenSsh`, `GetAuthKeysTectia` | _(none)_ |
| [`WriteDiscoveredAuthKeys`](#fn-unixshellauthorizedkeys-writediscoveredauthkeys) | Config, AuthKeys | `WriteDiscoveredAuthKeysOpenSsh` | `AccountUserName` |
| [`InitializeSshConfigData`](#fn-unixshellauthorizedkeys-initializesshconfigdata) | Platform | `GetSshdConfiguration`, `GetUserInfo`, ...(3 more) | `AssetName`, `DelegationPrefix`, `Exception` |
| [`UnixShellDiscoverAuthorizedKeys`](#fn-unixshellauthorizedkeys-unixshelldiscoverauthorizedkeys) | Platform | `GetAuthKeys`, `InitializeSshConfigData`, `WriteDiscoveredAuthKeys` | `DiscoveredAuthKeysList` |
| [`UnixShellCheckAuthorizedKey`](#fn-unixshellauthorizedkeys-unixshellcheckauthorizedkey) | Platform | `CheckAuthKey`, `GetAuthKeys`, `InitializeSshConfigData` | `DiscoveredAuthKeysList`, `OldSshKey` |
| [`CheckAuthKey`](#fn-unixshellauthorizedkeys-checkauthkey) | Config, AuthKeysDictionary, OldSshKey | `CheckSshKeyOpenSsh`, `CheckSshKeystorePermissions` | _(none)_ |
| [`UnixGetRemoteClient`](#fn-unixshellauthorizedkeys-unixgetremoteclient) | Config | `Converse`, `GetVariableFromResponse` | `Address` |
| [`CheckSshKeystorePermissions`](#fn-unixshellauthorizedkeys-checksshkeystorepermissions) | Config, Keystore | `Converse`, `GetVariableFromResponse` | `Group`, `GroupMembers`, ...(7 more) |
| [`UnixShellRemoveAuthorizedKey`](#fn-unixshellauthorizedkeys-unixshellremoveauthorizedkey) | Platform | `Converse`, `InitializeSshConfigData`, ...(3 more) | `ServerSoftwareName` |

### `LoginForOperation` <a id="fn-unixshellauthorizedkeys-loginforoperation"></a>

**Signature:** `LoginForOperation(_(none)_)`

**Caller-scope reads:** `FuncPassword`, `FuncUserDomain`, `FuncUserName`, `UserKey`

**Calls:** `LoginSsh`, `SetUpEnvironment`, `VerifyDelegationPrefix`

**Sets locally:** `Global:EnableAllCiphers`, `Global:RequestTerminal`, `LoginResult`

**Returns:** `false`, `true`

### `InitTargetUser` <a id="fn-unixshellauthorizedkeys-inittargetuser"></a>

**Signature:** `InitTargetUser(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `AccountUserName`, `FuncUserName`

**Calls:** _(none)_

**Sets locally:** `IsDomainUser`

**Returns:** _(none)_

### `GetUserInfo` <a id="fn-unixshellauthorizedkeys-getuserinfo"></a>

**Signature:** `GetUserInfo(Config: Object, Platform: string)`

**Parameters:**

- `Config` (Object, required)
- `Platform` (string, required)

**Caller-scope reads:** `Exception`

**Calls:** `Converse`, `GetOptionalVariableFromResponse`, `GetVariableFromResponse`

**Sets locally:** `ConverseOk`, `GetHomeDirCommand`, `HostnameCommand`, `IdString`, `ResponseResult`, `RunningShell`, `UidString`

**Returns:** _(none)_

### `GetUsersKeystore` <a id="fn-unixshellauthorizedkeys-getuserskeystore"></a>

**Signature:** `GetUsersKeystore(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `GetUsersKeystoreListOpenSsh`, `GetUsersKeystoreListTectia`

**Sets locally:** _(none)_

**Returns:** _(none)_

### `GetSshdConfiguration` <a id="fn-unixshellauthorizedkeys-getsshdconfiguration"></a>

**Signature:** `GetSshdConfiguration(Config: Object, Platform: String)`

**Parameters:**

- `Config` (Object, required)
- `Platform` (String, required)

**Caller-scope reads:** _(none)_

**Calls:** `GetSshdConfigurationOpenSsh`, `GetSshdConfigurationTectia`

**Sets locally:** _(none)_

**Returns:** _(none)_

### `GetAuthKeys` <a id="fn-unixshellauthorizedkeys-getauthkeys"></a>

**Signature:** `GetAuthKeys(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `GetAuthKeysOpenSsh`, `GetAuthKeysTectia`

**Sets locally:** `DiscoveredAuthKeys`, `GLOBAL:DiscoveredAuthKeys`

**Returns:** `%{DiscoveredAuthKeys}%`

### `WriteDiscoveredAuthKeys` <a id="fn-unixshellauthorizedkeys-writediscoveredauthkeys"></a>

**Signature:** `WriteDiscoveredAuthKeys(Config: Object, AuthKeys: Array)`

**Parameters:**

- `Config` (Object, required)
- `AuthKeys` (Array, required)

**Caller-scope reads:** `AccountUserName`

**Calls:** `WriteDiscoveredAuthKeysOpenSsh`

**Sets locally:** _(none)_

**Returns:** _(none)_

### `InitializeSshConfigData` <a id="fn-unixshellauthorizedkeys-initializesshconfigdata"></a>

**Signature:** `InitializeSshConfigData(Platform: string)`

**Parameters:**

- `Platform` (string, required)

**Caller-scope reads:** `AssetName`, `DelegationPrefix`, `Exception`

**Calls:** `GetSshdConfiguration`, `GetUserInfo`, `GetUsersKeystore`, `InitTargetUser`, `UnixGetRemoteClient`

**Sets locally:** `GLOBAL:UsingDefaultKeystoreTemplate`, `SshKeyConfig`, `TemplateListString`

**Returns:** `%{ SshKeyConfig }%`

### `UnixShellDiscoverAuthorizedKeys` <a id="fn-unixshellauthorizedkeys-unixshelldiscoverauthorizedkeys"></a>

**Signature:** `UnixShellDiscoverAuthorizedKeys(Platform: string)`

**Parameters:**

- `Platform` (string, required)

**Caller-scope reads:** `DiscoveredAuthKeysList`

**Calls:** `GetAuthKeys`, `InitializeSshConfigData`, `WriteDiscoveredAuthKeys`

**Sets locally:** `DiscoveredAuthKeys`, `GLOBAL:ConverseOk`, `GLOBAL:DiscoveredAuthKeysList`, `SshKeyConfig`

**Returns:** `false`, `true`

### `UnixShellCheckAuthorizedKey` <a id="fn-unixshellauthorizedkeys-unixshellcheckauthorizedkey"></a>

**Signature:** `UnixShellCheckAuthorizedKey(Platform: string)`

**Parameters:**

- `Platform` (string, required)

**Caller-scope reads:** `DiscoveredAuthKeysList`, `OldSshKey`

**Calls:** `CheckAuthKey`, `GetAuthKeys`, `InitializeSshConfigData`

**Sets locally:** `CheckAuthKeyResult`, `DiscoveredAuthKeys`, `GLOBAL:ConverseOk`, `GLOBAL:DiscoveredAuthKeysDictionary`, `GLOBAL:DiscoveredAuthKeysList`, `KeystoreListString`, `SshKeyConfig`

**Returns:** `%{CheckAuthKeyResult}%`, `false`

### `CheckAuthKey` <a id="fn-unixshellauthorizedkeys-checkauthkey"></a>

**Signature:** `CheckAuthKey(Config: Object, AuthKeysDictionary: Object, OldSshKey: String)`

**Parameters:**

- `Config` (Object, required)
- `AuthKeysDictionary` (Object, required)
- `OldSshKey` (String, required)

**Caller-scope reads:** _(none)_

**Calls:** `CheckSshKeyOpenSsh`, `CheckSshKeystorePermissions`

**Sets locally:** `CheckResult`, `GLOBAL:CheckResult`

**Returns:** `%{CheckResult.KeyExists}%`

### `UnixGetRemoteClient` <a id="fn-unixshellauthorizedkeys-unixgetremoteclient"></a>

**Signature:** `UnixGetRemoteClient(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `Address`

**Calls:** `Converse`, `GetVariableFromResponse`

**Sets locally:** `ConverseOk`, `RemoteHost`, `RemoteIP`, `VariableResponse`

**Returns:** _(none)_

### `CheckSshKeystorePermissions` <a id="fn-unixshellauthorizedkeys-checksshkeystorepermissions"></a>

**Signature:** `CheckSshKeystorePermissions(Config: Object, Keystore: String)`

**Parameters:**

- `Config` (Object, required)
- `Keystore` (String, required)

**Caller-scope reads:** `Group`, `GroupMembers`, `GroupMembership`, `Owner`, `ParentPath`, `Permissions`, `PermissionsCmd`, `PermissionsList`, `PermissionsString`

**Calls:** `Converse`, `GetVariableFromResponse`

**Sets locally:** `ConverseOk`, `GLOBAL:Group`, `GLOBAL:Index`, `GLOBAL:Owner`, `GLOBAL:ParentPath`, `GLOBAL:Permissions`, `GLOBAL:PermissionsCmd`, `GLOBAL:PermissionsString`, `GroupMembersList`, `GroupMembersString`, `UserX`, `VariableResponse`

**Returns:** _(none)_

### `UnixShellRemoveAuthorizedKey` <a id="fn-unixshellauthorizedkeys-unixshellremoveauthorizedkey"></a>

**Signature:** `UnixShellRemoveAuthorizedKey(Platform: string)`

**Parameters:**

- `Platform` (string, required)

**Caller-scope reads:** `ServerSoftwareName`

**Calls:** `Converse`, `InitializeSshConfigData`, `InitializeSshConfigTectia`, `RemoveKeyOpenSsh`, `RemoveKeyTectia`

**Sets locally:** `ConverseOk`, `GLOBAL:ConverseOk`, `GLOBAL:SshKeyConfig`, `SshKeyConfig`, `SshServerType`

**Returns:** `false`, `true`

## Library: `UnixShellAuthorizedKeysOpenSsh` <a id="library-unixshellauthorizedkeysopenssh"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`RunSshdCommand`](#fn-unixshellauthorizedkeysopenssh-runsshdcommand) | Desc, Args, SearchStr | `ConverseResponse` | `Config`, `DelegationPrefix`, `FoundStr` |
| [`GetSshdConfigurationOpenSsh`](#fn-unixshellauthorizedkeysopenssh-getsshdconfigurationopenssh) | Config, Platform | `GetAuthCommandAndUserOpenSsh`, `GetKeystoreTemplateListOpenSsh`, `GetSshdConfigurationPathOpenSsh` | _(none)_ |
| [`GetAuthCommandAndUserOpenSsh`](#fn-unixshellauthorizedkeysopenssh-getauthcommandanduseropenssh) | Config | `RunSshdCommand` | _(none)_ |
| [`GetSshdConfigurationPathOpenSsh`](#fn-unixshellauthorizedkeysopenssh-getsshdconfigurationpathopenssh) | Config, Platform | `Converse`, `GetOptionalVariableFromResponse` | `DelegationPrefix`, `SshKeyConfig` |
| [`GetKeystoreTemplateListOpenSsh`](#fn-unixshellauthorizedkeysopenssh-getkeystoretemplatelistopenssh) | Config | `CheckForDnsUsageConfig`, `CheckForPublicKeyAuthConfig`, `RunSshdCommand` | _(none)_ |
| [`GetUsersKeystoreListOpenSsh`](#fn-unixshellauthorizedkeysopenssh-getuserskeystorelistopenssh) | Config | `GetUsersKeystoreOpenSsh` | `one` |
| [`GetUsersKeystoreOpenSsh`](#fn-unixshellauthorizedkeysopenssh-getuserskeystoreopenssh) | Config, Template | _(none)_ | `SshKeyStore` |
| [`GetAuthKeysOpenSsh`](#fn-unixshellauthorizedkeysopenssh-getauthkeysopenssh) | Config | `ConverseResponse`, `EvaluateMatchHostConfigurationOpenSsh`, `GetAuthKeysForOneKeystoreOpenSsh`, `SplitAuthKeys` | `AssetName`, `DelegationPrefix`, `DiscoveredKeysDictionary`, `DiscoveredKeysList`, `Keystore` |
| [`SplitAuthKeys`](#fn-unixshellauthorizedkeysopenssh-splitauthkeys) | AuthKeys, Filename | `ValidateBase64String` | `Key` |
| [`GetAuthKeysForOneKeystoreOpenSsh`](#fn-unixshellauthorizedkeysopenssh-getauthkeysforonekeystoreopenssh) | Config, Keystore | `Converse`, `ConverseResponse`, `SplitAuthKeys` | `AssetName`, `FuncUserName` |
| [`WriteDiscoveredAuthKeysOpenSsh`](#fn-unixshellauthorizedkeysopenssh-writediscoveredauthkeysopenssh) | Keys | _(none)_ | `Key` |
| [`CheckSshKeyOpenSsh`](#fn-unixshellauthorizedkeysopenssh-checksshkeyopenssh) | AuthKeyDictionary, OldSshKey | _(none)_ | `AllAuthKeys`, `AuthKeyEntry` |
| [`EvaluateMatchHostConfigurationOpenSsh`](#fn-unixshellauthorizedkeysopenssh-evaluatematchhostconfigurationopenssh) | Config | `ConverseResponse` | `AssetName`, `DelegationPrefix`, `MatchHosts`, `MatchHostsArray` |
| [`CheckForDnsUsageConfig`](#fn-unixshellauthorizedkeysopenssh-checkfordnsusageconfig) | Config | `RunSshdCommand` | _(none)_ |
| [`CheckForPublicKeyAuthConfig`](#fn-unixshellauthorizedkeysopenssh-checkforpublickeyauthconfig) | Config | `RunSshdCommand` | `AssetName` |
| [`RemovePromptSymbolFromEnd`](#fn-unixshellauthorizedkeysopenssh-removepromptsymbolfromend) | AuthKeys | _(none)_ | _(none)_ |

### `RunSshdCommand` <a id="fn-unixshellauthorizedkeysopenssh-runsshdcommand"></a>

**Signature:** `RunSshdCommand(Desc: string, Args: string, SearchStr: string)`

**Parameters:**

- `Desc` (string, required)
- `Args` (string, required)
- `SearchStr` (string, required)

**Caller-scope reads:** `Config`, `DelegationPrefix`, `FoundStr`

**Calls:** `ConverseResponse`

**Sets locally:** `CheckString`, `Response`, `VarName`

**Returns:** _(none)_

### `GetSshdConfigurationOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-getsshdconfigurationopenssh"></a>

**Signature:** `GetSshdConfigurationOpenSsh(Config: Object, Platform: String)`

**Parameters:**

- `Config` (Object, required)
- `Platform` (String, required)

**Caller-scope reads:** _(none)_

**Calls:** `GetAuthCommandAndUserOpenSsh`, `GetKeystoreTemplateListOpenSsh`, `GetSshdConfigurationPathOpenSsh`

**Sets locally:** _(none)_

**Returns:** _(none)_

### `GetAuthCommandAndUserOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-getauthcommandanduseropenssh"></a>

**Signature:** `GetAuthCommandAndUserOpenSsh(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `RunSshdCommand`

**Sets locally:** `CheckTemplate`, `FoundStr`, `SshAuthKeysCmd`, `SshAuthKeysCmdTemplate`, `SshdResponse`

**Returns:** _(none)_

### `GetSshdConfigurationPathOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-getsshdconfigurationpathopenssh"></a>

**Signature:** `GetSshdConfigurationPathOpenSsh(Config: Object, Platform: String)`

**Parameters:**

- `Config` (Object, required)
- `Platform` (String, required)

**Caller-scope reads:** `DelegationPrefix`, `SshKeyConfig`

**Calls:** `Converse`, `GetOptionalVariableFromResponse`

**Sets locally:** `ConverseOk`, `FoundPath`, `Global:FoundPath`

**Returns:** _(none)_

### `GetKeystoreTemplateListOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-getkeystoretemplatelistopenssh"></a>

**Signature:** `GetKeystoreTemplateListOpenSsh(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `CheckForDnsUsageConfig`, `CheckForPublicKeyAuthConfig`, `RunSshdCommand`

**Sets locally:** `FoundStr`, `GLOBAL:UsingDefaultKeystoreTemplate`, `SshdResponse`, `TemplateHashSet`, `TemplateString`

**Returns:** _(none)_

### `GetUsersKeystoreListOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-getuserskeystorelistopenssh"></a>

**Signature:** `GetUsersKeystoreListOpenSsh(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `one`

**Calls:** `GetUsersKeystoreOpenSsh`

**Sets locally:** `count`, `Keyfiles`, `KeyListString`, `KeyPath`, `KeystoreTemplateList`, `KeystoreTemplateListCount`

**Returns:** _(none)_

### `GetUsersKeystoreOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-getuserskeystoreopenssh"></a>

**Signature:** `GetUsersKeystoreOpenSsh(Config: Object, Template: string)`

**Parameters:**

- `Config` (Object, required)
- `Template` (string, required)

**Caller-scope reads:** `SshKeyStore`

**Calls:** _(none)_

**Sets locally:** `GLOBAL:SshKeyStore`

**Returns:** `%{SshKeyStore}%`

### `GetAuthKeysOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-getauthkeysopenssh"></a>

**Signature:** `GetAuthKeysOpenSsh(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `AssetName`, `DelegationPrefix`, `DiscoveredKeysDictionary`, `DiscoveredKeysList`, `Keystore`

**Calls:** `ConverseResponse`, `EvaluateMatchHostConfigurationOpenSsh`, `GetAuthKeysForOneKeystoreOpenSsh`, `SplitAuthKeys`

**Sets locally:** `AuthKeys`, `DiscoveredKeys`, `GLOBAL:AuthKeys`, `GLOBAL:DiscoveredKeys`, `GLOBAL:DiscoveredKeysDictionary`, `GLOBAL:DiscoveredKeysList`, `KeystoreList`, `Response`

**Returns:** _(none)_

### `SplitAuthKeys` <a id="fn-unixshellauthorizedkeysopenssh-splitauthkeys"></a>

**Signature:** `SplitAuthKeys(AuthKeys: String, Filename: String)`

**Parameters:**

- `AuthKeys` (String, required)
- `Filename` (String, required)

**Caller-scope reads:** `Key`

**Calls:** `ValidateBase64String`

**Sets locally:** `KeyCount`, `KeyList`, `KeyMatch`, `KeyString`, `KeyStringIsValidBase64`, `OneKey`, `UnexpectedEntries`, `UnexpectedEntriesCount`, `UnexpectedEntriesList`

**Returns:** `%{KeyList}%`

### `GetAuthKeysForOneKeystoreOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-getauthkeysforonekeystoreopenssh"></a>

**Signature:** `GetAuthKeysForOneKeystoreOpenSsh(Config: Object, Keystore: String)`

**Parameters:**

- `Config` (Object, required)
- `Keystore` (String, required)

**Caller-scope reads:** `AssetName`, `FuncUserName`

**Calls:** `Converse`, `ConverseResponse`, `SplitAuthKeys`

**Sets locally:** `AuthKeys`, `ConverseOk`, `DiscoveredKeyList`, `Response`

**Returns:** `%{DiscoveredKeyList}%`, `null`

### `WriteDiscoveredAuthKeysOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-writediscoveredauthkeysopenssh"></a>

**Signature:** `WriteDiscoveredAuthKeysOpenSsh(Keys: Array)`

**Parameters:**

- `Keys` (Array, required)

**Caller-scope reads:** `Key`

**Calls:** _(none)_

**Sets locally:** `KeyCount`

**Returns:** _(none)_

### `CheckSshKeyOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-checksshkeyopenssh"></a>

**Signature:** `CheckSshKeyOpenSsh(AuthKeyDictionary: Object, OldSshKey: String)`

**Parameters:**

- `AuthKeyDictionary` (Object, required)
- `OldSshKey` (String, required)

**Caller-scope reads:** `AllAuthKeys`, `AuthKeyEntry`

**Calls:** _(none)_

**Sets locally:** `CompareKey`, `GLOBAL:AllAuthKeys`

**Returns:** _(none)_

### `EvaluateMatchHostConfigurationOpenSsh` <a id="fn-unixshellauthorizedkeysopenssh-evaluatematchhostconfigurationopenssh"></a>

**Signature:** `EvaluateMatchHostConfigurationOpenSsh(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `AssetName`, `DelegationPrefix`, `MatchHosts`, `MatchHostsArray`

**Calls:** `ConverseResponse`

**Sets locally:** `GLOBAL:MatchHosts`, `MatchHostString`, `Response`, `ResponseResult`

**Returns:** _(none)_

### `CheckForDnsUsageConfig` <a id="fn-unixshellauthorizedkeysopenssh-checkfordnsusageconfig"></a>

**Signature:** `CheckForDnsUsageConfig(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `RunSshdCommand`

**Sets locally:** `SshdResponse`, `UseDns`

**Returns:** _(none)_

### `CheckForPublicKeyAuthConfig` <a id="fn-unixshellauthorizedkeysopenssh-checkforpublickeyauthconfig"></a>

**Signature:** `CheckForPublicKeyAuthConfig(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `AssetName`

**Calls:** `RunSshdCommand`

**Sets locally:** `SshdResponse`

**Returns:** _(none)_

### `RemovePromptSymbolFromEnd` <a id="fn-unixshellauthorizedkeysopenssh-removepromptsymbolfromend"></a>

**Signature:** `RemovePromptSymbolFromEnd(AuthKeys: String)`

**Parameters:**

- `AuthKeys` (String, required)

**Caller-scope reads:** _(none)_

**Calls:** _(none)_

**Sets locally:** `LastIndexOfNewLine`

**Returns:** ``, `%AuthKeys%`

## Library: `UnixShellChangeSshKey` <a id="library-unixshellchangesshkey"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`UnixCheckKeyActionRequired`](#fn-unixshellchangesshkey-unixcheckkeyactionrequired) | _(none)_ | _(none)_ | `NewSshKey`, `NewSshPrivateKey` |
| [`SetPermissions`](#fn-unixshellchangesshkey-setpermissions) | Desc, Path, IsFile, Config | `Converse` | _(none)_ |
| [`InitSshEnvironmentVars`](#fn-unixshellchangesshkey-initsshenvironmentvars) | _(none)_ | `Converse` | `NewSshKey`, `NewSshKeyComment`, `OldSshKey` |
| [`UnixShellChangeSshKey`](#fn-unixshellchangesshkey-unixshellchangesshkey) | Platform | `ChangeSshKeyOpenSsh`, `ChangeSshKeyTectia`, `UnixCheckKeyActionRequired` | `ServerSoftwareName` |

### `UnixCheckKeyActionRequired` <a id="fn-unixshellchangesshkey-unixcheckkeyactionrequired"></a>

**Signature:** `UnixCheckKeyActionRequired(_(none)_)`

**Caller-scope reads:** `NewSshKey`, `NewSshPrivateKey`

**Calls:** _(none)_

**Sets locally:** `Add`, `OldSshKey`, `Remove`, `ReplaceExistingKeys`

**Returns:** _(none)_

### `SetPermissions` <a id="fn-unixshellchangesshkey-setpermissions"></a>

**Signature:** `SetPermissions(Desc: string, Path: string, IsFile: boolean, Config: Object)`

**Parameters:**

- `Desc` (string, required)
- `Path` (string, required)
- `IsFile` (boolean, required)
- `Config` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `Converse`

**Sets locally:** `ConverseOk`, `Ownership`, `Perm`

**Returns:** _(none)_

### `InitSshEnvironmentVars` <a id="fn-unixshellchangesshkey-initsshenvironmentvars"></a>

**Signature:** `InitSshEnvironmentVars(_(none)_)`

**Caller-scope reads:** `NewSshKey`, `NewSshKeyComment`, `OldSshKey`

**Calls:** `Converse`

**Sets locally:** `ConverseOk`, `converseOk`

**Returns:** _(none)_

### `UnixShellChangeSshKey` <a id="fn-unixshellchangesshkey-unixshellchangesshkey"></a>

**Signature:** `UnixShellChangeSshKey(Platform: string)`

**Parameters:**

- `Platform` (string, required)

**Caller-scope reads:** `ServerSoftwareName`

**Calls:** `ChangeSshKeyOpenSsh`, `ChangeSshKeyTectia`, `UnixCheckKeyActionRequired`

**Sets locally:** `GLOBAL:ConverseOk`, `GLOBAL:KeyChangeRequired`, `GLOBAL:SshKeyConfig`, `KeyChangeRequired`, `SshServerType`

**Returns:** `true`

## Library: `UnixShellChangeSshKeyOpenSsh` <a id="library-unixshellchangesshkeyopenssh"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`CleanUpOpenSsh`](#fn-unixshellchangesshkeyopenssh-cleanupopenssh) | Config, Rollback | `Converse` | _(none)_ |
| [`RemoveKeyOpenSsh`](#fn-unixshellchangesshkeyopenssh-removekeyopenssh) | Config | `AssignSshKeyToShellVariable`, `Converse`, `IsOldKeyInOpenSshKeystore`, `SetPermissions` | `AccountUserName`, `AssetName`, `OldSshKey` |
| [`ConfigureNewKeyOpenSsh`](#fn-unixshellchangesshkeyopenssh-configurenewkeyopenssh) | Config | `AddKeyToKeystoreOpenSsh`, `BackupKeystoreOpenSsh`, ...(6 more) | `NewSshKeyComment` |
| [`IsOldKeyInOpenSshKeystore`](#fn-unixshellchangesshkeyopenssh-isoldkeyinopensshkeystore) | Config | `Converse` | `Keystore`, `OldSshKey`, `OldSshKeyAsShellVariable` |
| [`IsNewKeyInOpenSshKeystore`](#fn-unixshellchangesshkeyopenssh-isnewkeyinopensshkeystore) | Config | `AssignSshKeyToShellVariable`, `Converse`, `GetVariableFromResponse`, `SplitAuthKeys` | `Keystore`, `NewSshKey`, `NewSshKeyComment`, `OriginalNewSshKeyComment`, `ReplaceExistingKeys` |
| [`CreateKeystoreDirOpenSsh`](#fn-unixshellchangesshkeyopenssh-createkeystorediropenssh) | Config, KeystoreAdd | `Converse`, `GetVariableFromResponse`, `SetPermissions` | _(none)_ |
| [`CreateKeystoreFileOpenSsh`](#fn-unixshellchangesshkeyopenssh-createkeystorefileopenssh) | Config, Keystore | `Converse`, `GetVariableFromResponse`, `SetPermissions` | _(none)_ |
| [`BackupKeystoreOpenSsh`](#fn-unixshellchangesshkeyopenssh-backupkeystoreopenssh) | Config, Keystore | `Converse`, `SetPermissions` | _(none)_ |
| [`AddKeyToKeystoreOpenSsh`](#fn-unixshellchangesshkeyopenssh-addkeytokeystoreopenssh) | Config, Keystore | `AssignSshKeyToShellVariable`, `Converse`, `SetPermissions` | `NewSshKey`, `NewSshKeyAndComment`, `NewSshKeyComment`, `ReplaceExistingKeys` |
| [`ChangeSshKeyOpenSsh`](#fn-unixshellchangesshkeyopenssh-changesshkeyopenssh) | Platform | `CleanUpOpenSsh`, `ConfigureNewKeyOpenSsh`, ...(4 more) | `KeyChangeRequired`, `NewSshPrivateKey`, `ReplaceExistingKeys` |
| [`ReplaceKeyCommentOpenSsh`](#fn-unixshellchangesshkeyopenssh-replacekeycommentopenssh) | Config, NewKeyWithOldComment, NewKeyWithNewComment, KeystoreToEdit | `AssignSshKeyToShellVariable`, `Converse`, `SetPermissions` | `Exception`, `NewSshKey` |

### `CleanUpOpenSsh` <a id="fn-unixshellchangesshkeyopenssh-cleanupopenssh"></a>

**Signature:** `CleanUpOpenSsh(Config: Object, Rollback: boolean)`

**Parameters:**

- `Config` (Object, required)
- `Rollback` (boolean, required)

**Caller-scope reads:** _(none)_

**Calls:** `Converse`

**Sets locally:** `backupfile`, `ConverseOk`, `Keyfile`, `tmpfile`

**Returns:** _(none)_

### `RemoveKeyOpenSsh` <a id="fn-unixshellchangesshkeyopenssh-removekeyopenssh"></a>

**Signature:** `RemoveKeyOpenSsh(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `AccountUserName`, `AssetName`, `OldSshKey`

**Calls:** `AssignSshKeyToShellVariable`, `Converse`, `IsOldKeyInOpenSshKeystore`, `SetPermissions`

**Sets locally:** `ConverseOk`, `GLOBAL:OldSshKeyAsShellVariable`, `KeyConfigured`, `KeystoreRemove`, `OldSshKeyAsShellVariable`, `TempFile`

**Returns:** _(none)_

### `ConfigureNewKeyOpenSsh` <a id="fn-unixshellchangesshkeyopenssh-configurenewkeyopenssh"></a>

**Signature:** `ConfigureNewKeyOpenSsh(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `NewSshKeyComment`

**Calls:** `AddKeyToKeystoreOpenSsh`, `BackupKeystoreOpenSsh`, `CleanUpOpenSsh`, `CreateKeystoreDirOpenSsh`, `CreateKeystoreFileOpenSsh`, `EscapeSingleQuoteFromString`, `IsNewKeyInOpenSshKeystore`, `ReplaceKeyCommentOpenSsh`

**Sets locally:** `%NewSshKeyComment%`, `CommentConfigResult`, `GLOBAL:OriginalNewSshKeyComment`, `KeystoreList`, `NewKeyConfigured`

**Returns:** `%{CommentConfigResult}%`, `false`, `true`

### `IsOldKeyInOpenSshKeystore` <a id="fn-unixshellchangesshkeyopenssh-isoldkeyinopensshkeystore"></a>

**Signature:** `IsOldKeyInOpenSshKeystore(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `Keystore`, `OldSshKey`, `OldSshKeyAsShellVariable`

**Calls:** `Converse`

**Sets locally:** `ConverseOk`, `KeystoreList`

**Returns:** `false`, `true`

### `IsNewKeyInOpenSshKeystore` <a id="fn-unixshellchangesshkeyopenssh-isnewkeyinopensshkeystore"></a>

**Signature:** `IsNewKeyInOpenSshKeystore(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `Keystore`, `NewSshKey`, `NewSshKeyComment`, `OriginalNewSshKeyComment`, `ReplaceExistingKeys`

**Calls:** `AssignSshKeyToShellVariable`, `Converse`, `GetVariableFromResponse`, `SplitAuthKeys`

**Sets locally:** `AuthKey`, `AuthKeyComment`, `ConnectSsh`, `ConverseOk`, `DiscoveredKeyList`, `GLOBAL:NewSshKeyAsShellVariable`, `KeystoreList`, `NewKeyWithNewComment`, `NewKeyWithOldComment`, `NewSshKeyAsShellVariable`, `ReturnStatus`

**Returns:** `false`

### `CreateKeystoreDirOpenSsh` <a id="fn-unixshellchangesshkeyopenssh-createkeystorediropenssh"></a>

**Signature:** `CreateKeystoreDirOpenSsh(Config: Object, KeystoreAdd: String)`

**Parameters:**

- `Config` (Object, required)
- `KeystoreAdd` (String, required)

**Caller-scope reads:** _(none)_

**Calls:** `Converse`, `GetVariableFromResponse`, `SetPermissions`

**Sets locally:** `ConverseOk`, `KeystoreDir`, `PermissionValue`

**Returns:** _(none)_

### `CreateKeystoreFileOpenSsh` <a id="fn-unixshellchangesshkeyopenssh-createkeystorefileopenssh"></a>

**Signature:** `CreateKeystoreFileOpenSsh(Config: Object, Keystore: String)`

**Parameters:**

- `Config` (Object, required)
- `Keystore` (String, required)

**Caller-scope reads:** _(none)_

**Calls:** `Converse`, `GetVariableFromResponse`, `SetPermissions`

**Sets locally:** `ConverseOk`, `Owner`, `Permission`

**Returns:** _(none)_

### `BackupKeystoreOpenSsh` <a id="fn-unixshellchangesshkeyopenssh-backupkeystoreopenssh"></a>

**Signature:** `BackupKeystoreOpenSsh(Config: Object, Keystore: String)`

**Parameters:**

- `Config` (Object, required)
- `Keystore` (String, required)

**Caller-scope reads:** _(none)_

**Calls:** `Converse`, `SetPermissions`

**Sets locally:** `ConverseOk`, `KeystoreBackupFile`

**Returns:** _(none)_

### `AddKeyToKeystoreOpenSsh` <a id="fn-unixshellchangesshkeyopenssh-addkeytokeystoreopenssh"></a>

**Signature:** `AddKeyToKeystoreOpenSsh(Config: Object, Keystore: String)`

**Parameters:**

- `Config` (Object, required)
- `Keystore` (String, required)

**Caller-scope reads:** `NewSshKey`, `NewSshKeyAndComment`, `NewSshKeyComment`, `ReplaceExistingKeys`

**Calls:** `AssignSshKeyToShellVariable`, `Converse`, `SetPermissions`

**Sets locally:** `ConverseOk`, `GLOBAL:NewSshKeyAndComment`, `GLOBAL:NewSshKeyAndCommentAsShellVariable`, `NewSshKeyAndCommentAsShellVariable`, `TempFile`

**Returns:** _(none)_

### `ChangeSshKeyOpenSsh` <a id="fn-unixshellchangesshkeyopenssh-changesshkeyopenssh"></a>

**Signature:** `ChangeSshKeyOpenSsh(Platform: string)`

**Parameters:**

- `Platform` (string, required)

**Caller-scope reads:** `KeyChangeRequired`, `NewSshPrivateKey`, `ReplaceExistingKeys`

**Calls:** `CleanUpOpenSsh`, `ConfigureNewKeyOpenSsh`, `Converse`, `InitializeSshConfigData`, `RemoveKeyOpenSsh`, `TestNewKey`

**Sets locally:** `ConfigureResult`, `ConverseOk`, `SshKeyConfig`

**Returns:** `false`, `true`

### `ReplaceKeyCommentOpenSsh` <a id="fn-unixshellchangesshkeyopenssh-replacekeycommentopenssh"></a>

**Signature:** `ReplaceKeyCommentOpenSsh(Config: Object, NewKeyWithOldComment: String, NewKeyWithNewComment: String, KeystoreToEdit: String)`

**Parameters:**

- `Config` (Object, required)
- `NewKeyWithOldComment` (String, required)
- `NewKeyWithNewComment` (String, required)
- `KeystoreToEdit` (String, required)

**Caller-scope reads:** `Exception`, `NewSshKey`

**Calls:** `AssignSshKeyToShellVariable`, `Converse`, `SetPermissions`

**Sets locally:** `BackupFile`, `ChangeResult`, `ConverseOk`, `GLOBAL:NewKeyWithNewCommentAsShellVariable`, `GLOBAL:NewSshKeyAsShellVariable`, `NewKeyWithNewCommentAsShellVariable`, `NewSshKeyAsShellVariable`, `TempFile`

**Returns:** `%{ChangeResult}%`

## Library: `UnixShellDiscoverAccounts` <a id="library-unixshelldiscoveraccounts"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`RunCmd`](#fn-unixshelldiscoveraccounts-runcmd) | Cmd, ExpectRegex | _(none)_ | `DelegationPrefix`, `FuncPassword` |
| [`DiscoverAccountsOnHost`](#fn-unixshelldiscoveraccounts-discoveraccountsonhost) | Platform? | `RunCmd` | `AssetName`, `DelegationPrefix` |

### `RunCmd` <a id="fn-unixshelldiscoveraccounts-runcmd"></a>

**Signature:** `RunCmd(Cmd: string, ExpectRegex: string)`

**Parameters:**

- `Cmd` (string, required)
- `ExpectRegex` (string, required)

**Caller-scope reads:** `DelegationPrefix`, `FuncPassword`

**Calls:** _(none)_

**Sets locally:** `CmdResponse`, `ConnectSsh`

**Returns:** _(none)_

### `DiscoverAccountsOnHost` <a id="fn-unixshelldiscoveraccounts-discoveraccountsonhost"></a>

**Signature:** `DiscoverAccountsOnHost(Platform?: string = Generic)`

**Parameters:**

- `Platform` (string, optional, default: Generic)

**Caller-scope reads:** `AssetName`, `DelegationPrefix`

**Calls:** `RunCmd`

**Sets locally:** `Awkcmd`, `DiscoveryResult`, `GetDiscoverDataSendBuffer`, `GroupNames`, `Idcmd`, `match`, `Pwdfile`, `UserCount`, `UserCountCmd`, `UserCountCmdResult`, `UserCountMatch`, `UserCountResult`, `UserListCmdResult`, `UserListString`

**Returns:** `%{ DiscoveryResult }%`

## Library: `UnixShellSshFunctions` <a id="library-unixshellsshfunctions"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`ChangeAccountMembershipList`](#fn-unixshellsshfunctions-changeaccountmembershiplist) | AccountMode, Groups | `ChangeAccountMembership` | `AccountUserName` |
| [`ChangeAccountMembership`](#fn-unixshellsshfunctions-changeaccountmembership) | AccountMode, GroupList | _(none)_ | `AccountUserName`, `DelegationPrefix`, `FuncPassword` |

### `ChangeAccountMembershipList` <a id="fn-unixshellsshfunctions-changeaccountmembershiplist"></a>

**Signature:** `ChangeAccountMembershipList(AccountMode: String, Groups: array)`

**Parameters:**

- `AccountMode` (String, required)
- `Groups` (array, required)

**Caller-scope reads:** `AccountUserName`

**Calls:** `ChangeAccountMembership`

**Sets locally:** `GroupList`, `Result`

**Returns:** `%Result%`

### `ChangeAccountMembership` <a id="fn-unixshellsshfunctions-changeaccountmembership"></a>

**Signature:** `ChangeAccountMembership(AccountMode: String, GroupList: string)`

**Parameters:**

- `AccountMode` (String, required)
- `GroupList` (string, required)

**Caller-scope reads:** `AccountUserName`, `DelegationPrefix`, `FuncPassword`

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`, `Global:ReceiveBuffer`, `ReceiveBuffer`, `ReturnStatus`

**Returns:** `False`, `false`, `true`

## Library: `ResolveAssetName` <a id="library-resolveassetname"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`ResolveAssetNameIfEmpty`](#fn-resolveassetname-resolveassetnameifempty) | _(none)_ | _(none)_ | `Address` |

### `ResolveAssetNameIfEmpty` <a id="fn-resolveassetname-resolveassetnameifempty"></a>

**Signature:** `ResolveAssetNameIfEmpty(_(none)_)`

**Caller-scope reads:** `Address`

**Calls:** _(none)_

**Sets locally:** `AssetName`

**Returns:** _(none)_

## Library: `ReturnOperationResultSsh` <a id="library-returnoperationresultssh"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`ReturnOperationResult`](#fn-returnoperationresultssh-returnoperationresult) | _(none)_ | _(none)_ | `OperationResult` |

### `ReturnOperationResult` <a id="fn-returnoperationresultssh-returnoperationresult"></a>

**Signature:** `ReturnOperationResult(_(none)_)`

**Caller-scope reads:** `OperationResult`

**Calls:** _(none)_

**Sets locally:** _(none)_

**Returns:** _(none)_

## Library: `WindowsSshFunctions` <a id="library-windowssshfunctions"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`WinLoginSshAttempt`](#fn-windowssshfunctions-winloginsshattempt) | UserName, Password?, LoginKey?, Term | _(none)_ | `Address`, `CheckHostKey`, ...(5 more) |
| [`WinLoginInteractiveSsh`](#fn-windowssshfunctions-winlogininteractivessh) | UserName, Password?, LoginKey?, UserDomain?, TerminalRequired | `ResolveAssetNameIfEmpty`, `WinLoginSshAttempt` | `Address`, `AssetName`, `Exception`, `FuncUserName`, `ServerSoftwareName` |
| [`WinLoginBatchModeSsh`](#fn-windowssshfunctions-winloginbatchmodessh) | UserName, Password?, LoginKey?, UserDomain? | `ResolveAssetNameIfEmpty`, `WinValidateServiceAccount` | `Address`, `AssetName`, ...(9 more) |
| [`WinValidateServiceAccount`](#fn-windowssshfunctions-winvalidateserviceaccount) | LocalUser, CmdContext | `WinRunBatchCommand` | `Address`, `AssetName` |
| [`WinValidateAccountExists`](#fn-windowssshfunctions-winvalidateaccountexists) | QuotedUserName, CmdContext | `WinRunBatchCommand` | _(none)_ |
| [`WinCheckError`](#fn-windowssshfunctions-wincheckerror) | Output | _(none)_ | `AccountUserName`, `AssetName` |
| [`WinChangeUserPassword`](#fn-windowssshfunctions-winchangeuserpassword) | _(none)_ | `WinCheckError` | `AccountUserName`, `AssetName`, `Exception`, `NewPassword` |
| [`WinChangeUserPasswordBatch`](#fn-windowssshfunctions-winchangeuserpasswordbatch) | IgnorePrefix | `WinCheckError`, `WinCheckForPowershell`, `WinQuoteUser`, `WinRunBatchStrictCommand` | `AccountUserName`, `Exception`, `NewPassword` |
| [`WinChangeAccountMode`](#fn-windowssshfunctions-winchangeaccountmode) | AccountMode | `WinCheckForPowershell`, `WinLoginBatchModeSsh`, `WinQuoteUser`, `WinRunBatchCommand` | `AccountUserName`, `FuncPassword`, `FuncUserDomain`, `FuncUserName`, `UserKey` |
| [`WinChangeAccountMembership`](#fn-windowssshfunctions-winchangeaccountmembership) | AccountMode, Groups | `WinCheckForPowershell`, `WinLoginBatchModeSsh`, `WinRunBatchCommand` | `AccountUserName`, `FuncPassword`, `FuncUserDomain`, `FuncUserName`, `Group`, `UserKey` |
| [`WinValidatePassword`](#fn-windowssshfunctions-winvalidatepassword) | _(none)_ | _(none)_ | `AccountPassword`, `AccountUserName`, ...(5 more) |
| [`WinCheckForPowershell`](#fn-windowssshfunctions-wincheckforpowershell) | IgnorePrefix? | `WinRunBatchCommand` | _(none)_ |
| [`WinRunBatchCommand`](#fn-windowssshfunctions-winrunbatchcommand) | ConvDescription, Line, SuccessRegex, CommandContainsSecret, OutputContainsSecret, UseCmd, SuppressExceptions | _(none)_ | `AssetName`, `Exception`, `rc`, `Reuse`, `Timeout` |
| [`WinRunBatchStrictCommand`](#fn-windowssshfunctions-winrunbatchstrictcommand) | ConvDescription, Line, SuccessRegex, CommandContainsSecret, OutputContainsSecret, UseCmd | `WinRunBatchCommand` | _(none)_ |

### `WinLoginSshAttempt` <a id="fn-windowssshfunctions-winloginsshattempt"></a>

**Signature:** `WinLoginSshAttempt(UserName: String, Password?: Secret, LoginKey?: Secret, Term: boolean)`

**Parameters:**

- `UserName` (String, required)
- `Password` (Secret, optional)
- `LoginKey` (Secret, optional)
- `Term` (boolean, required)

**Caller-scope reads:** `Address`, `CheckHostKey`, `EndOfDataSuffix`, `Exception`, `HostKey`, `Port`, `Timeout`

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`

**Returns:** `false`, `true`

### `WinLoginInteractiveSsh` <a id="fn-windowssshfunctions-winlogininteractivessh"></a>

**Signature:** `WinLoginInteractiveSsh(UserName: String, Password?: Secret, LoginKey?: Secret, UserDomain?: String, TerminalRequired: boolean)`

**Parameters:**

- `UserName` (String, required)
- `Password` (Secret, optional)
- `LoginKey` (Secret, optional)
- `UserDomain` (String, optional)
- `TerminalRequired` (boolean, required)

**Caller-scope reads:** `Address`, `AssetName`, `Exception`, `FuncUserName`, `ServerSoftwareName`

**Calls:** `ResolveAssetNameIfEmpty`, `WinLoginSshAttempt`

**Sets locally:** `ConnectSsh`, `EndOfDataSuffix`, `Errorstring`, `GLOBAL:ConnectSsh`, `GLOBAL:EndOfDataSuffix`, `GLOBAL:ServerSoftwareName`, `loginAttempt`, `LoginCheckBuffer`, `UserName`

**Returns:** `false`, `true`

### `WinLoginBatchModeSsh` <a id="fn-windowssshfunctions-winloginbatchmodessh"></a>

**Signature:** `WinLoginBatchModeSsh(UserName: String, Password?: Secret, LoginKey?: Secret, UserDomain?: String)`

**Parameters:**

- `UserName` (String, required)
- `Password` (Secret, optional)
- `LoginKey` (Secret, optional)
- `UserDomain` (String, optional)

**Caller-scope reads:** `Address`, `AssetName`, `CheckHostKey`, `EndOfDataSuffix`, `Exception`, `FuncUserName`, `HostKey`, `Port`, `rc`, `ServerSoftwareName`, `Timeout`

**Calls:** `ResolveAssetNameIfEmpty`, `WinValidateServiceAccount`

**Sets locally:** `CmdContext`, `ConnectSsh`, `ErrBuffer`, `Errorstring`, `FullUserName`, `GLOBAL:ConnectSsh`, `GLOBAL:ServerSoftwareName`, `IgnorePrefix`, `LocalUserName`, `OutputBuffer`, `Pattern`, `UserIndex`, `UserMatch`, `ValidationResult`

**Returns:** _(none)_

### `WinValidateServiceAccount` <a id="fn-windowssshfunctions-winvalidateserviceaccount"></a>

**Signature:** `WinValidateServiceAccount(LocalUser: string, CmdContext: Object)`

**Parameters:**

- `LocalUser` (string, required)
- `CmdContext` (Object, required)

**Caller-scope reads:** `Address`, `AssetName`

**Calls:** `WinRunBatchCommand`

**Sets locally:** `AccessChecked`

**Returns:** `false`, `true`

### `WinValidateAccountExists` <a id="fn-windowssshfunctions-winvalidateaccountexists"></a>

**Signature:** `WinValidateAccountExists(QuotedUserName: String, CmdContext: Object)`

**Parameters:**

- `QuotedUserName` (String, required)
- `CmdContext` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinRunBatchCommand`

**Sets locally:** `AccessChecked`, `err`, `UserExist`

**Returns:** `%{ UserExist }%`

### `WinCheckError` <a id="fn-windowssshfunctions-wincheckerror"></a>

**Signature:** `WinCheckError(Output: string)`

**Parameters:**

- `Output` (string, required)

**Caller-scope reads:** `AccountUserName`, `AssetName`

**Calls:** _(none)_

**Sets locally:** _(none)_

**Returns:** `false`, `true`

### `WinChangeUserPassword` <a id="fn-windowssshfunctions-winchangeuserpassword"></a>

**Signature:** `WinChangeUserPassword(_(none)_)`

**Caller-scope reads:** `AccountUserName`, `AssetName`, `Exception`, `NewPassword`

**Calls:** `WinCheckError`

**Sets locally:** `CommandRan`, `ConnectSsh`, `EndOfDataSuffix`, `ErrRegex`, `OutputOk`, `QuotedCmd`, `ReturnLine`

**Returns:** `false`, `true`

### `WinChangeUserPasswordBatch` <a id="fn-windowssshfunctions-winchangeuserpasswordbatch"></a>

**Signature:** `WinChangeUserPasswordBatch(IgnorePrefix: string)`

**Parameters:**

- `IgnorePrefix` (string, required)

**Caller-scope reads:** `AccountUserName`, `Exception`, `NewPassword`

**Calls:** `WinCheckError`, `WinCheckForPowershell`, `WinQuoteUser`, `WinRunBatchStrictCommand`

**Sets locally:** `CmdContext`, `ErrRegex`, `OpResult`, `OutputOk`, `QuotedUser`, `ReturnLine`

**Returns:** `false`, `true`

### `WinChangeAccountMode` <a id="fn-windowssshfunctions-winchangeaccountmode"></a>

**Signature:** `WinChangeAccountMode(AccountMode: string)`

**Parameters:**

- `AccountMode` (string, required)

**Caller-scope reads:** `AccountUserName`, `FuncPassword`, `FuncUserDomain`, `FuncUserName`, `UserKey`

**Calls:** `WinCheckForPowershell`, `WinLoginBatchModeSsh`, `WinQuoteUser`, `WinRunBatchCommand`

**Sets locally:** `CmdContext`, `IgnorePrefix`, `LoginResult`, `ModeString`, `OpResult`, `QuotedUser`

**Returns:** `%{ OpResult.Result }%`, `Error`, `false`, `true`

### `WinChangeAccountMembership` <a id="fn-windowssshfunctions-winchangeaccountmembership"></a>

**Signature:** `WinChangeAccountMembership(AccountMode: string, Groups: array)`

**Parameters:**

- `AccountMode` (string, required)
- `Groups` (array, required)

**Caller-scope reads:** `AccountUserName`, `FuncPassword`, `FuncUserDomain`, `FuncUserName`, `Group`, `UserKey`

**Calls:** `WinCheckForPowershell`, `WinLoginBatchModeSsh`, `WinRunBatchCommand`

**Sets locally:** `CmdContext`, `IgnorePrefix`, `LoginResult`, `ModeString`, `OpResult`

**Returns:** `Error`, `true`

### `WinValidatePassword` <a id="fn-windowssshfunctions-winvalidatepassword"></a>

**Signature:** `WinValidatePassword(_(none)_)`

**Caller-scope reads:** `AccountPassword`, `AccountUserName`, `Address`, `CheckHostKey`, `HostKey`, `Port`, `Timeout`

**Calls:** _(none)_

**Sets locally:** `TestConnectSsh`

**Returns:** `false`, `true`

### `WinCheckForPowershell` <a id="fn-windowssshfunctions-wincheckforpowershell"></a>

**Signature:** `WinCheckForPowershell(IgnorePrefix?: string)`

**Parameters:**

- `IgnorePrefix` (string, optional)

**Caller-scope reads:** _(none)_

**Calls:** `WinRunBatchCommand`

**Sets locally:** `CheckOutput`, `cmd`, `CmdContext`, `infocmd`, `quote`, `RunningPowershell`, `temp`

**Returns:** `%{ CmdContext }%`

### `WinRunBatchCommand` <a id="fn-windowssshfunctions-winrunbatchcommand"></a>

**Signature:** `WinRunBatchCommand(ConvDescription: string, Line: string, SuccessRegex: string, CommandContainsSecret: boolean, OutputContainsSecret: boolean, UseCmd: Object, SuppressExceptions: boolean)`

**Parameters:**

- `ConvDescription` (string, required)
- `Line` (string, required)
- `SuccessRegex` (string, required)
- `CommandContainsSecret` (boolean, required)
- `OutputContainsSecret` (boolean, required)
- `UseCmd` (Object, required)
- `SuppressExceptions` (boolean, required)

**Caller-scope reads:** `AssetName`, `Exception`, `rc`, `Reuse`, `Timeout`

**Calls:** _(none)_

**Sets locally:** `AccessRegex`, `ConnectSsh`, `ErrBuffer`, `ErrorRegex`, `FullRegex`, `ReturnLine`, `runcmd`

**Returns:** _(none)_

### `WinRunBatchStrictCommand` <a id="fn-windowssshfunctions-winrunbatchstrictcommand"></a>

**Signature:** `WinRunBatchStrictCommand(ConvDescription: string, Line: string, SuccessRegex: string, CommandContainsSecret: boolean, OutputContainsSecret: boolean, UseCmd: Object)`

**Parameters:**

- `ConvDescription` (string, required)
- `Line` (string, required)
- `SuccessRegex` (string, required)
- `CommandContainsSecret` (boolean, required)
- `OutputContainsSecret` (boolean, required)
- `UseCmd` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinRunBatchCommand`

**Sets locally:** `Err`, `OpResult`

**Returns:** `%{ OpResult }%`

## Library: `WindowsSshFunctionsDiscovery` <a id="library-windowssshfunctionsdiscovery"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`WinProcessDiscoveredGroup`](#fn-windowssshfunctionsdiscovery-winprocessdiscoveredgroup) | DiscoveryData, InputString | _(none)_ | `discoveredMembers`, `GroupList`, `oneuser` |
| [`WinProcessAccountDiscoveryData`](#fn-windowssshfunctionsdiscovery-winprocessaccountdiscoverydata) | DiscoveryData, InputString | _(none)_ | `UserList` |
| [`WinDiscoverNextBatchOfAccounts`](#fn-windowssshfunctionsdiscovery-windiscovernextbatchofaccounts) | DiscoveryData, CmdContext | `WinProcessAccountDiscoveryData`, `WinRunBatchCommand` | _(none)_ |
| [`WinDiscoverNextBatchOfGroups`](#fn-windowssshfunctionsdiscovery-windiscovernextbatchofgroups) | DiscoveryData, CmdContext | `WinProcessDiscoveredGroup`, `WinRunBatchCommand` | _(none)_ |
| [`WinCountObjects`](#fn-windowssshfunctionsdiscovery-wincountobjects) | SearchType, CmdContext | `WinRunBatchCommand` | _(none)_ |
| [`WinDiscoverAccountsOnHost`](#fn-windowssshfunctionsdiscovery-windiscoveraccountsonhost) | IgnorePrefix? | `WinCheckForPowershell`, `WinCountObjects`, `WinDiscoverNextBatchOfAccounts`, `WinDiscoverNextBatchOfGroups` | `AssetName`, `oneuser` |
| [`WinFilterDependentUser`](#fn-windowssshfunctionsdiscovery-winfilterdependentuser) | variablename, HostIdentity, IncludeLocal, ObjectSid | _(none)_ | `DependentUsername` |
| [`WinGetRunningDependenciesList`](#fn-windowssshfunctionsdiscovery-wingetrunningdependencieslist) | ServiceName, DisplayName, Context | `WinRunBatchCommand` | `DepList`, `one` |
| [`WinStopService`](#fn-windowssshfunctionsdiscovery-winstopservice) | ServiceName, DisplayName, Context | `WinRunBatchCommand`, `WinStoppingServices` | _(none)_ |
| [`CheckUpdatedServices`](#fn-windowssshfunctionsdiscovery-checkupdatedservices) | DepList, Context, RunningState | `WinRunBatchCommand` | _(none)_ |
| [`WinStartService`](#fn-windowssshfunctionsdiscovery-winstartservice) | RestartServiceName, Context | `WinRunBatchCommand` | _(none)_ |
| [`WinRestartDependencyList`](#fn-windowssshfunctionsdiscovery-winrestartdependencylist) | DepList, Context | `WinStartService` | _(none)_ |
| [`WinStoppingServices`](#fn-windowssshfunctionsdiscovery-winstoppingservices) | ServiceName, ServiceDisplayName, Result, Output, Error | _(none)_ | `oneline` |
| [`WinTryToStopDependentServices`](#fn-windowssshfunctionsdiscovery-wintrytostopdependentservices) | DepList, Context | `WinStopService` | _(none)_ |
| [`WinStopAllDependentServices`](#fn-windowssshfunctionsdiscovery-winstopalldependentservices) | DepList, Context | `CheckUpdatedServices`, `WinTryToStopDependentServices` | _(none)_ |
| [`WinUpdateServicePassword`](#fn-windowssshfunctionsdiscovery-winupdateservicepassword) | ServiceName, DisplayName, Account, ServiceState, Context, HostIdentity | `WinGetRunningDependenciesList`, `WinRestartDependencyList`, ...(4 more) | `AssetName`, `DependentPassword`, `Exception`, `RestartService` |
| [`WinCheckTaskXml`](#fn-windowssshfunctionsdiscovery-winchecktaskxml) | ServicePath, ServiceAccount, CheckAccount, CheckDomain, CmdContext, HostIdentity | `WinParseAccount`, `WinRunBatchCommand` | _(none)_ |
| [`WinGetMatchingAccount`](#fn-windowssshfunctionsdiscovery-wingetmatchingaccount) | CmdContext, Account, CheckDomain, HostIdentity, IncludeLocal | `ResolveUserIdentity`, `WinParseAccount` | `DomainName`, `ObjectSid`, `StringComparison` |
| [`WinParseAccount`](#fn-windowssshfunctionsdiscovery-winparseaccount) | Account | _(none)_ | `NameList` |
| [`WinUpdateTaskPassword`](#fn-windowssshfunctionsdiscovery-winupdatetaskpassword) | ServiceName, Runas, ServiceState, ServicePath, CmdContext, HostIdentity, ParsedAccount | `WinCheckTaskXml`, `WinGetMatchingAccount`, `WinParseAccount`, `WinRunBatchStrictCommand` | `AssetName`, `DependentPassword`, `Exception` |
| [`WinUpdateIisPassword`](#fn-windowssshfunctionsdiscovery-winupdateiispassword) | ServiceName, Account, ServiceState, ServicePath, CmdContext, HostIdentity, ParsedAccount | `WinGetMatchingAccount`, `WinRunBatchStrictCommand` | `AssetName`, `DependentPassword`, `Exception`, `RestartService` |
| [`WinUpdateComPlusPassword`](#fn-windowssshfunctionsdiscovery-winupdatecompluspassword) | ServiceName, Account, ServiceState, ServicePath, CmdContext, HostIdentity, ParsedAccount | `WinGetMatchingAccount`, `WinRunBatchCommand` | `AssetName`, `DependentPassword`, `Exception`, `RestartService` |
| [`InitIgnoredUsers`](#fn-windowssshfunctionsdiscovery-initignoredusers) | IgnoredUserList | _(none)_ | _(none)_ |
| [`FilterIgnoredRunasUsers`](#fn-windowssshfunctionsdiscovery-filterignoredrunasusers) | CheckName | _(none)_ | `IgnoredUserList` |
| [`IsUserLocal`](#fn-windowssshfunctionsdiscovery-isuserlocal) | Account, Domain, NetBios | _(none)_ | `StringComparison` |
| [`LookupUser`](#fn-windowssshfunctionsdiscovery-lookupuser) | CmdContext, CheckDomain, CheckAccount, Runas | `WinParseAccount`, `WinRunBatchStrictCommand` | `Exception`, `NameList`, `ResolvedUserList` |
| [`ResolveUserIdentity`](#fn-windowssshfunctionsdiscovery-resolveuseridentity) | CmdContext, Runas, CheckAccount, CheckDomain, HostIdentity | `IsUserLocal`, `LookupUser` | _(none)_ |
| [`WinProcessServiceDiscoveryData`](#fn-windowssshfunctionsdiscovery-winprocessservicediscoverydata) | InputString, ServiceType, CmdContext, HostIdentity | `FilterIgnoredRunasUsers`, `ResolveUserIdentity`, ...(6 more) | `DiscoverOnly`, `ServicesList` |
| [`WinDiscoverNextBatchOfServices`](#fn-windowssshfunctionsdiscovery-windiscovernextbatchofservices) | DiscoveryData, CmdContext, QueryString, ServiceType, HostIdentity | `WinProcessServiceDiscoveryData`, `WinRunBatchCommand` | _(none)_ |
| [`WinDiscoverServices`](#fn-windowssshfunctionsdiscovery-windiscoverservices) | DiscoverOnly, QueryString, ServiceType, CmdContext, HostIdentity | `WinDiscoverNextBatchOfServices` | `Exception` |
| [`WinCheckDiscoveryRequired`](#fn-windowssshfunctionsdiscovery-wincheckdiscoveryrequired) | _(none)_ | _(none)_ | `onerule`, `oneservice`, `ServiceDiscoveryQuery` |
| [`WinUpdateDependencies`](#fn-windowssshfunctionsdiscovery-winupdatedependencies) | HostIdentity, IgnorePrefix?, DependentUsername | `GetSid`, `WinCheckForPowershell`, ...(4 more) | `ChangeComPlus`, `ChangeIis`, ...(7 more) |
| [`CheckForErrors`](#fn-windowssshfunctionsdiscovery-checkforerrors) | rc, Buffer, ErrBuffer, Cmd, Resolved | _(none)_ | `AssetName`, `DependentCommand`, `LogCommandArguments`, `LogStdout` |
| [`WinRunDependentCommand`](#fn-windowssshfunctionsdiscovery-winrundependentcommand) | CmdContext | `CheckForErrors` | `AssetName`, `CommandArguments`, ...(9 more) |
| [`WinGetAssetCount`](#fn-windowssshfunctionsdiscovery-wingetassetcount) | CmdContext | `WinRunBatchCommand` | _(none)_ |
| [`WinGetSummary`](#fn-windowssshfunctionsdiscovery-wingetsummary) | CmdContext | `WinRunBatchCommand` | `SummaryLine` |
| [`WinGetNetworkInfo`](#fn-windowssshfunctionsdiscovery-wingetnetworkinfo) | CmdContext | `WinRunBatchCommand` | `FullIpLine`, `instanceid`, `SummaryHashList` |
| [`WriteAssetDiscoveryResults`](#fn-windowssshfunctionsdiscovery-writeassetdiscoveryresults) | _(none)_ | _(none)_ | `One` |
| [`WinDiscoverAssets`](#fn-windowssshfunctionsdiscovery-windiscoverassets) | IgnorePrefix? | `WinCheckForPowershell`, `WinGetAssetCount`, ...(3 more) | `AssetName`, `Exception`, `SummaryHashList` |

### `WinProcessDiscoveredGroup` <a id="fn-windowssshfunctionsdiscovery-winprocessdiscoveredgroup"></a>

**Signature:** `WinProcessDiscoveredGroup(DiscoveryData: Object, InputString: string)`

**Parameters:**

- `DiscoveryData` (Object, required)
- `InputString` (string, required)

**Caller-scope reads:** `discoveredMembers`, `GroupList`, `oneuser`

**Calls:** _(none)_

**Sets locally:** `Buffer`, `count`, `data`, `dictionary`, `discoveredGroup`, `discoveredGroupString`, `discoveredMembersList`, `GroupCount`, `GroupLineMatch`, `Line`

**Returns:** _(none)_

### `WinProcessAccountDiscoveryData` <a id="fn-windowssshfunctionsdiscovery-winprocessaccountdiscoverydata"></a>

**Signature:** `WinProcessAccountDiscoveryData(DiscoveryData: Object, InputString: string)`

**Parameters:**

- `DiscoveryData` (Object, required)
- `InputString` (string, required)

**Caller-scope reads:** `UserList`

**Calls:** _(none)_

**Sets locally:** `Buffer`, `count`, `dictionary`, `discoveredUser`, `discoveredUserSid`, `Line`, `SidDictionary`, `UserCount`, `UserLineMatch`

**Returns:** _(none)_

### `WinDiscoverNextBatchOfAccounts` <a id="fn-windowssshfunctionsdiscovery-windiscovernextbatchofaccounts"></a>

**Signature:** `WinDiscoverNextBatchOfAccounts(DiscoveryData: Object, CmdContext: Object)`

**Parameters:**

- `DiscoveryData` (Object, required)
- `CmdContext` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinProcessAccountDiscoveryData`, `WinRunBatchCommand`

**Sets locally:** `AllUsers`, `getallcmd`, `StartAt`, `Timeout`, `tot`

**Returns:** _(none)_

### `WinDiscoverNextBatchOfGroups` <a id="fn-windowssshfunctionsdiscovery-windiscovernextbatchofgroups"></a>

**Signature:** `WinDiscoverNextBatchOfGroups(DiscoveryData: Object, CmdContext: Object)`

**Parameters:**

- `DiscoveryData` (Object, required)
- `CmdContext` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinProcessDiscoveredGroup`, `WinRunBatchCommand`

**Sets locally:** `AllGroups`, `getallcmd`, `StartAt`, `Timeout`, `tot`

**Returns:** _(none)_

### `WinCountObjects` <a id="fn-windowssshfunctionsdiscovery-wincountobjects"></a>

**Signature:** `WinCountObjects(SearchType: string, CmdContext: Object)`

**Parameters:**

- `SearchType` (string, required)
- `CmdContext` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinRunBatchCommand`

**Sets locally:** `ListResult`, `NumMatch`, `TotalCount`, `TotalCountStr`

**Returns:** `%{ TotalCount }%`

### `WinDiscoverAccountsOnHost` <a id="fn-windowssshfunctionsdiscovery-windiscoveraccountsonhost"></a>

**Signature:** `WinDiscoverAccountsOnHost(IgnorePrefix?: string)`

**Parameters:**

- `IgnorePrefix` (string, optional)

**Caller-scope reads:** `AssetName`, `oneuser`

**Calls:** `WinCheckForPowershell`, `WinCountObjects`, `WinDiscoverNextBatchOfAccounts`, `WinDiscoverNextBatchOfGroups`

**Sets locally:** `CmdContext`, `dictionary`, `discoveredGroupList`, `DiscoveryData`, `key`, `Sid`, `SidDictionary`, `TotalGroupCount`, `TotalUserCount`, `UserCount`, `val`

**Returns:** _(none)_

### `WinFilterDependentUser` <a id="fn-windowssshfunctionsdiscovery-winfilterdependentuser"></a>

**Signature:** `WinFilterDependentUser(variablename: string, HostIdentity: Object, IncludeLocal: boolean, ObjectSid: String)`

**Parameters:**

- `variablename` (string, required)
- `HostIdentity` (Object, required)
- `IncludeLocal` (boolean, required)
- `ObjectSid` (String, required)

**Caller-scope reads:** `DependentUsername`

**Calls:** _(none)_

**Sets locally:** `BackTick`, `DomainDepUser`, `DomUser`, `HostDepUser`, `LocalDepUser`, `MatchString`

**Returns:** `%{ MatchString  }%`

### `WinGetRunningDependenciesList` <a id="fn-windowssshfunctionsdiscovery-wingetrunningdependencieslist"></a>

**Signature:** `WinGetRunningDependenciesList(ServiceName: string, DisplayName: string, Context: Object)`

**Parameters:**

- `ServiceName` (string, required)
- `DisplayName` (string, required)
- `Context` (Object, required)

**Caller-scope reads:** `DepList`, `one`

**Calls:** `WinRunBatchCommand`

**Sets locally:** `CmdResult`, `Dependencies`, `obj`, `objdispname`, `objMatch`, `objname`, `serviceList`

**Returns:** `%{ serviceList }%`

### `WinStopService` <a id="fn-windowssshfunctionsdiscovery-winstopservice"></a>

**Signature:** `WinStopService(ServiceName: string, DisplayName: string, Context: Object)`

**Parameters:**

- `ServiceName` (string, required)
- `DisplayName` (string, required)
- `Context` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinRunBatchCommand`, `WinStoppingServices`

**Sets locally:** `Quote`, `StopServiceResult`

**Returns:** `%{ StopServiceResult.Result }%`

### `CheckUpdatedServices` <a id="fn-windowssshfunctionsdiscovery-checkupdatedservices"></a>

**Signature:** `CheckUpdatedServices(DepList: Array, Context: Object, RunningState: Boolean)`

**Parameters:**

- `DepList` (Array, required)
- `Context` (Object, required)
- `RunningState` (Boolean, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinRunBatchCommand`

**Sets locally:** `cc`, `okCount`, `Quote`, `ReqState`, `StopServiceResult`

**Returns:** `%{ okCount == DepList.Count }%`

### `WinStartService` <a id="fn-windowssshfunctionsdiscovery-winstartservice"></a>

**Signature:** `WinStartService(RestartServiceName: string, Context: Object)`

**Parameters:**

- `RestartServiceName` (string, required)
- `Context` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinRunBatchCommand`

**Sets locally:** `Quote`, `Started`

**Returns:** `%{ Started.Result }%`

### `WinRestartDependencyList` <a id="fn-windowssshfunctionsdiscovery-winrestartdependencylist"></a>

**Signature:** `WinRestartDependencyList(DepList: Array, Context: Object)`

**Parameters:**

- `DepList` (Array, required)
- `Context` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinStartService`

**Sets locally:** `count`, `one`, `res`, `ServiceStarted`

**Returns:** `%{ res }%`

### `WinStoppingServices` <a id="fn-windowssshfunctionsdiscovery-winstoppingservices"></a>

**Signature:** `WinStoppingServices(ServiceName: String, ServiceDisplayName: String, Result: Boolean, Output: String, Error: String)`

**Parameters:**

- `ServiceName` (String, required)
- `ServiceDisplayName` (String, required)
- `Result` (Boolean, required)
- `Output` (String, required)
- `Error` (String, required)

**Caller-scope reads:** `oneline`

**Calls:** _(none)_

**Sets locally:** `linematch`

**Returns:** _(none)_

### `WinTryToStopDependentServices` <a id="fn-windowssshfunctionsdiscovery-wintrytostopdependentservices"></a>

**Signature:** `WinTryToStopDependentServices(DepList: Array, Context: Object)`

**Parameters:**

- `DepList` (Array, required)
- `Context` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinStopService`

**Sets locally:** `cc`, `OneItem`, `Quote`, `stopped`, `StoppedService`

**Returns:** `%{ stopped == DepList.Count }%`

### `WinStopAllDependentServices` <a id="fn-windowssshfunctionsdiscovery-winstopalldependentservices"></a>

**Signature:** `WinStopAllDependentServices(DepList: Array, Context: Object)`

**Parameters:**

- `DepList` (Array, required)
- `Context` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `CheckUpdatedServices`, `WinTryToStopDependentServices`

**Sets locally:** `count`, `DepRunning`, `FailedToStop`, `StopResult`

**Returns:** _(none)_

### `WinUpdateServicePassword` <a id="fn-windowssshfunctionsdiscovery-winupdateservicepassword"></a>

**Signature:** `WinUpdateServicePassword(ServiceName: string, DisplayName: string, Account: string, ServiceState: string, Context: Object, HostIdentity: Object)`

**Parameters:**

- `ServiceName` (string, required)
- `DisplayName` (string, required)
- `Account` (string, required)
- `ServiceState` (string, required)
- `Context` (Object, required)
- `HostIdentity` (Object, required)

**Caller-scope reads:** `AssetName`, `DependentPassword`, `Exception`, `RestartService`

**Calls:** `WinGetRunningDependenciesList`, `WinRestartDependencyList`, `WinRunBatchStrictCommand`, `WinStartService`, `WinStopAllDependentServices`, `WinStopService`

**Sets locally:** `count`, `DependList`, `err`, `Quote`, `Restart`, `Started`

**Returns:** _(none)_

### `WinCheckTaskXml` <a id="fn-windowssshfunctionsdiscovery-winchecktaskxml"></a>

**Signature:** `WinCheckTaskXml(ServicePath: string, ServiceAccount: string, CheckAccount: string, CheckDomain: string, CmdContext: Object, HostIdentity: Object)`

**Parameters:**

- `ServicePath` (string, required)
- `ServiceAccount` (string, required)
- `CheckAccount` (string, required)
- `CheckDomain` (string, required)
- `CmdContext` (Object, required)
- `HostIdentity` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinParseAccount`, `WinRunBatchCommand`

**Sets locally:** `ParsedDomainAccount`, `ReturnValue`, `Sid`, `TaskXml`, `XmlMatch`

**Returns:** `%{ ReturnValue }%`

### `WinGetMatchingAccount` <a id="fn-windowssshfunctionsdiscovery-wingetmatchingaccount"></a>

**Signature:** `WinGetMatchingAccount(CmdContext: Object, Account: string, CheckDomain: string, HostIdentity: Object, IncludeLocal: boolean)`

**Parameters:**

- `CmdContext` (Object, required)
- `Account` (string, required)
- `CheckDomain` (string, required)
- `HostIdentity` (Object, required)
- `IncludeLocal` (boolean, required)

**Caller-scope reads:** `DomainName`, `ObjectSid`, `StringComparison`

**Calls:** `ResolveUserIdentity`, `WinParseAccount`

**Sets locally:** `BackTick`, `FoundLocal`, `FoundMatch`, `isSid`, `ParsedAccount`, `ResolvedUser`, `RunasAccountName`, `RunasDomainName`, `RunasFullName`, `SearchForDomainAccount`

**Returns:** _(none)_

### `WinParseAccount` <a id="fn-windowssshfunctionsdiscovery-winparseaccount"></a>

**Signature:** `WinParseAccount(Account: string)`

**Parameters:**

- `Account` (string, required)

**Caller-scope reads:** `NameList`

**Calls:** _(none)_

**Sets locally:** _(none)_

**Returns:** _(none)_

### `WinUpdateTaskPassword` <a id="fn-windowssshfunctionsdiscovery-winupdatetaskpassword"></a>

**Signature:** `WinUpdateTaskPassword(ServiceName: string, Runas: string, ServiceState: string, ServicePath: string, CmdContext: Object, HostIdentity: Object, ParsedAccount: Object)`

**Parameters:**

- `ServiceName` (string, required)
- `Runas` (string, required)
- `ServiceState` (string, required)
- `ServicePath` (string, required)
- `CmdContext` (Object, required)
- `HostIdentity` (Object, required)
- `ParsedAccount` (Object, required)

**Caller-scope reads:** `AssetName`, `DependentPassword`, `Exception`

**Calls:** `WinCheckTaskXml`, `WinGetMatchingAccount`, `WinParseAccount`, `WinRunBatchStrictCommand`

**Sets locally:** `AccountMatch`, `CheckDomain`, `CheckResult`, `err`, `MatchedAccount`, `ParsedAccount`, `ResolvedUser`, `Runas`

**Returns:** _(none)_

### `WinUpdateIisPassword` <a id="fn-windowssshfunctionsdiscovery-winupdateiispassword"></a>

**Signature:** `WinUpdateIisPassword(ServiceName: string, Account: string, ServiceState: string, ServicePath: string, CmdContext: Object, HostIdentity: Object, ParsedAccount: Object)`

**Parameters:**

- `ServiceName` (string, required)
- `Account` (string, required)
- `ServiceState` (string, required)
- `ServicePath` (string, required)
- `CmdContext` (Object, required)
- `HostIdentity` (Object, required)
- `ParsedAccount` (Object, required)

**Caller-scope reads:** `AssetName`, `DependentPassword`, `Exception`, `RestartService`

**Calls:** `WinGetMatchingAccount`, `WinRunBatchStrictCommand`

**Sets locally:** `AccountMatch`, `AppCmd`, `err`

**Returns:** _(none)_

### `WinUpdateComPlusPassword` <a id="fn-windowssshfunctionsdiscovery-winupdatecompluspassword"></a>

**Signature:** `WinUpdateComPlusPassword(ServiceName: string, Account: string, ServiceState: string, ServicePath: string, CmdContext: Object, HostIdentity: Object, ParsedAccount: Object)`

**Parameters:**

- `ServiceName` (string, required)
- `Account` (string, required)
- `ServiceState` (string, required)
- `ServicePath` (string, required)
- `CmdContext` (Object, required)
- `HostIdentity` (Object, required)
- `ParsedAccount` (Object, required)

**Caller-scope reads:** `AssetName`, `DependentPassword`, `Exception`, `RestartService`

**Calls:** `WinGetMatchingAccount`, `WinRunBatchCommand`

**Sets locally:** `AccountMatch`, `CmdResult`, `err`, `EscQuote`, `Global:RESTARTING`, `Global:STOPPING`, `restartit`

**Returns:** _(none)_

### `InitIgnoredUsers` <a id="fn-windowssshfunctionsdiscovery-initignoredusers"></a>

**Signature:** `InitIgnoredUsers(IgnoredUserList: Object)`

**Parameters:**

- `IgnoredUserList` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** _(none)_

**Sets locally:** _(none)_

**Returns:** _(none)_

### `FilterIgnoredRunasUsers` <a id="fn-windowssshfunctionsdiscovery-filterignoredrunasusers"></a>

**Signature:** `FilterIgnoredRunasUsers(CheckName: String)`

**Parameters:**

- `CheckName` (String, required)

**Caller-scope reads:** `IgnoredUserList`

**Calls:** _(none)_

**Sets locally:** `CheckId`

**Returns:** `%{ IgnoredUserList[CheckId] }%`, `false`, `true`

### `IsUserLocal` <a id="fn-windowssshfunctionsdiscovery-isuserlocal"></a>

**Signature:** `IsUserLocal(Account: string, Domain: string, NetBios: string)`

**Parameters:**

- `Account` (string, required)
- `Domain` (string, required)
- `NetBios` (string, required)

**Caller-scope reads:** `StringComparison`

**Calls:** _(none)_

**Sets locally:** _(none)_

**Returns:** `false`, `true`

### `LookupUser` <a id="fn-windowssshfunctionsdiscovery-lookupuser"></a>

**Signature:** `LookupUser(CmdContext: Object, CheckDomain: string, CheckAccount: string, Runas: string)`

**Parameters:**

- `CmdContext` (Object, required)
- `CheckDomain` (string, required)
- `CheckAccount` (string, required)
- `Runas` (string, required)

**Caller-scope reads:** `Exception`, `NameList`, `ResolvedUserList`

**Calls:** `WinParseAccount`, `WinRunBatchStrictCommand`

**Sets locally:** `AccountExists`, `Buffer`, `GetUserCmd`, `Item`, `ParsedAccount`, `Property`, `PropValue`, `RunasId`

**Returns:** `%{ Item }%`

### `ResolveUserIdentity` <a id="fn-windowssshfunctionsdiscovery-resolveuseridentity"></a>

**Signature:** `ResolveUserIdentity(CmdContext: Object, Runas: string, CheckAccount: string, CheckDomain: string, HostIdentity: object)`

**Parameters:**

- `CmdContext` (Object, required)
- `Runas` (string, required)
- `CheckAccount` (string, required)
- `CheckDomain` (string, required)
- `HostIdentity` (object, required)

**Caller-scope reads:** _(none)_

**Calls:** `IsUserLocal`, `LookupUser`

**Sets locally:** `backtick`, `escquote`, `IsLocal`, `isSid`, `Item`

**Returns:** `%{ Item }%`

### `WinProcessServiceDiscoveryData` <a id="fn-windowssshfunctionsdiscovery-winprocessservicediscoverydata"></a>

**Signature:** `WinProcessServiceDiscoveryData(InputString: string, ServiceType: string, CmdContext: Object, HostIdentity: Object)`

**Parameters:**

- `InputString` (string, required)
- `ServiceType` (string, required)
- `CmdContext` (Object, required)
- `HostIdentity` (Object, required)

**Caller-scope reads:** `DiscoverOnly`, `ServicesList`

**Calls:** `FilterIgnoredRunasUsers`, `ResolveUserIdentity`, `WinCheckTaskXml`, `WinParseAccount`, `WinUpdateComPlusPassword`, `WinUpdateIisPassword`, `WinUpdateServicePassword`, `WinUpdateTaskPassword`

**Sets locally:** `CheckResult`, `count`, `IncludeServiceInList`, `IsLocal`, `Line`, `OneServiceAccount`, `OneServiceDisplay`, `OneServiceEnabled`, `OneServiceName`, `OneServicePath`, `OneServiceState`, `OutputString`, `ParsedAccount`, `ResolvedId`, `Result`, `ServiceLineMatch`, `UpdateResponse`

**Returns:** `%{ Result }%`

### `WinDiscoverNextBatchOfServices` <a id="fn-windowssshfunctionsdiscovery-windiscovernextbatchofservices"></a>

**Signature:** `WinDiscoverNextBatchOfServices(DiscoveryData: Object, CmdContext: Object, QueryString: string, ServiceType: string, HostIdentity: Object)`

**Parameters:**

- `DiscoveryData` (Object, required)
- `CmdContext` (Object, required)
- `QueryString` (string, required)
- `ServiceType` (string, required)
- `HostIdentity` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinProcessServiceDiscoveryData`, `WinRunBatchCommand`

**Sets locally:** `AllServices`, `getallcmd`, `ProcessingResult`, `StartAt`, `Timeout`, `tot`

**Returns:** _(none)_

### `WinDiscoverServices` <a id="fn-windowssshfunctionsdiscovery-windiscoverservices"></a>

**Signature:** `WinDiscoverServices(DiscoverOnly: boolean, QueryString: string, ServiceType: string, CmdContext: Object, HostIdentity: Object)`

**Parameters:**

- `DiscoverOnly` (boolean, required)
- `QueryString` (string, required)
- `ServiceType` (string, required)
- `CmdContext` (Object, required)
- `HostIdentity` (Object, required)

**Caller-scope reads:** `Exception`

**Calls:** `WinDiscoverNextBatchOfServices`

**Sets locally:** `DiscoveryData`, `ListServiceResult`, `Result`

**Returns:** _(none)_

### `WinCheckDiscoveryRequired` <a id="fn-windowssshfunctionsdiscovery-wincheckdiscoveryrequired"></a>

**Signature:** `WinCheckDiscoveryRequired(_(none)_)`

**Caller-scope reads:** `onerule`, `oneservice`, `ServiceDiscoveryQuery`

**Calls:** _(none)_

**Sets locally:** `All`, `constraintFilters`, `DiscoveryType`, `Rules`, `ServiceType`

**Returns:** _(none)_

### `WinUpdateDependencies` <a id="fn-windowssshfunctionsdiscovery-winupdatedependencies"></a>

**Signature:** `WinUpdateDependencies(HostIdentity: Object, IgnorePrefix?: string, DependentUsername: string)`

**Parameters:**

- `HostIdentity` (Object, required)
- `IgnorePrefix` (string, optional)
- `DependentUsername` (string, required)

**Caller-scope reads:** `ChangeComPlus`, `ChangeIis`, `ChangeService`, `ChangeTask`, `DependentCommand`, `DomainName`, `Exception`, `rc`, `Timeout`

**Calls:** `GetSid`, `WinCheckForPowershell`, `WinDiscoverServices`, `WinFilterDependentUser`, `WinRunBatchCommand`, `WinRunDependentCommand`

**Sets locally:** `AppCmd`, `AppCmdResult`, `CmdContext`, `ConnectSsh`, `ErrBuffer`, `escquote`, `FilterString`, `FormatEndofString`, `FormatString`, `ObjectSid`, `QueryString`, `Result`, `ReturnLine`, `UpdatedComPlus`, `UpdatedDependencyCount`, `UpdatedPools`, `UpdatedService`, `UpdatedTask`

**Returns:** _(none)_

### `CheckForErrors` <a id="fn-windowssshfunctionsdiscovery-checkforerrors"></a>

**Signature:** `CheckForErrors(rc: integer, Buffer: string, ErrBuffer: string, Cmd: string, Resolved: string)`

**Parameters:**

- `rc` (integer, required)
- `Buffer` (string, required)
- `ErrBuffer` (string, required)
- `Cmd` (string, required)
- `Resolved` (string, required)

**Caller-scope reads:** `AssetName`, `DependentCommand`, `LogCommandArguments`, `LogStdout`

**Calls:** _(none)_

**Sets locally:** `Output`, `permErrs`, `VisibleOutput`

**Returns:** `false`, `true`

### `WinRunDependentCommand` <a id="fn-windowssshfunctionsdiscovery-winrundependentcommand"></a>

**Signature:** `WinRunDependentCommand(CmdContext: Object)`

**Parameters:**

- `CmdContext` (Object, required)

**Caller-scope reads:** `AssetName`, `CommandArguments`, `DependentCommand`, `ErrBuf`, `Exception`, `LogCommand`, `LogCommandArguments`, `LogStdin`, `LogStdout`, `ReportExitStatus`, `StdinArguments`

**Calls:** `CheckForErrors`

**Sets locally:** `ConnectSsh`, `LogCmd`, `OutputBuffer`, `rc`, `ResolvedCommand`, `Result`

**Returns:** `%{ Result}%`, `true`

### `WinGetAssetCount` <a id="fn-windowssshfunctionsdiscovery-wingetassetcount"></a>

**Signature:** `WinGetAssetCount(CmdContext: Object)`

**Parameters:**

- `CmdContext` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinRunBatchCommand`

**Sets locally:** `AssetCount`, `getallcmd`, `Info`

**Returns:** _(none)_

### `WinGetSummary` <a id="fn-windowssshfunctionsdiscovery-wingetsummary"></a>

**Signature:** `WinGetSummary(CmdContext: Object)`

**Parameters:**

- `CmdContext` (Object, required)

**Caller-scope reads:** `SummaryLine`

**Calls:** `WinRunBatchCommand`

**Sets locally:** `getallcmd`, `State`, `SumLine`, `SummaryInfo`, `SummaryItem`, `SummaryList`, `SummaryMatch`

**Returns:** _(none)_

### `WinGetNetworkInfo` <a id="fn-windowssshfunctionsdiscovery-wingetnetworkinfo"></a>

**Signature:** `WinGetNetworkInfo(CmdContext: Object)`

**Parameters:**

- `CmdContext` (Object, required)

**Caller-scope reads:** `FullIpLine`, `instanceid`, `SummaryHashList`

**Calls:** `WinRunBatchCommand`

**Sets locally:** `FullIpList`, `getallcmd`, `IpLine`, `IpMatch`, `NetworkInfo`, `vmid`

**Returns:** _(none)_

### `WriteAssetDiscoveryResults` <a id="fn-windowssshfunctionsdiscovery-writeassetdiscoveryresults"></a>

**Signature:** `WriteAssetDiscoveryResults(_(none)_)`

**Caller-scope reads:** `One`

**Calls:** _(none)_

**Sets locally:** _(none)_

**Returns:** _(none)_

### `WinDiscoverAssets` <a id="fn-windowssshfunctionsdiscovery-windiscoverassets"></a>

**Signature:** `WinDiscoverAssets(IgnorePrefix?: string)`

**Parameters:**

- `IgnorePrefix` (string, optional)

**Caller-scope reads:** `AssetName`, `Exception`, `SummaryHashList`

**Calls:** `WinCheckForPowershell`, `WinGetAssetCount`, `WinGetNetworkInfo`, `WinGetSummary`, `WriteAssetDiscoveryResults`

**Sets locally:** `CmdContext`, `Error`, `Global:SummaryHashList`, `Result`

**Returns:** `%{ Result }%`

## Library: `WindowsSshFunctionsSshKey` <a id="library-windowssshfunctionssshkey"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`WinGetVariableFromLine`](#fn-windowssshfunctionssshkey-wingetvariablefromline) | ConvDescription, Line, SuccessRegex, ReplaceRegex, ThrowIfNotFound | _(none)_ | `ReturnLine` |
| [`InitializeSshConfigData`](#fn-windowssshfunctionssshkey-initializesshconfigdata) | LocalUser, IgnorePrefix? | `GetHostname`, `WinCheckForPowershell` | `FuncUserName` |
| [`WinChangeSshKey`](#fn-windowssshfunctionssshkey-winchangesshkey) | LocalUser, IgnorePrefix? | `WinCheckKeyActionRequired`, `WinCleanUp`, ...(4 more) | `AssetName`, `Exception`, `NewSshPrivateKey`, `ServerSoftwareName` |
| [`WinQuoteUser`](#fn-windowssshfunctionssshkey-winquoteuser) | User, Context? | _(none)_ | _(none)_ |
| [`WinGetSshServerVersion`](#fn-windowssshfunctionssshkey-wingetsshserverversion) | Config | _(none)_ | `ServerSoftwareName` |
| [`GetHomeDir`](#fn-windowssshfunctionssshkey-gethomedir) | CmdContext | `WinRunBatchCommand` | `AccountUserName` |
| [`GetSid`](#fn-windowssshfunctionssshkey-getsid) | CmdContext, ObjectSid, DomainName, UserName | `WinRunBatchCommand` | _(none)_ |
| [`WinCheckTargetHomeDir`](#fn-windowssshfunctionssshkey-winchecktargethomedir) | Config | `GetHomeDir`, `WinQuoteUser`, `WinRunBatchCommand`, `WinValidateAccountExists` | _(none)_ |
| [`WinCheckKeyActionRequired`](#fn-windowssshfunctionssshkey-wincheckkeyactionrequired) | _(none)_ | _(none)_ | `NewSshKey`, `NewSshPrivateKey` |
| [`WinGetOpenSshAuthConfigForHost`](#fn-windowssshfunctionssshkey-wingetopensshauthconfigforhost) | Config, ConfigFile, User, Host, Address | `WinCheckSshdConfig`, `WinRunSshdCommand` | `AssetName`, `FileList` |
| [`WinReadFileContents`](#fn-windowssshfunctionssshkey-winreadfilecontents) | Config, Filename, ReturnFalseIfAccessErrors | `WinRunBatchCommand` | `Exception`, `FileContentsList` |
| [`WinCheckMatch`](#fn-windowssshfunctionssshkey-wincheckmatch) | Config, MatchType, MatchString | _(none)_ | `AccountUserName`, `item` |
| [`WinCheckSshdConfig`](#fn-windowssshfunctionssshkey-winchecksshdconfig) | Config, ConfigFile | `WinCheckMatch`, `WinReadFileContents` | `Exception`, `FileOutput`, `Line` |
| [`WinRunSshdCommand`](#fn-windowssshfunctionssshkey-winrunsshdcommand) | Config, ConfigFile, SshdOptions | `WinGetVariableFromLine`, `WinRunBatchCommand` | `Address`, `AssetName`, ...(5 more) |
| [`WinGetRemoteClient`](#fn-windowssshfunctionssshkey-wingetremoteclient) | Config | `WinGetVariableFromLine`, `WinRunBatchCommand` | `Address` |
| [`WinEvaluateTemplateFile`](#fn-windowssshfunctionssshkey-winevaluatetemplatefile) | Config, Template | _(none)_ | _(none)_ |
| [`WinGetOpenSshOptions`](#fn-windowssshfunctionssshkey-wingetopensshoptions) | Config | `WinRunBatchStrictCommand` | `AssetName` |
| [`WinGetSshdConfig`](#fn-windowssshfunctionssshkey-wingetsshdconfig) | Config, ChangingKeys | `WinEvaluateTemplateFile`, `WinGetOpenSshAuthConfigForHost`, `WinGetOpenSshOptions`, `WinGetRemoteClient` | `AssetName`, `one` |
| [`WinGetCurrentKeys`](#fn-windowssshfunctionssshkey-wingetcurrentkeys) | ConfigData | `WinGetKeysFromFile` | `entry` |
| [`WinGetKeysFromFile`](#fn-windowssshfunctionssshkey-wingetkeysfromfile) | ConfigData, AuthKeyDictionary, Filename | `ValidateBase64String`, `WinReadFileContents` | _(none)_ |
| [`WinCheckKeyConfigured`](#fn-windowssshfunctionssshkey-wincheckkeyconfigured) | KeyDictionary, CheckKey, UseCmd, Comment | _(none)_ | _(none)_ |
| [`SetAcl`](#fn-windowssshfunctionssshkey-setacl) | Filename, CmdContext, Account, HomeDir, HostName | `WinRunBatchStrictCommand` | `Access`, `Exception`, `one` |
| [`WinConfigureNewKey`](#fn-windowssshfunctionssshkey-winconfigurenewkey) | ConfigData | `SetAcl`, `WinCheckKeyConfigured`, `WinCleanUp`, `WinRunBatchStrictCommand` | `NewSshKey`, `NewSshKeyComment`, `ReplaceExistingKeys` |
| [`WinCleanUp`](#fn-windowssshfunctionssshkey-wincleanup) | ConfigData, Rollback | `WinRunBatchCommand` | _(none)_ |
| [`WinTestNewKey`](#fn-windowssshfunctionssshkey-wintestnewkey) | TestUser, TestKey | _(none)_ | `AccountUserName`, `Address`, ...(5 more) |
| [`WinRemoveKeyFromFile`](#fn-windowssshfunctionssshkey-winremovekeyfromfile) | ConfigData, Filename | `SetAcl`, `WinRunBatchCommand`, `WinRunBatchStrictCommand` | `OldSshKey` |
| [`WinRemoveKey`](#fn-windowssshfunctionssshkey-winremovekey) | ConfigData | `WinCheckKeyConfigured`, `WinRemoveKeyFromFile` | `AccountUserName`, `AssetName`, `Exception`, `OldSshKey`, `onefile` |
| [`GetHostname`](#fn-windowssshfunctionssshkey-gethostname) | IgnorePrefix? | _(none)_ | `ErrBuffer`, `rc` |
| [`WinDiscoverSshConfig`](#fn-windowssshfunctionssshkey-windiscoversshconfig) | LocalUser, ChangingKeys, IgnorePrefix? | `InitializeSshConfigData`, `WinCheckTargetHomeDir`, ...(3 more) | _(none)_ |
| [`WinDiscoverAuthKeys`](#fn-windowssshfunctionssshkey-windiscoverauthkeys) | LocalUser, IgnorePrefix? | `WinDiscoverSshConfig` | `AccountUserName`, `one`, `ServerSoftwareName` |
| [`WinCheckAuthKey`](#fn-windowssshfunctionssshkey-wincheckauthkey) | LocalUser, IgnorePrefix? | `WinCheckKeyConfigured`, `WinCheckKeyPermission`, `WinDiscoverSshConfig` | `OldSshKey`, `ServerSoftwareName` |
| [`WinCheckKeyPermission`](#fn-windowssshfunctionssshkey-wincheckkeypermission) | Filename, CmdContext, Account, HomeDir | `WinRunBatchStrictCommand` | `Access`, `Exception`, `one` |
| [`WinRemoveAuthorizedKey`](#fn-windowssshfunctionssshkey-winremoveauthorizedkey) | LocalUser, IgnorePrefix? | `WinChangeSshKey` | _(none)_ |

### `WinGetVariableFromLine` <a id="fn-windowssshfunctionssshkey-wingetvariablefromline"></a>

**Signature:** `WinGetVariableFromLine(ConvDescription: string, Line: string, SuccessRegex: string, ReplaceRegex: string, ThrowIfNotFound: boolean)`

**Parameters:**

- `ConvDescription` (string, required)
- `Line` (string, required)
- `SuccessRegex` (string, required)
- `ReplaceRegex` (string, required)
- `ThrowIfNotFound` (boolean, required)

**Caller-scope reads:** `ReturnLine`

**Calls:** _(none)_

**Sets locally:** `tmpvar`

**Returns:** ``, `%{ tmpvar.Value.Trim() }%`

### `InitializeSshConfigData` <a id="fn-windowssshfunctionssshkey-initializesshconfigdata"></a>

**Signature:** `InitializeSshConfigData(LocalUser: string, IgnorePrefix?: string)`

**Parameters:**

- `LocalUser` (string, required)
- `IgnorePrefix` (string, optional)

**Caller-scope reads:** `FuncUserName`

**Calls:** `GetHostname`, `WinCheckForPowershell`

**Sets locally:** `AccountUserName`, `CmdContext`, `LocalHostName`, `SshKeyConfig`

**Returns:** `%{ SshKeyConfig }%`

### `WinChangeSshKey` <a id="fn-windowssshfunctionssshkey-winchangesshkey"></a>

**Signature:** `WinChangeSshKey(LocalUser: string, IgnorePrefix?: string)`

**Parameters:**

- `LocalUser` (string, required)
- `IgnorePrefix` (string, optional)

**Caller-scope reads:** `AssetName`, `Exception`, `NewSshPrivateKey`, `ServerSoftwareName`

**Calls:** `WinCheckKeyActionRequired`, `WinCleanUp`, `WinConfigureNewKey`, `WinDiscoverSshConfig`, `WinRemoveKey`, `WinTestNewKey`

**Sets locally:** `ConfigureResult`, `KeyChangeRequired`, `ReplaceExistingKeys`, `SshServerConfig`

**Returns:** `false`, `true`

### `WinQuoteUser` <a id="fn-windowssshfunctionssshkey-winquoteuser"></a>

**Signature:** `WinQuoteUser(User: string, Context?: Object)`

**Parameters:**

- `User` (string, required)
- `Context` (Object, optional)

**Caller-scope reads:** _(none)_

**Calls:** _(none)_

**Sets locally:** `Quote`

**Returns:** `%Quote%`, `%User%`

### `WinGetSshServerVersion` <a id="fn-windowssshfunctionssshkey-wingetsshserverversion"></a>

**Signature:** `WinGetSshServerVersion(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `ServerSoftwareName`

**Calls:** _(none)_

**Sets locally:** `SshVersionMatch`

**Returns:** _(none)_

### `GetHomeDir` <a id="fn-windowssshfunctionssshkey-gethomedir"></a>

**Signature:** `GetHomeDir(CmdContext: Object)`

**Parameters:**

- `CmdContext` (Object, required)

**Caller-scope reads:** `AccountUserName`

**Calls:** `WinRunBatchCommand`

**Sets locally:** `CmdOutput`, `GetPathCmd`, `GetSidCmd`, `SID`

**Returns:** ``, `%{ CmdOutput.RecvBuffer.Trim() }%`

### `GetSid` <a id="fn-windowssshfunctionssshkey-getsid"></a>

**Signature:** `GetSid(CmdContext: Object, ObjectSid: string, DomainName: String, UserName: String)`

**Parameters:**

- `CmdContext` (Object, required)
- `ObjectSid` (string, required)
- `DomainName` (String, required)
- `UserName` (String, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinRunBatchCommand`

**Sets locally:** `CmdOutput`, `filter`, `GetSidCmd`, `local`, `sid`

**Returns:** ``, `%{ ObjectSid }%`, `%{ sid }%`

### `WinCheckTargetHomeDir` <a id="fn-windowssshfunctionssshkey-winchecktargethomedir"></a>

**Signature:** `WinCheckTargetHomeDir(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** _(none)_

**Calls:** `GetHomeDir`, `WinQuoteUser`, `WinRunBatchCommand`, `WinValidateAccountExists`

**Sets locally:** `AccountChecked`, `cmd`, `GroupMatch`, `GroupStr`, `HomeDir`, `HomeDirMatch`, `HomeDirResult`, `QuotedUser`

**Returns:** _(none)_

### `WinCheckKeyActionRequired` <a id="fn-windowssshfunctionssshkey-wincheckkeyactionrequired"></a>

**Signature:** `WinCheckKeyActionRequired(_(none)_)`

**Caller-scope reads:** `NewSshKey`, `NewSshPrivateKey`

**Calls:** _(none)_

**Sets locally:** `Add`, `OldSshKey`, `Remove`, `ReplaceExistingKeys`

**Returns:** _(none)_

### `WinGetOpenSshAuthConfigForHost` <a id="fn-windowssshfunctionssshkey-wingetopensshauthconfigforhost"></a>

**Signature:** `WinGetOpenSshAuthConfigForHost(Config: Object, ConfigFile: string, User: string, Host: string, Address: string)`

**Parameters:**

- `Config` (Object, required)
- `ConfigFile` (string, required)
- `User` (string, required)
- `Host` (string, required)
- `Address` (string, required)

**Caller-scope reads:** `AssetName`, `FileList`

**Calls:** `WinCheckSshdConfig`, `WinRunSshdCommand`

**Sets locally:** `FileListString`, `FoundTemplates`, `SshdCmd`, `sshdCmd`

**Returns:** `%{ FileList }%`, `%{ FoundTemplates.FileList }%`

### `WinReadFileContents` <a id="fn-windowssshfunctionssshkey-winreadfilecontents"></a>

**Signature:** `WinReadFileContents(Config: Object, Filename: string, ReturnFalseIfAccessErrors: Boolean)`

**Parameters:**

- `Config` (Object, required)
- `Filename` (string, required)
- `ReturnFalseIfAccessErrors` (Boolean, required)

**Caller-scope reads:** `Exception`, `FileContentsList`

**Calls:** `WinRunBatchCommand`

**Sets locally:** `CmdContext`, `CmdOutput`, `esc`, `FileContents`, `InsufficientPrivileges`, `LineMatch`

**Returns:** _(none)_

### `WinCheckMatch` <a id="fn-windowssshfunctionssshkey-wincheckmatch"></a>

**Signature:** `WinCheckMatch(Config: Object, MatchType: string, MatchString: string)`

**Parameters:**

- `Config` (Object, required)
- `MatchType` (string, required)
- `MatchString` (string, required)

**Caller-scope reads:** `AccountUserName`, `item`

**Calls:** _(none)_

**Sets locally:** `Pattern`, `UserGroups`

**Returns:** `false`, `true`

### `WinCheckSshdConfig` <a id="fn-windowssshfunctionssshkey-winchecksshdconfig"></a>

**Signature:** `WinCheckSshdConfig(Config: Object, ConfigFile: string)`

**Parameters:**

- `Config` (Object, required)
- `ConfigFile` (string, required)

**Caller-scope reads:** `Exception`, `FileOutput`, `Line`

**Calls:** `WinCheckMatch`, `WinReadFileContents`

**Sets locally:** `CmdOutput`, `ConfigLines`, `ConfigString`, `FoundIdMatch`, `LineMatch`, `MatchConfig`, `ProcessLine`, `TemplateList`

**Returns:** _(none)_

### `WinRunSshdCommand` <a id="fn-windowssshfunctionssshkey-winrunsshdcommand"></a>

**Signature:** `WinRunSshdCommand(Config: Object, ConfigFile: string, SshdOptions: string)`

**Parameters:**

- `Config` (Object, required)
- `ConfigFile` (string, required)
- `SshdOptions` (string, required)

**Caller-scope reads:** `Address`, `AssetName`, `Exception`, `FileList`, `Host`, `SshConnectionLostException`, `User`

**Calls:** `WinGetVariableFromLine`, `WinRunBatchCommand`

**Sets locally:** `FindTemplate`, `FoundLine`, `TemplateFileList`

**Returns:** _(none)_

### `WinGetRemoteClient` <a id="fn-windowssshfunctionssshkey-wingetremoteclient"></a>

**Signature:** `WinGetRemoteClient(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `Address`

**Calls:** `WinGetVariableFromLine`, `WinRunBatchCommand`

**Sets locally:** `EnvOutput`, `PingMatch`, `RemoteHost`, `RemoteIP`, `ResolvedClient`

**Returns:** _(none)_

### `WinEvaluateTemplateFile` <a id="fn-windowssshfunctionssshkey-winevaluatetemplatefile"></a>

**Signature:** `WinEvaluateTemplateFile(Config: Object, Template: string)`

**Parameters:**

- `Config` (Object, required)
- `Template` (string, required)

**Caller-scope reads:** _(none)_

**Calls:** _(none)_

**Sets locally:** `Keyfile`

**Returns:** `%{ Keyfile }%`

### `WinGetOpenSshOptions` <a id="fn-windowssshfunctionssshkey-wingetopensshoptions"></a>

**Signature:** `WinGetOpenSshOptions(Config: Object)`

**Parameters:**

- `Config` (Object, required)

**Caller-scope reads:** `AssetName`

**Calls:** `WinRunBatchStrictCommand`

**Sets locally:** `ConfigFileContents`, `ConfigMatch`, `MatchString`

**Returns:** _(none)_

### `WinGetSshdConfig` <a id="fn-windowssshfunctionssshkey-wingetsshdconfig"></a>

**Signature:** `WinGetSshdConfig(Config: Object, ChangingKeys: boolean)`

**Parameters:**

- `Config` (Object, required)
- `ChangingKeys` (boolean, required)

**Caller-scope reads:** `AssetName`, `one`

**Calls:** `WinEvaluateTemplateFile`, `WinGetOpenSshAuthConfigForHost`, `WinGetOpenSshOptions`, `WinGetRemoteClient`

**Sets locally:** `count`, `Keyfiles`, `KeyListString`, `KeyPath`, `RemoteClient`, `TemplateList`, `TemplateListString`

**Returns:** _(none)_

### `WinGetCurrentKeys` <a id="fn-windowssshfunctionssshkey-wingetcurrentkeys"></a>

**Signature:** `WinGetCurrentKeys(ConfigData: Object)`

**Parameters:**

- `ConfigData` (Object, required)

**Caller-scope reads:** `entry`

**Calls:** `WinGetKeysFromFile`

**Sets locally:** `Keyfiles`, `NewKeyDictionary`

**Returns:** _(none)_

### `WinGetKeysFromFile` <a id="fn-windowssshfunctionssshkey-wingetkeysfromfile"></a>

**Signature:** `WinGetKeysFromFile(ConfigData: Object, AuthKeyDictionary: Object, Filename: string)`

**Parameters:**

- `ConfigData` (Object, required)
- `AuthKeyDictionary` (Object, required)
- `Filename` (string, required)

**Caller-scope reads:** _(none)_

**Calls:** `ValidateBase64String`, `WinReadFileContents`

**Sets locally:** `count`, `currlist`, `FileOutput`, `foundkeycount`, `FullKey`, `KeyList`, `KeyMatch`, `KeyString`, `KeyStringIsValidBase64`, `OneEntry`, `TrimmedLine`, `UnexpectedEntries`

**Returns:** _(none)_

### `WinCheckKeyConfigured` <a id="fn-windowssshfunctionssshkey-wincheckkeyconfigured"></a>

**Signature:** `WinCheckKeyConfigured(KeyDictionary: Object, CheckKey: string, UseCmd: Object, Comment: string)`

**Parameters:**

- `KeyDictionary` (Object, required)
- `CheckKey` (string, required)
- `UseCmd` (Object, required)
- `Comment` (string, required)

**Caller-scope reads:** _(none)_

**Calls:** _(none)_

**Sets locally:** `CheckComment`, `KeyFoundResult`, `OneEntry`, `TrimmedComment`, `TrimmedKey`

**Returns:** `%{ KeyFoundResult }%`

### `SetAcl` <a id="fn-windowssshfunctionssshkey-setacl"></a>

**Signature:** `SetAcl(Filename: string, CmdContext: Object, Account: string, HomeDir: string, HostName: string)`

**Parameters:**

- `Filename` (string, required)
- `CmdContext` (Object, required)
- `Account` (string, required)
- `HomeDir` (string, required)
- `HostName` (string, required)

**Caller-scope reads:** `Access`, `Exception`, `one`

**Calls:** `WinRunBatchStrictCommand`

**Sets locally:** `aclcmd`, `AclResult`, `cmd`, `IsOwner`, `TrimmedHomeDir`, `TrimmedHost`, `validUsers`

**Returns:** _(none)_

### `WinConfigureNewKey` <a id="fn-windowssshfunctionssshkey-winconfigurenewkey"></a>

**Signature:** `WinConfigureNewKey(ConfigData: Object)`

**Parameters:**

- `ConfigData` (Object, required)

**Caller-scope reads:** `NewSshKey`, `NewSshKeyComment`, `ReplaceExistingKeys`

**Calls:** `SetAcl`, `WinCheckKeyConfigured`, `WinCleanUp`, `WinRunBatchStrictCommand`

**Sets locally:** `backupfile`, `CmdContext`, `FindKeyDir`, `Keyfile`, `KeyfileContents`, `KeyFileExists`, `tmpfile`

**Returns:** `false`, `true`

### `WinCleanUp` <a id="fn-windowssshfunctionssshkey-wincleanup"></a>

**Signature:** `WinCleanUp(ConfigData: Object, Rollback: boolean)`

**Parameters:**

- `ConfigData` (Object, required)
- `Rollback` (boolean, required)

**Caller-scope reads:** _(none)_

**Calls:** `WinRunBatchCommand`

**Sets locally:** `backupfile`, `Keyfile`, `OpResult`, `tmpfile`

**Returns:** _(none)_

### `WinTestNewKey` <a id="fn-windowssshfunctionssshkey-wintestnewkey"></a>

**Signature:** `WinTestNewKey(TestUser: string, TestKey: string)`

**Parameters:**

- `TestUser` (string, required)
- `TestKey` (string, required)

**Caller-scope reads:** `AccountUserName`, `Address`, `CheckHostKey`, `Exception`, `FuncUserName`, `HostKey`, `Port`

**Calls:** _(none)_

**Sets locally:** `TestConnectSsh`

**Returns:** `true`

### `WinRemoveKeyFromFile` <a id="fn-windowssshfunctionssshkey-winremovekeyfromfile"></a>

**Signature:** `WinRemoveKeyFromFile(ConfigData: Object, Filename: string)`

**Parameters:**

- `ConfigData` (Object, required)
- `Filename` (string, required)

**Caller-scope reads:** `OldSshKey`

**Calls:** `SetAcl`, `WinRunBatchCommand`, `WinRunBatchStrictCommand`

**Sets locally:** `FileCopied`, `tmpfile`

**Returns:** `%{ FileCopied.Result }%`

### `WinRemoveKey` <a id="fn-windowssshfunctionssshkey-winremovekey"></a>

**Signature:** `WinRemoveKey(ConfigData: Object)`

**Parameters:**

- `ConfigData` (Object, required)

**Caller-scope reads:** `AccountUserName`, `AssetName`, `Exception`, `OldSshKey`, `onefile`

**Calls:** `WinCheckKeyConfigured`, `WinRemoveKeyFromFile`

**Sets locally:** `AllFiles`, `ErrBuffer`, `KeyResult`, `res`

**Returns:** `%{ res }%`, `true`

### `GetHostname` <a id="fn-windowssshfunctionssshkey-gethostname"></a>

**Signature:** `GetHostname(IgnorePrefix?: string)`

**Parameters:**

- `IgnorePrefix` (string, optional)

**Caller-scope reads:** `ErrBuffer`, `rc`

**Calls:** _(none)_

**Sets locally:** `ConnectSsh`, `hostnameresult`

**Returns:** `%{ hostnameresult }%`

### `WinDiscoverSshConfig` <a id="fn-windowssshfunctionssshkey-windiscoversshconfig"></a>

**Signature:** `WinDiscoverSshConfig(LocalUser: string, ChangingKeys: boolean, IgnorePrefix?: string)`

**Parameters:**

- `LocalUser` (string, required)
- `ChangingKeys` (boolean, required)
- `IgnorePrefix` (string, optional)

**Caller-scope reads:** _(none)_

**Calls:** `InitializeSshConfigData`, `WinCheckTargetHomeDir`, `WinGetCurrentKeys`, `WinGetSshdConfig`, `WinGetSshServerVersion`

**Sets locally:** `SshServerConfig`

**Returns:** `%{ SshServerConfig }%`

### `WinDiscoverAuthKeys` <a id="fn-windowssshfunctionssshkey-windiscoverauthkeys"></a>

**Signature:** `WinDiscoverAuthKeys(LocalUser: string, IgnorePrefix?: string = )`

**Parameters:**

- `LocalUser` (string, required)
- `IgnorePrefix` (string, optional, default: )

**Caller-scope reads:** `AccountUserName`, `one`, `ServerSoftwareName`

**Calls:** `WinDiscoverSshConfig`

**Sets locally:** `KeyDictionary`, `SshServerConfig`

**Returns:** `true`

### `WinCheckAuthKey` <a id="fn-windowssshfunctionssshkey-wincheckauthkey"></a>

**Signature:** `WinCheckAuthKey(LocalUser: string, IgnorePrefix?: string)`

**Parameters:**

- `LocalUser` (string, required)
- `IgnorePrefix` (string, optional)

**Caller-scope reads:** `OldSshKey`, `ServerSoftwareName`

**Calls:** `WinCheckKeyConfigured`, `WinCheckKeyPermission`, `WinDiscoverSshConfig`

**Sets locally:** `KeyFoundResult`, `SshServerConfig`

**Returns:** `%{ KeyFoundResult }%`

### `WinCheckKeyPermission` <a id="fn-windowssshfunctionssshkey-wincheckkeypermission"></a>

**Signature:** `WinCheckKeyPermission(Filename: string, CmdContext: Object, Account: string, HomeDir: string)`

**Parameters:**

- `Filename` (string, required)
- `CmdContext` (Object, required)
- `Account` (string, required)
- `HomeDir` (string, required)

**Caller-scope reads:** `Access`, `Exception`, `one`

**Calls:** `WinRunBatchStrictCommand`

**Sets locally:** `AclResult`, `cmd`, `IsOwner`, `validUsers`

**Returns:** _(none)_

### `WinRemoveAuthorizedKey` <a id="fn-windowssshfunctionssshkey-winremoveauthorizedkey"></a>

**Signature:** `WinRemoveAuthorizedKey(LocalUser: string, IgnorePrefix?: string)`

**Parameters:**

- `LocalUser` (string, required)
- `IgnorePrefix` (string, optional)

**Caller-scope reads:** _(none)_

**Calls:** `WinChangeSshKey`

**Sets locally:** `configResult`, `Global:NewSshKey`, `Global:NewSshPrivateKey`

**Returns:** `%{ configResult }%`

## Library: `UnixUpdateCustomDependency` <a id="library-unixupdatecustomdependency"></a>

| Function | Parameters | Calls | Caller-scope reads |
| --- | --- | --- | --- |
| [`CheckForErrorsF5BigIp`](#fn-unixupdatecustomdependency-checkforerrorsf5bigip) | rc, Buffer, ErrBuffer | `ParseError` | `DependentCommand`, `OutputBuffer` |
| [`CheckForErrors`](#fn-unixupdatecustomdependency-checkforerrors) | rc, Buffer, ErrBuffer | `ParseError` | `ErrBuf`, `OutputBuffer` |
| [`ParseError`](#fn-unixupdatecustomdependency-parseerror) | rc, Buffer, ErrBuffer | _(none)_ | `DelegationPrefix`, `DependentCommand`, `FuncUserName`, `LogStdout` |
| [`UnixUpdateCustomDependency`](#fn-unixupdatecustomdependency-unixupdatecustomdependency) | Platform | `CheckForErrors`, `CheckForErrorsF5BigIp` | `AssetName`, `CommandArguments`, ...(8 more) |

### `CheckForErrorsF5BigIp` <a id="fn-unixupdatecustomdependency-checkforerrorsf5bigip"></a>

**Signature:** `CheckForErrorsF5BigIp(rc: integer, Buffer: string, ErrBuffer: string)`

**Parameters:**

- `rc` (integer, required)
- `Buffer` (string, required)
- `ErrBuffer` (string, required)

**Caller-scope reads:** `DependentCommand`, `OutputBuffer`

**Calls:** `ParseError`

**Sets locally:** `Result`

**Returns:** `%{ rc == 0 }%`, `false`

### `CheckForErrors` <a id="fn-unixupdatecustomdependency-checkforerrors"></a>

**Signature:** `CheckForErrors(rc: integer, Buffer: string, ErrBuffer: string)`

**Parameters:**

- `rc` (integer, required)
- `Buffer` (string, required)
- `ErrBuffer` (string, required)

**Caller-scope reads:** `ErrBuf`, `OutputBuffer`

**Calls:** `ParseError`

**Sets locally:** `Result`

**Returns:** `false`, `true`

### `ParseError` <a id="fn-unixupdatecustomdependency-parseerror"></a>

**Signature:** `ParseError(rc: integer, Buffer: string, ErrBuffer: string)`

**Parameters:**

- `rc` (integer, required)
- `Buffer` (string, required)
- `ErrBuffer` (string, required)

**Caller-scope reads:** `DelegationPrefix`, `DependentCommand`, `FuncUserName`, `LogStdout`

**Calls:** _(none)_

**Sets locally:** `Output`, `sudoErrs`, `VisibleOutput`

**Returns:** `%{ rc == 0 }%`, `false`

### `UnixUpdateCustomDependency` <a id="fn-unixupdatecustomdependency-unixupdatecustomdependency"></a>

**Signature:** `UnixUpdateCustomDependency(Platform: string)`

**Parameters:**

- `Platform` (string, required)

**Caller-scope reads:** `AssetName`, `CommandArguments`, `DependentCommand`, `Exception`, `LogCommand`, `LogCommandArguments`, `LogStdin`, `LogStdout`, `ResolvedCommand`, `StdinArguments`

**Calls:** `CheckForErrors`, `CheckForErrorsF5BigIp`

**Sets locally:** `ConnectSsh`, `ErrBuf`, `Global:ResolvedCommand`, `LogCmd`, `OutputBuffer`, `rc`, `Result`

**Returns:** `%{ Result }%`

---

_Generated 2026-06-03 from Hercules sources at_ E:\source\SPP\Hercules\Source\Hercules.WebService\PlatformDefinitions\System\Imports.

