[← Repository README](../../README.md)

# Agent reference corpus

This directory holds machine-first reference material for the agent skill system. It is cited from `AGENTS.md` and from individual `SKILL.md` files under `.agents/skills/`.

Human-facing documentation lives in `docs/concepts/`, `docs/guides/`, `docs/tutorials/`, `docs/reference/`, and `docs/quick-start/` and is not duplicated here. Per `agent-skills-plan.md` §5, agent-only content stays out of human-facing locations.

## Files

| File | Purpose | How it is maintained |
| --- | --- | --- |
| [`samples-index.md`](samples-index.md) | Normalized index of every sample and template (protocol, auth-scheme, operations, OS-family, file-path, README). | **Generated** by `tools/Build-SamplesIndex.ps1`. CI runs the same script with `-CheckOnly` and fails if the committed copy is stale. |
| [`strategy-decision-tree.md`](strategy-decision-tree.md) | Decision table that backs the `strategy-selection` skill (SSH and HTTP only). | Hand-maintained from `docs/guides/`. SSH and HTTP only. |
| [`failure-patterns.md`](failure-patterns.md) | Error-signature → likely cause → fix catalog used by `task-log-analysis`. | **Empty in Phase 1.** Rows are populated from real extended task logs in Phase 5/F. Invented rows are not acceptable. |
| [`vendor-doc-search-recipes.md`](vendor-doc-search-recipes.md) | Query templates for fetching vendor docs and a normalization recipe for pasted vendor-doc excerpts. | Hand-maintained. |

## Related contracts

- `.agents/schemas/evidence.schema.json` — JSON Schema for the probing evidence artifact produced by the `target-probing` skill and consumed by `strategy-selection` and `script-authoring`. This is an internal agent contract and is deliberately separate from `schema/custom-platform-script.schema.json`.
