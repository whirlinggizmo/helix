# Experiment 05 — HeliX Asteroids

One Haxe game and renderer, direct browser WebGL2 and native hxcpp/Sokol. The build selects a small service composition profile with classpaths; framework and game contain **zero target conditionals**. Separate graphics, input, audio, fetch and storage contracts sit beneath shared asset/cache and audio resource/playback policy. No Lime/OpenFL, browser Wasm or copied libwgf implementation. SDL3 remains an alternative for native graphics/window/input/gamepads/audio; it has not been implemented or benchmarked.

The playable slice has a drifting title field, focusable/clickable menus, flight/fire, splitting rocks, waves, score/lives/life icons, session best, extra lives, delayed waves/respawn, thrust/explosion particles, bitmap text, eight original sound assets, looping thrust, game over, restart and return to title. It has keyboard/pointer and normalized controller input. The shared game remains an independent approximation of libwgf's Asteroids, with different font/art/audio, quantized physics and collision/wrap details; it does not recreate its ECS/prefab/general UI framework.

Contracts and limits: [INTERFACE.md](docs/INTERFACE.md). Implementation choices: [DECISIONS.md](docs/DECISIONS.md). Current measurements and recommendation: [FINDINGS.md](docs/FINDINGS.md). Reference capabilities, gaps and proposed stress workloads: [FEATURE_PARITY.md](docs/FEATURE_PARITY.md). Base decision against libwgf (and Heaps on hxcpp), with the probes that would settle it: [BASE_DECISION.md](docs/BASE_DECISION.md). QoL tools, autopilot schema and haxelib direction: [PACKAGING.md](docs/PACKAGING.md). [BRIEF.md](docs/history/BRIEF.md) and [START_PROMPT.md](docs/history/START_PROMPT.md) preserve the initial scope and authorized extension.

## Prerequisites and versions

Executed on Linux: Haxe **4.3.7**, hxcpp **4.3.2** (official lib.haxe.org release, the version libwgf's CI pins; installed on first native build into the ignored experiment-local `build/haxelib` via `HAXELIB_PATH`, which leaves the global haxelib untouched), Python **3.12.3**, PyYAML **6.0.1**, Node **26.1.0**, CMake **3.28.3**, GCC/G++ **13.3.0**, ALSA **1.2.11**, Terser **5.44.1**, Playwright **1.64.0**, pngjs **7.0.0**. The hot-reload probe uses hotreload-hx **`e8868c2`** (`haxelib dev hotreload-hx <clone>` or `haxelib git hotreload-hx https://github.com/whirlinggizmo/hotreload-hx`). Haxe runs `haxelib run hxcpp` without a version, so an hxml `-lib hxcpp:VERSION` alone would mix that version's Haxe classes with the current version's native runtime; `tools/pins.py` therefore owns the haxelib folder and stops a native build unless it resolves exactly the pinned release. On 2026-10-12 the main build, native unit/audio-device tests, browser/native service tests, parity build/checks and the mixed-submission builds (including the telemetry target, not rerun) were rebuilt and passed on 4.3.2. Results recorded before that used the robknopf/hxcpp fork: 08197b1c4aed5e3320ed859d8cf09c08b6a48bc6, and 81df26e79b95fcbfde21b2ee233d2ba059e61002 for the first parity cohort. Current native builds require no SDL. Historical SDL2 **2.30.0** results are preserved under `results/archive/pre-helix/stages/03-sdl-cohort/`. Exact browser/hardware/artifact identities are retained with results.

- Sokol headers: revision **401f21f8b7039258c35fef75c11d9a8a0e616771**, vendored with license in this experiment’s `vendor/`. Builds validate the local header hashes; no neighboring experiment is required.
- Sokol audio: same revision, vendored here with license in `vendor/`; SHA256 `e527091b2bc0c4ccbeb3f145489c0dbdbe74869247e30942c1e22bd580e2c4c7`. Dependency pins and header checks are in `dependencies.json`.
- Native Ogg decoder: system **libsndfile 1.2.2**, built with Vorbis and Opus support. The official 1.2.2 SDK header and LGPL 2.1 license are vendored in `vendor/sndfile/`; build checks their SHA256 pins in dependencies.json. Only a small codec bridge is compiled here; the library and its transitive codecs are dynamically supplied, with actual dependencies listed in sizes.json. A fresh Linux machine needs the runtime library (commonly `libsndfile1`) with these codecs; no system sndfile development header is needed. Native redistribution/package integration, including its license/dependency notices, remains unfinished. Browser has no libsndfile/Wasm decoder dependency. [Supported formats](https://libsndfile.github.io/libsndfile/formats.html) and [API](https://libsndfile.github.io/libsndfile/api.html).
- Offline audio generation: **FFmpeg 6.1.1-3ubuntu5** on this host, available on PATH with `libvorbis` and `libopus` encoders. Builds generate the original WAV sources under ignored `build/audio-source/`, then deploy quality 3 Vorbis `.ogg` files. A 64 kbps stereo 48 kHz Opus fixture is generated for tests, not game delivery. Tool version/parameters are retained with measurements; the same pinned host toolchain produced repeatable hashes. Other encoder versions can produce different bytes/sizes.
- Shader compiler: `sokol-tools-bin` revision **11d0cf678105d614d675e6d9bd2aaf3eeff12f8c**. Supply its host executable with `--shdc` or `SOKOL_SHDC`. Actual executable and generated-shader hashes are in `build/results/asteroids/sizes.json`. No compiler download or global installation is performed by build.py.
- Native: Linux/X11, GL4.1-capable desktop, hxcpp and C compiler; ALSA development headers, X11/Xi/Xcursor and GL libraries. Gamepads use Linux evdev device access and a fixed mapping. The native adapter is currently linked/configured for Linux only; Windows/macOS/mobile and modern graphics backends have not run.
- Browser: WebGL2. Browser build tooling uses Python/Haxe/Node and argument lists; no shell-script orchestration. Emscripten is unnecessary for this experiment.
- Checks: actual browser binary and, for native input/resize/display checks, a desktop display plus `xdotool` and optional `xset`. `ldd` is used only for Linux native dependency accounting.

## Build and play

Commands from the repository root (`python` or `py -3` may replace `python3`):

```console
python3 -m pip install -r experiments/05-hybrid-asteroids/requirements-build.txt
npm install --prefix experiments/05-hybrid-asteroids/build/tools terser@5.44.1 playwright@1.64.0 pngjs@7.0.0
python3 experiments/05-hybrid-asteroids/helix.py build web --shdc /path/to/sokol-shdc
python3 experiments/05-hybrid-asteroids/helix.py build native --shdc /path/to/sokol-shdc
python3 experiments/05-hybrid-asteroids/helix.py serve
```

Open `http://127.0.0.1:8050/`. Native executable: `experiments/05-hybrid-asteroids/build/native/asteroids/Main`. **Enter** activates the selected menu item; **Tab/Up/Down** selects game-over buttons; pointer clicks activate buttons. **Left/Right or A/D** rotate, **Up/W** thrust, **Space** fires; **Escape** quits on native. Standard controller: South/Start activates menus, South/right trigger thrusts, East/right bumper fires, left stick/D-pad rotates and D-pad Up/Down selects menus. The first connected mapped controller is used. Physical controllers have not been tested.

Resizing letterboxes a **960×720** logical playfield; browser pointer coordinates account for CSS sizing and device pixel ratio. Focus loss clears input and pauses live simulation/stops thrust. Browser audio unlocks on a real key/pointer gesture and suspends when hidden/unfocused; another gesture resumes it. Shared asset policy ensures eight encoded Vorbis files into persistent storage, then the selected audio adapter decodes them to mono float32 at 44100 Hz. Browser uses Web Audio; native uses libsndfile beneath Sokol delivery. Play waits for assets, and missing files fail visibly in browser. A missing native audio device leaves rendering playable and is reported in diagnostics. Thrust uses a two-second filtered-noise/motor loop with 133/266 Hz motor tones, intermediate noise filtering and a 40 ms head/tail blend plus a shared 60 Hz volume attack/release. Its versioned `thrust-v4.ogg` filename bypasses the earlier encoded cache; reload an existing browser tab to load the new code. Periodic volume modulation has been removed to reduce the audible repeat. Touch flight controls remain deferred.

Browser encoded cache: IndexedDB `hybrid-asteroids-cache-v1`; native cache: executable sibling `cache/`, overridable with `HELIX_CACHE`. Native defaults to sibling `assets/`; optional `HELIX_ASSET_HOST` supplies a full HTTP(S) asset base ending in `/`. The cache keys include base URL/path but have no version/revalidation policy yet: clear the browser database or native cache after changing an asset in place. Native HTTPS has compiled but only local HTTP fixtures were executed. An unwritable/full cache fails ensure explicitly.

`IFetch` and `IStorage` are thin replaceable Haxe contracts. `AssetService.ensure()` exposes callback completion, cancellation and phase/byte progress; browser Fetch streams response chunks and native `haxe.Http` runs in workers. Both return whole bytes bounded to 8 MiB; storage whole-file reads/writes share that cap. Two transfers/workers run per adapter. Host callback queues use nominal cooperative 2 ms slices, which cannot preempt a slow individual operation. Native cancellation suppresses late callbacks but does not abort a blocking worker; native socket timeouts differ from browser deadlines. Large/direct-to-storage/resumable downloads remain a separate gate.

`AudioResources` separates reusable `AudioClip`/`AudioStream` from an individual `AudioPlayback`. Resource release retains active/paused playbacks until stop or natural completion. WAV/Vorbis/Opus decoded clips and stored streams ran on both targets; mono/stereo Ogg clip input normalizes to mono 44100 Hz. Streams resolve usable storage first (browser Blob URL/native file), then remote media playback in browser; remote playback does not store. Ensure first when storage is required. Native stored WAV/Vorbis/Opus progressively feed an 8192-sample mono queue per playback; native remote streams remain deferred. The host fills this queue, so long frame stalls can underrun it. Browser remote playback passed but start before final network byte remains untested. The game uses decoded clips; service fixtures exercise streams separately. See INTERFACE.md for lifetime, cancellation, limits and codec semantics.

`helix.py build all` builds both. `examples/asteroids/web.hxml`/`native.hxml` own compiler settings; the Python front door calls the underlying tools. An optional Haxe entry point is `haxe --cwd experiments/05-hybrid-asteroids --run Run --help`; `HELIX_PYTHON` selects its Python executable. Native hxcpp/compiler caches and generated assets/shaders stay under ignored `build/`. No global Haxe registrations or libwgf files are changed. On this host, matching Node dependencies were copied from Experiment03's existing ignored tools cache rather than downloaded; a fresh machine can use the pinned npm command above.

Shaders are authored once in `examples/asteroids/shaders/sprite.glsl`. Build.py invokes sokol-shdc for GLSL300es/410, generates the browser Haxe shader strings, and compiles the Sokol descriptor into the native HAL. It requests `--format bare_yaml` and parses the structured reflection with PyYAML's SafeLoader, rejecting duplicate mapping keys. Shader source filenames come from metadata; neither GLSL nor generated C is scanned for bindings. See [the upstream output-format documentation](https://github.com/floooh/sokol-tools/blob/master/docs/sokol-shdc.md).

Reflection supplies attribute types/names/locations and texture/sampler slots, including the combined GLSL uniform name. `examples/asteroids/shaders/vertex.json` separately declares CPU vertex packing order and semantic roles: shaders do not specify byte offsets in the application's buffer. The build validates these together, checks agreement across dialects, and generates `GeneratedLayout.hx`, `vertex_layout.h` and an inspectable `shader-contract.json`. Shared Haxe writes vertices with generated inline offsets; both adapters consume generated locations/stride/bindings. Native static assertions also check slots against the compiler's C constants. Browser caches the generated sampler uniform at pipeline creation.

This is build-time shader reflection, with no shader runtime reflection or YAML shipped to the browser. Autopilot separately uses ordinary Haxe `Reflect` to validate structured JSON fields. The compiler revision and parser dependency are pinned; the upstream YAML has no schema-version field, so explicit validation rejects unknown resource sections, unsupported formats, duplicate slots and mismatched layouts. A compiler upgrade requires fixture checks and schema review. This first implementation uses GL on native; compiled shader variants alone do not prove another backend runs.

## Reproduce checks and measurements

```console
python3 experiments/05-hybrid-asteroids/helix.py test --native --audio-device --shdc /path/to/sokol-shdc
python3 experiments/05-hybrid-asteroids/helix.py services --browser /path/to/chromium --native
python3 experiments/05-hybrid-asteroids/helix.py audio-check --browser /path/to/chromium
python3 experiments/05-hybrid-asteroids/helix.py measure --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
```

Build first. Run `audio-check` with `helix.py serve` running in another terminal; `--url` selects a different server. It verifies served artifact hashes, then holds thrust through normal keyboard input past one clip duration and observes the Web Audio gain ramp and stop. It also checks decoded amplitude/seam and that the two one-second halves differ. It records signal/lifecycle evidence rather than speaker quality. Run it again after rebuilding the game before generating a current report. `measure` owns sequential correctness/CPU/autopilot cohorts, then size accounting and report generation; it requires both targets. `helix.py check --browser /path/to/chromium` runs browser-only correctness. Underlying `run.py checks|cpu|autopilot|all` is also available. `--awake` saves/restores X11 saver/DPMS/monitor state in `finally`; use it only with permission to change those settings. This session already supplied that permission, and exact restoration was verified. Direct autopilot does not change display settings.

Native unit checks use Sokol's dummy audio backend and pipe-fed evdev records; `--audio-device` additionally checks silent callbacks on a real Sokol/ALSA device. Native game/service checks use the real device. Browser controller checks inject a standard Gamepad API fixture. These establish callback/mixer/lifecycle behavior, without proving physical controllers or audible quality. CPU trials disable sound delivery while retaining asset loading/device initialization. Native captures are before presentation; browser readback/audit runs separately from CPU trials. Tools select the native input window by process ID and guarantee cleanup.

`services` builds one Haxe test harness for browser JS and optional native hxcpp. It starts isolated local HTTP fixtures and fresh storage, then repeats with the same storage to verify persistence. Network counts prove each ensured WAV/Vorbis/Opus fixture downloads once across both runs, clip loading and stored-stream playback. Tests cover status, progress, limits, timeout/cancel/shutdown, two concurrent transfers, read/write/remove, source leases, independent playbacks, pause/resume, loops and natural cleanup. Codec checks include signal/duration, stereo 48 kHz Opus normalization, empty/malformed input and exactly-once decode cancellation. Browser also exercises remote playback without persistence; native checks its explicit remote-stream failure. This suite is separate from game CPU sampling and makes no sustained large-download or audible-quality claim. Keep service tests/builds separate from timing runs.

Run packaged autopilot or regenerate existing measurements:

```console
python3 experiments/05-hybrid-asteroids/helix.py autopilot all --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority
python3 experiments/05-hybrid-asteroids/helix.py autopilot web --browser /path/to/chromium --script autopilot/smoke.json
python3 experiments/05-hybrid-asteroids/helix.py sizes
python3 experiments/05-hybrid-asteroids/helix.py report
python3 experiments/05-hybrid-asteroids/helix.py features --clang /path/to/clang --wgrender /path/to/wgrender-c --libwgf /path/to/libwgf
```

`playthrough.json` drives title/start/thrust/fire/game over/title/restart through the same input and menu code. It completed 4584 simulated ticks on both real renderers, with identical command outcomes, state and pixels. Fast autopilot is correctness tooling, not a performance benchmark. The bounded JSON schema and probes are documented in PACKAGING.md.

Individual commands:

```console
node experiments/05-hybrid-asteroids/tools/browser.cjs --action checks --browser /path/to/chromium
node experiments/05-hybrid-asteroids/tools/browser.cjs --action cpu --browser /path/to/chromium
python3 experiments/05-hybrid-asteroids/tools/native.py --action checks --display :1 --xauthority /path/to/Xauthority
python3 experiments/05-hybrid-asteroids/tools/native.py --action cpu --display :1 --xauthority /path/to/Xauthority
```

Browser options: `?tick=600` renders one frozen seeded replay snapshot; `?replay=1&audio=0&frames=600&autoclose=1` measures 60 warmup +600 moving frames then stops; `?autopilot=autopilot/playthrough.json&fast=1&audio=0` runs a script. Native equivalents are `HELIX_TICK`, `HELIX_REPLAY`, `HELIX_AUDIO`, `HELIX_FRAMES`, `HELIX_AUTOCLOSE`, `HELIX_SEED`, `HELIX_AUTOPILOT`, `HELIX_FAST`; `HELIX_CAPTURE` writes a diagnostic PPM and `HELIX_RESULT` writes JSON. `HELIX_LIVE` is an input-check-only per-frame JSON hook; it must remain unset for CPU runs. All diagnostics and autopilot code remain compiled in the measured delivery.

## Executed outcome and next step

Browser and Linux native builds ran. **35 shared assertions, nine shader metadata checks and 55 native service/mixer assertions passed**, plus an independent framework consumer under interpreter/JS and real ALSA callback checks. The async service suite passed two browser runs of **[90, 94] checks** and two native runs of **[90, 90] checks** (progress callback counts vary). WAV, Vorbis and Opus clips/stored streams pass; browser remote streams also pass. Each target downloaded each ensured codec fixture exactly once across fresh/persisted runs. Empty/malformed input, stereo Opus downmix/rate normalization and decode cancellation pass. Browser checks include pointer/keyboard, short taps, high-DPI hit testing, focus pause/resume, controller disconnect and missing-asset failure. Native checks include actual X11 pointer/keyboard/resize and service/audio tests. Five replay points match state, prepared vertex bytes and RGB pixels exactly, as does the 4584-tick autopilot capture.

The current identified Asteroids delivery is **22.50 KiB gzip code + HTML**, **51.55 KiB gzip sounds**, **74.05 KiB gzip total**, and **0 B Wasm**. Codecs/assets and historical size stages are separated in [the generated findings](docs/FINDINGS.md); optional autopilot/manifest files and native dynamic dependencies are accounted separately. Full Haxe DCE removes unused stream APIs from the game delivery; service tests exercise those paths independently.

Three sequential game CPU trials per target produced median trial means of **0.290 ms browser / 0.165 ms native**, with p95 **0.400/0.214 ms**. These clocks exclude service polling/presentation and disable sound delivery. Exact display settings were restored. The distinct P1 probe now records submission CPU and host callback CPU including idle service polling; it does not measure presentation, GPU completion or active downloads/audio. Current cohorts are selected by [results/latest.json](results/latest.json). No matched libwgf performance advantage is established.

[FEATURE_PARITY.md](docs/FEATURE_PARITY.md) now compares the reference capabilities against our executed scope and proposes the workloads needed to challenge the interfaces/web performance. A structured Clang AST snapshot inventories **522 wgrender-c  / 834 libwgf public functions**, with commits, input hashes and working-tree state in results/references/reference-features.json. There is **no full semantic 1:1 mapping or matched test coverage** yet. Reference capability descriptions are source/document evidence, not reference tests newly run here.

Proceed with the separated Haxe framework and adapters. Ogg closes the compressed-sound gate. The first mixed state-changing probe runs; its scoped P1 image/call/repetition/allocation gate is complete; proceed to UI/clipping and render-target/post passes, followed by a loading lit Racer scene with representative textures/models and the agreed optional physics module; Wits' skinning/scene breadth follows. A modern native backend and matched SDL3 comparison remain native gates. Desktop performance takes priority over executable size. A haxelib remains plausible, with dependency/licensing integration, installed-package consumption and API stabilization unfinished. Browser WebGPU, further targets, context recovery, physical controllers/audible quality, cache manifests/revalidation/eviction, large downloads, HTTPS/redirect/deadline normalization, native network audio, further audio controls, general UI/ECS and sustained GC/memory remain unproven. All changes stay inside this experiment.

## Shared-workload comparison with libwgf Asteroids

`examples/asteroids-parity` runs libwgf's own Asteroids game source (six Haxe files), scene file and Ogg sounds, byte-identical to libwgf commit `f87f0febf8a375f77a68d0b53f629914f58206c4`, on HeliX. A 285-line example-local `wgf` compatibility layer and 114 lines of bridge, font, renderer and launchers map the libwgf Haxe binding API onto HeliX services; no libwgf engine code is imported. The reference engine is compiled from a `git archive` of the pinned commit into experiment-owned `build/parity/` outputs, and the build verifies every workload/reviewed-engine hash in `reference.json`. Libwgf's dynamic font is replaced by an atlas baked from the same JetBrains Mono/fontstash sources at device DPI (1× and 2×, the glyphs this game draws).

```console
python3 experiments/05-hybrid-asteroids/helix.py parity build --shdc /path/to/sokol-shdc --baseline --native-baseline --reference /path/to/libwgf
python3 experiments/05-hybrid-asteroids/helix.py parity check --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
python3 experiments/05-hybrid-asteroids/helix.py parity measure --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
python3 experiments/05-hybrid-asteroids/tools/parity-results.py summary
python3 experiments/05-hybrid-asteroids/helix.py record --workload asteroids-parity --label "..."
python3 experiments/05-hybrid-asteroids/helix.py serve --example asteroids-parity
```

`--baseline` needs `EMSDK` and builds the libwgf browser/Wasm baseline plus a probe build; `--native-baseline` builds libwgf native normal/audit/profile executables. Both are needed once per pinned reference. The reference checkout must be clean at the pinned commit. Checks replay `reference.autopilot` on both engines in accelerated mode, then compare every recorded frame from the common start input (game state, score, lives, wave, best, rock/bullet counts, ship/rock/bullet poses to 0.01, audio command order/settings) and require **exactly equal RGB** final images. Native compares gameplay and images; audio is compared in the browser.

Correctness and sizes below were executed 2026-10-12 18:16 UTC (browser checks rerun 18:39 UTC after the capture fix below; the full suite rerun 20:20–20:37 UTC with the game-over menu cases added) on Linux (Chromium 153 / ANGLE Vulkan, RTX 4080 Laptop GPU; native Sokol GL core) with hxcpp 4.3.2 for both engines' native builds, matching libwgf's CI. Before that fix the result was 14/15, first on the hxcpp fork (17:47 UTC) and again on 4.3.2. Native captures used to differ by 1 now and then in a few RGB channels (8 of 1.44 million channel values), at frames 300 or 700. **Cause, found 2026-10-13:** the harness's display control woke the display and started the native build within milliseconds, and GL started while the woken display was still settling sometimes filtered a minified glyph one level differently on the NVIDIA driver. HeliX submitted identical input either way: across good and bad runs the vertex bytes, draw ranges, viewport, frame size and font texture bytes hashed the same, and the 8 values sat in the "w" of the HUD's "wave" text, drawn by linear filtering from a shrunken atlas. With the font sampled nearest the capture was stable (8 of 8), and with a 3 s pause after waking the display it was stable with the normal font (8 of 8, then 10 of 10). libwgf never varied because the harness always starts it second, after the display has settled. Not GC, and not HeliX's code. **Fix:** `tools/display.py` waits 3 s after waking the display (recorded as `settleSeconds`). Two full suites then passed 17/17 ([results/runs/20261013T030308447663Z-asteroids-parity](results/runs/20261013T030308447663Z-asteroids-parity)). Before the fix:

| Case | Result |
| --- | --- |
| Browser frames 220/300/700/2400/2500 at 800×600, seed 1; 2500 at seeds 2 and 7; 700 at 2× DPR and at 1200×700 | **Pass**: all 191–2471 compared frames agree, max pose error 0.0034, 40–158 audio commands equal in order, images identical |
| Native frames 220/300/700/2400/2500 | **Pass**: same gameplay agreement and identical images |
| Game-over menu path, frame 2500, browser and native (`--menus`: Down at 2405 selects the second game-over item, Enter at 2410 returns to the title with score 480 and lives 0 at 2412, Enter at 2420 starts again) | **Pass**: identical state, poses, 150 browser audio commands and images |
| Browser frame 10 (title, 10 frames after libwgf's loading wait) | **Pass**: identical image |

Frame 10 originally failed (about 1950 pixels, title rocks offset by drift). It was a harness timing error, not a rendering difference: libwgf's probe recorded state when it reached the target, but its autopilot `end` counts frames after `at 5 wait asteroids.ready == 1`, so libwgf ran three more frames before quitting and the preserved canvas showed a later frame. HeliX captured at frame 5 matched that image exactly. The libwgf probe now signals its actual shutdown; the harness reads libwgf's final state and pixels together and derives HeliX's title target from that frame. Audio is taken from the last frame, excluding teardown voice stops. All other cases were rerun and still pass.

Delivery, identical per-file gzip -9 over every deployed file: **HeliX 104.4 KiB** (code+HTML 29.9, font atlas 27.9, shared sounds/scene 46.4, scenario 0.2) versus **libwgf 296.3 KiB** (JS+HTML+Wasm 249.5, of which Wasm 215.0; shared sounds/scene 46.8). Libwgf additionally ships `sounds.json` (652 B) and `CREDITS.md` (312 B, counted as code). Brotli 11: 99.4 versus 255.0 KiB. Unstripped native executables on hxcpp 4.3.2: HeliX 4.80 MiB, libwgf 3.44 MiB.

Timing comes from the 17:47 cohort; the 4.3.2 cohort's timing ran while a concurrent libwgf headless-browser run loaded the machine (load average 17.6) and is not used. Browser builds do not involve hxcpp; the native diagnostics were built with the fork. Browser callback CPU (CDP animation-frame duration, normal vsync, sound on, three order-alternated trials of 600 frames): HeliX mean 0.224–0.239 ms, p95 0.407–0.438 ms; libwgf mean 0.213–0.269 ms, p95 0.376–0.449 ms. The ranges overlap; **no speed difference is established.** Native one-trial diagnostics use different callback boundaries (HeliX includes service polling; libwgf's `getFrameCost` excludes its core poll): HeliX mean 0.280 / p95 0.498 ms, libwgf mean 0.231 / p95 0.407 ms. Do not read these as a ratio.

This establishes that the same game source produces identical gameplay, audio commands and images on both engines at the tested checkpoints, and a ~2.8× smaller browser delivery for HeliX. It does not establish interchangeability for other libwgf scenes: the HeliX scene loader implements the subset this file uses, and the retained actor/parent model is local to the example. Evidence: [results/runs/20261012T203747755679Z-asteroids-parity](results/runs/20261012T203747755679Z-asteroids-parity) (hxcpp 4.3.2, 17/17 correctness and sizes), [results/runs/20261012T183903532200Z-asteroids-parity](results/runs/20261012T183903532200Z-asteroids-parity) (the earlier 15/15) and [results/runs/20261012T174722564335Z-asteroids-parity](results/runs/20261012T174722564335Z-asteroids-parity) (fork, timing).

## Hot reload in the browser

Probe 1 of [BASE_DECISION.md](docs/BASE_DECISION.md): hotreload-hx's dev server runs the Asteroids and parity-example web builds, and a Chromium page plays each while the probe edits sources and served asset files mid-game. The edits go to copies under `build/hotreload-probe/`, never to the repository. Each dev server is then stopped by its `/__hotreload_stop` request, and the probe checks no compilation server was left behind.

```console
python3 experiments/05-hybrid-asteroids/helix.py build web --shdc /path/to/sokol-shdc
python3 experiments/05-hybrid-asteroids/helix.py parity build --target web --shdc /path/to/sokol-shdc
python3 experiments/05-hybrid-asteroids/helix.py hotreload --browser /path/to/chromium
python3 experiments/05-hybrid-asteroids/helix.py record --workload hotreload --label "..."
```

Executed 2026-10-13 01:32 UTC with hotreload-hx `e8868c2`, Chromium 153, `-dce full`. Every edit showed up in the running page, play continued (tick advancing, same state and lives), the pages logged no errors, both dev servers stopped on request, and no compilation server was left:

| Edit, mid-game | Shown | Save to shown or applied |
| --- | --- | --- |
| Game code (`Game.snapshot`) | Yes | 660 ms (the first reload) |
| Graphics adapter (WebGL2 clear color) | Yes | 410 ms |
| The frame callback's own body (`App.frame`) | Yes | 311 ms |
| Generated shader source (`GeneratedShader.hx`, edited directly; see the note below) | Yes, through an `@:afterHotReload` hook that rebuilds the program | 328 ms |
| A sound file (`sounds/fire.ogg` replaced by another clip's bytes): a framework audio clip | Reloaded in place: fetched, decoded and swapped into the loaded clip | 224 ms |
| The parity example's font atlas (`font.alpha.zlib`, every glyph made opaque): a game-owned texture | Yes: text drew as solid blocks (white pixels 1,489 to 8,099) | 337 ms |
| The parity example's `scenario.json`: game-owned data | Reloaded in place | 168 ms |

The probe edited the generated `GeneratedShader.hx`, not the `.glsl` it comes from: nothing in the Asteroids dev loop runs `sokol-shdc` on save, so editing a shader's real source shows nothing until a build. Blocks' dev loop (below) closes that gap and was checked with a `.glsl` edit.

Code reload builds took 49–59 ms through the compilation server (461 ms for the first). An asset edit rebuilds nothing: the dev server notices the saved file (checked 10 times a second, then settled), tells the page its URL, and the page loads it again in place. These latencies were measured while the machine's CPU was capped (see the parity section) and are indicative only. The game ran without input, so the check shows play continuing rather than a rich game state surviving.

What getting there took:
- **ES6 output.** On Haxe's default ES5 output every swap failed (`newHooks.runAfter is not a function`). hotreload-hx now sets `-D js-es=6` through its `extraParams.hxml` and stops a hot build set lower (hotreload-hx `277c381`). It can't be set from the macro: the compiler has read `js-es` by then, and a constructor's `this` before `super()` stays ES5.
- **Calls through the app object.** `host.run(app.init, app.frame, app.cleanup)` passed bound methods, which keep their old code after a reload. `IHost.run` now takes an `IApp` (`helix.app.IApp`, with empty defaults in `BaseApp`), and hosts call `app.frame(dt)` through it each time.
- **Shader source as functions.** hotreload-hx keeps a static's value across a reload, even a `final` whose initializer changed, so the generated `GeneratedShader.vertex`/`fragment` strings are now functions returning them. The WebGL2 adapter's `@:afterHotReload` hook, compiled only with `-D hotreload`, rebuilds a program whose source changed, in place, so pipeline handles stay valid.
- **Orphaned compilation servers.** Stopping hotreload-hx's dev server leaves its `haxe --wait` running. The probe stops its whole process group. 112 such orphans from earlier sessions, holding about 10 GiB, were found on this machine and stopped.

**Assets reload in place.** hotreload-hx's dev server watches what it serves and tells the page which files changed (hotreload-hx `e8868c2`: `/__hotreload_assets`, a reloader's `assetsChanged`). In `-D hotreload` builds the browser host maps those URLs to asset paths and calls `AssetService.changed(path)`. That fetches the file once past the HTTP cache and the stored copy, stores the new copy, and calls each subscriber (`IAssets.subscribe(path, target:IReloadable)`) through the object, so a code reload's new methods are what run. `AudioResources` subscribes for each clip it loads: a reload decodes the new bytes and gives each clip from that path a new backend clip under the same `AudioClip`, so the game's handle stays valid; the old backend clip is destroyed once no playback started from it still plays. A game subscribes for its own files: the parity example rebuilds its font texture and re-reads its scenario. Limits: a looping voice keeps the old sound until the game stops it; with audio off, the probe checks the clip was decoded and swapped, not what is heard; a failed reload keeps the old version and is recorded in the host's `assetReloads` diagnostics.

Evidence: [results/runs/20261013T013254388755Z-hotreload](results/runs/20261013T013254388755Z-hotreload) (code and assets); [results/runs/20261013T010818036738Z-hotreload](results/runs/20261013T010818036738Z-hotreload) (code only, hotreload-hx `277c381`).

## Blocks: a 2D game on HeliX's own API

`examples/blocks` is a falling-blocks game written straight against HeliX, not through a compatibility layer: the first game that shows what a game needs from the framework. It plays with keyboard and gamepad, and with touch (drag to move by whole cells, tap to turn, flick down to drop, flick up to hold); portrait screens put the panels above the field, landscape beside it. No sound yet.

What it added to the framework, named for a later 3D layer beside it:
- `helix.render2d`: `Batch2D` (world-unit shapes, textured quads and text through a camera; one upload, one draw per texture run), `Camera2D` (fit a world rectangle, screen-world conversion), `Texture2D`, `Font2D` (the 5x7 pixel font as a framework asset) and `Text2D`. They generalize what Asteroids' renderer does privately; Asteroids is unchanged, so its parity evidence stands. The 2D shader is `src/helix/render2d/shaders/sprite2d.glsl`.
- `helix.input.PointerGestures`: taps, drags and flicks from the existing single pointer, the same for touch and mouse. The browser input adapter now follows only the first finger.
- Keys Z, X, C, P and Shift, on both targets (appended, so existing key numbers are unchanged).

```console
python3 experiments/05-hybrid-asteroids/tools/blocks.py dev --shdc /path/to/sokol-shdc      # the edit loop, http://localhost:8060/
python3 experiments/05-hybrid-asteroids/tools/blocks.py test
python3 experiments/05-hybrid-asteroids/tools/blocks.py build web
python3 experiments/05-hybrid-asteroids/tools/blocks.py build native
python3 experiments/05-hybrid-asteroids/tools/blocks.py autopilot --browser /path/to/chromium --display :1 --xauthority ~/.Xauthority
```

`dev` runs hotreload-hx's dev server on the example and regenerates the shader when `sprite2d.glsl` or its `vertex.json` changes; the new `GeneratedShader.hx` then reloads like any Haxe edit. `build web` writes the same `build/web/blocks/app.js` the dev server serves, so a release build while the loop runs is replaced at the next save.

**Development happened in the loop.** One page, a phone viewport (412x915 CSS pixels at 2.625x) with touch, stayed open while the game was written and edited; changes were judged in the running game, and native, tests and autopilot ran once, as a checkpoint. Executed 2026-10-13:
- A layout edit to `Renderer.hx` rebuilt in 470 ms and showed in the running page; the game went on (840 ticks, not reloaded).
- Editing `sprite2d.glsl` mid-game (a red tint) regenerated it, rebuilt in 535 ms, and the page reloaded 63 classes in 5 ms with the game continuing (8,152 ticks); reverting it reloaded the same way.
- Touch, through Chromium's touch events: a 3.2-cell drag moved the piece 3 columns, a tap turned it, a flick down hard-dropped it, a flick up held it, and a second flick up was refused (once per piece).
- What broke the loop: my tool exited when it couldn't find `sokol-shdc`, and its cleanup stopped the dev server (it now reports and keeps going). Restarting the dev server within about a minute of a page's connections failed to bind (`EADDRINUSE`, sockets in `TIME-WAIT`), raised past hotreload-hx's own "can't serve on port" message: a hotreload-hx issue, not yet fixed. The open page survived the outage and reloaded from the restarted server.

Checkpoint, 2026-10-13: 53 simulation, gesture and camera checks (`tests/unit/BlocksTests.hx`, Haxe interpreter); Asteroids' 35 simulation checks and the package smoke test still pass after the input changes. A keyboard autopilot (`examples/blocks/autopilot/smoke.json`: start, move, turn both ways, hard drop, hold, soft drop) ended in the same game, board included, in the browser and in the native build (3 pieces, score 99). Sizes: `app.js` 70,071 bytes, 20,526 gzip (`-dce full`, terser); native `Main` 4,489,376 bytes. The game is 267 lines of Haxe; the framework additions 170. The CPU cap noted above applies to these timings.

Limits: the native archive embeds one generated shader, compiled from `build/generated/asteroids`; Blocks' shader has the same program and layout, so it links, but a game with its own shader would need the archive built per game. Native has no touch input. Not checked: a real phone, landscape touch, and gamepad.

## HeliX layout and evidence

```text
src/helix/                 library APIs/policy; adapters grouped by service/provider
  adapters/<service>/<provider>/internal/   C glue and extern bindings
  profiles/                named compositions: BrowserWebGL2 / NativeSokolGL
examples/asteroids/         game, shaders, asset recipe, web shell, HXML, autopilot
benchmarks/mixed-submission/ P1 sources and HXML
tests/                    consumer, unit, services, native, shader checks
tools/                    build, checks, measurements, recording, reports
docs/                     current interfaces/decisions/findings; history/ for prompts
vendor/                   pinned headers and licenses
results/                  runs/, references/, archive/, latest.json
build/                    ignored generated outputs, caches and scratch evidence
helix.py / Run.hx          tooling front doors
```

The public namespace is `helix` and the product spelling is **HeliX**. Every Haxe adapter is under `src/helix/adapters/<service>/<provider>/`; class names consistently end in `Adapter`. `src/helix/profiles/BrowserWebGL2Profile.hx` and `NativeSokolGLProfile.hx` select services. Tiny target launchers under each application’s `launch/` pass an `IHost` to shared application code. Their host adapters own the loop, events and lifecycle via `HostServices`; game code consumes `IHost`. A native profile must keep host and graphics on the same context. Each native service owns its C sources, headers and extern bindings in its adapter’s `internal/` directory. Native Sokol adapters share Linux archive/link metadata through `adapters/internal/SokolNativeBuild.hx`. The Asteroids launcher retains its existing IndexedDB name to preserve stored encoded assets. “Native” consistently names the hxcpp target; “desktop” describes tested devices. A future WebGPU graphics adapter can use a `BrowserWebGPUProfile` alongside the existing WebGL2 profile and reuse DOM, Web Audio, Fetch API and IndexedDB services; WebGPU is not implemented.

Report tools write scratch evidence under `build/results/asteroids/`. After a complete validated cohort, run `helix.py record --label "HeliX baseline"`: it creates one immutable `results/runs/<run-id>/`, records evidence/source/reference hashes and updates `results/latest.json`. Re-recording identical evidence is a no-op. Historical results moved verbatim into `results/archive/pre-helix/`; recorded paths still describe their original builds. Stable reference inventories live once under `results/references/`. Resolve current results through `latest.json`, rather than treating archive values as current builds.

Haxelib publication remains deferred; the intended classPath is `src/`. No SDL3 adapter exists yet. The first mixed-submission probe runs through both adapters; the scoped range/material P1 gate now has complete image/call/repetition/allocation evidence; general shader/uniform/sampler breadth remains future work. [Results and reproduction](docs/MIXED_SUBMISSIONS.md). General shader/pass/package support remains unfinished.

The study-level summary still links the old `FINDINGS.md`/`FEATURE_PARITY.md` names and records `hybrid.py` commands. Those three tiny compatibility entries forward to the current docs/CLI; their implementations live in the new layout. The study-level summary and user-edited root IDE settings are outside this reorganization.


## Reproduce the hardened P1 range/material gate

```console
python3 experiments/05-hybrid-asteroids/helix.py mixed build --shdc /path/to/sokol-shdc
python3 experiments/05-hybrid-asteroids/helix.py mixed check --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
python3 experiments/05-hybrid-asteroids/helix.py mixed measure --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
python3 experiments/05-hybrid-asteroids/helix.py mixed profile --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
python3 experiments/05-hybrid-asteroids/helix.py mixed allocations --target native --browser /path/to/chromium --display :1 --xauthority /path/to/Xauthority --awake
python3 experiments/05-hybrid-asteroids/helix.py mixed report
python3 experiments/05-hybrid-asteroids/helix.py record --workload mixed-submission --label "P1 audited repeated explicit-offset gate"
```

`check`, `measure` and `profile` run baseline/cached/shared browser configurations, then native sequentially; `--target browser|native` can select one. `allocations` uses a separate native hxcpp telemetry/stack-trace executable and compares its final image against the browser profile. Run browser profile before allocations on a fresh checkout. `mixed build` also builds this test-only target and a Linux GL audit interposer, requiring the pinned hxcpp telemetry v1 SDK/header and Linux `dl` support. The normal delivered binaries exclude both. No allocation profiling/readback/call hooks run in performance trials. Rebuild after source/tool edits: reports reject stale source or target artifacts. Timing from the instrumented allocation target is not a performance result.

The draw offset is an explicit required `Int`, including zero for a whole batch. Together with typed command storage, this avoids the Dynamic/optional-integer boxing path found by telemetry. Asteroids explicitly enables verified browser state/program reuse; the P1 artifact retains three controls. The source/commit hashes for reviewed libwgf sprite/stage/replay patterns and hxcpp telemetry schema are under `results/references/`. Frozen pre-fix allocation evidence remains separately identified; no reference implementation was imported. GPU vertex reservation is queried on native: the 786432-byte P1 upload buffer occupies two Sokol slots, totaling 1572864 bytes, versus one browser slot. Heap/reservation/RSS diagnostics are scoped, not a complete browser/native/GPU memory comparison.


The latest P1 result is conditional for native GL: sorted cases meet the recorded callback budget, but the 4096-draw/64-texture alternating case exceeds 16.667 ms callback p95 in two trials. Browser shared-state/program cases fit on this device. The typed-command correction removes allocation scaling, but does not establish a native timing speedup. Transparent order cannot be freely sorted; sustained unsorted pressure and an executed modern native backend remain decision gates. See [the P1 findings](docs/MIXED_SUBMISSIONS.md) for ranges and exact boundaries.

The recorded P1 cohort was built with the earlier hxcpp fork. After the switch to 4.3.2 (2026-10-12 21:06 UTC), `mixed allocations` was rerun: managed allocation requests are unchanged in every case (77,024 B over 301 frames, 2701 events, no reallocations, 0 us instrumented GC; calibration fixture 4152 B), and the native image still matches the browser profile exactly. The GC heap reports less memory at the same allocation volume (reserved 3,961,576 versus 5,034,984 B; live after collect about 1.32 versus 1.44 MB), a runtime difference between the hxcpp versions, not a code change. P1 timing has not been re-measured on 4.3.2: the machine's CPU clock was being capped (a busy core read 1.7–4.7 GHz against a 5.4 GHz maximum), so no new timing was taken and the recorded timing remains the fork cohort's. The 4.3.2 allocation run is not frozen as a cohort, because `mixed report` requires measure/profile artifacts from the same build.
