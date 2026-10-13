# HeliX conventions

Rules for HeliX's public API, its examples, and the agents working on them. Naming follows libwgf's `docs/CONVENTIONS.md`, in Haxe's camelCase, so code and agents move between the two without translating.

## No backward compatibility

HeliX has no users to protect. When an API changes, every caller changes with it in the same commit: examples, tests and tools. Nothing keeps an old name, an old signature or an old behavior alive beside the new one: no aliases, deprecated wrappers, compatibility flags or shims.

The one exception is by design: `examples/asteroids-parity`'s `wgf` package, which presents libwgf's API to libwgf's own unchanged game. It is a compatibility layer for libwgf's API, and it follows HeliX's current API underneath.

## Names

| Kind | Form | Example |
| --- | --- | --- |
| Read a value | `getX()` | `window.getWidth()` |
| Change a value | `setX(...)` | `window.setSize(800, 600)` |
| A state now (a bool) | `isX()` | `window.isFullscreen()`, `input.isDown(Key.A)` |
| Whether something exists | `hasX()` | |
| Whether an action is possible here, so whether to offer it | `canX()` | `window.canMove()`, `host.canQuit()` |
| Ask for what the platform may refuse or grant later | `requestX(...)` | `window.requestFullscreen(true)` |
| An action | a verb | `host.quit()`, `batch.rect(...)` |

- **Methods, not Haxe properties.** Public state is read and changed through `get`/`set`/`is` methods, never public `var`s or `get_`/`set_` properties, so a setter can return whether it acted. The exceptions are composition (a host's services: `host.graphics`, `host.input`) and plain records of data (`Touch`).
- **Every setter has a getter:** `setX` with `getX`, or `isX` for a bool. A setter of several values (`setSize`) has a getter per value.
- **Say clamp or refuse.** A setter clamps when every value in range is the same request at another fidelity; it refuses, returning `false`, when the value would change what was asked or has no meaning here. Its comment says which, and a "False for ..." sentence names every refusal. A setter that can never refuse returns `Void`.
- **`request` returns whether it asked, never whether it was granted.** The answer is read back later with `is`, `get` or `can`: `requestFullscreen` returns whether the request was made; `isFullscreen` says, on a later frame, whether it was granted. `can` says whether to offer the request at all.
- **2D and 3D are named apart:** `Camera2D`, `Text2D`, `Batch2D`, so their 3D counterparts can sit beside them.

## Layout and documentation

Code is written to be read, by people and agents, not packed.

- **Formatted by the tool, not by hand.** Haxe source is laid out by haxe-formatter (`formatter` on lib.haxe.org) with the experiment's `hxformat.json`: one statement per line, indented blocks. Formatting is checked with the other checks, so dense one-line classes and functions don't come back.
- **Every public type and member has a doc comment** (`/** ... */`) saying what it is or does, in the units it uses, with its ranges and every refusal ("False for ..."). Private code gets a comment where the reason isn't plain from the code.
- **Generated API documentation.** The doc comments are the API reference: dox (`dox` on lib.haxe.org) generates it from them, so what a developer or an agent reads is what the code says.

## Examples

- An example shows a feature through the framework's API. Work that a game would otherwise repeat (hit tests, timers, layout) belongs in the framework; an example that has to do it by hand says so in its comment.
- Examples are developed in the browser hot-reload loop. Native builds, unit tests and cross-target checks run at checkpoints (the end of a feature or milestone), not after each change.
- Native checks that drive a window run on a private display (`tools/private_display.py`), never on the user's desktop: a new window takes the keyboard focus, so the user's typing would land in it.
