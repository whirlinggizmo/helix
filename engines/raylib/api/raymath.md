# Raymath

[Back to the library](README.md)

## raymath.h's defines


```haxe
static inline var PI:Float
static inline var DEG2RAD:Float
static inline var RAD2DEG:Float
static inline var EPSILON:Float
```

- `PI`: Pi, as raymath defines it when raylib hasn't.
- `DEG2RAD`: Degrees to radians: multiply by it.
- `RAD2DEG`: Radians to degrees: multiply by it.
- `EPSILON`: The difference under which raymath's `...Equals` functions take two values as equal.

## raymath: vectors, matrices and quaternions


```haxe
static function Clamp(value:Float, min:Float, max:Float):Float
static function Lerp(start:Float, end:Float, amount:Float):Float
static function Normalize(value:Float, start:Float, end:Float):Float
static function Remap(value:Float, inputStart:Float, inputEnd:Float, outputStart:Float, outputEnd:Float):Float
static function Wrap(value:Float, min:Float, max:Float):Float
static function FloatEquals(x:Float, y:Float):Int
static function Vector2Zero():Vector2
static function Vector2One():Vector2
static function Vector2Add(v1:Vector2, v2:Vector2):Vector2
static function Vector2AddValue(v:Vector2, add:Float):Vector2
static function Vector2Subtract(v1:Vector2, v2:Vector2):Vector2
static function Vector2SubtractValue(v:Vector2, sub:Float):Vector2
static function Vector2Length(v:Vector2):Float
static function Vector2LengthSqr(v:Vector2):Float
static function Vector2DotProduct(v1:Vector2, v2:Vector2):Float
static function Vector2Distance(v1:Vector2, v2:Vector2):Float
static function Vector2DistanceSqr(v1:Vector2, v2:Vector2):Float
static function Vector2Angle(v1:Vector2, v2:Vector2):Float
static function Vector2LineAngle(start:Vector2, end:Vector2):Float
static function Vector2Scale(v:Vector2, scale:Float):Vector2
static function Vector2Multiply(v1:Vector2, v2:Vector2):Vector2
static function Vector2Negate(v:Vector2):Vector2
static function Vector2Divide(v1:Vector2, v2:Vector2):Vector2
static function Vector2Normalize(v:Vector2):Vector2
static function Vector2Transform(v:Vector2, mat:Matrix):Vector2
static function Vector2Lerp(v1:Vector2, v2:Vector2, amount:Float):Vector2
static function Vector2Reflect(v:Vector2, normal:Vector2):Vector2
static function Vector2Min(v1:Vector2, v2:Vector2):Vector2
static function Vector2Max(v1:Vector2, v2:Vector2):Vector2
static function Vector2Rotate(v:Vector2, angle:Float):Vector2
static function Vector2MoveTowards(v:Vector2, target:Vector2, maxDistance:Float):Vector2
static function Vector2Invert(v:Vector2):Vector2
static function Vector2Clamp(v:Vector2, min:Vector2, max:Vector2):Vector2
static function Vector2ClampValue(v:Vector2, min:Float, max:Float):Vector2
static function Vector2Equals(p:Vector2, q:Vector2):Int
static function Vector2Refract(v:Vector2, n:Vector2, r:Float):Vector2
static function Vector3Zero():Vector3
static function Vector3One():Vector3
static function Vector3Add(v1:Vector3, v2:Vector3):Vector3
static function Vector3AddValue(v:Vector3, add:Float):Vector3
static function Vector3Subtract(v1:Vector3, v2:Vector3):Vector3
static function Vector3SubtractValue(v:Vector3, sub:Float):Vector3
static function Vector3Scale(v:Vector3, scalar:Float):Vector3
static function Vector3Multiply(v1:Vector3, v2:Vector3):Vector3
static function Vector3CrossProduct(v1:Vector3, v2:Vector3):Vector3
static function Vector3Perpendicular(v:Vector3):Vector3
static function Vector3Length(v:Vector3):Float
static function Vector3LengthSqr(v:Vector3):Float
static function Vector3DotProduct(v1:Vector3, v2:Vector3):Float
static function Vector3Distance(v1:Vector3, v2:Vector3):Float
static function Vector3DistanceSqr(v1:Vector3, v2:Vector3):Float
static function Vector3Angle(v1:Vector3, v2:Vector3):Float
static function Vector3Negate(v:Vector3):Vector3
static function Vector3Divide(v1:Vector3, v2:Vector3):Vector3
static function Vector3Normalize(v:Vector3):Vector3
static function Vector3Project(v1:Vector3, v2:Vector3):Vector3
static function Vector3Reject(v1:Vector3, v2:Vector3):Vector3
static function Vector3OrthoNormalize(v1:Vector3, v2:Vector3):Void
static function Vector3Transform(v:Vector3, mat:Matrix):Vector3
static function Vector3RotateByQuaternion(v:Vector3, q:Quaternion):Vector3
static function Vector3RotateByAxisAngle(v:Vector3, axis:Vector3, angle:Float):Vector3
static function Vector3MoveTowards(v:Vector3, target:Vector3, maxDistance:Float):Vector3
static function Vector3Lerp(v1:Vector3, v2:Vector3, amount:Float):Vector3
static function Vector3CubicHermite(v1:Vector3, tangent1:Vector3, v2:Vector3, tangent2:Vector3, amount:Float):Vector3
static function Vector3Reflect(v:Vector3, normal:Vector3):Vector3
static function Vector3Min(v1:Vector3, v2:Vector3):Vector3
static function Vector3Max(v1:Vector3, v2:Vector3):Vector3
static function Vector3Barycenter(p:Vector3, a:Vector3, b:Vector3, c:Vector3):Vector3
static function Vector3Unproject(source:Vector3, projection:Matrix, view:Matrix):Vector3
static function Vector3ToFloatV(v:Vector3):Array<Float>
static function Vector3Invert(v:Vector3):Vector3
static function Vector3Clamp(v:Vector3, min:Vector3, max:Vector3):Vector3
static function Vector3ClampValue(v:Vector3, min:Float, max:Float):Vector3
static function Vector3Equals(p:Vector3, q:Vector3):Int
static function Vector3Refract(v:Vector3, n:Vector3, r:Float):Vector3
static function Vector4Zero():Vector4
static function Vector4One():Vector4
static function Vector4Add(v1:Vector4, v2:Vector4):Vector4
static function Vector4AddValue(v:Vector4, add:Float):Vector4
static function Vector4Subtract(v1:Vector4, v2:Vector4):Vector4
static function Vector4SubtractValue(v:Vector4, add:Float):Vector4
static function Vector4Length(v:Vector4):Float
static function Vector4LengthSqr(v:Vector4):Float
static function Vector4DotProduct(v1:Vector4, v2:Vector4):Float
static function Vector4Distance(v1:Vector4, v2:Vector4):Float
static function Vector4DistanceSqr(v1:Vector4, v2:Vector4):Float
static function Vector4Scale(v:Vector4, scale:Float):Vector4
static function Vector4Multiply(v1:Vector4, v2:Vector4):Vector4
static function Vector4Negate(v:Vector4):Vector4
static function Vector4Divide(v1:Vector4, v2:Vector4):Vector4
static function Vector4Normalize(v:Vector4):Vector4
static function Vector4Min(v1:Vector4, v2:Vector4):Vector4
static function Vector4Max(v1:Vector4, v2:Vector4):Vector4
static function Vector4Lerp(v1:Vector4, v2:Vector4, amount:Float):Vector4
static function Vector4MoveTowards(v:Vector4, target:Vector4, maxDistance:Float):Vector4
static function Vector4Invert(v:Vector4):Vector4
static function Vector4Equals(p:Vector4, q:Vector4):Int
static function MatrixDeterminant(mat:Matrix):Float
static function MatrixTrace(mat:Matrix):Float
static function MatrixTranspose(mat:Matrix):Matrix
static function MatrixInvert(mat:Matrix):Matrix
static function MatrixIdentity():Matrix
static function MatrixAdd(left:Matrix, right:Matrix):Matrix
static function MatrixSubtract(left:Matrix, right:Matrix):Matrix
static function MatrixMultiply(left:Matrix, right:Matrix):Matrix
static function MatrixTranslate(x:Float, y:Float, z:Float):Matrix
static function MatrixRotate(axis:Vector3, angle:Float):Matrix
static function MatrixRotateX(angle:Float):Matrix
static function MatrixRotateY(angle:Float):Matrix
static function MatrixRotateZ(angle:Float):Matrix
static function MatrixRotateXYZ(angle:Vector3):Matrix
static function MatrixRotateZYX(angle:Vector3):Matrix
static function MatrixScale(x:Float, y:Float, z:Float):Matrix
static function MatrixFrustum(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float):Matrix
static function MatrixPerspective(fovY:Float, aspect:Float, nearPlane:Float, farPlane:Float):Matrix
static function MatrixOrtho(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float):Matrix
static function MatrixLookAt(eye:Vector3, target:Vector3, up:Vector3):Matrix
static function MatrixToFloatV(mat:Matrix):Array<Float>
static function QuaternionAdd(q1:Quaternion, q2:Quaternion):Quaternion
static function QuaternionAddValue(q:Quaternion, add:Float):Quaternion
static function QuaternionSubtract(q1:Quaternion, q2:Quaternion):Quaternion
static function QuaternionSubtractValue(q:Quaternion, sub:Float):Quaternion
static function QuaternionIdentity():Quaternion
static function QuaternionLength(q:Quaternion):Float
static function QuaternionNormalize(q:Quaternion):Quaternion
static function QuaternionInvert(q:Quaternion):Quaternion
static function QuaternionMultiply(q1:Quaternion, q2:Quaternion):Quaternion
static function QuaternionScale(q:Quaternion, mul:Float):Quaternion
static function QuaternionDivide(q1:Quaternion, q2:Quaternion):Quaternion
static function QuaternionLerp(q1:Quaternion, q2:Quaternion, amount:Float):Quaternion
static function QuaternionNlerp(q1:Quaternion, q2:Quaternion, amount:Float):Quaternion
static function QuaternionSlerp(q1:Quaternion, q2:Quaternion, amount:Float):Quaternion
static function QuaternionCubicHermiteSpline(q1:Quaternion, outTangent1:Quaternion, q2:Quaternion, inTangent2:Quaternion, t:Float):Quaternion
static function QuaternionFromVector3ToVector3(from:Vector3, to:Vector3):Quaternion
static function QuaternionFromMatrix(mat:Matrix):Quaternion
static function QuaternionToMatrix(q:Quaternion):Matrix
static function QuaternionFromAxisAngle(axis:Vector3, angle:Float):Quaternion
static function QuaternionToAxisAngle(q:Quaternion, outAxis:Array<Vector3>, outAngle:Array<Float>):Void
static function QuaternionFromEuler(pitch:Float, yaw:Float, roll:Float):Quaternion
static function QuaternionToEuler(q:Quaternion):Vector3
static function QuaternionTransform(q:Quaternion, mat:Matrix):Quaternion
static function QuaternionEquals(p:Quaternion, q:Quaternion):Int
static function MatrixDecompose(mat:Matrix, translation:Vector3, rotation:Quaternion, scale:Vector3):Void
```

- `Clamp`: Returns a value kept between two others.
  - `value`: The value.
  - `min`: The least.
  - `max`: The most.
  - returns: The value, at least min and at most max.
- `Lerp`: Returns a value part of the way from one to another.
  - `start`: The start.
  - `end`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The value.
- `Normalize`: Returns where a value falls from one to another: 0 at the start, 1 at the end.
  - `value`: The value.
  - `start`: The start.
  - `end`: The end.
  - returns: The fraction.
- `Remap`: Returns a value moved from one range to another.
  - `value`: The value.
  - `inputStart`: The first range's start.
  - `inputEnd`: Its end.
  - `outputStart`: The second range's start.
  - `outputEnd`: Its end.
  - returns: The value in the second range.
- `Wrap`: Returns a value wrapped around into a range, as an angle wraps around a turn.
  - `value`: The value.
  - `min`: The range's start.
  - `max`: Its end.
  - returns: The value in the range.
- `FloatEquals`: Returns whether two values are equal but for rounding.
  - `x`: One.
  - `y`: The other.
  - returns: 1 if they are, 0 if not.

  Counts them equal when they are no further apart than `EPSILON`, times the larger magnitude when that is over 1.
- `Vector2Zero`: Returns (0, 0).
  - returns: The vector.
- `Vector2One`: Returns (1, 1).
  - returns: The vector.
- `Vector2Add`: Returns the sum of two vectors.
  - `v1`: One.
  - `v2`: The other.
  - returns: The sum.
- `Vector2AddValue`: Returns a vector with a value added to each component.
  - `v`: The vector.
  - `add`: The value.
  - returns: The sum.
- `Vector2Subtract`: Returns one vector less another.
  - `v1`: The first.
  - `v2`: The one taken from it.
  - returns: The difference.
- `Vector2SubtractValue`: Returns a vector with a value taken from each component.
  - `v`: The vector.
  - `sub`: The value.
  - returns: The difference.
- `Vector2Length`: Returns a vector's length.
  - `v`: The vector.
  - returns: The length.
- `Vector2LengthSqr`: Returns a vector's length squared.
  - `v`: The vector.
  - returns: The length squared.
- `Vector2DotProduct`: Returns the dot product.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector2Distance`: Returns the distance between two points.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance.
- `Vector2DistanceSqr`: Returns the distance between two points, squared.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance squared.
- `Vector2Angle`: Returns the angle from one vector to another, from -pi to pi.
  - `v1`: The first.
  - `v2`: The second.
  - returns: The angle, in radians.

  Positive turning from x toward y.
- `Vector2LineAngle`: Returns the angle of the line from one point to another, measured from the x axis.
  - `start`: The line's start.
  - `end`: Its end.
  - returns: The angle, in radians.

  Positive turning from x toward -y.
- `Vector2Scale`: Returns a vector scaled.
  - `v`: The vector.
  - `scale`: The scale.
  - returns: The scaled vector.
- `Vector2Multiply`: Returns two vectors multiplied component by component.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector2Negate`: Returns a vector pointing the other way.
  - `v`: The vector.
  - returns: The negated vector.
- `Vector2Divide`: Returns one vector divided by another, component by component.
  - `v1`: The one divided.
  - `v2`: The one dividing it.
  - returns: The quotient.
- `Vector2Normalize`: Returns a vector of length 1 in the same direction, or (0, 0) for (0, 0).
  - `v`: The vector.
  - returns: The direction.
- `Vector2Transform`: Returns a point transformed by a matrix, the point at z 0.
  - `v`: The point.
  - `mat`: The matrix.
  - returns: The transformed point's x and y.
- `Vector2Lerp`: Returns a point part of the way from one to another.
  - `v1`: The start.
  - `v2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector2Reflect`: Returns a direction reflected off a surface.
  - `v`: The direction.
  - `normal`: The surface's normal, of length 1.
  - returns: The reflected direction.
- `Vector2Min`: Returns the least of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the least.
- `Vector2Max`: Returns the most of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the most.
- `Vector2Rotate`: Returns a vector turned by an angle, from x toward y.
  - `v`: The vector.
  - `angle`: The angle, in radians.
  - returns: The turned vector.
- `Vector2MoveTowards`: Returns a point moved toward a target by at most a distance.
  - `v`: The point.
  - `target`: The target.
  - `maxDistance`: The most it moves.
  - returns: The moved point.

  Gives the target itself when the target is within that distance.
- `Vector2Invert`: Returns 1 divided by each of a vector's components.
  - `v`: The vector.
  - returns: The inverted vector.
- `Vector2Clamp`: Returns a vector with each component kept between two others'.
  - `v`: The vector.
  - `min`: The least components.
  - `max`: The most.
  - returns: The vector.
- `Vector2ClampValue`: Returns a vector with its length kept between two values.
  - `v`: The vector.
  - `min`: The least length.
  - `max`: The most length.
  - returns: The vector.
- `Vector2Equals`: Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.
  - `p`: One.
  - `q`: The other.
  - returns: 1 if they are, 0 if not.
- `Vector2Refract`: Returns a direction bent passing into a surface, or (0, 0) when it is wholly reflected instead.
  - `v`: The direction, of length 1.
  - `n`: The surface's normal, of length 1.
  - `r`: The ratio of the refractive indices, the one it leaves over the one it enters.
  - returns: The bent direction.
- `Vector3Zero`: Returns (0, 0, 0).
  - returns: The vector.
- `Vector3One`: Returns (1, 1, 1).
  - returns: The vector.
- `Vector3Add`: Returns the sum of two vectors.
  - `v1`: One.
  - `v2`: The other.
  - returns: The sum.
- `Vector3AddValue`: Returns a vector with a value added to each component.
  - `v`: The vector.
  - `add`: The value.
  - returns: The sum.
- `Vector3Subtract`: Returns one vector less another.
  - `v1`: The first.
  - `v2`: The one taken from it.
  - returns: The difference.
- `Vector3SubtractValue`: Returns a vector with a value taken from each component.
  - `v`: The vector.
  - `sub`: The value.
  - returns: The difference.
- `Vector3Scale`: Returns a vector scaled.
  - `v`: The vector.
  - `scalar`: The scale.
  - returns: The scaled vector.
- `Vector3Multiply`: Returns two vectors multiplied component by component.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector3CrossProduct`: Returns the cross product.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector3Perpendicular`: Returns a vector perpendicular to another: its cross product with the axis the vector is least along.
  - `v`: The vector.
  - returns: The perpendicular vector.
- `Vector3Length`: Returns a vector's length.
  - `v`: The vector.
  - returns: The length.
- `Vector3LengthSqr`: Returns a vector's length squared.
  - `v`: The vector.
  - returns: The length squared.
- `Vector3DotProduct`: Returns the dot product.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector3Distance`: Returns the distance between two points.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance.
- `Vector3DistanceSqr`: Returns the distance between two points, squared.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance squared.
- `Vector3Angle`: Returns the angle between two vectors, from 0 to pi.
  - `v1`: One.
  - `v2`: The other.
  - returns: The angle, in radians.
- `Vector3Negate`: Returns a vector pointing the other way.
  - `v`: The vector.
  - returns: The negated vector.
- `Vector3Divide`: Returns one vector divided by another, component by component.
  - `v1`: The one divided.
  - `v2`: The one dividing it.
  - returns: The quotient.
- `Vector3Normalize`: Returns a vector of length 1 in the same direction, or the vector itself when its length is 0.
  - `v`: The vector.
  - returns: The direction.
- `Vector3Project`: Returns the part of one vector along another.
  - `v1`: The vector.
  - `v2`: The direction it is projected onto.
  - returns: The projection.
- `Vector3Reject`: Returns the part of one vector across another: the vector less its projection.
  - `v1`: The vector.
  - `v2`: The direction taken out of it.
  - returns: The rejection.
- `Vector3OrthoNormalize`: Makes two vectors of length 1 and at right angles to each other, the first keeping its direction (Gram-Schmidt).
  - `v1`: The first, set to its direction.
  - `v2`: The second, set at right angles to the first, in the plane the two were in and on its own side.
- `Vector3Transform`: Returns a point transformed by a matrix.
  - `v`: The point.
  - `mat`: The matrix.
  - returns: The transformed point.
- `Vector3RotateByQuaternion`: Returns a vector turned by a quaternion.
  - `v`: The vector.
  - `q`: The quaternion.
  - returns: The turned vector.
- `Vector3RotateByAxisAngle`: Returns a vector turned about an axis.
  - `v`: The vector.
  - `axis`: The axis.
  - `angle`: The angle, in radians.
  - returns: The turned vector.
- `Vector3MoveTowards`: Returns a point moved toward a target by at most a distance.
  - `v`: The point.
  - `target`: The target.
  - `maxDistance`: The most it moves.
  - returns: The moved point.

  Gives the target itself when the target is within that distance.
- `Vector3Lerp`: Returns a point part of the way from one to another.
  - `v1`: The start.
  - `v2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector3CubicHermite`: Returns a point part of the way along a cubic Hermite curve, from one point to another, leaving and arriving along tangents.
  - `v1`: The start.
  - `tangent1`: The tangent leaving it.
  - `v2`: The end.
  - `tangent2`: The tangent arriving at it.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector3Reflect`: Returns a direction reflected off a surface.
  - `v`: The direction.
  - `normal`: The surface's normal, of length 1.
  - returns: The reflected direction.
- `Vector3Min`: Returns the least of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the least.
- `Vector3Max`: Returns the most of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the most.
- `Vector3Barycenter`: Returns a point's barycentric coordinates in a triangle: how much of each corner it is made of.
  - `p`: The point.
  - `a`: The first corner.
  - `b`: The second.
  - `c`: The third.
  - returns: How much of a (x), b (y) and c (z).
- `Vector3Unproject`: Returns a point in normalized device coordinates (each from -1 to 1) taken back into the world, through a view and a projection.
  - `source`: The point.
  - `projection`: The projection.
  - `view`: The view.
  - returns: The point in the world.
- `Vector3ToFloatV`: Returns a vector's components as an array: x, y, z.
  - `v`: The vector.
  - returns: The array.
- `Vector3Invert`: Returns 1 divided by each of a vector's components.
  - `v`: The vector.
  - returns: The inverted vector.
- `Vector3Clamp`: Returns a vector with each component kept between two others'.
  - `v`: The vector.
  - `min`: The least components.
  - `max`: The most.
  - returns: The vector.
- `Vector3ClampValue`: Returns a vector with its length kept between two values.
  - `v`: The vector.
  - `min`: The least length.
  - `max`: The most length.
  - returns: The vector.
- `Vector3Equals`: Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.
  - `p`: One.
  - `q`: The other.
  - returns: 1 if they are, 0 if not.
- `Vector3Refract`: Returns a direction bent passing into a surface, or (0, 0, 0) when it is wholly reflected instead.
  - `v`: The direction, of length 1.
  - `n`: The surface's normal, of length 1.
  - `r`: The ratio of the refractive indices, the one it leaves over the one it enters.
  - returns: The bent direction.
- `Vector4Zero`: Returns (0, 0, 0, 0).
  - returns: The vector.
- `Vector4One`: Returns (1, 1, 1, 1).
  - returns: The vector.
- `Vector4Add`: Returns the sum of two vectors.
  - `v1`: One.
  - `v2`: The other.
  - returns: The sum.
- `Vector4AddValue`: Returns a vector with a value added to each component.
  - `v`: The vector.
  - `add`: The value.
  - returns: The sum.
- `Vector4Subtract`: Returns one vector less another.
  - `v1`: The first.
  - `v2`: The one taken from it.
  - returns: The difference.
- `Vector4SubtractValue`: Returns a vector with a value taken from each component.
  - `v`: The vector.
  - `add`: The value.
  - returns: The difference.
- `Vector4Length`: Returns a vector's length.
  - `v`: The vector.
  - returns: The length.
- `Vector4LengthSqr`: Returns a vector's length squared.
  - `v`: The vector.
  - returns: The length squared.
- `Vector4DotProduct`: Returns the dot product.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector4Distance`: Returns the distance between two points.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance.
- `Vector4DistanceSqr`: Returns the distance between two points, squared.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance squared.
- `Vector4Scale`: Returns a vector scaled.
  - `v`: The vector.
  - `scale`: The scale.
  - returns: The scaled vector.
- `Vector4Multiply`: Returns two vectors multiplied component by component.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector4Negate`: Returns a vector pointing the other way.
  - `v`: The vector.
  - returns: The negated vector.
- `Vector4Divide`: Returns one vector divided by another, component by component.
  - `v1`: The one divided.
  - `v2`: The one dividing it.
  - returns: The quotient.
- `Vector4Normalize`: Returns a vector of length 1 in the same direction, or (0, 0, 0, 0) for (0, 0, 0, 0).
  - `v`: The vector.
  - returns: The direction.
- `Vector4Min`: Returns the least of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the least.
- `Vector4Max`: Returns the most of two vectors' components, each on its own.
  - `v1`: One.
  - `v2`: The other.
  - returns: The vector of the most.
- `Vector4Lerp`: Returns a point part of the way from one to another.
  - `v1`: The start.
  - `v2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector4MoveTowards`: Returns a point moved toward a target by at most a distance.
  - `v`: The point.
  - `target`: The target.
  - `maxDistance`: The most it moves.
  - returns: The moved point.

  Gives the target itself when the target is within that distance.
- `Vector4Invert`: Returns 1 divided by each of a vector's components.
  - `v`: The vector.
  - returns: The inverted vector.
- `Vector4Equals`: Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.
  - `p`: One.
  - `q`: The other.
  - returns: 1 if they are, 0 if not.
- `MatrixDeterminant`: Returns a matrix's determinant.
  - `mat`: The matrix.
  - returns: The determinant.
- `MatrixTrace`: Returns a matrix's trace: the sum of its diagonal.
  - `mat`: The matrix.
  - returns: The trace.
- `MatrixTranspose`: Returns a matrix transposed.
  - `mat`: The matrix.
  - returns: Its transpose.
- `MatrixInvert`: Returns a matrix's inverse.
  - `mat`: The matrix.
  - returns: Its inverse.

  Inverting a singular matrix divides by a determinant of 0 and gives infinite or NaN values.
- `MatrixIdentity`: Returns the identity matrix.
  - returns: The matrix.
- `MatrixAdd`: Returns the sum of two matrices.
  - `left`: One.
  - `right`: The other.
  - returns: The sum.
- `MatrixSubtract`: Returns one matrix less another.
  - `left`: The first.
  - `right`: The one taken from it.
  - returns: The difference.
- `MatrixMultiply`: Returns two matrices multiplied: left, then right.
  - `left`: The first.
  - `right`: The second.
  - returns: The product.
- `MatrixTranslate`: Returns a translation.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - returns: The matrix.
- `MatrixRotate`: Returns a rotation about an axis.
  - `axis`: The axis.
  - `angle`: The angle, in radians.
  - returns: The matrix.
- `MatrixRotateX`: Returns a rotation about x.
  - `angle`: The angle, in radians.
  - returns: The matrix.
- `MatrixRotateY`: Returns a rotation about y.
  - `angle`: The angle, in radians.
  - returns: The matrix.
- `MatrixRotateZ`: Returns a rotation about z.
  - `angle`: The angle, in radians.
  - returns: The matrix.
- `MatrixRotateXYZ`: Returns a rotation by three angles that turns a point about z, then y, then x. See `MatrixRotateZYX` for turning in the reverse order.
  - `angle`: The angles, in radians.
  - returns: The matrix.
- `MatrixRotateZYX`: Returns a rotation by three angles that turns a point about x, then y, then z, the reverse of `MatrixRotateXYZ`.
  - `angle`: The angles, in radians.
  - returns: The matrix.
- `MatrixScale`: Returns a scale.
  - `x`: Along x.
  - `y`: Along y.
  - `z`: Along z.
  - returns: The matrix.
- `MatrixFrustum`: Returns a perspective projection by its near plane's edges.
  - `left`: The near plane's left.
  - `right`: Its right.
  - `bottom`: Its bottom.
  - `top`: Its top.
  - `nearPlane`: The near plane.
  - `farPlane`: The far plane.
  - returns: The matrix.
- `MatrixPerspective`: Returns a perspective projection.
  - `fovY`: The field of view, top to bottom, in radians.
  - `aspect`: Width over height.
  - `nearPlane`: The near plane.
  - `farPlane`: The far plane.
  - returns: The matrix.
- `MatrixOrtho`: Returns an orthographic projection.
  - `left`: Left.
  - `right`: Right.
  - `bottom`: Bottom.
  - `top`: Top.
  - `nearPlane`: The near plane.
  - `farPlane`: The far plane.
  - returns: The matrix.
- `MatrixLookAt`: Returns a view looking from eye at target.
  - `eye`: Where from.
  - `target`: What at.
  - `up`: Up.
  - returns: The matrix.
- `MatrixToFloatV`: Returns a matrix's values as an array, by columns: m0 to m15, as a shader takes them.
  - `mat`: The matrix.
  - returns: The array.
- `QuaternionAdd`: Returns the sum of two quaternions.
  - `q1`: One.
  - `q2`: The other.
  - returns: The sum.
- `QuaternionAddValue`: Returns a quaternion with a value added to each component.
  - `q`: The quaternion.
  - `add`: The value.
  - returns: The sum.
- `QuaternionSubtract`: Returns one quaternion less another.
  - `q1`: The first.
  - `q2`: The one taken from it.
  - returns: The difference.
- `QuaternionSubtractValue`: Returns a quaternion with a value taken from each component.
  - `q`: The quaternion.
  - `sub`: The value.
  - returns: The difference.
- `QuaternionIdentity`: Returns the identity quaternion.
  - returns: The quaternion.
- `QuaternionLength`: Returns a quaternion's length.
  - `q`: The quaternion.
  - returns: The length.
- `QuaternionNormalize`: Returns a quaternion of length 1 in the same direction, or the quaternion itself when its length is 0.
  - `q`: The quaternion.
  - returns: The normalized quaternion.
- `QuaternionInvert`: Returns a quaternion's inverse, which for a quaternion of length 1 is the rotation back.
  - `q`: The quaternion.
  - returns: Its inverse.

  Gives the quaternion unchanged when its length is 0.
- `QuaternionMultiply`: Returns two quaternions multiplied: the rotation q2, then q1.
  - `q1`: The first.
  - `q2`: The second.
  - returns: The product.
- `QuaternionScale`: Returns a quaternion scaled.
  - `q`: The quaternion.
  - `mul`: The scale.
  - returns: The scaled quaternion.
- `QuaternionDivide`: Returns one quaternion divided by another, component by component.
  - `q1`: The one divided.
  - `q2`: The one dividing it.
  - returns: The quotient.
- `QuaternionLerp`: Returns a quaternion part of the way from one to another, component by component.
  - `q1`: The start.
  - `q2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The quaternion.
- `QuaternionNlerp`: Returns a quaternion part of the way from one to another, component by component, then normalized.
  - `q1`: The start.
  - `q2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The quaternion.
- `QuaternionSlerp`: Returns a rotation part of the way from one to another at a steady turn, the short way round (spherical linear interpolation).
  - `q1`: The start.
  - `q2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The quaternion.
- `QuaternionCubicHermiteSpline`: Returns a rotation part of the way along a cubic Hermite curve, from one quaternion to another, leaving and arriving along tangents, normalized.
  - `q1`: The start.
  - `outTangent1`: The tangent leaving it.
  - `q2`: The end.
  - `inTangent2`: The tangent arriving at it.
  - `t`: 0 for the start, 1 for the end.
  - returns: The quaternion.
- `QuaternionFromVector3ToVector3`: Returns the rotation turning one direction to another.
  - `from`: The direction turned from.
  - `to`: The direction turned to.
  - returns: The quaternion, of length 1; all 0 when either direction is.

  Takes directions of any length.

  Opposite directions give half a turn about a direction square to the first.
- `QuaternionFromMatrix`: Returns a rotation matrix's rotation as a quaternion.
  - `mat`: The matrix.
  - returns: The quaternion.
- `QuaternionToMatrix`: Returns a quaternion's rotation as a matrix.
  - `q`: The quaternion.
  - returns: The matrix.
- `QuaternionFromAxisAngle`: Returns the rotation about an axis as a quaternion, normalized.
  - `axis`: The axis.
  - `angle`: The angle, in radians.
  - returns: The quaternion.

  Gives the identity for an axis of length 0.
- `QuaternionToAxisAngle`: Finds a quaternion's rotation as an axis and an angle about it.
  - `q`: The quaternion, normalized first when its w is over 1 either way.
  - `outAxis`: Its first element is set to the axis, of length 1.
  - `outAngle`: Its first element is set to the angle, in radians.

  Gives x as the axis when the angle is 0.
- `QuaternionFromEuler`: Returns a rotation by Euler angles as a quaternion.
  - `pitch`: About x, in radians.
  - `yaw`: About y.
  - `roll`: About z.
  - returns: The quaternion.
- `QuaternionToEuler`: Returns a quaternion's rotation as Euler angles: about x (pitch), y (yaw) and z (roll), as `QuaternionFromEuler` takes them.
  - `q`: The quaternion.
  - returns: The angles, in radians.
- `QuaternionTransform`: Returns a quaternion's four components transformed by a matrix, as a point with w.
  - `q`: The quaternion.
  - `mat`: The matrix.
  - returns: The transformed quaternion.
- `QuaternionEquals`: Returns whether two quaternions are the same rotation but for rounding: equal as `FloatEquals` compares each component, or one the other negated.
  - `p`: One.
  - `q`: The other.
  - returns: 1 if they are, 0 if not.
- `MatrixDecompose`: Splits a transform matrix into its translation, rotation and scale.
  - `mat`: The matrix.
  - `translation`: Set to its translation.
  - `rotation`: Set to its rotation.
  - `scale`: Set to its scale.

  Makes the columns orthonormal one after another. The orthonormal columns are the rotation, and their lengths are the scale.

  Drops any shear between the columns.

  Decomposing a matrix that mirrors negates all three components of the scale.
