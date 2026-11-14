# NOTES

## Compile errors
- `LoadTexture` is "Not supported. Use LoadTextureAsync". I switched to `LoadTextureAsync` for all 7 textures, stored them in a map, and wait (drawing blank frames) until all have arrived before setting skins/icons. After that it compiled with no errors.

## Guesses / unsure
- **Text offsets:** `GuiSkinFromSheet` leaves offsets at (0,0), so I set them myself: normal/disabled (0,-2), pressed (0,2), focused (0,-2) for `button.png` and (0,-4) for `button_quit.png` (face 2 higher). I took the doc's numbers on trust; I assumed offsets are absolute per state, not cumulative with the normal one.
- **Quit's own sheet:** there's no per-button skin, so I `GuiSetSkin(BUTTON, GUI_SKIN_BASE, quitSkin)` before the Quit `GuiButton` and put the shared skin back after. I relied on "the skin is read as each control draws".
- **Icons:** `GuiSetIconTexture` needs an `ICON_*` id; I used spare `ICON_229..231` and `GuiIconText(id, text)`. I guessed the images are drawn at 24x24 (icon scale default 1) and that the text shifts after them, as the doc says. Icon textures are only registered after the async load.
- **Disabled Options:** `GuiDisable()`/`GuiEnable()` around the button; I assumed disabling also makes the icon fade to half and picks the disabled cell.
- **Sound toggle:** `GuiTextureButton(bounds, normal, null, pressed)`, passing null for focused (falls back to normal). Clickable area is the whole 48x48 rectangle, so the "round" button's clear corners also respond. It has no text, so no icon/text issues. I picked the on/off textures by branching on state each frame.
- Unsure whether `GuiSkin` fields (e.g. `normalTextOffset`) can be mutated in place after `GuiSkinFromSheet`, or are copied at `GuiSetSkin` time; I set them before `GuiSetSkin`.
- Unclear where `GuiSetSkin`'s doc'd "text offset" applies to icon+text together: assumed both move.

## API suggestions
- Per-call skin/skin-override for `GuiButton` (or a `GuiButtonSkinned`) rather than swapping the BUTTON skin around a call.
- Let `GuiSkinFromSheet` take optional text offsets (or a lip height) so the common raised-lip case needn't hand-set four vectors; and a lift parameter for the focused state.
- `GuiTextureButton` hit-testing against alpha / a circle for round buttons.
- Make `LoadTexture` usable, or document the async requirement in GuiSkins' intro (the example shows it but a sync fallback would be easier).
- A named icon-slot allocator instead of picking spare `ICON_229+`.
