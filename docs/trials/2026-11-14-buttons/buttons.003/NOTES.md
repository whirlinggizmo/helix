# NOTES

## Compile errors
- `LoadTexture` is "Not supported. Use LoadTextureAsync". Switched to `LoadTextureAsync` with callbacks; the skins are built in the
  callbacks and the menu is drawn only once a counter of 7 pending loads reaches 0. After that it compiled cleanly.

## Guesses / unsure
- Icons: `GuiSetIconTexture` replaces raygui's icons by id, so I used the spare `ICON_229..231` for triangle/gear/door, with source
  rects cut from `icons.png` (x = 0, 24, 48), and `GuiButton(bounds, GuiIconText(ICON_229, "Play"))`. Assumed the text lands after the
  icon (the doc says it moves along by the texture's width) and the icon's text-offset moves with the pressed offset too.
- Pressed text moving down: set `pressedTextOffset = (0, 4)` on the skin by hand; `GuiSkinFromSheet` leaves offsets at (0,0). Quit also
  gets `focusedTextOffset = (0, -2)` for the 2-texel lift. Unsure whether the focused offset applies in addition to or instead of
  the face's own lift (the face lift is in the texture, the text lift in the offset).
- Quit button: one shared `BUTTON` skin, so I swap `GuiSetSkin(BUTTON, GUI_SKIN_BASE, ...)` before and after the Quit call (doc says the
  skin is read as each control draws, so this should work).
- Bottom border 20 vs. the 4-texel lip: assumed it's just the `bottom` argument of `GuiSkinFromSheet`; the lip is not otherwise handled.
- Whether the text is centred over the face or over the whole bounds (lip included) isn't documented.
- Disabled Options: `GuiDisable()/GuiEnable()` around the call. Assumed the disabled cell is drawn and a click returns 0.
- Sound toggle: `GuiTextureButton(bounds, normal, null, pressed)`, passing null for focused (falls back to normal). Not clipped to a
  circle; the round shape is just in the images. Hit area is the full 48x48 square. Sound itself isn't played; only the flag toggles.
  Corner position (740, 10) is my choice.
- The "pending" load counter is my own pattern; no failure callback is given, so a failed load leaves the menu blank.

## API suggestions
- `GuiSkinFromSheet` could take optional text offsets (or a "lift"/"press depth" parameter), since the pressed/focused text offsets
  must be set by hand on the returned skin.
- A per-button skin (or `GuiSetSkin` variant for one call) would avoid swapping skins around the Quit button.
- Say whether `GuiIconText` with a replaced icon texture lays out text using the texture width and whether the icon moves with offsets.
- `GuiTextureButton`'s docs don't say whether it supports a circular hit test.
- Mention in GuiSkins docs that `LoadTexture` is unsupported and that textures load asynchronously (the example uses it, but a note
  on knowing when everything is ready would help).
