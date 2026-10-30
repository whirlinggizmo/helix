# helix.platform

[Back to the index](README.md)

## BlendMode

*abstract* in [`platform/src/helix/platform/BlendMode.hx`](../../platform/src/helix/platform/BlendMode.hx), `import helix.platform.BlendMode;`

Specifies how a pipeline's colors are combined with the colors already in the target.

Colors use straight alpha, not premultiplied alpha.

- `BlendMode.Opaque`: The color replaces the target's.
- `BlendMode.Alpha`: The color is blended over the target's by its alpha.
- `BlendMode.Additive`: The color, multiplied by its alpha, is added to the target's. It suits light, fire and glows.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Opaque, Alpha): what Std.string, interpolation and trace show.

## ClipFlip

*abstract* in [`platform/src/helix/platform/ClipFlip.hx`](../../platform/src/helix/platform/ClipFlip.hx), `import helix.platform.ClipFlip;`

Specifies what a pipeline's uniform block 0 holds, so that an adapter can draw a render target the right way up.

An adapter whose render targets are stored bottom row first, as GL's are, flips its draws into a target. With ClipScale, it writes block 0 as (1, -1) in a pass into a target and as (1, 1) otherwise. With ViewProjection, it negates the y row of the column-major matrix in block 0's first 64 bytes in a pass into a target. An adapter whose targets are stored top row first ignores this value.

- `ClipFlip.None`: Block 0 is not touched, or there is none.
- `ClipFlip.ClipScale`: Block 0 is a vec4 clip scale that the adapter writes.
- `ClipFlip.ViewProjection`: Block 0 starts with a view-projection matrix whose y row the adapter negates.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (None, ClipScale): what Std.string, interpolation and trace show.

## Color

*class* in [`platform/src/helix/platform/Color.hx`](../../platform/src/helix/platform/Color.hx), `import helix.platform.Color;`

Provides functions for colors held as 0xAARRGGBB integers, with alpha in the top byte.

Each channel is 0 to 255. Text writes a color in CSS order, as #RRGGBB or #RRGGBBAA. `fromRgba` and `toRgba` convert between that order and this one.

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

- `fromChannels`: Returns the color with the provided channels.
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

- `CullFace.None`: No faces are culled, so both sides are drawn.
- `CullFace.Back`: Back faces, the ones facing away, are culled. This skips the far side of a closed surface.
- `CullFace.Front`: Front faces are culled, so only a surface's far side is drawn, as for an outline's shell.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (None, Back): what Std.string, interpolation and trace show.

## DepthTest

*abstract* in [`platform/src/helix/platform/DepthTest.hx`](../../platform/src/helix/platform/DepthTest.hx), `import helix.platform.DepthTest;`

Specifies which fragments a pipeline's depth test passes, compared with the depth already in the target.

- `DepthTest.Off`: There is no test, so every fragment is drawn.
- `DepthTest.LessEqual`: Fragments as near as or nearer than the depth there pass. This is the usual test.
- `DepthTest.Greater`: Fragments farther than the depth there pass, so only what is hidden behind something drawn before is drawn.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Off, LessEqual): what Std.string, interpolation and trace show.

## Device

*class* in [`platform/src/helix/platform/Device.hx`](../../platform/src/helix/platform/Device.hx), `import helix.platform.Device;`

Represents what the program runs on, as far as the platform reports it.

It tells a browser from native, and names the operating system and the processor's architecture. It also reports whether there is a touch screen and whether there is a fine pointer.

A game uses it to choose what it shows on each device, such as touch controls on a phone, "tap" or "click" in a prompt, or a landscape lock. A browser can be wrong about a laptop with a touch screen, which has both. Touch controls therefore also appear on the first touch, not by device alone.

```haxe
final browser:Bool
final os:String
final architecture:String
final touchScreen:Bool
final finePointer:Bool
var mobile(get, never):Bool
```

- `browser`: Gets a value indicating whether the program runs in a browser page rather than natively.
- `os`: Gets the operating system, in lowercase: "windows", "macos", "linux", "android", "ios" or "chromeos".
  It is "" when the platform doesn't report one.
- `architecture`: Gets the processor architecture the program runs as, in lowercase: "x86_64", "arm64" or "x86".
  Natively it is the architecture the program was built for. In a page it is the one the browser names, or "" when the browser names none. A browser may name none, or the wrong one. Safari on Apple silicon reports Intel.
- `touchScreen`: Gets a value indicating whether there is a touch screen. It is always false natively.
- `finePointer`: Gets a value indicating whether there is a fine pointer, such as a mouse, a trackpad or a pen.
  It is false on a phone or a tablet alone.
- `mobile`: Gets a value indicating whether the device is a phone or a tablet, which means a touch screen and no fine pointer.

## Event

*enum* in [`platform/src/helix/platform/Event.hx`](../../platform/src/helix/platform/Event.hx), `import helix.platform.Event;`

Represents one window or device event, as `IEvents.poll` delivers it.

Positions are in framebuffer pixels from the window's top-left corner. A key is its physical position on a US layout (`Key`). Right-hand modifiers are reported as the left-hand ones.

- `KeyDown(key:Key, repeat:Bool)`: A key went down. repeat is true when the OS repeats a held key.
- `KeyUp(key:Key)`: A key went up.
- `Text(text:String)`: Characters were typed. It arrives only while `IKeyboard.textInput` is on.
- `MouseMove(x:Float, y:Float)`: The mouse moved over the window.
- `MouseDown(button:MouseButton, x:Float, y:Float)`: A mouse button went down.
- `MouseUp(button:MouseButton, x:Float, y:Float)`: A mouse button went up.
- `MouseLeave`: The mouse left the window.
- `Wheel(dx:Float, dy:Float)`: The wheel turned, in notches. Right and away from the player are positive.
- `TouchDown(id:Int, x:Float, y:Float)`: A finger touched the screen. id stays the same for that finger until it lifts.
- `TouchMove(id:Int, x:Float, y:Float)`: A finger moved.
- `TouchUp(id:Int, x:Float, y:Float)`: A finger lifted, or the OS took the touch away.
- `Tilt(beta:Float, gamma:Float, screenAngle:Float)`: Reports the device's orientation while tilt access is held (`ITilt.requestAccess`). beta and gamma are in degrees, and screenAngle is the screen's angle.
- `TiltState(status:TiltStatus)`: The tilt's status changed.
- `Unlocked`: The player's first press: a key or a mouse button pressed, or a finger lifted, for the first time.
  In a browser that press unlocks the page, which may then play sound, ask for tilt and go fullscreen. It arrives once, before that press's own event, on every target, so a game's "press any key" start flows the same everywhere (`IEvents.unlocked`). A finger counts as it lifts because a browser counts a tap then. A gamepad's press doesn't count, as a browser doesn't take one as the player's.
- `PadConnected(slot:Int)`: A gamepad was connected in a slot, 0 to 3.
- `PadDisconnected(slot:Int)`: The gamepad in a slot was disconnected. Its buttons count as up.
- `PadButtonDown(slot:Int, button:PadButton)`: A gamepad's button went down. A trigger is also a button, down when pulled past half way.
- `PadButtonUp(slot:Int, button:PadButton)`: A gamepad's button went up. Natively, the Guide button's release arrives no sooner than a quarter second after its press.
- `Resized(width:Int, height:Int)`: The drawable area changed size, in framebuffer pixels.
- `FocusGained`: The window got the keyboard.
- `FocusLost`: The window lost the keyboard. Just before it, each key still down arrives as a `KeyUp`.
- `Shown`: The player can see the window again, because it was restored or its page came to the front.
- `Hidden`: The player can't see the window, because it is minimized or hidden, or its page is in the background.
- `CloseRequested`: The player or the OS asked to close the window. The program decides whether to close it.
  It arrives only natively. A page never receives it, because a closing tab gives no frame to decide in. A page's end is `IWindow.onClose`.
- `GraphicsLost`: The GPU's context is gone. In a page, the WebGL context was lost to a GPU reset or an evicted tab.

## Filter

*abstract* in [`platform/src/helix/platform/Filter.hx`](../../platform/src/helix/platform/Filter.hx), `import helix.platform.Filter;`

Specifies how a texture is filtered when drawn at a size other than its own.

- `Filter.Nearest`: The nearest texel is used. It looks sharp and suits pixel art.
- `Filter.Linear`: Neighboring texels are blended, which looks smooth. A texture with mipmaps is also blended between them, so it shrinks without shimmering.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Nearest, Linear): what Std.string, interpolation and trace show.

## GraphicsUnavailableException

*class* in [`platform/src/helix/platform/GraphicsUnavailableException.hx`](../../platform/src/helix/platform/GraphicsUnavailableException.hx), `import helix.platform.GraphicsUnavailableException;`, extends `Exception`

Represents the error a graphics adapter throws when the GPU API it draws through is missing, such as WebGL2 in a browser without it.

A caller can tell this error apart from a failure in the program's own code, and report the platform as unsupported.

```haxe
function new(message:String, ?previous:haxe.Exception, ?native:Any)
```


## GrowingSource

*class* in [`platform/src/helix/platform/GrowingSource.hx`](../../platform/src/helix/platform/GrowingSource.hx), `import helix.platform.GrowingSource;`

Represents a file arriving from a download, readable while it arrives.

The downloader appends each part as it comes, and a native audio output reads what has arrived. The file's length is known, so room for the whole file is allocated at the start. The bytes therefore never move, and what has arrived is the first `received` of them. It must be used on the main thread only.

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
- `bytes`: Gets the file's bytes, `total` long. The first `received` of them have arrived, and the rest are zero.
- `received`: Gets how many bytes have arrived, 0 to `total`.
- `total`: Gets the file's length in bytes.
- `done`: Gets a value indicating whether the whole file has arrived.
- `failure`: Gets why the download failed, or null while it hasn't. Once it is set, nothing more arrives.
- `append`: Adds a part after what has arrived.
  - `part`: The next bytes of the file.
  - returns: False, adding nothing, when the part goes past the file's length or the download has ended.

  The source is done once the file is whole.
- `fail`: Ends the download short.
  - `message`: Why the download failed.

  It does nothing once the file is whole or the download has already failed.

## IAudio

*interface* in [`platform/src/helix/platform/IAudio.hx`](../../platform/src/helix/platform/IAudio.hx), `import helix.platform.IAudio;`, extends `IPollable`

Defines the sound output, which plays clips held whole and streams played as they are read.

Each playing of a clip or a stream is a voice. Clip, stream and voice ids are the adapter's. Samples are mono 32-bit float PCM at 44100 Hz, -1 to 1.

A browser starts its audio on the page's first key or pointer press, and suspends it while the page is hidden or blurred. Natively, audio runs once the device opens.

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

- `available`: Gets a value indicating whether there is an output at all. It is false natively when there is no audio device.
- `running`: Gets a value indicating whether voices are heard now.
  In a browser it is false until the page's first key press, mouse button or tap. The adapter listens for that press and unlocks audio itself. It is false again while the page is hidden. Natively it is true once the device opens. A voice requested before audio runs waits, and starts once audio runs (`playClip`).
- `playsUrls`: Gets a value indicating whether `openStream` plays a `Remote` source's URL itself.
  It is true in a browser, whose media element streams the URL. It is false natively, where the caller downloads the file and opens the download as a `Downloading` source.
- `createClip`: Copies samples into a new clip.
  - `samples`: Mono 32-bit float PCM at 44100 Hz, -1 to 1.
  - returns: The clip's id.
  - throws `String`: When there is no room for the clip.
- `disposeClip`: Disposes a clip and stops its voices.
  - `clip`: The clip.
  - throws `String`: For an unknown clip.
- `openStream`: Opens a source to play as it is read.
  - `source`: What to play.
  - `opened`: Receives the stream's id.
  - `failed`: Receives why the source can't be opened. Natively, the cause is a `Remote` source, a file its codec can't read, or a download that failed or ended unreadable. In a browser, it is a load error, no metadata within 15 seconds, or a `Downloading` source.
  - returns: A function that aborts the open. Neither callback is called after it, and an opened stream is closed.

  One of `opened` or `failed` is called once, on the main thread, never during this call. A download is opened once enough of it has arrived for its codec. A `Local` source's file must outlive the stream.
- `disposeStream`: Disposes a stream and stops its voices.
  - `stream`: The stream.
  - throws `String`: For an unknown stream.
- `playClip`: Starts a clip playing.
  - `clip`: The clip.
  - `loop`: True to play it again from the start each time it ends.
  - `volume`: The volume, 0 to 1.
  - returns: The voice's id, or 0 when there is no output (`available`).
  - throws `String`: For an unknown clip.

  A voice requested before audio runs waits, and keeps any volume, pitch, pan and pause set on it. It starts at the first `poll` after audio runs. Meanwhile `isPlaying` is true for it.
- `playStream`: Starts a stream playing from its beginning.
  - `stream`: The stream.
  - `loop`: True to play it again from the start each time it ends.
  - `volume`: The volume, 0 to 1.
  - returns: The voice's id, or 0 when there is no output (`available`) or, natively, when the file can't be played.
  - throws `String`: For an unknown stream.

  A voice requested before audio runs waits and starts once audio runs, as `playClip`'s does.
- `stop`: Stops a voice.
  - `voice`: The voice.

  It does nothing for an unknown or ended voice.
- `pause`: Pauses or resumes a voice.
  - `voice`: The voice.
  - `paused`: True to pause it, false to resume it.

  It does nothing for an unknown voice.
- `setVolume`: Sets a voice's volume.
  - `voice`: The voice.
  - `volume`: The volume, 0 to 1.
  - returns: False, changing nothing, when the voice isn't playing (unknown, stopped or ended) or the volume is outside 0 to 1.

  The change is ramped over a few milliseconds (the output's next block), so a fade stepped once a frame doesn't click.
- `setPitch`: Sets a voice's playback rate, which changes its pitch and length together.
  - `voice`: The voice.
  - `pitch`: The rate, 0.25 to 4, where 1 plays as recorded.
  - returns: False, changing nothing, when the voice isn't playing (unknown, stopped or ended).
- `setPan`: Sets a voice's pan, using equal-power panning.
  - `voice`: The voice.
  - `pan`: The pan, -1 (left) to 1 (right), where 0 is the middle.
  - returns: False, changing nothing, when the voice isn't playing (unknown, stopped or ended).

  The change is ramped as a volume change is.
- `isPlaying`: Returns whether a voice is still playing or paused.
  - `voice`: The voice.
  - returns: False once the voice has ended or been stopped, and for an unknown voice.
- `poll`: Feeds streamed voices, opens downloads that have arrived far enough, and delivers what the platform's threads finished.
  The program calls it once a frame.
- `dispose`: Stops every voice, disposes every stream and clip, and closes the output.

## IAudioDecoder

*interface* in [`platform/src/helix/platform/IAudioDecoder.hx`](../../platform/src/helix/platform/IAudioDecoder.hx), `import helix.platform.IAudioDecoder;`, extends `IPollable`

Defines audio decoding from a whole file into mono 32-bit float PCM at 44100 Hz.

It reads WAV (PCM or float, at any rate), Ogg Vorbis, MP3 and FLAC files, mono or stereo. Stereo is mixed down and other rates are resampled. Samples are -1 to 1.

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
- `poll`: Delivers what finished on the platform's threads since the last poll. The program calls it once a frame.
- `dispose`: Closes the decoder. A decode still running finishes without calling back.

## IEvents

*interface* in [`platform/src/helix/platform/IEvents.hx`](../../platform/src/helix/platform/IEvents.hx), `import helix.platform.IEvents;`, extends `IPollable`

Defines the events, polled once a frame: what happens to the window, the player's first press, and what the devices built over it add.

Each `poll` delivers what happened as `Event` records, in the order the OS reported them. Without a device, that is the window being resized, focused, shown, hidden or closed, its graphics lost, and `Unlocked`. A device's adapter, constructed over the events adapter, adds its own events to the same records: `IKeyboard` keys and text, `IMouse` the mouse, `ITouch` fingers, `IGamepads` pads and `ITilt` the tilt. A device that isn't constructed isn't listened to. Nothing is delivered between polls, and nothing calls the program. The program walks `events` itself.

```haxe
events.poll();
for (event in events.events)
switch event {
case KeyDown(key, _): pressed(key);
case CloseRequested: window.close();
case _:
}
```

```haxe
function poll():Void
var events(get, never):Array<Event>
function wait(timeout:Float):Void
var unlocked(get, never):Bool
function dispose():Void
```

- `poll`: Drains the OS's queue into `events`, with the devices' events among them.
  `events` then holds this frame's events, in order. Last frame's events are cleared.
- `events`: Gets the events the last `poll` delivered. The array is reused by the next poll.
- `wait`: Sleeps in the OS until an event arrives or the timeout passes, using no CPU.
  - `timeout`: The longest wait, in seconds.

  It does nothing in a page. A native loop calls it while the window can't be seen (after `Hidden`), so the loop doesn't spin. The loop wakes at the timeout to service what must not starve. Events that arrive stay for the next `poll`.
- `unlocked`: Gets a value indicating whether the player has made the first press (`Event.Unlocked`): a key or a mouse button pressed, or a finger lifted. In a browser that press unlocks the page, which may then play sound, ask for tilt and go fullscreen. It is heard without a keyboard, mouse or touch adapter, follows the same rule natively, and stays true once set.
- `dispose`: Stops listening to the window and the first press. A program disposes of the devices built over it before it.

## IExport

*interface* in [`platform/src/helix/platform/IExport.hx`](../../platform/src/helix/platform/IExport.hx), `import helix.platform.IExport;`

Defines handing a finished file to the user.

In a page the file is a download. Natively it is written to a directory chosen when the adapter is made.

```haxe
function export(name:String, mimeType:String, bytes:haxe.io.Bytes, exported:(where:String) -> Void, failed:String -> Void):Void
```

- `export`: Hands a file over to the user.
  - `name`: The file's name, with no directory, and not hidden.
  - `mimeType`: The file's type, such as `"image/png"`.
  - `bytes`: The file.
  - `exported`: Receives where the file went. Natively it is the file's path. In a page it is the file's name, and the download has only begun.
  - `failed`: Receives why the file couldn't be exported, such as no room or no permission.
  - throws `String`: When the name isn't a plain file name.

  Natively, a file of the same name is replaced, and is never left half written. One of `exported` or `failed` is called once, on the main thread, during this call or later.

## IFileSystem

*interface* in [`platform/src/helix/platform/IFileSystem.hx`](../../platform/src/helix/platform/IFileSystem.hx), `import helix.platform.IFileSystem;`, extends `IPollable`

Defines files on this machine under one root, read and written whole by path.

Natively the root is a directory on disk. In a page it is an IndexedDB database. A file on a server is read through `IHttp` instead.

There is no listing, no making directories, no seeking and no metadata. A file is reached by its path. It is read whole or located for streaming, and written whole or not at all. These are a page's limits, kept natively so a program works the same on both.

A path is plain names joined by `/`, such as `audio/music.ogg`. Names use letters, digits, `_`, `-` and `.`, and the path is at most 256 characters. An absolute path, an empty name, `.` or `..` is refused through `failed`.

One of each call's callbacks is called once, on the main thread, never during the call. `missing` is called when the file isn't there, and `failed` receives why for anything else.

```haxe
files.read("levels/1.json", 1 << 20, bytes -> start(bytes), () -> trace("no level 1"), why -> trace(why));
```

```haxe
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

- `root`: Gets the root as the adapter received it, which is a directory or a database's name.
- `canWrite`: Gets a value indicating whether files can be written here.
  It is false when the file system was opened read-only, as over the files a program ships with.
- `read`: Reads a whole file.
  - `path`: The file's path under the root.
  - `maxBytes`: The largest file to read; a larger one fails.
  - `loaded`: Receives the file's bytes.
  - `missing`: Called when there is no file at the path.
  - `failed`: Receives why it can't be read.
  - returns: The abort: nothing is called after it.
- `write`: Writes a whole file, replacing what is there.
  - `path`: The file's path under the root.
  - `bytes`: The file's contents.
  - `written`: Called once the file is kept.
  - `failed`: Receives why the file can't be written: a root that can't be written (`canWrite`), no room, or the platform's reason.

  A reader never sees half of it. The directories above the file are made.
- `deleteFile`: Deletes a file.
  - `path`: The file's path under the root.
  - `deleted`: Called once the file is gone.
  - `failed`: Receives why the file can't be deleted.

  Deleting a file that isn't there succeeds.
- `deleteFiles`: Deletes every file under the root, as when clearing a cache.
  - `deleted`: Called once the files are gone.
  - `failed`: Receives why the files can't be deleted.
- `locate`: Finds where a file is, so it can be played as it is read without loading it whole.
  - `path`: The file's path under the root.
  - `located`: Receives the location and a function that releases it. That function is called once, when the location is no longer read.
  - `missing`: Called when there is no file at the path.
  - `failed`: Receives why it can't be located.

  Natively the location is the file's path. In a page it is a URL the audio output plays, kept until `release` is called.
- `poll`: Delivers what finished on the platform's threads since the last poll. The program calls it once a frame.
- `dispose`: Closes the file system. What is still running finishes without calling back.

## IGamepads

*interface* in [`platform/src/helix/platform/IGamepads.hx`](../../platform/src/helix/platform/IGamepads.hx), `import helix.platform.IGamepads;`

Defines the gamepads, in slots 0 to 3: `PadConnected`, `PadDisconnected`, `PadButtonDown` and `PadButtonUp` in `IEvents.events` while it exists, and each pad's state as of the last `IEvents.poll`.

Its adapter is constructed over the events adapter, whose `poll` delivers its events and reads the pads. Natively, a button pressed and released between two polls arrives as both events. A page reads its pads only at each poll, so it sees a press only if the button is down then.

```haxe
var stick = gamepads.getAxis(0, LeftX);
```

```haxe
function isConnected(slot:Int):Bool
function getName(slot:Int):String
function isButtonDown(slot:Int, button:PadButton):Bool
function getAxis(slot:Int, axis:PadAxis):Float
function dispose():Void
```

- `isConnected`: Returns whether a gamepad is in a slot.
  - `slot`: The slot, 0 to 3.
  - returns: True when one is connected there.
- `getName`: Returns the name of the gamepad in a slot.
  - `slot`: The slot, 0 to 3.
  - returns: The name, or "" when the slot is empty.
- `isButtonDown`: Returns whether a gamepad's button is down.
  - `slot`: The slot, 0 to 3.
  - `button`: The button.
  - returns: True when it is down; false for an empty slot.
- `getAxis`: Returns a gamepad's axis.
  - `slot`: The slot, 0 to 3.
  - `axis`: The axis.
  - returns: The axis's value. A stick runs from -1 to 1, with down and right positive. A trigger runs from 0 to 1. An empty slot gives 0.
- `dispose`: Stops reading the gamepads and lets them go.

## IGraphics

*interface* in [`platform/src/helix/platform/IGraphics.hx`](../../platform/src/helix/platform/IGraphics.hx), `import helix.platform.IGraphics;`

Defines the GPU as a platform's graphics adapter provides it, with its resources, its passes and one draw call.

Resources are textures of a few kinds, buffers, programs built from a `ShaderSource`, and pipelines made from a `PipelineDesc`. A frame is any number of passes into render targets and shadow maps, then the screen's pass from `beginFrame` to `endFrame`.

An adapter knows nothing of its caller's programs, layouts or pipelines. The caller describes them as data. Whoever creates a handle disposes it, once.

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
  - `levels`: The image with rows top first, then optionally its mipmaps. Each mipmap is half the size of the last, and at least 1. Each level is `format.levelBytes` of its size.
  - `format`: Optional. The texels' format; defaults to Rgba8.
  - returns: The texture's handle.
  - throws `String`: A size of 0 or less, no levels, a level of the wrong size, or a format this GPU cannot sample.

  Each draw chooses how the texture is sampled (`Sampling`).
- `createCubeTexture`: Uploads a cubemap.
  - `size`: Each face's width and height, in texels.
  - `levels`: Mip 0, then optionally its mips, each half the size of the last and at least 1. Each level holds its six faces in the order +X, -X, +Y, -Y, +Z, -Z, in GL's cube orientation, where a face's first row is its t = 0. Each face is `format.levelBytes` of its size.
  - `format`: The texels' format.
  - returns: The cubemap's handle.
  - throws `String`: A size of 0 or less, no levels, a level of the wrong size, or a format this GPU cannot sample.

  A cubemap is sampled at a texture slot like any texture. The sampling's filter applies and its wrap is ignored.
- `createDataTexture`: Creates a data texture of RGBA 32-bit floats, 16 bytes a texel.
  - `width`: The width, in texels.
  - `height`: The height, in texels.
  - returns: The data texture's handle.
  - throws `String`: A size of 0 or less, or larger than this GPU allows.

  A data texture is read texel by texel and never filtered, so its samplings are ignored. `updateDataTexture` fills it.
- `updateDataTexture`: Replaces a data texture's contents for the draws after it.
  - `handle`: The data texture.
  - `data`: The texels, at least width * height * 16 bytes, as little-endian floats with rows top first.
  - throws `String`: A handle that is not a data texture, or data that is too short.

  It can be called any number of times a frame.
- `canSample`: Returns whether this GPU samples textures of a format.
  - `format`: The format.
  - returns: True when textures of the format can be sampled.

  RGBA8 can always be sampled. The compressed formats can be sampled on GPUs that have them, and half floats where this GPU filters them.
- `msaaSamples`: Gets the number of multisampling samples per pixel that the screen is drawn with, or 1 for none.
  It can be fewer than the window asked for. Render targets with depth are drawn with the same number, and resolved into the texture that is sampled.
- `maxMsaaSamples`: Gets the largest number of multisampling samples a window could ask for here, at most 8.
  A browser only switches antialiasing on or off, and chooses its own count. In a browser this is therefore the count the canvas has when antialiasing is on, which is 4 where the GPU supports 4, and 1 otherwise.
- `createRenderTarget`: Creates a render target, which is a texture that a target pass draws into.
  - `width`: The width, in texels.
  - `height`: The height, in texels.
  - `format`: Optional. The texels' format; defaults to Rgba8.
  - `depth`: Optional. Whether it has a depth buffer; defaults to true.
  - returns: The render target's handle.
  - throws `String`: A size of 0 or less, or a format this GPU cannot draw into (`canRender`).

  The target is sampled like any texture and stored top row first. A target with depth has its own depth buffer. It is multisampled as the screen is (`msaaSamples`), or single-sampled where this GPU cannot multisample the format, and it is resolved into the texture at the end of each pass. A target without depth has neither a depth buffer nor multisampling, for a pass that draws over the whole target.
- `canRender`: Returns whether this GPU draws into, blends over and filters render targets of a format.
  - `format`: The format.
  - returns: True when render targets of the format can be drawn into.

  RGBA8 always can. RGBA16F can where float targets exist, which is nearly always natively, and in a browser through EXT_color_buffer_float. A compressed format never can.
- `createShadowMap`: Creates a shadow map, which is a depth texture of layers that shadow passes draw into.
  - `size`: Each layer's width and height, in texels.
  - `layers`: The number of layers.
  - returns: The shadow map's handle.
  - throws `String`: A size or layer count of 0 or less, or larger than this GPU allows.

  A program that declares a shadow texture samples it through a comparison sampler that is linear, less or equal, and clamped to its edge. The slot's sampling is ignored. The map's rows are stored bottom first, as GL's are, so clip space's -1 to 1 is its 0 to 1.
- `disposeTexture`: Frees a texture of any kind.
  - `handle`: The texture.
  - throws `String`: An unknown handle.
- `createBuffer`: Creates a stream vertex buffer, filled each frame by `updateBuffer`.
  - `capacityBytes`: The capacity, in bytes, which must be a positive multiple of 4.
  - returns: The buffer's handle.
  - throws `String`: A capacity that is not a positive multiple of 4.
- `createStaticBuffer`: Creates an immutable buffer of vertices or indices.
  - `data`: The contents.
  - `bytes`: The number of bytes of data to use, which must be a positive multiple of 4.
  - `index`: Whether the buffer holds uint32 indices (little-endian) rather than vertices.
  - returns: The buffer's handle.
  - throws `String`: A size that is not a positive multiple of 4.
- `updateBuffer`: Replaces a stream buffer's contents for the draws after it.
  - `handle`: The stream buffer.
  - `data`: The new contents.
  - `usedBytes`: The number of bytes of data to use.
  - throws `String`: A call outside a pass, an unknown handle, or a size out of range.

  It must be called inside a pass, and can be called any number of times a frame. A buffer drawn into a target and then into the screen is uploaded twice.
- `disposeBuffer`: Frees a buffer.
  - `handle`: The buffer.
  - throws `String`: An unknown handle.
- `createShader`: Builds a program for pipelines to use.
  - `source`: The program, with the dialect this adapter compiles, its attributes by slot, its uniform blocks, and its textures. Each texture is a plain, cube, shadow or data texture.
  - returns: The program's handle.
  - throws `String`: A program that does not build, with the compiler's log.
- `disposeShader`: Frees a program, disposing the pipelines made with it first.
  - `handle`: The program.
  - throws `String`: An unknown handle.
- `createPipeline`: Creates a pipeline.
  - `desc`: What the pipeline fixes for its draws.
  - returns: The pipeline's handle.
  - throws `String`: An unknown program, or a description this adapter cannot make.
- `disposePipeline`: Frees a pipeline.
  - `handle`: The pipeline.
  - throws `String`: An unknown handle.
- `beginShadowPass`: Starts a depth-only pass into one layer of a shadow map, for depth-only pipelines.
  - `map`: The shadow map, as a `createShadowMap` handle.
  - `layer`: The layer to draw into.
  - throws `String`: A call inside a pass, a handle that is not a shadow map, or a layer it does not have.

  The layer is cleared to the farthest depth, and the viewport is set to all of it. The pass comes before the screen's and outside any other. `endTargetPass` ends it.
- `beginTargetPass`: Starts a pass into a render target.
  - `target`: The render target, as a `createRenderTarget` handle.
  - `red`: The clear color's red.
  - `green`: The clear color's green.
  - `blue`: The clear color's blue.
  - `alpha`: The clear color's alpha.
  - throws `String`: A call inside a pass, or a handle that is not a render target.

  The target is cleared to the color as its texels store it. That is 0 to 1 in an RGBA8 target, and can be beyond 1 in a half-float one. Its depth, if it has one, is cleared to the farthest, and the viewport is set to all of it. The pass comes before the screen's and outside any other. `endTargetPass` ends it.
- `endTargetPass`: Ends the pass that `beginTargetPass` or `beginShadowPass` started.
  - throws `String`: No such pass is open.

  Its target can be sampled from then on.
- `beginFrame`: Starts the frame's screen pass, after its target passes.
  - `width`: The framebuffer's width, in framebuffer pixels.
  - `height`: The framebuffer's height, in framebuffer pixels.
  - `clearColor`: The clear color, as 0xAARRGGBB.
  - throws `String`: A call inside a pass, or a size of 0 or less.

  The framebuffer is cleared to the color and the farthest depth, and the viewport is set to all of it.
- `applyViewport`: Sets the rectangle that the following draws fill.
  - `x`: The left edge, in framebuffer pixels.
  - `y`: The bottom edge, in framebuffer pixels from the bottom.
  - `w`: The width, in framebuffer pixels.
  - `h`: The height, in framebuffer pixels.
  - throws `String`: A call outside a frame, or a size of 0 or less.
- `applyScissor`: Clips the following draws to a rectangle, until `resetScissor` or the end of the pass.
  - `x`: The left edge, in framebuffer pixels.
  - `y`: The bottom edge, in framebuffer pixels from the bottom.
  - `w`: The width, in framebuffer pixels.
  - `h`: The height, in framebuffer pixels.
  - throws `String`: A call outside a pass, or a size below 0.

  A pass begins unclipped.
- `resetScissor`: Removes the clip that `applyScissor` set, for the rest of the pass.
  - throws `String`: A call outside a pass.
- `draw`: Draws through a pipeline.
  - `pipeline`: The pipeline.
  - `buffers`: The buffer for each of the pipeline's buffers, by index, or 0 for a gap. Each is a `createBuffer` handle as this frame's upload left it, or a `createStaticBuffer` handle.
  - `indices`: For an indexed pipeline, a static index buffer. Otherwise it is ignored.
  - `first`: The first vertex, or for an indexed pipeline the first index.
  - `count`: The number of vertices, or indices.
  - `firstInstance`: The first record of the instanced buffers.
  - `instanceCount`: The number of instances.
  - `textures`: The texture bound at each of the program's texture slots, by slot. A slot provided 0, or past the array's end, reads a clear 1x1 texture of its kind, for a texture the program declares and doesn't read.
  - `samplings`: How each texture is sampled, by slot. A shadow map or data texture is sampled as its kind requires.
  - `uniforms`: The bytes of each uniform block, by slot, at its declared size, or null for a slot the program lacks.
  - throws `String`: Anything invalid, before drawing.

  Only whole primitives are drawn. A pipeline without buffers draws count vertices from no data, so one triangle over the viewport is three vertices. Block 0 of the uniforms is flipped as the pipeline's `ClipFlip` specifies.
- `endFrame`: Ends the screen's pass and the frame, and submits it.
  - throws `String`: No screen pass is open.

  `present` shows the frame. Between the two calls, the frame can be read back with `readPixels(0)`, and the caller can do other work.
- `present`: Shows the frame that `endFrame` submitted, and waits for the display's refresh.
  Natively the wait paces the caller's loop. In a page it does nothing, because the browser shows the frame when the frame's callback returns.
- `readPixels`: Reads a render target, or the frame just ended, back from the GPU.
  - `target`: The render target, as a `createRenderTarget` handle, or 0 for the frame `endFrame` just ended.
  - `read`: Receives the pixels and their width and height. The pixels are `width * height * 4` bytes of RGBA8, with rows top first.
  - `failed`: Receives why the pixels can't be read, which is that no frame has ended since the last `beginFrame`.
  - throws `String`: A call inside a pass, or a handle that is not an RGBA8 render target.

  It waits for the GPU, so it suits screenshots and checks, not every frame. The frame `endFrame` ended must be read before `present`, and in a page before the frame's callback returns. One of `read` or `failed` is called once, on the main thread. It is called during the call, or later on a GPU that reads back asynchronously.
- `dispose`: Releases the adapter.
  It is called after every handle the adapter made is disposed, and before its window is closed.

## IHttp

*interface* in [`platform/src/helix/platform/IHttp.hx`](../../platform/src/helix/platform/IHttp.hx), `import helix.platform.IHttp;`, extends `IPollable`

Defines HTTP GET requests, whose response body arrives in parts and which can be aborted.

```haxe
function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:haxe.io.Bytes -> Void, done:() -> Void, failed:String -> Void):() -> Void
function poll():Void
function dispose():Void
```

- `get`: Starts a GET request.
  - `url`: The URL. In a page, a relative URL is relative to the page. Natively, only http and https URLs are allowed.
  - `noCache`: Whether to bypass HTTP caches, where the platform has one.
  - `headers`: The request's headers, names in any case.
  - `head`: Receives the response's status and its headers, names in lower case.
  - `body`: Receives each part of the body.
  - `done`: Called when the body is all here.
  - `failed`: Receives why the transfer failed.
  - returns: The abort, which stops the transfer where the platform can.

  The callbacks are called on the main thread, never during this call. `head` is called once, then `body` for each part of the body as it arrives, then one of `done` or `failed`. An HTTP error status is a response, not a failure. After an abort, nothing more is called.

  A conditional request (`If-None-Match`, `If-Modified-Since`) may be answered 200 with the whole body, as HTTP allows any server to do.
- `poll`: Delivers what arrived on the platform's threads since the last poll. The program calls it once a frame.
- `dispose`: Aborts every transfer.

## IImageDecoder

*interface* in [`platform/src/helix/platform/IImageDecoder.hx`](../../platform/src/helix/platform/IImageDecoder.hx), `import helix.platform.IImageDecoder;`, extends `IPollable`

Defines image decoding from a file into 8-bit RGBA pixels.

It reads PNG, JPEG, BMP, TGA and GIF files, and a GIF's first frame only. The pixels are not premultiplied, and rows run top to bottom.

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
- `poll`: Delivers what finished on the platform's threads since the last poll. The program calls it once a frame.
- `dispose`: Closes the decoder. A decode still running finishes without calling back.

## IKeyboard

*interface* in [`platform/src/helix/platform/IKeyboard.hx`](../../platform/src/helix/platform/IKeyboard.hx), `import helix.platform.IKeyboard;`

Defines the keyboard: `KeyDown`, `KeyUp` and `Text` in `IEvents.events` while it exists.

Its adapter is constructed over the events adapter, whose `poll` delivers its events.

```haxe
var textInput(get, set):Bool
function dispose():Void
```

- `textInput`: Gets or sets whether typed text arrives, as `Text` events. A phone shows its keyboard while it is on. Defaults to false.
- `dispose`: Stops listening to the keyboard.

## IMouse

*interface* in [`platform/src/helix/platform/IMouse.hx`](../../platform/src/helix/platform/IMouse.hx), `import helix.platform.IMouse;`

Defines the mouse: `MouseMove`, `MouseDown`, `MouseUp`, `MouseLeave` and `Wheel` in `IEvents.events` while it exists.

Its adapter is constructed over the events adapter, whose `poll` delivers its events. A pen counts as the mouse.

```haxe
function dispose():Void
```

- `dispose`: Stops listening to the mouse.

## IPollable

*interface* in [`platform/src/helix/platform/IPollable.hx`](../../platform/src/helix/platform/IPollable.hx), `import helix.platform.IPollable;`

Defines a contract that answers later, delivering what it was asked for in its `poll` on the main thread and at no other time.

The program calls `poll` once a frame on each pollable it made. One it forgets to poll never answers. A service never polls the pollables it was provided, so one built over an `IFileSystem` or an `IAudio` leaves their polls to the program.

`IEvents`, `IHttp`, `IFileSystem`, `IAudio`, `IAudioDecoder` and `IImageDecoder` are pollable. A layer above them that answers later is pollable too, and is polled the same way.

```haxe
function poll():Void
```

- `poll`: Delivers what finished since the last poll. The program calls it once a frame.

## ISystem

*interface* in [`platform/src/helix/platform/ISystem.hx`](../../platform/src/helix/platform/ISystem.hx), `import helix.platform.ISystem;`

Defines the facts about where the program runs.

They are the program's company and product, the device, the options the program was started with, the time, where the program's own files are, and where the OS keeps a program's files.

```haxe
var company(default, null):String
var product(default, null):String
var device(get, never):Device
function getOption(name:String):Null<String>
function getTime():Float
function getProgramDirectory():String
function getDataDirectory():String
function getCacheDirectory():String
```

- `company`: Gets the company that makes the program: the `helix-company` define, or "DefaultCompany".
- `product`: Gets the program's name: the `helix-product` define, or natively the executable's name and in a page "Game". It names the program wherever one is shown, such as a window's title or a log.
- `device`: Gets what the program runs on, as far as the platform reports it.
- `getOption`: Returns an option the program was started with.
  - `name`: The option's name.
  - returns: The option's value, or null when it is not set.

  Natively the option is the environment variable named HELIX_ followed by the name in capitals. In a page it is the URL's query parameter of that name.
- `getTime`: Returns the time on a monotonic clock, for measuring how long something took, such as a frame.
  - returns: Seconds from an unspecified zero.

  It never goes back or jumps when the system's clock is set. A pause in the program, such as at a debugger or in a hidden page, counts as time that passed. In a page the clock is `performance.now`, and natively it is SDL's.
- `getProgramDirectory`: Returns where the files that ship with the program are, such as its assets.
  - returns: The directory natively, or the URL in a page.

  Natively it is the executable's directory, or `Contents/Resources` in a macOS app bundle, and a read-only `IFileSystem` reads it. In a page it is "./", the page's own directory on its server, as a URL relative to the page that `IHttp` fetches from.
- `getDataDirectory`: Returns where the OS keeps a program's files that must last, such as its saves.
  - returns: The directory natively, or the database's name in a page.
  - throws `String`: Natively, when the environment variable the directory comes from is set to a path that isn't absolute, or is unset and the OS has no such directory.

  Natively it is the user's data directory, then the company and the product (the `helix-company` and `helix-product` defines). The user's data directory is `$XDG_DATA_HOME` or `~/.local/share` on Linux, `~/Library/Application Support` on macOS, and `%APPDATA%` on Windows. The directory may not exist yet.

  In a page it is the name of the database where the browser keeps the program's files, "company/product/data".
- `getCacheDirectory`: Returns where the OS keeps a program's files that can be made or fetched again, such as downloaded assets.
  - returns: The directory natively, or the database's name in a page.
  - throws `String`: Natively, when the environment variable the directory comes from is set to a path that isn't absolute, or is unset and the OS has no such directory.

  Natively it is the user's cache directory, then the company and the product (the `helix-company` and `helix-product` defines). The user's cache directory is `$XDG_CACHE_HOME` or `~/.cache` on Linux, and `~/Library/Caches` on macOS. On Windows it is `%LOCALAPPDATA%`, then the company, the product and `cache`. The directory may not exist yet.

  In a page it is the name of the database where the browser keeps the program's files, "company/product/cache".

## ITilt

*interface* in [`platform/src/helix/platform/ITilt.hx`](../../platform/src/helix/platform/ITilt.hx), `import helix.platform.ITilt;`

Defines the device's tilt: `Tilt` and `TiltState` in `IEvents.events` once access is requested.

Its adapter is constructed over the events adapter, whose `poll` delivers its events and runs the request's callbacks.

```haxe
function requestAccess(?done:() -> Void, ?failed:String -> Void):Bool
function releaseAccess():Void
function dispose():Void
```

- `requestAccess`: Asks for the device's motion sensor, whose readings then arrive as `Tilt` events.
  - `done`: Optional. Called once readings arrive.
  - `failed`: Optional. Receives why there will be none: the player refused, the page isn't secure (not HTTPS), or the browser reads no orientation.
  - returns: False, calling neither and reporting `Unavailable`, where the tilt can't be read at all.

  A page may need the player's permission, which is asked at the player's next tap. `TiltState` events report each change, for a game that shows "tap to start tilt" while it waits. A reading that arrives after the tilt was reported unavailable turns it on, as a phone's sensor may start late.
- `releaseAccess`: Stops the readings. A permission the player granted stays granted, so a later `requestAccess` usually starts without asking again.
- `dispose`: Stops the readings and any request still waiting.

## ITouch

*interface* in [`platform/src/helix/platform/ITouch.hx`](../../platform/src/helix/platform/ITouch.hx), `import helix.platform.ITouch;`

Defines touch: `TouchDown`, `TouchMove` and `TouchUp` in `IEvents.events` while it exists.

Its adapter is constructed over the events adapter, whose `poll` delivers its events. A finger is never reported as the mouse.

```haxe
function dispose():Void
```

- `dispose`: Stops listening to touch.

## IWindow

*interface* in [`platform/src/helix/platform/IWindow.hx`](../../platform/src/helix/platform/IWindow.hx), `import helix.platform.IWindow;`

Defines the window a program draws in, with its title, size, position, fullscreen, visibility and monitors.

In a page the window is the page. Its title is the document's and its size is the viewport's, while fullscreen and visibility apply to the canvas. Sizes are in logical pixels unless they are named as framebuffer pixels.

A request asks for something the platform may refuse, or grant later. It returns whether it asked, and the matching property answers on a later frame. A `can` method tells whether to offer the request at all.

The window reports nothing by itself. What happens to it, such as being resized, focused, minimized or asked to close, arrives as events from `IEvents.poll`.

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
var onClose:Null<() -> Void>
```

- `framebufferWidth`: Gets the drawable area's width, in framebuffer pixels.
- `framebufferHeight`: Gets the drawable area's height, in framebuffer pixels.
- `pixelRatio`: Gets the number of framebuffer pixels per logical pixel.
- `focused`: Gets a value indicating whether the window has the keyboard, as of the last `IEvents.poll`.
- `title`: Gets or sets the title bar's text. In a page it is the document's title.
- `width`: Gets the window's inner width, in logical pixels. In a page it is the viewport's width.
- `height`: Gets the window's inner height, in logical pixels. In a page it is the viewport's height.
- `requestSize`: Asks for an inner size.
  - `width`: The width, in logical pixels.
  - `height`: The height, in logical pixels.
  - returns: False, asking nothing, in a page or for a size under 1.

  The window manager may give another size, or none; `width` and `height` answer on a later frame.
- `canMove`: Returns whether `requestPosition` and `requestMonitorIndex` can ask.
  - returns: False in a page, and where the compositor places windows (Wayland, XWayland).
- `x`: Gets the window's left edge on the desktop, in logical pixels.
  Natively it is 0 where the window can't move. In a page it is the browser window's left edge.
- `y`: Gets the window's top edge on the desktop, in logical pixels.
  Natively it is 0 where the window can't move. In a page it is the browser window's top edge.
- `requestPosition`: Asks for the window's left and top edges on the desktop.
  - `x`: The left edge, in logical pixels.
  - `y`: The top edge, in logical pixels.
  - returns: False, asking nothing, where the window can't move (`canMove`).

  `x` and `y` answer on a later frame, with what the window manager gave.
- `canFullscreen`: Returns whether `requestFullscreen` can ask.
  - returns: True natively. In a page, whether the page may go fullscreen.
- `fullscreen`: Gets a value indicating whether the window is fullscreen now. In a page it tells whether the canvas is.
- `requestFullscreen`: Asks for fullscreen or a window.
  - `enabled`: True for fullscreen, false for a window.
  - `done`: Optional. Called once the change is granted.
  - `failed`: Optional. Receives the browser's reason when it refuses. The page is unchanged.
  - returns: False, calling neither, where it can't ask (`canFullscreen`).

  `fullscreen` answers on a later frame. Natively the request is granted. A browser grants fullscreen only soon after a key press, click or tap. Without a recent one, the request waits for the player's next one.
- `requestOrientation`: Asks for the screen to be held one way up, or as the player holds it.
  - `orientation`: Landscape, Portrait, or Any to release a lock.
  - `done`: Optional. Called once the screen is locked.
  - `failed`: Optional. Receives the browser's reason when it refuses.
  - returns: False, calling neither, where it can't ask, which is natively.

  Only some browsers lock the screen. Chrome on Android does, but only in fullscreen, so the request belongs in `requestFullscreen`'s done. iOS Safari and desktops don't lock it. A game also shows "turn your device" when the shape is wrong.
- `visible`: Gets a value indicating whether the program shows the window. In a page it tells whether the canvas is shown.
  Whether the player can see the window, because it isn't minimized and its tab isn't in the background, is reported by the `Shown` and `Hidden` events.
- `requestVisible`: Asks to show or hide the window. In a page it shows or hides the canvas.
  - `visible`: True to show it.
  - returns: True, because it always asks.

  `visible` answers on a later frame, natively once the window manager has shown it.
- `monitorCount`: Gets the number of monitors, at least 1. A page sees one screen.
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
  - returns: The edge, in logical pixels, or 0 for an index out of range and in a page.
- `getMonitorY`: Returns a monitor's top edge on the desktop.
  - `index`: The monitor.
  - returns: The edge, in logical pixels, or 0 for an index out of range and in a page.
- `getMonitorWidth`: Returns a monitor's width.
  - `index`: The monitor.
  - returns: The width, in logical pixels, or 0 for an index out of range.
- `getMonitorHeight`: Returns a monitor's height.
  - `index`: The monitor.
  - returns: The height, in logical pixels, or 0 for an index out of range.
- `canClose`: Returns whether `close` removes the window.
  - returns: True natively. False in a page, which a script can't close.

  A menu checks it before offering Quit.
- `close`: Closes the window natively, and does nothing in a page.
  `onClose` runs before the window closes. The program disposes the graphics drawing in the window before calling it, and ends its loop after it.
- `onClose`: Gets or sets the function called once, as the window goes for good. It defaults to null, for none.
  Natively it is called in `close`. In a page it is called at pagehide. Nothing of the program runs after it, so it is the last place to save. In a page no frame follows, and an asynchronous write started in it may not finish. A page receives no `CloseRequested`, so this is a page's only end.

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
- `named`: Returns the key a name spells, ignoring case.
  - `name`: The key's name.
  - returns: The key.
  - throws `String`: When no key has the name.

  The name is a key's own spelling or a digit, such as "A", "space", "KeypadEnter" or "0".
- `getName`: Returns a key's name, as `named` reads it.
  - `key`: The key.
  - returns: The key's name.

  The name is the key's own spelling, such as "Space", "PageUp" or "KeypadEnter", or a digit key's digit, such as "0".
- `toString`: Returns the value's name as written (Space, Apostrophe): what Std.string, interpolation and trace show.

## MouseButton

*abstract* in [`platform/src/helix/platform/MouseButton.hx`](../../platform/src/helix/platform/MouseButton.hx), `import helix.platform.MouseButton;`

Specifies a mouse button.

Values: `Left`, `Right`, `Middle`.

```haxe
static final all(default, null):Array<MouseButton>
function toString():String
```

- `all`: Every button.
- `toString`: Returns the value's name as written (Left, Right): what Std.string, interpolation and trace show.

## Orientation

*abstract* in [`platform/src/helix/platform/Orientation.hx`](../../platform/src/helix/platform/Orientation.hx), `import helix.platform.Orientation;`

Specifies which way up a game wants the screen (`IWindow.requestOrientation`).

- `Orientation.Any`: As the player holds it, with any lock released.
- `Orientation.Landscape`: Wider than tall, with the long side across.
- `Orientation.Portrait`: Taller than wide, as a phone held upright.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Any, Landscape): what Std.string, interpolation and trace show.

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
- `toString`: Returns the value's name as written (LeftX, LeftY): what Std.string, interpolation and trace show.

## PadButton

*abstract* in [`platform/src/helix/platform/PadButton.hx`](../../platform/src/helix/platform/PadButton.hx), `import helix.platform.PadButton;`

Specifies a gamepad's button by its place on an Xbox-style pad, numbered as the W3C standard gamepad numbers them.

The triggers are both buttons and axes. As buttons, they are pressed when pulled past half way, or by a digital trigger.

Values: `South`, `East`, `West`, `North`, `LeftBumper`, `RightBumper`, `LeftTrigger`, `RightTrigger`, `Back`, `Start`, `LeftStick`, `RightStick`, `Up`, `Down`, `Left`, `Right`, `Guide`.

```haxe
static inline var COUNT:Int
static final all(default, null):Array<PadButton>
function toString():String
```

- `COUNT`: One past the largest value, for arrays indexed by button.
- `all`: Every button.
- `toString`: Returns the value's name as written (South, East): what Std.string, interpolation and trace show.

## PipelineDesc

*typedef* in [`platform/src/helix/platform/PipelineDesc.hx`](../../platform/src/helix/platform/PipelineDesc.hx), `import helix.platform.PipelineDesc;`

Represents everything a pipeline fixes for the draws through it.

`IGraphics.createPipeline` makes a pipeline from it. An adapter makes what the description specifies and knows nothing else about the program.

- `shader:Int`: The program, as an `IGraphics.createShader` handle.
- `primitive:Primitive`: The primitive the draws make.
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

- `toString`: Returns the value's name as written (Triangles, Lines): what Std.string, interpolation and trace show.

## Sampling

*abstract* in [`platform/src/helix/platform/Sampling.hx`](../../platform/src/helix/platform/Sampling.hx), `import helix.platform.Sampling;`

Represents how a draw samples a texture, by its filter and how it wraps along u and v.

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

- `NEAREST`: Nearest filtering, clamped, for pixel art.
- `LINEAR`: Linear filtering, clamped, for a smooth look.
- `filter`: Gets how the texture is filtered, Linear or Nearest.
- `wrapU`: Gets how the texture wraps along u.
- `wrapV`: Gets how the texture wraps along v.
- `withFilter`: Returns this sampling with another filter.
  - `filter`: The new filter.
  - returns: The sampling, its wrapping unchanged.
- `withWrap`: Returns this sampling with other wrapping.
  - `wrapU`: How the texture wraps along u.
  - `wrapV`: How the texture wraps along v.
  - returns: The sampling, its filter unchanged.
- `COUNT`: The number of distinct values, which run 0 to COUNT - 1. It is the size of an adapter's table of samplers.

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

Represents a compiled program, with its stages in each dialect the adapters compile, its vertex attributes, and what it binds.

`IGraphics.createShader` builds a program from it. An adapter reads only its own dialect. That is GLSL ES 300 in the browser, GLSL 410 for GL natively, and SDL_GPU's stages for SDL_GPU.

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
- `shadow:Bool`: Whether it is a shadow map, which is a depth array read through a comparison sampler.
- `glslName:String`: The GLSL name of the texture and sampler pair.
- `data:Bool`: Whether the program never filters it.
- `cube:Bool`: Whether it is a cubemap.

## StreamSource

*enum* in [`platform/src/helix/platform/StreamSource.hx`](../../platform/src/helix/platform/StreamSource.hx), `import helix.platform.StreamSource;`

Specifies what an audio stream plays (`IAudio.openStream`).

- `Local(location:String)`: A file the platform reads directly. Natively it is a path, and in a page it is a URL, such as a Blob's.
- `Remote(url:String)`: A URL, which only an output that plays URLs itself opens (`IAudio.playsUrls`).
- `Downloading(source:GrowingSource)`: A file still downloading, played as it arrives. Only a native output plays it.

## TextureFormat

*abstract* in [`platform/src/helix/platform/TextureFormat.hx`](../../platform/src/helix/platform/TextureFormat.hx), `import helix.platform.TextureFormat;`

Specifies the format of a texture's texels.

The 8-bit and compressed formats hold sRGB values. The compressed formats store 4x4 blocks of 16 bytes, and only some GPUs sample them (`IGraphics.canSample`).

- `TextureFormat.Rgba8`: Four bytes a texel, rows top first.
- `TextureFormat.Bc7`: BC7 (BPTC), compressed, for desktop GPUs.
- `TextureFormat.Astc4x4`: ASTC 4x4, compressed, for phone GPUs.
- `TextureFormat.Etc2Rgba8`: ETC2 RGBA8 with EAC alpha, compressed, for older phone GPUs.
- `TextureFormat.Rgba16f`: RGBA half floats (IEEE binary16, little-endian), 8 bytes a texel, rows top first.

```haxe
function levelBytes(width:Int, height:Int):Int
function toString():String
```

- `levelBytes`: Returns the byte size of one level of a texture in this format.
  - `width`: The level's width, in texels.
  - `height`: The level's height, in texels; for a cube, one face's.
  - returns: The level's size, in bytes.
- `toString`: Returns the value's name as written (Rgba8, Bc7): what Std.string, interpolation and trace show.

## TiltStatus

*enum* in [`platform/src/helix/platform/TiltStatus.hx`](../../platform/src/helix/platform/TiltStatus.hx), `import helix.platform.TiltStatus;`

Specifies where the device's tilt is (`Event.TiltState`, after `ITilt.requestAccess`).

- `Off`: Not read: it was never asked for, or it was turned off.
- `WaitingForTap`: Waiting for the player's next tap, where a page asks for permission.
- `On`: Read: `Tilt` events arrive.
- `Refused`: The player refused permission.
- `Unavailable`: The device gives no readings: there is no sensor, or none answered, or none is read on this target.
- `NeedsHttps`: The page isn't secure (not HTTPS), so the browser gives no readings.

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
- `instanced:Bool`: Whether each record belongs to an instance rather than a vertex, so the buffer steps once per instance.
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

- `toString`: Returns the value's name as written (Clamp, Repeat): what Std.string, interpolation and trace show.

## Defines

Set in a build's hxml, as `-D helix-product=Asteroids` (quoted when the value has a space: `-D "helix-company=Whirling Gizmo"`). `haxe --help-user-defines` lists them too, and an editor completes them in an hxml file.

- `helix-company=<name>`: The company that makes the program, one directory's name. ISystem's data and cache directories are under it, and natively SDL names the program by its product. Defaults to DefaultCompany.
- `helix-product=<name>`: The program's name, one directory's name. ISystem's data and cache directories are under the company and it, and natively SDL names the program by it, in the OS's audio mixer for one. Defaults to the executable's name natively and Game in a page.
