# API findings

Found while documenting every public member (2026-10-13), by reading each implementation. Fixed items say where; the rest are open, roughly in order of how much they matter.

## Fixed with the documentation pass

- Public `var`s against the conventions: `WebGL2GraphicsAdapter.gl`, `DomInputAdapter.active`, `WebAudioAdapter.played`/`stopped`.
- `Camera2D.fit()` and `pixels()` set the zoom without `setZoom`'s refusal: a zero width, height or scale gave an infinite or zero zoom.
- `Ticker`'s constructor and `PointerGestures`' ignored their own setters' refusals (a rate of 0 kept 60 silently).
- Gamepad edges weren't counted as keys' are, and pads and the mouse had no release edges.
- `Batch2D.cleanup()` named unlike every other `destroy()`.

## Open

**Behaviour that differs between the targets**
- `DomHostAdapter.quit()` only stops the frame loop; `cleanup()` and the services' shutdowns wait for `pagehide`. Natively, quit runs cleanup.
- `frame(dt)`: native passes Sokol's smoothed frame duration, the browser the raw requestAnimationFrame interval, unclamped. `Ticker` clamps; an app using dt directly doesn't get that.
- A host's services exist from construction on the web, but only from Sokol's init natively: read them in `init()` or later.
- `IWindow.getX/getY` where the window can't move: native answers 0, the browser `screenX/screenY`.
- `IAudio.destroyStream`: Web Audio stops the stream's playbacks; Sokol's doesn't, and a playing stream keeps reading its file. `AudioResources` hides it by keeping resources alive while played.
- `IGraphics`: Sokol refuses `updateBuffer` outside a frame and textures over 4096; WebGL2 accepts both. Bounds checks differ slightly.
- `capture("")` does nothing on the web; natively it writes the capture.

**Correctness**
- `HaxeHttpFetchAdapter`: cancelling doesn't stop the download (the worker runs to the end and holds one of two slots); `timeoutSeconds` limits only connecting; `noCache` is ignored; `Content-Length` is read case-sensitively; cancelled requests' progress readers are never removed.
- A hot reload whose new audio fails to decode throws inside the decode callback, past `AssetService`'s try/catch, so it isn't recorded in `getReloads()`.
- `WebAudioAdapter.unlock()` creates the AudioContext without the 44,100 Hz rate `decodeClip` asks for, so which runs first decides the rate.
- `DomInputAdapter` gates only keydown on `active`: pointer, mouse and wheel still record while inactive.
- `InputState.clear()` keeps typed text and wheel notches.
- `Batch2D.end()` takes the camera's viewport as the whole framebuffer, at 0,0.
- `IGraphics.destroy(kind:String, ...)`: the kind is a string; an enum would be checked.

**Smaller**
- `AudioResources` doesn't own the services it's given: `poll` polls only the backend, `shutdown` shuts down neither.
- `FileStorageAdapter`'s read-only mode still reads and lends sources (by design?); a job after shutdown completes Cancelled, not Failed.
- `InputState.capture`/`capturePointer` have no callers.
- The default clear color is written twice (WebGL2 adapter and graphics.c).
- One native host per program (`SokolHostAdapter.instance`).
- Limits worth stating where they bite: WAV clips 4 s (`Wav.decode`), decoded clips 2Mi frames, the native mixer 16 voices and 32 clips (`play` returns 0 when full).
