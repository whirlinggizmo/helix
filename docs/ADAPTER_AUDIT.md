# Adapter audit (2026-10-14)

Every adapter and the contract it implements, checked against the adapter rule in [ARCHITECTURE.md](ARCHITECTURE.md): an adapter holds only what differs because of its platform or API. Line numbers are as of the audit; they'll drift as the plan below lands.

## Graphics: done

`IGraphics` was a list of HeliX's own pipeline kinds, each adapter hardcoding every framework program's layout, slots and state (the WebGL2 adapter referenced the generated layouts 141 times; the C adapter branched per kind). Now it is resources, programs from a `ShaderSource`, pipelines from a `PipelineDesc`, passes and one `draw`; the engine's `Pipelines` describes the framework's pipelines and the generated layouts carry each program's source and buffers. Neither adapter names a HeliX program. Left over: the native graphics bridge also serves process diagnostics (peak RSS, frame capture), which belong to the host's tooling.

## Host and diagnostics

- **`IHost` mixes platform and engine.** Platform: the window, time, framebuffer, focus, quit, the loop. Engine: assets, sounds, textures, environments (built identically by `HostCore`), the frame clock, diagnostics. Its services exist from construction in a browser but only from `run` natively.
- **Both hosts still repeat** about 15 fields copied from the services and core, the timing pass-throughs, option fallback and `getInfo` augmentation; quit-after-frame lives in the browser host only; the native host does the `HELIX_LIVE` dump and frame capture itself.
- **`IDiagnostics` has five concerns**, all `Dynamic`: options, the test harness (publish, expose, capture), shared timing, a graphics audit (null in a browser), GC control (native only).
- **`HostServices` hooks are closures** each profile re-implements (focus policy differs, no-op stubs natively); `info` is untyped; a doc comment sits on the wrong field.
- **`isFocused`** means "visible and focused" in a browser, "sokol focused or resumed" natively.

## Input

- **Adapters subclass `InputState`** (the engine's input API), so the HAL boundary is blurred and they inherit replay-only methods.
- **Duplicated in both:** pad slot syncing (about 20 lines each), the left button driving the pointer, focus loss releasing everything (in three places, one in a profile), focus gating of pads (twice natively, once in C).
- **Engine policy in the browser adapter only:** the first finger as the pointer and a second finger cancelling it, so touch doesn't drive the pointer natively, contrary to `IInput`'s contract; text suppressed while a shortcut modifier is held (missing natively).
- **Contract slips:** `isPadPressed` is documented "not counted" but is; `getPadAxis` is raw while `getPad().getAxis` applies the dead zone; `Key.fromCode` is the native key table inside shared `Key`.

## Audio

- **Duplicated in both:** request and cancel bookkeeping (and a third time in `AudioResources`, so completions are deferred twice), the 8 MiB and frame limits, RIFF sniffing and the WAV dispatch, Ogg/MP3 sniffing, downmix and resampling to mono 44.1 kHz (Haxe in one, C in the other), volume and PCM validation (also in C), shutdown, counters.
- **Engine policy in the native adapter:** a decode scheduler (two at once) and the stream pump (budget, chunking, loop rewind); files reopened inside `play`.
- **`IAudio` contract:** `decodeClip`'s contract states the WAV rules and limits (policy); `play` erases clip versus stream (native recovers it from the id's sign); the browser's start-after-unlock is hidden in `play`; `destroyStream` stops playbacks in a browser but not natively; unlock, suspend and info are profile closures; libsndfile is fused into the sokol output adapter instead of being a codec of its own.

## Fetch, storage and images

- **Duplicated in each pair** (25 to 60 lines a pair): request and cancel bookkeeping, defaults and limits, validation, a two-at-a-time cap, progress coalescing, shutdown. Five private work queues, each with its own 2 ms budget: no single frame budget.
- **One contract, two behaviors:** a fetch timeout covers the whole transfer in a browser but only the connection natively; `noCache` is ignored natively; a native cancel doesn't stop the transfer and holds its worker slot until the thread ends; the scheme check is native only. A closed storage answers `Cancelled` natively and `Failed` in a browser (the contract says `Failed`); IndexedDB has no concurrency cap.
- **Policy in contract docs:** "at most two", "8 MiB". `IStorage` names keys `path`; its lease type is called `LocalAudio`.
- **Bugs:** the native image decoder's shutdown drops queued decodes, which never complete; the browser's still delivers decodes after shutdown.
- **Images:** decoding isn't a platform concern in itself; the platform part is that a browser ships a fast native decoder. Recommendation: a codec seam only (stb natively, the browser's decoder on the web, exact through WebCodecs' `ImageDecoder` where available), with queuing, cancellation and shutdown in shared code. A pure-Haxe decoder would be slow on the main thread (and Haxe has no mature JPEG decoder); stb in Wasm would add a toolchain for little gain.

## Plan

In order, each step leaving both targets working:

1. **Host.** A platform host interface (the loop, time, framebuffer, focus with one definition, quit, the window, raw options); `HostCore` becomes the shared host implementing `IHost`, with the engine's services and clock in an engine context; quit-after-frame, focus fan-out and `getInfo` shared. `IDiagnostics` split: options (shared), a test-harness adapter (publish, expose, capture, the live dump), timing (shared), a typed graphics audit and a runtime adapter for memory. Capture moves to `IGraphics` (read pixels). Closures in `HostServices` become small interfaces.
2. **Shared async plumbing.** One job pool in `helix.core` (requests, queue, cap as policy, cancel on shutdown, hand-off to the host thread) under one frame budget; adapters keep only the hand-off mechanism and their platform calls.
3. **Fetch, storage, images** slimmed onto it: shared services own limits, validation, progress and closed states; images become a codec seam. Fixes the contract mismatches and both shutdown bugs; documents the native fetch gaps (whole-transfer timeout, abort) that remain.
4. **Audio.** A minimal `IAudio` (running, resume and suspend, compressed decode, clips, streams, voices, typed info); limits, sniffing, WAV, resampling (benchmarked on hxcpp before it leaves C), the decode cap, start-after-unlock and the native stream pump move to shared code; libsndfile becomes a codec adapter of its own.
5. **Input.** Adapters become event sources feeding a shared router in front of `InputState`: pointer from the left button or first finger (fixing native touch), focus release and pad gating once, pad slot syncing once; key tables stay per platform as data.
6. **Enforcement and docs.** `tools/adaptercheck.py` in the typecheck and test runs (adapters import no engine package or generated layout; engine code uses no platform API or target conditional); ARCHITECTURE.md completed with every adapter's responsibilities; AGENTS.md's rule; INTERFACE.md rewritten.
