# helix.raylib.extras.tweens

[Back to the library](README.md)

## ColorTween

*abstract* in [`engines/raylib/src/helix/raylib/extras/tweens/ColorTween.hx`](../src/helix/raylib/extras/tweens/ColorTween.hx), `import helix.raylib.extras.tweens.ColorTween;`

Represents a `Color` fading from one color to another, each of its four channels on its own. It is helix-tweens' `ColorTween` taking and giving raylib's `Color`, so it has that type's members too, and is placed in a sequence or added to a set as one.

```haxe
var flash = new ColorTween(WHITE, RED, 0.2, Ease.outQuad);
// each frame
flash.update(GetFrameTime());
DrawCircle(200, 200, 40, flash.value);
```

```haxe
function new(from:Color, to:Color, duration:Float, ?ease:Ease)
var from(get, set):Color
var to(get, set):Color
var value(get, never):Color
function append(to:Color, duration:Float, ?ease:Ease):ColorTween
function appendDelay(seconds:Float):ColorTween
```

- `new`: Creates a tween of a color, at its start.
  - `from`: The color at the start.
  - `to`: The color at the end.
  - `duration`: The seconds one play takes, 0 or more.
  - `ease`: Optional. The easing curve; a straight line when omitted.
- `from`: Gets or sets the color at the start.
- `to`: Gets or sets the color at the end: the first leg's end, where `append` added more legs.
- `value`: Gets the color now, its channels rounded and kept to 0 to 255 where the easing curve overshoots.
- `append`: Adds a leg: the color fades on from where the tween ended before to another color.
  - `to`: The color at the leg's end.
  - `duration`: The seconds the leg takes, 0 or more.
  - `ease`: Optional. The leg's easing curve; a straight line when omitted.
  - returns: This tween.
  - throws `String`: A tween placed in a sequence, which took the tween's time when placed.

  The tween's `duration` grows by the leg's seconds, so a repeat, a yoyo and a seek take every leg as one play. `from`, `to` and `ease` stay the first leg's.

  ```haxe
  // To red, a wait, then back to white.
  var flash = new ColorTween(WHITE, RED, 0.1).appendDelay(0.2).append(WHITE, 0.5, Ease.outQuad);
  ```
- `appendDelay`: Adds a wait: the color stays where the tween ended before, for some seconds.
  - `seconds`: The seconds to wait, 0 or more.
  - returns: This tween.
  - throws `String`: A tween placed in a sequence, which took the tween's time when placed.

## Ease

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/Ease.hx`](../src/helix/raylib/extras/tweens/Ease.hx), `import helix.raylib.extras.tweens.Ease;`

Represents an easing curve, the shape a tween moves by: `Ease.outCubic`, `Ease.inOutSine`, `Ease.outBounce` and the rest of its thirty, `Ease.linear`, or a function of the program's own through `Ease.of`. It is helix-math's `Ease`.

An alias of [`Ease`](../../../libs/math/api/types.md#ease).

## EasedTween

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/EasedTween.hx`](../src/helix/raylib/extras/tweens/EasedTween.hx), `import helix.raylib.extras.tweens.EasedTween;`

Represents a play along an easing curve, from 0 to 1, for a value the program mixes itself by `amount`. It is helix-tweens' `EasedTween`.

The easing curves are `Ease`'s: `Ease.outCubic`, `Ease.inOutSine`, `Ease.outBounce` and the rest of its thirty, or a function of the program's own through `Ease.of`.

An alias of [`EasedTween`](../../../libs/tweens/api/types.md#easedtween).

## FloatTween

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/FloatTween.hx`](../src/helix/raylib/extras/tweens/FloatTween.hx), `import helix.raylib.extras.tweens.FloatTween;`

Represents a number moving from one value to another. It is helix-tweens' `FloatTween`.

```haxe
var zoom = new FloatTween(1, 2, 0.3, Ease.outCubic);
// each frame
zoom.update(GetFrameTime());
camera.zoom = zoom.value;
```

An alias of [`FloatTween`](../../../libs/tweens/api/types.md#floattween).

## QuaternionTween

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/QuaternionTween.hx`](../src/helix/raylib/extras/tweens/QuaternionTween.hx), `import helix.raylib.extras.tweens.QuaternionTween;`

Represents a `Quaternion` turning from one rotation to another, the short way round, as `QuaternionSlerp` turns one, written in place. It is helix-tweens' `QuaternionTween`.

An alias of [`QuaternionTween`](../../../libs/tweens/api/types.md#quaterniontween).

## Tween

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/Tween.hx`](../src/helix/raylib/extras/tweens/Tween.hx), `import helix.raylib.extras.tweens.Tween;`

Represents something that plays over time: a value moving along an easing curve, or a `TweenSequence`. It is helix-tweens' `Tween`, which has the delay, the repeats, the speed, the callbacks, `update`, `reverse` and `seek` every tween here has.

An alias of [`Tween`](../../../libs/tweens/api/types.md#tween).

## TweenSequence

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/TweenSequence.hx`](../src/helix/raylib/extras/tweens/TweenSequence.hx), `import helix.raylib.extras.tweens.TweenSequence;`

Represents tweens placed in time: one after another, together, or each at a time of its own, with waits and calls between them. It is helix-tweens' `TweenSequence`.

An alias of [`TweenSequence`](../../../libs/tweens/api/types.md#tweensequence).

## Tweens

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/Tweens.hx`](../src/helix/raylib/extras/tweens/Tweens.hx), `import helix.raylib.extras.tweens.Tweens;`

Provides a set of tweens stepped together, each leaving the set when it is done. It is helix-tweens' `Tweens`.

```haxe
var tweens = new Tweens();
var fade = tweens.add(new ColorTween(WHITE, BLANK, 0.5));
// each frame
tweens.update(GetFrameTime());
DrawTexture(logo, 0, 0, fade.value);
```

An alias of [`Tweens`](../../../libs/tweens/api/types.md#tweens).

## Vector2CurveTween

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/Vector2CurveTween.hx`](../src/helix/raylib/extras/tweens/Vector2CurveTween.hx), `import helix.raylib.extras.tweens.Vector2CurveTween;`

Represents a `Vector2` moving along a curve by distance, with its heading. It is helix-tweens' `Vector2CurveTween`. The curve is helix-math's (`import helix.math.Curve;`): `Curve.through` makes one through points.

An alias of [`Vector2CurveTween`](../../../libs/tweens/api/types.md#vector2curvetween).

## Vector2Tween

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/Vector2Tween.hx`](../src/helix/raylib/extras/tweens/Vector2Tween.hx), `import helix.raylib.extras.tweens.Vector2Tween;`

Represents a `Vector2` moving from one point to another, written in place. It is helix-tweens' `Vector2Tween`.

An alias of [`Vector2Tween`](../../../libs/tweens/api/types.md#vector2tween).

## Vector3CurveTween

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/Vector3CurveTween.hx`](../src/helix/raylib/extras/tweens/Vector3CurveTween.hx), `import helix.raylib.extras.tweens.Vector3CurveTween;`

Represents a `Vector3` moving along a curve by distance, with its heading. It is helix-tweens' `Vector3CurveTween`. The curve is helix-math's (`import helix.math.Curve;`): `Curve.through` makes one through points.

An alias of [`Vector3CurveTween`](../../../libs/tweens/api/types.md#vector3curvetween).

## Vector3Tween

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/Vector3Tween.hx`](../src/helix/raylib/extras/tweens/Vector3Tween.hx), `import helix.raylib.extras.tweens.Vector3Tween;`

Represents a `Vector3` moving from one point to another, written in place. It is helix-tweens' `Vector3Tween`.

```haxe
var rise = new Vector3Tween(door, new Vector3(0, 3, 0), 1.5, Ease.inOutCubic, door);
// each frame
rise.update(GetFrameTime()); // moves door
DrawCubeV(door, size, BROWN);
```

An alias of [`Vector3Tween`](../../../libs/tweens/api/types.md#vector3tween).

## Vector4Tween

*typedef* in [`engines/raylib/src/helix/raylib/extras/tweens/Vector4Tween.hx`](../src/helix/raylib/extras/tweens/Vector4Tween.hx), `import helix.raylib.extras.tweens.Vector4Tween;`

Represents a `Vector4` moving from one value to another, each of its four numbers on its own, written in place. It is helix-tweens' `Vector4Tween`.

An alias of [`Vector4Tween`](../../../libs/tweens/api/types.md#vector4tween).
