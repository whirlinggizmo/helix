# Notes

## Compile errors
None. `haxe build.hxml` compiled `Main.hx` on the first try (exit 0). The program was not run.

## Guesses and uncertainties
- **Text offsets.** The task gives a 4-texel lip, so I took the doc's own example values:
  normal (0,-2), pressed (0,2), disabled (0,-2). Focused is (0,-2) for `button.png`. For
  `button_quit.png` the focused face is 2 texels higher, so focused is (0,-4). I couldn't check
  these against the real art. I also assumed the offset is added on top of raygui's centering.
- **Quit's own skin.** `GuiSetSkin` is global per control. I read the skin with `GuiGetSkin`,
  set Quit's skin just before drawing the Quit button, then put the old one back. The doc says
  this works ("a skin set before one call and put back after it changes that call's control alone"),
  but I'm not sure `GuiGetSkin` returns a usable value before the async load finishes. I only
  swap when `quitSkin != null`, but restore `prev` unconditionally, and `prev` may be null.
  Restoring null should mean flat, which matches the state before the load.
- **Async loading.** I assumed `LoadTextureAsync(path, callback)` as in the doc example, with
  controls drawn flat until the callback fires. The sound button waits for all four textures
  (counter `soundReady`). `quitSkin` and the icon textures are not guarded beyond that.
- **Icons.** `GuiSetIconTexture` needs an icon id. I used the spare `ICON_229..231`, with the source
  rectangles taken from the three 24x24 cells of `icons.png`. I assumed `GuiIconText(id, text)` then
  puts the icon before the text and shifts the text by 24 px, as the docs say. I did not use
  `GuiSetIconScale`.
- **Disabled Options.** I used `GuiDisable()`/`GuiEnable()` around it. The doc says the disabled
  patch is drawn between them. The icon fades to half in the disabled state, which is fine here.
- **Sound toggle.** `GuiTextureButton(bounds, normal, focused, pressed)` stretches each texture to
  `bounds`. I passed the "on" texture as both normal and focused, since the task gives no hover image.
  The bounds are 48x48, matching the textures. The round shape comes from the texture's clear texels;
  the doc says the whole rectangle answers the pointer, so clicks in the corners count. That may not
  be wanted for a round button.
- **Pressed text.** I rely on the `pressedTextOffset` of (0,2) for the text moving down with the face.

## API changes I'd suggest
- Per-call skin swapping (Quit) is clumsy. A `GuiButtonSkinned(bounds, text, skin)`, or letting a
  skin be passed per call, would avoid the get/set/restore.
- A text offset in the `GuiSkinFromSheet` arguments, or a helper like `GuiSkinLip(skin, lip, lift)`,
  would save working out the offsets by hand from the lip and lift sizes.
- Say whether the offsets are added to raygui's centered position or replace it, and how the offset
  combines with an icon.
- Say whether `GuiGetSkin` returning null means "none set" or "not loaded yet", and what an async
  load does for a control drawn before its callback fires.
- `GuiTextureButton` could take a hit shape (round) or a way to ignore clear texels.
- Say whether `GuiSetIconTexture`'s `source` is in texels of the texture (the doc says so), and
  list the icon ids that are free to use in a more visible place than the `ICON_229` note.
