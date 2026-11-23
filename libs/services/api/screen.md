# helix.services.screen

[Back to the library](README.md)

## Screen

*class* in [`libs/services/src/helix/services/screen/Screen.hx`](../src/helix/services/screen/Screen.hx), `import helix.services.screen.Screen;`, implements `IPollable`

Provides the window as a game draws to it: a design size fitted to the window, fullscreen asked for with the windowed size and place to go back to, whether the window was resized, and the window kept as it was between runs.

The program constructs one over its `IWindow` and `IEvents`, and calls `poll` once a frame. With no design size, the design is the window's own logical size. With one, the design is centred in the window, and a game draws the visible area (`visibleX` to `visibleHeight`, design pixels) into the viewport (`viewportX` to `viewportHeight`, framebuffer pixels, for `IGraphics.applyViewport`). The visible area is the design itself, or more around it where the fit grows it (`visibleX` and `visibleY` negative), or less where `Cover` cuts its edges off. The game turns the mouse's or a finger's framebuffer position into design pixels with `toDesignX` and `toDesignY`. A HUD lays out inside the safe area (`safeAreaX` to `safeAreaHeight`, design pixels), clear of a phone's notch and bars. The sizes, scales and viewport follow the window's framebuffer as it is when read, so a page's canvas resized between frames is seen before the next poll.

```haxe
var screen = new Screen(window, events, {designWidth: 320, designHeight: 180, fit: Keep, integerScale: true});
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
var integerScale(default, null):Bool
function setDesignSize(width:Int, height:Int, fit:ScreenFit, ?integerScale:Bool = false):Void
var visibleX(get, never):Float
var visibleY(get, never):Float
var visibleWidth(get, never):Float
var visibleHeight(get, never):Float
var scaleX(get, never):Float
var scaleY(get, never):Float
var viewportX(get, never):Int
var viewportY(get, never):Int
var viewportWidth(get, never):Int
var viewportHeight(get, never):Int
var safeAreaX(get, never):Float
var safeAreaY(get, never):Float
var safeAreaWidth(get, never):Float
var safeAreaHeight(get, never):Float
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
- `integerScale`: Gets whether the design is scaled by a whole number (`ScreenOptions.integerScale`).
- `setDesignSize`: Sets the design size and how it fits the window; 0 by 0 for none.
  - `width`: The design's width, in design pixels.
  - `height`: The design's height.
  - `fit`: How it fits.
  - `integerScale`: Optional. Whether the design is scaled by a whole number, every design pixel a square block, all alike: the largest that fits, or under `Cover` the smallest that covers. A window smaller than the design shows it smaller, not at a whole multiple. A fit growing the design grows it by whole design pixels, alike on both sides, and what is left is bars. `Stretch` ignores it. Defaults to false.
- `visibleX`: Gets the left edge of the visible area, in design pixels: 0 with no design and under `Keep` and `Stretch`, negative where the fit grows the design across, positive where `Cover` cuts its left edge off.
- `visibleY`: Gets the top edge of the visible area, in design pixels: negative where the fit grows the design down and up, positive where `Cover` cuts its top edge off.
- `visibleWidth`: Gets the visible area's width, in design pixels: the design's, wider where the fit grows it across, narrower where `Cover` cuts it, or the window's logical width with no design.
- `visibleHeight`: Gets the visible area's height, in design pixels: the design's, taller where the fit grows it, shorter where `Cover` cuts it, or the window's logical height with no design.
- `scaleX`: Gets the framebuffer pixels a design pixel spans across.
- `scaleY`: Gets the framebuffer pixels a design pixel spans down; `scaleX` unless the fit is `Stretch`.
- `viewportX`: Gets the left edge of the viewport, where the visible area is shown, in framebuffer pixels.
- `viewportY`: Gets the top edge of the viewport, in framebuffer pixels from the top.
- `viewportWidth`: Gets the viewport's width, in framebuffer pixels.
- `viewportHeight`: Gets the viewport's height, in framebuffer pixels.
- `safeAreaX`: Gets the left edge of the safe area, in design pixels: where a HUD's left edge goes.
  The safe area is the part of the window that no notch, rounded corner or system bar covers (`IWindow.safeAreaX`), here the part of it inside the visible area. On a desktop it is the whole visible area.
- `safeAreaY`: Gets the top edge of the safe area, in design pixels. `safeAreaX` says what the safe area is.
- `safeAreaWidth`: Gets the safe area's width, in design pixels. `safeAreaX` says what the safe area is.
- `safeAreaHeight`: Gets the safe area's height, in design pixels. `safeAreaX` says what the safe area is.
- `toDesignX`: Returns where a framebuffer position across is in design pixels, as the mouse's or a finger's.
  - `x`: The position, in framebuffer pixels from the left.
  - returns: The position in design pixels; outside the visible area on a bar.
- `toDesignY`: Returns where a framebuffer position down is in design pixels.
  - `y`: The position, in framebuffer pixels from the top.
  - returns: The position in design pixels; outside the visible area on a bar.
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

*abstract* in [`libs/services/src/helix/services/screen/ScreenFit.hx`](../src/helix/services/screen/ScreenFit.hx), `import helix.services.screen.ScreenFit;`

Specifies how `Screen` fits its design size to the window. The design is centred in the window under each, and its scale is a whole number when `Screen.integerScale` is set.

- `ScreenFit.Keep`: Scaled as large as it fits whole, keeping its shape; bars fill the rest.
- `ScreenFit.KeepWidth`: Scaled as `Keep` is, then grown down and up to fill a window taller than the design, so more of the world shows above and below; bars beside it on a wider window.
- `ScreenFit.KeepHeight`: Scaled as `Keep` is, then grown across to fill a window wider than the design, so more of the world shows beside it; bars above and below on a taller window.
- `ScreenFit.Expand`: Scaled as `Keep` is, then grown on its short side to fill the window, so more of the world shows on a wider or taller window and there are no bars.
- `ScreenFit.Cover`: Scaled as small as covers the window, keeping its shape; the design's edges past the window are cut off, and there are no bars.
- `ScreenFit.Stretch`: Scaled to fill the window, its shape stretched to the window's.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Keep, KeepWidth): what Std.string, interpolation and trace show.

## ScreenOptions

*class* in [`libs/services/src/helix/services/screen/ScreenOptions.hx`](../src/helix/services/screen/ScreenOptions.hx), `import helix.services.screen.ScreenOptions;`

Represents how `Screen` starts: its design size and how it fits the window.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?designWidth:Int, ?designHeight:Int, ?fit:ScreenFit, ?integerScale:Bool}
```

```haxe
final designWidth:Int = 0
final designHeight:Int = 0
final fit:ScreenFit = Keep
final integerScale:Bool = false
```

- `designWidth`: Gets the design's width, in design pixels; 0, the default, for none: the window's own logical size.
- `designHeight`: Gets the design's height, in design pixels; 0, the default, for none.
- `fit`: Gets how the design fits the window. Defaults to `Keep`.
- `integerScale`: Gets whether the design is scaled by a whole number, every design pixel a square block of framebuffer pixels, all alike, for pixel art. Defaults to false.
