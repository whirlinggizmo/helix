# helix.platform

[Back to the index](README.md)

## BlendMode

*abstract* in [`platform/src/helix/platform/BlendMode.hx`](../../platform/src/helix/platform/BlendMode.hx), `import helix.platform.BlendMode;`

Specifies how a pipeline's colors are combined with the colors already in the target.

Colors use straight (not premultiplied) alpha.

- `BlendMode.Opaque`: The color replaces the target's.
- `BlendMode.Alpha`: The color is blended over the target's by its alpha.
- `BlendMode.Additive`: The color, multiplied by its alpha, is added to the target's: for light, fire and glows.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## ClipFlip

*abstract* in [`platform/src/helix/platform/ClipFlip.hx`](../../platform/src/helix/platform/ClipFlip.hx), `import helix.platform.ClipFlip;`

Specifies what a pipeline's uniform block 0 holds, so that an adapter can draw a render target the right way up.

An adapter whose render targets are stored bottom row first (GL's) flips its draws into a target. With ClipScale it writes block 0 as (1, -1) in such a pass and (1, 1) otherwise; with ViewProjection it negates the y row of the column-major matrix in block 0's first 64 bytes in such a pass. An adapter whose targets are stored top row first ignores it.

- `ClipFlip.None`: Block 0 is not touched, or there is none.
- `ClipFlip.ClipScale`: Block 0 is a vec4 clip scale that the adapter writes.
- `ClipFlip.ViewProjection`: Block 0 starts with a view-projection matrix whose y row the adapter negates.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## Color

*class* in [`platform/src/helix/platform/Color.hx`](../../platform/src/helix/platform/Color.hx), `import helix.platform.Color;`

Provides functions for colors held as 0xAARRGGBB integers, alpha in the top byte.

Each channel is 0 to 255. Text writes a color in CSS order, #RRGGBB or #RRGGBBAA; `fromRgba` and `toRgba` convert between that order and this one.

```haxe
var orange = Color.fromChannels(255, 128, 0);
var faded = Color.withAlpha(orange, 128);
```

```haxe
static function fromChannels(red:Int, green:Int, blue:Int, ?alpha:Int = 255):Int
static function getRed(color:Int):Int
static function getGreen(color:Int):Int
static function getBlue(color:Int):Int
static function getAlpha(color:Int):Int
static function withAlpha(color:Int, alpha:Int):Int
static function fromRgba(rgba:Int):Int
static function toRgba(color:Int):Int
```

- `fromChannels`: Returns the color with the given channels.
  - `red`: The red channel, 0 to 255.
  - `green`: The green channel, 0 to 255.
  - `blue`: The blue channel, 0 to 255.
  - `alpha`: Optional. The alpha channel, 0 (clear) to 255 (opaque); defaults to 255.
  - returns: The color, as 0xAARRGGBB.

  Only the low 8 bits of each channel are used.
- `getRed`: Returns a color's red channel.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The red channel, 0 to 255.
- `getGreen`: Returns a color's green channel.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The green channel, 0 to 255.
- `getBlue`: Returns a color's blue channel.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The blue channel, 0 to 255.
- `getAlpha`: Returns a color's alpha channel.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The alpha channel, 0 (clear) to 255 (opaque).
- `withAlpha`: Returns a color with its alpha channel replaced.
  - `color`: The color, as 0xAARRGGBB.
  - `alpha`: The new alpha channel, 0 (clear) to 255 (opaque).
  - returns: The color with the new alpha.

  Only the low 8 bits of alpha are used.
- `fromRgba`: Returns the color that an integer in CSS order names.
  - `rgba`: The color, as 0xRRGGBBAA.
  - returns: The color, as 0xAARRGGBB.
- `toRgba`: Returns a color as an integer in CSS order.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The color, as 0xRRGGBBAA.

## CullFace

*abstract* in [`platform/src/helix/platform/CullFace.hx`](../../platform/src/helix/platform/CullFace.hx), `import helix.platform.CullFace;`

Specifies which faces of a pipeline's triangles are not drawn.

- `CullFace.None`: No faces are culled: both sides are drawn.
- `CullFace.Back`: Back faces, those facing away, are culled: the far side of a closed surface.
- `CullFace.Front`: Front faces are culled: only a surface's far side is drawn, as for an outline's shell.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## DepthTest

*abstract* in [`platform/src/helix/platform/DepthTest.hx`](../../platform/src/helix/platform/DepthTest.hx), `import helix.platform.DepthTest;`

Specifies which fragments a pipeline's depth test passes, compared with the depth already in the target.

- `DepthTest.Off`: No test: every fragment is drawn.
- `DepthTest.LessEqual`: Fragments as near as or nearer than the depth there pass: the usual test.
- `DepthTest.Greater`: Fragments farther than the depth there pass: only what is hidden behind something drawn before.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## Device

*class* in [`platform/src/helix/platform/Device.hx`](../../platform/src/helix/platform/Device.hx), `import helix.platform.Device;`

Represents what the program runs on, as far as the platform says: a browser or native, the operating system, a touch screen, a fine pointer.

A game uses it for what it shows by device: touch controls on a phone, "tap" or "click" in a prompt, a landscape lock. A browser can be wrong about a laptop with a touch screen (it has both), so touch controls also appear on the first touch, not by device alone.

```haxe
final browser:Bool
final os:String
final touchScreen:Bool
final finePointer:Bool
var mobile(get, never):Bool
```

- `browser`: Gets a value indicating whether the program runs in a browser page rather than natively.
- `os`: Gets the operating system, lowercase: "windows", "macos", "linux", "android", "ios", "chromeos"; "" when the platform doesn't say.
- `touchScreen`: Gets a value indicating whether there is a touch screen; natively always false.
- `finePointer`: Gets a value indicating whether there is a fine pointer: a mouse, a trackpad or a pen. False on a phone or a tablet alone.
- `mobile`: Gets a value indicating whether it is a phone or a tablet: a touch screen and no fine pointer.

## Event

*enum* in [`platform/src/helix/platform/Event.hx`](../../platform/src/helix/platform/Event.hx), `import helix.platform.Event;`

Represents one thing that happened, as `IEvents.poll` delivers it.

Positions are framebuffer pixels from the window's top-left. A key is its physical position on a US layout (`Key`), right-hand modifiers reported as the left-hand ones.

- `KeyDown(key:Key, repeat:Bool)`: A key went down; repeat is true when the OS repeats a held key.
- `KeyUp(key:Key)`: A key went up.
- `Text(text:String)`: Characters were typed, while `IEvents.setTextInput` is on.
- `MouseMove(x:Float, y:Float)`: The mouse moved over the window.
- `MouseDown(button:MouseButton, x:Float, y:Float)`: A mouse button went down.
- `MouseUp(button:MouseButton, x:Float, y:Float)`: A mouse button went up.
- `MouseLeave`: The mouse left the window.
- `Wheel(dx:Float, dy:Float)`: The wheel turned, in notches: right and away from the player positive.
- `TouchDown(id:Int, x:Float, y:Float)`: A finger touched the screen; id is the same for that finger until it lifts.
- `TouchMove(id:Int, x:Float, y:Float)`: A finger moved.
- `TouchUp(id:Int, x:Float, y:Float)`: A finger lifted, or the OS took the touch away.
- `Tilt(beta:Float, gamma:Float, screenAngle:Float)`: The device's orientation, while `IEvents.setTiltWanted` is on: beta and gamma in degrees, and the screen's angle.
- `TiltState(state:Int)`: The tilt's state changed: 0 off, 1 waiting for the player's permission, 2 calibrating, 3 on, 4 refused, 5 unavailable, 6 unavailable because the page isn't secure (HTTPS).
- `PadConnected(slot:Int)`: A gamepad was connected in a slot, 0 to 3.
- `PadDisconnected(slot:Int)`: The gamepad in a slot was disconnected; its buttons count as up.
- `PadButtonDown(slot:Int, button:PadButton)`: A gamepad's button went down. A trigger is a button too, down past half way.
- `PadButtonUp(slot:Int, button:PadButton)`: A gamepad's button went up. Natively the Guide button's release arrives no sooner than a quarter second after its press.
- `Resized(width:Int, height:Int)`: The drawable area changed size, in framebuffer pixels.
- `FocusGained`: The window got the keyboard.
- `FocusLost`: The window lost the keyboard; each key still down came up just before, a `KeyUp` each.
- `Shown`: The player can see the window again: restored, or the page in front again.
- `Hidden`: The player can't see the window: minimized or hidden, or the page in the background.
- `CloseRequested`: The player or the OS asked to close the window, natively; the owner decides.
- `GraphicsLost`: The GPU's context is gone: in a page, the WebGL context lost to a GPU reset or an evicted tab.

## Filter

*abstract* in [`platform/src/helix/platform/Filter.hx`](../../platform/src/helix/platform/Filter.hx), `import helix.platform.Filter;`

Specifies how a texture is filtered when drawn at a size other than its own.

- `Filter.Nearest`: The nearest texel: sharp, for pixel art.
- `Filter.Linear`: Neighboring texels blended: smooth, and through the texture's mipmaps when it has them, so it shrinks without shimmering.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## GraphicsUnavailableException

*class* in [`platform/src/helix/platform/GraphicsUnavailableException.hx`](../../platform/src/helix/platform/GraphicsUnavailableException.hx), `import helix.platform.GraphicsUnavailableException;`

Represents the error a graphics adapter throws when the GPU API it draws through is missing, such as WebGL2 in a browser without it.

A caller can tell it apart from a failure in the program's own code and report the platform as unsupported.

```haxe
function new(message:String, ?previous:haxe.Exception, ?native:Any)
```


## GrowingSource

*class* in [`platform/src/helix/platform/GrowingSource.hx`](../../platform/src/helix/platform/GrowingSource.hx), `import helix.platform.GrowingSource;`

Represents a file arriving from a download, readable while it arrives.

The downloader appends each part as it comes; a native audio output reads what has arrived. The whole file's room is taken at the start, since its length is known, so the bytes never move and what has arrived is the first `received` of them. Use it on the main thread only.

```haxe
function new(total:Int)
static function of(bytes:haxe.io.Bytes):GrowingSource
var bytes(default, null):haxe.io.Bytes
var received(default, null):Int
var total(default, null):Int
var done(default, null):Bool
var failure(default, null):Null<String>
function append(part:haxe.io.Bytes):Bool
function fail(message:String):Void
```

- `new`: Creates a source with none of its bytes arrived yet.
  - `total`: The file's length in bytes, 0 or more.
- `of`: Returns a source with the whole of a file arrived.
  - `bytes`: The file.
  - returns: The source, done.
- `bytes`: Gets the file's bytes, `total` long: the first `received` of them have arrived, the rest are zero.
- `received`: Gets how many bytes have arrived, 0 to `total`.
- `total`: Gets the file's length in bytes.
- `done`: Gets a value indicating whether the whole file has arrived.
- `failure`: Gets why the download failed, or null while it hasn't; once set, no more arrives.
- `append`: Adds a part after what has arrived; the source is done once the file is whole.
  - `part`: The next bytes of the file.
  - returns: False, adding nothing, past the file's length or once the download ended.
- `fail`: Ends the download short; does nothing once the file is whole or already failed.
  - `message`: Why it failed.

## IAudio

*class* in [`platform/src/helix/platform/IAudio.hx`](../../platform/src/helix/platform/IAudio.hx), `import helix.platform.IAudio;`

Defines the sound output: clips held whole and streams played as they are read, each played as voices.

Clip, stream and voice ids are the adapter's. Samples are mono 32-bit float PCM at 44100 Hz, -1 to 1. A browser starts its audio on the page's first key or pointer press and suspends it while the page is hidden or blurred; natively it runs once the device opens.

```haxe
var available(get, never):Bool
var running(get, never):Bool
var playsUrls(get, never):Bool
function createClip(samples:haxe.io.Bytes):Int
function disposeClip(clip:Int):Void
function openStream(source:StreamSource, opened:Int -> Void, failed:String -> Void):() -> Void
function disposeStream(stream:Int):Void
function playClip(clip:Int, loop:Bool, volume:Float):Int
function playStream(stream:Int, loop:Bool, volume:Float):Int
function stop(voice:Int):Void
function pause(voice:Int, paused:Bool):Void
function setVolume(voice:Int, volume:Float):Bool
function setPitch(voice:Int, pitch:Float):Bool
function setPan(voice:Int, pan:Float):Bool
function isPlaying(voice:Int):Bool
function poll():Void
function dispose():Void
```

- `available`: Gets a value indicating whether there is an output at all: false natively without an audio device.
- `running`: Gets a value indicating whether voices are heard now.
  In a browser it's false until the page's first key press, mouse button or tap, which the adapter listens for and unlocks audio at itself, and false again while the page is hidden. Natively it's true once the device opens. A voice asked for before then waits and starts once it runs (`playClip`).
- `playsUrls`: Gets a value indicating whether `openStream` plays a `Remote` source's URL itself.
  True in a browser, whose media element streams the URL. False natively: the caller downloads the file and opens the download (`Downloading`).
- `createClip`: Copies samples into a new clip.
  - `samples`: Mono 32-bit float PCM at 44100 Hz, -1 to 1.
  - returns: The clip's id.
  - `String`: When there is no room for the clip.
- `disposeClip`: Disposes a clip and stops its voices.
  - `clip`: The clip.
  - `String`: For an unknown clip.
- `openStream`: Opens a source for playing as it is read.
  - `source`: What to play.
  - `opened`: Receives the stream's id.
  - `failed`: Receives why it can't be opened: natively a `Remote` source, a file its codec can't read, or a download that failed or ended unreadable; in a browser a load error, no metadata within 15 seconds, or a `Downloading` source.
  - returns: A function that aborts the open: neither callback is called after it, and an opened stream is closed.

  One of `opened` or `failed` is called once, on the main thread, never during this call. A download is opened once enough of it has arrived for its codec. A `Local` source's file must outlive the stream.
- `disposeStream`: Disposes a stream and stops its voices.
  - `stream`: The stream.
  - `String`: For an unknown stream.
- `playClip`: Starts a clip playing.
  - `clip`: The clip.
  - `loop`: True to play it again from the start each time it ends.
  - `volume`: The volume, 0 to 1.
  - returns: The voice's id, or 0 when there is no output (`available`). Asked for before audio runs, the voice waits, its volume, pitch, pan and pause kept, and starts at the first `poll` once it does; meanwhile `isPlaying` is true.
  - `String`: For an unknown clip.
- `playStream`: Starts a stream playing from its beginning.
  - `stream`: The stream.
  - `loop`: True to play it again from the start each time it ends.
  - `volume`: The volume, 0 to 1.
  - returns: The voice's id, or 0 when there is no output (`available`) or, natively, a file that can't be played. Asked for before audio runs, the voice waits and starts once it does, as `playClip`'s.
  - `String`: For an unknown stream.
- `stop`: Stops a voice; does nothing for an unknown or ended one.
  - `voice`: The voice.
- `pause`: Pauses or resumes a voice; does nothing for an unknown one.
  - `voice`: The voice.
  - `paused`: True to pause it, false to resume it.
- `setVolume`: Sets a voice's volume.
  - `voice`: The voice.
  - `volume`: The volume, 0 to 1.
  - returns: False, changing nothing, for a voice not playing (unknown, stopped or ended) or a volume outside 0 to 1.

  The change is ramped over a few milliseconds (the output's next block), so a fade stepped once a frame doesn't click.
- `setPitch`: Sets a voice's playback rate, which changes its pitch and length together.
  - `voice`: The voice.
  - `pitch`: The rate, 0.25 to 4; 1 as recorded.
  - returns: False, changing nothing, for a voice not playing (unknown, stopped or ended).
- `setPan`: Sets a voice's pan, equal power.
  - `voice`: The voice.
  - `pan`: -1 left to 1 right; 0 the middle.
  - returns: False, changing nothing, for a voice not playing (unknown, stopped or ended).

  The change is ramped as a volume's is.
- `isPlaying`: Returns whether a voice is still playing or paused.
  - `voice`: The voice.
  - returns: False once it ended or was stopped, and for an unknown voice.
- `poll`: Keeps streamed voices fed, opens downloads that have arrived far enough, and delivers what the platform's threads finished; call once a frame.
- `dispose`: Stops every voice, disposes every stream and clip, and closes the output.

## IAudioDecoder

*class* in [`platform/src/helix/platform/IAudioDecoder.hx`](../../platform/src/helix/platform/IAudioDecoder.hx), `import helix.platform.IAudioDecoder;`

Defines audio decoding: a whole WAV (PCM or float, any rate), Ogg Vorbis, MP3 or FLAC file, mono or stereo, into mono 32-bit float PCM at 44100 Hz, samples -1 to 1, mixed down and resampled.

```haxe
function decode(encoded:haxe.io.Bytes, decoded:haxe.io.Bytes -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `decode`: Decodes a file, off the main thread where the platform can.
  - `encoded`: The file's bytes.
  - `decoded`: Receives the samples.
  - `failed`: Receives why the file can't be read.

  One of `decoded` or `failed` is called once, on the main thread, never during this call.
- `poll`: Delivers what finished on the platform's threads since the last poll; call once a frame.
- `dispose`: Closes the decoder; a decode still running finishes without answering.

## IEvents

*class* in [`platform/src/helix/platform/IEvents.hx`](../../platform/src/helix/platform/IEvents.hx), `import helix.platform.IEvents;`

Defines the input and the window's events, pulled once a frame, and the gamepads' state.

What happens (keys, text, the mouse, touches, a pad connecting, a pad's buttons, the window resized, focused or closed) arrives as `Event` records from `poll`, in the order the OS gave them; natively a button pressed and let go between two polls arrives as both, while a page reads its pads only at each poll, so it sees one only if it is down then. What is held (a stick, a trigger, a pad's buttons) can also be read directly after it. Nothing is delivered between polls, and nothing calls the program: the owner walks `events`.

```haxe
events.poll();
for (event in events.events)
switch event {
case KeyDown(key, _): pressed(key);
case CloseRequested: window.close();
case _:
}
var stick = events.getPadAxis(0, 0);
```

```haxe
function poll():Void
var events(get, never):Array<Event>
function wait(timeout:Float):Void
function setTextInput(on:Bool):Void
function setTiltWanted(on:Bool):Void
var activated(get, never):Bool
function isPadConnected(slot:Int):Bool
function getPadName(slot:Int):String
function isPadButtonDown(slot:Int, button:PadButton):Bool
function getPadAxis(slot:Int, axis:PadAxis):Float
function dispose():Void
```

- `poll`: Drains the OS's queue into `events`: this frame's events, in order. Last frame's are cleared.
- `events`: Gets the events the last `poll` delivered. The array is reused by the next poll.
- `wait`: Sleeps in the OS until an event arrives or the timeout passes, using no CPU; does nothing in a page.
  - `timeout`: The longest wait, in seconds.

  A native loop calls it while the window can't be seen (after `Hidden`), so it doesn't spin, waking at the timeout to service what must not starve. Events that arrive stay for the next `poll`.
- `setTextInput`: Starts or stops typed text: `Text` events arrive only while it is on, and a phone shows its keyboard then.
  - `on`: True to start.
- `setTiltWanted`: Starts or stops reading the device's orientation as `Tilt` events.
  - `on`: True to start.

  A page may need the player's permission, asked at their next tap; `TiltState` events report how it went.
- `activated`: Gets a value indicating whether the player has pressed a key, a button or a finger yet: a browser allows audio and fullscreen only after that. Always true natively.
- `isPadConnected`: Returns whether a gamepad is in a slot, as of the last `poll`.
  - `slot`: The slot, 0 to 3.
  - returns: True when one is connected there.
- `getPadName`: Returns a slot's gamepad's name.
  - `slot`: The slot, 0 to 3.
  - returns: The name, or "" when the slot is empty.
- `isPadButtonDown`: Returns whether a gamepad's button is down, as of the last `poll`.
  - `slot`: The slot, 0 to 3.
  - `button`: The button.
  - returns: True when it is down; false for an empty slot.
- `getPadAxis`: Returns a gamepad's axis, as of the last `poll`.
  - `slot`: The slot, 0 to 3.
  - `axis`: The axis.
  - returns: A stick from -1 to 1, down and right positive; a trigger from 0 to 1; 0 for an empty slot.
- `dispose`: Releases the events' resources: listeners, the gamepads.

## IExport

*class* in [`platform/src/helix/platform/IExport.hx`](../../platform/src/helix/platform/IExport.hx), `import helix.platform.IExport;`

Defines handing a finished file to the user: in a page a download, natively a file in a directory chosen when the adapter is made.

```haxe
function export(name:String, mimeType:String, bytes:haxe.io.Bytes, exported:(where:String) -> Void, failed:String -> Void):Void
```

- `export`: Hands a file over; natively a file of the same name is replaced, never left half written.
  - `name`: The file's name: no directory, not hidden.
  - `mimeType`: Its type, such as `"image/png"`.
  - `bytes`: The file.
  - `exported`: Receives where it went: its path natively, its file name in a page, where the download only began.
  - `failed`: Receives why it couldn't be, such as no room or no permission.
  - `String`: A name that isn't a plain file name.

  One of `exported` or `failed` is called once, on the main thread, during this call or later.

## IFileSystem

*class* in [`platform/src/helix/platform/IFileSystem.hx`](../../platform/src/helix/platform/IFileSystem.hx), `import helix.platform.IFileSystem;`

Defines files under one root, read and written whole by path: natively a directory on disk, in a page the server or an IndexedDB database.

There is no listing, no directories to make, no seeking and no metadata: a file is reached by its path, read whole or located for streaming, and written whole or not at all. Those are a page's limits, kept natively so a program works the same on both.

A path is plain names joined by `/` (`audio/music.ogg`): letters, digits, `_`, `-` and `.`, at most 256 characters. An absolute path, an empty name, `.` or `..` is refused, as `failed`. One of each call's callbacks is called once, on the main thread, never during the call; `missing` is a file that isn't there, `failed` anything else, with why.

```haxe
files.read("levels/1.json", 1 << 20, bytes -> start(bytes), () -> trace("no level 1"), why -> trace(why));
```

```haxe
var root(get, never):String
var canWrite(get, never):Bool
function read(path:String, maxBytes:Int, loaded:haxe.io.Bytes -> Void, missing:() -> Void, failed:String -> Void):() -> Void
function write(path:String, bytes:haxe.io.Bytes, written:() -> Void, failed:String -> Void):Void
function remove(path:String, removed:() -> Void, failed:String -> Void):Void
function clear(cleared:() -> Void, failed:String -> Void):Void
function locate(path:String, located:(location:String, release:() -> Void) -> Void, missing:() -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `root`: Gets the root, as the adapter was given it: a directory, a URL or a database's name.
- `canWrite`: Gets a value indicating whether files can be written here: false for a server.
- `read`: Reads a whole file.
  - `path`: The file's path under the root.
  - `maxBytes`: The largest file to read; a larger one fails.
  - `loaded`: Receives the file's bytes.
  - `missing`: Called when there is no file at the path.
  - `failed`: Receives why it can't be read.
  - returns: The abort: nothing is called after it.
- `write`: Writes a whole file, replacing what is there; a reader never sees half of it.
  - `path`: The file's path under the root; the directories above it are made.
  - `bytes`: The file's contents.
  - `written`: Called once it is kept.
  - `failed`: Receives why it can't be written: a root that can't be (`canWrite`), no room, or the platform's reason.
- `remove`: Removes a file; removing one that isn't there succeeds.
  - `path`: The file's path under the root.
  - `removed`: Called once it is gone.
  - `failed`: Receives why it can't be removed.
- `clear`: Removes every file under the root, for a cache.
  - `cleared`: Called once they are gone.
  - `failed`: Receives why they can't be removed.
- `locate`: Finds where a file is, for playing it as it is read, without loading it whole.
  - `path`: The file's path under the root.
  - `located`: Receives the location and the function that releases it, called once when it is no longer read.
  - `missing`: Called when there is no file at the path.
  - `failed`: Receives why it can't be located.

  Natively the file's path; in a page a URL the audio output plays, kept until `release` is called.
- `poll`: Delivers what finished on the platform's threads since the last poll; call once a frame.
- `dispose`: Closes the file system; what is still running finishes without answering.

## IGraphics

*class* in [`platform/src/helix/platform/IGraphics.hx`](../../platform/src/helix/platform/IGraphics.hx), `import helix.platform.IGraphics;`

Defines the GPU as a platform's graphics adapter provides it: resources, passes and one draw.

Resources are textures of a few kinds, buffers, programs built from a `ShaderSource` and pipelines made from a `PipelineDesc`. A frame is any passes into render targets and shadow maps, then the screen's pass from `beginFrame` to `endFrame`. An adapter knows no program, layout or pipeline of its caller's: the caller describes them as data. Whoever creates a handle disposes it, once.

A call that cannot be done throws before doing anything.

```haxe
function createTexture(width:Int, height:Int, levels:Array<haxe.io.Bytes>, ?format:TextureFormat = Rgba8):Int
function createCubeTexture(size:Int, levels:Array<haxe.io.Bytes>, format:TextureFormat):Int
function createDataTexture(width:Int, height:Int):Int
function updateDataTexture(handle:Int, data:haxe.io.Bytes):Void
function canSample(format:TextureFormat):Bool
var msaaSamples(get, never):Int
var maxMsaaSamples(get, never):Int
function createRenderTarget(width:Int, height:Int, ?format:TextureFormat = Rgba8, ?depth:Bool = true):Int
function canRender(format:TextureFormat):Bool
function createShadowMap(size:Int, layers:Int):Int
function disposeTexture(handle:Int):Void
function createBuffer(capacityBytes:Int):Int
function createStaticBuffer(data:haxe.io.Bytes, bytes:Int, index:Bool):Int
function updateBuffer(handle:Int, data:haxe.io.Bytes, usedBytes:Int):Void
function disposeBuffer(handle:Int):Void
function createShader(source:ShaderSource):Int
function disposeShader(handle:Int):Void
function createPipeline(desc:PipelineDesc):Int
function disposePipeline(handle:Int):Void
function beginShadowPass(map:Int, layer:Int):Void
function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void
function endTargetPass():Void
function beginFrame(width:Int, height:Int, clearColor:Int):Void
function applyViewport(x:Int, y:Int, w:Int, h:Int):Void
function applyScissor(x:Int, y:Int, w:Int, h:Int):Void
function resetScissor():Void
function draw(pipeline:Int, buffers:Array<Int>, indices:Int, first:Int, count:Int, firstInstance:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<haxe.io.Bytes>>):Void
function endFrame():Void
function present():Void
function readPixels(target:Int, read:(pixels:haxe.io.Bytes, width:Int, height:Int) -> Void, failed:String -> Void):Void
function dispose():Void
```

- `createTexture`: Uploads an image as a texture.
  - `width`: The width, in texels.
  - `height`: The height, in texels.
  - `levels`: The image, rows top first, then optionally its mipmaps, each half the size of the last (at least 1); each level `format.levelBytes` of its size.
  - `format`: Optional. The texels' format; defaults to Rgba8.
  - returns: The texture's handle.
  - `String`: A size of 0 or less, no levels, a level of the wrong size, or a format this GPU cannot sample.

  How the texture is sampled is each draw's (`Sampling`).
- `createCubeTexture`: Uploads a cubemap.
  - `size`: Each face's width and height, in texels.
  - `levels`: Mip 0 then optionally its mips, each half the size of the last (at least 1). Each level is its six faces in order +X, -X, +Y, -Y, +Z, -Z, in GL's cube orientation (a face's first row is its t = 0), each face `format.levelBytes` of its size.
  - `format`: The texels' format.
  - returns: The cubemap's handle.
  - `String`: A size of 0 or less, no levels, a level of the wrong size, or a format this GPU cannot sample.

  A cubemap is sampled at a texture slot like any texture. The sampling's filter applies and its wrap is ignored.
- `createDataTexture`: Creates a data texture of RGBA 32-bit floats, 16 bytes a texel.
  - `width`: The width, in texels.
  - `height`: The height, in texels.
  - returns: The data texture's handle.
  - `String`: A size of 0 or less, or larger than this GPU allows.

  A data texture is read texel by texel and never filtered: its samplings are ignored. `updateDataTexture` fills it.
- `updateDataTexture`: Replaces a data texture's contents for the draws after it.
  - `handle`: The data texture.
  - `data`: At least width * height * 16 bytes: rows top first, little-endian floats.
  - `String`: A handle that is not a data texture, or data that is too short.

  It can be called any number of times a frame.
- `canSample`: Returns whether this GPU samples textures of a format.
  - `format`: The format.
  - returns: True when textures of the format can be sampled.

  RGBA8 is always sampled. The compressed formats are sampled on GPUs that have them, and half floats where this GPU filters them.
- `msaaSamples`: Gets the number of multisampling samples a pixel the screen is drawn with: 1 for none.
  It can be fewer than the window asked for. Render targets with depth are drawn with the same number, resolved into the texture that is sampled.
- `maxMsaaSamples`: Gets the largest number of multisampling samples a window could ask for here, at most 8.
  A browser only switches antialiasing on or off and chooses its own count, so in a browser it is the count the canvas has when antialiasing is on: 4 where the GPU supports 4, else 1.
- `createRenderTarget`: Creates a render target: a texture that a target pass draws into.
  - `width`: The width, in texels.
  - `height`: The height, in texels.
  - `format`: Optional. The texels' format; defaults to Rgba8.
  - `depth`: Optional. Whether it has a depth buffer; defaults to true.
  - returns: The render target's handle.
  - `String`: A size of 0 or less, or a format this GPU cannot draw into (`canRender`).

  The target is sampled like any texture and stored top row first. With depth, it has its own depth buffer and is multisampled as the screen is (`msaaSamples`), or single-sampled where this GPU cannot multisample the format, resolved into the texture at the end of each pass. Without depth it has neither, for a pass that draws over the whole target.
- `canRender`: Returns whether this GPU draws into, blends over and filters render targets of a format.
  - `format`: The format.
  - returns: True when render targets of the format can be drawn into.

  RGBA8 always can. RGBA16F can where float targets exist: nearly always natively, and in a browser through EXT_color_buffer_float. A compressed format never can.
- `createShadowMap`: Creates a shadow map: a depth texture of layers that shadow passes draw into.
  - `size`: Each layer's width and height, in texels.
  - `layers`: The number of layers.
  - returns: The shadow map's handle.
  - `String`: A size or layer count of 0 or less, or larger than this GPU allows.

  A program that declares a shadow texture samples it through a comparison sampler: linear, less or equal, clamped to its edge. The slot's sampling is ignored. Its rows are stored bottom first, as GL's: clip space's -1 to 1 is its 0 to 1.
- `disposeTexture`: Frees a texture of any kind.
  - `handle`: The texture.
  - `String`: An unknown handle.
- `createBuffer`: Creates a stream vertex buffer, filled each frame by `updateBuffer`.
  - `capacityBytes`: The capacity, in bytes: a positive multiple of 4.
  - returns: The buffer's handle.
  - `String`: Any other size.
- `createStaticBuffer`: Creates an immutable buffer of vertices or indices.
  - `data`: The contents.
  - `bytes`: The number of bytes of data to use: a positive multiple of 4.
  - `index`: Whether the buffer holds uint32 indices (little-endian) rather than vertices.
  - returns: The buffer's handle.
  - `String`: A size that is not a positive multiple of 4.
- `updateBuffer`: Replaces a stream buffer's contents for the draws after it.
  - `handle`: The stream buffer.
  - `data`: The new contents.
  - `usedBytes`: The number of bytes of data to use.
  - `String`: A call outside a pass, an unknown handle, or a size out of range.

  It can be called inside a pass any number of times a frame: a buffer drawn into a target and then the screen is uploaded twice.
- `disposeBuffer`: Frees a buffer.
  - `handle`: The buffer.
  - `String`: An unknown handle.
- `createShader`: Builds a program, for pipelines.
  - `source`: The program: the dialect this adapter compiles, its attributes by slot, its uniform blocks, and its textures, each a plain, cube, shadow or data texture.
  - returns: The program's handle.
  - `String`: A program that does not build, with the compiler's log.
- `disposeShader`: Frees a program, disposing the pipelines made with it first.
  - `handle`: The program.
  - `String`: An unknown handle.
- `createPipeline`: Creates a pipeline.
  - `desc`: What the pipeline fixes for its draws.
  - returns: The pipeline's handle.
  - `String`: An unknown program, or a description this adapter cannot make.
- `disposePipeline`: Frees a pipeline.
  - `handle`: The pipeline.
  - `String`: An unknown handle.
- `beginShadowPass`: Starts a depth-only pass into one layer of a shadow map, for depth-only pipelines.
  - `map`: The shadow map: a `createShadowMap` handle.
  - `layer`: The layer to draw into.
  - `String`: A call inside a pass, a handle that is not a shadow map, or a layer it does not have.

  The layer is cleared to the farthest depth and the viewport set to all of it. The pass comes before the screen's and outside any other; `endTargetPass` ends it.
- `beginTargetPass`: Starts a pass into a render target.
  - `target`: The render target: a `createRenderTarget` handle.
  - `red`: The clear color's red.
  - `green`: The clear color's green.
  - `blue`: The clear color's blue.
  - `alpha`: The clear color's alpha.
  - `String`: A call inside a pass, or a handle that is not a render target.

  The target is cleared to the color, as its texels store it: 0 to 1 in an RGBA8 target, beyond 1 in a half-float one. Its depth, if it has one, is cleared to the farthest, and the viewport is set to all of it. The pass comes before the screen's and outside any other; `endTargetPass` ends it.
- `endTargetPass`: Ends the pass that `beginTargetPass` or `beginShadowPass` started.
  - `String`: No such pass is open.

  Its target can be sampled from then on.
- `beginFrame`: Starts the frame's screen pass, after its target passes.
  - `width`: The framebuffer's width, in framebuffer pixels.
  - `height`: The framebuffer's height, in framebuffer pixels.
  - `clearColor`: The clear color, as 0xAARRGGBB.
  - `String`: A call inside a pass, or a size of 0 or less.

  The framebuffer is cleared to the color and the farthest depth, and the viewport set to all of it.
- `applyViewport`: Sets the rectangle that the following draws fill.
  - `x`: The left edge, in framebuffer pixels.
  - `y`: The bottom edge, in framebuffer pixels from the bottom.
  - `w`: The width, in framebuffer pixels.
  - `h`: The height, in framebuffer pixels.
  - `String`: A call outside a frame, or a size of 0 or less.
- `applyScissor`: Clips the following draws to a rectangle, until `resetScissor` or the end of the pass.
  - `x`: The left edge, in framebuffer pixels.
  - `y`: The bottom edge, in framebuffer pixels from the bottom.
  - `w`: The width, in framebuffer pixels.
  - `h`: The height, in framebuffer pixels.
  - `String`: A call outside a pass, or a size below 0.

  A pass begins unclipped.
- `resetScissor`: Removes the clip that `applyScissor` set, for the rest of the pass.
  - `String`: A call outside a pass.
- `draw`: Draws through a pipeline.
  - `pipeline`: The pipeline.
  - `buffers`: The buffer for each of the pipeline's buffers, by index: a `createBuffer` handle as this frame's upload left it, or a `createStaticBuffer` handle; 0 for a gap.
  - `indices`: For an indexed pipeline, a static index buffer; else ignored.
  - `first`: The first vertex, or for an indexed pipeline the first index.
  - `count`: The number of vertices, or indices.
  - `firstInstance`: The first record of the instanced buffers.
  - `instanceCount`: The number of instances.
  - `textures`: The texture bound at each of the program's texture slots, by slot. A slot given 0, or past the array's end, reads a clear 1x1 texture of its kind, for one the program declares and doesn't read.
  - `samplings`: How each texture is sampled, by slot. A shadow map or data texture is sampled as its kind requires.
  - `uniforms`: The bytes of each uniform block, by slot, at its declared size; null for a slot the program lacks.
  - `String`: Anything invalid, before drawing.

  Only whole primitives are drawn. A pipeline without buffers draws count vertices from nothing: one triangle over the viewport is three. Block 0 of the uniforms is flipped as the pipeline's `ClipFlip` says.
- `endFrame`: Ends the screen's pass and the frame, and submits it.
  - `String`: No screen pass is open.

  The frame is shown by `present`. Between the two it can be read back (`readPixels(0)`), and the caller can do other work.
- `present`: Shows the frame `endFrame` submitted, and waits for the display's refresh.
  The wait paces the caller's loop natively. In a page it does nothing: the browser shows the frame when the frame's callback returns.
- `readPixels`: Reads a render target, or the frame just ended, back from the GPU.
  - `target`: The render target: a `createRenderTarget` handle; 0 for the frame `endFrame` just ended.
  - `read`: Receives the pixels, `width * height * 4` bytes of RGBA8 with rows top first, and their width and height.
  - `failed`: Receives why they can't be read: no frame has ended since the last `beginFrame`.
  - `String`: A call inside a pass, or a handle that is not an RGBA8 render target.

  It waits for the GPU, so it suits screenshots and checks, not every frame. The frame `endFrame` ended must be read before `present`, and in a page before the frame's callback returns. One of `read` or `failed` is called once, on the main thread, during the call or later on a GPU that reads back asynchronously.
- `dispose`: Releases the adapter, after every handle it made is disposed.

## IHttp

*class* in [`platform/src/helix/platform/IHttp.hx`](../../platform/src/helix/platform/IHttp.hx), `import helix.platform.IHttp;`

Defines HTTP GET: a response whose body arrives in parts, and its abort.

```haxe
function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:haxe.io.Bytes -> Void, done:() -> Void, failed:String -> Void):() -> Void
function poll():Void
function dispose():Void
```

- `get`: Starts a GET.
  - `url`: The URL: relative to the page in a page; natively http or https only.
  - `noCache`: Whether to bypass HTTP caches, where the platform has one.
  - `headers`: The request's headers, names in any case.
  - `head`: Receives the response's status and its headers, names in lower case.
  - `body`: Receives each part of the body.
  - `done`: Called when the body is all here.
  - `failed`: Receives why the transfer failed.
  - returns: The abort: it stops the transfer where the platform can.

  On the main thread, never during this call: `head` once, `body` for each part of the body as it arrives, then one of `done` or `failed`. An HTTP error status is a response, not a failure. After an abort nothing more is called.

  A conditional request (`If-None-Match`, `If-Modified-Since`) may be answered 200 with the whole body, as HTTP allows any server to.
- `poll`: Delivers what arrived on the platform's threads since the last poll; call once a frame.
- `dispose`: Aborts every transfer.

## IImageDecoder

*class* in [`platform/src/helix/platform/IImageDecoder.hx`](../../platform/src/helix/platform/IImageDecoder.hx), `import helix.platform.IImageDecoder;`

Defines image decoding: a PNG, JPEG, BMP, TGA or GIF file (its first frame) into 8-bit RGBA, rows top to bottom, not premultiplied.

```haxe
function decode(encoded:haxe.io.Bytes, decoded:(pixels:haxe.io.Bytes, width:Int, height:Int) -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `decode`: Decodes a file, off the main thread where the platform can.
  - `encoded`: The file's bytes.
  - `decoded`: Receives the pixels, `width * height * 4` bytes, and the image's width and height.
  - `failed`: Receives why the file can't be read.

  One of `decoded` or `failed` is called once, on the main thread, never during this call.
- `poll`: Delivers what finished on the platform's threads since the last poll; call once a frame.
- `dispose`: Closes the decoder; a decode still running finishes without answering.

## ISystem

*class* in [`platform/src/helix/platform/ISystem.hx`](../../platform/src/helix/platform/ISystem.hx), `import helix.platform.ISystem;`

Defines the facts about where the program runs: the device, the options it was started with, the time, where its own files are, and where the OS keeps a program's files.

```haxe
var device(get, never):Device
function getOption(name:String):Null<String>
function getTime():Float
function getProgramDirectory():Null<String>
function getDataDirectory(company:String, product:String):Null<String>
function getCacheDirectory(company:String, product:String):Null<String>
```

- `device`: Gets what the program runs on, as the platform says.
- `getOption`: Returns an option the program was started with.
  - `name`: The option's name.
  - returns: Natively the environment variable HELIX_ and name in capitals; in a page the URL's query parameter name; null when not set.
- `getTime`: Returns the time on a monotonic clock, for measuring how long something took, such as a frame.
  - returns: Seconds from an unspecified zero.

  It never goes back or jumps when the system's clock is set; a pause in the program (a debugger, a hidden page) is time that passed. In a page `performance.now`, natively SDL's.
- `getProgramDirectory`: Returns the directory of the files that ship with the program, such as its assets.
  - returns: The directory, or null in a page.

  Natively the executable's directory; in a macOS app bundle, its `Contents/Resources`. A read-only `IFileSystem` over it reads them. In a page they're on the server, fetched with `IHttp`.
- `getDataDirectory`: Returns where the OS keeps a program's files that must last, such as its saves.
  - `company`: The company's name, a plain directory name.
  - `product`: The product's name, a plain directory name.
  - returns: The directory, or null in a page, where the browser keeps a program's files, or when the OS's directory can't be found.

  Natively the user's data directory (`$XDG_DATA_HOME` or `~/.local/share` on Linux, `~/Library/Application Support` on macOS, `%APPDATA%` on Windows), then the company and the product. The directory may not exist yet.
- `getCacheDirectory`: Returns where the OS keeps a program's files that can be made or fetched again, such as downloaded assets.
  - `company`: The company's name, a plain directory name.
  - `product`: The product's name, a plain directory name.
  - returns: The directory, or null in a page, where the browser keeps a program's files, or when the OS's directory can't be found.

  Natively the user's cache directory (`$XDG_CACHE_HOME` or `~/.cache` on Linux, `~/Library/Caches` on macOS), then the company and the product; on Windows `%LOCALAPPDATA%`, the company, the product and `cache`. The directory may not exist yet.

## IWindow

*class* in [`platform/src/helix/platform/IWindow.hx`](../../platform/src/helix/platform/IWindow.hx), `import helix.platform.IWindow;`

Defines the window a program draws in: its title, size, position, fullscreen, visibility and monitors.

In a page the window is the page: its title is the document's, its size the viewport's, and fullscreen and visibility are the canvas's. Sizes are logical pixels unless named framebuffer pixels. A request asks for what the platform may refuse or grant later: it returns whether it asked, and the matching property answers on a later frame. A `can` method says whether to offer the request at all.

The window reports nothing by itself: what happens to it (resized, focused, minimized, a close asked for) arrives as events from `IEvents.poll`.

```haxe
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
function onClosing(callback:() -> Void):Void
```

- `framebufferWidth`: Gets the drawable area's width, in framebuffer pixels.
- `framebufferHeight`: Gets the drawable area's height, in framebuffer pixels.
- `pixelRatio`: Gets the number of framebuffer pixels per logical pixel.
- `focused`: Gets a value indicating whether the window has the keyboard, as of the last `IEvents.poll`.
- `title`: Gets or sets the title bar's text; in a page, the document's title.
- `width`: Gets the window's inner width, in logical pixels; in a page, the viewport's.
- `height`: Gets the window's inner height, in logical pixels; in a page, the viewport's.
- `requestSize`: Asks for an inner size.
  - `width`: The width, in logical pixels.
  - `height`: The height, in logical pixels.
  - returns: False, asking nothing, in a page or for a size under 1.

  The window manager may give another size, or none; `width` and `height` answer on a later frame.
- `canMove`: Returns whether `requestPosition` and `requestMonitorIndex` can ask.
  - returns: False in a page, and where the compositor places windows (Wayland, XWayland).
- `x`: Gets the window's left edge on the desktop, in logical pixels: 0 natively where it can't move, the browser window's in a page.
- `y`: Gets the window's top edge on the desktop, in logical pixels: 0 natively where it can't move, the browser window's in a page.
- `requestPosition`: Asks for the window's left and top edges on the desktop.
  - `x`: The left edge, in logical pixels.
  - `y`: The top edge, in logical pixels.
  - returns: False, asking nothing, where the window can't move (`canMove`).

  `x` and `y` answer on a later frame, with what the window manager gave.
- `canFullscreen`: Returns whether `requestFullscreen` can ask.
  - returns: True natively; in a page, whether the page may go fullscreen.
- `fullscreen`: Gets a value indicating whether the window is fullscreen now; in a page, the canvas.
- `requestFullscreen`: Asks for fullscreen or a window.
  - `enabled`: True for fullscreen, false for a window.
  - `done`: Optional. Called once the change is granted.
  - `failed`: Optional. Receives the browser's reason when it refuses; the page stays as it was.
  - returns: False, calling neither, where it can't ask (`canFullscreen`).

  `fullscreen` answers on a later frame. A browser grants fullscreen only soon after a key press, click or tap; without a recent one the request waits for the player's next one. Natively it is granted.
- `requestOrientation`: Asks for the screen held one way up, or as the player holds it.
  - `orientation`: Landscape, Portrait, or Any to let a lock go.
  - `done`: Optional. Called once the screen is locked.
  - `failed`: Optional. Receives the browser's reason when it refuses.
  - returns: False, calling neither, where it can't ask: natively.

  Only some browsers lock it (Chrome on Android, and only in fullscreen: ask in `requestFullscreen`'s done); iOS Safari and desktops don't. A game also shows "turn your device" when the shape is wrong.
- `visible`: Gets a value indicating whether the program shows the window; in a page, the canvas.
  Whether the player can see it (not minimized, the tab not in the background) is reported by the `Shown` and `Hidden` events.
- `requestVisible`: Asks to show or hide the window; in a page, the canvas.
  - `visible`: True to show it.
  - returns: True: it always asks.

  `visible` answers on a later frame, natively once the window manager has shown it.
- `monitorCount`: Gets the number of monitors, at least 1; a page sees one screen.
- `monitorIndex`: Gets the index of the monitor holding the window.
- `requestMonitorIndex`: Asks for the window on another monitor.
  - `index`: The monitor, 0 to `monitorCount` - 1.
  - returns: False, asking nothing, for an index out of range or where the window can't move (`canMove`).

  `monitorIndex` answers on a later frame.
- `getMonitorName`: Returns a monitor's name.
  - `index`: The monitor.
  - returns: Its name, or "" for an index out of range.
- `getMonitorX`: Returns a monitor's left edge on the desktop.
  - `index`: The monitor.
  - returns: The edge, in logical pixels; 0 for an index out of range, and in a page.
- `getMonitorY`: Returns a monitor's top edge on the desktop.
  - `index`: The monitor.
  - returns: The edge, in logical pixels; 0 for an index out of range, and in a page.
- `getMonitorWidth`: Returns a monitor's width.
  - `index`: The monitor.
  - returns: The width, in logical pixels; 0 for an index out of range.
- `getMonitorHeight`: Returns a monitor's height.
  - `index`: The monitor.
  - returns: The height, in logical pixels; 0 for an index out of range.
- `canClose`: Returns whether `close` removes the window.
  - returns: True natively; false in a page, which a script can't close.

  A menu asks before offering Quit.
- `close`: Closes the window, natively; does nothing in a page.
  The program's owner ends its loop after it. `onClosing`'s callback runs first.
- `onClosing`: Sets the call made once, as the window goes for good: natively when it is disposed, in a page at pagehide.
  - `callback`: The call.

  Nothing of the program runs after it, so it is the last place to save; in a page, no frame follows, and an asynchronous write started in it may not finish. A page gets no `CloseRequested`, so this is its only end. A later call replaces an earlier callback.

## Key

*abstract* in [`platform/src/helix/platform/Key.hx`](../../platform/src/helix/platform/Key.hx), `import helix.platform.Key;`

Specifies a physical key by its place on a US layout, numbered as GLFW numbers them.

Each events adapter maps its platform's codes to these. Left and right Shift, Control, Alt and Super are one key each.

Values: `Space`, `Apostrophe`, `Comma`, `Minus`, `Period`, `Slash`, `Digit0`, `Digit1`, `Digit2`, `Digit3`, `Digit4`, `Digit5`, `Digit6`, `Digit7`, `Digit8`, `Digit9`, `Semicolon`, `Equal`, `A`, `B`, `C`, `D`, `E`, `F`, `G`, `H`, `I`, `J`, `K`, `L`, `M`, `N`, `O`, `P`, `Q`, `R`, `S`, `T`, `U`, `V`, `W`, `X`, `Y`, `Z`, `LeftBracket`, `Backslash`, `RightBracket`, `Grave`, `Escape`, `Enter`, `Tab`, `Backspace`, `Insert`, `Delete`, `Right`, `Left`, `Down`, `Up`, `PageUp`, `PageDown`, `Home`, `End`, `F1`, `F2`, `F3`, `F4`, `F5`, `F6`, `F7`, `F8`, `F9`, `F10`, `F11`, `F12`, `World1`, `World2`, `CapsLock`, `ScrollLock`, `NumLock`, `PrintScreen`, `Pause`, `F13`, `F14`, `F15`, `F16`, `F17`, `F18`, `F19`, `F20`, `F21`, `F22`, `F23`, `F24`, `F25`, `Keypad0`, `Keypad1`, `Keypad2`, `Keypad3`, `Keypad4`, `Keypad5`, `Keypad6`, `Keypad7`, `Keypad8`, `Keypad9`, `KeypadDecimal`, `KeypadDivide`, `KeypadMultiply`, `KeypadSubtract`, `KeypadAdd`, `KeypadEnter`, `KeypadEqual`, `Shift`, `Control`, `Alt`, `Super`, `Menu`.

```haxe
static inline var COUNT:Int
static final all(default, null):Array<Key>
static function named(name:String):Key
static function getName(key:Key):String
function toString():String
```

- `COUNT`: One past the largest value, for arrays indexed by key.
- `all`: Every key, in order of value.
- `named`: The key a name spells, ignoring case ("A", "space", "KeypadEnter", "0"); throws for an unknown name.
- `getName`: The key's name as named reads it: its own spelling ("Space", "PageUp", "KeypadEnter"), a digit's its digit ("0").
- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## MouseButton

*abstract* in [`platform/src/helix/platform/MouseButton.hx`](../../platform/src/helix/platform/MouseButton.hx), `import helix.platform.MouseButton;`

Specifies a mouse button.

Values: `Left`, `Right`, `Middle`.

```haxe
static final all(default, null):Array<MouseButton>
function toString():String
```

- `all`: Every button.
- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## Orientation

*abstract* in [`platform/src/helix/platform/Orientation.hx`](../../platform/src/helix/platform/Orientation.hx), `import helix.platform.Orientation;`

Specifies which way up a game wants the screen (`IWindow.requestOrientation`).

- `Orientation.Any`: As the player holds it: any lock let go.
- `Orientation.Landscape`: Wider than tall: the long side across.
- `Orientation.Portrait`: Taller than wide: a phone held upright.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## PadAxis

*abstract* in [`platform/src/helix/platform/PadAxis.hx`](../../platform/src/helix/platform/PadAxis.hx), `import helix.platform.PadAxis;`

Specifies a gamepad's axis.

Sticks run from -1 to 1, down and right positive; triggers from 0 to 1.

Values: `LeftX`, `LeftY`, `RightX`, `RightY`, `LeftTrigger`, `RightTrigger`.

```haxe
static inline var COUNT:Int
static final all(default, null):Array<PadAxis>
function toString():String
```

- `COUNT`: One past the largest value, for arrays indexed by axis.
- `all`: Every axis.
- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## PadButton

*abstract* in [`platform/src/helix/platform/PadButton.hx`](../../platform/src/helix/platform/PadButton.hx), `import helix.platform.PadButton;`

Specifies a gamepad's button by its place on an Xbox-style pad, numbered as the W3C standard gamepad numbers them.

The triggers are buttons too, pressed when pulled past half way (or by a digital trigger), as well as axes.

Values: `South`, `East`, `West`, `North`, `LeftBumper`, `RightBumper`, `LeftTrigger`, `RightTrigger`, `Back`, `Start`, `LeftStick`, `RightStick`, `Up`, `Down`, `Left`, `Right`, `Guide`.

```haxe
static inline var COUNT:Int
static final all(default, null):Array<PadButton>
function toString():String
```

- `COUNT`: One past the largest value, for arrays indexed by button.
- `all`: Every button.
- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## PipelineDesc

*typedef* in [`platform/src/helix/platform/PipelineDesc.hx`](../../platform/src/helix/platform/PipelineDesc.hx), `import helix.platform.PipelineDesc;`

Represents everything a pipeline fixes for the draws through it.

`IGraphics.createPipeline` makes it. An adapter makes what the description says and knows nothing else about the program.

- `shader:Int`: The program: an `IGraphics.createShader` handle.
- `primitive:Primitive`: What the draws make.
- `indexed:Bool`: Whether the draws are indexed, by uint32 indices.
- `flip:ClipFlip`: What uniform block 0 holds, for drawing render targets the right way up.
- `depthWrite:Bool`: Whether the draws write depth.
- `depthTest:DepthTest`: The depth test.
- `depthOnly:Bool`: Whether the draws write depth alone, for a shadow pass.
- `cull:CullFace`: Which faces are culled.
- `clockwise:Bool`: Whether clockwise winding is the front face.
- `buffers:Array<VertexBuffer>`: The vertex buffers' layouts, by their index in a draw's buffers.
- `blend:BlendMode`: How the colors are combined with the target's.

## Primitive

*abstract* in [`platform/src/helix/platform/Primitive.hx`](../../platform/src/helix/platform/Primitive.hx), `import helix.platform.Primitive;`

Specifies what a pipeline's draws make.

- `Primitive.Triangles`: Triangles, three vertices or indices each.
- `Primitive.Lines`: Lines, two vertices or indices each.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## Sampling

*abstract* in [`platform/src/helix/platform/Sampling.hx`](../../platform/src/helix/platform/Sampling.hx), `import helix.platform.Sampling;`

Represents how a draw samples a texture: its filter, and how it wraps along u and v.

It is a small value passed with each texture a draw uses. Adapters keep one sampler for each value used.

```haxe
var tiled = new Sampling(Nearest, Repeat, Repeat);
```

```haxe
static final NEAREST(default, null):Sampling
static final LINEAR(default, null):Sampling
var filter(get, never):Filter
var wrapU(get, never):Wrap
var wrapV(get, never):Wrap
function withFilter(filter:Filter):Sampling
function withWrap(wrapU:Wrap, wrapV:Wrap):Sampling
static inline var COUNT:Int
```

- `NEAREST`: Nearest filtering, clamped: for pixel art.
- `LINEAR`: Linear filtering, clamped: smooth.
- `filter`: Gets how the texture is filtered: Linear or Nearest.
- `wrapU`: Gets how the texture wraps along u.
- `wrapV`: Gets how the texture wraps along v.
- `withFilter`: Returns this sampling with another filter.
  - `filter`: The new filter.
  - returns: The sampling, its wrapping unchanged.
- `withWrap`: Returns this sampling with other wrapping.
  - `wrapU`: How the texture wraps along u.
  - `wrapV`: How the texture wraps along v.
  - returns: The sampling, its filter unchanged.
- `COUNT`: The number of distinct values, 0 to COUNT - 1: the size of an adapter's table of samplers.

## SdlGpuStages

*typedef* in [`platform/src/helix/platform/SdlGpuStages.hx`](../../platform/src/helix/platform/SdlGpuStages.hx), `import helix.platform.SdlGpuStages;`

Represents a program in SDL_GPU's dialects, laid out as SDL_GPU binds them.

- `spirv:ShaderStages`: SPIR-V for Vulkan, each stage base64-encoded.
- `msl:ShaderStages`: MSL for Metal, entry points main0.
- `hlsl:ShaderStages`: HLSL for Direct3D 12, shader model 5.1, entry points main.

## ShaderBlock

*typedef* in [`platform/src/helix/platform/ShaderBlock.hx`](../../platform/src/helix/platform/ShaderBlock.hx), `import helix.platform.ShaderBlock;`

Represents a uniform block that a program declares.

In GLSL the block is flattened to an array of vec4s.

- `vec4Count:Int`: The number of vec4s the GLSL array holds.
- `stage:String`: The stage that reads it: "vertex" or "fragment".
- `slot:Int`: The binding slot.
- `size:Int`: The size, in bytes.
- `glslName:String`: The block's name in the GLSL.

## ShaderSource

*typedef* in [`platform/src/helix/platform/ShaderSource.hx`](../../platform/src/helix/platform/ShaderSource.hx), `import helix.platform.ShaderSource;`

Represents a compiled program: its stages in each dialect the adapters compile, its vertex attributes, and what it binds.

`IGraphics.createShader` builds it. An adapter reads only its own dialect: GLSL ES 300 in the browser, GLSL 410 for GL natively, and SDL_GPU's stages for SDL_GPU.

- `uniformBlocks:Array<ShaderBlock>`: The uniform blocks it declares.
- `textures:Array<ShaderTexture>`: The textures it samples.
- `sdlGpu:Null<SdlGpuStages>`: SDL_GPU's stages. Present only in a build for SDL_GPU.
- `glsl410:Null<ShaderStages>`: GLSL 410, for GL natively. Absent from a browser build.
- `glsl300es:ShaderStages`: GLSL ES 300, for WebGL2.
- `attributes:Array<String>`: The vertex attributes' names, by slot.

## ShaderStages

*typedef* in [`platform/src/helix/platform/ShaderStages.hx`](../../platform/src/helix/platform/ShaderStages.hx), `import helix.platform.ShaderStages;`

Represents one program's source in one dialect: its vertex and fragment stages.

- `vertex:String`: The vertex stage's source.
- `fragment:String`: The fragment stage's source.

## ShaderTexture

*typedef* in [`platform/src/helix/platform/ShaderTexture.hx`](../../platform/src/helix/platform/ShaderTexture.hx), `import helix.platform.ShaderTexture;`

Represents a texture that a program samples, and its kind.

A texture is a plain 2D texture unless one of shadow, cube or data is true.

- `stage:String`: The stage that samples it: "vertex" or "fragment".
- `slot:Int`: The binding slot of the texture and its sampler.
- `shadow:Bool`: Whether it is a shadow map: a depth array read through a comparison sampler.
- `glslName:String`: The GLSL name of the texture and sampler pair.
- `data:Bool`: Whether the program never filters it: it only reads it texel by texel (`texelFetch`), so it is sampled nearest whatever the draw's sampling, as a data texture (`IGraphics.createDataTexture`) always is.
- `cube:Bool`: Whether it is a cubemap.

## StreamSource

*enum* in [`platform/src/helix/platform/StreamSource.hx`](../../platform/src/helix/platform/StreamSource.hx), `import helix.platform.StreamSource;`

Specifies what an audio stream plays (`IAudio.openStream`).

- `Local(location:String)`: A file the platform reads directly: natively a path, in a page a URL (a Blob's).
- `Remote(url:String)`: A URL, which only an output that plays URLs itself opens (`IAudio.playsUrls`).
- `Downloading(source:GrowingSource)`: A file still downloading, played as it arrives; natively.

## TextureFormat

*abstract* in [`platform/src/helix/platform/TextureFormat.hx`](../../platform/src/helix/platform/TextureFormat.hx), `import helix.platform.TextureFormat;`

Specifies the format of a texture's texels.

The 8-bit and compressed formats hold sRGB values. The compressed formats store 4x4 blocks of 16 bytes, and only some GPUs sample them (`IGraphics.canSample`).

- `TextureFormat.Rgba8`: Four bytes a texel, rows top first.
- `TextureFormat.Bc7`: BC7 (BPTC), compressed: desktop GPUs.
- `TextureFormat.Astc4x4`: ASTC 4x4, compressed: phone GPUs.
- `TextureFormat.Etc2Rgba8`: ETC2 RGBA8 with EAC alpha, compressed: older phone GPUs.
- `TextureFormat.Rgba16f`: RGBA half floats (IEEE binary16, little-endian), 8 bytes a texel, rows top first: linear light that can exceed 1. Filtered linearly where `IGraphics.canSample` is true for it.

```haxe
function levelBytes(width:Int, height:Int):Int
function toString():String
```

- `levelBytes`: Returns the byte size of one level of a texture in this format.
  - `width`: The level's width, in texels.
  - `height`: The level's height, in texels; for a cube, one face's.
  - returns: The level's size, in bytes.
- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.

## VertexAttribute

*typedef* in [`platform/src/helix/platform/VertexAttribute.hx`](../../platform/src/helix/platform/VertexAttribute.hx), `import helix.platform.VertexAttribute;`

Represents a vertex attribute that a pipeline reads from one of its buffers.

- `slot:Int`: The shader's input slot.
- `offset:Int`: The byte offset within each record.
- `componentCount:Int`: The number of floats, 1 to 4.

## VertexBuffer

*typedef* in [`platform/src/helix/platform/VertexBuffer.hx`](../../platform/src/helix/platform/VertexBuffer.hx), `import helix.platform.VertexBuffer;`

Represents a vertex buffer that a pipeline reads, by its index in a draw's buffers.

A buffer with no attributes is a gap that the draw skips.

- `stride:Int`: The size of one record, in bytes.
- `instanced:Bool`: Whether a record is an instance's, stepped once an instance, rather than a vertex's.
- `attributes:Array<VertexAttribute>`: The attributes read from each record.

## Wrap

*abstract* in [`platform/src/helix/platform/Wrap.hx`](../../platform/src/helix/platform/Wrap.hx), `import helix.platform.Wrap;`

Specifies how a texture is sampled outside the 0 to 1 range of its coordinates.

- `Wrap.Clamp`: The edge texel continues.
- `Wrap.Repeat`: The texture tiles.
- `Wrap.Mirror`: The texture tiles, every other copy mirrored.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Stopped, Playing): what Std.string, interpolation and trace show.
