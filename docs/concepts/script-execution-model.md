[← Concepts](README.md)

# Script Execution Model

This document explains what happens when SPP runs a custom platform script — from the moment you upload a JSON file to the moment a task executes against a target system.

## Upload and Validation

When you upload a script (via the web UI or `Import-SafeguardCustomPlatformScript`), SPP performs these steps in order:

1. **JSON parse** — The file must be valid JSON. Syntax errors are rejected immediately.
2. **Structure validation** — SPP checks for required top-level keys (`Id`, `BackEnd`). Operations and functions are validated for correct structure but `Parameters` defaults to an empty array and `Do` may be absent.
3. **Parameter type checking** — Each parameter is validated against known types (string, boolean, integer, password/secret). Reserved parameter names are matched against their expected types.
4. **Import expansion** — If the script declares `Imports`, SPP locates the referenced function libraries and loads their function definitions into memory for runtime use. The imported functions are not serialized into the stored definition.
5. **Feature flag derivation** — SPP scans the operations present in the script and sets capability flags automatically. See [Feature Flags](feature-flags.md).
6. **Storage** — The validated script is stored in the SPP database and the platform is ready for use.

## Task Execution

When SPP needs to perform an operation (e.g., a scheduled password check), this is the execution flow:

### 1. Operation Selection

SPP determines which operation to call based on the task type:
- A password check task invokes `CheckPassword`
- A password change task invokes `ChangePassword`
- An account discovery task invokes `DiscoverAccounts`
- And so on for the other supported operations

### 2. Parameter Population

SPP auto-populates reserved parameters from the asset and account configuration:
- `Address` ← asset network address
- `Port` ← asset connection port
- `FuncUserName` / `FuncPassword` ← service account credentials
- `AccountUserName` / `AccountPassword` ← managed account credentials
- `NewPassword` ← the SPP-generated replacement password (for change operations)

Custom parameters retain their configured default values unless overridden at the asset level.

### 3. Script Engine Execution

The scripting engine processes the operation's `Do` array sequentially:

1. Each command in the `Do` array is executed in order.
2. Variable interpolation (`%VariableName%`) is resolved at execution time.
3. Commands may set variables, make connections, send data, or branch execution.
4. Flow control commands (`Condition`, `Switch`, `For`, `ForEach`) alter the execution path.
5. Functions can be called and may return values.
6. Error handling (`Try`/`Catch`) provides recovery paths.

### 4. Result Determination

The operation result is determined by:
- **Success** — The `Do` block completes with result type `Ok`. For check operations (e.g., `CheckPassword`), the boolean return value indicates the check outcome (match vs. mismatch) but the operation itself succeeds either way when the result type is `Ok`.
- **Failure** — The result type is not `Ok`, the return data cannot be parsed as a boolean, or an unhandled exception escapes the `Do` block.

For discovery operations, success is determined by the result type and return value, not by whether `WriteDiscoveredAccount` (or `WriteDiscoveredService`) was called.

## Connection Lifecycle

For SSH operations, the connection lifecycle is:
1. `Connect` opens the SSH session (interactive or batch mode)
2. Commands interact with the remote system
3. `Disconnect` closes the session
4. If the script ends without `Disconnect`, the engine cleans up automatically

For HTTP operations, there is no persistent connection — each `Request` is independent (though cookies and session state persist across requests within a single operation execution).

## Import Libraries

When a script declares `Imports`, the referenced function libraries are loaded into memory at upload time. At runtime, these imported functions are available for the script to call just like locally-defined functions.

Import libraries provide reusable patterns for common tasks (e.g., SSH login sequences, privilege escalation, output parsing). See [Imports Reference](../reference/imports.md) for the full catalog.

## Error Propagation

Errors propagate up the call stack:
1. A command fails or `Throw` is called
2. If inside a `Try` block, execution jumps to the `Catch` block
3. If not caught, the error propagates to the calling function
4. If uncaught at the top level, the operation fails

The task log captures all errors and, with `ExtendedLogging` enabled, captures the full execution trace.

## Related

- [Architecture](architecture.md) — high-level overview
- [Feature Flags](feature-flags.md) — how capabilities are derived
- [Operations Reference](../reference/operations.md) — all 24 supported operations
- [Testing and Debugging](../guides/testing-and-debugging.md) — how to diagnose execution issues
