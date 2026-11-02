# helix.services.screen

[Back to the index](README.md)

## Screen

*class* in [`services/src/helix/services/screen/Screen.hx`](../../services/src/helix/services/screen/Screen.hx), `import helix.services.screen.Screen;`, implements `IPollable`

Provides the window as a game draws to it: a design size fitted to the window, fullscreen asked for with the windowed size and place to go back to, whether the window was resized, and the window kept as it was between runs.

The program constructs one over its `IWindow` and `IEvents`, and calls `poll` once a frame. With no design size, the design is the window's own logical size. With one, a game draws in design pixels into the viewport (`viewportX` to `viewportHeight`, framebuffer pixels, for `IGraphics.applyViewport`), and turns the mouse's or a finger's framebuffer position into design pixels with `toDesignX` and `toDesignY`. The sizes, scales and viewport follow the window's framebuffer as it is when read, so a page's canvas resized between frames is seen before the next poll.

```haxe
var screen = new Screen(window, events, {designWidth: 320, designHeight: 180, fit: PixelPerfect});
// each frame:
screen.poll();
var x = screen.toDesignX(mouse.x), y = screen.toDesignY(mouse.y);
if (keyboard.isKeyPressed(F11)) screen.requestFullscreen(!screen.fullscreen);
```

```haxe
function new(window:IWindow, events:IEvents, ?options:ScreenOptions)
var designWidth(default, null):Int
var designHeight(default, null):Int
var fit(default, null):ScreenFit
function setDesignSize(width:Int, height:Int, fit:ScreenFit):Void
var width(get, never):Float
var height(get, never):Float
var scaleX(get, never):Float
var scaleY(get, never):Float
var viewportX(get, never):Int
var viewportY(get, never):Int
var viewportWidth(get, never):Int
var viewportHeight(get, never):Int
function toDesignX(x:Float):Float
function toDesignY(y:Float):Float
function toScreenX(x:Float):Float
function toScreenY(y:Float):Float
var resized(default, null):Bool
var fullscreen(get, never):Bool
function requestFullscreen(enabled:Bool, ?done:() -> Void, ?failed:String -> Void):Bool
function remember(saves:Saves, ?key:String = "screen"):Void
function poll():Void
```

- `new`: Creates the screen over the window, its design and fit as the options say.
  - `window`: The window.
  - `events`: The platform's events, whose last `poll` this one reads.
  - `options`: Optional. The design size and how it fits; none by default.
- `designWidth`: Gets the design's width, in design pixels; 0 for none.
- `designHeight`: Gets the design's height, in design pixels; 0 for none.
- `fit`: Gets how the design fits the window.
- `setDesignSize`: Sets the design size and how it fits the window; 0 by 0 for none.
  - `width`: The design's width, in design pixels.
  - `height`: The design's height.
  - `fit`: How it fits.
- `width`: Gets the width drawn in, in design pixels: the design's, wider under `Expand` on a wider window, or the window's logical width with no design.
- `height`: Gets the height drawn in, in design pixels: the design's, taller under `Expand` on a taller window, or the window's logical height with no design.
- `scaleX`: Gets the framebuffer pixels a design pixel takes across.
- `scaleY`: Gets the framebuffer pixels a design pixel takes down; `scaleX` unless the fit is `Stretch`.
- `viewportX`: Gets the left edge of the area drawn in, in framebuffer pixels.
- `viewportY`: Gets the top edge of the area drawn in, in framebuffer pixels from the top.
- `viewportWidth`: Gets the width of the area drawn in, in framebuffer pixels.
- `viewportHeight`: Gets the height of the area drawn in, in framebuffer pixels.
- `toDesignX`: Returns where a framebuffer position across is in design pixels, as the mouse's or a finger's.
  - `x`: The position, in framebuffer pixels from the left.
  - returns: The position in design pixels; outside 0 to `width` on a bar.
- `toDesignY`: Returns where a framebuffer position down is in design pixels.
  - `y`: The position, in framebuffer pixels from the top.
  - returns: The position in design pixels; outside 0 to `height` on a bar.
- `toScreenX`: Returns where a design position across is on the framebuffer.
  - `x`: The position, in design pixels.
  - returns: The position, in framebuffer pixels from the left.
- `toScreenY`: Returns where a design position down is on the framebuffer.
  - `y`: The position, in design pixels.
  - returns: The position, in framebuffer pixels from the top.
- `resized`: Gets whether the window was resized this frame, by the player, the OS or a request.
- `fullscreen`: Gets whether the window is fullscreen now.
- `requestFullscreen`: Asks for fullscreen or a window. Leaving fullscreen goes back to the size and place the window last had.
  - `enabled`: True for fullscreen, false for a window.
  - `done`: Optional. Called once it is granted.
  - `failed`: Optional. Receives the reason when it is refused.
  - returns: Whether it asked: false where the window can't be fullscreen.

  The result comes later, to the lambdas, and `fullscreen` reflects it once the request completes.
- `remember`: Keeps the window's size, place and fullscreen between runs, in the saves under a key: what was kept is asked for now, and what changes is kept as it does. The saves need not have been read: what was kept is asked for once they are.
  - `saves`: The saves.
  - `key`: Optional. The key it is kept under. Defaults to "screen".
- `poll`: Reads the events the last `IEvents.poll` delivered: whether the window was resized; the size and place it has while windowed, and going back to them as it leaves fullscreen; the fit; and what `remember` keeps. Call it once a frame.

## ScreenFit

*abstract* in [`services/src/helix/services/screen/ScreenFit.hx`](../../services/src/helix/services/screen/ScreenFit.hx), `import helix.services.screen.ScreenFit;`

Specifies how `Screen` fits its design size to the window.

- `ScreenFit.Letterbox`: Scaled as large as it fits whole, keeping its shape; bars fill the rest.
- `ScreenFit.PixelPerfect`: Scaled by the largest whole number that fits, keeping its shape and every pixel square and alike; bars fill the rest.
- `ScreenFit.Stretch`: Scaled to fill the window, its shape stretched to the window's.
- `ScreenFit.Expand`: Scaled as large as it fits whole, keeping its shape, then grown on its short side to fill the window, so more of the world shows on a wider or taller window and there are no bars.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Letterbox, PixelPerfect): what Std.string, interpolation and trace show.

## ScreenOptions

*class* in [`services/src/helix/services/screen/ScreenOptions.hx`](../../services/src/helix/services/screen/ScreenOptions.hx), `import helix.services.screen.ScreenOptions;`

Represents how `Screen` starts: its design size and how it fits the window.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?designWidth:Int, ?designHeight:Int, ?fit:ScreenFit}
```

```haxe
final designWidth:Int = 0
final designHeight:Int = 0
final fit:ScreenFit = Letterbox
```

- `designWidth`: Gets the design's width, in design pixels; 0, the default, for none: the window's own logical size.
- `designHeight`: Gets the design's height, in design pixels; 0, the default, for none.
- `fit`: Gets how the design fits the window. Defaults to `Letterbox`.
