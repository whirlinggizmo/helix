# Speed

How fast helix-raylib draws, and how large it is, against raylib C, Godot and HeliX on the same programs. Whatever changes
helix-raylib's drawing (helix-render underneath it, DECISIONS 39) is held to these numbers. This page is replaced when the numbers are
measured again, and git keeps the earlier ones.

Measured 2026-11-04 at helix-2.0 78f16db on coinspinner: an i9-13900HX and an RTX 4080 Laptop GPU, on Linux and X11. Native programs
ran in windows on the real display with vsync off. Pages ran in headless Chromium 1248 on the GPU (ANGLE over Vulkan) with its frame
rate cap lifted. A frame's time is the mean of 600 frames after 120 warming up, and each cell is the median of three runs. At 16.7 ms
a frame a program runs at 60 fps, and at 33.3 ms at 30 fps.

## The bunnymark

raylib's `textures_bunnymark`, the same program in each: bunnies of one 32 x 32 texture bouncing in an 800 x 450 window, each spawned
from the same seed, so every program draws the same frames. The example's counter bar is left out. helix-raylib's program and raylib
C's are `engines/raylib/tests/bunnymark/`, run by `tools/bunnymark.py`.

The most held is the largest count, rising by 1000 every second, whose frames averaged 59 fps or better. A single slow frame ends it,
so it is the noisier measure. Size is every file of the program's code a page fetches, gzipped, without the bunny's texture, or the
native program stripped.

Frame time in ms:

| program | where | 10k | 50k | 100k | 150k | 200k | most held | size |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| **helix-raylib** | page, WebGL2 | 0.84 | 3.63 | 7.75 | 13.48 | 17.44 | 179k | 43.8 KB |
| raylib C 5.5 | page, wasm, WebGL1 | 0.76 | 3.27 | 6.34 | 9.69 | 13.04 | 227k | 117.4 KB |
| HeliX, a `Sprite2D` each | page, WebGL2 | 2.64 | 14.81 | 28.04 | 41.58 | 54.70 | 63k | 83.6 KB |
| Godot 4.7.2, MultiMesh | page, wasm, WebGL2 | 10.16 | 46.27 | 91.00 | 135.61 | 183.95 | 15k | 10,125 KB |
| Godot 4.7.2, a `Sprite2D` each | page, wasm, WebGL2 | 20.17 | 102.34 | 203.58 | 285.45 | 376.67 | 7k | 10,125 KB |
| **helix-raylib** | native, GL | 0.72 | 2.98 | 6.02 | 9.57 | 15.73 | 174k | 7.9 MB |
| **helix-raylib** | native, SDL_GPU (Vulkan) | 0.66 | 3.05 | 6.74 | 8.73 | 11.89 | 268k | 7.1 MB |
| raylib C 5.5 | native, GL | 0.75 | 3.18 | 6.04 | 8.90 | 11.72 | 279k | 0.9 MB |
| Godot 4.7.2, MultiMesh | native, Vulkan (Forward+) | 1.31 | 6.12 | 11.77 | 16.99 | 23.66 | 131k | 73.5 MB |
| Godot 4.7.2, MultiMesh | native, GL (Compatibility) | 1.45 | 7.19 | 13.92 | 21.03 | 27.81 | 111k | 73.5 MB |

Godot's `Sprite2D` page past 50k is one run each.

## Animated robots

raylib's `models_animation`, many at once: a grid of the same robot (`robot.glb`, 7218 vertices and 43 bones), each posed by
`UpdateModelAnimation` at its own frame and drawn with `DrawModel`, in a 1280 x 720 window. helix-raylib skins on the GPU. raylib C
does either: on the CPU, as `UpdateModelAnimation` does by default, or on the GPU with `UpdateModelAnimationBones` and its skinning
shader. Size leaves out the robot's file (1.6 MB), which each program loads.

Frame time in ms:

| program | where | 50 | 200 | 400 | size |
|---|---|---:|---:|---:|---:|
| **helix-raylib** | page, WebGL2 | 3.16 | 13.06 | 26.04 | 78.5 KB |
| raylib C 5.5, GPU skinning | page, wasm, WebGL1 | 2.64 | 10.60 | 24.66 | 192.6 KB |
| raylib C 5.5, CPU skinning | page, wasm, WebGL1 | 21.89 | 86.41 | 173.00 | 192.9 KB |
| Godot 4.7.2 | page, wasm, WebGL2 | 13.20 | 56.44 | 163.98 | 10,125 KB |
| **helix-raylib** | native, GL | 2.99 | 12.14 | 24.24 | 8.8 MB |
| **helix-raylib** | native, SDL_GPU (Vulkan) | 2.79 | 11.71 | 23.50 | 8.0 MB |
| raylib C 5.5, GPU skinning | native, GL | 3.62 | 15.13 | 29.27 | 1.2 MB |
| raylib C 5.5, CPU skinning | native, GL | 5.49 | 22.22 | 42.67 | 1.2 MB |
| Godot 4.7.2 | native, GL (Compatibility) | 15.08 | 59.72 | 125.59 | 73.5 MB |

## Where they differ

- **In a page, raylib C is faster:** 18% at 100k bunnies, 28% at 150k and 19% on 200 robots, where its download is 2.5 to 2.7 times
  helix-raylib's.
- **Natively, SDL_GPU matches raylib C,** and GL falls behind it past 100k bunnies. On the robots helix-raylib is ahead of raylib C's
  own GPU skinning on either backend.
- **raylib's builds:** natively, raylib C is raylib's default release (-O1) with GLFW. In a page it is Emscripten -O3 and WebGL1
  (raylib's default ES2), where helix-raylib is WebGL2 and unminified.
- **Godot's programs** are GDScript. The `Sprite2D` version is the idiomatic one (one manager's `_process` moves every node), and
  MultiMesh is its documented fast path. Its web export has only the Compatibility renderer. It draws at fractional positions, where
  raylib and helix-raylib truncate them to whole pixels.
- **HeliX** draws a `Sprite2D` on its stage for each bunny. Its `Batch2D`, the fast path, is internal and not something a game reaches.
- **Chromium's backend** changes the page's numbers: see below.

## Pages over GL

The tables above ran on ANGLE over Vulkan. Over GL, Chrome's default on Linux, the pages ran as below, in a visible window and
headless (ms, the median of three runs). Visible was within 15% of headless. Over Vulkan a visible window lost its WebGL context at
startup, every program's, so pages are measured headless.

| program | 100k bunnies, headless | visible | 200 robots, headless | visible |
|---|---:|---:|---:|---:|
| **helix-raylib** | 9.35 | 8.99 | 20.42 | 23.54 |
| raylib C 5.5, GPU skinning | 6.35 | 6.66 | 8.40 | 10.95 |
| raylib C 5.5, CPU skinning |  |  | 24.28 | 23.98 |

Over GL, raylib C's GPU skinning is 2.4 times as fast as helix-raylib's on the robots, and its CPU skinning 3.6 times as fast as over
Vulkan.
