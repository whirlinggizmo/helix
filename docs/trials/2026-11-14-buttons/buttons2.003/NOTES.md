# NOTES

## Compile errors
- `LoadTexture(...)` failed to compile ("Not supported. Use LoadTextureAsync"). Switched to `LoadTextureAsync` for all 7 textures,
  counting completions and building skins/icons once all have loaded (the frame loop draws only a blank screen until then).

## Guesses / unsure
- Icons: used `GuiSetIconTexture(ICON_229..231, icons, source)` with `GuiIconText(id, text)`; assumed this is the intended way to put
  a texture icon before button text. Not sure how the text is aligned (centered icon+text as a group assumed).
- Quit's different skin: only one skin per control+part, so I swap `BUTTON/GUI_SKIN_BASE` around the Quit call using `GuiGetSkin`/`GuiSetSkin`
  (doc says a swap around one call affects that call alone).
- Text offsets: `pressedTextOffset=(0,4)` for all buttons, `focusedTextOffset=(0,-2)` for Quit. Unsure whether offsets apply to the icon
  texture as well (docs say "text and icon") and whether a disabled button should offset.
- Pressed state: assumed the skin's pressed cell fills the full bounds, so the 4px lip is part of the art, not something I draw.
- Sound toggle: `GuiTextureButton` with focused=null (falls back to normal). Assumed it draws no text and the 48x48 images aren't
  stretched oddly (bounds 48x48). It ignores `GuiDisable` only when enabled — fine here.
- Options disabled with `GuiDisable()/GuiEnable()`; assumed GuiEnable doesn't clear other state.
- `GuiSkinFromSheet` returns a class with mutable fields; setting offsets after creation (no constructor arg for them).

## API suggestions
- Add text offsets as optional params of `GuiSkinFromSheet`, or a helper that takes a lift/press amount.
- A synchronous texture loader (or a note that `LoadTexture` is unsupported) in the extra's docs; the example comment in `GuiSkins`
  doesn't mention the async-only requirement besides the snippet.
- Per-call skin override (e.g. `GuiButtonSkinned(bounds, text, skin)`) so Quit doesn't need get/set swapping.
- Doc for `GuiIconText` alignment with texture icons, and the icon's size vs `GuiSetIconScale`.
