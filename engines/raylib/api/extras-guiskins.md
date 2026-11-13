# GuiSkins

[Back to the library](README.md)

## GuiSkins

*class* in [`engines/raylib/src/helix/raylib/extras/GuiSkins.hx`](../src/helix/raylib/extras/GuiSkins.hx), `import helix.raylib.extras.GuiSkins;`

Provides skins for raygui's controls, helix-raylib's own: a part of a control drawn from a texture, stretched as a nine-patch so its corners keep their shape, in place of its style's flat colors. The controls keep raygui's signatures, so a skinned button is still `GuiButton(bounds, text)`, and its text is still drawn in the style's text colors and font. Imported apart: `import helix.raylib.extras.GuiSkins.*;`. The skin's type, `GuiSkin`, is `helix.raylib`'s, with raylib's.

```haxe
// button.png: a cell of 190 x 49 for each state, top down (normal, focused, pressed, disabled), borders of 14.
LoadTextureAsync("assets/button.png", sheet -> GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromSheet(sheet, 190, 49, 14, 14, 14, 14)));
...
if (GuiButton(new Rectangle(20, 20, 190, 49), "Play") != 0) ...
```

The parts each control draws:

| control | `GUI_SKIN_BASE` | `GUI_SKIN_FILL` | `GUI_SKIN_HANDLE` | `GUI_SKIN_ITEM` | |---|---|---|---|---| | `DEFAULT` | `GuiPanel`'s, `GuiWindowBox`'s and `GuiScrollPanel`'s body | | | | | `BUTTON` | `GuiButton`, and `GuiSpinner`'s arrows | | | | | `TOGGLE` | a toggle, each of a toggle group's, a toggle slider's box | a toggle slider's selection | | | | `SLIDER` | the box | `GuiSliderBar`'s bar | `GuiSlider`'s handle | | | `PROGRESSBAR` | the box | the progress | | | | `CHECKBOX` | the box | the check | | | | `COMBOBOX`, `TEXTBOX`, `VALUEBOX`, `STATUSBAR` | the box | | | | | `DROPDOWNBOX` | the box | | | an open list's focused and chosen items | | `LISTVIEW` | the box | | | the focused and active items | | `SCROLLBAR` | the bar and its track | | the thumb | |

A control draws its state's patch: `STATE_FOCUSED` with the pointer over it, `STATE_PRESSED` held down (and a toggle on), `STATE_DISABLED` between `GuiDisable` and `GuiEnable` or under `GuiSetState(STATE_DISABLED)`. A program that sets no skin links none of this.

```haxe
static inline var GUI_SKIN_BASE:Int
static inline var GUI_SKIN_FILL:Int
static inline var GUI_SKIN_HANDLE:Int
static inline var GUI_SKIN_ITEM:Int
```

- `GUI_SKIN_BASE`: A control's box: its border and background. Every control has one.
- `GUI_SKIN_FILL`: The part a control fills to show its value: a slider's or progress bar's bar, a check box's check.
- `GUI_SKIN_HANDLE`: The part a control is dragged by: a slider's handle, a scroll bar's thumb.
- `GUI_SKIN_ITEM`: One item of a list: a list view's row, a drop-down box's choice, a toggle group's toggle.

### gui skins: raygui's controls drawn from textures

```haxe
static function GuiSkinFromTexture(texture:Texture2D, normal:NPatchInfo, ?focused:NPatchInfo, ?pressed:NPatchInfo, ?disabled:NPatchInfo, ?tint:Color):GuiSkin
static function GuiSkinFromSheet(texture:Texture2D, cellWidth:Int, cellHeight:Int, left:Int, top:Int, right:Int, bottom:Int):GuiSkin
static function GuiSetSkin(control:Int, part:Int, skin:Null<GuiSkin>):Void
static function GuiGetSkin(control:Int, part:Int):Null<GuiSkin>
static function GuiClearSkins():Void
```

- `GuiSkinFromTexture`: Returns a skin cut from a texture by one patch for each state. See `GuiSkinFromSheet` for cutting the patches from a sheet of equal cells.
  - `texture`: The texture the patches are cut from.
  - `normal`: The patch drawn in `STATE_NORMAL`.
  - `focused`: Optional. The patch drawn in `STATE_FOCUSED`; `normal` when omitted.
  - `pressed`: Optional. The patch drawn in `STATE_PRESSED`; `focused` when omitted, or `normal` without it.
  - `disabled`: Optional. The patch drawn in `STATE_DISABLED`; `normal` when omitted.
  - `tint`: Optional. The color the patches are multiplied by; `WHITE` when omitted.
  - returns: The skin.
- `GuiSkinFromSheet`: Returns a skin cut from a sheet of a control's states, one cell of one size each. See `GuiSkinFromTexture` for cutting a patch per state from one texture.
  - `texture`: The sheet.
  - `cellWidth`: A cell's width, in texels.
  - `cellHeight`: A cell's height, in texels.
  - `left`: The left border's width, in texels, kept unstretched.
  - `top`: The top border's height.
  - `right`: The right border's width.
  - `bottom`: The bottom border's height.
  - returns: The skin.

  The cells are in raygui's order of states: normal, focused, pressed, disabled.

  They run from the top down, or from the left across when the sheet is less than two cells high.

  A sheet of fewer than four cells leaves the rest to their fallbacks (`GuiSkin`).

  Each cell is cut as a nine-patch by the same borders.
- `GuiSetSkin`: Sets the skin a part of a control is drawn with, in place of its style's border and base colors. See `GuiGetSkin` for reading the skin set, and `GuiClearSkins` for removing every one.
  - `control`: The control: `DEFAULT`, `BUTTON`, `SLIDER` and the rest of raygui's.
  - `part`: `GUI_SKIN_BASE`, `GUI_SKIN_FILL`, `GUI_SKIN_HANDLE` or `GUI_SKIN_ITEM`.
  - `skin`: The skin, or null to draw the part flat in its style's colors again.

  A skin set on `DEFAULT` is set on every control too, as `GuiSetStyle` sets `DEFAULT`'s base properties. Set `DEFAULT`'s first and each control's own after.

  The skin is read as each control draws. A skin set before one call and put back after it changes that call's control alone.

  `GuiPanel`, `GuiWindowBox` and `GuiScrollPanel` draw their body with `DEFAULT`'s own `GUI_SKIN_BASE`.
- `GuiGetSkin`: Returns the skin a part of a control is drawn with, to put back after a change. See `GuiSetSkin` for setting it.
  - `control`: The control.
  - `part`: The part.
  - returns: The skin, or null when the part is drawn flat.
- `GuiClearSkins`: Removes every skin, so every control is drawn flat in its style's colors again. See `GuiSetSkin` with null for removing one.
  Loading a style leaves the skins unchanged.

## GuiSkin

*class* in [`engines/raylib/src/helix/raylib/extras/GuiSkin.hx`](../src/helix/raylib/extras/GuiSkin.hx), `import helix.raylib.extras.GuiSkin;`

Represents a skin: how one part of raygui's controls is drawn from a texture, a nine-patch for each state, in place of its style's flat colors.

Made by `GuiSkinFromTexture` and set by `GuiSetSkin`, both in `helix.raylib.extras.GuiSkins`.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{texture:Texture2D, normal:NPatchInfo, focused:Null<NPatchInfo>, pressed:Null<NPatchInfo>, disabled:Null<NPatchInfo>, tint:Color}
```

```haxe
var texture:Texture2D
var normal:NPatchInfo
var focused:Null<NPatchInfo>
var pressed:Null<NPatchInfo>
var disabled:Null<NPatchInfo>
var tint:Color
```

- `texture`: Gets or sets the texture holding the patches, often one sheet for every skin.
- `normal`: Gets or sets the patch drawn in `STATE_NORMAL`.
- `focused`: Gets or sets the patch drawn in `STATE_FOCUSED`, with the pointer over the control, or null to draw `normal`.
- `pressed`: Gets or sets the patch drawn in `STATE_PRESSED`, or null to draw `focused`, or `normal` when that is null too.
- `disabled`: Gets or sets the patch drawn in `STATE_DISABLED`, or null to draw `normal`.
- `tint`: Gets or sets the tint multiplying the patches, `WHITE` to draw them unchanged.
