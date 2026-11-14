# NOTES

## Compile errors
- `LoadTexture` is "Not supported" (use `LoadTextureAsync`). I first loaded synchronously; I changed every load to
  `LoadTextureAsync` with callbacks storing the textures/skins in statics, and guard draws against null until loaded.
  No other errors.

## Guesses / unsure
- **Icon on a button**: used `GuiSetIconTexture(ICON_229..231, icons, source)` + `GuiButton(bounds, GuiIconText(id, "Play"))`.
  Chose the spare icons 229-231 so no real icon is replaced. Assumed the text is laid out after the icon's texture width
  (24) as the doc says; the 24 px texture is at 1x since I didn't call `GuiSetIconScale`.
- **Disabled Options**: used `GuiDisable()`/`GuiEnable()` around the button, assuming the disabled cell and half-faded icon apply. Doc says a disabled control doesn't answer clicks (not stated explicitly) — assumed.
- **Pressed text drop**: `pressedTextOffset = (0, 4)`; the doc example suggests this. Whether the offset applies to the icon *and* text: doc says yes.
- **Hover lift**: Quit has its own skin with `focusedTextOffset = (0, -2)`. The skin swap is done around the Quit `GuiButton` call, relying on "the skin is read as each control draws". The face lift itself is in the art; the offset only lifts text. Unsure whether the offset applies in the pressed state beyond `pressedTextOffset`, so I set 4 there.
- **Skin swap**: `GuiSetSkin(..., baseSkin)` is also called every frame to restore; baseSkin is null until loaded (null = flat), which is fine.
- **Sound toggle**: `GuiTextureButton(bounds, on, on, held)`; focused = normal image (no hover art). "Round" is only the art, hit area is the 48x48 rectangle (doc says it answers the pointer in `bounds`) — a corner click on the transparent part would count. Unsure whether it checks alpha.
- `GuiSkinFromSheet` borders: left, top, right, bottom = 16, 16, 16, 20.
- Skin fields (`focusedTextOffset` etc.) are set after creation on the returned object; assumed it is mutable and not shared.

## API suggestions
- A per-button skin override (e.g. `GuiButton` variant taking a skin) would avoid swapping `GuiSetSkin` around one call.
- Say whether text offset values are relative to y-down (negative = up); I inferred this from the `(0, -2)` doc example.
- `GuiSkinFromSheet` could take a lift/pressed-drop for the text offsets, since they're tied to the art.
- State explicitly that `GuiTextureButton` is hit-tested by rectangle, and that `GuiDisable` blocks clicks.
- Document that `LoadTexture` isn't supported, and that skins can be made only after the async load completes.
