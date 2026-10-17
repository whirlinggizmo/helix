# helix.ui

[Back to the index](README.md)

## Alignment

*enum* in `src/helix/ui/Box.hx`

Where boxes go in the room they have, along an axis.

- `Start`: At its start: the left, or the top.
- `Center`: In its middle.
- `End`: At its end: the right, or the bottom.
- `Stretch`: Across a row or column only: filling it.

## Box

*class* in `src/helix/ui/Box.hx`

A rectangle of a layout: rows, columns and stacks of boxes, each sized fixed, fitted to its content, growing into the room left or as a share of its parent, with padding, gaps and alignment (Clay's model, in Haxe). A box may place a node: arrange() writes its position (by its pivot) and, for a sprite or rectangle, its size, once a frame. Boxes only lay out; what's drawn is the nodes'.

```haxe
function new(direction:BoxDirection, ?node:Node2D)
static function row(?node:Node2D):Box
static function column(?node:Node2D):Box
static function stack(?node:Node2D):Box
static function of(node:Node2D):Box
static function arrange(root:Box, x:Float, y:Float, width:Float, height:Float, font:Font2D):Void
function add(child:Box):Void
function remove(child:Box):Bool
function getChildren():Array<Box>
function getNode():Null<Node2D>
function getWidthSizing():Sizing
function getHeightSizing():Sizing
function setSizing(width:Sizing, height:Sizing):Void
function getPaddingLeft():Float
function getPaddingTop():Float
function getPaddingRight():Float
function getPaddingBottom():Float
function setPadding(left:Float, top:Float, right:Float, bottom:Float):Void
function getGap():Float
function setGap(value:Float):Void
function getMainAlign():Alignment
function getCrossAlign():Alignment
function setAlign(main:Alignment, cross:Alignment):Void
function getAnchorX():Null<Alignment>
function getAnchorY():Null<Alignment>
function getAnchorOffsetX():Float
function getAnchorOffsetY():Float
function setAnchor(horizontal:Alignment, vertical:Alignment, ?offsetX:Float = 0., ?offsetY:Float = 0.):Void
function getX():Float
function getY():Float
function getWidth():Float
function getHeight():Float
```

- `new`: A box laying out its children direction's way, placing node (or none).
- `row`: A row, left to right.
- `column`: A column, top to bottom.
- `stack`: A stack, its children over one another, each by its own alignment.
- `of`: A box holding node alone, sized to it unless sized otherwise.
- `arrange`: Lays root and everything in it out in the rectangle x, y, width x height (a screen's, a design resolution's) and writes the nodes' places: its content measured (texts in their fonts, font for those without one), then each box placed. Once a frame, before drawing.
- `add`: Adds child as its last.
- `remove`: Takes child out.
- `getChildren`: Its children, in order.
- `getNode`: The node it places, or null.
- `getWidthSizing`: How its width is decided.
- `getHeightSizing`: How its height is decided.
- `setSizing`: How its width and height are decided (Fit both, to start).
- `getPaddingLeft`: Its padding inside its left edge.
- `getPaddingTop`: Its padding inside its top edge.
- `getPaddingRight`: Its padding inside its right edge.
- `getPaddingBottom`: Its padding inside its bottom edge.
- `setPadding`: Its padding inside its edges (none, to start).
- `getGap`: The room between its children in a row or column.
- `setGap`: Sets the room between its children in a row or column (none, to start).
- `getMainAlign`: Where its children go along its row or column.
- `getCrossAlign`: Where its children go across its row or column.
- `setAlign`: Where its children go: along a row or column (main: Start, Center or End when none grows) and across it (cross, Stretch filling it); Start both, to start.
- `getAnchorX`: Where it goes across a stack, or null for its stack's alignment.
- `getAnchorY`: Where it goes down a stack, or null for its stack's alignment.
- `getAnchorOffsetX`: How far it's moved right from its anchor.
- `getAnchorOffsetY`: How far it's moved down from its anchor.
- `setAnchor`: Where it goes in a stack (horizontally, vertically; Stretch fills that way), moved by offsetX, offsetY: anchored to an edge, a corner or the middle.
- `getX`: Where the last arrange put it, x of its left edge.
- `getY`: Its top edge as last arranged.
- `getWidth`: Its width as last arranged.
- `getHeight`: Its height as last arranged.

## BoxDirection

*enum* in `src/helix/ui/Box.hx`

How a box lays its children out.

- `Row`: Left to right.
- `Column`: Top to bottom.
- `Stack`: Over one another, each placed by its own alignment in the box (anchored to an edge, a corner or the middle).

## Button

*class* in `src/helix/ui/Button.hx`

A button reading a line of text: clicked by the pointer (released over it, as pressed), or activated with focus by Enter, Space or a pad's South. Ask isClicked once a frame.

```haxe
function isClicked():Bool
function getText():String
function setText(value:String):Void
function isFocusable():Bool
```

- `isClicked`: Whether it was clicked or activated this frame.
- `getText`: Its text.
- `setText`: Reads text.

## Label

*class* in `src/helix/ui/Label.hx`

A line of text (wrapped, if given a width): shown, never focused.

```haxe
function getText():String
function setText(value:String):Void
function getNode():Node2D
```

- `getText`: Its text.
- `setText`: Shows text.
- `getNode`: Its text node: its color, size, alignment, wrap width.

## ListView

*class* in `src/helix/ui/ListView.hx`

A list of items in a window rows tall: scrolled by the wheel over it or a drag, an item chosen by a click or, with focus, by Up and Down (scrolled into view), and activated by a click on the chosen one or Enter, Space or a pad's South. Ask getSelectedIndex, isChanged and isActivated once a frame.

```haxe
function getItems():Array<String>
function setItems(value:Array<String>):Void
function getSelectedIndex():Int
function setSelectedIndex(index:Int):Bool
function isChanged():Bool
function isActivated():Bool
function isFocusable():Bool
```

- `getItems`: Its items.
- `setItems`: Shows items, choosing none.
- `getSelectedIndex`: The chosen item's index, or -1.
- `setSelectedIndex`: Chooses item index (-1: none), scrolled into view; not counted as a change. False, changing nothing, for an index out of range.
- `isChanged`: Whether the chosen item changed this frame.
- `isActivated`: Whether the chosen item was activated this frame: clicked again, or Enter, Space or South with focus.

## Panel

*class* in `src/helix/ui/Panel.hx`

A background holding a column of widgets (add): hidden, they're hidden with it. A plain rectangle in the theme's panel color, or a nine-slice frame (setFrame). Never focused; the pointer stops at it, so what's under a panel doesn't see it.

```haxe
function add(widget:Widget):Void
function getContent():Box
function adopt(widget:Widget):Void
function getFrame():Null<Node2D>
function setFrame(texture:Null<Texture2D>, left:Float, top:Float, right:Float, bottom:Float, ?tint:Int = 0xffffffff):Bool
```

- `add`: Puts widget in it, last in its column: its nodes under the panel's (hidden with it), its box in the column.
- `getContent`: The column its widgets go in, for boxes of other kinds (a row of buttons: put the buttons' boxes in a row, and the buttons in the panel with adopt).
- `adopt`: Puts widget's nodes under the panel's (hidden with it) without placing it: its box goes in a layout of the caller's inside getContent().
- `getFrame`: Its nine-slice frame, a sprite (its texture, insets and tint read from it), or null for the theme's rectangle.
- `setFrame`: Draws it as texture's nine-slice frame, its corners left, top, right and bottom texels in, tinted tint. False, changing nothing, for no texture.

## ProgressBar

*class* in `src/helix/ui/ProgressBar.hx`

How far along something is: a track filled from its left by a value, 0 to 1. Never focused.

```haxe
function getValue():Float
function setValue(v:Float):Void
```

- `getValue`: How far along, 0 to 1.
- `setValue`: Sets how far along (held to 0 .. 1).

## Sizing

*enum* in `src/helix/ui/Box.hx`

How a box's width or height is decided.

- `Fixed(units:Float)`: This many units.
- `Fit`: Its content's: its children's (and gaps and padding), or its node's own (a text's measured width, a sprite's or rectangle's size).
- `Grow(weight:Float)`: A share of the room its row or column has left, by weight against its siblings' (across, the whole room).
- `Percent(fraction:Float)`: This fraction of its parent's room inside the padding (0 to 1).

## Slider

*class* in `src/helix/ui/Slider.hx`

A value from min to max in steps (0: any), beside a line of text: dragged along its track by the pointer, or stepped by Left and Right with focus (a tenth of the way without steps). Ask getValue, and isChanged once a frame.

```haxe
function getValue():Float
function setValue(v:Float):Void
function isChanged():Bool
function isFocusable():Bool
```

- `getValue`: Its value.
- `setValue`: Sets its value (held to min .. max and its steps; not counted as a change).
- `isChanged`: Whether its value changed this frame.

## TextField

*class* in `src/helix/ui/TextField.hx`

A line of text typed in: with focus, the characters typed (after the keyboard layout) are added, Backspace takes the last off and Enter submits; the caret is at its end. While it has focus the UI has the keys (Ui.isCapturingKeys) and asks for typed text (IInput.setTextEntry, so a platform's keyboard shows for it), however it got focus, so a game doesn't act on letters typed. Ask getText, isChanged and isSubmitted once a frame. No input method (IME) composition yet.

```haxe
function getText():String
function setText(value:String):Void
function isChanged():Bool
function isSubmitted():Bool
function isFocusable():Bool
```

- `getText`: Its text.
- `setText`: Shows value (cut to its longest; not counted as a change).
- `isChanged`: Whether its text changed this frame.
- `isSubmitted`: Whether Enter was pressed in it this frame.

## Theme

*class* in `src/helix/ui/Theme.hx`

How the UI's widgets look: their colors (0xRRGGBBAA), font and sizes. Change one before making widgets; widgets read it as they're made and as they draw their states.

```haxe
function new()
function getFont():Null<Font2D>
function setFont(value:Null<Font2D>):Void
function getTextSize():Float
function setTextSize(value:Float):Bool
function getTextColor():Int
function setTextColor(value:Int):Void
function getDisabledTextColor():Int
function setDisabledTextColor(value:Int):Void
function getPanelColor():Int
function setPanelColor(value:Int):Void
function getFaceColor():Int
function setFaceColor(value:Int):Void
function getHoveredColor():Int
function setHoveredColor(value:Int):Void
function getPressedColor():Int
function setPressedColor(value:Int):Void
function getAccentColor():Int
function setAccentColor(value:Int):Void
function getFocusColor():Int
function setFocusColor(value:Int):Void
function getFocusWidth():Float
function setFocusWidth(value:Float):Bool
function getCornerRadius():Float
function setCornerRadius(value:Float):Bool
function getPadding():Float
function setPadding(value:Float):Bool
function getGap():Float
function setGap(value:Float):Bool
function getWidgetHeight():Float
function setWidgetHeight(value:Float):Bool
```

- `new`: The colors and sizes as each getter says to start.
- `getFont`: The font text is drawn in, or null for the stage's (the batch's built-in one).
- `setFont`: Sets it, as getFont says.
- `getTextSize`: Text's height in units. (18 to start.)
- `setTextSize`: Sets it, as getTextSize says. False, changing nothing, for 0 or less.
- `getTextColor`: Text's color. (0xf0f2f8ff to start.)
- `setTextColor`: Sets it, as getTextColor says.
- `getDisabledTextColor`: The color of text on a widget that can't be used now. (0x80869aff to start.)
- `setDisabledTextColor`: Sets it, as getDisabledTextColor says.
- `getPanelColor`: A panel's background color. (0x1e2230e8 to start.)
- `setPanelColor`: Sets it, as getPanelColor says.
- `getFaceColor`: The color of a button's (and a toggle's box's, a track's) face at rest. (0x2e3448ff to start.)
- `setFaceColor`: Sets it, as getFaceColor says.
- `getHoveredColor`: The color of a face under the pointer. (0x3e4660ff to start.)
- `setHoveredColor`: Sets it, as getHoveredColor says.
- `getPressedColor`: The color of a face held down. (0x56607eff to start.)
- `setPressedColor`: Sets it, as getPressedColor says.
- `getAccentColor`: The color of what's on, filled or chosen: a toggle's mark, a slider's fill and knob, a progress bar's fill, a list's selected row. (0x4c8ef0ff to start.)
- `setAccentColor`: Sets it, as getAccentColor says.
- `getFocusColor`: The color of the ring around the focused widget, shown when focus was moved by keys or a pad. (0xffd25aff to start.)
- `setFocusColor`: Sets it, as getFocusColor says.
- `getFocusWidth`: The focus ring's width in units. (2 to start.)
- `setFocusWidth`: Sets it, as getFocusWidth says. False, changing nothing, for below 0.
- `getCornerRadius`: The radius of a panel's, a button's, a field's and a list's corners in units (a track's, a bar's and a box's at most half their height); 0 for square. The focus ring follows them. (8 to start.)
- `setCornerRadius`: Sets it, as getCornerRadius says. False, changing nothing, for below 0.
- `getPadding`: Room inside a button or panel, around its content, in units. (10 to start.)
- `setPadding`: Sets it, as getPadding says. False, changing nothing, for below 0.
- `getGap`: Room between widgets in a panel, in units. (8 to start.)
- `setGap`: Sets it, as getGap says. False, changing nothing, for below 0.
- `getWidgetHeight`: A button's (and a list row's, a slider's) height in units. (40 to start.)
- `setWidgetHeight`: Sets it, as getWidgetHeight says. False, changing nothing, for 0 or less.

## Tile

*class* in `src/helix/ui/Tile.hx`

A picture with a caption under it, in a frame: an inventory's item, a character creator's choice, a level to pick. Clicked by the pointer, or activated with focus by Enter, Space or a pad's South; marked selected by the game (one of a group, as the game decides: isClicked, then setSelected). Its picture can come later (a thumbnail still being made): until then, and with none, the frame shows the theme's face color. Ask isClicked once a frame.

```haxe
function isClicked():Bool
function isSelected():Bool
function setSelected(value:Bool):Void
function getTexture():Null<Texture2D>
function setTexture(texture:Null<Texture2D>):Void
function getCaption():String
function setCaption(value:String):Void
function getSide():Float
function isFocusable():Bool
```

- `isClicked`: Whether it was clicked or activated this frame.
- `isSelected`: Whether it's marked selected: drawn with an accent edge.
- `setSelected`: Marks it selected, or not.
- `getTexture`: Its picture, or null while it has none.
- `setTexture`: Shows texture as its picture, scaled into its square (null: none, the frame's face showing).
- `getCaption`: Its caption.
- `setCaption`: Reads caption under the picture.
- `getSide`: The side of its picture's square, in units.

## Toggle

*class* in `src/helix/ui/Toggle.hx`

A box that's on or off, beside a line of text: switched by a click or by activating it with focus. Ask getValue, and isChanged once a frame.

```haxe
function isOn():Bool
function setOn(on:Bool):Void
function isChanged():Bool
function isFocusable():Bool
```

- `isOn`: Whether it's on.
- `setOn`: Turns it on or off (not counted as a change).
- `isChanged`: Whether it was switched this frame.

## Ui

*class* in `src/helix/ui/Ui.hx`

A screen's widgets on a Stage2D, used by the pointer, keys and pads alike: made here, placed by their boxes (Box.arrange), asked what happened. update() once a frame, after the pointer's: - Arrows and a pad's D-pad move focus to the nearest widget that way on screen (by the boxes' last arrangement: a grid of tiles moves in two dimensions), or, with none that way, in the order widgets were made: Down and Right to the next, Up and Left to the one before, wrapping; Left and Right only when the focused widget doesn't use them (a slider), Up and Down only when it doesn't (a list). Tab and Shift+Tab always go in that order. Enter, Space or a pad's South activates it; Escape or East is back (isBackPressed). - The ring around the focused widget shows only when keys or a pad moved focus, not the pointer (as the web's :focus-visible); after keys or a pad, something always has focus (the first widget, if nothing did). - A key or button already held when a screen begins (reset) does nothing until it's let go: a fire key held into a menu doesn't press its first button. - While a widget has the keys (isCapturingKeys), a game should leave arrows and Enter be, or they drive the game and the menu at once. The widgets' nodes are under one node (getRoot) on the stage, in the order made, the ring above them. The pointer must be looking at the stage, through camera.

```haxe
function new(stage:Stage2D, camera:Camera2D, pointer:Pointer, input:IInput, ?theme:Theme)
function getTheme():Theme
function getRoot():Node2D
function getFont():Null<Font2D>
function getCamera():Camera2D
function getInput():IInput
function label(text:String, ?name:String):Label
function panel(?name:String):Panel
function button(text:String, ?name:String):Button
function toggle(text:String, value:Bool, ?name:String):Toggle
function slider(text:String, min:Float, max:Float, value:Float, ?step:Float = 0., ?name:String):Slider
function progress(value:Float, ?name:String):ProgressBar
function textField(value:String, ?hint:String = "", ?maxLength:Int = 64, ?name:String):TextField
function tile(texture:Null<Texture2D>, caption:String, side:Float, ?name:String):Tile
function list(items:Array<String>, rows:Int, ?name:String):ListView
function remove(widget:Widget):Void
function find(name:String):Null<Widget>
function press(name:String):Bool
function getFocused():Null<Widget>
function getFocusedName():String
function setFocused(widget:Null<Widget>):Void
function isCapturingKeys():Bool
function isBackPressed():Bool
function reset():Void
function update():Void
```

- `new`: A UI on stage (drawn through camera, which pointer looks at), read from input, in theme's look (a new Theme when not given).
- `getTheme`: Its look.
- `getRoot`: The node its widgets are under.
- `getFont`: The font text is drawn in without the theme's: the stage's last (the batch's built-in), once drawn.
- `getCamera`: The camera it's drawn through.
- `getInput`: The input it reads.
- `label`: A line of text.
- `panel`: A background holding a column of widgets (add their boxes to its getContent()).
- `button`: A button reading text: clicked by the pointer, or activated with focus.
- `toggle`: A box that's on or off, beside text.
- `slider`: A value from min to max in steps of step (0: any), dragged along a track or stepped by Left and Right, beside text.
- `progress`: How far along something is, 0 to 1.
- `textField`: A line of text typed in, at most maxLength characters, hint shown while it's empty.
- `tile`: A picture with a caption (a texture still to come: null), in a frame whose picture is side units square.
- `list`: A list of items rows tall, scrolled by the wheel or a drag, an item chosen by the pointer or Up and Down.
- `remove`: Takes widget out, its nodes off the stage.
- `find`: The widget named name (Widget.getName), or null.
- `press`: Uses the widget named name as a click would (a button clicked, a toggle switched, a list's choice activated), at the next update, when it's shown, enabled and can be: as a test or an autopilot does, by name rather than by place. False, doing nothing, when there's no such widget or it isn't usable now.
- `getFocused`: The widget with focus, or null.
- `getFocusedName`: The focused widget's name, or "" (for a check's probe).
- `setFocused`: Gives widget focus (null: none), shown as keys would show it.
- `isCapturingKeys`: Whether a widget has the keys: a game should leave arrows, Enter and Space be.
- `isBackPressed`: Whether Escape or a pad's East was pressed this frame (not held over from before reset).
- `reset`: A new screen begins: no focus, and keys and buttons held now do nothing until they're let go.
- `update`: Once a frame, after the pointer's update and before reading the widgets: moves focus, activates, and brings each widget up to date.

## Widget

*class* in `src/helix/ui/Widget.hx`

A piece of UI: nodes it owns (under its root, on the Ui's stage) and the layout box placing them. A widget is asked what happened (isClicked, getValue ...), never calls anything (DECISIONS 61); the Ui updates it once a frame.

```haxe
function getName():String
function getBox():Box
function getRoot():Node2D
function isEnabled():Bool
function setEnabled(value:Bool):Void
function setVisible(value:Bool):Void
function isVisible():Bool
function isFocusable():Bool
```

- `getName`: Its name: what the focus is published as (Ui.getFocusedName), for checks.
- `getBox`: The box placing it: put it in a layout.
- `getRoot`: Its root node, everything it draws under it.
- `isEnabled`: Whether it can be used: a disabled one is drawn dimmed, can't take focus and does nothing.
- `setEnabled`: Lets it be used, or not (isEnabled).
- `setVisible`: Shows or hides it (and lets it take focus, or not).
- `isVisible`: Whether it's shown: it, and any panel holding it.
- `isFocusable`: Whether focus can rest on it.
