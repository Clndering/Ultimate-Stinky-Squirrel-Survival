# Godot GDScript parser fix — iOS / itch.io edition

Issue: Godot reports `Cannot infer the type of "err" variable because the value doesn't have a set type.`

File: `scripts/Main.gd`, in `_start_host()` and `_start_join()`.

Cause: The ENet peer is instantiated dynamically with `ClassDB.instantiate(...)`, so calling `peer.create_server()` or `peer.create_client()` returns a value that the static analyzer cannot use with `var err := ...`.

Changes:

```gdscript
# In _start_host():
var err: int = int(peer.call("create_server", PORT, MAX_GUESTS))

# In _start_join():
var err: int = int(peer.call("create_client", addr, PORT))
```

The existing error checks and toast messages remain unchanged. The browser build continues to disallow native UDP ENet hosting/joining; these functions are used only in native Godot releases.

## Use the corrected project

1. Extract this complete RAR archive to a **new folder**.
2. Open **this folder's** `project.godot` with Godot **4.7.x**.
3. Allow Godot to import assets and reload all scripts.
4. Run **Project > Run Project**. If another error appears, report the **file, line number and full error text**.

Checks performed for this package: exact replacement of both untyped ENet error declarations, source/asset integrity checks, and byte-for-byte RAR content verification. A full Godot 4.7 compile and iOS Safari browser run could not be executed in this environment; they are **not** claimed as passed.
