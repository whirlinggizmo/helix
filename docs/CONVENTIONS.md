# HeliX conventions

Rules for HeliX's public API, its examples, and the agents working on them. Names are predictable from what they do, so code and agents can find an API before reading it.

## No backward compatibility

HeliX has no users to protect. When an API changes, every caller changes with it in the same commit: examples, tests and tools. Nothing keeps an old name, an old signature or an old behavior alive beside the new one: no aliases, deprecated wrappers, compatibility flags or shims.

## Names

HeliX is Haxe through and through, and its API uses what Haxe gives: properties for values, classes for kinds, static classes for the program's one set of services. The earlier C frameworks' rules (a method for everything, so a binding could be made of it; a type field instead of a class) were theirs, not Haxe's, and were dropped (DECISIONS 130).

| Kind | Form | Example |
| --- | --- | --- |
| A value | a property, read and assigned | `Window.title = "Asteroids"`, `light.intensity = 2`, `node.visible = false` |
| Several values set at once | `setX(...)` | `node.setPosition(x, y, z)`, `camera.setView(eye..., target...)` |
| A state now (a bool) | an adjective property | `node.visible`, `clock.paused`, `pad.connected` |
| A state asked with an argument | `isX(...)` | `Input.isDown(Key.A)`, `Input.isFramePressed(Key.Space)` |
| Whether an action is possible here, so whether to offer it | `canX()` | `Window.canMove()`, `Host.canQuit()` |
| Ask for what the platform may refuse or grant later | `requestX(...)` | `Window.requestFullscreen(true)`, `Window.requestSize(800, 600)` |
| An action | a verb | `Host.quit()`, `stage.add(node)`, `Models.load(path, done)` |
| A count or a limit | a property naming what it counts; the limit first | `Input.padCount`, `Graphics.msaaSamples`, `Graphics.maxMsaaSamples`, `ticker.maxSteps` |
| Fill what it's given | a verb, not a property | `camera.computeRay(x, y, ray)`, `node.computeWorld(out)` |
| A command for what follows in a pass | `applyX(...)` (sokol's word) | `Graphics.applyViewport(...)`, `Graphics.applyScissor(...)` |

- **A value is a property.** One that must act when assigned (a node's `x` dirties its matrix, a material's `baseColor` marks a GPU update) has a `set_` accessor; one read back from somewhere else has a `get_`; one nothing may assign is `(default, null)`. A record made whole and never changed after (`Touch`, a parsed header, a progress report) shows `final` fields. Nothing public is a bare `var` that something else keeps in step by hand.
- **A property clamps; a method may refuse.** Assigning can't answer, so a property takes what it's given, held to its range (an intensity under 0 is 0, a cone past its outer is the outer), and its doc comment says the range. Whatever can be refused or decided later is a method returning `Bool`: `requestSize`, `add`, `load`'s result.
- **`request` returns whether it asked, never whether it was granted.** The answer is read back later from a property: `requestFullscreen` returns whether the request was made; `fullscreen` says, on a later frame, whether it was granted. `can` says whether to offer the request at all.
- **No chaining.** A method that changes something returns `Void`, or `Bool` when it can refuse; none returns its object. Building something takes one statement a line.
- **A completion takes a lambda per outcome, success first:** `Models.load(path, file -> place(file))`, with the failure's lambda optional (`Models.load(path, file -> place(file), message -> caption = message)`): one left out is logged with the path, so nothing fails silently, and a cancelled request calls nothing, as its caller cancelled it. No result enum to switch on. A lambda made before a reload runs the code it came from (hotreload-hx), so a completion's lambda calls a method by name, `file -> place(file)`, never passes the method itself (`place` binds the old code when it's passed). In the browser the method it reaches is then the new one, and only the lambda's line is old for the frames a load takes. Natively an old lambda runs its old module through and through, and the `this` it captured is a copy the new code has left behind, unless what it calls is a `@:hot` static function, which every old closure reaches at its newest (hotreload-hx ef1d678); the browser loop is where reloads happen, and a game that must survive a native reload mid-load makes its completion `file -> Game.onLoaded(file)` with `onLoaded` a `@:hot` static. The build warns where a method is passed as a value. A callback registered once for the program's life (a frame, a resize, an input) is registered by the main class or again from `@:afterHotReload`, never kept from before.
- **Kinds are classes.** A `Node` is a name, the flags (`enabled`, `visible`, `pickable`), a parent and children, and `find`; a `Node3D` and a `Node2D` add their transforms, each taking children of its own kind only. What a stage holds is a `Node3D` and the framework's kinds on it: `Model`, `DirectionalLight`, `PointLight`, `SpotLight`, `Camera3D`, `Sprite3D`, `Text3D`, `Particles3D`, and on `Node2D`: `Sprite2D`, `Shape2D`, `Text2D`, `Particles2D`. A class holds only its kind's data. A game never subclasses a node, and nothing but drawing is a node: a behavior is run by a `Behaviors` pass the scene owns, holding the node it drives (DECISIONS 61 and 130).
- **A behavior is a class extending `Behavior`** (`helix.behavior`), run by a `Behaviors` pass, never by a node: `node` (the `Node3D` it drives, set by the pass before `start`), `enabled`, `done` (set true to end), and `start()`, `update(dt)`, `stop()` to override. Its props, what a scene file or an inspector sets, are `@:prop public var` fields with an initializer (`@:prop public var radius = 4.;`), of `Int`, `Float`, `Bool`, `String`, `Array<Float>`, a color (`@:prop("color")` on an `Int`) or `Node3D` (a reference); `@:range(min, max)` on a field gives an inspector its range; `@:behavior("Name")` on the class registers it under another name than the class's. The build macro generates the class's `schema()`, its typed setters and its registration in `BehaviorRegistry`, so a file names a behavior and nothing is found by reflection; a class only a file names must be in the build (`--macro include("pack")`). The pass runs where the game's time does: each `Scene` owns one (`Scene.behaviors`), ticked by the stack before the scene's `update` and cleared as it exits; an app without scenes makes and updates one as it does a `Tweens`. A phase says when in a frame a behavior runs: `@:phase(Late)` on the class, one of `Phase`'s `Input` (reading devices, deciding intent), `Simulate` (moving the world; the default), `Resolve` (settling what Simulate produced: checkpoints, hits, triggers) and `Late` (following the settled world: cameras, HUD anchors, effects), run in that order. Behaviors don't signal each other: a capability is an interface a behavior implements (`IDamageModifier`), and a system that decides across entities is a resolver behavior, found with `pass.find`, which the others report to, gathering the participants with `pass.allUnder(node, IDamageModifier)` (gear on the entity's child nodes) and applying them in a fixed order of its own.
- **The program's services are static classes:** `Host`, `Window`, `Input`, `Graphics`, `Audio`, `Assets`, `Storage`, `Fetch`, `Textures`, `Fonts`, `Models`, `Environments`, `Time` (the program's clock and frame timings), `Screen` (the presentation), `Screenshots`, `TestHarness`, each one instance for the one program (a singleton), forwarding to the instance the runner gave it (`Window.instance`, an adapter; `Models.instance`, a `ModelCache`: the class a static stands over takes a `Cache` or `Service` suffix, `TextureCache`, `FetchService`); the forwarders are generated from the service's interface by a build macro, so nothing is written twice, and the interface stays the adapters' and the tests' side. A thing a game makes for itself (a `Clock`, a `Ticker`, a `Stage3D`, a `Tweens`) is an ordinary class with instances.
- **A static survives a hot reload only if it says `@:hot`, on both targets.** In the project's own code (its class paths, `src/` and `examples/`, less the main class; the standard library and haxelibs keep theirs), a plain static starts over from its first value at every reload (hotreload-hx b9aa033), so an edited initializer takes effect; a static holding state that must outlive the swap (a service's instance, an id counter, a cache the reload's hook rebuilds from) carries `@:hot`, with a comment saying why. A closure or a bound method kept in a static runs the code it came from (DECISIONS 123).
- **One concept, one name across types:** a sprite's part of its texture is its region everywhere (`regionX`, `regionWidth`), not a region here and a source there.
- **Adapter classes are `<Api><Contract>Adapter`**, words the API's name ends with and the contract's starts with written once (`WebAudioAdapter`, not `WebAudioAudioAdapter`); ARCHITECTURE.md has the directories, and `tools/check_adapters.py` checks both.
- **2D and 3D are named apart:** `Camera2D`, `Text2D`, `Batch2D`, so their 3D counterparts can sit beside them.
- **Capitals:** `2D` and `3D` keep a capital D. Acronyms are written as words, as in Haxe's standard library (`Json`, `Xml`, `Http`): `id`, `Url`, `IndexedDb`. Product names keep their own spelling (`WebGL2`, `Sokol`).

## Units

One unit per kind of value across the API, so nothing has to be converted at a call:

- **Angles are radians.** A positive angle turns from +x toward +y: clockwise on screen in 2D, where y grows downward. 3D is right-handed with +y up.
- **Time is seconds**, as a `Float`. A value in another unit says so in its name (`WorkQueue.budgetMs`) or, where the name can't, in its doc comment (`Time.frameCpu` and `frameInterval` are milliseconds).
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
