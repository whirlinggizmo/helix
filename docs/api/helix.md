# helix

[Back to the index](README.md)

## App

*class* in [`src/helix/App.hx`](../../src/helix/App.hx)

HeliX's entry point. A game is a class extending it, overriding init, update and cleanup (the IApp contract), and its Main is `new Game()`: the constructor starts HeliX, picking the profile by the backend the build names (`-D helix-backend=webgl2`, `sokol-gl`, `sdl3-gl` or `sdl3-gpu`; a build naming none fails, naming the choices), so one Main serves every target: `class Game extends helix.App { override public function init():Void {...} override public function update(dt:Float):Void {...} }` (init once, the services bound: Window, Input, Graphics and the others; update once a display refresh, the game's logic), and `class Main { static function main() new Game(); }`. The drawing is the runner's: after update it draws the Stage (helix.render2d.Stage), what the game put on it (docs/DISPLAY_MODEL.md). The object exists before HeliX does: a field initializer runs before the services are bound, so what needs them (a Batch2D, a texture) is made in init. Natively the constructor returns only when the window closes. Options (AppOptions: the identity, where the assets are, a manifest, the window, the development extras) are given to the constructor, `super(options)` or `new Game(options)`. Hot reload: the Runner reaches the app only through `@:hot` static springboards that helix.macro.AppBuild writes into the game's class (`hotApp`, the object; `hotInit`, `hotFrame`, `hotCleanup`), so a native reload re-points its calls and migrates the object (hotreload-hx: the main class is compiled once and never reloaded, and a call from code compiled before a reload reaches new code only through a `@:hot` static function); in the browser old classes forward, so it costs nothing. The game class is therefore not Main, which hotreload-hx never reloads and refuses `@:hot` in.

```haxe
function new(?options:AppOptions)
var options(default, null):AppOptions
function init():Void
function update(dt:Float):Void
function cleanup():Void
```

- `new`: Starts HeliX with this app, with options (the defaults when not given): the profile of the build's backend runs, binds the services, calls init once the game's config.json (if any) has come, then update once a display refresh, and cleanup when the window closes (the page goes away). Throws for an identity (product, company) that isn't a file name. Natively returns when the window has closed.
- `options`: The options it started with.
