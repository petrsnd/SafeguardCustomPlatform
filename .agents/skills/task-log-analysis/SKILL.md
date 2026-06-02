---
name: task-log-analysis
description: >-
  Use when an operation has run and produced an extended task log that
  must be classified and turned into a next step. Pulls or accepts the
  extended task-log JSON, classifies the failure phase
  (connect / auth / parse / operation / unknown), extracts actionable
  signals, and recommends the next iteration. Backed by the
  failure-pattern catalog at docs/agent-reference/failure-patterns.md,
  which ships empty and is grown only from real runs.
---

<!--
Body authored in Phase 3 (see agent-skills-plan.md §6 Phase C).

Required content (per agent-skills-plan.md §5):
- Classification flow: connect / auth / parse / operation / unknown.
- Signal extraction from extended task-log JSON.
- Next-step recommendation hooked into the iterative debug loop in
  AGENTS.md.
- Cites docs/agent-reference/failure-patterns.md (empty in Phase 1;
  populated from real runs in Phase 5/F).
- Modes: full-loop (live log fetch); author-only when given a saved
  task-log JSON file.
- Pre-flight pointer to AGENTS.md.
-->
