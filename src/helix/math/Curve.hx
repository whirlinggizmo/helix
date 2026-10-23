package helix.math;

import helix.math.CurveKind;

/** A curve through or near points in 2D or 3D (a camera rail, a patrol path, a projectile's arc), asked where it is at t from 0 to 1 along its
	whole length, which way it heads there, how long it is, and the t at a distance along it, so something moves along it at a steady speed.
	Kinds: through its points (Catmull-Rom, centripetal: no loops or kinks between unevenly spaced points), by control points (cubic Bézier,
	a curve from each four), or straight between points (a polyline); open, or closed back to the start. Points are flat (x, y or x, y, z, as
	the dimensions say), as HeliX passes positions; a curve's points are fixed once made. */
class Curve {
	// Samples a segment for the length table.
	static inline var SAMPLES = 16;

	var points:Array<Float>;
	var count:Int;
	var segments:Int;
	// The length table: the cumulative length at each sample, lazily.
	var lengths:Null<Array<Float>>;

	function new(kind:CurveKind, points:Array<Float>, dimensions:Int, closed:Bool) {
		if (dimensions != 2 && dimensions != 3)
			throw 'A curve is in 2 or 3 dimensions, not $dimensions';
		if (points.length % dimensions != 0)
			throw 'A curve\'s points are ${dimensions} numbers each: ${points.length} don\'t divide';
		this.kind = kind;
		this.dimensions = dimensions;
		this.points = points.copy();
		count = Std.int(points.length / dimensions);
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

	/** A curve through every point in order (Catmull-Rom, centripetal), closed back to the first when closed. Throws for fewer than 2 points
		or a count that doesn't divide by dimensions. */
	public static function through(points:Array<Float>, dimensions = 2, closed = false):Curve
		return new Curve(Through, points, dimensions, closed);

	/** Cubic Bézier pieces: the first point, then three for each piece (two control points and the piece's end), the pieces joined. Throws for
		another count. */
	public static function bezier(points:Array<Float>, dimensions = 2):Curve
		return new Curve(Bezier, points, dimensions, false);

	/** Straight from point to point, closed back to the first when closed. Throws for fewer than 2 points. */
	public static function polyline(points:Array<Float>, dimensions = 2, closed = false):Curve
		return new Curve(Polyline, points, dimensions, closed);

	/** Its kind. */
	public var kind(default, null):CurveKind;

	/** 2 or 3. */
	public var dimensions(default, null):Int;

	/** Whether it comes back to its start. */
	public var closed(default, null):Bool;

	/** How many points it was made with. */
	public var pointCount(get, never):Int;

	function get_pointCount():Int
		return count;

	/** Point index's coordinate axis (0 x, 1 y, 2 z); 0 past them. */
	public function getPoint(index:Int, axis:Int):Float
		return index < 0 || index >= count || axis < 0 || axis >= dimensions ? 0 : points[index * dimensions + axis];

	/** X at t, 0 to 1 along the whole curve (held to it; around it when closed). */
	public function getX(t:Float):Float
		return at(t, 0);

	/** Y at t. */
	public function getY(t:Float):Float
		return at(t, 1);

	/** Z at t; 0 in 2D. */
	public function getZ(t:Float):Float
		return dimensions < 3 ? 0 : at(t, 2);

	/** Where it is at t, all axes into out (x, y and z in 3D), which it returns. */
	public function evaluate(t:Float, out:Array<Float>):Array<Float> {
		for (axis in 0...dimensions)
			out[axis] = at(t, axis);
		return out;
	}

	/** Which way it heads at t, as a unit vector into out (x, y and z in 3D), which it returns; 0s where it doesn't move. */
	public function tangent(t:Float, out:Array<Float>):Array<Float> {
		var h = 1e-4, length = 0.;
		var before = closed ? t - h : Math.max(0, t - h),
			after = closed ? t + h : Math.min(1, t + h);
		for (axis in 0...dimensions) {
			out[axis] = at(after, axis) - at(before, axis);
			length += out[axis] * out[axis];
		}
		length = Math.sqrt(length);
		for (axis in 0...dimensions)
			out[axis] = length > 0 ? out[axis] / length : 0;
		return out;
	}

	/** Its length, measured along it (SAMPLES straight pieces a segment). */
	public var length(get, never):Float;

	function get_length():Float {
		table();
		return lengths[lengths.length - 1];
	}

	/** The t at distance along it from the start (held to its length; around it when closed), so steps of equal distance move at a steady
		speed where equal steps of t don't. */
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
		return points[index * dimensions + axis];
	}

	function bezierAt(segment:Int, u:Float, axis:Int):Float {
		var i = segment * 3, v = 1 - u;
		var p0 = points[i * dimensions + axis],
			p1 = points[(i + 1) * dimensions + axis],
			p2 = points[(i + 2) * dimensions + axis],
			p3 = points[(i + 3) * dimensions + axis];
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
		for (axis in 0...dimensions) {
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
		evaluate(0, previous);
		lengths = [0];
		for (i in 1...n + 1) {
			evaluate(i / n, current);
			var d = 0.;
			for (axis in 0...dimensions) {
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
