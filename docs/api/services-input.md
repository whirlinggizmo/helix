# helix.services.input

[Back to the index](README.md)

## Actions

*class* in [`services/src/helix/services/input/Actions.hx`](../../services/src/helix/services/input/Actions.hx), `import helix.services.input.Actions;`

Provides actions, which are names the game reads, such as "jump" or "left", each bound to keys, mouse buttons and gamepads.

Any of an action's bindings works it. Actions reads the `Input` it was created over, so it is current once that `Input` is polled. It has no `poll` of its own. A name with no bindings reads as not held, with a value of 0.

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
function unbindAll():Void
function getBindings(name:String):Array<Binding>
function isDown(name:String):Bool
function isPressed(name:String):Bool
function isReleased(name:String):Bool
function getValue(name:String):Float
function getAxis(negative:String, positive:String):Float
function computeVector(left:String, right:String, up:String, down:String, ?out:Point2D):Point2D
```

- `new`: Creates actions with nothing bound.
  - `input`: The input state the actions read.
- `bind`: Binds a name to keys, buttons or sticks, in addition to its existing bindings.
  - `name`: The action's name.
  - `bindings`: One or more bindings that work the action.
  - returns: False when the name was already bound to every one of them. Any new ones are bound either way.

  An existing array is passed as `...bindings`.
- `unbind`: Removes bindings from a name.
  - `name`: The action's name.
  - `bindings`: One or more bindings that no longer work the action.
  - returns: False when the name was bound to none of them. Any it was bound to are removed either way.

  `unbind(name, ...getBindings(name))` removes every binding of one name.
- `unbindAll`: Removes every binding from every name, as before anything was bound.
- `getBindings`: Returns a name's bindings.
  - `name`: The action's name.
  - returns: A copy of its bindings, in the order they were bound, or an empty array for a name with no bindings.
- `isDown`: Returns whether an action is held, which is when any of its bindings is held.
  - `name`: The action's name.
  - returns: True while any of its bindings is held.
- `isPressed`: Returns whether an action began this frame, which is when one of its bindings went down while none was held before.
  - `name`: The action's name.
  - returns: True for that frame alone, once per press.
- `isReleased`: Returns whether an action ended this frame, which is when its last held binding went up.
  - `name`: The action's name.
  - returns: True for that frame alone.
- `getValue`: Returns how far an action is worked.
  - `name`: The action's name.
  - returns: The largest value among its bindings, 0 to 1.

  A held key or button is 1. A stick or trigger is its distance past the dead zone.
- `getAxis`: Returns one axis made of two actions, such as "left" and "right".
  - `negative`: The action toward -1.
  - `positive`: The action toward 1.
  - returns: The positive action's value less the negative's, -1 to 1.

  Two axes read this way make a diagonal longer than either axis. For movement in two directions, use `computeVector`.
- `computeVector`: Returns a direction made of four actions, with its length clamped to at most 1.
  - `left`: The action toward -x.
  - `right`: The action toward +x.
  - `up`: The action toward -y.
  - `down`: The action toward +y.
  - `out`: Optional. The point to fill. A new point is created when omitted.
  - returns: The direction. Its x is `getAxis(left, right)` and its y is `getAxis(up, down)`, scaled down when longer than 1.

  A diagonal is no faster than a straight line, and a stick pushed partway stays partway.

## AxisDirection

*enum* in [`services/src/helix/services/input/AxisDirection.hx`](../../services/src/helix/services/input/AxisDirection.hx), `import helix.services.input.AxisDirection;`

Specifies which side of a stick's axis a binding reads (`Binding.Axis`). A trigger reads as `Positive`.

- `Negative`: Left on an X axis, up on a Y axis.
- `Positive`: Right on an X axis, down on a Y axis, or a trigger pulled.

## Binding

*enum* in [`services/src/helix/services/input/Binding.hx`](../../services/src/helix/services/input/Binding.hx), `import helix.services.input.Binding;`

Specifies what an action is bound to (`Actions.bind`).

- `Keyboard(key:Key)`: A key.
- `Mouse(button:MouseButton)`: A mouse button.
- `Pad(slot:Int, button:PadButton)`: A gamepad's button, by the gamepad's slot, 0 to 3.
- `Axis(slot:Int, axis:PadAxis, direction:AxisDirection)`: One side of a gamepad's stick axis or trigger, by the gamepad's slot, 0 to 3.
  The binding is down while the axis is past the dead zone on that side, and its value is how far past.

## Input

*class* in [`services/src/helix/services/input/Input.hx`](../../services/src/helix/services/input/Input.hx), `import helix.services.input.Input;`, implements `IPollable`

Provides the keyboard, the mouse and the gamepads as state: what is held, and what went down or up this frame.

The program constructs one over its `IEvents` and calls `poll` once a frame. The state then holds until the next poll. `poll` reads the events the last `IEvents.poll` delivered, so the two may be polled in either order. When `Input` is polled first, it is a frame behind.

"Pressed" is true for the frame a key or button went down, once per press however long it is held. For named actions bound to several of these, use `Actions`.

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
- `poll`: Reads the events the last `IEvents.poll` delivered, updating what went down or up, the mouse's position and the wheel.
  Call it once a frame. When the window loses focus, every held key and mouse button is released.
- `isKeyDown`: Returns whether a key is held.
  - `key`: The key.
  - returns: True from the frame it went down until the frame it went up.
- `isKeyPressed`: Returns whether a key went down this frame.
  - `key`: The key.
  - returns: True for that frame alone. A key the OS repeats while it is held isn't pressed again.
- `isKeyReleased`: Returns whether a key went up this frame.
  - `key`: The key.
  - returns: True for that frame alone.
- `mouseX`: Gets the mouse's distance from the window's left edge, in framebuffer pixels, where it was last over the window.
- `mouseY`: Gets the mouse's distance from the window's top edge, in framebuffer pixels, where it was last over the window.
- `wheelX`: Gets the wheel's horizontal turn this frame, in notches, positive to the right.
- `wheelY`: Gets the wheel's vertical turn this frame, in notches, positive away from the player.
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
  - returns: The axis's value, or 0 for an empty slot or one outside 0 to 3.

  A stick's axis is -1 to 1, with right and down positive. A trigger is 0 to 1. Inside `padDeadZone` the value is 0, and beyond it the value is scaled so it still reaches 1. A stick's dead zone is a circle, so a diagonal push isn't cut off where one axis alone would be.
- `padDeadZone`: Gets or sets how far a stick or trigger moves before it counts, 0 to 1. Clamped to that range. Defaults to 0.2.
  The default is large enough that a worn stick resting off center stays inside it. A dead zone past 0.95 acts as 0.95, so the stick keeps some travel.
