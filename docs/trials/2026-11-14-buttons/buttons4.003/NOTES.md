# NOTES

## Compile errors
1. `LoadImage` -> "Not supported. Use LoadImageAsync". I load the click-mask image with `LoadImageAsync("assets/sound_on.png", i -> soundMask = i)`.
   No other errors; `haxe build.hxml` compiles cleanly. (Not run; assets/ doesn't exist in the dir.)

## Guesses / unsure
- Textures are loaded with `LoadTextureAsync` (as in the GuiSkins doc example), so they are null for the first frames. I guard every use
  (`!= null`, `iconsReady`). Unsure whether callbacks fire on the main thread / between frames.
- `GuiSkinFromSheet(sheet, 192, 64, 16, 16, 16, 20, lip=4, lift=0)` for button.png; `lift=2` for button_quit.png. The doc says lip gives
  text offsets (0,-2) normal/disabled and (0,+2) pressed, and focused (0,-2-lift). I rely on that for "pressed text moves with its face"
  and "Quit text lifts on hover", and set no offsets by hand. Note: the doc's "(0, -lip/2)" for pressed vs the face moving 4 down: the
  pressed text lands 4px below normal (-2 -> +2), which matches.
- Quit's skin is applied with `GuiSetSkinOnce(BUTTON, GUI_SKIN_BASE, quitSkin)` right before its `GuiButton`. Unsure whether it must be
  re-issued each frame (I do) and whether it applies to the next `GuiButton` call only after any `GuiIconText`/other calls (assumed yes).
- Icons: `GuiSetIconTexture(ICON_229..231, icons, Rectangle(24*i,0,24,24))` using the spare icons, then `GuiIconText(id, text)`.
  Assumed icons.png order is triangle, gear, door (task order). Assumed the texture is drawn at 24x24 (scale 1) and that "the text sits
  after the icon" comes from the control's alignment (default centered group). Called it every frame (cheap); could be done once.
- Disabled Options: `GuiDisable()`/`GuiEnable()` around the button. Assumed the disabled cell is used and icon fades to half.
  A disabled button's text offset is `disabledTextOffset` = (0,-2) by lip; assumed fine.
- Sound button: `GuiTextureButton(bounds, normal, null, pressed, null, clickMask)`. Passed null focused (-> normal) and null disabled.
  Doc says pressed falls back to focused when omitted, so passing null focused is OK. Used the on-image as click mask for both states
  (assumes both on/off art share the round silhouette). Assumed "pressed" texture is shown while held. Bounds 48x48 top right, 10px margin.
- Whether `null` in the middle of optional args (`?focused`) compiles/behaves as omitted: it compiled; behaviour unknown.
- Quit button click exits the loop; I don't know whether the text moves for the Quit when pressed (should: pressedTextOffset from lip).
- Skin set with `GuiSetSkin(BUTTON, ...)` in the loader callback, so it applies as soon as loaded.

## API suggestions
- A way to know a skin/texture is ready, or a sync load, to avoid null guards.
- `GuiSkinFromSheet` with eight positional Int args is easy to mix up (left, top, right, bottom, lip, lift); a struct/`NPatch`-like
  borders param or named options would help.
- Doc ambiguity: pressed text offset "(0, lip/2)" vs `normalTextOffset` "(0, -lip/2)" - state clearly that offsets are relative to raygui's centred position.
- Say whether `GuiSetSkinOnce` is consumed by a call that draws nothing, and whether it works while disabled.
- Icon placement ("text after the icon") for centered text: spell out that the icon+text group is centered together.
- Provide a helper for loading a row of icons from one texture (`GuiSetIconTextures(startId, texture, cellW, cellH)`).
