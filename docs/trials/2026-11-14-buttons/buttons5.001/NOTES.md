# Notes

## Compile errors hit
1. `LoadImage: Not supported` — used `LoadImageAsync("assets/sound_on.png", i -> soundMask = i)` instead (for the click mask).
2. `GuiProgressBar` `value` wanted `Array<Float>` (raygui's `float*`), not `Float` — pass one-element arrays.

## Guesses / unsure
- `NPatchInfo` built as a struct literal (source/left/top/right/bottom/layout); it compiled.
- Bars: `GuiSkinFromTexture` with a `NPATCH_THREE_PATCH_HORIZONTAL` patch (96x16, caps 16). Grey is PROGRESSBAR `GUI_SKIN_BASE`; red is `GUI_SKIN_FILL` with `fillMode = GUI_SKIN_FILL_CLIPPED` and `fillEdge = bar_tip`. Blue is applied only for the experience bar with `GuiSetSkinOnce(PROGRESSBAR, GUI_SKIN_FILL, ...)` immediately before that call. Unsure whether `Once` is consumed by the *call* even when the skin is null/ignored, and whether it applies to the BASE part too (I assumed only the part named).
- Unsure how "the filled part" is computed for the clipped mode (whole control width vs. inside the caps), and where the tip is centered when value is 0/100 (doc says half outside the control).
- Icons: used spare `ICON_229..231` with source rects into icons.png; assumed `GuiIconText(id, text)` then places the text after the texture. Assumed the icon texture is laid out at 24x24 (scale 1).
- Quit skin via `GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin)` before its call; icon/text offset is from `GuiSkinFromSheet` lip=4, lift=2. Unsure the text offset comes from the Once skin rather than the set skin.
- Options disabled with `GuiDisable()/GuiEnable()`; assumed that selects the disabled cell and half-fades the icon.
- Sound toggle: `GuiTextureButton` with `focused = null` (falls back to normal) and the normal image as `clickMask`. Whether the mask image is read once or per call, and whether it must stay alive, isn't stated. Pressed state: assumed "pressed" texture is shown while held.
- The progress-bar bounds (96x16) equal the texture size; the task didn't give an on-screen size.
- Health is a triangle wave of period 10 s (0→100→0 over 10 s); I read "and back over 10 seconds" as the round trip.
- Textures load async, so controls draw flat/unskinned for the first frames; `GuiSetSkin` inside callbacks is assumed safe.
- `assets/` isn't present in the directory, so nothing was run.

## API changes I'd suggest
- Let `GuiSkinFromSheet` take the NPatch borders as a small struct, or document the argument order (left, top, right, bottom) more prominently; and a `GuiSkinFromTexture`-style helper for a horizontal bar (`GuiSkinBar(texture, cap)`), since building `NPatchInfo` by hand is verbose.
- Say whether `GuiSetSkinOnce` is consumed by a call when the control is a different kind, and which part's text offsets it uses.
- A `fillEdge` setter in a constructor, rather than mutating the returned skin.
- Document the `Texture2D`/`Image` lifetime of `clickMask`, and whether `GuiTextureButton` could take a disabled/focused fallback explicitly.
- Allow `GuiProgressBar` to take a plain Float (the array value is awkward) — that's raygui's, not the extra's.
