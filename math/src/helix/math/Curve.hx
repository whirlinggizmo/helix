package helix.math;

import helix.math.CurveKind;

/** Represents a curve through or near points in 2 or 3 dimensions: a camera rail, a patrol path, a projectile's arc.

	A curve is made by `through`, `bezier` or `polyline`, and its points are fixed once made. It is asked where it is and which way it heads
	at a parameter t, from 0 at its start to 1 at its end, and how long it is. Equal steps of t are not equal distances along it:
	`getParameterAtDistance` gives the t at a distance, for moving along it at a steady speed. Points are given flat, x, y or x, y, z each.
	```haxe
	var rail = Curve.through([0, 0, 100, 50, 200, 0]);
	var t = rail.getParameterAtDistance(speed * time);
	var x = rail.getX(t), y = rail.getY(t);
	```
 */
class Curve {
	// Samples a segment for the length table.
	static inline var SAMPLES = 16;

	var points:Array<Float>;
	var count:Int;
	var segments:Int;
	// The length table: the cumulative length at each sample, lazily.
	var lengths:Null<Array<Float>>;

	function new(kind:CurveKind, points:Array<Float>, dimensionCount:Int, closed:Bool) {
		if (dimensionCount != 2 && dimensionCount != 3)
			throw 'A curve is in 2 or 3 dimensions, not $dimensionCount';
		if (points.length % dimensionCount != 0)
			throw 'A curve\'s points are ${dimensionCount} numbers each: ${points.length} don\'t divide';
		this.kind = kind;
		this.dimensionCount = dimensionCount;
		this.points = points.copy();
		count = Std.int(points.length / dimensionCount);
		switch kind {
			case Through | Polyline:
				if (count < 2)
					throw 'A curve needs at least 2 points, not $count';
				this.closed = closed;
				segments = closed ? count : count - 1;
			case Bezier:
				if (count < 4 || (count - 1) % 3 != 0)
					throw 'A Bézier curve has 4 points, then 3 more for each further piece, not $count';
				this.closed = false;
				segments = Std.int((count - 1) / 3);
		}
	}

	/** Returns a curve that passes smoothly through every point in order.

		It is a centripetal Catmull-Rom spline, which makes no loops or kinks between unevenly spaced points.
		@param points  The points, flat: x, y or x, y, z each.
		@param dimensionCount  Optional. 2 or 3; defaults to 2.
		@param closed  Optional. Whether it comes back to the first point; defaults to false.
		@return  The curve.
		@throws String  Fewer than 2 points, or a count of numbers that dimensions doesn't divide. */
	public static function through(points:Array<Float>, dimensionCount = 2, closed = false):Curve
		return new Curve(Through, points, dimensionCount, closed);

	/** Returns a curve of joined cubic Bézier pieces.

		@param points  The first point, then three for each piece: two control points and the piece's end. Flat: x, y or x, y, z each.
		@param dimensionCount  Optional. 2 or 3; defaults to 2.
		@return  The curve.
		@throws String  A point count other than 4, 7, 10 and so on. */
	public static function bezier(points:Array<Float>, dimensionCount = 2):Curve
		return new Curve(Bezier, points, dimensionCount, false);

	/** Returns a curve straight from point to point.

		@param points  The points, flat: x, y or x, y, z each.
		@param dimensionCount  Optional. 2 or 3; defaults to 2.
		@param closed  Optional. Whether it comes back to the first point; defaults to false.
		@return  The curve.
		@throws String  Fewer than 2 points, or a count of numbers that dimensions doesn't divide. */
	public static function polyline(points:Array<Float>, dimensionCount = 2, closed = false):Curve
		return new Curve(Polyline, points, dimensionCount, closed);

	/** Gets how the curve passes its points. */
	public var kind(default, null):CurveKind;

	/** Gets the number of dimensions: 2 or 3. */
	public var dimensionCount(default, null):Int;

	/** Gets a value indicating whether the curve comes back to its start. */
	public var closed(default, null):Bool;

	/** Gets the number of points the curve was made with. */
	public var pointCount(get, never):Int;

	function get_pointCount():Int
		return count;

	/** Returns one coordinate of one of the points the curve was made with.

		@param pointIndex  The point's index.
		@param axis  The axis: 0 for x, 1 for y, 2 for z.
		@return  The coordinate, or 0 for an index or axis out of range. */
	public function getPoint(pointIndex:Int, axis:Int):Float
		return pointIndex < 0
			|| pointIndex >= count
			|| axis < 0
			|| axis >= dimensionCount ? 0 : points[pointIndex * dimensionCount + axis];

	/** Returns the x coordinate at a parameter.

		A parameter outside 0 to 1 is clamped to it, or wrapped around a closed curve.
		@param t  The parameter: 0 at the start, 1 at the end.
		@return  The x coordinate. */
	public function getX(t:Float):Float
		return at(t, 0);

	/** Returns the y coordinate at a parameter, as `getX` does.

		@param t  The parameter: 0 at the start, 1 at the end.
		@return  The y coordinate. */
	public function getY(t:Float):Float
		return at(t, 1);

	/** Returns the z coordinate at a parameter, as `getX` does.

		@param t  The parameter: 0 at the start, 1 at the end.
		@return  The z coordinate, or 0 in 2 dimensions. */
	public function getZ(t:Float):Float
		return dimensionCount < 3 ? 0 : at(t, 2);

	/** Returns the position at a parameter, every coordinate at once.

		@param t  The parameter: 0 at the start, 1 at the end.
		@param out  Optional. The array to fill with x and y, and z in 3 dimensions; a new one when omitted.
		@return  The position. */
	public function computePosition(t:Float, ?out:Array<Float>):Array<Float> {
		if (out == null)
			out = [for (_ in 0...dimensionCount) 0.];
		for (axis in 0...dimensionCount)
			out[axis] = at(t, axis);
		return out;
	}

	/** Returns the direction the curve heads at a parameter.

		@param t  The parameter: 0 at the start, 1 at the end.
		@param out  Optional. The array to fill with the direction as a unit vector, x and y, and z in 3 dimensions; zeros where the curve
			doesn't move. A new one when omitted.
		@return  The direction. */
	public function computeTangent(t:Float, ?out:Array<Float>):Array<Float> {
		if (out == null)
			out = [for (_ in 0...dimensionCount) 0.];
		var h = 1e-4, length = 0.;
		var before = closed ? t - h : Math.max(0, t - h),
			after = closed ? t + h : Math.min(1, t + h);
		for (axis in 0...dimensionCount) {
			out[axis] = at(after, axis) - at(before, axis);
			length += out[axis] * out[axis];
		}
		length = Math.sqrt(length);
		for (axis in 0...dimensionCount)
			out[axis] = length > 0 ? out[axis] / length : 0;
		return out;
	}

	/** Gets the curve's length, measured along it in 16 straight pieces between each two points. */
	public var length(get, never):Float;

	function get_length():Float {
		table();
		return lengths[lengths.length - 1];
	}

	/** Returns the parameter at a distance along the curve from its start.

		Steps of equal distance move at a steady speed, where equal steps of t don't. A distance past the ends is clamped to them, or
		wrapped around a closed curve.
		@param distance  The distance from the start.
		@return  The parameter, from 0 to 1. */
	public function getParameterAtDistance(distance:Float):Float {
		table();
		var total = lengths[lengths.length - 1];
		if (total <= 0)
			return 0;
		if (closed) {
			distance %= total;
			if (distance < 0)
				distance += total;
		} else if (distance <= 0)
			return 0;
		else if (distance >= total)
			return 1;
		// The sample the distance falls in, by bisection, then straight between it and the next.
		var low = 0, high = lengths.length - 1;
		while (high - low > 1) {
			var mid = (low + high) >> 1;
			if (lengths[mid] <= distance)
				low = mid;
			else
				high = mid;
		}
		var span = lengths[high] - lengths[low];
		var within = span > 0 ? (distance - lengths[low]) / span : 0;
		return (low + within) / (lengths.length - 1);
	}

	// The coordinate on axis at t.
	function at(t:Float, axis:Int):Float {
		if (closed) {
			t %= 1;
			if (t < 0)
				t += 1;
		} else
			t = t < 0 ? 0 : t > 1 ? 1 : t;
		var scaled = t * segments, segment = Math.floor(scaled);
		if (segment >= segments) {
			segment = segments - 1;
		}
		var u = scaled - segment;
		return switch kind {
			case Polyline: coordinate(segment, axis) + (coordinate(segment + 1, axis) - coordinate(segment, axis)) * u;
			case Bezier: bezierAt(segment, u, axis);
			case Through: catmullRomAt(segment, u, axis);
		}
	}

	// Point index's coordinate, wrapped around a closed curve and held at an open one's ends (Catmull-Rom's ghost points).
	function coordinate(index:Int, axis:Int):Float {
		if (closed)
			index = ((index % count) + count) % count;
		else
			index = index < 0 ? 0 : index >= count ? count - 1 : index;
		return points[index * dimensionCount + axis];
	}

	function bezierAt(segment:Int, u:Float, axis:Int):Float {
		var i = segment * 3, v = 1 - u;
		var p0 = points[i * dimensionCount + axis],
			p1 = points[(i + 1) * dimensionCount + axis],
			p2 = points[(i + 2) * dimensionCount + axis],
			p3 = points[(i + 3) * dimensionCount + axis];
		return v * v * v * p0 + 3 * v * v * u * p1 + 3 * v * u * u * p2 + u * u * u * p3;
	}

	// Centripetal Catmull-Rom (alpha 1/2) between points segment and segment + 1, Barry and Goldman's form.
	function catmullRomAt(segment:Int, u:Float, axis:Int):Float {
		var i0 = segment - 1, i1 = segment, i2 = segment + 1, i3 = segment + 2;
		var t0 = 0., t1 = t0 + knot(i0, i1), t2 = t1 + knot(i1, i2), t3 = t2 + knot(i2, i3);
		var t = t1 + (t2 - t1) * u;
		var p0 = coordinate(i0, axis),
			p1 = coordinate(i1, axis),
			p2 = coordinate(i2, axis),
			p3 = coordinate(i3, axis);
		var a1 = t1 == t0 ? p0 : (t1 - t) / (t1 - t0) * p0 + (t - t0) / (t1 - t0) * p1,
			a2 = t2 == t1 ? p1 : (t2 - t) / (t2 - t1) * p1 + (t - t1) / (t2 - t1) * p2,
			a3 = t3 == t2 ? p2 : (t3 - t) / (t3 - t2) * p2 + (t - t2) / (t3 - t2) * p3;
		var b1 = t2 == t0 ? a1 : (t2 - t) / (t2 - t0) * a1 + (t - t0) / (t2 - t0) * a2,
			b2 = t3 == t1 ? a2 : (t3 - t) / (t3 - t1) * a2 + (t - t1) / (t3 - t1) * a3;
		return t2 == t1 ? b1 : (t2 - t) / (t2 - t1) * b1 + (t - t1) / (t2 - t1) * b2;
	}

	// The knot spacing between two points: the square root of their distance (centripetal); a hair for points on top of each other.
	function knot(a:Int, b:Int):Float {
		var d = 0.;
		for (axis in 0...dimensionCount) {
			var e = coordinate(b, axis) - coordinate(a, axis);
			d += e * e;
		}
		var k = Math.sqrt(Math.sqrt(d));
		return k > 1e-6 ? k : 1e-6;
	}

	// The cumulative lengths at SAMPLES points a segment, measured straight between them.
	function table():Void {
		if (lengths != null)
			return;
		var n = segments * SAMPLES, sum = 0., previous = [], current = [];
		computePosition(0, previous);
		lengths = [0];
		for (i in 1...n + 1) {
			computePosition(i / n, current);
			var d = 0.;
			for (axis in 0...dimensionCount) {
				var e = current[axis] - previous[axis];
				d += e * e;
			}
			sum += Math.sqrt(d);
			lengths.push(sum);
			var swap = previous;
			previous = current;
			current = swap;
		}
	}
}
