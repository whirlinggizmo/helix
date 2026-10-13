# HeliX

HeliX is a Haxe game framework. One Haxe program runs in the browser (Haxe → JS, WebGL2, Web Audio, Fetch, IndexedDB) and on the desktop (Haxe → hxcpp/C++, Sokol, libsndfile, evdev). Games use the same Haxe interfaces on both. Thin adapters supply each platform's services underneath them; a named profile picks the adapters for a build. Framework and game code have no target conditionals.

Status: milestones 1 (the platform, 2D and services) and 2 (3D basics: immediate 3D, stages of lit models, materials, lights, glTF models) are complete; milestone 3 (2D gfx) is under way. Every example below runs in the browser and natively on Linux/X11. Windows, macOS and mobile have not run.

> **Work in progress: caveat emptor.** HeliX is not yet stable, and backward compatibility is not a consideration. Any API, name or file layout may change in any commit, with every caller in this repository changed alongside and no deprecation period. There are no releases or versions to pin yet. If you build on it, pin a commit and expect to update your code when you move.

## Layout

```text
src/helix/                 the framework: contracts, policy, render2d, render3d, math, input, audio, assets
  adapters/<service>/<provider>/           Haxe adapters; internal/ holds their C glue and externs
  profiles/                BrowserWebGL2Profile, NativeSokolGLProfile
examples/<name>/App.hx      the catalog: one feature each, sharing examples/shared/launch and examples/assets
examples/asteroids/src/     larger examples: whole games, built the same way, with autopilot scripts
examples/blocks/src/
tests/                    unit (Haxe interpreter), services (both targets), native, consumer, shader checks
tools/                    example/build/check/format/doc tools (Python, some Node)
docs/                     CONVENTIONS, INTERFACE, DECISIONS, API_FINDINGS, PACKAGING
vendor/                   pinned third-party headers, fonts and their licenses
helix.py / Run.hx          front door for the tests and the services checks
build/                    ignored: generated code, builds, caches, check output
```

## Prerequisites

Executed on Linux:
- **Haxe 4.3.7.**
- **hxcpp 4.3.2.** Installed on the first native build into the repository's own `build/haxelib`, so the global haxelib is untouched. `tools/pins.py` stops a native build that would resolve another version.
- **Python 3.12** with PyYAML (`python3 -m pip install -r requirements-build.txt`).
- **FFmpeg** with the libvorbis and libopus encoders, for the test fixtures and Asteroids' sounds.
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
  - the Sokol headers, from the Whirling Gizmo fork [whirlinggizmo/sokol](https://github.com/whirlinggizmo/sokol) at `c237609` (upstream to `5e94d12`)
  - [whirlinggizmo/sokol_utils](https://github.com/whirlinggizmo/sokol_utils) at `8e85d19` (window position, size, displays, style and visibility)
  - stb_image
  - JetBrains Mono, baked into the built-in distance-field font by `tools/fontbake.py` (HeliX's own TrueType reader and baker, under the Haxe interpreter)

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
| `hello3d` | an orbiting 3D camera, depth-tested shapes and lines, a 2D overlay |
| `meshes` | generated meshes on a `Stage3D`: lit, instanced models with glTF materials |
| `materials` | metallic-roughness steps, unlit, emissive, a normal map, see-through; a sun and a point light |
| `lights` | directional, point and spot lights on a stage, beside an immediate grid |
| `model` | a glTF (GLB) model loaded into nodes: parts found by name, its own lights |
| `sprite2d` | sprites on a `Stage2D`: a sheet's regions, pivots, rotation, a mirror, a tint, hovering by `toLocalX` |
| `stage2d` | a world stage through a zooming camera and a HUD stage, in one batch: shapes, a sprite, text, a turning group |
| `textures` | one texture drawn smooth then sharp (sampling per draw); `name.ktx` loading this GPU's compressed variant (BC7, ASTC, ETC2) or the PNG |
| `font` | TrueType fonts loaded and baked into distance fields in Haxe: a measured, centered title, several sizes, kerning |
| `tilemap` | a scrolling, zooming tile map of sprites cut from one sheet, culled to the view; props on their pivots, coins hovered and collected |
| `render-target` | drawing into textures: a low-resolution pixel view, an orthographic minimap, a text label worn by a globe |

Still to come: milestones 3–6 (2D gfx; advanced 3D: shadows, environments, instancing, particles, 3D sprites and text, skinning and animation; scene and pick; UI). `ecs-scene` waits on the game model. A Clay-style UI is deferred.

## Larger examples: Asteroids and Blocks

Both are whole games, built and developed like every other example, on HeliX's own 2D API, `Ticker` and shared launchers. Each has autopilot scripts that must end in the same game on both targets.

- **Asteroids** (`examples/asteroids`): menus, flight, splitting rocks, waves, Ogg sound, keyboard/pointer/gamepad, letterboxed with a camera viewport area.
- **Blocks** (`examples/blocks`): falling blocks, with keyboard, gamepad and touch.

```console
python3 tools/example.py asteroids dev
python3 tools/example.py blocks autopilot --browser /path/to/chromium --shdc /path/to/sokol-shdc
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

- **Unit tests** run under the Haxe interpreter: input, host and frame timing, WAV and asset paths, 3D math, trigonometry, Blocks and the Asteroids simulation. `helix.math.Trig` must also give the same bits in JS and, with `--native`, in hxcpp.
- **`services`** runs the asset, storage, fetch and audio services on both targets against local HTTP fixtures.
- **Autopilot** (`tools/example.py <name> autopilot`) replays an example's scripts in a headless browser and natively, and requires the same final game.
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
