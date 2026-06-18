[← Agent reference](README.md)

# Script-authoring deep dives

Long-form reference material extracted from the `script-authoring` skill. The skill points here for topics that are too dense to live inline. Every entry below is grounded in repo samples, on-disk templates, or [`failure-patterns.md`](failure-patterns.md) rows.

## Bake diagnostics in on the first try

Every appliance round-trip (validate → import → trigger → fetch task log) costs the operator real time. Treat it as the most expensive resource in the loop. Before a trigger, mentally walk through every failure branch the script can take and ask: *if this fails, will the task log tell me **why**, or will I need another iteration to find out?* If the answer is "another iteration", instrument the script before triggering — not after the first failure surprises you.

Concrete rules for any `Send`/`ExecuteCommand` block whose output is parsed:

- **Capture stderr.** Use `2>&1` (combine streams) for shell pipelines whose output you parse. Never `2>/dev/null`. Never bare stdout-only on a command that can fail. The actual diagnostic almost always comes out on stderr.
- **Capture exit codes explicitly.** Prefer `cmd 2>&1; echo MARKER_RC_$?\n` over `cmd && echo OK || echo FAIL`. The numeric code distinguishes auth failure from permission failure from syntax failure without another round trip; the binary OK/FAIL form throws that information away.
- **Suppress sudo's password prompt** with `-S -p ''` when piping a password into sudo. Without `-p ''`, sudo's prompt text leaks into the captured buffer and pollutes the regex / parse logic of whatever command follows.
- **Terminate `Send` buffers with `\n`.** A PTY shell will not execute a typed line until it sees a newline. A `Send` without `\n` causes the next `Receive` to time out (or match echo) — a silent class of bug that costs an entire iteration to diagnose.
- **Echo the parsed buffer back** via `WriteResponseObject` (or the equivalent diagnostic command) so it lands in the task log. Without this, parse-condition failures in `Condition` blocks produce a `Returning false` with no visible reason — another wasted iteration.

## When two iterations fail with the same signature, stop drafting and grep

If iteration N+1 fails with the same classified phase and substantively the same signature as iteration N (same `Status` enum value, same parse failure in the same `Receive`, same regex that did not fire), switch from drafting to sample-mining:

1. Run `grep -rn "<construct>" samples/<protocol>/` for the construct that is failing — `passwd`, `chpasswd`, `Bearer`, `HttpAuth`, `ExtractJsonObject` against a similar response shape, etc.
2. **Read the matching sample's full operation in context**, not just the line that grep returned. The shape around the line — what `Receive` precedes it, which buffer is marked `ContainsSecret`, whether the surrounding command has quotes — is usually what makes the sample work.
3. Port the working shape into the draft as a single change. Trigger. If the new failure is in a different phase, the port worked; iterate from there.

## Function-call signatures: copy from samples, do not infer

When emitting a `Function` call — whether to a locally-defined function, an imported library function, or anything else with a name and `Parameters` array — the agent **must** find at least one working call site for that function in `samples/` and copy the `Parameters` array shape verbatim.

- The call's `Parameters` field is a positional array; calls do not name their arguments. Order matters; arity matters.
- Public prose docs (e.g., [`docs/reference/imports.md`](../reference/imports.md)) list library and function names but **deliberately do not document call signatures**. That is not an oversight — the deployed appliance's view of an imported function's arity can drift from any external reference. Samples are the only source of call shapes that round-trip through CI against shipped appliances.
- Search the whole `samples/` tree, not just the closest production sample for the active pattern. A function may be imported by several samples in different sub-trees.
- If no sample exercises the call you need, **stop and ask** the operator. The fallback is empirical probing via `Test-SafeguardCustomPlatformScript`: submit a call with a deliberate-arity guess and read the appliance's `expects N parameters` error literally. The appliance is authoritative for its own deployed signature.
- Do not pad with `""` to match a guessed arity, do not reorder a sample's call to "look more logical," and do not infer a parameter from a function name.

If a sample's call site uses 3 args and another uses 4, that is a real signal: either the function is overloaded, or one of those samples shadows the import with a locally-defined function of the same name. Read the sample's `Imports` and `Functions` blocks before copying — the right call site is the one whose enclosing script imports the same library yours does.

## `CheckPassword` on Linux: pass the whole shadow line to `CompareShadowHash`

The authoritative pattern is in [`samples/ssh/generic-linux/GenericLinux.json`](../../samples/ssh/generic-linux/GenericLinux.json) lines 220–245:

1. `ExecuteCommand`: `sudo -S /usr/bin/getent shadow %AccountUserName%` (batch mode has no PTY, so `-S` is required).
2. Capture the whole stdout buffer into `%AccountEntry%`.
3. `CompareShadowHash` with `SaltedHash: "%AccountEntry%"` — **pass the whole shadow line, not a pre-extracted field**. The component handler splits on `:` and pulls field[1] internally.
4. `Condition` on `PasswordHashMatched == true` → `Return true`; else `Return false`.
5. Wrap the whole sequence in `Try`/`Catch`; the `Catch` is the **fallback** for environments where `getent` is unavailable (locked-down sudo, no shadow read), not a hash-format workaround.

**Do not pre-split the shadow line in a `SetItem` expression** (`ShadowLine.Split(':')[1]`). Two compounding reasons:

- It is unnecessary — `CompareShadowHash` does the split itself.
- It triggers a Z.Expressions overload-ambiguity error on `string.Split(char)` (catalogued in [`failure-patterns.md`](failure-patterns.md)), and the resulting `Try`/`Catch` fallback emits a sentinel verdict that looks like a target-state mismatch but is really a script bug.

`CompareShadowHash` understands yescrypt (`$y$j9T$…`, default on Ubuntu 22.04+ / Debian 12+), bcrypt, SHA-512, SHA-256, MD5, and AIX SSHA. There is no hash-format reason to abandon it for an auth-by-login primary; auth-by-login is the documented `Catch` fallback only.

## Catch blocks must log before falling back

Any `Try`/`Catch` whose `Catch` produces a verdict (rather than re-raising) **must log the caught exception** via `WriteResponseObject` (or a `Status` message that includes the exception text) before emitting the fallback value. Otherwise the next agent reads a clean verdict — `PasswordMismatch`, `false`, `Error` — and attributes it to target state when the actual cause was a script-side bug the catch swallowed. A Z.Expressions overload error in a pre-split `SetItem`, for example, will surface as a bare `PasswordMismatch` unless the catch emits the inner exception text.
