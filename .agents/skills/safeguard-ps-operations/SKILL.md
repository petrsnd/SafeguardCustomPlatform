---
name: safeguard-ps-operations
description: >-
  Use when the agent must drive a live SPP appliance through safeguard-ps
  to validate, import, trigger, and inspect a custom platform script.
  Covers Connect-Safeguard -Browser auth, the cmdlet menu
  (Test- / Import- / Export- / asset / account / trigger), idempotency,
  extended-logging triggers, task-log JSON retrieval, and how to call
  tools/Invoke-PlatformDevLoop.ps1 instead of re-implementing the loop.
  All cmdlet syntax must be sourced from Get-Help <Cmdlet> -Full against
  the installed module, never paraphrased from memory.
---

<!--
Body authored in Phase 3 (see agent-skills-plan.md §6 Phase C).

Required content (per agent-skills-plan.md §5):
- Connect-Safeguard -Browser (PKCE) only. No password-in-script recipes.
- Cmdlet menu: Test-SafeguardCustomPlatformScript,
  Import-SafeguardCustomPlatformScript, Export-… read-back check
  (source-of-truth for enhance-platform), asset/account create-or-update
  idempotency, trigger Restore/Elevate/Demote/Suspend with
  extendedLogging=true, fetch task log JSON.
- Mandate: cmdlet syntax sourced from Get-Help <Cmdlet> -Full against the
  installed safeguard-ps module. No paraphrase from memory.
- Wraps tools/Invoke-PlatformDevLoop.ps1 (Phase 2) for the standard loop.
- Modes: full-loop primarily; Test-… and Export-… read-back also work in
  author-only when given a local file.
- Pre-flight pointer to AGENTS.md.
-->
