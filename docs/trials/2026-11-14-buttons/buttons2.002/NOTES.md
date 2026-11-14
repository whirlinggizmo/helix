# Notes

## Compile errors
None. `Main.hx` compiled on the first try (`haxe build.hxml`, no output). I then made one edit (keep the skins in my own
variables instead of reading them back with `GuiGetSkin`) and it compiled again.

## Guesses / unsure
- **Skin per button.** `BUTTON`'s base skin is global, so for Quit I call `GuiSetSkin(BUTTON, GUI_SKIN_BASE, quitSkin)` just before
  its `GuiButton` and put the normal skin back after it (the doc says a skin swapped around one call affects that call alone).
  Unsure whether that is the intended way to give one button a different skin; a per-call skin parameter would be clearer.
- **Skin fields after creation.** I set `pressedTextOffset` / `focusedTextOffset` on the object `GuiSkinFromSheet` returns, before
  `GuiSetSkin`. I assumed the skin is read by reference at draw time and not copied at `GuiSetSkin`. I didn't rely on `GuiGetSkin`
  returning the same object. The sheet-based constructor can't take text offsets, so they have to be patched on afterwards.
- **Text offset for the raised face.** Text is "placed in its bounds as raygui places it", so it is centred over the whole 64-tall
  button, lip included. I didn't offset the normal state, so the text sits about 2 px lower than the centre of the face. The
  skin has no normal-state text offset (only focused, pressed, disabled), so I couldn't correct this. Are the offsets relative to
  raygui's placement (so Quit's focused (0,-2) is added on top of normal) or to the normal state? I assumed relative to raygui's
  placement, hence the focused offset (0,-2) for Quit's 2 texel lift and pressed (0,4) for the 4 texel push.
- **Pressed face.** I assumed the pressed cell's artwork already shows the face pushed down, so only the text needs
  `pressedTextOffset`.
- **Icons.** I used the spare icons `ICON_229`..`ICON_231` with `GuiSetIconTexture(id, icons, Rectangle(i*24, 0, 24, 24))` and
  `GuiIconText(id, text)`. Assumed the icons are drawn at 24x24 (scale 1) and the text is shifted after them, as documented. Unsure
  how the icon-plus-text pair is aligned in the button (centred as a group, I assumed). Disabled Options halves the icon's alpha.
- **Async loading.** `LoadTextureAsync` callbacks run at an unspecified time, so the skins and sound textures are null until
  loaded. Until then buttons draw flat (no skin) and the sound button is skipped. I don't know if the callback runs on the main
  thread or between frames; I assumed it's safe to call `GuiSetSkin` from it. The icon texture is also set in a callback, so the
  first frames show no icon.
- **Sound button.** Used `GuiTextureButton(bounds, normal, null, pressed)` with `focused` null (falls back to normal) and no
  disabled texture. Whether the pressed image shows "while held" matches `STATE_PRESSED`, as I assumed. The whole 48x48 rectangle
  answers the pointer, including clear corners of the round image, so clicks in the corners count. Fine here, but a round hit
  test would be better. Sound on/off picks different texture sets in my code, not in the API.
- **Disabled Options.** `GuiDisable()` / `GuiEnable()` around the call. Assumed this gives the disabled cell and returns 0 on clicks.
- **Quit.** Sets a flag that ends the loop; no `CloseWindow` call elsewhere.

## API suggestions
- `GuiSkinFromSheet` should take optional text offsets (focused, pressed, disabled), or a normal-state offset too.
- A way to pass a skin for one control instance, without swapping the global skin around the call.
- `GuiGetSkin` should say whether it returns the live skin or a copy.
- Say when `LoadTextureAsync` callbacks run and what a skin set before the texture loads looks like.
- A round / alpha hit test option for `GuiTextureButton`.
