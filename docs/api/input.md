# helix.input

[Back to the index](README.md)

## Actions

*class* in `src/helix/input/Actions.hx`

What the player means ("jump", "steer", "fire"), bound by name to keys, pad buttons and axes, mouse buttons and touch regions, and read as one: a game asks for "jump", never for Space or the south button, and a player can rebind it (capture) and keep it (save, load). Each binding gives a value from -1 to 1 (Binding), and the action is the binding pushed furthest, across every pad: axis its value, value how far (0 to 1), isDown while any binding is pushed to its limit (0.5, or a pad axis's non-zero threshold). Pressed and released come per tick (isPressed, isReleased) and per frame (isFramePressed, isFrameReleased), as IInput's do: an action is pressed when it is down and wasn't as the last tick (or frame) ended, or when a key, button or finger of it went down since (IInput's own edges, so a tap shorter than a tick is still a press, and two taps reach two ticks). The map keeps whether each action was down itself, told by the input as each tick and frame ends (IInput.watch), so a game makes no extra calls. A finger's edges are frame edges only (IInput has no tick edges for touches): a tap shorter than a frame reaches isFramePressed, not isPressed. An action never bound reads as up and 0, so a game's code may run before its bindings load. Built on IInput, so whatever drives the input drives the actions: the autopilot's input given to it (input) replays them.

```haxe
function new(input:IInput, ?presentation:Presentation)
static var VERSION(inline, null):Int
static var CAPTURE_THRESHOLD(inline, null):Float
static function describe(binding:Binding):String
var input(default, set):Null<IInput>
var presentation:Null<Presentation>
var names(get, never):Array<String>
var capturing(default, null):Bool
var captureTouchSize(default, set):Float
function bind(name:String, binding:Binding):Bool
function unbind(name:String, binding:Binding):Bool
function clear(name:String):Bool
function bindings(name:String):Array<Binding>
function axis(name:String):Float
function value(name:String):Float
function isDown(name:String):Bool
function isPressed(name:String):Bool
function isReleased(name:String):Bool
function isFramePressed(name:String):Bool
function isFrameReleased(name:String):Bool
function capture(name:String, done:Binding -> Void, ?cancelled:() -> Void):Bool
function cancelCapture():Bool
function save(?key:String = "actions", ?done:() -> Void, ?failed:String -> Void):Void
function load(?key:String = "actions", ?done:() -> Void, ?failed:String -> Void):Void
function reset():Void
function tickEnded():Void
function frameEnded():Void
```

- `new`: Actions read from input, their touch regions placed on presentation's visible area (Screen.instance's when null).
- `VERSION`: The saved format's version (save, load).
- `CAPTURE_THRESHOLD`: How far past it a pad axis must go for capture to take it: half way, as down is for a binding without a threshold.
- `describe`: The text a remap screen shows for binding: "Space", "Left / Right", "Pad south", "D-pad left / D-pad right", "Left stick X", "Left stick left" (a stick with a side), "Right trigger", "Left mouse", "Touch".
- `input`: The input the actions are read from, which tells the map as each tick and frame ends; null reads every action as up. Assigning stops watching the input before: a game playing an autopilot's script gives it the script's input, and an Actions given up is given null.
- `presentation`: Whose visible area and units touch regions are in: null for Screen's (Screen.instance), read as each finger is. Without either (a unit test with no runner) a touch region reads nothing; a test gives its own Presentation, whose None mode is logical pixels.
- `names`: The actions, in the order first bound; an action cleared or unbound to nothing stays.
- `capturing`: Whether capture is waiting for a press; while it is, every action reads as up.
- `captureTouchSize`: The width and height of a touch region capture makes, centered where the finger landed, in the game's units (Screen's). At least 1; 96 to begin with.
- `bind`: Adds binding to the action name, making the action with its first binding. False, changing nothing, for an empty name, a binding the action has already, a pad axis's side not -1, 0 or 1 or threshold outside 0 to 1, or a touch region with no area or an offset that isn't a number.
- `unbind`: Takes binding off the action name, the action kept; false for an action or binding there isn't.
- `clear`: Takes every binding off the action name, the action kept (a remap screen binds it again); false for an action there isn't.
- `bindings`: The action's bindings, in the order bound (a copy); empty for an action there isn't.
- `axis`: The action's value with its direction, -1 to 1: the binding pushed furthest. 0 for an action there isn't.
- `value`: How far the action is pushed, 0 to 1: axis without its direction.
- `isDown`: Whether the action is held: any of its bindings pushed to 0.5, or a pad axis to its threshold when that isn't 0.
- `isPressed`: The action went down: since the last tick ended, it went down, or a key, button or mouse button of it did (a tick edge).
- `isReleased`: The action came up: it was down as the last tick ended and isn't now, or a key, button or mouse button of it came up and it isn't down (a tick edge).
- `isFramePressed`: The action went down this frame, as isPressed for the frame, a finger landing in a touch region too (a frame edge).
- `isFrameReleased`: The action came up this frame, as isReleased for the frame, a finger lifting in a touch region too (a frame edge).
- `capture`: Waits for the player's next press and binds it to the action name: a key, a pad button, a pad axis pushed past half way (Axis with its side and a threshold of CAPTURE_THRESHOLD), or a finger (a captureTouchSize square centered where it landed, anchored to the nearest of the visible area's nine anchors). Mouse buttons aren't captured, as the mouse works the remap screen itself. The press replaces the action's bindings of the same device (the keyboard's Keyboard and KeyboardPair; the pad's Pad, PadPair and Axis; the touch screen's TouchRegion) and leaves the others; done is then called with it. Escape cancels, calling cancelled. Presses in the frame capture is called in don't count (the click or tap on a Rebind button), and while it waits every action reads as up; the captured press, and the Escape, read as up until they are let go. False, starting nothing, for an empty name or while capturing already.
- `cancelCapture`: Stops a capture waiting for a press, calling its cancelled (a remap screen's Cancel button); false when none is waiting.
- `save`: Writes every action's bindings under key in Storage, as JSON: {"version":1,"actions":{"jump":[{"key":"Space"},{"padButton":"South"}]}}, each binding by its kind ({"keys":["Left","Right"]}, {"padButtons":["Left","Right"]}, {"padAxis":"LeftX","side":0,"threshold":0.15}, {"mouseButton":"Left"}, {"touch":"BottomRight","x":-120,"y":-120,"width":96,"height":96}), keys by Key.getName. Then done; a failure (no Storage, a write refused) goes to failed, or to the log when failed is null.
- `load`: Reads the bindings saved under key in Storage, and replaces the bindings of each action the game has bound with the saved ones; an action the save names but the game doesn't bind is dropped, an action the save doesn't name keeps its bindings, and an entry the map can't read (an unknown kind or name, a refused binding) is skipped and logged (Failure). Then done, also when nothing was saved; a failure (no Storage, a read failing, a file that isn't a version 1 save) goes to failed, or to the log when failed is null, the bindings unchanged. The defaults reset restores are kept first.
- `reset`: Restores each action's defaults: its bindings as the game bound them in code, kept at the first load or capture after the action was made (so what a player changed, by a capture or a loaded save, goes back). An action made after the last load or capture has no defaults yet and keeps its bindings.
- `tickEnded`: For the input (IInputWatcher): keeps whether each action was down as the tick ended, and lets go of a captured press seen up.
- `frameEnded`: For the input (IInputWatcher): takes a press for capture, keeps whether each action was down as the frame ended, and lets go of a captured press seen up.

## Anchor

*enum* in `src/helix/input/Anchor.hx`

A point of the visible area (Screen's), which a touch region is placed from: a corner, an edge's middle or the center.

- `TopLeft`: The visible area's top left corner.
- `Top`: The middle of its top edge.
- `TopRight`: Its top right corner.
- `Left`: The middle of its left edge.
- `Center`: Its center.
- `Right`: The middle of its right edge.
- `BottomLeft`: Its bottom left corner.
- `Bottom`: The middle of its bottom edge.
- `BottomRight`: Its bottom right corner.

## Binding

*enum* in `src/helix/input/Binding.hx`

What drives an action (Actions), each giving a value from -1 to 1; the action is the binding pushed furthest.

- `Keyboard(key:Key)`: A key: 1 while it is down.
- `KeyboardPair(negative:Key, positive:Key)`: A pair of keys as an axis: -1 while negative is down, 1 while positive is, 0 for both or neither.
- `Pad(button:PadButton)`: A pad button on any connected pad: 1 while it is down.
- `PadPair(negative:PadButton, positive:PadButton)`: A pair of pad buttons as an axis, across the pads: -1 for negative, 1 for positive, 0 for both or neither (the d-pad's Left and Right as steering).
- `Axis(axis:PadAxis, side:Int, threshold:Float)`: A pad axis, past the dead zone (Gamepad.getAxis), the pad pushed furthest: side 0 reads both directions (-1..1, a trigger 0..1), 1 or -1 only that side, as 0..1; under threshold (0..1) it reads 0, and at or past a non-zero threshold the action is down.
- `Mouse(button:MouseButton)`: A mouse button: 1 while it is down.
- `TouchRegion(anchor:Anchor, x:Float, y:Float, width:Float, height:Float)`: A touch region: 1 while a finger is down in it. In the game's units (Screen's): the anchor's point on the visible area, then x, y from it to the region's top left, width x height across and down; so it scales with the design and follows the visible area's edges.

## Gamepad

*class* in `src/helix/input/Gamepad.hx`

One gamepad slot. Edges work as the keyboard's: tick edges until consume(), frame edges until the frame ends. Sticks read past a radial dead zone, rescaled so they still reach 1; getRawAxis reads them as the pad reports.

```haxe
function new()
var connected(default, null):Bool
var name(default, null):String
var deadzone(default, set):Float
function isDown(button:PadButton):Bool
function isPressed(button:PadButton):Bool
function isReleased(button:PadButton):Bool
function isFramePressed(button:PadButton):Bool
function isFrameReleased(button:PadButton):Bool
function getRawAxis(axis:PadAxis):Float
function getAxis(axis:PadAxis):Float
function connect(value:Bool, name:String):Void
function buttonEvent(button:PadButton, value:Bool):Void
function axisEvent(axis:PadAxis, value:Float):Void
function consume():Void
function endFrame():Void
```

- `new`: An empty slot.
- `connected`: Whether a pad is in this slot. While the window is unfocused a pad stays connected, its buttons up and axes centred.
- `name`: The pad's name as the platform reports it; empty when the slot is empty.
- `deadzone`: Fraction of a stick's reach that reads as centred. Clamped to 0 (none) to 0.999 (NaN is 0).
- `isDown`: Whether the button is held now.
- `isPressed`: The button went down: a counted tick edge, as a key's, so two presses between ticks reach two ticks.
- `isReleased`: The button came up: a counted tick edge.
- `isFramePressed`: The button went down this frame: a frame edge.
- `isFrameReleased`: The button came up this frame: a frame edge.
- `getRawAxis`: The axis as the pad reports it, without the dead zone: sticks -1..1, triggers 0..1.
- `getAxis`: A stick axis past the radial dead zone, rescaled to reach 1, -1..1; a trigger as reported, 0..1.
- `connect`: Fills the slot with a named pad (true) or empties it (false), for the InputRouter; emptying lets go of every button and centres every axis.
- `buttonEvent`: A button's state, from the InputRouter; going down sets both press edges.
- `axisEvent`: An axis's value, from the InputRouter, clamped to -1..1 for a stick and 0..1 for a trigger.
- `consume`: Clears the tick edges; the input's consume() calls it after each tick.
- `endFrame`: Clears the frame edges; the input's endFrame() calls it after each frame.

## IInput

*class* in `src/helix/input/IInput.hx`

Keyboard, pointer, mouse buttons, wheel, typed text, touches and gamepads. Tick edges (isPressed, isReleased) are counted and survive polling and render frames; consume() after a simulation tick takes one of each, so every press is seen by exactly one tick, and two presses between ticks reach two ticks. Frame edges (isFramePressed, isFrameReleased), typed text, the wheel and lifted touches last one frame. A key is claimed by what reads it first and uses it (claim: the UI's focused text field, a menu): for the rest of the frame it reads as up, unpressed and unreleased to everything after, so typing a space in a field doesn't make the player jump.

```haxe
function isDown(key:Key):Bool
function isPressed(key:Key):Bool
function isReleased(key:Key):Bool
function isFramePressed(key:Key):Bool
function isFrameReleased(key:Key):Bool
function claim(key:Key):Void
function isClaimed(key:Key):Bool
var pointerX(get, never):Float
var pointerY(get, never):Float
var pointerDown(get, never):Bool
var pointerPressed(get, never):Bool
var pointerReleased(get, never):Bool
var pointerFramePressed(get, never):Bool
var pointerFrameReleased(get, never):Bool
function isMouseDown(button:MouseButton):Bool
function isMousePressed(button:MouseButton):Bool
function isMouseFramePressed(button:MouseButton):Bool
function isMouseReleased(button:MouseButton):Bool
function isMouseFrameReleased(button:MouseButton):Bool
var wheelX(get, never):Float
var wheelY(get, never):Float
var text(get, never):String
var textEntry(get, set):Bool
var touches(get, never):Array<Touch>
var touchGesture(get, never):Bool
var touchGestureCenterX(get, never):Float
var touchGestureCenterY(get, never):Float
function getTouchGesturePanX(?perTick:Bool = false):Float
function getTouchGesturePanY(?perTick:Bool = false):Float
function getTouchGestureScale(?perTick:Bool = false):Float
function getTouchGestureRotation(?perTick:Bool = false):Float
var padCount(get, never):Int
function getPad(index:Int):Null<Gamepad>
var activated(get, never):Bool
var anyFramePressed(get, never):Bool
function isPadDown(button:PadButton):Bool
function isPadPressed(button:PadButton):Bool
function getPadAxis(axis:PadAxis):Float
function consume():Void
function watch(watcher:IInputWatcher):Bool
function unwatch(watcher:IInputWatcher):Bool
```

- `isDown`: Whether the key is held now.
- `isPressed`: The key went down: a tick edge, counted until consume() takes it.
- `isReleased`: The key came up: a tick edge, counted until consume() takes it.
- `isFramePressed`: The key went down this frame: a frame edge.
- `isFrameReleased`: The key came up this frame: a frame edge.
- `claim`: Takes key for the rest of the frame: what reads it after sees it up, unpressed and unreleased (isDown, isPressed, isReleased and the frame edges false) until the frame ends, and its edges are spent, so no later tick sees them either. Whoever reads first and uses a key claims it: the UI does (Ui.update), so the game reads after it.
- `isClaimed`: Whether key was claimed this frame (claim).
- `pointerX`: The primary pointer, in framebuffer pixels: the mouse with its left button, or the first finger. -1 when it isn't over the window.
- `pointerY`: The primary pointer's y, in framebuffer pixels down from the top. -1 when it isn't over the window.
- `pointerDown`: Whether the primary pointer is down: the left mouse button held, or the first finger touching.
- `pointerPressed`: The primary pointer went down: a tick edge, counted until consume() takes it.
- `pointerReleased`: The primary pointer came up: a tick edge, counted until consume() takes it.
- `pointerFramePressed`: The primary pointer went down this frame: a frame edge.
- `pointerFrameReleased`: The primary pointer came up this frame: a frame edge.
- `isMouseDown`: Whether the mouse button is held now.
- `isMousePressed`: The mouse button went down: a tick edge, counted until consume() takes it.
- `isMouseFramePressed`: The mouse button went down this frame: a frame edge.
- `isMouseReleased`: The button came up: a counted tick edge, as a key's.
- `isMouseFrameReleased`: The button came up this frame: a frame edge.
- `wheelX`: Wheel notches this frame; up and right are positive.
- `wheelY`: Vertical wheel notches this frame; up is positive.
- `text`: Characters typed this frame, after the keyboard layout; only while text entry is on (textEntry).
- `textEntry`: Whether typed text is being taken; off at start. On, text carries the characters typed, and a platform with a soft keyboard shows it for them; off, keys are only keys and the keyboard stays down. The UI turns it on while a text field has focus; a game reading text itself turns it on while it types (a name entered, a chat line) and off after.
- `touches`: Fingers down, and those lifted this frame.
- `touchGesture`: Whether two fingers are down: the two down longest make the gesture.
- `touchGestureCenterX`: The point between the gesture's fingers now, in framebuffer pixels; 0 without a gesture.
- `touchGestureCenterY`: See touchGestureCenterX.
- `getTouchGesturePanX`: How far the point between the fingers moved, in framebuffer pixels: this frame, or since the last tick with perTick.
- `getTouchGesturePanY`: See getTouchGesturePanX.
- `getTouchGestureScale`: How much the fingers spread (over 1) or pinched (under 1), as a factor: this frame, or since the last tick with perTick; 1 without.
- `getTouchGestureRotation`: How far the line between the fingers turned, in radians, clockwise on screen positive: this frame, or since the last tick with perTick.
- `padCount`: Four slots, connected or not.
- `getPad`: null for an index out of range.
- `activated`: Whether the user has pressed a key, a mouse button or a finger yet (the browser's user activation, which lets audio start and fullscreen be asked for; the same rule everywhere, so a game's flow is one flow): a title screen's "press any key". A pad's press doesn't count, as a browser can't unlock with one, so a game on a pad alone asks for a tap or key once. Stays true. An autopilot's press counts, so a script gated on it presses before it waits.
- `anyFramePressed`: Whether a key, a mouse button or a finger went down this frame, whichever: a "press any key" screen's press. A pad's doesn't count, as activated's doesn't.
- `isPadDown`: Any connected pad.
- `isPadPressed`: A connected pad's button went down: a counted tick edge, as a key's.
- `getPadAxis`: The first connected pad's axis, past the dead zone as Gamepad.getAxis gives it.
- `consume`: Call after each simulation tick: takes one of each counted tick edge and clears the pads' tick edges.
- `watch`: Plumbing for what is built on the input, not for a game (the Input static leaves it out): tells watcher as each tick and each frame ends (consume, and the frame's end), before their edges are cleared, which is how an action map (Actions) keeps its own previous states without calls from the game. False, changing nothing, for a watcher already told.
- `unwatch`: Plumbing, as watch: stops telling watcher; false for one not told.

## IInputEvents

*class* in `src/helix/input/IInputEvents.hx`

What an IInputSource reports to: the platform's input events as they are. Positions are framebuffer pixels from the top left.

```haxe
function key(key:Key, down:Bool):Void
function text(chars:String):Void
function mouseButton(button:MouseButton, down:Bool, x:Float, y:Float):Void
function mouseMove(x:Float, y:Float):Void
function mouseLeave():Void
function wheel(x:Float, y:Float):Void
function touch(id:Int, x:Float, y:Float, down:Bool):Void
function focus(focused:Bool):Void
function pad(name:String, buttons:Array<Bool>, axes:Array<Float>):Void
```

- `key`: A key went down (true) or up (false); a repeat may report down again.
- `text`: Characters typed, after the keyboard layout.
- `mouseButton`: A mouse button went down or up with the mouse at x, y. A source may report every button's state on each event.
- `mouseMove`: The mouse moved to x, y.
- `mouseLeave`: The mouse left the window, or the platform took it over (a cancelled pointer).
- `wheel`: The wheel turned, in notches; up and right are positive.
- `touch`: A finger touched (down true), moved (true) or lifted (false), at x, y.
- `focus`: The window gained (true) or lost (false) the input: lost while it is unfocused or hidden.
- `pad`: A connected gamepad's state at poll: its name, each PadButton's state by number and each PadAxis's value by number (sticks -1..1, triggers 0..1). The arrays are read during the call only.

## IInputSource

*class* in `src/helix/input/IInputSource.hx`

A platform's input: its keyboard, mouse, touch, focus and gamepad events reported as they are, in order, to the shared InputRouter, which makes the input an app reads from them. Edges, the pointer, focus policy and pad slots are the router's.

```haxe
function start(events:IInputEvents):Void
function poll():Void
function setTextEntry(on:Bool):Void
function shutdown():Void
```

- `start`: Reports to events from now on, on the host thread: as the platform's events arrive, or at poll. Called once, before the first poll.
- `poll`: Before the app's frame: reports what arrived since the last poll, then every connected gamepad's state, in the platform's order.
- `setTextEntry`: Asks the platform for typed text while on (SDL3's text input; a soft keyboard where the platform has one), and no longer when off. The router calls it before a poll, as the app's text entry (IInput.setTextEntry) changes; off until then.
- `shutdown`: Releases the platform's input, after the app's cleanup.

## IInputWatcher

*class* in `src/helix/input/IInputWatcher.hx`

Told by an IInput (watch) as a tick's edges and a frame's end, before they are cleared: what keeps a state of its own from tick to tick and frame to frame over the input, as an action map (Actions) keeps whether each action was down.

```haxe
function tickEnded():Void
function frameEnded():Void
```

- `tickEnded`: A simulation tick ended: the input's consume() is taking one of each tick edge, after this.
- `frameEnded`: The frame ended: its frame edges, text, wheel and lifted touches end after this.

## Input

*class* in `src/helix/input/Input.hx`

Keyboard, mouse, touch and gamepads, as this frame and tick see them. The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from IInput's public members with their doc comments, but watch and unwatch (plumbing for what is built on IInput, as Actions, not for a game).

```haxe
static var instance(default, null):IInput
static function isDown(key:Key):Bool
static function isPressed(key:Key):Bool
static function isReleased(key:Key):Bool
static function isFramePressed(key:Key):Bool
static function isFrameReleased(key:Key):Bool
static function claim(key:Key):Void
static function isClaimed(key:Key):Bool
static var pointerX(get, never):Float
static var pointerY(get, never):Float
static var pointerDown(get, never):Bool
static var pointerPressed(get, never):Bool
static var pointerReleased(get, never):Bool
static var pointerFramePressed(get, never):Bool
static var pointerFrameReleased(get, never):Bool
static function isMouseDown(button:MouseButton):Bool
static function isMousePressed(button:MouseButton):Bool
static function isMouseFramePressed(button:MouseButton):Bool
static function isMouseReleased(button:MouseButton):Bool
static function isMouseFrameReleased(button:MouseButton):Bool
static var wheelX(get, never):Float
static var wheelY(get, never):Float
static var text(get, never):String
static var textEntry(get, set):Bool
static var touches(get, never):Array<Touch>
static var touchGesture(get, never):Bool
static var touchGestureCenterX(get, never):Float
static var touchGestureCenterY(get, never):Float
static function getTouchGesturePanX(?perTick:Bool = false):Float
static function getTouchGesturePanY(?perTick:Bool = false):Float
static function getTouchGestureScale(?perTick:Bool = false):Float
static function getTouchGestureRotation(?perTick:Bool = false):Float
static var padCount(get, never):Int
static function getPad(index:Int):Null<Gamepad>
static var activated(get, never):Bool
static var anyFramePressed(get, never):Bool
static function isPadDown(button:PadButton):Bool
static function isPadPressed(button:PadButton):Bool
static function getPadAxis(axis:PadAxis):Float
static function consume():Void
```

- `instance`: The input forwarded to: the runner's router's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `isDown`: Whether the key is held now.
- `isPressed`: The key went down: a tick edge, counted until consume() takes it.
- `isReleased`: The key came up: a tick edge, counted until consume() takes it.
- `isFramePressed`: The key went down this frame: a frame edge.
- `isFrameReleased`: The key came up this frame: a frame edge.
- `claim`: Takes key for the rest of the frame: what reads it after sees it up, unpressed and unreleased (isDown, isPressed, isReleased and the frame edges false) until the frame ends, and its edges are spent, so no later tick sees them either. Whoever reads first and uses a key claims it: the UI does (Ui.update), so the game reads after it.
- `isClaimed`: Whether key was claimed this frame (claim).
- `pointerX`: The primary pointer, in framebuffer pixels: the mouse with its left button, or the first finger. -1 when it isn't over the window.
- `pointerY`: The primary pointer's y, in framebuffer pixels down from the top. -1 when it isn't over the window.
- `pointerDown`: Whether the primary pointer is down: the left mouse button held, or the first finger touching.
- `pointerPressed`: The primary pointer went down: a tick edge, counted until consume() takes it.
- `pointerReleased`: The primary pointer came up: a tick edge, counted until consume() takes it.
- `pointerFramePressed`: The primary pointer went down this frame: a frame edge.
- `pointerFrameReleased`: The primary pointer came up this frame: a frame edge.
- `isMouseDown`: Whether the mouse button is held now.
- `isMousePressed`: The mouse button went down: a tick edge, counted until consume() takes it.
- `isMouseFramePressed`: The mouse button went down this frame: a frame edge.
- `isMouseReleased`: The button came up: a counted tick edge, as a key's.
- `isMouseFrameReleased`: The button came up this frame: a frame edge.
- `wheelX`: Wheel notches this frame; up and right are positive.
- `wheelY`: Vertical wheel notches this frame; up is positive.
- `text`: Characters typed this frame, after the keyboard layout; only while text entry is on (textEntry).
- `textEntry`: Whether typed text is being taken; off at start. On, text carries the characters typed, and a platform with a soft keyboard shows it for them; off, keys are only keys and the keyboard stays down. The UI turns it on while a text field has focus; a game reading text itself turns it on while it types (a name entered, a chat line) and off after.
- `touches`: Fingers down, and those lifted this frame.
- `touchGesture`: Whether two fingers are down: the two down longest make the gesture.
- `touchGestureCenterX`: The point between the gesture's fingers now, in framebuffer pixels; 0 without a gesture.
- `touchGestureCenterY`: See touchGestureCenterX.
- `getTouchGesturePanX`: How far the point between the fingers moved, in framebuffer pixels: this frame, or since the last tick with perTick.
- `getTouchGesturePanY`: See getTouchGesturePanX.
- `getTouchGestureScale`: How much the fingers spread (over 1) or pinched (under 1), as a factor: this frame, or since the last tick with perTick; 1 without.
- `getTouchGestureRotation`: How far the line between the fingers turned, in radians, clockwise on screen positive: this frame, or since the last tick with perTick.
- `padCount`: Four slots, connected or not.
- `getPad`: null for an index out of range.
- `activated`: Whether the user has pressed a key, a mouse button or a finger yet (the browser's user activation, which lets audio start and fullscreen be asked for; the same rule everywhere, so a game's flow is one flow): a title screen's "press any key". A pad's press doesn't count, as a browser can't unlock with one, so a game on a pad alone asks for a tap or key once. Stays true. An autopilot's press counts, so a script gated on it presses before it waits.
- `anyFramePressed`: Whether a key, a mouse button or a finger went down this frame, whichever: a "press any key" screen's press. A pad's doesn't count, as activated's doesn't.
- `isPadDown`: Any connected pad.
- `isPadPressed`: A connected pad's button went down: a counted tick edge, as a key's.
- `getPadAxis`: The first connected pad's axis, past the dead zone as Gamepad.getAxis gives it.
- `consume`: Call after each simulation tick: takes one of each counted tick edge and clears the pads' tick edges.

## InputRouter

*class* in `src/helix/input/InputRouter.hx`

Makes the input an app reads (an InputState) from a platform's events, the same on every platform: - the primary pointer is the mouse with its left button, or the first finger down; a second finger lets it go, off the window, so a pinch never drops or clicks anything, and the pointer stays let go until every finger lifts; - losing focus lets go of everything, and while unfocused presses, text, the wheel and pads are ignored (releases and moves still count); - text is ignored while Control or Super is held (a shortcut, not typing); Alt isn't, because AltGr and macOS's Option type characters; - the first four connected gamepads fill the four slots in the platform's order, and the rest of the slots are empty.

```haxe
function new()
var input(get, never):IInput
function poll(source:IInputSource):Void
function endFrame():Void
function key(key:Key, down:Bool):Void
function text(chars:String):Void
function mouseButton(button:MouseButton, down:Bool, x:Float, y:Float):Void
function mouseMove(x:Float, y:Float):Void
function mouseLeave():Void
function wheel(x:Float, y:Float):Void
function touch(id:Int, x:Float, y:Float, down:Bool):Void
function focus(value:Bool):Void
function pad(name:String, buttons:Array<Bool>, axes:Array<Float>):Void
```

- `new`: Focused, with nothing held.
- `input`: The input the app reads.
- `poll`: Before the app's frame: tells source when the app's text entry changed, has it report what arrived, then empties the pad slots no connected pad reported into.
- `endFrame`: After the app's frame: the frame's edges, text, wheel and lifted touches end.

## InputState

*class* in `src/helix/input/InputState.hx`

The input an app reads, as edges and state: fed by the InputRouter from a platform's events, or directly by replay and tests. Tick edges (isPressed, isReleased) are counted, and consume() after a simulation tick takes one of each, so every press is seen by exactly one tick, and two presses between ticks reach two ticks; frame edges (isFramePressed, isFrameReleased), typed text, the wheel and lifted touches last one frame, until endFrame() (the InputRouter's, which the Runner calls).

```haxe
function new()
function isDown(key:Key):Bool
function isPressed(key:Key):Bool
function isReleased(key:Key):Bool
function isFramePressed(key:Key):Bool
function isFrameReleased(key:Key):Bool
function claim(key:Key):Void
function isClaimed(key:Key):Bool
var pointerX(get, never):Float
var pointerY(get, never):Float
var pointerDown(get, never):Bool
var pointerPressed(get, never):Bool
var pointerReleased(get, never):Bool
var pointerFramePressed(get, never):Bool
var pointerFrameReleased(get, never):Bool
var wheelX(get, never):Float
var wheelY(get, never):Float
var text(get, never):String
var textEntry(get, set):Bool
var touches(get, never):Array<Touch>
var padCount(get, never):Int
function getPad(index:Int):Null<Gamepad>
function isMouseDown(button:MouseButton):Bool
function isMousePressed(button:MouseButton):Bool
function isMouseFramePressed(button:MouseButton):Bool
function isMouseReleased(button:MouseButton):Bool
function isMouseFrameReleased(button:MouseButton):Bool
function isPadDown(button:PadButton):Bool
function isPadPressed(button:PadButton):Bool
function getPadAxis(axis:PadAxis):Float
var activated(get, never):Bool
var anyFramePressed(get, never):Bool
function keyEvent(key:Key, value:Bool):Void
function padEvent(button:PadButton, value:Bool):Void
function axisEvent(axis:PadAxis, value:Float):Void
function mouseEvent(button:MouseButton, value:Bool):Void
function pointerEvent(x:Float, y:Float, value:Bool):Void
function textEvent(value:String):Void
function wheelEvent(x:Float, y:Float):Void
function touchEvent(id:Int, x:Float, y:Float, value:Bool):Void
var touchGesture(get, never):Bool
var touchGestureCenterX(get, never):Float
var touchGestureCenterY(get, never):Float
function getTouchGesturePanX(?perTick:Bool = false):Float
function getTouchGesturePanY(?perTick:Bool = false):Float
function getTouchGestureScale(?perTick:Bool = false):Float
function getTouchGestureRotation(?perTick:Bool = false):Float
function clear():Void
function watch(watcher:IInputWatcher):Bool
function unwatch(watcher:IInputWatcher):Bool
function consume():Void
function endFrame():Void
```

- `new`: Nothing down, nothing pressed, no pad connected, not activated.
- `keyEvent`: A key down (true) or up (false); only a change of state counts an edge, so key repeat doesn't. A down activates (activated).
- `padEvent`: Pad 0's button or axis, connecting it: for replay and tests.
- `axisEvent`: Pad 0's axis, connecting it: for replay and tests.
- `mouseEvent`: A mouse button down (true) or up (false); only a change of state counts an edge.
- `pointerEvent`: The primary pointer at x, y in framebuffer pixels (-1, -1 off the window), down or up; only a change of down counts an edge.
- `textEvent`: Typed characters, appended to this frame's text while text entry is on; dropped while it's off.
- `wheelEvent`: Wheel notches, added to this frame's; up and right are positive.
- `touchEvent`: A finger down, moved or lifted. A lifted one stays in touches, not down, until the frame ends.
- `clear`: Lets go of everything held, as when focus is lost: the releases are edges; presses not yet consumed, typed text and the wheel are dropped.
- `endFrame`: Tells the watchers, then ends the frame's edges, text, wheel and lifted touches; the InputRouter calls it after each frame.

## Key

*abstract* in `src/helix/input/Key.hx`

Physical keys by place on a US layout, numbered as GLFW numbers them; each input adapter maps its platform's codes to them. Left and right Shift, Control, Alt and Super are one key each.

## MouseButton

*abstract* in `src/helix/input/MouseButton.hx`

The mouse buttons HeliX reads, numbered as Sokol numbers them.

## PadAxis

*abstract* in `src/helix/input/PadAxis.hx`

Sticks run from -1 to 1 (down and right positive), triggers from 0 to 1.

## PadButton

*abstract* in `src/helix/input/PadButton.hx`

A gamepad's buttons, as on an Xbox-style pad, numbered as the W3C standard gamepad numbers them. The triggers are buttons too (pressed when pulled past half way, or by a digital trigger) as well as axes.

## PointerGestures

*class* in `src/helix/input/PointerGestures.hx`

Taps, double taps, drags and flicks from IInput's pointer, in framebuffer pixels; touch and mouse alike (a double tap is a double click). Update once per tick, before the input is consumed, reading its tick edges; or once per frame, reading its frame edges, in a program without a fixed tick.

```haxe
function new(?slop:Float = 12., ?tapSeconds:Float = .3)
var maxTapDistance(get, set):Float
var maxTapDuration(get, set):Float
var maxDoubleTapInterval(get, set):Float
var maxDoubleTapDistance(get, set):Float
var down(default, null):Bool
var pressed(default, null):Bool
var released(default, null):Bool
var dragging(default, null):Bool
var tapped(default, null):Bool
var doubleTapped(default, null):Bool
var x(default, null):Float
var y(default, null):Float
var startX(default, null):Float
var startY(default, null):Float
var flickVelocityX(get, never):Float
var flickVelocityY(get, never):Float
function update(input:IInput, now:Float, perTick:Bool):Void
```

- `new`: Gestures with a tap's limits: slop in framebuffer pixels, tapSeconds in seconds, clamped as maxTapDistance and maxTapDuration are.
- `maxTapDistance`: How far a press may move and still be a tap, in pixels. 0 or more (under 0, or NaN, is 0).
- `maxTapDuration`: How long a press may last and still be a tap, in seconds. At least 1e-6 (0 or less, or NaN, is 1e-6).
- `maxDoubleTapInterval`: How long after one tap began the next may begin and make a double tap, in seconds. At least 1e-6 (0 or less, or NaN, is 1e-6); half a second at first.
- `maxDoubleTapDistance`: How far from where one tap began the next may begin and make a double tap, in pixels. 0 or more (under 0, or NaN, is 0); 24 at first.
- `down`: Whether the pointer is down, as of the last update.
- `pressed`: The pointer went down at the last update.
- `released`: The pointer came up at the last update.
- `dragging`: Moved past the slop during this press.
- `tapped`: The press that ended at the last update was a tap: it stayed within the slop and the tap time.
- `doubleTapped`: The tap that ended at the last update was the second of a double tap (a double click): it began within maxDoubleTapInterval of the tap before it and within maxDoubleTapDistance of where that one began. A third tap starts a new pair.
- `x`: The pointer's x in framebuffer pixels, as of the last update while down; it holds while the pointer is off the window, and after release.
- `y`: The pointer's y in framebuffer pixels, held as x is.
- `startX`: Where the current or last press began, x in framebuffer pixels.
- `startY`: Where the current or last press began, y in framebuffer pixels.
- `flickVelocityX`: Velocity over the last tenth of a second before release, pixels per second.
- `flickVelocityY`: Vertical velocity as flickVelocityX, down positive.
- `update`: Reads the pointer: once per tick with perTick, its tick edges, before the input is consumed; or once per frame without, its frame edges. now is the time in seconds.

## Touch

*typedef* in `src/helix/input/Touch.hx`

A finger, in framebuffer pixels like the pointer. Its id stays the same while it is down.

- `y:Float`
- `x:Float`
- `released:Bool`
- `pressed:Bool`
- `id:Int`
- `down:Bool`
