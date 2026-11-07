# Roadmap

The order (DECISIONS 40, 53): raygui on helix-raylib (done, DECISIONS 41), then its skins (done, `extras.GuiSkins`, DECISIONS 42), then
helix-render's stages 1 to 3 (done, and set aside, DECISIONS 53), then helix-raylib's lit extras (`LoadPbrShader` done; light range,
intensity and tone mapping next, then environment maps), then a retained-mode engine tried on helix-raylib, Gyre's or a three.js-style one as the jam decides. Whatever comes next
keeps helix-raylib's size and speed where docs/speed.md records them.

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
- **helix-raylib's lit extras (DECISIONS 53):** what raylib's API lacks for a model drawn as authored, each an extra only a program
  calling it links. Done: `LoadPbrShader` beside `LoadLightingShader` (which stays raylib's, the lighting parity suite holding it to
  raylib's C): a glTF's materials under rlights' lights, the base color factor taken as linear where raylib reads it as sRGB bytes,
  `KHR_materials_unlit` honoured, `pbr.glsl` for a program's own fragment stage. Next, lights a scene of several can use: `range` and
  `intensity` on `Light`, read by `LoadPbrShader` alone, with a falloff by distance, and tone mapping in `pbr.glsl` in place of its hard
  clamp, since a point light dims with no distance today and four near-white lights clip to white. A scene graph with lights as nodes
  needs them first. Then environment maps: a cubemap prefiltered at
  load for the material's roughness and a BRDF table, on raylib's `MATERIAL_MAP_IRRADIANCE`, `MATERIAL_MAP_PREFILTER` and
  `MATERIAL_MAP_BRDF` slots and `LoadTextureCubemap`, so a metal under the PBR shader reflects something. `DrawMeshInstanced` draws
  nothing under `LoadPbrShader`, which has no `mat4` attribute, so an instanced twin is wanted too. Then lit sprites (below), shadows,
  and lights past rlights' four a draw, as the jam's games ask.
- **The jam, before Gyre's shape is decided:** agents (Sonnet, docs allowed) build the same small 3D top-down survivors-like on
  helix-raylib and on HeliX, two or three each, with gear worn from the modular characters' parts (CC0, Quaternius). Measured: tokens,
  time, build failures, bugs, lines written (engine-substitute against game logic), frame time, size, startup, and a change made
  later by a fresh agent. It answers whether a framework's structure beats a familiar API agents were trained on. Run on Sonnet
  2026-11-06, three a side, a tie but for a quarter less reading on helix-raylib, with the play pass, timing at 200 and the change task
  left. It compared two of our own APIs: the harder control is HeliX's docs/TRIAL.md, the same game as a clean room on plain
  TypeScript, on Three.js, Pixi, OpenFL and Godot, to which helix-raylib is added, with this spec in place of the draft's game.
- **A retained-mode engine on helix-raylib (DECISIONS 53), then Gyre's shape.** The scene (a stage, 2D and 3D nodes, transforms,
  hierarchy, the walk that culls, gathers lights and sorts, picking), ported from HeliX's scene code rather than designed anew, issues
  raylib's calls each frame as three.js does under its graph: the speed and size measured for `DrawTexturePro` and `DrawMesh` are
  its, raylib's holders are its GPU handles, and what raylib lacks comes as the extras above. The sketch is done
  (docs/trials/2026-11-06-retained-sketch): a thin graph issuing raylib's calls, nine gaps and the extras for them, unbuilt. Timed
  against the robots contender, the tree, cull and sort cost 6 to 8% at 400 robots with helix-math's matrices, 30 to 43% with raymath's
  allocating ones, so the graph keeps helix-math's. Gyre is HeliX's game-level API (app, loader, UI, transitions, animator, autopilot) on that
  scene and the services, so its users keep the API they know; the test is one of HeliX's games ported, its effort and its size
  beside its HeliX build. Whether Gyre keeps HeliX's API or folds its useful parts (the app's lifecycle, a retained UI, tweens,
  transitions, the autopilot) into a three.js-style engine on the same scene is the jam's question (DECISIONS 40). Whatever of the
  scene proves engine-neutral moves down into a library of its own once a second engine wants it, as `Images` did.
- **helix-raylib (DECISIONS 16, 19, 20, 21, 38):** raylib's API over the services, merged to `main`. Next:
  the environment-map extra (above); then reloading and placeholders under raylib's own names (the assets,
  resources and objects below). Then a trial of how agents take to
  the `...Async` loads, now in `helix.raylib.extras` (one task a blended animation: whether agents reach for 6.2's `UpdateModelAnimationEx`, DECISIONS 24), and only after it, faking sync loads in a page: compared as a spike, a worker-hosted page whose loads block
  (Atomics.wait, which a worker may; cross-origin isolation, OffscreenCanvas, input and audio relayed; raylib's loop run as written)
  against a whole-program rewrite into callbacks. A `Future` of our own over the callbacks, cross-target, may serve the managed layer,
  as Haxe has none (`js.lib.Promise` is the browser's alone). Every raylib 5.5 function is in; what refuses to compile
  does so on purpose (blocking loads, rlgl's GL handles, what a page can't do), naming itself. Platform changes it would like,
  for review: a page's cache in OPFS readable at once from the main thread (a worker holding OPFS's sync handles, the page
  spinning on a SharedArrayBuffer for the reply, as emscripten does), which needs the page cross-origin isolated (COOP and COEP), so
  only ever an option a program chooses, never the default.
- **Texture eviction, a proposal for review (DECISIONS 47's bar first):** of the engine set only Unity evicts on its own (its mipmap
  streaming under a memory budget); Godot, three.js, Heaps and raylib hold a texture until the program disposes it. What a user has is a
  page's GPU memory ceiling on phones, so the proposal is small and off by default. In helix-raylib: `extras.Textures.setGpuBudget(
  megabytes)` (0, the default, holds everything); each GPU texture carries the frame it was last drawn in (`Textures` stamps it as a draw
  binds it); when the frame's end finds `GpuMemory.textureBytes` over the budget, textures not drawn for 60 frames go, least recently
  drawn first, until under it, each keeping what refetches it after a lost context (its path, its encoded bytes, its pixels); the next
  draw of one brings it back as a restore does, the frame drawn with it missing as after a lost context. Render textures, fonts and the
  frame's own textures are never evicted. `DrawFrameStats` shows evictions a frame beside the GPU bytes. Not built until the user has
  read it; the bar says one engine, so it may also be dropped.
- **The frame stats in pages, with the frame's shape:** `DrawFrameStats` (`extras.Debug`) grows a line a feature and will crowd. Make it
  pages, cycled as three.js's stats panel cycles on a click: a click or tap on the panel (and `ToggleFrameStats()` for a key the program
  binds) shows the next, `FrameStatsStyle.page` says which. Page 0 fps and the frame time's mean and p95; 1 draw calls, triangles,
  state changes; 2 memory, the GPU's textures and buffers and the process's; 3 the frame's shape over the last five seconds, which
  found tonight's stalls where a half second's p95 stayed innocent: median against mean, the worst frame, and how many frames ran over
  a threshold (25 ms until set), each page with the small bar graph of its last few seconds behind the number, as stats.js draws, where
  a once-a-second stall shows without any threshold. What the display can't reach stays in the tools: GPU time, the GPU process's waits and the collector's
  pauses, read from a Chrome trace or perf (`scratchpad` scripts from 2026-11-05: `robots_profile.cjs`, `cpu_profile.cjs`,
  `gpu_perf.sh`, `phone_page.cjs`, to be kept under tools/compare when they settle).
- **The sprite path's per-sprite cost in a page:** the bunnymark at 200k takes 5.21 ms over Vulkan (docs/speed.md, after `DrawTexture`
  learned to write its record itself with the texture's handle an array read, from 6.73) against three.js's InstancedMesh at 3.84, both
  one instanced draw, so what is left is JavaScript a sprite, about 26 ns against 19: the record's twelve writes (about 2.5 ms of the
  5.2 for 200k, measured in isolation) and reading the bunnies' objects (about 2.1). The other texture draws (`DrawTextureRec`, `Pro`,
  `DrawTextureInstanced`) still go through `Frame.quad` out of line, since inlining it everywhere cost 640 B gzip a rung. On the phone
  the robots are script-bound the same way (36 ms of 40 at 100 robots, raylib wasm 30 whole): the draw path's cost per call is the
  mobile item as well.
- **Type bits in the graphics handles, and the resource floor's shape:** the native adapters pack a slot and a generation into a handle
  (sokol's own ids, the SDL_GPU adapter's slot + 1 below a generation), per kind, so a buffer handle given where a texture is expected is
  caught only when its slot and generation miss a live texture; the earlier C frameworks' handles carried the kind too. Put the kind in the handle's
  high bits on every adapter (the WebGL2 one hands out plain increasing ints) and refuse a handle of another kind, with a graphics test
  for each mistake. The floor of 2047 of each kind alive (docs/PLATFORM.md) is the native tables' size; a mesh takes a buffer an
  attribute, so interleaving a mesh's attributes into one buffer (helix-geometry's meshes, helix-raylib's Models) cuts a scene's count
  six-fold before the tables need to grow.
- **A masked animation blend, in helix-geometry, with a helix-raylib extra as its door (DECISIONS 47):** a pose blended from two
  clips bone by bone, each bone taking the second clip by a weight of its own: a set the program names (a bone and its children,
  `Spine` up for the upper body), or the bones the clip has tracks for, so a clip authored for the legs alone moves the legs alone.
  Godot's and Unity's animation trees blend by bone masks; raylib 6.2's `UpdateModelAnimationEx` blends the whole body by one value,
  so an attack clip replaces the run on the legs too and the character slides (the jam's warden does), and a clip with no track for a
  bone fills it with the rest pose at load, so partial clips dilute each other through a single blend. helix-geometry's `Animation3D`
  holds a clip's tracks per bone and `Skeleton3D` its rest pose, so the blend and the mask from a clip's tracks are theirs; the
  extra poses a `Model` by two animations and a mask under raylib's names, and keeps which bones each loaded clip animates beside its
  frames (`ModelAnimation` holds every bone's pose and says nothing of which were authored). A shader only takes the matrices.
  Then the jam's spec can ask for an attack on the upper body over the legs' run.
- **Lit sprites (DECISIONS 47, 53):** 2D point and directional lights over a sprite run, a region with an optional normal map
  (Godot's Light2D and CanvasItem normal maps, Unity's 2D lights and lit sprite material, Phaser's Light2D), so a top-down game has a
  torch, a flash and a night. An extra in helix-raylib over `Frame`'s sprite runs, a shader as `LoadPbrShader` is.
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
  icons load through `GuiLoadStyleAsync` and `GuiLoadIconsAsync` in `extras.Gui`. Left: rGuiLayout's `.rgl` layouts, and its code
  export through a Haxe code template for helix-raylib, if its custom templates allow one (to be checked). raygui styles only
  colors, borders, text and its icons. Skins from images are helix-raylib's own, in `extras.GuiSkins` (done, DECISIONS 42). raylib's other companion headers agents know, easings (`reasings.h`) and physics (`physac.h`), are each a module
  of their own the same way when wanted; the extras keep only what has no raylib-family equivalent.
- **Platform proposals queued, for review:** depth sampled after a pass, depth bias, stencil, and the depth tests `Always`, `Less`,
  `Equal` and `GreaterEqual` (helix-render's revision 9). A render target's own sample count, apart from its depth, is being built. Deferred from the vertex formats
  (DECISIONS 33): bone IDs and three.js' skinIndex fed as normalized bytes or shorts and scaled back by the compiler, rounded, as a
  `ShaderCompileOptions` entry; until then they are floats, or a layer owning its shader scales them itself.
  The platform's checks of a pipeline's vertex layout (`PipelineLayout.check`, every backend, about 0.3 KB gzip) to be trimmed to what
  a backend would otherwise get wrong silently, once the platform's API is settled.
- **Assets, resources and objects, as the earlier C frameworks layered them (AGENTS.md's prior art: their resource/object model),
  after the lit extras, as plumbing a game never calls.** Each engine keeps its own names: helix-raylib's `texture.id` becomes a
  stable handle its table maps to the current resource; helix-render's `Texture2D`, `GpuModel3D` and `GpuFont2D` are the stable
  identities, their platform handles internal; the HeliX engine's and a three.js layer's objects are their own nodes and meshes.
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
  `helix-raylib-files`, `helix-raylib-native-root` and `helix-raylib-custom-frame-control`. Next, separate repositories, each engine
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

## Known size leaks

What a rung's `@:adds` or a program's bytes show a program links without naming (docs/CONVENTIONS.md, "A program links only what it names"):

- helix-raylib's `LoadImageFromMemoryAsync` and `LoadMusicStreamFromMemory` choose by their `fileType`, as raylib's do, and
  `LoadWaveAsync` and `LoadWaveFromMemoryAsync` by a name or type known only as the program runs: raylib's API, so they stay. And in a
  page its assets are made over the server and its cache whatever a program loads: a program can't be told from its calls whether it
  reads anything from the server.
