# Speed: the bunnymark

raylib's `textures_bunnymark`, the same program in each contender: bunnies of one 32 x 32 texture bouncing in an 800 x 450 window,
each spawned from the same seed, so every contender draws the same frames. The example's counter bar is left out. helix-raylib's
program and raylib C's are `engines/raylib/tests/bunnymark/`, run by `tools/bunnymark.py`. Whatever changes helix-raylib's drawing
(helix-render underneath it, DECISIONS 39) is held to these numbers.

Measured 2026-11-04 on coinspinner: an i9-13900HX and an RTX 4080 Laptop GPU on Linux and X11, native windows on the real display with
vsync off, and pages in headless Chromium 1248 on the GPU (ANGLE over Vulkan, the frame rate capped at 60 Hz). Each cell is the
median of three runs. A frame's time is the mean of 600 frames after 120 warming up. The most held is the largest count, rising by
1000 every second, whose frames averaged 59 fps or better. A single slow frame ends that, so it is the noisier measure.

## Native

Frame time in ms, and the most bunnies held at 59 fps.

| contender | 1k | 10k | 50k | 100k | most held |
|---|---:|---:|---:|---:|---:|
| raylib C 5.5 (GL 3.3, its default -O1 build) | 0.10 | 0.72 | 2.95 | 5.86 | 295k |
| **helix-raylib, GL** | 0.18 | 0.77 | **3.10** | 6.12 | 174k |
| **helix-raylib, SDL_GPU (Vulkan)** | 0.25 | 0.69 | **3.02** | 6.66 | 263k |
| Godot 4.7.2, MultiMesh, Forward+ | 0.21 | 1.37 | 6.06 | 11.63 | 140k |
| Godot 4.7.2, MultiMesh, Compatibility (GL) | 0.22 | 1.40 | 7.14 | 14.04 | 114k |
| Godot 4.7.2, a Sprite2D for each bunny, Forward+ | 0.31 | 2.39 | 16.41 | 35.10 | 44k |
| Godot 4.7.2, a Sprite2D for each bunny, Compatibility | 1.41 | 12.93 | 67.83 | 132.03 | 12k |

helix-raylib on the way there, GL and then SDL_GPU at 50k:

| helix-raylib | GL at 50k | SDL_GPU at 50k | GL most held | SDL_GPU most held |
|---|---:|---:|---:|---:|
| 5d3d4f9, before | 30.83 | 25.05 | 27k | 35k |
| f4c712b, nothing allocated per draw, typed records | 3.99 | 4.35 | 123k | 199k |
| cb90b0b, quads as four indexed vertices | 3.10 | 3.02 | 174k | 263k |

Before f4c712b, a profile at 50k found 40% of the time in hxcpp's collector and allocation (each `DrawTexture` made two rectangles,
a vector, two arrays and a closure, and each vertex an array) and 15% in dynamic field access (the batch's records were anonymous
structures, which hxcpp reads by name). Before cb90b0b, each quad was six vertices, and GL's frame time grew faster than the count
past 50k as the vertex upload grew.

## Page

Frame time in ms (16.7 is 60 fps, the cap), and the most held.

| contender | 50k | 100k | 150k | 200k | most held |
|---|---:|---:|---:|---:|---:|
| raylib C 5.5 (Emscripten -O3, WebGL1) | 16.7 | 16.7 | 16.7 |  | 220k to 238k |
| **helix-raylib (WebGL2)** | 16.7 | 16.7 | **16.7** | 17.4 |  |
| helix-raylib at 5d3d4f9, before | 16.7 | 23.1 | 32.6 |  | 77k |
| HeliX, a Sprite2D for each bunny (one run each) | 16.7 | 28.3 | 40.9 |  |  |
| Godot 4.7.2, MultiMesh | 46.2 |  |  |  | 15k |
| Godot 4.7.2, a Sprite2D for each bunny | 105.7 |  |  |  | 7k |

## Size

Every file each page fetched, KB.

| contender | raw | gzip | brotli |
|---|---:|---:|---:|
| helix-raylib (unminified, as docs/benchmarks.md measures) | 190 | 42.7 | 35.9 |
| raylib C (Emscripten -O3) | 350 | 115 | 98 |
| Godot 4.7.2 (web, no threads) | 38,901 | 9,918 | 6,831 |

Native, stripped: raylib C 0.88 MB, helix-raylib 7.7 MB with GL and 7.0 MB with SDL_GPU (SDL3 linked in), Godot's export template
71.8 MB.

## Not equal

- **raylib's builds:** natively, raylib C is raylib's default release (-O1) with GLFW, and an -O2 build would widen its lead. In a page it
  is WebGL1 (raylib's default ES2) where helix-raylib is WebGL2.
- **Godot's variants:** its programs are GDScript. The Sprite2D version is the idiomatic one (one manager's `_process` moves every node),
  and MultiMesh is its documented fast path. Its web export has only the Compatibility renderer.
- **HeliX's run:** HeliX was run only in a page, once a count, with a `Sprite2D` on its stage for each bunny. Its `Batch2D`, the fast
  path, is internal and not something a game reaches.
- **Positions:** Godot draws at fractional positions, where raylib and helix-raylib truncate them to whole pixels.
