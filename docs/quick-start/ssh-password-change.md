[← Quick Start](README.md)

# Quick Start: SSH Password Check

Get a working custom platform that validates a Linux password over SSH in under 5 minutes.

## What You'll Get

A minimal platform script that connects to a Linux host and verifies a managed account password using `CheckPassword`.

## Steps

### 1. Copy the Minimal Template

Download or copy [`TemplateSshMinimal.json`](../../templates/TemplateSshMinimal.json) and rename it (e.g., `MyLinuxCheck.json`).

### 2. Add CheckPassword

Open the file and add this `CheckPassword` operation after the existing `CheckSystem`:

```json
"CheckPassword": {
  "Parameters": [
    { "Address": { "Type": "String", "Required": true } },
    { "Port": { "Type": "Integer", "Required": false, "DefaultValue": 22 } },
    { "AccountUserName": { "Type": "String", "Required": true } },
    { "AccountPassword": { "Type": "Secret", "Required": true } }
  ],
  "Do": [
    { "Connect": {
        "ConnectionObjectName": "SshConn",
        "Type": "Ssh",
        "NetworkAddress": "%Address%",
        "Port": "%Port%",
        "Login": "%AccountUserName%",
        "Password": "%AccountPassword%"
    } },
    { "Disconnect": { "ConnectionObjectName": "SshConn" } },
    { "Return": { "Value": true } }
  ]
}
```

This connects with the managed account's credentials. If the connection succeeds, the script returns `true` to indicate the password is valid. Without an explicit `Return`, SPP treats the result as a failed check.

### 3. Upload to SPP

```powershell
# Create a new custom platform with the script
New-SafeguardCustomPlatform -Name "MyLinuxCheck" -ScriptFile .\MyLinuxCheck.json

# To update an existing platform's script later:
# Import-SafeguardCustomPlatformScript -PlatformToEdit "MyLinuxCheck" -ScriptFile .\MyLinuxCheck.json
```

### 4. Create an Asset

1. In the SPP web UI, go to **Asset Management > Assets > Add**
2. Set the platform to your new custom platform
3. Configure the network address (IP or hostname) and port (default 22)
4. Assign a service account (the account SPP uses to connect for `CheckSystem`)
5. Add a managed account (the account whose password you want to validate)

### 5. Test

```powershell
Test-SafeguardAssetAccountPassword -AssetToUse "MyLinuxHost" -AccountToUse "root" -ExtendedLogging
```

If it reports success, you have a working custom platform.

## Next Steps

- Add `ChangePassword` — see [Your First SSH Script](../tutorials/your-first-ssh-script.md)
- Understand the full script structure — see [Script Structure](../reference/script-structure.md)
- Study a production-ready sample — see [Generic Linux](../../samples/ssh/generic-linux/)
