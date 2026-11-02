# Roadmap

- **helix-render, being built** (directory `render/`, packages `helix.render` and `helix.render.effects`; DECISIONS 35), from its
  agreed API (revision 9), in stages, each member of a later stage throwing and naming it: 1 (done), the renderer and its recorded
  frame, textures and targets, `Batch2D`, `DrawList2D`, fonts and text, and `Batch3D`'s unlit work (views, the batch draws, unlit
  meshes and models, instancing, skinning, `DrawList3D`, the compile macros); next, 2, lit materials and lights (with the draft's
  model example), and a mesh drawn as points larger than a pixel, which stage 1 refuses;
  3, shadows; 4, environment maps and the background; 5, post-processing (with the draft's scene example); 6, fog; 7, morph targets.
  Asked below it: helix-services' `Font2D.kind` and kerning pairs (until then every font draws as coverage, unkerned) and a `Font2D`
  from glyph data; helix-formats' `GltfMaterial` alpha mode, cutoff, sides, samplers, texture transforms and extensions, and morph
  targets; helix-geometry's second texture coordinates, morph targets and mesh groups; helix-math's Euler orders, an object's `lookAt`
  and `Bounds3D` through a matrix. Then helix-ray rebuilt on it, and helix-scene (`scene/`, `helix.scene`) on it (2D and 3D nodes, transforms, hierarchy,
  the walk that culls, lights and sorts; HeliX's nodes and stage carried over), drafted as an API and tried by fresh agents first;
  the engines over helix-scene, which first to be chosen: HeliX's engine (its game-level API, its games and docs) and a three.js-style one.
- **helix-ray, on trial (DECISIONS 16, 19, 20, 21):** raylib's API over the services; to decide whether it merges. Next: a managed layer beside it (assets, instances,
  placeholders, as librl has them), designed as an API first. Then a trial of how agents take to
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
  For review, from helix-render's stage 1: sokol_gfx's GL adapter refuses a vertex layout whose fed attributes leave a gap of slots
  (sokol's "layout.attrs is not continuous"; a release build draws nothing past the gap), where the contract has an unfed attribute
  read its constant; helix-render feeds every attribute it names from records of its own meanwhile (`RenderConstants`, to be removed
  when the adapter fills the gaps itself). Pros: the contract holds on every backend, and a layer stops carrying the records. Cons: the
  adapter binds a constants buffer of its own, as its SDL_GPU sibling does.
  The platform's checks of a pipeline's vertex layout (`PipelineLayout.check`, every backend, about 0.3 KB gzip) to be trimmed to what
  a backend would otherwise get wrong silently, once the platform's API is settled.
- **Services features an engine needs and helix-ray now reaches the platform for:** the mouse cursor (shape, visibility, lock) on
  `Mouse`, gamepad vibration and mappings on `Gamepads`, and a clipboard service.
- **The layer above the services:** constructs the platform and the services for a target, runs the frame in order and ends with the
  saves written, so a program knows none of that; its spec is the `Main.hx` the services trial's three agents each wrote the same way.
  Whether it wears a known API or an engine's is GOALS' open path.
- **Libraries apart from engines:** helix the umbrella; the libraries (math, log, formats, platform, services, later UI) know no
  consumer, and the engines over them (helix-ray, to be renamed, perhaps helix-raylib; an OpenFL mirror; what HeliX's engine
  becomes, its name to be chosen, as raylib names raylib's) may own the loop and keep statics. First one repository, `libs/` and
  `engines/`, `check_layers` refusing a library that reaches an engine and the engines' checks run on every library change, as no
  backward compatibility means every caller changes in the same commit; separate repositories, each engine pinning a library
  version, once the platform has held through a second consumer and is versioned.
- **SDL3 with the platform:** a native build needs only Haxe and hxcpp (goal 6), so the platform haxelib ships the pinned SDL3 per
  system, or its build fetches it, in place of naming a library with `HELIX_SDL3_LIBRARY`.
- **Gestures:** taps, double taps, drags and flicks (the mouse and fingers alike), and two fingers' pan, pinch and twist, over `Touch`
  and `Mouse`, as HeliX's `PointerGestures` and touch gesture had them.
- **On-screen controls, not as a service, where to be decided:** touch regions and floating touch sticks (one, two halves, regions;
  dead zone, takeover, blocked by buttons) read by `Actions` through `IActionDevice`, placed in the game's units and drawn
  (DECISIONS 13).
