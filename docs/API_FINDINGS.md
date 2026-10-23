# API findings

Found while documenting every public member (2026-10-13), by reading each implementation. Fixed items say where; the rest are open, roughly in order of how much they matter.

## Fixed with the documentation pass

- Public `var`s against the conventions: `WebGL2GraphicsAdapter.gl`, `DomInputSourceAdapter.active`, `WebAudioAdapter.played`/`stopped`.
- `Camera2D.fit()` and `pixels()` set the zoom without `setZoom`'s refusal: a zero width, height or scale gave an infinite or zero zoom.
- `Ticker`'s constructor and `PointerGestures`' ignored their own setters' refusals (a rate of 0 kept 60 silently).
- Gamepad edges weren't counted as keys' are, and pads and the mouse had no release edges.
- `Batch2D.cleanup()` named unlike every other `destroy()`.
- `DomHostAdapter.quit()` only stopped the frame loop, and `cleanup()` and the services' shutdowns waited for `pagehide`. Now a quit closes after the frame, as natively (the quit example).

## Fixed before milestone 2

- `frame(dt)` was Sokol's smoothed frame duration natively and the raw, unclamped interval in a browser. Both hosts now measure it the same way (`FrameClock`): held between 1e-6 and 0.1 s, 1/60 on the first frame. `Ticker` takes the unheld `IHost.getFrameElapsed()`, so a slow frame is caught up in ticks, up to `getMaxSteps`.
- `Batch2D.end()` took the camera's viewport as the whole framebuffer, at 0,0. `Camera2D.setViewportArea` narrows it, and screen positions are the framebuffer's.
- `IGraphics.destroy(kind:String, ...)` took the kind as a string: now `destroyTexture`, `destroyBuffer` and `destroyPipeline`.
- `Math`'s `sin`, `cos`, `tan`, `atan2`, `asin`, `exp` and `log` differ by 1 ulp between V8 and glibc for 1–18% of inputs (3.3% for `sin`, 18% for `atan2`), so a simulation calling them plays differently on each target. `helix.math.Trig` gives the same bits everywhere (`helix.py test` holds the interpreter, JS and hxcpp to one hash), and native builds that use it compile with `-ffp-contract=off`.

## Fixed in milestone 5

- A `Stage3D` lit every model with the first four lights its walk found, a fifth ignored. Each model is now lit by the 8 of a table of 16 that reach its box most, as the earlier frameworks chose (DECISIONS 89).

## Fixed with the adapter audit

- A host's services existed from construction on the web but only from Sokol's init natively; the `Runner` fills `Services` at init on both (DECISIONS 81). `capture` went with the diagnostics (DECISIONS 81).
- `HaxeHttpFetchAdapter`: cancelling didn't stop the download, the timeout limited only connecting, `Content-Length` was read case-sensitively and cancelled requests' progress readers were never removed; the read-only store still lent sources, a closed native store answered Cancelled, and the clear colour was written in both graphics adapters; each was gone by the end of the audit (fetch and storage with DECISIONS 82).
- `Jobs.shutdown` dropped queued operations without completing them, against the pool's exactly-once promise; they now complete with their cancelled value (DECISIONS 85).
- `IAudio.destroyStream`: Web Audio stopped the stream's playbacks; Sokol's didn't, and a playing stream kept reading its file. `AudioResources` hid it by keeping resources alive while played. Now both stop them (DECISIONS 83).
- A hot reload whose new audio failed to decode threw inside the decode callback. Now it's traced and the old clip kept (DECISIONS 83).
- `WebAudioAdapter.unlock()` made the AudioContext without the 44,100 Hz rate decoding asked for, so which ran first decided the rate. Decoding now has its own 44,100 Hz `OfflineAudioContext` (DECISIONS 83).
- `DomInputSourceAdapter` gated only keydown on focus: pointer, mouse and wheel still recorded while inactive. Native touch never drove the pointer. The shared `InputRouter` now applies one focus and pointer policy (DECISIONS 84).
- `InputState.clear()` kept typed text and wheel notches; now it drops them. `InputState.capture`/`capturePointer` had no callers and are gone (DECISIONS 84).
- `isPadPressed` was documented as not counted, but is; `getPadAxis` was raw while `getPad().getAxis` applied the dead zone; both now say and do the same (DECISIONS 84).

## Open

**Behaviour that differs between the targets**
- `IWindow.getX/getY` where the window can't move: native answers 0, the browser `screenX/screenY`.
- `IGraphics`: Sokol refuses textures over 16384 on a side; WebGL2 refuses over the GPU's `MAX_TEXTURE_SIZE`. Bounds checks differ slightly. (Both now refuse `updateBuffer` outside a frame.)

**Correctness**
- `HaxeHttpAdapter`: an abort stops a transfer only at the next part of its body, not while it connects; `noCache` has nothing to bypass (no HTTP cache natively).


**Smaller**
- One native host per program: `SokolHostAdapter` keeps sokol's callbacks in statics.
- Limits worth stating where they bite: decoded clips 2Mi frames (about 47 s), the native mixer 16 voices and 32 clips (`playClip` and `playStream` return 0 when full).
