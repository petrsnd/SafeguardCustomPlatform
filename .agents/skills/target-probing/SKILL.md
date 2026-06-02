---
name: target-probing
description: >-
  Use when the agent must learn how a live target system actually behaves
  before authoring or revising a custom platform script. Covers per-protocol
  recon recipes (SSH and HTTP) run from the operator's local shell with a
  seed credential, the probe-safety contract (read-only by default,
  per-probe consent for destructive probes, rate limits, no-production
  guard), and the structured evidence artifact consumed by
  strategy-selection and script-authoring.
---

<!--
Body authored in Phase 3 (see agent-skills-plan.md §6 Phase C).

Required content (per agent-skills-plan.md §5):
- Per-protocol playbooks: SSH (prompt, batch-mode probe, sudo behavior,
  password-change command) and HTTP (auth-scheme detection, login-form
  inspection, cookie behavior, API discovery).
- Probe-safety contract (mandatory): read-only default, per-probe consent
  for destructive probes, rate limit (default 3 auth/min), no-production
  guard, pre-flight echo, fail-closed on lockout/throttle/MFA signals.
- Evidence output conforming to .agents/schemas/evidence.schema.json.
- Modes: probe-only, full-loop. Fail closed in author-only.
- Pre-flight pointer to AGENTS.md for the active workflow algorithm and
  iterative debug-loop budget.
-->
