# Plan: the API in Haxe's own terms

The target is written in [CONVENTIONS.md](../CONVENTIONS.md) (Names) and [DECISIONS.md](../DECISIONS.md) 130. This plan is the work, in
order, for an agent executing it. Read those two first, then [ARCHITECTURE.md](../ARCHITECTURE.md) and [INTERFACE.md](../INTERFACE.md).
When the plan and the conventions disagree, the conventions win; when something here can't be done as written, stop and say so rather
than inventing a way around it. Delete this file in the last phase; HISTORY records what was done.

## Ground rules for the whole job

- **One phase, one commit,** locally, no push. Each commit's message says what changed and what was checked, as the log's other commits do.
  Before a commit: `python3 tools/format.py`, `python3 tools/check_types.py --no-output`, `python3 tools/check_docs.py`,
  `python3 tools/gen_apidoc.py`, `python3 helix.py test --native`. Nothing is committed with one of them failing.
- **No backward compatibility.** When a name changes, every caller changes in the same commit: `src/`, `examples/`, `tests/`, `tools/`, the
  docs. No alias, no wrapper left behind, no `@:deprecated`. `grep -rn` for the old name must find nothing but DECISIONS and HISTORY.
- **Doc comments on everything public,** moved with the member, rewritten where the member changed. `check_docs.py` must say
  `0 undocumented`.
- **The formatter lays code out.** Never hand-pack a class.
- **Stop and ask** when: a setter that can refuse today has no sensible clamp (see phase 3); an interface can't be forwarded by the macro;
  a test's expectation is wrong rather than the code; an example can't be rewritten without a feature the framework lacks; or a check
  fails in a way the phase didn't change.
- **Shared builds take the lock:** `flock /tmp/claude-1000/helix-build.lock <command>`. After editing a `.c` or `.h` under
  `src/helix/adapters`, `rm -rf build/hxcpp-cache` first.
- **Native windows go on the private display** (`tools/private_display.py`), never the desktop; `HELIX_AUDIO=0`.
- **Autopilots are the net:** `python3 tools/example.py asteroids autopilot --browser <chrome>`, the same for `blocks` and `scenes`, after
  phases 1, 2, 4 and 6. Chrome is `/home/rknopf/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome`.

## Phase 1: kinds as classes, 3D

**Goal:** `src/helix/render3d/Node.hx` becomes `Node3D.hx`, a transform with children and nothing else (Godot's name, beside `Node2D`); each kind is a class holding only its data.

New classes in `src/helix/render3d/` (each with a doc comment saying what it is):

```haxe
class Node3D          // transform (position, rotation, scale), parent, children, name, enabled, visible, pickable, local/world matrices,
                      // add, remove, find, computeWorld, lookAt, setPosition, setRotation, setScale, setMatrix. A bare Node3D is a group.
class Model extends Node3D       // parts:Array<Part>; mesh and material read and set parts[0]'s; tint; castsShadows, receivesShadows;
                               // skin, joints, bindSkeleton; new(?mesh, ?material)
class Part                     // mesh:Mesh, material:Material (a Material.white default when null)
class Light extends Node3D       // color, intensity, shadow settings (shadowCasting, shadowDistance, shadowMapSize, shadowStrength,
                               // shadowColor, shadowBias). Abstract: a stage never holds a bare Light.
class DirectionalLight extends Light   // direction: the node's forward
class PointLight extends Light         // range
class SpotLight extends Light          // range, cone (inner, outer)
class Camera3D extends Node3D    // everything Camera3D has now; its view matrix from its world transform (see below)
class Sprite3D extends Node3D    // texture, region, size, pivot, facing, alpha mode, tint
class Text3D extends Node3D      // text, size, color, font
class Particles3D extends Node3D // emitter
```

What goes: `NodeKind`, `Node.getKind`, every `Node.xxx(...)` static constructor, `lightOf`, `cameraOf`, `emitterOf`, the sprite and text
fields on `Node3D`, `Node.setMaterial`/`getMesh`/`getMaterial` (now `Model`'s).

**Camera3D as a node.** Today it holds an eye, a target and an up vector. After: `setView(eye..., target..., up...)` sets the node's position
and rotation (a lookAt), and the view matrix is the inverse of the world matrix, so a camera under a moving node moves with it. `getEyeX` and
the like read the world position. `computeRay`, `getViewProjection`, the shadow cameras in `Stage3D` and `Camera3D.getNode` (gone: the camera
is the node) follow. Check with `examples/model` (the ride-along) and `tests/unit/PickTests.hx`.

**Model parts.** `ModelFile.instantiate` makes one `Model` per glTF node with a mesh, its primitives as `parts`, named as the file names the
node; a group only where the file has a node holding other nodes; a light node a `SpotLight`/`PointLight`/`DirectionalLight` by the file's
type. `Stage3D` keeps its records per part (a part is what it instanced per node before). `Node.collectModels`, `findAttachment`,
`bindSkeleton` and `Animator` work on `Model`.

**Type dispatch.** Where `Stage3D`, `Sprites3D`, picking and `ModelFile` switched on `getKind`, they use `Std.isOfType` / `Std.downcast`
once per node per walk, or keep typed lists (models, lights, sprites, texts, emitters) that `add`/`remove` maintain, which is faster and
what the stage already does for lights. Prefer the typed lists.

**Callers to change** (counts from `grep -rc 'Node3D\.\(group\|model\|light\|camera\|sprite\|text3D\|emitter\)('`): `tests/unit/Render3DTests.hx`
(27), `PickTests.hx` (12), `examples/text3d` (7), `sprite3d` (6), `shaders` (6), `pick` (6), `ModelFile.hx` (5), `scene3d` (5), `lights` (5),
`OutfitTests.hx` (4), `shadows` (4), `postprocess` (4), `materials` (4), `instancing` (4), `Render2DTests.hx` (3), `AnimationTests.hx` (3),
`tests/bench/StageBench.hx` (3), `render-target` (3), `model` (3), `meshes` (3), `dressing-room` (3), `animation` (2), `Stage3D.hx` (1),
`particles` (1), `environment` (1). `getKind` users: `Light.hx`, `Node.hx`, `ModelFile.hx`, `Sprites3D.hx`, `Material.hx`, `Stage3D.hx`,
`examples/pick`, `Render3DTests.hx`, `AnimationTests.hx` (the others' `getKind` are other enums: leave them).

**Checks:** the five commands; `tools/bench_stage.py` still runs; autopilots; and in the dev loop (`python3 tools/example.py <name> dev`)
`model`, `animation`, `dressing-room`, `shadows`, `pick`, `lights`, `sprite3d`, `text3d`, `particles`, `instancing` each show what they did.
Compare against the live site's thumbnails (https://whirlinggizmo.github.io/helix/) when unsure what "did" looks like.

## Phase 2: services as static classes

**Goal:** `Services` is gone. Each service is a static class forwarding to the instance the runner gives it.

The macro, `src/helix/macro/Facade.hx` (a build macro; `#if macro` guarded; read Haxe's `haxe.macro.Context` and `haxe.macro.Type` docs):

```haxe
// class Window {} becomes, from IWindow's fields:
@:hot static var instance:IWindow;                       // bound by the runner, null outside init..cleanup
public static function bind(value:IWindow):Void          // the runner's; clears with null
public static function setTitle(value:String):Void return instance.setTitle(value);   // one per method, doc comment copied
public static var title(get, set):String;               // one per property, after phase 3 (the macro handles both forms)
```

Facades and what they forward to:

| Static | Over | Today |
| --- | --- | --- |
| `Host` | `IHost` | `Services.quit`, `canQuit`, `isRunning`, `isBusy`, `getOption*`, `config` |
| `Window` | `IWindow` | `Services.window` |
| `Input` | `IInput` | `Services.input` |
| `Graphics` | `IGraphics` | `Services.graphics` |
| `Audio` | `AudioResources` (a class; the macro takes a class's public fields too) | `Services.audioResources`; `IAudio` stays the adapter's, not static |
| `Assets` | `IAssets` | `Services.assets` |
| `Fetch`, `Storage` | the classes | `Services.fetch`, `Services.storage` |
| `Textures`, `Models`, `Environments` | the classes (renamed `TextureCache`, `ModelCache`, `EnvironmentCache` so the static takes the name) | `Services.textures`, `environments`; `new Models(...)` in ten examples |
| `Time` | the runner's frame clock and `Services.clock` | `getTime`, `getFrameElapsed`, `getFrameCpu`, `getFrameInterval`, `Services.clock` (as `Time.clock`, the program's `Clock`) |
| `Presentation` | the class (renamed `Presenter`? no: keep `Presentation` the class and make the static `Screen`) | `Services.presentation` |
| `Screenshots`, `TestHarness` | `helix.graphics.Screenshots`, `ITestHarness` | `Services.screenshots`, `harness` |

Decide `Presentation`'s static name before starting the phase: `Screen` is proposed (its visible area, fit mode, portrait), since
`Presentation` the class has instances in tests. Stop and ask if it reads wrong.

The runner (`src/helix/host/Runner.hx`) binds every facade at init and clears at cleanup, exactly where it fills and clears `Services` now.
`Services.hx` is deleted. Call sites by count: `Services.window` 179, `graphics` 138, `input` 55, `presentation` 49, `canQuit` 46, `quit` 40,
`textures` 39, `clock` 39, `getFrameCpu` 31, `assets` 29, `audioResources` 16, `getOption` 14, `getTime` 12, `environments` 10,
`screenshots` 8, `harness` 6, `isBusy` 5, `config` 3, `storage` 2, `runner` 2, `getOptionFloat` 2, `getOptionBool` 2, `getFrameElapsed` 2,
`fetch` 2, `audio` 2, `isRunning` 1. A `sed` over `examples/`, `src/` and `tests/` does most of it; read the result.

The unit tests keep constructing the classes with fakes (`new ModelCache(fakeAssets, textures)`), never the statics.

**Checks:** the five commands; the hot-reload smoke test (`python3 tools/example.py scenes dev`, edit `examples/scenes/App.hx`, see the swap
report "statics kept" include the facades' instances, no errors); autopilots.

## Phase 3: properties

**Goal:** every `getX`/`setX`/`isX` pair becomes a property per CONVENTIONS; `isX(argument)` methods stay.

Do it package by package, the formatter after each: `helix.render3d`, `render2d`, `graphics`, `host`, `input`, `audio`, `assets`, `time`,
`tween`, `math`, `collision`, `scene`, `ui`, `particles`, `debug`, `app`; then the facades regenerate themselves from the interfaces. About
910 accessor methods in `src/helix`.

Rules for each pair:

- `getX()` + `setX(v):Void` → `public var x(get, set):T` with the same bodies as `get_x`/`set_x`; the setter returns `value`.
- `getX()` + `setX(v):Bool` that **clamps** today → the property clamps; the doc comment says the range.
- `getX()` + `setX(v):Bool` that **refuses** today → decide: if the refusal is "out of range", clamp and say so; if it is "no meaning here"
  (a cone on a directional light), the typed classes of phase 1 removed the case; if it is "can't now" (a texture size past the GPU's
  limit, a sample count the driver lacks), it stays a method and is listed in the commit message. When unsure, stop and ask with the list.
- `getX()` with no setter → `public var x(get, never):T` or `(default, null)`.
- `isX()` + `setX(bool)` → an adjective property: `visible`, `enabled`, `paused`, `fullscreen`, `connected`, `repeating`, `done`.
  `isX(argument)` stays a method.
- `setX(a, b, c)` of several values stays a method; its per-value getters become properties (`x`, `y`, `z`).
- `getXCount()` → `xCount`; `getMaxX()` → `maxX`.
- `computeX`, `makeX`, `applyX`, `requestX`, `canX` stay methods.
- Every property keeps the doc comment of the pair, merged into one.

Hot reload: a property's accessors are methods and re-point like any other. Nothing special.

**Checks:** the five commands; `python3 tools/gen_apidoc.py` shows properties in the reference (check `docs/api/render3d.md` reads well);
autopilots.

## Phase 4: kinds as classes, 2D, and the text rename

**Goal:** `Node2D` is a transform with children; `Sprite2D`, `Shape2D`, `Text2D`, `Particles2D` are its kinds; immediate text drawing
moves to `Batch2D` and measuring to `Font2D`.

- Today's `helix.render2d.Text2D` (static `draw`, `drawWrapped`, `measure`) → `Batch2D.drawText(...)`, `Batch2D.drawTextWrapped(...)`,
  `Font2D.measure(...)`; 47 files use `Text2D.`.
- `Node2D.rectangle/circle/line/polygon` → `Shape2D.rectangle(...)` etc. (static constructors on `Shape2D`, which holds the shape's
  geometry and color); `Node2D.sprite` → `new Sprite2D(texture)`; `Node2D.text` → `new Text2D(value, size, color, align, ?font)`;
  `Node2D.emitter` → `new Particles2D(emitter)`; `Node2D.group()` → `new Node2D()`.
- The UI (`src/helix/ui/*.hx`: `Slider`, `ListView`, `Toggle`, `Tile`, `TextField`, `Ui`, `ProgressBar`, `Panel`, `Button`, `Widget`,
  `Label`, `Box`) builds on those; `Stage2D` dispatches by type as `Stage3D` does after phase 1.
- Callers: `tests/unit/Render2DTests.hx` (26), `examples/stage2d` (12), `motion` (6), `UiTests.hx` (4), `scene3d` (2), `PickTests.hx`,
  `tilemap`, `sprite2d`, `particles`, and every example's HUD text.

**Checks:** the five commands; `ui`, `stage2d`, `sprite2d`, `tilemap`, `motion`, `font` in the dev loop; the `ui` example's text field
still types; autopilots (Asteroids' menus are `helix.ui`).

## Phase 5: completions take lambdas

**Goal:** `load(path, loaded, ?failed)` everywhere a result enum is switched on today.

- `Models.load(path, loaded:ModelFile->Void, ?failed:String->Void):IRequest`; the same shape for `Textures.load`, `Environments.load`,
  `Audio.loadClip`, `Audio.loadStream`, `Assets.load`/`ensure` where they take a result callback. A failure with no `failed` is logged
  (`trace` with the path; natively `Sys.println`). A cancel calls nothing.
- The result enums (`ModelLoadResult` and its siblings) go, with `Cancelled` arms everywhere.
- `helix.scene.Loader` wraps the new shape; its own API is unchanged.
- Every example's `switch result` becomes a lambda that calls a method by name (CONVENTIONS: never pass the method bare). Nothing
  more for native reloads: a load in flight across one lands in the old world, which the conventions accept.

**Checks:** the five commands; `tests/unit/AssetTests`, `SceneTests` and the others that fake a load; autopilots (`scenes` loads through
the `Loader`).

## Phase 6: the model example, the shared orbit, the docs

- `examples/shared/src/Orbit.hx`: the examples' circling camera (an angle advanced by `update(dt)`, a radius, a height, a target;
  `apply(camera)` sets the camera's view). The examples that circle by hand (`model`, `shadows`, `lights`, `materials`, `meshes`,
  `environment`, `instancing`, `animation`: check each) use it.
- `examples/model/App.hx` rewritten per DECISIONS 130's motivation: load, a `place(file)` that says in its comment what tree the file made,
  wheels and headlights found by name, D to drive, the ride-along camera as a `Camera3D` under the car, the orbit from `Orbit`. Names:
  `orbitCamera`, `rideCamera`, `riding`, `driving`, `driveAngle`, `wheelSpin`, `headlights`, `caption`. Nothing about the orbit toggle.
- Docs: `INTERFACE.md` and `ARCHITECTURE.md` read through and brought to the new names; `README.md`'s snippets; `docs/api` regenerated;
  HISTORY gets a milestone entry (the API rework, what was checked, the numbers: files, call sites) and ROADMAP loses what it covered;
  this file deleted.

**Final checks:** the five commands; every example built for web (`python3 tools/example.py all build web`) and the site made
(`python3 tools/pages.py` if it builds locally) with its thumbnails looked at; `python3 tools/example.py all build native-sdl3` under the
lock; all three autopilots on both targets; the hot-reload smoke test. Then report: what was done, what was checked and on which target,
what was left, and the commit list. The push is the user's call.
