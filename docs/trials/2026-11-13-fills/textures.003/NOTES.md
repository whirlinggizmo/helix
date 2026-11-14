# Notes

## Compile errors
1. `Main.hx:106: Float should be Array<Float>` for `GuiProgressBar(..., health * 100, 0, 100)`. Raygui's `value` is a pointer in
   this binding, so I pass a one-element `Array<Float>` (`healthVal[0] = ...`). That is raygui, not the extras.

Nothing else failed. It compiles, but was not run, so everything below is unchecked.

## Guesses / unsure
- **Health bar skin**: `GuiSkinFromTexture` takes `NPatchInfo`. I used a 3-patch horizontal (`NPATCH_THREE_PATCH_HORIZONTAL`, left/right 16)
  for box and fill, `GUI_SKIN_FILL_CLIPPED` via `GuiSetSkinFillMode(PROGRESSBAR, ...)`, and bar_tip.png as `GUI_SKIN_FILL_EDGE`.
  Unsure whether the fill mode is global to PROGRESSBAR (assumed) and whether the tip's `NPatchInfo` borders of 0 are fine.
  The bar is 192 x 32 on screen, so the 96 x 16 art is scaled 2x. The doc says the fill is "drawn at the control's full size", so I
  assume that is stretched from 96 x 16 to the box, not left at 96 x 16. This is unclear.
- **Skin setup timing**: skins are set once, after the async loads finish (`pending == 0`). `GuiProgressBar`'s text args are `null`.
- **Panel**: `GuiSetSkin(DEFAULT, GUI_SKIN_BASE, ...)` with the rope texture (borders 24), passing `NPATCH_MODE_TILE` for both axes to
  `GuiSkinFromTexture`. Its doc says `DEFAULT` skins are set on every control too, so this also skins other controls
  (the progress bar gets its own base after, hence "set DEFAULT's first"). But the panel skin is set in the rope's load callback, which
  may run after the progress bar's skin is set (callback order isn't specified), which would overwrite the progress bar's base.
  Unclear whether setting DEFAULT overwrites existing control skins.
  Also `GuiSkinFromTexture` accepts `horizontalPatchMode`/`verticalPatchMode` in its signature but, in the source, doesn't pass them on
  to `RGuiSkins.GuiSkinFromTexture` (same for `GuiSkinFromSheet`). That looks like a bug; tiling might silently not happen.
  `DrawTextureNPatchEx` is the alternative, but it's not used here because the panel must be raygui's.
- **Mana ball**: draw the mana fill first, then the glass over it, then froth at `GetTextureFillEdge`'s point. Draw order of glass vs. mana is
  my assumption. Froth is centered on the edge.
- **Cooldown**: grey via `GRAY` tint on the icon (a tint isn't a true greyscale), then `TEXTURE_FILL_CLOCKWISE` over it.
- **Speed gauge**: the gauge texture is only the top half (200 x 100), but a radial fill is about dest's middle. I guessed dest is a
  200 x 200 square (whose top half shows the texture's 200 x 100) and the source is the 200 x 100 texture. Unclear whether the source
  has to be the whole circle, or whether dest's rim/middle apply to the 200 x 100 rectangle (then the middle would be at the half-height).
  Start angle 270 (straight left, since angles run clockwise from up) and 180 degrees sweep. The needle is a line from the middle
  (480, 230) to the edge, at (x, y).
- **Hexagon**: `DrawTexturePoly` with center and 6 points; texcoords are the unit circle mapped to 0..1. Radius 48 = "96 across" (pointy-top).
- **Icons**: `GetTextureAtlasRect` then `DrawTexturePro` from `atlas.texture`. I passed `icons.xml` to `LoadTextureAtlasAsync`.
- **Render texture**: `GetRenderTextureFitRect` with `SetMouseOffset`/`SetMouseScale` to map the mouse. Not sure `integerScale=false` is right
  ("as large as fits" says so), and not sure whether offset is applied before or after the scale.
- **Background**: `DrawTextureTiled` with `scale` 0.5.

## API changes I'd suggest
- Pass `horizontalPatchMode`/`verticalPatchMode` through in `GuiSkinFromTexture` and `GuiSkinFromSheet`.
- Say whether `GuiSetSkinFillMode` is per-control and how it interacts with a `DEFAULT` skin.
- A gauge/half-circle fill that takes the half-circle texture directly (or say how `dest` and `source` relate for radial fills).
- `GuiSkin` is imported from `helix.raylib.extras.GuiSkin`, but it has no file in `api/`; document it.
- `GetRenderTextureFitRect` could offer a helper that sets the mouse offset and scale.
- A greyscale tint/option for the cooldown's grey icon.
