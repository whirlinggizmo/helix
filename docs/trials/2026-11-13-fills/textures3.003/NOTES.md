# NOTES

## Compile errors and fixes
1. `LoadTexture: Not supported. Use LoadTextureAsync(...)` (11 times). Every texture is now loaded with `LoadTextureAsync`, and the atlas with `LoadTextureAtlasAsync`. A `pending` counter counts down as they load, and the frame loop draws only black until it reaches 0.
2. `GuiProgressBar`'s `value` is `Float should be Array<Float>`. It takes a one-element array (raygui's `float*`), so I keep `healthValue = [0.0]` and set `healthValue[0]` each frame.

Everything else compiled first time. Nothing was run, and the `assets/` directory doesn't exist here.

## Guesses and uncertainties
- **Skins are set after the textures load**, inside the loop on the first ready frame, because `GuiSkinFromTexture` needs loaded `Texture2D`s. The docs don't say whether a skin may be built from a texture that isn't loaded yet.
- **The loop shape is a guess.** I used `while (!WindowShouldClose())` on a JS target and don't know whether that yields to the event loop so the async loads can finish. It may need a frame callback. The docs for the extras don't say.
- **Panel:** `GuiPanel` draws its body with `DEFAULT`'s `GUI_SKIN_BASE`, so the rope frame goes there, and `NPATCH_MODE_TILE` is set both ways so the twists repeat. I picked `TILE` over `TILE_FIT`. `TILE` cuts the last tile, `TILE_FIT` scales each tile slightly. The task says "repeating rather than stretching", so I chose the unscaled one. Setting a skin on `DEFAULT` also sets it on every control, so I set `DEFAULT` first and `PROGRESSBAR` after. This is why skinning the panel at all is a trap: the progress bar would otherwise get the rope.
- **Progress bar:** `GuiSkinFromTexture` takes an `NPatchInfo`, not the texture's size. I used a three-patch horizontal layout with left and right borders of 16 and top and bottom of 0. `NPATCH_THREE_PATCH_HORIZONTAL` vs `NPATCH_NINE_PATCH` with zero top and bottom borders: I'm not sure which `GuiSkins` expects. I assumed that with `GUI_SKIN_FILL_CLIPPED` the red is stretched over the whole bar and clipped, giving the left cap always and the right cap only when full, as the task wants. `GuiSetSkinFillEdge` draws the tip centered on the end of the fill. I assumed it is drawn over the bar's rectangle, not clipped to it.
- **Progress bar range:** I assumed the fill amount is `(value - min) / (max - min)`, so 0 to 100 is passed as is.
- **Mana ball:** followed the doc example. `GetTextureFillEdge` returns the edge's center in the same pixel space as `dest`, so froth is centered on it with `DrawTexture`. I'm not sure the froth should be centered vs sit on top of the surface. Centered looks right for "riding on".
- **Cooldown:** `TEXTURE_FILL_CLOCKWISE` with `DrawTextureFill`, which the docs say starts straight up (twelve o'clock). The grey base is `DrawTexturePro` tinted `GRAY`. I assumed that darkens the icon without desaturating it. There's no real grey-scale draw, so this is only an approximation.
- **Speed gauge:** `DrawTextureFillEx` with the origin at the bottom middle of the dial (100, 100, from dest's top-left), start angle 270 (straight up is 0, clockwise, so 270 is pointing left) and sweep 180. The gauge is 200 x 100 and dest is the same size. I wasn't sure whether `fillDegrees` is also the fill's end for amount 1 (I assumed so). The needle is drawn from the edge's `x, y` (the hub), using `z` as an angle. I converted the angle to radians as `(z - 90)`, since `z` is clockwise from up and screen angles run clockwise from right. The needle is a line of 90 px from the hub. Note that it's the "hub" and not the "revealed edge" that `x, y` return for radial fills, as the doc says: "x and y are that point". That's a doc subtlety that's easy to read the other way.
- **Where each is drawn:** the dest rectangles are in the render texture's 640 x 360 pixels. I picked the layout myself.
- **Portrait:** `DrawTexturePoly` with `center` at the hexagon's middle and the six points at radius 48 (so 96 across, corner to corner). Texcoords are `0.5 + 0.5 * unit`. The doc says `center` is "drawn with the texture's middle", so I assumed (0.5, 0.5) for the center's texcoord. The hexagon has a vertex pointing right (flat top).
- `pointCount` is 6 as the points are "each counted once", and I assumed the first point isn't repeated at the end.
- **Background:** `DrawTextureTiled`, source the whole 64 x 64, scale 0.5, origin and rotation zero.
- **Icons:** `GetTextureAtlasRectangle(atlas, "sword.png")`, with the extension, as the docs say. Drawn from `atlas.texture` at 48 x 48. I don't know the sheet's cell size, so this scales them.
- **Fit:** `SetMouseRenderTextureFit` is called each frame and `integerScale` is false, as "as large as fits" suggests. 1280x720 over 640x360 is exactly 2x anyway.

## API changes I'd suggest
- Have `GuiSkinFromTexture` offer a short form for a plain three-patch or nine-patch (borders only), so the source rectangle and layout needn't be built by hand.
- Document `GuiProgressBar`'s value as an array, or give it a `Float` overload. A one-element array is awkward in Haxe.
- A radial `GetTextureFillEdge` returning the hub in `x, y` is surprising when the caller wants the edge point on the arc. Add a radius-taking variant or return the point on the rim.
- Say how a gauge's half circle is set up with `DrawTextureFillEx` (a worked example with `origin`, `startAngle` and `fillDegrees`).
- A grey / desaturated tint option for `DrawTextureFill` (cooldown icons are common), or a documented way to get the grey base.
- Say in `GuiSkins` whether a skin may be set before a texture loads, and how an async load is meant to be sequenced with it. The `GuiSkins` example uses `LoadTextureAsync` but shows no wait.
- `LoadTexture` fails at compile time on JS, which is helpful, but the docs for the extras could say so up front.
