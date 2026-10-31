# Building

## Prerequisites

To use the libraries:

- **Haxe 4.3.7.** Enough for the browser, and for writing shaders: the platform's shader compiler fetches glslang and SPIRV-Cross into
  the user's cache the first time.
- **Natively:** hxcpp 4.3.2 (`dependencies.json`'s pin), the C/C++ compiler it drives, and SDL3: `tools/sdl3.py` finds or makes the
  pinned release into `build/deps` for this repository; a program elsewhere names the library with `HELIX_SDL3_LIBRARY`. On Linux, SDL
  loads X11/Xrandr/Xi/Xcursor and GL for the window and graphics, and ALSA or PulseAudio for audio.

To develop them, also:

- **Python 3** for the checks and tools in `tools/`, standard library only.
- **Node** with Playwright (Chromium) for the browser checks (`tools/platform_checks.py`); installed into `build/tools`.
- **CMake** for the platform's native C tests (`platform/tests/native/CMakeLists.txt`, built by `helix.py test --native` with the
  compiler hxcpp uses), and on Linux to build SDL3 when the system has none.

The repository keeps its own haxelib in `build/haxelib`: a dev link to each library, the pinned hxcpp and the formatter, made by the
tools as they run (`tools/pins.py`).

## Checks

```console
python3 helix.py test                       # the tools' checks, the size ladders, each library's tests, Trig's bits across targets
python3 helix.py test --native              # also each library's tests in hxcpp and the platform's native C tests
python3 tools/check_types.py --no-output    # type-check every entry point of every library on its targets
python3 tools/platform_checks.py --browser <chromium>   # the platform's examples and GPU tests, natively on a private display and in Chromium
python3 tools/services_checks.py --browser <chromium>   # the services' examples, natively on a private display and in Chromium
python3 tools/format.py --check             # layout
python3 tools/check_docs.py                 # doc comments
python3 tools/gen_apidoc.py                 # remake docs/api after a doc comment changes (--check in the tests)
python3 tools/gen_raylib.py                 # remake helix-ray's Raylib.hx, Raymath.hx and Rlgl.hx after a section changes (--check in the tests)
```

Native checks that open a window run on a private display (`tools/private_display.py`), never on the user's desktop. `SDL_AUDIO_DRIVER=dummy`
keeps them silent; the browser checks run Chromium with `--mute-audio`.

## Tools

| Tool | What it does |
|---|---|
| `helix.py` | The front door: `test [--native] [--audio-device]` runs the tools' checks, each library's tests on the interpreter and Node, the shader compiler's tests, Trig's bits across targets, and with `--native` the platform's C tests |
| `tools/check_adapters.py` | The adapter rule (docs/ARCHITECTURE.md) on `platform/src/helix/platform` and its adapters |
| `tools/check_docs.py` | Every public type and member has a doc comment; nothing but DECISIONS.md and AGENTS.md names the earlier frameworks |
| `tools/check_layers.py` | Each library names only itself and what it's built on; the platform's contracts don't know each other |
| `tools/check_names.py` | 2D and 3D named apart (docs/CONVENTIONS.md) |
| `tools/check_tools.py` | Every tool answers `--help`, refuses an argument it doesn't take, and is in this table |
| `tools/check_types.py` | Every entry point type-checked on its targets (`--web`: the browser alone) |
| `tools/cli.py` | The Python tools' argument parsing (a module) |
| `tools/cli.cjs` | The Node tools' argument parsing (a module) |
| `tools/format.py` | haxe-formatter over the libraries (`--check` only checks) |
| `tools/gen_apidoc.py` | The API reference from the doc comments: `docs/api` (committed) and `build/api` (`--check`) |
| `tools/gen_raylib.py` | helix-ray's `Raylib.hx`, `Raymath.hx` and `Rlgl.hx`: forwards to each function of its sections (`ray/src/helix/ray/raylib`, read through `haxe -xml`), by raylib's modules, and the refusals of what helix-ray won't or doesn't yet have (`--check`) |
| `tools/measure_sizes.py` | Each library's web size ladder (`<library>/tests/sizes`) against `docs/benchmarks.json` (`--write`, `--check`) |
| `tools/native_build.py` | hxcpp's environment for the adapters' C, and the platform's C-only tests built with CMake (a module) |
| `tools/page_check.cjs` | A page in headless Chromium: its errors, its result and a screenshot (run by `platform_checks.py`) |
| `tools/pins.py` | The repository's haxelib: dev links to the libraries and the pinned hxcpp (a module) |
| `tools/platform_checks.py` | The platform's examples and graphics tests on the GPU, natively on a private display and in Chromium |
| `tools/services_checks.py` | The services' examples on the platform's real adapters, natively on a private display and in Chromium |
| `tools/private_display.py` | A private X display for native windows in checks (a module) |
| `tools/remote_windows.py` | This checkout built and checked on a Windows machine over ssh |
| `tools/sdl3.py` | The SDL3 library a native build links: the system's, or the pinned release made into `build/deps` |

## Layout

```
math/ log/ formats/ platform/ services/ ray/   the libraries: haxelib.json, README.md, src/, tests/ (and examples/, vendor/)
tools/                                         the repository's checks and helpers, never shipped
docs/                                          the plan, the specs, conventions, architecture, the API reference and the benchmarks
build/                                         scratch: the repository's haxelib, SDL3, hxcpp's output (ignored)
```
