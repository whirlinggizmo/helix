# helix.services.input

[Back to the library](README.md)

## Actions

*class* in [`libs/services/src/helix/services/input/Actions.hx`](../src/helix/services/input/Actions.hx), `import helix.services.input.Actions;`

Provides actions, which are names the game reads, such as "jump" or "left", each bound to keys, mouse buttons, gamepads and tilt.

Any of an action's bindings works it. Actions reads the devices it was created over, so it is current once they are polled. It has no `poll` of its own. A binding to a device it wasn't given, or a name with no bindings, reads as not held, with a value of 0.

```haxe
var keyboard = new Keyboard(events, keyboardAdapter), gamepads = new Gamepads(events, gamepadsAdapter);
var actions = new Actions([keyboard, gamepads]);
actions.bind("jump", Keyboard(Space), Gamepad(0, South));
actions.bind("left", Keyboard(Left), Keyboard(A), Axis(0, LeftX, Negative));
actions.bind("right", Keyboard(Right), Keyboard(D), Axis(0, LeftX, Positive));
actions.bind("up", Keyboard(Up), Keyboard(W), Axis(0, LeftY, Negative));
actions.bind("down", Keyboard(Down), Keyboard(S), Axis(0, LeftY, Positive));
var move = new Vector2D();
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
function computeVector(left:String, right:String, up:String, down:String, ?out:Vector2D):Vector2D
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
  - `out`: Optional. The vector to fill. A new vector is created when omitted.
  - returns: The direction. Its x is `getAxis(left, right)` and its y is `getAxis(up, down)`, scaled down when longer than 1.

  A diagonal is no faster than a straight line, and a stick pushed partway stays partway.

## AxisDirection

*enum* in [`libs/services/src/helix/services/input/AxisDirection.hx`](../src/helix/services/input/AxisDirection.hx), `import helix.services.input.AxisDirection;`

Specifies which side of a stick's axis a binding reads (`Binding.Axis`). A trigger reads as `Positive`.

- `Negative`: Left on an X axis, up on a Y axis.
- `Positive`: Right on an X axis, down on a Y axis, or a trigger pulled.

## Binding

*enum* in [`libs/services/src/helix/services/input/Binding.hx`](../src/helix/services/input/Binding.hx), `import helix.services.input.Binding;`

Specifies what an action is bound to (`Actions.bind`).

- `Keyboard(key:Key)`: A key.
- `Mouse(button:MouseButton)`: A mouse button.
- `Gamepad(slot:Int, button:GamepadButton)`: A gamepad's button, by the gamepad's slot, 0 to 3.
- `Axis(slot:Int, axis:GamepadAxis, direction:AxisDirection)`: One side of a gamepad's stick axis or trigger, by the gamepad's slot, 0 to 3.
  The binding is down while the axis is past the dead zone on that side, and its value is how far past.
- `Tilt(axis:TiltAxis, direction:AxisDirection)`: One side of the device's tilt (`Tilt.getAxis`): down while it's tilted that way, its value how far.

## Gamepads

*class* in [`libs/services/src/helix/services/input/Gamepads.hx`](../src/helix/services/input/Gamepads.hx), `import helix.services.input.Gamepads;`, implements `IActionDevice`, `IPollable`

Provides the gamepads as state, in slots 0 to 3: which buttons are held or went down or up this frame, and where each stick and trigger is, past a dead zone.

The program constructs one over its `IEvents` and its `IGamepads`, and calls `poll` once a frame, as `Keyboard` is. A gamepad's axes are read once a poll, so they hold still for the frame. A gamepad that disconnects lets go of its buttons.

```haxe
var gamepads = new Gamepads(events, gamepadsAdapter);
// each frame:
gamepads.poll();
if (gamepads.isButtonPressed(0, South)) jump();
var x = gamepads.getAxis(0, LeftX);
```

```haxe
function new(events:IEvents, gamepads:IGamepads)
function poll():Void
function isConnected(slot:Int):Bool
function getName(slot:Int):String
function isButtonDown(slot:Int, button:GamepadButton):Bool
function isButtonPressed(slot:Int, button:GamepadButton):Bool
function isButtonReleased(slot:Int, button:GamepadButton):Bool
function getAxis(slot:Int, axis:GamepadAxis):Float
var deadZone(default, set):Float
```

- `new`: Creates the gamepads over the platform's events and gamepads, with nothing held.
  - `events`: The platform's events, whose last `poll` this one reads.
  - `gamepads`: The platform's gamepads, whose buttons those events carry and whose sticks and triggers are read.
- `poll`: Reads the events the last `IEvents.poll` delivered, and every gamepad's axes. Call it once a frame.
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

## Gesture

*abstract* in [`libs/services/src/helix/services/input/Gesture.hx`](../src/helix/services/input/Gesture.hx), `import helix.services.input.Gesture;`

Specifies a gesture `Gestures` detects, as a flag: flags are or'd together to say which gestures are detected (`Gestures.enabled`).

- `Gesture.None`: No gesture.
- `Gesture.Tap`: A finger, or a mouse button, went down. It lasts a frame, then is a hold.
- `Gesture.DoubleTap`: A second tap soon after the first and near it. It lasts a frame, then is a hold.
- `Gesture.Hold`: A finger or button kept down.
- `Gesture.Drag`: A finger or button held a moment and then moved.
- `Gesture.SwipeRight`: A quick move to the right as the finger lifted. It lasts a frame.
- `Gesture.SwipeLeft`: A quick move to the left as the finger lifted. It lasts a frame.
- `Gesture.SwipeUp`: A quick move up as the finger lifted. It lasts a frame.
- `Gesture.SwipeDown`: A quick move down as the finger lifted. It lasts a frame.
- `Gesture.PinchIn`: Two fingers moving together.
- `Gesture.PinchOut`: Two fingers moving apart.
- `Gesture.All`: Every gesture.

## Gestures

*class* in [`libs/services/src/helix/services/input/Gestures.hx`](../src/helix/services/input/Gestures.hx), `import helix.services.input.Gestures;`, implements `IPollable`

Provides gestures from the mouse and the fingers on the screen: a tap, a double tap, a hold, a drag, a swipe each way and a pinch in or out, as raylib's gestures (rgestures.h) detect them, from the frame's events in the order they came. Every mouse button counts as one finger. Positions and distances are fractions of the window, 0 to 1 across it.

The program constructs one over its `IEvents`, `IWindow` and `ISystem`, and calls `poll` once a frame. The mouse's and touch's events arrive only while their adapters exist, so the program constructs those too.

```haxe
var gestures = new Gestures(events, window, system);
// each frame:
gestures.poll();
if (gestures.isDetected(Tap)) select();
```

```haxe
function new(events:IEvents, window:IWindow, system:ISystem)
var enabled:Gesture
var current(get, never):Gesture
function isDetected(gesture:Gesture):Bool
var holdDuration(get, never):Float
var dragX(default, null):Float
var dragY(default, null):Float
var dragAngle(default, null):Float
var pinchX(default, null):Float
var pinchY(default, null):Float
var pinchAngle(default, null):Float
function poll():Void
```

- `new`: Creates the gestures, none detected yet.
  - `events`: The platform's events, whose last `poll` this one reads.
  - `window`: The window, whose framebuffer's size positions are fractions of.
  - `system`: The system, whose clock times holds, double taps and swipes.
- `enabled`: Gets or sets the gestures detected, as flags or'd together. Defaults to `All`.
- `current`: Gets the gesture detected now, or `None`: one that isn't enabled isn't.
- `isDetected`: Returns whether a gesture is the one detected now.
  - `gesture`: The gesture.
  - returns: True while it is, and it is enabled.
- `holdDuration`: Gets how long the hold has lasted, in seconds: 0 when the gesture isn't a hold.
- `dragX`: Gets the drag across, from where the finger landed to where it is, in fractions of the window's width.
- `dragY`: Gets the drag down, in fractions of the window's height.
- `dragAngle`: Gets the last swipe's angle, in degrees counterclockwise from right.
- `pinchX`: Gets the pinch across, from the first finger to the second, in fractions of the window's width.
- `pinchY`: Gets the pinch down, in fractions of the window's height.
- `pinchAngle`: Gets the pinch's angle, in degrees counterclockwise from right.
- `poll`: Steps the gestures to the new frame, then reads the events the last `IEvents.poll` delivered. Call it once a frame.

## IActionDevice

*interface* in [`libs/services/src/helix/services/input/IActionDevice.hx`](../src/helix/services/input/IActionDevice.hx), `import helix.services.input.IActionDevice;`

Defines a device `Actions` reads its bindings from: `Keyboard`, `Mouse`, `Gamepads` and `Tilt` each read their own kind of binding.

A game passes its devices to `Actions` and never calls these itself.

## Keyboard

*class* in [`libs/services/src/helix/services/input/Keyboard.hx`](../src/helix/services/input/Keyboard.hx), `import helix.services.input.Keyboard;`, implements `IActionDevice`, `IPollable`

Provides the keyboard as state: what is held, what went down or up this frame, which keys the OS repeated, and the text typed.

The program constructs one over its `IEvents` and its `IKeyboard`, and calls `poll` once a frame. The state then holds until the next poll. `poll` reads the events the last `IEvents.poll` delivered, so the two may be polled in either order. When the keyboard is polled first, it is a frame behind. "Pressed" is true for the frame a key went down, once per press however long it is held.

```haxe
var keyboard = new Keyboard(events, keyboardAdapter);
// each frame:
keyboard.poll();
if (keyboard.isKeyPressed(Space)) jump();
```

```haxe
function new(events:IEvents, keyboard:IKeyboard)
final pressedKeys:Array<Key>
var text(default, null):String
var textInput(get, set):Bool
function poll():Void
function isKeyDown(key:Key):Bool
function isKeyPressed(key:Key):Bool
function isKeyReleased(key:Key):Bool
function isKeyRepeated(key:Key):Bool
```

- `new`: Creates the keyboard over the platform's events and keyboard, with nothing held.
  - `events`: The platform's events, whose last `poll` this one reads.
  - `keyboard`: The platform's keyboard, whose keys those events carry.
- `pressedKeys`: Gets the keys that went down this frame, in the order they did; a key the OS repeats isn't among them again. The array is reused by the next poll.
- `text`: Gets the text typed this frame, in the order it was, while `textInput` is on; "" otherwise.
- `textInput`: Gets or sets whether typed text arrives in `text`. A phone shows its keyboard while it is on. Defaults to false.
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
- `isKeyRepeated`: Returns whether the OS repeated a held key this frame, as it does after a moment, at its own rate.
  - `key`: The key.
  - returns: True for the frames it repeated.

## Mouse

*class* in [`libs/services/src/helix/services/input/Mouse.hx`](../src/helix/services/input/Mouse.hx), `import helix.services.input.Mouse;`, implements `IActionDevice`, `IPollable`

Provides the mouse as state: where it is, its wheel, and which buttons are held or went down or up this frame.

The program constructs one over its `IEvents` and its `IMouse`, and calls `poll` once a frame, as `Keyboard` is. "Pressed" is true for the frame a button went down.

```haxe
var mouse = new Mouse(events, mouseAdapter);
// each frame:
mouse.poll();
if (mouse.isButtonPressed(Left)) fire(mouse.x, mouse.y);
```

```haxe
function new(events:IEvents, mouse:IMouse)
var x(default, null):Float
var y(default, null):Float
var wheelX(default, null):Float
var wheelY(default, null):Float
function poll():Void
function isButtonDown(button:MouseButton):Bool
function isButtonPressed(button:MouseButton):Bool
function isButtonReleased(button:MouseButton):Bool
```

- `new`: Creates the mouse over the platform's events and mouse, with nothing held.
  - `events`: The platform's events, whose last `poll` this one reads.
  - `mouse`: The platform's mouse, whose buttons and moves those events carry.
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

*class* in [`libs/services/src/helix/services/input/Tilt.hx`](../src/helix/services/input/Tilt.hx), `import helix.services.input.Tilt;`, implements `IActionDevice`, `IPollable`

Provides the device's tilt, from level and turned with the screen, for a game steered by tilting a phone or a tablet.

The program constructs one over its `IEvents` and its `ITilt`, calls `requestAccess`, and calls `poll` once a frame, as `Keyboard` is. A page may need the player's permission, asked at the player's next tap, so a game asks before the tap that starts play. Level is taken once the device is held steady, and the tilt reads 0 until then (`calibrating`). Natively it is unavailable.

```haxe
var tilt = new Tilt(events, tiltAdapter);
tilt.requestAccess(() -> trace("tilt on"), why -> trace(why));
// each frame:
tilt.poll();
x += speed * tilt.getAxis(X) * time.delta;
```

```haxe
function new(events:IEvents, tilt:ITilt)
function requestAccess(?done:() -> Void, ?failed:String -> Void):Bool
function releaseAccess():Void
var status(default, null):TiltStatus
var calibrating(default, null):Bool
function calibrate():Void
function getAxis(axis:TiltAxis):Float
var range(default, set):Float
function poll():Void
```

- `new`: Creates the tilt over the platform's events and tilt, off until `requestAccess`.
  - `events`: The platform's events, whose last `poll` this one reads.
  - `tilt`: The platform's tilt, whose readings those events carry.
- `requestAccess`: Asks for the device's motion sensor, as `ITilt.requestAccess` does.
  - `done`: Optional. Called once readings arrive.
  - `failed`: Optional. Receives why there will be none: the player refused, the page isn't secure, or the browser reads no orientation.
  - returns: False, calling neither, where the tilt can't be read at all, as natively.

  A page may need the player's permission, which is asked at the player's next tap. `status` follows each change, for a game that shows "tap to start tilt" while it waits.
- `releaseAccess`: Stops the readings, and reads 0 from then. A permission the player granted stays granted, so a later `requestAccess` usually starts without asking again.
- `status`: Gets where the tilt is: Off, WaitingForTap, On, Refused, Unavailable or NeedsHttps. Defaults to Off.
- `calibrating`: Gets a value indicating whether level is being taken.
  Level is taken once the device is held within 3 degrees for half a second: when the tilt starts, after the screen turns, and after `calibrate`. The tilt reads 0 meanwhile.
- `calibrate`: Takes level again from how the device is held next, as a game's "Level" button does.
- `getAxis`: Returns how far the device is tilted from level along an axis, turned with the screen.
  - `axis`: The axis: X across the screen, right positive; Y up and down it, down positive.
  - returns: -1 to 1, where `range` degrees reads 1; 0 while level is being taken, or when the tilt isn't on.
- `range`: Gets or sets how many degrees of tilt read 1. Clamped to at least 1. Defaults to 30.
- `poll`: Reads the events the last `IEvents.poll` delivered: the tilt's status and its readings. Call it once a frame.

## TiltAxis

*enum* in [`libs/services/src/helix/services/input/TiltAxis.hx`](../src/helix/services/input/TiltAxis.hx), `import helix.services.input.TiltAxis;`

Specifies an axis of the device's tilt, turned with the screen (`Tilt.getAxis`).

- `X`: Across the screen, right positive.
- `Y`: Up and down the screen, down positive.

## Touch

*class* in [`libs/services/src/helix/services/input/Touch.hx`](../src/helix/services/input/Touch.hx), `import helix.services.input.Touch;`, implements `IPollable`

Provides the fingers on the screen as state: which are down, where each is, and which landed or lifted this frame.

The program constructs one over its `IEvents` and its `ITouch`, and calls `poll` once a frame, as `Keyboard` is. A finger is known by its id from the frame it lands until the frame it lifts. Positions are in framebuffer pixels. When the window loses focus, every finger counts as lifted.

```haxe
var touch = new Touch(events, touchAdapter);
// each frame:
touch.poll();
for (id in touch.pressed) tapAt(touch.getX(id), touch.getY(id));
```

```haxe
function new(events:IEvents, touch:ITouch)
var available(get, never):Bool
var fingers(get, never):Array<Int>
var pressed(get, never):Array<Int>
var released(get, never):Array<Int>
function poll():Void
function isFingerDown(id:Int):Bool
function isFingerPressed(id:Int):Bool
function isFingerReleased(id:Int):Bool
function getX(id:Int):Float
function getY(id:Int):Float
```

- `new`: Creates the touch over the platform's events and touch, with no finger down.
  - `events`: The platform's events, whose last `poll` this one reads.
  - `touch`: The platform's touch, whose fingers those events carry.
- `available`: Gets a value indicating whether the device has a touch screen.
- `fingers`: Gets the fingers down, by id, in the order they landed. The array is reused by the next poll.
- `pressed`: Gets the fingers that landed this frame, by id. The array is reused by the next poll.
- `released`: Gets the fingers that lifted this frame, by id. The array is reused by the next poll.
- `poll`: Reads the events the last `IEvents.poll` delivered. Call it once a frame.
- `isFingerDown`: Returns whether a finger is down.
  - `id`: The finger.
  - returns: True from the frame it landed until the frame it lifted.
- `isFingerPressed`: Returns whether a finger landed this frame.
  - `id`: The finger.
  - returns: True for that frame alone.
- `isFingerReleased`: Returns whether a finger lifted this frame.
  - `id`: The finger.
  - returns: True for that frame alone.
- `getX`: Returns a finger's distance from the window's left edge.
  - `id`: The finger.
  - returns: Where it is in framebuffer pixels, or where it lifted this frame; 0 for one that isn't down or lifting.
- `getY`: Returns a finger's distance from the window's top edge.
  - `id`: The finger.
  - returns: Where it is in framebuffer pixels, or where it lifted this frame; 0 for one that isn't down or lifting.

## VirtualGamepad

*class* in [`libs/services/src/helix/services/input/VirtualGamepad.hx`](../src/helix/services/input/VirtualGamepad.hx), `import helix.services.input.VirtualGamepad;`, implements `IGamepads`, `IPollable`

Provides an on-screen gamepad worked by the fingers, read as a gamepad in a slot.

The program constructs one over its `Touch`, `IWindow` and `IGamepads`, and gives the virtual gamepad to `Gamepads` in place of the `IGamepads`. The program calls `poll` once a frame, after `Touch.poll` and before `Gamepads.poll`. The virtual gamepad's sticks read through `Gamepads.getAxis` and `Actions`, as any gamepad's do.

The first touch anywhere in the window plugs the virtual gamepad in. A physical gamepad plugged into the virtual gamepad's slot replaces the virtual gamepad. Physical gamepads fill the slots from 0, whatever slot the virtual gamepad is in. The next touch after the physical gamepad is unplugged plugs the virtual gamepad in again. `GamepadConnected` and `GamepadDisconnected` come from physical gamepads alone.

Positions and sizes are framebuffer pixels, as `Touch` gives them. `Touch` lists every finger, a finger holding a stick included. Drawing is the engine's, from each stick's `held`, base, knob and radius, and its hint while `hintVisible` is true.

```haxe
var virtualGamepad = new VirtualGamepad(touch, window, gamepadsAdapter, 0);
var gamepads = new Gamepads(events, virtualGamepad);
// each frame:
events.poll();
touch.poll();
virtualGamepad.poll();
gamepads.poll();
var moveX = gamepads.getAxis(0, LeftX);
```

```haxe
function new(touch:Touch, window:IWindow, gamepads:IGamepads, slot:Int, ?options:VirtualGamepadOptions)
function configure(?options:VirtualGamepadOptions):Void
function holdsFinger(id:Int):Bool
var enabled(default, set):Bool
var pluggedIn(get, never):Bool
var physicalConnected(get, never):Bool
var hintVisible(get, never):Bool
var left(default, null):VirtualStick
var right(default, null):VirtualStick
var blockedBounds:Array<Bounds2D>
function poll():Void
function isConnected(slot:Int):Bool
function getName(slot:Int):String
function isButtonDown(slot:Int, button:GamepadButton):Bool
function getAxis(slot:Int, axis:GamepadAxis):Float
function setVibration(slot:Int, low:Float, high:Float, seconds:Float):Bool
function addMappings(mappings:String):Int
function dispose():Void
```

- `new`: Creates the virtual gamepad, enabled and not plugged in.
  - `touch`: The fingers, polled before this each frame.
  - `window`: The window, whose pixel ratio sets a stick's default radius.
  - `gamepads`: The gamepads it stands in front of. They stay the program's to dispose.
  - `slot`: The slot it's plugged into, 0 to 3.
  - `options`: Optional. Its sticks. Two floating sticks, on the window's left and right halves, when omitted.
- `configure`: Applies options, as the constructor does. A held stick stays held.
  - `options`: Optional. Its sticks. Two floating sticks, on the window's left and right halves, when omitted.
- `holdsFinger`: Returns whether a stick holds a finger, or held it until it lifted this frame. An engine that turns fingers into a mouse leaves these out.
  - `id`: The finger, as `Touch` knows it.
  - returns: True for a stick's finger.
- `enabled`: Gets or sets whether it's enabled. Turned off, the virtual gamepad is unplugged and its sticks let go. Defaults to true.
- `pluggedIn`: Gets a value indicating whether it's plugged in: enabled, touched, and its slot free of physical gamepads. While a physical gamepad is in its slot, the virtual gamepad's sticks ignore touches.
- `physicalConnected`: Gets a value indicating whether a physical gamepad is in the virtual gamepad's slot.
- `hintVisible`: Gets a value indicating whether an engine draws a hint at each unheld stick's base: enabled, untouched, its slot free of physical gamepads, and on a device with a touch screen (`Touch.available`). The first touch ends every stick's hint.
- `left`: Gets the left stick, read as `LeftX` and `LeftY`.
- `right`: Gets the right stick, read as `RightX` and `RightY`.
- `blockedBounds`: Gets or sets bounds cut out of the sticks' touch zones, such as a pause button's. The blocked bounds follow changes to these bounds' fields. A finger holding a stick keeps the stick when the finger moves into a blocked bound.
- `poll`: Reads the fingers `Touch` read this frame, and moves each stick. Call it once a frame, after `Touch.poll`.
- `isConnected`: Returns whether a gamepad is in a slot. The virtual gamepad's slot is true while the virtual gamepad is plugged in or a physical gamepad is there. See `physicalConnected` for telling them apart.
  - `slot`: The slot, 0 to 3.
  - returns: True when one is there.
- `getName`: Returns the name of the gamepad in a slot. The virtual gamepad's name is "Virtual gamepad".
  - `slot`: The slot, 0 to 3.
  - returns: The name, or "" for an empty slot.
- `isButtonDown`: Returns whether a gamepad's button is down. The virtual gamepad's buttons are always up.
  - `slot`: The slot, 0 to 3.
  - `button`: The button.
  - returns: True while it's down.
- `getAxis`: Returns a gamepad's axis. While the virtual gamepad is plugged in, its slot's sticks are the virtual sticks, and its triggers are 0.
  - `slot`: The slot, 0 to 3.
  - `axis`: The axis.
  - returns: -1 to 1 for a stick, right and down positive. 0 to 1 for a trigger.
- `setVibration`: Shakes a physical gamepad. The virtual gamepad stays still.
  - `slot`: The slot, 0 to 3.
  - `low`: The low-frequency motor, 0 to 1.
  - `high`: The high-frequency motor, 0 to 1.
  - `seconds`: How long.
  - returns: False for the virtual gamepad or an empty slot.
- `addMappings`: Adds mappings for the physical gamepads, in SDL's controller database format.
  - `mappings`: The mappings.
  - returns: How many were added.
- `dispose`: Lets go of its sticks. The gamepads it stands in front of stay the program's.

## VirtualGamepadOptions

*class* in [`libs/services/src/helix/services/input/VirtualGamepadOptions.hx`](../src/helix/services/input/VirtualGamepadOptions.hx), `import helix.services.input.VirtualGamepadOptions;`

Represents how a `VirtualGamepad` starts. Every field has a default, so options set only what they change. Each field here is both sticks' default. A field set in a stick's own options replaces it for that stick. Positions and sizes are framebuffer pixels.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?basePlacement:VirtualStickBase, ?deadZone:Float, ?blockedBounds:Array<Bounds2D>, ?left:VirtualStickOptions, ?right:VirtualStickOptions}
```

```haxe
final basePlacement:Null<VirtualStickBase>
final deadZone:Null<Float>
final blockedBounds:Null<Array<Bounds2D>>
final left:Null<VirtualStickOptions>
final right:Null<VirtualStickOptions>
```

- `basePlacement`: Gets where each stick's base goes. Defaults to `Floating`.
- `deadZone`: Gets how far each stick's knob moves before the stick reads, as a share of the radius. Defaults to 0.12.
- `blockedBounds`: Gets the bounds cut out of the sticks' touch zones.
- `left`: Gets the left stick.
- `right`: Gets the right stick.

## VirtualStick

*class* in [`libs/services/src/helix/services/input/VirtualStick.hx`](../src/helix/services/input/VirtualStick.hx), `import helix.services.input.VirtualStick;`

Represents one stick of a `VirtualGamepad`: its settings, and where a finger holds it.

A finger landing in the stick's touch zone takes the stick, even from the finger holding it. A finger holding the other stick keeps the other stick. Where the two zones overlap, a landing finger takes the free stick, or the left stick if both are free. When the finger holding the stick lifts, a finger still down in the stick's zone takes the stick, without moving the knob.

The stick lets go when the window changes size, when the stick is turned off, and when a physical gamepad replaces the virtual gamepad. A finger landing takes the stick again. Positions and sizes are framebuffer pixels.

```haxe
var enabled(default, set):Bool
var touchZone:Null<Bounds2D>
var basePlacement:VirtualStickBase
var fixedBasePosition:Null<Vector2D>
var radius:Float
var deadZone(default, set):Float
var held(get, never):Bool
var finger(default, null):Int
var x(default, null):Float
var y(default, null):Float
var baseX(default, null):Float
var baseY(default, null):Float
var knobX(default, null):Float
var knobY(default, null):Float
```

- `enabled`: Gets or sets whether it's on the screen. Turned off, the stick lets go of its finger.
- `touchZone`: Gets or sets where a finger can land to take it. The zone follows changes to these bounds' fields. Null for its default: the window's left or right half with both sticks enabled, and the whole window with one, following the window's size.
- `basePlacement`: Gets or sets where the base goes.
- `fixedBasePosition`: Gets or sets where the base stays with `Fixed` placement. The base follows changes to this vector's fields. Null for the touch zone's center.
- `radius`: Gets or sets how far the knob travels for a full push, in framebuffer pixels.
- `deadZone`: Gets or sets how far the knob moves before the stick reads, as a share of the radius, 0 to 1. A push past the dead zone reads from 0. Clamped to that range. `Gamepads.deadZone` applies after it.
- `held`: Gets a value indicating whether a finger holds it.
- `finger`: Gets the id of the finger holding it, as `Touch` knows the finger. -1 while not held.
- `x`: Gets where it's pushed across, -1 (left) to 1 (right), within a circle of radius 1. 0 while not held.
- `y`: Gets where it's pushed up and down, -1 (up) to 1 (down), within a circle of radius 1. 0 while not held.
- `baseX`: Gets the base's distance from the window's left edge. While not held, it's the stick's home: the fixed base, or centered one and a half radii in from the touch zone's bottom outer corner.
- `baseY`: Gets the base's distance from the window's top edge.
- `knobX`: Gets the knob's distance from the window's left edge. It's the finger's position, held within the radius. While not held, it's the base's position.
- `knobY`: Gets the knob's distance from the window's top edge.

## VirtualStickBase

*abstract* in [`libs/services/src/helix/services/input/VirtualStickBase.hx`](../src/helix/services/input/VirtualStickBase.hx), `import helix.services.input.VirtualStickBase;`

Specifies where a virtual stick's base goes.

- `VirtualStickBase.Floating`: Where the finger lands. It stays there while held.
- `VirtualStickBase.Following`: Where the finger lands. It's pulled along when the finger moves past the radius.
- `VirtualStickBase.Fixed`: At the stick's fixed base position. A finger landing anywhere in the stick's touch zone pushes the stick from the base toward the finger.

## VirtualStickOptions

*class* in [`libs/services/src/helix/services/input/VirtualStickOptions.hx`](../src/helix/services/input/VirtualStickOptions.hx), `import helix.services.input.VirtualStickOptions;`

Represents how one stick of a `VirtualGamepad` starts. A field left out takes the gamepad's options, or their default.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?enabled:Bool, ?touchZone:Bounds2D, ?basePlacement:VirtualStickBase, ?fixedBasePosition:Vector2D, ?radius:Float, ?deadZone:Float}
```

```haxe
final enabled:Null<Bool>
final touchZone:Null<Bounds2D>
final basePlacement:Null<VirtualStickBase>
final fixedBasePosition:Null<Vector2D>
final radius:Null<Float>
final deadZone:Null<Float>
```

- `enabled`: Gets a value indicating whether the stick is on the screen. Defaults to true.
- `touchZone`: Gets where a finger can land to take it.
- `basePlacement`: Gets where the base goes.
- `fixedBasePosition`: Gets where the base stays with `Fixed` placement.
- `radius`: Gets how far the knob travels for a full push. Defaults to 60 times the window's pixel ratio.
- `deadZone`: Gets how far the knob moves before the stick reads, as a share of the radius.
