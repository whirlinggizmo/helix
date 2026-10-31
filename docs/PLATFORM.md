# helix-platform: the contracts

What the platform library is, contract by contract: each contract's members, what they mean, and what each adapter does beneath them.
The interfaces in `platform/src/helix/platform/` are the authority; this is their specification, and a contract changes here first.

## Principles

- **Pumped, never driving.** Nothing in the platform runs the program or calls into it on its own; the one exception is
  `IWindow.onClose`, because a browser gives no frame in which to poll it. Everything that must be serviced once a frame is its own
  small `poll`, named for what it services and doing nothing else: input, http, the file system, each decoder, audio. Each of those
  contracts extends `IPollable`, the one interface they share, so a program can hold them as one list. The platform never bundles them;
  whoever owns the program does, in its own order (raylib hides the same pumps inside `EndDrawing`).
- **Granular, for whoever builds on it.** The platform keeps the pieces separate (end the frame, read it back, present, poll) and
  leaves their order to the layer above. A smaller surface, like raylib's `EndDrawing` that flushes, captures, swaps, waits and polls in
  one call, is a layer on top.
- **No policy.** No queues, caches, buses, frame order, retries or asset model. The test for a member: would a different engine on the
  same hardware need it to draw, hear or read at all? If not, it isn't here.
- **The raw truth, as plain data.** A GPU program is a `ShaderSource`, a pipeline a `PipelineDesc`, a decoded image bytes and a size, an
  input event its arguments. Handles are `Int`. A completion is a callback per outcome (`decoded` and `failed`, `done` and `failed`),
  never a nullable error or a result to switch on; one of them is called, once, on the main thread, never during the call that took it.
  None is optional, as the platform never logs.
- **Reports, never logs.** A refusal or a failure reaches the caller through the API (a `failed` callback, a state, a result) and the
  caller decides whether it is worth a log line; the platform depends on no logger.
- **Fails before doing anything.** A call that can't be done throws, saying why; one that may be refused returns false or null and its
  doc says when.
- **One contract per thing, one adapter per API.** An adapter's public members are its constructor and its contract's, nothing else; the
  constructor takes nothing, or one `<Adapter>Options` holding the platform's own arguments (a canvas's id, a directory), named at the call:
  `new DomWindowAdapter({canvasId: "canvas"})`. `check_adapters` holds both.
- **One directory per contract, even when one library provides several.** SDL3 provides the window, the events and the system, and a
  page does the same: each still gets its own adapter in `adapters/<contract>/<api>/` (`adapters/window/sdl3/Sdl3WindowAdapter`,
  `adapters/events/sdl3/Sdl3EventsAdapter`), so a program chooses each contract's adapter on its own. What two adapters of one library
  share (the SDL window, the page's canvas, state seen by one and answered by another) lives in `adapters/shared/<api>/`, which both
  reach; no adapter reaches into another's directory, but a device's adapter is given the events adapter it is built over (Events).
- **Contracts don't know each other.** No contract or its adapters imports another contract's (http never names graphics, the file
  system never names audio); only `adapters/shared/` is common to them. `check_layers` enforces it: a contract's files are its
  interface, the types it reaches and its adapters; anything else may name at most one contract. A base any contract may extend
  (`IPollable`) is no contract's and names no other type. A device (`IKeyboard`, `IMouse`, `ITouch`, `IGamepads`, `ITilt`) is built
  over the events, and may name theirs.
- **Both targets, one interface.** Every contract has the same members on js and cpp; an adapter is for one API on one target.
- **Units** as CONVENTIONS: seconds, radians, framebuffer pixels for the pointer, logical pixels for the window, `0xAARRGGBB` colors.

## Window

`IWindow`: the drawing surface and the window around it. The graphics adapter is made after the window and draws into its surface
(natively through `surface.h`, which the window's C implements).

- `title`; `width`, `height` (logical pixels) and `framebufferWidth`, `framebufferHeight`, `pixelRatio`; `focused`.
- `visible`, `requestVisible`; `requestSize`, `canMove`, `x`, `y`, `requestPosition`; `canFullscreen`, `fullscreen`,
  `requestFullscreen(enabled, ?done, ?failed)`; `orientation`, `requestOrientation(orientation, ?done, ?failed)`.
- `maximized`, `requestMaximized`, `minimized`, `requestMinimized` (false and asking nothing in a page); `requestFocus` (natively
  raised, in a page the canvas taking the keyboard); `setIcon(width, height, pixels)` (in a page, the page's icon); `opacity`,
  `requestOpacity` (natively the compositor's, in a page the canvas's); `requestMinimumSize`, `requestMaximumSize` (false in a page).
- The monitors: `monitorCount`, `monitorIndex`, `requestMonitorIndex`, `getMonitorName`, `getMonitorX`, `getMonitorY`,
  `getMonitorWidth`, `getMonitorHeight`, `getMonitorRefreshRate` (0 in a page).
- `onClose`, a property: the call made once, the last before the window is gone (natively in `close`, in a page at pagehide). Not a
  place to save: a page's write started there isn't kept.
- `close()` natively destroys the window and in a page does nothing (a script can't close its tab); `canClose()` says whether `close`
  removes the window: true natively, false in a page, so a menu asks it before offering Quit.

A request asks; the getter answers on a later frame. Presenting the frame is graphics' (`IGraphics.present`), where every backend
actually swaps; the window only provides the surface.

- Natively, a close asked for by the user or the OS (the close button, the OS quitting the program) is an event, `CloseRequested`,
  delivered by `IEvents.poll` like a key press: it happens once, and the owner decides, closing with `close()` or not (asking "quit
  without saving?" first).
- A page never gets `CloseRequested`: a tab closing or navigating away gives no frame to decide in. Its end is `onClose`, at
  pagehide, the one call the platform makes upward; nothing of the program runs after it, so work started there must not need a later
  frame. A browser drops a write that starts as its page goes (IndexedDB's, in Chromium every time), so a program keeps what it must
  as it changes.
- Quitting is the owner's loop ending, the same on both targets: natively the owner closes the window and ends its loop; in a page a
  program doesn't offer Quit, since `canClose()` is false and a stopped program would leave the page frozen.
- `visible` and `requestVisible` are the program's own choice to show or hide its window (in a page, the canvas). Whether the player
  can see it (not minimized, the tab not in the background) is a different thing, reported only as the `Shown` and `Hidden` events;
  whether it has the keyboard is `focused`. Not spinning while it can't be seen is the owner's loop's, with `IEvents.wait`.

## Events

`IEvents`: the window's events and the player's first press, and the one stream every device adds to. What happens (the window
resized, focused, shown, hidden or closed, its graphics lost, the first press) arrives as events from one `poll`. One stream, because
the OS has one queue: one pump drains it and one consumer walks it, and the order between devices (a key before a click) is kept. The
platform keeps no listeners; a state model (arrays of what's held) or a dispatch model (listeners) is a short walk over what a poll
delivers, built above.

Each device is a contract of its own, built over the events: `IKeyboard`, `IMouse`, `ITouch`, `IGamepads` and `ITilt`. Its adapter is
constructed over the events adapter of its API (`new DomKeyboardAdapter({events: events})`) and adds its events to the same stream,
delivered by the events' `poll`. A device that isn't constructed isn't listened to: a page installs none of its listeners and doesn't
read its pads; natively SDL's events for it are turned off, and SDL's gamepads aren't started, so a program links and runs only the
devices it makes. A device's contract may name the events' types and adapters, and nothing else of another contract's.

```haxe
interface IEvents {
	function poll():Void;                         // drains the OS queue into events: this frame's, in order, every device's
	var events(get, never):Array<Event>;          // valid until the next poll; the array is reused
	function wait(timeout:Float):Void;            // sleeps in the OS until an event or timeout seconds; does nothing in a page
	var unlocked(get, never):Bool;                // the player's first press has happened, on every target, with or without devices
	function dispose():Void;                      // after the devices built over it
}

interface IKeyboard {
	var textInput(get, set):Bool;                 // typed text only while on; a phone shows its keyboard then
	function dispose():Void;
}

interface IMouse {                             // a pen counts as the mouse
	var cursorVisible(get, set):Bool;             // hidden either way while locked
	var cursorShape(get, set):CursorShape;        // the system's cursor of each shape
	var locked(get, never):Bool;                  // cursor hidden and held; moves go on from where it was, past the edges
	function requestLock(locked:Bool, ?done:Void->Void, ?failed:String->Void):Bool; // a page: soon after a press, else at the next; Escape lets go
	function canSetPosition():Bool;               // false in a page
	function setPosition(x:Float, y:Float):Bool;  // framebuffer pixels; a MouseMove there at the next poll
	function dispose():Void;
}
interface ITouch { function dispose():Void; }    // a finger is never the mouse

interface IGamepads {
	function isConnected(slot:Int):Bool;          // slots 0..3
	function getName(slot:Int):String;
	function isButtonDown(slot:Int, button:PadButton):Bool;   // the W3C standard gamepad's buttons
	function getAxis(slot:Int, axis:PadAxis):Float;           // sticks -1..1, down and right positive; triggers 0..1
	function setVibration(slot:Int, low:Float, high:Float, seconds:Float):Bool; // natively SDL's rumble; a page's vibrationActuator, none in Firefox
	function addMappings(mappings:String):Int;    // SDL's controller database lines; 0 in a page, whose browser maps pads
	function dispose():Void;
}

interface ITilt {
	function requestAccess(?done:Void->Void, ?failed:String->Void):Bool;   // device motion, asked of a page's player at a tap
	function releaseAccess():Void;
	function dispose():Void;
}

enum Event {
	KeyDown(key:Key, repeat:Bool);       // IKeyboard; by physical position
	KeyUp(key:Key);
	Text(text:String);                   // while IKeyboard.textInput
	MouseMove(x:Float, y:Float);         // IMouse; framebuffer pixels from the top-left
	MouseDown(button:MouseButton, x:Float, y:Float);
	MouseUp(button:MouseButton, x:Float, y:Float);
	MouseLeave;
	Wheel(dx:Float, dy:Float);
	TouchDown(id:Int, x:Float, y:Float); // ITouch
	TouchMove(id:Int, x:Float, y:Float);
	TouchUp(id:Int, x:Float, y:Float);
	Tilt(beta:Float, gamma:Float, screenAngle:Float);   // ITilt
	TiltState(status:TiltStatus);        // the tilt's status: Off, WaitingForTap, On, Refused, Unavailable, NeedsHttps
	Unlocked;                            // the player's first press (a key or mouse press, or a finger lift), before that event, on every target
	PadConnected(slot:Int);              // IGamepads
	PadDisconnected(slot:Int);
	PadButtonDown(slot:Int, button:PadButton);   // a trigger is a button too, down past half way
	PadButtonUp(slot:Int, button:PadButton);
	Resized(width:Int, height:Int);      // the framebuffer's
	FocusGained;
	FocusLost;                           // each key still down came up just before, a KeyUp each
	Shown;
	Hidden;
	CloseRequested;                      // natively; a page's end is IWindow.onClose
	GraphicsLost;                        // the GPU's context is gone (a page's WebGL context lost: a GPU reset, an evicted tab)
}
```

- `poll` is the only pump for input and window state; `IWindow`'s getters and the pad reads answer as of it. `events` holds enum
  records in the order the OS gave them, cleared and reused each poll; the owner walks it with a `switch`. In a page the DOM pushes
  events into the adapters' listeners between frames, which only append to that buffer, and the poll then reads the pads; natively
  `poll` drains `SDL_PollEvent` into it, and the device adapters only say which of SDL's events are wanted.
- The first press is heard without a keyboard, mouse or touch adapter: in a page a listener on the window, ahead of the page's elements,
  until it comes; natively SDL's key, mouse button and finger-lift events stay on until it comes.
- What the adapters number, they name: `Key` (physical keys), `MouseButton`, `CursorShape` (the system cursors of each kind),
  `PadButton` (the W3C standard gamepad's buttons: the face buttons by position, the shoulders, the triggers as 6 and 7, back and start,
  the stick clicks, the pad, guide), `PadAxis`.
- Pad buttons: natively a button pressed and let go between two polls arrives as both events, in order, though its state reads up; a
  page reads its pads only at each poll (the Gamepad API has no events), so it sees a press only if the button is down then. Natively
  the Guide button's release arrives no sooner than a quarter second after its press: SDL holds it back that long. A trigger's analog
  value is `getAxis`; its button events come as it crosses half way.
- Focus and visibility are tracked once, by the events adapter: in a page it alone installs the blur, focus and visibility listeners;
  natively it alone sees SDL's focus and window events. They arrive as `FocusGained`, `FocusLost`, `Shown` and `Hidden`, and
  `IWindow.focused` answers from what the last poll saw. `Hidden` fires when the player stops being able to see the window: natively
  minimized or hidden (by the OS or by `requestVisible(false)`), in a page `visibilitychange` to hidden (a background tab, a minimized
  browser, a phone switched away or locked); `Shown` on the reverse. Another window covering it, or losing focus, fires neither.
- `wait` is how a native loop idles while the window can't be seen: the thread sleeps in the OS's event wait (`SDL_WaitEventTimeout`),
  using no CPU, and wakes for an event or at the timeout, so the owner can still pump what must not starve (a music stream, a
  download's completion) at an interval of its choosing: `if (hidden) events.wait(0.25); events.poll(); ...`. In a page the browser
  already withholds frames from a hidden tab.
- No policy: which finger is "the pointer", whether a shortcut swallows text, a stick's dead zone, which pad is the player's are above.
  An adapter reports what the platform said and nothing else.

## Graphics

`IGraphics`: resources, passes and one draw. The adapter knows no program or layout of its caller's.

- Textures: `createTexture(width, height, levels, format)` (2D, with its mip levels), `createCubeTexture`, `createDataTexture` and
  `updateDataTexture` (floats read texel by texel), `createRenderTarget(width, height, format, depth)` (RGBA8 or half floats, with or
  without depth), `createShadowMap(size, layers)` (a depth array read through a comparison sampler), `disposeTexture`; `canSample(format)`
  and `canRender(format)` say what the GPU can.
- Buffers: `createBuffer(capacityBytes)` and `updateBuffer`, `createStaticBuffer(data, bytes, index)`, `disposeBuffer`.
- Programs and pipelines: `createShader(source:ShaderSource)`, `createPipeline(desc:PipelineDesc)` (a program, its buffers' layout,
  primitive, indexing, blend, depth test and write, culling and winding, depth-only, and the clip flip), each with its `dispose`.
- Passes: `beginShadowPass(map, layer)`; `beginTargetPass(target, r, g, b, a)` and `endTargetPass`; the screen's, `beginFrame(width,
  height, clearColor)` and `endFrame`; within a pass `applyViewport`, `applyScissor`, `resetScissor`.
- `draw(pipeline, buffers, indices, first, count, firstInstance, instanceCount, textures, samplings, uniforms)`: buffers by the
  pipeline's buffer index, an index buffer for indexed pipelines, a range, instances, textures, samplings and uniform blocks by slot.
- `readPixels(target, read(pixels, width, height), failed(message))`; `msaaSamples`, `maxMsaaSamples`; `dispose`.

`endFrame` ends the screen's pass and submits it; `present()` shows the frame and waits for the display's refresh, which paces the
owner's loop. Between the two the frame can still be read back (`readPixels(0)`), and the owner can do work in the time the display
would otherwise be waited for. GL natively swaps through the window's surface (`surface.h`), SDL_GPU presents its swapchain, and in a
page `present` does nothing, since the browser presents when the frame's callback returns. A native window opened without vsync (`Sdl3WindowAdapterOptions.vsync`)
presents at once and waits for nothing, and the frame may tear: GL swaps with interval 0, SDL_GPU presents IMMEDIATE, or MAILBOX where the
window has no IMMEDIATE, or VSYNC where it has neither. A page always waits.

Render targets are stored top row first on every backend. A declared texture a draw leaves unbound gets a placeholder, so a shader may
declare more than a draw binds. Adapters: `graphics/webgl2` (`WebGl2GraphicsAdapter`), `graphics/sokol` (`SokolGraphicsAdapter`,
sokol_gfx on GL 4.1), `graphics/sdl3gpu` (`Sdl3GpuGraphicsAdapter`, SDL_GPU on Vulkan, Direct3D 12 or Metal). `platform/tests/graphics`
draws on each and checks the pixels it reads back.

## Shader compiler

`helix.platform.tools.ShaderCompiler`: a program on `IGraphics` needs every backend's dialect, and gets them from standard GLSL.

**What a program writes:** Vulkan-style GLSL 450, one file a stage (`triangle.vert`, `triangle.frag`): attributes at
`layout(location = n)`, uniform blocks at `layout(binding = n)`, textures as combined samplers. No annotations. The build macro
`ShaderCompiler.compile("triangle.vert", "triangle.frag")`, paths beside the calling file, compiles them while Haxe builds the program and
puts the `ShaderSource` in it as a literal; the program hands it to `IGraphics.createShader`. `#include` with a quoted name resolves
beside the including file (`#extension GL_GOOGLE_include_directive : require`).

**The chain:** glslang compiles each stage to SPIR-V (Vulkan 1.0, unoptimized, so nothing declared is trimmed; the drivers optimize);
SPIRV-Cross emits every dialect from it (GLSL 410 and GLSL ES 300 with each uniform block flattened to a `vec4` array named for the
block's type; MSL and HLSL laid out as SDL_GPU binds them) and reflects the attributes, blocks and textures.

**What it refuses, saying why:** a block that can't be flattened (members of mixed types; arrays not of `vec4`, `ivec4` or `mat4`);
a uniform block bound past 3 or a texture past 11, since every adapter binds blocks 0 to 3 and textures 0 to 11. Errors name the
source file's lines. Values passed between the stages may leave out their locations; the compiler numbers them.

**What's reflected is what's declared:** every uniform block and texture the source declares, at its binding and its declared size
(rounded up to whole `vec4`s, as GL's flattened array holds it), whether or not the code reads it, so commenting out a line never
changes what the program binds. A texture's kind comes from its GLSL type (`sampler2D`, `sampler2DArray`, `samplerCube`,
`sampler2DArrayShadow` for a shadow map's comparison); a texture the shader reads only with `texelFetch` is never filtered
(`ShaderSource`'s `data`), since fetching reads one exact texel.

**The tools,** pinned in `ShaderTools.hx` and made ready in the user's cache, checked by SHA-256, the first time a shader is compiled:
glslang's official release builds (Linux x86_64, macOS, Windows x64); SPIRV-Cross, which publishes source only, from the builds of the
pinned tag at github.com/whirlinggizmo/helix-tools (Linux x86_64 and ARM64, macOS universal, Windows x86_64), which also builds glslang
for Linux on ARM64. On a system without a build, SPIRV-Cross is built from its source by hxcpp. A shader author needs nothing but Haxe.
`HELIX_GLSLANG` and `HELIX_SPIRV_CROSS` name other builds of the tools.

## Audio

`IAudio`: output only.

- `available` (a device opened), `running` (producing sound now; in a page, after the user's first gesture), `playsUrls` (whether a
  stream can be a URL the platform plays itself).
- `createClip(samples, channels)` from float32 PCM at 44100 Hz, mono or stereo interleaved, `disposeClip`; `openStream(source, opened,
  failed)` returning an abort, `getStreamDuration` (seconds, 0 while unknown), `disposeStream`; `createQueue(channels, sampleRate)`,
  `queueSamples`, `getQueuedFrames` (not yet heard), `disposeQueue`.
- `playClip(clip, loop, volume)`, `playStream(stream, loop, volume)` and `playQueue(queue, volume)` giving a voice; `stop`, `pause`,
  `setVolume`, `setPitch`, `setPan` (equal power for a mono voice, a balance for a stereo one, as Web Audio's `StereoPannerNode`),
  `getPosition` and `setPosition` (seconds; a queue's voice isn't moved), `isPlaying`.
- `poll` (feeds the streams, delivers what the platform's threads finished, and in a page starts waiting voices); `dispose`.

A voice played in a page before audio runs waits, and starts when it does, in the order played: `play` returns its voice at once,
`stop`, `pause` and the setters work on it while it waits, and `isPlaying` is true. Buses, fades, ducking and what a player hears are
above.

A queue plays samples as they are added (raylib's `AudioStream`): back to back while they are added ahead, at the queue's own rate, which
the platform resamples. One that runs dry stays playing, silent, and goes on when fed; it has one voice, and stopping it drops what was
queued. A stream plays its file's channels.

A stream plays a `StreamSource`: `Local(location)` (a path natively, a Blob's URL in a page, as `IFileSystem.locate` gives it),
`Remote(url)` (only where `playsUrls`), or `Downloading(source)`, a `GrowingSource`: the file's room taken at the start, each part
appended as it arrives, `done` or `failure` at the end, written by whoever downloads it and read by the native output.

- **In a page, `audio/webaudio` (`WebAudioAdapter`):** clips are buffer sources, streams an `HTMLAudioElement` (which plays a URL itself,
  so `playsUrls` is true), each voice through a gain and a `StereoPannerNode`, a change approached by `setTargetAtTime`. A clip's
  position is counted from the context's clock; a stream's is the element's `currentTime`, its length the element's `duration`, and it
  moves only within the element's `seekable` ranges. A queue's blocks (one `queueSamples` each) are buffer sources scheduled back to back
  on the context's clock; its queued frames are counted from the scheduled end. Pitch is each source's playback rate, so a pitch change
  reschedules the blocks not yet started and the one playing finishes at its old rate.
- **Natively, `audio/sdl3mixer` (`Sdl3MixerAudioAdapter`):** SDL3_mixer on SDL3's default playback device. A voice is a track; a clip
  is audio loaded from its PCM; pitch is the track's frequency ratio. A stream is decoded by the adapter in `poll`, for up to 2 ms a
  frame and a second ahead, in its file's channels, into an audio stream the track plays, the track told to wait rather than stop when it
  runs dry. A clip's position is its track's; a stream's is counted from what was decoded less what the track hasn't taken, and it is
  moved by SDL3_mixer's own decoder seek (its internal header, as its API seeks only a track that decodes for itself); its length is the
  codec's, a download's once it has all arrived. A queue is an SDL audio stream bound to a track, SDL resampling it and locking it as
  the device's thread reads it. A download
  is copied into C as it arrives and read through an I/O stream whose size is what has arrived; it opens once 16 KiB have arrived,
  again each time that doubles while the codec can't yet, is decoded only while 16 KiB ahead of the decoder's reads (or complete), and
  its voice sounds once a second is decoded (a file's, a tenth). Volume and pan are equal power and ramped across each block, since SDL
  applies a gain at once; a stereo voice's pan is the same balance as a page's. `playsUrls` is false: a remote stream is downloaded above and handed over as `Downloading`. With no
  device, clips are still made, nothing plays, and `available` is false.

`platform/tests/native/native_sdl3mixer_audio.c` renders the native adapter's C with no device (`MIX_CreateMixer`, `MIX_Generate`):
clips, pan, pitch, the ramps, pause, stereo balance, positions read and moved, streams' lengths, streams from a file and from a download
arriving slowly or stopping, looping, queues fed, run dry and fed again, and a render thread racing the main one;
`native_sdl3mixer_device.c` plays silence on the real device (`helix.py test --native --audio-device`). `platform/tests/audio`
(`AudioTests`, run by `tools/platform_checks.py`) checks both adapters against the clock: natively on SDL3's dummy driver, which mixes in
time, and in a headless Chromium let start audio without a gesture: decoded channels, a stereo clip's position advancing and moved, a
stream's length and position, and a queue's frames falling, running dry and resuming.

## Decoders

`IAudioDecoder`: `decode(encoded, decoded(samples, channels), failed(message))`, float32 at 44100 Hz in the file's channels (mono or
stereo interleaved; more mixed down to stereo, by SDL's channel conversion natively and Web Audio's speaker down-mix in a page); `poll`;
`dispose`. It reads **WAV, Ogg
Vorbis, MP3 and FLAC**. In a page, `audiodecoder/webaudio` (`WebAudioDecoderAdapter`, `decodeAudioData` on a 44100 Hz
`OfflineAudioContext`, which may read more). Natively, `audiodecoder/sdl3mixer` (`Sdl3MixerAudioDecoderAdapter`): SDL3_mixer's decoder
on a worker thread, resampled to 44100 Hz, delivered at `poll`.

`IImageDecoder`: `decode(encoded, decoded(pixels, width, height), failed(message))`, the pixels 8-bit RGBA with rows top to bottom, not
premultiplied; `poll`; `dispose`. It reads **PNG, JPEG, BMP, TGA and GIF** (the first frame). In a page, `imagedecoder/canvas`
(`CanvasImageDecoderAdapter`): `createImageBitmap` with no color conversion or premultiplying, read back through an `OffscreenCanvas`,
which stores pixels premultiplied, so a partly transparent pixel may come back a level or two from the file's value. Natively,
`imagedecoder/stb` (`StbImageDecoderAdapter`): stb_image 2.30 (`platform/vendor/stb`) on a worker thread, exact, delivered at `poll`.

`IFontRasterizer`: `rasterize(encoded, size, codepoints, sdf, rasterized(glyphs, ascent, descent, lineGap), failed(message))`; `poll`;
`dispose`. It reads **TrueType and OpenType** fonts (not a collection's) and gives each codepoint's glyph (`RasterGlyph`): whether the font
has it, its bitmap (8-bit coverage, or signed distances: 4 pixels of padding, 128 on the outline, 64 a pixel), its offset from the pen and
the baseline, and its advance, with the font's ascent, descent and line gap. Sizes and lengths are stb_truetype's: the size is the pixel
height, ascent minus descent. Natively, `fontrasterizer/stb` (`StbFontRasterizerAdapter`): stb_truetype 1.26 (`platform/vendor/stb`) on
a worker thread. In a page, `fontrasterizer/canvas` (`CanvasFontRasterizerAdapter`): the font's tables read as stb_truetype reads them
(which glyphs it has, the metrics, the advances, and a TrueType glyph's box), so glyphs are found, sized and placed the same, and the
glyphs drawn by the browser with `fillText`, whose coverage may differ by a level or so at the edges; a CFF glyph's box is what the canvas
measures, and signed distances come from a distance transform of the glyph drawn 8 times larger, within about a sixteenth of a pixel.

SDL3_mixer 3.2.4 is vendored in `platform/vendor/sdl3_mixer` (its sources, pinned by a tree hash in `dependencies.json` that
`tools/sdl3.py` checks) and compiled with the program by hxcpp, with its built-in decoders only (WAV, stb_vorbis, dr_mp3, dr_flac). A
native program links no audio library but SDL3.

## Http

`IHttp`: `get(url, noCache, headers, head(status, headers), body(part), done(), failed(message))` returning an abort; `head` once (the
status and the headers, names in lower case), `body` for each part as it arrives, then `done` when the body is all here or `failed` when
the transfer failed. An HTTP error status is a response, not a failure. After an abort nothing more is called. `poll`; `dispose`, which
aborts every transfer. Queues, concurrency limits, retries, manifests and caching are above.

A conditional request (`If-None-Match`, `If-Modified-Since`) may be answered 200 with the whole body on any target, as HTTP allows any
server to. In a page, `http/fetchapi` (`FetchApiHttpAdapter`, over `fetch`, the body read as it arrives, aborted through an
`AbortController`) leaves those headers out of a request to another origin, where they would need a CORS preflight the server may
refuse, and has the browser revalidate its own copy instead. Natively, `http/haxehttp` (`HaxeHttpAdapter`, over `sys.Http`, a worker
thread a transfer) sends the headers as given; it fetches http and https URLs only, `noCache` has no cache to bypass, and an abort stops
a transfer at its next part of the body, not while it connects. Native HTTPS compiles but hasn't been checked against a server.

## File system

`IFileSystem`: files that reside on this machine, under one root given at construction (natively a directory, in a page an IndexedDB
database), read and written whole by path. A path is plain names joined by `/` (`audio/music.ogg`): letters, digits, `_`, `-` and `.`,
at most 256 characters, none empty, `.` or `..`; every adapter checks it, by `FilePath.isValid`, which a layer above may hold its other
sources to as well (helix-services' `Assets` does). There is no listing, no directories to make and no seeking.

- `root`, the root as given; `canWrite`, whether it can be written.
- `read(path, maxBytes, loaded(bytes), missing(), failed(message))`, a file over `maxBytes` failing, returning an abort;
- `write(path, bytes, written(), failed(message))`, replacing what is there, never leaving half a file;
- `deleteFile(path, deleted(), failed(message))`, deleted also when there was none;
- `deleteFiles(deleted(), failed(message))`;
- `locate(path, located(location, release), missing(), failed(message))`: the file for reading as a stream without reading it whole
  (a path natively, a Blob's URL in a page), held until `release` is called, once;
- `poll`, delivering what finished on the platform's threads; `dispose`.

Natively `filesystem/native` (`NativeFileSystemAdapter({directory: ..., readOnly: ...})`: each operation on a worker thread, each write whole or not
at all; opened read-only over `ISystem.getProgramDirectory()` for the files a program ships with); in a page `filesystem/browser`
(`BrowserFileSystemAdapter({name: ...})`, IndexedDB). A file system holds only what is on this machine: fetching from a server is `IHttp`, and
bringing a file in when it isn't there or is out of date is above.

## Clipboard

`IClipboard`: the system's clipboard, its text and an image as PNG. `requestText(read, ?failed)` and `requestImage(read, ?failed)`
answer once, during the call or later; `setText(text, ?done, ?failed)` and `setImage(png, ?done, ?failed)`; `dispose`.

- **In a page, `clipboard/dom` (`DomClipboardAdapter`):** the Clipboard API. A read needs the player's permission, which the browser
  may ask for; a write needs the keyboard, soon after a press; a page served without HTTPS (but localhost) has no clipboard. Chromium
  re-encodes an image put on it, so one read back is the same picture in another PNG.
- **Natively, `clipboard/sdl3` (`Sdl3ClipboardAdapter`):** SDL3's clipboard, made after the window; an image is offered as
  `image/png` and handed over when another program pastes. Each answer comes during the call.

## Export

`IExport`: `export(name, mimeType, bytes, exported(where), failed(message))` hands a finished file to the user: in a page a download
(`export/download`, `where` its file name), natively a file in the directory the adapter was made with (`export/filesystem`, `where` its
path, written whole or not at all). A name that isn't a plain file name throws. What is exported, what it's called and which directory it
goes to are the caller's.

## System

`ISystem`: facts about where the program runs, no meaning attached.

```haxe
interface ISystem {
	var company(default, null):String;               // helix-company, or DefaultCompany
	var product(default, null):String;               // helix-product, or the executable's name natively and Game in a page
	var device(get, never):Device;                  // what it runs on: browser, OS, architecture, touch screen, fine pointer
	function getOption(name:String):Null<String>;   // natively the environment variable HELIX_<NAME>; in a page the URL's query parameter
	function getTime():Float;                       // seconds on a monotonic clock: performance.now in a page, SDL's natively
	function getProgramDirectory():String;    // the files shipped with the program; "./" in a page, a URL
	function getDataDirectory():String;     // where lasting files go; a database's name in a page
	function getCacheDirectory():String;    // where what can be fetched again goes; a database's name in a page
}
```

- `getTime` never goes back or jumps when the system's clock is set; a pause in the program (a debugger, a hidden page) is time that
  passed.
- `getProgramDirectory` is the executable's directory natively (in a macOS app bundle, its `Contents/Resources`); in a page `"./"`,
  the page's own directory on its server, a URL `IHttp` fetches from.
- `getDataDirectory` is the user's data directory (`$XDG_DATA_HOME` or `~/.local/share` on Linux, `~/Library/Application Support` on
  macOS, `%APPDATA%` on Windows), then `<company>/<product>`, the names the `helix-company` and `helix-product` defines give
  ("DefaultCompany", and the executable's name natively or "Game" in a page, by default; the build fails for one that can't be a
  directory's name); `getCacheDirectory` the cache's (`$XDG_CACHE_HOME` or `~/.cache`,
  `~/Library/Caches`, `%LOCALAPPDATA%\<company>\<product>\cache`). Each comes from its environment variable when that's set (empty
  counts as unset) and from the OS when it isn't (the user database's home directory, Windows' shell folders); a variable set to a path
  that isn't absolute throws, naming it, where XDG would ignore it, since writing elsewhere would hide the mistake. In a page each is the
  name of a database, `<company>/<product>/data` and `/cache`, which a `BrowserFileSystemAdapter` opens. The SDL3 adapter keeps these
  rules itself rather than asking `SDL_GetPrefPath`: SDL has no cache directory, and it makes the directory as a side effect of the
  question.

## Page errors

An uncaught script error or an unhandled rejection in a page is not the platform's: catching it, stopping the frames and telling the
player are the owner's choices. A lost GPU context is the platform's, an event (`GraphicsLost`) the owner reads in its next poll.

## Not in the platform

What's above it: logging (helix-log, beside the platform); the loop and the frame's order; input state, edges and actions; audio buses
and fades; download queues and limits; caches, manifests and assets; saves; config; a game clock; every renderer and its programs and
pipelines. `adapters/shared/Mailbox` is an implementation helper behind the native adapters' `poll`, not a contract.
