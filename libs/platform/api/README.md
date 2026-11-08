# helix.platform

Generated from the doc comments by `tools/gen_apidoc.py`.

## Packages

- [`helix.platform.adapters`](adapters.md): Sdl3MixerAudioAdapter, WebAudioAdapter, Sdl3MixerAudioDecoderAdapter, WebAudioDecoderAdapter, DomClipboardAdapter, Sdl3ClipboardAdapter, DomEventsAdapter, DomEventsAdapterOptions, Sdl3EventsAdapter, DownloadExportAdapter, FileSystemExportAdapter, FileSystemExportAdapterOptions, BrowserFileSystemAdapter, BrowserFileSystemAdapterOptions, NativeFileSystemAdapter, NativeFileSystemAdapterOptions, CanvasFontRasterizerAdapter, StbFontRasterizerAdapter, DomGamepadsAdapter, DomGamepadsAdapterOptions, Sdl3GamepadsAdapter, Sdl3GamepadsAdapterOptions, Sdl3GpuGraphicsAdapter, SokolGraphicsAdapter, WebGl2GraphicsAdapter, WebGl2GraphicsAdapterOptions, FetchApiHttpAdapter, HaxeHttpAdapter, CanvasImageDecoderAdapter, StbImageDecoderAdapter, DomKeyboardAdapter, DomKeyboardAdapterOptions, Sdl3KeyboardAdapter, Sdl3KeyboardAdapterOptions, DomMouseAdapter, DomMouseAdapterOptions, Sdl3MouseAdapter, Sdl3MouseAdapterOptions, DomSystemAdapter, Sdl3SystemAdapter, DomTiltAdapter, DomTiltAdapterOptions, Sdl3TiltAdapter, Sdl3TiltAdapterOptions, DomTouchAdapter, DomTouchAdapterOptions, Sdl3TouchAdapter, Sdl3TouchAdapterOptions, DomWindowAdapter, DomWindowAdapterOptions, Sdl3WindowAdapter, Sdl3WindowAdapterOptions, Sdl3WindowGraphics
- [`helix.platform.tools`](tools.md): ShaderCompileOptions, ShaderCompiler

## AudioEffect

*enum* in [`libs/platform/src/helix/platform/AudioEffect.hx`](../src/helix/platform/AudioEffect.hx), `import helix.platform.AudioEffect;`

Specifies an effect on a chain of what voices play (`IAudioEffects.addEffect`), with its settings.

Both targets compute each effect the same way, so a game sounds alike on both. The filters follow the Audio EQ Cookbook, as Web Audio's `BiquadFilterNode` does. The reverbs are convolutions, as Web Audio's `ConvolverNode` is, with the same room's response on both. The delay, the distortion, the compressor and the pitch shift are the platform's own, the same code natively and in a page.

- `LowPass(frequency:Float, q:Float)`: Lets through what is below a frequency and cuts what is above it, as underwater or behind a wall sounds.
  - `frequency`: The cutoff in Hz, 10 to 22050.
  - `q`: How sharp the cutoff is, 0.1 to 20, where 0.71 is flat to the cutoff.
- `HighPass(frequency:Float, q:Float)`: Lets through what is above a frequency and cuts what is below it, as a radio or a telephone sounds.
  - `frequency`: The cutoff in Hz, 10 to 22050.
  - `q`: How sharp the cutoff is, 0.1 to 20, where 0.71 is flat to the cutoff.
- `BandPass(frequency:Float, q:Float)`: Lets through a band around a frequency and cuts what is either side of it.
  - `frequency`: The band's middle in Hz, 10 to 22050.
  - `q`: How narrow the band is, 0.1 to 20.
- `Peaking(frequency:Float, q:Float, gain:Float)`: Raises or lowers a band around a frequency, one band of an equalizer.
  - `frequency`: The band's middle in Hz, 10 to 22050.
  - `q`: How narrow the band is, 0.1 to 20.
  - `gain`: The change in decibels, -40 to 40.
- `LowShelf(frequency:Float, gain:Float)`: Raises or lowers everything below a frequency, an equalizer's bass.
  - `frequency`: The shelf's edge in Hz, 10 to 22050.
  - `gain`: The change in decibels, -40 to 40.
- `HighShelf(frequency:Float, gain:Float)`: Raises or lowers everything above a frequency, an equalizer's treble.
  - `frequency`: The shelf's edge in Hz, 10 to 22050.
  - `gain`: The change in decibels, -40 to 40.
- `Delay(seconds:Float, feedback:Float, mix:Float)`: Repeats what plays after a time, each repeat quieter, as an echo.
  - `seconds`: The time to each repeat, 0.001 to 2.
  - `feedback`: How loud each repeat is against the one before, 0 to 0.95.
  - `mix`: How much of the echo is heard against what plays, 0 (none) to 1 (only the echo).
- `Reverb(size:Float, damping:Float, mix:Float)`: Adds the reflections of a room, from a small room to a hall. The room's response is made from its size and damping by the platform's own code, the same on both targets.
  - `size`: The room's size, 0 (small) to 1 (a hall).
  - `damping`: How soon the reflections lose their highs, 0 (bright) to 1 (dull).
  - `mix`: How much of the room is heard against what plays, 0 (none) to 1 (only the room).
- `RecordedReverb(response:haxe.io.Bytes, channelCount:Int, mix:Float)`: Adds the reflections of a recorded room: its impulse response, the echo of a single click played in it.
  - `response`: The response as 32-bit float PCM at 44100 Hz, -1 to 1, interleaved when stereo, up to 10 seconds. It is copied.
  - `channelCount`: Its channels, 1 or 2.
  - `mix`: How much of the room is heard against what plays, 0 (none) to 1 (only the room).
- `Compressor(threshold:Float, ratio:Float, attack:Float, release:Float)`: Evens out loud and quiet, lowering what is above a level.
  - `threshold`: The level in decibels where it starts, -60 to 0.
  - `ratio`: How much it lowers what is above the threshold, 1 (not at all) to 20.
  - `attack`: The seconds it takes to lower a sound that gets loud, 0 to 1.
  - `release`: The seconds it takes to let a sound back up, 0 to 1.
- `Distortion(drive:Float)`: Clips what plays toward a square wave, from warmth to a broken speaker.
  - `drive`: How hard it clips, 0 (not at all) to 1.
- `PitchShift(ratio:Float)`: Raises or lowers the pitch of what plays and keeps its speed, as a voice changer or a slowed world sounds. `IAudio.setPitch` changes a voice's pitch and speed together.
  - `ratio`: The pitch against what plays, 0.5 (an octave down) to 2 (an octave up), where 1 changes nothing.

## Blend

*abstract* in [`libs/platform/src/helix/platform/Blend.hx`](../src/helix/platform/Blend.hx), `import helix.platform.Blend;`

Represents how a pipeline's colors are combined with the colors already in the target: a factor for each side and an operation, for red, green and blue, and for alpha.

The source is the color a draw writes, and the destination the color in the target. Each channel becomes `source * sourceFactor` combined by the operation with `destination * destinationFactor`, then clamped to what the target stores (0 to 1 in an RGBA8 target). Colors are straight alpha, not premultiplied, unless a program premultiplies its own. It is a small value, like `Sampling`; adapters keep a GPU blend state for each value used.

```haxe
var multiply = new Blend(DestinationColor, OneMinusSourceAlpha);
var keepAlpha = new Blend(SourceAlpha, OneMinusSourceAlpha, Add, Zero, One);
```

```haxe
function new(colorSource:BlendFactor, colorDestination:BlendFactor, ?colorOperation:BlendOperation = Add, ?alphaSource:BlendFactor, ?alphaDestination:BlendFactor, ?alphaOperation:BlendOperation)
static inline var OPAQUE:Blend
static inline var ALPHA:Blend
static inline var ADDITIVE:Blend
var colorSource(get, never):BlendFactor
var colorDestination(get, never):BlendFactor
var alphaSource(get, never):BlendFactor
var alphaDestination(get, never):BlendFactor
var colorOperation(get, never):BlendOperation
var alphaOperation(get, never):BlendOperation
```

- `new`: Creates a blend.
  - `colorSource`: The factor for the source's red, green and blue.
  - `colorDestination`: The factor for the destination's red, green and blue.
  - `colorOperation`: Optional. How red, green and blue are combined; defaults to Add.
  - `alphaSource`: Optional. The factor for the source's alpha; defaults to colorSource.
  - `alphaDestination`: Optional. The factor for the destination's alpha; defaults to colorDestination.
  - `alphaOperation`: Optional. How the alphas are combined; defaults to colorOperation.
- `OPAQUE`: No blending: the color replaces the target's.
- `ALPHA`: The color blended over the target's by its alpha. The target's alpha becomes `a + destination alpha * (1 - a)`, so what is drawn over a clear target stays as opaque as it was drawn.
- `ADDITIVE`: The color, multiplied by its alpha, added to the target's. It suits light, fire and glows.
- `colorSource`: Gets the factor for the source's red, green and blue.
- `colorDestination`: Gets the factor for the destination's red, green and blue.
- `alphaSource`: Gets the factor for the source's alpha.
- `alphaDestination`: Gets the factor for the destination's alpha.
- `colorOperation`: Gets how red, green and blue are combined.
- `alphaOperation`: Gets how the alphas are combined.

## BlendFactor

*abstract* in [`libs/platform/src/helix/platform/BlendFactor.hx`](../src/helix/platform/BlendFactor.hx), `import helix.platform.BlendFactor;`

Specifies what one side of a blend is multiplied by.

The source is the color a draw writes, and the destination the color already in the target. Each factor is a value per channel.

- `BlendFactor.Zero`: 0: the side adds nothing.
- `BlendFactor.One`: 1: the side as it is.
- `BlendFactor.SourceColor`: The source color, channel by channel.
- `BlendFactor.OneMinusSourceColor`: 1 minus the source color, channel by channel.
- `BlendFactor.DestinationColor`: The destination color, channel by channel.
- `BlendFactor.OneMinusDestinationColor`: 1 minus the destination color, channel by channel.
- `BlendFactor.SourceAlpha`: The source's alpha.
- `BlendFactor.OneMinusSourceAlpha`: 1 minus the source's alpha.
- `BlendFactor.DestinationAlpha`: The destination's alpha.
- `BlendFactor.OneMinusDestinationAlpha`: 1 minus the destination's alpha.
- `BlendFactor.SourceAlphaSaturated`: The smaller of the source's alpha and 1 minus the destination's alpha for red, green and blue, and 1 for alpha.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Zero, One): what Std.string, interpolation and trace show.

## BlendOperation

*abstract* in [`libs/platform/src/helix/platform/BlendOperation.hx`](../src/helix/platform/BlendOperation.hx), `import helix.platform.BlendOperation;`

Specifies how a blend combines its two sides, each already multiplied by its factor.

The source is the color a draw writes, and the destination the color already in the target. Min and Max take the two colors as they are, and their factors are ignored.

- `BlendOperation.Add`: The source plus the destination.
- `BlendOperation.Subtract`: The source minus the destination.
- `BlendOperation.ReverseSubtract`: The destination minus the source.
- `BlendOperation.Min`: The smaller of the source and the destination, channel by channel.
- `BlendOperation.Max`: The larger of the source and the destination, channel by channel.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Add, Subtract): what Std.string, interpolation and trace show.

## ClipFlip

*abstract* in [`libs/platform/src/helix/platform/ClipFlip.hx`](../src/helix/platform/ClipFlip.hx), `import helix.platform.ClipFlip;`

Specifies what a pipeline's flip uniform holds, so that an adapter can draw a render target the right way up.

The uniform is the one at `PipelineDesc.flipBlockSlot` and `flipOffset`, in the vertex stage's block of that slot. An adapter whose render targets are stored bottom row first, as GL's are, flips its draws into a target. With ClipScale every adapter writes the vec4 there, all four components: (1, -1, 1, 1) in a pass into a target on an adapter storing targets bottom row first, and (1, 1, 1, 1) otherwise, so a shader multiplying `gl_Position` by it is right everywhere. With ViewProjection an adapter storing targets bottom row first negates the y row of the column-major matrix there in a pass into a target. An adapter flips its own copy of the bytes, never the caller's, and reverses the winding with it. A shadow pass is never flipped.

- `ClipFlip.None`: Nothing is touched.
- `ClipFlip.ClipScale`: The uniform is a vec4 clip scale that the adapter writes.
- `ClipFlip.ViewProjection`: The uniform is a view-projection matrix whose y row the adapter negates.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (None, ClipScale): what Std.string, interpolation and trace show.

## ColorChannels

*abstract* in [`libs/platform/src/helix/platform/ColorChannels.hx`](../src/helix/platform/ColorChannels.hx), `import helix.platform.ColorChannels;`

Specifies a set of a color's channels, combined with `|`, such as the ones a pipeline's draws write (`PipelineDesc.colorWrite`).

```haxe
var noAlpha:ColorChannels = Red | Green | Blue;
```

- `ColorChannels.None`: No channel.
- `ColorChannels.Red`: Red.
- `ColorChannels.Green`: Green.
- `ColorChannels.Blue`: Blue.
- `ColorChannels.Alpha`: Alpha.
- `ColorChannels.All`: Red, green, blue and alpha.

```haxe
function or(other:ColorChannels):ColorChannels
function hasChannels(channels:ColorChannels):Bool
function toString():String
```

- `or`: Returns the channels in either set.
  - `other`: The other set.
  - returns: The channels of both sets together.
- `hasChannels`: Returns whether the set has every channel of another.
  - `channels`: The channels looked for.
  - returns: True when each of them is in the set.
- `toString`: Returns the value's name as written (None, Red): what Std.string, interpolation and trace show.

## CullFace

*abstract* in [`libs/platform/src/helix/platform/CullFace.hx`](../src/helix/platform/CullFace.hx), `import helix.platform.CullFace;`

Specifies which faces of a pipeline's triangles are not drawn.

- `CullFace.None`: No faces are culled, so both sides are drawn.
- `CullFace.Back`: Back faces, the ones facing away, are culled. This skips the far side of a closed surface.
- `CullFace.Front`: Front faces are culled, so only a surface's far side is drawn, as for an outline's shell.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (None, Back): what Std.string, interpolation and trace show.

## CursorShape

*abstract* in [`libs/platform/src/helix/platform/CursorShape.hx`](../src/helix/platform/CursorShape.hx), `import helix.platform.CursorShape;`

Specifies the cursor's shape over the canvas or window (`IMouse.cursorShape`): the system's own cursor of each kind.

Values: `Arrow`, `Text`, `Crosshair`, `Pointer`, `ResizeHorizontal`, `ResizeVertical`, `ResizeDiagonalDown`, `ResizeDiagonalUp`, `Move`, `NotAllowed`, `Wait`, `Progress`.

```haxe
static final all(default, null):Array<CursorShape>
function toString():String
```

- `all`: Every shape.
- `toString`: Returns the value's name as written (Arrow, Text): what Std.string, interpolation and trace show.

## DepthTest

*abstract* in [`libs/platform/src/helix/platform/DepthTest.hx`](../src/helix/platform/DepthTest.hx), `import helix.platform.DepthTest;`

Specifies which fragments a pipeline's depth test passes, compared with the depth already in the target.

- `DepthTest.Off`: The depth buffer is off for the draws: no test, so every fragment is drawn, and no depth written whatever `PipelineDesc.depthWrite` says.
- `DepthTest.LessEqual`: Fragments as near as or nearer than the depth there pass. This is the usual test.
- `DepthTest.Greater`: Fragments farther than the depth there pass, so only what is hidden behind something drawn before is drawn.
- `DepthTest.Always`: Every fragment passes, and its depth is written as `PipelineDesc.depthWrite` says: the depth buffer is on, unlike `Off`, so a draw can lay down depth without testing it.
- `DepthTest.Less`: Fragments nearer than the depth there pass; one exactly as near doesn't, so a second draw of the same surface leaves the first.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Off, LessEqual): what Std.string, interpolation and trace show.

## Device

*class* in [`libs/platform/src/helix/platform/Device.hx`](../src/helix/platform/Device.hx), `import helix.platform.Device;`

Represents what the program runs on, as far as the platform reports it.

It tells a browser from native, and names the operating system and the processor's architecture. It also reports whether there is a fine pointer. `ITouch.available` reports touch.

A game uses it to choose what it shows on each device, such as "tap" or "click" in a prompt, or a landscape lock.

```haxe
final browser:Bool
final os:String
final architecture:String
final finePointer:Bool
```

- `browser`: Gets a value indicating whether the program runs in a browser page rather than natively.
- `os`: Gets the operating system, in lowercase: "windows", "macos", "linux", "android", "ios" or "chromeos".
  It is "" when the platform doesn't report one.
- `architecture`: Gets the processor architecture the program runs as, in lowercase: "x86_64", "arm64" or "x86".
  Natively it is the architecture the program was built for. In a page it is the one the browser names, or "" when the browser names none. A browser may name none, or the wrong one. Safari on Apple silicon reports Intel.
- `finePointer`: Gets a value indicating whether there is a fine pointer, such as a mouse, a trackpad or a pen.
  It is false on a phone or a tablet alone.

## Event

*enum* in [`libs/platform/src/helix/platform/Event.hx`](../src/helix/platform/Event.hx), `import helix.platform.Event;`

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
- `GamepadConnected(slot:Int)`: A gamepad was connected in a slot, 0 to 3.
- `GamepadDisconnected(slot:Int)`: The gamepad in a slot was disconnected. Its buttons count as up.
- `GamepadButtonDown(slot:Int, button:GamepadButton)`: A gamepad's button went down. A trigger is also a button, down when pulled past half way.
- `GamepadButtonUp(slot:Int, button:GamepadButton)`: A gamepad's button went up. Natively, the Guide button's release arrives no sooner than a quarter second after its press.
- `Resized(width:Int, height:Int)`: The drawable area changed size, in framebuffer pixels.
- `FocusGained`: The window got the keyboard.
- `FocusLost`: The window lost the keyboard. Just before it, each key still down arrives as a `KeyUp`.
- `Shown`: The player can see the window again, because it was restored or its page came to the front.
- `Hidden`: The player can't see the window, because it is minimized or hidden, or its page is in the background.
- `CloseRequested`: The player or the OS asked to close the window. The program decides whether to close it.
  It arrives only natively. A page never receives it, because a closing tab gives no frame to decide in. A page's end is `IWindow.onClose`.
- `FilesDropped(count:Int)`: Files were dropped on the window, count of them. `IWindow.readDroppedFile` reads each, 0 to count - 1, until the next `FilesDropped`.
  Every file dropped since the last poll is in the one event: natively from the desktop's drag and drop, in a page dropped on the canvas. A dropped directory is no file and isn't counted.
- `GraphicsLost`: The GPU's context is gone. In a page, the WebGL context was lost to a GPU reset or an evicted tab. Until `GraphicsRestored`, the graphics take every call and draw nothing.
- `GraphicsRestored`: The GPU's context is back after `GraphicsLost`, and the graphics have remade what they could under their handles (`IGraphics`): textures and static buffers are gone, for their owner to make again.

## FilePath

*class* in [`libs/platform/src/helix/platform/FilePath.hx`](../src/helix/platform/FilePath.hx), `import helix.platform.FilePath;`

Provides the rule for the paths `IFileSystem` takes, which every file system adapter checks, and which helix-services' `Assets` holds every source to, so a name is refused the same way on every target.

```haxe
static function isValid(path:String):Bool
static inline var INVALID:String
static function isDirectoryName(name:String):Bool
```

- `isValid`: Returns whether a path is one `IFileSystem` takes: plain names of letters, digits, `_`, `-` and `.` joined by `/`, at most 256 characters, none empty, `.` or `..`.
  - `path`: The path.
  - returns: True when it is.
- `INVALID`: The failure for a path `isValid` refuses.
- `isDirectoryName`: Returns whether a name can be one directory's on every OS, as a program's company and product are: 1 to 64 characters, not `.` or `..`, no `/ \\ : * ? " < > |` or control characters, and no space or `.` at its end, which Windows drops.
  - `name`: The name.
  - returns: True when it can.

## Filter

*abstract* in [`libs/platform/src/helix/platform/Filter.hx`](../src/helix/platform/Filter.hx), `import helix.platform.Filter;`

Specifies how a texture is filtered when drawn at a size other than its own.

- `Filter.Nearest`: The nearest texel is used. It looks sharp and suits pixel art.
- `Filter.Linear`: Neighboring texels are blended, which looks smooth.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Nearest, Linear): what Std.string, interpolation and trace show.

## GamepadAxis

*abstract* in [`libs/platform/src/helix/platform/GamepadAxis.hx`](../src/helix/platform/GamepadAxis.hx), `import helix.platform.GamepadAxis;`

Specifies a gamepad's axis.

Sticks run from -1 to 1, down and right positive; triggers from 0 to 1.

Values: `LeftX`, `LeftY`, `RightX`, `RightY`, `LeftTrigger`, `RightTrigger`.

```haxe
static inline var COUNT:Int
static final all(default, null):Array<GamepadAxis>
function toString():String
```

- `COUNT`: One past the largest value, for arrays indexed by axis.
- `all`: Every axis.
- `toString`: Returns the value's name as written (LeftX, LeftY): what Std.string, interpolation and trace show.

## GamepadButton

*abstract* in [`libs/platform/src/helix/platform/GamepadButton.hx`](../src/helix/platform/GamepadButton.hx), `import helix.platform.GamepadButton;`

Specifies a gamepad's button by its place on an Xbox-style gamepad, numbered as the W3C standard gamepad numbers them.

The triggers are both buttons and axes. As buttons, they are pressed when pulled past half way, or by a digital trigger.

Values: `South`, `East`, `West`, `North`, `LeftBumper`, `RightBumper`, `LeftTrigger`, `RightTrigger`, `Back`, `Start`, `LeftStick`, `RightStick`, `Up`, `Down`, `Left`, `Right`, `Guide`.

```haxe
static inline var COUNT:Int
static final all(default, null):Array<GamepadButton>
function toString():String
```

- `COUNT`: One past the largest value, for arrays indexed by button.
- `all`: Every button.
- `toString`: Returns the value's name as written (South, East): what Std.string, interpolation and trace show.

## GraphicsDevice

*typedef* in [`libs/platform/src/helix/platform/GraphicsDevice.hx`](../src/helix/platform/GraphicsDevice.hx), `import helix.platform.GraphicsDevice;`

Represents the GPU and driver a graphics adapter draws with, as the graphics API reports them. A value the API doesn't report is "".

- `version:String`: The API's or the driver's version.
- `vendor:String`: The GPU's maker, or the driver's.
- `shadingLanguage:String`: The shading language the adapter compiles programs for, and its version.
- `renderer:String`: The GPU, or the software renderer drawing in its place.
- `api:String`: The graphics API: "WebGL 2", "OpenGL", "Vulkan", "Metal" or "Direct3D 12".

## GraphicsUnavailableException

*class* in [`libs/platform/src/helix/platform/GraphicsUnavailableException.hx`](../src/helix/platform/GraphicsUnavailableException.hx), `import helix.platform.GraphicsUnavailableException;`, extends `Exception`

Represents the error a graphics adapter throws when the GPU API it draws through is missing, such as WebGL2 in a browser without it.

A caller can tell this error apart from a failure in the program's own code, and report the platform as unsupported.

```haxe
function new(message:String, ?previous:haxe.Exception, ?native:Any)
```


## GrowingSource

*class* in [`libs/platform/src/helix/platform/GrowingSource.hx`](../src/helix/platform/GrowingSource.hx), `import helix.platform.GrowingSource;`

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

*interface* in [`libs/platform/src/helix/platform/IAudio.hx`](../src/helix/platform/IAudio.hx), `import helix.platform.IAudio;`, extends `IPollable`

Defines the sound output, which plays clips held whole, streams played as they are read, and queues of samples fed as they play.

Each playing of a clip, a stream or a queue is a voice. Clip, stream, queue and voice ids are the adapter's. Samples are 32-bit float PCM, -1 to 1, mono or stereo; stereo samples are interleaved, left first. A clip's rate is 44100 Hz. A stream plays its file's channels.

A browser starts its audio on the page's first key or pointer press, and suspends it while the page is hidden or blurred. Natively, audio runs once the device opens.

```haxe
var available(get, never):Bool
var running(get, never):Bool
var playsUrls(get, never):Bool
function createClip(samples:haxe.io.Bytes, channelCount:Int):Int
function disposeClip(clip:Int):Void
function openStream(source:StreamSource, opened:Int -> Void, failed:String -> Void):() -> Void
function disposeStream(stream:Int):Void
function getStreamDuration(stream:Int):Float
function getStreamChannelCount(stream:Int):Int
function createQueue(channelCount:Int, sampleRate:Int):Int
function queueSamples(queue:Int, samples:haxe.io.Bytes):Void
function getQueuedFrameCount(queue:Int):Int
function disposeQueue(queue:Int):Void
function playClip(clip:Int, loop:Bool, volume:Float):Int
function playStream(stream:Int, loop:Bool, volume:Float):Int
function playQueue(queue:Int, volume:Float):Int
function stop(voice:Int):Void
function pause(voice:Int, paused:Bool):Void
function setVolume(voice:Int, volume:Float):Bool
function setPitch(voice:Int, pitch:Float):Bool
function setPan(voice:Int, pan:Float):Bool
function getPosition(voice:Int):Float
function setPosition(voice:Int, seconds:Float):Bool
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
  - `samples`: 32-bit float PCM at 44100 Hz, -1 to 1, interleaved when stereo.
  - `channelCount`: The channels, 1 (mono) or 2 (stereo).
  - returns: The clip's id.
  - throws `String`: When channels isn't 1 or 2, the samples hold no whole frame, or there is no room for the clip.

  A partial frame at the end is ignored.
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
- `getStreamDuration`: Returns a stream's length.
  - `stream`: The stream.
  - returns: The length in seconds, or 0 while it is unknown.
  - throws `String`: For an unknown stream.

  The length may be unknown at first and known later. Natively, a `Downloading` source's length is unknown until all of it has arrived. In a page, it is unknown for a live stream.
- `getStreamChannelCount`: Returns how many channels a stream plays.
  - `stream`: The stream.
  - returns: 1 (mono) or 2 (stereo); a file of more plays as stereo. 0 when it can't tell: in a page, where a stream's channels are read from its file's first bytes (helix-formats' `AudioHeader`), a kind it doesn't read or a fetch that failed.
  - throws `String`: For an unknown stream.
- `createQueue`: Creates a queue, which plays samples given to it as it goes.
  - `channelCount`: The channels, 1 (mono) or 2 (stereo).
  - `sampleRate`: The samples' rate in frames a second, 8000 to 96000.
  - returns: The queue's id.
  - throws `String`: When channels or sampleRate is out of range.

  Samples are added with `queueSamples` and played by `playQueue`, back to back without a gap while they are added ahead of what is heard. The platform resamples them to the output's rate.
- `queueSamples`: Adds samples to the end of a queue.
  - `queue`: The queue.
  - `samples`: 32-bit float PCM at the queue's rate, -1 to 1, interleaved when stereo.
  - throws `String`: For an unknown queue.

  They are copied. Samples added while the queue has no voice wait for `playQueue`. A partial frame at the end is ignored.
- `getQueuedFrameCount`: Returns how many frames a queue holds that haven't been heard yet.
  - `queue`: The queue.
  - returns: The frames queued and not yet played.
  - throws `String`: For an unknown queue.
- `disposeQueue`: Disposes a queue and stops its voice.
  - `queue`: The queue.
  - throws `String`: For an unknown queue.
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
- `playQueue`: Starts a queue playing what it holds and what is added to it.
  - `queue`: The queue.
  - `volume`: The volume, 0 to 1.
  - returns: The voice's id, or 0 when there is no output (`available`).
  - throws `String`: For an unknown queue.

  A queue has one voice at a time: playing it again stops its earlier voice and keeps its samples. A queue that runs out of samples keeps playing, silent, and goes on as soon as more are added; its voice ends only when stopped. A voice requested before audio runs waits and starts once audio runs, as `playClip`'s does.
- `stop`: Stops a voice.
  - `voice`: The voice.

  Stopping a queue's voice drops the samples it hadn't played yet. It does nothing for an unknown or ended voice.
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

  On a queue's voice in a page, the block playing (what one `queueSamples` call added) finishes at the rate it had, and the blocks after it play at the new rate. Natively the change is immediate.
- `setPan`: Sets a voice's pan.
  - `voice`: The voice.
  - `pan`: The pan, -1 (left) to 1 (right), where 0 is the middle.
  - returns: False, changing nothing, when the voice isn't playing (unknown, stopped or ended).

  A mono voice is panned by equal power: at 0 each side hears it at about 0.71. A stereo voice is balanced: at 0 each side hears its own channel unchanged, and toward one side the far channel fades by equal power and is mixed into the near one, as Web Audio's `StereoPannerNode` does. The change is ramped as a volume change is.
- `getPosition`: Returns how far a voice has played.
  - `voice`: The voice.
  - returns: The position in seconds from the start of its clip, stream or queue; 0 for an unknown or ended voice.

  A looping voice goes back to 0 at each loop. A queue's voice counts the frames it has played since `playQueue`. Natively a stream's voice counts what the output has taken from it, a few milliseconds ahead of what is heard.
- `setPosition`: Moves a playing or paused voice to a position.
  - `voice`: The voice.
  - `seconds`: The position in seconds from the start, 0 or more.
  - returns: False, changing nothing, when the voice isn't playing (unknown, stopped or ended), is a queue's, or can't be moved there.

  A position past the end is clamped to the end, where a voice that doesn't loop ends. A queue's voice can't be moved. In a page, a stream moves only within what its media element can seek (`HTMLMediaElement.seekable`), which a server that doesn't take range requests prevents.
- `isPlaying`: Returns whether a voice is still playing or paused.
  - `voice`: The voice.
  - returns: False once the voice has ended or been stopped, and for an unknown voice.
- `poll`: Feeds streamed voices, opens downloads that have arrived far enough, and delivers what the platform's threads finished.
  The program calls it once a frame.
- `dispose`: Stops every voice, disposes every stream, queue and clip, and closes the output.

## IAudioDecoder

*interface* in [`libs/platform/src/helix/platform/IAudioDecoder.hx`](../src/helix/platform/IAudioDecoder.hx), `import helix.platform.IAudioDecoder;`, extends `IPollable`

Defines audio decoding from a whole file into 32-bit float PCM at the rate asked.

It reads WAV (PCM or float, at any rate), Ogg Vorbis, MP3 and FLAC files, resampled to the rate asked unless it is the file's own. A clip plays at 44100 Hz (`IAudio.createClip`), so a program decoding for one asks for 44100; one keeping a file's samples as they are asks for the rate its header records (helix-formats' `AudioHeader.readSampleRate`). A mono file decodes to mono and a stereo file to stereo, interleaved, left first. A file of more channels is mixed down to stereo by the platform's speaker mix: SDL's channel conversion natively, Web Audio's down-mix in a page, which may differ slightly. Samples are -1 to 1.

```haxe
function decode(encoded:haxe.io.Bytes, sampleRate:Int, decoded:(samples:haxe.io.Bytes, channelCount:Int) -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `decode`: Decodes a file, off the main thread where the platform can.
  - `encoded`: The file's bytes.
  - `sampleRate`: The frames a second to decode at.
  - `decoded`: Receives the samples, at `sampleRate`, and their number of channels, 1 or 2.
  - `failed`: Receives why the file can't be read.

  One of `decoded` or `failed` is called once, on the main thread, never during this call.
- `poll`: Delivers what finished on the platform's threads since the last poll. The program calls it once a frame.
- `dispose`: Closes the decoder. A decode still running finishes without calling back.

## IAudioEffects

*interface* in [`libs/platform/src/helix/platform/IAudioEffects.hx`](../src/helix/platform/IAudioEffects.hx), `import helix.platform.IAudioEffects;`, extends `IPollable`

Defines effects on what voices play, and reading what they play, over an `IAudio` output.

Voices play into chains, and each chain plays into another chain or into the mix, which is a chain too (`mix`), so chains form a tree as an engine's buses do. Each chain runs its effects and analysers in the order they were added (`AudioEffect`), then plays into the chain above it. A voice plays into the mix until it is sent to another chain (`send`). A program that never constructs an `IAudioEffects` carries none of its code: every voice plays straight to the output.

Chain and effect ids are the adapter's. The effects run where the platform mixes, on its audio thread natively and in the page's audio graph in a browser, so nothing here runs a program's code on the audio thread.

```haxe
var mix(get, never):Int
function createChain(?output:Int):Int
function disposeChain(chain:Int):Void
function send(voice:Int, chain:Int):Bool
function addEffect(chain:Int, effect:AudioEffect):Int
function addAnalyser(chain:Int, frameCount:Int):Int
function setEffect(effect:Int, settings:AudioEffect):Bool
function setBypassed(effect:Int, bypassed:Bool):Bool
function removeEffect(effect:Int):Void
function getSamples(effect:Int, into:haxe.io.Bytes):Int
function getFramesPassed(effect:Int):Float
function getSpectrum(effect:Int, into:haxe.io.Bytes):Int
function poll():Void
function dispose():Void
```

- `mix`: Gets the chain everything plays through last, on its way to the output. It can't be disposed.
- `createChain`: Creates a chain.
  - `output`: Optional. The chain it plays into. Defaults to `mix`.
  - returns: The chain's id.
  - throws `String`: For an unknown output chain.
- `disposeChain`: Disposes a chain and its effects. Its voices, and the chains that played into it, play into its output chain from then on.
  - `chain`: The chain.

  It does nothing for the mix or an unknown chain.
- `send`: Sends a voice into a chain, from what it plays next.
  - `voice`: The voice, as `IAudio` gave it.
  - `chain`: The chain, or `mix` to play straight into the mix.
  - returns: False, changing nothing, when the voice isn't playing (unknown, stopped or ended) or the chain is unknown.
- `addEffect`: Adds an effect at the end of a chain.
  - `chain`: The chain.
  - `effect`: The effect and its settings.
  - returns: The effect's id.
  - throws `String`: For an unknown chain, or a setting outside its range.
- `addAnalyser`: Adds an analyser at the end of a chain. It changes nothing, and keeps the latest frames that pass it, for `getSamples` and `getSpectrum`. It is removed and bypassed as an effect is.
  - `chain`: The chain.
  - `frameCount`: How many frames it keeps, a power of two from 32 to 32768.
  - returns: The analyser's id, which is an effect's id.
  - throws `String`: For an unknown chain, or a frame count that isn't a power of two from 32 to 32768.
- `setEffect`: Changes an effect's settings.
  - `effect`: The effect.
  - `settings`: Its new settings, of the same kind as when it was added.
  - returns: False, changing nothing, for an unknown effect, an analyser, one of another kind, or a setting outside its range.

  The change is ramped over the output's next block, as `IAudio.setVolume` is, so a filter swept once a frame doesn't click.
- `setBypassed`: Turns an effect off or on again, keeping its place and settings. Off, it passes what plays unchanged.
  - `effect`: The effect.
  - `bypassed`: True to turn it off, false to turn it on.
  - returns: False for an unknown effect.
- `removeEffect`: Removes an effect from its chain.
  - `effect`: The effect.

  It does nothing for an unknown effect.
- `getSamples`: Copies the latest frames an analyser kept, as they were heard.
  - `effect`: The analyser.
  - `into`: Receives the frames as 32-bit floats, stereo interleaved, left first, the oldest first. Its length sets how many, up to the analyser's frame count.
  - returns: The frames copied: 0 for an unknown analyser, and fewer than asked until enough have played.

  Natively the frames are copied out on the audio thread and read here, up to one output block late.
- `getFramesPassed`: Returns how many frames have passed an analyser since it was added, so a reader can tell which of the latest frames are new.
  - `effect`: The analyser.
  - returns: The frames, counted as `getSamples` sees them; 0 for an unknown analyser.
- `getSpectrum`: Measures the latest frames an analyser kept by frequency, as Web Audio's `AnalyserNode.getFloatFrequencyData` does.
  - `effect`: The analyser.
  - `into`: Receives the bands as 32-bit floats in decibels, from 0 Hz up to half the output's rate. Its length sets how many, up to half the analyser's frame count.
  - returns: The bands written: 0 for an unknown analyser.

  The channels are mixed to one, windowed (Blackman) and transformed. Each band is smoothed against the last measure, 0.8 of the old to 0.2 of the new.
- `poll`: Delivers what the audio thread kept since the last poll. The program calls it once a frame.
- `dispose`: Removes every effect and chain, and sends every voice straight to the output again.

## IClipboard

*interface* in [`libs/platform/src/helix/platform/IClipboard.hx`](../src/helix/platform/IClipboard.hx), `import helix.platform.IClipboard;`

Defines the system's clipboard: text, and an image as PNG.

Each call answers once, never during the call, as a page's clipboard does: natively at the next `IEvents.poll`. A page reads only with the player's permission, which the browser may ask for, and writes only while it has the keyboard, soon after a key press, click or tap.

```haxe
function requestText(read:String -> Void, ?failed:String -> Void):Bool
function setText(text:String, ?done:() -> Void, ?failed:String -> Void):Void
function requestImage(read:haxe.io.Bytes -> Void, ?failed:String -> Void):Bool
function setImage(png:haxe.io.Bytes, ?done:() -> Void, ?failed:String -> Void):Void
function dispose():Void
```

- `requestText`: Asks for the clipboard's text.
  - `read`: Receives the text; "" when the clipboard holds none.
  - `failed`: Optional. Receives why it couldn't be read, such as a page's permission refused.
  - returns: True, because it always asks.

  One of `read` or `failed` is called once, never during this call.
- `setText`: Puts text on the clipboard.
  - `text`: The text.
  - `done`: Optional. Called once the text is on the clipboard.
  - `failed`: Optional. Receives why it couldn't be, such as a page without the keyboard.

  One of `done` or `failed` is called once, never during this call.
- `requestImage`: Asks for the clipboard's image, as PNG.
  - `read`: Receives the PNG's bytes. A page's browser may give the same picture encoded anew.
  - `failed`: Optional. Receives why there is none: no image on the clipboard, or a page's permission refused.
  - returns: True, because it always asks.

  One of `read` or `failed` is called once, never during this call.
- `setImage`: Puts an image on the clipboard.
  - `png`: The image, as a PNG file's bytes.
  - `done`: Optional. Called once the image is on the clipboard.
  - `failed`: Optional. Receives why it couldn't be.

  One of `done` or `failed` is called once, never during this call.
- `dispose`: Releases the adapter; the clipboard keeps what was put on it, where the system does.

## IDecodedImage

*interface* in [`libs/platform/src/helix/platform/IDecodedImage.hx`](../src/helix/platform/IDecodedImage.hx), `import helix.platform.IDecodedImage;`

Represents an image decoded for the GPU: what `IImageDecoder.decodeForGpu` gives and `IGraphics.createTextureFromImage` uploads, so a program draws a file without ever holding its pixels.

In a page it is the browser's decoded image (`bitmapHandle` names it), uploaded as it is. Natively it is the pixels. Either can give its pixels (`pixels`) when a program wants them after all, at the cost a page's readback has.

```haxe
var width(get, never):Int
var height(get, never):Int
var bitmapHandle(get, never):Int
function pixels():haxe.io.Bytes
function dispose():Void
```

- `width`: Gets its width, in pixels.
- `height`: Gets its height, in pixels.
- `bitmapHandle`: Gets the handle of the browser's decoded image in a page (an `ImageBitmap`, which `IGraphics.createTextureFromImage` uploads as it is), or 0 natively, where `pixels` holds the image, and once disposed.
- `pixels`: Returns its pixels, 8-bit RGBA with rows top to bottom, not premultiplied, `width * height * 4` bytes, made once and kept.
  - returns: The pixels.

  In a page they are read back from the bitmap through a canvas, which stores pixels premultiplied, so a partly transparent pixel may come back a level or two from the file's value.
- `dispose`: Frees it: the bitmap closed, the pixels let go. It isn't uploaded or read after this.

## IEvents

*interface* in [`libs/platform/src/helix/platform/IEvents.hx`](../src/helix/platform/IEvents.hx), `import helix.platform.IEvents;`, extends `IPollable`

Defines the events, polled once a frame: what happens to the window, the player's first press, and what the devices built over it add.

Each `poll` delivers what happened as `Event` records, in the order the OS reported them. Without a device, that is the window being resized, focused, shown, hidden or closed, its graphics lost, and `Unlocked`. A device's adapter, constructed over the events adapter, adds its own events to the same records: `IKeyboard` keys and text, `IMouse` the mouse, `ITouch` fingers, `IGamepads` gamepads and `ITilt` the tilt. A device that isn't constructed isn't listened to. Nothing is delivered between polls, and nothing calls the program. The program walks `events` itself.

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

*interface* in [`libs/platform/src/helix/platform/IExport.hx`](../src/helix/platform/IExport.hx), `import helix.platform.IExport;`

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

*interface* in [`libs/platform/src/helix/platform/IFileSystem.hx`](../src/helix/platform/IFileSystem.hx), `import helix.platform.IFileSystem;`, extends `IPollable`

Defines files on this machine under one root, read and written whole by path.

Natively the root is a directory on disk. In a page it is an IndexedDB database. A file on a server is read through `IHttp` instead.

A file is reached by its path. It is read whole or located for streaming, and written whole or not at all, with no seeking. Its size and when it was last written are found with `getInfo`, and what a directory holds with `list`. A directory is made by writing a file under it, as a page has none of its own; there is no call that makes or deletes one. These are a page's limits, kept natively so a program works the same on both.

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
function getInfo(path:String, found:(size:Int, modified:Float) -> Void, missing:() -> Void, failed:String -> Void):Void
function list(directory:String, listed:Array<String> -> Void, missing:() -> Void, failed:String -> Void):Void
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
- `getInfo`: Finds a file's size and when it was last written.
  - `path`: The file's path under the root.
  - `found`: Receives the file's size, in bytes, and when it was last written, in seconds since the Unix epoch.
  - `missing`: Called when there is no file at the path.
  - `failed`: Receives why it can't be found.

  A directory isn't a file, so its path is missing here. In a page, a file written before the adapter kept write times was last written at 0.
- `list`: Lists what a directory holds: its files' names, and its subdirectories' names ending in `/`.
  - `directory`: The directory's path under the root, or "" for the root.
  - `listed`: Receives the names, such as `["1.json", "bonus/"]`; none for an empty directory or a root not yet written.
  - `missing`: Called when there is no directory at the path, including when a file is there.
  - `failed`: Receives why it can't be listed.

  Only the directory's own entries are listed, sorted, not what its subdirectories hold. Natively a name the paths can't hold (one with a space, say) is listed too, though no call reaches it. In a page a directory is there while a file is under it.
- `locate`: Finds where a file is, so it can be played as it is read without loading it whole.
  - `path`: The file's path under the root.
  - `located`: Receives the location and a function that releases it. That function is called once, when the location is no longer read.
  - `missing`: Called when there is no file at the path.
  - `failed`: Receives why it can't be located.

  Natively the location is the file's path. In a page it is a URL the audio output plays, kept until `release` is called.
- `poll`: Delivers what finished on the platform's threads since the last poll. The program calls it once a frame.
- `dispose`: Closes the file system. What is still running finishes without calling back.

## IFontRasterizer

*interface* in [`libs/platform/src/helix/platform/IFontRasterizer.hx`](../src/helix/platform/IFontRasterizer.hx), `import helix.platform.IFontRasterizer;`, extends `IPollable`

Defines rasterizing a TrueType or OpenType font's glyphs at a size, as 8-bit coverage or signed distances.

Sizes and metrics are stb_truetype's: the size is the font's pixel height (its ascent minus its descent), and every length is in pixels at that size.

```haxe
function rasterize(encoded:haxe.io.Bytes, size:Float, codepoints:Array<Int>, rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String -> Void):Void
function rasterizeDistanceField(encoded:haxe.io.Bytes, size:Float, codepoints:Array<Int>, rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `rasterize`: Rasterizes glyphs as 8-bit coverage, off the main thread where the platform can.
  - `encoded`: The font file's bytes, TTF or OTF; the first font of a collection is not read.
  - `size`: The pixel height.
  - `codepoints`: The glyphs wanted.
  - `rasterized`: Receives a glyph for each codepoint, in their order, and the font's ascent, descent (below the baseline, negative) and line gap.
  - `failed`: Receives why the font can't be read.

  One of `rasterized` or `failed` is called once, on the main thread, never during this call.
- `rasterizeDistanceField`: Rasterizes glyphs as signed distances to their outlines, off the main thread where the platform can.
  - `encoded`: The font file's bytes, TTF or OTF; the first font of a collection is not read.
  - `size`: The pixel height.
  - `codepoints`: The glyphs wanted.
  - `rasterized`: Receives a glyph for each codepoint, in their order, and the font's ascent, descent (below the baseline, negative) and line gap.
  - `failed`: Receives why the font can't be read.

  A glyph has 4 pixels of padding around its outline; a pixel on the outline is 128, and each pixel inside is 64 more, each outside 64 less, clamped to 0 and 255. One of `rasterized` or `failed` is called once, on the main thread, never during this call.
- `poll`: Delivers what finished on the platform's threads since the last poll. The program calls it once a frame.
- `dispose`: Closes the rasterizer. A rasterize still running finishes without calling back.

## IGamepads

*interface* in [`libs/platform/src/helix/platform/IGamepads.hx`](../src/helix/platform/IGamepads.hx), `import helix.platform.IGamepads;`

Defines the gamepads, in slots 0 to 3: `GamepadConnected`, `GamepadDisconnected`, `GamepadButtonDown` and `GamepadButtonUp` in `IEvents.events` while it exists, and each gamepad's state as of the last `IEvents.poll`.

Its adapter is constructed over the events adapter, whose `poll` delivers its events and reads the gamepads. Natively, a button pressed and released between two polls arrives as both events. A page reads its gamepads only at each poll, so it sees a press only if the button is down then.

```haxe
var stick = gamepads.getAxis(0, LeftX);
```

```haxe
function isConnected(slot:Int):Bool
function getName(slot:Int):String
function isButtonDown(slot:Int, button:GamepadButton):Bool
function getAxis(slot:Int, axis:GamepadAxis):Float
function setVibration(slot:Int, low:Float, high:Float, seconds:Float):Bool
function addMappings(mappings:String):Int
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
- `setVibration`: Shakes a gamepad: its low-frequency (heavy) and high-frequency (light) motors for a while, replacing any shaking it was doing.
  - `slot`: The slot, 0 to 3.
  - `low`: The heavy motor's strength, 0 to 1.
  - `high`: The light motor's strength, 0 to 1.
  - `seconds`: How long; 0 stops it.
  - returns: Whether the gamepad shakes: false for an empty slot or a gamepad without motors, and in a browser without vibration (Firefox).
- `addMappings`: Adds mappings that say how gamepads the system doesn't know lay out their buttons and axes, in SDL's controller database format (one per line, as `gamecontrollerdb.txt` has them).
  - `mappings`: The mappings.
  - returns: How many were added or updated; 0 in a page, whose browser maps gamepads itself.
- `dispose`: Stops reading the gamepads and lets them go.

## IGraphics

*interface* in [`libs/platform/src/helix/platform/IGraphics.hx`](../src/helix/platform/IGraphics.hx), `import helix.platform.IGraphics;`

Defines the GPU as a platform's graphics adapter provides it, with its resources, its passes and one draw call.

Resources are textures of a few kinds, buffers, programs built from a `ShaderSource`, and pipelines made from a `PipelineDesc`. A frame is any number of passes into render targets and shadow maps, then the screen's pass from `beginFrame` to `endFrame`.

An adapter knows nothing of its caller's programs, layouts or pipelines. The caller describes them as data. Whoever creates a handle disposes it, once. A handle carries its kind (a buffer, a texture of any kind, a program or a pipeline), and a call refuses a handle of another kind as unknown.

A call that cannot be done throws before doing anything.

**A lost context** (a page's `GraphicsLost`). While the context is lost, every call is taken and does nothing: a creation returns a handle, a draw draws nothing, `readPixels` fails. At `GraphicsRestored` the adapter has remade, under the old handles, its programs, pipelines, render targets and shadow maps (their texels cleared), data textures and stream buffers (rewritten each frame anyway). Textures (`createTexture`, `createTextureFromImage`, `createCubeTexture`) and static buffers are gone, those made during the loss too, and their handles disposed: their owner makes them again from what it keeps. Natively, a lost context (rare) is currently unrecoverable.

```haxe
function createTexture(width:Int, height:Int, levels:Array<haxe.io.Bytes>, ?format:TextureFormat = Rgba8):Int
function createTextureFromImage(image:IDecodedImage):Int
function createCubeTexture(size:Int, levels:Array<haxe.io.Bytes>, format:TextureFormat):Int
function createDataTexture(width:Int, height:Int):Int
function updateTexture(handle:Int, x:Int, y:Int, width:Int, height:Int, data:haxe.io.Bytes):Void
function canSample(format:TextureFormat):Bool
var msaaSampleCount(get, never):Int
var maxMsaaSampleCount(get, never):Int
var device(get, never):GraphicsDevice
function getMaxRenderTargetMsaaSampleCount(format:TextureFormat):Int
function createRenderTarget(width:Int, height:Int, ?format:TextureFormat = Rgba8, ?depth:Bool = true, ?msaaSampleCount:Int = 0):Int
function canRender(format:TextureFormat):Bool
function createShadowMap(size:Int, layerCount:Int):Int
function disposeTexture(handle:Int):Void
function createBuffer(capacityBytes:Int):Int
function createStaticBuffer(data:haxe.io.Bytes, bytes:Int, index:Bool):Int
function updateBuffer(handle:Int, data:haxe.io.Bytes, usedBytes:Int):Void
function appendBuffer(handle:Int, data:haxe.io.Bytes, usedBytes:Int):Int
function disposeBuffer(handle:Int):Void
function createShader(source:ShaderSource):Int
function disposeShader(handle:Int):Void
function createPipeline(desc:PipelineDesc):Int
function disposePipeline(handle:Int):Void
function beginShadowPass(map:Int, layerIndex:Int):Void
function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void
function resumeTargetPass(target:Int):Void
function endTargetPass():Void
function beginFrame(width:Int, height:Int, clearColor:Int):Void
function applyViewport(x:Int, y:Int, w:Int, h:Int):Void
function applyScissor(x:Int, y:Int, w:Int, h:Int):Void
function resetScissor():Void
function draw(pipeline:Int, buffers:Array<Int>, bufferOffsets:Null<Array<Int>>, indexBuffer:Int, firstElementIndex:Int, elementCount:Int, firstInstanceIndex:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<haxe.io.Bytes>>):Void
function endFrame():Void
function present():Void
function readPixels(handle:Int, read:(pixels:haxe.io.Bytes, width:Int, height:Int) -> Void, failed:String -> Void):Void
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
- `createTextureFromImage`: Uploads a decoded image (`IImageDecoder.decodeForGpu`) as a texture of one level, format Rgba8.
  - `image`: The decoded image.
  - returns: The texture's handle.
  - throws `String`: A disposed image.

  In a page the browser's decoded image goes to the GPU as it is, with no premultiplying and no color conversion, so the texels are the file's as the native decoder reads them. The image is still the caller's to dispose.
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

  A data texture is read texel by texel and never filtered, so its samplings are ignored. `updateTexture` fills it, whole.
- `updateTexture`: Replaces a rectangle of a texture's texels, for the draws after it.
  - `handle`: The texture: a `createTexture` texture of format Rgba8 or Rgba16f, or a data texture.
  - `x`: The rectangle's left edge, in texels.
  - `y`: The rectangle's top edge, in texels from the top row.
  - `width`: The rectangle's width, in texels.
  - `height`: The rectangle's height, in texels.
  - `data`: The rectangle's texels with rows top first, `format.levelBytes(width, height)` bytes of the texture's format, or 16 bytes a texel of little-endian floats for a data texture.
  - throws `String`: An unknown handle, a cube, render target or shadow map, a compressed format, a call inside a pass for a `createTexture` texture, a rectangle that is empty or not inside the texture (not all of a data texture), or data that is too short.

  A `createTexture` texture is updated outside a pass, any number of times a frame: draws in the passes before it read the old texels, and those after it the new. Only its top level changes; its mipmaps are left as they were. A data texture is rewritten whole, the rectangle all of it, any number of times a frame, inside a pass or outside: each draw reads the latest.
- `canSample`: Returns whether this GPU samples textures of a format.
  - `format`: The format.
  - returns: True when textures of the format can be sampled.

  RGBA8 can always be sampled. The compressed formats can be sampled on GPUs that have them, and half floats where this GPU filters them.
- `msaaSampleCount`: Gets the number of multisampling samples per pixel that the screen is drawn with, or 1 for none.
  It can be fewer than the window asked for. A render target created with a sample count of 0 is drawn with the same number, where its format takes it.
- `maxMsaaSampleCount`: Gets the largest number of multisampling samples a window could ask for here, at most 8.
  A browser only switches antialiasing on or off, and chooses its own count. In a browser this is therefore the count the canvas has when antialiasing is on, which is 4 where the GPU supports 4, and 1 otherwise. A render target's limit is `getMaxRenderTargetMsaaSampleCount`.
- `device`: Gets the GPU and driver drawing, as the graphics API reports them, for a program to log or show.
  A browser may mask them: the adapter asks for the unmasked names (`WEBGL_debug_renderer_info`) where the browser gives them, and otherwise has the browser's own, such as "WebKit WebGL".
- `getMaxRenderTargetMsaaSampleCount`: Returns the largest number of multisampling samples a render target of a format can be drawn with here, at most 8.
  - `format`: The format.
  - returns: The largest sample count `createRenderTarget` gives a target of the format.

  It is 1, 2, 4 or 8: 1 where this GPU cannot multisample the format, or cannot draw into it at all (`canRender`).
- `createRenderTarget`: Creates a render target, which is a texture that a target pass draws into.
  - `width`: The width, in texels.
  - `height`: The height, in texels.
  - `format`: Optional. The texels' format; defaults to Rgba8.
  - `depth`: Optional. Whether it has a depth buffer; defaults to true.
  - `msaaSampleCount`: Optional. The multisampling samples per texel asked for: 1 for none, or 0, the default, for the screen's (`msaaSampleCount`).
  - returns: The render target's handle.
  - throws `String`: A size of 0 or less, a format this GPU cannot draw into (`canRender`), or a sample count below 0.

  The target is sampled like any texture and stored top row first. A target with depth has its own depth buffer. Whether it has depth and how many samples it is drawn with are chosen apart. A target of more than one sample is drawn into its samples, which are resolved into the texture at the end of each pass; a target of one sample is drawn into the texture itself. The count asked for is rounded down to the nearest that this GPU draws the format with: 1, 2, 4 or 8, at most `getMaxRenderTargetMsaaSampleCount(format)`. A count the GPU can't give is never refused. What a pass leaves in a target, its samples and depth too, lasts until a `beginTargetPass` clears it, so `resumeTargetPass` draws over it in a later pass or frame. A new target holds transparent black and the farthest depth.
- `canRender`: Returns whether this GPU draws into, blends over and filters render targets of a format.
  - `format`: The format.
  - returns: True when render targets of the format can be drawn into.

  RGBA8 always can. RGBA16F can where float targets exist, which is nearly always natively, and in a browser through EXT_color_buffer_float. A compressed format never can.
- `createShadowMap`: Creates a shadow map, which is a depth texture of layers that shadow passes draw into.
  - `size`: Each layer's width and height, in texels.
  - `layerCount`: The number of layers.
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
  - throws `String`: A call outside a pass, an unknown handle, a size out of range, or a buffer appended to this frame.

  It must be called inside a pass, and can be called any number of times a frame. A buffer drawn into a target and then into the screen is uploaded twice. A buffer a frame has appended to (`appendBuffer`) can't be updated until the next frame.
- `appendBuffer`: Adds bytes to the end of a stream buffer, so draws can read each range from its own offset.
  - `handle`: The stream buffer.
  - `data`: The bytes to add.
  - `usedBytes`: The number of bytes of data to use, which must be a multiple of 4.
  - returns: The byte offset in the buffer where the bytes landed, which is a multiple of 4. Pass it in a draw's `bufferOffsets`.
  - throws `String`: A call outside a pass, an unknown handle, a size out of range, bytes that don't fit in the buffer's capacity, or a buffer updated this frame.

  A frame starts with every stream buffer empty. Each call writes after the bytes the frame's earlier calls wrote, and the earlier bytes stay as they were, so a draw after any call can read any range written so far. It must be called inside a pass, and can be called any number of times a frame. A buffer is either appended to or updated (`updateBuffer`) in a frame, not both. An adapter may set aside the buffer's whole capacity of its upload space for the frame, at the first call.
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
  - `layerIndex`: The index of the layer to draw into.
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
- `resumeTargetPass`: Starts a pass into a render target that keeps what the target holds: its texels, and its depth if it has one.
  - `target`: The render target, as a `createRenderTarget` handle.
  - throws `String`: A call inside a pass, or a handle that is not a render target.

  It is `beginTargetPass` without the clear: the viewport is set to all of the target, and the pass comes before the screen's and outside any other. `endTargetPass` ends it.
- `endTargetPass`: Ends the pass that `beginTargetPass`, `resumeTargetPass` or `beginShadowPass` started.
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
  - `bufferOffsets`: The byte offset in each of `buffers` where its data starts, so draws can read different ranges of one buffer. Null, or a buffer past the array's end, is 0. An offset is a multiple of 4. The draw's elements and instances are counted from it, and must end inside the buffer's bytes, written this frame or static: a vertex buffer's at `firstElementIndex` plus `elementCount` records for a pipeline that isn't indexed, an instanced buffer's at `firstInstanceIndex` plus `instanceCount`. An indexed pipeline's vertex data is read from the offset by index, with no base vertex. It applies to vertex and instanced buffers alike.
  - `indexBuffer`: For an indexed pipeline, a static index buffer. Otherwise it is ignored.
  - `firstElementIndex`: The index of the first element drawn: its first vertex, or for an indexed pipeline its first index.
  - `elementCount`: The number of elements drawn: vertices, or for an indexed pipeline indices.
  - `firstInstanceIndex`: The index of the first instance drawn: the first record of the instanced buffers.
  - `instanceCount`: The number of instances.
  - `textures`: The texture bound at each of the program's texture slots, by slot. A slot provided 0, or past the array's end, reads a clear 1x1 texture of its kind, for a texture the program declares and doesn't read.
  - `samplings`: How each texture is sampled, by slot. A shadow map or data texture is sampled as its kind requires.
  - `uniforms`: The bytes of each uniform block at its declared size, by stage and slot: the vertex stage's slot n at index n, the fragment stage's at 4 + n, a block both stages read at both (`ShaderBlock`); null at an index the program has no block for.
  - throws `String`: Anything invalid, before drawing: a texture that is the pass's own target among them, or an offset out of range.

  Only whole primitives are drawn. A pipeline without buffers draws `elementCount` vertices from no data, so one triangle over the viewport is three vertices. An attribute the program declares that no buffer feeds reads the pipeline's constant for its slot, or (0, 0, 0, 1) (`PipelineDesc.attributeConstants`). The uniform the pipeline names is flipped as its `ClipFlip` specifies, in the adapter's own copy of the block. A texture that is the open pass's own target (the render target drawn into, or the shadow map whose layer is drawn into) is refused, as sampling what a pass draws into is undefined.
- `endFrame`: Ends the screen's pass and the frame, and submits it.
  - throws `String`: No screen pass is open.

  `present` shows the frame. Between the two calls, the frame can be read back with `readPixels(0)`, and the caller can do other work.
- `present`: Shows the frame that `endFrame` submitted, and waits for the display's refresh.
  Natively the wait paces the caller's loop. In a page it does nothing, because the browser shows the frame when the frame's callback returns.
- `readPixels`: Reads a texture, a render target, or the frame just ended, back from the GPU.
  - `handle`: An RGBA8 `createTexture` texture (its top level), an RGBA8 render target, or 0 for the frame `endFrame` just ended.
  - `read`: Receives the pixels and their width and height. The pixels are `width * height * 4` bytes of RGBA8, with rows top first.
  - `failed`: Receives why the pixels can't be read, which is that no frame has ended since the last `beginFrame`.
  - throws `String`: A call inside a pass, or a handle that is none of these.

  It waits for the GPU, so it suits screenshots and checks, not every frame. A texture or render target is read as the passes so far left it. The frame `endFrame` ended must be read before `present`, and in a page before the frame's callback returns. One of `read` or `failed` is called once, on the main thread. It is called during the call, or later on a GPU that reads back asynchronously.
- `dispose`: Releases the adapter.
  It is called after every handle the adapter made is disposed, and before its window is closed.

## IHttp

*interface* in [`libs/platform/src/helix/platform/IHttp.hx`](../src/helix/platform/IHttp.hx), `import helix.platform.IHttp;`, extends `IPollable`

Defines HTTP GET requests, whose response body arrives in parts and which can be aborted.

```haxe
function get(url:String, noCache:Bool, headers:Map<String, String>, head:(status:Int, headers:Map<String, String>) -> Void, body:haxe.io.Bytes -> Void, done:() -> Void, failed:String -> Void, ?idleTimeout:Float):() -> Void
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
  - `idleTimeout`: Optional. How long, in seconds, the request may receive nothing before it fails; defaults to 30, and is clamped to 0.001 to 86400 (a day).
  - returns: The abort, which stops the transfer where the platform can.

  The callbacks are called on the main thread, never during this call. `head` is called once, then `body` for each part of the body as it arrives, then one of `done` or `failed`. An HTTP error status is a response, not a failure. After an abort, nothing more is called.

  A request that receives nothing for `idleTimeout` seconds fails: while it connects, while it waits for the head, or between parts of the body. A server that keeps sending, however slowly, doesn't time out. Natively, looking up the server's name isn't timed: that is left to the system's resolver.

  `done` means the body is as long as its `Content-Length`, where the platform can tell. In a page it sometimes can't: see `FetchApiHttpAdapter`.

  A conditional request (`If-None-Match`, `If-Modified-Since`) may be answered 200 with the whole body, as HTTP allows any server to do.
- `poll`: Delivers what arrived on the platform's threads since the last poll. The program calls it once a frame.
- `dispose`: Aborts every transfer.

## IImageDecoder

*interface* in [`libs/platform/src/helix/platform/IImageDecoder.hx`](../src/helix/platform/IImageDecoder.hx), `import helix.platform.IImageDecoder;`, extends `IPollable`

Defines image decoding from a file into 8-bit RGBA pixels.

It reads PNG, JPEG, BMP, TGA and GIF files, and a GIF's first frame only. The pixels are not premultiplied, and rows run top to bottom.

```haxe
function decode(encoded:haxe.io.Bytes, decoded:(pixels:haxe.io.Bytes, width:Int, height:Int) -> Void, failed:String -> Void):Void
function decodeForGpu(encoded:haxe.io.Bytes, decoded:IDecodedImage -> Void, failed:String -> Void):Void
function poll():Void
function dispose():Void
```

- `decode`: Decodes a file, off the main thread where the platform can.
  - `encoded`: The file's bytes.
  - `decoded`: Receives the pixels, `width * height * 4` bytes, and the image's width and height.
  - `failed`: Receives why the file can't be read.

  One of `decoded` or `failed` is called once, on the main thread, never during this call.
- `decodeForGpu`: Decodes a file for the GPU, off the main thread where the platform can: in a page the browser's own decoded image, with no readback, which `IGraphics.createTextureFromImage` uploads as it is; natively the pixels.
  - `encoded`: The file's bytes.
  - `decoded`: Receives the image. The receiver disposes it once it is uploaded, or when it isn't wanted.
  - `failed`: Receives why the file can't be read.

  One of `decoded` or `failed` is called once, on the main thread, never during this call.
- `poll`: Delivers what finished on the platform's threads since the last poll. The program calls it once a frame.
- `dispose`: Closes the decoder. A decode still running finishes without calling back.

## IKeyboard

*interface* in [`libs/platform/src/helix/platform/IKeyboard.hx`](../src/helix/platform/IKeyboard.hx), `import helix.platform.IKeyboard;`

Defines the keyboard: `KeyDown`, `KeyUp` and `Text` in `IEvents.events` while it exists.

Its adapter is constructed over the events adapter, whose `poll` delivers its events.

```haxe
var textInput(get, set):Bool
function dispose():Void
```

- `textInput`: Gets or sets whether typed text arrives, as `Text` events. A phone shows its keyboard while it is on. Defaults to false.
- `dispose`: Stops listening to the keyboard.

## IMouse

*interface* in [`libs/platform/src/helix/platform/IMouse.hx`](../src/helix/platform/IMouse.hx), `import helix.platform.IMouse;`

Defines the mouse: `MouseMove`, `MouseDown`, `MouseUp`, `MouseLeave` and `Wheel` in `IEvents.events` while it exists, and the cursor over the canvas or window.

Its adapter is constructed over the events adapter, whose `poll` delivers its events. A pen counts as the mouse.

```haxe
var cursorVisible(get, set):Bool
var cursorShape(get, set):CursorShape
var locked(get, never):Bool
function requestLock(locked:Bool, ?done:() -> Void, ?failed:String -> Void):Bool
function canSetPosition():Bool
function setPosition(x:Float, y:Float):Bool
function dispose():Void
```

- `cursorVisible`: Gets or sets whether the cursor shows over the canvas or window. Defaults to true. A locked mouse's cursor is hidden either way.
- `cursorShape`: Gets or sets the cursor's shape while it shows. Defaults to `Arrow`.
- `locked`: Gets whether the mouse is locked: its cursor hidden and held still, while its moves keep arriving. A locked mouse's `MouseMove` positions go on from where it was locked, by each move, past the canvas's or window's edges.
- `requestLock`: Asks for the mouse locked, for looking around with it, or let go.
  - `locked`: True to lock it, false to let it go.
  - `done`: Optional. Called once it is granted.
  - `failed`: Optional. Receives the reason when it is refused.
  - returns: Whether it asked: false where the mouse can't be locked.

  One of `done` or `failed` is called once, never during the call, and `locked` reflects the result from then. Natively the answer comes at the next `IEvents.poll`. A page locks only soon after a key press, click or tap; without one, it asks at the player's next. In a page, the player can let it go too, with Escape.
- `canSetPosition`: Returns whether `setPosition` can move the cursor. It is false in a page, where the browser doesn't let a program move it.
- `setPosition`: Moves the cursor to a place over the canvas or window, and a `MouseMove` there arrives at the next poll.
  - `x`: The place across, in framebuffer pixels from the left.
  - `y`: The place down, in framebuffer pixels from the top.
  - returns: Whether it moved: false where it can't (`canSetPosition`).
- `dispose`: Stops listening to the mouse, and shows the cursor as the system has it.

## IPollable

*interface* in [`libs/platform/src/helix/platform/IPollable.hx`](../src/helix/platform/IPollable.hx), `import helix.platform.IPollable;`

Defines an interface that answers later, delivering what it was asked for in its `poll` on the main thread and at no other time.

The program calls `poll` once a frame on each pollable it made. One it forgets to poll never answers. A service never polls the pollables it was provided, so one built over an `IFileSystem` or an `IAudio` leaves their polls to the program.

`IEvents`, `IHttp`, `IFileSystem`, `IAudio`, `IAudioDecoder` and `IImageDecoder` are pollable. A layer above them that answers later is pollable too, and is polled the same way.

```haxe
function poll():Void
```

- `poll`: Delivers what finished since the last poll. The program calls it once a frame.

## ISystem

*interface* in [`libs/platform/src/helix/platform/ISystem.hx`](../src/helix/platform/ISystem.hx), `import helix.platform.ISystem;`

Defines the facts about where the program runs.

They are the program's company and product, the device, the options the program was started with, the time, where the program's own files are, and where the OS keeps a program's files.

```haxe
var company(default, null):String
var product(default, null):String
var device(get, never):Device
function getOption(name:String):Null<String>
function getMemoryBytes():Float
function getTime():Float
function getProgramDirectory():String
function getDataDirectory():String
function getCacheDirectory():String
function openUrl(url:String):Bool
```

- `company`: Gets the company that makes the program: the `helix-company` define, or "DefaultCompany".
- `product`: Gets the program's name: the `helix-product` define, or natively the executable's name and in a page "Game". It names the program wherever one is shown, such as a window's title or a log.
- `device`: Gets what the program runs on, as far as the platform reports it.
- `getOption`: Returns an option the program was started with.
  - `name`: The option's name.
  - returns: The option's value, or null when it is not set.

  Natively the option is the command line's `--name=value`, or a bare `--name` for an empty value. When the command line doesn't have it, it is the environment variable named HELIX_ followed by the name in capitals. In a page it is the URL's query parameter of that name.
- `getMemoryBytes`: Returns the bytes of memory the program holds now, as far as the platform tells: natively the process's resident memory (what the OS has in RAM for it, code and data alike); in a page the script's heap where the browser reports it (Chromium), and 0 where it doesn't. A reading for a stats line, not an accounting: what it counts differs by platform, so compare readings on one.
  - returns: The bytes, or 0 when the platform can't tell.
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
- `openUrl`: Opens a URL in the system's browser. In a page it opens in a new tab, which the browser allows only soon after a key press, click or tap; without one, it opens at the player's next.
  - `url`: The URL: http, https or mailto.
  - returns: False, opening nothing, for a URL of another scheme.

## ITilt

*interface* in [`libs/platform/src/helix/platform/ITilt.hx`](../src/helix/platform/ITilt.hx), `import helix.platform.ITilt;`

Defines the device's tilt: `Tilt` and `TiltState` in `IEvents.events` once access is requested.

Its adapter is constructed over the events adapter, whose `poll` delivers its events and runs the request's callbacks.

```haxe
function requestAccess(?done:() -> Void, ?failed:String -> Void):Bool
function releaseAccess():Void
function dispose():Void
```

- `requestAccess`: Asks for the device's motion sensor, whose readings then arrive as `Tilt` events.
  - `done`: Optional. Called once readings arrive.
  - `failed`: Optional. Receives why there will be none: permission was refused, the page isn't secure (not HTTPS), or the browser reads no orientation.
  - returns: False, calling neither and reporting `Unavailable`, where the tilt can't be read at all.

  A page may need permission, which is asked at the next tap. `TiltState` events report each change: WaitingForTap while a tap is awaited, Starting until the first reading, then On. A game shows "tap to allow tilt" while the tilt waits for a tap. A reading that arrives after the tilt was reported unavailable turns it on, as a phone's sensor may start late.
- `releaseAccess`: Stops the readings. A permission granted stays granted, so a later `requestAccess` usually starts without asking again.
- `dispose`: Stops the readings and any request still waiting.

## ITouch

*interface* in [`libs/platform/src/helix/platform/ITouch.hx`](../src/helix/platform/ITouch.hx), `import helix.platform.ITouch;`

Defines touch: `TouchDown`, `TouchMove` and `TouchUp` in `IEvents.events` while it exists.

Its adapter is constructed over the events adapter, whose `poll` delivers its events. A finger is never reported as the mouse, and a trackpad's fingers aren't touch.

```haxe
var available(get, never):Bool
function dispose():Void
```

- `available`: Gets a value indicating whether the device has touch. A trackpad isn't touch.
- `dispose`: Stops listening to touch.

## IWindow

*interface* in [`libs/platform/src/helix/platform/IWindow.hx`](../src/helix/platform/IWindow.hx), `import helix.platform.IWindow;`

Defines the window a program draws in, with its title, size, position, fullscreen, visibility and monitors.

In a page the window is the page. Its title is the document's and its size is the viewport's, while fullscreen and visibility apply to the canvas. Sizes are in logical pixels unless they are named as framebuffer pixels.

A request asks for something the platform may refuse, or grant later. One of its `done` or `failed` is called once, never during the call: `done` once the window reflects it, and `failed` with the reason where it isn't done. Natively the answer comes at a later `IEvents.poll`, and a request the window manager ignores fails after a second. In a page, what a page can't do fails at the next `IEvents.poll`. A request returns false, calling neither, only where its doc says. A `can` method tells whether to offer it at all.

The window reports nothing by itself. What happens to it, such as being resized, focused, minimized or asked to close, arrives as events from `IEvents.poll`.

```haxe
var framebufferWidth(get, never):Int
var framebufferHeight(get, never):Int
var pixelRatio(get, never):Float
var focused(get, never):Bool
var title(get, set):String
var width(get, never):Int
var height(get, never):Int
var safeAreaX(get, never):Int
var safeAreaY(get, never):Int
var safeAreaWidth(get, never):Int
var safeAreaHeight(get, never):Int
function requestSize(width:Int, height:Int, ?done:() -> Void, ?failed:String -> Void):Bool
function canMove():Bool
var x(get, never):Int
var y(get, never):Int
function requestPosition(x:Int, y:Int, ?done:() -> Void, ?failed:String -> Void):Bool
function canFullscreen():Bool
var fullscreen(get, never):Bool
function requestFullscreen(enabled:Bool, ?done:() -> Void, ?failed:String -> Void):Bool
var orientation(get, never):Orientation
function requestOrientation(orientation:Orientation, ?done:() -> Void, ?failed:String -> Void):Bool
var visible(get, never):Bool
function requestVisible(visible:Bool, ?done:() -> Void, ?failed:String -> Void):Bool
var maximized(get, never):Bool
function requestMaximized(maximized:Bool, ?done:() -> Void, ?failed:String -> Void):Bool
var minimized(get, never):Bool
function requestMinimized(minimized:Bool, ?done:() -> Void, ?failed:String -> Void):Bool
function requestFocus(?done:() -> Void, ?failed:String -> Void):Bool
function setIcon(width:Int, height:Int, pixels:haxe.io.Bytes):Void
var opacity(get, never):Float
function requestOpacity(opacity:Float, ?done:() -> Void, ?failed:String -> Void):Bool
function requestMinimumSize(width:Int, height:Int, ?done:() -> Void, ?failed:String -> Void):Bool
function requestMaximumSize(width:Int, height:Int, ?done:() -> Void, ?failed:String -> Void):Bool
var monitorCount(get, never):Int
var monitorIndex(get, never):Int
function requestMonitorIndex(monitorIndex:Int, ?done:() -> Void, ?failed:String -> Void):Bool
function getMonitorName(monitorIndex:Int):String
function getMonitorX(monitorIndex:Int):Int
function getMonitorY(monitorIndex:Int):Int
function getMonitorWidth(monitorIndex:Int):Int
function getMonitorHeight(monitorIndex:Int):Int
function getMonitorRefreshRate(monitorIndex:Int):Float
function readDroppedFile(fileIndex:Int, maxBytes:Int, read:(name:String, bytes:haxe.io.Bytes) -> Void, failed:String -> Void):Void
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
- `safeAreaX`: Gets the left edge of the safe area, in logical pixels from the window's left.
  The safe area is the part of the window that no notch, rounded corner or system bar covers, where a HUD and buttons go; the window's whole inside where nothing does, as on a desktop. Natively it is SDL's (`SDL_GetWindowSafeArea`). In a page it is the viewport less CSS's `env(safe-area-inset-*)`, which a browser reports only to a page whose viewport meta tag has `viewport-fit=cover` (`<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">`): without it the browser keeps the page inside the safe area itself, and the safe area is the whole viewport.
- `safeAreaY`: Gets the top edge of the safe area, in logical pixels from the window's top. `safeAreaX` says what the safe area is.
- `safeAreaWidth`: Gets the safe area's width, in logical pixels. `safeAreaX` says what the safe area is.
- `safeAreaHeight`: Gets the safe area's height, in logical pixels. `safeAreaX` says what the safe area is.
- `requestSize`: Asks for an inner size.
  - `width`: The width, in logical pixels.
  - `height`: The height, in logical pixels.
  - `done`: Optional. Called once the window has a size from the request.
  - `failed`: Optional. Receives the reason the window wasn't resized.
  - returns: False, calling neither, for a size under 1.

  The window manager may give another size; `width` and `height` reflect what it gave. A fullscreen or maximized window keeps its size, and a page's canvas follows the page, so those fail.
- `canMove`: Returns whether `requestPosition` and `requestMonitorIndex` can move the window.
  - returns: False in a page, and where the compositor places windows (Wayland, XWayland).
- `x`: Gets the window's left edge on the desktop, in logical pixels.
  Natively it is 0 where the window can't move. In a page it is the browser window's left edge.
- `y`: Gets the window's top edge on the desktop, in logical pixels.
  Natively it is 0 where the window can't move. In a page it is the browser window's top edge.
- `requestPosition`: Asks for the window's left and top edges on the desktop.
  - `x`: The left edge, in logical pixels.
  - `y`: The top edge, in logical pixels.
  - `done`: Optional. Called once the window has moved, or was already there.
  - `failed`: Optional. Receives the reason it didn't move.
  - returns: True, because it always asks.

  `x` and `y` reflect what the window manager gave. Where the window can't move (`canMove`), or while it is fullscreen or maximized, it fails.
- `canFullscreen`: Returns whether `requestFullscreen` can ask.
  - returns: True natively. In a page, whether the page may go fullscreen.
- `fullscreen`: Gets a value indicating whether the window is fullscreen now. In a page it tells whether the canvas is.
- `requestFullscreen`: Asks for fullscreen or a window.
  - `enabled`: True for fullscreen, false for a window.
  - `done`: Optional. Called once the window is fullscreen, or windowed, as asked.
  - `failed`: Optional. Receives the reason when it is refused. The window is unchanged.
  - returns: False, calling neither, where it can't ask (`canFullscreen`).

  `fullscreen` reflects the result once the request completes. Natively the window manager applies it in its own time. A browser grants fullscreen only soon after a key press, click or tap. Without a recent one, the request waits for the player's next one.
- `orientation`: Gets the way up the screen is held for the program, as `requestOrientation` asked: `Any` when it isn't held. A page loses it as it leaves fullscreen, as browsers release the lock then; natively it is always `Any`.
- `requestOrientation`: Asks for the screen to be held one way up, or as the player holds it.
  - `orientation`: Landscape, Portrait, or Any to release a lock.
  - `done`: Optional. Called once the screen is locked.
  - `failed`: Optional. Receives the browser's reason when it refuses.
  - returns: False, calling neither, where it can't ask, which is natively.

  Only some browsers lock the screen. Chrome on Android does, but only in fullscreen, so the request belongs in `requestFullscreen`'s done. iOS Safari and desktops don't lock it. A game also shows "turn your device" when the shape is wrong. `orientation` reflects the result once the request completes.
- `visible`: Gets a value indicating whether the program shows the window. In a page it tells whether the canvas is shown.
  Whether the player can see the window, because it isn't minimized and its tab isn't in the background, is reported by the `Shown` and `Hidden` events.
- `requestVisible`: Asks to show or hide the window. In a page it shows or hides the canvas.
  - `visible`: True to show it.
  - `done`: Optional. Called once the window is shown, or hidden.
  - `failed`: Optional. Receives the reason it wasn't.
  - returns: True, because it always asks.

  `visible` reflects the result once the request completes: natively, once the window manager has shown it.
- `maximized`: Gets a value indicating whether the window fills the desktop as the window manager maximizes it. It is false in a page.
- `requestMaximized`: Asks for the window maximized, or back to its size from maximized or minimized.
  - `maximized`: True to maximize it, false to restore it.
  - `done`: Optional. Called once the window is maximized, or restored.
  - `failed`: Optional. Receives the reason it wasn't.
  - returns: True, because it always asks.

  `maximized` reflects the result once the request completes. In a page, whose canvas the page sizes, it fails.
- `minimized`: Gets a value indicating whether the window is minimized. It is false in a page; a tab in the background is `Hidden`.
- `requestMinimized`: Asks for the window minimized, or back from minimized.
  - `minimized`: True to minimize it, false to restore it.
  - `done`: Optional. Called once the window is minimized, or restored.
  - `failed`: Optional. Receives the reason it wasn't.
  - returns: True, because it always asks.

  `minimized` reflects the result once the request completes. In a page it fails.
- `requestFocus`: Asks for the window brought to the front with the keyboard. A window manager may only flash it. In a page the canvas takes the keyboard.
  - `done`: Optional. Called once the window, or in a page the canvas, has the keyboard.
  - `failed`: Optional. Receives the reason it hasn't: natively the window manager kept it elsewhere.
  - returns: True, because it always asks.

  `focused` reflects the result once the request completes.
- `setIcon`: Sets the window's icon, which the desktop shows in its title bar and task bar. In a page it is the page's icon.
  - `width`: The icon's width, in pixels.
  - `height`: The icon's height.
  - `pixels`: The icon's pixels: `width * height * 4` bytes of RGBA8, rows top first.
  - throws `String`: When the size isn't positive or the pixels are fewer than it needs.
- `opacity`: Gets how opaque the window is, from 0 (clear) to 1.
- `requestOpacity`: Asks for the window to be see-through. In a page it fades the canvas.
  - `opacity`: From 0 (clear) to 1 (opaque).
  - `done`: Optional. Called once the window has the opacity.
  - `failed`: Optional. Receives the reason it hasn't.
  - returns: True, because it always asks.

  `opacity` reflects the result once the request completes. A desktop without a compositor can't, and it fails.
- `requestMinimumSize`: Asks for the smallest size the player can make the window; 0 by 0 for none. In a page it fails.
  - `width`: The width, in logical pixels.
  - `height`: The height.
  - `done`: Optional. Called once the window has the limit.
  - `failed`: Optional. Receives the reason it hasn't.
  - returns: False, calling neither, for a size under 0.
- `requestMaximumSize`: Asks for the largest size the player can make the window; 0 by 0 for none. In a page it fails.
  - `width`: The width, in logical pixels.
  - `height`: The height.
  - `done`: Optional. Called once the window has the limit.
  - `failed`: Optional. Receives the reason it hasn't.
  - returns: False, calling neither, for a size under 0.
- `monitorCount`: Gets the number of monitors, at least 1. A page sees one screen.
- `monitorIndex`: Gets the index of the monitor holding the window.
- `requestMonitorIndex`: Asks for the window on another monitor.
  - `monitorIndex`: The monitor, 0 to `monitorCount` - 1.
  - `done`: Optional. Called once the window is on the monitor.
  - `failed`: Optional. Receives the reason it isn't.
  - returns: False, calling neither, for an index out of range.

  `monitorIndex` reflects the result once the request completes. Where the window can't move (`canMove`), a monitor other than its own fails.
- `getMonitorName`: Returns a monitor's name.
  - `monitorIndex`: The monitor.
  - returns: Its name, or "" for an index out of range.
- `getMonitorX`: Returns a monitor's left edge on the desktop.
  - `monitorIndex`: The monitor.
  - returns: The edge, in logical pixels, or 0 for an index out of range and in a page.
- `getMonitorY`: Returns a monitor's top edge on the desktop.
  - `monitorIndex`: The monitor.
  - returns: The edge, in logical pixels, or 0 for an index out of range and in a page.
- `getMonitorWidth`: Returns a monitor's width.
  - `monitorIndex`: The monitor.
  - returns: The width, in logical pixels, or 0 for an index out of range.
- `getMonitorHeight`: Returns a monitor's height.
  - `monitorIndex`: The monitor.
  - returns: The height, in logical pixels, or 0 for an index out of range.
- `getMonitorRefreshRate`: Returns how many times a second a monitor shows a new picture.
  - `monitorIndex`: The monitor, 0 to `monitorCount` - 1.
  - returns: The refresh rate in hertz, or 0 where it isn't known, as in a page.
- `readDroppedFile`: Reads a file dropped on the window, one the last `FilesDropped` event counted.
  - `fileIndex`: The file, 0 to the event's count - 1.
  - `maxBytes`: The largest file to read; a larger one fails.
  - `read`: Receives the file's name, without its directory, and its bytes.
  - `failed`: Receives why it can't be read: an index no drop gave, a file over `maxBytes`, or the platform's reason.

  One of `read` or `failed` is called once, never during the call: natively at the next `IEvents.poll`, in a page once the browser has read it, or for an index no drop gave or a file over `maxBytes`, at the next poll. Natively the file is read from where it is on disk then, so one moved or changed since the drop reads as it is then. In a page it is the File the browser gave, kept until the next drop.
- `canClose`: Returns whether `close` removes the window.
  - returns: True natively. False in a page, which a script can't close.

  A menu checks it before offering Quit.
- `close`: Closes the window natively, and does nothing in a page.
  `onClose` runs before the window closes. The program disposes the graphics drawing in the window before calling it, and ends its loop after it.
- `onClose`: Gets or sets the function called once, as the window goes for good. It defaults to null, for none.
  Natively it is called in `close`. In a page it is called at pagehide, with no frame after it, so a file written there isn't kept: a browser drops a write that starts as its page goes. A page receives no `CloseRequested`, so this is a page's only end.

## Key

*abstract* in [`libs/platform/src/helix/platform/Key.hx`](../src/helix/platform/Key.hx), `import helix.platform.Key;`

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

## MipmapFilter

*abstract* in [`libs/platform/src/helix/platform/MipmapFilter.hx`](../src/helix/platform/MipmapFilter.hx), `import helix.platform.MipmapFilter;`

Specifies how a texture's mipmaps are sampled when it is drawn smaller than its size.

A texture without mipmaps reads its top level whatever this is.

- `MipmapFilter.None`: The mipmaps aren't read: the top level alone, filtered as the sampling's filter says.
- `MipmapFilter.Nearest`: The mipmap nearest the drawn size, filtered as the sampling's filter says.
- `MipmapFilter.Linear`: The two mipmaps nearest the drawn size, each filtered as the sampling's filter says, blended, so a texture shrinks without shimmering or a seam between levels.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (None, Nearest): what Std.string, interpolation and trace show.

## MouseButton

*abstract* in [`libs/platform/src/helix/platform/MouseButton.hx`](../src/helix/platform/MouseButton.hx), `import helix.platform.MouseButton;`

Specifies a mouse button.

Values: `Left`, `Right`, `Middle`.

```haxe
static final all(default, null):Array<MouseButton>
function toString():String
```

- `all`: Every button.
- `toString`: Returns the value's name as written (Left, Right): what Std.string, interpolation and trace show.

## Orientation

*abstract* in [`libs/platform/src/helix/platform/Orientation.hx`](../src/helix/platform/Orientation.hx), `import helix.platform.Orientation;`

Specifies which way up a game wants the screen (`IWindow.requestOrientation`).

- `Orientation.Any`: As the player holds it, with any lock released.
- `Orientation.Landscape`: Wider than tall, with the long side across.
- `Orientation.Portrait`: Taller than wide, as a phone held upright.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Any, Landscape): what Std.string, interpolation and trace show.

## PipelineDesc

*typedef* in [`libs/platform/src/helix/platform/PipelineDesc.hx`](../src/helix/platform/PipelineDesc.hx), `import helix.platform.PipelineDesc;`

Represents everything a pipeline fixes for the draws through it.

`IGraphics.createPipeline` makes a pipeline from it. An adapter makes what the description specifies and knows nothing else about the program.

- `shader:Int`: The program, as an `IGraphics.createShader` handle.
- `primitive:Primitive`: The primitive the draws make.
- `indexed:Bool`: Whether the draws are indexed, by uint32 indices.
- `flipOffset:Null<Int>`: The byte offset in its block of the uniform `flip` reads. Optional; 0 when omitted. The adapter flips its own copy of the bytes as it uploads them, never the caller's, and reverses the winding with it, so `clockwise` and `cull` hold in a target and on the screen alike.
- `flipBlockSlot:Null<Int>`: The slot of the vertex stage's block holding the uniform `flip` reads. Optional; 0 when omitted.
- `flip:ClipFlip`: How a draw into a render target is turned the right way up, and through which uniform: the one at `flipBlockSlot` and `flipOffset`.
- `depthWrite:Bool`: Whether the draws write depth, where the test is on.
- `depthTest:DepthTest`: The depth test. `Off` turns the depth buffer off for the draws: no test and no write.
- `depthSlopeBias:Null<Float>`: The slope depth bias, scaled by how steeply the triangle's depth changes across a pixel and added with `depthBias`, so a surface seen edge-on gets more. Omitted, 0.
- `depthOnly:Bool`: Whether the draws write depth alone, for a shadow pass.
- `depthBias:Null<Float>`: The constant depth bias, in units of the smallest difference the target's depth resolves, added to each fragment's depth before the test and the write: positive pushes the draws away from the eye, negative pulls them nearer, so a decal wins over the surface under it and a shadow caster is lifted off itself. Omitted, 0.
- `cull:CullFace`: Which faces are culled.
- `colorWrite:Null<ColorChannels>`: The color channels the draws write; omitted, all of them. A channel left out keeps the target's value, blended or not. Depth is written as `depthWrite` specifies, and a depth-only pipeline writes no color whatever this holds.
- `clockwise:Bool`: Whether clockwise winding is the front face.
- `buffers:Array<VertexBuffer>`: The vertex buffers' layouts, by their index in a draw's buffers: at most 8, with at most 16 attributes across them, each at a slot from 0 to 15, as every adapter takes them.
- `blend:Blend`: How the colors are combined with the target's.
- `attributeConstants:Null<Array<{values:Array<Float>, slot:Int}>>`: What attributes no buffer feeds read, by slot: up to four floats each, the rest 0, 0, 1 as (0, 0, 0, 1) has them, the same for every vertex and instance. Optional; a slot not given reads (0, 0, 0, 1). A constant for a slot a buffer feeds is refused.

## Primitive

*abstract* in [`libs/platform/src/helix/platform/Primitive.hx`](../src/helix/platform/Primitive.hx), `import helix.platform.Primitive;`

Specifies what a pipeline's draws make.

- `Primitive.Triangles`: Triangles, three vertices or indices each.
- `Primitive.Lines`: Lines, two vertices or indices each.
- `Primitive.Points`: Points, one vertex or index each, drawn one pixel in size on every backend; culling ignores them.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Triangles, Lines): what Std.string, interpolation and trace show.

## RasterGlyph

*typedef* in [`libs/platform/src/helix/platform/RasterGlyph.hx`](../src/helix/platform/RasterGlyph.hx), `import helix.platform.RasterGlyph;`

Represents one glyph from `IFontRasterizer.rasterize`: its bitmap, where it sits, and how far it moves the pen.

- `width:Int`: The bitmap's width, in pixels; 0 for a glyph with no outline, such as a space.
- `pixels:haxe.io.Bytes`: The bitmap, `width * height` bytes, rows top to bottom: coverage, 0 to 255, or signed distances.
- `offsetY:Int`: The bitmap's top edge from the baseline, in pixels, down positive: above the baseline it is negative.
- `offsetX:Int`: The bitmap's left edge from the pen, in pixels.
- `height:Int`: The bitmap's height, in pixels.
- `found:Bool`: Whether the font has a glyph for it. When it doesn't, the bitmap is empty and the advance 0.
- `codepoint:Int`: The codepoint asked for.
- `advance:Float`: How far the pen moves after the glyph, in pixels.

## Sampling

*abstract* in [`libs/platform/src/helix/platform/Sampling.hx`](../src/helix/platform/Sampling.hx), `import helix.platform.Sampling;`

Represents how a draw samples a texture: its filter, how it wraps along u and v, how its mipmaps are read, and its anisotropy.

It is a small value passed with each texture a draw uses. Adapters keep one sampler for each value used.

```haxe
var tiled = new Sampling(Nearest, Repeat, Repeat);
var floor = new Sampling(Linear, Repeat, Repeat, Linear, 8);
```

```haxe
function new(filter:Filter, ?wrapU:Wrap = Clamp, ?wrapV:Wrap = Clamp, ?mipmapFilter:MipmapFilter, ?anisotropy:Int = 1)
static inline var NEAREST:Sampling
static inline var LINEAR:Sampling
var filter(get, never):Filter
var wrapU(get, never):Wrap
var wrapV(get, never):Wrap
var mipmapFilter(get, never):MipmapFilter
var anisotropy(get, never):Int
function withFilter(filter:Filter):Sampling
function withWrap(wrapU:Wrap, wrapV:Wrap):Sampling
function withMipmapFilter(mipmapFilter:MipmapFilter):Sampling
function withAnisotropy(anisotropy:Int):Sampling
static inline var COUNT:Int
```

- `new`: Creates a sampling.
  - `filter`: How the texture is filtered.
  - `wrapU`: Optional. How the texture wraps along u; defaults to Clamp.
  - `wrapV`: Optional. How the texture wraps along v; defaults to Clamp.
  - `mipmapFilter`: Optional. How a texture's mipmaps are read; defaults to Linear for a Linear filter and Nearest for a Nearest one.
  - `anisotropy`: Optional. The most texels read along a surface seen at a slant, 1 to 16, rounded down to 1, 2, 4, 8 or 16 and clamped to what the GPU has; defaults to 1, for none. It is used only with a Linear filter and Linear mipmaps, and ignored otherwise.
- `NEAREST`: Nearest filtering, clamped, for pixel art.
- `LINEAR`: Linear filtering, clamped, for a smooth look.
- `filter`: Gets how the texture is filtered, Linear or Nearest.
- `wrapU`: Gets how the texture wraps along u.
- `wrapV`: Gets how the texture wraps along v.
- `mipmapFilter`: Gets how the texture's mipmaps are read.
- `anisotropy`: Gets the most texels read along a surface seen at a slant: 1, 2, 4, 8 or 16.
- `withFilter`: Returns this sampling with another filter.
  - `filter`: The new filter.
  - returns: The sampling, its wrapping, mipmap filter and anisotropy unchanged.
- `withWrap`: Returns this sampling with other wrapping.
  - `wrapU`: How the texture wraps along u.
  - `wrapV`: How the texture wraps along v.
  - returns: The sampling, its filters and anisotropy unchanged.
- `withMipmapFilter`: Returns this sampling with another mipmap filter.
  - `mipmapFilter`: How the texture's mipmaps are read.
  - returns: The sampling, its filter, wrapping and anisotropy unchanged.
- `withAnisotropy`: Returns this sampling with another anisotropy.
  - `anisotropy`: The most texels read along a surface seen at a slant, 1 to 16, as the constructor takes it.
  - returns: The sampling, its filters and wrapping unchanged.
- `COUNT`: The number of distinct values, which run 0 to COUNT - 1. It is the size of an adapter's table of samplers.

## SdlGpuStages

*typedef* in [`libs/platform/src/helix/platform/SdlGpuStages.hx`](../src/helix/platform/SdlGpuStages.hx), `import helix.platform.SdlGpuStages;`

Represents a program in SDL_GPU's dialects, laid out as SDL_GPU binds them.

- `spirv:ShaderStages`: SPIR-V for Vulkan, each stage base64-encoded.
- `msl:ShaderStages`: MSL for Metal, entry points main0.
- `hlsl:ShaderStages`: HLSL for Direct3D 12, shader model 5.1, entry points main.

## ShaderBlock

*typedef* in [`libs/platform/src/helix/platform/ShaderBlock.hx`](../src/helix/platform/ShaderBlock.hx), `import helix.platform.ShaderBlock;`

Represents a uniform block that a program declares, and its members.

A block's bytes are laid out by std140, as `members` places them, on every adapter. Blocks are numbered in each stage, 0 to 3; one both stages declare alike is one block, at the same slot in each. `IGraphics.draw` takes a block's bytes at its index in `uniforms`: its slot for the vertex stage's, 4 plus its slot for the fragment stage's, and both for a block both read.

- `stage:String`: The stage that reads it: "vertex", "fragment", or "both" for a block both declare alike (the same name, slot and members).
- `slot:Int`: The binding slot in its stage, or in each stage for a block both read: 0 to 3.
- `size:Int`: The size, in bytes, rounded up to whole `vec4`s.
- `members:Array<ShaderMember>`: The members, in the order the block declares them, at their std140 offsets.
- `glslName:String`: The block's name in the GLSL.

## ShaderMember

*typedef* in [`libs/platform/src/helix/platform/ShaderMember.hx`](../src/helix/platform/ShaderMember.hx), `import helix.platform.ShaderMember;`

Represents a member of a uniform block that a program declares, as a leaf: its path, its GLSL type, where it starts in the block's bytes, and how many elements it has.

The block is laid out by std140: each element of an array, and each column of a matrix, starts on a 16-byte boundary, and a `vec3` is followed by room for one float. A struct member is reflected as its fields, each with its path (`light.color`); a field of an array of structs is one member whose elements are the array's (`lights.color`, `elementCount` the array's length, `stride` the struct's size). A member of a block with an instance name (`uniform Camera { ... } camera;`) has a path starting with that name (`camera.viewProjection`), as the GLSL writes it.

- `type:String`: The GLSL type: `float`, `vec2`, `vec3`, `vec4`, `mat2`, `mat3`, `mat4`, `int`, `ivec2`, `ivec3`, `ivec4`, `uint`, `uvec2`, `uvec3`, `uvec4`, `bool`, `bvec2`, `bvec3` or `bvec4`. A `bool` takes 4 bytes, 0 or 1, as a `uint` does.
- `stride:Int`: The bytes from one element to the next: 16 for a scalar or a vector, 16 a column for a matrix (64 for a `mat4`), a struct's size for a field of an array of structs.
- `offset:Int`: The byte offset of its first element in the block.
- `glslName:String`: The member's path in the GLSL: its name, or a struct field's `name.field`.
- `elementCount:Int`: The number of elements: 1, an array's length, or the length of the array of structs it is a field of.
- `active:Bool`: Whether the program's code reads it, as glslang's reflection of the stages finds; an unread one is still reflected, at its place. It is the whole member's: an array read at any element is active.

## ShaderSource

*typedef* in [`libs/platform/src/helix/platform/ShaderSource.hx`](../src/helix/platform/ShaderSource.hx), `import helix.platform.ShaderSource;`

Represents a compiled program, with its stages in each dialect the adapters compile, its vertex attributes, and what it binds.

`IGraphics.createShader` builds a program from it. An adapter reads only its own dialect. That is GLSL ES 300 in the browser, GLSL 410 for GL natively, and SDL_GPU's stages for SDL_GPU. The attributes with their types, the blocks with their members, and the textures are the program's reflection, for a caller that fills them by name.

- `vertexOutputs:Array<ShaderVarying>`: The values the vertex stage passes on, by location: what it declares as outputs.
- `uniformBlocks:Array<ShaderBlock>`: The uniform blocks it declares, with their members.
- `textures:Array<ShaderTexture>`: The textures it samples.
- `sdlGpu:Null<SdlGpuStages>`: SDL_GPU's stages. Present only in a build for SDL_GPU.
- `points:Null<Bool>`: Whether the vertex stage writes a point size of 1, compiled with `ShaderCompileOptions.points`, so `Primitive.Points` pipelines may draw it. Optional; false when omitted.
- `glsl410:Null<ShaderStages>`: GLSL 410, for GL natively. Absent from a browser build.
- `glsl300es:ShaderStages`: GLSL ES 300, for WebGL2.
- `fragmentInputs:Array<ShaderVarying>`: The values the fragment stage takes, by location: what it declares as inputs.
- `attributes:Array<String>`: The vertex attributes' names, by slot. A matrix's name is at its first slot, and its other columns' slots hold "".
- `attributeTypes:Array<String>`: The vertex attributes' GLSL types (`float`, `vec2`, `vec3`, `vec4`, `mat4`, `int`, `ivec4` and the rest), by slot: a matrix's at its first slot, and its columns' (`vec4` for a `mat4`) at the rest.
- `activeAttributes:Array<Int>`: The slots of the vertex attributes the vertex stage's code reads, as glslang finds; the others are declared and fed, and unread. A matrix's slot is its first column's.

## ShaderStages

*typedef* in [`libs/platform/src/helix/platform/ShaderStages.hx`](../src/helix/platform/ShaderStages.hx), `import helix.platform.ShaderStages;`

Represents one program's source in one dialect: its vertex and fragment stages.

- `vertex:String`: The vertex stage's source.
- `fragment:String`: The fragment stage's source.

## ShaderTexture

*typedef* in [`libs/platform/src/helix/platform/ShaderTexture.hx`](../src/helix/platform/ShaderTexture.hx), `import helix.platform.ShaderTexture;`

Represents a texture that a program samples, and its kind.

A texture is a plain 2D texture unless one of shadow, cube or data is true.

- `stage:String`: The stage that samples it: "vertex" or "fragment".
- `slot:Int`: The binding slot of the texture and its sampler.
- `shadow:Bool`: Whether it is a shadow map, which is a depth array read through a comparison sampler.
- `glslName:String`: The GLSL name of the texture and sampler pair.
- `data:Bool`: Whether the program never filters it.
- `cube:Bool`: Whether it is a cubemap.
- `active:Bool`: Whether the program's code samples it, as glslang finds; one unsampled is still declared and bound.

## ShaderVarying

*typedef* in [`libs/platform/src/helix/platform/ShaderVarying.hx`](../src/helix/platform/ShaderVarying.hx), `import helix.platform.ShaderVarying;`

Represents a value one stage of a program passes to the next: an output of the vertex stage, or an input of the fragment stage.

It is read from the compiled program, so it is what the stage declares, built-ins (`gl_Position`, `gl_FragCoord`) left out.

- `type:String`: Its GLSL type: `float`, `vec2`, `vec3`, `vec4`, `int`, `ivecN`, `uint`, `uvecN` or `matN`.
- `location:Int`: The location it is passed at. A matrix takes a location a column, from its own.
- `glslName:String`: Its GLSL name.

## StreamSource

*enum* in [`libs/platform/src/helix/platform/StreamSource.hx`](../src/helix/platform/StreamSource.hx), `import helix.platform.StreamSource;`

Specifies what an audio stream plays (`IAudio.openStream`).

- `Local(location:String)`: A file the platform reads directly. Natively it is a path, and in a page it is a URL, such as a Blob's.
- `Remote(url:String)`: A URL, which only an output that plays URLs itself opens (`IAudio.playsUrls`).
- `Downloading(source:GrowingSource)`: A file still downloading, played as it arrives. Only a native output plays it.

## TextureFormat

*abstract* in [`libs/platform/src/helix/platform/TextureFormat.hx`](../src/helix/platform/TextureFormat.hx), `import helix.platform.TextureFormat;`

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

*enum* in [`libs/platform/src/helix/platform/TiltStatus.hx`](../src/helix/platform/TiltStatus.hx), `import helix.platform.TiltStatus;`

Specifies the device's tilt status (`Event.TiltState`, after `ITilt.requestAccess`).

- `Off`: Not read: it was never asked for, or it was turned off.
- `WaitingForTap`: Waiting for the next tap, where a page asks for permission.
- `Starting`: Asked for, and listening. The first reading turns the tilt On. After a second and a half without a reading, the status is Unavailable.
- `On`: Read: `Tilt` events arrive.
- `Refused`: Permission was refused.
- `Unavailable`: The device gives no readings: there is no sensor, or none answered, or none is read on this target.
- `NeedsHttps`: The page isn't secure (not HTTPS), so the browser gives no readings.

## VertexAttribute

*typedef* in [`libs/platform/src/helix/platform/VertexAttribute.hx`](../src/helix/platform/VertexAttribute.hx), `import helix.platform.VertexAttribute;`

Represents a vertex attribute that a pipeline reads from one of its buffers.

- `slot:Int`: The shader's input slot, 0 to 15. The input must be a float one (`float`, `vecN` or a matrix's column).
- `offset:Int`: The byte offset within each record: a multiple of 4, its format's `bytes` ending within the record.
- `format:VertexFormat`: How its values are stored.

## VertexBuffer

*typedef* in [`libs/platform/src/helix/platform/VertexBuffer.hx`](../src/helix/platform/VertexBuffer.hx), `import helix.platform.VertexBuffer;`

Represents a vertex buffer that a pipeline reads, by its index in a draw's buffers.

A buffer with no attributes is a gap that the draw skips.

- `stride:Int`: The size of one record, in bytes: a multiple of 4, at most 255.
- `instanced:Bool`: Whether each record belongs to an instance rather than a vertex, so the buffer steps once per instance.
- `attributes:Array<VertexAttribute>`: The attributes read from each record.

## VertexFormat

*abstract* in [`libs/platform/src/helix/platform/VertexFormat.hx`](../src/helix/platform/VertexFormat.hx), `import helix.platform.VertexFormat;`

Specifies how a vertex attribute's values are stored in a buffer's records.

Every format is read by a float input (`float`, `vecN`, a matrix's column): floats and half floats as they are, a normalized format's integers as floats from 0 to 1 (unsigned) or -1 to 1 (signed, the lowest value reading -1 as the next one up does, 0 reading 0). These are the formats every backend has; an input of more components than its format reads the rest as 0, 0, 1 as (0, 0, 0, 1) has them, and one of fewer reads the first ones.

- `VertexFormat.Float1`: One float, 4 bytes.
- `VertexFormat.Float2`: Two floats, 8 bytes.
- `VertexFormat.Float3`: Three floats, 12 bytes.
- `VertexFormat.Float4`: Four floats, 16 bytes.
- `VertexFormat.UByte4Norm`: Four unsigned bytes, each read as its value over 255: 4 bytes, a color as RGBA8 stores it.
- `VertexFormat.Byte4Norm`: Four signed bytes, each read as its value over 127, -128 reading -1: 4 bytes.
- `VertexFormat.UShort2Norm`: Two unsigned 16-bit integers, little-endian, each read as its value over 65535: 4 bytes.
- `VertexFormat.Short2Norm`: Two signed 16-bit integers, little-endian, each read as its value over 32767, -32768 reading -1: 4 bytes.
- `VertexFormat.UShort4Norm`: Four unsigned 16-bit integers, little-endian, each read as its value over 65535: 8 bytes.
- `VertexFormat.Short4Norm`: Four signed 16-bit integers, little-endian, each read as its value over 32767, -32768 reading -1: 8 bytes.
- `VertexFormat.Half2`: Two half floats (IEEE binary16, little-endian): 4 bytes.
- `VertexFormat.Half4`: Four half floats (IEEE binary16, little-endian): 8 bytes.

```haxe
var bytes(get, never):Int
var componentCount(get, never):Int
function toString():String
```

- `bytes`: Gets the bytes one value takes in a record: 4, 8, 12 or 16.
- `componentCount`: Gets the number of components one value holds, 1 to 4.
- `toString`: Returns the value's name as written (Float1, Float2): what Std.string, interpolation and trace show.

## Wrap

*abstract* in [`libs/platform/src/helix/platform/Wrap.hx`](../src/helix/platform/Wrap.hx), `import helix.platform.Wrap;`

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
