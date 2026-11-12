# Speed

`tools/gen_speed.py` measures helix-raylib against raylib C, Godot, three.js, Lime and helix-legacy on the same two programs and writes
the numbers into `docs/speed.json`, and `docs/benchmarks.md`'s speed tables and charts. `gen_speed.py --help` has the command line.

## The programs

Each contender's are in `contenders/<name>/`.

- **bunnymark**: raylib's `textures_bunnymark`. 800 x 450, the 32 x 32 `wabbit_alpha.png`, no counter bar. Every bunny spawns from
  the same xorshift32 seed (2463534242): x in [0, 768], y in [40, 418], a speed of rnd(-250, 250) / 60 a frame on each axis, a color of
  (rnd(50, 240), rnd(80, 240), rnd(100, 240), 255). The update and the bounce are raylib's, and positions are truncated to whole pixels
  as raylib draws them. Options: `count=N`, or `ramp=1`.
- **robots**: raylib's `models_animation`, many at once. 1280 x 720, `robot.glb` (7218 vertices, 43 bones), count robots in a grid of
  ceil(sqrt(count)) columns at a spacing of 4, the camera at (0, 0.9w, 0.9w) looking at (0, 1.5, 0) with a 45 degree field of view
  where w is the columns times 4, each robot posed at frame (frame + 1 + i * 5) % frameCount of the first animation, drawn unlit.
  Option: `count=N`.

Both assets come from raylib's own release, which `tools/raylib_parity.py` fetches and pins, so no binary lives here.

## The measure

A `count=N` run draws 120 frames to warm up, then times 600: the mean and the 95th percentile of the frame-to-frame times, printed as
one JSON line with `"contender"`, `mean_ms` and `p95_ms`. A `ramp=1` run starts at 1000 and adds 1000 every 60 frames while those
averaged 59 frames a second or better, and prints the largest count that held as `ramp_max`. Each cell in the tables is the median over
the runs (three by default), the runs taken round-robin over every program and count so a drift in the machine spreads over all of them.

Pages run in Chromium with its frame rate cap lifted, on ANGLE over Vulkan or over GL. Native programs run in windows with vsync off.
three.js's native program is its page in Electron (`contenders/three/electron/main.cjs`), run by `run_page.cjs --electron`. By default
both run headless: the pages in headless Chromium, the native programs on a private display with software GL (not representative, and
the tool says so, and won't write them). `--headed` runs the native programs on the real display, and the pages over GL in a window.

## When it runs

When asked, never in CI. With no contender named a run takes helix-raylib, raylib C as the control (`--no-control` leaves it out, and
then nothing is written), and each other contender whose rows are missing or whose pinned version changed; `--all` takes every
contender and the pages over both backends. `--write` first checks the machine is quiet (its load, and a pinned loop's time, which a
CPU held back by its firmware slows), and after the run that the control stayed within 20% of its last rows.

## Sizes

A page's size is every file it fetched but the assets (`.png`, `.glb`, Emscripten's `.data`, Godot's `.pck`), raw, gzip -9 and brotli
-q 11. three.js's is also its page bundled and minified with esbuild, the size a three.js game ships. A native program's size is its
binary stripped, and Electron's is its files as installed, with the page bundled.

## Toolchains

Found, never fetched, and a contender whose toolchain is missing is skipped with one line: Emscripten (`EMSDK`, `HELIX_EMSDK` or
`~/toolchains/emsdk`), Godot's binary (`HELIX_GODOT`, `godot` on PATH, or `~/toolchains/godot/Godot_v<version>-stable_linux.x86_64`),
helix-legacy's checkout (`HELIX_LEGACY`, or `../helix-legacy`), npm for three.js, esbuild and Electron (installed into
`build/speed/three/npm` at the versions `dependencies.json`'s `speed` entry pins), `brotli` for the brotli sizes.
