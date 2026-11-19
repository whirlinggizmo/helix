# VirtualGamepad

[Back to the library](README.md)

## VirtualGamepad

*class* in [`engines/raylib/src/helix/raylib/extras/VirtualGamepad.hx`](../src/helix/raylib/extras/VirtualGamepad.hx), `import helix.raylib.extras.VirtualGamepad;`

Provides on-screen gamepads for phones: sticks and buttons a finger works, read through raylib's gamepad functions. Imported apart, with its constants: `import helix.raylib.extras.VirtualGamepad.*;`. The example `engines/raylib/examples/extras/virtual_gamepad` uses it.

The first touch in the window plugs an enabled virtual gamepad in, as does a press of the left mouse button with touch emulation (`EnableTouchEmulation`). A virtual gamepad with a tilt stick (`VirtualStickOptions.tilt`) is plugged in once the tilt is on (`EnableTiltAsync`). Once the virtual gamepad is plugged in, `IsGamepadAvailable` is true for its slot, and its sticks read through `GetGamepadAxisMovement` and its buttons through `IsGamepadButtonDown`, `IsGamepadButtonPressed` and `IsGamepadButtonReleased`. `IsGamepadVirtual` tells a virtual gamepad from a physical one.

A physical gamepad plugged into the virtual gamepad's slot replaces the virtual gamepad. The first physical gamepad plugged in gets slot 0. The next touch after the physical gamepad is unplugged plugs the virtual gamepad in again.

A free finger is a finger that is not currently captured. A stick captures a finger landing in its touch zone, and the buttons a finger landing on one of them. A finger landing within the blocked bounds (`VirtualGamepadOptions.blockedBounds`) stays a free finger. A free finger counts as the mouse, and as a touch point, as every finger does without a virtual gamepad. A captured finger is neither: the touch functions list the free fingers.

The virtual gamepad is drawn at `EndDrawing`, over everything the frame drew. On a device with touch or with touch emulation, its buttons and fixed sticks are drawn from the moment it's enabled, and every other stick while it has captured a finger. A program drawing its own controls sets their `visible` to false and draws from `IsVirtualGamepadVisible`, `IsVirtualStickHeld`, `GetVirtualStickBase` and `GetVirtualStickKnob`. The virtual gamepad is hidden while a physical gamepad is in its slot.

```haxe
InitWindow(800, 450, "twin stick");
EnableVirtualGamepad(0);
while (!WindowShouldClose()) {
var moveX = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
var aimX = GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_X);
// ...
}
```

```haxe
static inline var VIRTUAL_STICK_BASE_FLOATING:Int
static inline var VIRTUAL_STICK_BASE_FOLLOWING:Int
static inline var VIRTUAL_STICK_BASE_FIXED:Int
static inline var VIRTUAL_STICK_LEFT:Int
static inline var VIRTUAL_STICK_RIGHT:Int
```

- `VIRTUAL_STICK_BASE_FLOATING`: A stick whose base is where the finger lands. The base stays there while the stick is held.
- `VIRTUAL_STICK_BASE_FOLLOWING`: A stick whose base is where the finger lands. The base is pulled along when the finger moves past the radius.
- `VIRTUAL_STICK_BASE_FIXED`: A stick whose base stays at the fixed base position. A finger landing anywhere in the stick's touch zone pushes the stick from the base toward the finger. While no finger holds the stick, the stick is drawn at the base, the knob at rest.
- `VIRTUAL_STICK_LEFT`: The left stick, read as `GAMEPAD_AXIS_LEFT_X` and `GAMEPAD_AXIS_LEFT_Y`.
- `VIRTUAL_STICK_RIGHT`: The right stick, read as `GAMEPAD_AXIS_RIGHT_X` and `GAMEPAD_AXIS_RIGHT_Y`.

### virtual gamepad: on-screen sticks read as a gamepad's

```haxe
static function EnableVirtualGamepad(gamepad:Int, ?options:VirtualGamepadOptions):Void
static function DisableVirtualGamepad(gamepad:Int):Void
static function IsGamepadVirtual(gamepad:Int):Bool
static function IsVirtualGamepadVisible(gamepad:Int):Bool
static function IsVirtualStickHeld(gamepad:Int, stick:Int):Bool
static function GetVirtualStickBase(gamepad:Int, stick:Int, ?out:Vector2):Vector2
static function GetVirtualStickKnob(gamepad:Int, stick:Int, ?out:Vector2):Vector2
```

- `EnableVirtualGamepad`: Enables a virtual gamepad in a slot. The first touch after enabling plugs the virtual gamepad in, and so does the tilt once it's on, for a tilt stick. Enabling it again applies the new options. Its held sticks and buttons, and whether it's plugged in, stay as they were.
  - `gamepad`: The slot, 0 to 3.
  - `options`: Optional. Its sticks, its buttons and their look. Two floating sticks, on the screen's left and right halves, when omitted.

  ```haxe
  EnableVirtualGamepad(0, {
  right: {enabled: false},
  buttons: [{button: GAMEPAD_BUTTON_RIGHT_FACE_DOWN}, {button: GAMEPAD_BUTTON_RIGHT_FACE_RIGHT}]
  });
  ```
- `DisableVirtualGamepad`: Disables the virtual gamepad in a slot, unplugging it. A physical gamepad in that slot is unaffected.
  - `gamepad`: The slot, 0 to 3.
- `IsGamepadVirtual`: Returns whether the gamepad in a slot is a virtual one (`EnableVirtualGamepad`).
  - `gamepad`: The slot, 0 to 3.
  - returns: True while a virtual gamepad is plugged in there. False for a physical one or an empty slot.
- `IsVirtualGamepadVisible`: Returns whether the virtual gamepad in a slot is drawn: enabled, on a device with touch or with touch emulation (`EnableTouchEmulation`), with no physical gamepad in its slot. A program drawing its own sticks (`visible: false`) draws them while this is true.
  - `gamepad`: The slot, 0 to 3.
  - returns: True while drawn.
- `IsVirtualStickHeld`: Returns whether a finger holds a stick of the virtual gamepad in a slot.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - returns: True while held.
- `GetVirtualStickBase`: Returns where a stick's base is, in the screen's pixels. While the stick isn't held, and for a tilt stick, the base is at the stick's home: the fixed base position, or one and a half radii in from the touch zone's bottom outer corner.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The base's center. (0, 0) without a virtual gamepad in the slot.
- `GetVirtualStickKnob`: Returns where a stick's knob is, in the screen's pixels: under the finger, held within the radius of the base. A tilt stick's knob is pushed from the base by the tilt, a full tilt at the radius. While a stick read by fingers isn't held, the knob is at the base.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The knob's center. (0, 0) without a virtual gamepad in the slot.

## VirtualGamepadOptions

*class* in [`engines/raylib/src/helix/raylib/extras/VirtualGamepadOptions.hx`](../src/helix/raylib/extras/VirtualGamepadOptions.hx), `import helix.raylib.extras.VirtualGamepadOptions;`

Represents how a virtual gamepad starts and looks (`EnableVirtualGamepad`, in `helix.raylib.extras.VirtualGamepad`). Every field has a default, so options set only what they change. Its placement, dead zone, hint and colors are both sticks' defaults, and its colors the buttons' too. A field set in a stick's or a button's own options replaces it for that stick or button. Positions and sizes are in the screen's pixels.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?basePlacement:Int, ?deadZone:Float, ?hintVisible:Bool, ?baseOutlineColor:Color, ?baseFillColor:Color, ?knobColor:Color, ?baseTexture:Texture2D, ?knobTexture:Texture2D, ?font:Font, ?blockedBounds:Array<Rectangle>, ?left:VirtualStickOptions, ?right:VirtualStickOptions, ?buttons:Array<VirtualButtonOptions>}
```

```haxe
var basePlacement:Null<Int>
var deadZone:Null<Float>
var hintVisible:Null<Bool>
var baseOutlineColor:Null<Color>
var baseFillColor:Null<Color>
var knobColor:Null<Color>
var baseTexture:Null<Texture2D>
var knobTexture:Null<Texture2D>
var font:Null<Font>
var blockedBounds:Null<Array<Rectangle>>
var left:Null<VirtualStickOptions>
var right:Null<VirtualStickOptions>
var buttons:Null<Array<VirtualButtonOptions>>
```

- `basePlacement`: Gets or sets where each stick's base goes: `VIRTUAL_STICK_BASE_FLOATING`, `VIRTUAL_STICK_BASE_FOLLOWING` or `VIRTUAL_STICK_BASE_FIXED`. Defaults to `VIRTUAL_STICK_BASE_FLOATING`.
- `deadZone`: Gets or sets how far each stick's knob moves before the stick reads, as a share of the radius, 0 to 1. Defaults to 0.12.
  Past the dead zone, a stick reads from 0, rising evenly to 1 at the radius in any direction from the base. A game's own dead zone applies on top.
- `hintVisible`: Gets or sets a value indicating whether each floating or following stick's hint is visible until the first touch. The hint is a fainter copy of the stick at rest, centered one and a half radii in from the touch zone's bottom outer corner, on a device with touch or with touch emulation (`EnableTouchEmulation`). Defaults to true.
- `baseOutlineColor`: Gets or sets each stick's ring around the base. Defaults to `Fade(LIGHTGRAY, 0.5)`. The hint is this ring, fainter.
- `baseFillColor`: Gets or sets each stick's disc inside the ring. Defaults to `BLANK`.
- `knobColor`: Gets or sets each stick's knob, the disc under the finger, 0.4 of the radius. Defaults to the stick's base outline color, a little more opaque.
- `baseTexture`: Gets or sets each stick's image of the base, drawn in place of the ring and the disc, scaled to the base's diameter and tinted by the base outline color. With a base texture, the base outline color defaults to `WHITE`.
- `knobTexture`: Gets or sets each stick's image of the knob, drawn in place of the knob's disc, scaled to the knob's diameter and tinted by the knob color. With a knob texture, the knob color defaults to `WHITE`.
- `font`: Gets or sets the font every button's label is drawn in. Defaults to the default font (`GetFontDefault`).
- `blockedBounds`: Gets or sets bounds where a landing finger stays a free finger, even within a stick's touch zone, such as a raygui button's bounds. The blocked bounds follow changes to these rectangles' fields. A finger holding a stick keeps the stick when the finger moves into a blocked bound.
- `left`: Gets or sets the left stick, read as `GAMEPAD_AXIS_LEFT_X` and `GAMEPAD_AXIS_LEFT_Y`.
- `right`: Gets or sets the right stick, read as `GAMEPAD_AXIS_RIGHT_X` and `GAMEPAD_AXIS_RIGHT_Y`.
- `buttons`: Gets or sets the buttons, each read as a gamepad button. A finger landing on a button presses the button, even within a stick's touch zone. Defaults to `[]`.

## VirtualStickOptions

*class* in [`engines/raylib/src/helix/raylib/extras/VirtualStickOptions.hx`](../src/helix/raylib/extras/VirtualStickOptions.hx), `import helix.raylib.extras.VirtualStickOptions;`

Represents how one stick of a virtual gamepad starts and looks (`VirtualGamepadOptions`). A field left out uses the gamepad's options, or their default. Positions and sizes are in the screen's pixels.

A stick captures a finger landing in its touch zone, even while it has captured another, and releases the earlier finger. A finger the other stick captured stays with the other stick. Where the two zones overlap, the stick that is not currently capturing a finger captures the landing finger, or the left stick when both are free. The stick releases its finger when the window changes size, and when a physical gamepad replaces the virtual gamepad.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?enabled:Bool, ?touchZone:Rectangle, ?tilt:Bool, ?basePlacement:Int, ?fixedBasePosition:Vector2, ?radius:Float, ?deadZone:Float, ?hintVisible:Bool, ?visible:Bool, ?baseOutlineColor:Color, ?baseFillColor:Color, ?knobColor:Color, ?baseTexture:Texture2D, ?knobTexture:Texture2D}
```

```haxe
var enabled:Null<Bool>
var touchZone:Null<Rectangle>
var tilt:Null<Bool>
var basePlacement:Null<Int>
var fixedBasePosition:Null<Vector2>
var radius:Null<Float>
var deadZone:Null<Float>
var hintVisible:Null<Bool>
var visible:Null<Bool>
var baseOutlineColor:Null<Color>
var baseFillColor:Null<Color>
var knobColor:Null<Color>
var baseTexture:Null<Texture2D>
var knobTexture:Null<Texture2D>
```

- `enabled`: Gets or sets a value indicating whether the stick is enabled. Defaults to true. A disabled stick reads 0, is hidden, and ignores fingers.
- `touchZone`: Gets or sets where the stick captures a landing finger. The zone follows changes to this rectangle's fields. Defaults to the screen's left or right half with both sticks enabled and read by fingers, and the whole screen with one. The default follows the screen's size.
- `tilt`: Gets or sets a value indicating whether the stick reads the device's tilt (`EnableTiltAsync`) in place of a finger: across the screen as x and down it as y, past the stick's dead zone, a full tilt at `SetTiltRange`'s angle. Defaults to false.
  A tilt stick is hidden and ignores fingers. The tilt plugs the virtual gamepad in once the tilt is on, as a touch does. A tilt stick reads 0 until the tilt is on and level (`GetTiltStatus`, `IsTiltCalibrating`).
- `basePlacement`: Gets or sets where the base goes.
- `fixedBasePosition`: Gets or sets where the base stays with `VIRTUAL_STICK_BASE_FIXED`. The base follows changes to this vector's fields. Defaults to the touch zone's center.
- `radius`: Gets or sets how far the knob travels for a full push, in the screen's pixels. Defaults to 60.
- `deadZone`: Gets or sets how far the knob moves before the stick reads, as a share of the radius, 0 to 1. Defaults to the gamepad's `deadZone`.
  Past the dead zone, the stick reads from 0, rising evenly to 1 at the radius in any direction from the base.
- `hintVisible`: Gets or sets a value indicating whether the stick's hint is visible until the first touch.
- `visible`: Gets or sets a value indicating whether the stick is visible. A stick that isn't visible still reads. Defaults to true.
- `baseOutlineColor`: Gets or sets the ring around the base.
- `baseFillColor`: Gets or sets the disc inside the ring.
- `knobColor`: Gets or sets the knob, the disc under the finger. Defaults to the base outline color, a little more opaque.
- `baseTexture`: Gets or sets the image of the base, drawn in place of the ring and the disc.
- `knobTexture`: Gets or sets the image of the knob, drawn in place of the knob's disc.

## VirtualButtonOptions

*class* in [`engines/raylib/src/helix/raylib/extras/VirtualButtonOptions.hx`](../src/helix/raylib/extras/VirtualButtonOptions.hx), `import helix.raylib.extras.VirtualButtonOptions;`

Represents one on-screen button of a virtual gamepad (`VirtualGamepadOptions.buttons`), read as a gamepad button. Positions and sizes are in the screen's pixels.

The buttons capture a finger landing on one of them, even within a stick's touch zone, until the finger lifts. A button is down while a finger the buttons captured is within its circle, including a finger that slid there from another button. The mouse follows the free fingers.

The buttons are drawn at `EndDrawing` while the virtual gamepad is enabled, on a device with touch or with touch emulation (`EnableTouchEmulation`). The buttons are hidden while a physical gamepad is in the virtual gamepad's slot.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{button:Int, ?position:Vector2, ?enabled:Bool, ?visible:Bool, ?radius:Float, ?label:String, ?outlineColor:Color, ?fillColor:Color, ?labelColor:Color, ?texture:Texture2D, ?downTexture:Texture2D}
```

```haxe
var button:Int
var position:Null<Vector2>
var enabled:Null<Bool>
var visible:Null<Bool>
var radius:Null<Float>
var label:Null<String>
var outlineColor:Null<Color>
var fillColor:Null<Color>
var labelColor:Null<Color>
var texture:Null<Texture2D>
var downTexture:Null<Texture2D>
```

- `button`: Gets or sets the gamepad button the button is read as, such as `GAMEPAD_BUTTON_RIGHT_FACE_DOWN`.
- `position`: Gets or sets the button's center. The center follows changes to this vector's fields. Defaults to the button's place in a diamond of the four face buttons (`GAMEPAD_BUTTON_RIGHT_FACE_*`) at the screen's bottom-right corner, following the screen's size: the diamond's center three and a half radii in from the corner, each face button 1.6 radii from that center. Another button without a position is up and isn't drawn.
- `enabled`: Gets or sets a value indicating whether the button is enabled. Defaults to true. A disabled button is up, hidden, and ignores fingers.
- `visible`: Gets or sets a value indicating whether the button is visible. A button that isn't visible still reads. Defaults to true.
- `radius`: Gets or sets the button's radius, the reach of a finger landing on the button. Defaults to 40.
- `label`: Gets or sets the text drawn at the button's center, in the gamepad's font (`VirtualGamepadOptions.font`), as tall as the radius, or smaller to fit within the button's width. Defaults to "A", "B", "X" or "Y" for the face buttons (`GAMEPAD_BUTTON_RIGHT_FACE_DOWN`, `_RIGHT`, `_LEFT` and `_UP`), and "" for another button.
- `outlineColor`: Gets or sets the ring's color. Defaults to the gamepad's base outline color.
- `fillColor`: Gets or sets the color of the disc inside the ring, drawn while the button is down. Defaults to the gamepad's knob color.
- `labelColor`: Gets or sets the label's color. Defaults to the ring's color while the button is up, and `Fade(BLACK, 0.6)` while the button is down.
- `texture`: Gets or sets the image of the button while up, drawn in place of the ring, scaled to the button's diameter and tinted by the outline color. With a texture, the outline color defaults to `WHITE`. The label is drawn over the image.
- `downTexture`: Gets or sets the image of the button while down, drawn in place of the ring and the disc. Defaults to the texture, tinted by the fill color.
