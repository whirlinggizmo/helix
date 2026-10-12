# Tools, autopilot and a possible haxelib

The useful package boundary is the Haxe framework API and utilities, with separately selected platform adapters. A game depends on host/graphics/input services and shared asset/audio resource policy. `IFetch`, `IStorage` and `IAudio` supply replaceable mechanisms; browser externs and native bindings belong underneath them. Native compiles Haxe through hxcpp and links a thin Sokol layer plus Linux evdev gamepad support. SDL3 is a candidate for graphics/window/input/gamepad/audio adapters, not an implemented dependency. A haxelib can include native sources/tools as well as Haxe; packaging does not remove that glue. See the [official package guide](https://lib.haxe.org/documentation/creating-a-haxelib-package/).

## What exists and was tested

`prototype/framework/hybrid/` contains contracts, input accumulation, path validation, asset cache policy, cooperative callback queues, audio resource/playback lifetimes, PCM/WAV utilities and JSON autopilot. It imports no Asteroids, adapters or generated shader types. `prototype/src/` contains game/menu/renderer/atlas/sound policy. Adapters implement the same contracts with different classpaths. Framework/game contain zero target conditionals. Canonical WAV validation/decoding is Haxe; Ogg/Vorbis and Opus decoding stays under IAudio: browser Web Audio or native libsndfile through a small C bridge. Sokol C supplies graphics/events/PCM delivery, while browser audio/fetch/storage stay in browser APIs. Native package consumption must supply libsndfile/codec dependencies and preserve the recorded LGPL SDK/library notices; the decoder is not shipped in browser Wasm.

`tests/PackageSmoke.hx` is a separate consumer compiled and executed with only the framework and test classpaths under the Haxe interpreter and JS/Node. It checks reusable input and autopilot behavior and type-checks the service contracts. Asteroids itself ran against both real adapters. This proves a source boundary; it does not prove installation of a packaged backend into another game. No `haxelib.json`, global dev registration, package archive or publication has been created.

The first graphics contract deliberately retains one fixed vertex layout and generated shader. `GeneratedLayout`/`GeneratedShader` belong to the application build, so the current backends need that build output. Generalizing shader injection and testing a second consumer comes before a reusable backend package. Avoid expanding the API into a new general GPU framework merely to make packaging look complete.

## Build front door

Use HXML for Haxe compiler settings and Python for external-tool orchestration. The checked-in `web.hxml`/`native.hxml` describe classpaths, target, DCE and analyzer settings. Python coordinates sokol-shdc, structured metadata generation, original asset generation, CMake, hxcpp, Terser and measurements. It passes argument lists, with no shell-script dependency. The [Haxe HXML documentation](https://haxe.org/manual/compiler-usage-hxml.html) describes the compiler's own configuration format.

From the study root:

```console
python3 experiments/05-hybrid-asteroids/hybrid.py build all --shdc /path/to/sokol-shdc
python3 experiments/05-hybrid-asteroids/hybrid.py test --native --shdc /path/to/sokol-shdc
python3 experiments/05-hybrid-asteroids/hybrid.py services --browser /path/to/chromium --native
python3 experiments/05-hybrid-asteroids/hybrid.py audio-check --browser /path/to/chromium
python3 experiments/05-hybrid-asteroids/hybrid.py serve
python3 experiments/05-hybrid-asteroids/hybrid.py check --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
python3 experiments/05-hybrid-asteroids/hybrid.py measure --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
python3 experiments/05-hybrid-asteroids/hybrid.py sizes
python3 experiments/05-hybrid-asteroids/hybrid.py report
python3 experiments/05-hybrid-asteroids/hybrid.py features --clang /path/to/clang --wgrender /path/to/wgrender-c --libwgf /path/to/libwgf
```

`audio-check` requires `serve` in another terminal and verifies the served build plus sustained thrust/gain/release behavior. Run it after a game rebuild before generating the report. `measure` runs correctness, three CPU trials per target and autopilot sequentially, restores any authorized display override, then generates sizes/findings. It requires both targets. Run `test --native --audio-device`, `services --browser ... --native` and the optional Clang reference `features` inventory beforehand for report inputs: report validates native/audio/cache source identities. Keep timing separate from builds/service tests. `features` reads reference public headers through structured Clang JSON AST, records identities, and does not edit references or establish behavioral equivalence. See FEATURE_PARITY.md. `check` can run browser only. `sizes`/`report` use existing builds/results and do not rebuild. Build before measuring source changes. Native execution/linking is Linux only; Python/Haxe tooling uses portable process/path APIs. X11 checks are platform-specific test adapters.

An optional Haxe entry point delegates to the same Python CLI:

```console
haxe --cwd experiments/05-hybrid-asteroids --run Run --help
haxe --cwd experiments/05-hybrid-asteroids --run Run build web --shdc /path/to/sokol-shdc
```

`Run.hx --help` was executed successfully. `HYBRID_PYTHON` selects a Python executable; defaults are `python` on Windows and `python3` elsewhere. The launcher is outside the game/library classpaths. A future package could expose a `haxelib run` entry point through its metadata, as described in the official package guide; that integration has not been built or tested. Rewriting the orchestration in Haxe now would replace working tooling without changing runtime delivery size.

## Autopilot

Autopilot loads a packaged JSON file through `IAssets`, supplies normal named input through `IInput`, and observes only an explicit `String -> Dynamic` probe callback provided by the app. It drives the same `Controls`, menu and simulation as interactive play. It does not edit game state, inspect private fields or scrape source files. Ordinary `haxe.Json` parsing and `Reflect` field validation are used for the JSON schema; shader reflection remains an unrelated offline build step.

The schema is version 1, with a deterministic seed and up to 128 commands:

```json
{
  "version": 1,
  "seed": 12345,
  "commands": [
    {"op": "press", "key": "ENTER"},
    {"op": "wait", "probe": "state", "equals": "playing", "timeout": 120},
    {"op": "hold", "keys": ["UP", "SPACE"], "ticks": 120},
    {"op": "assert", "probe": "shots", "atLeast": 6}
  ]
}
```

`press` lasts one simulation tick. `hold` specifies a tick count. `wait` has exactly one `equals` or numeric `atLeast` condition and a timeout; optional `keys` remain held while waiting. `assert` checks immediately without advancing time. Durations/timeouts are limited to 36000 ticks per command; unknown fields, commands, key names, duplicates and invalid bounds fail. Asteroids explicitly exposes state, score, best, lives, wave, shots, deaths and hits. Another game can supply different probes while reusing the command runner.

After building:

```console
python3 experiments/05-hybrid-asteroids/hybrid.py autopilot all --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority
python3 experiments/05-hybrid-asteroids/hybrid.py autopilot web --browser /path/to/chromium --script autopilot/smoke.json
```

The full `playthrough.json` passed on browser WebGL2 and native Sokol in 4584 simulated ticks, with identical command outcomes, final state and RGB pixels. It covers title, start, thrust/fire, game over, return to title and restart. The interpreter also exercises the same script. Fast mode advances up to 120 fixed ticks per frame; its wall time is a correctness convenience, not a performance result. These automated runs disable sound delivery; separate interactive/service checks exercise audio.

Manual browser use: `?autopilot=autopilot/playthrough.json&fast=1&audio=0`. Native: `HY_AUTOPILOT=autopilot/playthrough.json`, `HY_FAST=1`, `HY_AUDIO=0`. `hybrid.py serve` makes the packaged scripts available. Direct `autopilot` never changes display settings and rejects `--awake`; `measure --awake` owns the entire override/restore lifecycle.

## Recommendation

Proceed toward a Haxe library with platform adapters. Keep application code outside it and choose backends in build configuration. Keep the Python front door now, with the optional Haxe launcher for convenience. Neither tool contributes runtime bytes to the delivered game.

Before making a distributable haxelib: choose package name/license/version policy; stabilize lifecycle and handle contracts; remove reliance on neighboring study-vendored headers; define shader generation and native build integration for consumers; decide how Sokol/SDL versions are supplied; and build an independent application against an installed local package. Modern native backends, further OS targets and context/device recovery still require execution. The measured source separation is a promising foundation, not a completed production package.
