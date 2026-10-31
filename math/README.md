# helix-math

Math for games: pure Haxe, depending on nothing.

- `Trig`: trigonometry giving the same bits on every target, so a simulation plays alike in the browser and natively.
- `Random`: a seeded generator giving the same sequence on every target.
- `Interpolate`: interpolating, clamping, smoothing and easing numbers and angles, and points on spline pieces (Catmull-Rom,
  B-spline, Bezier).
- `Curve`: curves through points or by control points, in 2D and 3D, and moving along them.
- `Point2D`, `Point3D`, `Bounds2D`, `Bounds3D`: points and axis-aligned boxes, and where boxes overlap.
- `Geometry2D`: segments crossing, points in triangles and polygons, distances to segments, circles touching them.
- `DistanceField2D`: a grid's distance transform, for distance fields.
- `RectPacker2D`: rectangles packed into an area, as stb_rect_pack packs them (an atlas's images, say).
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

## Credit

Portions of `Matrix3D` are from [raylib](https://www.raylib.com) 5.5's raymath, by Ramon Santamaria (@raysan5) and its contributors,
altered; zlib license, `vendor/raylib/LICENSE`.
`Geometry2D`'s tests and `Interpolate`'s spline pieces follow raylib 5.5's rshapes. `RectPacker2D` is
[stb_rect_pack](https://github.com/nothings/stb) 1.01's skyline packer, by Sean Barrett, ported; public domain. `DistanceField2D` is
Felzenszwalb and Huttenlocher's distance transform ("Distance Transforms of Sampled Functions", 2012).
