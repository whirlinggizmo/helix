# History

What was built, milestone by milestone, and what each step found. Every entry links to the decisions behind it, in [DECISIONS.md](DECISIONS.md) (numbered, in order: the record the code and docs cite). What's next: [ROADMAP.md](ROADMAP.md). Text here is kept as written, so a name in it may since have changed.

## Before HeliX: the architecture study

HeliX began as experiment 05 of whirlinggizmo's framework architecture study, a Haxe framework compared against libwgf (C): one Haxe program built to JS for the browser and to C++ through hxcpp natively, over thin platform adapters. Asteroids was its first slice. Two probes decided whether it went on: hot reload in the browser through hotreload-hx (probe 1, during milestone 1), and the cost of 3D on the CPU (probe 2, 2026-10-13, before milestone 2: Haxe matched libwgf's C natively and its Wasm in V8).

## Milestone 1: the platform, 2D and services (to 2026-10-12)

The hosts, input (keys, pointer, touch, four gamepads), Web Audio and sokol audio, fetch, storage and the asset cache, 2D batches and text, a fixed-rate ticker, Asteroids and Blocks as examples like the rest, with autopilot scripts that must end in the same game on both targets. HeliX then moved to its own repository; the study keeps its record. Decisions 1–58 (those before the move were made in the study, and name it).

## Milestone 2: 3D basics (2026-10-13)

A frame the app owns and framework shaders by kind; deterministic trigonometry for simulations (`helix.math.Trig`, the same bits in the interpreter, JS and hxcpp); retained stages of render nodes beside the immediate batches; lit models through an instance buffer and a trimmed PBR shader; normal maps; glTF models read in Haxe. Decisions 59–64.

## Milestone 3: 2D stages and the rest of 2D (2026-10-13)

`Stage2D`; sampling per draw and compressed textures picked by GPU; TrueType read and baked in Haxe; render targets; apps' own shaders as assets, surface shaders on Stage3D materials, screen effects. Decisions 65–70.

## Milestone 4: advanced 3D (2026-10-13 to 2026-10-14)

Camera nodes; glTF from .gltf files and files beside them; mirrored models; textures shared by file; 3D sprites and text; GPU particles in 2D and 3D; shadow maps (the sun's texels held still in the world); environments (split-sum image-based light, prepared a step at a time). Decisions 71–79. Then skinning and skeletal animation: skins and clips bound by joint name, a file of animations playing on any skeleton with its names, gear swapped at run time, sockets, crossfades, one joint texture a pass, culling by the posed joints. Decision 87.

Checked at its end (2026-10-14): the full tests with native (unit, shader tools, package smoke, the C services test, the trig bits), the services on both targets, Asteroids' and Blocks' autopilots ending in the same game on both, and every 3D example natively on the private display (the animation example driven by keys: clips, the sword socket mid-crossfade, the outfit swapped, posed shadows). On that software-rendered display the environment took 11.8 s to prepare: its bake is tied to a per-frame budget ([ROADMAP.md](ROADMAP.md)).

### The adapter audit (2026-10-14)

Midway through milestone 4, the platform adapters were found repeating engine policy, each its own way. They became a hardware abstraction layer with a rule (an adapter holds only what differs because of its platform) and a check that enforces it: graphics as data, the host split from the engine's runner, one job pool under fetch, storage and decoding, audio output apart from audio decoding, input adapters as event sources feeding one router, adapter directories and classes named by rule, and screenshots (the frame read back, PNG encoded in Haxe, saved through `IExport`). Decisions 80–86; the audit's findings and plan: [ADAPTER_AUDIT.md](ADAPTER_AUDIT.md).

## Milestone 5: scene and pick (2026-10-14)

libwgf's three node flags (enabled, visible, pickable) on 3D and 2D nodes (decision 88). The ray through a pixel of a camera's viewport; picking a Stage3D by each model's triangles (skinned ones as posed), sprites and text by their quads; picking a Stage2D by each kind's own area; `helix.scene.Pointer` over stages, topmost first, a press on 2D capturing it (decision 90). Lights chosen per model: a table of 16, each model's 8, in its record (decision 89, fixing the first-four-lights finding). A culling switch, libwgf's shadow-caster case checked, and `tools/stagebench.py`: culling worth almost everything out of view, a pick through 4000 models under a sixth of drawing them, and the first light choice found seven times too slow and fixed (decision 90). The `scene3d` and `pick` examples. Checked at its end: the full tests with native, the services on both targets, the autopilots, `scene3d`, `pick`, `lights`, `shaders`, `shadows` and `animation` natively (a sphere hovered and clicked through the pointer on the private display).

## Milestone 6: UI (2026-10-14)

`helix.ui`: wgrender-c's widgets of nodes, asked each frame, with libwgf's focus by keys and pads and its friction fixed (a key held into a new screen ignored, the ring only when keys moved focus, the keys reported so a game leaves them be); a layout of rows, columns and anchors in Haxe (Clay's passes, no Clay); label, panel, button, toggle, slider, progress bar, list and text field; beneath them a scissor in IGraphics, nested clips, nine-slice sprites and wrapped text (decision 91). Replay made independent of timing: scripts wait on state with limits in seconds for what isn't the simulation's, games start each replayed phase fresh (Asteroids' title rocks became dressing), and scripts use UI by name with the autopilot's `click`, as web suites do (decision 92). The `ui` example; Asteroids' menus on helix.ui. Checked at its end: the full tests with native, the services on both targets, both games' autopilots the same final game on both targets, `ui`, `sprite2d`, `stage2d`, `tilemap` and `scene3d` natively (the level list opened by keys and scrolled by the wheel, its rows clipped by the native scissor).

