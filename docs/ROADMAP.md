# Roadmap

The order (DECISIONS 40, 53, 60): raygui on helix-raylib (done, DECISIONS 41), then helix-render's stages 1 to 3 (done, and set aside,
DECISIONS 53), then a retained-mode engine tried on helix-raylib, Gyre's or a three.js-style one as the jam decides. helix-raylib itself
is raylib 5.5's API, the calls its refusals name, and the extras a program opts into (DECISIONS 60, 61). Whatever comes next keeps helix-raylib's size and
speed where docs/benchmarks.md records them.

- **helix-render, set aside (DECISIONS 53)** (directory `libs/render/`, packages `helix.render` and `helix.render.effects`; DECISIONS
  35): built from its agreed API (revision 9) through stage 3 (the renderer and its recorded frame, textures and targets, `Batch2D`,
  `DrawList2D`, fonts and text, `Batch3D` unlit and lit, lights in three.js's units, shadows), and no engine draws on it: helix-raylib's
  rebuild on it failed its size and speed gates (DECISIONS 53), and nothing else links it. It stays on main with its checks running,
  and its stages 4 to 7 (environment maps and the background, post-processing, fog, morph targets) wait for an engine that needs it,
  pulled out of that engine rather than built ahead of it. What was asked of the libraries below it is still wanted on its own:
  helix-formats' `GltfMaterial` alpha mode, cutoff, sides, samplers, texture transforms and extensions (`KHR_materials_unlit` done),
  and morph targets; helix-geometry's second texture coordinates, morph targets and mesh groups; helix-math's Euler orders, an
  object's `lookAt` and `Bounds3D` through a matrix. Effects (particles, model passes such as outlines, sprite and ground effects,
  screen effects) start from docs/EFFECTS.md, an inventory of the earlier projects' effects, each judged by other engines and by what
  the jam's entrants write.
- **The jam, before Gyre's shape is decided:** agents (Sonnet, docs allowed) build the same small 3D top-down survivors-like on
  helix-raylib and on helix-legacy, two or three each, with gear worn from the modular characters' parts (CC0, Quaternius). Measured: tokens,
  time, build failures, bugs, lines written (engine-substitute against game logic), frame time, size, startup, and a change made
  later by a fresh agent. It answers whether a framework's structure beats a familiar API agents were trained on. Run on Sonnet
  2026-11-06, three a side, a tie but for a quarter less reading on helix-raylib, with the play pass, timing at 200 and the change task
  left. It compared two of our own APIs: the harder control is helix-legacy's docs/TRIAL.md, the same game as a clean room on plain
  TypeScript, on Three.js, Pixi, OpenFL and Godot, to which helix-raylib is added, with this spec in place of the draft's game.
- **A retained-mode engine on helix-raylib (DECISIONS 53), then Gyre's shape.** The scene (a stage, 2D and 3D nodes, transforms,
  hierarchy, the walk that culls, gathers lights and sorts, picking), ported from helix-legacy's scene code rather than designed anew, issues
  raylib's calls each frame as three.js does under its graph: the speed and size measured for `DrawTexturePro` and `DrawMesh` are
  its, raylib's holders are its GPU handles, and what raylib lacks is the engine's own (DECISIONS 60). The sketch is done
  (docs/trials/2026-11-06-retained-sketch): a thin graph issuing raylib's calls, and nine gaps, unbuilt. Timed
  against the robots contender, the tree, cull and sort cost 6 to 8% at 400 robots with helix-math's matrices, 30 to 43% with raymath's
  allocating ones, so the graph keeps helix-math's. Gyre is helix-legacy's game-level API (app, loader, UI, transitions, animator, autopilot) on that
  scene and the services, so its users keep the API they know; the test is one of helix-legacy's games ported, its effort and its size
  beside its helix-legacy build. Whether Gyre keeps helix-legacy's API or folds its useful parts (the app's lifecycle, a retained UI, tweens,
  transitions, the autopilot) into a three.js-style engine on the same scene is the jam's question (DECISIONS 40). Whatever of the
  scene proves engine-neutral moves down into a library of its own once a second engine wants it, as `Images` did.
- **helix-raylib (DECISIONS 16, 19, 20, 21, 38, 72):** raylib's API over the services, merged to `main`. Every raylib 5.5 function
  is in. A page waits where the program calls `EndDrawing`, `WaitTime`, the file calls and the clipboard's, as a native build does
  (DECISIONS 72). What refuses to compile does so on purpose, naming itself: the asset loads and the screen reads, each naming its
  `...Async` call, rlgl's GL handles, and what a page can't do. Next: reloading and placeholders under raylib's own names (the assets,
  resources and objects below). The `...Async` calls no refusal names stay in `Raylib`, and may move to the extras. A `Future` of our
  own over the callbacks, cross-target, may serve the managed layer, as Haxe has none (`js.lib.Promise` is the browser's alone).
- **The sprite path's per-sprite cost in a page:** the bunnymark at 200k takes 4.54 ms over Vulkan (docs/benchmarks.md) against three.js's
  InstancedMesh at 3.84, both one instanced draw, so what is left is JavaScript a sprite, about 23 ns against 19: the record's twelve
  writes (about 2.5 ms for 200k, measured in isolation) and reading the bunnies' objects (about 2.1). The other texture draws (`DrawTextureRec`, `Pro`)
  still go through `Frame.quad` out of line, since inlining it everywhere cost 640 B gzip a rung. On the phone
  the robots are script-bound the same way (36 ms of 40 at 100 robots, raylib wasm 30 whole): the draw path's cost per call is the
  mobile item as well.
- **Type bits in the graphics handles, and the resource floor's shape:** the native adapters pack a slot and a generation into a handle
  (sokol's own ids, the SDL_GPU adapter's slot + 1 below a generation), per kind, so a buffer handle given where a texture is expected is
  caught only when its slot and generation miss a live texture; the earlier C frameworks' handles carried the kind too. Put the kind in the handle's
  high bits on every adapter (the WebGL2 one hands out plain increasing ints) and refuse a handle of another kind, with a graphics test
  for each mistake. The floor of 2047 of each kind alive (docs/PLATFORM.md) is the native tables' size; a mesh takes a buffer an
  attribute, so interleaving a mesh's attributes into one buffer (helix-geometry's meshes, helix-raylib's Models) cuts a scene's count
  six-fold before the tables need to grow.
- **A masked animation blend, in helix-geometry (DECISIONS 47):** a pose blended from two
  clips bone by bone, each bone taking the second clip by a weight of its own: a set the program names (a bone and its children,
  `Spine` up for the upper body), or the bones the clip has tracks for, so a clip authored for the legs alone moves the legs alone.
  Godot's and Unity's animation trees blend by bone masks; raylib 6.0's `UpdateModelAnimationEx` blends the whole body by one value,
  so an attack clip replaces the run on the legs too and the character slides (the jam's warden does), and a clip with no track for a
  bone fills it with the rest pose at load, so partial clips dilute each other through a single blend. helix-geometry's `Animation3D`
  holds a clip's tracks per bone and `Skeleton3D` its rest pose, so the blend and the mask from a clip's tracks are theirs, for an
  engine above. helix-raylib has no call for it (DECISIONS 60).
- **Lit sprites (DECISIONS 47, 53):** 2D point and directional lights over a sprite run, a region with an optional normal map
  (Godot's Light2D and CanvasItem normal maps, Unity's 2D lights and lit sprite material, Phaser's Light2D), so a top-down game has a
  torch, a flash and a night. For an engine above, not helix-raylib (DECISIONS 60).
- **The garbage collector's share of a frame, natively first:** hxcpp's collector over helix-raylib's draw path is unmeasured. Measure
  it on the robots and bunnymark programs (hxcpp's `GC_STATS`, or perf on the collector's symbols), find what each draw allocates in
  `Frame`, `Models` and `Skinning`, and take it out or pool it (done 2026-11-05: the robots program's allocations a frame fell from 200k
  to 53k and the collector's share from 12.6% to 1.2% of the main thread's cycles, with the native adapter's draw allocating nothing). The
  collector's own settings were measured and are not worth setting: generational mode (`-D HXCPP_GC_GENERATIONAL`, a build define in
  hxcpp 4.3.2) and a 256 MB minimum working memory each take under half a point more, the floor at the cost of its memory; the robots
  contender keeps a `gc-min=MB` run option for measuring. In a page the collector is V8's: the robots page at 200 scavenges every
  third frame (125 in 8 s, 332 ms of main thread, none over 4 ms), from a typed-array view a block a draw and a key string a draw in
  the WebGL2 adapter, and helix-raylib's own; the same pass trims those.
- **raygui on helix-raylib (done, DECISIONS 41):** `helix.raylib.Raygui`, raygui 4.5-dev as raylib 5.5 ships it, every control, its
  style, icons and tooltips, held to raygui's C by the `raygui`, `raygui_input` and `raygui_values` suites. `.rgs` styles and `.rgi`
  icons load through `GuiLoadStyleAsync` and `GuiLoadIconsAsync` in `Raygui`. Left: rGuiLayout's `.rgl` layouts, and its code
  export through a Haxe code template for helix-raylib, if its custom templates allow one (to be checked). raygui styles only
  colors, borders, text and its icons. Skins from images are helix-raylib's own, in `extras.GuiSkins` (done, DECISIONS 42, 63). rlights is `helix.raylib.Rlights` the same way. raylib's other companion headers agents know,
  easings (`reasings.h`) and physics (`physac.h`), are each a module of their own the same way when wanted.
- **Platform proposals queued, for review:** depth sampled after a pass, depth bias, stencil, and the depth tests `Always`, `Less`,
  `Equal` and `GreaterEqual` (helix-render's revision 9). A render target's own sample count, apart from its depth, is being built. Deferred from the vertex formats
  (DECISIONS 33): bone IDs and three.js' skinIndex fed as normalized bytes or shorts and scaled back by the compiler, rounded, as a
  `ShaderCompileOptions` entry; until then they are floats, or a layer owning its shader scales them itself.
  The platform's checks of a pipeline's vertex layout (`PipelineLayout.check`, every backend, about 0.3 KB gzip) to be trimmed to what
  a backend would otherwise get wrong silently, once the platform's API is settled.
- **Assets, resources and objects, as the earlier C frameworks layered them (AGENTS.md's prior art: their resource/object model),
  as plumbing a game never calls.** Each engine keeps its own names: helix-raylib's `texture.id` becomes a
  stable handle its table maps to the current resource; helix-render's `Texture2D`, `GpuModel3D` and `GpuFont2D` are the stable
  identities, their platform handles internal; the helix-legacy engine's and a three.js layer's objects are their own nodes and meshes.
  Underneath, an internal registry in the services for layer authors: one resource per path (or generator's parameters), reference
  counted, replaced in place while the program runs (the changed file loaded beside the old, swapped at a frame boundary, a failure
  keeping the old, as `Shaders.watch` replaces a shader), a placeholder while it first loads. Linked only by a program that loads or
  watches that kind; a game reads nothing new. What each kind shares, as the earlier C frameworks' keyed resources did and as
  helix-raylib's textures already do (`Textures.byPath`, counted by holders, DECISIONS 25): a model file's decoded meshes and their
  GPU buffers, loaded twice or a hundred times one resident copy; an animation file's decoded clips (every frame's pose of every bone,
  never written once loaded, so the plainest case; today each load decodes its own); a font file's atlas texture and glyph table at a size; a sound file's
  decoded wave, each Sound its own playback (raylib's `LoadSoundAlias` by hand); one compiled program per distinct source pair, each
  Shader record's locations its own; music never, a stream being one playback; images never, a load being a mutable copy as raylib's
  is. Each engine's per-load records stay as its API has them; the sharing is underneath. After the jam, which measures the engine as
  it is.
- **Services features an engine needs and helix-raylib now reaches the platform for:** the mouse cursor (shape, visibility, lock) on
  `Mouse`, gamepad vibration and mappings on `Gamepads`, and a clipboard service.
- **The layer above the services:** constructs the platform and the services for a target, runs the frame in order and ends with the
  saves written, so a program knows none of that; its spec is the `Main.hx` the services trial's three agents each wrote the same way.
  Whether it wears a known API or an engine's is GOALS' open path.
- **Libraries apart from engines (done):** the libraries in `libs/` know no consumer, and the engines over them in `engines/` may own
  the loop and keep statics (docs/PLAN.md); `check_layers` refuses a library that reaches an engine, and the engines' tests run on every
  library change. helix-ray is helix-raylib: `engines/raylib/`, `-lib helix-raylib`, `import helix.raylib.Raylib.*;`, its defines
  `helix-raylib-native-root` and `helix-raylib-custom-frame-control`. Next, separate repositories, each engine
  pinning a library version, once the platform has held through a second consumer and is versioned.
- **Audio effects, low priority:** the API is agreed and committed (`IAudioEffects`, `AudioEffect`, PLATFORM.md's plan, and helix-services'
  `AudioEffects`, `Effect` and `Analyser` with their bodies unimplemented). Still to build: the two adapters (`WebAudioEffectsAdapter`,
  `Sdl3MixerAudioEffectsAdapter`) and the services' bodies, for an engine above. raylib has no effects of its own, so helix-raylib has
  no call for them (DECISIONS 60). Its programs write them as audio processors (`AttachAudioStreamProcessor`,
  `AttachAudioMixedProcessor`), which helix-raylib refuses, as they run on the audio thread.
- **A compiled shader per dialect, low priority (DECISIONS 54):** `CompileShaderFile` writes every dialect into one file, so a page
  fetches GLSL 410 and SDL_GPU's code it never reads (about 13 KB raw a shader, 3 KB gzip). Each graphics adapter would name the
  `ShaderSource` field it reads (an `IGraphics` member, a platform interface change for review), `CompileShaderFile` would write a file
  for each (`glow.glsl300es.shader`) and the loads would fetch the running adapter's, so a new adapter's dialect needs no table above
  the platform.
- **A C library through the C ABI, Box2D 3.x first (GOALS 5):** the pattern every C library follows, proved on one. A flat C file of the
  library's calls shaped for bulk work (a step, poses read into a buffer the caller owns, events read the same way), compiled from its
  pinned source into a native program by hxcpp, and built from the same source into a `.wasm` the library ships, fetched only by a
  program that uses it (no C toolchain in a user's path, goal 6). One Haxe class over both, in Box2D's own names, the target chosen by
  the compiler: a binding, not an adapter, with no interface until a second implementation exists (DECISIONS 53's rule). In a page it
  loads as the assets do, natively at once. Its test runs one scene on Node and natively and checks the two agree. helix-legacy's
  physics study measured the crossing: 32-byte poses read in bulk, 10 to 30 ns a body in a browser. Jolt follows behind a C file of
  its own (no exceptions or RTTI). Work off the frame (a Web Worker in a page, a thread natively) waits for physics to need it.
- **Pathfinding, the binding's second library:** grid A* and flow fields in Haxe, for tile and top-down games; a navmesh for 3D
  through the binding, Recast building it from a level's geometry (ahead of time, or once at load) and Detour querying it (paths,
  raycasts, the nearest point, DetourCrowd steering many agents, their positions read back in bulk), C++ behind a C file of its own,
  as Jolt; hxDaedalus (Haxe, 2D) benchmarked against it first. The test: agents cross a level the same way on both targets.
- **Particles, after the C binding:** emitters and their particles updated each frame and drawn instanced, judged against
  docs/EFFECTS.md's inventory and the earlier projects'. Written in Haxe first; its update moves into C through the binding's pattern
  only if measuring says it pays.
- **SDL3 with the platform:** a native build needs only Haxe and hxcpp (goal 6), so the platform haxelib ships the pinned SDL3 per
  system, or its build fetches it, in place of naming a library with `HELIX_SDL3_LIBRARY`.
- **Gestures:** taps, double taps, drags and flicks (the mouse and fingers alike), and two fingers' pan, pinch and twist, over `Touch`
  and `Mouse`, as helix-legacy's `PointerGestures` and touch gesture had them.
- **From a jam game's friction log (F numbers), for the layers that own them:**
  - helix-scene: `find` by name and kind, `addChildAt`, `getChildIndex`, `removeChildAt`, `contains` (F1, F2, F4); text pivot or
    vertical align (F20); a sprite keeping its sheet and index across a reload (F56); a matrix transform, so skew (F57); a pointer
    that never hovers from a finger (F63); the stage's default font (F66); 3D picking through a function registered when a 3D layer
    is added, not a hardwired 3D renderer (F74); reparenting that keeps the world transform (F44).
  - helix-render's size ladder: a 2D-only rung (`Batch2D` and text, no `Batch3D` or lighting) and a rung with UI and a pointer (F74).
  - helix-legacy's engine: an event queue (F3); splash, loading screen and transitions run as halves, held until a condition (F7-F11, F41,
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

## Known size leaks

What a rung's `@:adds` or a program's bytes show a program links without naming (docs/CONVENTIONS.md, "A program links only what it names"):

- helix-raylib's `LoadImageFromMemoryAsync` and `LoadMusicStreamFromMemory` choose by their `fileType`, as raylib's do, and
  `LoadWaveAsync` and `LoadWaveFromMemoryAsync` by a name or type known only as the program runs: raylib's API, so they stay. And in a
  page its assets are made over the server and its cache whatever a program loads: a program can't be told from its calls whether it
  reads anything from the server.
