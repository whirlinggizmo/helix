# helix-math

Math for games: pure Haxe, depending on nothing.

- `Trig`: trigonometry giving the same bits on every target, so a simulation plays alike in the browser and natively.
- `Random`: a seeded generator giving the same sequence on every target.
- `Interpolate`: interpolating, clamping, smoothing and easing numbers and angles.
- `Curve`: curves through points or by control points, in 2D and 3D, and moving along them.
- `Point2D`, `Point3D`, `Bounds2D`, `Bounds3D`: points and axis-aligned boxes.
- `Matrix3D`: 4 x 4 transforms, moving, turning, scaling and projecting points, the same on every target.

```haxe
import helix.math.Random;
import helix.math.Trig;

var random = new Random(42);
var angle = random.nextRange(0, 2 * Math.PI);
var x = Trig.cos(angle) * speed, y = Trig.sin(angle) * speed;
```

The API reference is [docs/api/math.md](https://github.com/whirlinggizmo/helix-2.0/blob/main/docs/api/math.md). Its tests, in `tests/`,
build with `-lib helix-math` alone.
