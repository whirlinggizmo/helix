# Raygui

[Back to the library](README.md)

## Gui control state (GuiState)


```haxe
static inline var STATE_NORMAL:Int
static inline var STATE_FOCUSED:Int
static inline var STATE_PRESSED:Int
static inline var STATE_DISABLED:Int
```

- `STATE_NORMAL`: Gui control state: `STATE_NORMAL`.
- `STATE_FOCUSED`: Gui control state: `STATE_FOCUSED`.
- `STATE_PRESSED`: Gui control state: `STATE_PRESSED`.
- `STATE_DISABLED`: Gui control state: `STATE_DISABLED`.

## Gui control text alignment (GuiTextAlignment)


```haxe
static inline var TEXT_ALIGN_LEFT:Int
static inline var TEXT_ALIGN_CENTER:Int
static inline var TEXT_ALIGN_RIGHT:Int
```

- `TEXT_ALIGN_LEFT`: Gui control text alignment: `TEXT_ALIGN_LEFT`.
- `TEXT_ALIGN_CENTER`: Gui control text alignment: `TEXT_ALIGN_CENTER`.
- `TEXT_ALIGN_RIGHT`: Gui control text alignment: `TEXT_ALIGN_RIGHT`.

## Gui control text alignment vertical (GuiTextAlignmentVertical)


```haxe
static inline var TEXT_ALIGN_TOP:Int
static inline var TEXT_ALIGN_MIDDLE:Int
static inline var TEXT_ALIGN_BOTTOM:Int
```

- `TEXT_ALIGN_TOP`: Gui control text alignment vertical: `TEXT_ALIGN_TOP`.
- `TEXT_ALIGN_MIDDLE`: Gui control text alignment vertical: `TEXT_ALIGN_MIDDLE`.
- `TEXT_ALIGN_BOTTOM`: Gui control text alignment vertical: `TEXT_ALIGN_BOTTOM`.

## Gui control text wrap mode (GuiTextWrapMode)


```haxe
static inline var TEXT_WRAP_NONE:Int
static inline var TEXT_WRAP_CHAR:Int
static inline var TEXT_WRAP_WORD:Int
```

- `TEXT_WRAP_NONE`: Gui control text wrap mode: `TEXT_WRAP_NONE`.
- `TEXT_WRAP_CHAR`: Gui control text wrap mode: `TEXT_WRAP_CHAR`.
- `TEXT_WRAP_WORD`: Gui control text wrap mode: `TEXT_WRAP_WORD`.

## Gui controls (GuiControl)


```haxe
static inline var DEFAULT:Int
static inline var LABEL:Int
static inline var BUTTON:Int
static inline var TOGGLE:Int
static inline var SLIDER:Int
static inline var PROGRESSBAR:Int
static inline var CHECKBOX:Int
static inline var COMBOBOX:Int
static inline var DROPDOWNBOX:Int
static inline var TEXTBOX:Int
static inline var VALUEBOX:Int
static inline var SPINNER:Int
static inline var LISTVIEW:Int
static inline var COLORPICKER:Int
static inline var SCROLLBAR:Int
static inline var STATUSBAR:Int
```

- `DEFAULT`: Gui controls: `DEFAULT`.
- `LABEL`: Used also for: LABELBUTTON.
- `BUTTON`: Gui controls: `BUTTON`.
- `TOGGLE`: Used also for: TOGGLEGROUP.
- `SLIDER`: Used also for: SLIDERBAR, TOGGLESLIDER.
- `PROGRESSBAR`: Gui controls: `PROGRESSBAR`.
- `CHECKBOX`: Gui controls: `CHECKBOX`.
- `COMBOBOX`: Gui controls: `COMBOBOX`.
- `DROPDOWNBOX`: Gui controls: `DROPDOWNBOX`.
- `TEXTBOX`: Used also for: TEXTBOXMULTI.
- `VALUEBOX`: Gui controls: `VALUEBOX`.
- `SPINNER`: Uses: BUTTON, VALUEBOX.
- `LISTVIEW`: Gui controls: `LISTVIEW`.
- `COLORPICKER`: Gui controls: `COLORPICKER`.
- `SCROLLBAR`: Gui controls: `SCROLLBAR`.
- `STATUSBAR`: Gui controls: `STATUSBAR`.

## Gui base properties for every control (GuiControlProperty)


```haxe
static inline var BORDER_COLOR_NORMAL:Int
static inline var BASE_COLOR_NORMAL:Int
static inline var TEXT_COLOR_NORMAL:Int
static inline var BORDER_COLOR_FOCUSED:Int
static inline var BASE_COLOR_FOCUSED:Int
static inline var TEXT_COLOR_FOCUSED:Int
static inline var BORDER_COLOR_PRESSED:Int
static inline var BASE_COLOR_PRESSED:Int
static inline var TEXT_COLOR_PRESSED:Int
static inline var BORDER_COLOR_DISABLED:Int
static inline var BASE_COLOR_DISABLED:Int
static inline var TEXT_COLOR_DISABLED:Int
static inline var BORDER_WIDTH:Int
static inline var TEXT_PADDING:Int
static inline var TEXT_ALIGNMENT:Int
```

- `BORDER_COLOR_NORMAL`: Control border color in STATE_NORMAL.
- `BASE_COLOR_NORMAL`: Control base color in STATE_NORMAL.
- `TEXT_COLOR_NORMAL`: Control text color in STATE_NORMAL.
- `BORDER_COLOR_FOCUSED`: Control border color in STATE_FOCUSED.
- `BASE_COLOR_FOCUSED`: Control base color in STATE_FOCUSED.
- `TEXT_COLOR_FOCUSED`: Control text color in STATE_FOCUSED.
- `BORDER_COLOR_PRESSED`: Control border color in STATE_PRESSED.
- `BASE_COLOR_PRESSED`: Control base color in STATE_PRESSED.
- `TEXT_COLOR_PRESSED`: Control text color in STATE_PRESSED.
- `BORDER_COLOR_DISABLED`: Control border color in STATE_DISABLED.
- `BASE_COLOR_DISABLED`: Control base color in STATE_DISABLED.
- `TEXT_COLOR_DISABLED`: Control text color in STATE_DISABLED.
- `BORDER_WIDTH`: Control border size, 0 for no border.
- `TEXT_PADDING`: Control text padding, not considering border.
- `TEXT_ALIGNMENT`: Control text horizontal alignment inside control text bound (after border and padding).

## DEFAULT extended properties (GuiDefaultProperty)


```haxe
static inline var TEXT_SIZE:Int
static inline var TEXT_SPACING:Int
static inline var LINE_COLOR:Int
static inline var BACKGROUND_COLOR:Int
static inline var TEXT_LINE_SPACING:Int
static inline var TEXT_ALIGNMENT_VERTICAL:Int
static inline var TEXT_WRAP_MODE:Int
```

- `TEXT_SIZE`: Text size (glyphs max height).
- `TEXT_SPACING`: Text spacing between glyphs.
- `LINE_COLOR`: Line control color.
- `BACKGROUND_COLOR`: Background color.
- `TEXT_LINE_SPACING`: Text spacing between lines.
- `TEXT_ALIGNMENT_VERTICAL`: Text vertical alignment inside text bounds (after border and padding).
- `TEXT_WRAP_MODE`: Text wrap-mode inside text bounds.

## Toggle/ToggleGroup (GuiToggleProperty)


```haxe
static inline var GROUP_PADDING:Int
```

- `GROUP_PADDING`: ToggleGroup separation between toggles.

## Slider/SliderBar (GuiSliderProperty)


```haxe
static inline var SLIDER_WIDTH:Int
static inline var SLIDER_PADDING:Int
```

- `SLIDER_WIDTH`: Slider size of internal bar.
- `SLIDER_PADDING`: Slider/SliderBar internal bar padding.

## ProgressBar (GuiProgressBarProperty)


```haxe
static inline var PROGRESS_PADDING:Int
```

- `PROGRESS_PADDING`: ProgressBar internal padding.

## ScrollBar (GuiScrollBarProperty)


```haxe
static inline var ARROWS_SIZE:Int
static inline var ARROWS_VISIBLE:Int
static inline var SCROLL_SLIDER_PADDING:Int
static inline var SCROLL_SLIDER_SIZE:Int
static inline var SCROLL_PADDING:Int
static inline var SCROLL_SPEED:Int
```

- `ARROWS_SIZE`: ScrollBar arrows size.
- `ARROWS_VISIBLE`: ScrollBar arrows visible.
- `SCROLL_SLIDER_PADDING`: ScrollBar slider internal padding.
- `SCROLL_SLIDER_SIZE`: ScrollBar slider size.
- `SCROLL_PADDING`: ScrollBar scroll padding from arrows.
- `SCROLL_SPEED`: ScrollBar scrolling speed.

## CheckBox (GuiCheckBoxProperty)


```haxe
static inline var CHECK_PADDING:Int
```

- `CHECK_PADDING`: CheckBox internal check padding.

## ComboBox (GuiComboBoxProperty)


```haxe
static inline var COMBO_BUTTON_WIDTH:Int
static inline var COMBO_BUTTON_SPACING:Int
```

- `COMBO_BUTTON_WIDTH`: ComboBox right button width.
- `COMBO_BUTTON_SPACING`: ComboBox button separation.

## DropdownBox (GuiDropdownBoxProperty)


```haxe
static inline var ARROW_PADDING:Int
static inline var DROPDOWN_ITEMS_SPACING:Int
static inline var DROPDOWN_ARROW_HIDDEN:Int
static inline var DROPDOWN_ROLL_UP:Int
```

- `ARROW_PADDING`: DropdownBox arrow separation from border and items.
- `DROPDOWN_ITEMS_SPACING`: DropdownBox items separation.
- `DROPDOWN_ARROW_HIDDEN`: DropdownBox arrow hidden.
- `DROPDOWN_ROLL_UP`: DropdownBox roll up flag (default rolls down).

## TextBox/TextBoxMulti/ValueBox/Spinner (GuiTextBoxProperty)


```haxe
static inline var TEXT_READONLY:Int
```

- `TEXT_READONLY`: TextBox in read-only mode: 0-text editable, 1-text no-editable.

## Spinner (GuiSpinnerProperty)


```haxe
static inline var SPIN_BUTTON_WIDTH:Int
static inline var SPIN_BUTTON_SPACING:Int
```

- `SPIN_BUTTON_WIDTH`: Spinner left/right buttons width.
- `SPIN_BUTTON_SPACING`: Spinner buttons separation.

## ListView (GuiListViewProperty)


```haxe
static inline var LIST_ITEMS_HEIGHT:Int
static inline var LIST_ITEMS_SPACING:Int
static inline var SCROLLBAR_WIDTH:Int
static inline var SCROLLBAR_SIDE:Int
static inline var LIST_ITEMS_BORDER_WIDTH:Int
```

- `LIST_ITEMS_HEIGHT`: ListView items height.
- `LIST_ITEMS_SPACING`: ListView items separation.
- `SCROLLBAR_WIDTH`: ListView scrollbar size (usually width).
- `SCROLLBAR_SIDE`: ListView scrollbar side (0-SCROLLBAR_LEFT_SIDE, 1-SCROLLBAR_RIGHT_SIDE).
- `LIST_ITEMS_BORDER_WIDTH`: ListView items border width.

## ColorPicker (GuiColorPickerProperty)


```haxe
static inline var COLOR_SELECTOR_SIZE:Int
static inline var HUEBAR_WIDTH:Int
static inline var HUEBAR_PADDING:Int
static inline var HUEBAR_SELECTOR_HEIGHT:Int
static inline var HUEBAR_SELECTOR_OVERFLOW:Int
```

- `COLOR_SELECTOR_SIZE`: ColorPicker: `COLOR_SELECTOR_SIZE`.
- `HUEBAR_WIDTH`: ColorPicker right hue bar width.
- `HUEBAR_PADDING`: ColorPicker right hue bar separation from panel.
- `HUEBAR_SELECTOR_HEIGHT`: ColorPicker right hue bar selector height.
- `HUEBAR_SELECTOR_OVERFLOW`: ColorPicker right hue bar selector overflow.

##  (GuiIconName)


```haxe
static inline var ICON_NONE:Int
static inline var ICON_FOLDER_FILE_OPEN:Int
static inline var ICON_FILE_SAVE_CLASSIC:Int
static inline var ICON_FOLDER_OPEN:Int
static inline var ICON_FOLDER_SAVE:Int
static inline var ICON_FILE_OPEN:Int
static inline var ICON_FILE_SAVE:Int
static inline var ICON_FILE_EXPORT:Int
static inline var ICON_FILE_ADD:Int
static inline var ICON_FILE_DELETE:Int
static inline var ICON_FILETYPE_TEXT:Int
static inline var ICON_FILETYPE_AUDIO:Int
static inline var ICON_FILETYPE_IMAGE:Int
static inline var ICON_FILETYPE_PLAY:Int
static inline var ICON_FILETYPE_VIDEO:Int
static inline var ICON_FILETYPE_INFO:Int
static inline var ICON_FILE_COPY:Int
static inline var ICON_FILE_CUT:Int
static inline var ICON_FILE_PASTE:Int
static inline var ICON_CURSOR_HAND:Int
static inline var ICON_CURSOR_POINTER:Int
static inline var ICON_CURSOR_CLASSIC:Int
static inline var ICON_PENCIL:Int
static inline var ICON_PENCIL_BIG:Int
static inline var ICON_BRUSH_CLASSIC:Int
static inline var ICON_BRUSH_PAINTER:Int
static inline var ICON_WATER_DROP:Int
static inline var ICON_COLOR_PICKER:Int
static inline var ICON_RUBBER:Int
static inline var ICON_COLOR_BUCKET:Int
static inline var ICON_TEXT_T:Int
static inline var ICON_TEXT_A:Int
static inline var ICON_SCALE:Int
static inline var ICON_RESIZE:Int
static inline var ICON_FILTER_POINT:Int
static inline var ICON_FILTER_BILINEAR:Int
static inline var ICON_CROP:Int
static inline var ICON_CROP_ALPHA:Int
static inline var ICON_SQUARE_TOGGLE:Int
static inline var ICON_SYMMETRY:Int
static inline var ICON_SYMMETRY_HORIZONTAL:Int
static inline var ICON_SYMMETRY_VERTICAL:Int
static inline var ICON_LENS:Int
static inline var ICON_LENS_BIG:Int
static inline var ICON_EYE_ON:Int
static inline var ICON_EYE_OFF:Int
static inline var ICON_FILTER_TOP:Int
static inline var ICON_FILTER:Int
static inline var ICON_TARGET_POINT:Int
static inline var ICON_TARGET_SMALL:Int
static inline var ICON_TARGET_BIG:Int
static inline var ICON_TARGET_MOVE:Int
static inline var ICON_CURSOR_MOVE:Int
static inline var ICON_CURSOR_SCALE:Int
static inline var ICON_CURSOR_SCALE_RIGHT:Int
static inline var ICON_CURSOR_SCALE_LEFT:Int
static inline var ICON_UNDO:Int
static inline var ICON_REDO:Int
static inline var ICON_REREDO:Int
static inline var ICON_MUTATE:Int
static inline var ICON_ROTATE:Int
static inline var ICON_REPEAT:Int
static inline var ICON_SHUFFLE:Int
static inline var ICON_EMPTYBOX:Int
static inline var ICON_TARGET:Int
static inline var ICON_TARGET_SMALL_FILL:Int
static inline var ICON_TARGET_BIG_FILL:Int
static inline var ICON_TARGET_MOVE_FILL:Int
static inline var ICON_CURSOR_MOVE_FILL:Int
static inline var ICON_CURSOR_SCALE_FILL:Int
static inline var ICON_CURSOR_SCALE_RIGHT_FILL:Int
static inline var ICON_CURSOR_SCALE_LEFT_FILL:Int
static inline var ICON_UNDO_FILL:Int
static inline var ICON_REDO_FILL:Int
static inline var ICON_REREDO_FILL:Int
static inline var ICON_MUTATE_FILL:Int
static inline var ICON_ROTATE_FILL:Int
static inline var ICON_REPEAT_FILL:Int
static inline var ICON_SHUFFLE_FILL:Int
static inline var ICON_EMPTYBOX_SMALL:Int
static inline var ICON_BOX:Int
static inline var ICON_BOX_TOP:Int
static inline var ICON_BOX_TOP_RIGHT:Int
static inline var ICON_BOX_RIGHT:Int
static inline var ICON_BOX_BOTTOM_RIGHT:Int
static inline var ICON_BOX_BOTTOM:Int
static inline var ICON_BOX_BOTTOM_LEFT:Int
static inline var ICON_BOX_LEFT:Int
static inline var ICON_BOX_TOP_LEFT:Int
static inline var ICON_BOX_CENTER:Int
static inline var ICON_BOX_CIRCLE_MASK:Int
static inline var ICON_POT:Int
static inline var ICON_ALPHA_MULTIPLY:Int
static inline var ICON_ALPHA_CLEAR:Int
static inline var ICON_DITHERING:Int
static inline var ICON_MIPMAPS:Int
static inline var ICON_BOX_GRID:Int
static inline var ICON_GRID:Int
static inline var ICON_BOX_CORNERS_SMALL:Int
static inline var ICON_BOX_CORNERS_BIG:Int
static inline var ICON_FOUR_BOXES:Int
static inline var ICON_GRID_FILL:Int
static inline var ICON_BOX_MULTISIZE:Int
static inline var ICON_ZOOM_SMALL:Int
static inline var ICON_ZOOM_MEDIUM:Int
static inline var ICON_ZOOM_BIG:Int
static inline var ICON_ZOOM_ALL:Int
static inline var ICON_ZOOM_CENTER:Int
static inline var ICON_BOX_DOTS_SMALL:Int
static inline var ICON_BOX_DOTS_BIG:Int
static inline var ICON_BOX_CONCENTRIC:Int
static inline var ICON_BOX_GRID_BIG:Int
static inline var ICON_OK_TICK:Int
static inline var ICON_CROSS:Int
static inline var ICON_ARROW_LEFT:Int
static inline var ICON_ARROW_RIGHT:Int
static inline var ICON_ARROW_DOWN:Int
static inline var ICON_ARROW_UP:Int
static inline var ICON_ARROW_LEFT_FILL:Int
static inline var ICON_ARROW_RIGHT_FILL:Int
static inline var ICON_ARROW_DOWN_FILL:Int
static inline var ICON_ARROW_UP_FILL:Int
static inline var ICON_AUDIO:Int
static inline var ICON_FX:Int
static inline var ICON_WAVE:Int
static inline var ICON_WAVE_SINUS:Int
static inline var ICON_WAVE_SQUARE:Int
static inline var ICON_WAVE_TRIANGULAR:Int
static inline var ICON_CROSS_SMALL:Int
static inline var ICON_PLAYER_PREVIOUS:Int
static inline var ICON_PLAYER_PLAY_BACK:Int
static inline var ICON_PLAYER_PLAY:Int
static inline var ICON_PLAYER_PAUSE:Int
static inline var ICON_PLAYER_STOP:Int
static inline var ICON_PLAYER_NEXT:Int
static inline var ICON_PLAYER_RECORD:Int
static inline var ICON_MAGNET:Int
static inline var ICON_LOCK_CLOSE:Int
static inline var ICON_LOCK_OPEN:Int
static inline var ICON_CLOCK:Int
static inline var ICON_TOOLS:Int
static inline var ICON_GEAR:Int
static inline var ICON_GEAR_BIG:Int
static inline var ICON_BIN:Int
static inline var ICON_HAND_POINTER:Int
static inline var ICON_LASER:Int
static inline var ICON_COIN:Int
static inline var ICON_EXPLOSION:Int
static inline var ICON_1UP:Int
static inline var ICON_PLAYER:Int
static inline var ICON_PLAYER_JUMP:Int
static inline var ICON_KEY:Int
static inline var ICON_DEMON:Int
static inline var ICON_TEXT_POPUP:Int
static inline var ICON_GEAR_EX:Int
static inline var ICON_CRACK:Int
static inline var ICON_CRACK_POINTS:Int
static inline var ICON_STAR:Int
static inline var ICON_DOOR:Int
static inline var ICON_EXIT:Int
static inline var ICON_MODE_2D:Int
static inline var ICON_MODE_3D:Int
static inline var ICON_CUBE:Int
static inline var ICON_CUBE_FACE_TOP:Int
static inline var ICON_CUBE_FACE_LEFT:Int
static inline var ICON_CUBE_FACE_FRONT:Int
static inline var ICON_CUBE_FACE_BOTTOM:Int
static inline var ICON_CUBE_FACE_RIGHT:Int
static inline var ICON_CUBE_FACE_BACK:Int
static inline var ICON_CAMERA:Int
static inline var ICON_SPECIAL:Int
static inline var ICON_LINK_NET:Int
static inline var ICON_LINK_BOXES:Int
static inline var ICON_LINK_MULTI:Int
static inline var ICON_LINK:Int
static inline var ICON_LINK_BROKE:Int
static inline var ICON_TEXT_NOTES:Int
static inline var ICON_NOTEBOOK:Int
static inline var ICON_SUITCASE:Int
static inline var ICON_SUITCASE_ZIP:Int
static inline var ICON_MAILBOX:Int
static inline var ICON_MONITOR:Int
static inline var ICON_PRINTER:Int
static inline var ICON_PHOTO_CAMERA:Int
static inline var ICON_PHOTO_CAMERA_FLASH:Int
static inline var ICON_HOUSE:Int
static inline var ICON_HEART:Int
static inline var ICON_CORNER:Int
static inline var ICON_VERTICAL_BARS:Int
static inline var ICON_VERTICAL_BARS_FILL:Int
static inline var ICON_LIFE_BARS:Int
static inline var ICON_INFO:Int
static inline var ICON_CROSSLINE:Int
static inline var ICON_HELP:Int
static inline var ICON_FILETYPE_ALPHA:Int
static inline var ICON_FILETYPE_HOME:Int
static inline var ICON_LAYERS_VISIBLE:Int
static inline var ICON_LAYERS:Int
static inline var ICON_WINDOW:Int
static inline var ICON_HIDPI:Int
static inline var ICON_FILETYPE_BINARY:Int
static inline var ICON_HEX:Int
static inline var ICON_SHIELD:Int
static inline var ICON_FILE_NEW:Int
static inline var ICON_FOLDER_ADD:Int
static inline var ICON_ALARM:Int
static inline var ICON_CPU:Int
static inline var ICON_ROM:Int
static inline var ICON_STEP_OVER:Int
static inline var ICON_STEP_INTO:Int
static inline var ICON_STEP_OUT:Int
static inline var ICON_RESTART:Int
static inline var ICON_BREAKPOINT_ON:Int
static inline var ICON_BREAKPOINT_OFF:Int
static inline var ICON_BURGER_MENU:Int
static inline var ICON_CASE_SENSITIVE:Int
static inline var ICON_REG_EXP:Int
static inline var ICON_FOLDER:Int
static inline var ICON_FILE:Int
static inline var ICON_SAND_TIMER:Int
static inline var ICON_WARNING:Int
static inline var ICON_HELP_BOX:Int
static inline var ICON_INFO_BOX:Int
static inline var ICON_PRIORITY:Int
static inline var ICON_LAYERS_ISO:Int
static inline var ICON_LAYERS2:Int
static inline var ICON_MLAYERS:Int
static inline var ICON_MAPS:Int
static inline var ICON_HOT:Int
static inline var ICON_229:Int
static inline var ICON_230:Int
static inline var ICON_231:Int
static inline var ICON_232:Int
static inline var ICON_233:Int
static inline var ICON_234:Int
static inline var ICON_235:Int
static inline var ICON_236:Int
static inline var ICON_237:Int
static inline var ICON_238:Int
static inline var ICON_239:Int
static inline var ICON_240:Int
static inline var ICON_241:Int
static inline var ICON_242:Int
static inline var ICON_243:Int
static inline var ICON_244:Int
static inline var ICON_245:Int
static inline var ICON_246:Int
static inline var ICON_247:Int
static inline var ICON_248:Int
static inline var ICON_249:Int
static inline var ICON_250:Int
static inline var ICON_251:Int
static inline var ICON_252:Int
static inline var ICON_253:Int
static inline var ICON_254:Int
static inline var ICON_255:Int
```

- `ICON_NONE`: raygui.h's `ICON_NONE`.
- `ICON_FOLDER_FILE_OPEN`: raygui.h's `ICON_FOLDER_FILE_OPEN`.
- `ICON_FILE_SAVE_CLASSIC`: raygui.h's `ICON_FILE_SAVE_CLASSIC`.
- `ICON_FOLDER_OPEN`: raygui.h's `ICON_FOLDER_OPEN`.
- `ICON_FOLDER_SAVE`: raygui.h's `ICON_FOLDER_SAVE`.
- `ICON_FILE_OPEN`: raygui.h's `ICON_FILE_OPEN`.
- `ICON_FILE_SAVE`: raygui.h's `ICON_FILE_SAVE`.
- `ICON_FILE_EXPORT`: raygui.h's `ICON_FILE_EXPORT`.
- `ICON_FILE_ADD`: raygui.h's `ICON_FILE_ADD`.
- `ICON_FILE_DELETE`: raygui.h's `ICON_FILE_DELETE`.
- `ICON_FILETYPE_TEXT`: raygui.h's `ICON_FILETYPE_TEXT`.
- `ICON_FILETYPE_AUDIO`: raygui.h's `ICON_FILETYPE_AUDIO`.
- `ICON_FILETYPE_IMAGE`: raygui.h's `ICON_FILETYPE_IMAGE`.
- `ICON_FILETYPE_PLAY`: raygui.h's `ICON_FILETYPE_PLAY`.
- `ICON_FILETYPE_VIDEO`: raygui.h's `ICON_FILETYPE_VIDEO`.
- `ICON_FILETYPE_INFO`: raygui.h's `ICON_FILETYPE_INFO`.
- `ICON_FILE_COPY`: raygui.h's `ICON_FILE_COPY`.
- `ICON_FILE_CUT`: raygui.h's `ICON_FILE_CUT`.
- `ICON_FILE_PASTE`: raygui.h's `ICON_FILE_PASTE`.
- `ICON_CURSOR_HAND`: raygui.h's `ICON_CURSOR_HAND`.
- `ICON_CURSOR_POINTER`: raygui.h's `ICON_CURSOR_POINTER`.
- `ICON_CURSOR_CLASSIC`: raygui.h's `ICON_CURSOR_CLASSIC`.
- `ICON_PENCIL`: raygui.h's `ICON_PENCIL`.
- `ICON_PENCIL_BIG`: raygui.h's `ICON_PENCIL_BIG`.
- `ICON_BRUSH_CLASSIC`: raygui.h's `ICON_BRUSH_CLASSIC`.
- `ICON_BRUSH_PAINTER`: raygui.h's `ICON_BRUSH_PAINTER`.
- `ICON_WATER_DROP`: raygui.h's `ICON_WATER_DROP`.
- `ICON_COLOR_PICKER`: raygui.h's `ICON_COLOR_PICKER`.
- `ICON_RUBBER`: raygui.h's `ICON_RUBBER`.
- `ICON_COLOR_BUCKET`: raygui.h's `ICON_COLOR_BUCKET`.
- `ICON_TEXT_T`: raygui.h's `ICON_TEXT_T`.
- `ICON_TEXT_A`: raygui.h's `ICON_TEXT_A`.
- `ICON_SCALE`: raygui.h's `ICON_SCALE`.
- `ICON_RESIZE`: raygui.h's `ICON_RESIZE`.
- `ICON_FILTER_POINT`: raygui.h's `ICON_FILTER_POINT`.
- `ICON_FILTER_BILINEAR`: raygui.h's `ICON_FILTER_BILINEAR`.
- `ICON_CROP`: raygui.h's `ICON_CROP`.
- `ICON_CROP_ALPHA`: raygui.h's `ICON_CROP_ALPHA`.
- `ICON_SQUARE_TOGGLE`: raygui.h's `ICON_SQUARE_TOGGLE`.
- `ICON_SYMMETRY`: raygui.h's `ICON_SYMMETRY`.
- `ICON_SYMMETRY_HORIZONTAL`: raygui.h's `ICON_SYMMETRY_HORIZONTAL`.
- `ICON_SYMMETRY_VERTICAL`: raygui.h's `ICON_SYMMETRY_VERTICAL`.
- `ICON_LENS`: raygui.h's `ICON_LENS`.
- `ICON_LENS_BIG`: raygui.h's `ICON_LENS_BIG`.
- `ICON_EYE_ON`: raygui.h's `ICON_EYE_ON`.
- `ICON_EYE_OFF`: raygui.h's `ICON_EYE_OFF`.
- `ICON_FILTER_TOP`: raygui.h's `ICON_FILTER_TOP`.
- `ICON_FILTER`: raygui.h's `ICON_FILTER`.
- `ICON_TARGET_POINT`: raygui.h's `ICON_TARGET_POINT`.
- `ICON_TARGET_SMALL`: raygui.h's `ICON_TARGET_SMALL`.
- `ICON_TARGET_BIG`: raygui.h's `ICON_TARGET_BIG`.
- `ICON_TARGET_MOVE`: raygui.h's `ICON_TARGET_MOVE`.
- `ICON_CURSOR_MOVE`: raygui.h's `ICON_CURSOR_MOVE`.
- `ICON_CURSOR_SCALE`: raygui.h's `ICON_CURSOR_SCALE`.
- `ICON_CURSOR_SCALE_RIGHT`: raygui.h's `ICON_CURSOR_SCALE_RIGHT`.
- `ICON_CURSOR_SCALE_LEFT`: raygui.h's `ICON_CURSOR_SCALE_LEFT`.
- `ICON_UNDO`: raygui.h's `ICON_UNDO`.
- `ICON_REDO`: raygui.h's `ICON_REDO`.
- `ICON_REREDO`: raygui.h's `ICON_REREDO`.
- `ICON_MUTATE`: raygui.h's `ICON_MUTATE`.
- `ICON_ROTATE`: raygui.h's `ICON_ROTATE`.
- `ICON_REPEAT`: raygui.h's `ICON_REPEAT`.
- `ICON_SHUFFLE`: raygui.h's `ICON_SHUFFLE`.
- `ICON_EMPTYBOX`: raygui.h's `ICON_EMPTYBOX`.
- `ICON_TARGET`: raygui.h's `ICON_TARGET`.
- `ICON_TARGET_SMALL_FILL`: raygui.h's `ICON_TARGET_SMALL_FILL`.
- `ICON_TARGET_BIG_FILL`: raygui.h's `ICON_TARGET_BIG_FILL`.
- `ICON_TARGET_MOVE_FILL`: raygui.h's `ICON_TARGET_MOVE_FILL`.
- `ICON_CURSOR_MOVE_FILL`: raygui.h's `ICON_CURSOR_MOVE_FILL`.
- `ICON_CURSOR_SCALE_FILL`: raygui.h's `ICON_CURSOR_SCALE_FILL`.
- `ICON_CURSOR_SCALE_RIGHT_FILL`: raygui.h's `ICON_CURSOR_SCALE_RIGHT_FILL`.
- `ICON_CURSOR_SCALE_LEFT_FILL`: raygui.h's `ICON_CURSOR_SCALE_LEFT_FILL`.
- `ICON_UNDO_FILL`: raygui.h's `ICON_UNDO_FILL`.
- `ICON_REDO_FILL`: raygui.h's `ICON_REDO_FILL`.
- `ICON_REREDO_FILL`: raygui.h's `ICON_REREDO_FILL`.
- `ICON_MUTATE_FILL`: raygui.h's `ICON_MUTATE_FILL`.
- `ICON_ROTATE_FILL`: raygui.h's `ICON_ROTATE_FILL`.
- `ICON_REPEAT_FILL`: raygui.h's `ICON_REPEAT_FILL`.
- `ICON_SHUFFLE_FILL`: raygui.h's `ICON_SHUFFLE_FILL`.
- `ICON_EMPTYBOX_SMALL`: raygui.h's `ICON_EMPTYBOX_SMALL`.
- `ICON_BOX`: raygui.h's `ICON_BOX`.
- `ICON_BOX_TOP`: raygui.h's `ICON_BOX_TOP`.
- `ICON_BOX_TOP_RIGHT`: raygui.h's `ICON_BOX_TOP_RIGHT`.
- `ICON_BOX_RIGHT`: raygui.h's `ICON_BOX_RIGHT`.
- `ICON_BOX_BOTTOM_RIGHT`: raygui.h's `ICON_BOX_BOTTOM_RIGHT`.
- `ICON_BOX_BOTTOM`: raygui.h's `ICON_BOX_BOTTOM`.
- `ICON_BOX_BOTTOM_LEFT`: raygui.h's `ICON_BOX_BOTTOM_LEFT`.
- `ICON_BOX_LEFT`: raygui.h's `ICON_BOX_LEFT`.
- `ICON_BOX_TOP_LEFT`: raygui.h's `ICON_BOX_TOP_LEFT`.
- `ICON_BOX_CENTER`: raygui.h's `ICON_BOX_CENTER`.
- `ICON_BOX_CIRCLE_MASK`: raygui.h's `ICON_BOX_CIRCLE_MASK`.
- `ICON_POT`: raygui.h's `ICON_POT`.
- `ICON_ALPHA_MULTIPLY`: raygui.h's `ICON_ALPHA_MULTIPLY`.
- `ICON_ALPHA_CLEAR`: raygui.h's `ICON_ALPHA_CLEAR`.
- `ICON_DITHERING`: raygui.h's `ICON_DITHERING`.
- `ICON_MIPMAPS`: raygui.h's `ICON_MIPMAPS`.
- `ICON_BOX_GRID`: raygui.h's `ICON_BOX_GRID`.
- `ICON_GRID`: raygui.h's `ICON_GRID`.
- `ICON_BOX_CORNERS_SMALL`: raygui.h's `ICON_BOX_CORNERS_SMALL`.
- `ICON_BOX_CORNERS_BIG`: raygui.h's `ICON_BOX_CORNERS_BIG`.
- `ICON_FOUR_BOXES`: raygui.h's `ICON_FOUR_BOXES`.
- `ICON_GRID_FILL`: raygui.h's `ICON_GRID_FILL`.
- `ICON_BOX_MULTISIZE`: raygui.h's `ICON_BOX_MULTISIZE`.
- `ICON_ZOOM_SMALL`: raygui.h's `ICON_ZOOM_SMALL`.
- `ICON_ZOOM_MEDIUM`: raygui.h's `ICON_ZOOM_MEDIUM`.
- `ICON_ZOOM_BIG`: raygui.h's `ICON_ZOOM_BIG`.
- `ICON_ZOOM_ALL`: raygui.h's `ICON_ZOOM_ALL`.
- `ICON_ZOOM_CENTER`: raygui.h's `ICON_ZOOM_CENTER`.
- `ICON_BOX_DOTS_SMALL`: raygui.h's `ICON_BOX_DOTS_SMALL`.
- `ICON_BOX_DOTS_BIG`: raygui.h's `ICON_BOX_DOTS_BIG`.
- `ICON_BOX_CONCENTRIC`: raygui.h's `ICON_BOX_CONCENTRIC`.
- `ICON_BOX_GRID_BIG`: raygui.h's `ICON_BOX_GRID_BIG`.
- `ICON_OK_TICK`: raygui.h's `ICON_OK_TICK`.
- `ICON_CROSS`: raygui.h's `ICON_CROSS`.
- `ICON_ARROW_LEFT`: raygui.h's `ICON_ARROW_LEFT`.
- `ICON_ARROW_RIGHT`: raygui.h's `ICON_ARROW_RIGHT`.
- `ICON_ARROW_DOWN`: raygui.h's `ICON_ARROW_DOWN`.
- `ICON_ARROW_UP`: raygui.h's `ICON_ARROW_UP`.
- `ICON_ARROW_LEFT_FILL`: raygui.h's `ICON_ARROW_LEFT_FILL`.
- `ICON_ARROW_RIGHT_FILL`: raygui.h's `ICON_ARROW_RIGHT_FILL`.
- `ICON_ARROW_DOWN_FILL`: raygui.h's `ICON_ARROW_DOWN_FILL`.
- `ICON_ARROW_UP_FILL`: raygui.h's `ICON_ARROW_UP_FILL`.
- `ICON_AUDIO`: raygui.h's `ICON_AUDIO`.
- `ICON_FX`: raygui.h's `ICON_FX`.
- `ICON_WAVE`: raygui.h's `ICON_WAVE`.
- `ICON_WAVE_SINUS`: raygui.h's `ICON_WAVE_SINUS`.
- `ICON_WAVE_SQUARE`: raygui.h's `ICON_WAVE_SQUARE`.
- `ICON_WAVE_TRIANGULAR`: raygui.h's `ICON_WAVE_TRIANGULAR`.
- `ICON_CROSS_SMALL`: raygui.h's `ICON_CROSS_SMALL`.
- `ICON_PLAYER_PREVIOUS`: raygui.h's `ICON_PLAYER_PREVIOUS`.
- `ICON_PLAYER_PLAY_BACK`: raygui.h's `ICON_PLAYER_PLAY_BACK`.
- `ICON_PLAYER_PLAY`: raygui.h's `ICON_PLAYER_PLAY`.
- `ICON_PLAYER_PAUSE`: raygui.h's `ICON_PLAYER_PAUSE`.
- `ICON_PLAYER_STOP`: raygui.h's `ICON_PLAYER_STOP`.
- `ICON_PLAYER_NEXT`: raygui.h's `ICON_PLAYER_NEXT`.
- `ICON_PLAYER_RECORD`: raygui.h's `ICON_PLAYER_RECORD`.
- `ICON_MAGNET`: raygui.h's `ICON_MAGNET`.
- `ICON_LOCK_CLOSE`: raygui.h's `ICON_LOCK_CLOSE`.
- `ICON_LOCK_OPEN`: raygui.h's `ICON_LOCK_OPEN`.
- `ICON_CLOCK`: raygui.h's `ICON_CLOCK`.
- `ICON_TOOLS`: raygui.h's `ICON_TOOLS`.
- `ICON_GEAR`: raygui.h's `ICON_GEAR`.
- `ICON_GEAR_BIG`: raygui.h's `ICON_GEAR_BIG`.
- `ICON_BIN`: raygui.h's `ICON_BIN`.
- `ICON_HAND_POINTER`: raygui.h's `ICON_HAND_POINTER`.
- `ICON_LASER`: raygui.h's `ICON_LASER`.
- `ICON_COIN`: raygui.h's `ICON_COIN`.
- `ICON_EXPLOSION`: raygui.h's `ICON_EXPLOSION`.
- `ICON_1UP`: raygui.h's `ICON_1UP`.
- `ICON_PLAYER`: raygui.h's `ICON_PLAYER`.
- `ICON_PLAYER_JUMP`: raygui.h's `ICON_PLAYER_JUMP`.
- `ICON_KEY`: raygui.h's `ICON_KEY`.
- `ICON_DEMON`: raygui.h's `ICON_DEMON`.
- `ICON_TEXT_POPUP`: raygui.h's `ICON_TEXT_POPUP`.
- `ICON_GEAR_EX`: raygui.h's `ICON_GEAR_EX`.
- `ICON_CRACK`: raygui.h's `ICON_CRACK`.
- `ICON_CRACK_POINTS`: raygui.h's `ICON_CRACK_POINTS`.
- `ICON_STAR`: raygui.h's `ICON_STAR`.
- `ICON_DOOR`: raygui.h's `ICON_DOOR`.
- `ICON_EXIT`: raygui.h's `ICON_EXIT`.
- `ICON_MODE_2D`: raygui.h's `ICON_MODE_2D`.
- `ICON_MODE_3D`: raygui.h's `ICON_MODE_3D`.
- `ICON_CUBE`: raygui.h's `ICON_CUBE`.
- `ICON_CUBE_FACE_TOP`: raygui.h's `ICON_CUBE_FACE_TOP`.
- `ICON_CUBE_FACE_LEFT`: raygui.h's `ICON_CUBE_FACE_LEFT`.
- `ICON_CUBE_FACE_FRONT`: raygui.h's `ICON_CUBE_FACE_FRONT`.
- `ICON_CUBE_FACE_BOTTOM`: raygui.h's `ICON_CUBE_FACE_BOTTOM`.
- `ICON_CUBE_FACE_RIGHT`: raygui.h's `ICON_CUBE_FACE_RIGHT`.
- `ICON_CUBE_FACE_BACK`: raygui.h's `ICON_CUBE_FACE_BACK`.
- `ICON_CAMERA`: raygui.h's `ICON_CAMERA`.
- `ICON_SPECIAL`: raygui.h's `ICON_SPECIAL`.
- `ICON_LINK_NET`: raygui.h's `ICON_LINK_NET`.
- `ICON_LINK_BOXES`: raygui.h's `ICON_LINK_BOXES`.
- `ICON_LINK_MULTI`: raygui.h's `ICON_LINK_MULTI`.
- `ICON_LINK`: raygui.h's `ICON_LINK`.
- `ICON_LINK_BROKE`: raygui.h's `ICON_LINK_BROKE`.
- `ICON_TEXT_NOTES`: raygui.h's `ICON_TEXT_NOTES`.
- `ICON_NOTEBOOK`: raygui.h's `ICON_NOTEBOOK`.
- `ICON_SUITCASE`: raygui.h's `ICON_SUITCASE`.
- `ICON_SUITCASE_ZIP`: raygui.h's `ICON_SUITCASE_ZIP`.
- `ICON_MAILBOX`: raygui.h's `ICON_MAILBOX`.
- `ICON_MONITOR`: raygui.h's `ICON_MONITOR`.
- `ICON_PRINTER`: raygui.h's `ICON_PRINTER`.
- `ICON_PHOTO_CAMERA`: raygui.h's `ICON_PHOTO_CAMERA`.
- `ICON_PHOTO_CAMERA_FLASH`: raygui.h's `ICON_PHOTO_CAMERA_FLASH`.
- `ICON_HOUSE`: raygui.h's `ICON_HOUSE`.
- `ICON_HEART`: raygui.h's `ICON_HEART`.
- `ICON_CORNER`: raygui.h's `ICON_CORNER`.
- `ICON_VERTICAL_BARS`: raygui.h's `ICON_VERTICAL_BARS`.
- `ICON_VERTICAL_BARS_FILL`: raygui.h's `ICON_VERTICAL_BARS_FILL`.
- `ICON_LIFE_BARS`: raygui.h's `ICON_LIFE_BARS`.
- `ICON_INFO`: raygui.h's `ICON_INFO`.
- `ICON_CROSSLINE`: raygui.h's `ICON_CROSSLINE`.
- `ICON_HELP`: raygui.h's `ICON_HELP`.
- `ICON_FILETYPE_ALPHA`: raygui.h's `ICON_FILETYPE_ALPHA`.
- `ICON_FILETYPE_HOME`: raygui.h's `ICON_FILETYPE_HOME`.
- `ICON_LAYERS_VISIBLE`: raygui.h's `ICON_LAYERS_VISIBLE`.
- `ICON_LAYERS`: raygui.h's `ICON_LAYERS`.
- `ICON_WINDOW`: raygui.h's `ICON_WINDOW`.
- `ICON_HIDPI`: raygui.h's `ICON_HIDPI`.
- `ICON_FILETYPE_BINARY`: raygui.h's `ICON_FILETYPE_BINARY`.
- `ICON_HEX`: raygui.h's `ICON_HEX`.
- `ICON_SHIELD`: raygui.h's `ICON_SHIELD`.
- `ICON_FILE_NEW`: raygui.h's `ICON_FILE_NEW`.
- `ICON_FOLDER_ADD`: raygui.h's `ICON_FOLDER_ADD`.
- `ICON_ALARM`: raygui.h's `ICON_ALARM`.
- `ICON_CPU`: raygui.h's `ICON_CPU`.
- `ICON_ROM`: raygui.h's `ICON_ROM`.
- `ICON_STEP_OVER`: raygui.h's `ICON_STEP_OVER`.
- `ICON_STEP_INTO`: raygui.h's `ICON_STEP_INTO`.
- `ICON_STEP_OUT`: raygui.h's `ICON_STEP_OUT`.
- `ICON_RESTART`: raygui.h's `ICON_RESTART`.
- `ICON_BREAKPOINT_ON`: raygui.h's `ICON_BREAKPOINT_ON`.
- `ICON_BREAKPOINT_OFF`: raygui.h's `ICON_BREAKPOINT_OFF`.
- `ICON_BURGER_MENU`: raygui.h's `ICON_BURGER_MENU`.
- `ICON_CASE_SENSITIVE`: raygui.h's `ICON_CASE_SENSITIVE`.
- `ICON_REG_EXP`: raygui.h's `ICON_REG_EXP`.
- `ICON_FOLDER`: raygui.h's `ICON_FOLDER`.
- `ICON_FILE`: raygui.h's `ICON_FILE`.
- `ICON_SAND_TIMER`: raygui.h's `ICON_SAND_TIMER`.
- `ICON_WARNING`: raygui.h's `ICON_WARNING`.
- `ICON_HELP_BOX`: raygui.h's `ICON_HELP_BOX`.
- `ICON_INFO_BOX`: raygui.h's `ICON_INFO_BOX`.
- `ICON_PRIORITY`: raygui.h's `ICON_PRIORITY`.
- `ICON_LAYERS_ISO`: raygui.h's `ICON_LAYERS_ISO`.
- `ICON_LAYERS2`: raygui.h's `ICON_LAYERS2`.
- `ICON_MLAYERS`: raygui.h's `ICON_MLAYERS`.
- `ICON_MAPS`: raygui.h's `ICON_MAPS`.
- `ICON_HOT`: raygui.h's `ICON_HOT`.
- `ICON_229`: raygui.h's `ICON_229`.
- `ICON_230`: raygui.h's `ICON_230`.
- `ICON_231`: raygui.h's `ICON_231`.
- `ICON_232`: raygui.h's `ICON_232`.
- `ICON_233`: raygui.h's `ICON_233`.
- `ICON_234`: raygui.h's `ICON_234`.
- `ICON_235`: raygui.h's `ICON_235`.
- `ICON_236`: raygui.h's `ICON_236`.
- `ICON_237`: raygui.h's `ICON_237`.
- `ICON_238`: raygui.h's `ICON_238`.
- `ICON_239`: raygui.h's `ICON_239`.
- `ICON_240`: raygui.h's `ICON_240`.
- `ICON_241`: raygui.h's `ICON_241`.
- `ICON_242`: raygui.h's `ICON_242`.
- `ICON_243`: raygui.h's `ICON_243`.
- `ICON_244`: raygui.h's `ICON_244`.
- `ICON_245`: raygui.h's `ICON_245`.
- `ICON_246`: raygui.h's `ICON_246`.
- `ICON_247`: raygui.h's `ICON_247`.
- `ICON_248`: raygui.h's `ICON_248`.
- `ICON_249`: raygui.h's `ICON_249`.
- `ICON_250`: raygui.h's `ICON_250`.
- `ICON_251`: raygui.h's `ICON_251`.
- `ICON_252`: raygui.h's `ICON_252`.
- `ICON_253`: raygui.h's `ICON_253`.
- `ICON_254`: raygui.h's `ICON_254`.
- `ICON_255`: raygui.h's `ICON_255`.

## raygui.h's defines


```haxe
static inline var RAYGUI_VERSION_MAJOR:Int
static inline var RAYGUI_VERSION_MINOR:Int
static inline var RAYGUI_VERSION_PATCH:Int
static inline var SCROLLBAR_LEFT_SIDE:Int
static inline var SCROLLBAR_RIGHT_SIDE:Int
```

- `RAYGUI_VERSION_MAJOR`: raygui.h's `RAYGUI_VERSION_MAJOR`.
- `RAYGUI_VERSION_MINOR`: raygui.h's `RAYGUI_VERSION_MINOR`.
- `RAYGUI_VERSION_PATCH`: raygui.h's `RAYGUI_VERSION_PATCH`.
- `SCROLLBAR_LEFT_SIDE`: raygui.h's `SCROLLBAR_LEFT_SIDE`.
- `SCROLLBAR_RIGHT_SIDE`: raygui.h's `SCROLLBAR_RIGHT_SIDE`.

## raygui: its state, style, icons and tooltips


```haxe
static function GuiEnable():Void
static function GuiDisable():Void
static function GuiLock():Void
static function GuiUnlock():Void
static function GuiIsLocked():Bool
static function GuiSetAlpha(alpha:Float):Void
static function GuiSetState(state:Int):Void
static function GuiGetState():Int
static function GuiSetFont(font:Font):Void
static function GuiGetFont():Font
static function GuiSetStyle(control:Int, property:Int, value:Int):Void
static function GuiGetStyle(control:Int, property:Int):Int
static function GuiLoadStyleDefault():Void
static function GuiEnableTooltip():Void
static function GuiDisableTooltip():Void
static function GuiSetTooltip(tooltip:String):Void
static function GuiIconText(iconId:Int, text:String):String
static function GuiSetIconScale(scale:Int):Void
static function GuiGetIcons():Array<Int>
static function GuiDrawIcon(iconId:Int, posX:Int, posY:Int, pixelSize:Int, color:Color):Void
```

- `GuiEnable`: Enables the controls again after `GuiDisable`.
  A state other than disabled, set with `GuiSetState`, is unchanged.
- `GuiDisable`: Disables the controls, so they draw disabled and take no input. See `GuiLock` for stopping the controls' input while they keep their look.
  A state other than normal, set with `GuiSetState`, is unchanged.
- `GuiLock`: Locks the controls until `GuiUnlock`, so they draw as they are and take no input. See `GuiDisable` for drawing the controls disabled.
- `GuiUnlock`: Unlocks the controls after `GuiLock`.
- `GuiIsLocked`: Returns whether the controls are locked.
  - returns: True between `GuiLock` and `GuiUnlock`.
- `GuiSetAlpha`: Sets how opaque the controls are drawn.
  - `alpha`: 0 for clear to 1 for opaque, clamped to that range.
- `GuiSetState`: Sets the state every control is drawn in.
  - `state`: The state (`STATE_NORMAL`, `STATE_FOCUSED`, `STATE_PRESSED` or `STATE_DISABLED`).

  With `STATE_NORMAL`, each control follows the mouse.

  Any other state is forced on every control.
- `GuiGetState`: Returns the state set with `GuiSetState`.
  - returns: The state (`STATE_*`).
- `GuiSetFont`: Sets the font the controls draw their text in.
  - `font`: The font.

  A font with no texture is ignored.

  Loads the default style first when no style is loaded yet, so a control's first use of the style keeps this font.
- `GuiGetFont`: Returns the font the controls draw their text in.
  - returns: The font.

  Once the style is loaded, the font is raylib's default font or the one set with `GuiSetFont`.

  Before anything is drawn or styled, the font is an empty font.
- `GuiSetStyle`: Sets one property of a control's style.
  - `control`: The control (`DEFAULT`, `LABEL`, `BUTTON` and the rest).
  - `property`: The property (`BORDER_COLOR_NORMAL`, `TEXT_SIZE`, `SLIDER_WIDTH` and the rest).
  - `value`: Its value: a color as 0xRRGGBBAA, a size in pixels, or one of the property's values.

  Setting a base property of `DEFAULT` (below 16) sets that property for every control.

  Loads the default style first when no style is loaded yet.
- `GuiGetStyle`: Returns one property of a control's style.
  - `control`: The control (`DEFAULT`, `LABEL`, `BUTTON` and the rest).
  - `property`: The property (`BORDER_COLOR_NORMAL`, `TEXT_SIZE`, `SLIDER_WIDTH` and the rest).
  - returns: Its value: a color as 0xRRGGBBAA, a size in pixels, or one of the property's values.

  Loads the default style first when no style is loaded yet.
- `GuiLoadStyleDefault`: Loads raygui's default style, its light theme, over every control's colors, borders, text and sizes.
  Sets the font back to raylib's default font and unloads the font set before.

  Sets raylib's shapes to draw from the default font's white glyph, so text and shapes share one texture.
- `GuiEnableTooltip`: Turns tooltips on, so a control the mouse is over draws the text set with `GuiSetTooltip` below it.
- `GuiDisableTooltip`: Turns tooltips off after `GuiEnableTooltip`.
- `GuiSetTooltip`: Sets the tooltip the next controls show while tooltips are on, until the next call. See `GuiEnableTooltip` for turning tooltips on.
  - `tooltip`: The text, or null for none.
- `GuiIconText`: Returns a control's text with an icon before it, as raygui writes one.
  - `iconId`: The icon (`ICON_*`).
  - `text`: The text, or null for the icon alone.
  - returns: The text, as "#012#text".

  The icon is "#", the icon's number padded to three characters with a minus sign counting as one (`#012#`, `#-01#`), then "#".
- `GuiSetIconScale`: Sets the size icons are drawn at in text, a whole multiple of their 16 pixels.
  - `scale`: The scale, 1 or more; less is ignored.
- `GuiGetIcons`: Returns the icons' bits, which a program may change.
  - returns: The icons, 2048 words.

  The bits are laid out as:

  - eight 32-bit words an icon, the icon's first at `ICON_*` times 8 - two 16-pixel rows a word - bit 0 the leftmost pixel of the word's first row
- `GuiDrawIcon`: Draws an icon, each of its pixels a square.
  - `iconId`: The icon (`ICON_*`).
  - `posX`: Its left edge, in pixels.
  - `posY`: Its top edge, in pixels.
  - `pixelSize`: The size of each of its pixels.
  - `color`: The color.

  Fades the icon by the alpha set with `GuiSetAlpha`.

## raygui: its controls


```haxe
static function GuiWindowBox(bounds:Rectangle, title:String):Int
static function GuiGroupBox(bounds:Rectangle, text:String):Int
static function GuiLine(bounds:Rectangle, text:String):Int
static function GuiPanel(bounds:Rectangle, text:String):Int
static function GuiTabBar(bounds:Rectangle, text:Array<String>, count:Int, active:Array<Int>):Int
static function GuiScrollPanel(bounds:Rectangle, text:String, content:Rectangle, scroll:Vector2, view:Rectangle):Int
static function GuiLabel(bounds:Rectangle, text:String):Int
static function GuiButton(bounds:Rectangle, text:String):Int
static function GuiLabelButton(bounds:Rectangle, text:String):Int
static function GuiToggle(bounds:Rectangle, text:String, active:Array<Bool>):Int
static function GuiToggleGroup(bounds:Rectangle, text:String, active:Array<Int>):Int
static function GuiToggleSlider(bounds:Rectangle, text:String, active:Array<Int>):Int
static function GuiCheckBox(bounds:Rectangle, text:String, checked:Array<Bool>):Int
static function GuiComboBox(bounds:Rectangle, text:String, active:Array<Int>):Int
static function GuiDropdownBox(bounds:Rectangle, text:String, active:Array<Int>, editMode:Bool):Int
static function GuiTextBox(bounds:Rectangle, text:Array<String>, textSize:Int, editMode:Bool):Int
static function GuiSpinner(bounds:Rectangle, text:String, value:Array<Int>, minValue:Int, maxValue:Int, editMode:Bool):Int
static function GuiValueBox(bounds:Rectangle, text:String, value:Array<Int>, minValue:Int, maxValue:Int, editMode:Bool):Int
static function GuiValueBoxFloat(bounds:Rectangle, text:String, textValue:Array<String>, value:Array<Float>, editMode:Bool):Int
static function GuiSlider(bounds:Rectangle, textLeft:String, textRight:String, value:Array<Float>, minValue:Float, maxValue:Float):Int
static function GuiSliderBar(bounds:Rectangle, textLeft:String, textRight:String, value:Array<Float>, minValue:Float, maxValue:Float):Int
static function GuiProgressBar(bounds:Rectangle, textLeft:String, textRight:String, value:Array<Float>, minValue:Float, maxValue:Float):Int
static function GuiStatusBar(bounds:Rectangle, text:String):Int
static function GuiDummyRec(bounds:Rectangle, text:String):Int
static function GuiGrid(bounds:Rectangle, text:String, spacing:Float, subdivs:Int, mouseCell:Vector2):Int
static function GuiListView(bounds:Rectangle, text:String, scrollIndex:Array<Int>, active:Array<Int>):Int
static function GuiListViewEx(bounds:Rectangle, text:Array<String>, count:Int, scrollIndex:Array<Int>, active:Array<Int>, focus:Array<Int>):Int
static function GuiMessageBox(bounds:Rectangle, title:String, message:String, buttons:String):Int
static function GuiTextInputBox(bounds:Rectangle, title:String, message:String, buttons:String, text:Array<String>, textMaxSize:Int, secretViewActive:Array<Bool>):Int
static function GuiColorPicker(bounds:Rectangle, text:String, color:Null<Array<Color>>):Int
static function GuiColorPanel(bounds:Rectangle, text:String, color:Array<Color>):Int
static function GuiColorBarAlpha(bounds:Rectangle, text:String, alpha:Array<Float>):Int
static function GuiColorBarHue(bounds:Rectangle, text:String, value:Array<Float>):Int
static function GuiColorPickerHSV(bounds:Rectangle, text:String, colorHsv:Vector3):Int
static function GuiColorPanelHSV(bounds:Rectangle, text:String, colorHsv:Vector3):Int
```

- `GuiWindowBox`: Draws a window, a title bar with a close button over a panel, and returns 1 when the close button is clicked. See `GuiPanel` for drawing a panel with no close button.
  - `bounds`: The window, its title bar 24 pixels high; it is at least 48.
  - `title`: The title, or null.
  - returns: 1 when the close button is clicked, else 0.
- `GuiGroupBox`: Draws a group box, a frame with its name in its top line.
  - `bounds`: The box.
  - `text`: Its name, or null.
  - returns: 0.
- `GuiLine`: Draws a line across its bounds' middle, with the text in it when provided ("--- text ------").
  - `bounds`: The line's bounds.
  - `text`: The text, or null for a plain line.
  - returns: 0.
- `GuiPanel`: Draws a panel, with a header bar when the text is provided. See `GuiScrollPanel` for showing content larger than the panel.
  - `bounds`: The panel; with a header it is at least 48 pixels high.
  - `text`: The header's text, or null for none.
  - returns: 0.
- `GuiTabBar`: Draws a bar of tabs and returns the tab whose close button is clicked or that the middle button presses.
  - `bounds`: The bar; its height is the tabs'.
  - `text`: The tabs' names.
  - `count`: How many tabs.
  - `active`: The active tab, in `active[0]`, clamped to the tabs.
  - returns: The tab whose close button was clicked or that the middle button pressed, else -1.

  Each tab is a toggle 160 pixels wide with a close button.

  A click on a tab makes it the active tab.

  Scrolls the bar so the active tab shows.
- `GuiScrollPanel`: Draws a scroll panel, a view of content larger than the panel, with scroll bars where the content is wider or taller. See `GuiPanel` for drawing a panel with no scrolling.
  - `bounds`: The panel; with a header it is at least 48 pixels high.
  - `text`: The header's text, or null for none.
  - `content`: The content's size (its x and y aren't read).
  - `scroll`: The content's offset, changed as it scrolls (0 to minus how much is hidden), or null.
  - `view`: Receives the area the content shows in, inside the bars, or null.
  - returns: 0.

  The bars and the mouse wheel scroll the content, across while Shift or Control is held.
- `GuiLabel`: Draws a label, text in its bounds aligned as the label style sets. See `GuiLabelButton` for drawing a label that takes clicks.
  - `bounds`: The label.
  - `text`: The text, or null.
  - returns: 0.
- `GuiButton`: Draws a button and returns 1 when the left button is released over it.
  - `bounds`: The button.
  - `text`: Its text, or null.
  - returns: 1 when the left button is released over it, else 0.

  Drawn focused while the mouse is over the button, and pressed while the left button is held there.
- `GuiLabelButton`: Draws a label that works as a button, at least as wide as its text, and returns 1 when the left button is released over it. See `GuiButton` for drawing a button.
  - `bounds`: The label.
  - `text`: Its text, or null.
  - returns: 1 when the left button is released over it, else 0.
- `GuiToggle`: Draws a toggle button, drawn pressed while on. See `GuiCheckBox` for drawing a check box.
  - `bounds`: The button.
  - `text`: Its text, or null.
  - `active`: Whether it is on, in `active[0]`, or null.
  - returns: 0.

  A click turns the toggle over.
- `GuiToggleGroup`: Draws a group of toggles, one on at a time, a toggle for each of the text's items ("One;Two;Three"). See `GuiToggleSlider` for drawing the items under one slider.
  - `bounds`: The first toggle; each is this size.
  - `text`: The items, split at ';' and '\n'.
  - `active`: The item on, in `active[0]`, or null.
  - returns: 0.

  Starts a new row at each '\n'.

  A click on a toggle turns it on and the one that was on off.
- `GuiToggleSlider`: Draws a toggle slider, its items ("Off;On") side by side with the active one under a slider, and returns 1 when clicked. See `GuiToggleGroup` for drawing a toggle for each item.
  - `bounds`: The slider.
  - `text`: The items, split at ';'.
  - `active`: The active item, in `active[0]`, or null.
  - returns: 1 when clicked, else 0.

  A click moves the slider to the next item, and from the last back to the first.
- `GuiCheckBox`: Draws a check box with its text beside it, and returns 1 when clicked. See `GuiToggle` for drawing a toggle button.
  - `bounds`: The box.
  - `text`: Its text, or null.
  - `checked`: Whether it is checked, in `checked[0]`, or null.
  - returns: 1 when clicked, else 0.

  A click on the box or its text turns the check over.
- `GuiComboBox`: Draws a combo box, its active item and a button showing which of how many. See `GuiDropdownBox` for listing the items to choose from.
  - `bounds`: The box, its button included.
  - `text`: The items, split at ';'.
  - `active`: The active item, in `active[0]`, or null; clamped to the items.
  - returns: 0.

  A press on the item or the button moves to the next item, and from the last back to the first.
- `GuiDropdownBox`: Draws a dropdown box, its active item with its items listed below it in edit mode. See `GuiComboBox` for stepping through the items in place.
  - `bounds`: The box; each item is its size.
  - `text`: The items, split at ';'.
  - `active`: The active item, in `active[0]`, or null; an item clicked in edit mode becomes it.
  - `editMode`: Whether it is open.
  - returns: 1 when it was pressed closed, or an item was chosen or a press fell outside it open, else 0.

  The program turns edit mode on and off with the result.

  Lists the items above the box with `DROPDOWN_ROLL_UP`.

  Focuses the item under the mouse.
- `GuiTextBox`: Draws a text box that takes typed text in edit mode.
  - `bounds`: The box.
  - `text`: The text, in `text[0]`, edited in place.
  - `textSize`: The most bytes the text may take, its UTF-8 bytes and one more, as raygui's buffer holds them.
  - `editMode`: Whether it is being edited.
  - returns: 1 when its edit mode should flip: while editing, Enter (a single-line box) or a click outside it; otherwise a click on it. Else 0.

  The program turns edit mode on and off with the result.

  In edit mode, a click places the cursor, and these keys move the cursor and delete, repeating while held:

  - Home and End - the arrows - Delete and Backspace - Control-Backspace, which deletes a word
- `GuiSpinner`: Draws a spinner, a value box between buttons that step its value down and up. See `GuiValueBox` for drawing the value box alone.
  - `bounds`: The spinner, its buttons included.
  - `text`: Its label, beside it, or null.
  - `value`: The value, in `value[0]`.
  - `minValue`: The least.
  - `maxValue`: The most.
  - `editMode`: Whether its value box is being edited.
  - returns: The value box's result: 1 when its edit mode should flip, as `GuiTextBox`'s; else 0.

  In edit mode, the value box takes typed digits.

  Out of edit mode, the value is clamped to the range.
- `GuiValueBox`: Draws a value box, a whole number centered. See `GuiValueBoxFloat` for editing a number with a fraction.
  - `bounds`: The box.
  - `text`: Its label, beside it, or null.
  - `value`: The value, in `value[0]`.
  - `minValue`: The least.
  - `maxValue`: The most.
  - `editMode`: Whether it is being edited.
  - returns: 1 when it was clicked into edit mode, or editing ended, else 0.

  The program turns edit mode on and off with the result.

  In edit mode, the box takes typed digits and Backspace.

  Enter or a click outside ends editing and clamps the value to the range.
- `GuiValueBoxFloat`: Draws a value box for a number with a fraction, showing and editing the number's text and reading the value from it. See `GuiValueBox` for editing a whole number.
  - `bounds`: The box.
  - `text`: Its label, beside it, or null.
  - `textValue`: The number's text, in `textValue[0]`, edited in place.
  - `value`: The value, in `value[0]`, read from the text as it changes.
  - `editMode`: Whether it is being edited.
  - returns: 1 when it was clicked into edit mode, or Enter or a click outside ended editing, else 0.

  The program keeps the text.

  In edit mode, the box takes digits, '.', and a sign first.
- `GuiSlider`: Draws a slider, a handle along a bar dragged with the left button, and returns 1 when the value changes. See `GuiSliderBar` for drawing a bar filled to the value.
  - `bounds`: The slider.
  - `textLeft`: The text left of it, or null.
  - `textRight`: The text right of it, or null.
  - `value`: The value, in `value[0]`, clamped to the range.
  - `minValue`: The value at the left end.
  - `maxValue`: The value at the right end.
  - returns: 1 when the value changed, else 0.

  The drag goes on outside the bar until the left button is released.
- `GuiSliderBar`: Draws a slider bar, filled from the left to the value and dragged with the left button, and returns 1 when the value changes. See `GuiSlider` for drawing a handle along a bar.
  - `bounds`: The bar.
  - `textLeft`: The text left of it, or null.
  - `textRight`: The text right of it, or null.
  - `value`: The value, in `value[0]`, clamped to the range.
  - `minValue`: The value at the left end.
  - `maxValue`: The value at the right end.
  - returns: 1 when the value changed, else 0.
- `GuiProgressBar`: Draws a progress bar, filled from the left to the value.
  - `bounds`: The bar.
  - `textLeft`: The text left of it, or null.
  - `textRight`: The text right of it, or null.
  - `value`: The value, in `value[0]`, or null; clamped to the most.
  - `minValue`: The least.
  - `maxValue`: The most.
  - returns: 0.

  Colors the border as far as the value reaches.

  The fill is the value over the most less the least, so the least only clamps, as raygui's. A null value is drawn at half.
- `GuiStatusBar`: Draws a status bar, a bordered bar with text, as a window's title.
  - `bounds`: The bar.
  - `text`: The text, or null.
  - returns: 0.
- `GuiDummyRec`: Draws a placeholder, a filled rectangle with centered text.
  - `bounds`: The rectangle.
  - `text`: The text, or null.
  - returns: 0.
- `GuiGrid`: Draws a grid, a line every spacing divided by subdivs, every subdivs-th line stronger.
  - `bounds`: The grid.
  - `text`: Not drawn.
  - `spacing`: The space between the strong lines, in pixels.
  - `subdivs`: How many cells between strong lines; 0 draws no lines.
  - `mouseCell`: Receives the cell under the mouse, counted in spacings from the grid's corner, or -1, -1 when it isn't over it; or null.
  - returns: 0.
- `GuiListView`: Draws a list view of the text's items ("One;Two;Three"), scrolled by a bar and the mouse wheel when they don't fit. See `GuiListViewEx` for listing an array of items and reading the one under the mouse.
  - `bounds`: The list.
  - `text`: The items, split at ';'.
  - `scrollIndex`: The first item shown, in `scrollIndex[0]`, or null.
  - `active`: The item chosen, in `active[0]`, -1 for none, or null.
  - returns: 0.

  A click on an item chooses it, and a second click unchooses it.
- `GuiListViewEx`: Draws a list view of an array of items, scrolled by a bar and the mouse wheel when they don't fit. See `GuiListView` for listing the items of a string split at ';'.
  - `bounds`: The list.
  - `text`: The items.
  - `count`: How many items.
  - `scrollIndex`: The first item shown, in `scrollIndex[0]`, or null.
  - `active`: The item chosen, in `active[0]`, -1 for none, or null.
  - `focus`: Receives the item under the mouse, in `focus[0]`, -1 for none, or null.
  - returns: 0.

  Focuses the item under the mouse.

  A click on an item chooses it, and a second click unchooses it.
- `GuiMessageBox`: Draws a message box, a window with a centered message and a row of buttons, and returns the button clicked. See `GuiTextInputBox` for adding a text box.
  - `bounds`: The window.
  - `title`: Its title, or null.
  - `message`: The message.
  - `buttons`: The buttons' texts, split at ';' ("Ok;Cancel").
  - returns: The button clicked, from 1, 0 for the close button, else -1.
- `GuiTextInputBox`: Draws a text input box, a window with a message, a text box and a row of buttons, and returns the button clicked. See `GuiMessageBox` for drawing the message and buttons alone.
  - `bounds`: The window.
  - `title`: Its title, or null.
  - `message`: The message above the text box, or null.
  - `buttons`: The buttons' texts, split at ';' ("Ok;Cancel").
  - `text`: The text, in `text[0]`, edited in place.
  - `textMaxSize`: The most bytes the text may take, as `GuiTextBox`'s textSize.
  - `secretViewActive`: Whether the text shows, in `secretViewActive[0]`, or null for a box that always shows it.
  - returns: The button clicked, from 1, 0 for the close button, else -1.

  A click on the text box starts editing the text.

  With `secretViewActive`, a toggle beside the text box shows the text or hides it behind stars.

  One text input box may be open at a time.
- `GuiColorPicker`: Draws a color picker, a saturation and value panel with a hue bar beside it, both dragged with the left button. See `GuiColorPickerHSV` for keeping the hue steady.
  - `bounds`: The panel; the hue bar is beside it.
  - `text`: Not drawn.
  - `color`: The color in a one-element array, as raygui takes a pointer, changed there; or null. Its alpha is kept.
  - returns: 0.

  Converts the color through HSV each call, so its hue may shift where red, green and blue are close.
- `GuiColorPanel`: Draws a color panel, saturation across and value down at the color's hue, dragged with the left button. See `GuiColorPanelHSV` for editing an HSV color.
  - `bounds`: The panel.
  - `text`: Not drawn.
  - `color`: The color in a one-element array, as raygui takes a pointer, changed there when the panel changes it. Its alpha is kept.
  - returns: 0.
- `GuiColorBarAlpha`: Draws an alpha bar, clear to opaque across over a checked background, its selector dragged with the left button.
  - `bounds`: The bar.
  - `text`: Not drawn.
  - `alpha`: The alpha, 0 to 1, in `alpha[0]`.
  - returns: 0.
- `GuiColorBarHue`: Draws a hue bar, the hues from red at the top round to red at the bottom, its selector dragged with the left button.
  - `bounds`: The bar.
  - `text`: Not drawn.
  - `value`: The hue, in degrees from 0 to 359, in `value[0]`.
  - returns: 0.
- `GuiColorPickerHSV`: Draws a color picker for an HSV color, a saturation and value panel with a hue bar beside it. See `GuiColorPicker` for editing a `Color`.
  - `bounds`: The panel; the hue bar is beside it.
  - `text`: Not drawn.
  - `colorHsv`: The color, hue in degrees (x), saturation (y) and value (z) 0 to 1, changed in place; or null.
  - returns: 0.

  Keeps the color as HSV, so its hue never shifts.
- `GuiColorPanelHSV`: Draws a color panel for an HSV color, saturation across and value down at its hue, dragged with the left button. See `GuiColorPanel` for editing a `Color`.
  - `bounds`: The panel.
  - `text`: Not drawn.
  - `colorHsv`: The color, hue in degrees (x), saturation (y) and value (z) 0 to 1; saturation and value change in place.
  - returns: 0.

```haxe
static macro function GuiLoadStyle(fileName:String):Void
static macro function GuiLoadIcons(fileName:String, loadIconsName:Bool):Array<String>
```

- `GuiLoadStyle`: Stands for raygui's style file load, which doesn't compile. See `GuiLoadStyleAsync` in `helix.raylib.extras.Gui` for loading a style file.
- `GuiLoadIcons`: Stands for raygui's icon file load, which doesn't compile. See `GuiLoadIconsAsync` in `helix.raylib.extras.Gui` for loading an icon file.
