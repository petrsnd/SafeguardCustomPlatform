[← Quick Start](README.md)

# Quick Start: HTTP Form-Fill Password Check

Get a working custom platform that validates credentials against a web login form in under 5 minutes.

## What You'll Get

A minimal platform script that navigates to a login page, fills in the username and password fields, submits the form, and checks whether the login succeeded — the same pattern used by the Facebook and Twitter samples.

## When to Use Form-Fill vs. REST API

| Approach | Use when... |
| --- | --- |
| **REST API** ([HTTP API Quick Start](http-api-check.md)) | The target exposes a programmatic API with JSON responses |
| **Form-Fill** (this guide) | The target only has a web login page with HTML forms |

## Steps

### 1. Start with the Minimal HTTP Template

Download or copy [`TemplateHttpMinimal.json`](../../templates/TemplateHttpMinimal.json) and rename it (e.g., `MyWebAppFormFill.json`).

### 2. Replace CheckSystem with a Form-Fill Login

Replace the `CheckSystem` operation with one that fetches the login page, extracts the form, fills in credentials, and submits:

```json
"CheckSystem": {
  "Do": [
    { "BaseAddress": { "Address": "https://%Address%" } },
    { "NewHttpRequest": { "ObjectName": "LoginPageReq" } },
    { "Request": {
        "Verb": "Get",
        "Url": "/login",
        "RequestObjectName": "LoginPageReq",
        "ResponseObjectName": "LoginPageResp"
    } },
    { "ExtractFormData": {
        "ResponseObjectName": "LoginPageResp",
        "FormObjectName": "LoginForm"
    } },
    {
      "Condition": {
        "If": "LoginForm == null",
        "Then": { "Do": [
          { "Throw": { "Value": "Login form not found on page" } }
        ] }
      }
    },
    { "SetFormValue": {
        "FormObjectName": "LoginForm",
        "InputName": "username",
        "Value": "%FuncUserName%"
    } },
    { "SetFormValue": {
        "FormObjectName": "LoginForm",
        "InputName": "password",
        "Value": "%FuncPassword%",
        "IsSecret": true
    } },
    { "NewHttpRequest": { "ObjectName": "LoginPostReq" } },
    { "Request": {
        "Verb": "Post",
        "Url": "%LoginForm.Action%",
        "RequestObjectName": "LoginPostReq",
        "ResponseObjectName": "LoginPostResp",
        "Content": {
          "ContentObjectName": "LoginForm",
          "ContentType": "application/x-www-form-urlencoded"
        }
    } },
    {
      "Condition": {
        "If": "LoginPostResp.StatusCode == 200 || LoginPostResp.StatusCode == 302",
        "Then": { "Do": [{ "Return": { "Value": true } }] }
      }
    },
    { "Throw": { "Value": "Login failed: HTTP %{LoginPostResp.StatusCode}%" } }
  ]
}
```

### 3. Adapt for Your Login Page

You'll likely need to adjust:

| What to change | How to find it |
| --- | --- |
| Login URL (`/login`) | Open the page in a browser and note the URL |
| Form field names (`username`, `password`) | Inspect the `<input>` elements in the HTML source |
| Success condition | Some sites redirect (302), others return 200 with a session cookie |

> **Tip:** If the page has multiple `<form>` elements, add an `"XPath"` parameter to `ExtractFormData` to select the right one:
> ```json
> "XPath": "//form[@id='login-form']"
> ```

### 4. Cookie Persistence

Cookies persist by default across requests within the same operation (`PersistCookies: true` is the default on `Request`). No extra step is needed for session tracking.

### 5. Upload to SPP

```powershell
# Create a new custom platform with the script
New-SafeguardCustomPlatform -Name "MyWebAppFormFill" -ScriptFile .\MyWebAppFormFill.json

# To update an existing platform's script later:
# Import-SafeguardCustomPlatformScript -PlatformToEdit "MyWebAppFormFill" -ScriptFile .\MyWebAppFormFill.json
```

### 6. Create an Asset

1. In the SPP web UI, go to **Asset Management > Assets > Add**
2. Set the platform to your new custom platform
3. Set the network address to the web application hostname
4. Assign a service account with valid login credentials

### 7. Test

```powershell
Test-SafeguardAsset -AssetToTest "MyWebApp" -ExtendedLogging
```

If it reports success, SPP can log in to your web application.

## Key Concepts for Form-Fill

- **`ExtractFormData`** parses HTML and extracts all `<input>` fields, including hidden CSRF tokens
- **`SetFormValue`** updates a field before submission — hidden fields are preserved automatically
- Cookies persist by default (`Request.PersistCookies` defaults to `true`), so session cookies flow between requests automatically
- **`IsSecret: true`** on password fields prevents credentials from appearing in logs
- The form's `Action` attribute is available as `%LoginForm.Action%` for the submit URL

## Next Steps

- Add `CheckPassword` and `ChangePassword` — study the [Facebook sample](../../samples/http/facebook/) for the full pattern
- Learn about CSRF tokens and multi-step forms — see [Forms Reference](../reference/commands/forms.md)
- Handle login challenges (CAPTCHAs, MFA prompts) — see the [Twitter sample](../../samples/http/twitter/)
- Read about HTTP cookie management — see [Cookies Reference](../reference/commands/cookies.md)
