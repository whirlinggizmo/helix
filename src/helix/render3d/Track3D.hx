package helix.render3d;

import haxe.ds.Vector;

/** One node's motion along one path in a clip: the node by name, its keys' times (seconds, rising) and values. */
class Track3D {
	/** The node it moves, by name: bound under whatever an Animator3D plays it on. */
	public final target:String;

	/** What it moves. */
	public final path:TrackPath3D;

	/** How it runs between keys. */
	public final interpolation:TrackInterpolation3D;

	/** Its keys' times, seconds, rising. */
	public final times:Vector<Float>;

	/** Its keys' values, one after another (3 floats a key, or 4 for a rotation; for a cubic spline, the in-tangent, value and out-tangent of
		each key). */
	public final values:Vector<Float>;

	/** A track moving target's path through times and values. Throws for values that don't match the times, or times that fall. */
	public function new(target:String, path:TrackPath3D, interpolation:TrackInterpolation3D, times:Array<Float>, values:Array<Float>) {
		var width = path == Rotation ? 4 : 3;
		if (times.length == 0 || values.length != times.length * width * (interpolation == CubicSpline ? 3 : 1))
			throw 'A track of $target whose values don\'t match its times';
		for (i in 1...times.length)
			if (times[i] < times[i - 1])
				throw 'A track of $target whose times fall';
		this.target = target;
		this.path = path;
		this.interpolation = interpolation;
		this.times = Vector.fromArrayCopy(times);
		this.values = Vector.fromArrayCopy(values);
	}

	/** Its value at seconds (held before its first key and after its last), into out (3 floats, or 4 for a rotation, normalized). */
	public function sample(seconds:Float, out:Vector<Float>):Void {
		var width = path == Rotation ? 4 : 3,
			count = times.length,
			cubic = interpolation == CubicSpline;
		// The value of key k, element c: a cubic spline's keys are each three values, the value the middle one.
		inline function value(k:Int, c:Int):Float
			return values[cubic ? (k * 3 + 1) * width + c : k * width + c];
		if (seconds <= times[0] || count == 1) {
			for (c in 0...width)
				out[c] = value(0, c);
			return;
		}
		if (seconds >= times[count - 1]) {
			for (c in 0...width)
				out[c] = value(count - 1, c);
			return;
		}
		// The last key at or before seconds.
		var lo = 0, hi = count - 1;
		while (hi - lo > 1) {
			var mid = (lo + hi) >> 1;
			if (times[mid] <= seconds)
				lo = mid;
			else
				hi = mid;
		}
		var span = times[hi] - times[lo],
			t = span > 0 ? (seconds - times[lo]) / span : 0.;
		switch interpolation {
			case Step:
				for (c in 0...width)
					out[c] = value(lo, c);
				return;
			case CubicSpline:
				var t2 = t * t, t3 = t2 * t;
				var h00 = 2 * t3 - 3 * t2 + 1, h10 = t3 - 2 * t2 + t, h01 = -2 * t3 + 3 * t2, h11 = t3 - t2;
				for (c in 0...width) {
					var outTangent = values[(lo * 3 + 2) * width + c],
						inTangent = values[(hi * 3) * width + c];
					out[c] = h00 * value(lo, c) + h10 * span * outTangent + h01 * value(hi, c) + h11 * span * inTangent;
				}
			case Linear:
				if (path == Rotation) {
					slerp(value(lo, 0), value(lo, 1), value(lo, 2), value(lo, 3), value(hi, 0), value(hi, 1), value(hi, 2), value(hi, 3), t, out);
					return;
				}
				for (c in 0...width)
					out[c] = value(lo, c) + (value(hi, c) - value(lo, c)) * t;
		}
		if (path == Rotation)
			normalize(out);
	}

	/** The rotation t of the way from quaternion a to b along the shorter arc, into out (normalized). */
	public static function slerp(ax:Float, ay:Float, az:Float, aw:Float, bx:Float, by:Float, bz:Float, bw:Float, t:Float, out:Vector<Float>):Void {
		var dot = ax * bx + ay * by + az * bz + aw * bw;
		// The shorter way round: q and -q are the same rotation.
		if (dot < 0) {
			bx = -bx;
			by = -by;
			bz = -bz;
			bw = -bw;
			dot = -dot;
		}
		var wa = 1 - t, wb = t;
		// Nearly the same rotation: a straight line is as good, and doesn't divide by a vanishing sine.
		if (dot < .9995) {
			var angle = Math.acos(dot), sine = Math.sin(angle);
			wa = Math.sin((1 - t) * angle) / sine;
			wb = Math.sin(t * angle) / sine;
		}
		out[0] = ax * wa + bx * wb;
		out[1] = ay * wa + by * wb;
		out[2] = az * wa + bz * wb;
		out[3] = aw * wa + bw * wb;
		normalize(out);
	}

	static inline function normalize(q:Vector<Float>):Void {
		var length = Math.sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3]);
		if (length > 0)
			for (c in 0...4)
				q[c] /= length;
	}
}
