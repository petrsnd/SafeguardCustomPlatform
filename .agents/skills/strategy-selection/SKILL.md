---
name: strategy-selection
description: >-
  Use to decide the implementation approach for a custom platform from
  protocol, vendor documentation, and probe evidence. Maps inputs to a
  recommendation across SSH (interactive vs batch) and HTTP (form-fill
  vs API; basic / bearer / api-key; password vs key vs API key;
  self-managed vs service-account). Accepts both fetched URLs and
  vendor-doc excerpts the user pasted into the conversation.
---

<!--
Body authored in Phase 3 (see agent-skills-plan.md §6 Phase C).

Required content (per agent-skills-plan.md §5):
- Decision tree backed by docs/agent-reference/strategy-decision-tree.md.
- Rules for when to surface a question to the user vs decide autonomously.
- Vendor-doc handling: URL fetch path AND pasted-excerpt path; both are
  first-class inputs. Cite docs/agent-reference/vendor-doc-search-recipes.md.
- Modes: author-only, probe-only, full-loop.
- Pre-flight pointer to AGENTS.md for the active workflow algorithm.
-->
