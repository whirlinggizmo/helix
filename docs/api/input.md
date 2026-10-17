# helix.input

[Back to the index](README.md)

## Gamepad

*class* in `src/helix/input/Gamepad.hx`

One gamepad slot. Edges work as the keyboard's: tick edges until consume(), frame edges until the frame ends. Sticks read past a radial dead zone, rescaled so they still reach 1; getRawAxis reads them as the pad reports.

```haxe
function new()
function isConnected():Bool
function getName():String
function getDeadzone():Float
function setDeadzone(value:Float):Bool
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
- `isConnected`: Whether a pad is in this slot. While the window is unfocused a pad stays connected, its buttons up and axes centred.
- `getName`: The pad's name as the platform reports it; empty when the slot is empty.
- `getDeadzone`: Fraction of a stick's reach that reads as centred.
- `setDeadzone`: False for a value outside 0 (none) to just under 1.
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

Keyboard, pointer, mouse buttons, wheel, typed text, touches and gamepads. Tick edges (isPressed, isReleased) are counted and survive polling and render frames; consume() after a simulation tick takes one of each, so every press is seen by exactly one tick, and two presses between ticks reach two ticks. Frame edges (isFramePressed, isFrameReleased), typed text, the wheel and lifted touches last one frame.

```haxe
function isDown(key:Key):Bool
function isPressed(key:Key):Bool
function isReleased(key:Key):Bool
function isFramePressed(key:Key):Bool
function isFrameReleased(key:Key):Bool
function getPointerX():Float
function getPointerY():Float
function isPointerDown():Bool
function isPointerPressed():Bool
function isPointerReleased():Bool
function isPointerFramePressed():Bool
function isPointerFrameReleased():Bool
function isMouseDown(button:MouseButton):Bool
function isMousePressed(button:MouseButton):Bool
function isMouseFramePressed(button:MouseButton):Bool
function isMouseReleased(button:MouseButton):Bool
function isMouseFrameReleased(button:MouseButton):Bool
function getWheelX():Float
function getWheelY():Float
function getText():String
function isTextEntry():Bool
function setTextEntry(on:Bool):Void
function getTouches():Array<Touch>
function isTouchGesture():Bool
function getTouchGestureCenterX():Float
function getTouchGestureCenterY():Float
function getTouchGesturePanX(?perTick:Bool = false):Float
function getTouchGesturePanY(?perTick:Bool = false):Float
function getTouchGestureScale(?perTick:Bool = false):Float
function getTouchGestureRotation(?perTick:Bool = false):Float
function getPadCount():Int
function getPad(index:Int):Null<Gamepad>
function isActivated():Bool
function isAnyFramePressed():Bool
function isPadDown(button:PadButton):Bool
function isPadPressed(button:PadButton):Bool
function getPadAxis(axis:PadAxis):Float
function consume():Void
```

- `isDown`: Whether the key is held now.
- `isPressed`: The key went down: a tick edge, counted until consume() takes it.
- `isReleased`: The key came up: a tick edge, counted until consume() takes it.
- `isFramePressed`: The key went down this frame: a frame edge.
- `isFrameReleased`: The key came up this frame: a frame edge.
- `getPointerX`: The primary pointer, in framebuffer pixels: the mouse with its left button, or the first finger. -1 when it isn't over the window.
- `getPointerY`: The primary pointer's y, in framebuffer pixels down from the top. -1 when it isn't over the window.
- `isPointerDown`: Whether the primary pointer is down: the left mouse button held, or the first finger touching.
- `isPointerPressed`: The primary pointer went down: a tick edge, counted until consume() takes it.
- `isPointerReleased`: The primary pointer came up: a tick edge, counted until consume() takes it.
- `isPointerFramePressed`: The primary pointer went down this frame: a frame edge.
- `isPointerFrameReleased`: The primary pointer came up this frame: a frame edge.
- `isMouseDown`: Whether the mouse button is held now.
- `isMousePressed`: The mouse button went down: a tick edge, counted until consume() takes it.
- `isMouseFramePressed`: The mouse button went down this frame: a frame edge.
- `isMouseReleased`: The button came up: a counted tick edge, as a key's.
- `isMouseFrameReleased`: The button came up this frame: a frame edge.
- `getWheelX`: Wheel notches this frame; up and right are positive.
- `getWheelY`: Vertical wheel notches this frame; up is positive.
- `getText`: Characters typed this frame, after the keyboard layout; only while text entry is on (setTextEntry).
- `isTextEntry`: Whether typed text is being taken (setTextEntry); off at start.
- `setTextEntry`: Takes typed text or stops: on, getText carries the characters typed, and a platform with a soft keyboard shows it for them; off, keys are only keys and the keyboard stays down. The UI turns it on while a text field has focus; a game reading getText itself turns it on while it types (a name entered, a chat line) and off after.
- `getTouches`: Fingers down, and those lifted this frame.
- `isTouchGesture`: Whether two fingers are down: the two down longest make the gesture.
- `getTouchGestureCenterX`: The point between the gesture's fingers now, in framebuffer pixels; 0 without a gesture.
- `getTouchGestureCenterY`: See getTouchGestureCenterX.
- `getTouchGesturePanX`: How far the point between the fingers moved, in framebuffer pixels: this frame, or since the last tick with perTick.
- `getTouchGesturePanY`: See getTouchGesturePanX.
- `getTouchGestureScale`: How much the fingers spread (over 1) or pinched (under 1), as a factor: this frame, or since the last tick with perTick; 1 without.
- `getTouchGestureRotation`: How far the line between the fingers turned, in radians, clockwise on screen positive: this frame, or since the last tick with perTick.
- `getPadCount`: Four slots, connected or not.
- `getPad`: null for an index out of range.
- `isActivated`: Whether the user has pressed a key, a mouse button or a finger yet (the browser's user activation, which lets audio start and fullscreen be asked for; the same rule everywhere, so a game's flow is one flow): a title screen's "press any key". A pad's press doesn't count, as a browser can't unlock with one, so a game on a pad alone asks for a tap or key once. Stays true. An autopilot's press counts, so a script gated on it presses before it waits.
- `isAnyFramePressed`: Whether a key, a mouse button or a finger went down this frame, whichever: a "press any key" screen's press. A pad's doesn't count, as isActivated's doesn't.
- `isPadDown`: Any connected pad.
- `isPadPressed`: A connected pad's button went down: a counted tick edge, as a key's.
- `getPadAxis`: The first connected pad's axis, past the dead zone as Gamepad.getAxis gives it.
- `consume`: Call after each simulation tick: takes one of each counted tick edge and clears the pads' tick edges.

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

## Input

*class* in `src/helix/input/Input.hx`

Keyboard, mouse, touch and gamepads, as this frame and tick see them. The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from IInput's public members with their doc comments.

```haxe
static var instance(default, null):IInput
static function isDown(key:Key):Bool
static function isPressed(key:Key):Bool
static function isReleased(key:Key):Bool
static function isFramePressed(key:Key):Bool
static function isFrameReleased(key:Key):Bool
static function getPointerX():Float
static function getPointerY():Float
static function isPointerDown():Bool
static function isPointerPressed():Bool
static function isPointerReleased():Bool
static function isPointerFramePressed():Bool
static function isPointerFrameReleased():Bool
static function isMouseDown(button:MouseButton):Bool
static function isMousePressed(button:MouseButton):Bool
static function isMouseFramePressed(button:MouseButton):Bool
static function isMouseReleased(button:MouseButton):Bool
static function isMouseFrameReleased(button:MouseButton):Bool
static function getWheelX():Float
static function getWheelY():Float
static function getText():String
static function isTextEntry():Bool
static function setTextEntry(on:Bool):Void
static function getTouches():Array<Touch>
static function isTouchGesture():Bool
static function getTouchGestureCenterX():Float
static function getTouchGestureCenterY():Float
static function getTouchGesturePanX(?perTick:Bool = false):Float
static function getTouchGesturePanY(?perTick:Bool = false):Float
static function getTouchGestureScale(?perTick:Bool = false):Float
static function getTouchGestureRotation(?perTick:Bool = false):Float
static function getPadCount():Int
static function getPad(index:Int):Null<Gamepad>
static function isActivated():Bool
static function isAnyFramePressed():Bool
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
- `getPointerX`: The primary pointer, in framebuffer pixels: the mouse with its left button, or the first finger. -1 when it isn't over the window.
- `getPointerY`: The primary pointer's y, in framebuffer pixels down from the top. -1 when it isn't over the window.
- `isPointerDown`: Whether the primary pointer is down: the left mouse button held, or the first finger touching.
- `isPointerPressed`: The primary pointer went down: a tick edge, counted until consume() takes it.
- `isPointerReleased`: The primary pointer came up: a tick edge, counted until consume() takes it.
- `isPointerFramePressed`: The primary pointer went down this frame: a frame edge.
- `isPointerFrameReleased`: The primary pointer came up this frame: a frame edge.
- `isMouseDown`: Whether the mouse button is held now.
- `isMousePressed`: The mouse button went down: a tick edge, counted until consume() takes it.
- `isMouseFramePressed`: The mouse button went down this frame: a frame edge.
- `isMouseReleased`: The button came up: a counted tick edge, as a key's.
- `isMouseFrameReleased`: The button came up this frame: a frame edge.
- `getWheelX`: Wheel notches this frame; up and right are positive.
- `getWheelY`: Vertical wheel notches this frame; up is positive.
- `getText`: Characters typed this frame, after the keyboard layout; only while text entry is on (setTextEntry).
- `isTextEntry`: Whether typed text is being taken (setTextEntry); off at start.
- `setTextEntry`: Takes typed text or stops: on, getText carries the characters typed, and a platform with a soft keyboard shows it for them; off, keys are only keys and the keyboard stays down. The UI turns it on while a text field has focus; a game reading getText itself turns it on while it types (a name entered, a chat line) and off after.
- `getTouches`: Fingers down, and those lifted this frame.
- `isTouchGesture`: Whether two fingers are down: the two down longest make the gesture.
- `getTouchGestureCenterX`: The point between the gesture's fingers now, in framebuffer pixels; 0 without a gesture.
- `getTouchGestureCenterY`: See getTouchGestureCenterX.
- `getTouchGesturePanX`: How far the point between the fingers moved, in framebuffer pixels: this frame, or since the last tick with perTick.
- `getTouchGesturePanY`: See getTouchGesturePanX.
- `getTouchGestureScale`: How much the fingers spread (over 1) or pinched (under 1), as a factor: this frame, or since the last tick with perTick; 1 without.
- `getTouchGestureRotation`: How far the line between the fingers turned, in radians, clockwise on screen positive: this frame, or since the last tick with perTick.
- `getPadCount`: Four slots, connected or not.
- `getPad`: null for an index out of range.
- `isActivated`: Whether the user has pressed a key, a mouse button or a finger yet (the browser's user activation, which lets audio start and fullscreen be asked for; the same rule everywhere, so a game's flow is one flow): a title screen's "press any key". A pad's press doesn't count, as a browser can't unlock with one, so a game on a pad alone asks for a tap or key once. Stays true. An autopilot's press counts, so a script gated on it presses before it waits.
- `isAnyFramePressed`: Whether a key, a mouse button or a finger went down this frame, whichever: a "press any key" screen's press. A pad's doesn't count, as isActivated's doesn't.
- `isPadDown`: Any connected pad.
- `isPadPressed`: A connected pad's button went down: a counted tick edge, as a key's.
- `getPadAxis`: The first connected pad's axis, past the dead zone as Gamepad.getAxis gives it.
- `consume`: Call after each simulation tick: takes one of each counted tick edge and clears the pads' tick edges.

## InputRouter

*class* in `src/helix/input/InputRouter.hx`

Makes the input an app reads (an InputState) from a platform's events, the same on every platform: - the primary pointer is the mouse with its left button, or the first finger down; a second finger lets it go, off the window, so a pinch never drops or clicks anything, and the pointer stays let go until every finger lifts; - losing focus lets go of everything, and while unfocused presses, text, the wheel and pads are ignored (releases and moves still count); - text is ignored while Control or Super is held (a shortcut, not typing); Alt isn't, because AltGr and macOS's Option type characters; - the first four connected gamepads fill the four slots in the platform's order, and the rest of the slots are empty.

```haxe
function new()
function getInput():IInput
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
- `getInput`: The input the app reads.
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
function getPointerX():Float
function getPointerY():Float
function isPointerDown():Bool
function isPointerPressed():Bool
function isPointerReleased():Bool
function isPointerFramePressed():Bool
function isPointerFrameReleased():Bool
function getWheelX():Float
function getWheelY():Float
function getText():String
function isTextEntry():Bool
function setTextEntry(on:Bool):Void
function getTouches():Array<Touch>
function getPadCount():Int
function getPad(index:Int):Null<Gamepad>
function isMouseDown(button:MouseButton):Bool
function isMousePressed(button:MouseButton):Bool
function isMouseFramePressed(button:MouseButton):Bool
function isMouseReleased(button:MouseButton):Bool
function isMouseFrameReleased(button:MouseButton):Bool
function isPadDown(button:PadButton):Bool
function isPadPressed(button:PadButton):Bool
function getPadAxis(axis:PadAxis):Float
function isActivated():Bool
function isAnyFramePressed():Bool
function keyEvent(key:Key, value:Bool):Void
function padEvent(button:PadButton, value:Bool):Void
function axisEvent(axis:PadAxis, value:Float):Void
function mouseEvent(button:MouseButton, value:Bool):Void
function pointerEvent(x:Float, y:Float, value:Bool):Void
function textEvent(value:String):Void
function wheelEvent(x:Float, y:Float):Void
function touchEvent(id:Int, x:Float, y:Float, value:Bool):Void
function isTouchGesture():Bool
function getTouchGestureCenterX():Float
function getTouchGestureCenterY():Float
function getTouchGesturePanX(?perTick:Bool = false):Float
function getTouchGesturePanY(?perTick:Bool = false):Float
function getTouchGestureScale(?perTick:Bool = false):Float
function getTouchGestureRotation(?perTick:Bool = false):Float
function clear():Void
function consume():Void
function endFrame():Void
```

- `new`: Nothing down, nothing pressed, no pad connected, not activated.
- `keyEvent`: A key down (true) or up (false); only a change of state counts an edge, so key repeat doesn't. A down activates (isActivated).
- `padEvent`: Pad 0's button or axis, connecting it: for replay and tests.
- `axisEvent`: Pad 0's axis, connecting it: for replay and tests.
- `mouseEvent`: A mouse button down (true) or up (false); only a change of state counts an edge.
- `pointerEvent`: The primary pointer at x, y in framebuffer pixels (-1, -1 off the window), down or up; only a change of down counts an edge.
- `textEvent`: Typed characters, appended to this frame's text while text entry is on; dropped while it's off.
- `wheelEvent`: Wheel notches, added to this frame's; up and right are positive.
- `touchEvent`: A finger down, moved or lifted. A lifted one stays in touches, not down, until the frame ends.
- `clear`: Lets go of everything held, as when focus is lost: the releases are edges; presses not yet consumed, typed text and the wheel are dropped.
- `endFrame`: Ends the frame's edges, text, wheel and lifted touches; the InputRouter calls it after each frame.

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

Taps, drags and flicks from IInput's pointer, in framebuffer pixels; touch and mouse alike. Update once per tick, before the input is consumed.

```haxe
function new(?slop:Float = 12., ?tapSeconds:Float = .3)
function getMaxTapDistance():Float
function setMaxTapDistance(value:Float):Bool
function getMaxTapDuration():Float
function setMaxTapDuration(value:Float):Bool
function isDown():Bool
function isPressed():Bool
function isReleased():Bool
function isDragging():Bool
function isTapped():Bool
function getX():Float
function getY():Float
function getStartX():Float
function getStartY():Float
function getFlickVelocityX():Float
function getFlickVelocityY():Float
function update(input:IInput, now:Float):Void
```

- `new`: Gestures with a tap's limits: slop in framebuffer pixels, tapSeconds in seconds. Throws for a slop under 0 or tapSeconds of 0 or less, as the setters refuse.
- `getMaxTapDistance`: How far a press may move and still be a tap, in pixels.
- `setMaxTapDistance`: False for under 0.
- `getMaxTapDuration`: How long a press may last and still be a tap, in seconds.
- `setMaxTapDuration`: False for 0 or less.
- `isDown`: Whether the pointer is down, as of the last update.
- `isPressed`: The pointer went down at the last update.
- `isReleased`: The pointer came up at the last update.
- `isDragging`: Moved past the slop during this press.
- `isTapped`: The press that ended at the last update was a tap: it stayed within the slop and the tap time.
- `getX`: The pointer's x in framebuffer pixels, as of the last update while down; it holds while the pointer is off the window, and after release.
- `getY`: The pointer's y in framebuffer pixels, held as getX is.
- `getStartX`: Where the current or last press began, x in framebuffer pixels.
- `getStartY`: Where the current or last press began, y in framebuffer pixels.
- `getFlickVelocityX`: Velocity over the last tenth of a second before release, pixels per second.
- `getFlickVelocityY`: Vertical velocity as getFlickVelocityX, down positive.
- `update`: Reads the pointer once per tick, before the input is consumed; now is the time in seconds.

## Touch

*typedef* in `src/helix/input/Touch.hx`

A finger, in framebuffer pixels like the pointer. Its id stays the same while it is down.

- `y:Float`
- `x:Float`
- `released:Bool`
- `pressed:Bool`
- `id:Int`
- `down:Bool`
