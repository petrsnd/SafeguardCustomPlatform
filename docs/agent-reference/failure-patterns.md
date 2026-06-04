[← Agent reference](README.md)

# Failure patterns

This catalog maps real error signatures observed in extended task logs to likely causes and concrete next-step fixes. It backs the `task-log-analysis` skill.

## Status: empty by design

Per `agent-skills-plan.md` §5 and §6 Phase F, this file ships **empty in Phase 1** and is populated only from real runs during the maiden voyage in Phase 5/F. Rows mined from prose guides or invented from memory are explicitly not acceptable — they undermine the skill they support.

When this catalog has rows, each one is grounded in:

- a captured extended task-log JSON (kept under version control or referenced by run ID), and
- a concrete fix that was applied and verified against the same target.

Until Phase 5/F runs, `task-log-analysis` falls back to its classification flow (connect / auth / parse / operation / unknown) and asks the operator for guidance on signatures it has not seen before.

## Validate-phase errors

Errors raised by `Test-SafeguardCustomPlatformScript` (and equivalent server-side import validation) are **not** extended task-log failures — they are caught before the script ever runs. They are catalogued separately so the strict provenance rule above is preserved for the trigger-time table.

Each row is grounded in a real `Test-SafeguardCustomPlatformScript` response captured during authoring.

| signature | likely cause | recommended fix | first observed |
| --- | --- | --- | --- |
| `Function 'X' expects N parameters, but is being called with M` | Caller is passing the wrong number of positional args to an imported (or local) function. The public docs at `docs/reference/imports.md` deliberately do not list signatures because the deployed appliance's view can drift from any external reference. | Grep `samples/` for `"Name": "X"` and copy the `Parameters` array from a working call site that imports the same library. If no sample exercises the call, attempt the call with a guess and read the appliance's `expects N` error literally — the appliance is authoritative for its own deployed signature. Order in the array is positional; calls do not name their parameters. | 2025-01 / generic-linux (LoginSsh observed during Phase 5 maiden voyage; Hercules `master` declared 4 params but appliance and 14 of 15 sample call sites use 3) |

## Asset-onboarding errors

Errors raised by `New-SafeguardCustomPlatformAsset` (and equivalent appliance APIs that create or onboard a custom-platform asset) — these happen **before** any task runs, so the script itself never executes. The appliance is inspecting the platform's *shape* to decide what protocol it speaks and which onboarding steps to wire up.

Each row is grounded in a real cmdlet response captured during authoring or onboarding.

| signature | likely cause | recommended fix | first observed |
| --- | --- | --- | --- |
| `60306: Platform does not support SSH authentication.` (returned by `New-SafeguardCustomPlatformAsset` when `-AcceptSshHostKey` or `-NoSshHostKeyDiscovery` is supplied for a custom platform whose script does not expose any SSH-recognized operation) | The appliance classifies a custom platform as "SSH-capable" by inspecting its operation set. If the script defines no operation that is recognized as SSH (notably `DiscoverSshHostKey`), the appliance refuses to onboard the asset under the SSH host-key flow and rejects with HTTP 400 / error 60306. Schema validation passes because the schema does not require `DiscoverSshHostKey` — this is a runtime classification rule, not a static one. | Add a `DiscoverSshHostKey` operation to the platform script (every SSH sample under `samples/ssh/` has one). Re-import the script, then retry asset creation. | 2026 / Phase 5 maiden voyage / Ubuntu 24.04 ssh-interactive draft (`VoyageUbuntuSshInteractive`) |

## Trigger-time errors (from extended task logs)

| signature | phase | likely cause | recommended fix | first observed |
| --- | --- | --- | --- | --- |
| `An error was thrown in the try block: "An interactive session is required"` (immediately after first `Send` on a successfully-opened SSH connection) | operation | The `Connect` command opened the SSH session without requesting a PTY, but the very first `Send` (or any subsequent `sudo` invocation against a target with `Defaults use_pty` in sudoers) requires an interactive shell. The Ubuntu 24.04 default sudoers sets `Defaults use_pty`, so any `sudo` will fail with this signature even if the initial bash session would have tolerated `Send` without a PTY. | Add `"RequestTerminal": "%RequestTerminal%"` (or `"RequestTerminal": true`) to every `Connect` command in the script, and declare a `RequestTerminal` parameter (`Type: Boolean`, `DefaultValue: true`) on every operation that opens a connection. The PTY allocation is a per-Connect setting, not a per-platform one. | 2026 / Phase 5 maiden voyage / Ubuntu 24.04 ssh-interactive draft (`VoyageUbuntuSshInteractive`) |
| `Sorry, try again.\r\nsudo: no password was provided\r\nsudo: 2 incorrect password attempts` (in a `Receive` buffer after a `(printf ... ) \| sudo -S ...` pipeline; the `Send` completed cleanly and `Connect` succeeded) | operation | Piping a password through a bash one-liner into `sudo -S` is brittle inside a PTY-allocated shell: the parent shell may strip or echo the password line in ways that defeat sudo's stdin read, and the only diagnostic ever printed is a generic "Sorry, try again". The pattern is also fragile to passwords containing shell metacharacters. The proven SSH password-rotation pattern in the repo never pipes the password — it sends `sudo passwd <user>` as a normal command, then walks through sudo's password prompt, the new-password prompt, and the retype-new-password prompt **as separate `Send`/`Receive` pairs**, with the password buffers marked `"ContainsSecret": true`. | Replace any `printf ... \| sudo -S ...` construct with the prompt-driven pattern from [`samples/ssh/generic-linux/GenericLinux.json`](../../samples/ssh/generic-linux/GenericLinux.json) lines 281–340 (`ChangeUserPassword`): `Send "sudo passwd <user>; echo CHGPASS=$?\n"`, then `Receive` the sudo prompt, `Send` `%FuncPassword%` (`ContainsSecret: true`, no surrounding quotes, no trailing `\n` — the appliance terminates secret sends itself), `Receive` `[Nn]ew.*[Pp]assword:`, `Send` `%NewPassword%`, `Receive` retype/new prompt, `Send` `%NewPassword%` again, `Receive` `CHGPASS=[0-9]+`. Capture the final buffer with `WriteResponseObject` so the task log shows the success/failure marker on the very next iteration. | 2026 / Phase 5 maiden voyage / Ubuntu 24.04 ssh-interactive draft (`VoyageUbuntuSshInteractive`) |

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
