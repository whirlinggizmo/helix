# helix.app

[Back to the index](README.md)

## BaseApp

*class* in `src/helix/app/BaseApp.hx`

Empty defaults: an app overrides only the callbacks it uses. One that can't extend this implements IApp directly.

```haxe
function new()
function init():Void
function frame(dt:Float):Void
function cleanup():Void
```

- `new`: An app with no callbacks of its own.

## IApp

*class* in `src/helix/app/IApp.hx`

What the Runner drives. It calls through the object each time, so after a hot reload its new methods are what run.

```haxe
function init():Void
function frame(dt:Float):Void
function cleanup():Void
```

- `init`: Once, before the first frame, with the app's services bound (Window, Input, Graphics and the others).
- `frame`: Once a display refresh; dt is the measured seconds since the last frame, held between 1e-6 and 0.1, and 1/60 on the first: for animation. A fixed-rate simulation takes Time.frameElapsed instead (helix.host.FrameClock).
- `cleanup`: Once, when the window closes (on the web, at the page's pagehide).
