# helix.services.input

[Back to the index](README.md)

## Actions

*class* in [`services/src/helix/services/input/Actions.hx`](../../services/src/helix/services/input/Actions.hx), `import helix.services.input.Actions;`

Provides actions, which are names the game reads, such as "jump" or "left", each bound to keys, mouse buttons, gamepads and tilt.

Any of an action's bindings works it. Actions reads the devices it was created over, so it is current once they are polled. It has no `poll` of its own. A binding to a device it wasn't given, or a name with no bindings, reads as not held, with a value of 0.

```haxe
var keyboard = new Keyboard(events), pads = new Gamepads(events);
var actions = new Actions([keyboard, pads]);
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
function new(devices:Array<IActionDevice>)
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

- `new`: Creates actions with nothing bound, over the devices the game made.
  - `devices`: The devices its bindings are read from: any of `Keyboard`, `Mouse`, `Gamepads` and `Tilt`.
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
- `Tilt(axis:TiltAxis, direction:AxisDirection)`: One side of the device's tilt (`Tilt.getAxis`): down while it's tilted that way, its value how far.

## Gamepads

*class* in [`services/src/helix/services/input/Gamepads.hx`](../../services/src/helix/services/input/Gamepads.hx), `import helix.services.input.Gamepads;`, implements `IActionDevice`, `IPollable`

Provides the gamepads as state, in slots 0 to 3: which buttons are held or went down or up this frame, and where each stick and trigger is, past a dead zone.

The program constructs one over its `IEvents` and calls `poll` once a frame, as `Keyboard` is. A pad's axes are read once a poll, so they hold still for the frame. A pad that disconnects lets go of its buttons.

```haxe
var pads = new Gamepads(events);
// each frame:
pads.poll();
if (pads.isButtonPressed(0, South)) jump();
var x = pads.getAxis(0, LeftX);
```

```haxe
function new(events:IEvents)
function poll():Void
function isConnected(slot:Int):Bool
function getName(slot:Int):String
function isButtonDown(slot:Int, button:PadButton):Bool
function isButtonPressed(slot:Int, button:PadButton):Bool
function isButtonReleased(slot:Int, button:PadButton):Bool
function getAxis(slot:Int, axis:PadAxis):Float
var deadZone(default, set):Float
```

- `new`: Creates the gamepads over the platform's events, with nothing held.
  - `events`: The platform's events, whose last `poll` this one reads.
- `poll`: Reads the events the last `IEvents.poll` delivered, and every pad's axes. Call it once a frame.
- `isConnected`: Returns whether a gamepad is in a slot.
  - `slot`: The slot, 0 to 3.
  - returns: True when one is connected there.
- `getName`: Returns a gamepad's name, as its maker gives it.
  - `slot`: The slot, 0 to 3.
  - returns: The name, or "" for an empty slot.
- `isButtonDown`: Returns whether a button is held.
  - `slot`: The gamepad's slot, 0 to 3.
  - `button`: The button.
  - returns: True from the frame it went down until the frame it went up. False for an empty slot.
- `isButtonPressed`: Returns whether a button went down this frame.
  - `slot`: The gamepad's slot, 0 to 3.
  - `button`: The button.
  - returns: True for that frame alone.
- `isButtonReleased`: Returns whether a button went up this frame.
  - `slot`: The gamepad's slot, 0 to 3.
  - `button`: The button.
  - returns: True for that frame alone.
- `getAxis`: Returns where a stick's axis or a trigger is, past the dead zone.
  - `slot`: The gamepad's slot, 0 to 3.
  - `axis`: The stick's axis or the trigger.
  - returns: A stick's axis -1 to 1, right and down positive; a trigger 0 to 1. 0 inside `deadZone`, and beyond it scaled so it still reaches 1. 0 for an empty slot or one past 3.

  A stick's dead zone is a circle, so a diagonal push isn't cut off where one axis alone would be.
- `deadZone`: Gets or sets how far a stick or trigger moves before it counts, 0 to 1. Clamped to that range. Defaults to 0.2.
  The default is large enough that a worn stick resting off center stays inside it. A dead zone past 0.95 acts as 0.95, so the stick keeps some travel.

## IActionDevice

*interface* in [`services/src/helix/services/input/IActionDevice.hx`](../../services/src/helix/services/input/IActionDevice.hx), `import helix.services.input.IActionDevice;`

Defines a device `Actions` reads its bindings from: `Keyboard`, `Mouse`, `Gamepads` and `Tilt` each read their own kind of binding.

A game passes its devices to `Actions` and never calls these itself.

## Keyboard

*class* in [`services/src/helix/services/input/Keyboard.hx`](../../services/src/helix/services/input/Keyboard.hx), `import helix.services.input.Keyboard;`, implements `IActionDevice`, `IPollable`

Provides the keyboard as state: what is held, and what went down or up this frame.

The program constructs one over its `IEvents` and calls `poll` once a frame. The state then holds until the next poll. `poll` reads the events the last `IEvents.poll` delivered, so the two may be polled in either order. When the keyboard is polled first, it is a frame behind. "Pressed" is true for the frame a key went down, once per press however long it is held.

```haxe
var keyboard = new Keyboard(events);
// each frame:
keyboard.poll();
if (keyboard.isKeyPressed(Space)) jump();
```

```haxe
function new(events:IEvents)
function poll():Void
function isKeyDown(key:Key):Bool
function isKeyPressed(key:Key):Bool
function isKeyReleased(key:Key):Bool
```

- `new`: Creates the keyboard over the platform's events, with nothing held.
  - `events`: The platform's events, whose last `poll` this one reads.
- `poll`: Reads the events the last `IEvents.poll` delivered. Call it once a frame. When the window loses focus, every held key is released.
- `isKeyDown`: Returns whether a key is held.
  - `key`: The key.
  - returns: True from the frame it went down until the frame it went up.
- `isKeyPressed`: Returns whether a key went down this frame.
  - `key`: The key.
  - returns: True for that frame alone. A key the OS repeats while it is held isn't pressed again.
- `isKeyReleased`: Returns whether a key went up this frame.
  - `key`: The key.
  - returns: True for that frame alone.

## Mouse

*class* in [`services/src/helix/services/input/Mouse.hx`](../../services/src/helix/services/input/Mouse.hx), `import helix.services.input.Mouse;`, implements `IActionDevice`, `IPollable`

Provides the mouse as state: where it is, its wheel, and which buttons are held or went down or up this frame.

The program constructs one over its `IEvents` and calls `poll` once a frame, as `Keyboard` is. "Pressed" is true for the frame a button went down.

```haxe
var mouse = new Mouse(events);
// each frame:
mouse.poll();
if (mouse.isButtonPressed(Left)) fire(mouse.x, mouse.y);
```

```haxe
function new(events:IEvents)
var x(default, null):Float
var y(default, null):Float
var wheelX(default, null):Float
var wheelY(default, null):Float
function poll():Void
function isButtonDown(button:MouseButton):Bool
function isButtonPressed(button:MouseButton):Bool
function isButtonReleased(button:MouseButton):Bool
```

- `new`: Creates the mouse over the platform's events, with nothing held.
  - `events`: The platform's events, whose last `poll` this one reads.
- `x`: Gets the mouse's distance from the window's left edge, in framebuffer pixels, where it last was over the window.
- `y`: Gets the mouse's distance from the window's top edge, in framebuffer pixels, where it last was over the window.
- `wheelX`: Gets how far the wheel turned this frame, in notches, right positive.
- `wheelY`: Gets how far the wheel turned this frame, in notches, away from the player positive.
- `poll`: Reads the events the last `IEvents.poll` delivered. Call it once a frame. When the window loses focus, every held button is released.
- `isButtonDown`: Returns whether a button is held.
  - `button`: The button.
  - returns: True from the frame it went down until the frame it went up.
- `isButtonPressed`: Returns whether a button went down this frame.
  - `button`: The button.
  - returns: True for that frame alone.
- `isButtonReleased`: Returns whether a button went up this frame.
  - `button`: The button.
  - returns: True for that frame alone.

## Tilt

*class* in [`services/src/helix/services/input/Tilt.hx`](../../services/src/helix/services/input/Tilt.hx), `import helix.services.input.Tilt;`, implements `IActionDevice`, `IPollable`

Provides the device's tilt, from level and turned with the screen, for a game steered by tilting a phone or a tablet.

The program constructs one over its `IEvents`, calls `requestAccess`, and calls `poll` once a frame, as `Keyboard` is. A page may need the player's permission, asked at the player's next tap, so a game asks before the tap that starts play. Level is taken once the device is held steady, and the tilt reads 0 until then (`calibrating`). Natively there is no tilt.

```haxe
var tilt = new Tilt(events);
tilt.requestAccess(() -> trace("tilt on"), why -> trace(why));
// each frame:
tilt.poll();
x += speed * tilt.getAxis(X) * time.delta;
```

```haxe
function new(events:IEvents)
function requestAccess(?done:() -> Void, ?failed:String -> Void):Bool
function releaseAccess():Void
var status(default, null):TiltStatus
var calibrating(default, null):Bool
function calibrate():Void
function getAxis(axis:TiltAxis):Float
var range(default, set):Float
function poll():Void
```

- `new`: Creates the tilt over the platform's events, off until `requestAccess`.
  - `events`: The platform's events, whose last `poll` this one reads.
- `requestAccess`: Asks for the device's motion sensor, as `IEvents.requestTiltAccess` does.
  - `done`: Optional. Called once readings arrive.
  - `failed`: Optional. Receives why there will be none: the player refused, the page isn't secure, or the browser reads no orientation.
  - returns: False, calling neither, where the tilt can't be read at all: natively.

  A page may need the player's permission, which is asked at the player's next tap. `status` follows each change, for a game that shows "tap to start tilt" while it waits.
- `releaseAccess`: Stops the readings, and reads 0 from then. A permission the player granted stays granted, so a later `requestAccess` usually starts without asking again.
- `status`: Gets where the tilt is: Off, WaitingForTap, On, Refused, Unavailable or NeedsHttps. Defaults to Off.
- `calibrating`: Gets a value indicating whether level is being taken.
  Level is taken once the device is held within 3 degrees for half a second: when the tilt starts, after the screen turns, and after `calibrate`. The tilt reads 0 meanwhile.
- `calibrate`: Takes level again from how the device is held next, as a game's "Level" button does.
- `getAxis`: Returns how far the device is tilted from level along an axis, turned with the screen.
  - `axis`: The axis: X across the screen, right positive; Y along it, toward the player positive.
  - returns: -1 to 1, where `range` degrees reads 1; 0 while level is being taken, or when the tilt isn't on.
- `range`: Gets or sets how many degrees of tilt read 1. Clamped to at least 1. Defaults to 30.
- `poll`: Reads the events the last `IEvents.poll` delivered: the tilt's status and its readings. Call it once a frame.

## TiltAxis

*enum* in [`services/src/helix/services/input/TiltAxis.hx`](../../services/src/helix/services/input/TiltAxis.hx), `import helix.services.input.TiltAxis;`

Specifies an axis of the device's tilt, turned with the screen (`Tilt.getAxis`).

- `X`: Across the screen, right positive.
- `Y`: Along the screen, toward the player positive.
