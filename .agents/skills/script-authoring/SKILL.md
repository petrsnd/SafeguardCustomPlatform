---
name: script-authoring
description: >-
  Use when drafting or revising the custom-platform JSON itself. Six
  pattern recipes (ssh-interactive, ssh-batch, http-api-basic,
  http-api-bearer, http-api-key, http-form-fill) cite schema, samples,
  and templates and cover Do blocks, status messages, custom parameters,
  and reserved variables. Mandates the fast inner loop: local schema
  validation against schema/ before any appliance round-trip. SchemaOnly
  green is necessary but not sufficient — cross-reference samples for
  analogous patterns before declaring ready.
---

<!--
Body authored in Phase 3 (see agent-skills-plan.md §6 Phase C).

Required content (per agent-skills-plan.md §5):
- Six pattern recipes: ssh-interactive, ssh-batch, http-api-basic,
  http-api-bearer, http-api-key, http-form-fill. Telnet out of scope.
- Each recipe cites schema/, samples/, templates/.
- Coverage: Do blocks, status messages, custom parameters, reserved
  variables.
- Mandate fast inner loop: local schema validation against schema/ first;
  Test-SafeguardCustomPlatformScript only after local validation passes.
- SchemaOnly is not a correctness signal — cross-reference samples and
  the reference corpus for analogous patterns before treating green as
  ready-to-import. Surface divergences from analogous samples.
- Modes: author-only, probe-only, full-loop.
- Pre-flight pointer to AGENTS.md.
-->
