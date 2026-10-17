# helix.host

[Back to the index](README.md)

## Adapters

*typedef* in `src/helix/host/Adapters.hx`

A profile's choice of adapter for each platform contract, which the Runner builds the app's services over.

- `storage:IStore`: The writable cache downloaded assets are kept in.
- `packaged:IStore`: The assets shipped with the build, read when base is null (read-only).
- `name:String`: The program's name, beginning the names of the files it makes (Identity.product).
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

## Config

*class* in `src/helix/host/Config.hx`

A game's settings from config.json among its assets, fetched as the program starts (so a deployed game changes them without a build): a "default" object, and named profiles over it ("development", "production", any the game names), each a partial that layers on the default; "profile" at the root names the one in force, and the run option config=<name> overrides that. Host.getOption reads the profile, by dotted names into nested objects ("renderer.background"), after the run options. The keys and their meanings are the game's: whether to show a splash, play music, where assets are.

```haxe
static function parse(bytes:haxe.io.Bytes, ?profileName:String):Null<Config>
static function toBool(text:Null<String>, fallback:Bool):Bool
static function toFloat(text:Null<String>, fallback:Float):Float
static function toInt(text:Null<String>, fallback:Int):Int
var profileName(default, null):String
var profileNames(get, never):Array<String>
function get(name:String):Null<Dynamic>
function getString(name:String):Null<String>
```

- `parse`: The config in bytes (JSON), with the profile chosen (the root's "profile", else "default") unless profileName names one. Null for bytes that aren't a JSON object.
- `toBool`: text as a bool: 1, true, yes and on are true, 0, false, no and off are false (any case); fallback for anything else or null.
- `toFloat`: text as a number; fallback for anything that isn't one, or null.
- `toInt`: text as a whole number; fallback for anything that isn't one, or null.
- `profileName`: The profile in force.
- `profileNames`: The profiles the file has, in name order, "default" among them when it does.
- `get`: The value at name (dotted into nested objects) in the profile, else in the default; null for none. A number, a string, a bool, an array or an object, as the JSON has it.
- `getString`: The value at name as text: a string as it is, a number or bool as JSON writes it ("1.5", "true"); null for none or an object.

## FrameClock

*class* in `src/helix/host/FrameClock.hx`

A host's frame timing, the same on every target, measured on the host's own clock between frames that ran (not a smoothed estimate, whose sum drifts from wall time). Each frame has two measures: the delta, the dt IApp.frame is passed, held between MIN_DELTA and MAX_DELTA for animation; and the elapsed time, unheld, for a fixed-rate simulation (Ticker), which bounds its own catch-up.

```haxe
function new()
static var MIN_DELTA(inline, null):Float
static var MAX_DELTA(inline, null):Float
function frame(now:Float):Void
var delta(default, null):Float
var elapsed(default, null):Float
```

- `new`: A clock with no frame yet.
- `MIN_DELTA`: The least delta, in seconds.
- `MAX_DELTA`: The most delta, in seconds: past a longer stall (a hidden tab, a debugger) animation moves on by this much.
- `frame`: Starts a frame at now, seconds on the host's clock (IHost.time).
- `delta`: This frame's delta in seconds: the time since the last frame, held between MIN_DELTA and MAX_DELTA, and 1/60 on the first, which has nothing to measure from.
- `elapsed`: This frame's elapsed time in seconds: the time since the last frame, unheld, and 0 on the first.

## Host

*class* in `src/helix/host/Host.hx`

The program on its platform: whether it runs, whether anything is still loading, its run options and settings, and quitting. The program's one, a static class: canQuit and quit forward to instance, written by helix.macro.Facade from IHost's with their doc comments; the loop, the window (Window) and the clock (Time) are reached elsewhere.

```haxe
static var instance(default, null):IHost
static var config(default, null):Null<Config>
static var running(get, never):Bool
static var busy(get, never):Bool
static function getOption(name:String, fallback:String):String
static function getOptionBool(name:String, fallback:Bool):Bool
static function getOptionFloat(name:String, fallback:Float):Float
static function getOptionInt(name:String, fallback:Int):Int
static function canQuit():Bool
static function quit():Void
```

- `instance`: The host forwarded to: the runner's from its start to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `config`: The game's settings from config.json among its assets (Config), or null without one. Kept across a hot reload (@:hot), as instance is.
- `running`: Whether the runner is running the program: false in a test, which makes what it needs itself.
- `busy`: Whether anything is still loading: an asset, an image or sound being decoded, an environment being prepared. A loading screen waits for it to be false (with the app's own loads in view); so does a tool taking the frame's picture once it's in.
- `getOption`: A run option, or fallback when it isn't given: in a browser the URL query parameter name, natively the environment variable HELIX_ and name in capitals; else the config's value at name (its profile over its default, dotted into nested objects), as text.
- `getOptionBool`: getOption as a bool: 1, true, yes and on are true, 0, false, no and off are false; fallback for anything else.
- `getOptionFloat`: getOption as a number; fallback for anything that isn't one.
- `getOptionInt`: getOption as a whole number; fallback for anything that isn't one.
- `canQuit`: Whether quitting closes anything, so whether an app should offer a quit key: not in a browser page, where quit stops the program but the page stays.
- `quit`: Closes after the current frame: cleanup runs. Natively the window closes; in a browser page the frames stop and the canvas keeps its last one.

## IHost

*class* in `src/helix/host/IHost.hx`

The host: what runs the program on a platform (a browser page's frame callbacks, a native process's app loop). It owns the loop, the clock, quitting, the window and where run options come from, and nothing else: the Runner it pumps builds and runs everything the app sees (the static classes it binds: Window, Input, Graphics and the others).

```haxe
function run(init:() -> Void, frame:() -> Void, cleanup:() -> Void):Void
var time(get, never):Float
var window(get, never):IWindow
function canQuit():Bool
function quit():Void
function getOption(name:String):Null<String>
```

- `run`: Runs the program: init once, when the window and the GPU exist; frame once a display refresh; cleanup once, when it closes (the window closed, quit, or a browser page going away). Natively it returns only after the window closes.
- `time`: Seconds on a monotonic clock.
- `window`: The window the program draws in (the page, on the web).
- `canQuit`: Whether quitting closes anything, so whether an app should offer a quit key: not in a browser page, where quit stops the program but the page stays.
- `quit`: Closes after the current frame: cleanup runs. Natively the window closes; in a browser page the frames stop and the canvas keeps its last one.
- `getOption`: A run option as the platform passes it, or null when it isn't given: in a browser the URL query parameter name, natively the environment variable HELIX_ and name in capitals.

## IWindow

*class* in `src/helix/host/IWindow.hx`

The window the app draws in: title, size, place, fullscreen, visibility and the monitors, in logical pixels. Names follow docs/CONVENTIONS.md: a value is a property; can says whether to offer an action at all; request asks for what the platform may refuse or grant later, returning whether it asked, never whether it was granted, and the property answers on a later frame. A request that can't act here refuses, returning false: the web can't move or size its window, and under XWayland the compositor places windows.

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
function requestFullscreen(enabled:Bool):Bool
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
```

- `framebufferWidth`: The drawable area's width in framebuffer pixels (the width and height sizes are logical pixels).
- `framebufferHeight`: The drawable area's height in framebuffer pixels.
- `pixelRatio`: Framebuffer pixels per logical pixel.
- `focused`: Whether the window has the keyboard and is shown: false while it's in the background, minimized, or (on the web) the page is hidden.
- `title`: The title bar's text (the document's title, on the web).
- `width`: The window's inner width in logical pixels (the viewport's, on the web).
- `height`: The window's inner height in logical pixels (the viewport's, on the web).
- `requestSize`: Asks for an inner size in logical pixels; width and height answer on a later frame, with what the window manager gave (it may give another size, or none). False, asking nothing, where a program can't size its window (the web), or for a size under 1.
- `canMove`: Whether requestPosition and requestMonitorIndex can ask: not on the web, nor where the compositor places windows (XWayland).
- `x`: The window's left edge on the desktop in logical pixels; natively 0 where it can't move (canMove), on the web the browser window's.
- `y`: The window's top edge on the desktop in logical pixels; natively 0 where it can't move (canMove), on the web the browser window's.
- `requestPosition`: Asks for the window's left and top edges on the desktop in logical pixels; x and y answer on a later frame, with what the window manager gave. False, asking nothing, where the window can't move (canMove).
- `canFullscreen`: Whether requestFullscreen can ask: always natively; on the web, where the page may go fullscreen.
- `fullscreen`: Whether the window is fullscreen now (the canvas, on the web).
- `requestFullscreen`: Asks for fullscreen or a window; fullscreen answers on a later frame. False where it can't ask (canFullscreen). On the web the browser grants it only soon after a key press or click.
- `visible`: Whether the window is shown (the canvas, on the web).
- `requestVisible`: Asks to show or hide the window (the canvas, on the web); visible answers on a later frame (natively, once the window manager has shown it). Always asks: true.
- `monitorCount`: How many monitors there are, at least 1; the web sees one screen.
- `monitorIndex`: The monitor holding the window.
- `requestMonitorIndex`: Asks for the window on monitor index; monitorIndex answers on a later frame. False, asking nothing, for an index out of range, or where the window can't move (canMove).
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
var company(default, null):String
var product(default, null):String
```

- `new`: product and company, cleaned (cleanName). Throws for a name that cleans to nothing or is too long.
- `cleanName`: name as one file name every desktop accepts: characters no file system takes (<>:"/\|? *, control characters) become _, leading and trailing dots and spaces go, and a Windows device name (CON, PRN, AUX, NUL, COM1-9, LPT1-9, with any extension) gets a leading _. null for a name that's empty once cleaned, or 128 characters or more (refused, never cut).
- `company`: The company, cleaned; "DefaultCompany" unless given.
- `product`: The product, cleaned: the program's own name.

## Presentation

*class* in `src/helix/host/Presentation.hx`

The app's design fitted to its window, one setting for the whole program: a game is written for a design size, its units stay the design's at any window size, on a phone or in fullscreen, and what's visible of them (the visible area) is known each frame. The runner refits it to the window before every frame. A 2D camera shows it (apply), a layout is arranged into the visible area (Box.arrange), and the pointer comes back in units through the camera (Pointer), or through toUnitsX and toUnitsY. A 3D camera draws into the area it covers (areaX and the rest, Camera3D.setViewportArea) to keep out of the bars.

```haxe
function new()
function set(mode:PresentationMode, width:Float, height:Float):Bool
var mode(default, null):PresentationMode
var width(get, never):Float
var height(get, never):Float
var scaleX(default, null):Float
var scaleY(default, null):Float
var visibleX(default, null):Float
var visibleY(default, null):Float
var visibleWidth(default, null):Float
var visibleHeight(default, null):Float
var portrait(get, never):Bool
var areaX(default, null):Int
var areaY(default, null):Int
var areaWidth(default, null):Int
var areaHeight(default, null):Int
function toUnitsX(x:Float):Float
function toUnitsY(y:Float):Float
function apply(camera:Camera2D):Void
```

- `new`: None, fitted to a 1 x 1 framebuffer until the runner's first refit.
- `set`: Fits the design, width x height units, to the window by mode, from the next frame (None takes no size: give 0, 0). False, changing nothing, for a size under 1 but for None.
- `mode`: How the design is fitted.
- `width`: The design's width in units: the window's logical width under None.
- `height`: The design's height in units: the window's logical height under None.
- `scaleX`: Framebuffer pixels to a unit, across (under Stretch, each axis has its own).
- `scaleY`: Framebuffer pixels to a unit, down.
- `visibleX`: The visible area's left edge in units: 0 under None, Stretch, Fit and Integer; more under Fill, which crops; less under Expand, which grows. A HUD anchored to an edge places itself from the visible area.
- `visibleY`: The visible area's top edge in units.
- `visibleWidth`: The visible area's width in units.
- `visibleHeight`: The visible area's height in units.
- `portrait`: Whether the visible area is taller than wide: a phone held upright, for a game with a layout for each.
- `areaX`: The visible area's left edge in framebuffer pixels: past 0 where Fit and Integer have bars.
- `areaY`: The visible area's top edge in framebuffer pixels, from the framebuffer's top.
- `areaWidth`: The visible area's width in framebuffer pixels.
- `areaHeight`: The visible area's height in framebuffer pixels.
- `toUnitsX`: The unit across at framebuffer pixel x (input's pointer and touches are framebuffer pixels).
- `toUnitsY`: The unit down at framebuffer pixel y.
- `apply`: Sets camera to show the visible area on the framebuffer pixels it covers: its viewport the area, a unit its zoom.

## PresentationMode

*enum* in `src/helix/host/Presentation.hx`

How a game's design is fitted to the window (Godot's stretch modes and aspects).

- `None`: The default: a unit is a logical pixel (a framebuffer pixel over the pixel ratio), and the visible area is the window.
- `Stretch`: The design scaled to the window on each axis apart, its aspect lost.
- `Fit`: Scaled alike on both axes, as large as it fits whole, centered; the framebuffer around it is bars, nothing drawn in them.
- `Fill`: Scaled alike, as small as covers the window, centered; what's past the window's edges is cropped.
- `Expand`: Scaled as Fit is, but the visible area grows past the design to the window's edges, centered on it: the design is the least the game shows, and a layout arranged into the visible area keeps to the window's edges.
- `Integer`: As Fit, at a whole number of framebuffer pixels to a unit (at least 1), for pixel art; bars around it.

## Runner

*class* in `src/helix/host/Runner.hx`

What a host pumps: at its init it builds the app's services over a profile's adapters (and the engine's shared services over those) and binds the static classes the app reaches them by (Window, Input, Graphics, Audio, Assets, Time and the others), each frame it runs them in their order (the shared services' polls, input's, the presentation refitted to the window and the game's clock advanced, the app's frame, input's frame end) with the clock and timings, and at its cleanup it closes them in theirs (the shared services, the app's cleanup, audio, input, the framework's pipelines, the GPU) and unbinds the statics: the platform's services are the runner's to close, never the app's. The same on every platform: a host owns only the loop, the clock and the window.

```haxe
function new(host:IHost, compose:() -> Adapters)
function run(makeApp:() -> IApp):Void
var host(default, null):IHost
var clock(default, null):FrameClock
var frameCpu(default, null):Float
var frameInterval(default, null):Float
var busy(get, never):Bool
function assetChanged(path:String):Void
```

- `new`: A runner for host, building its services from compose's adapters when the host starts (natively the GPU exists only then).
- `run`: Runs the app makeApp builds on the host: built once the services are filled (so its field initializers may read them), its init then, its frame once a display refresh, its cleanup at the end. Natively it returns only after the window closes.
- `host`: The host it runs on.
- `clock`: The frame clock.
- `frameCpu`: The last frame's CPU time in milliseconds.
- `frameInterval`: Milliseconds between the last two frames' starts (0 for the first).
- `busy`: Whether the shared services are loading anything (Host.busy).
- `assetChanged`: The file at path (an asset path) changed: its assets load again in place. A development host's file watcher calls it.

## Screen

*class* in `src/helix/host/Screen.hx`

The app's design fitted to the window (Presentation): its units, what's visible of them, and a 2D camera to show them (None, logical pixels, until the app sets a mode). The runner refits it to the window before every frame. The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from Presentation's public members with their doc comments.

```haxe
static var instance(default, null):Presentation
static function set(mode:PresentationMode, width:Float, height:Float):Bool
static var mode(get, never):PresentationMode
static var width(get, never):Float
static var height(get, never):Float
static var scaleX(get, never):Float
static var scaleY(get, never):Float
static var visibleX(get, never):Float
static var visibleY(get, never):Float
static var visibleWidth(get, never):Float
static var visibleHeight(get, never):Float
static var portrait(get, never):Bool
static var areaX(get, never):Int
static var areaY(get, never):Int
static var areaWidth(get, never):Int
static var areaHeight(get, never):Int
static function toUnitsX(x:Float):Float
static function toUnitsY(y:Float):Float
static function apply(camera:Camera2D):Void
```

- `instance`: The presentation forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `set`: Fits the design, width x height units, to the window by mode, from the next frame (None takes no size: give 0, 0). False, changing nothing, for a size under 1 but for None.
- `mode`: How the design is fitted.
- `width`: The design's width in units: the window's logical width under None.
- `height`: The design's height in units: the window's logical height under None.
- `scaleX`: Framebuffer pixels to a unit, across (under Stretch, each axis has its own).
- `scaleY`: Framebuffer pixels to a unit, down.
- `visibleX`: The visible area's left edge in units: 0 under None, Stretch, Fit and Integer; more under Fill, which crops; less under Expand, which grows. A HUD anchored to an edge places itself from the visible area.
- `visibleY`: The visible area's top edge in units.
- `visibleWidth`: The visible area's width in units.
- `visibleHeight`: The visible area's height in units.
- `portrait`: Whether the visible area is taller than wide: a phone held upright, for a game with a layout for each.
- `areaX`: The visible area's left edge in framebuffer pixels: past 0 where Fit and Integer have bars.
- `areaY`: The visible area's top edge in framebuffer pixels, from the framebuffer's top.
- `areaWidth`: The visible area's width in framebuffer pixels.
- `areaHeight`: The visible area's height in framebuffer pixels.
- `toUnitsX`: The unit across at framebuffer pixel x (input's pointer and touches are framebuffer pixels).
- `toUnitsY`: The unit down at framebuffer pixel y.
- `apply`: Sets camera to show the visible area on the framebuffer pixels it covers: its viewport the area, a unit its zoom.

## Window

*class* in `src/helix/host/Window.hx`

The window the app draws in (the page, on the web): its drawing surface's size, pixel ratio and focus too, and what may be asked of it (a size, a position, fullscreen). The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from IWindow's public members with their doc comments.

```haxe
static var instance(default, null):IWindow
static var framebufferWidth(get, never):Int
static var framebufferHeight(get, never):Int
static var pixelRatio(get, never):Float
static var focused(get, never):Bool
static var title(get, set):String
static var width(get, never):Int
static var height(get, never):Int
static function requestSize(width:Int, height:Int):Bool
static function canMove():Bool
static var x(get, never):Int
static var y(get, never):Int
static function requestPosition(x:Int, y:Int):Bool
static function canFullscreen():Bool
static var fullscreen(get, never):Bool
static function requestFullscreen(enabled:Bool):Bool
static var visible(get, never):Bool
static function requestVisible(visible:Bool):Bool
static var monitorCount(get, never):Int
static var monitorIndex(get, never):Int
static function requestMonitorIndex(index:Int):Bool
static function getMonitorName(index:Int):String
static function getMonitorX(index:Int):Int
static function getMonitorY(index:Int):Int
static function getMonitorWidth(index:Int):Int
static function getMonitorHeight(index:Int):Int
```

- `instance`: The window forwarded to: the host's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `framebufferWidth`: The drawable area's width in framebuffer pixels (the width and height sizes are logical pixels).
- `framebufferHeight`: The drawable area's height in framebuffer pixels.
- `pixelRatio`: Framebuffer pixels per logical pixel.
- `focused`: Whether the window has the keyboard and is shown: false while it's in the background, minimized, or (on the web) the page is hidden.
- `title`: The title bar's text (the document's title, on the web).
- `width`: The window's inner width in logical pixels (the viewport's, on the web).
- `height`: The window's inner height in logical pixels (the viewport's, on the web).
- `requestSize`: Asks for an inner size in logical pixels; width and height answer on a later frame, with what the window manager gave (it may give another size, or none). False, asking nothing, where a program can't size its window (the web), or for a size under 1.
- `canMove`: Whether requestPosition and requestMonitorIndex can ask: not on the web, nor where the compositor places windows (XWayland).
- `x`: The window's left edge on the desktop in logical pixels; natively 0 where it can't move (canMove), on the web the browser window's.
- `y`: The window's top edge on the desktop in logical pixels; natively 0 where it can't move (canMove), on the web the browser window's.
- `requestPosition`: Asks for the window's left and top edges on the desktop in logical pixels; x and y answer on a later frame, with what the window manager gave. False, asking nothing, where the window can't move (canMove).
- `canFullscreen`: Whether requestFullscreen can ask: always natively; on the web, where the page may go fullscreen.
- `fullscreen`: Whether the window is fullscreen now (the canvas, on the web).
- `requestFullscreen`: Asks for fullscreen or a window; fullscreen answers on a later frame. False where it can't ask (canFullscreen). On the web the browser grants it only soon after a key press or click.
- `visible`: Whether the window is shown (the canvas, on the web).
- `requestVisible`: Asks to show or hide the window (the canvas, on the web); visible answers on a later frame (natively, once the window manager has shown it). Always asks: true.
- `monitorCount`: How many monitors there are, at least 1; the web sees one screen.
- `monitorIndex`: The monitor holding the window.
- `requestMonitorIndex`: Asks for the window on monitor index; monitorIndex answers on a later frame. False, asking nothing, for an index out of range, or where the window can't move (canMove).
- `getMonitorName`: "" for an index out of range, as the other monitor getters answer 0.
- `getMonitorX`: The monitor's left edge on the desktop in logical pixels; 0 for an index out of range, and on the web.
- `getMonitorY`: The monitor's top edge on the desktop in logical pixels; 0 for an index out of range, and on the web.
- `getMonitorWidth`: The monitor's width in logical pixels; 0 for an index out of range.
- `getMonitorHeight`: The monitor's height in logical pixels; 0 for an index out of range.

## WindowOptions

*class* in `src/helix/host/WindowOptions.hx`

What's fixed when the window opens, given to a profile's run before it does: an app starts after, too late to change them.

```haxe
function new()
var msaaSamples(default, null):Int
function requestMsaaSamples(count:Int):Bool
```

- `new`: The defaults: 4 multisampling samples a pixel.
- `msaaSamples`: The multisampling samples a pixel asked for: 4 unless requested otherwise.
- `requestMsaaSamples`: Asks for count samples a pixel to smooth edges (multisampling): 1 for none, else 2, 4 or 8. A request: the platform may give fewer (a browser chooses its own count, nearly always 4, for anything over 1), and IGraphics.msaaSamples answers what it gave (maxMsaaSamples, the most this GPU has, for a settings menu to offer at the next start). False, changing nothing, for another count.
