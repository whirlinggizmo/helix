# NOTES

## Compile errors and fixes
1. `LoadTexture: Not supported. Use LoadTextureAsync(...)` (11 times). I loaded every texture with `LoadTextureAsync`. A `pending`
   counter runs `setup()` (skins, hexagon) once the last one has arrived, and the loop shows "Loading..." until then.
   I also loaded the atlas with `LoadTextureAtlasAsync`. The sync `LoadTextureAtlas` has no such error, but its doc comment is
   ambiguous about files, so I took the async one to be safe.
2. `GuiProgressBar` `value` is `Float should be Array<Float>`. I pass a one-element array, `healthValue[0] = health * 100`.
   This is raygui's pointer-out-param convention. The extras' docs say nothing about it, and it was not obvious from the task.

## Guesses and uncertainties
- **Fill edge tip**: `GuiSetSkinFillEdge` says "centered on the fill's end". I assumed that end is the right edge of the red at
  `health` of the bar's width, and that the tip draws over the box's own caps. The docs don't say whether the edge is inset by the
  caps, or whether the tip is clipped to the bounds at 0 and 100.
- **`GUI_SKIN_FILL_CLIPPED`**: I assumed this gives the "left cap always shows, right cap only when full" behavior from the doc text
  ("starting end whole, far end only when full"). I assumed the fill is the same size as the box.
- **Bar caps**: I used `NPATCH_THREE_PATCH_HORIZONTAL` with left/right 16 and top/bottom 0 for both bar skins. Under CLIPPED mode
  I don't know whether the fill's nine-patch is drawn at full control width and then cropped, or whether its borders apply to the
  cropped part. I assumed the former.
- **Panel**: `GuiPanel` draws with `DEFAULT`'s `GUI_SKIN_BASE`, so I set the rope skin on `DEFAULT`. That makes every control
  without its own skin (not just the panel) use the rope. I set `PROGRESSBAR`'s skins after, as the docs say. I used
  `NPATCH_MODE_TILE_FIT` for the rope so twists don't get cut at the corner. `NPATCH_MODE_TILE` would cut the last twist. Which of
  the two the task means by "repeating rather than stretching" is a judgement call. `GuiPanel`'s `text` I passed as null, unsure
  whether null is accepted (the sibling docs say "or null").
- **`DrawTextureFill` `dest`**: I took the dest as the *full* widget rectangle (the fill is drawn at dest's size, shown to the
  amount). The source is the full texture. The mana ball doc example does the same.
- **Cooldown**: `TEXTURE_FILL_CLOCKWISE` is said to start straight up, so I used `DrawTextureFill` and not `...Ex`.
- **Gauge**: used `DrawTextureFillEx` with origin (100,100), the bottom middle of dest. `startAngle` is 270 (degrees clockwise from
  up, so 270 is pointing left). `fillDegrees` is 180, the sweep from left, over the top, to right. For the needle I took `edge.z`
  as degrees clockwise from up and converted it to a screen direction as `z - 90`. The edge's x,y is the hub, so the needle runs
  from the hub out along that angle for 90 px. I'm not sure the Ex edge keeps x,y at the origin, or moves out to the rim. The docs
  say "x and y are that point" so I trusted that.
- **Hexagon**: `DrawTexturePoly` takes points in absolute screen pixels. Texcoords are relative to the whole texture. I put the
  hexagon's flat-to-point width at 96 (radius 48, point to point). "96 pixels across" could also mean flat-to-flat. I scaled the
  128 px portrait to 96 px by uv = 0.5 + offset/96, which crops the portrait's outer rim and doesn't shrink it to fit.
  I'm unsure whether `pointCount` is 6 or 7 ("each counted once", polygon closed automatically, so 6).
- **Atlas**: `atlas.texture` is read as a field. `GetTextureAtlasRectangle` is given the name with extension (`sword.png`).
  Kenney XML `SubTexture name` values include the extension, as the doc says.
- **`DrawRenderTextureFit`/`SetMouseRenderTextureFit`**: I called the set once a frame before drawing, with `integerScale` false (the
  task says "as large as fits", not whole multiples).
- **Stone**: `DrawTextureTiled` with scale 0.5, origin (0,0), rotation 0.
- **Layout**: no spec was given, so positions are my own picks. Assets were missing from the folder, so nothing was checked by eye.

## Process slip
A `grep` I ran to find `GuiProgressBar`'s signature went through the installed helix-raylib library (outside this folder) and
printed those files. I should not have. Nothing there was written or used beyond that one signature.

## API changes I'd suggest
- Allow `LoadTexture` (or tell loudly in the extras' docs) that textures load only async. Every extras doc example uses `LoadTexture*`
  loosely. `LoadTextureAtlas`'s doc should say whether it works on this target.
- `GuiSetSkinFillEdge`: say whether the tip is inset, clipped, and drawn above or below the fill.
- `GuiSkinFromTexture` takes five optional args before the modes, so `null, null, null, WHITE` is needed to reach the patch modes.
  A named-options form or a `tileMode` helper would be nicer. A rope-like frame wants one `GuiSkinFromNPatch(texture, info, mode)`.
- A setter that draws a skin on `PANEL` alone: now `DEFAULT` skins every control.
- `DrawTexturePoly` should take a `Vector2` array without a `pointCount`, or give a regular-polygon helper (hexagon, with the texture
  fitted).
- The fill edge for the radial `Ex` should say whether x,y is the hub or the rim, with a rim helper for needles.
- Say in `GuiProgressBar`'s extras section that `value` is an `Array<Float>`.
