# helix.math

[Back to the library](README.md)

## Color

*class* in [`libs/math/src/helix/math/Color.hx`](../src/helix/math/Color.hx), `import helix.math.Color;`

Provides functions for colors held as 0xAARRGGBB integers, with alpha in the top byte: their channels, hue, saturation, value and lightness, their channels as linear light, blending one over another, and mixing, tinting, brightening and contrasting them.

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
static function fromHsl(hue:Float, saturation:Float, lightness:Float, ?alpha:Int = 255):Int
static function getLightness(color:Int):Float
static function getHslSaturation(color:Int):Float
static function srgbToLinear(value:Float):Float
static function linearToSrgb(value:Float):Float
static function toLinear(color:Int, ?out:Vector4):Vector4
static function fromLinear(red:Float, green:Float, blue:Float, ?alpha:Float = 1.):Int
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
- `fromHsl`: Returns the color of a hue, saturation and lightness, opaque or with an alpha.
  - `hue`: The hue, in degrees: 0 red, 120 green, 240 blue; any angle, wrapped.
  - `saturation`: The saturation, 0 (gray) to 1, clamped.
  - `lightness`: The lightness, 0 (black) to 1 (white), clamped. 0.5 is the pure hue.
  - `alpha`: Optional. The alpha channel, 0 to 255; defaults to 255.
  - returns: The color, its channels rounded.
- `getLightness`: Returns a color's lightness: halfway between its brightest and darkest channels.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The lightness, 0 (black) to 1 (white).
- `getHslSaturation`: Returns a color's saturation as `fromHsl` accepts it. `getSaturation` returns the saturation `fromHsv` accepts.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The saturation, 0 to 1: 0 for a gray, black or white.
- `srgbToLinear`: Returns a channel of an sRGB color as linear light.
  - `value`: The channel as stored, 0 to 1.
  - returns: The linear value, 0 to 1.
- `linearToSrgb`: Returns a channel of linear light as an sRGB color stores it.
  - `value`: The linear value, 0 to 1.
  - returns: The channel as stored, 0 to 1.
- `toLinear`: Returns a color as linear light, for a shader that lights in linear light.
  - `color`: The color, as 0xAARRGGBB, sRGB.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The red, green and blue as linear light and the alpha, each 0 to 1.
- `fromLinear`: Returns the color of linear light.
  - `red`: The red, linear, 0 to 1, clamped.
  - `green`: The green, linear, 0 to 1, clamped.
  - `blue`: The blue, linear, 0 to 1, clamped.
  - `alpha`: Optional. The alpha, 0 to 1, clamped; defaults to 1.
  - returns: The color, as 0xAARRGGBB, sRGB, its channels rounded.
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

A curve is made by `through`, `bezier` or `polyline`, and its points are fixed once made. It is asked where it is and which way it heads at a parameter t, from 0 at its start to 1 at its end, and how long it is. Equal steps of t are not equal distances along it: `getParameterAtDistance` finds the t at a distance, for moving along it at a steady speed. Points are passed flat, x, y or x, y, z each.

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

## Ease

*abstract* in [`libs/math/src/helix/math/Ease.hx`](../src/helix/math/Ease.hx), `import helix.math.Ease;`

Represents an easing curve: the shape a tween moves by, or any move from 0 to 1. `Interpolate`'s thirty curves are each one (`Ease.outCubic` is `Interpolate.easeOutCubic`), `Ease.linear` is a straight line, and `Ease.of` makes one of a program's own function.

```haxe
var ease = Ease.outBack;
// each frame
scale = Interpolate.lerp(1, 2, ease.at(elapsed / 0.5));
```

```haxe
static final linear(default, null):Ease
static final inSine(default, null):Ease
static final outSine(default, null):Ease
static final inOutSine(default, null):Ease
static final inQuad(default, null):Ease
static final outQuad(default, null):Ease
static final inOutQuad(default, null):Ease
static final inCubic(default, null):Ease
static final outCubic(default, null):Ease
static final inOutCubic(default, null):Ease
static final inQuart(default, null):Ease
static final outQuart(default, null):Ease
static final inOutQuart(default, null):Ease
static final inQuint(default, null):Ease
static final outQuint(default, null):Ease
static final inOutQuint(default, null):Ease
static final inExpo(default, null):Ease
static final outExpo(default, null):Ease
static final inOutExpo(default, null):Ease
static final inCirc(default, null):Ease
static final outCirc(default, null):Ease
static final inOutCirc(default, null):Ease
static final inBack(default, null):Ease
static final outBack(default, null):Ease
static final inOutBack(default, null):Ease
static final inElastic(default, null):Ease
static final outElastic(default, null):Ease
static final inOutElastic(default, null):Ease
static final inBounce(default, null):Ease
static final outBounce(default, null):Ease
static final inOutBounce(default, null):Ease
static function of(curve:Float -> Float):Ease
function at(t:Float):Float
```

- `linear`: Gets the straight line: a fraction unchanged.
- `inSine`: Gets the curve slow at the start, a quarter sine wave: `Interpolate.easeInSine`.
- `outSine`: Gets the curve slow at the end, a quarter sine wave: `Interpolate.easeOutSine`.
- `inOutSine`: Gets the curve slow at both ends, a quarter sine wave: `Interpolate.easeInOutSine`.
- `inQuad`: Gets the curve slow at the start, t squared: `Interpolate.easeInQuad`.
- `outQuad`: Gets the curve slow at the end, t squared: `Interpolate.easeOutQuad`.
- `inOutQuad`: Gets the curve slow at both ends, t squared: `Interpolate.easeInOutQuad`.
- `inCubic`: Gets the curve slow at the start, t cubed: `Interpolate.easeInCubic`.
- `outCubic`: Gets the curve slow at the end, t cubed: `Interpolate.easeOutCubic`.
- `inOutCubic`: Gets the curve slow at both ends, t cubed: `Interpolate.easeInOutCubic`.
- `inQuart`: Gets the curve slow at the start, t to the fourth: `Interpolate.easeInQuart`.
- `outQuart`: Gets the curve slow at the end, t to the fourth: `Interpolate.easeOutQuart`.
- `inOutQuart`: Gets the curve slow at both ends, t to the fourth: `Interpolate.easeInOutQuart`.
- `inQuint`: Gets the curve slow at the start, t to the fifth: `Interpolate.easeInQuint`.
- `outQuint`: Gets the curve slow at the end, t to the fifth: `Interpolate.easeOutQuint`.
- `inOutQuint`: Gets the curve slow at both ends, t to the fifth: `Interpolate.easeInOutQuint`.
- `inExpo`: Gets the curve slow at the start, two to the power of t: `Interpolate.easeInExpo`.
- `outExpo`: Gets the curve slow at the end, two to the power of t: `Interpolate.easeOutExpo`.
- `inOutExpo`: Gets the curve slow at both ends, two to the power of t: `Interpolate.easeInOutExpo`.
- `inCirc`: Gets the curve slow at the start, a quarter circle: `Interpolate.easeInCirc`.
- `outCirc`: Gets the curve slow at the end, a quarter circle: `Interpolate.easeOutCirc`.
- `inOutCirc`: Gets the curve slow at both ends, a quarter circle: `Interpolate.easeInOutCirc`.
- `inBack`: Gets the curve slow at the start, pulling back a tenth before it goes: `Interpolate.easeInBack`.
- `outBack`: Gets the curve slow at the end, pulling back a tenth before it goes: `Interpolate.easeOutBack`.
- `inOutBack`: Gets the curve slow at both ends, pulling back a tenth before it goes: `Interpolate.easeInOutBack`.
- `inElastic`: Gets the curve slow at the start, springing past its end and back: `Interpolate.easeInElastic`.
- `outElastic`: Gets the curve slow at the end, springing past its end and back: `Interpolate.easeOutElastic`.
- `inOutElastic`: Gets the curve slow at both ends, springing past its end and back: `Interpolate.easeInOutElastic`.
- `inBounce`: Gets the curve slow at the start, bouncing to rest: `Interpolate.easeInBounce`.
- `outBounce`: Gets the curve slow at the end, bouncing to rest: `Interpolate.easeOutBounce`.
- `inOutBounce`: Gets the curve slow at both ends, bouncing to rest: `Interpolate.easeInOutBounce`.
- `of`: Returns a curve of a program's own function.
  - `curve`: The function: it accepts a fraction from 0 to 1 and returns the eased fraction, 0 at 0 and 1 at 1.
  - returns: The curve.

  On hxcpp each `at` of the returned curve allocates, as hxcpp boxes a number passed to a function value. The curves named here allocate nothing.
- `at`: Returns a fraction eased along this curve.
  - `t`: The fraction, 0 to 1.
  - returns: The eased fraction, 0 at 0 and 1 at 1.

## EulerOrder

*abstract* in [`libs/math/src/helix/math/EulerOrder.hx`](../src/helix/math/EulerOrder.hx), `import helix.math.EulerOrder;`

Specifies the order three turns around x, y and z are made in. Each order is named as raylib, three.js and glm name it: by the product of the three rotation matrices, so the last letter's turn is made first. Every turn is around the world's axes.

- `EulerOrder.ZYX`: Around x first, then y, then z.
- `EulerOrder.XYZ`: Around z first, then y, then x.
- `EulerOrder.YXZ`: Around z first, then x, then y.
- `EulerOrder.ZXY`: Around y first, then x, then z.
- `EulerOrder.YZX`: Around x first, then z, then y.
- `EulerOrder.XZY`: Around y first, then z, then x.

## Interpolate

*class* in [`libs/math/src/helix/math/Interpolate.hx`](../src/helix/math/Interpolate.hx), `import helix.math.Interpolate;`

Provides interpolation: between numbers and angles, along spline pieces, easing curves, smoothing, stepping and easing toward a target. `MathTools` clamps, wraps and snaps a number.

The easing curves are Robert Penner's, each family in three: `easeIn...` starts slow, `easeOut...` ends slow, `easeInOut...` does both. Each accepts a fraction from 0 to 1 and returns 0 at 0 and 1 at 1; back and elastic go past 0 and 1 on their way. The sine family uses `Trig`, so it is the same on every target; the expo and elastic families use `Math.pow`, whose last bit can differ between targets. `Ease` has each curve as a value (`Ease.outCubic`), for a tween or another call to accept.

`damp` and `dampAngle` use `Math.exp`, whose last bit can differ between targets, so a simulation that must replay alike on every target uses `moveToward` or its own integer math instead. Angles are in radians.

```haxe
static function lerp(a:Float, b:Float, t:Float):Float
static function inverseLerp(a:Float, b:Float, value:Float):Float
static function remap(value:Float, fromA:Float, fromB:Float, toA:Float, toB:Float):Float
static function smoothStep(t:Float):Float
static function smootherStep(t:Float):Float
static function lerpAngle(a:Float, b:Float, t:Float):Float
static function moveToward(value:Float, target:Float, step:Float):Float
static function rotateToward(angle:Float, target:Float, step:Float):Float
static function damp(value:Float, target:Float, rate:Float, dt:Float):Float
static function dampAngle(value:Float, target:Float, rate:Float, dt:Float):Float
static function hermite(from:Float, fromTangent:Float, to:Float, toTangent:Float, t:Float):Float
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
- `smoothStep`: Returns a fraction clamped to 0 to 1 and smoothed, slow at both ends.
  - `t`: The fraction.
  - returns: 3t² - 2t³ of the clamped fraction.
- `smootherStep`: Returns a fraction clamped to 0 to 1 and smoothed more than `smoothStep` smooths: speed and acceleration are 0 at both ends.
  - `t`: The fraction.
  - returns: 6t⁵ - 15t⁴ + 10t³ of the clamped fraction.
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
- `rotateToward`: Returns an angle turned toward a target by at most a step, the short way round.
  - `angle`: The angle, in radians.
  - `target`: The angle to turn toward, in radians.
  - `step`: The most the angle turns, in radians.
  - returns: The turned angle, in radians, not wrapped.

  The angle reaches the target's direction and stops there. A step of 0 or less leaves the angle unchanged.
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
- `hermite`: Returns the value on a curve from one value to another, the curve leaving and arriving at two slopes (a cubic Hermite curve), on one axis.
  - `from`: The value at 0.
  - `fromTangent`: The slope leaving `from`.
  - `to`: The value at 1.
  - `toTangent`: The slope arriving at `to`.
  - `t`: How far along, 0 to 1.
  - returns: The value.
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

## MathTools

*class* in [`libs/math/src/helix/math/MathTools.hx`](../src/helix/math/MathTools.hx), `import helix.math.MathTools;`

Provides what Haxe's `Math` lacks for a number: clamping, wrapping, snapping, comparing, the least, greatest and size of whole numbers, powers of two, and degrees and radians.

Each function accepts the number first, so a file with `using helix.math.MathTools;` calls each on the number. `clamp`, `wrap` and `snap` return an `Int` for `Int`s and a `Float` for any other numbers.

```haxe
using helix.math.MathTools;

var volume = level.clamp(0, 1);
var column = index.clamp(0, 7); // an Int, as index is
var facing = velocity.x.sign(); // -1, 0 or 1
var radians = degrees.toRadians();
```

```haxe
static function clamp(value:Int, min:Int, max:Int):Int
static function clamp(value:Float, min:Float, max:Float):Float
static function clamp01(value:Float):Float
static function wrap(value:Int, min:Int, max:Int):Int
static function wrap(value:Float, min:Float, max:Float):Float
static function wrapAngle(angle:Float):Float
static function snap(value:Int, step:Int):Int
static function snap(value:Float, step:Float):Float
static function pingPong(value:Float, length:Float):Float
static function sign(value:Float):Int
static function equals(a:Float, b:Float, tolerance:Float):Bool
static function min(a:Int, b:Int):Int
static function max(a:Int, b:Int):Int
static function abs(value:Int):Int
static function isPowerOfTwo(value:Int):Bool
static function nextPowerOfTwo(value:Int):Int
static function toRadians(degrees:Float):Float
static function toDegrees(radians:Float):Float
```

- `clamp`: Returns a whole number clamped to a range.
  - `value`: The number.
  - `min`: The lower bound.
  - `max`: The upper bound.
  - returns: The number, or the bound the number is past.

  Bounds provided in the wrong order are swapped.
- `clamp`: Returns a value clamped to a range.
  - `value`: The value.
  - `min`: The lower bound.
  - `max`: The upper bound.
  - returns: The value, or the bound the value is past.

  Bounds provided in the wrong order are swapped.
- `clamp01`: Returns a value clamped to 0 to 1.
  - `value`: The value.
  - returns: The value, 0 below 0, or 1 above 1.
- `wrap`: Returns a whole number wrapped around into a range, as a column wraps around a row.
  - `value`: The number.
  - `min`: The range's start.
  - `max`: The range's end.
  - returns: The number, from min up to max, max excluded.

  Bounds provided in the wrong order are swapped. A range of no size returns `min`.
- `wrap`: Returns a value wrapped around into a range, as an angle wraps around a turn.
  - `value`: The value.
  - `min`: The range's start.
  - `max`: The range's end.
  - returns: The value, from min up to max.

  Bounds provided in the wrong order are swapped. A range of no size returns `min`.
- `wrapAngle`: Returns an angle wrapped to -π up to π.
  - `angle`: The angle, in radians.
  - returns: The same direction, from -π, included, to π, excluded.
- `snap`: Returns a whole number moved to the nearest multiple of a step, as a place snaps to a grid of tiles.
  - `value`: The number.
  - `step`: The step. 0 or less leaves the number as it is.
  - returns: The snapped number.

  A number halfway between two multiples moves to the greater.
- `snap`: Returns a value moved to the nearest multiple of a step, as a slider snaps to its marks.
  - `value`: The value.
  - `step`: The step. 0 or less leaves the value as it is.
  - returns: The snapped value.

  A value halfway between two multiples moves to the greater.
- `pingPong`: Returns a value bounced back and forth between 0 and a length, as a ball between two walls.
  - `value`: The value, of any size.
  - `length`: The far wall. 0 or less returns 0.
  - returns: The bounced value, 0 to length.
- `sign`: Returns a value's sign.
  - `value`: The value.
  - returns: 1 above 0, -1 below 0, and 0 at 0 and for NaN.
- `equals`: Returns whether two values are equal but for rounding.
  - `a`: One value.
  - `b`: The other value.
  - `tolerance`: The most the values may differ by, multiplied by the larger value's size when that size is over 1.
  - returns: True when the values are that close.
- `min`: Returns the lesser of two whole numbers, as an `Int`. `Math.min` returns a `Float`.
  - `a`: One number.
  - `b`: The other number.
  - returns: The lesser.
- `max`: Returns the greater of two whole numbers, as an `Int`. `Math.max` returns a `Float`.
  - `a`: One number.
  - `b`: The other number.
  - returns: The greater.
- `abs`: Returns a whole number's size, as an `Int`. `Math.abs` returns a `Float`.
  - `value`: The number.
  - returns: The number without its sign.
- `isPowerOfTwo`: Returns whether a whole number is a power of two: 1, 2, 4, 8 and on.
  - `value`: The number.
  - returns: True for a power of two. False for 0 and for a number below 0.
- `nextPowerOfTwo`: Returns the least power of two that isn't below a whole number, as a texture's side is rounded up.
  - `value`: The number.
  - returns: The power of two: the number itself when the number is one, 1 for a number below 1, and 1,073,741,824 at most.
- `toRadians`: Returns an angle in degrees as radians.
  - `degrees`: The angle, in degrees.
  - returns: The angle, in radians.
- `toDegrees`: Returns an angle in radians as degrees.
  - `radians`: The angle, in radians.
  - returns: The angle, in degrees.

## Matrix3

*class* in [`libs/math/src/helix/math/Matrix3.hx`](../src/helix/math/Matrix3.hx), `import helix.math.Matrix3;`

Represents a 2D affine matrix: moving, turning, scaling and shearing points in 2 dimensions.

It is the 3 x 3 matrix whose last row is 0, 0, 1, kept as its six other numbers as a canvas's `setTransform` and Flash's `Matrix` keep them: a point (x, y) goes to (a x + c y + tx, b x + d y + ty). Its operations follow helix-math's out rule: each writes into an optional out, last, and returns it; omitted, it makes a new matrix; provided the matrix itself, it works in place. Rotations use `Trig`, so a matrix comes out the same on every target. Angles are radians, a positive one turning from +x toward +y, clockwise on screen where y grows downward.

```haxe
var model = Matrix3.fromScale(2, 2);
model.appendRotation(angle, model).appendTranslation(x, y, model);
var onScreen = model.transformPoint(0, 0);
```

```haxe
function new()
static function fromTranslation(x:Float, y:Float, ?out:Matrix3):Matrix3
static function fromScale(x:Float, y:Float, ?out:Matrix3):Matrix3
static function fromRotation(radians:Float, ?out:Matrix3):Matrix3
static function compose(first:Matrix3, second:Matrix3, ?out:Matrix3):Matrix3
var a:Float
var b:Float
var c:Float
var d:Float
var tx:Float
var ty:Float
function set(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Matrix3
function copyFrom(other:Matrix3):Matrix3
function makeIdentity():Matrix3
function append(other:Matrix3, ?out:Matrix3):Matrix3
function prepend(other:Matrix3, ?out:Matrix3):Matrix3
function appendTranslation(x:Float, y:Float, ?out:Matrix3):Matrix3
function appendScale(x:Float, y:Float, ?out:Matrix3):Matrix3
function appendRotation(radians:Float, ?out:Matrix3):Matrix3
function invert(?out:Matrix3):Null<Matrix3>
function transformPoint(x:Float, y:Float, ?out:Vector2):Vector2
function transformDirection(x:Float, y:Float, ?out:Vector2):Vector2
function toMatrix4(?out:Matrix4):Matrix4
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
- `toMatrix4`: Returns the matrix as a 4 x 4 one acting on x and y alone, as a shader accepts a 2D view.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The matrix.

## Matrix4

*class* in [`libs/math/src/helix/math/Matrix4.hx`](../src/helix/math/Matrix4.hx), `import helix.math.Matrix4;`

Represents a 4 x 4 matrix transforming points in 3 dimensions: moving, turning, scaling and projecting them.

It acts on column vectors, and its 16 numbers are `m0` to `m15` by columns, as GPUs read them: row r of column c is number c * 4 + r, and the translation is `m12`, `m13` and `m14`. `toArray` returns the 16 numbers a shader reads. A static `fromX` makes a matrix of one kind, and `compose` one transform followed by another. Each of those, and each operation on a matrix (`append`, `invert`, `transpose`, `transformPoint`), writes its result into an optional out, the last argument, and returns it. Without one it makes a new result and leaves this matrix unchanged; with this matrix as the out, it works in place (`m.transpose(m)`). The out may be this matrix or any other argument, and none of them allocates when provided one, so a caller can reuse one matrix every frame and chain calls through what each returns. `makeIdentity` and `copyFrom` change this matrix and return it. Rotations use `Trig`, so a matrix comes out the same on every target. The formulas are raymath's (raylib 5.5, zlib, `vendor/raylib/LICENSE`).

```haxe
var model = Matrix4.fromScale(2, 2, 2);
model.appendRotation(0, 1, 0, angle, model).appendTranslation(x, 0, z, model);
var mvp = Matrix4.compose(model, view).append(projection);
```

```haxe
function new()
static function fromArray(values:Array<Float>, ?offset:Int = 0, ?out:Matrix4):Matrix4
static function fromTranslation(x:Float, y:Float, z:Float, ?out:Matrix4):Matrix4
static function fromScale(x:Float, y:Float, z:Float, ?out:Matrix4):Matrix4
static function fromRotation(axisX:Float, axisY:Float, axisZ:Float, radians:Float, ?out:Matrix4):Matrix4
static function fromQuaternion(x:Float, y:Float, z:Float, w:Float, ?out:Matrix4):Matrix4
static function fromEuler(pitch:Float, yaw:Float, roll:Float, ?order:EulerOrder = EulerOrder.ZYX, ?out:Matrix4):Matrix4
static function fromLookAt(eyeX:Float, eyeY:Float, eyeZ:Float, targetX:Float, targetY:Float, targetZ:Float, upX:Float, upY:Float, upZ:Float, ?out:Matrix4):Matrix4
static function fromPerspective(fovY:Float, aspect:Float, near:Float, far:Float, ?out:Matrix4):Matrix4
static function fromOrthographic(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float, ?out:Matrix4):Matrix4
static function fromFrustum(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float, ?out:Matrix4):Matrix4
static function compose(first:Matrix4, second:Matrix4, ?out:Matrix4):Matrix4
var m0(get, set):Float
var m1(get, set):Float
var m2(get, set):Float
var m3(get, set):Float
var m4(get, set):Float
var m5(get, set):Float
var m6(get, set):Float
var m7(get, set):Float
var m8(get, set):Float
var m9(get, set):Float
var m10(get, set):Float
var m11(get, set):Float
var m12(get, set):Float
var m13(get, set):Float
var m14(get, set):Float
var m15(get, set):Float
var determinant(get, never):Float
var trace(get, never):Float
function makeIdentity():Matrix4
function copyFrom(other:Matrix4):Matrix4
function append(other:Matrix4, ?out:Matrix4):Matrix4
function prepend(other:Matrix4, ?out:Matrix4):Matrix4
function appendTranslation(x:Float, y:Float, z:Float, ?out:Matrix4):Matrix4
function appendScale(x:Float, y:Float, z:Float, ?out:Matrix4):Matrix4
function appendRotation(axisX:Float, axisY:Float, axisZ:Float, radians:Float, ?out:Matrix4):Matrix4
function invert(?out:Matrix4):Null<Matrix4>
function transpose(?out:Matrix4):Matrix4
function add(other:Matrix4, ?out:Matrix4):Matrix4
function subtract(other:Matrix4, ?out:Matrix4):Matrix4
function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3):Vector3
function transformDirection(x:Float, y:Float, z:Float, ?out:Vector3):Vector3
function projectPoint(x:Float, y:Float, z:Float, ?out:Vector3):Vector3
function toArray(?out:Array<Float>, ?offset:Int = 0):Array<Float>
function getTranslation(?out:Vector3):Vector3
function getRotation(?out:Quaternion):Quaternion
function getScale(?out:Vector3):Vector3
function decompose(translation:Vector3, rotation:Quaternion, scale:Vector3):Void
```

- `new`: Creates the identity matrix.
- `fromArray`: Returns the matrix of 16 numbers of an array, by columns.
  - `values`: The array.
  - `offset`: Optional. Where in the array the first of the 16 numbers is; defaults to 0.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
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
- `fromQuaternion`: Returns the rotation a quaternion (x, y, z, w) describes.
  - `x`: The quaternion's x.
  - `y`: Its y.
  - `z`: Its z.
  - `w`: Its w.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
- `fromEuler`: Returns the rotation of three turns around x, y and z, each around the world's axes. `Quaternion.fromEuler` returns the same rotation as a quaternion.
  - `pitch`: The turn around x, in radians.
  - `yaw`: The turn around y, in radians.
  - `roll`: The turn around z, in radians.
  - `order`: Optional. The order the turns are made in; defaults to `ZYX`: around x, then y, then z.
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
- `fromPerspective`: Returns a perspective projection into GL's clip space (depth -1 to 1), which every helix-platform adapter uses.
  - `fovY`: The field of view, top to bottom, in radians.
  - `aspect`: Width over height.
  - `near`: The near plane's distance.
  - `far`: The far plane's distance.
  - `out`: Optional. The matrix to fill; a new one when omitted.
  - returns: The matrix.
- `fromOrthographic`: Returns an orthographic projection into GL's clip space (depth -1 to 1), which every helix-platform adapter uses.
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
- `m0`: Gets or sets the number in row 0 of column 0.
- `m1`: Gets or sets the number in row 1 of column 0.
- `m2`: Gets or sets the number in row 2 of column 0.
- `m3`: Gets or sets the number in row 3 of column 0.
- `m4`: Gets or sets the number in row 0 of column 1.
- `m5`: Gets or sets the number in row 1 of column 1.
- `m6`: Gets or sets the number in row 2 of column 1.
- `m7`: Gets or sets the number in row 3 of column 1.
- `m8`: Gets or sets the number in row 0 of column 2.
- `m9`: Gets or sets the number in row 1 of column 2.
- `m10`: Gets or sets the number in row 2 of column 2.
- `m11`: Gets or sets the number in row 3 of column 2.
- `m12`: Gets or sets the number in row 0 of column 3: the translation's x.
- `m13`: Gets or sets the number in row 1 of column 3: the translation's y.
- `m14`: Gets or sets the number in row 2 of column 3: the translation's z.
- `m15`: Gets or sets the number in row 3 of column 3.
- `determinant`: Gets this matrix's determinant: 0 when the matrix has no inverse.
- `trace`: Gets this matrix's trace: the sum of the four numbers on its diagonal.
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
- `add`: Returns this matrix plus another, number by number.
  - `other`: The matrix to add.
  - `out`: Optional. The matrix to fill; a new one when omitted. It may be this matrix or the other.
  - returns: The sum.
- `subtract`: Returns this matrix less another, number by number.
  - `other`: The matrix to subtract.
  - `out`: Optional. The matrix to fill; a new one when omitted. It may be this matrix or the other.
  - returns: The difference.
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
- `projectPoint`: Computes where a point goes through a projection: transformed, then divided by the w the matrix produces for the point.
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: The point's z.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The point.
- `toArray`: Returns the matrix's 16 numbers as an array, by columns, as a shader reads them.
  - `out`: Optional. The array to fill; a new one when omitted.
  - `offset`: Optional. Where in the array the first of the 16 numbers goes; defaults to 0.
  - returns: The array.
- `getTranslation`: Returns the matrix's translation.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The translation.
- `getRotation`: Returns the matrix's rotation, its scale and translation left out.
  - `out`: Optional. The rotation to fill; a new one when omitted.
  - returns: The rotation.

  A matrix that mirrors is treated as mirrored along x, so the way it faces and its up are kept. See `decompose` for a matrix that shears.
- `getScale`: Returns the matrix's scale: the lengths of its x, y and z axes.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The scale along x, y and z.

  A matrix that mirrors produces an x scale less than 0. See `decompose` for a matrix that shears.
- `decompose`: Decomposes this transform into a translation, a rotation and a scale.
  - `translation`: Filled with the translation.
  - `rotation`: Filled with the rotation.
  - `scale`: Filled with the scale along x, y and z.

  A matrix that shears produces the nearest rotation (its polar decomposition's) and the scale along that rotation's axes, the shear lost. One that mirrors produces an x scale less than 0, so the way it faces and its up are kept.

## Noise

*class* in [`libs/math/src/helix/math/Noise.hx`](../src/helix/math/Noise.hx), `import helix.math.Noise;`

Provides smooth noise: a number for each point that changes little between near points, the same on every target.

```haxe
var height = Noise.fractal(x * .01, z * .01) * 40; // terrain: hills with detail
var sway = Noise.perlin(time * .5, 0) * 3; // a camera's shake or a flame's flicker
var cloud = Noise.simplex(x * .02, y * .02, time); // a moving cloud layer
var crack = Noise.cellular(x * .1, y * .1); // cells, as stone or water caustics
```

Natively the generated C++ is compiled with `-ffp-contract=off` on GCC and clang, so that fused multiply-adds don't change the rounding.

```haxe
static function perlin(x:Float, y:Float, ?z:Float = 0., ?seed:Int = 0):Float
static function simplex(x:Float, y:Float, ?z:Float = 0., ?seed:Int = 0):Float
static function cellular(x:Float, y:Float, ?z:Float = 0., ?seed:Int = 0):Float
static function fractal(x:Float, y:Float, ?z:Float = 0., ?octaves:Int = 6, ?lacunarity:Float = 2., ?gain:Float = .5, ?seed:Int = 0):Float
```

- `perlin`: Returns Perlin noise at a point.
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: Optional. The point's z; defaults to 0, a 2D slice.
  - `seed`: Optional. Picks one noise of 256; defaults to 0.
  - returns: The noise, about -1 to 1.

  The noise is 0 at a point with whole-number coordinates. The noise repeats every 256 along each axis.
- `simplex`: Returns simplex noise at a point. Simplex noise shows less of the grid's directions than `perlin` does.
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: Optional. The point's z; defaults to 0, a 2D slice.
  - `seed`: Optional. Picks one noise of 256; defaults to 0.
  - returns: The noise, about -1 to 1.

  The noise repeats every 768 along each axis.
- `cellular`: Returns cellular (Worley) noise at a point: the distance to the nearest of points scattered one to a unit cell.
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: Optional. The point's z; defaults to 0, a 2D slice.
  - `seed`: Optional. Picks one scatter of 256; defaults to 0.
  - returns: The distance, 0 at a scattered point.

  The scatter repeats every 256 along each axis.
- `fractal`: Returns Perlin noise summed over octaves, each finer and fainter than the last (fractal Brownian motion).
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: Optional. The point's z; defaults to 0, a 2D slice.
  - `octaves`: Optional. How many layers are summed; defaults to 6.
  - `lacunarity`: Optional. How much finer each octave is than the last; defaults to 2.
  - `gain`: Optional. How much fainter each octave is than the last; defaults to 0.5.
  - `seed`: Optional. Picks one noise of 256; defaults to 0.
  - returns: The sum: mostly within -1 to 1 at the default gain, and at most the octaves' sizes added up, 1.97 at the defaults.

## Quaternion

*class* in [`libs/math/src/helix/math/Quaternion.hx`](../src/helix/math/Quaternion.hx), `import helix.math.Quaternion;`

Represents a rotation in 3 dimensions, as a unit quaternion.

Two rotations blend along the shortest arc (`slerp`), which matrices can't do, so an animation's rotations are kept as these and turned into a matrix to draw. A static `fromX` makes a rotation, and `slerp`, `nlerp` and `compose` make one from others. Each of those, and each operation on a rotation (`append`, `invert`, `normalize`, `transformPoint`, `toMatrix`), writes its result into an optional out, the last argument, and returns it. Without one it makes a new result and leaves this rotation unchanged; provided this rotation, it works in place (`q.normalize(q)`). The out may be this rotation or any other argument, and calls chain through what each returns. `set`, `copyFrom` and `makeIdentity` change this rotation and return it. It uses `Trig`, so a rotation comes out the same on every target. Space is right-handed with +y up, as every 3D type here.

```haxe
var turn = Quaternion.fromAxisAngle(0, 1, 0, Math.PI / 2);
var halfway = Quaternion.slerp(from, turn, .5);
var facing = turn.transformPoint(0, 0, -1);
```

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?x:Float, ?y:Float, ?z:Float, ?w:Float}
```

```haxe
static function fromAxisAngle(axisX:Float, axisY:Float, axisZ:Float, radians:Float, ?out:Quaternion):Quaternion
static function fromEuler(pitch:Float, yaw:Float, roll:Float, ?order:EulerOrder = EulerOrder.ZYX, ?out:Quaternion):Quaternion = { order : EulerOrder.ZYX }
static function fromLookRotation(forwardX:Float, forwardY:Float, forwardZ:Float, ?upX:Float = 0., ?upY:Float = 1., ?upZ:Float = 0., ?out:Quaternion):Quaternion = { upZ : 0., upY : 1., upX : 0. }
static function fromBetween(from:Vector3, to:Vector3, ?out:Quaternion):Quaternion
static function fromRotationMatrix(matrix:Matrix4, ?out:Quaternion):Quaternion
static function slerp(from:Quaternion, to:Quaternion, amount:Float, ?out:Quaternion):Quaternion
static function nlerp(from:Quaternion, to:Quaternion, amount:Float, ?out:Quaternion):Quaternion
static function hermite(from:Quaternion, fromTangent:Quaternion, to:Quaternion, toTangent:Quaternion, amount:Float, ?out:Quaternion):Quaternion
static function compose(first:Quaternion, second:Quaternion, ?out:Quaternion):Quaternion
var x:Float
var y:Float
var z:Float
var w:Float
function set(x:Float, y:Float, z:Float, w:Float):Quaternion
function copyFrom(other:Quaternion):Quaternion
function copy(?out:Quaternion):Quaternion
function makeIdentity():Quaternion
function append(other:Quaternion, ?out:Quaternion):Quaternion
function prepend(other:Quaternion, ?out:Quaternion):Quaternion
function invert(?out:Quaternion):Quaternion
function normalize(?out:Quaternion):Quaternion
function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3):Vector3
function toEuler(?order:EulerOrder = EulerOrder.ZYX, ?out:Vector3):Vector3 = { order : EulerOrder.ZYX }
var angle(get, never):Float
function getAxis(?out:Vector3):Vector3
var length(get, never):Float
function equals(other:Quaternion, ?tolerance:Float = 0.):Bool = { tolerance : 0. }
function dot(other:Quaternion):Float
function angleTo(other:Quaternion):Float
function rotateToward(target:Quaternion, step:Float, ?out:Quaternion):Quaternion
function toMatrix(?out:Matrix4):Matrix4
```

- `fromAxisAngle`: Returns a turn around an axis.
  - `axisX`: The axis's x; it needn't be of length 1.
  - `axisY`: The axis's y.
  - `axisZ`: The axis's z.
  - `radians`: The angle, counterclockwise looking down the axis toward the origin.
  - `out`: Optional. The rotation to fill; a new one when omitted.
  - returns: The rotation.

  An axis of length 0 makes the identity.
- `fromEuler`: Returns the rotation of three turns around x, y and z, each around the world's axes.
  - `pitch`: The turn around x, in radians.
  - `yaw`: The turn around y, in radians.
  - `roll`: The turn around z, in radians.
  - `order`: Optional. The order the turns are made in; defaults to `ZYX`: around x, then y, then z.
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

  Opposite directions produce half a turn around an axis square to them. A direction of length 0 produces the identity.
- `fromRotationMatrix`: Returns the rotation of a matrix that is a rotation alone.
  - `matrix`: The rotation matrix: its three axes of length 1 and square to one another.
  - `out`: Optional. The rotation to fill; a new one when omitted.
  - returns: The rotation.

  A matrix with a scale or a shear makes a quaternion that isn't a rotation. See `Matrix4.getRotation` for a matrix with a scale.
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
- `hermite`: Returns the rotation on a curve from one rotation to another, the curve leaving and arriving along two tangents (a cubic Hermite curve, as glTF's CUBICSPLINE animation uses).
  - `from`: The rotation at 0.
  - `fromTangent`: The tangent leaving `from`, four numbers held in a quaternion.
  - `to`: The rotation at 1.
  - `toTangent`: The tangent arriving at `to`, four numbers held in a quaternion.
  - `amount`: How far along, 0 to 1.
  - `out`: Optional. The rotation to fill; a new one when omitted. It may be any of the four.
  - returns: The rotation, of length 1.
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
- `copy`: Returns a separate rotation with this one's quaternion.
  - `out`: Optional. The rotation to fill; a new one when omitted.
  - returns: The copy.
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

  A quaternion of length 0 produces the identity.
- `transformPoint`: Returns a point turned by this rotation.
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: The point's z.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The turned point.
- `toEuler`: Returns the turns around x, y and z that `fromEuler` would make this rotation from, in an order.
  - `order`: Optional. The order the turns are made in; defaults to `ZYX`: around x, then y, then z.
  - `out`: Optional. The vector to write into: pitch in x, yaw in y, roll in z, in radians; a new one when omitted.
  - returns: The angles.

  The turn made second is from -pi / 2 to pi / 2, and the other two are from -pi to pi. Where the second turn is a quarter turn either way, the first and the last turn around the same axis: the last is 0 and the first carries the whole turn.
- `angle`: Gets the angle this rotation turns by, around whatever axis, in radians, 0 to pi.
- `getAxis`: Returns the axis this rotation turns around. `angle` is the angle of the turn around the axis.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The axis, of length 1; the x axis for a rotation that turns nothing.
- `length`: Gets this quaternion's length, 1 for a rotation.
- `equals`: Returns whether this rotation and another turn the same way, within a tolerance on each of the quaternion's four numbers.
  - `other`: The other rotation.
  - `tolerance`: Optional. The most each number may differ by, multiplied by the larger number's size when that size is over 1; defaults to 0, exactly equal.
  - returns: True when they are the same rotation.

  A quaternion and its negative are the same rotation.
- `dot`: Returns this quaternion's dot product with another: 1 or -1 for the same rotation, 0 for rotations half a turn apart.
  - `other`: The other rotation.
  - returns: The dot product.
- `angleTo`: Returns the angle between this rotation and another, in radians: how far one turns to become the other, the short way round.
  - `other`: The other rotation.
  - returns: The angle, 0 to pi.
- `rotateToward`: Returns this rotation turned toward a target by at most a step, the short way round.
  - `target`: The rotation to turn toward.
  - `step`: The most to turn by, in radians.
  - `out`: Optional. The rotation to fill; a new one when omitted. It may be this rotation or the target.
  - returns: The turned rotation.

  The rotation reaches the target exactly. A step of 0 or less leaves the rotation as it is.

  ```haxe
  turret.rotation.rotateToward(aim, turnSpeed * dt, turret.rotation);
  ```
- `toMatrix`: Returns the rotation as a matrix.
  - `out`: Optional. The matrix to write into; a new one when omitted.
  - returns: The matrix.

## Random

*class* in [`libs/math/src/helix/math/Random.hx`](../src/helix/math/Random.hx), `import helix.math.Random;`

Represents a seeded random number generator that produces the same sequence on every target.

It is xoshiro128**, its state made from the seed by SplitMix64, as raylib's rprand is, so a seed produces raylib's numbers. It is written in 32-bit integer arithmetic, so the interpreter, JS and hxcpp agree bit for bit. A simulation that must replay alike, such as a recorded run or a lockstep game, draws from one. A program keeps one generator per stream (play, and a title screen's decoration), so that drawing from one doesn't change another's sequence.

```haxe
var random = new Random(42);
var angle = random.nextRange(0, 2 * Math.PI);
var card = random.pick(deck);
```

The points, directions, rotations and bell-shaped numbers it makes agree on every target too, made with `Trig` and arithmetic alone.

Natively the generated C++ is compiled with `-fwrapv` and `-ffp-contract=off` on GCC and clang. Haxe's Int wraps on overflow, and C++'s int doesn't, so without `-fwrapv` a compiler may change the sequence. Without `-ffp-contract=off` fused multiply-adds may change a number's rounding.

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
function nextGaussian(?mean:Float = 0., ?deviation:Float = 1.):Float
function nextInCircle(?radius:Float = 1., ?out:Vector2):Vector2
function nextOnCircle(?radius:Float = 1., ?out:Vector2):Vector2
function nextInSphere(?radius:Float = 1., ?out:Vector3):Vector3
function nextOnSphere(?radius:Float = 1., ?out:Vector3):Vector3
function nextInCone(direction:Vector3, radians:Float, ?out:Vector3):Vector3
function nextRotation(?out:Quaternion):Quaternion
```

- `new`: Creates a generator.
  - `seed`: Optional. The seed, read as unsigned; defaults to 12345.
- `seed`: Gets or sets the seed the sequence last started from.
  Setting it starts the sequence again from that seed. Every seed, 0 among them, produces a sequence of its own.
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

  Bounds provided in the wrong order are swapped.
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
- `nextGaussian`: Returns a number from a normal (bell-shaped) distribution.
  - `mean`: Optional. The middle of the bell; defaults to 0.
  - `deviation`: Optional. The bell's standard deviation; defaults to 1.
  - returns: The number.
- `nextInCircle`: Returns a point inside a circle around the origin, every place as likely as another.
  - `radius`: Optional. The circle's radius; defaults to 1.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The point.
- `nextOnCircle`: Returns a point on a circle around the origin: a direction in 2D at radius 1.
  - `radius`: Optional. The circle's radius; defaults to 1.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The point.
- `nextInSphere`: Returns a point inside a sphere around the origin, every place as likely as another.
  - `radius`: Optional. The sphere's radius; defaults to 1.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The point.
- `nextOnSphere`: Returns a point on a sphere around the origin: a direction in 3D at radius 1.
  - `radius`: Optional. The sphere's radius; defaults to 1.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The point.
- `nextInCone`: Returns a direction within an angle of another, every direction in that cone as likely as another.
  - `direction`: The cone's middle; it needn't be of length 1.
  - `radians`: The most the direction strays from the middle, clamped to 0 to pi.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be the middle.
  - returns: The direction, of length 1; of length 0 when the middle is.
- `nextRotation`: Returns a rotation, every rotation as likely as another.
  - `out`: Optional. The rotation to fill; a new one when omitted.
  - returns: The rotation.

## RectanglePacker

*class* in [`libs/math/src/helix/math/RectanglePacker.hx`](../src/helix/math/RectanglePacker.hx), `import helix.math.RectanglePacker;`

Provides packing rectangles into an area, as stb_rect_pack 1.01 does (public domain, Sean Barrett), which raylib packs its font atlases with: a skyline, each rectangle placed as low as it goes and then as far left, the tallest first.

```haxe
static function pack(width:Int, height:Int, sizes:Array<Int>):Array<Int>
```

- `pack`: Places rectangles in an area.
  - `width`: The area's width.
  - `height`: The area's height.
  - `sizes`: Each rectangle's width and height, flat: width, height, width, height.
  - returns: Each rectangle's place, flat, in the same order: x, y, and 1 when it was placed or 0 when it didn't fit. A rectangle with no width or height is placed at 0, 0.

## Spring

*class* in [`libs/math/src/helix/math/Spring.hx`](../src/helix/math/Spring.hx), `import helix.math.Spring;`

Represents a value that follows a target as a damped spring does: the value speeds up, slows as it nears the target, and stops at the target without going past (Unity's SmoothDamp).

```haxe
var zoom = new Spring(1);
zoom.update(target, .25, dt);
camera.zoom = zoom.value;
```

```haxe
function new(?value:Float = 0.)
var value:Float
var velocity:Float
function update(target:Float, time:Float, dt:Float):Float
```

- `new`: Creates a spring at rest.
  - `value`: Optional. The value the spring starts at; defaults to 0.
- `value`: Gets or sets the value.
- `velocity`: Gets or sets how fast the value is changing, per second.
- `update`: Moves the value toward a target over a time step, the same at any frame rate.
  - `target`: The target.
  - `time`: About how long the value needs to reach the target, in seconds: the value closes 3/5 of the gap in that time from rest, and 9/10 in twice that time. 0 or less puts the value at the target.
  - `dt`: The time step, in seconds.
  - returns: The value.

  A time step of 0 or less leaves the value and the velocity unchanged. A value that would pass the target stops at the target.

## Transform2D

*class* in [`libs/math/src/helix/math/Transform2D.hx`](../src/helix/math/Transform2D.hx), `import helix.math.Transform2D;`

Represents where an object is in 2 dimensions, which way it faces, and how large it is: a position, a rotation and a scale.

It faces along its own +x, so a rotation of 0 faces +x and a positive one turns toward +y, clockwise on screen where y grows downward. Moving and turning are along and around its own axes unless a method says otherwise, so a sprite, a turret or a 2D camera is steered the same way. The matrix that draws it scales, then rotates, then moves (`toMatrix`); a child's is its own composed with its parent's (`Matrix3.compose`). It uses `Trig`, so a transform comes out the same on every target.

```haxe
var ship = new Transform2D();
ship.position.set(100, 50);
ship.lookAt(mouseX, mouseY);
ship.moveForward(speed * dt);
var model = ship.toMatrix(scratch);
```

```haxe
function new()
static function fromMatrix(matrix:Matrix3, ?out:Transform2D):Transform2D
final position:Vector2
var rotation:Float
final scale:Vector2
function copyFrom(other:Transform2D):Transform2D
function makeIdentity():Transform2D
function computeForward(?out:Vector2):Vector2
function computeRight(?out:Vector2):Vector2
function moveForward(distance:Float):Transform2D
function moveRight(distance:Float):Transform2D
function moveToward(x:Float, y:Float, distance:Float, ?nearest:Float = .001):Transform2D
function rotate(radians:Float):Transform2D
function lookAt(x:Float, y:Float):Transform2D
function rotateToward(x:Float, y:Float, step:Float):Transform2D
function orbit(x:Float, y:Float, radians:Float):Transform2D
function transformPoint(x:Float, y:Float, ?out:Vector2):Vector2
function toMatrix(?out:Matrix3):Matrix3
```

- `new`: Creates a transform at the origin, facing +x, at scale 1.
- `fromMatrix`: Returns the transform a matrix places, scales and turns by.
  - `matrix`: The matrix.
  - `out`: Optional. The transform to write into; a new one when omitted.
  - returns: The transform.

  Its rotation and x scale are the matrix's x axis's, and its y scale what the y axis reaches across it, so a matrix that shears loses the shear, and one that mirrors produces a y scale less than 0.
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
- `rotateToward`: Turns it toward facing a point by at most a step, the short way round, as a turret follows what it aims at.
  - `x`: The point's x.
  - `y`: The point's y.
  - `step`: The most to turn by, in radians.
  - returns: This transform.

  It faces the point exactly once within a step of facing the point. A point at its position, or a step of 0 or less, leaves it as it is.
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

Its own axes are its rotation's: -z is forward, +x right and +y up, as a camera looks down -z. Moving and turning are along and around those axes unless a method says otherwise, so a ship, a turret or a camera is steered the same way. The matrix that draws it scales, then rotates, then moves (`toMatrix`); a child's is its own composed with its parent's (`Matrix4.compose`). It uses `Trig`, so a transform comes out the same on every target.

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
static function fromMatrix(matrix:Matrix4, ?out:Transform3D):Transform3D
final position:Vector3
final rotation:Quaternion
final scale:Vector3
function copyFrom(other:Transform3D):Transform3D
function makeIdentity():Transform3D
function computeForward(?out:Vector3):Vector3
function computeRight(?out:Vector3):Vector3
function computeUp(?out:Vector3):Vector3
function moveForward(distance:Float, ?inWorldPlane:Bool = false):Transform3D
function moveRight(distance:Float, ?inWorldPlane:Bool = false):Transform3D
function moveUp(distance:Float):Transform3D
function moveToward(x:Float, y:Float, z:Float, distance:Float, ?nearest:Float = .001):Transform3D
function yaw(radians:Float):Transform3D
function pitch(radians:Float, ?lock:Bool = false):Transform3D
function roll(radians:Float):Transform3D
function lookAt(x:Float, y:Float, z:Float, ?upX:Float = 0., ?upY:Float = 1., ?upZ:Float = 0.):Transform3D
function rotateToward(x:Float, y:Float, z:Float, step:Float, ?upX:Float = 0., ?upY:Float = 1., ?upZ:Float = 0.):Transform3D
function orbit(x:Float, y:Float, z:Float, yaw:Float, pitch:Float, ?lock:Bool = false):Transform3D
function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3):Vector3
function toMatrix(?out:Matrix4):Matrix4
```

- `new`: Creates a transform at the origin, facing -z, at scale 1.
- `fromMatrix`: Returns the transform of a matrix: its position, rotation and scale.
  - `matrix`: The matrix.
  - `out`: Optional. The transform to fill; a new one when omitted.
  - returns: The transform.

  A matrix that shears produces the nearest rotation (its polar decomposition's) and the scale along that rotation's axes, the shear lost. One that mirrors produces an x scale less than 0, so the way it faces and its up are kept.
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
  - `inWorldPlane`: Optional. True to move along the ground, its forward with the height removed, as a walking camera does; defaults to false.
  - returns: This transform.
- `moveRight`: Moves it to its right.
  - `distance`: How far, in its parent's units; less than 0 moves it left.
  - `inWorldPlane`: Optional. True to move along the ground, its right with the height removed; defaults to false.
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
- `rotateToward`: Turns it toward facing a point by at most a step, the short way round, as a turret follows what it aims at.
  - `x`: The point's x.
  - `y`: The point's y.
  - `z`: The point's z.
  - `step`: The most to turn by, in radians.
  - `upX`: Optional. Which way up it is kept once it faces the point, x; defaults to 0.
  - `upY`: Optional. Up's y; defaults to 1.
  - `upZ`: Optional. Up's z; defaults to 0.
  - returns: This transform.

  It faces the point exactly once within a step of facing the point. A point at its position, or a step of 0 or less, leaves it as it is.
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

Provides trigonometry that returns the same bits on every target.

A simulation that must play alike on every target (a recorded run's replay, a lockstep game, physics) uses these in place of `Math`'s, whose last bit differs between targets for some angles. Drawing doesn't need them. Results are within a few ulp of `Math`'s. Angles are in radians, of any size: an angle that keeps growing stays as accurate however large it gets. An infinite or NaN angle returns NaN, as do `asin` and `acos` outside -1 to 1.

With `-D helix-math-standard-trig` each function is the standard library's (`Math.sin` and the others), which is faster in a browser. A result's last bit may then differ between targets.

Natively the generated C++ is compiled with `-ffp-contract=off` on GCC and clang, so that fused multiply-adds don't change the rounding.

```haxe
static function sin(x:Float):Float
static function cos(x:Float):Float
static function tan(x:Float):Float
static function cosSin(x:Float, ?out:Vector2):Vector2
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
- `cosSin`: Returns the cosine and the sine of an angle together, each as `cos` and `sin` return it, for less than the two calls cost.
  - `x`: The angle, in radians.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The cosine in x and the sine in y: the point at the angle on a circle of radius 1.
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

## Vector2

*class* in [`libs/math/src/helix/math/Vector2.hx`](../src/helix/math/Vector2.hx), `import helix.math.Vector2;`

Represents a vector in 2 dimensions: a position or a direction, as its user means it.

Each operation writes its result into an optional out, the last argument, and returns it. Without one it makes a new vector and leaves this one unchanged; with this vector as the out, it works in place (`v.normalize(v)`). The out may be this vector or any other argument, as every input is read before anything is written, and calls chain through what each returns (`a.add(b, a).scale(2, a)`). `set` and `copyFrom` change this vector and return it. A number made from vectors (`dot`, `cross`, `distance`) is a method, a number of one (`length`, `angle`) a property.

It uses only addition, subtraction, multiplication, division and square roots, which agree on every target, and `Trig` for angles, so a vector comes out the same everywhere. Angles are radians, turning from +x toward +y. Its space is its user's.

```haxe
var velocity = Vector2.fromAngle(heading, speed);
position.addScaled(velocity, dt, position);
var toward = target.subtract(position).normalize();
```

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?x:Float, ?y:Float}
```

```haxe
static function fromAngle(radians:Float, ?length:Float = 1., ?out:Vector2):Vector2 = { length : 1. }
static function lerp(from:Vector2, to:Vector2, amount:Float, ?out:Vector2):Vector2
static function hermite(from:Vector2, fromTangent:Vector2, to:Vector2, toTangent:Vector2, amount:Float, ?out:Vector2):Vector2
var x:Float
var y:Float
function set(x:Float, y:Float):Vector2
function copyFrom(other:Vector2):Vector2
function copy(?out:Vector2):Vector2
function add(other:Vector2, ?out:Vector2):Vector2
function subtract(other:Vector2, ?out:Vector2):Vector2
function scale(factor:Float, ?out:Vector2):Vector2
function addScaled(other:Vector2, factor:Float, ?out:Vector2):Vector2
function negate(?out:Vector2):Vector2
function inverse(?out:Vector2):Vector2
function normalize(?out:Vector2):Vector2
function rotate(radians:Float, ?out:Vector2):Vector2
function multiply(other:Vector2, ?out:Vector2):Vector2
function divide(other:Vector2, ?out:Vector2):Vector2
function min(other:Vector2, ?out:Vector2):Vector2
function max(other:Vector2, ?out:Vector2):Vector2
function clamp(min:Vector2, max:Vector2, ?out:Vector2):Vector2
function clampLength(min:Float, max:Float, ?out:Vector2):Vector2
function moveToward(target:Vector2, step:Float, ?out:Vector2):Vector2
function reflect(normal:Vector2, ?out:Vector2):Vector2
function refract(normal:Vector2, ratio:Float, ?out:Vector2):Vector2
function angleTo(other:Vector2):Float
var length(get, never):Float
var lengthSquared(get, never):Float
var angle(get, never):Float
function dot(other:Vector2):Float
function cross(other:Vector2):Float
function distance(other:Vector2):Float
function distanceSquared(other:Vector2):Float
function equals(other:Vector2, ?tolerance:Float = 0.):Bool = { tolerance : 0. }
```

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
- `hermite`: Returns the point on a curve from one point to another, the curve leaving and arriving along two tangents (a cubic Hermite curve).
  - `from`: The point at 0.
  - `fromTangent`: The curve's direction and speed leaving `from`.
  - `to`: The point at 1.
  - `toTangent`: The curve's direction and speed arriving at `to`.
  - `amount`: How far along, 0 to 1.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be any of the four.
  - returns: The point.
- `x`: Gets or sets the x coordinate.
- `y`: Gets or sets the y coordinate.
- `set`: Sets the coordinates.
  - `x`: The x coordinate.
  - `y`: The y coordinate.
  - returns: This vector.
- `copyFrom`: Sets the coordinates to another vector's.
  - `other`: The vector to copy.
  - returns: This vector.
- `copy`: Returns a separate vector with this one's coordinates.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The copy.
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
- `inverse`: Returns 1 divided by each of this vector's coordinates.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The inverted vector. A coordinate of 0 becomes an infinite one.
- `normalize`: Returns this vector scaled to length 1, its direction kept.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The vector of length 1, or of length 0.

  A vector of length 0 stays 0.
- `rotate`: Returns this vector turned around the origin.
  - `radians`: The angle; more than 0 turns from +x toward +y.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The turned vector.
- `multiply`: Returns this vector times another, coordinate by coordinate.
  - `other`: The vector to multiply by.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The product.
- `divide`: Returns this vector divided by another, coordinate by coordinate.
  - `other`: The vector to divide by.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The quotient.
- `min`: Returns the lesser of this vector's and another's coordinates, each coordinate on its own.
  - `other`: The other vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The least coordinates.
- `max`: Returns the greater of this vector's and another's coordinates, each coordinate on its own.
  - `other`: The other vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The greatest coordinates.
- `clamp`: Returns this vector with each coordinate kept between two other vectors' coordinates.
  - `min`: The least coordinates.
  - `max`: The greatest coordinates.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or either bound.
  - returns: The clamped vector.

  A coordinate's two bounds in the wrong order are swapped.
- `clampLength`: Returns this vector with its length kept between two lengths, its direction unchanged.
  - `min`: The least length.
  - `max`: The greatest length.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The clamped vector.

  A vector of length 0 stays 0. Bounds in the wrong order are swapped.
- `moveToward`: Returns this point moved toward a target by at most a step.
  - `target`: The point to move toward.
  - `step`: The most distance to move.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the target.
  - returns: The moved point.

  The point reaches the target exactly. A step of 0 or less leaves the point where it is.
- `reflect`: Returns this direction bounced off a surface.
  - `normal`: The surface's normal, of length 1.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the normal.
  - returns: The reflected direction.
- `refract`: Returns this direction bent as light bends entering a surface.
  - `normal`: The surface's normal, of length 1.
  - `ratio`: The refractive index of what the direction leaves, over the index of what the direction enters.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the normal.
  - returns: The bent direction, or all 0 when the surface reflects the direction wholly.
- `angleTo`: Returns the angle from this vector to another, in radians.
  - `other`: The other vector.
  - returns: The angle, -pi to pi: more than 0 when the other is turned from this one toward +y.
- `length`: Gets the length.
- `lengthSquared`: Gets the length squared, which is quicker to find than the length and orders vectors alike.
- `angle`: Gets the angle from +x toward +y, in radians, -pi to pi; 0 for a vector of length 0.
- `dot`: Returns the dot product with another vector: the product of their lengths and the cosine of the angle between them.
  - `other`: The other vector.
  - returns: The dot product; 0 when they are at right angles.
- `cross`: Returns the cross product with another vector, as a number: the product of their lengths and the sine of the angle from this one to the other.
  - `other`: The other vector.
  - returns: The cross product: more than 0 when the other is turned from this one toward +y, 0 when they are parallel.
- `distance`: Returns the distance to another vector, each treated as a position.
  - `other`: The other vector.
  - returns: The distance.
- `distanceSquared`: Returns the distance to another vector squared, which is quicker to find than the distance and orders distances alike.
  - `other`: The other vector.
  - returns: The distance squared.
- `equals`: Returns whether another vector is the same, within a tolerance on each coordinate.
  - `other`: The other vector.
  - `tolerance`: Optional. The most each coordinate may differ by, multiplied by the larger coordinate's size when that size is over 1; defaults to 0, exactly equal.
  - returns: True when every coordinate is within the tolerance.

## Vector3

*class* in [`libs/math/src/helix/math/Vector3.hx`](../src/helix/math/Vector3.hx), `import helix.math.Vector3;`

Represents a vector in 3 dimensions: a position or a direction, as its user means it.

Each operation writes its result into an optional out, the last argument, and returns it. Without one it makes a new vector and leaves this one unchanged; with this vector as the out, it works in place (`v.normalize(v)`). The out may be this vector or any other argument, as every input is read before anything is written, and calls chain through what each returns (`a.add(b, a).scale(2, a)`). `set` and `copyFrom` change this vector and return it. A number made from vectors (`dot`, `distance`) is a method, a number of one (`length`) a property. `Matrix4` keeps positions and directions apart by its methods: `transformPoint` moves a position, `transformDirection` only turns and scales a direction.

It uses only addition, subtraction, multiplication, division and square roots, which agree on every target, so a vector comes out the same everywhere. Space is right-handed with +y up, as every 3D type here.

```haxe
position.addScaled(velocity, dt, position);
var toward = target.subtract(position).normalize();
var right = forward.cross(up);
```

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?x:Float, ?y:Float, ?z:Float}
```

```haxe
static function lerp(from:Vector3, to:Vector3, amount:Float, ?out:Vector3):Vector3
static function hermite(from:Vector3, fromTangent:Vector3, to:Vector3, toTangent:Vector3, amount:Float, ?out:Vector3):Vector3
static function orthoNormalize(first:Vector3, second:Vector3):Void
static function barycentric(point:Vector3, a:Vector3, b:Vector3, c:Vector3, ?out:Vector3):Vector3
var x:Float
var y:Float
var z:Float
function set(x:Float, y:Float, z:Float):Vector3
function copyFrom(other:Vector3):Vector3
function copy(?out:Vector3):Vector3
function add(other:Vector3, ?out:Vector3):Vector3
function subtract(other:Vector3, ?out:Vector3):Vector3
function scale(factor:Float, ?out:Vector3):Vector3
function addScaled(other:Vector3, factor:Float, ?out:Vector3):Vector3
function negate(?out:Vector3):Vector3
function inverse(?out:Vector3):Vector3
function normalize(?out:Vector3):Vector3
function cross(other:Vector3, ?out:Vector3):Vector3
function multiply(other:Vector3, ?out:Vector3):Vector3
function divide(other:Vector3, ?out:Vector3):Vector3
function min(other:Vector3, ?out:Vector3):Vector3
function max(other:Vector3, ?out:Vector3):Vector3
function clamp(min:Vector3, max:Vector3, ?out:Vector3):Vector3
function clampLength(min:Float, max:Float, ?out:Vector3):Vector3
function moveToward(target:Vector3, step:Float, ?out:Vector3):Vector3
function reflect(normal:Vector3, ?out:Vector3):Vector3
function refract(normal:Vector3, ratio:Float, ?out:Vector3):Vector3
function angleTo(other:Vector3):Float
function project(onto:Vector3, ?out:Vector3):Vector3
function reject(from:Vector3, ?out:Vector3):Vector3
function perpendicular(?out:Vector3):Vector3
function rotate(axis:Vector3, radians:Float, ?out:Vector3):Vector3
var length(get, never):Float
var lengthSquared(get, never):Float
function dot(other:Vector3):Float
function distance(other:Vector3):Float
function distanceSquared(other:Vector3):Float
function equals(other:Vector3, ?tolerance:Float = 0.):Bool = { tolerance : 0. }
```

- `lerp`: Returns the vector a fraction of the way from one vector to another.
  - `from`: The vector at 0.
  - `to`: The vector at 1.
  - `amount`: The fraction.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be from or to.
  - returns: The vector.

  A fraction outside 0 to 1 goes past the ends.
- `hermite`: Returns the point on a curve from one point to another, the curve leaving and arriving along two tangents (a cubic Hermite curve).
  - `from`: The point at 0.
  - `fromTangent`: The curve's direction and speed leaving `from`.
  - `to`: The point at 1.
  - `toTangent`: The curve's direction and speed arriving at `to`.
  - `amount`: How far along, 0 to 1.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be any of the four.
  - returns: The point.
- `orthoNormalize`: Makes two vectors of length 1 and square to each other, in place.
  - `first`: The vector whose direction is kept.
  - `second`: The vector turned to be square to `first`, in the plane the two vectors span.
- `barycentric`: Returns a point's weights among a triangle's three corners (barycentric coordinates).
  - `point`: The point, in the triangle's plane.
  - `a`: The first corner.
  - `b`: The second corner.
  - `c`: The third corner.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be any of the four.
  - returns: The weights of `a`, `b` and `c`, which add to 1.
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
- `copy`: Returns a separate vector with this one's coordinates.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The copy.
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
- `inverse`: Returns 1 divided by each of this vector's coordinates.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The inverted vector. A coordinate of 0 becomes an infinite one.
- `normalize`: Returns this vector scaled to length 1, its direction kept.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The vector of length 1, or of length 0.

  A vector of length 0 stays 0.
- `cross`: Returns the cross product with another vector: at right angles to both, as long as the area they span, by the right-hand rule (x cross y is z).
  - `other`: The other vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The cross product; of length 0 when they are parallel.
- `multiply`: Returns this vector times another, coordinate by coordinate.
  - `other`: The vector to multiply by.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The product.
- `divide`: Returns this vector divided by another, coordinate by coordinate.
  - `other`: The vector to divide by.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The quotient.
- `min`: Returns the lesser of this vector's and another's coordinates, each coordinate on its own.
  - `other`: The other vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The least coordinates.
- `max`: Returns the greater of this vector's and another's coordinates, each coordinate on its own.
  - `other`: The other vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The greatest coordinates.
- `clamp`: Returns this vector with each coordinate kept between two other vectors' coordinates.
  - `min`: The least coordinates.
  - `max`: The greatest coordinates.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or either bound.
  - returns: The clamped vector.

  A coordinate's two bounds in the wrong order are swapped.
- `clampLength`: Returns this vector with its length kept between two lengths, its direction unchanged.
  - `min`: The least length.
  - `max`: The greatest length.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The clamped vector.

  A vector of length 0 stays 0. Bounds in the wrong order are swapped.
- `moveToward`: Returns this point moved toward a target by at most a step.
  - `target`: The point to move toward.
  - `step`: The most distance to move.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the target.
  - returns: The moved point.

  The point reaches the target exactly. A step of 0 or less leaves the point where it is.
- `reflect`: Returns this direction bounced off a surface.
  - `normal`: The surface's normal, of length 1.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the normal.
  - returns: The reflected direction.
- `refract`: Returns this direction bent as light bends entering a surface.
  - `normal`: The surface's normal, of length 1.
  - `ratio`: The refractive index of what the direction leaves, over the index of what the direction enters.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the normal.
  - returns: The bent direction, or all 0 when the surface reflects the direction wholly.
- `angleTo`: Returns the angle between this vector and another, in radians.
  - `other`: The other vector.
  - returns: The angle, 0 to pi.
- `project`: Returns the part of this vector that lies along another.
  - `onto`: The vector to project onto, of any length but 0.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The projection.
- `reject`: Returns the part of this vector that is square to another: this vector less its projection.
  - `from`: The vector to be square to, of any length but 0.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The rejection.
- `perpendicular`: Returns a vector square to this one: this vector crossed with the axis this vector lies least along.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The perpendicular vector, of length 0 when this vector is.
- `rotate`: Returns this point turned around an axis through the origin.
  - `axis`: The axis, of any length. An axis of length 0 leaves the point where it is.
  - `radians`: The angle, by the right-hand rule around the axis.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the axis.
  - returns: The turned point.
- `length`: Gets the length.
- `lengthSquared`: Gets the length squared, which is quicker to find than the length and orders vectors alike.
- `dot`: Returns the dot product with another vector: the product of their lengths and the cosine of the angle between them.
  - `other`: The other vector.
  - returns: The dot product; 0 when they are at right angles.
- `distance`: Returns the distance to another vector, each treated as a position.
  - `other`: The other vector.
  - returns: The distance.
- `distanceSquared`: Returns the distance to another vector squared, which is quicker to find than the distance and orders distances alike.
  - `other`: The other vector.
  - returns: The distance squared.
- `equals`: Returns whether another vector is the same, within a tolerance on each coordinate.
  - `other`: The other vector.
  - `tolerance`: Optional. The most each coordinate may differ by, multiplied by the larger coordinate's size when that size is over 1; defaults to 0, exactly equal.
  - returns: True when every coordinate is within the tolerance.

## Vector4

*class* in [`libs/math/src/helix/math/Vector4.hx`](../src/helix/math/Vector4.hx), `import helix.math.Vector4;`

Represents a vector of 4 numbers: a point before its perspective divide, a tangent with its handedness, a plane, or any four a shader reads, as its user means it.

Each operation writes its result into an optional out, the last argument, and returns it. Without one it makes a new vector and leaves this one unchanged; with this vector as the out, it works in place (`v.normalize(v)`). The out may be this vector or any other argument, as every input is read before anything is written, and calls chain through what each returns (`a.add(b, a).scale(2, a)`). `set` and `copyFrom` change this vector and return it. A number made from vectors (`dot`, `distance`) is a method, a number of one (`length`) a property. See `Quaternion` for a rotation, which has four numbers too and its own operations.

It uses only addition, subtraction, multiplication, division and square roots, which agree on every target, so a vector comes out the same everywhere.

```haxe
var clip = new Vector4(x, y, z, 1);
var plane = new Vector4(0, 1, 0, -height).normalize();
```

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?x:Float, ?y:Float, ?z:Float, ?w:Float}
```

```haxe
static function lerp(from:Vector4, to:Vector4, amount:Float, ?out:Vector4):Vector4
static function hermite(from:Vector4, fromTangent:Vector4, to:Vector4, toTangent:Vector4, amount:Float, ?out:Vector4):Vector4
var x:Float
var y:Float
var z:Float
var w:Float
function set(x:Float, y:Float, z:Float, w:Float):Vector4
function copyFrom(other:Vector4):Vector4
function copy(?out:Vector4):Vector4
function add(other:Vector4, ?out:Vector4):Vector4
function subtract(other:Vector4, ?out:Vector4):Vector4
function scale(factor:Float, ?out:Vector4):Vector4
function addScaled(other:Vector4, factor:Float, ?out:Vector4):Vector4
function negate(?out:Vector4):Vector4
function inverse(?out:Vector4):Vector4
function normalize(?out:Vector4):Vector4
function multiply(other:Vector4, ?out:Vector4):Vector4
function divide(other:Vector4, ?out:Vector4):Vector4
function min(other:Vector4, ?out:Vector4):Vector4
function max(other:Vector4, ?out:Vector4):Vector4
function clamp(min:Vector4, max:Vector4, ?out:Vector4):Vector4
function clampLength(min:Float, max:Float, ?out:Vector4):Vector4
function moveToward(target:Vector4, step:Float, ?out:Vector4):Vector4
var length(get, never):Float
var lengthSquared(get, never):Float
function dot(other:Vector4):Float
function distance(other:Vector4):Float
function distanceSquared(other:Vector4):Float
function equals(other:Vector4, ?tolerance:Float = 0.):Bool = { tolerance : 0. }
```

- `lerp`: Returns the vector a fraction of the way from one vector to another.
  - `from`: The vector at 0.
  - `to`: The vector at 1.
  - `amount`: The fraction.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be from or to.
  - returns: The vector.

  A fraction outside 0 to 1 goes past the ends.
- `hermite`: Returns the point on a curve from one point to another, the curve leaving and arriving along two tangents (a cubic Hermite curve).
  - `from`: The point at 0.
  - `fromTangent`: The curve's direction and speed leaving `from`.
  - `to`: The point at 1.
  - `toTangent`: The curve's direction and speed arriving at `to`.
  - `amount`: How far along, 0 to 1.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be any of the four.
  - returns: The point.
- `x`: Gets or sets the x coordinate.
- `y`: Gets or sets the y coordinate.
- `z`: Gets or sets the z coordinate.
- `w`: Gets or sets the w coordinate.
- `set`: Sets the coordinates.
  - `x`: The x coordinate.
  - `y`: The y coordinate.
  - `z`: The z coordinate.
  - `w`: The w coordinate.
  - returns: This vector.
- `copyFrom`: Sets the coordinates to another vector's.
  - `other`: The vector to copy.
  - returns: This vector.
- `copy`: Returns a separate vector with this one's coordinates.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The copy.
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
- `addScaled`: Returns this vector plus another times a number.
  - `other`: The vector to add.
  - `factor`: The number it is multiplied by first.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The sum.
- `negate`: Returns this vector with every coordinate negated.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The negated vector.
- `inverse`: Returns 1 divided by each of this vector's coordinates.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The inverted vector. A coordinate of 0 becomes an infinite one.
- `normalize`: Returns this vector scaled to length 1, the proportions of its coordinates kept.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The vector of length 1, or of length 0.

  A vector of length 0 stays 0.
- `multiply`: Returns this vector times another, coordinate by coordinate.
  - `other`: The vector to multiply by.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The product.
- `divide`: Returns this vector divided by another, coordinate by coordinate.
  - `other`: The vector to divide by.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The quotient.
- `min`: Returns the lesser of this vector's and another's coordinates, each coordinate on its own.
  - `other`: The other vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The least coordinates.
- `max`: Returns the greater of this vector's and another's coordinates, each coordinate on its own.
  - `other`: The other vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
  - returns: The greatest coordinates.
- `clamp`: Returns this vector with each coordinate kept between two other vectors' coordinates.
  - `min`: The least coordinates.
  - `max`: The greatest coordinates.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or either bound.
  - returns: The clamped vector.

  A coordinate's two bounds in the wrong order are swapped.
- `clampLength`: Returns this vector with its length kept between two lengths, its direction unchanged.
  - `min`: The least length.
  - `max`: The greatest length.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The clamped vector.

  A vector of length 0 stays 0. Bounds in the wrong order are swapped.
- `moveToward`: Returns this point moved toward a target by at most a step.
  - `target`: The point to move toward.
  - `step`: The most distance to move.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector or the target.
  - returns: The moved point.

  The point reaches the target exactly. A step of 0 or less leaves the point where it is.
- `length`: Gets the length.
- `lengthSquared`: Gets the length squared, which is quicker to find than the length and orders vectors alike.
- `dot`: Returns the dot product with another vector: each coordinate times the other's, summed.
  - `other`: The other vector.
  - returns: The dot product.
- `distance`: Returns the distance to another vector.
  - `other`: The other vector.
  - returns: The distance.
- `distanceSquared`: Returns the distance to another vector squared, which is quicker to find than the distance and orders distances alike.
  - `other`: The other vector.
  - returns: The distance squared.
- `equals`: Returns whether another vector is the same, within a tolerance on each coordinate.
  - `other`: The other vector.
  - `tolerance`: Optional. The most each coordinate may differ by, multiplied by the larger coordinate's size when that size is over 1; defaults to 0, exactly equal.
  - returns: True when every coordinate is within the tolerance.
