# helix.math

[Back to the index](README.md)

## Bounds2D

*class* in [`math/src/helix/math/Bounds2D.hx`](../../math/src/helix/math/Bounds2D.hx), `import helix.math.Bounds2D;`

Represents an axis-aligned box in 2 dimensions: its least and greatest coordinate on each axis.

A new box is empty (its least coordinates past its greatest), so expanding it by a first point makes it that point. Its space is its maker's.

```haxe
function new()
var minX:Float
var maxX:Float
var minY:Float
var maxY:Float
function set(minX:Float, minY:Float, maxX:Float, maxY:Float):Bounds2D
function makeEmpty():Bounds2D
function copyFrom(other:Bounds2D):Bounds2D
var isEmpty(get, never):Bool
var width(get, never):Float
var height(get, never):Float
var centerX(get, never):Float
var centerY(get, never):Float
function expand(x:Float, y:Float):Bounds2D
function union(other:Bounds2D):Bounds2D
function contains(x:Float, y:Float):Bool
function intersection(other:Bounds2D, ?out:Bounds2D):Bounds2D
function intersects(other:Bounds2D):Bool
```

- `new`: Creates an empty box.
- `minX`: Gets or sets the least x coordinate; infinity while empty.
- `maxX`: Gets or sets the greatest x coordinate; minus infinity while empty.
- `minY`: Gets or sets the least y coordinate; infinity while empty.
- `maxY`: Gets or sets the greatest y coordinate; minus infinity while empty.
- `set`: Sets the box's coordinates.
  - `minX`: The least x coordinate.
  - `minY`: The least y coordinate.
  - `maxX`: The greatest x coordinate.
  - `maxY`: The greatest y coordinate.
  - returns: This box.
- `makeEmpty`: Makes the box empty, holding nothing.
  - returns: This box.
- `copyFrom`: Sets the box's coordinates to another box's.
  - `other`: The box to copy.
  - returns: This box.
- `isEmpty`: Gets a value indicating whether the box holds nothing: its least coordinate is past its greatest on an axis, as when made or made empty (`makeEmpty`).
- `width`: Gets the width, maxX - minX; 0 while empty.
- `height`: Gets the height, maxY - minY; 0 while empty.
- `centerX`: Gets the center's x coordinate; NaN while empty.
- `centerY`: Gets the center's y coordinate; NaN while empty.
- `expand`: Grows the box to hold a point.
  - `x`: The point's x coordinate.
  - `y`: The point's y coordinate.
  - returns: This box.
- `union`: Grows the box to hold another box too.
  - `other`: The other box.
  - returns: This box.

  An empty box leaves it unchanged.
- `contains`: Returns whether a point is in the box, its edges included.
  - `x`: The point's x coordinate.
  - `y`: The point's y coordinate.
  - returns: True when the point is in the box; false for an empty box.
- `intersection`: Returns where the box and another overlap: a box with no width or height where they only touch, an empty one where they don't.
  - `other`: The other box.
  - `out`: Optional. The box to fill; a new one when omitted. It may be this box or the other.
  - returns: The overlap.
- `intersects`: Returns whether the box and another overlap, touching edges included.
  - `other`: The other box.
  - returns: True when they overlap; false when either is empty.

## Bounds3D

*class* in [`math/src/helix/math/Bounds3D.hx`](../../math/src/helix/math/Bounds3D.hx), `import helix.math.Bounds3D;`

Represents an axis-aligned box in 3 dimensions: its least and greatest coordinate on each axis.

A new box is empty (its least coordinates past its greatest), so expanding it by a first point makes it that point. Its space is its maker's.

```haxe
function new()
var minX:Float
var maxX:Float
var minY:Float
var maxY:Float
var minZ:Float
var maxZ:Float
function set(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Bounds3D
function makeEmpty():Bounds3D
function copyFrom(other:Bounds3D):Bounds3D
var isEmpty(get, never):Bool
var width(get, never):Float
var height(get, never):Float
var depth(get, never):Float
var centerX(get, never):Float
var centerY(get, never):Float
var centerZ(get, never):Float
function expand(x:Float, y:Float, z:Float):Bounds3D
function union(other:Bounds3D):Bounds3D
function contains(x:Float, y:Float, z:Float):Bool
function intersects(other:Bounds3D):Bool
```

- `new`: Creates an empty box.
- `minX`: Gets or sets the least x coordinate; infinity while empty.
- `maxX`: Gets or sets the greatest x coordinate; minus infinity while empty.
- `minY`: Gets or sets the least y coordinate; infinity while empty.
- `maxY`: Gets or sets the greatest y coordinate; minus infinity while empty.
- `minZ`: Gets or sets the least z coordinate; infinity while empty.
- `maxZ`: Gets or sets the greatest z coordinate; minus infinity while empty.
- `set`: Sets the box's coordinates.
  - `minX`: The least x coordinate.
  - `minY`: The least y coordinate.
  - `minZ`: The least z coordinate.
  - `maxX`: The greatest x coordinate.
  - `maxY`: The greatest y coordinate.
  - `maxZ`: The greatest z coordinate.
  - returns: This box.
- `makeEmpty`: Makes the box empty, holding nothing.
  - returns: This box.
- `copyFrom`: Sets the box's coordinates to another box's.
  - `other`: The box to copy.
  - returns: This box.
- `isEmpty`: Gets a value indicating whether the box holds nothing: its least coordinate is past its greatest on an axis, as when made or made empty (`makeEmpty`).
- `width`: Gets the width, maxX - minX; 0 while empty.
- `height`: Gets the height, maxY - minY; 0 while empty.
- `depth`: Gets the depth, maxZ - minZ; 0 while empty.
- `centerX`: Gets the center's x coordinate; NaN while empty.
- `centerY`: Gets the center's y coordinate; NaN while empty.
- `centerZ`: Gets the center's z coordinate; NaN while empty.
- `expand`: Grows the box to hold a point.
  - `x`: The point's x coordinate.
  - `y`: The point's y coordinate.
  - `z`: The point's z coordinate.
  - returns: This box.
- `union`: Grows the box to hold another box too.
  - `other`: The other box.
  - returns: This box.

  An empty box leaves it unchanged.
- `contains`: Returns whether a point is in the box, its faces included.
  - `x`: The point's x coordinate.
  - `y`: The point's y coordinate.
  - `z`: The point's z coordinate.
  - returns: True when the point is in the box; false for an empty box.
- `intersects`: Returns whether the box and another overlap, touching faces included.
  - `other`: The other box.
  - returns: True when they overlap; false when either is empty.

## Curve

*class* in [`math/src/helix/math/Curve.hx`](../../math/src/helix/math/Curve.hx), `import helix.math.Curve;`

Represents a curve through or near points in 2 or 3 dimensions: a camera rail, a patrol path, a projectile's arc.

A curve is made by `through`, `bezier` or `polyline`, and its points are fixed once made. It is asked where it is and which way it heads at a parameter t, from 0 at its start to 1 at its end, and how long it is. Equal steps of t are not equal distances along it: `getParameterAtDistance` gives the t at a distance, for moving along it at a steady speed. Points are given flat, x, y or x, y, z each.

```haxe
var rail = Curve.through([0, 0, 100, 50, 200, 0]);
var t = rail.getParameterAtDistance(speed * time);
var x = rail.getX(t), y = rail.getY(t);
```

```haxe
static function through(points:Array<Float>, ?dimensions:Int = 2, ?closed:Bool = false):Curve
static function bezier(points:Array<Float>, ?dimensions:Int = 2):Curve
static function polyline(points:Array<Float>, ?dimensions:Int = 2, ?closed:Bool = false):Curve
var kind(default, null):CurveKind
var dimensions(default, null):Int
var closed(default, null):Bool
var pointCount(get, never):Int
function getPoint(index:Int, axis:Int):Float
function getX(t:Float):Float
function getY(t:Float):Float
function getZ(t:Float):Float
function evaluate(t:Float, out:Array<Float>):Array<Float>
function tangent(t:Float, out:Array<Float>):Array<Float>
var length(get, never):Float
function getParameterAtDistance(distance:Float):Float
```

- `through`: Returns a curve that passes smoothly through every point in order.
  - `points`: The points, flat: x, y or x, y, z each.
  - `dimensions`: Optional. 2 or 3; defaults to 2.
  - `closed`: Optional. Whether it comes back to the first point; defaults to false.
  - returns: The curve.
  - throws `String`: Fewer than 2 points, or a count of numbers that dimensions doesn't divide.

  It is a centripetal Catmull-Rom spline, which makes no loops or kinks between unevenly spaced points.
- `bezier`: Returns a curve of joined cubic Bézier pieces.
  - `points`: The first point, then three for each piece: two control points and the piece's end. Flat: x, y or x, y, z each.
  - `dimensions`: Optional. 2 or 3; defaults to 2.
  - returns: The curve.
  - throws `String`: A point count other than 4, 7, 10 and so on.
- `polyline`: Returns a curve straight from point to point.
  - `points`: The points, flat: x, y or x, y, z each.
  - `dimensions`: Optional. 2 or 3; defaults to 2.
  - `closed`: Optional. Whether it comes back to the first point; defaults to false.
  - returns: The curve.
  - throws `String`: Fewer than 2 points, or a count of numbers that dimensions doesn't divide.
- `kind`: Gets how the curve passes its points.
- `dimensions`: Gets the number of dimensions: 2 or 3.
- `closed`: Gets a value indicating whether the curve comes back to its start.
- `pointCount`: Gets the number of points the curve was made with.
- `getPoint`: Returns one coordinate of one of the points the curve was made with.
  - `index`: The point's index.
  - `axis`: The axis: 0 for x, 1 for y, 2 for z.
  - returns: The coordinate, or 0 for an index or axis out of range.
- `getX`: Returns the x coordinate at a parameter.
  - `t`: The parameter: 0 at the start, 1 at the end.
  - returns: The x coordinate.

  A parameter outside 0 to 1 is clamped to it, or wrapped around a closed curve.
- `getY`: Returns the y coordinate at a parameter, as `getX` does.
  - `t`: The parameter: 0 at the start, 1 at the end.
  - returns: The y coordinate.
- `getZ`: Returns the z coordinate at a parameter, as `getX` does.
  - `t`: The parameter: 0 at the start, 1 at the end.
  - returns: The z coordinate, or 0 in 2 dimensions.
- `evaluate`: Finds the point at a parameter, every coordinate at once.
  - `t`: The parameter: 0 at the start, 1 at the end.
  - `out`: Receives x and y, and z in 3 dimensions.
  - returns: out.
- `tangent`: Finds the direction the curve heads at a parameter.
  - `t`: The parameter: 0 at the start, 1 at the end.
  - `out`: Receives the direction as a unit vector, x and y, and z in 3 dimensions; zeros where the curve doesn't move.
  - returns: out.
- `length`: Gets the curve's length, measured along it in 16 straight pieces between each two points.
- `getParameterAtDistance`: Returns the parameter at a distance along the curve from its start.
  - `distance`: The distance from the start.
  - returns: The parameter, from 0 to 1.

  Steps of equal distance move at a steady speed, where equal steps of t don't. A distance past the ends is clamped to them, or wrapped around a closed curve.

## CurveKind

*enum* in [`math/src/helix/math/CurveKind.hx`](../../math/src/helix/math/CurveKind.hx), `import helix.math.CurveKind;`

Specifies how a `Curve` passes its points.

- `Through`: Through each point, smoothly: a centripetal Catmull-Rom spline.
- `Bezier`: Near its control points: cubic Bézier pieces.
- `Polyline`: Straight from point to point.

## DistanceField2D

*class* in [`math/src/helix/math/DistanceField2D.hx`](../../math/src/helix/math/DistanceField2D.hx), `import helix.math.DistanceField2D;`

Provides the distance transform of a grid: for each cell, the squared distance to the nearest cell that is 0, by Felzenszwalb and Huttenlocher's method, in time proportional to the cells. Two transforms, one from inside a shape and one from outside it, make a signed distance field.

```haxe
static function transform(grid:Array<Float>, width:Int, height:Int):Void
```

- `transform`: Transforms a grid in place: each cell becomes its squared distance, in cells, to the nearest cell that was 0.
  - `grid`: The cells, row by row, `width * height` of them.
  - `width`: The cells in a row.
  - `height`: The rows.

  Cells start at 0 where distances are measured from, and large (1e20) everywhere else.

## Geometry2D

*class* in [`math/src/helix/math/Geometry2D.hx`](../../math/src/helix/math/Geometry2D.hx), `import helix.math.Geometry2D;`

Provides tests on points, segments, triangles, polygons and circles in a plane, their points given as plain numbers.

Lines that are parallel within a ten-millionth (by the cross product of their directions) don't cross.

```haxe
static function intersectSegments(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, dx:Float, dy:Float, ?out:Point2D):Bool
static function isPointInTriangle(x:Float, y:Float, ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Bool
static function isPointInPolygon(x:Float, y:Float, points:Array<Float>):Bool
static function getDistanceToSegment(x:Float, y:Float, ax:Float, ay:Float, bx:Float, by:Float):Float
static function intersectsCircleSegment(cx:Float, cy:Float, radius:Float, ax:Float, ay:Float, bx:Float, by:Float):Bool
```

- `intersectSegments`: Returns whether two segments cross, and where. Parallel segments, overlapping ones too, don't.
  - `ax`: The first segment's start x.
  - `ay`: Its start y.
  - `bx`: Its end x.
  - `by`: Its end y.
  - `cx`: The second segment's start x.
  - `cy`: Its start y.
  - `dx`: Its end x.
  - `dy`: Its end y.
  - `out`: Optional. Set to where they cross, when they do.
  - returns: True when they cross, their ends included.
- `isPointInTriangle`: Returns whether a point is inside a triangle, its edges not included.
  - `x`: The point's x.
  - `y`: Its y.
  - `ax`: The triangle's first corner's x.
  - `ay`: Its y.
  - `bx`: The second corner's x.
  - `by`: Its y.
  - `cx`: The third corner's x.
  - `cy`: Its y.
  - returns: True when it is inside; false for a triangle with no area.
- `isPointInPolygon`: Returns whether a point is inside a polygon, by how many of its edges a ray from the point crosses. A point on an edge may count either way.
  - `x`: The point's x.
  - `y`: Its y.
  - `points`: The polygon's corners in order, flat: x, y, x, y.
  - returns: True when it is inside; false for fewer than 3 corners.
- `getDistanceToSegment`: Returns how far a point is from the nearest point of a segment.
  - `x`: The point's x.
  - `y`: Its y.
  - `ax`: The segment's start x.
  - `ay`: Its start y.
  - `bx`: Its end x.
  - `by`: Its end y.
  - returns: The distance.
- `intersectsCircleSegment`: Returns whether a circle and a segment touch.
  - `cx`: The circle's center x.
  - `cy`: Its center y.
  - `radius`: Its radius.
  - `ax`: The segment's start x.
  - `ay`: Its start y.
  - `bx`: Its end x.
  - `by`: Its end y.
  - returns: True when they touch, the circle's edge included.

## Interpolate

*class* in [`math/src/helix/math/Interpolate.hx`](../../math/src/helix/math/Interpolate.hx), `import helix.math.Interpolate;`

Provides interpolation: between numbers and angles, along spline pieces, clamping, smoothing, stepping and easing toward a target.

`damp` and `dampAngle` use `Math.exp`, whose last bit can differ between targets, so a simulation that must replay alike on every target uses `moveToward` or its own integer math instead. Angles are in radians.

```haxe
static function lerp(a:Float, b:Float, t:Float):Float
static function inverseLerp(a:Float, b:Float, value:Float):Float
static function remap(value:Float, fromA:Float, fromB:Float, toA:Float, toB:Float):Float
static function clamp(value:Float, min:Float, max:Float):Float
static function smoothStep(t:Float):Float
static function wrapAngle(angle:Float):Float
static function lerpAngle(a:Float, b:Float, t:Float):Float
static function moveToward(value:Float, target:Float, step:Float):Float
static function damp(value:Float, target:Float, rate:Float, dt:Float):Float
static function dampAngle(value:Float, target:Float, rate:Float, dt:Float):Float
static function catmullRom(p0:Float, p1:Float, p2:Float, p3:Float, t:Float):Float
static function bSpline(p0:Float, p1:Float, p2:Float, p3:Float, t:Float):Float
static function quadraticBezier(p0:Float, p1:Float, p2:Float, t:Float):Float
static function cubicBezier(p0:Float, p1:Float, p2:Float, p3:Float, t:Float):Float
```

- `lerp`: Returns the value a fraction of the way from one number to another.
  - `a`: The value at 0.
  - `b`: The value at 1.
  - `t`: The fraction.
  - returns: a + (b - a) * t.

  A fraction outside 0 to 1 goes past the ends.
- `inverseLerp`: Returns how far a value lies from one number to another, as a fraction.
  - `a`: The value at 0.
  - `b`: The value at 1.
  - `value`: The value.
  - returns: The fraction: 0 at a, 1 at b, past them beyond; 0 when a and b are equal.
- `remap`: Returns a value moved from one range to another, at the same fraction of the way along.
  - `value`: The value.
  - `fromA`: The first range's start.
  - `fromB`: The first range's end.
  - `toA`: The second range's start.
  - `toB`: The second range's end.
  - returns: The value in the second range.
- `clamp`: Returns a value clamped to a range.
  - `value`: The value.
  - `min`: The lower bound.
  - `max`: The upper bound.
  - returns: The value, or the bound it's past.

  Bounds given in the wrong order are swapped.
- `smoothStep`: Returns a fraction clamped to 0 to 1 and smoothed, slow at both ends.
  - `t`: The fraction.
  - returns: 3t² - 2t³ of the clamped fraction.
- `wrapAngle`: Returns an angle wrapped to -π up to π.
  - `angle`: The angle, in radians.
  - returns: The same direction, from -π, included, to π, excluded.
- `lerpAngle`: Returns the angle a fraction of the way from one angle to another, the short way round.
  - `a`: The angle at 0, in radians.
  - `b`: The angle at 1, in radians.
  - `t`: The fraction.
  - returns: The angle, in radians, not wrapped.
- `moveToward`: Returns a value moved toward a target by at most a step.
  - `value`: The value.
  - `target`: The target.
  - `step`: The most it moves.
  - returns: The moved value.

  It reaches the target exactly. A step of 0 or less leaves the value unchanged.
- `damp`: Returns a value eased toward a target over a time step, the same at any frame rate.
  - `value`: The value.
  - `target`: The target.
  - `rate`: How fast it closes the gap, per second.
  - `dt`: The time step, in seconds.
  - returns: The eased value.

  Each step closes 1 - e^(-rate * dt) of the gap, so the value approaches the target without reaching it exactly. A rate or time step of 0 or less leaves the value unchanged.
- `dampAngle`: Returns an angle eased toward a target angle over a time step, the short way round, as `damp` does.
  - `value`: The angle, in radians.
  - `target`: The target angle, in radians.
  - `rate`: How fast it closes the gap, per second.
  - `dt`: The time step, in seconds.
  - returns: The eased angle, in radians, not wrapped.
- `catmullRom`: Returns a point on a piece of a uniform Catmull-Rom spline, which passes through the middle two of four points, on one axis.
  - `p0`: The first point, which steers the piece.
  - `p1`: The piece's start.
  - `p2`: Its end.
  - `p3`: The fourth point, which steers it.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.

  Each axis of a 2D or 3D point is asked for in turn.
- `bSpline`: Returns a point on a piece of a uniform cubic B-spline, which passes near the middle two of four points, on one axis.
  - `p0`: The first point.
  - `p1`: The second, near the piece's start.
  - `p2`: The third, near its end.
  - `p3`: The fourth.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `quadraticBezier`: Returns a point on a quadratic Bezier curve, on one axis.
  - `p0`: The start.
  - `p1`: The control point.
  - `p2`: The end.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.
- `cubicBezier`: Returns a point on a cubic Bezier curve, on one axis.
  - `p0`: The start.
  - `p1`: The start's control point.
  - `p2`: The end's control point.
  - `p3`: The end.
  - `t`: How far along, 0 at the start to 1 at the end.
  - returns: The point.

## Matrix3D

*class* in [`math/src/helix/math/Matrix3D.hx`](../../math/src/helix/math/Matrix3D.hx), `import helix.math.Matrix3D;`

Represents a 4 x 4 matrix transforming points in 3 dimensions: moving, turning, scaling and projecting them.

It acts on column vectors and is stored by columns, as GPUs take it, so `values` can be sent to a shader as they are. A method that makes or changes a matrix changes this one and returns it, so a caller can reuse one every frame; one that computes a point writes it into the point given. Rotations use `Trig`, so a matrix comes out the same on every target. The formulas are raymath's (raylib 5.5, zlib, `vendor/raylib/LICENSE`).

```haxe
var model = new Matrix3D().makeScale(2, 2, 2).appendRotation(0, 1, 0, angle).appendTranslation(x, 0, z);
var mvp = new Matrix3D().copyFrom(model).append(view).append(projection);
```

```haxe
function new()
final values:Array<Float>
function makeIdentity():Matrix3D
function copyFrom(other:Matrix3D):Matrix3D
function makeTranslation(x:Float, y:Float, z:Float):Matrix3D
function makeScale(x:Float, y:Float, z:Float):Matrix3D
function makeRotation(axisX:Float, axisY:Float, axisZ:Float, radians:Float):Matrix3D
function makeQuaternionRotation(x:Float, y:Float, z:Float, w:Float):Matrix3D
function makeLookAt(eyeX:Float, eyeY:Float, eyeZ:Float, targetX:Float, targetY:Float, targetZ:Float, upX:Float, upY:Float, upZ:Float):Matrix3D
function makePerspective(fovY:Float, aspect:Float, near:Float, far:Float):Matrix3D
function makeOrthographic(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float):Matrix3D
function makeFrustum(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float):Matrix3D
function compose(first:Matrix3D, second:Matrix3D):Matrix3D
function append(other:Matrix3D):Matrix3D
function prepend(other:Matrix3D):Matrix3D
function appendTranslation(x:Float, y:Float, z:Float):Matrix3D
function appendScale(x:Float, y:Float, z:Float):Matrix3D
function appendRotation(axisX:Float, axisY:Float, axisZ:Float, radians:Float):Matrix3D
function invert():Bool
function transpose():Matrix3D
function transformPoint(x:Float, y:Float, z:Float, ?out:Point3D):Point3D
function transformDirection(x:Float, y:Float, z:Float, ?out:Point3D):Point3D
```

- `new`: Creates the identity matrix.
- `values`: Gets the 16 numbers, by columns: row r of column c at `values[c * 4 + r]`; the translation at 12, 13 and 14.
- `makeIdentity`: Makes this the identity.
  - returns: This matrix.
- `copyFrom`: Sets this to another matrix's values.
  - `other`: The matrix to copy.
  - returns: This matrix.
- `makeTranslation`: Makes this a translation.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - returns: This matrix.
- `makeScale`: Makes this a scale.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - returns: This matrix.
- `makeRotation`: Makes this a rotation about an axis, which needn't be of length 1.
  - `axisX`: The axis's x.
  - `axisY`: Its y.
  - `axisZ`: Its z.
  - `radians`: The angle, counterclockwise looking down the axis toward its origin.
  - returns: This matrix.
- `makeQuaternionRotation`: Makes this the rotation a quaternion (x, y, z, w) gives.
  - `x`: The quaternion's x.
  - `y`: Its y.
  - `z`: Its z.
  - `w`: Its w.
  - returns: This matrix.
- `makeLookAt`: Makes this a view from an eye looking at a target.
  - `eyeX`: Where it looks from.
  - `eyeY`: Where it looks from.
  - `eyeZ`: Where it looks from.
  - `targetX`: What it looks at.
  - `targetY`: What it looks at.
  - `targetZ`: What it looks at.
  - `upX`: Up.
  - `upY`: Up.
  - `upZ`: Up.
  - returns: This matrix.
- `makePerspective`: Makes this a perspective projection into GL's clip space (depth -1 to 1), which every helix-platform adapter takes.
  - `fovY`: The field of view, top to bottom, in radians.
  - `aspect`: Width over height.
  - `near`: The near plane's distance.
  - `far`: The far plane's distance.
  - returns: This matrix.
- `makeOrthographic`: Makes this an orthographic projection into GL's clip space (depth -1 to 1), which every helix-platform adapter takes.
  - `left`: The left edge.
  - `right`: The right edge.
  - `bottom`: The bottom edge.
  - `top`: The top edge.
  - `near`: The near plane's distance.
  - `far`: The far plane's distance.
  - returns: This matrix.
- `makeFrustum`: Makes this a perspective projection into GL's clip space (depth -1 to 1) by its near plane's edges, which may be off center.
  - `left`: The near plane's left edge.
  - `right`: Its right edge.
  - `bottom`: Its bottom edge.
  - `top`: Its top edge.
  - `near`: The near plane's distance.
  - `far`: The far plane's distance.
  - returns: This matrix.
- `compose`: Makes this first's transform followed by second's. Either may be this matrix.
  - `first`: The transform applied first.
  - `second`: The transform applied after it.
  - returns: This matrix.
- `append`: Follows this transform with another's.
  - `other`: The transform applied after this one.
  - returns: This matrix.
- `prepend`: Puts another transform before this one.
  - `other`: The transform applied before this one.
  - returns: This matrix.
- `appendTranslation`: Follows this transform with a translation.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - returns: This matrix.
- `appendScale`: Follows this transform with a scale.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - returns: This matrix.
- `appendRotation`: Follows this transform with a rotation about an axis.
  - `axisX`: The axis's x.
  - `axisY`: Its y.
  - `axisZ`: Its z.
  - `radians`: The angle, counterclockwise looking down the axis toward its origin.
  - returns: This matrix.
- `invert`: Inverts this matrix.
  - returns: False, leaving it as it was, when it has no inverse.
- `transpose`: Transposes this matrix: rows become columns.
  - returns: This matrix.
- `transformPoint`: Computes where a point goes, translation included.
  - `x`: The point's x.
  - `y`: Its y.
  - `z`: Its z.
  - `out`: Optional. The point to fill; a new one when omitted.
  - returns: The point.
- `transformDirection`: Computes where a direction goes, translation left out.
  - `x`: The direction's x.
  - `y`: Its y.
  - `z`: Its z.
  - `out`: Optional. The point to fill; a new one when omitted.
  - returns: The direction.

## Point2D

*class* in [`math/src/helix/math/Point2D.hx`](../../math/src/helix/math/Point2D.hx), `import helix.math.Point2D;`

Represents a point in 2 dimensions.

A method that computes a point writes it into one given to it, so a caller can reuse the same point every frame. Its space is the method's.

```haxe
function new(?x:Float = 0., ?y:Float = 0.)
var x:Float
var y:Float
function set(x:Float, y:Float):Point2D
function copyFrom(other:Point2D):Point2D
```

- `new`: Creates a point.
  - `x`: Optional. The x coordinate; defaults to 0.
  - `y`: Optional. The y coordinate; defaults to 0.
- `x`: Gets or sets the x coordinate.
- `y`: Gets or sets the y coordinate.
- `set`: Sets the point's coordinates.
  - `x`: The x coordinate.
  - `y`: The y coordinate.
  - returns: This point.
- `copyFrom`: Sets the point's coordinates to another point's.
  - `other`: The point to copy.
  - returns: This point.

## Point3D

*class* in [`math/src/helix/math/Point3D.hx`](../../math/src/helix/math/Point3D.hx), `import helix.math.Point3D;`

Represents a point in 3 dimensions.

A method that computes a point writes it into one given to it, so a caller can reuse the same point every frame. Its space is the method's.

```haxe
function new(?x:Float = 0., ?y:Float = 0., ?z:Float = 0.)
var x:Float
var y:Float
var z:Float
function set(x:Float, y:Float, z:Float):Point3D
function copyFrom(other:Point3D):Point3D
```

- `new`: Creates a point.
  - `x`: Optional. The x coordinate; defaults to 0.
  - `y`: Optional. The y coordinate; defaults to 0.
  - `z`: Optional. The z coordinate; defaults to 0.
- `x`: Gets or sets the x coordinate.
- `y`: Gets or sets the y coordinate.
- `z`: Gets or sets the z coordinate.
- `set`: Sets the point's coordinates.
  - `x`: The x coordinate.
  - `y`: The y coordinate.
  - `z`: The z coordinate.
  - returns: This point.
- `copyFrom`: Sets the point's coordinates to another point's.
  - `other`: The point to copy.
  - returns: This point.

## Random

*class* in [`math/src/helix/math/Random.hx`](../../math/src/helix/math/Random.hx), `import helix.math.Random;`

Represents a seeded random number generator that gives the same sequence on every target.

It is xorshift32 in integer arithmetic, so the interpreter, JS and hxcpp agree bit for bit. A simulation that must replay alike, such as a recorded run or a lockstep game, draws from one. A program keeps one generator per stream (play, and a title screen's decoration), so that drawing from one doesn't change another's sequence.

```haxe
var random = new Random(42);
var angle = random.nextRange(0, 2 * Math.PI);
var card = random.pick(deck);
```

```haxe
function new(?seed:Int = 12345)
var seed(default, set):Int
var state(default, set):Int
function next():Int
function nextInt(max:Int):Int
function nextFloat():Float
function nextRange(min:Float, max:Float):Float
function nextBool(?chance:Float = .5):Bool
function pick(items:Array<T>):Null<T>
function pickWeighted(weights:Array<Float>):Int
function shuffle(items:Array<T>):Array<T>
```

- `new`: Creates a generator.
  - `seed`: Optional. The seed; defaults to 12345. A seed of 0 is taken as 1.
- `seed`: Gets or sets the seed the sequence last started from.
  Setting it starts the sequence again from that seed. A seed of 0 is taken as 1.
- `state`: Gets or sets where the sequence is now.
  Reading it and setting it back later continues the sequence from that point, so one generator can serve two streams in turn. A state of 0 is taken as 1.
- `next`: Returns the next whole number.
  - returns: A number from 0 to 2147483647.
- `nextInt`: Returns the next whole number below a maximum.
  - `max`: The maximum, excluded.
  - returns: A number from 0 to max - 1.

  A maximum of 1 or less returns 0.
- `nextFloat`: Returns the next number from 0 up to 1.
  - returns: A number from 0, included, to 1, excluded.

  It has 24 bits, exact in a float on every target.
- `nextRange`: Returns the next number in a range.
  - `min`: The lower bound, included.
  - `max`: The upper bound, excluded.
  - returns: A number from min up to max, or min when they're equal.

  Bounds given in the wrong order are swapped.
- `nextBool`: Returns true with a chance.
  - `chance`: Optional. The chance, from 0 to 1; defaults to 0.5.
  - returns: True with that chance.
- `pick`: Returns one of the items, each equally likely.
  - `items`: The items.
  - returns: An item, or null if there are none.
- `pickWeighted`: Returns the index of one of the weights, each as likely as its weight.
  - `weights`: The weights.
  - returns: The index, or -1 if no weight is over 0.

  A weight of 0 or less is never picked.
- `shuffle`: Shuffles items in place, every order equally likely.
  - `items`: The items.
  - returns: The same array, shuffled.

## RectPacker2D

*class* in [`math/src/helix/math/RectPacker2D.hx`](../../math/src/helix/math/RectPacker2D.hx), `import helix.math.RectPacker2D;`

Provides packing rectangles into an area, as stb_rect_pack 1.01 does (public domain, Sean Barrett), which raylib packs its font atlases with: a skyline, each rectangle placed as low as it goes and then as far left, the tallest first.

```haxe
static function pack(width:Int, height:Int, sizes:Array<Int>):Array<Int>
```

- `pack`: Places rectangles in an area.
  - `width`: The area's width.
  - `height`: The area's height.
  - `sizes`: Each rectangle's width and height, flat: width, height, width, height.
  - returns: Each rectangle's place, flat, in the same order: x, y, and 1 when it was placed or 0 when it didn't fit. A rectangle with no width or height is placed at 0, 0.

## Trig

*class* in [`math/src/helix/math/Trig.hx`](../../math/src/helix/math/Trig.hx), `import helix.math.Trig;`

Provides trigonometry that gives the same bits on every target.

A simulation that must play alike in the browser and natively (a recorded run's replay, a lockstep game, physics) uses these in place of `Math`'s, whose last bit differs between targets for some angles. Drawing doesn't need them. Results are within a few ulp of `Math`'s. Angles are in radians, of any size: an angle that keeps growing stays as accurate however large it gets. An infinite or NaN angle gives NaN, as do `asin` and `acos` outside -1 to 1.

Natively the generated C++ is compiled with `-ffp-contract=off` on GCC and clang, so that fused multiply-adds don't change the rounding.

```haxe
static function sin(x:Float):Float
static function cos(x:Float):Float
static function tan(x:Float):Float
static function atan2(y:Float, x:Float):Float
static function asin(x:Float):Float
static function acos(x:Float):Float
```

- `sin`: Returns the sine of an angle.
  - `x`: The angle, in radians.
  - returns: The sine.
- `cos`: Returns the cosine of an angle.
  - `x`: The angle, in radians.
  - returns: The cosine.
- `tan`: Returns the tangent of an angle.
  - `x`: The angle, in radians.
  - returns: The tangent.
- `atan2`: Returns the angle of a point from the +x axis, as `Math.atan2` does.
  - `y`: The point's y coordinate.
  - `x`: The point's x coordinate.
  - returns: The angle, in radians, from -π to π.
- `asin`: Returns the angle whose sine is a value.
  - `x`: The sine, from -1 to 1.
  - returns: The angle, in radians, from -π/2 to π/2, or NaN if x is outside -1 to 1.
- `acos`: Returns the angle whose cosine is a value.
  - `x`: The cosine, from -1 to 1.
  - returns: The angle, in radians, from 0 to π, or NaN if x is outside -1 to 1.
