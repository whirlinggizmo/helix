# helix.app

[Back to the index](README.md)

## AppOptions

*class* in `src/helix/app/AppOptions.hx`

What an App starts with, given to its constructor (`super(options)`, or `new Game(options)` from Main); the defaults when none is given. Read once, as the app starts: a change after is too late.

```haxe
function new()
var product:String
var company:String
var assets:Null<String>
var manifest:Null<String>
var window:WindowOptions
var devKeys:Bool
var pageState:Bool
var pauseOnBlur:Bool
```

- `new`: The defaults: product "Game" by "DefaultCompany", the assets beside the program, no manifest, a window of 4 samples a pixel, and the development extras on in a debug build (-debug) and off otherwise.
- `product`: The program's own name: with company, its identity (helix.host.Identity), which names what HeliX keeps for it (its cache directory natively, its cache database in the browser, its screenshots' directory). One safe file name; cleaned as Identity cleans it.
- `company`: The company, the other half of the identity.
- `assets`: Where the assets are: in the browser the URL the asset paths are fetched under ("assets/", beside the page, by default), natively a directory relative to the program's ("assets", beside it, by default). Null for the platform's default.
- `manifest`: A manifest among the assets (tools/gen_manifest.py; "manifest.json" for the examples), read in the browser so a returning page re-fetches only what changed; null (the default) fetches each file as it's asked for. Natively a manifest comes from HELIX_ASSET_MANIFEST instead, with HELIX_ASSET_HOST.
- `window`: The window as it opens: the multisampling samples a pixel.
- `devKeys`: The development keys around every frame: F9 saves a screenshot of the frame (a download in a browser, a file in the user's pictures natively), logged where it went. On in a debug build (-debug), off otherwise, unless set. A game chooses its own keys for what it ships.
- `pageState`: Whether the page is told the program's state, for the tools driving it: in a browser, window.helixBusy says after each frame whether the services are still loading (Host.busy), and false once the program has quit, so a tool captures the page once it has settled (tools/pages_shots.cjs); natively nothing. On in a debug build (-debug), off otherwise, unless set.
- `pauseOnBlur`: Whether the game's clock (Time.clock) pauses while the window doesn't have the focus, and goes on when it's back: a game left in another tab or behind another window waits. On unless set off; a clock the game paused itself stays paused either way.

## IApp

*class* in `src/helix/app/IApp.hx`

What the Runner drives. It calls through the object each time, so after a hot reload its new methods are what run.

```haxe
function init():Void
function update(dt:Float):Void
function cleanup():Void
```

- `init`: Once, before the first frame, with the app's services bound (Window, Input, Graphics and the others).
- `update`: Once a display refresh, before the frame is drawn: the game's logic. dt is the measured seconds since the last frame, held between 1e-6 and 0.1, and 1/60 on the first: for animation. A fixed-rate simulation takes Time.frameElapsed instead (helix.host.FrameClock).
- `cleanup`: Once, when the window closes (on the web, at the page's pagehide).

## Springboard

*class* in `src/helix/app/Springboard.hx`

The Runner's way into an App across a hot reload: three lambdas, each calling a `@:hot` static function of the app's class by name (hotreload-hx's springboards), which helix.macro.AppBuild writes for every App subclass. Natively a reload re-points those statics at the new module and migrates the app object held in the class's `@:hot static`, so the Runner, compiled once into the executable, reaches the newest code and the migrated object without knowing either; in the browser every call reaches the new code anyway, and the lambdas cost nothing.

```haxe
function new(init:() -> Void, update:Float -> Void, cleanup:() -> Void)
function init():Void
function update(dt:Float):Void
function cleanup():Void
```

- `new`: The three calls: each a lambda calling the class's `@:hot` static by name, `() -> Game.hotInit()`, never the function passed as a value (a bound method keeps its old code).
