# Screen

[Back to the library](README.md)

## Screen

*class* in [`engines/raylib/src/helix/raylib/extras/Screen.hx`](../src/helix/raylib/extras/Screen.hx), `import helix.raylib.extras.Screen;`

Provides a design size for the screen, fitted to the window: a program draws in the design's pixels whatever the window's size, with Godot's stretch modes and aspects. Imported apart, with its constants: `import helix.raylib.extras.Screen.*;`.

```haxe
InitWindow(1280, 720, "fitted");
SetScreenFit(640, 360, SCREEN_STRETCH_VIEWPORT, SCREEN_FIT_KEEP, true);
while (!WindowShouldClose()) {
BeginDrawing();
ClearBackground(BLACK);
DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), DARKBLUE); // the whole design, 640 x 360
EndDrawing();
}
```

With a fit set, `GetScreenWidth` and `GetScreenHeight` return the design's size, and everything drawn between `BeginDrawing` and `EndDrawing` is drawn in the design's pixels. The design is centred in the window under every fit. A fit showing more than the design (`SCREEN_FIT_KEEP_WIDTH`, `SCREEN_FIT_KEEP_HEIGHT`, `SCREEN_FIT_EXPAND`) shows more around the design, at negative coordinates and past the design's size. A fit showing less (`SCREEN_FIT_COVER`) crops the design's edges. `GetScreenVisibleArea` returns what is shown, and a HUD anchored to the window's edges lays out in it. Bars where nothing is shown are black, or the color `SetScreenFitBarColor` sets.

The safe area (`GetWindowSafeArea`, the Device extra) is in the design's pixels too, inside the visible area. The mouse and touch positions (`GetMousePosition`, `GetTouchPosition`) and raygui's controls read in the design's pixels, outside the design where the pointer is. `TakeScreenshot` saves the window, bars and all, at its own size. Without a fit, the screen is the window, in its own pixels, as in raylib.

- **When:** a fit is set or cleared at any time after `InitWindow`. `GetScreenWidth` and the pointer read in it at once, and drawing from the next `BeginDrawing`. Each frame it is fitted to the window as it is then.
- **Orientation:** a device turned is a window resized, and the fit follows it. A game with a layout for each orientation sets a design for each when `IsWindowResized` is true, and one with a single layout holds the orientation with the Device extra.
- **3D:** `BeginMode3D` projects at the visible area's shape, and `GetScreenToWorldRay` and `GetWorldToScreen` read in the design's pixels. A visible area taller or shorter than the design shows a camera's framing changed unless the program sets `camera.fovy = GetScreenFitFovy(fovy)`.
- **Text:** under `SCREEN_STRETCH_CANVAS`, the default font's and a TrueType or OpenType font's glyphs are made at the size they are shown, so text is sharp at any scale. They are kept on one texture, 512 x 512 at first and at most 2048 x 2048. A font made from an image or glyphs a program made is drawn from its own texture, scaled.
- **High DPI:** the design is fitted to the framebuffer, in its pixels (`GetRenderWidth`), which a high-DPI window has more of than its logical size (`GetWindowScaleDPI`). The pointer is mapped through that scale, so the design pixel under it is the one read.
- **Render textures:** between `BeginTextureMode` and `EndTextureMode`, drawing is in the render texture's own pixels, as in raylib, untouched by the fit.

```haxe
static inline var SCREEN_STRETCH_CANVAS:Int
static inline var SCREEN_STRETCH_VIEWPORT:Int
static inline var SCREEN_FIT_NONE:Int
static inline var SCREEN_FIT_KEEP:Int
static inline var SCREEN_FIT_KEEP_WIDTH:Int
static inline var SCREEN_FIT_KEEP_HEIGHT:Int
static inline var SCREEN_FIT_EXPAND:Int
static inline var SCREEN_FIT_COVER:Int
static inline var SCREEN_FIT_STRETCH:Int
```

- `SCREEN_STRETCH_CANVAS`: Draws in the design's coordinates at the window's resolution: lines, text and edges sharp at any size, a texture scaled as drawn. Godot's `canvas_items`.
- `SCREEN_STRETCH_VIEWPORT`: Draws the frame at the design's size, then shows that picture scaled: every pixel a block, a sprite turned or placed between pixels kept on the design's grid, as pixel art wants. Godot's `viewport`.
- `SCREEN_FIT_NONE`: No fit: the screen is the window, in its own pixels. Returned by `GetScreenFit` alone. Godot's `disabled`.
- `SCREEN_FIT_KEEP`: Keeps the design's shape, as large as it fits whole, with bars above and below or beside it. Godot's `keep`.
- `SCREEN_FIT_KEEP_WIDTH`: Keeps the design's width: a window taller than the design shows more above and below, a wider one has bars beside it. Godot's `keep_width`.
- `SCREEN_FIT_KEEP_HEIGHT`: Keeps the design's height: a window wider than the design shows more beside it, a taller one has bars above and below. Godot's `keep_height`.
- `SCREEN_FIT_EXPAND`: Shows the design whole with no bars, and more around it on the window's longer side. Godot's `expand`.
- `SCREEN_FIT_COVER`: Keeps the design's shape, as small as covers the window, with no bars: the design's edges on the window's longer side are cut off. Phaser's envelop and CSS's cover.
- `SCREEN_FIT_STRETCH`: Fills the window, the design stretched to its shape. Godot's `ignore`.

### screen: a design size fitted to the window

```haxe
static function SetScreenFit(designWidth:Int, designHeight:Int, stretch:Int, fit:Int, integerScale:Bool):Void
static function ClearScreenFit():Void
static function SetScreenFitBarColor(color:Color):Void
static function GetScreenFitBarColor():Color
static function GetScreenFit():Int
static function GetScreenStretch():Int
static function IsScreenFitIntegerScale():Bool
static function GetScreenFitScale(?out:Vector2):Vector2
static function GetScreenVisibleArea(?out:Rectangle):Rectangle
static function GetScreenFitRectangle(?out:Rectangle):Rectangle
static function GetScreenFitFovy(fovy:Float):Float
```

- `SetScreenFit`: Sets the screen's design size and how it fits the window, until `ClearScreenFit`. A size under 1, or a stretch or fit that isn't one of the constants, `SCREEN_FIT_NONE` included, is refused with a warning, changing nothing.
  - `designWidth`: The design's width, in its pixels.
  - `designHeight`: The design's height, in its pixels.
  - `stretch`: How it is drawn (`SCREEN_STRETCH_*`).
  - `fit`: How it fits (`SCREEN_FIT_*`).
  - `integerScale`: Whether the design is shown at a whole multiple of its size: the largest at which it fits, or under `SCREEN_FIT_COVER` the smallest at which it covers. Under `SCREEN_STRETCH_VIEWPORT` every design pixel is then a square block, all alike. A window smaller than the design shows it smaller, not at a whole multiple. Under `SCREEN_STRETCH_CANVAS` the coordinates are scaled by a whole number, and drawing is still at the window's resolution. A fit showing more than the design shows more by whole design pixels, and what is left is bars. `SCREEN_FIT_STRETCH` ignores it. Godot's `integer` scale mode.
- `ClearScreenFit`: Clears the design size: the screen is the window again, in its own pixels.
- `SetScreenFitBarColor`: Sets the color of the bars where the window shows nothing of the screen, under every fit from the next frame. Black until set. Its alpha shows what is behind the window only in a transparent window (`FLAG_WINDOW_TRANSPARENT`): `BLANK` there shows the page or the desktop through the bars. Elsewhere the bars are opaque.
  - `color`: The color.
- `GetScreenFitBarColor`: Returns the color of the bars (`SetScreenFitBarColor`).
  - returns: The color: `BLACK` until set.
- `GetScreenFit`: Returns how the screen fits the window.
  - returns: A `SCREEN_FIT_*`: `SCREEN_FIT_NONE` without a fit.
- `GetScreenStretch`: Returns how the design is drawn.
  - returns: A `SCREEN_STRETCH_*`: `SCREEN_STRETCH_CANVAS` without a fit.
- `IsScreenFitIntegerScale`: Returns whether the design is shown at a whole multiple of its size (`SetScreenFit`'s `integerScale`): false without a fit.
  - returns: True at a whole multiple.
- `GetScreenFitScale`: Returns how many framebuffer pixels show one design pixel, across and down: alike but under `SCREEN_FIT_STRETCH`, and a whole number under integer scale. Without a fit, the window's DPI scale.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The scale.
- `GetScreenVisibleArea`: Returns what the window shows, in the design's pixels: the design itself under `SCREEN_FIT_KEEP` and `SCREEN_FIT_STRETCH`, more around it under `SCREEN_FIT_KEEP_WIDTH`, `SCREEN_FIT_KEEP_HEIGHT` and `SCREEN_FIT_EXPAND` (its `x` or `y` negative), less under `SCREEN_FIT_COVER`. A HUD anchored to the window's edges lays out in it. Without a fit, the whole screen.
  - `out`: Optional. The rectangle to fill; a new one when omitted.
  - returns: The visible area.
- `GetScreenFitRectangle`: Returns where the visible area is shown in the window, in framebuffer pixels as `GetRenderWidth` measures them: the window less its bars. Without a fit, the whole window.
  - `out`: Optional. The rectangle to fill; a new one when omitted.
  - returns: The rectangle.
- `GetScreenFitFovy`: Returns the vertical field of view that keeps a 3D view framed under the fit: from the `fovy` a camera was framed with at the design's shape, the `fovy` showing the same at the visible area's shape now. It is wider where the visible area is taller than the design, under `SCREEN_FIT_KEEP_WIDTH` and `SCREEN_FIT_EXPAND`, narrower where `SCREEN_FIT_COVER` cuts the design's top and bottom off, and `fovy` itself otherwise and without a fit.
  - `fovy`: The vertical field of view at the design's shape, in degrees.
  - returns: The vertical field of view at the visible area's shape now, in degrees.

  ```haxe
  camera.fovy = GetScreenFitFovy(36);
  ```
