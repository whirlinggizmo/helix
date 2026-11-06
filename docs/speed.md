# Speed

How fast helix-raylib draws, and how large it is, against raylib C, Godot, three.js, Lime and HeliX on the same programs. Whatever changes
helix-raylib's drawing (helix-render underneath it, DECISIONS 39) is held to these numbers. The tables are written by
`tools/compare/compare.py --write` from `speed.json`, which keeps each contender's last measurement: helix-raylib's rows are measured
again with each change to its drawing, the others' when they change, and a row measured on another date than its table's newest says
so.

Measured on coinspinner: an i9-13900HX and an RTX 4080 Laptop GPU, on Linux and X11. Native programs run in windows on the real display
with vsync off. Pages run in headless Chromium 1248 on the GPU, ANGLE over Vulkan, with its frame rate cap lifted. A frame's time is the
mean of 600 frames after 120 warming up, and each cell is the median of three runs. At 16.7 ms a frame a program runs at 60 fps, and at
33.3 ms at 30 fps.

## The bunnymark

raylib's `textures_bunnymark`, the same program in each: bunnies of one 32 x 32 texture bouncing in an 800 x 450 window, each spawned
from the same seed, so every program draws the same frames. The example's counter bar is left out. Each contender's program is in
`tools/compare/contenders/`.

The most held is the largest count, rising by 1000 every second, whose frames averaged 59 fps or better. A single slow frame ends it,
so it is the noisier measure. Size is every file of the program's code a page fetches, gzipped, without the bunny's texture, or the
native program stripped. three.js's size is its page bundled and minified with esbuild, which is what a three.js game ships, with the
size as served (its modules unminified) beside it.

Frame time in ms:

<!-- compare: bunnymark -->
| program | where | 10k | 50k | 100k | 150k | 200k | most held | size |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| **helix-raylib** | page, WebGL2 | 0.39 | 1.48 | 3.10 | 4.88 | 6.88 | 417k | 51.3 KB |
| raylib C 5.5 | page, wasm, WebGL1 | 0.71 | 3.19 | 6.46 | 9.72 | 12.74 | 254k | 117.4 KB |
| Godot 4.7.2, MultiMesh | page, wasm, WebGL2 (2026-11-04) | 10.16 | 46.27 | 91.00 | 135.61 | 183.95 | 15k | 10,125.4 KB |
| Godot 4.7.2, a Sprite2D each | page, wasm, WebGL2 (2026-11-04) | 20.17 | 102.34 | 203.58 | 285.45 | 376.67 | 7k | 10,125.4 KB |
| three.js 0.187.0, InstancedMesh | page, WebGL2 | 0.17 | 0.63 | 1.44 | 2.26 | 3.08 | 482k | 136.0 KB bundled (422.0 as served) |
| three.js 0.187.0, a Sprite each | page, WebGL2 | 14.20 | 64.13 | 129.18 | 192.81 | 258.13 | 16k | 136.0 KB bundled (422.0 as served) |
| HeliX, a Sprite2D each | page, WebGL2 (2026-11-04) | 2.64 | 14.81 | 28.04 | 41.58 | 54.70 | 63k | 83.6 KB |
| **helix-raylib** | native, GL | 0.48 | 1.71 | 3.35 | 4.91 | 6.79 | 452k | 8.1 MB |
| raylib C 5.5 | native, GL | 0.72 | 3.27 | 6.50 | 9.41 | 11.71 | 273k | 0.9 MB |
| Godot 4.7.2, MultiMesh | native, GL, Compatibility (2026-11-04) | 1.45 | 7.19 | 13.92 | 21.03 | 27.81 | 111k | 73.5 MB |
| **helix-raylib** | native, SDL_GPU (Vulkan) | 0.37 | 1.68 | 3.40 | 5.27 | 7.33 | 468k | 7.3 MB |
| Godot 4.7.2, MultiMesh | native, Vulkan, Forward+ (2026-11-04) | 1.31 | 6.12 | 11.77 | 16.99 | 23.66 | 131k | 73.5 MB |
<!-- /compare: bunnymark -->

Godot's `Sprite2D` page past 50k is one run each.

## Animated robots

raylib's `models_animation`, many at once: a grid of the same robot (`robot.glb`, 7218 vertices and 43 bones), each posed by
`UpdateModelAnimation` at its own frame and drawn with `DrawModel`, in a 1280 x 720 window. helix-raylib skins on the GPU. raylib C
does either: on the CPU, as `UpdateModelAnimation` does by default, or on the GPU with `UpdateModelAnimationBones` and its skinning
shader. three.js skins on the GPU, one `SkinnedMesh` and one `AnimationMixer` a robot. Size leaves out the robot's file (1.6 MB), which
each program loads.

Frame time in ms:

<!-- compare: robots -->
| program | where | 50 | 200 | 400 | size |
|---|---|---:|---:|---:|---:|
| **helix-raylib** | page, WebGL2 | 2.49 | 10.21 | 17.83 | 86.2 KB |
| raylib C 5.5, CPU skinning | page, wasm, WebGL1 | 21.35 | 85.66 | 171.98 | 193.1 KB |
| raylib C 5.5, GPU skinning | page, wasm, WebGL1 | 1.97 | 7.95 | 15.92 | 192.8 KB |
| Godot 4.7.2 | page, wasm, WebGL2 (2026-11-04) | 13.20 | 56.44 | 163.98 | 10,125.4 KB |
| three.js 0.187.0 | page, WebGL2 | 5.13 | 19.20 | 39.97 | 160.0 KB bundled (460.0 as served) |
| **helix-raylib** | native, GL | 2.49 | 10.11 | 20.13 | 8.9 MB |
| raylib C 5.5, CPU skinning | native, GL | 5.81 | 21.56 | 43.86 | 1.2 MB |
| raylib C 5.5, GPU skinning | native, GL | 3.47 | 14.24 | 27.07 | 1.2 MB |
| Godot 4.7.2 | native, GL, Compatibility (2026-11-04) | 15.08 | 59.72 |  | 73.5 MB |
| **helix-raylib** | native, SDL_GPU (Vulkan) | 2.56 | 10.17 | 20.87 | 8.1 MB |
<!-- /compare: robots -->

## Where they differ

- **Size at game scale:** the bunnymark is a small program. The fair size comparison with three.js is `sizes.md`'s game rung, a skinned
  model, textures, a font, audio, input, a save, a shader and a render texture: 128.6 KB gzip, against three's 160 KB bundled with its
  model loader, and a three.js game's UI is the page's DOM, which costs it nothing.
- **three.js's two bunnymarks:** `InstancedMesh` keeps the quad on the GPU and sends a matrix and a color an instance, in one draw. A
  `Sprite` a bunny, its idiomatic 2D path, is one object and one draw each, with a `SpriteMaterial` of its own for its tint.
- **three.js's robots** are each a `SkinnedMesh` with its own skeleton, bone texture and mixer: one bone texture upload and eight draws
  (the robot's meshes) a robot, where helix-raylib poses into one palette texture a frame.
- **raylib's builds:** natively, raylib C is raylib's default release (-O1) with GLFW. In a page it is Emscripten -O3 and WebGL1
  (raylib's default ES2), where helix-raylib is WebGL2 and unminified.
- **Godot's programs** are GDScript. The `Sprite2D` version is the idiomatic one (one manager's `_process` moves every node), and
  MultiMesh is its documented fast path. Its web export has only the Compatibility renderer. It draws at fractional positions, where
  raylib and helix-raylib truncate them to whole pixels.
- **HeliX** draws a `Sprite2D` on its stage for each bunny. Its `Batch2D`, the fast path, is internal and not something a game reaches.
- **Chromium's backend** changes the page's numbers: see below.

## Pages over GL

ANGLE over GL is Chrome's default on Linux, and the pages run there as below (`compare.py --backend gl`). A visible window is within 15%
of headless over GL. Over Vulkan a visible window loses its WebGL context at startup, every program's, so pages are measured headless.

<!-- compare: bunnymark-gl -->
| program | where | 10k | 50k | 100k | 150k | 200k | most held | size |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| **helix-raylib** | page, WebGL2 | 0.45 | 1.57 | 3.26 | 5.13 | 7.08 | 324k | 51.3 KB |
| raylib C 5.5 | page, wasm, WebGL1 | 0.69 | 3.43 | 6.62 | 10.10 | 13.09 | 261k | 117.4 KB |
| three.js 0.187.0, InstancedMesh | page, WebGL2 | 0.21 | 0.96 | 1.89 | 2.78 | 4.61 | 369k | 136.0 KB bundled (422.0 as served) |
| three.js 0.187.0, a Sprite each | page, WebGL2 | 14.75 | 60.10 | 113.78 | 170.83 | 227.03 | 16k | 136.0 KB bundled (422.0 as served) |
<!-- /compare: bunnymark-gl -->

<!-- compare: robots-gl -->
| program | where | 50 | 200 | 400 | size |
|---|---|---:|---:|---:|---:|
| **helix-raylib** | page, WebGL2 | 2.70 | 10.83 | 20.80 | 86.2 KB |
| raylib C 5.5, CPU skinning | page, wasm, WebGL1 | 5.91 | 23.51 | 46.28 | 193.1 KB |
| raylib C 5.5, GPU skinning | page, wasm, WebGL1 | 1.96 | 7.84 | 15.33 | 192.8 KB |
| three.js 0.187.0 | page, WebGL2 | 6.30 | 34.50 | 70.25 | 160.0 KB bundled (460.0 as served) |
<!-- /compare: robots-gl -->
