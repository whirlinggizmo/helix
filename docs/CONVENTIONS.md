# HeliX conventions

Rules for HeliX's public API, its examples, and the agents working on them. Names are predictable from what they do, so code and agents can find an API before reading it.

## No backward compatibility

HeliX has no users to protect. When an API changes, every caller changes with it in the same commit: examples, tests and tools. Nothing keeps an old name, an old signature or an old behavior alive beside the new one: no aliases, deprecated wrappers, compatibility flags or shims.

## Names

| Kind | Form | Example |
| --- | --- | --- |
| Read a value | `getX()` | `window.getWidth()` |
| Change a value, done when it returns | `setX(...)` | `window.setTitle("Asteroids")`, `node.setSize(64, 32)` |
| A state now (a bool) | `isX()` | `window.isFullscreen()`, `input.isDown(Key.A)` |
| Whether something exists | `hasX()` | |
| Whether an action is possible here, so whether to offer it | `canX()` | `window.canMove()`, `host.canQuit()` |
| Ask for what the platform may refuse or grant later | `requestX(...)` | `window.requestFullscreen(true)`, `window.requestSize(800, 600)` |
| An action | a verb | `host.quit()`, `batch.rect(...)` |

- **Methods, not Haxe properties.** Public state is read and changed through `get`/`set`/`is` methods, never public `var`s or `get_`/`set_` properties, so a setter can return whether it acted. The exceptions are composition (an app's `Services`: `services.graphics`, `services.input`) and records built once: a type made whole and never changed after (a parsed file's header, `Touch`, a progress report, `Hdr`'s size) may show `final` fields, since a field nothing can assign has no set to refuse. Anything that can change goes through methods; something kept and changed in place inside (InputState's touches) is handed out as a fresh record.
- **Every setter has a getter:** `setX` with `getX`, or `isX` for a bool. A setter of several values (`node.setSize`) has a getter per value.
- **Say clamp or refuse.** A setter clamps when every value in range is the same request at another fidelity; it refuses, returning `false`, when the value would change what was asked or has no meaning here. Its comment says which, and a "False for ..." sentence names every refusal. A setter that can never refuse returns `Void`.
- **`set` or `request`: whether the result is known when the call returns.** A `set` that returns true has happened: its getter answers the new value at once. When the platform decides later or may give something else (a window manager sizing or placing a window, a browser granting fullscreen, a driver granting multisampling), it's a `request`. Both return false, changing nothing, for a value that's invalid or impossible here.
- **`request` returns whether it asked, never whether it was granted.** The answer is read back later with `is`, `get` or `can`: `requestFullscreen` returns whether the request was made; `isFullscreen` says, on a later frame, whether it was granted. `can` says whether to offer the request at all.
- **A count names what it counts:** `getMsaaSamples()`, `getPadCount()`, never a bare `getSamples()`. **A limit comes first:** `getMaxMsaaSamples()`, `getMaxSteps()`, `getMinX()`.
- **A call that fills what it's given is a verb, not `get` or `set`:** `camera.computeRay(x, y, ray)`, `node.computeWorld(out)`, `matrix.makePerspective(...)` (the whole matrix overwritten). A `get` only reads; a `set` changes one value its getter answers.
- **A command for what follows in a pass is `apply`** (sokol's word): `graphics.applyViewport(...)`, `graphics.applyScissor(...)`. It's an instruction to the GPU's stream, not a value kept to read back.
- **No chaining.** Setters return `Void`, or `Bool` when they can refuse; none returns its object, which would make a call read like a property. Building something takes one call a line.
- **One concept, one name across types:** a sprite's part of its texture is its region everywhere (`setRegion`, `getRegionX`), not a region here and a source there.
- **Adapter classes are `<Api><Contract>Adapter`**, words the API's name ends with and the contract's starts with written once (`WebAudioAdapter`, not `WebAudioAudioAdapter`); ARCHITECTURE.md has the directories, and `tools/check_adapters.py` checks both.
- **2D and 3D are named apart:** `Camera2D`, `Text2D`, `Batch2D`, so their 3D counterparts can sit beside them.
- **Capitals:** `2D` and `3D` keep a capital D. Acronyms are written as words, as in Haxe's standard library (`Json`, `Xml`, `Http`): `getId`, `Url`, `IndexedDb`. Product names keep their own spelling (`WebGL2`, `Sokol`).

## Units

One unit per kind of value across the API, so nothing has to be converted at a call:

- **Angles are radians.** A positive angle turns from +x toward +y: clockwise on screen in 2D, where y grows downward. 3D is right-handed with +y up.
- **Time is seconds**, as a `Float`. A value in another unit says so in its name (`WorkQueue.getBudgetMs`) or, where the name can't, in its doc comment (`Services.getFrameCpu` and `getFrameInterval` are milliseconds).
- **Colors are `0xRRGGBBAA`** integers.
- **A simulation that must play alike on every target** (an autopilot's replay, lockstep, physics) takes its trigonometry from `helix.math.Trig`, never `Math`'s `sin`, `cos`, `tan`, `atan2`, `asin`, `acos`, `exp` or `log`, which differ in the last bit between the browser and native. Arithmetic, `sqrt`, `floor` and `pow` agree. Drawing may use `Math`.
- **Positions and sizes name their space** in the doc comment: framebuffer pixels (`IWindow`'s framebuffer size, the pointer), logical pixels (the window), or world units (a camera's).

## Layout and documentation

Code is written to be read, by people and agents, not packed.

- **Formatted by the tool, not by hand.** Haxe source is laid out by haxe-formatter (`formatter` on lib.haxe.org) with the repository's `hxformat.json`: one statement per line, indented blocks. Formatting is checked with the other checks, so dense one-line classes and functions don't come back.
- **Every public type and member has a doc comment** (`/** ... */`) saying what it is or does, in the units it uses, with its ranges and every refusal ("False for ..."). Private code gets a comment where the reason isn't plain from the code.
- **Generated API documentation.** The doc comments are the API reference: dox (`dox` on lib.haxe.org) generates it from them, so what a developer or an agent reads is what the code says.

```console
python3 tools/format.py         # lay out the Haxe source; --check only checks
python3 tools/check_docs.py     # list public API without a doc comment
python3 tools/check_types.py    # every entry point, both targets, in seconds
python3 tools/gen_apidoc.py     # the API reference: docs/api (committed; --check in the tests) and build/api/index.html
```

- **Tools are named verb_noun, words apart by underscores:** `check_types.py`, `gen_manifest.py`, `bake_fonts.py`, `pack_shader.py`; a `check_` tool only reports, a `gen_` tool makes files (committed ones, remade with `--regenerate`), the rest do what they say. The same for the Node scripts beside them (`check_cache.cjs`). Front doors keep their noun (`helix.py`, `tools/example.py`, `tools/services.py`, `tools/pages.py`).

The formatter and dox are pinned in `dependencies.json` and installed into the repository's own haxelib (`build/haxelib`), as hxcpp is.

## Examples

- An example shows a feature through the framework's API. Work that a game would otherwise repeat (hit tests, timers, layout) belongs in the framework; an example that has to do it by hand says so in its comment.
- Examples are developed in the browser hot-reload loop. Native builds, unit tests and cross-target checks run at checkpoints (the end of a feature or milestone), not after each change.
- Native checks that drive a window run on a private display (`tools/private_display.py`), never on the user's desktop: a new window takes the keyboard focus, so the user's typing would land in it.
