# Contributing

How work on this repository runs: what to install, how to check a change, the tools, and how unattended work is kept honest. The
rules for the code itself are in [docs/CONVENTIONS.md](docs/CONVENTIONS.md). The agents' entry point is [AGENTS.md](AGENTS.md).

## Prerequisites

To use the libraries:

- **Haxe 4.3.7.** Enough for the browser, and for writing shaders. The platform's shader compiler fetches glslang and SPIRV-Cross into
  the user's cache the first time.
- **Natively:** hxcpp 4.3.2 (`dependencies.json`'s pin), the C/C++ compiler it drives, and SDL3. `tools/sdl3.py` finds or makes the
  pinned release into `build/deps` for this repository. A program elsewhere names the library with `HELIX_SDL3_LIBRARY`. On Linux, SDL
  loads X11/Xrandr/Xi/Xcursor and GL for the window and graphics, and ALSA or PulseAudio for audio.

To develop them, also:

- **Python 3** for the checks and tools in `tools/`, standard library only.
- **Node** with Playwright (Chromium) for the browser checks. The tools install it into `build/tools`.
- **CMake** for the platform's native C tests (`libs/platform/tests/native/CMakeLists.txt`, built by `helix.py test --native` with the
  compiler hxcpp uses), and on Linux to build SDL3 when the system has none.

The repository keeps its own haxelib in `build/haxelib`: a dev link to each library, the pinned hxcpp, the formatter and dox. The tools
make it as they run (`tools/pins.py`). A worktree gets a real copy of `build/haxelib`, whose dev links then point into the worktree.

## Layout

```
libs/<library>/    the libraries (math, log, geometry, formats, platform, services, render): haxelib.json, README.md, src/, tests/ (and examples/, vendor/)
engines/<engine>/  the engines over them (raylib), laid out as a library is (and parity/)
tools/             the repository's checks and helpers, never shipped
docs/              the plan, the specs, conventions, architecture, the API reference and the benchmarks
build/             scratch: the repository's haxelib, SDL3, hxcpp's output (ignored)
```

## Checks

Fast ones with each step, the full ones at a milestone:

- After an API change: `python3 tools/check_types.py --no-output`, every entry point of every library on its targets, in seconds.
- Before a commit: `python3 helix.py test`, `python3 tools/format.py --check`, `python3 tools/check_docs.py`. A commit touching doc
  comments also runs `python3 tools/gen_apidoc.py` first, since the committed reference must match them.
- A change touching helix-raylib's `Runtime`, `Frame` or what the native adapters are built over also gets one native parity suite,
  `python3 tools/raylib_parity.py shapes2d`. The unit suite and a page run open no native window, so a native-only fault passes them.
- At the end of a feature: the native builds, `tools/platform_checks.py`, `tools/services_checks.py`, `tools/render_checks.py` and
  `tools/raylib_parity.py`.

```console
python3 helix.py test                       # the tools' checks, the size ladders, each library's tests, Trig's bits across targets
python3 helix.py test --native              # also each library's tests in hxcpp and the platform's native C tests
python3 tools/check_types.py --no-output    # type-check every entry point of every library on its targets
python3 tools/platform_checks.py --browser <chromium>   # the platform's examples and GPU tests, natively on a private display and in Chromium
python3 tools/services_checks.py --browser <chromium>   # the services' examples, natively on a private display and in Chromium
python3 tools/render_checks.py --browser <chromium>     # helix-render's examples and pixel tests, on GL, SDL_GPU and WebGL2
python3 tools/raylib_parity.py                 # helix-raylib against raylib's own C, each suite against its release (Linux)
python3 tools/format.py --check             # layout
python3 tools/check_docs.py                 # doc comments
python3 tools/gen_apidoc.py                 # remake each library's api/ after a doc comment changes (--check in the tests)
python3 tools/gen_raylib.py                 # remake helix-raylib's Raylib.hx, Raymath.hx, Rlgl.hx and extras/*.hx after a section changes (--check in the tests)
```

A check reports what ran, on which target. Nothing is called faster or smaller until it is measured (`tools/measure_sizes.py`,
`tools/compare/compare.py`).

## Windows, sound and the machine

- A native check that opens a window runs on a private display (`tools/private_display.py`), never on the desktop: a new window takes
  the keyboard focus. `--desktop` runs on the real display, for timing, when the person says the machine is free.
- `SDL_AUDIO_DRIVER=dummy` keeps native checks silent. The browser checks run Chromium with `--mute-audio`.
- A native program that may open a URL runs without `DBUS_SESSION_BUS_ADDRESS`, or it opens the desktop's browser.
- Each checkout's builds take its own `build/.lock`. A tool that takes the lock itself (`tools/compare/compare.py`) is never run under
  it.
- A timing run needs a quiet machine: no other builds, a load average under 2, and the reference contender in the same run as the
  control. A run whose control moved is discarded.

## Unattended work

- One worktree an agent, beside the checkout, with its own copy of `build/haxelib`. Main's index is then nobody else's. In a shared
  checkout, a commit names its paths (`git commit -- <paths>`), since a plain commit takes whatever another has staged.
- Watch, don't wait. Nothing gates all work on one background task. Its log is read early, a watcher reports its steps, and the person
  following along gets a status line every ten minutes, each starting with the Eastern time.
- Check the homework. An agent's report is a claim: read its diff, run the checks it names, and when a task went to two agents,
  compare their branches.

## Publishing

Ask before pushing, opening a pull request, creating a repository or publishing a package. Commits carry no attribution lines.

## Builds

A build is named `<platform>-<config>-<backend>[-<option>...][-<sanitizer>]`, each part from a fixed list, so a name says what was
built and where it is (`tools/variants.py` holds the lists).

- **platform:** what the program links against, this machine's for a native build: `linux-x64`, `linux-arm64`, `macos-arm64`,
  `macos-x64`, `windows-x64-msvc` (hxcpp's default on Windows; `windows-x64-mingw` would be MinGW's, not supported yet), and `js` for
  the browser.
- **config:** `debug` or `release`. `release` is what ships: full dead-code elimination, the analyzer's optimizations, Terser in the
  browser. `debug` finds faults: Haxe's `-debug` (a source map in the browser; natively hxcpp's debug runtime with stack lines and null
  checks), the standard dead-code elimination, no optimizer, and the adapters' C unoptimized with its assertions and sokol_gfx's
  validation on.
- **backend:** always named, never implied by the platform: the exact API the build draws with, `webgl2`, `sdl3-gl`, `sdl3-gpu`.
  `sdl3-gl` draws with sokol_gfx on GL. `sdl3-gpu` is SDL_GPU, whose driver (Vulkan, Direct3D 12, Metal) SDL picks as the program
  starts; a program chooses it by constructing `Sdl3GpuGraphicsAdapter` (`-D sdl_gpu` in the platform's examples). WebGPU's, when it
  comes, is `webgpu`. A `headless` backend (no window or GPU, for tests) is to come; none exists yet.
- **options**, then a **sanitizer**, in that order: a name only adds, never `-noX`. None exists yet.

## Tools

- **A tool reads Haxe as the compiler describes it,** `haxe -xml` or a macro run in the compile, never by matching its text. The
  compiler resolves types, parameters, metadata and doc comments as the code means them, where a pattern breaks on the next arrow or
  generic it didn't foresee. `tools/gen_raylib.py` reads helix-raylib's sections so, with a macro (`tools/haxe/Fields.hx`) for the macro
  functions `-xml` leaves out. A tool still matching text is changed when it is next touched.
- **Shaders are read the same way.** What a stage declares (its blocks, uniforms, attributes, textures) comes from the shader compiler's
  reflection, and its includes from the compiler's include mechanism, never from matching the GLSL's text. A library naming its own
  blocks for every shader shares them where the compiled shader declares them (`ShaderSharedBlock.whereDeclared`).
- **Tools are named for what they are:** a runnable tool is verb_noun, words apart by underscores (`check_types.py`,
  `measure_sizes.py`). A `check_` tool only reports, a `gen_` tool makes files (committed ones), the rest do what they say. Every tool
  answers `--help` with its usage from its docstring (a Node tool's leading comment), does nothing else then, and refuses an argument
  it doesn't take (`tools/cli.py`). A module the tools import says so when it is run, and is named for what it holds, a plain noun that
  can't read as a verb (`variants.py`, `pins.py`). Front doors keep their noun (`helix.py`). This table names every tool, and
  `tools/check_tools.py` checks all of it.
- **What a program runs is Haxe,** on a library's class path under `helix.<library>.tools` (`helix.platform.tools.ShaderCompiler`), run
  in the compiler or its interpreter, so a program needs no Python, and nothing of the tools is compiled into a program. A library's
  examples build from hxml files beside them. Python and Node are the repository's own checks, never in a user's path.

| Tool | What it does |
|---|---|
| `helix.py` | The front door: `test [--native] [--audio-device]` runs the tools' checks, each library's tests on the interpreter and Node, the shader compiler's tests, Trig's bits across targets, and with `--native` the libraries' tests in hxcpp and the platform's native C tests |
| `tools/check_adapters.py` | The adapter rule (docs/ARCHITECTURE.md) on `libs/platform/src/helix/platform` and its adapters |
| `tools/check_docs.py` | Every public type and member has a doc comment; nothing but DECISIONS.md and AGENTS.md names the earlier frameworks |
| `tools/check_layers.py` | Each library names only itself and what it's built on, and no library reaches an engine; the platform's interfaces don't know each other |
| `tools/check_names.py` | 2D and 3D named apart, counts and indices named as such (docs/CONVENTIONS.md) |
| `tools/compare/compare.py` | helix-raylib's speed and size against raylib C, Godot, three.js, Lime and helix-legacy on the same programs (`tools/compare/contenders`), pages in headless Chromium and native programs on a private display or the desktop; `--write` keeps `docs/speed.json` and `docs/speed.md`'s tables |
| `tools/compare/page.cjs` | One page run in headless Chromium on the GPU, ANGLE over Vulkan or GL, printing the program's JSON line and the files fetched (run by `compare.py`) |
| `tools/check_tools.py` | Every tool answers `--help`, refuses an argument it doesn't take, and is in this table |
| `tools/check_types.py` | Every entry point type-checked on its targets (`--web`: the browser alone) |
| `tools/cli.py` | The Python tools' argument parsing (a module) |
| `tools/cli.cjs` | The Node tools' argument parsing (a module) |
| `tools/format.py` | haxe-formatter over the libraries (`--check` only checks) |
| `tools/gen_apidoc.py` | The API reference from the doc comments: each library's `api/` (committed) and `build/api` (`--check`) |
| `tools/pages.py` | The GitHub Pages site in `build/site`: the API reference's HTML at `api/`. The pages workflow deploys it |
| `tools/gen_raylib.py` | helix-raylib's `Raylib.hx`, `Raymath.hx`, `Rlgl.hx` and the `extras` modules: forwards to each function of its sections (`engines/raylib/src/helix/raylib/modules`, read through `haxe -xml`), by section (`--check`) |
| `tools/measure_sizes.py` | Each library's and engine's web size ladder (`<directory>/tests/sizes`) against `docs/sizes.json` (`--write`, `--check`), and with `--check` what each rung links against what its `@:adds` declares |
| `tools/native_build.py` | hxcpp's environment for the adapters' C, and the platform's C-only tests built with CMake (a module) |
| `tools/page_check.cjs` | A page in headless Chromium: its errors, its result and a screenshot (run by `platform_checks.py`) |
| `tools/pins.py` | The repository's haxelib: dev links to the libraries and the pinned hxcpp (a module) |
| `tools/platform_checks.py` | The platform's examples and graphics tests on the GPU, natively on a private display and in Chromium |
| `tools/render_checks.py` | helix-render's examples and pixel tests on the GPU, natively (GL and SDL_GPU) on a private display and in Chromium (WebGL2) |
| `tools/services_checks.py` | The services' examples on the platform's real adapters, natively on a private display and in Chromium |
| `tools/private_display.py` | A private X display for native windows in checks (a module) |
| `tools/raylib_parity.py` | helix-raylib against raylib's own C (`engines/raylib/parity`): each suite's C reference built against its raylib release (fetched, pinned by sha256, built into `build/raylib`), run on a private display beside helix-raylib's |
| `tools/remote_windows.py` | This checkout built and checked on a Windows machine over ssh |
| `tools/sdl3.py` | The SDL3 library a native build links: the system's, or the pinned release made into `build/deps` |
