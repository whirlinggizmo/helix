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
var children(get, never):Array<Box>
var node(default, null):Null<Node2D>
var widthSizing(get, never):Sizing
var heightSizing(get, never):Sizing
function setSizing(width:Sizing, height:Sizing):Void
var paddingLeft(default, null):Float
var paddingTop(default, null):Float
var paddingRight(default, null):Float
var paddingBottom(default, null):Float
function setPadding(left:Float, top:Float, right:Float, bottom:Float):Void
var gap:Float
var mainAlign(default, null):Alignment
var crossAlign(default, null):Alignment
function setAlign(main:Alignment, cross:Alignment):Void
var anchorX(get, never):Null<Alignment>
var anchorY(get, never):Null<Alignment>
var anchorOffsetX(get, never):Float
var anchorOffsetY(get, never):Float
function setAnchor(horizontal:Alignment, vertical:Alignment, ?offsetX:Float = 0., ?offsetY:Float = 0.):Void
var x(default, null):Float
var y(default, null):Float
var width(get, never):Float
var height(get, never):Float
```

- `new`: A box laying out its children direction's way, placing node (or none).
- `row`: A row, left to right.
- `column`: A column, top to bottom.
- `stack`: A stack, its children over one another, each by its own alignment.
- `of`: A box holding node alone, sized to it unless sized otherwise.
- `arrange`: Lays root and everything in it out in the rectangle x, y, width x height (a screen's, a design resolution's) and writes the nodes' places: its content measured (texts in their fonts, font for those without one), then each box placed. Once a frame, before drawing.
- `add`: Adds child as its last.
- `remove`: Takes child out.
- `children`: Its children, in order.
- `node`: The node it places, or null.
- `widthSizing`: How its width is decided.
- `heightSizing`: How its height is decided.
- `setSizing`: How its width and height are decided (Fit both, to start).
- `paddingLeft`: Its padding inside its left edge.
- `paddingTop`: Its padding inside its top edge.
- `paddingRight`: Its padding inside its right edge.
- `paddingBottom`: Its padding inside its bottom edge.
- `setPadding`: Its padding inside its edges (none, to start).
- `gap`: The room between its children in a row or column.
- `mainAlign`: Where its children go along its row or column.
- `crossAlign`: Where its children go across its row or column.
- `setAlign`: Where its children go: along a row or column (main: Start, Center or End when none grows) and across it (cross, Stretch filling it); Start both, to start.
- `anchorX`: Where it goes across a stack, or null for its stack's alignment.
- `anchorY`: Where it goes down a stack, or null for its stack's alignment.
- `anchorOffsetX`: How far it's moved right from its anchor.
- `anchorOffsetY`: How far it's moved down from its anchor.
- `setAnchor`: Where it goes in a stack (horizontally, vertically; Stretch fills that way), moved by offsetX, offsetY: anchored to an edge, a corner or the middle.
- `x`: Where the last arrange put it, x of its left edge.
- `y`: Its top edge as last arranged.
- `width`: Its width as last arranged.
- `height`: Its height as last arranged.

## BoxDirection

*enum* in `src/helix/ui/Box.hx`

How a box lays its children out.

- `Row`: Left to right.
- `Column`: Top to bottom.
- `Stack`: Over one another, each placed by its own alignment in the box (anchored to an edge, a corner or the middle).

## Button

*class* in `src/helix/ui/Button.hx`

A button reading a line of text: clicked by the pointer (released over it, as pressed), or activated with focus by Enter, Space or a pad's South. Ask clicked once a frame.

```haxe
var clicked(default, null):Bool
var text(get, set):String
```

- `clicked`: Whether it was clicked or activated this frame.
- `text`: Its text.

## Label

*class* in `src/helix/ui/Label.hx`

A line of text (wrapped, if given a width): shown, never focused.

```haxe
var text(get, set):String
var node(default, null):Node2D
```

- `text`: Its text.
- `node`: Its text node: its color, size, alignment, wrap width.

## ListView

*class* in `src/helix/ui/ListView.hx`

A list of items in a window rows tall: scrolled by the wheel over it or a drag, an item chosen by a click or, with focus, by Up and Down (scrolled into view), and activated by a click on the chosen one or Enter, Space or a pad's South. Ask selectedIndex, changed and activated once a frame.

```haxe
var items(get, set):Array<String>
var selectedIndex(get, set):Int
var changed(default, null):Bool
var activated(default, null):Bool
```

- `items`: Its items.
- `selectedIndex`: The chosen item's index, or -1 for none; assigning one scrolls it into view, not counted as a change. Clamped to -1 to the last item's index.
- `changed`: Whether the chosen item changed this frame.
- `activated`: Whether the chosen item was activated this frame: clicked again, or Enter, Space or South with focus.

## Panel

*class* in `src/helix/ui/Panel.hx`

A background holding a column of widgets (add): hidden, they're hidden with it. A plain rectangle in the theme's panel color, or a nine-slice frame (setFrame). Never focused; the pointer stops at it, so what's under a panel doesn't see it.

```haxe
function add(widget:Widget):Void
var content(default, null):Box
function adopt(widget:Widget):Void
var frame(default, null):Null<Node2D>
function setFrame(texture:Null<Texture2D>, left:Float, top:Float, right:Float, bottom:Float, ?tint:Int = 0xffffffff):Bool
```

- `add`: Puts widget in it, last in its column: its nodes under the panel's (hidden with it), its box in the column.
- `content`: The column its widgets go in, for boxes of other kinds (a row of buttons: put the buttons' boxes in a row, and the buttons in the panel with adopt).
- `adopt`: Puts widget's nodes under the panel's (hidden with it) without placing it: its box goes in a layout of the caller's inside this.content.
- `frame`: Its nine-slice frame, a sprite (its texture, insets and tint read from it), or null for the theme's rectangle.
- `setFrame`: Draws it as texture's nine-slice frame, its corners left, top, right and bottom texels in, tinted tint. False, changing nothing, for no texture.

## ProgressBar

*class* in `src/helix/ui/ProgressBar.hx`

How far along something is: a track filled from its left by a value, 0 to 1. Never focused.

```haxe
var value(default, set):Float
```

- `value`: How far along, 0 to 1.

## Sizing

*enum* in `src/helix/ui/Box.hx`

How a box's width or height is decided.

- `Fixed(units:Float)`: This many units.
- `Fit`: Its content's: its children's (and gaps and padding), or its node's own (a text's measured width, a sprite's or rectangle's size).
- `Grow(weight:Float)`: A share of the room its row or column has left, by weight against its siblings' (across, the whole room).
- `Percent(fraction:Float)`: This fraction of its parent's room inside the padding (0 to 1).

## Slider

*class* in `src/helix/ui/Slider.hx`

A value from min to max in steps (0: any), beside a line of text: dragged along its track by the pointer, or stepped by Left and Right with focus (a tenth of the way without steps). Ask value, and changed once a frame.

```haxe
var value(default, set):Float
var changed(default, null):Bool
```

- `value`: Its value.
- `changed`: Whether its value changed this frame.

## TextField

*class* in `src/helix/ui/TextField.hx`

A line of text typed in: with focus, the characters typed (after the keyboard layout) are added, Backspace takes the last off and Enter submits; the caret is at its end. While it has focus the UI has the keys (Ui.capturingKeys) and asks for typed text (IInput.setTextEntry, so a platform's keyboard shows for it), however it got focus, so a game doesn't act on letters typed. Ask text, changed and submitted once a frame. No input method (IME) composition yet.

```haxe
var text(get, set):String
var changed(default, null):Bool
var submitted(default, null):Bool
```

- `text`: Its text.
- `changed`: Whether its text changed this frame.
- `submitted`: Whether Enter was pressed in it this frame.

## Theme

*class* in `src/helix/ui/Theme.hx`

How the UI's widgets look: their colors (0xRRGGBBAA), font and sizes. Change one before making widgets; widgets read it as they're made and as they draw their states.

```haxe
function new()
var font:Null<Font2D>
var textSize(default, set):Float
var textColor(get, set):Int
var disabledTextColor(get, set):Int
var panelColor(get, set):Int
var faceColor(get, set):Int
var hoveredColor(get, set):Int
var pressedColor(get, set):Int
var accentColor(get, set):Int
var focusColor(get, set):Int
var focusWidth(default, set):Float
var cornerRadius(get, set):Float
var padding(default, set):Float
var gap(default, set):Float
var widgetHeight(get, set):Float
```

- `new`: The colors and sizes as each getter says to start.
- `font`: The font text is drawn in, or null for the stage's (the batch's built-in one).
- `textSize`: Text's height in units. (18 to start.) At least 1e-6 (0 or less, or NaN, is 1e-6).
- `textColor`: Text's color. (0xf0f2f8ff to start.)
- `disabledTextColor`: The color of text on a widget that can't be used now. (0x80869aff to start.)
- `panelColor`: A panel's background color. (0x1e2230e8 to start.)
- `faceColor`: The color of a button's (and a toggle's box's, a track's) face at rest. (0x2e3448ff to start.)
- `hoveredColor`: The color of a face under the pointer. (0x3e4660ff to start.)
- `pressedColor`: The color of a face held down. (0x56607eff to start.)
- `accentColor`: The color of what's on, filled or chosen: a toggle's mark, a slider's fill and knob, a progress bar's fill, a list's selected row. (0x4c8ef0ff to start.)
- `focusColor`: The color of the ring around the focused widget, shown when focus was moved by keys or a pad. (0xffd25aff to start.)
- `focusWidth`: The focus ring's width in units. (2 to start.) 0 or more (under 0, or NaN, is 0).
- `cornerRadius`: The radius of a panel's, a button's, a field's and a list's corners in units (a track's, a bar's and a box's at most half their height); 0 for square. The focus ring follows them. (8 to start.) 0 or more (under 0, or NaN, is 0).
- `padding`: Room inside a button or panel, around its content, in units. (10 to start.) 0 or more (under 0, or NaN, is 0).
- `gap`: Room between widgets in a panel, in units. (8 to start.) 0 or more (under 0, or NaN, is 0).
- `widgetHeight`: A button's (and a list row's, a slider's) height in units. (40 to start.) At least 1e-6 (0 or less, or NaN, is 1e-6).

## Tile

*class* in `src/helix/ui/Tile.hx`

A picture with a caption under it, in a frame: an inventory's item, a character creator's choice, a level to pick. Clicked by the pointer, or activated with focus by Enter, Space or a pad's South; marked selected by the game (one of a group, as the game decides: clicked, then selected). Its picture can come later (a thumbnail still being made): until then, and with none, the frame shows the theme's face color. Ask clicked once a frame.

```haxe
var clicked(default, null):Bool
var selected:Bool
var texture(get, set):Null<Texture2D>
var caption(get, set):String
var side(default, null):Float
```

- `clicked`: Whether it was clicked or activated this frame.
- `selected`: Whether it's marked selected: drawn with an accent edge.
- `texture`: Its picture, or null while it has none.
- `caption`: Its caption, under the picture.
- `side`: The side of its picture's square, in units.

## Toggle

*class* in `src/helix/ui/Toggle.hx`

A box that's on or off, beside a line of text: switched by a click or by activating it with focus. Ask on, and changed once a frame.

```haxe
var on(get, set):Bool
var changed(default, null):Bool
```

- `on`: Whether it's on.
- `changed`: Whether it was switched this frame.

## Ui

*class* in `src/helix/ui/Ui.hx`

A screen's widgets on a Stage2D, used by the pointer, keys and pads alike: made here, placed by their boxes (Box.arrange), asked what happened. update() once a frame, after the pointer's: - Arrows and a pad's D-pad move focus to the nearest widget that way on screen (by the boxes' last arrangement: a grid of tiles moves in two dimensions), or, with none that way, in the order widgets were made: Down and Right to the next, Up and Left to the one before, wrapping; Left and Right only when the focused widget doesn't use them (a slider), Up and Down only when it doesn't (a list). Tab and Shift+Tab always go in that order. Enter, Space or a pad's South activates it; Escape or East is back (backPressed). - The ring around the focused widget shows only when keys or a pad moved focus, not the pointer (as the web's :focus-visible); after keys or a pad, something always has focus (the first widget, if nothing did). - A key or button already held when a screen begins (reset) does nothing until it's let go: a fire key held into a menu doesn't press its first button. - While a widget has the keys (capturingKeys), a game should leave arrows and Enter be, or they drive the game and the menu at once. The widgets' nodes are under one node (root) on the stage, in the order made, the ring above them. The pointer must be looking at the stage, through camera.

```haxe
function new(stage:Stage2D, camera:Camera2D, pointer:Pointer, input:IInput, ?theme:Theme)
var theme(default, null):Theme
var root(default, null):Node2D
var font(get, never):Null<Font2D>
var camera(default, null):Camera2D
var input(default, null):IInput
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
var focused(default, set):Null<Widget>
var focusedName(get, never):String
var capturingKeys(get, never):Bool
var backPressed(get, never):Bool
function reset():Void
function update():Void
```

- `new`: A UI on stage (drawn through camera, which pointer looks at), read from input, in theme's look (a new Theme when not given).
- `theme`: Its look.
- `root`: The node its widgets are under.
- `font`: The font text is drawn in without the theme's: the stage's last (the batch's built-in), once drawn.
- `camera`: The camera it's drawn through.
- `input`: The input it reads.
- `label`: A line of text.
- `panel`: A background holding a column of widgets (add their boxes to its content).
- `button`: A button reading text: clicked by the pointer, or activated with focus.
- `toggle`: A box that's on or off, beside text.
- `slider`: A value from min to max in steps of step (0: any), dragged along a track or stepped by Left and Right, beside text.
- `progress`: How far along something is, 0 to 1.
- `textField`: A line of text typed in, at most maxLength characters, hint shown while it's empty.
- `tile`: A picture with a caption (a texture still to come: null), in a frame whose picture is side units square.
- `list`: A list of items rows tall, scrolled by the wheel or a drag, an item chosen by the pointer or Up and Down.
- `remove`: Takes widget out, its nodes off the stage.
- `find`: The widget named name (Widget.name), or null.
- `press`: Uses the widget named name as a click would (a button clicked, a toggle switched, a list's choice activated), at the next update, when it's shown, enabled and can be: as a test or an autopilot does, by name rather than by place. False, doing nothing, when there's no such widget or it isn't usable now.
- `focused`: The widget with focus, or null.
- `focusedName`: The focused widget's name, or "" (for a check's probe).
- `capturingKeys`: Whether a widget has the keys: a game should leave arrows, Enter and Space be.
- `backPressed`: Whether Escape or a pad's East was pressed this frame (not held over from before reset).
- `reset`: A new screen begins: no focus, and keys and buttons held now do nothing until they're let go.
- `update`: Once a frame, after the pointer's update and before reading the widgets: moves focus, activates, and brings each widget up to date.

## Widget

*class* in `src/helix/ui/Widget.hx`

A piece of UI: nodes it owns (under its root, on the Ui's stage) and the layout box placing them. A widget is asked what happened (clicked, value ...), never calls anything (DECISIONS 61); the Ui updates it once a frame.

```haxe
var name(default, null):String
var box(default, null):Box
var root(default, null):Node2D
var enabled:Bool
var visible(get, set):Bool
var focusable(get, never):Bool
```

- `name`: Its name: what the focus is published as (Ui.focusedName), for checks.
- `box`: The box placing it: put it in a layout.
- `root`: Its root node, everything it draws under it.
- `enabled`: Whether it can be used: a disabled one is drawn dimmed, can't take focus and does nothing.
- `visible`: Whether it's shown: it, and any panel holding it.
- `focusable`: Whether focus can rest on it.
