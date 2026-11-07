# helix.math

Generated from the doc comments by `tools/gen_apidoc.py`.

## Bounds2D

*class* in [`libs/math/src/helix/math/Bounds2D.hx`](../src/helix/math/Bounds2D.hx), `import helix.math.Bounds2D;`

Represents an axis-aligned box in 2 dimensions: its least and greatest coordinate on each axis.

A new box is empty (its least coordinates past its greatest), so expanding it by a first point makes it that point. `set`, `copyFrom`, `makeEmpty` and `expand` change this box and return it. `union` and `intersection` write their result into an optional out, the last argument, and return it: a new box when it is omitted, this one left unchanged; the out may be this box or the other. Its space is its maker's.

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
function union(other:Bounds2D, ?out:Bounds2D):Bounds2D
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
- `union`: Returns the smallest box holding this box and another.
  - `other`: The other box.
  - `out`: Optional. The box to fill; a new one when omitted. It may be this box or the other.
  - returns: The union.

  An empty box adds nothing: the union with one is the other box.
- `contains`: Returns whether a point is in the box, its edges included.
  - `x`: The point's x coordinate.
  - `y`: The point's y coordinate.
  - returns: True when the point is in the box; false for an empty box.
- `intersection`: Returns where this box and another overlap: a box with no width or height where they only touch, an empty one where they don't.
  - `other`: The other box.
  - `out`: Optional. The box to fill; a new one when omitted. It may be this box or the other.
  - returns: The overlap.
- `intersects`: Returns whether the box and another overlap, touching edges included.
  - `other`: The other box.
  - returns: True when they overlap; false when either is empty.

## Bounds3D

*class* in [`libs/math/src/helix/math/Bounds3D.hx`](../src/helix/math/Bounds3D.hx), `import helix.math.Bounds3D;`

Represents an axis-aligned box in 3 dimensions: its least and greatest coordinate on each axis.

A new box is empty (its least coordinates past its greatest), so expanding it by a first point makes it that point. `set`, `copyFrom`, `makeEmpty` and `expand` change this box and return it. `union` writes its result into an optional out, the last argument, and returns it: a new box when it is omitted, this one left unchanged; the out may be this box or the other. Its space is its maker's.

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
function union(other:Bounds3D, ?out:Bounds3D):Bounds3D
function contains(x:Float, y:Float, z:Float):Bool
function intersects(other:Bounds3D):Bool
function intersectsSphere(x:Float, y:Float, z:Float, radius:Float):Bool
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
- `union`: Returns the smallest box holding this box and another.
  - `other`: The other box.
  - `out`: Optional. The box to fill; a new one when omitted. It may be this box or the other.
  - returns: The union.

  An empty box adds nothing: the union with one is the other box.
- `contains`: Returns whether a point is in the box, its faces included.
  - `x`: The point's x coordinate.
  - `y`: The point's y coordinate.
  - `z`: The point's z coordinate.
  - returns: True when the point is in the box; false for an empty box.
- `intersects`: Returns whether the box and another overlap, touching faces included.
  - `other`: The other box.
  - returns: True when they overlap; false when either is empty.
- `intersectsSphere`: Returns whether a sphere touches or overlaps the bounds.
  - `x`: The sphere's center's x.
  - `y`: Its y.
  - `z`: Its z.
  - `radius`: Its radius.
  - returns: True when they touch or overlap; false for empty bounds.

## Color

*class* in [`libs/math/src/helix/math/Color.hx`](../src/helix/math/Color.hx), `import helix.math.Color;`

Provides functions for colors held as 0xAARRGGBB integers, with alpha in the top byte: their channels, hue, saturation and value, blending one over another, and mixing, tinting, brightening and contrasting them.

Each channel is 0 to 255. Text writes a color in CSS order, as #RRGGBB or #RRGGBBAA. `fromRgba` and `toRgba` convert between that order and this one.

```haxe
var orange = Color.fromChannels(255, 128, 0);
var faded = Color.withAlpha(orange, 128);
```

```haxe
static function fromChannels(red:Int, green:Int, blue:Int, ?alpha:Int = 255):Int
static function getRed(color:Int):Int
static function getGreen(color:Int):Int
static function getBlue(color:Int):Int
static function getAlpha(color:Int):Int
static function withAlpha(color:Int, alpha:Int):Int
static function fromRgba(rgba:Int):Int
static function toRgba(color:Int):Int
static function fromHsv(hue:Float, saturation:Float, value:Float, ?alpha:Int = 255):Int
static function getHue(color:Int):Float
static function getSaturation(color:Int):Float
static function getValue(color:Int):Float
static function lerp(from:Int, to:Int, t:Float):Int
static function blend(under:Int, over:Int):Int
static function tint(color:Int, tint:Int):Int
static function brighten(color:Int, factor:Float):Int
static function contrast(color:Int, factor:Float):Int
```

- `fromChannels`: Returns the color with the provided channels.
  - `red`: The red channel, 0 to 255.
  - `green`: The green channel, 0 to 255.
  - `blue`: The blue channel, 0 to 255.
  - `alpha`: Optional. The alpha channel, 0 (clear) to 255 (opaque); defaults to 255.
  - returns: The color, as 0xAARRGGBB.

  Only the low 8 bits of each channel are used.
- `getRed`: Returns a color's red channel.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The red channel, 0 to 255.
- `getGreen`: Returns a color's green channel.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The green channel, 0 to 255.
- `getBlue`: Returns a color's blue channel.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The blue channel, 0 to 255.
- `getAlpha`: Returns a color's alpha channel.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The alpha channel, 0 (clear) to 255 (opaque).
- `withAlpha`: Returns a color with its alpha channel replaced.
  - `color`: The color, as 0xAARRGGBB.
  - `alpha`: The new alpha channel, 0 (clear) to 255 (opaque).
  - returns: The color with the new alpha.

  Only the low 8 bits of alpha are used.
- `fromRgba`: Returns the color that an integer in CSS order names.
  - `rgba`: The color, as 0xRRGGBBAA.
  - returns: The color, as 0xAARRGGBB.
- `toRgba`: Returns a color as an integer in CSS order.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The color, as 0xRRGGBBAA.
- `fromHsv`: Returns the color of a hue, saturation and value, opaque or with an alpha.
  - `hue`: The hue, in degrees: 0 red, 120 green, 240 blue; any angle, wrapped.
  - `saturation`: The saturation, 0 (gray) to 1, clamped.
  - `value`: The value, 0 (black) to 1, clamped.
  - `alpha`: Optional. The alpha channel, 0 to 255; defaults to 255.
  - returns: The color, its channels rounded.
- `getHue`: Returns a color's hue.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The hue, in degrees, 0 up to 360: 0 for a gray.
- `getSaturation`: Returns a color's saturation: how far it is from gray.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The saturation, 0 to 1: 0 for a gray or black.
- `getValue`: Returns a color's value: its brightest channel.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The value, 0 (black) to 1.
- `lerp`: Returns the color a fraction of the way from one color to another, each channel alpha included.
  - `from`: The color at 0, as 0xAARRGGBB.
  - `to`: The color at 1.
  - `t`: The fraction, clamped to 0 to 1.
  - returns: The mix, its channels rounded.
- `blend`: Returns one color laid over another by its alpha, as a translucent paint covers what is under it ("source over").
  - `under`: The color beneath, as 0xAARRGGBB.
  - `over`: The color laid over it.
  - returns: What is seen, its channels rounded: the color beneath where the one over is clear, the one over where it is opaque.
- `tint`: Returns a color multiplied by another, channel by channel, alpha included: white leaves it as it is, black makes it black.
  - `color`: The color, as 0xAARRGGBB.
  - `tint`: The color it is multiplied by.
  - returns: The tinted color, its channels rounded.
- `brighten`: Returns a color brightened toward white or darkened toward black, its alpha kept.
  - `color`: The color, as 0xAARRGGBB.
  - `factor`: How far: 1 white, -1 black, 0 unchanged; clamped to -1 to 1.
  - returns: The color, its channels rounded.
- `contrast`: Returns a color with its contrast changed: its channels pushed away from mid-gray, or pulled toward it, its alpha kept.
  - `color`: The color, as 0xAARRGGBB.
  - `factor`: How far: 1 the most contrast (each channel to 0 or 255), -1 none (mid-gray), 0 unchanged; clamped to -1 to 1.
  - returns: The color, its channels rounded and kept to 0 to 255.

## Curve

*class* in [`libs/math/src/helix/math/Curve.hx`](../src/helix/math/Curve.hx), `import helix.math.Curve;`

Represents a curve through or near points in 2 or 3 dimensions: a camera rail, a patrol path, a projectile's arc.

A curve is made by `through`, `bezier` or `polyline`, and its points are fixed once made. It is asked where it is and which way it heads at a parameter t, from 0 at its start to 1 at its end, and how long it is. Equal steps of t are not equal distances along it: `getParameterAtDistance` gives the t at a distance, for moving along it at a steady speed. Points are given flat, x, y or x, y, z each.

```haxe
var rail = Curve.through([0, 0, 100, 50, 200, 0]);
var t = rail.getParameterAtDistance(speed * time);
var x = rail.getX(t), y = rail.getY(t);
```

```haxe
static function through(points:Array<Float>, ?dimensionCount:Int = 2, ?closed:Bool = false):Curve
static function bezier(points:Array<Float>, ?dimensionCount:Int = 2):Curve
static function polyline(points:Array<Float>, ?dimensionCount:Int = 2, ?closed:Bool = false):Curve
var kind(default, null):CurveKind
var dimensionCount(default, null):Int
var closed(default, null):Bool
var pointCount(get, never):Int
function getPoint(pointIndex:Int, axis:Int):Float
function getX(t:Float):Float
function getY(t:Float):Float
function getZ(t:Float):Float
function computePosition(t:Float, ?out:Array<Float>):Array<Float>
function computeTangent(t:Float, ?out:Array<Float>):Array<Float>
var length(get, never):Float
function getParameterAtDistance(distance:Float):Float
```

- `through`: Returns a curve that passes smoothly through every point in order.
  - `points`: The points, flat: x, y or x, y, z each.
  - `dimensionCount`: Optional. 2 or 3; defaults to 2.
  - `closed`: Optional. Whether it comes back to the first point; defaults to false.
  - returns: The curve.
  - throws `String`: Fewer than 2 points, or a count of numbers that dimensions doesn't divide.

  It is a centripetal Catmull-Rom spline, which makes no loops or kinks between unevenly spaced points.
- `bezier`: Returns a curve of joined cubic Bézier pieces.
  - `points`: The first point, then three for each piece: two control points and the piece's end. Flat: x, y or x, y, z each.
  - `dimensionCount`: Optional. 2 or 3; defaults to 2.
  - returns: The curve.
  - throws `String`: A point count other than 4, 7, 10 and so on.
- `polyline`: Returns a curve straight from point to point.
  - `points`: The points, flat: x, y or x, y, z each.
  - `dimensionCount`: Optional. 2 or 3; defaults to 2.
  - `closed`: Optional. Whether it comes back to the first point; defaults to false.
  - returns: The curve.
  - throws `String`: Fewer than 2 points, or a count of numbers that dimensions doesn't divide.
- `kind`: Gets how the curve passes its points.
- `dimensionCount`: Gets the number of dimensions: 2 or 3.
- `closed`: Gets a value indicating whether the curve comes back to its start.
- `pointCount`: Gets the number of points the curve was made with.
- `getPoint`: Returns one coordinate of one of the points the curve was made with.
  - `pointIndex`: The point's index.
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
- `computePosition`: Returns the position at a parameter, every coordinate at once.
  - `t`: The parameter: 0 at the start, 1 at the end.
  - `out`: Optional. The array to fill with x and y, and z in 3 dimensions; a new one when omitted.
  - returns: The position.
- `computeTangent`: Returns the direction the curve heads at a parameter.
  - `t`: The parameter: 0 at the start, 1 at the end.
  - `out`: Optional. The array to fill with the direction as a unit vector, x and y, and z in 3 dimensions; zeros where the curve doesn't move. A new one when omitted.
  - returns: The direction.
- `length`: Gets the curve's length, measured along it in 16 straight pieces between each two points.
- `getParameterAtDistance`: Returns the parameter at a distance along the curve from its start.
  - `distance`: The distance from the start.
  - returns: The parameter, from 0 to 1.

  Steps of equal distance move at a steady speed, where equal steps of t don't. A distance past the ends is clamped to them, or wrapped around a closed curve.

## CurveKind

*enum* in [`libs/math/src/helix/math/CurveKind.hx`](../src/helix/math/CurveKind.hx), `import helix.math.CurveKind;`

Specifies how a `Curve` passes its points.

- `Through`: Through each point, smoothly: a centripetal Catmull-Rom spline.
- `Bezier`: Near its control points: cubic Bézier pieces.
- `Polyline`: Straight from point to point.

## DistanceField2D

*class* in [`libs/math/src/helix/math/DistanceField2D.hx`](../src/helix/math/DistanceField2D.hx), `import helix.math.DistanceField2D;`

Provides the distance transform of a grid: for each cell, the squared distance to the nearest cell that is 0, by Felzenszwalb and Huttenlocher's method, in time proportional to the cells. Two transforms, one from inside a shape and one from outside it, make a signed distance field.

```haxe
static function transform(grid:Array<Float>, width:Int, height:Int):Void
```

- `transform`: Transforms a grid in place: each cell becomes its squared distance, in cells, to the nearest cell that was 0.
  - `grid`: The cells, row by row, `width * height` of them.
  - `width`: The cells in a row.
  - `height`: The rows.

  Cells start at 0 where distances are measured from, and large (1e20) everywhere else.

## Interpolate

*class* in [`libs/math/src/helix/math/Interpolate.hx`](../src/helix/math/Interpolate.hx), `import helix.math.Interpolate;`

Provides interpolation: between numbers and angles, along spline pieces, easing curves, clamping, smoothing, stepping and easing toward a target.

The easing curves are Robert Penner's, each family in three: `easeIn...` starts slow, `easeOut...` ends slow, `easeInOut...` does both. Each takes a fraction from 0 to 1 and returns 0 at 0 and 1 at 1; back and elastic go past 0 and 1 on their way. The sine family uses `Trig`, so it is the same on every target; the expo and elastic families use `Math.pow`, whose last bit can differ between targets.

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
static function easeInSine(t:Float):Float
static function easeOutSine(t:Float):Float
static function easeInOutSine(t:Float):Float
static function easeInQuad(t:Float):Float
static function easeOutQuad(t:Float):Float
static function easeInOutQuad(t:Float):Float
static function easeInCubic(t:Float):Float
static function easeOutCubic(t:Float):Float
static function easeInOutCubic(t:Float):Float
static function easeInQuart(t:Float):Float
static function easeOutQuart(t:Float):Float
static function easeInOutQuart(t:Float):Float
static function easeInQuint(t:Float):Float
static function easeOutQuint(t:Float):Float
static function easeInOutQuint(t:Float):Float
static function easeInExpo(t:Float):Float
static function easeOutExpo(t:Float):Float
static function easeInOutExpo(t:Float):Float
static function easeInCirc(t:Float):Float
static function easeOutCirc(t:Float):Float
static function easeInOutCirc(t:Float):Float
static function easeInBack(t:Float):Float
static function easeOutBack(t:Float):Float
static function easeInOutBack(t:Float):Float
static function easeInElastic(t:Float):Float
static function easeOutElastic(t:Float):Float
static function easeInOutElastic(t:Float):Float
static function easeInBounce(t:Float):Float
static function easeOutBounce(t:Float):Float
static function easeInOutBounce(t:Float):Float
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
- `easeInSine`: Returns a fraction eased slow at the start: a quarter sine wave.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeOutSine`: Returns a fraction eased slow at the end: a quarter sine wave.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInOutSine`: Returns a fraction eased slow at both ends: a quarter sine wave.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInQuad`: Returns a fraction eased slow at the start: t squared.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeOutQuad`: Returns a fraction eased slow at the end: t squared.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInOutQuad`: Returns a fraction eased slow at both ends: t squared.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInCubic`: Returns a fraction eased slow at the start: t cubed.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeOutCubic`: Returns a fraction eased slow at the end: t cubed.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInOutCubic`: Returns a fraction eased slow at both ends: t cubed.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInQuart`: Returns a fraction eased slow at the start: t to the fourth.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeOutQuart`: Returns a fraction eased slow at the end: t to the fourth.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInOutQuart`: Returns a fraction eased slow at both ends: t to the fourth.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInQuint`: Returns a fraction eased slow at the start: t to the fifth.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeOutQuint`: Returns a fraction eased slow at the end: t to the fifth.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInOutQuint`: Returns a fraction eased slow at both ends: t to the fifth.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInExpo`: Returns a fraction eased slow at the start: two to the power of t.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeOutExpo`: Returns a fraction eased slow at the end: two to the power of t.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInOutExpo`: Returns a fraction eased slow at both ends: two to the power of t.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInCirc`: Returns a fraction eased slow at the start: a quarter circle.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeOutCirc`: Returns a fraction eased slow at the end: a quarter circle.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInOutCirc`: Returns a fraction eased slow at both ends: a quarter circle.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInBack`: Returns a fraction eased slow at the start: pulling back a tenth before it goes.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeOutBack`: Returns a fraction eased slow at the end: pulling back a tenth before it goes.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInOutBack`: Returns a fraction eased slow at both ends: pulling back a tenth before it goes.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInElastic`: Returns a fraction eased slow at the start: springing past its end and back.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeOutElastic`: Returns a fraction eased slow at the end: springing past its end and back.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInOutElastic`: Returns a fraction eased slow at both ends: springing past its end and back.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInBounce`: Returns a fraction eased slow at the start: bouncing to rest.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeOutBounce`: Returns a fraction eased slow at the end: bouncing to rest.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.
- `easeInOutBounce`: Returns a fraction eased slow at both ends: bouncing to rest.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.

## Matrix2D

*class* in [`libs/math/src/helix/math/Matrix2D.hx`](../src/helix/math/Matrix2D.hx), `import helix.math.Matrix2D;`

Represents a 2D affine matrix: moving, turning, scaling and shearing points in 2 dimensions.

It is the 3 x 3 matrix whose last row is 0, 0, 1, kept as its six other numbers as a canvas's `setTransform` and Flash's `Matrix` keep them: a point (x, y) goes to (a x + c y + tx, b x + d y + ty). Its operations follow helix-math's out rule: each writes into an optional out, last, and returns it; omitted, it makes a new matrix; given the matrix itself, it works in place. Rotations use `Trig`, so a matrix comes out the same on every target. Angles are radians, a positive one turning from +x toward +y, clockwise on screen where y grows downward.

```haxe
var model = Matrix2D.fromScale(2, 2);
model.appendRotation(angle, model).appendTranslation(x, y, model);
var onScreen = model.transformPoint(0, 0);
```

```haxe
function new()
static function fromTranslation(x:Float, y:Float, ?out:Matrix2D):Matrix2D
static function fromScale(x:Float, y:Float, ?out:Matrix2D):Matrix2D
static function fromRotation(radians:Float, ?out:Matrix2D):Matrix2D
static function compose(first:Matrix2D, second:Matrix2D, ?out:Matrix2D):Matrix2D
var a:Float
var b:Float
var c:Float
var d:Float
var tx:Float
var ty:Float
function set(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Matrix2D
function copyFrom(other:Matrix2D):Matrix2D
function makeIdentity():Matrix2D
function append(other:Matrix2D, ?out:Matrix2D):Matrix2D
function prepend(other:Matrix2D, ?out:Matrix2D):Matrix2D
function appendTranslation(x:Float, y:Float, ?out:Matrix2D):Matrix2D
function appendScale(x:Float, y:Float, ?out:Matrix2D):Matrix2D
function appendRotation(radians:Float, ?out:Matrix2D):Matrix2D
function invert(?out:Matrix2D):Null<Matrix2D>
function transformPoint(x:Float, y:Float, ?out:Vector2D):Vector2D
function transformDirection(x:Float, y:Float, ?out:Vector2D):Vector2D
function toMatrix3D(?out:Matrix3D):Matrix3D
```

- `new`: Creates the identity matrix.
- `fromTranslation`: Returns a matrix that moves points.
  - `x`: How far along x.
  - `y`: How far along y.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The matrix.
- `fromScale`: Returns a matrix that scales points from the origin.
  - `x`: The scale along x.
  - `y`: The scale along y.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The matrix.
- `fromRotation`: Returns a matrix that turns points around the origin.
  - `radians`: The angle; more than 0 turns from +x toward +y.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The matrix.
- `compose`: Returns one matrix followed by another.
  - `first`: The matrix applied first.
  - `second`: The matrix applied after it.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The matrix.

  Either may be the out.
- `a`: Gets or sets how x scales x: the top left.
- `b`: Gets or sets how x moves y.
- `c`: Gets or sets how y moves x.
- `d`: Gets or sets how y scales y.
- `tx`: Gets or sets the translation's x.
- `ty`: Gets or sets the translation's y.
- `set`: Sets the six numbers.
  - `a`: How x scales x.
  - `b`: How x moves y.
  - `c`: How y moves x.
  - `d`: How y scales y.
  - `tx`: The translation's x.
  - `ty`: The translation's y.
  - returns: This matrix.
- `copyFrom`: Sets this matrix to another's numbers.
  - `other`: The matrix to copy.
  - returns: This matrix.
- `makeIdentity`: Makes this the identity.
  - returns: This matrix.
- `append`: Returns this matrix followed by another.
  - `other`: The matrix applied after this one.
  - `out`: Optional. The matrix to write into, which may be this one or other; a new one when omitted.
  - returns: The matrix.
- `prepend`: Returns another matrix followed by this one.
  - `other`: The matrix applied before this one.
  - `out`: Optional. The matrix to write into, which may be this one or other; a new one when omitted.
  - returns: The matrix.
- `appendTranslation`: Returns this matrix followed by a move.
  - `x`: How far along x.
  - `y`: How far along y.
  - `out`: Optional. The matrix to write into, which may be this one; a new one when omitted.
  - returns: The matrix.
- `appendScale`: Returns this matrix followed by a scale from the origin.
  - `x`: The scale along x.
  - `y`: The scale along y.
  - `out`: Optional. The matrix to write into, which may be this one; a new one when omitted.
  - returns: The matrix.
- `appendRotation`: Returns this matrix followed by a turn around the origin.
  - `radians`: The angle; more than 0 turns from +x toward +y.
  - `out`: Optional. The matrix to write into, which may be this one; a new one when omitted.
  - returns: The matrix.
- `invert`: Returns the matrix that undoes this one.
  - `out`: Optional. The matrix to write into, which may be this one; a new one when omitted.
  - returns: The inverse, or null when there is none (a matrix that flattens points onto a line), the out unchanged.
- `transformPoint`: Returns a point moved by this matrix.
  - `x`: The point's x.
  - `y`: The point's y.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The point.
- `transformDirection`: Returns a direction turned and scaled by this matrix, its translation ignored.
  - `x`: The direction's x.
  - `y`: The direction's y.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The direction.
- `toMatrix3D`: Returns the matrix as a 4 x 4 one acting on x and y alone, as a shader takes a 2D view.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The matrix.

## Matrix3D

*class* in [`libs/math/src/helix/math/Matrix3D.hx`](../src/helix/math/Matrix3D.hx), `import helix.math.Matrix3D;`

Represents a 4 x 4 matrix transforming points in 3 dimensions: moving, turning, scaling and projecting them.

It acts on column vectors and is stored by columns, as GPUs take it, so `values` can be sent to a shader as they are. A static `fromX` makes a matrix of one kind, and `compose` one transform followed by another. Each of those, and each operation on a matrix (`append`, `invert`, `transpose`, `transformPoint`), writes its result into an optional out, the last argument, and returns it. Without one it makes a new result and leaves this matrix unchanged; given this matrix, it changes it in place (`m.transpose(m)`). The out may be this matrix or any other argument, and none of them allocates when given one, so a caller can reuse one matrix every frame and chain calls through what each returns. `makeIdentity` and `copyFrom` change this matrix and return it. Rotations use `Trig`, so a matrix comes out the same on every target. The formulas are raymath's (raylib 5.5, zlib, `vendor/raylib/LICENSE`).

```haxe
var model = Matrix3D.fromScale(2, 2, 2);
model.appendRotation(0, 1, 0, angle, model).appendTranslation(x, 0, z, model);
var mvp = Matrix3D.compose(model, view).append(projection);
```

```haxe
function new()
static function fromTranslation(x:Float, y:Float, z:Float, ?out:Matrix3D):Matrix3D
static function fromScale(x:Float, y:Float, z:Float, ?out:Matrix3D):Matrix3D
static function fromRotation(axisX:Float, axisY:Float, axisZ:Float, radians:Float, ?out:Matrix3D):Matrix3D
static function fromQuaternion(x:Float, y:Float, z:Float, w:Float, ?out:Matrix3D):Matrix3D
static function fromLookAt(eyeX:Float, eyeY:Float, eyeZ:Float, targetX:Float, targetY:Float, targetZ:Float, upX:Float, upY:Float, upZ:Float, ?out:Matrix3D):Matrix3D
static function fromPerspective(fovY:Float, aspect:Float, near:Float, far:Float, ?out:Matrix3D):Matrix3D
static function fromOrthographic(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float, ?out:Matrix3D):Matrix3D
static function fromFrustum(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float, ?out:Matrix3D):Matrix3D
static function compose(first:Matrix3D, second:Matrix3D, ?out:Matrix3D):Matrix3D
final values:Array<Float>
function makeIdentity():Matrix3D
function copyFrom(other:Matrix3D):Matrix3D
function append(other:Matrix3D, ?out:Matrix3D):Matrix3D
function prepend(other:Matrix3D, ?out:Matrix3D):Matrix3D
function appendTranslation(x:Float, y:Float, z:Float, ?out:Matrix3D):Matrix3D
function appendScale(x:Float, y:Float, z:Float, ?out:Matrix3D):Matrix3D
function appendRotation(axisX:Float, axisY:Float, axisZ:Float, radians:Float, ?out:Matrix3D):Matrix3D
function invert(?out:Matrix3D):Null<Matrix3D>
function transpose(?out:Matrix3D):Matrix3D
function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3D):Vector3D
function transformDirection(x:Float, y:Float, z:Float, ?out:Vector3D):Vector3D
```

- `new`: Creates the identity matrix.
- `fromTranslation`: Returns a translation.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
- `fromScale`: Returns a scale.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
- `fromRotation`: Returns a rotation about an axis, which needn't be of length 1.
  - `axisX`: The axis's x.
  - `axisY`: Its y.
  - `axisZ`: Its z.
  - `radians`: The angle, counterclockwise looking down the axis toward its origin.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
- `fromQuaternion`: Returns the rotation a quaternion (x, y, z, w) gives.
  - `x`: The quaternion's x.
  - `y`: Its y.
  - `z`: Its z.
  - `w`: Its w.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
- `fromLookAt`: Returns a view from an eye looking at a target.
  - `eyeX`: Where it looks from.
  - `eyeY`: Where it looks from.
  - `eyeZ`: Where it looks from.
  - `targetX`: What it looks at.
  - `targetY`: What it looks at.
  - `targetZ`: What it looks at.
  - `upX`: Up.
  - `upY`: Up.
  - `upZ`: Up.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
- `fromPerspective`: Returns a perspective projection into GL's clip space (depth -1 to 1), which every helix-platform adapter takes.
  - `fovY`: The field of view, top to bottom, in radians.
  - `aspect`: Width over height.
  - `near`: The near plane's distance.
  - `far`: The far plane's distance.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
- `fromOrthographic`: Returns an orthographic projection into GL's clip space (depth -1 to 1), which every helix-platform adapter takes.
  - `left`: The left edge.
  - `right`: The right edge.
  - `bottom`: The bottom edge.
  - `top`: The top edge.
  - `near`: The near plane's distance.
  - `far`: The far plane's distance.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
- `fromFrustum`: Returns a perspective projection into GL's clip space (depth -1 to 1) by its near plane's edges, which may be off center.
  - `left`: The near plane's left edge.
  - `right`: Its right edge.
  - `bottom`: Its bottom edge.
  - `top`: Its top edge.
  - `near`: The near plane's distance.
  - `far`: The far plane's distance.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
- `compose`: Returns one transform followed by another.
  - `first`: The transform applied first.
  - `second`: The transform applied after it.
  - `out`: Optional. The matrix to fill; a new one when omitted. It may be first or second.
  - returns: The matrix.
- `values`: Gets the 16 numbers, by columns: row r of column c at `values[c * 4 + r]`; the translation at 12, 13 and 14.
- `makeIdentity`: Makes this matrix the identity.
  - returns: This matrix.
- `copyFrom`: Sets this to another matrix's values.
  - `other`: The matrix to copy.
  - returns: This matrix.
- `append`: Returns this transform followed by another.
  - `other`: The transform applied after this one.
  - `out`: Optional. The matrix to fill; a new one when omitted. It may be this matrix or the other.
  - returns: The matrix.
- `prepend`: Returns another transform followed by this one.
  - `other`: The transform applied before this one.
  - `out`: Optional. The matrix to fill; a new one when omitted. It may be this matrix or the other.
  - returns: The matrix.
- `appendTranslation`: Returns this transform followed by a translation.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - `out`: Optional. The matrix to fill; a new one when omitted. It may be this matrix.
  - returns: The matrix.
- `appendScale`: Returns this transform followed by a scale.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - `out`: Optional. The matrix to fill; a new one when omitted. It may be this matrix.
  - returns: The matrix.
- `appendRotation`: Returns this transform followed by a rotation about an axis.
  - `axisX`: The axis's x.
  - `axisY`: Its y.
  - `axisZ`: Its z.
  - `radians`: The angle, counterclockwise looking down the axis toward its origin.
  - `out`: Optional. The matrix to fill; a new one when omitted. It may be this matrix.
  - returns: The matrix.
- `invert`: Returns the inverse of this matrix: the transform that undoes it.
  - `out`: Optional. The matrix to fill; a new one when omitted. It may be this matrix.
  - returns: The inverse, or null, leaving out unchanged and making nothing, when this matrix has no inverse.
- `transpose`: Returns this matrix transposed: its rows made columns.
  - `out`: Optional. The matrix to fill; a new one when omitted. It may be this matrix.
  - returns: The transpose.
- `transformPoint`: Computes where a point goes, translation included.
  - `x`: The point's x.
  - `y`: Its y.
  - `z`: Its z.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The point.
- `transformDirection`: Computes where a direction goes, translation left out.
  - `x`: The direction's x.
  - `y`: Its y.
  - `z`: Its z.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The direction.

## Quaternion3D

*class* in [`libs/math/src/helix/math/Quaternion3D.hx`](../src/helix/math/Quaternion3D.hx), `import helix.math.Quaternion3D;`

Represents a rotation in 3 dimensions, as a unit quaternion.

Two rotations blend along the shortest arc (`slerp`), which matrices can't do, so an animation's rotations are kept as these and turned into a matrix to draw. A static `fromX` makes a rotation, and `slerp`, `nlerp` and `compose` make one from others. Each of those, and each operation on a rotation (`append`, `invert`, `normalize`, `transformPoint`, `toMatrix`), writes its result into an optional out, the last argument, and returns it. Without one it makes a new result and leaves this rotation unchanged; given this rotation, it changes it in place (`q.normalize(q)`). The out may be this rotation or any other argument, and calls chain through what each returns. `set`, `copyFrom` and `makeIdentity` change this rotation and return it. It uses `Trig`, so a rotation comes out the same on every target. Space is right-handed with +y up, as every 3D type here.

```haxe
var turn = Quaternion3D.fromAxisAngle(0, 1, 0, Math.PI / 2);
var halfway = Quaternion3D.slerp(from, turn, .5);
var facing = turn.transformPoint(0, 0, -1);
```

```haxe
function new(?x:Float = 0., ?y:Float = 0., ?z:Float = 0., ?w:Float = 1.)
static function fromAxisAngle(axisX:Float, axisY:Float, axisZ:Float, radians:Float, ?out:Quaternion3D):Quaternion3D
static function fromEuler(pitch:Float, yaw:Float, roll:Float, ?out:Quaternion3D):Quaternion3D
static function fromLookRotation(forwardX:Float, forwardY:Float, forwardZ:Float, ?upX:Float = 0., ?upY:Float = 1., ?upZ:Float = 0., ?out:Quaternion3D):Quaternion3D
static function fromBetween(from:Vector3D, to:Vector3D, ?out:Quaternion3D):Quaternion3D
static function fromMatrix(matrix:Matrix3D, ?out:Quaternion3D):Quaternion3D
static function slerp(from:Quaternion3D, to:Quaternion3D, amount:Float, ?out:Quaternion3D):Quaternion3D
static function nlerp(from:Quaternion3D, to:Quaternion3D, amount:Float, ?out:Quaternion3D):Quaternion3D
static function compose(first:Quaternion3D, second:Quaternion3D, ?out:Quaternion3D):Quaternion3D
var x:Float
var y:Float
var z:Float
var w:Float
function set(x:Float, y:Float, z:Float, w:Float):Quaternion3D
function copyFrom(other:Quaternion3D):Quaternion3D
function makeIdentity():Quaternion3D
function append(other:Quaternion3D, ?out:Quaternion3D):Quaternion3D
function prepend(other:Quaternion3D, ?out:Quaternion3D):Quaternion3D
function invert(?out:Quaternion3D):Quaternion3D
function normalize(?out:Quaternion3D):Quaternion3D
function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3D):Vector3D
function toEuler(?out:Vector3D):Vector3D
var angle(get, never):Float
function toMatrix(?out:Matrix3D):Matrix3D
```

- `new`: Creates a rotation, the identity unless the quaternion is provided.
  - `x`: Optional. The quaternion's x; defaults to 0.
  - `y`: Optional. The quaternion's y; defaults to 0.
  - `z`: Optional. The quaternion's z; defaults to 0.
  - `w`: Optional. The quaternion's w; defaults to 1.
- `fromAxisAngle`: Returns a turn around an axis.
  - `axisX`: The axis's x; it needn't be of length 1.
  - `axisY`: The axis's y.
  - `axisZ`: The axis's z.
  - `radians`: The angle, counterclockwise looking down the axis toward the origin.
  - `out`: Optional. The rotation to fill; a new one when omitted.
  - returns: The rotation.

  An axis of length 0 makes the identity.
- `fromEuler`: Returns the rotation of three turns, around x, then y, then z, each around the world's axes.
  - `pitch`: The turn around x, in radians.
  - `yaw`: The turn around y, in radians.
  - `roll`: The turn around z, in radians.
  - `out`: Optional. The rotation to fill; a new one when omitted.
  - returns: The rotation.
- `fromLookRotation`: Returns the rotation that turns -z to face a direction, +y kept as near to up as it can be.
  - `forwardX`: The direction to face's x; it needn't be of length 1.
  - `forwardY`: The direction's y.
  - `forwardZ`: The direction's z.
  - `upX`: Optional. Up's x; defaults to 0.
  - `upY`: Optional. Up's y; defaults to 1.
  - `upZ`: Optional. Up's z; defaults to 0.
  - `out`: Optional. The rotation to fill; a new one when omitted.
  - returns: The rotation.

  A direction of length 0 makes the identity; an up along the direction is replaced by another axis.
- `fromBetween`: Returns the shortest turn from one direction to another.
  - `from`: The first direction; it needn't be of length 1.
  - `to`: The second direction.
  - `out`: Optional. The rotation to fill; a new one when omitted.
  - returns: The rotation.
- `fromMatrix`: Returns the rotation of a matrix, its scale ignored.
  - `matrix`: The matrix: a rotation, scale and translation.
  - `out`: Optional. The rotation to fill; a new one when omitted.
  - returns: The rotation.
- `slerp`: Returns the rotation part way from one rotation to another along the shortest arc, at an even speed (slerp).
  - `from`: The rotation at 0.
  - `to`: The rotation at 1.
  - `amount`: How far, 0 to 1; outside it the turn goes on past either end.
  - `out`: Optional. The rotation to fill; a new one when omitted. It may be from or to.
  - returns: The rotation.
- `nlerp`: Returns the rotation part way from one rotation to another along the shortest arc, faster than `slerp` but at an uneven speed (nlerp).
  - `from`: The rotation at 0.
  - `to`: The rotation at 1.
  - `amount`: How far, 0 to 1.
  - `out`: Optional. The rotation to fill; a new one when omitted. It may be from or to.
  - returns: The rotation.
- `compose`: Returns one rotation followed by another.
  - `first`: The rotation applied first.
  - `second`: The rotation applied after it.
  - `out`: Optional. The rotation to fill; a new one when omitted. It may be first or second.
  - returns: The rotation.
- `x`: Gets or sets the quaternion's x, the axis's x scaled by the sine of half the angle.
- `y`: Gets or sets the quaternion's y.
- `z`: Gets or sets the quaternion's z.
- `w`: Gets or sets the quaternion's w, the cosine of half the angle.
- `set`: Sets the quaternion's four numbers, as they are; `normalize` makes them a rotation if they aren't one.
  - `x`: The x.
  - `y`: The y.
  - `z`: The z.
  - `w`: The w.
  - returns: This rotation.
- `copyFrom`: Sets this rotation to another's.
  - `other`: The rotation to copy.
  - returns: This rotation.
- `makeIdentity`: Makes this the rotation that turns nothing.
  - returns: This rotation.
- `append`: Returns this rotation followed by another.
  - `other`: The rotation applied after this one.
  - `out`: Optional. The rotation to fill; a new one when omitted. It may be this rotation or the other.
  - returns: The rotation.
- `prepend`: Returns another rotation followed by this one.
  - `other`: The rotation applied before this one.
  - `out`: Optional. The rotation to fill; a new one when omitted. It may be this rotation or the other.
  - returns: The rotation.
- `invert`: Returns the rotation that undoes this one.
  - `out`: Optional. The rotation to fill; a new one when omitted. It may be this rotation.
  - returns: The inverse.
- `normalize`: Returns the quaternion scaled to length 1, so it is a rotation again after numbers set by hand or many compositions.
  - `out`: Optional. The rotation to fill; a new one when omitted. It may be this rotation.
  - returns: The rotation.

  A quaternion of length 0 gives the identity.
- `transformPoint`: Returns a point turned by this rotation.
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: The point's z.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The turned point.
- `toEuler`: Returns the turns around x, y and z that `fromEuler` would make this from.
  - `out`: Optional. The vector to write into: pitch in x, yaw in y, roll in z, in radians; a new one when omitted.
  - returns: The angles.

  The pitch and the roll are from -pi to pi, the yaw from -pi / 2 to pi / 2. At a yaw of a quarter turn either way, where the pitch and the roll turn around the same axis, the roll is 0 and the pitch carries the whole turn.
- `angle`: Gets the angle this rotation turns by, around whatever axis, in radians, 0 to pi.
- `toMatrix`: Returns the rotation as a matrix.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The matrix.

## Random

*class* in [`libs/math/src/helix/math/Random.hx`](../src/helix/math/Random.hx), `import helix.math.Random;`

Represents a seeded random number generator that gives the same sequence on every target.

It is xoshiro128**, its state made from the seed by SplitMix64, as raylib's rprand is, so a seed gives raylib's numbers. It is written in 32-bit integer arithmetic, so the interpreter, JS and hxcpp agree bit for bit. A simulation that must replay alike, such as a recorded run or a lockstep game, draws from one. A program keeps one generator per stream (play, and a title screen's decoration), so that drawing from one doesn't change another's sequence.

```haxe
var random = new Random(42);
var angle = random.nextRange(0, 2 * Math.PI);
var card = random.pick(deck);
```

Natively the generated C++ is compiled with `-fwrapv` on GCC and clang. Haxe's Int wraps on overflow, and C++'s int doesn't, so without it a compiler may change the sequence.

```haxe
function new(?seed:Int = 12345)
var seed(default, set):Int
var state(get, set):Array<Int>
function nextBits():Int
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
  - `seed`: Optional. The seed, read as unsigned; defaults to 12345.
- `seed`: Gets or sets the seed the sequence last started from.
  Setting it starts the sequence again from that seed. Every seed, 0 among them, gives a sequence of its own.
- `state`: Gets or sets where the sequence is now, as xoshiro128**'s four 32-bit words.
  - throws `String`: When set to anything but four words, or to four zeros, from which the sequence would be zeros alone.

  Reading it and setting it back later continues the sequence from that point, so one generator can serve two streams in turn. The words are copied both ways.
- `nextBits`: Returns the next 32 bits.
  - returns: Any whole number a 32-bit Int holds, read as unsigned where a range is made from it.
- `next`: Returns the next whole number.
  - returns: A number from 0 to 2147483647: the next 32 bits' top 31.
- `nextInt`: Returns the next whole number below a maximum.
  - `max`: The maximum, excluded.
  - returns: A number from 0 to max - 1.

  It is the next 32 bits, unsigned, modulo max, as raylib's `GetRandomValue(0, max - 1)` is. A maximum of 1 or less returns 0, a number drawn all the same.
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

*class* in [`libs/math/src/helix/math/RectPacker2D.hx`](../src/helix/math/RectPacker2D.hx), `import helix.math.RectPacker2D;`

Provides packing rectangles into an area, as stb_rect_pack 1.01 does (public domain, Sean Barrett), which raylib packs its font atlases with: a skyline, each rectangle placed as low as it goes and then as far left, the tallest first.

```haxe
static function pack(width:Int, height:Int, sizes:Array<Int>):Array<Int>
```

- `pack`: Places rectangles in an area.
  - `width`: The area's width.
  - `height`: The area's height.
  - `sizes`: Each rectangle's width and height, flat: width, height, width, height.
  - returns: Each rectangle's place, flat, in the same order: x, y, and 1 when it was placed or 0 when it didn't fit. A rectangle with no width or height is placed at 0, 0.

## Transform2D

*class* in [`libs/math/src/helix/math/Transform2D.hx`](../src/helix/math/Transform2D.hx), `import helix.math.Transform2D;`

Represents where an object is in 2 dimensions, which way it faces, and how large it is: a position, a rotation and a scale.

It faces along its own +x, so a rotation of 0 faces +x and a positive one turns toward +y, clockwise on screen where y grows downward. Moving and turning are along and around its own axes unless a method says otherwise, so a sprite, a turret or a 2D camera is steered the same way. The matrix that draws it scales, then rotates, then moves (`toMatrix`); a child's is its own composed with its parent's (`Matrix2D.compose`). It uses `Trig`, so a transform comes out the same on every target.

```haxe
var ship = new Transform2D();
ship.position.set(100, 50);
ship.lookAt(mouseX, mouseY);
ship.moveForward(speed * dt);
var model = ship.toMatrix(scratch);
```

```haxe
function new()
static function fromMatrix(matrix:Matrix2D, ?out:Transform2D):Transform2D
final position:Vector2D
var rotation:Float
final scale:Vector2D
function copyFrom(other:Transform2D):Transform2D
function makeIdentity():Transform2D
function computeForward(?out:Vector2D):Vector2D
function computeRight(?out:Vector2D):Vector2D
function moveForward(distance:Float):Transform2D
function moveRight(distance:Float):Transform2D
function moveToward(x:Float, y:Float, distance:Float, ?nearest:Float = .001):Transform2D
function rotate(radians:Float):Transform2D
function lookAt(x:Float, y:Float):Transform2D
function orbit(x:Float, y:Float, radians:Float):Transform2D
function transformPoint(x:Float, y:Float, ?out:Vector2D):Vector2D
function toMatrix(?out:Matrix2D):Matrix2D
```

- `new`: Creates a transform at the origin, facing +x, at scale 1.
- `fromMatrix`: Returns the transform a matrix places, scales and turns by.
  - `matrix`: The matrix.
  - `out`: Optional. The transform to write into; a new one when omitted.
  - returns: The transform.

  Its rotation and x scale are the matrix's x axis's, and its y scale what the y axis reaches across it, so a matrix that shears loses the shear, and one that mirrors gives a y scale less than 0.
- `position`: Gets the position, in its parent's units; the origin until changed.
- `rotation`: Gets or sets the rotation in radians; 0, facing +x, until set.
- `scale`: Gets the scale along its own axes; 1 on each until changed.
- `copyFrom`: Sets this transform to another's position, rotation and scale.
  - `other`: The transform to copy.
  - returns: This transform.
- `makeIdentity`: Puts it back at the origin, facing +x, at scale 1.
  - returns: This transform.
- `computeForward`: Returns the direction it faces, of length 1.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The direction.
- `computeRight`: Returns its right, a quarter turn from forward toward +y, of length 1.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The direction.
- `moveForward`: Moves it along the way it faces.
  - `distance`: How far, in its parent's units; less than 0 moves it back.
  - returns: This transform.
- `moveRight`: Moves it to its right.
  - `distance`: How far, in its parent's units; less than 0 moves it left.
  - returns: This transform.
- `moveToward`: Moves it toward a point or away from it, along the line between them.
  - `x`: The point's x.
  - `y`: The point's y.
  - `distance`: How far nearer, in its parent's units; less than 0 moves it away.
  - `nearest`: Optional. The least distance it keeps from the point; defaults to 0.001.
  - returns: This transform.

  It stops short of the point rather than passing through it.
- `rotate`: Turns it.
  - `radians`: The angle; more than 0 turns from +x toward +y.
  - returns: This transform.
- `lookAt`: Turns it to face a point.
  - `x`: The point's x.
  - `y`: The point's y.
  - returns: This transform.

  A point at its position leaves it as it is.
- `orbit`: Swings it around a point: its position and its rotation both, so whatever faced the point still does.
  - `x`: The point's x.
  - `y`: The point's y.
  - `radians`: The swing; more than 0 swings it from +x toward +y.
  - returns: This transform.
- `transformPoint`: Returns a point in its own space put into its parent's: scaled, rotated, then moved.
  - `x`: The point's x, in its own units.
  - `y`: The point's y.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The point, in its parent's units.
- `toMatrix`: Returns the matrix that scales, rotates and then moves, to draw it with.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The matrix.

## Transform3D

*class* in [`libs/math/src/helix/math/Transform3D.hx`](../src/helix/math/Transform3D.hx), `import helix.math.Transform3D;`

Represents where an object is in 3 dimensions, which way it faces, and how large it is: a position, a rotation and a scale.

Its own axes are its rotation's: -z is forward, +x right and +y up, as a camera looks down -z. Moving and turning are along and around those axes unless a method says otherwise, so a ship, a turret or a camera is steered the same way. The matrix that draws it scales, then rotates, then moves (`toMatrix`); a child's is its own composed with its parent's (`Matrix3D.compose`). It uses `Trig`, so a transform comes out the same on every target.

```haxe
var ship = new Transform3D();
ship.position.set(0, 0, 10);
ship.lookAt(0, 0, 0);
ship.yaw(turnSpeed * dt);
ship.moveForward(speed * dt);
var model = ship.toMatrix(scratch);
```

```haxe
function new()
static function fromMatrix(matrix:Matrix3D, ?out:Transform3D):Transform3D
final position:Vector3D
final rotation:Quaternion3D
final scale:Vector3D
function copyFrom(other:Transform3D):Transform3D
function makeIdentity():Transform3D
function computeForward(?out:Vector3D):Vector3D
function computeRight(?out:Vector3D):Vector3D
function computeUp(?out:Vector3D):Vector3D
function moveForward(distance:Float, ?inWorldPlane:Bool = false):Transform3D
function moveRight(distance:Float, ?inWorldPlane:Bool = false):Transform3D
function moveUp(distance:Float):Transform3D
function moveToward(x:Float, y:Float, z:Float, distance:Float, ?nearest:Float = .001):Transform3D
function yaw(radians:Float):Transform3D
function pitch(radians:Float, ?lock:Bool = false):Transform3D
function roll(radians:Float):Transform3D
function lookAt(x:Float, y:Float, z:Float, ?upX:Float = 0., ?upY:Float = 1., ?upZ:Float = 0.):Transform3D
function orbit(x:Float, y:Float, z:Float, yaw:Float, pitch:Float, ?lock:Bool = false):Transform3D
function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3D):Vector3D
function toMatrix(?out:Matrix3D):Matrix3D
```

- `new`: Creates a transform at the origin, facing -z, at scale 1.
- `fromMatrix`: Returns the transform of a matrix: its position, rotation and scale.
  - `matrix`: The matrix.
  - `out`: Optional. The transform to fill; a new one when omitted.
  - returns: The transform.

  A matrix that shears gives the nearest rotation (its polar decomposition's) and the scale along that rotation's axes, the shear lost. One that mirrors gives an x scale less than 0, so the way it faces and its up are kept.
- `position`: Gets the position, in its parent's units; the origin until changed.
- `rotation`: Gets the rotation; the identity until changed.
- `scale`: Gets the scale along its own axes; 1 on each until changed.
- `copyFrom`: Sets this transform to another's position, rotation and scale.
  - `other`: The transform to copy.
  - returns: This transform.
- `makeIdentity`: Puts it back at the origin, facing -z, at scale 1.
  - returns: This transform.
- `computeForward`: Returns the direction it faces, its -z, of length 1.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The direction.
- `computeRight`: Returns its right, its +x, of length 1.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The direction.
- `computeUp`: Returns its up, its +y, of length 1.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The direction.
- `moveForward`: Moves it along the way it faces.
  - `distance`: How far, in its parent's units; less than 0 moves it back.
  - `inWorldPlane`: Optional. True to move along the ground, its forward with the height taken out, as a walking camera does; defaults to false.
  - returns: This transform.
- `moveRight`: Moves it to its right.
  - `distance`: How far, in its parent's units; less than 0 moves it left.
  - `inWorldPlane`: Optional. True to move along the ground, its right with the height taken out; defaults to false.
  - returns: This transform.
- `moveUp`: Moves it along its up.
  - `distance`: How far, in its parent's units; less than 0 moves it down.
  - returns: This transform.
- `moveToward`: Moves it toward a point or away from it, along the line between them, as a camera zooms on what it orbits.
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: The point's z.
  - `distance`: How far nearer, in its parent's units; less than 0 moves it away.
  - `nearest`: Optional. The least distance it keeps from the point; defaults to 0.001.
  - returns: This transform.

  It stops short of the point rather than passing through it.
- `yaw`: Turns it left or right, around its own up.
  - `radians`: The angle; more than 0 turns it left.
  - returns: This transform.
- `pitch`: Turns it to face higher or lower, around its own right.
  - `radians`: The angle; more than 0 faces it higher.
  - `lock`: Optional. True to stop 0.001 radians short of facing straight up or down, the world's +y or -y, as a camera's look stops, so it never turns over; defaults to false. Already past that, it turns only back toward level.
  - returns: This transform.
- `roll`: Tilts it around the way it faces.
  - `radians`: The angle; more than 0 tilts it to the right.
  - returns: This transform.
- `lookAt`: Turns it to face a point.
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: The point's z.
  - `upX`: Optional. Which way up it is kept, x; defaults to 0.
  - `upY`: Optional. Up's y; defaults to 1.
  - `upZ`: Optional. Up's z; defaults to 0.
  - returns: This transform.

  A point at its position leaves it as it is.
- `orbit`: Swings it around a point: its position and its rotation both, so whatever faced the point still does, as an orbiting camera moves.
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: The point's z.
  - `yaw`: The swing left or right, in radians; more than 0 turns it to the left, as `yaw` does, which carries it to its right around the point: counterclockwise seen from above.
  - `pitch`: The swing up or down, in radians; more than 0 swings it upward.
  - `lock`: Optional. True to stop 0.001 radians short of straight above or below the point, along the world's +y or -y, so it never turns over; defaults to false.
  - returns: This transform.

  The yaw is around the world's up; the pitch around its own right.
- `transformPoint`: Returns a point in its own space put into its parent's: scaled, rotated, then moved.
  - `x`: The point's x, in its own units.
  - `y`: The point's y.
  - `z`: The point's z.
  - `out`: Optional. The vector to write into; a new one when omitted.
  - returns: The point, in its parent's units.
- `toMatrix`: Returns the matrix that scales, rotates and then moves, to draw it with.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The matrix.

## Trig

*class* in [`libs/math/src/helix/math/Trig.hx`](../src/helix/math/Trig.hx), `import helix.math.Trig;`

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

## Vector2D

*class* in [`libs/math/src/helix/math/Vector2D.hx`](../src/helix/math/Vector2D.hx), `import helix.math.Vector2D;`

Represents a vector in 2 dimensions: a position or a direction, as its user means it.

Each operation writes its result into an optional out, the last argument, and returns it. Without one it makes a new vector and leaves this one unchanged; given this vector, it changes it in place (`v.normalize(v)`). The out may be this vector or any other argument, as every input is read before anything is written, and calls chain through what each returns (`a.add(b, a).scale(2, a)`). `set` and `copyFrom` change this vector and return it. A number made from vectors (`dot`, `cross`, `distance`) is a method, a number of one (`length`, `angle`) a property.

It uses only addition, subtraction, multiplication, division and square roots, which agree on every target, and `Trig` for angles, so a vector comes out the same everywhere. Angles are radians, turning from +x toward +y. Its space is its user's.

```haxe
var velocity = Vector2D.fromAngle(heading, speed);
position.addScaled(velocity, dt, position);
var toward = target.subtract(position).normalize();
```

```haxe
function new(?x:Float = 0., ?y:Float = 0.)
static function fromAngle(radians:Float, ?length:Float = 1., ?out:Vector2D):Vector2D
static function lerp(from:Vector2D, to:Vector2D, amount:Float, ?out:Vector2D):Vector2D
var x:Float
var y:Float
function set(x:Float, y:Float):Vector2D
function copyFrom(other:Vector2D):Vector2D
function add(other:Vector2D, ?out:Vector2D):Vector2D
function subtract(other:Vector2D, ?out:Vector2D):Vector2D
function scale(factor:Float, ?out:Vector2D):Vector2D
function addScaled(other:Vector2D, factor:Float, ?out:Vector2D):Vector2D
function negate(?out:Vector2D):Vector2D
function normalize(?out:Vector2D):Vector2D
function rotate(radians:Float, ?out:Vector2D):Vector2D
var length(get, never):Float
var lengthSquared(get, never):Float
var angle(get, never):Float
function dot(other:Vector2D):Float
function cross(other:Vector2D):Float
function distance(other:Vector2D):Float
function distanceSquared(other:Vector2D):Float
function equals(other:Vector2D, ?tolerance:Float = 0.):Bool
```

- `new`: Creates a vector.
  - `x`: Optional. The x coordinate; defaults to 0.
  - `y`: Optional. The y coordinate; defaults to 0.
- `fromAngle`: Returns the vector of an angle and a length.
  - `radians`: The angle from +x toward +y.
  - `length`: Optional. The length; defaults to 1.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The vector.
- `lerp`: Returns the vector a fraction of the way from one vector to another.
  - `from`: The vector at 0.
  - `to`: The vector at 1.
  - `amount`: The fraction.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be from or to.
  - returns: The vector.

  A fraction outside 0 to 1 goes past the ends.
- `x`: Gets or sets the x coordinate.
- `y`: Gets or sets the y coordinate.
- `set`: Sets the coordinates.
  - `x`: The x coordinate.
  - `y`: The y coordinate.
  - returns: This vector.
- `copyFrom`: Sets the coordinates to another vector's.
  - `other`: The vector to copy.
  - returns: This vector.
- `add`: Returns this vector plus another.
  - `other`: The vector to add.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The sum.
- `subtract`: Returns this vector minus another.
  - `other`: The vector to subtract.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The difference.
- `scale`: Returns this vector with both coordinates multiplied by a number.
  - `factor`: The number.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The scaled vector.
- `addScaled`: Returns this vector plus another times a number, as a position moves by a velocity over a time step.
  - `other`: The vector to add.
  - `factor`: The number it is multiplied by first.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The sum.
- `negate`: Returns this vector turned the other way: both coordinates negated.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The negated vector.
- `normalize`: Returns this vector scaled to length 1, its direction kept.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The vector of length 1, or of length 0.

  A vector of length 0 stays 0.
- `rotate`: Returns this vector turned around the origin.
  - `radians`: The angle; more than 0 turns from +x toward +y.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The turned vector.
- `length`: Gets the length.
- `lengthSquared`: Gets the length squared, which is quicker to find than the length and orders vectors alike.
- `angle`: Gets the angle from +x toward +y, in radians, -pi to pi; 0 for a vector of length 0.
- `dot`: Returns the dot product with another vector: the product of their lengths and the cosine of the angle between them.
  - `other`: The other vector.
  - returns: The dot product; 0 when they are at right angles.
- `cross`: Returns the cross product with another vector, as a number: the product of their lengths and the sine of the angle from this one to the other.
  - `other`: The other vector.
  - returns: The cross product: more than 0 when the other is turned from this one toward +y, 0 when they are parallel.
- `distance`: Returns the distance to another vector, each taken as a position.
  - `other`: The other vector.
  - returns: The distance.
- `distanceSquared`: Returns the distance to another vector squared, which is quicker to find than the distance and orders distances alike.
  - `other`: The other vector.
  - returns: The distance squared.
- `equals`: Returns whether another vector is the same, within a tolerance on each coordinate.
  - `other`: The other vector.
  - `tolerance`: Optional. The most each coordinate may differ by; defaults to 0, exactly equal.
  - returns: True when every coordinate is within the tolerance.

## Vector3D

*class* in [`libs/math/src/helix/math/Vector3D.hx`](../src/helix/math/Vector3D.hx), `import helix.math.Vector3D;`

Represents a vector in 3 dimensions: a position or a direction, as its user means it.

Each operation writes its result into an optional out, the last argument, and returns it. Without one it makes a new vector and leaves this one unchanged; given this vector, it changes it in place (`v.normalize(v)`). The out may be this vector or any other argument, as every input is read before anything is written, and calls chain through what each returns (`a.add(b, a).scale(2, a)`). `set` and `copyFrom` change this vector and return it. A number made from vectors (`dot`, `distance`) is a method, a number of one (`length`) a property. `Matrix3D` keeps positions and directions apart by its methods: `transformPoint` moves a position, `transformDirection` only turns and scales a direction.

It uses only addition, subtraction, multiplication, division and square roots, which agree on every target, so a vector comes out the same everywhere. Space is right-handed with +y up, as every 3D type here.

```haxe
position.addScaled(velocity, dt, position);
var toward = target.subtract(position).normalize();
var right = forward.cross(up);
```

```haxe
function new(?x:Float = 0., ?y:Float = 0., ?z:Float = 0.)
static function lerp(from:Vector3D, to:Vector3D, amount:Float, ?out:Vector3D):Vector3D
var x:Float
var y:Float
var z:Float
function set(x:Float, y:Float, z:Float):Vector3D
function copyFrom(other:Vector3D):Vector3D
function add(other:Vector3D, ?out:Vector3D):Vector3D
function subtract(other:Vector3D, ?out:Vector3D):Vector3D
function scale(factor:Float, ?out:Vector3D):Vector3D
function addScaled(other:Vector3D, factor:Float, ?out:Vector3D):Vector3D
function negate(?out:Vector3D):Vector3D
function normalize(?out:Vector3D):Vector3D
function cross(other:Vector3D, ?out:Vector3D):Vector3D
var length(get, never):Float
var lengthSquared(get, never):Float
function dot(other:Vector3D):Float
function distance(other:Vector3D):Float
function distanceSquared(other:Vector3D):Float
function equals(other:Vector3D, ?tolerance:Float = 0.):Bool
```

- `new`: Creates a vector.
  - `x`: Optional. The x coordinate; defaults to 0.
  - `y`: Optional. The y coordinate; defaults to 0.
  - `z`: Optional. The z coordinate; defaults to 0.
- `lerp`: Returns the vector a fraction of the way from one vector to another.
  - `from`: The vector at 0.
  - `to`: The vector at 1.
  - `amount`: The fraction.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be from or to.
  - returns: The vector.

  A fraction outside 0 to 1 goes past the ends.
- `x`: Gets or sets the x coordinate.
- `y`: Gets or sets the y coordinate.
- `z`: Gets or sets the z coordinate.
- `set`: Sets the coordinates.
  - `x`: The x coordinate.
  - `y`: The y coordinate.
  - `z`: The z coordinate.
  - returns: This vector.
- `copyFrom`: Sets the coordinates to another vector's.
  - `other`: The vector to copy.
  - returns: This vector.
- `add`: Returns this vector plus another.
  - `other`: The vector to add.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The sum.
- `subtract`: Returns this vector minus another.
  - `other`: The vector to subtract.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The difference.
- `scale`: Returns this vector with every coordinate multiplied by a number.
  - `factor`: The number.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The scaled vector.
- `addScaled`: Returns this vector plus another times a number, as a position moves by a velocity over a time step.
  - `other`: The vector to add.
  - `factor`: The number it is multiplied by first.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The sum.
- `negate`: Returns this vector turned the other way: every coordinate negated.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The negated vector.
- `normalize`: Returns this vector scaled to length 1, its direction kept.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The vector of length 1, or of length 0.

  A vector of length 0 stays 0.
- `cross`: Returns the cross product with another vector: at right angles to both, as long as the area they span, by the right-hand rule (x cross y is z).
  - `other`: The other vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The cross product; of length 0 when they are parallel.
- `length`: Gets the length.
- `lengthSquared`: Gets the length squared, which is quicker to find than the length and orders vectors alike.
- `dot`: Returns the dot product with another vector: the product of their lengths and the cosine of the angle between them.
  - `other`: The other vector.
  - returns: The dot product; 0 when they are at right angles.
- `distance`: Returns the distance to another vector, each taken as a position.
  - `other`: The other vector.
  - returns: The distance.
- `distanceSquared`: Returns the distance to another vector squared, which is quicker to find than the distance and orders distances alike.
  - `other`: The other vector.
  - returns: The distance squared.
- `equals`: Returns whether another vector is the same, within a tolerance on each coordinate.
  - `other`: The other vector.
  - `tolerance`: Optional. The most each coordinate may differ by; defaults to 0, exactly equal.
  - returns: True when every coordinate is within the tolerance.
