# Jam-readiness audit

What a game jam would stall on, checked against what HeliX has (October 2026, after milestone 8's SDL3 work). The test isn't "an example needs it" but "a game written in a weekend would stop to build it" (DECISIONS 111's rule, the completeness memory). Each item is **present**, **partial** or **missing**, with what exists, what's lacking, and where the earlier frameworks (wgrender-c, libwgf, the libwgf racer's FRICTION.md) or the engines HeliX takes from have an answer. The ranking is the user's; a proposed order is at the end.

## 1. Jam basics

| Item | Status | What exists | What's lacking |
|---|---|---|---|
| Saves | **missing** | `Storage` is the asset cache (`StorageService` over `IStore`), wiped by `clearCache`; the dressing room can't save a look (DECISIONS 112) | A store of the game's own, apart from the cache: keys to bytes or JSON, slots, a version for migration; IndexedDB in a browser, the user's data directory natively (as `Identity` already places the cache) |
| Input actions and remapping | **missing** | Raw keys, mouse buttons, pointer, touches, pad buttons and axes, with tick and frame edges; a round dead zone on pads | An action map ("jump" = Space, pad South, a touch button), queried as keys are, rebindable at run time and saved; the names a settings screen shows |
| Pause and time | present | `Time.clock` (`helix.time.Clock`): scaled and paused as a whole, feeding tickers, tweens, timers and whatever takes its delta (milestone 9); `Scenes` pauses it on focus loss (milestone 10) | |
| Audio control | partial | Clips and streams, play, pause, resume, stop, volume per playback, MP3 and WAV, reload in place | Groups or buses (master, music, effects) with their own volumes, saved; fades (music cross-fade); pitch and pan; ducking |
| Scenes and flow | present | `helix.scene.Scenes`: push, pop, replace with enter, exit, pause and resume, a `Fade` between, pause on focus loss (milestone 10) | Wipes and other transitions |
| Splash and loading | present | `Loader` (one progress, failures by name), the built-in `Loading` shown by the stack (replaceable, or none), the built-in `Splash` holding until a press (milestone 10) | Progress by bytes |
| Tweens, timers, sequences | present | `helix.tween.Tweens` (Penner's easings, delay, repeats, yoyo, completion), `helix.time.Timers` (after, every), on the clock's delta (milestone 9) | Sequences beyond chaining completions |
| Seeded random | present | `helix.math.Random` (xorshift32, an instance per stream, states, pick, shuffle, weighted), the same bits on every target (milestone 9) | |
| 2D collision | present | `helix.collision`: rectangles, circles, convex polygons, points, segments, rays, sweeps, move-and-slide over tiles, a spatial hash (milestone 9) | Slopes and one-way platforms; layers and masks |
| Camera helpers | partial | `Camera2D` fit and pixels, `Presentation`, `Camera3D.minAspect`; `Interpolate.damp` and `Curve` for rails (milestone 9) | Follow with lag, bounds, shake, zoom tween; a third-person follow for 3D |
| Text and localization | partial | TrueType, baking, wrapping, `measureWrapped`, kerning | String tables with a language switch, plural forms; glyph fallback (CJK, emoji); number and time formatting |
| UI | present (basics) | Button, label, list, panel (nine-slice), progress, slider, text field, toggle, tile, focus by pointer, keys and pad, themes, `Layout2D` rows, columns and stacks with anchors | A scroll view, dropdown, tabs, tooltip, modal dialog; a wrapping row (Godot's flow container); the phone's keyboard for a text field; text scaling as a setting |
| Sprites and sheets | partial | Textures, sprites with flips and tints, KTX | A sprite sheet (atlas) with named frames and frame animation; a packer tool |
| Tilemaps | partial | The tilemap example draws tiles as sprites through a camera | A Tiled (JSON) loader with layers, objects and collision; a chunked tile stage drawn as one batch |
| Particles | present | `Emitter` in 2D and 3D | A few presets (burst, trail, smoke) a jam can start from |
| Window | present | Size, fullscreen, monitors, title, focus, pixel ratio, presentation | Orientation lock on phones (the browser only allows it fullscreen) |
| Debug | present | FPS overlay, `Batch3D` lines and grid, screenshots, autopilot probes and clicks | A debug text console on the page (libwgf's page had one: logs and errors a phone can't show otherwise) |
| Hot reload | present | Code and assets in the browser, assets natively | |
| Settings and flags | present | `config.json` with profiles, fetched at start; `Host.getOption` and the typed readers (milestone 10) | A settings screen saving over it (milestone 12) |
| Packaging | partial | A web folder per example; a native binary beside its assets; manifests | One command that makes an itch.io-ready zip (web) and a named folder or archive (native), with the manifest written; an icon and a title |

## 1b. The scene file and the editor

| Item | Status | Notes |
|---|---|---|
| A scene file | **missing** | Stages are built in code; a glTF file is the nearest thing (a Blender scene loaded whole). libwgf had scene files of blocks (the racer's track: bodies, shadows, checkpoints; FRICTION part 4), whose lessons are the rules: lights live in the file, game data lives in the file, overriding a file's node doesn't mean re-declaring its parents, and load, save, load gives the same bytes. A `.scene` of HeliX's own: JSON, a tree of nodes (group, a model from a file by path, light, camera, a nested scene as the prefab), overrides on a file's nodes by path, and `props` per node |
| Behaviors | **missing** | The game model is open (DECISIONS 61). A behavior as Unity's: a class with lifecycle hooks (init, update, an event, teardown) attached to a node with its props. The file names it by a string, so a registry is forced: a build macro collecting every `@:behavior` class, as Haxe has no reflection by type name and hand registration stalls a jam. Vignette Studio (`experiments-ts-vfstudio`) left the same question open: a hardcoded event-handler registry, scripts' lifecycle and dispatch in its TODO |
| Property schemas | **missing** | What an inspector reads: a node kind's editable properties, as Vignette Studio's `object_schema.ts` drove its inspector |
| Blender as a way in | **missing** | `tools/gltf2scene.py`: an exported `.glb` into a `.scene`, Blender's custom properties as props |
| The editor | **missing** | A separate package (`helix-editor`), a web app over HeliX's JS build as the viewport with the browser's DOM for panels, tree, property grid and dialogs, as three.js's editor and PlayCanvas are; not in the framework, which would then carry selection, undo, gizmos and an editing mode. Vignette Studio is the prior art for its model: objects with property tracks and event tracks, keys by frame, a live preview at the playhead, Move, Rotate and Scale modes, explicit keying; timelines and events come to the file as a `timeline` block with a player, once the format has carried a real level |

## 2. Standard shaders

| Item | Status | Notes |
|---|---|---|
| Surface: toon, dissolve, water | done (milestone 13) | `helix.shaders`' `Toon`, `Dissolve` (laid over the model in its own space, its shadow dissolving with it) and `Water` (its waves moving its shadow), and `Unlit`, made on a material in one line, static or skinned; the `shaders` example keeps one of its own to show how one is written |
| Surface: outline, silhouette, rim light, flash or hit tint | done (milestone 13) | `Outline` (an inverted hull, a width in world units) and `Silhouette` (depth greater) as passes on a model; `Rim` and `HitFlash` as every material's terms, whatever its shader |
| Screen: bloom and glow | done (milestone 13) | `Bloom` over an HDR scene (half floats where the GPU draws them), down six halving intermediates and back up, `PostProcess` growing intermediates at fractions of the frame |
| Screen: FXAA, blur, vignette, color LUT, CRT, chromatic aberration, pixelate | done (milestone 13) | `Fxaa`, `Blur`, `Vignette`, `ColorLut`, `Crt`, `ChromaticAberration`, `Pixelate` and `Tonemap`, each a class whose fields are its parameters; the `shader-gallery` example shows every one |
| 2D: sprite outline, flash, dissolve, palette swap | done (milestone 13) | `helix.shaders`' `SpriteOutline`, `SpriteFlash`, `SpriteDissolve` and `PaletteSwap`: sprite shaders (the `helix_sprite` kind, a `SpriteEffect`) that a `Sprite2D`, a `Batch2D` or a `Stage3D`'s `Sprite3D` draws through (`effect`), a batch splitting where the effect changes. Before them `Batch2D` had no custom shader path: it always drew the framework's sprite program, its tint only multiplying |

Proposal: `helix.shaders`, a library of ready surface and screen shaders with parameters by name, each with a one-line way to attach it (a material's surface shader, a `ScreenEffect`), and `PostProcess` growing scaled intermediates for bloom.

## 3. Networking and multiplayer

| Item | Status | Notes |
|---|---|---|
| HTTP | present | `Fetch` with headers, progress, timeouts, cache control |
| WebSockets | **missing** | `ISocket` (open, send, receive, close) with a browser adapter over `WebSocket` and a native one (TLS is the hard part natively: SDL3 has no TLS; a small client over mbedTLS or the platform's) and a shared service for reconnecting and queuing (ROADMAP's `IWebSocket`) |
| Netcode | **missing** | Lockstep or snapshot sync, prediction, a lobby: a separate package over `ISocket`, with the final example (an ARPG-like, the user's) deciding its shape; determinism (Trig, a seeded random, fixed ticks) already points at lockstep. Prior art of the user's: `experiments-ts-vfcore`, a deterministic fixed-step module host with multi-peer sessions (provisioning, join and leave, reconnect with grace, a host-owned lifetime) over Web Workers or WebSockets, its conformance suite proving a TypeScript and a WASM module behave identically |

## 4. Physics

| Item | Status | Notes |
|---|---|---|
| 2D arcade physics | **missing** | Most jam games: AABB and circle bodies, gravity, move-and-slide against tiles and slopes; pure Haxe, deterministic |
| Box2D | **missing** | The physics study showed Box2D and Jolt through wasm with bulk reads (work off the frame, ROADMAP's open design); a 2D rigid-body game (a racer top-down, a physics puzzle) wants it |
| Jolt (3D) | **missing** | libwgf's physics3d on Jolt carried the racer: its FRICTION part 2 lessons to keep: lower the center of mass or a car rolls; wheel slip 1/60 rolling, 1 driving; driver aids on keys; grass as grip, not drag; a track of 500 scaled planes as a static mesh just worked; sensors centered on their actor; the web size budget; determinism held with Jolt; settings take effect "made again, at rest" |
| The drawn transform | **missing** | The racer's first friction: nothing gave a simulated body's interpolated transform for the camera; HeliX's `Ticker.fraction` is the half, a body's previous and current the other |

## 5. Pathfinding

| Item | Status | Notes |
|---|---|---|
| Grid A* | **missing** | Small, pure Haxe, with a flow field for many agents; most 2D jams |
| Navmesh | **missing** | Recast and Detour through wasm and a native library (bake from the stage's meshes, query), or hxDaedalus (pure Haxe, never benchmarked here); steering (seek, arrive, avoid) beside it |

## 6. Found on the way (earlier sessions)

- A public posed bounds for a skinned model (picking poses one on the CPU already; the dressing room framed by joint reach instead).
- `Font2D.measureWrapped` (done), a wrapping box (not done).
- An orientation preference for phones.
- The `tilemap` example's world camera upright shows 5 tiles across.

## The order (the user's)

Smallest stalls first, where a weekend is lost on something an afternoon builds; saves after pathfinding, the user's call:

1. The small utilities: tweens and timers, a seeded random, 2D collision, a game clock with pause. One milestone, all pure Haxe with unit tests.
2. Scenes and flow, with loading and splash over `Host.busy` and progress.
3. The scene file: the format, load and save, behaviors by name, property schemas; the editor as a separate package after.
4. Input actions and remapping; audio buses and fades (the settings screen needs both).
5. The shader library, surface then screen, with bloom's intermediates.
6. 2D arcade physics; then Box2D and Jolt through the work-off-the-frame module.
7. Grid A*; then a navmesh.
8. Saves.
9. `ISocket`, then netcode with the final example.
