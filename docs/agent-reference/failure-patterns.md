[← Agent reference](README.md)

# Failure patterns

This catalog maps real error signatures observed in extended task logs to likely causes and concrete next-step fixes. It backs the `task-log-analysis` skill.

## Status: empty by design

Per `agent-skills-plan.md` §5 and §6 Phase F, this file ships **empty in Phase 1** and is populated only from real runs during the maiden voyage in Phase 5/F. Rows mined from prose guides or invented from memory are explicitly not acceptable — they undermine the skill they support.

When this catalog has rows, each one is grounded in:

- a captured extended task-log JSON (kept under version control or referenced by run ID), and
- a concrete fix that was applied and verified against the same target.

Until Phase 5/F runs, `task-log-analysis` falls back to its classification flow (connect / auth / parse / operation / unknown) and asks the operator for guidance on signatures it has not seen before.

<!--
Schema for future rows (locked down in Phase 5/F):

| signature | phase | likely cause | recommended fix | first observed |
| --- | --- | --- | --- | --- |

- `signature`: short stable token suitable for substring match against the
  task-log error text.
- `phase`: one of connect / auth / parse / operation / unknown.
- `likely cause`: one sentence, grounded in the captured task log.
- `recommended fix`: one or two sentences pointing at the JSON change or
  configuration adjustment that resolved the failure.
- `first observed`: ISO date and target type (e.g., 2026-07-15 / generic-linux).
-->
