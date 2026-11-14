# NOTES

## Compile errors and fixes
1. `LoadTexture: Not supported. Use LoadTextureAsync(...)` — switched to `LoadTextureAsync` with a pending counter; skins/icons are set up
   in `setup()` once all 11 textures have loaded, and the frame loop draws nothing but a blank frame until `ready`.
2. `Float should be Array<Float>` for `GuiProgressBar`'s `value` — raygui's `float *value` is an `Array<Float>` here; passed `[health]`.
   (No raygui header was in docs/include, so I guessed the signature `(bounds, textLeft, textRight, value, min, max)`.)
3. `Type not found : GuiSkin` — `GuiSkins.*` doesn't bring the type; added `import helix.raylib.extras.GuiSkin;`.
4. `Unknown identifier : greySkin` — my own slip (missing `var`).

## Guesses / uncertainties
- **Spare icon ids**: used `ICON_229..231` for Play/Options/Quit with `GuiSetIconTexture(id, icons, Rectangle(24*i,0,24,24))`, then
  `GuiButton(bounds, GuiIconText(ICON_229, "Play"))`. Assumed that `ICON_229` etc. exist as constants in helix-raylib (it compiled).
- **Quit lift**: `GuiSkinFromSheet(..., lip=4, lift=2)` for the quit sheet, so its focused text offset is (0,-4). Used `GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin)` before the Quit call. Unsure whether `Once` also applies to the disabled path (doc says yes).
- Normal buttons: `lift=0`. Passed `lip=4` so text offsets are (0,-2)/(0,2) — I assumed the text-moves-with-face-when-pressed requirement is satisfied by that, not by anything else.
- **Options disabled**: `GuiDisable()`/`GuiEnable()` around the call; the disabled skin cell and the icon halving ("to half in STATE_DISABLED") are assumed automatic.
- **Bars**: a 3-patch horizontal `NPatchInfo(source 0,0,96,16, left 16, top 0, right 16, bottom 0)`; the `top/bottom` values of 0 for a three-patch are a guess. Grey is the global `PROGRESSBAR`/`GUI_SKIN_BASE`; red and blue go in via `GuiSetSkinOnce(PROGRESSBAR, GUI_SKIN_FILL, ...)` per call. Red: `GUI_SKIN_FILL_CLIPPED` + `fillEdge = bar_tip`; blue: default stretched, no edge.
  Unsure whether the clipped fill's left cap shows at value 0 (the task says always) and whether the tip is drawn at 0 (doc says yes, at every value, half outside the control).
- **Bar size**: drew bars at their native 96 x 16; the task doesn't give the on-screen size.
- **Sound toggle**: `GuiTextureButton(bounds, normal, null, pressed)` — focused omitted (falls back to normal), and no `clickMask` passed (task says "round" so I could pass an Image mask, but that needs an Image load; skipped, so corners respond to clicks). `pressed` is the "held" image, as I read it.
- Experience clamps to 100 after 20 s rather than looping; health ping-pongs 0→100→0 over 10 s.
- Ordering of `GuiSetSkin` calls: only BUTTON and PROGRESSBAR set, so DEFAULT-order concerns don't arise.

## API suggestions
- `GuiSkins.*` should make `GuiSkin` reachable without a second import, or the docs should say so up front.
- A `GuiSkinFromThreePatch(texture, source, left, right)` helper (bars with caps) would avoid hand-built `NPatchInfo` and the guessed top/bottom values.
- `GuiSetSkinOnce` for fill skins on the same control is awkward; a `GuiProgressBar` skin per call, or a skin bundle for base+fill+edge, would be clearer.
- `GuiTextureButton`'s `clickMask` takes an `Image`, forcing an extra CPU load beside a texture; a Texture-derived or alpha-threshold option would help.
- Say whether `GuiSetIconTexture`'s text offset applies to the icon, and whether a skin's `fillEdge` is drawn when the value is at the minimum for CLIPPED mode (doc says yes, which conflicts with "left cap always showing" only at the edge; the tip then sits over the left cap at 0).
- Doc for `GuiSkinFromSheet` doesn't say how `lip` interacts with `bottom`; I assumed bottom (20) includes the 4 lip.
