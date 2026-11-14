# GuiSkins

[Back to the library](README.md)

## GuiSkins

*class* in [`engines/raylib/src/helix/raylib/extras/GuiSkins.hx`](../src/helix/raylib/extras/GuiSkins.hx), `import helix.raylib.extras.GuiSkins;`

Provides skins for raygui's controls, helix-raylib's own: a part of a control drawn from a texture, a nine-patch whose corners keep their shape, in place of its style's flat colors. The controls keep raygui's signatures, so a skinned button is still `GuiButton(bounds, text)`, and its text is still drawn in the style's text colors and font. Imported apart: `import helix.raylib.extras.GuiSkins.*;`, and the skin's type apart: `import helix.raylib.extras.GuiSkin;`. The example `engines/raylib/examples/extras/gui_skins` uses it.

```haxe
// button.png: a cell of 190 x 49 for each state, top down (normal, focused, pressed, disabled), borders of 14.
LoadTextureAsync("assets/button.png", sheet -> GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromSheet(sheet, 190, 49, 14, 14, 14, 14)));
...
if (GuiButton(new Rectangle(20, 20, 190, 49), "Play") != 0) ...
```

The parts each control draws:

| control | `GUI_SKIN_BASE` | `GUI_SKIN_FILL` | `GUI_SKIN_HANDLE` | `GUI_SKIN_ITEM` | |---|---|---|---|---| | `DEFAULT` | `GuiPanel`'s, `GuiWindowBox`'s and `GuiScrollPanel`'s body | | | | | `BUTTON` | `GuiButton`, and `GuiSpinner`'s arrows | | | | | `TOGGLE` | a toggle, each of a toggle group's, a toggle slider's box | a toggle slider's selection | | | | `SLIDER` | the box | `GuiSliderBar`'s bar | `GuiSlider`'s handle | | | `PROGRESSBAR` | the box | the progress | | | | `CHECKBOX` | the box | the check | | | | `COMBOBOX`, `TEXTBOX`, `VALUEBOX`, `STATUSBAR` | the box | | | | | `DROPDOWNBOX` | the box | | | an open list's focused and chosen items | | `LISTVIEW` | the box | | | the focused and active items | | `SCROLLBAR` | the bar and its track | | the thumb | |

A control draws its state's patch: `STATE_FOCUSED` with the pointer over it, `STATE_PRESSED` held down (and a toggle on), `STATE_DISABLED` between `GuiDisable` and `GuiEnable` or under `GuiSetState(STATE_DISABLED)`. A control's text and icon are placed in its bounds as raygui places them, then moved by its `GUI_SKIN_BASE` skin's text offset for its state. A program that sets no skin links none of this.

```haxe
static inline var GUI_SKIN_BASE:Int
static inline var GUI_SKIN_FILL:Int
static inline var GUI_SKIN_HANDLE:Int
static inline var GUI_SKIN_ITEM:Int
static inline var GUI_SKIN_FILL_STRETCHED:Int
static inline var GUI_SKIN_FILL_CLIPPED:Int
```

- `GUI_SKIN_BASE`: A control's box: its border and background. Every control has one.
- `GUI_SKIN_FILL`: The part a control fills to show its value: a slider's or progress bar's bar, a check box's check.
- `GUI_SKIN_HANDLE`: The part a control is dragged by: a slider's handle, a scroll bar's thumb.
- `GUI_SKIN_ITEM`: One item of a list: a list view's row, a drop-down box's choice, a toggle group's toggle.
- `GUI_SKIN_FILL_STRETCHED`: A fill skin is stretched over the filled part. The default, as `GuiSkin`'s `fillMode`.
- `GUI_SKIN_FILL_CLIPPED`: A fill skin is stretched over the whole control and shown up to the filled part, as Godot's TextureProgressBar draws its progress: a bar with rounded ends shows its starting end whole, and its far end only when full.

### gui skins: raygui's controls drawn from textures

```haxe
static function GuiSkinFromTexture(texture:Texture2D, normal:NPatchInfo, ?focused:NPatchInfo, ?pressed:NPatchInfo, ?disabled:NPatchInfo, ?tint:Color):GuiSkin
static function GuiSkinFromSheet(texture:Texture2D, cellWidth:Int, cellHeight:Int, left:Int, top:Int, right:Int, bottom:Int, ?lip:Int, ?lift:Int):GuiSkin
static function GuiSetSkin(control:Int, part:Int, skin:Null<GuiSkin>):Void
static function GuiSetSkinOnce(control:Int, part:Int, skin:Null<GuiSkin>):Void
static function GuiGetSkin(control:Int, part:Int):Null<GuiSkin>
static function GuiTextureButton(bounds:Rectangle, normal:Texture2D, ?focused:Texture2D, ?pressed:Texture2D, ?disabled:Texture2D, ?clickMask:Image):Int
static function GuiSetIconTexture(iconId:Int, texture:Null<Texture2D>, ?source:Rectangle):Void
static function GuiClearSkins():Void
```

- `GuiSkinFromTexture`: Returns a skin cut from a texture by one patch for each state. See `GuiSkinFromSheet` for cutting the patches from a sheet of equal cells.
  - `texture`: The texture the patches are cut from.
  - `normal`: The patch drawn in `STATE_NORMAL`, in any of raylib's layouts: `NPATCH_NINE_PATCH`, `NPATCH_THREE_PATCH_HORIZONTAL` for a bar with caps at its ends, or `NPATCH_THREE_PATCH_VERTICAL`.
  - `focused`: Optional. The patch drawn in `STATE_FOCUSED`; `normal` when omitted.
  - `pressed`: Optional. The patch drawn in `STATE_PRESSED`; `focused` when omitted, or `normal` without it.
  - `disabled`: Optional. The patch drawn in `STATE_DISABLED`; `normal` when omitted.
  - `tint`: Optional. The color the patches are multiplied by; `WHITE` when omitted.
  - returns: The skin, its patches stretched. Set its `horizontalPatchMode` and `verticalPatchMode` to repeat them.
- `GuiSkinFromSheet`: Returns a skin cut from a sheet of a control's states, one cell of one size each. See `GuiSkinFromTexture` for cutting a patch per state from one texture.
  - `texture`: The sheet.
  - `cellWidth`: A cell's width, in texels.
  - `cellHeight`: A cell's height, in texels.
  - `left`: The left border's width, in texels, kept unstretched.
  - `top`: The top border's height.
  - `right`: The right border's width.
  - `bottom`: The bottom border's height, a lip under the face included.
  - `lip`: Optional. How many texels at the bottom of the normal, focused and disabled cells are a lip under a raised face, the pressed cell's face pushed down onto it; 0 when omitted. Sets the skin's text offsets so the text stays centered on the face: (0, -lip / 2) normal and disabled, (0, lip / 2) pressed.
  - `lift`: Optional. How many texels higher the focused cell's face is than the normal cell's; 0 when omitted. The focused text offset is (0, -lip / 2 - lift).
  - returns: The skin, its patches stretched. Set its `horizontalPatchMode` and `verticalPatchMode` to repeat them.

  The cells are in raygui's order of states: normal, focused, pressed, disabled.

  They run from the top down, or from the left across when the sheet is less than two cells high.

  A sheet of fewer than four cells leaves the rest to their fallbacks (`GuiSkin`).

  Each cell is cut as a nine-patch by the same borders.
- `GuiSetSkin`: Sets the skin a part of a control is drawn with, in place of its style's border and base colors. See `GuiGetSkin` for reading the skin set, and `GuiClearSkins` for removing every one.
  - `control`: The control: `DEFAULT`, `BUTTON`, `SLIDER` and the rest of raygui's.
  - `part`: `GUI_SKIN_BASE`, `GUI_SKIN_FILL`, `GUI_SKIN_HANDLE` or `GUI_SKIN_ITEM`.
  - `skin`: The skin, or null to draw the part flat in its style's colors again.

  A skin set on `DEFAULT` is set on every control too, as `GuiSetStyle` sets `DEFAULT`'s base properties. Set `DEFAULT`'s first and each control's own after.

  The skin is read as each control draws. See `GuiSetSkinOnce` for a skin for one call.

  `GuiPanel`, `GuiWindowBox` and `GuiScrollPanel` draw their body with `DEFAULT`'s own `GUI_SKIN_BASE`.
- `GuiSetSkinOnce`: Sets the skin the next control call of a kind draws a part with, in place of the one `GuiSetSkin` set: one button in a different skin from the rest. The next call of that control takes it, drawn or disabled alike, and the call after it draws with `GuiSetSkin`'s again.
  - `control`: The control: `BUTTON`, `SLIDER` and the rest of raygui's.
  - `part`: `GUI_SKIN_BASE`, `GUI_SKIN_FILL`, `GUI_SKIN_HANDLE` or `GUI_SKIN_ITEM`.
  - `skin`: The skin, drawn in full for that call (its patches, text offsets, fill mode and fill edge), or null to draw the part flat.
- `GuiGetSkin`: Returns the skin a part of a control is drawn with, to put back after a change. See `GuiSetSkin` for setting it.
  - `control`: The control.
  - `part`: The part.
  - returns: The skin, or null when the part is drawn flat.
- `GuiTextureButton`: Draws a button of images, one for each state, as Godot's TextureButton, in place of `BUTTON`'s box and text: each state's texture drawn whole, stretched to `bounds`, faded by `GuiSetAlpha`'s alpha. See `GuiButton` for a button with text, and `GuiSetIconTexture` for an image beside its text.
  - `bounds`: Where the button is drawn, and where it answers the pointer.
  - `normal`: The texture drawn in `STATE_NORMAL`.
  - `focused`: Optional. The texture drawn in `STATE_FOCUSED`; `normal` when omitted.
  - `pressed`: Optional. The texture drawn in `STATE_PRESSED`; `focused` when omitted, or `normal` without it.
  - `disabled`: Optional. The texture drawn in `STATE_DISABLED`; `normal` when omitted.
  - `clickMask`: Optional. An image whose clear texels (alpha 0) don't answer the pointer, stretched to `bounds` as the textures are: often the normal texture's image, so a round button's corners ignore it. The whole rectangle answers when omitted.
  - returns: 1 when it's clicked, else 0, as `GuiButton`: always 0 in `STATE_DISABLED`.
- `GuiSetIconTexture`: Sets the texture drawn for one of raygui's icons in place of its pixels. Every control drawing that icon in its text (`GuiIconText(iconId, text)`) draws the texture there, laid out as raygui's icon is: the texture and the text after it aligned together as the control aligns its text, the text moved along by the texture's width. Draws raygui's own icon again when given null. See `GuiDrawIcon` for an icon on its own.
  - `iconId`: The icon (`ICON_*`). `ICON_229` to `ICON_255` are raygui's spare icons, blank.
  - `texture`: The texture, or null for raygui's icon.
  - `source`: Optional. The part of the texture drawn, in texels; the whole texture when omitted.

  The texture is drawn at the source's size times `GuiSetIconScale`'s scale, centered on the text's line, in its own colors. It fades with the control: by `GuiSetAlpha`'s alpha, and to half in `STATE_DISABLED`.
- `GuiClearSkins`: Removes every skin and icon texture. Every control is drawn flat in its style's colors again, with raygui's icons. See `GuiSetSkin` with null for removing one skin.
  Loading a style leaves the skins unchanged.

## GuiSkin

*class* in [`engines/raylib/src/helix/raylib/extras/GuiSkin.hx`](../src/helix/raylib/extras/GuiSkin.hx), `import helix.raylib.extras.GuiSkin;`

Represents a skin: how one part of raygui's controls is drawn from a texture, a nine-patch for each state, in place of its style's flat colors.

Made by `GuiSkinFromTexture` and set by `GuiSetSkin`, both in `helix.raylib.extras.GuiSkins`.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{texture:Texture2D, normal:NPatchInfo, focused:Null<NPatchInfo>, pressed:Null<NPatchInfo>, disabled:Null<NPatchInfo>, tint:Color, ?horizontalPatchMode:Int, ?verticalPatchMode:Int, ?fillMode:Int, ?fillEdge:Null<Texture2D>, ?normalTextOffset:Vector2, ?focusedTextOffset:Vector2, ?pressedTextOffset:Vector2, ?disabledTextOffset:Vector2}
```

```haxe
var texture:Texture2D
var normal:NPatchInfo
var focused:Null<NPatchInfo>
var pressed:Null<NPatchInfo>
var disabled:Null<NPatchInfo>
var tint:Color
var horizontalPatchMode:Int = 0
var verticalPatchMode:Int = 0
var fillMode:Int = 0
var fillEdge:Null<Texture2D> = null
var normalTextOffset:Vector2 = new Vector2(0, 0)
var focusedTextOffset:Vector2 = new Vector2(0, 0)
var pressedTextOffset:Vector2 = new Vector2(0, 0)
var disabledTextOffset:Vector2 = new Vector2(0, 0)
```

- `texture`: Gets or sets the texture holding the patches, often one sheet for every skin.
- `normal`: Gets or sets the patch drawn in `STATE_NORMAL`.
- `focused`: Gets or sets the patch drawn in `STATE_FOCUSED`, with the pointer over the control, or null to draw `normal`.
- `pressed`: Gets or sets the patch drawn in `STATE_PRESSED`, or null to draw `focused`, or `normal` when that is null too.
- `disabled`: Gets or sets the patch drawn in `STATE_DISABLED`, or null to draw `normal`.
- `tint`: Gets or sets the tint multiplying the patches, `WHITE` to draw them unchanged.
- `horizontalPatchMode`: Gets or sets how the patches fill a control across: `NPATCH_MODE_STRETCH`, `NPATCH_MODE_TILE` or `NPATCH_MODE_TILE_FIT` from `Textures`. `NPATCH_MODE_STRETCH` in a skin made by `GuiSkinFromTexture` or `GuiSkinFromSheet`.
- `verticalPatchMode`: Gets or sets how the patches fill a control down, as `horizontalPatchMode`.
- `fillMode`: Gets or sets how a `GUI_SKIN_FILL` skin is drawn: `GUI_SKIN_FILL_STRETCHED` over the filled part, or `GUI_SKIN_FILL_CLIPPED` over the whole control and shown up to the filled part. `GUI_SKIN_FILL_STRETCHED` in a made skin. Read for a progress bar's progress and `GuiSliderBar`'s bar.
- `fillEdge`: Gets or sets the texture a `GUI_SKIN_FILL` skin draws at the moving end of its fill, a thermometer's rounded tip or a line, or null for none. Drawn whole at the texture's size, centered on the fill's end, over the fill, at every value from the minimum to the maximum. It isn't clipped to the control: at the minimum and the maximum, half of it lies outside the control. Null in a made skin.
- `normalTextOffset`: Gets or sets how far a control's text and icon move from where raygui draws them, in pixels, x right and y down, in `STATE_NORMAL`: (0, -2) to center them on a face whose bottom 4 pixels are a lip. (0, 0) in a skin made by `GuiSkinFromTexture`, set from the lip in one made by `GuiSkinFromSheet`.
- `focusedTextOffset`: Gets or sets how far a control's text and icon move in `STATE_FOCUSED`, as `normalTextOffset`: (0, -4) for that face lifted 2 pixels more.
- `pressedTextOffset`: Gets or sets how far a control's text and icon move in `STATE_PRESSED`, as `normalTextOffset`: (0, 2) for that face pushed down 4 pixels onto its lip.
- `disabledTextOffset`: Gets or sets how far a control's text and icon move in `STATE_DISABLED`, as `normalTextOffset`.
