# helix.platform.adapters

[Back to the index](README.md)

## Sdl3MixerAudioAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/audio/sdl3mixer/Sdl3MixerAudioAdapter.hx`](../../platform/src/helix/platform/adapters/audio/sdl3mixer/Sdl3MixerAudioAdapter.hx), `import helix.platform.adapters.audio.sdl3mixer.Sdl3MixerAudioAdapter;`, implements `IAudio`

Provides `IAudio` natively over SDL3_mixer on SDL3's default playback device.

Voices are SDL3_mixer's tracks; a stream is decoded on the main thread at each poll, up to a second ahead, from a file or from a download as it arrives, in its file's channels. A queue is an SDL audio stream its track plays, SDL resampling it. A stream's position is counted from what was decoded and what its track hasn't taken yet, and it is moved by SDL3_mixer's own decoder seek. A download opens once 16 KiB have arrived (or the whole, when smaller), tried again each time what has arrived doubles while its codec can't open it yet; it is decoded only while 16 KiB ahead of the decoder's reads, or complete, and its voice sounds once a second is decoded. A download that fails plays to where it stopped, then ends. A `Remote` source fails: the caller downloads it, `playsUrls` being false.

```haxe
function new()
var available(get, never):Bool
var running(get, never):Bool
var playsUrls(get, never):Bool
function createClip(samples:haxe.io.Bytes, channels:Int):Int
function disposeClip(clip:Int):Void
function openStream(source:StreamSource, opened:Int -> Void, failed:String -> Void):() -> Void
function disposeStream(stream:Int):Void
function getStreamDuration(stream:Int):Float
function createQueue(channels:Int, sampleRate:Int):Int
function queueSamples(queue:Int, samples:haxe.io.Bytes):Void
function getQueuedFrames(queue:Int):Int
function disposeQueue(queue:Int):Void
function playQueue(queue:Int, volume:Float):Int
function playClip(clip:Int, loop:Bool, volume:Float):Int
function playStream(stream:Int, loop:Bool, volume:Float):Int
function stop(voice:Int):Void
function pause(voice:Int, paused:Bool):Void
function setVolume(voice:Int, volume:Float):Bool
function setPitch(voice:Int, pitch:Float):Bool
function setPan(voice:Int, pan:Float):Bool
function isPlaying(voice:Int):Bool
function getPosition(voice:Int):Float
function setPosition(voice:Int, seconds:Float):Bool
function poll():Void
function dispose():Void
```

- `new`: Creates the output, opening the default playback device; with none, clips are still made, nothing plays and `available` is false.

## WebAudioAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/audio/webaudio/WebAudioAdapter.hx`](../../platform/src/helix/platform/adapters/audio/webaudio/WebAudioAdapter.hx), `import helix.platform.adapters.audio.webaudio.WebAudioAdapter;`, implements `IAudio`

Provides `IAudio` in a browser page, over Web Audio.

Clips are AudioBuffers and streams media elements routed through the audio graph, each voice a source through a gain and a stereo panner, its volume and pan changes approached by setTargetAtTime and its pitch the source's playback rate. A queue's blocks are AudioBuffers scheduled back to back on the context's clock, the browser resampling them; a pitch change reschedules the blocks not yet started. The page's first key, click or tap unlocks audio, as browsers let it start only in a user gesture; the page losing focus or being hidden suspends it. A voice asked for before then waits, its volume, pitch, pan and pause kept, and starts at the first poll once audio runs.

```haxe
function new()
var available(get, never):Bool
var playsUrls(get, never):Bool
var running(get, never):Bool
function createClip(samples:haxe.io.Bytes, channels:Int):Int
function getStreamDuration(stream:Int):Float
function openStream(source:StreamSource, opened:Int -> Void, failed:String -> Void):() -> Void
function playClip(clip:Int, loop:Bool, volume:Float):Int
function playStream(stream:Int, loop:Bool, volume:Float):Int
function createQueue(channels:Int, sampleRate:Int):Int
function queueSamples(queue:Int, samples:haxe.io.Bytes):Void
function getQueuedFrames(queue:Int):Int
function disposeQueue(queue:Int):Void
function playQueue(queue:Int, volume:Float):Int
function stop(id:Int):Void
function pause(id:Int, paused:Bool):Void
function setVolume(id:Int, volume:Float):Bool
function setPitch(id:Int, pitch:Float):Bool
function setPan(id:Int, pan:Float):Bool
function isPlaying(id:Int):Bool
function getPosition(id:Int):Float
function setPosition(id:Int, seconds:Float):Bool
function disposeClip(id:Int):Void
function disposeStream(id:Int):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the output, listening for the page's gestures (as they reach the window, before the page's own handlers) and its visibility; no AudioContext exists until a gesture unlocks audio.
- `poll`: Starts the voices that waited, in the order asked, once audio runs, and lets go of queue blocks played; media elements and the audio graph run on their own.

## Sdl3MixerAudioDecoderAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/audiodecoder/sdl3mixer/Sdl3MixerAudioDecoderAdapter.hx`](../../platform/src/helix/platform/adapters/audiodecoder/sdl3mixer/Sdl3MixerAudioDecoderAdapter.hx), `import helix.platform.adapters.audiodecoder.sdl3mixer.Sdl3MixerAudioDecoderAdapter;`, implements `IAudioDecoder`

Provides `IAudioDecoder` natively over SDL3_mixer's decoder: WAV, Ogg Vorbis, MP3 and FLAC, resampled to 44100 Hz by it, in the file's channels (more than 2 mixed down to stereo by SDL), each decode on a worker thread.

```haxe
function new()
function decode(encoded:haxe.io.Bytes, decoded:(samples:haxe.io.Bytes, channels:Int) -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the decoder.
- `dispose`: Closes the decoder: a decode still running on its worker finishes, and its answer is dropped.

## WebAudioDecoderAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/audiodecoder/webaudio/WebAudioDecoderAdapter.hx`](../../platform/src/helix/platform/adapters/audiodecoder/webaudio/WebAudioDecoderAdapter.hx), `import helix.platform.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter;`, implements `IAudioDecoder`

Provides `IAudioDecoder` in a browser page: decodeAudioData on an OfflineAudioContext at 44100 Hz, which needs no user gesture and resamples, in the file's channels; a file of more than 2 is rendered through a stereo OfflineAudioContext, which mixes it down by Web Audio's speaker rules.

```haxe
function new()
function decode(encoded:haxe.io.Bytes, decoded:(samples:haxe.io.Bytes, channels:Int) -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the decoder; the page's decoding context is made at the first decode.

## DomEventsAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/events/dom/DomEventsAdapter.hx`](../../platform/src/helix/platform/adapters/events/dom/DomEventsAdapter.hx), `import helix.platform.adapters.events.dom.DomEventsAdapter;`, implements `IEvents`

Provides `IEvents` in a browser page.

It listens to the page's focus and visibility, the viewport's size, which the canvas follows, and a lost WebGL context, and for the player's first press anywhere in the page, until it comes. Each listener only records; `poll` hands over what was recorded since the last one. The device adapters built over it (`DomKeyboardAdapter`, `DomMouseAdapter`, `DomTouchAdapter`, `DomGamepadsAdapter`, `DomTiltAdapter`) add their events to the same records.

```haxe
function new(options:DomEventsAdapterOptions)
function poll():Void
var unlocked(get, never):Bool
var events(get, never):Array<Event>
function wait(timeout:Float):Void
function dispose():Void
```

- `new`: Starts listening to the page and the canvas the program draws in.
  - `options`: The canvas's id.
  - throws `String`: No canvas has that id.

## DomEventsAdapterOptions

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/events/dom/DomEventsAdapterOptions.hx`](../../platform/src/helix/platform/adapters/events/dom/DomEventsAdapterOptions.hx), `import helix.platform.adapters.events.dom.DomEventsAdapterOptions;`

Represents what `DomEventsAdapter` listens to.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{canvasId:String}
```

```haxe
final canvasId:String
```

- `canvasId`: Gets the id of the canvas the program draws in: where the pointer is read and what the WebGL context belongs to.

## Sdl3EventsAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/events/sdl3/Sdl3EventsAdapter.hx`](../../platform/src/helix/platform/adapters/events/sdl3/Sdl3EventsAdapter.hx), `import helix.platform.adapters.events.sdl3.Sdl3EventsAdapter;`, implements `IEvents`

Provides `IEvents` on SDL3, natively: its one queue drained at each poll.

The window must be open (`Sdl3WindowAdapter`) before the first poll. SDL's events for a device are turned off until its adapter is constructed over this one (`Sdl3KeyboardAdapter`, `Sdl3MouseAdapter`, `Sdl3TouchAdapter`, `Sdl3GamepadsAdapter`), except a key, a mouse button and a finger lifting, which stay on until the first press has come.

```haxe
function new()
var unlocked(get, never):Bool
function poll():Void
var events(get, never):Array<Event>
function wait(timeout:Float):Void
function dispose():Void
```

- `new`: Sets up SDL's events, with no device's wanted yet.

## DownloadExportAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/export/download/DownloadExportAdapter.hx`](../../platform/src/helix/platform/adapters/export/download/DownloadExportAdapter.hx), `import helix.platform.adapters.export.download.DownloadExportAdapter;`, implements `IExport`

Provides `IExport` in a page: the file is downloaded, as a link with the download attribute does it; the browser may ask where, or keep it in its downloads.

The page can't know whether the user kept it: `exported` says only that the download began.

```haxe
function new()
function export(name:String, mimeType:String, bytes:haxe.io.Bytes, exported:(where:String) -> Void, failed:String -> Void):Void
```

- `new`: Creates the adapter, downloading through the page's document.

## FileSystemExportAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/export/filesystem/FileSystemExportAdapter.hx`](../../platform/src/helix/platform/adapters/export/filesystem/FileSystemExportAdapter.hx), `import helix.platform.adapters.export.filesystem.FileSystemExportAdapter;`, implements `IExport`

Provides `IExport` natively: the file is written into a directory, made when first needed, whole or not at all (`AtomicFile`).

```haxe
function new(options:FileSystemExportAdapterOptions)
function export(name:String, mimeType:String, bytes:haxe.io.Bytes, exported:(where:String) -> Void, failed:String -> Void):Void
```

- `new`: Creates the adapter.
  - `options`: The directory files go to.

## FileSystemExportAdapterOptions

*class*, native (cpp) in [`platform/src/helix/platform/adapters/export/filesystem/FileSystemExportAdapterOptions.hx`](../../platform/src/helix/platform/adapters/export/filesystem/FileSystemExportAdapterOptions.hx), `import helix.platform.adapters.export.filesystem.FileSystemExportAdapterOptions;`

Represents where `FileSystemExportAdapter` writes.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{directory:String}
```

```haxe
final directory:String
```

- `directory`: Gets the directory files go to, made when first needed.

## BrowserFileSystemAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/filesystem/browser/BrowserFileSystemAdapter.hx`](../../platform/src/helix/platform/adapters/filesystem/browser/BrowserFileSystemAdapter.hx), `import helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapter;`, implements `IFileSystem`

Provides `IFileSystem` in a page: Blobs in an IndexedDB database, a located file a Blob's URL, released by revoking it.

Operations asked before the database opens wait for it.

```haxe
function new(options:BrowserFileSystemAdapterOptions)
var root(get, never):String
var canWrite(get, never):Bool
function read(path:String, maxBytes:Int, loaded:haxe.io.Bytes -> Void, missing:() -> Void, failed:String -> Void):() -> Void
function write(path:String, bytes:haxe.io.Bytes, written:() -> Void, failed:String -> Void):Void
function deleteFile(path:String, deleted:() -> Void, failed:String -> Void):Void
function deleteFiles(deleted:() -> Void, failed:String -> Void):Void
function locate(path:String, located:(location:String, release:() -> Void) -> Void, missing:() -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Opens an IndexedDB database, creating it if needed; operations fail if it can't open.
  - `options`: The database's name.
- `poll`: Does nothing: IndexedDB's callbacks already run on the main thread.

## BrowserFileSystemAdapterOptions

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/filesystem/browser/BrowserFileSystemAdapterOptions.hx`](../../platform/src/helix/platform/adapters/filesystem/browser/BrowserFileSystemAdapterOptions.hx), `import helix.platform.adapters.filesystem.browser.BrowserFileSystemAdapterOptions;`

Represents the database `BrowserFileSystemAdapter` holds.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{name:String}
```

```haxe
final name:String
```

- `name`: Gets the IndexedDB database's name.

## NativeFileSystemAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/filesystem/native/NativeFileSystemAdapter.hx`](../../platform/src/helix/platform/adapters/filesystem/native/NativeFileSystemAdapter.hx), `import helix.platform.adapters.filesystem.native.NativeFileSystemAdapter;`, implements `IFileSystem`

Provides `IFileSystem` natively: files under a directory on disk, each operation on a worker thread.

A write is whole or not at all (`AtomicFile`), so a reader never sees half a file. A located file is its path, with nothing to release.

```haxe
function new(options:NativeFileSystemAdapterOptions)
var root(get, never):String
var canWrite(get, never):Bool
function read(path:String, maxBytes:Int, loaded:haxe.io.Bytes -> Void, missing:() -> Void, failed:String -> Void):() -> Void
function write(path:String, bytes:haxe.io.Bytes, written:() -> Void, failed:String -> Void):Void
function deleteFile(path:String, deleted:() -> Void, failed:String -> Void):Void
function deleteFiles(deleted:() -> Void, failed:String -> Void):Void
function locate(path:String, located:(location:String, release:() -> Void) -> Void, missing:() -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates a file system over a directory, made when first written.
  - `options`: The directory, and whether it is read-only.
- `dispose`: Does nothing to close: a worker still running finishes on its own, and its answer is dropped.

## NativeFileSystemAdapterOptions

*class*, native (cpp) in [`platform/src/helix/platform/adapters/filesystem/native/NativeFileSystemAdapterOptions.hx`](../../platform/src/helix/platform/adapters/filesystem/native/NativeFileSystemAdapterOptions.hx), `import helix.platform.adapters.filesystem.native.NativeFileSystemAdapterOptions;`

Represents the directory `NativeFileSystemAdapter` holds and how.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{directory:String, ?readOnly:Bool}
```

```haxe
final directory:String
final readOnly:Bool = false
```

- `directory`: Gets the directory, made when first written.
- `readOnly`: Gets a value indicating whether writing, removing and clearing are refused, as for the files a program ships with; false by default.

## CanvasFontRasterizerAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/fontrasterizer/canvas/CanvasFontRasterizerAdapter.hx`](../../platform/src/helix/platform/adapters/fontrasterizer/canvas/CanvasFontRasterizerAdapter.hx), `import helix.platform.adapters.fontrasterizer.canvas.CanvasFontRasterizerAdapter;`, implements `IFontRasterizer`

Provides `IFontRasterizer` in a page: the font loaded as a `FontFace` and its glyphs drawn with `fillText` on an `OffscreenCanvas`.

What stb_truetype reads from the font's tables is read here the same way (helix-formats' `TrueTypeTables`): the metrics, which glyphs it has, the advances, and a TrueType glyph's box, so glyphs are placed and sized as natively. The pixels are the browser's: coverage may differ by a level or so at a glyph's edges, and an OpenType glyph with CFF outlines is boxed by what the canvas measures. Signed distances come from the glyph drawn 8 times larger, by a distance transform, within about a sixteenth of a pixel of stb_truetype's.

```haxe
function new()
function rasterize(encoded:haxe.io.Bytes, size:Float, codepoints:Array<Int>, sdf:Bool, rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the rasterizer.
- `poll`: Does nothing: the page's promises already resolve on the main thread.

## StbFontRasterizerAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/fontrasterizer/stb/StbFontRasterizerAdapter.hx`](../../platform/src/helix/platform/adapters/fontrasterizer/stb/StbFontRasterizerAdapter.hx), `import helix.platform.adapters.fontrasterizer.stb.StbFontRasterizerAdapter;`, implements `IFontRasterizer`

Provides `IFontRasterizer` natively over stb_truetype, each rasterize on a worker thread.

```haxe
function new()
function rasterize(encoded:haxe.io.Bytes, size:Float, codepoints:Array<Int>, sdf:Bool, rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the rasterizer.
- `dispose`: Closes the rasterizer: a rasterize still running on its worker finishes, and its answer is dropped.

## DomGamepadsAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/gamepads/dom/DomGamepadsAdapter.hx`](../../platform/src/helix/platform/adapters/gamepads/dom/DomGamepadsAdapter.hx), `import helix.platform.adapters.gamepads.dom.DomGamepadsAdapter;`, implements `IGamepads`

Provides `IGamepads` in a browser page, read at each `IEvents.poll` in the W3C standard layout.

A page sees a pad only after a button press on it. The Gamepad API has no button events, so a change between two polls is one.

```haxe
function new(options:DomGamepadsAdapterOptions)
function isConnected(slot:Int):Bool
function getName(slot:Int):String
function isButtonDown(slot:Int, button:PadButton):Bool
function getAxis(slot:Int, axis:PadAxis):Float
function dispose():Void
```

- `new`: Starts reading the gamepads at each poll.
  - `options`: The events adapter whose poll reads them.

## DomGamepadsAdapterOptions

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/gamepads/dom/DomGamepadsAdapterOptions.hx`](../../platform/src/helix/platform/adapters/gamepads/dom/DomGamepadsAdapterOptions.hx), `import helix.platform.adapters.gamepads.dom.DomGamepadsAdapterOptions;`

Represents what `DomGamepadsAdapter` is built over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{events:DomEventsAdapter}
```

```haxe
final events:DomEventsAdapter
```

- `events`: Gets the events adapter whose `poll` delivers its events.

## Sdl3GamepadsAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/gamepads/sdl3/Sdl3GamepadsAdapter.hx`](../../platform/src/helix/platform/adapters/gamepads/sdl3/Sdl3GamepadsAdapter.hx), `import helix.platform.adapters.gamepads.sdl3.Sdl3GamepadsAdapter;`, implements `IGamepads`

Provides `IGamepads` on SDL3, natively, through SDL's controller database, in the W3C standard layout.

SDL's gamepad subsystem starts with it and stops at `dispose`. Pads are read whether the window has the keyboard or not.

```haxe
function new(options:Sdl3GamepadsAdapterOptions)
function isConnected(slot:Int):Bool
function getName(slot:Int):String
function isButtonDown(slot:Int, button:PadButton):Bool
function getAxis(slot:Int, axis:PadAxis):Float
function dispose():Void
```

- `new`: Starts SDL's gamepads.
  - `options`: The events adapter its events are delivered by.

## Sdl3GamepadsAdapterOptions

*class*, native (cpp) in [`platform/src/helix/platform/adapters/gamepads/sdl3/Sdl3GamepadsAdapterOptions.hx`](../../platform/src/helix/platform/adapters/gamepads/sdl3/Sdl3GamepadsAdapterOptions.hx), `import helix.platform.adapters.gamepads.sdl3.Sdl3GamepadsAdapterOptions;`

Represents what `Sdl3GamepadsAdapter` is built over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{events:Sdl3EventsAdapter}
```

```haxe
final events:Sdl3EventsAdapter
```

- `events`: Gets the events adapter whose `poll` delivers its events.

## Sdl3GpuGraphicsAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/graphics/sdl3gpu/Sdl3GpuGraphicsAdapter.hx`](../../platform/src/helix/platform/adapters/graphics/sdl3gpu/Sdl3GpuGraphicsAdapter.hx), `import helix.platform.adapters.graphics.sdl3gpu.Sdl3GpuGraphicsAdapter;`, extends `NativeGraphics`, implements `IGraphics`

Provides `IGraphics` on SDL_GPU, natively: Vulkan, Direct3D 12 or Metal.

SDL picks the backend for the system; the environment variable SDL_GPU_DRIVER chooses another. Programs come from a `ShaderSource`'s SDL_GPU stages (`ShaderSource.sdlGpu`).

```haxe
function new()
function createShader(source:ShaderSource):Int
function dispose():Void
```

- `new`: Creates the GPU device and claims the window, which must already exist.
  - throws `String`: SDL cannot create the device or claim the window.

## SokolGraphicsAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/graphics/sokol/SokolGraphicsAdapter.hx`](../../platform/src/helix/platform/adapters/graphics/sokol/SokolGraphicsAdapter.hx), `import helix.platform.adapters.graphics.sokol.SokolGraphicsAdapter;`, extends `NativeGraphics`, implements `IGraphics`

Provides `IGraphics` on sokol_gfx, natively, drawing with GL 4.1 in the window's context.

Programs come from a `ShaderSource`'s GLSL 410.

```haxe
function new()
function createShader(source:ShaderSource):Int
function dispose():Void
```

- `new`: Creates the adapter, setting up sokol_gfx in the window's GL context, which must already exist.

## WebGl2GraphicsAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/graphics/webgl2/WebGl2GraphicsAdapter.hx`](../../platform/src/helix/platform/adapters/graphics/webgl2/WebGl2GraphicsAdapter.hx), `import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapter;`, implements `IGraphics`

Provides `IGraphics` on a canvas's WebGL2 context.

It builds programs from a `ShaderSource`'s GLSL ES 300 and pipelines from a `PipelineDesc`.

```haxe
function new(options:WebGl2GraphicsAdapterOptions)
var msaaSamples(get, never):Int
var maxMsaaSamples(get, never):Int
function createTexture(width:Int, height:Int, levels:Array<haxe.io.Bytes>, ?format:TextureFormat = Rgba8):Int
function createDataTexture(width:Int, height:Int):Int
function updateDataTexture(handle:Int, data:haxe.io.Bytes):Void
function createCubeTexture(size:Int, levels:Array<haxe.io.Bytes>, format:TextureFormat):Int
function canSample(format:TextureFormat):Bool
function createBuffer(capacityBytes:Int):Int
function createStaticBuffer(data:haxe.io.Bytes, bytes:Int, index:Bool):Int
function updateBuffer(handle:Int, data:haxe.io.Bytes, usedBytes:Int):Void
function createShader(source:ShaderSource):Int
function disposeShader(handle:Int):Void
function createPipeline(desc:PipelineDesc):Int
function disposePipeline(handle:Int):Void
function canRender(format:TextureFormat):Bool
function createRenderTarget(width:Int, height:Int, ?format:TextureFormat = Rgba8, ?depth:Bool = true):Int
function createShadowMap(size:Int, layers:Int):Int
function beginShadowPass(map:Int, layer:Int):Void
function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void
function endTargetPass():Void
function beginFrame(width:Int, height:Int, clearColor:Int):Void
function applyScissor(x:Int, y:Int, w:Int, h:Int):Void
function resetScissor():Void
function applyViewport(x:Int, y:Int, w:Int, h:Int):Void
function draw(pipeline:Int, buffers:Array<Int>, indices:Int, first:Int, count:Int, firstInstance:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<haxe.io.Bytes>>):Void
function endFrame():Void
function present():Void
function readPixels(target:Int, read:(pixels:haxe.io.Bytes, width:Int, height:Int) -> Void, failed:String -> Void):Void
function disposeBuffer(handle:Int):Void
function disposeTexture(handle:Int):Void
function dispose():Void
```

- `new`: Creates the adapter on a canvas's WebGL2 context.
  - `options`: The canvas's id, its samples and whether its drawing buffer is kept.
  - throws `String`: No canvas has that id.
  - throws `GraphicsUnavailableException`: The browser has no WebGL2.

  The context has a depth buffer and no alpha or stencil. When antialiased, the browser chooses the number of samples, nearly always 4.

## WebGl2GraphicsAdapterOptions

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/graphics/webgl2/WebGl2GraphicsAdapterOptions.hx`](../../platform/src/helix/platform/adapters/graphics/webgl2/WebGl2GraphicsAdapterOptions.hx), `import helix.platform.adapters.graphics.webgl2.WebGl2GraphicsAdapterOptions;`

Represents how `WebGl2GraphicsAdapter` makes its context.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{canvasId:String, ?msaaSamples:Int, ?preserveDrawingBuffer:Bool}
```

```haxe
final canvasId:String
final msaaSamples:Int = 1
final preserveDrawingBuffer:Bool = false
```

- `canvasId`: Gets the id of the canvas whose WebGL2 context is drawn with.
- `msaaSamples`: Gets the multisampling samples a pixel asks for; 1 for none, the default. Over 1 makes the context antialiased, and the browser chooses the number, nearly always 4.
- `preserveDrawingBuffer`: Gets a value indicating whether the drawing buffer is kept after a frame is shown, so it can be read back later; false by default.

## FetchApiHttpAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/http/fetchapi/FetchApiHttpAdapter.hx`](../../platform/src/helix/platform/adapters/http/fetchapi/FetchApiHttpAdapter.hx), `import helix.platform.adapters.http.fetchapi.FetchApiHttpAdapter;`, implements `IHttp`

Provides `IHttp` in a page over `fetch`: the body read as it arrives, aborted through an `AbortController`.

Conditional headers (`If-None-Match`, `If-Modified-Since`) to another origin would need a CORS preflight the server may refuse, so there they are left out and the browser revalidates its own copy instead (cache `no-cache`), answering 200.

```haxe
function new()
function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:haxe.io.Bytes -> Void, done:() -> Void, failed:String -> Void):() -> Void
function poll():Void
function dispose():Void
```

- `new`: Creates the adapter.
- `poll`: Does nothing: the page's callbacks already run on the main thread.

## HaxeHttpAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/http/haxehttp/HaxeHttpAdapter.hx`](../../platform/src/helix/platform/adapters/http/haxehttp/HaxeHttpAdapter.hx), `import helix.platform.adapters.http.haxehttp.HaxeHttpAdapter;`, implements `IHttp`

Provides `IHttp` natively over `sys.Http`, on a worker thread for each transfer.

It fetches http and https URLs only, failing others; `noCache` has no cache to bypass; an abort stops a transfer at its next part of the body, not while it connects.

```haxe
function new()
function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:haxe.io.Bytes -> Void, done:() -> Void, failed:String -> Void):() -> Void
function poll():Void
function dispose():Void
```

- `new`: Creates the adapter.

## CanvasImageDecoderAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/imagedecoder/canvas/CanvasImageDecoderAdapter.hx`](../../platform/src/helix/platform/adapters/imagedecoder/canvas/CanvasImageDecoderAdapter.hx), `import helix.platform.adapters.imagedecoder.canvas.CanvasImageDecoderAdapter;`, implements `IImageDecoder`

Provides `IImageDecoder` in a page over its own decoder (`createImageBitmap`, with no color conversion or premultiplying), read back through an `OffscreenCanvas`.

The canvas stores pixels premultiplied, so a partly transparent pixel may come back a level or two from the file's value.

```haxe
function new()
function decode(encoded:haxe.io.Bytes, decoded:(pixels:haxe.io.Bytes, width:Int, height:Int) -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the decoder.
- `poll`: Does nothing: the page's promises already resolve on the main thread.

## StbImageDecoderAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/imagedecoder/stb/StbImageDecoderAdapter.hx`](../../platform/src/helix/platform/adapters/imagedecoder/stb/StbImageDecoderAdapter.hx), `import helix.platform.adapters.imagedecoder.stb.StbImageDecoderAdapter;`, implements `IImageDecoder`

Provides `IImageDecoder` natively over stb_image, each decode on a worker thread.

```haxe
function new()
function decode(encoded:haxe.io.Bytes, decoded:(pixels:haxe.io.Bytes, width:Int, height:Int) -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `new`: Creates the decoder.
- `dispose`: Closes the decoder: a decode still running on its worker finishes, and its answer is dropped.

## DomKeyboardAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/keyboard/dom/DomKeyboardAdapter.hx`](../../platform/src/helix/platform/adapters/keyboard/dom/DomKeyboardAdapter.hx), `import helix.platform.adapters.keyboard.dom.DomKeyboardAdapter;`, implements `IKeyboard`

Provides `IKeyboard` in a browser page: keys and typed text from the window.

A key still down when the page loses the keyboard arrives as a `KeyUp` just before `FocusLost`, as a page gets no keyup for a key let go while it hasn't the keyboard. The page keeps its own shortcuts (with Ctrl, Meta or Alt) and the function keys; the program gets the rest.

```haxe
function new(options:DomKeyboardAdapterOptions)
var textInput(get, set):Bool
function dispose():Void
```

- `new`: Starts listening to the keyboard.
  - `options`: The events adapter its events are delivered by.
- `textInput`: Gets or sets whether typed text arrives. A computer's keys type while it is on; a phone shows no keyboard, which needs a focused input element.

## DomKeyboardAdapterOptions

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/keyboard/dom/DomKeyboardAdapterOptions.hx`](../../platform/src/helix/platform/adapters/keyboard/dom/DomKeyboardAdapterOptions.hx), `import helix.platform.adapters.keyboard.dom.DomKeyboardAdapterOptions;`

Represents what `DomKeyboardAdapter` is built over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{events:DomEventsAdapter}
```

```haxe
final events:DomEventsAdapter
```

- `events`: Gets the events adapter whose `poll` delivers its events.

## Sdl3KeyboardAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/keyboard/sdl3/Sdl3KeyboardAdapter.hx`](../../platform/src/helix/platform/adapters/keyboard/sdl3/Sdl3KeyboardAdapter.hx), `import helix.platform.adapters.keyboard.sdl3.Sdl3KeyboardAdapter;`, implements `IKeyboard`

Provides `IKeyboard` on SDL3, natively: keys by their physical position, and typed text through SDL's text input.

SDL lets go of each key still down as the window loses the keyboard, so its `KeyUp` arrives.

```haxe
function new(options:Sdl3KeyboardAdapterOptions)
var textInput(get, set):Bool
function dispose():Void
```

- `new`: Turns SDL's keyboard events on.
  - `options`: The events adapter its events are delivered by.
- `textInput`: Gets or sets whether typed text arrives. While it is on, SDL's text input is started on the window: a phone shows its keyboard, and Windows with a gamepad plugged in may show its touch keyboard.

## Sdl3KeyboardAdapterOptions

*class*, native (cpp) in [`platform/src/helix/platform/adapters/keyboard/sdl3/Sdl3KeyboardAdapterOptions.hx`](../../platform/src/helix/platform/adapters/keyboard/sdl3/Sdl3KeyboardAdapterOptions.hx), `import helix.platform.adapters.keyboard.sdl3.Sdl3KeyboardAdapterOptions;`

Represents what `Sdl3KeyboardAdapter` is built over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{events:Sdl3EventsAdapter}
```

```haxe
final events:Sdl3EventsAdapter
```

- `events`: Gets the events adapter whose `poll` delivers its events.

## DomMouseAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/mouse/dom/DomMouseAdapter.hx`](../../platform/src/helix/platform/adapters/mouse/dom/DomMouseAdapter.hx), `import helix.platform.adapters.mouse.dom.DomMouseAdapter;`, implements `IMouse`

Provides `IMouse` in a browser page: the mouse's and a pen's buttons, moves and wheel over the canvas, in its framebuffer pixels.

The canvas keeps a pressed mouse until it is let go, so a drag out of it still arrives. Its context menu is kept from showing.

```haxe
function new(options:DomMouseAdapterOptions)
function dispose():Void
```

- `new`: Starts listening to the mouse over the canvas.
  - `options`: The events adapter its events are delivered by.

## DomMouseAdapterOptions

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/mouse/dom/DomMouseAdapterOptions.hx`](../../platform/src/helix/platform/adapters/mouse/dom/DomMouseAdapterOptions.hx), `import helix.platform.adapters.mouse.dom.DomMouseAdapterOptions;`

Represents what `DomMouseAdapter` is built over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{events:DomEventsAdapter}
```

```haxe
final events:DomEventsAdapter
```

- `events`: Gets the events adapter whose `poll` delivers its events.

## Sdl3MouseAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/mouse/sdl3/Sdl3MouseAdapter.hx`](../../platform/src/helix/platform/adapters/mouse/sdl3/Sdl3MouseAdapter.hx), `import helix.platform.adapters.mouse.sdl3.Sdl3MouseAdapter;`, implements `IMouse`

Provides `IMouse` on SDL3, natively: the mouse's and a pen's buttons, moves and wheel over the window, in framebuffer pixels. SDL's mouse made of a touch is passed over.

```haxe
function new(options:Sdl3MouseAdapterOptions)
function dispose():Void
```

- `new`: Turns SDL's mouse events on.
  - `options`: The events adapter its events are delivered by.

## Sdl3MouseAdapterOptions

*class*, native (cpp) in [`platform/src/helix/platform/adapters/mouse/sdl3/Sdl3MouseAdapterOptions.hx`](../../platform/src/helix/platform/adapters/mouse/sdl3/Sdl3MouseAdapterOptions.hx), `import helix.platform.adapters.mouse.sdl3.Sdl3MouseAdapterOptions;`

Represents what `Sdl3MouseAdapter` is built over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{events:Sdl3EventsAdapter}
```

```haxe
final events:Sdl3EventsAdapter
```

- `events`: Gets the events adapter whose `poll` delivers its events.

## DomSystemAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/system/dom/DomSystemAdapter.hx`](../../platform/src/helix/platform/adapters/system/dom/DomSystemAdapter.hx), `import helix.platform.adapters.system.dom.DomSystemAdapter;`, implements `ISystem`

Provides `ISystem` in a browser page: the device as the browser describes it, and options from the URL's query.

The system comes from the user agent, a touch screen from its touch points, a fine pointer from the any-pointer media query.

```haxe
function new()
var company(default, null):String
var product(default, null):String
var device(get, never):Device
function getOption(name:String):Null<String>
function getTime():Float
function getProgramDirectory():String
function getDataDirectory():String
function getCacheDirectory():String
```

- `new`: Creates the system's facts for the program the `helix-company` and `helix-product` defines name.

## Sdl3SystemAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/system/sdl3/Sdl3SystemAdapter.hx`](../../platform/src/helix/platform/adapters/system/sdl3/Sdl3SystemAdapter.hx), `import helix.platform.adapters.system.sdl3.Sdl3SystemAdapter;`, implements `ISystem`

Provides `ISystem` on SDL3, natively: the platform SDL names, options from HELIX_ environment variables, SDL's monotonic clock, the program's directory as SDL finds it, and the OS's directories by each OS's rules.

A mouse is assumed and no touch screen reported. The directories follow the rules SDL's `SDL_GetPrefPath` does for data, without its making the directory, and the same OS conventions for the cache, which SDL has no call for. Each comes from its environment variable when that's set, and from the OS when it isn't (the user database's home directory, Windows' shell folders); an empty one counts as unset. A variable set to a path that isn't absolute throws, naming it, where the XDG specification would ignore it: someone set it, and quietly writing elsewhere would hide the mistake.

```haxe
function new()
var company(default, null):String
var product(default, null):String
var device(get, never):Device
function getOption(name:String):Null<String>
function getTime():Float
function getProgramDirectory():String
function getDataDirectory():String
function getCacheDirectory():String
```

- `new`: Creates the system's facts for the program the `helix-company` and `helix-product` defines name.
  - throws `String`: For an executable whose name can't be one directory's name, when `helix-product` is unset.

## DomTiltAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/tilt/dom/DomTiltAdapter.hx`](../../platform/src/helix/platform/adapters/tilt/dom/DomTiltAdapter.hx), `import helix.platform.adapters.tilt.dom.DomTiltAdapter;`, implements `ITilt`

Provides `ITilt` in a browser page: the device's orientation (deviceorientation), asked for at the player's next tap where the browser wants permission (iOS, and Chrome on Android).

```haxe
function new(options:DomTiltAdapterOptions)
function requestAccess(?done:() -> Void, ?failed:String -> Void):Bool
function releaseAccess():Void
function dispose():Void
```

- `new`: Creates the tilt, off until `requestAccess`.
  - `options`: The events adapter its events are delivered by.
- `requestAccess`: Asks for the device's orientation.
  Where the browser asks for permission (iOS, and Chrome on Android), it is asked at the player's next tap, which shows its prompt. A page that isn't secure gets no readings (NeedsHttps). No reading within a second and a half of the page having its focus is reported unavailable without calling `failed`, and it goes on listening, as a phone's sensor may start late.
- `releaseAccess`: Stops the readings and any ask still waiting for a tap.

## DomTiltAdapterOptions

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/tilt/dom/DomTiltAdapterOptions.hx`](../../platform/src/helix/platform/adapters/tilt/dom/DomTiltAdapterOptions.hx), `import helix.platform.adapters.tilt.dom.DomTiltAdapterOptions;`

Represents what `DomTiltAdapter` is built over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{events:DomEventsAdapter}
```

```haxe
final events:DomEventsAdapter
```

- `events`: Gets the events adapter whose `poll` delivers its events.

## Sdl3TiltAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/tilt/sdl3/Sdl3TiltAdapter.hx`](../../platform/src/helix/platform/adapters/tilt/sdl3/Sdl3TiltAdapter.hx), `import helix.platform.adapters.tilt.sdl3.Sdl3TiltAdapter;`, implements `ITilt`

Provides `ITilt` on SDL3, natively. No motion sensor is read yet, so the tilt is unavailable on every target.

```haxe
function new(options:Sdl3TiltAdapterOptions)
function requestAccess(?done:() -> Void, ?failed:String -> Void):Bool
function releaseAccess():Void
function dispose():Void
```

- `new`: Creates the tilt.
  - `options`: The events adapter its events are delivered by.
- `requestAccess`: Returns false, calling neither callback, and reports `Unavailable` at the next poll: no motion sensor is read.
- `releaseAccess`: Does nothing: nothing is read.
- `dispose`: Does nothing: nothing is read.

## Sdl3TiltAdapterOptions

*class*, native (cpp) in [`platform/src/helix/platform/adapters/tilt/sdl3/Sdl3TiltAdapterOptions.hx`](../../platform/src/helix/platform/adapters/tilt/sdl3/Sdl3TiltAdapterOptions.hx), `import helix.platform.adapters.tilt.sdl3.Sdl3TiltAdapterOptions;`

Represents what `Sdl3TiltAdapter` is built over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{events:Sdl3EventsAdapter}
```

```haxe
final events:Sdl3EventsAdapter
```

- `events`: Gets the events adapter whose `poll` delivers its events.

## DomTouchAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/touch/dom/DomTouchAdapter.hx`](../../platform/src/helix/platform/adapters/touch/dom/DomTouchAdapter.hx), `import helix.platform.adapters.touch.dom.DomTouchAdapter;`, implements `ITouch`

Provides `ITouch` in a browser page: fingers on the canvas, in its framebuffer pixels.

The canvas keeps a finger until it lifts, so one sliding off it still arrives. While it exists the canvas's `touch-action` is `none`, so the browser doesn't take a moving finger to scroll or zoom the page, which would cancel it; one the browser takes anyway arrives as its `TouchUp`.

```haxe
function new(options:DomTouchAdapterOptions)
function dispose():Void
```

- `new`: Starts listening to fingers on the canvas.
  - `options`: The events adapter its events are delivered by.

## DomTouchAdapterOptions

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/touch/dom/DomTouchAdapterOptions.hx`](../../platform/src/helix/platform/adapters/touch/dom/DomTouchAdapterOptions.hx), `import helix.platform.adapters.touch.dom.DomTouchAdapterOptions;`

Represents what `DomTouchAdapter` is built over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{events:DomEventsAdapter}
```

```haxe
final events:DomEventsAdapter
```

- `events`: Gets the events adapter whose `poll` delivers its events.

## Sdl3TouchAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/touch/sdl3/Sdl3TouchAdapter.hx`](../../platform/src/helix/platform/adapters/touch/sdl3/Sdl3TouchAdapter.hx), `import helix.platform.adapters.touch.sdl3.Sdl3TouchAdapter;`, implements `ITouch`

Provides `ITouch` on SDL3, natively: fingers on the window, in framebuffer pixels, each numbered by its place among the fingers down. A touch SDL cancels arrives as its `TouchUp`.

```haxe
function new(options:Sdl3TouchAdapterOptions)
function dispose():Void
```

- `new`: Turns SDL's finger events on.
  - `options`: The events adapter its events are delivered by.

## Sdl3TouchAdapterOptions

*class*, native (cpp) in [`platform/src/helix/platform/adapters/touch/sdl3/Sdl3TouchAdapterOptions.hx`](../../platform/src/helix/platform/adapters/touch/sdl3/Sdl3TouchAdapterOptions.hx), `import helix.platform.adapters.touch.sdl3.Sdl3TouchAdapterOptions;`

Represents what `Sdl3TouchAdapter` is built over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{events:Sdl3EventsAdapter}
```

```haxe
final events:Sdl3EventsAdapter
```

- `events`: Gets the events adapter whose `poll` delivers its events.

## DomWindowAdapter

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/window/dom/DomWindowAdapter.hx`](../../platform/src/helix/platform/adapters/window/dom/DomWindowAdapter.hx), `import helix.platform.adapters.window.dom.DomWindowAdapter;`, implements `IWindow`

Provides `IWindow` in a browser page: the page is the window.

Its title is the document's, its size the viewport's, and fullscreen and visibility are the canvas's, whose drawing size follows the viewport and the pixel ratio. A page can't move or size its window, choose a monitor, or close; it sees one screen.

```haxe
function new(options:DomWindowAdapterOptions)
var framebufferWidth(get, never):Int
var framebufferHeight(get, never):Int
var pixelRatio(get, never):Float
var focused(get, never):Bool
var title(get, set):String
var width(get, never):Int
var height(get, never):Int
function requestSize(width:Int, height:Int):Bool
function canMove():Bool
var x(get, never):Int
var y(get, never):Int
function requestPosition(x:Int, y:Int):Bool
var orientation(get, never):Orientation
function requestOrientation(orientation:Orientation, ?done:() -> Void, ?failed:String -> Void):Bool
function canFullscreen():Bool
var fullscreen(get, never):Bool
function requestFullscreen(enabled:Bool, ?done:() -> Void, ?failed:String -> Void):Bool
var visible(get, never):Bool
function requestVisible(visible:Bool):Bool
var monitorCount(get, never):Int
var monitorIndex(get, never):Int
function requestMonitorIndex(index:Int):Bool
function getMonitorName(index:Int):String
function getMonitorX(index:Int):Int
function getMonitorY(index:Int):Int
function getMonitorWidth(index:Int):Int
function getMonitorHeight(index:Int):Int
function canClose():Bool
function close():Void
var onClose:Null<() -> Void>
```

- `new`: Creates the page's window over the canvas the program draws in, sizing its drawing buffer to the viewport.
  - `options`: The canvas's id.
  - throws `String`: No canvas has that id.

## DomWindowAdapterOptions

*class*, for the browser (js) in [`platform/src/helix/platform/adapters/window/dom/DomWindowAdapterOptions.hx`](../../platform/src/helix/platform/adapters/window/dom/DomWindowAdapterOptions.hx), `import helix.platform.adapters.window.dom.DomWindowAdapterOptions;`

Represents what `DomWindowAdapter` is made over.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{canvasId:String}
```

```haxe
final canvasId:String
```

- `canvasId`: Gets the id of the canvas the program draws in: what goes fullscreen or hides, and the drawing surface.

## Sdl3WindowAdapter

*class*, native (cpp) in [`platform/src/helix/platform/adapters/window/sdl3/Sdl3WindowAdapter.hx`](../../platform/src/helix/platform/adapters/window/sdl3/Sdl3WindowAdapter.hx), `import helix.platform.adapters.window.sdl3.Sdl3WindowAdapter;`, implements `IWindow`

Provides `IWindow` on an SDL3 window, natively.

The window opens with the adapter, before the graphics adapter that draws in it. Moves are refused where the compositor places windows (Wayland, XWayland); orientation is a page's alone.

```haxe
function new(options:Sdl3WindowAdapterOptions)
var framebufferWidth(get, never):Int
var framebufferHeight(get, never):Int
var pixelRatio(get, never):Float
var focused(get, never):Bool
var title(get, set):String
var width(get, never):Int
var height(get, never):Int
function requestSize(width:Int, height:Int):Bool
function canMove():Bool
var x(get, never):Int
var y(get, never):Int
function requestPosition(x:Int, y:Int):Bool
function canFullscreen():Bool
var fullscreen(get, never):Bool
function requestFullscreen(enabled:Bool, ?done:() -> Void, ?failed:String -> Void):Bool
var orientation(get, never):Orientation
function requestOrientation(orientation:Orientation, ?done:() -> Void, ?failed:String -> Void):Bool
var visible(get, never):Bool
function requestVisible(visible:Bool):Bool
var monitorCount(get, never):Int
var monitorIndex(get, never):Int
function requestMonitorIndex(index:Int):Bool
function getMonitorName(index:Int):String
function getMonitorX(index:Int):Int
function getMonitorY(index:Int):Int
function getMonitorWidth(index:Int):Int
function getMonitorHeight(index:Int):Int
function canClose():Bool
function close():Void
var onClose:Null<() -> Void>
```

- `new`: Opens the program's window.
  - `options`: The graphics adapter it is for, its samples, and whether presenting waits for the display.
  - throws `String`: SDL or the window can't be had.

## Sdl3WindowAdapterOptions

*class*, native (cpp) in [`platform/src/helix/platform/adapters/window/sdl3/Sdl3WindowAdapterOptions.hx`](../../platform/src/helix/platform/adapters/window/sdl3/Sdl3WindowAdapterOptions.hx), `import helix.platform.adapters.window.sdl3.Sdl3WindowAdapterOptions;`

Represents how `Sdl3WindowAdapter` opens its window.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{graphics:Sdl3WindowGraphics, ?msaaSamples:Int, ?vsync:Bool}
```

```haxe
final graphics:Sdl3WindowGraphics
final msaaSamples:Int = 1
final vsync:Bool = true
```

- `graphics`: Gets the graphics adapter that draws in the window.
- `msaaSamples`: Gets the multisampling samples a pixel asks for; 1 for none, the default. The GPU may give fewer.
- `vsync`: Gets whether presenting waits for the display's refresh, which paces the owner's loop: true, the default. False shows each frame as soon as it is drawn, which may tear.

## Sdl3WindowGraphics

*enum*, native (cpp) in [`platform/src/helix/platform/adapters/window/sdl3/Sdl3WindowGraphics.hx`](../../platform/src/helix/platform/adapters/window/sdl3/Sdl3WindowGraphics.hx), `import helix.platform.adapters.window.sdl3.Sdl3WindowGraphics;`

Specifies the graphics adapter an SDL3 window is opened for.

- `Gl`: A GL 4.1 context, for `SokolGraphicsAdapter`.
- `Gpu`: No GL context, for `Sdl3GpuGraphicsAdapter`.
