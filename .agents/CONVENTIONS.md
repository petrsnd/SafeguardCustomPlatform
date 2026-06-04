# Notation conventions

Agent-facing material in this repo distinguishes three shapes so an agent never has to guess whether a token is a cmdlet parameter, an API field, or a transport-agnostic idea.

- **PowerShell** — backtick the literal as it appears in `Get-Help <Cmdlet> -Full`. Switches stand alone; valued parameters use a space before the value.
  - `` `-ExtendedLogging` `` (switch), `` `-TaskId <GUID>` `` (valued), `` `Connect-Safeguard -DeviceCode` `` (cmdlet + switch).
- **API / JSON** — backtick a PascalCase field as `Field: value`, mirroring the transfer-object shape SPP emits and accepts.
  - `` `ExtendedLogs: true` ``, `` `OperationType: CheckPassword` ``.
- **Concept (transport-agnostic)** — plain English, no backticks. Use this in orchestration prose where the agent should not yet be biased toward PS or API.
  - "with extended logging enabled", "trigger the affected operation".

Rule of thumb: `AGENTS.md` speaks **concept**. The skills speak **PowerShell** (e.g., `safeguard-ps-operations`) or **API** with backticks. When a skill bridges them, it shows both forms side by side.
