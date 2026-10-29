# helix-math

Math for games: pure Haxe, depending on nothing.

- `Trig`: sine, cosine, tangent and their inverses giving the same bits on every target, for a simulation that must play alike in the
  browser and natively.
- `Random`: a seeded generator whose sequence is the same on every target: whole numbers, floats, ranges, picks, weights and shuffles.
- `Interpolate`: between numbers and angles, clamping, smoothing, stepping and easing toward a target at any frame rate.
- `Curve`: through points (Catmull-Rom), by control points (Bézier) or straight between them, in 2 or 3 dimensions, with its length and
  the parameter at a distance for moving along it at a steady speed.
- `Point2D`, `Point3D`, `Bounds2D`, `Bounds3D`: points and axis-aligned boxes.

```haxe
import helix.math.Random;
import helix.math.Trig;

var random = new Random(42);
var angle = random.nextRange(0, 2 * Math.PI);
var x = Trig.cos(angle) * speed, y = Trig.sin(angle) * speed;
```

Its tests, in `tests/`, build with `-lib helix-math` alone, on the interpreter and Node. `TrigBits` hashes `Trig`'s results over fixed
inputs; the hash must be the same on the interpreter, in JS and in hxcpp, which the repository's `helix.py test` compares.
