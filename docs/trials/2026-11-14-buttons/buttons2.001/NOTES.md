# NOTES

## Compile errors
None: `haxe build.hxml` compiled `Main.hx` on the first try.

## Guesses / unsure
- **Text offsets.** The doc says the offsets move text "from where raygui draws it", but not what raygui's baseline is. I assumed text
  is centred in the whole bounds, so I used the pressed offset (0, 4) (face drops 4) and, for Quit, a focused offset (0, -2). I also
  wondered whether the raised face's 4 texel lip should shift the normal text up by 2. I didn't, as the doc gives no such rule.
- **Offsets live on the skin struct.** `GuiSkinFromSheet` takes no offsets, so I made the skin, then assigned
  `focusedTextOffset` / `pressedTextOffset`. The struct fields are assumed to be writable after creation and read at draw time.
  The "Gets or sets" wording and `@:structInit` suggest so.
- **Offset applies to the icon too.** Doc says "text and icon", so I assumed the icon lifts and drops with the text.
- **Sheet borders.** `GuiSkinFromSheet(tex, 192, 64, left 16, top 16, right 16, bottom 20)`. The argument order is left, top, right, bottom.
- **Icon ids.** Used the spare `ICON_229`..`ICON_231` with `GuiSetIconTexture`, and one shared `icons.png` with a `source` rectangle per
  icon. I wasn't sure whether the source is in texels of the texture (assumed so). The icon is drawn at 24x24 times the icon scale
  (default assumed 1; I didn't call `GuiSetIconScale`). I couldn't tell where the text starts for a centred label (assumed it is
  centred together with the icon, as the doc says).
- **Per-button skin.** There is one `BUTTON` skin slot, so I call `GuiSetSkin` before the Quit button and put the normal skin back after
  it. The doc says this changes only that call's control. `GuiGetSkin` isn't needed because I keep both skins myself.
- **Disabled.** `GuiDisable()` / `GuiEnable()` around the Options button picks the disabled cell. Whether a disabled button's icon fades to half
  too (the icon doc says so) is assumed.
- **Async loading.** `LoadTextureAsync` callbacks run at an unknown time (assumed: on the main thread, a frame or more later), so
  every skin or texture is null-checked and the buttons draw flat until it arrives. The callback's `Texture2D` is assumed to stay valid.
  Note that `GuiSetSkin(.., null)` is used before the load finishes, so the flat default is drawn.
- **Sound button.** `GuiTextureButton(bounds, normal, focused=null, pressed)`. Passing null for `focused` is meant to give `normal` on
  hover. "Pressed" is assumed to be drawn only while held. Its click returns 1 on release, as `GuiButton` (not stated). It has no text,
  so the texture is stretched to the 48x48 bounds, which is its size. Its image is drawn over the "round" shape, so clicks in the clear corners count (doc says so).
  I wrapped it in `on != null` so nothing draws until loaded.
- `LoadTextureAsync` isn't in `api/`; I used it as in the GuiSkins doc example (callback of `Texture2D`).

## API changes I'd suggest
- `GuiSkinFromSheet` could take optional text offsets (or a `liftPx`), so the common raised-face case doesn't need a mutable struct.
- Say where the text sits in a raised-face sheet, and whether the offset is relative to the bounds centre or to the lip-free face.
- `GuiTextureButton` should say whether a null `focused` falls back to `normal` or `pressed`; the doc says `normal`, though `pressed` says
  `focused`, so with pressed given and focused null the result is a little confusing.
- `GuiSetIconTexture`'s `source` should say whether it is in texels. A helper to register a row of equal icons from one sheet would help.
- A scoped/override variant (`GuiButtonSkinned(bounds, text, skin)`) would avoid the set/restore dance for one-off buttons.
