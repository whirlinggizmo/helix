# Notes

## Compile errors
- `LoadTexture` is "Not supported. Use LoadTextureAsync". Seven errors, one per texture. I load every texture with
  `LoadTextureAsync`, count the callbacks, build the skins and icon textures when all seven have arrived, and draw nothing (an empty
  frame) until then. Nothing else failed; the second compile was clean.

## Guesses / unsure
- **Text offsets.** `GuiSkinFromSheet` leaves all four offsets at (0,0), although the `GuiSkin` doc comments suggest (0,-2) / (0,-4) / (0,2).
  I set them by hand. Normal, focused and disabled are (0,-2) (centered on the raised face), pressed is (0,2) (face down 4, so
  -2 + 4). Quit's focused offset is (0,-4), since its face is 2 higher. I read "moved by its GUI_SKIN_BASE skin's text offset"
  as applying to the icon too, so the icon and text lift together.
- **Per-button skin.** Quit needs a different sheet, so I call `GuiSetSkin(BUTTON, GUI_SKIN_BASE, ...)` before the Quit button
  and put the normal one back after it, as the doc says a skin set before one call and put back after changes only that call.
- **Icons.** Icons go in via `GuiSetIconTexture` on the spare ids `ICON_229..231`, each with a 24x24 `source` rectangle cut
  from the strip. They're used through `GuiIconText(id, text)`. I assumed the icon ids exist as constants in Raygui and that the text
  is placed after the icon, as the doc says. I didn't check whether the 24 px icon is scaled by the default icon scale (`GuiSetIconScale`); I left it alone.
- **Disabled Options.** `GuiDisable()` / `GuiEnable()` around the call. I assumed `GuiButton` returns 0 and the
  disabled cell is drawn. The icon is faded to half in the disabled state, as documented.
- **Sound toggle.** `GuiTextureButton(bounds, normal, focused, pressed)`, with focused = normal so there's no hover change. That the
  pressed image shows while held is taken from the doc. It's the whole 48x48 rectangle that answers the pointer, not the round
  shape, so the corners of the square are clickable. "Round" is only a matter of the textures' clear corners.
- No sound is actually played or muted; the toggle only flips a flag, since the task doesn't ask for audio.
- Skins aren't set up in `STATE_*` terms by me: I rely on `GuiButton` to pick the state from the pointer. Nothing was run.

## API suggestions
- `GuiSkinFromSheet` could take optional text offsets (or the lip height) so a raised-face sheet doesn't need four hand-set Vector2s,
  and the default offsets in the GuiSkin docs ((0,-2) etc.) contradict "(0, 0) in a skin made by GuiSkinFromSheet": reword.
- A synchronous `LoadTexture` fails at compile time; a note in GuiSkins' docs showing the async-ready pattern for several textures would help.
- A skin per call (e.g. `GuiButtonSkinned(bounds, text, skin)`) would be less error-prone than set/restore around a call.
- `GuiTextureButton` would benefit from a hit shape option (circle) for round buttons, and a toggle variant that takes on/off textures.
- Say which icon ids are free and whether `GuiSetIconTexture` icons follow `GuiSetIconScale`.
