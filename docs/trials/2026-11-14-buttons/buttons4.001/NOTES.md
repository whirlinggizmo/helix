# Notes

## Compile errors
None. `haxe build.hxml` compiled `Main.hx` on the first try.

One slip to own up to: while looking for `LoadTextureAsync`'s signature I ran a grep that reached into the installed helix-raylib
library, outside this directory. I shouldn't have. It only showed me the signature, `LoadTextureAsync(fileName, loaded:Texture2D -> Void, ?failed)`.

## Guesses and doubts
- **Assets not seen.** There's no `assets/` directory here, so the cell sizes, borders and icon rects come from task.md only.
- **Skin from sheet.** `GuiSkinFromSheet(t, 192, 64, 16, 16, 16, 20, 4)` for `button.png`: left, top, right and bottom borders are 16, 16, 16
  and 20. I read the bottom 20 as including the 4-texel lip, because the task says the borders are 20 at the bottom. `lip` is 4, so
  text offsets are (0,-2) normal and disabled, (0,2) pressed, and I left them to the sheet function rather than setting them. If the bottom border
  was meant to sit under the lip, 20 would be wrong.
- **Quit.** `GuiSkinFromSheet(..., 4, 2)`, lip 4 and lift 2, gives focused text (0,-4) per the doc. `GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin)`
  comes right before Quit's `GuiButton`. I assumed "the next control call of a kind" means the next `GuiButton`, and
  that `GuiDisable`/`GuiEnable` or the Options button before it consume nothing.
- **Icons.** I used `GuiSetIconTexture(ICON_229 + i, icons, Rectangle(i*24,0,24,24))` and `GuiIconText(ICON_229 + i, text)`. The doc says
  229-255 are spare, so I assumed `ICON_229` etc. exist as constants (they compile). I assumed the text is laid out after the icon with no extra
  help. Whether the icon scale defaults to 1 (`GuiSetIconScale`) isn't stated; I didn't set it. Disabled icons fade to half, which I took as fine.
- **Disabled.** `GuiDisable()`/`GuiEnable()` around Options. I assumed `GuiButton` returns 0 there (stated for `GuiTextureButton`, not for `GuiButton`).
- **Sound toggle.** `GuiTextureButton(bounds, normal, focused, pressed, disabled, clickMask)`. The `focused` I gave is the normal image,
  because the task has no hover image. The clickMask is `sound_on.png`'s image, also used while sound is off; it assumes both share the same round
  shape. `null` for `disabled` assumes optional args accept null as well as being left out.
- **Where drawn.** I didn't know whether skins apply to `GuiButton` before `GuiSetSkin` is called each frame; I call it every frame
  after loading finishes (cheap, and it works with async loading). `GuiSetSkin` before the texture is ready would take null skins.
- **Loading.** Everything loads async, so the menu waits on a counter (`pending`, 7 textures) plus the mask image. Failure callbacks are omitted,
  so a missing file would leave "Loading..." up forever.

## API changes I'd suggest
- `GuiSkinFromSheet`: say whether `bottom` includes the lip.
- Say whether `GuiSetSkinOnce` is consumed by the next call of that control even when it's disabled or off-screen.
- State that `GuiButton` returns 0 in `STATE_DISABLED` as `GuiTextureButton` says.
- A `GuiTextureToggle` taking on/off textures would fit the sound button, which I wrote as a bool plus two textures chosen by hand.
- Name constants for the spare icons (e.g. `GUI_ICON_USER0`) rather than `ICON_229 + i`.
- A synchronous loader or one "all loaded" callback would spare the counter.
