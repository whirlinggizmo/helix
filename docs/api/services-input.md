# helix.services.input

[Back to the index](README.md)

## Actions

*class* in [`services/src/helix/services/input/Actions.hx`](../../services/src/helix/services/input/Actions.hx), `import helix.services.input.Actions;`

Provides actions: names the game reads ("jump", "left"), each bound to keys, mouse buttons and gamepads, any of which works it.

It reads the `Input` it was made over, so it is current once that is polled; it has no `poll` of its own. A name nothing is bound to reads as not held and 0.

```haxe
actions.bind("jump", Keyboard(Space), Pad(0, South));
actions.bind("left", Keyboard(Left), Keyboard(A), Axis(0, LeftX, Negative));
actions.bind("right", Keyboard(Right), Keyboard(D), Axis(0, LeftX, Positive));
actions.bind("up", Keyboard(Up), Keyboard(W), Axis(0, LeftY, Negative));
actions.bind("down", Keyboard(Down), Keyboard(S), Axis(0, LeftY, Positive));
var move = new Point2D();
// each frame:
if (actions.isPressed("jump")) jump();
actions.computeVector("left", "right", "up", "down", move);
x += speed * move.x * time.delta;
y += speed * move.y * time.delta;
```

```haxe
function new(input:Input)
function bind(name:String, ...bindings:Binding):Bool
function unbind(name:String, ...bindings:Binding):Bool
function clearBindings():Void
function getBindings(name:String):Array<Binding>
function isDown(name:String):Bool
function isPressed(name:String):Bool
function isReleased(name:String):Bool
function getValue(name:String):Float
function getAxis(negative:String, positive:String):Float
function computeVector(left:String, right:String, up:String, down:String, ?out:Point2D):Point2D
```

- `new`: Creates actions with nothing bound.
  - `input`: The state the actions read.
- `bind`: Binds a name to keys, buttons or sticks, beside what it's already bound to.
  - `name`: The action's name.
  - `bindings`: What works it, one or more.
  - returns: False when it was already bound to every one of them; any it wasn't are bound either way.

  An array already made is passed as `...bindings`.
- `unbind`: Takes bindings off a name.
  - `name`: The action's name.
  - `bindings`: What no longer works it, one or more.
  - returns: False when it was bound to none of them; any it was are taken off either way.

  Every binding of one name comes off as `unbind(name, ...getBindings(name))`.
- `clearBindings`: Takes every binding off every name, as before anything was bound.
- `getBindings`: Returns what a name is bound to.
  - `name`: The action's name.
  - returns: A copy of its bindings, in the order they were bound; empty for a name nothing is bound to.
- `isDown`: Returns whether an action is held: any of its bindings is.
  - `name`: The action's name.
  - returns: True while any is held.
- `isPressed`: Returns whether an action began this frame: one of its bindings went down while none was held.
  - `name`: The action's name.
  - returns: True for that frame alone, once per press.
- `isReleased`: Returns whether an action ended this frame: its last held binding went up.
  - `name`: The action's name.
  - returns: True for that frame alone.
- `getValue`: Returns how far an action is worked: a key or button held is 1, a stick its distance past the dead zone.
  - `name`: The action's name.
  - returns: The most of its bindings, 0 to 1.
- `getAxis`: Returns one axis made of two actions, such as "left" and "right".
  - `negative`: The action toward -1.
  - `positive`: The action toward 1.
  - returns: The positive action's value less the negative's, -1 to 1.

  Two axes read this way make a diagonal longer than either: for movement in two directions, `computeVector`.
- `computeVector`: Returns a direction made of four actions, its length held to at most 1, so a diagonal is no faster than a straight line and a stick pushed partway stays partway.
  - `left`: The action toward -x.
  - `right`: The action toward +x.
  - `up`: The action toward -y.
  - `down`: The action toward +y.
  - `out`: Optional. The point to fill; a new one when left out.
  - returns: The direction: x is `getAxis(left, right)` and y `getAxis(up, down)`, scaled down when longer than 1.

## AxisDirection

*enum* in [`services/src/helix/services/input/AxisDirection.hx`](../../services/src/helix/services/input/AxisDirection.hx), `import helix.services.input.AxisDirection;`

Specifies which side of a stick's axis a binding reads (`Binding.Axis`); a trigger's is Positive.

- `Negative`: Left on an X axis, up on a Y axis.
- `Positive`: Right on an X axis, down on a Y axis, and a trigger pulled.

## Binding

*enum* in [`services/src/helix/services/input/Binding.hx`](../../services/src/helix/services/input/Binding.hx), `import helix.services.input.Binding;`

Specifies what an action is bound to (`Actions.bind`).

- `Keyboard(key:Key)`: A key.
- `Mouse(button:MouseButton)`: A mouse button.
- `Pad(slot:Int, button:PadButton)`: A gamepad's button, in a slot, 0 to 3.
- `Axis(slot:Int, axis:PadAxis, direction:AxisDirection)`: One side of a gamepad's stick axis or trigger, in a slot, 0 to 3: down while it's past the dead zone that way, its value how far.

## Input

*class* in [`services/src/helix/services/input/Input.hx`](../../services/src/helix/services/input/Input.hx), `import helix.services.input.Input;`, implements `IPollable`

Provides the keyboard, the mouse and the gamepads as state: what is held, and what went down or up this frame.

The program constructs one over its `IEvents` and calls `poll` once a frame; the state then holds until the next poll. It reads the events the last `IEvents.poll` delivered, so the two may be polled in either order: polled before them, it is a frame behind. "Pressed" is true for the frame a key or button went down, once per press however long it's held. Named actions bound to several of these are `Actions`.

```haxe
events.poll();
input.poll();
if (input.isKeyPressed(Space)) jump();
var x = input.getPadAxis(0, LeftX);
```

```haxe
function new(events:IEvents)
function poll():Void
function isKeyDown(key:Key):Bool
function isKeyPressed(key:Key):Bool
function isKeyReleased(key:Key):Bool
var mouseX(default, null):Float
var mouseY(default, null):Float
var wheelX(default, null):Float
var wheelY(default, null):Float
function isMouseDown(button:MouseButton):Bool
function isMousePressed(button:MouseButton):Bool
function isMouseReleased(button:MouseButton):Bool
function isPadButtonDown(slot:Int, button:PadButton):Bool
function isPadButtonPressed(slot:Int, button:PadButton):Bool
function isPadButtonReleased(slot:Int, button:PadButton):Bool
function getPadAxis(slot:Int, axis:PadAxis):Float
var padDeadZone(default, set):Float
```

- `new`: Creates the state over the platform's events, with nothing held.
  - `events`: The platform's events, whose last `poll` this one reads.
- `poll`: Reads the events the last `IEvents.poll` delivered: what went down or up, where the mouse is and the wheel; call once a frame.
- `isKeyDown`: Returns whether a key is held.
  - `key`: The key.
  - returns: True from the frame it went down until the frame it went up.
- `isKeyPressed`: Returns whether a key went down this frame.
  - `key`: The key.
  - returns: True for that frame alone; a key the OS repeats while it's held isn't pressed again.
- `isKeyReleased`: Returns whether a key went up this frame.
  - `key`: The key.
  - returns: True for that frame alone.
- `mouseX`: Gets the mouse's distance from the window's left edge, in framebuffer pixels, where it last was over the window.
- `mouseY`: Gets the mouse's distance from the window's top edge, in framebuffer pixels, where it last was over the window.
- `wheelX`: Gets the wheel's turn this frame, in notches: right positive.
- `wheelY`: Gets the wheel's turn this frame, in notches: away from the player positive.
- `isMouseDown`: Returns whether a mouse button is held.
  - `button`: The button.
  - returns: True from the frame it went down until the frame it went up.
- `isMousePressed`: Returns whether a mouse button went down this frame.
  - `button`: The button.
  - returns: True for that frame alone.
- `isMouseReleased`: Returns whether a mouse button went up this frame.
  - `button`: The button.
  - returns: True for that frame alone.
- `isPadButtonDown`: Returns whether a gamepad's button is held.
  - `slot`: The gamepad's slot, 0 to 3.
  - `button`: The button.
  - returns: True from the frame it went down until the frame it went up; false for an empty slot.
- `isPadButtonPressed`: Returns whether a gamepad's button went down this frame.
  - `slot`: The gamepad's slot, 0 to 3.
  - `button`: The button.
  - returns: True for that frame alone.
- `isPadButtonReleased`: Returns whether a gamepad's button went up this frame.
  - `slot`: The gamepad's slot, 0 to 3.
  - `button`: The button.
  - returns: True for that frame alone.
- `getPadAxis`: Returns where a gamepad's stick or trigger is, past the dead zone.
  - `slot`: The gamepad's slot, 0 to 3.
  - `axis`: The stick's axis or the trigger.
  - returns: A stick's axis -1 to 1 (right and down positive), a trigger 0 to 1; 0 inside `padDeadZone`, and the rest scaled so it still reaches 1; 0 for an empty slot.
- `padDeadZone`: Gets or sets how far a stick or trigger moves before it counts, 0 to 1; 0.2 by default, which a worn stick resting off center stays inside.
