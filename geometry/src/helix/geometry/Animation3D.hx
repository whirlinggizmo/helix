package helix.geometry;

import helix.math.Quaternion3D;
import helix.math.Transform3D;

/** Represents an animation of a skeleton: tracks moving its bones over time. */
class Animation3D {
	/** Gets its name: empty for none. */
	public final name:String;

	/** Gets its tracks. */
	public final tracks:Array<AnimationTrack3D>;

	/** Gets how long it lasts, in seconds: the latest key of all its tracks; 0 without keys. */
	public var duration(get, never):Float;

	function get_duration():Float {
		var last = 0.;
		for (track in tracks)
			if (track.times.length > 0 && track.times[track.times.length - 1] > last)
				last = track.times[track.times.length - 1];
		return last;
	}

	/** Creates an animation.

		@param name  Its name.
		@param tracks  Its tracks. */
	public function new(name:String, tracks:Array<AnimationTrack3D>) {
		this.name = name;
		this.tracks = tracks;
	}

	/** Returns a skeleton's pose at a time: its rest pose, with each track's part of its bone's transform at that time; a bone no track
		moves keeps its rest. Before a track's first key it holds the first; after its last, the last, so playing it over and over is the
		caller's (the time modulo `duration`).

		@param skeleton  The skeleton.
		@param time  The time, in seconds.
		@param out  Optional. Set to the pose, its transforms reused, grown or shrunk to fit.
		@return  Each bone's transform relative to its parent. */
	public function computePose(skeleton:Skeleton3D, time:Float, ?out:Array<Transform3D>):Array<Transform3D> {
		out = skeleton.computeRestPose(out);
		for (track in tracks) {
			var keys = track.times, count = keys.length;
			if (count == 0 || track.bone < 0 || track.bone >= out.length)
				continue;
			var size = track.property == Rotation ? 4 : 3,
				cubic = track.interpolation == CubicSpline;
			// A key's value starts here: after its in-tangent, for a cubic track.
			inline function at(key:Int):Int
				return cubic ? key * size * 3 + size : key * size;
			var v = track.values, target = out[track.bone];
			// The key at or before the time, and how far on to the next.
			var k = 0;
			while (k + 1 < count && keys[k + 1] <= time)
				k++;
			var span = k + 1 < count ? keys[k + 1] - keys[k] : 0.,
				t = span > 0 && time > keys[k] ? (time - keys[k]) / span : 0.;
			if (time <= keys[0] || k + 1 >= count || track.interpolation == Step || span <= 0)
				t = 0;
			for (c in 0...size) {
				var a = v[at(k) + c], b = k + 1 < count ? v[at(k + 1) + c] : a;
				if (cubic && t > 0) {
					var t2 = t * t, t3 = t2 * t;
					var outTangent = v[at(k) + size + c],
						inTangent = v[at(k + 1) - size + c];
					scratch[c] = (2 * t3 - 3 * t2 + 1) * a + (t3 - 2 * t2 + t) * span * outTangent + (-2 * t3 + 3 * t2) * b + (t3 - t2) * span * inTangent;
				} else
					scratch[c] = t == 0 ? a : a + (b - a) * t;
			}
			switch track.property {
				case Translation:
					target.position.set(scratch[0], scratch[1], scratch[2]);
				case Scale:
					target.scale.set(scratch[0], scratch[1], scratch[2]);
				case Rotation:
					if (track.interpolation == Linear && t > 0) {
						from.set(v[at(k)], v[at(k) + 1], v[at(k) + 2], v[at(k) + 3]);
						to.set(v[at(k + 1)], v[at(k + 1) + 1], v[at(k + 1) + 2], v[at(k + 1) + 3]);
						Quaternion3D.slerp(from, to, t, target.rotation);
					} else
						target.rotation.set(scratch[0], scratch[1], scratch[2], scratch[3]).normalize(target.rotation);
			}
		}
		return out;
	}

	// A key's components between keys, and two rotations to go between, reused.
	static final scratch = [0., 0, 0, 0];

	static final from = new Quaternion3D();

	static final to = new Quaternion3D();
}
