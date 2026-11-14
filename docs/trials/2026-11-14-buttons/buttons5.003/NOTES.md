# NOTES

## Compile errors and fixes
1. `LoadImage: Not supported. Use LoadImageAsync(...)`: loaded the sound button's click mask with `LoadImageAsync`, counted with the textures.
2. `Float should be Array<Float>` on `GuiProgressBar`'s `value`: it's passed by reference, so health and exp are one-element `Array<Float>`s.
   (It then compiled.)

## Guesses / unsure
- **Async loading**: skins are built only after all 12 assets arrive (`LoadTextureAsync` per the doc example); controls aren't drawn until then.
  Unsure whether `GuiSkinFromSheet` needs the texture's size at call time (assumed yes, hence the wait).
- **Sheet args**: `GuiSkinFromSheet(sheet,192,64,16,16,16,20,lip=4,lift=0)`; Quit uses `lift=2`. I assumed `bottom` = 20 includes the 4-texel lip
  (as the doc says "a lip included"). Relied on the generated text offsets for "text moves down when pressed / lifts on hover" and set none by hand.
- **Icons**: used spare icons `ICON_229..231` via `GuiSetIconTexture` and `GuiIconText(id, text)`. Assumed the 24x24 source rect per cell of
  the 72x24 row, and that raygui's default icon scale (1) draws them at 24 px. Whether the button text is centred as icon+text together
  (doc says "aligned together") is unverified; I didn't set text alignment.
- **Quit skin**: `GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin)` right before the Quit `GuiButton`. Unsure whether the once-skin
  covers the text offsets as well as the patches (assumed so; they're in the skin).
- **Options disabled**: `GuiDisable()`/`GuiEnable()` around the button; its disabled cell is drawn with half-faded icon.
- **Bars**: the base is a global `PROGRESSBAR` `GUI_SKIN_BASE`; each bar's fill is set with `GuiSetSkinOnce(..., GUI_SKIN_FILL, ...)`. Health
  uses `GUI_SKIN_FILL_CLIPPED` + `fillEdge = bar_tip`; experience stays stretched with no edge. Patches are `NPATCH_THREE_PATCH_HORIZONTAL` with
  source (0,0,96,16), left/right 16 (top/bottom 0 - unsure whether those must be 0 for that layout). Bars are drawn 96x16 (native size); unsure
  whether a different size was wanted. Bar text args are empty strings.
- "Health goes from 0 to 100 and back over 10 s": read as a 10 s round trip (5 s up, 5 s down). Experience clamps at 100 after 20 s.
- **Sound toggle**: `GuiTextureButton` with `sound_on.png` as click mask (round button ignores corners), for both states. Pressed image shown while held.
  I assumed the mask's alpha rather than the texture decides hit, and that "disabled" with null falls back to normal.
- Positions (button at x 304, bars at y 350/380, sound at top right) are my own layout; "corner" chosen as top right.
- Quit on click does `break` out of the loop.

## API suggestions
- `GuiSkinFromSheet` and `GuiSkinFromTexture` could take the lip/lift on both, and a bare `threePatch` helper (`NPatchInfo` for a capped bar)
  would save the boilerplate of building `NPatchInfo` by hand.
- Document whether `GuiSetSkinOnce` also applies the skin's text offsets, and which part is drawn when the target is disabled.
- A `GuiSetSkins(control, skin)` or sheet-based `GuiSkinFromBar(texture, cap)` for bars would be handy.
- Document whether `GuiProgressBar`'s fill honours `fillEdge` when value equals min (it says yes, half outside the control).
- Texture-based `GuiTextureButton` could take a mask by texture to avoid a separate image load; async-only loading makes the mask awkward.
