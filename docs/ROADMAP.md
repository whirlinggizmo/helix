# Roadmap

- **helix-render, being built** (directory `libs/render/`, packages `helix.render` and `helix.render.effects`; DECISIONS 35), from its
  agreed API (revision 9), in stages, each member of a later stage throwing and naming it: 1 (done), the renderer and its recorded
  frame, textures and targets, `Batch2D`, `DrawList2D`, fonts and text, and `Batch3D`'s unlit work (views, the batch draws, unlit
  meshes and models, instancing, skinning, `DrawList3D`, the compile macros); next, 2, lit materials and lights (with the draft's
  model example), and a mesh drawn as points larger than a pixel, which stage 1 refuses;
  3, shadows; 4, environment maps and the background; 5, post-processing (with the draft's scene example); 6, fog; 7, morph targets.
  Asked below it: helix-formats' `GltfMaterial` alpha mode, cutoff, sides, samplers, texture transforms and extensions, and morph
  targets; helix-geometry's second texture coordinates, morph targets and mesh groups; helix-math's Euler orders, an object's `lookAt`
  and `Bounds3D` through a matrix. Then helix-ray rebuilt on it (immediate, as raylib is, on helix-render directly).
- **helix-scene and Gyre, HeliX's engine (`gyre/`, `helix.gyre`): HeliX on top of the libraries, not replaced by them.** helix-scene (`scene/`, `helix.scene`) is
  HeliX's scene code (its stage, 2D and 3D nodes, transforms, hierarchy, the walk that culls, gathers lights and sorts, picking) moved
  onto helix-render and made engine-neutral, the link rule applied (a 2D game carries no 3D): a port of HeliX's code, not a new
  design. Gyre is HeliX's game-level API (app, loader, UI, transitions, animator, autopilot) on helix-scene, helix-render and
  the services, so its users keep the API they know; a three.js-style engine later on the same helix-scene. The test: one of
  HeliX's games ported, its effort and its size beside its HeliX build.
- **helix-ray (DECISIONS 16, 19, 20, 21):** raylib's API over the services, merged to `main`. Next: rebuilt on helix-render; then reloading and placeholders under raylib's own names (the assets,
  resources and objects below). Then a trial of how agents take to
  the `...Async` loads (one task a blended animation: whether agents reach for 6.2's `UpdateModelAnimationEx`, DECISIONS 24), and only after it, faking sync loads in a page: compared as a spike, a worker-hosted page whose loads block
  (Atomics.wait, which a worker may; cross-origin isolation, OffscreenCanvas, input and audio relayed; raylib's loop run as written)
  against a whole-program rewrite into callbacks. A `Future` of our own over the callbacks, cross-target, may serve the managed layer,
  as Haxe has none (`js.lib.Promise` is the browser's alone). Every raylib 5.5 function is in; what refuses to compile
  does so on purpose (blocking loads, rlgl's GL handles, what a page can't do), naming itself. Platform changes it would like,
  for review: a sound's length and the position it plays at in services' `Audio` (raylib's `GetMusicTimeLength`,
  `GetMusicTimePlayed` and `SeekMusicStream` refuse until then), and a page's cache in OPFS readable at once from the main thread (a worker holding OPFS's sync handles, the page
  spinning on a SharedArrayBuffer for the reply, as emscripten does), which needs the page cross-origin isolated (COOP and COEP), so
  only ever an option a program chooses, never the default.
- **Platform proposals queued, for review:** depth sampled after a pass, depth bias, stencil, and the depth tests `Always`, `Less`,
  `Equal` and `GreaterEqual` (helix-render's revision 9). A render target's own sample count, apart from its depth, is being built. Deferred from the vertex formats
  (DECISIONS 33): bone IDs and three.js' skinIndex fed as normalized bytes or shorts and scaled back by the compiler, rounded, as a
  `ShaderCompileOptions` entry; until then they are floats, or a layer owning its shader scales them itself.
  The platform's checks of a pipeline's vertex layout (`PipelineLayout.check`, every backend, about 0.3 KB gzip) to be trimmed to what
  a backend would otherwise get wrong silently, once the platform's API is settled.
- **Assets, resources and objects, as the earlier C frameworks layered them (AGENTS.md's prior art: their resource/object model),
  after helix-render's stages, as plumbing a game never calls.** Each engine keeps its own names: helix-ray's `texture.id` becomes a
  stable handle its table maps to the current resource; helix-render's `Texture2D`, `GpuModel3D` and `GpuFont2D` are the stable
  identities, their platform handles internal; the HeliX engine's and a three.js layer's objects are their own nodes and meshes.
  Underneath, an internal registry in the services for layer authors: one resource per path (or generator's parameters), reference
  counted, replaced in place while the program runs (the changed file loaded beside the old, swapped at a frame boundary, a failure
  keeping the old, as `Shaders.watch` replaces a shader), a placeholder while it first loads. Linked only by a program that loads or
  watches that kind; a game reads nothing new.
- **Services features an engine needs and helix-ray now reaches the platform for:** the mouse cursor (shape, visibility, lock) on
  `Mouse`, gamepad vibration and mappings on `Gamepads`, and a clipboard service.
- **The layer above the services:** constructs the platform and the services for a target, runs the frame in order and ends with the
  saves written, so a program knows none of that; its spec is the `Main.hx` the services trial's three agents each wrote the same way.
  Whether it wears a known API or an engine's is GOALS' open path.
- **Libraries apart from engines, next after helix-ray merges to `main` and before Gyre starts:** helix the umbrella; the
  libraries (math, log, geometry, formats, platform, services, render, later scene and UI) know no consumer, and the engines over them
  (helix-raylib, today's helix-ray; Gyre, what HeliX's engine becomes; a three.js-style one) may own the loop and keep statics. One
  repository, `libs/` and `engines/` (moved with `git mv`, every tool, hxml, haxelib.json and doc naming a path changed with them),
  `check_layers` refusing a library that reaches an engine and the engines' checks run on every library change, as no backward
  compatibility means every caller changes in the same commit. helix-ray is renamed helix-raylib in the same move: its directory, its
  haxelib name, its package (`helix.raylib`) and its defines (`helix-raylib-files` and the rest). Separate repositories, each engine
  pinning a library version, once the platform has held through a second consumer and is versioned.
- **SDL3 with the platform:** a native build needs only Haxe and hxcpp (goal 6), so the platform haxelib ships the pinned SDL3 per
  system, or its build fetches it, in place of naming a library with `HELIX_SDL3_LIBRARY`.
- **Gestures:** taps, double taps, drags and flicks (the mouse and fingers alike), and two fingers' pan, pinch and twist, over `Touch`
  and `Mouse`, as HeliX's `PointerGestures` and touch gesture had them.
- **On-screen controls, not as a service, where to be decided:** touch regions and floating touch sticks (one, two halves, regions;
  dead zone, takeover, blocked by buttons) read by `Actions` through `IActionDevice`, placed in the game's units and drawn
  (DECISIONS 13).
- **From a jam game's friction log (F numbers), for the layers that own them:**
  - helix-scene: `find` by name and kind, `addChildAt`, `getChildIndex`, `removeChildAt`, `contains` (F1, F2, F4); text pivot or
    vertical align (F20); a sprite keeping its sheet and index across a reload (F56); a matrix transform, so skew (F57); a pointer
    that never hovers from a finger (F63); the stage's default font (F66); 3D picking through a function registered when a 3D layer
    is added, not a hardwired 3D renderer (F74); reparenting that keeps the world transform (F44).
  - helix-render's size ladder: a 2D-only rung (`Batch2D` and text, no `Batch3D` or lighting) and a rung with UI and a pointer (F74).
  - HeliX's engine: an event queue (F3); splash, loading screen and transitions run as halves, held until a condition (F7-F11, F41,
    F42); `Collect2D`/`Collect3D` taking a region or factory, a parent and `cancel` (F37, F70, F71); a loader over the services'
    loads, fonts too (F39, F75); a camera that follows in 3D (F44).
  - A UI library: input from the events, not a kept `Input` (F12); keys held at a reset ignored alone (F13, F14); aligned slider
    tracks (F15); wrapping labels (F58); list rows beyond text (F59); a modal dialog (F60); drawn panel borders (F68); a frame that
    keeps its layout (F69).
  - On-screen controls: a touch stick (F48, DECISIONS 13).
  - Physics: bodies with circle contacts (F18) and spheres against meshes (F44).
  - Tooling: hot reload and the runner's statics and setup (F26, F27, F29, F45); a pinned release and the starter's `init` (F30, F36);
    an autopilot feeding the events, fingers too, its failures not timeouts, a `wait` with `atMost` (F31-F33, F50, F72); dev and
    release output kept apart (F34); one ignore list for copied assets and manifests (F61); a minified release with no Node in a
    user's path (F73, GOALS 6).
  - helix-geometry: polygon triangulation returning indices, for textured polygons and extruded outlines (F23, F24); circle-vs-segment,
    rectangle and polygon contacts with normal and depth (F18).
