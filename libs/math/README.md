# helix-math

Math for games, in pure Haxe.

- `Trig`: trigonometry giving the same bits on every target, or the standard library's with `-D helix-math-standard-trig`.
- `Random`: a seeded generator giving the same sequence on every target.
- `Interpolate`: interpolating, clamping, smoothing and easing numbers and angles, and points on spline pieces (Catmull-Rom,
  B-spline, Bezier).
- `Ease`: an easing curve as a value, for a tween or any move from 0 to 1 to take: `Interpolate`'s thirty and a straight line.
- `Curve`: curves through points or by control points, in 2D and 3D, and moving along them.
- `Vector2`, `Vector3`, `Vector4`, `Aabb2D`, `Aabb3D`: vectors (positions and directions, their sums, products, lengths, blends and
  turns) and axis-aligned boxes, and where boxes overlap.
- `DistanceField2D`: a grid's distance transform, for distance fields.
- `Color`: colors as 0xAARRGGBB integers: their channels, the CSS order, hue, saturation and value, mixing, laying one over another,
  tinting, brightening and contrasting.
- `RectanglePacker`: rectangles packed into an area, as stb_rect_pack packs them (an atlas's images, say).
- `Matrix3`, `Matrix4`, `Quaternion`, `Transform2D`, `Transform3D`: transforms, moving, turning, scaling and projecting points,
  the same on every target.

Cameras, rays, meshes and the tests on shapes built on these are in [helix-geometry](../geometry/README.md). Tweens along `Ease`'s
curves are in [helix-tweens](../tweens/README.md).

```haxe
import helix.math.Random;
import helix.math.Trig;

var random = new Random(42);
var angle = random.nextRange(0, 2 * Math.PI);
var x = Trig.cos(angle) * speed, y = Trig.sin(angle) * speed;
```

## Using it

```
-lib helix-math
```

Until it is on haxelib, install it from GitHub:

```
haxelib git helix-math https://github.com/whirlinggizmo/helix main libs/math
```

The API reference is [api/](api/README.md). Its tests, in `tests/`,
build with `-lib helix-math` alone.

## Credit

Portions of `Matrix4` are from [raylib](https://www.raylib.com) 5.5's raymath, by Ramon Santamaria (@raysan5) and its contributors,
altered; zlib license, `vendor/raylib/LICENSE`.
`Interpolate`'s spline pieces follow raylib 5.5's rshapes. `RectanglePacker` is
[stb_rect_pack](https://github.com/nothings/stb) 1.01's skyline packer, by Sean Barrett, ported; public domain. `DistanceField2D` is
Felzenszwalb and Huttenlocher's distance transform ("Distance Transforms of Sampled Functions", 2012).
