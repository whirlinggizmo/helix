# NOTES

## Compile errors
1. `LoadImage: Not supported. Use LoadImageAsync(...)` (for the sound button's click mask). Changed to
   `LoadImageAsync("assets/sound_on.png", i -> soundMask = i)`. Until it loads, `soundMask` is null, so the whole rectangle answers.
No other errors; `haxe build.hxml` compiles cleanly. Not run.

## Guesses / uncertainties
- **Icon ids:** I used the spare icons `ICON_229/230/231` for triangle/gear/door via `GuiSetIconTexture(id, icons, source)` with
  sources (0,0,24,24), (24,0,...), (48,0,...), and `GuiIconText(id, "Play")` as the button text. I assumed `GuiSetIconScale` default
  is 1 so the icons draw at 24 x 24, and that the text really goes after the icon, not over it.
- **GuiSkinFromSheet args:** `(sheet, 192, 64, left 16, top 16, right 16, bottom 20, lip 4, lift 0)`. Border order is left, top, right,
  bottom per the signature; the task's "16 at sides and top, 20 at bottom" mapped to that. I relied on `lip` to set the text offsets
  (text moves down with the pressed face) rather than setting the `*TextOffset` fields by hand. Unsure whether the pressed offset
  (0, +lip/2 = 2) matches "text moves down with its face" (face drops 4 texels, but the centering offset goes from -2 to +2, i.e. 4: so fine).
- **Quit hover lift:** `lift = 2` for button_quit; I trust that the focused text offset becomes (0, -lip/2 - lift) = (0, -4).
- **Quit skin:** applied with `GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin)` immediately before the Quit `GuiButton`. It is null until the
  async load finishes, which per the doc draws that button flat for those frames. It's unclear whether `Once` is consumed by a
  disabled call or by a call outside the right control; I set it right before each use.
- **Disabled Options:** `GuiDisable()`/`GuiEnable()` around the call; assumed this picks the skin's disabled cell, dims the icon texture
  to half, and `GuiButton` returns 0.
- **Sound toggle:** `GuiTextureButton(bounds, normal, focused=normal, pressed, null, clickMask)`. I passed the normal texture as
  focused explicitly (omitting works too per docs). The mask is the normal "on" image, used for both states (assumed the off image
  has the same circle). Drawn in the top-right corner at 48 x 48 with a 10 px margin. It is the only place skins are drawn in `STATE_*` without text.
- **Async loads:** I don't know when callbacks fire (probably during a frame); the main skin is set from a callback, so the first frames draw flat.
  The sound button is skipped until all four textures are loaded.
- **Quit:** I call `CloseWindow()` then return from main on click, instead of tracking a quit flag.
- **Sound state:** only toggles the flag; no audio is used.

## API suggestions
- `GuiSkinFromSheet`'s border order (left, top, right, bottom) differs from raylib's NPatchInfo (left, top, right, bottom is the same, but
  CSS is top/right/bottom/left); a doc line stating it explicitly is good, which exists in the params, fine. A named-parameter form would help.
- Document whether `GuiSetSkinOnce` with a null skin counts as set, and whether a disabled/hidden control consumes it.
- Provide a skin-less way to say "this icon on the left, text after" order, and say the icon scale default (`GuiSetIconScale`).
- A `GuiSetSkin` taking sheets directly (`GuiSetSkinFromSheet`) would remove the boilerplate of async callbacks; some way to know when
  the skin is ready (or accept a `Texture` placeholder) would avoid the flat frames.
- `lip`/`lift` doc says the pressed text offset is `lip / 2`, while the GuiSkin doc example says (0, 2) for a 4 lip: consistent, but
  the GuiSkin doc for `normalTextOffset` mentions (0, -2) as an example without saying lip does it automatically.
- `GuiTextureButton`'s `clickMask` takes an `Image` (needs `LoadImageAsync`); accepting a Texture or an alpha-threshold would be easier.
