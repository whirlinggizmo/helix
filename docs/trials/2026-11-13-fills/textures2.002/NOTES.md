# Notes

## Compile errors
None: `haxe build.hxml` compiled the first time. (Not run; there is no `assets/` folder here, so the paths are untested.)

## Guesses / unsure
- **Doc example is stale**: `Textures`'s class comment calls `DrawTextureFill(liquid, src, ball, ...)` fine, but `GetTextureFillEdge(ball, mana, dir)` there
  passes a texture-less `ball` first, which matches the signature; the glass is drawn with `DrawTexturePro` using a 64x64 source. OK, but it
  does not say whether the fill's `source` should be the whole texture when `dest` is the same size (I used the whole 128x128).
- **Radial `center` (`DrawTextureFillEx` / `GetTextureFillEdgeEx`)**: "in pixels" doesn't say if it is relative to `dest` or absolute on screen.
  I guessed relative to dest's top-left (hub at 100,100 for the 200x100 gauge). Same question for the returned edge x,y: I treated them as screen pixels.
- **Gauge angles**: half circle left to right over the top = `startAngle -90`, `fillDegrees 180`, `TEXTURE_FILL_CLOCKWISE`. Assumed
  "degrees clockwise from straight up" so -90 is the left end. Needle drawn from the edge's (x,y) (the hub) along angle z; the doc says x,y are
  the center for radial fills, so the needle is my own line of length 90, not a texture.
- **Hub of the gauge image**: the 200x100 texture is the top half, so I took the hub at the bottom middle of the image.
- **Clockwise fill on a square icon**: assumed starts at twelve o'clock with the default center (middle) and full sweep.
- **Rope panel**: used `NPATCH_MODE_TILE_FIT` on both axes (whole twists, no cut tile) instead of `TILE`. Passed `null` for focused/pressed/disabled
  of `GuiSkinFromTexture`. The `NPatchInfo` is built with a struct literal (`layout: NPATCH_NINE_PATCH`), assuming the field names mirror raylib's.
- **`DEFAULT` skin is inherited by every control**, so `PROGRESSBAR` is set after it, as the doc says. Unsure if skinning `DEFAULT` also
  re-skins the progress bar's box if I forget a part (FILL falls back to?).
- **Progress bar**: `GuiSkinFromSheet(tex, 96, 16, 16, 0, 16, 0)` for a single-cell image (a sheet "less than two cells high" runs left to right, so
  one cell is fine). With `GUI_SKIN_FILL_CLIPPED` the left cap always shows and the right only at full, as the task wants. `GuiSetSkinFillEdge(PROGRESSBAR, tip)` is
  drawn "centered on the fill's end"; unclear whether the tip is also drawn at 0% (doc says every value) which would show a tip on an empty bar.
- **`GuiProgressBar` value**: raygui takes `float*`; I guessed `Array<Float>` (`health`) and it compiled. Value range 0..100 via min/max.
- **Panel**: `GuiPanel(bounds, null)` for no title text.
- **Skins applied after loading**: textures load via `LoadTextureAsync`; skins are set once all 12 loads call back (the skin needs the loaded texture).
  Unsure whether `LoadTexture` sync would work on this JS target. Atlas loaded via `LoadTextureAtlasAsync`.
- **Atlas names**: I assume `names` holds `sword.png` etc., with extensions, as `GetTextureAtlasRect` says.
- **Mouse**: `SetMouseRenderTextureFit` called every frame before drawing; `integerScale` false (aspect kept, 1280x720 is a 2x anyway).
- **Hexagon UVs**: texcoords scaled by 96/128 so the portrait is not squeezed (the 128 image sits 1:1 in a 96 hexagon); unsure if the poly is
  expected to span the whole texture.
- `DrawTexturePoly` takes `pointCount` plus arrays; I pass 6 and the arrays' lengths agree, unclear if the array should repeat the first point.

## API changes I'd make
- Say in the docs whether radial `center` and returned edge are relative to `dest` or absolute.
- Give `GuiSkinFromTexture` a helper for a single image with borders (like `GuiSkinFromSheet` with one cell), and an NPatchInfo builder.
- Let `DrawTexturePoly` infer `pointCount` from the arrays and say if the first point repeats.
- Add a gauge-friendly radial preset (half circle left-to-right) and a needle draw.
- Document what the fill edge does at an amount of 0.
- Fix `DrawTexturePro`'s example in the `Textures` comment (it uses a 64x64 source) so it reads as a fill example for any size.
