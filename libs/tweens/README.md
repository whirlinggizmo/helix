# helix-tweens

Tweens for games: pure Haxe, built on [helix-math](../math/README.md). A program steps its tweens with the seconds since the last
frame. Stepping allocates nothing natively and makes no object in a page.

- `FloatTween`, `Vector2Tween`, `Vector3Tween`, `Vector4Tween`, `QuaternionTween`, `ColorTween`: a number, a vector, a rotation or a
  color moved from a start to an end along an easing curve. The vectors and the rotation are written in place.
- `Vector2CurveTween`, `Vector3CurveTween`: a point moved along a `Curve` by distance, or along a part of it, with its heading.
- `append` and `appendDelay` on each of those: the value moves on to another end, or waits, as one tween with one `value`.
- `EasedTween`: the easing curve alone, for a program that mixes values of its own.
- `Tween`: what every tween has: a delay, repeats and the wait before each, yoyo, a speed, pausing, playing backwards, seeking, and
  callbacks at the start, each step, each repeat and the end.
- `TweenSequence`: tweens placed one after another, together, or each at a time of its own, with waits and calls between. A sequence
  is a tween.
- `Tweens`: a set of tweens stepped together, each leaving the set when it is done.

The easing curves are `helix.math.Ease`'s: the thirty of `Interpolate` (`Ease.outCubic`, `Ease.inOutSine`, `Ease.outBounce`), a
straight line, and a function of the program's own through `Ease.of`.

```haxe
import helix.math.Ease;
import helix.math.Vector3;
import helix.tweens.FloatTween;
import helix.tweens.TweenSequence;
import helix.tweens.Tweens;
import helix.tweens.Vector3Tween;

var tweens = new Tweens();
var closed = new Vector3(0, 0, 0), open = new Vector3(0, 3, 0);

// The door's position moves in place, and a light fades in after it.
var rise = new Vector3Tween(closed, open, 1.5, Ease.inOutCubic, door.position);
var glow = new FloatTween(0, 1, 0.5);
tweens.add(new TweenSequence().append(rise).appendDelay(0.25).append(glow).appendCall(unlock));

// each frame
tweens.update(dt);
light.intensity = glow.value;
```

## One value through several moves, or several tweens

A value that goes somewhere, waits and goes on is one tween. `append` adds a leg from where the tween ended before, and
`appendDelay` a wait. The tween has one `value`, and repeats, plays back and seeks through every leg as one play.

```haxe
// Across with a bounce, a second's wait, back smoothly, a second's wait, for ever.
var x = new FloatTween(-4, 4, 2, Ease.outBounce).appendDelay(1).append(-4, 2, Ease.inOutSine).appendDelay(1);
x.repeatCount = -1;

// each frame
x.update(dt);
ball.x = x.value;
```

Tweens that each move a value of their own are placed in a `TweenSequence`, as the door and the light above. Each stays a tween,
with its own start, end, curve, repeats and callbacks, and the sequence can place them together or overlapping.

## Using it

```
-lib helix-tweens
```

Until it is on haxelib, install it and the library it depends on from GitHub:

```
haxelib git helix-math https://github.com/whirlinggizmo/helix main libs/math
haxelib git helix-tweens https://github.com/whirlinggizmo/helix main libs/tweens
```

The API reference is [api/](api/README.md). Its tests, in `tests/`,
build with `-lib helix-tweens` alone.

## Depends on

helix-math.
