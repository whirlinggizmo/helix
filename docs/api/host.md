# helix.host

[Back to the index](README.md)

## Adapters

*typedef* in `src/helix/host/Adapters.hx`

A profile's choice of adapter for each platform contract, which the Runner builds the app's Services over.

- `storage:IStore`: The writable cache downloaded assets are kept in.
- `packaged:IStore`: The assets shipped with the build, read when base is null (read-only).
- `name:String`: The program's name, beginning the names of the files it makes (Identity.getProduct).
- `manifest:Null<String>`: The root asset manifest's path under base (IAssets.setManifest), or null for none.
- `input:IInputSource`: Keyboard, mouse, touch and gamepads.
- `images:IImageDecoder`: Image decoding.
- `http:IHttp`: HTTP downloads.
- `harness:ITestHarness`: Where results go for the check that launched the program.
- `graphics:IGraphics`: The GPU.
- `export:IExport`: Where files made for the user (screenshots) go.
- `base:Null<String>`: The URL prefix assets are fetched from; null reads them from packaged instead.
- `audioDecoder:IAudioDecoder`: Compressed audio decoding.
- `audio:IAudio`: Sound output.

## FrameClock

*class* in `src/helix/host/FrameClock.hx`

A host's frame timing, the same on every target, measured on the host's own clock between frames that ran (not a smoothed estimate, whose sum drifts from wall time). Each frame has two measures: the delta, the dt IApp.frame is passed, held between MIN_DELTA and MAX_DELTA for animation; and the elapsed time, unheld, for a fixed-rate simulation (Ticker), which bounds its own catch-up.

```haxe
function new()
static var MIN_DELTA(inline, null):Float
static var MAX_DELTA(inline, null):Float
function frame(now:Float):Void
function getDelta():Float
function getElapsed():Float
```

- `new`: A clock with no frame yet.
- `MIN_DELTA`: The least delta, in seconds.
- `MAX_DELTA`: The most delta, in seconds: past a longer stall (a hidden tab, a debugger) animation moves on by this much.
- `frame`: Starts a frame at now, seconds on the host's clock (IHost.getTime).
- `getDelta`: This frame's delta in seconds: the time since the last frame, held between MIN_DELTA and MAX_DELTA, and 1/60 on the first, which has nothing to measure from.
- `getElapsed`: This frame's elapsed time in seconds: the time since the last frame, unheld, and 0 on the first.

## IHost

*class* in `src/helix/host/IHost.hx`

The host: what runs the program on a platform (a browser page's frame callbacks, a native process's app loop). It owns the loop, the clock, quitting, the window and where run options come from, and nothing else: the Runner it pumps builds and runs everything the app sees (Services).

```haxe
function run(init:() -> Void, frame:() -> Void, cleanup:() -> Void):Void
function getTime():Float
function getWindow():IWindow
function canQuit():Bool
function quit():Void
function getOption(name:String):Null<String>
```

- `run`: Runs the program: init once, when the window and the GPU exist; frame once a display refresh; cleanup once, when it closes (the window closed, quit, or a browser page going away). Natively it returns only after the window closes.
- `getTime`: Seconds on a monotonic clock.
- `getWindow`: The window the program draws in (the page, on the web).
- `canQuit`: Whether quitting closes anything, so whether an app should offer a quit key: not in a browser page, where quit stops the program but the page stays.
- `quit`: Closes after the current frame: cleanup runs. Natively the window closes; in a browser page the frames stop and the canvas keeps its last one.
- `getOption`: A run option as the platform passes it, or null when it isn't given: in a browser the URL query parameter name, natively the environment variable HELIX_ and name in capitals.

## IWindow

*class* in `src/helix/host/IWindow.hx`

The window the app draws in: title, size, place, fullscreen, visibility and the monitors, in logical pixels. Names follow docs/CONVENTIONS.md: every set has a get (is for a bool); can says whether to offer an action at all; request asks for what the platform may refuse or grant later, returning whether it asked, never whether it was granted. A setter that can't act here refuses, returning false: the web can't move or size its window, and under XWayland the compositor places windows.

```haxe
function getFramebufferWidth():Int
function getFramebufferHeight():Int
function getPixelRatio():Float
function isFocused():Bool
function getTitle():String
function setTitle(title:String):Void
function getWidth():Int
function getHeight():Int
function requestSize(width:Int, height:Int):Bool
function canMove():Bool
function getX():Int
function getY():Int
function requestPosition(x:Int, y:Int):Bool
function canFullscreen():Bool
function isFullscreen():Bool
function requestFullscreen(enabled:Bool):Bool
function isVisible():Bool
function requestVisible(visible:Bool):Bool
function getMonitorCount():Int
function getMonitorIndex():Int
function requestMonitorIndex(index:Int):Bool
function getMonitorName(index:Int):String
function getMonitorX(index:Int):Int
function getMonitorY(index:Int):Int
function getMonitorWidth(index:Int):Int
function getMonitorHeight(index:Int):Int
```

- `getFramebufferWidth`: The drawable area's width in framebuffer pixels (the getWidth and getHeight sizes are logical pixels).
- `getFramebufferHeight`: The drawable area's height in framebuffer pixels.
- `getPixelRatio`: Framebuffer pixels per logical pixel.
- `isFocused`: Whether the window has the keyboard and is shown: false while it's in the background, minimized, or (on the web) the page is hidden.
- `getTitle`: The title bar's text (the document's title, on the web).
- `setTitle`: Sets the title bar's text (the document's title, on the web).
- `getWidth`: The window's inner width in logical pixels (the viewport's, on the web).
- `getHeight`: The window's inner height in logical pixels (the viewport's, on the web).
- `requestSize`: Asks for an inner size in logical pixels; getWidth and getHeight answer on a later frame, with what the window manager gave (it may give another size, or none). False, asking nothing, where a program can't size its window (the web), or for a size under 1.
- `canMove`: Whether requestPosition and requestMonitorIndex can ask: not on the web, nor where the compositor places windows (XWayland).
- `getX`: The window's left edge on the desktop in logical pixels; natively 0 where it can't move (canMove), on the web the browser window's.
- `getY`: The window's top edge on the desktop in logical pixels; natively 0 where it can't move (canMove), on the web the browser window's.
- `requestPosition`: Asks for the window's left and top edges on the desktop in logical pixels; getX and getY answer on a later frame, with what the window manager gave. False, asking nothing, where the window can't move (canMove).
- `canFullscreen`: Whether requestFullscreen can ask: always natively; on the web, where the page may go fullscreen.
- `isFullscreen`: Whether the window is fullscreen now (the canvas, on the web).
- `requestFullscreen`: Asks for fullscreen or a window; isFullscreen answers on a later frame. False where it can't ask (canFullscreen). On the web the browser grants it only soon after a key press or click.
- `isVisible`: Whether the window is shown (the canvas, on the web).
- `requestVisible`: Asks to show or hide the window (the canvas, on the web); isVisible answers on a later frame (natively, once the window manager has shown it). Always asks: true.
- `getMonitorCount`: How many monitors there are, at least 1; the web sees one screen.
- `getMonitorIndex`: The monitor holding the window.
- `requestMonitorIndex`: Asks for the window on monitor index; getMonitorIndex answers on a later frame. False, asking nothing, for an index out of range, or where the window can't move (canMove).
- `getMonitorName`: "" for an index out of range, as the other monitor getters answer 0.
- `getMonitorX`: The monitor's left edge on the desktop in logical pixels; 0 for an index out of range, and on the web.
- `getMonitorY`: The monitor's top edge on the desktop in logical pixels; 0 for an index out of range, and on the web.
- `getMonitorWidth`: The monitor's width in logical pixels; 0 for an index out of range.
- `getMonitorHeight`: The monitor's height in logical pixels; 0 for an index out of range.

## Identity

*class* in `src/helix/host/Identity.hx`

Who the program is, for what HeliX keeps for it: a company and a product, each one safe file name. Natively it names the cache directory (<user cache>/<company>/<product>); in the browser, the page's cache database.

```haxe
function new(product:String, ?company:String = "DefaultCompany")
static function cleanName(name:String):Null<String>
function getCompany():String
function getProduct():String
```

- `new`: product and company, cleaned (cleanName). Throws for a name that cleans to nothing or is too long.
- `cleanName`: name as one file name every desktop accepts: characters no file system takes (<>:"/\|? *, control characters) become _, leading and trailing dots and spaces go, and a Windows device name (CON, PRN, AUX, NUL, COM1-9, LPT1-9, with any extension) gets a leading _. null for a name that's empty once cleaned, or 128 characters or more (refused, never cut).
- `getCompany`: The company, cleaned; "DefaultCompany" unless given.
- `getProduct`: The product, cleaned: the program's own name.

## Presentation

*class* in `src/helix/host/Presentation.hx`

The app's design fitted to its window, one setting for the whole program: a game is written for a design size, its units stay the design's at any window size, on a phone or in fullscreen, and what's visible of them (the visible area) is known each frame. The runner refits it to the window before every frame. A 2D camera shows it (apply), a layout is arranged into the visible area (Box.arrange), and the pointer comes back in units through the camera (Pointer), or through toUnitsX and toUnitsY. A 3D camera draws into the area it covers (getAreaX and the rest, Camera3D.setViewportArea) to keep out of the bars.

```haxe
function new()
function set(mode:PresentationMode, width:Float, height:Float):Bool
function getMode():PresentationMode
function getWidth():Float
function getHeight():Float
function getScaleX():Float
function getScaleY():Float
function getVisibleX():Float
function getVisibleY():Float
function getVisibleWidth():Float
function getVisibleHeight():Float
function isPortrait():Bool
function getAreaX():Int
function getAreaY():Int
function getAreaWidth():Int
function getAreaHeight():Int
function toUnitsX(x:Float):Float
function toUnitsY(y:Float):Float
function apply(camera:Camera2D):Void
```

- `new`: None, fitted to a 1 x 1 framebuffer until the runner's first refit.
- `set`: Fits the design, width x height units, to the window by mode, from the next frame (None takes no size: give 0, 0). False, changing nothing, for a size under 1 but for None.
- `getMode`: How the design is fitted.
- `getWidth`: The design's width in units: the window's logical width under None.
- `getHeight`: The design's height in units: the window's logical height under None.
- `getScaleX`: Framebuffer pixels to a unit, across (under Stretch, each axis has its own).
- `getScaleY`: Framebuffer pixels to a unit, down.
- `getVisibleX`: The visible area's left edge in units: 0 under None, Stretch, Fit and Integer; more under Fill, which crops; less under Expand, which grows. A HUD anchored to an edge places itself from the visible area.
- `getVisibleY`: The visible area's top edge in units.
- `getVisibleWidth`: The visible area's width in units.
- `getVisibleHeight`: The visible area's height in units.
- `isPortrait`: Whether the visible area is taller than wide: a phone held upright, for a game with a layout for each.
- `getAreaX`: The visible area's left edge in framebuffer pixels: past 0 where Fit and Integer have bars.
- `getAreaY`: The visible area's top edge in framebuffer pixels, from the framebuffer's top.
- `getAreaWidth`: The visible area's width in framebuffer pixels.
- `getAreaHeight`: The visible area's height in framebuffer pixels.
- `toUnitsX`: The unit across at framebuffer pixel x (input's pointer and touches are framebuffer pixels).
- `toUnitsY`: The unit down at framebuffer pixel y.
- `apply`: Sets camera to show the visible area on the framebuffer pixels it covers: its viewport the area, a unit its zoom.

## PresentationMode

*enum* in `src/helix/host/Presentation.hx`

How a game's design is fitted to the window (Godot's stretch modes and aspects, libwgf's presentation).

- `None`: The default: a unit is a logical pixel (a framebuffer pixel over the pixel ratio), and the visible area is the window.
- `Stretch`: The design scaled to the window on each axis apart, its aspect lost.
- `Fit`: Scaled alike on both axes, as large as it fits whole, centered; the framebuffer around it is bars, nothing drawn in them.
- `Fill`: Scaled alike, as small as covers the window, centered; what's past the window's edges is cropped.
- `Expand`: Scaled as Fit is, but the visible area grows past the design to the window's edges, centered on it: the design is the least the game shows, and a layout arranged into the visible area keeps to the window's edges.
- `Integer`: As Fit, at a whole number of framebuffer pixels to a unit (at least 1), for pixel art; bars around it.

## Runner

*class* in `src/helix/host/Runner.hx`

What a host pumps: at its init it builds the app's Services over a profile's adapters (and the engine's shared services over those), each frame it runs them in their order (the shared services' polls, input's, the presentation refitted to the window and the game's clock advanced, the app's frame, input's frame end) with the clock and timings, and at its cleanup it closes them in theirs (the shared services, the app's cleanup, audio, input, the framework's pipelines, the GPU): the platform's services are the runner's to close, never the app's. The same on every platform: a host owns only the loop, the clock and the window.

```haxe
function new(host:IHost, compose:() -> Adapters)
function run(makeApp:() -> IApp):Void
function getHost():IHost
function getClock():FrameClock
function getFrameCpu():Float
function getFrameInterval():Float
function isBusy():Bool
function assetChanged(path:String):Void
```

- `new`: A runner for host, building its services from compose's adapters when the host starts (natively the GPU exists only then).
- `run`: Runs the app makeApp builds on the host: built once the services are filled (so its field initializers may read them), its init then, its frame once a display refresh, its cleanup at the end. Natively it returns only after the window closes.
- `getHost`: The host it runs on.
- `getClock`: The frame clock.
- `getFrameCpu`: The last frame's CPU time in milliseconds.
- `getFrameInterval`: Milliseconds between the last two frames' starts (0 for the first).
- `isBusy`: Whether the shared services are loading anything (Services.isBusy).
- `assetChanged`: The file at path (an asset path) changed: its assets load again in place. A development host's file watcher calls it.

## Services

*class* in `src/helix/host/Services.hx`

What an app has to work with: the platform's GPU, input, audio, window and storage, the engine's shared services over them (assets, sounds, textures, environments), the presentation, the clock, run options and quitting. One program, one set, so they're statics, as the earlier frameworks' and Godot's are (DECISIONS 114): any class reads `Services.window` without being handed it. The Runner fills them as the program starts and clears them at its end: an app reads them from its init on (a profile builds the app after they're filled, so a field initializer may read them too), and the framework's own classes in src/ never read them, taking what they use instead, so they stay testable apart. A test fills what it needs (`@:privateAccess`) and clears it after. hotreload-hx keeps every static's value across a reload, so a swap keeps them.

```haxe
static var graphics(default, null):IGraphics
static var input(default, null):IInput
static var audio(default, null):IAudio
static var window(default, null):IWindow
static var presentation(default, null):Presentation
static var clock(default, null):Clock
static var assets(default, null):IAssets
static var fetch(default, null):Fetch
static var storage(default, null):Storage
static var audioResources(default, null):AudioResources
static var textures(default, null):Textures
static var environments(default, null):Environments
static var harness(default, null):ITestHarness
static var screenshots(default, null):Screenshots
static function isBusy():Bool
static function getTime():Float
static function getFrameElapsed():Float
static function getFrameCpu():Float
static function getFrameInterval():Float
static function getOption(name:String, fallback:String):String
static function canQuit():Bool
static function quit():Void
```

- `graphics`: The GPU.
- `input`: Keyboard, mouse, touch and gamepads.
- `audio`: Sound output.
- `window`: The window the app draws in (the page, on the web): its drawing surface's size, pixel ratio and focus too.
- `presentation`: The app's design fitted to the window: its units, what's visible of them, and a 2D camera to show them (None, logical pixels, until the app sets a mode).
- `clock`: The game's time: the frames' time scaled and paused as a whole (helix.time.Clock), updated before each frame; what tickers, tweens, timers, animators and emitters are fed.
- `assets`: Assets: the packaged files or downloads, cached.
- `fetch`: Downloads.
- `storage`: The writable cache.
- `audioResources`: Sounds loaded through the assets and decoded for audio.
- `textures`: Textures from image files, reloading in place when a file changes during development.
- `environments`: Environment maps from equirectangular images, prepared a little each frame.
- `harness`: Where results go for the check that launched the program.
- `screenshots`: Screenshots of the frame, saved for the user (a download in a browser, a file natively).
- `isBusy`: Whether anything is still loading: an asset, an image or sound being decoded, an environment being prepared. A loading screen waits for it to be false (with the app's own loads in view); so does a tool taking the frame's picture once it's in.
- `getTime`: Seconds on the host's monotonic clock.
- `getFrameElapsed`: The seconds since the last frame, unheld (the app's frame dt is held at 0.1), and 0 on the first: what a fixed-rate simulation (Ticker.advance) is fed, so a slow frame is caught up in ticks instead of lost.
- `getFrameCpu`: The last frame's CPU time in milliseconds, its services' polls included.
- `getFrameInterval`: Milliseconds between the last two frames' starts (0 for the first).
- `getOption`: A run option, or fallback when it isn't given: in a browser the URL query parameter name, natively the environment variable HELIX_ and name in capitals.
- `canQuit`: Whether quitting closes anything, so whether to offer a quit key: not in a browser page, where quit stops the program but the page stays.
- `quit`: Ends the program after this frame: the services close and the app's cleanup runs. Natively the window closes; in a browser page the frames stop and the canvas keeps its last one.

## WindowOptions

*class* in `src/helix/host/WindowOptions.hx`

What's fixed when the window opens, given to a profile's run before it does: an app starts after, too late to change them.

```haxe
function new()
function getMsaaSamples():Int
function requestMsaaSamples(count:Int):Bool
```

- `new`: The defaults: 4 multisampling samples a pixel.
- `getMsaaSamples`: The multisampling samples a pixel asked for: 4 unless requested otherwise.
- `requestMsaaSamples`: Asks for count samples a pixel to smooth edges (multisampling): 1 for none, else 2, 4 or 8. A request: the platform may give fewer (a browser chooses its own count, nearly always 4, for anything over 1), and IGraphics.getMsaaSamples answers what it gave (getMaxMsaaSamples, the most this GPU has, for a settings menu to offer at the next start). False, changing nothing, for another count.
