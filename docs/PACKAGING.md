# Tools, autopilot and a possible haxelib

The useful package boundary is the Haxe framework API and utilities, with separately selected platform adapters. A game depends on host/graphics/input services and shared asset/audio resource policy. `IFetch`, `IStorage` and `IAudio` supply replaceable mechanisms; browser externs and native bindings belong underneath them. Native compiles Haxe through hxcpp and links a thin Sokol layer plus Linux evdev gamepad support. SDL3 is a candidate for graphics/window/input/gamepad/audio adapters, not an implemented dependency. A haxelib can include native sources/tools as well as Haxe; packaging does not remove that glue. See the [official package guide](https://lib.haxe.org/documentation/creating-a-haxelib-package/).

## What exists and was tested

`src/helix/` contains contracts, input accumulation, path validation, asset cache policy, cooperative callback queues, audio resource/playback lifetimes, PCM/WAV utilities and JSON autopilot. It imports no Asteroids, adapters or generated shader types. `examples/asteroids/src/` contains game/menu/renderer/atlas/sound policy. Adapters implement the same contracts; tiny target launchers select explicitly named profiles from `src/helix/profiles/` and inject `IHost`. Framework/game contain zero target conditionals. Canonical WAV validation/decoding is Haxe; Ogg/Vorbis and Opus decoding stays under IAudio: browser Web Audio or native libsndfile through a small C bridge. Sokol C supplies graphics/events/PCM delivery, while browser audio/fetch/storage stay in browser APIs. Native package consumption must supply libsndfile/codec dependencies and preserve the recorded LGPL SDK/library notices; the decoder is not shipped in browser Wasm.

`tests/consumer/PackageSmoke.hx` is a separate consumer compiled and executed with only the framework and test classpaths under the Haxe interpreter and JS/Node. It checks reusable input and autopilot behavior and type-checks the service contracts. Asteroids itself ran against both real adapters. This proves a source boundary; it does not prove installation of a packaged backend into another game. No `haxelib.json`, global dev registration, package archive or publication has been created.

The first graphics contract deliberately retains one fixed vertex layout and generated shader. `GeneratedLayout`/`GeneratedShader` belong to the application build, so the current adapters need that build output. Generalizing shader injection and testing an installed-package consumer comes before a reusable backend package. Avoid expanding the API into a new general GPU framework merely to make packaging look complete.

## Build front door

Use HXML for Haxe compiler settings and Python for external-tool orchestration. The checked-in `examples/asteroids/web.hxml`/`examples/asteroids/native.hxml` describe classpaths, target, DCE and analyzer settings. Python coordinates sokol-shdc, structured metadata generation, original asset generation, hxcpp (which compiles the native adapters' C with each app, against that app's generated shader), Terser and measurements. It passes argument lists, with no shell-script dependency. The [Haxe HXML documentation](https://haxe.org/manual/compiler-usage-hxml.html) describes the compiler's own configuration format.

From the study root:

```console
python3 experiments/05-hybrid-asteroids/helix.py build all --shdc /path/to/sokol-shdc
python3 experiments/05-hybrid-asteroids/helix.py test --native --shdc /path/to/sokol-shdc
python3 experiments/05-hybrid-asteroids/helix.py services --browser /path/to/chromium --native
python3 experiments/05-hybrid-asteroids/helix.py audio-check --browser /path/to/chromium
python3 experiments/05-hybrid-asteroids/helix.py serve
python3 experiments/05-hybrid-asteroids/helix.py check --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
python3 experiments/05-hybrid-asteroids/helix.py measure --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
python3 experiments/05-hybrid-asteroids/helix.py sizes
python3 experiments/05-hybrid-asteroids/helix.py report
python3 experiments/05-hybrid-asteroids/helix.py features --clang /path/to/clang --wgrender /path/to/wgrender-c --libwgf /path/to/libwgf
```

`audio-check` requires `serve` in another terminal and verifies the served build plus sustained thrust/gain/release behavior. Run it after a game rebuild before generating the report. `measure` runs correctness, three CPU trials per target and autopilot sequentially, restores any authorized display override, then generates sizes/findings. It requires both targets. Run `test --native --audio-device`, `services --browser ... --native` and the optional Clang reference `features` inventory beforehand for report inputs: report validates native/audio/cache source identities. Keep timing separate from builds/service tests. `features` reads reference public headers through structured Clang JSON AST, records identities, and does not edit references or establish behavioral equivalence. See FEATURE_PARITY.md. `check` can run browser only. `sizes`/`report` use existing builds/results and do not rebuild. Build before measuring source changes. Native execution/linking is Linux only; Python/Haxe tooling uses portable process/path APIs. X11 checks are platform-specific test adapters.

An optional Haxe entry point delegates to the same Python CLI:

```console
haxe --cwd experiments/05-hybrid-asteroids --run Run --help
haxe --cwd experiments/05-hybrid-asteroids --run Run build web --shdc /path/to/sokol-shdc
```

`Run.hx --help` was executed successfully. `HELIX_PYTHON` selects a Python executable; defaults are `python` on Windows and `python3` elsewhere. The launcher is outside the game/library classpaths. A future package could expose a `haxelib run` entry point through its metadata, as described in the official package guide; that integration has not been built or tested. Rewriting the orchestration in Haxe now would replace working tooling without changing runtime delivery size.

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
python3 experiments/05-hybrid-asteroids/helix.py autopilot all --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority
python3 experiments/05-hybrid-asteroids/helix.py autopilot web --browser /path/to/chromium --script autopilot/smoke.json
```

The full `playthrough.json` passed on browser WebGL2 and native Sokol in 4584 simulated ticks, with identical command outcomes, final state and RGB pixels. It covers title, start, thrust/fire, game over, return to title and restart. The interpreter also exercises the same script. Fast mode advances up to 120 fixed ticks per frame; its wall time is a correctness convenience, not a performance result. These automated runs disable sound delivery; separate interactive/service checks exercise audio.

Manual browser use: `?autopilot=autopilot/playthrough.json&fast=1&audio=0`. Native: `HELIX_AUTOPILOT=autopilot/playthrough.json`, `HELIX_FAST=1`, `HELIX_AUDIO=0`. `helix.py serve` makes the packaged scripts available. Direct `autopilot` never changes display settings and rejects `--awake`; `measure --awake` owns the entire override/restore lifecycle.

## Recommendation

Proceed toward a Haxe library with platform adapters. Keep application code outside it and choose adapters in build configuration. Keep the Python front door now, with the optional Haxe launcher for convenience. Neither tool contributes runtime bytes to the delivered game.

Before making a distributable haxelib: choose license/version policy; stabilize lifecycle and handle contracts; define shader generation and native build integration for consumers; decide how Sokol/SDL versions are supplied; and build an independent application against an installed local package. Modern native adapters, further OS targets and context/device recovery still require execution. The measured source separation is a promising foundation, not a completed production package.

The distinct mixed-submission workload now consumes the same graphics/host interfaces and both adapters from source. It reuses the fixed generated shader/layout; it does not prove shader injection or an installed haxelib package. Its reproduction and identified evidence are in [MIXED_SUBMISSIONS.md](MIXED_SUBMISSIONS.md). Native host and graphics share one Sokol context through separate C translation units in their respective `src/helix/adapters/<service>/sokol/internal/` directories. Audio/codecs/gamepads likewise own their C sources, headers and extern bindings. Shared Linux archive/link metadata lives in `adapters/internal/SokolNativeBuild.hx`; independently installed native service packages and additional OS link integration remain untested.


## P1 tooling and shipped scope

`helix.py mixed build/check/measure/profile/allocations/report` drives the separate range/material workload. Its normal browser/native artifacts contain no allocation telemetry or GL interposer. `benchmarks/mixed-submission/native-profile.hxml` selects an independent native test launcher with `HXCPP_TELEMETRY` and `HXCPP_STACK_TRACE`; `tests/native/graphics_calls.c` builds a Linux-only check library loaded by the native audit. Profiling, call auditing and CPU timing run in separate processes. These tools do not add Wasm or bytes to Asteroids. See [MIXED_SUBMISSIONS.md](MIXED_SUBMISSIONS.md) for portable command orchestration, actual executed evidence and remaining shader/package limitations.


The latest P1 result is conditional for native GL: sorted cases meet the recorded callback budget, but the 4096-draw/64-texture alternating case exceeds 16.667 ms callback p95 in two trials. Browser shared-state/program cases fit on this device. The typed-command correction removes allocation scaling, but does not establish a native timing speedup. Transparent order cannot be freely sorted; sustained unsorted pressure and an executed modern native backend remain decision gates. See [the P1 findings](MIXED_SUBMISSIONS.md) for ranges and exact boundaries.
