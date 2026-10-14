# API findings

Found while documenting every public member (2026-10-13), by reading each implementation. Fixed items say where; the rest are open, roughly in order of how much they matter.

## Fixed with the documentation pass

- Public `var`s against the conventions: `WebGL2GraphicsAdapter.gl`, `DomInputAdapter.active`, `WebAudioAdapter.played`/`stopped`.
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

## Fixed with the adapter audit

- `IAudio.destroyStream`: Web Audio stopped the stream's playbacks; Sokol's didn't, and a playing stream kept reading its file. `AudioResources` hid it by keeping resources alive while played. Now both stop them (DECISIONS 83).
- A hot reload whose new audio failed to decode threw inside the decode callback. Now it's traced and the old clip kept (DECISIONS 83).
- `WebAudioAdapter.unlock()` made the AudioContext without the 44,100 Hz rate decoding asked for, so which ran first decided the rate. Decoding now has its own 44,100 Hz `OfflineAudioContext` (DECISIONS 83).

## Open

**Behaviour that differs between the targets**
- A host's services exist from construction on the web, but only from Sokol's init natively: read them in `init()` or later.
- `IWindow.getX/getY` where the window can't move: native answers 0, the browser `screenX/screenY`.
- `IGraphics`: Sokol refuses textures over 4096; WebGL2 accepts them. Bounds checks differ slightly. (Both now refuse `updateBuffer` outside a frame.)
- `capture("")` does nothing on the web; natively it writes the capture.

**Correctness**
- `HaxeHttpFetchAdapter`: cancelling doesn't stop the download (the worker runs to the end and holds one of two slots); `timeoutSeconds` limits only connecting; `noCache` is ignored; `Content-Length` is read case-sensitively; cancelled requests' progress readers are never removed.
- `DomInputAdapter` gates only keydown on `active`: pointer, mouse and wheel still record while inactive.
- `InputState.clear()` keeps typed text and wheel notches.

- A `Stage3D` lights every model with the first four lights its walk finds; a fifth is ignored. The earlier framework chose up to 8 for each model by which reach its box.

**Smaller**
- `FileStorageAdapter`'s read-only mode still reads and lends sources (by design?); a job after shutdown completes Cancelled, not Failed.
- `InputState.capture`/`capturePointer` have no callers.
- The default clear color is written twice (WebGL2 adapter and graphics.c).
- One native host per program (`SokolHostAdapter.instance`).
- Limits worth stating where they bite: WAV clips 4 s (`Wav.decode`), decoded clips 2Mi frames, the native mixer 16 voices and 32 clips (`playClip` and `playStream` return 0 when full).
