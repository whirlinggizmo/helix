# NOTES

## Compile errors
1. `Main.hx:84 Float should be Array<Float>` for `GuiProgressBar(..., health, 0, 100)`. The Haxe binding takes the value as a
   one-element array (C's `float*`). Changed to `[health]`. (That is raygui, not the two extras.) It then compiled.

## Guesses / unsure
- **Asset files missing**: `assets/` doesn't exist, so nothing was checked against real images; sizes come from task.md.
- **Main loop**: I wrote a plain `while (!WindowShouldClose())` loop with async loading. On a JS target a blocking loop may never yield to
  the browser, so async loads would never finish. I didn't know whether helix-raylib's portable sys handles this. Not verifiable here.
- **Async loading**: used `LoadTextureAsync` / `LoadTextureAtlasAsync` and a pending counter; skins are set once everything has loaded
  (skins need the textures). `LoadTexture` (sync) might work too, but the docs only show the async one.
- **NPatchInfo**: built with `new NPatchInfo(source, left, top, right, bottom, layout)` (positional, raylib's field order). For the bar
  caps I used `NPATCH_THREE_PATCH_HORIZONTAL` with left/right 16 and top/bottom 0; I wasn't sure whether the skin code wants
  `NPATCH_NINE_PATCH` with 0 top/bottom instead. `GuiSkinFromSheet` can't be used for the bar (one cell per state, but the
  grey and red bars are separate files), so `GuiSkinFromTexture` it is.
- **Health bar**: `GUI_SKIN_FILL_CLIPPED` is the thermometer mode (left cap always, right cap only when full) and
  `GuiSetSkinFillEdge(PROGRESSBAR, barTip)` the tip. Unsure whether the tip is drawn above the fill clipped to the box or may overhang
  it; at 0 health the doc says it still draws "at every value", so the tip sits at the left end then. The box is 192 x 16 (twice the
  texture) and I assumed the caps stay 16 texels wide, not scaled.
- **Skin order**: `DEFAULT` set first, then `PROGRESSBAR` (as documented). Does a `DEFAULT` skin also skin the progress bar's box
  until overridden? Documented as yes; I override it.
- **Panel**: `GuiPanel` draws `DEFAULT`'s `GUI_SKIN_BASE`; tiling via the skin's `NPATCH_MODE_TILE` on both axes. I chose TILE over
  TILE_FIT; for "twists repeating rather than stretching" either fits, TILE_FIT avoids a cut twist at a corner. Unsure which is wanted.
  Should the panel's `text` be null or ""? I passed null.
- **Mana ball**: `DrawTextureFill` with `BOTTOM_TO_TOP`; froth centered on `GetTextureFillEdge` (its y is the surface, x the middle of the
  fill, assumed to be in the same screen pixels as dest). The doc example uses a 64 px source; mine is 128. Whether froth is drawn
  over or under the glass isn't specified; I drew it last.
- **Cooldown**: grey via `GRAY` tint on the whole icon, then color drawn with `TEXTURE_FILL_CLOCKWISE`. Assumed grey = a tint, not a
  desaturated asset.
- **Gauge**: `DrawTextureFillEx` with origin (100,100) (dest-relative bottom middle), startAngle 270 (= left, clockwise from up),
  fillDegrees 180. The needle uses `GetTextureFillEdgeEx`'s x,y (the hub) and z (angle), and I draw a line of length 90 from the hub
  along the angle; the edge's "middle" point for a radial fill is thus the hub, not a point on the arc, per the doc. Whether
  the texture is positioned so the dial's hub is at the dest's bottom middle is assumed. A negative `origin`/`dest` mismatch isn't checked.
- **Portrait**: `DrawTexturePoly` with center (cx, cy), 6 points at radius 48 (pointy-top hexagon), texcoords from the circle of radius 0.5
  around (0.5, 0.5). "96 across" taken as point-to-point; flat-to-flat would be ~83. `pointCount` = 6 (the polygon isn't repeated
  with the first point at the end).
- **Atlas**: `LoadTextureAtlasAsync("assets/icons.xml")` per the doc ("texture is the file the atlas names, beside it"). Names include `.png`.
  `GetTextureAtlasRectangle` allocates a new Rectangle each frame; I could pass `out` to reuse.
- **Mouse**: `SetMouseRenderTextureFit(target, false)` each frame, non-integer since the window is 2x exactly and the task says
  "as large as fits". It's called before drawing the scene so raygui sees it. The task's mouse requirement matters only for hover.
- **Background**: `DrawTextureTiled(... scale 0.5)`, scale as "a multiple of source's" size.

## API changes I'd make
- `GuiProgressBar` value as `Array<Float>` is awkward; a `Float`-returning variant would be nicer.
- State that fill edge coordinates are relative to screen/target pixels (not dest-local) for the radial case, and where a radial
  `origin` of the hub puts the edge's x/y explicitly.
- `GuiSetSkinFillEdge`: say whether the tip is clipped to the control.
- A `NPatchInfo` helper (e.g. `NPatchHorizontal(src, left, right)`) would remove guessing at layouts.
- Mention whether sync `LoadTexture` is allowed when the atlas/texture is a file, and how a JS main loop should be structured.
- A `Textures` "hexagon/regular polygon" helper that builds points and texcoords for `DrawTexturePoly`.
