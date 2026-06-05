---
name: strategy-selection
description: >-
  Use to decide the implementation approach for a custom platform from
  protocol, vendor documentation, and probe evidence. Maps inputs to a
  recommendation across SSH (interactive vs batch) and HTTP (form-fill
  vs api). For http-api, also picks the auth shape — HttpAuth-managed
  (Basic, Digest) vs script-managed header (Bearer, custom Authorization
  scheme, custom-header API key) — and one-step vs two-step token fetch.
  Plus credential intent (password / SSH key / API key / bearer token)
  and self-managed vs service-account. Accepts both fetched URLs and
  vendor-doc excerpts the user pasted into the conversation.
---

# strategy-selection

## Pre-flight

Before recommending a pattern, consult [`AGENTS.md`](../../../AGENTS.md) for the active workflow algorithm. Strategy selection is the bridge between [`target-probing`](../target-probing/SKILL.md) and [`script-authoring`](../script-authoring/SKILL.md): it turns vendor docs plus probe evidence into a concrete recommendation, then hands off. It does not author JSON.

## Scope

Map `(protocol, vendor docs, probe evidence)` to one of the four authoring patterns covered by [`script-authoring`](../script-authoring/SKILL.md):

- `ssh-interactive`
- `ssh-batch`
- `http-api`
- `http-form-fill`

When `http-api` is the recommendation, also pick:

- **Auth shape bucket.** *HttpAuth-managed* (Basic, Digest) vs *script-managed header* (Bearer, custom `Authorization` scheme, custom-header API key).
- **Specific scheme** within the bucket (e.g., `Bearer` vs `PVEAPIToken=…` vs `X-API-Key`).
- **One-step vs two-step** — does the operator already hold the credential the script presents on every call (one-step), or must the script POST credentials to a token endpoint first (two-step)?

Plus two orthogonal dimensions that apply to every pattern: **credential intent** (password / SSH key / API key / bearer token) and **self-managed vs service-account**.

## Modes

`author-only`, `probe-only`, `full-loop`. The skill never contacts the appliance or the target. It reads inputs and produces a recommendation.

## Inputs

1. **Protocol.** From the operator's stated requirement and confirmed by `target-probing` (`evidence.protocol`).
2. **Vendor documentation.** Either a URL the agent has fetched, or content the operator pasted into the conversation. **Both are first-class.** Use [`docs/agent-reference/vendor-doc-search-recipes.md`](../../../docs/agent-reference/vendor-doc-search-recipes.md) for query templates and the normalization recipe.
3. **Probe evidence.** The artifact produced by [`target-probing`](../target-probing/SKILL.md), conforming to [`.agents/schemas/evidence.schema.json`](../../../.agents/schemas/evidence.schema.json).
4. **Operator-declared credential intent.** `credentialKind` from the evidence artifact (`password | ssh-key | api-key | bearer-token | unknown`). This is sourced from the operator, not inferred — that is a deliberate choice in the schema (lines 56–60).

## The decision tree

This skill **does not duplicate** the decision tree. The tree lives in [`docs/agent-reference/strategy-decision-tree.md`](../../../docs/agent-reference/strategy-decision-tree.md). This skill wraps it with prompting rules: when to ask the operator, when to decide autonomously, how to phrase the trade-off when both branches look viable.

When a recommendation is made, cite the row that drove it. *"Recommended `ssh-batch` because the [SSH branch row matching `ssh user@host '<command>' returns stdout/stderr/exit-code cleanly`](../../../docs/agent-reference/strategy-decision-tree.md#ssh-branch) matches probe record `<id>`."*

## Vendor-doc handling

Whether vendor docs arrive via URL fetch or paste, normalize them into the structured record shown in [`docs/agent-reference/vendor-doc-search-recipes.md`](../../../docs/agent-reference/vendor-doc-search-recipes.md) ("Normalization recipe") **before** running the decision tree:

```
Vendor: <product name>
Version: <deployed version, or "unspecified">
Source: <URL or "user-pasted excerpt">
Captured: <ISO date>
Authentication:  scheme / endpoint / notes
Operations:      method / endpoint / payload / notes
Pagination:      shape / parameters
Quirks:          one or two notes
```

This serves three purposes: it forces the agent to read the docs (not skim), it strips secrets, and it gives `script-authoring` a single citable artifact.

If the agent has no web search **and** the operator has not pasted vendor docs, fall back to:

1. Whatever `target-probing` captured under `httpFindings.apiDiscovery` or `sshFindings`.
2. Asking the operator to paste the relevant pages.

Do not invent vendor-doc content. The grounding rule applies.

## When to ask vs decide

The detailed rules per branch are in the decision tree. The skill-level meta-rules:

- **Ask** when the choice has security implications and probe evidence does not conclusively favour one option (e.g., Basic vs Bearer when both are documented; service-account vs self-managed when the deployment context is unclear).
- **Ask** when the operator has not stated `credentialKind` and probe evidence cannot infer it (a Bearer token in the operator's hand vs an API key looks similar in `httpFindings.authScheme`).
- **Decide** when probe evidence and vendor docs corroborate one option directly. State the decision and cite the corroborating evidence in one sentence — the operator can correct course before authoring begins.
- **Surface the trade-off** when both an SSH and an HTTP path are viable. Per the decision tree's top-level guidance, prefer HTTP when the API covers the required operations end-to-end without shell access; APIs tend to produce stabler scripts than shell-prompt scraping. Make the trade-off visible rather than picking silently.

## Self-managed vs service-account

Orthogonal to the four patterns. Decide based on vendor docs and probe evidence, not assumption (see the "Self-managed vs service-account" section of the decision tree). When in doubt, ask the operator which mode the deployment will use — the answer changes which operations the script must implement and may bring `service-account` parameters (like a separate `FuncUsername`/`FuncPassword`) into scope.

## Output

The skill emits a short structured recommendation to whichever caller asked, typically `script-authoring` next:

- **Recommended pattern** — one of the four.
- **For `http-api`:** auth shape bucket + specific scheme + one-step vs two-step.
- **Credential intent** — one of the schema-defined kinds.
- **Self-managed vs service-account** — pick or "ask operator".
- **Citations** — the decision-tree row that drove the choice, the vendor-doc record, and the relevant `probeRecord.id`s from the evidence artifact.
- **Open questions** — anything the agent could not decide with the available evidence. Surface these to the operator before authoring rather than after.

When evidence is incomplete, the recommendation is allowed to be conditional ("`http-api` with two-step Bearer if vendor confirms the token endpoint at `/oauth/token`; otherwise re-probe and revisit"). A conditional recommendation is preferable to a confident guess.

