# NOTES

## Compile errors
- `LoadTexture` ("Not supported, use LoadTextureAsync") on all seven textures. I switched to `LoadTextureAsync` with a
  pending counter, and build the skins and icon textures in `setup()` once every texture has arrived (the menu isn't drawn before that).
  The GuiSkins doc example shows async loading, but nothing in GuiSkins.hx says sync `LoadTexture` is unavailable.

## Guesses / unsure
- **Icons on buttons:** I used `GuiSetIconTexture` on spare icons `ICON_229..231` with source rects cut from icons.png
  (0/24/48, 0, 24, 24), then `GuiIconText(id, text)` as the button text. I assumed this is the intended way to show an
  image before text; the doc says the text moves by the texture's width, but not whether the button's text is still centered
  as a whole (icon + text) or whether the icon clips in a narrow button. Icon scale left at the default (assumed 1).
- **Pressed text offset:** `GuiSkinFromSheet` leaves offsets at (0,0), so I set `pressedTextOffset = (0, 4)` by hand. Is the icon
  moved too? Doc says "text and icon", so assumed yes. The offset applies to a control "whose GUI_SKIN_BASE skin has" one, so I
  set it on the skin object after creation (assumed fields are mutable after `GuiSetSkin`; I set them before).
- **Quit hover lift:** `focusedTextOffset = (0, -2)` on the quit skin only. The task says the face lifts 2 texels in the art;
  the offset only moves the text, which I assumed matches.
- **Per-button skin:** I swapped `BUTTON`'s `GUI_SKIN_BASE` around the Quit call, per the doc ("a skin set before one call and
  put back after it changes that call's control alone"), using `GuiGetSkin` to restore. Alternative would be nothing built in.
- **Disabled Options:** used `GuiDisable()`/`GuiEnable()`; a disabled button presumably also doesn't return clicks (raygui behaviour).
- **Sound toggle:** `GuiTextureButton` with `null` as focused so it falls back to `normal`, per docs; the pressed image is passed as `pressed`.
  Pressed-only fallback chain (`focused` null -> `normal`) was assumed from the doc. "Round" is just the image's shape; hit area is the
  square bounds. Position (top-right, 16px margin) is my choice.
- Not sure where the skin's pressed patch is drawn relative to bounds (the face is pushed down 4 texels inside the same cell, so I assumed the same bounds).

## API suggestions
- Name the unsupported sync `LoadTexture` in the GuiSkins docs/example, or make the example's async pattern explicit.
- Let `GuiSkinFromSheet` take optional text offsets (focused/pressed/disabled) rather than editing fields afterward.
- A way to give a skin per call (e.g. `GuiButtonSkinned(bounds, text, skin)`) would avoid the swap-and-restore around Quit.
- `GuiTextureButton` takes `null` placeholders for optional middle args; named/array variants would be easier to read.
- Document whether the GuiSkin object may be mutated after `GuiSetSkin`.
