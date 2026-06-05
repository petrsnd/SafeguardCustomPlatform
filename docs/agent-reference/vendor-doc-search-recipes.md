[← Agent reference](README.md)

# Vendor doc search recipes

Used by the `strategy-selection` skill (and indirectly by `script-authoring`) to obtain authoritative vendor documentation about a target system. Two input paths are equally first-class:

1. **The agent has web search.** Use the query templates below, then normalize the result.
2. **The user pasted vendor-doc content into the conversation.** Use the normalization recipe directly.

Either way, the goal is a small, structured "vendor evidence" record that strategy-selection can reason over without re-reading raw vendor pages.

## Query templates

Replace `<vendor>` with the target product name (e.g., "Okta", "WordPress", "vCenter"). Replace `<version>` with the actual deployed version when known; omit if not. Prefer official vendor domains in the result list.

### HTTP / REST API

- Authentication scheme(s):
  - `<vendor> REST API authentication`
  - `<vendor> API basic auth OR bearer token OR api key`
  - `<vendor> OAuth2 client credentials token endpoint`
- Password change / credential rotation endpoint:
  - `<vendor> API change password endpoint`
  - `<vendor> API reset user password REST`
  - `<vendor> API rotate api key`
- Account discovery / enumeration:
  - `<vendor> API list users pagination`
  - `<vendor> API search users filter`
- Pagination shape (when the API documents one):
  - `<vendor> API pagination cursor OR offset OR link header`
- Form-fill fallback (when no public API exists):
  - `<vendor> change password form action url`
  - `<vendor> login form CSRF token field name`

### SSH

- Login and shell behavior:
  - `<vendor> SSH login banner`
  - `<vendor> default shell <version>`
  - `<vendor> CLI prompt format`
- Password change command:
  - `<vendor> change password CLI command`
  - `<vendor> service account password rotation`
- Privilege escalation:
  - `<vendor> sudo NOPASSWD service account`
  - `<vendor> root password change command`
- Discovery:
  - `<vendor> list local accounts command`
  - `<vendor> /etc/passwd format`
- SSH key management:
  - `<vendor> authorized_keys path location`
  - `<vendor> sshd_config AuthorizedKeysFile`

## Choosing among results

Prefer, in order:

1. The vendor's own documentation site (e.g., `developer.<vendor>.com`, `docs.<vendor>.com`).
2. The vendor's API reference (Swagger/OpenAPI page if published).
3. The vendor's release notes for the deployed `<version>` — these often describe behavioral changes the agent must account for.
4. Vendor-published code samples in their official SDK repos.

Do not treat third-party blog posts as authoritative. They are useful for orientation but the script must be grounded in a vendor-controlled source before it is shipped.

## Normalization recipe

Whether content arrived from web search or from a paste, distill it into the same shape before handing it to `strategy-selection`. Cite the source URL or paste so the user can audit.

```
Vendor: <product name>
Version: <deployed version, or "unspecified">
Source: <URL or "user-pasted excerpt">
Captured: <ISO date>

Authentication:
  - scheme: <basic | bearer | api-key | form | unspecified>
  - endpoint: <token / login URL when applicable>
  - notes: <one or two short notes; e.g., "OAuth2 client credentials">

Operations:
  - <operation name>:
      method: <HTTP verb or shell command>
      endpoint: <URL or command path>
      payload: <field names; no secrets>
      notes: <quirks, required headers, expected status codes>

Pagination:
  - shape: <cursor | offset | link-header | none>
  - parameters: <field names>

Quirks:
  - <one or two notes the agent should remember; e.g., "401 has empty body", "POST returns 204 on success">
```

Rules:

- **No secrets.** Strip any tokens, passwords, or sample API keys from the captured content before saving.
- **One source per record.** If multiple vendor pages were consulted, produce one record per page and let strategy-selection consider them as siblings.
- **Verbatim quotes for surprising claims.** When the vendor doc says something counterintuitive (e.g., "401 has an empty body"), include the exact sentence and the URL.

## When the user pasted content

Treat the paste as the source. Do not re-fetch unless the user asks — they may be working in an environment where the agent has no web access, and silent re-fetching changes the grounding.

If the paste appears truncated (unbalanced JSON, cut-off URLs, mid-sentence), surface this to the user and ask whether to proceed with what's available or wait for a fuller paste.

## When the agent has no web search

Web search is not available in every agent runtime. If the agent cannot fetch and the user has not pasted vendor docs, `strategy-selection` falls back to:

1. Probe evidence from `target-probing` (auth-scheme detection, login-form inspection, etc.).
2. Asking the operator to paste the relevant vendor pages.

Do not invent vendor-doc content. If neither probes nor a paste are available, stop and ask.
