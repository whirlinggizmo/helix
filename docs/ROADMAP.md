# Roadmap

- **helix-ray, on trial (DECISIONS 16, 19):** raylib's API over the services; to decide whether it merges. Next: raylib's music
  streaming (over `Audio.stream`), its load and save hooks with `LoadFileData`, then a managed layer beside it (assets, instances,
  placeholders, as librl has them), designed as an API first. To weigh: a page awaiting raylib's plain loads, the build macro rewriting a
  load in `main`'s setup into its `...Async` and the code after it into the callback (as `tink_await` does), so a raylib program needs
  no preload there (loads inside the frame loop or a helper would need the loop made resumable, a far larger rewrite); and a `Future`
  of our own over the callbacks, cross-target, for the managed layer, as Haxe has none (`js.lib.Promise` is the browser's alone). Not there yet: skinned models and animations, fonts from files, images
  on the CPU, `SetTextureFilter`, `UpdateMeshBuffer`, `DrawMeshInstanced`; each refuses to compile, naming itself. Platform changes it would like,
  for review: a render-target pass that keeps what the target holds (raylib's render textures keep it; ours start cleared each
  frame), a uniform block both shader stages share (worked around: a block a stage), `ShaderCompiler.compileText` as a supported
  entry point, and a page's cache in OPFS readable at once from the main thread (a worker holding OPFS's sync handles, the page
  spinning on a SharedArrayBuffer for the reply, as emscripten does), which needs the page cross-origin isolated (COOP and COEP), so
  only ever an option a program chooses, never the default.
- **A drawing library,** between the services and a mirror, when a second mirror needs what helix-ray draws with (its frame recording,
  shader programs, meshes, default font); and glTF's reading as a services package beside `images`.
- **The layer above the services:** constructs the platform and the services for a target, runs the frame in order and ends with the
  saves written, so a program knows none of that; its spec is the `Main.hx` the services trial's three agents each wrote the same way.
  Whether it wears a known API or an engine's is GOALS' open path.
- **SDL3 with the platform:** a native build needs only Haxe and hxcpp (goal 6), so the platform haxelib ships the pinned SDL3 per
  system, or its build fetches it, in place of naming a library with `HELIX_SDL3_LIBRARY`.
- **Gestures:** taps, double taps, drags and flicks (the mouse and fingers alike), and two fingers' pan, pinch and twist, over `Touch`
  and `Mouse`, as HeliX's `PointerGestures` and touch gesture had them.
- **On-screen controls, not as a service, where to be decided:** touch regions and floating touch sticks (one, two halves, regions;
  dead zone, takeover, blocked by buttons) read by `Actions` through `IActionDevice`, placed in the game's units and drawn
  (DECISIONS 13).
