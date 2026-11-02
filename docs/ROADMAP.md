# Roadmap

- **Drawing and a scene, drafted as APIs:** helix-draw (2D and 3D drawing over the platform: batches, draw lists, lit
  materials, lights, shadows, environment maps, post-processing, points; HeliX's renderers carried over), on helix-services' shaders
  package (DECISIONS 31, helix-ray already on it), then a scene
  library on helix-draw (2D and 3D nodes, transforms, hierarchy, the walk that culls, lights and sorts; HeliX's nodes and stage
  carried over). Each judged by what a raylib layer and a three.js layer would need from below; helix-ray to be rebuilt on
  helix-draw. Drafts agreed with the user and tried by fresh agents before any is written.
- **helix-ray, on trial (DECISIONS 16, 19, 20, 21):** raylib's API over the services; to decide whether it merges. Next: a managed layer beside it (assets, instances,
  placeholders, as librl has them), designed as an API first. Then a trial of how agents take to
  the `...Async` loads (one task a blended animation: whether agents reach for 6.2's `UpdateModelAnimationEx`, DECISIONS 24), and only after it, faking sync loads in a page: compared as a spike, a worker-hosted page whose loads block
  (Atomics.wait, which a worker may; cross-origin isolation, OffscreenCanvas, input and audio relayed; raylib's loop run as written)
  against a whole-program rewrite into callbacks. A `Future` of our own over the callbacks, cross-target, may serve the managed layer,
  as Haxe has none (`js.lib.Promise` is the browser's alone). Not there yet: skinned models and animations, fonts from files, images
  on the CPU, `UpdateMeshBuffer`; each refuses to compile, naming itself. Platform changes it would like,
  for review: a sound's length and the position it plays at in services' `Audio` (raylib's `GetMusicTimeLength`,
  `GetMusicTimePlayed` and `SeekMusicStream` refuse until then), and a page's cache in OPFS readable at once from the main thread (a worker holding OPFS's sync handles, the page
  spinning on a SharedArrayBuffer for the reply, as emscripten does), which needs the page cross-origin isolated (COOP and COEP), so
  only ever an option a program chooses, never the default.
- **Platform proposals queued, for review:** depth sampled after a pass, depth bias, and stencil. Deferred from the vertex formats
  (DECISIONS 33): bone IDs and three.js' skinIndex fed as normalized bytes or shorts and scaled back by the compiler, rounded, as a
  `ShaderCompileOptions` entry; until then they are floats, or a layer owning its shader scales them itself.
  The platform's checks of a pipeline's vertex layout (`PipelineLayout.check`, every backend, about 0.3 KB gzip) to be trimmed to what
  a backend would otherwise get wrong silently, once the platform's API is settled.
- **A drawing library,** between the services and a mirror, when a second mirror needs what helix-ray draws with (its frame recording,
  meshes, default font; its shader programs are the services' now); and glTF's reading as a services package beside `images`.
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
