# Building HeliX

How to build, run and check HeliX and its examples. What HeliX is: [README.md](README.md); the examples: [docs/EXAMPLES.md](docs/EXAMPLES.md).

## Prerequisites

Executed on Linux, Windows 11 and macOS (CI's runners, and a Windows machine: decisions 99–101):
- **Haxe 4.3.7.**
- **hxcpp 4.3.2.** Installed on the first native build into the repository's own `build/haxelib`, so the global haxelib is untouched. `tools/pins.py` stops a native build that would resolve another version.
- **Python 3.12** with PyYAML (`python3 -m pip install -r requirements-build.txt`).
- **FFmpeg** with the libvorbis and libopus encoders, for the test fixtures and Asteroids' sounds.
- **Node 26**, with Terser, Playwright and pngjs for release builds and browser checks:
  ```console
  npm install --prefix build/tools terser@5.44.1 playwright@1.64.0 pngjs@7.0.0
  ```
- **The dev loop:** [hotreload-hx](https://github.com/whirlinggizmo/hotreload-hx) at `f591b94` or later (`haxelib git hotreload-hx https://github.com/whirlinggizmo/hotreload-hx`).
- **The shader compiler:** `sokol-shdc` from sokol-tools-bin `11d0cf678105d614d675e6d9bd2aaf3eeff12f8c`. `tools/shdc.py` downloads it for this system into the user's cache the first time (`~/.cache/helix/tools`, `~/Library/Caches/helix/tools` or `%LOCALAPPDATA%\helix\tools`) and checks its SHA-256 every time it's used; nothing is installed globally.
- **SDL_GPU's shader translators:** glslang 16.6.0 (its official release for the system: Linux x86_64, Windows x64, macOS universal) and SPIRV-Cross `vulkan-sdk-1.4.363.0` (its source, built once by hxcpp with the system's compiler, as it publishes no programs), pinned in `dependencies.json` (`gpuShaders`), fetched into `build/deps` and hash-checked by `tools/gpu_shaders.py` the first time shaders are generated. Only SDL_GPU builds (`native-sdl3-gpu`) run them; other builds, the browser's included, never fetch or build them. There's no Linux arm64 glslang release.
- **Native builds:** no CMake: hxcpp compiles the adapters' C with each app, from the build XML on each adapter's extern bridge (`internal/*Bridge.hx`).
  - Linux: GCC/G++ 13 and ALSA headers; X11/Xrandr/Xi/Xcursor and GL libraries; the libsndfile 1.2.2 runtime with Vorbis/Opus and mpg123 (MP3). Its header is vendored.
  - Windows: Visual Studio's C++ tools (MSVC, which hxcpp finds itself; MinGW isn't supported). libsndfile's official 1.2.2 win64 release is downloaded and hash-checked into the user's cache, and its DLL copied beside each program.
  - macOS: Xcode's command-line tools and Homebrew's `libsndfile`; for FFmpeg, Homebrew's `ffmpeg-full` (its `ffmpeg` has no Vorbis encoder). Apple silicon builds arm64.
  - **The SDL3 profiles** (`native-sdl3`, sokol_gfx drawing GL in SDL's window; `native-sdl3-gpu`, SDL_GPU on Vulkan, Direct3D 12 or Metal): SDL 3.4.18, found or fetched by `tools/sdl3.py` into `build/deps` on its first build. On Linux, the system's SDL3 when pkg-config finds 3.4.18 or newer; else the pinned source release, checked and built once with **CMake** (needed for that build alone) against the X11, Wayland and audio development headers it finds. Missing CMake, or headers enough to open a window, it stops and prints the install command (Debian/Ubuntu's, CI's list; Fedora's, after SDL's `docs/README-linux.md`); missing only optional parts (Wayland, PipeWire, PulseAudio), it builds and says which, and what would add them. On Windows and macOS, SDL's official release, checked, its DLL or framework copied beside each program. The headers are vendored (`vendor/sdl3`).
  - `python3 tools/remote_windows.py HOST` builds and checks this checkout on a Windows machine over ssh; `--desktop` runs in its logged-in session, where windows can open.
- **Pinned in `vendor/`, hashes in `dependencies.json`:**
  - the Sokol headers, from the Whirling Gizmo fork [whirlinggizmo/sokol](https://github.com/whirlinggizmo/sokol) at `c237609` (upstream to `5e94d12`)
  - [whirlinggizmo/sokol_utils](https://github.com/whirlinggizmo/sokol_utils) at `8e85d19` (window position, size, displays, style and visibility)
  - stb_image
  - SDL 3.4.18's headers (`vendor/sdl3`)
  - JetBrains Mono, baked into the built-in distance-field font by `tools/fontbake.py` (HeliX's own TrueType reader and baker, under the Haxe interpreter)

Third-party licenses, and what builds ship with: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Example asset credits: [examples/assets/CREDITS.md](examples/assets/CREDITS.md).


## Build and develop

Work happens in the browser with hot reload: edit, save, and the running page takes the new code (or the changed asset, shader or font) without restarting.

```console
python3 tools/example.py app-hello dev            # hotreload-hx dev server, http://localhost:8060/
python3 tools/example.py app-hello build web      # build/web/app-hello/
python3 tools/example.py app-hello build native   # build/native/app-hello/Main, the sokol profile
python3 tools/example.py app-hello build native-sdl3   # build/native-sdl3/app-hello/Main, the SDL3 profile on GL
python3 tools/example.py app-hello build native-sdl3-gpu   # build/native-sdl3-gpu/app-hello/Main, the SDL3 profile on SDL_GPU
```

SDL_GPU picks its backend (Direct3D 12 on Windows, Metal on macOS, Vulkan elsewhere); `SDL_GPU_DRIVER=vulkan` (or `direct3d12`, `metal`) chooses another. On a machine without a Vulkan GPU, such as the private display, Mesa's software driver runs it: `VK_DRIVER_FILES=/usr/share/vulkan/icd.d/lvp_icd.json` (package `mesa-vulkan-drivers`).

**F9 saves a screenshot** in every example: a download in the browser, natively a PNG in `~/Pictures/<example>/` (or `HELIX_EXPORT`). Autopilot scripts take them too (`{"op": "screenshot"}`).

Examples, their files and how each one is run: [docs/EXAMPLES.md](docs/EXAMPLES.md).

## Checks


```console
python3 tools/typecheck.py --no-output    # every entry point, both targets, in seconds
python3 tools/format.py --check           # haxe-formatter, pinned
python3 tools/doccheck.py                 # public API without a doc comment
python3 tools/apidoc.py                   # the API reference, build/api/index.html
python3 helix.py test --native
python3 helix.py services --browser /path/to/chromium --native
```

- **Unit tests** run under the Haxe interpreter: input, host and frame timing, WAV and asset paths, 3D math, trigonometry, Blocks and the Asteroids simulation. `helix.math.Trig` must also give the same bits in JS and, with `--native`, in hxcpp.
- **`services`** runs the asset, storage, fetch and audio services on both targets against local HTTP fixtures; `--native-profile sdl3` plays natively through SDL3's audio (its dummy driver) instead of sokol's.
- **Autopilot** (`tools/example.py <name> autopilot [native-sdl3|native-sdl3-gpu]`) replays an example's scripts in a headless browser and natively (the sokol profile, or an SDL3 one), and requires the same final game.
- **Native window checks** run on a private Xvfb display (`tools/private_display.py`), never on the desktop in use.


## Layout

## Layout

```text
src/helix/                 the framework: contracts, policy, render2d, render3d, math, input, audio, assets
  adapters/<contract>/<api>/   one platform API behind one contract (<Api><Contract>Adapter); internal/ holds C glue and externs
  profiles/                BrowserWebGL2Profile, NativeSokolGLProfile
examples/<name>/App.hx      the catalog: one feature each, sharing examples/shared/launch and examples/assets (built once a target, build/<target>/assets)
examples/asteroids/src/     larger examples: whole games, built the same way, with autopilot scripts
examples/blocks/src/
tests/                    unit (Haxe interpreter), services (both targets), native, consumer, shader checks
tools/                    example/build/check/format/doc tools (Python, some Node)
docs/                     EXAMPLES, ROADMAP, HISTORY, ARCHITECTURE, INTERFACE, CONVENTIONS, DECISIONS, API_FINDINGS, ADAPTER_AUDIT, PACKAGING
vendor/                   pinned third-party headers, fonts and their licenses
helix.py / Run.hx          front door for the tests and the services checks
build/                    ignored: generated code, builds, caches, check output
```

