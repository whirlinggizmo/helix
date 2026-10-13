# HeliX

HeliX is a Haxe game framework. One Haxe program runs in the browser (Haxe → JS, WebGL2, Web Audio, Fetch, IndexedDB) and on the desktop (Haxe → hxcpp/C++, Sokol, libsndfile, evdev). Games use the same Haxe interfaces on both. Thin adapters supply each platform's services underneath them; a named profile picks the adapters for a build. Framework and game code have no target conditionals.

Status: milestone 1 (the platform, 2D and services) is complete. Every example below runs in the browser and natively on Linux/X11. 3D comes next. Windows, macOS and mobile have not run.

## Layout

```text
src/helix/                 the framework: contracts, policy, render2d, input, audio, assets
  adapters/<service>/<provider>/           Haxe adapters; internal/ holds their C glue and externs
  profiles/                BrowserWebGL2Profile, NativeSokolGLProfile
examples/<name>/App.hx      the catalog: one feature each, sharing examples/shared/launch and examples/assets
examples/asteroids/         larger examples: whole games, with their own launchers, autopilot scripts and checks
examples/blocks/
tests/                    unit (Haxe interpreter), services (both targets), native, consumer, shader checks
tools/                    example/build/check/format/doc tools (Python, some Node)
docs/                     CONVENTIONS, INTERFACE, DECISIONS, API_FINDINGS, PACKAGING
vendor/                   pinned third-party headers, fonts and their licenses
helix.py / Run.hx          front door for Asteroids, the tests and the services checks
build/                    ignored: generated code, builds, caches, check output
```

## Prerequisites

Executed on Linux:
- **Haxe 4.3.7.**
- **hxcpp 4.3.2.** Installed on the first native build into the repository's own `build/haxelib`, so the global haxelib is untouched. `tools/pins.py` stops a native build that would resolve another version.
- **Python 3.12** with PyYAML (`python3 -m pip install -r requirements-build.txt`).
- **Node 26**, with Terser, Playwright and pngjs for release builds and browser checks:
  ```console
  npm install --prefix build/tools terser@5.44.1 playwright@1.64.0 pngjs@7.0.0
  ```
- **The dev loop:** [hotreload-hx](https://github.com/whirlinggizmo/hotreload-hx) at `8df4871` or later (`haxelib git hotreload-hx https://github.com/whirlinggizmo/hotreload-hx`).
- **The shader compiler:** `sokol-shdc` from sokol-tools-bin `11d0cf678105d614d675e6d9bd2aaf3eeff12f8c`. Pass it with `--shdc` or `SOKOL_SHDC`. Nothing is downloaded or installed globally.
- **Native builds:**
  - GCC/G++ 13 and ALSA headers.
  - X11/Xi/Xcursor and GL libraries.
  - The libsndfile 1.2.2 runtime with Vorbis/Opus and mpg123 (MP3). Its header is vendored.
  - No CMake: hxcpp compiles the adapters' C with each app.
- **Pinned in `vendor/`, hashes in `dependencies.json`:**
  - the Sokol headers, from the Whirling Gizmo fork [robknopf/sokol](https://github.com/robknopf/sokol) at `1b0a77a` (upstream to `5e94d12`)
  - [robknopf/sokol_utils](https://github.com/robknopf/sokol_utils) at `d997b35` (window position, size, displays, style and visibility)
  - stb_image and stb_truetype
  - JetBrains Mono, baked into the built-in distance-field font by `tools/fontbake`

Third-party licenses, and what builds ship with: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Example asset credits: [examples/assets/CREDITS.md](examples/assets/CREDITS.md).

## Develop an example

Work happens in the browser with hot reload: edit, save, and the running page takes the new code (or the changed asset, shader or font) without restarting.

```console
python3 tools/example.py app-hello dev            # hotreload-hx dev server, http://localhost:8060/
python3 tools/example.py app-hello build web      # build/web/app-hello/
python3 tools/example.py app-hello build native   # build/native/app-hello/Main
```

The catalog follows the earlier C frameworks' example names. Each example matches the feature, not the original's scene.

| Example | Shows |
|---|---|
| `app-skeleton` | a window cleared each frame |
| `app-hello` | shapes and text |
| `app-tick` | a fixed-rate simulation, time scale and the tick fraction |
| `app-window` | window size, position, fullscreen and displays (get/set/can/request) |
| `app-gamepad` | four pads in the W3C standard layout |
| `app-touch` | two-finger pan, pinch and twist; images and mipmaps |
| `audio-music` | streamed music and decoded clips, with play state |
| `asset-fetch` | assets from a host, the cache, and asking whether a host answers |
| `asset-force-fetch` | ensure with a source and past the cache |
| `quit` | quitting mid-load: shutdown runs after the frame |

Still to come: milestones 2–6, covering gfx and 3D, pick and ui-menu. `ecs-scene` waits on the game model. A Clay-style UI is deferred.

## Larger examples: Asteroids and Blocks

Both are whole games. They are examples like the rest, and each brings its own regression checks.

- **Asteroids** (`examples/asteroids`): menus, flight, splitting rocks, waves, Ogg sound, keyboard/pointer/gamepad. Its checks compare browser and native images and replay an autopilot script on both.
  ```console
  python3 helix.py build all --shdc /path/to/sokol-shdc
  python3 helix.py serve                          # http://127.0.0.1:8050/
  python3 helix.py check --browser /path/to/chromium --display :1 --xauthority ~/.Xauthority
  ```
- **Blocks** (`examples/blocks`): falling blocks on HeliX's own 2D API, with keyboard, gamepad and touch. Its autopilot must end in the same game on both targets.
  ```console
  python3 tools/blocks.py dev --shdc /path/to/sokol-shdc
  python3 tools/blocks.py autopilot --browser /path/to/chromium --display :1 --xauthority ~/.Xauthority
  ```

## Checks

```console
python3 tools/typecheck.py --no-output    # every entry point, both targets, in seconds
python3 tools/format.py --check           # haxe-formatter, pinned
python3 tools/doccheck.py                 # public API without a doc comment
python3 tools/apidoc.py                   # the API reference, build/api/index.html
python3 helix.py test --native --shdc /path/to/sokol-shdc
python3 helix.py services --browser /path/to/chromium --native
```

- **Unit tests** run under the Haxe interpreter: input, Blocks, the Asteroids simulation, host and identity.
- **`services`** runs the asset, storage, fetch and audio services on both targets against local HTTP fixtures.
- **Native window checks** run on a private Xvfb display (`tools/private_display.py`), never on the desktop in use.

## Documents

- [CONVENTIONS.md](docs/CONVENTIONS.md): names, units, layout, and how examples are developed.
- [INTERFACE.md](docs/INTERFACE.md): the contracts and their limits.
- [DECISIONS.md](docs/DECISIONS.md): why things are the way they are, in order.
- [API_FINDINGS.md](docs/API_FINDINGS.md): known API problems, fixed and open.
- [PACKAGING.md](docs/PACKAGING.md): tooling, autopilot and the road to a haxelib.

## License

MIT: [LICENSE](LICENSE). Third-party code, fonts and assets keep their own licenses: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

HeliX began as experiment 05 of whirlinggizmo's framework architecture study. That study keeps its comparison and measurements; this repository carries HeliX's history from it.
