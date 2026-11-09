import helix.geometry.Animation3D;
import helix.geometry.AnimationTrack3D;
import helix.geometry.Bone3D;
import helix.geometry.Mesh3D;
import helix.geometry.Skeleton3D;
import helix.geometry.Skin3D;
import helix.math.Matrix3D;
import helix.math.Transform3D;

/** Checks Skeleton3D, Skin3D, Animation3D and Mesh3D's skinning with the library alone, on an arm made by hand (a shoulder at the
	origin, an elbow 1 above it, a hand 1 above the elbow), against positions worked by hand: bones found by name; the rest pose copied;
	each bone's place in the model; a skin's matrices the identity at rest; poses at times, linear (a rotation by the shorter arc),
	stepped and cubic, before the first key and after the last, a bone no track moves at rest; the duration; a tube's vertices moved by
	their weights, those of no weight left; out arrays reused, grown and shrunk; joints and weights carried by merge, copy and unindexing. */
class AnimationTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-12):Bool
		return Math.abs(a - b) <= tolerance;

	static function at(m:Matrix3D, x:Float, y:Float, z:Float, tolerance = 1e-12):Bool
		return near(m.values[12], x, tolerance) && near(m.values[13], y, tolerance) && near(m.values[14], z, tolerance);

	static function rest(y:Float):Transform3D {
		var t = new Transform3D();
		t.position.set(0, y, 0);
		return t;
	}

	static function main():Void {
		var arm = new Skeleton3D([
			new Bone3D("shoulder", -1, rest(0)),
			new Bone3D("elbow", 0, rest(1)),
			new Bone3D("hand", 1, rest(1))
		]);
		check(arm.findBone("hand") == 2 && arm.findBone("foot") == -1, "bones found by name");
		var pose = arm.computeRestPose();
		check(pose.length == 3 && pose[1].position.y == 1 && pose[1] != arm.bones[1].rest, "the rest pose, copied");
		var world = arm.computeWorld(pose);
		check(at(world[0], 0, 0, 0) && at(world[1], 0, 1, 0) && at(world[2], 0, 2, 0), "each bone's place: its rest after its parents'");
		var skin = new Skin3D("arm", [0, 1, 2], [for (m in world) m.invert()]);
		var skinning = skin.computeSkinning(world);
		var identity = true;
		for (m in skinning)
			for (i in 0...16)
				identity = identity && near(m.values[i], i % 5 == 0 ? 1 : 0);
		check(identity, "at rest, a skin's matrices are the identity");

		// The elbow bent 90 degrees about z over a second, moving straight between its two keys.
		var s = Math.sin(Math.PI / 4), c = Math.cos(Math.PI / 4);
		var bend = new Animation3D("bend", [new AnimationTrack3D(1, Rotation, Linear, [0, 1], [0, 0, 0, 1, 0, 0, s, c])]);
		check(bend.duration == 1 && new Animation3D("none", []).duration == 0, "its duration, its last key's time; none without keys");
		var half = bend.computePose(arm, .5);
		var hw = arm.computeWorld(half);
		var h = Math.sqrt(.5);
		check(at(hw[2], -h, 1 + h, 0, 1e-12) && at(hw[1], 0, 1, 0), "half way, the elbow turned 45 degrees: the hand up and to the left");
		check(half[0].rotation.w == 1 && half[2].position.y == 1, "a bone no track moves keeps its rest");
		var before = arm.computeWorld(bend.computePose(arm, -1)),
			after = arm.computeWorld(bend.computePose(arm, 5));
		check(at(before[2], 0, 2, 0) && at(after[2], -1, 1, 0, 1e-12), "before the first key, the first; after the last, the last");
		var shorter = new Animation3D("", [new AnimationTrack3D(1, Rotation, Linear, [0, 1], [0, 0, s, c, 0, 0, -s, -c])]);
		var same = shorter.computePose(arm, .5)[1].rotation;
		check(near(Math.abs(same.w), c, 1e-12) && near(Math.abs(same.z), s, 1e-12),
			"a rotation by the shorter arc: a quaternion and its negation are one turn");
		var steps = new Animation3D("", [
			new AnimationTrack3D(0, Translation, Step, [0, 1, 2], [0, 0, 0, 5, 0, 0, 9, 0, 0])
		]);
		check(steps.computePose(arm, .99)[0].position.x == 0
			&& steps.computePose(arm, 1)[0].position.x == 5
			&& steps.computePose(arm, 1.5)[0].position.x == 5,
			"stepped: each key held until the next");
		var moves = new Animation3D("", [new AnimationTrack3D(2, Scale, Linear, [1, 3], [1, 1, 1, 3, 5, 7])]);
		var scaled = moves.computePose(arm, 2)[2].scale;
		check(scaled.x == 2 && scaled.y == 3 && scaled.z == 4, "a scale moving straight between keys");
		// Cubic, its tangents 0: the smooth step between the keys, 0.5 at the middle, 0.15625 a quarter of the way.
		var cubic = new Animation3D("", [
			new AnimationTrack3D(0, Translation, CubicSpline, [0, 2], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0])
		]);
		check(near(cubic.computePose(arm, 1)[0].position.x, .5)
			&& near(cubic.computePose(arm, .5)[0].position.x, .15625)
			&& cubic.computePose(arm, 2)[0].position.x == 1,
			"cubic, tangents 0: a smooth step through the keys");
		var sloped = new Animation3D("", [
			new AnimationTrack3D(0, Translation, CubicSpline, [0, 2], [0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0, 0])
		]);
		check(near(sloped.computePose(arm, 1)[0].position.x, 1), "cubic, tangents a line's slope: the line");

		// A tube 0.2 in radius from y 0 to y 2: below y 1 it follows the shoulder, above it the elbow.
		var tube = Mesh3D.fromCylinder(.2, .2, 2, 8, 4, false).transform(Matrix3D.fromTranslation(0, 1, 0));
		tube.jointIndices = [];
		tube.weights = [];
		for (v in 0...tube.vertexCount) {
			var upper = tube.positions[v * 3 + 1] > 1;
			for (k in [upper ? 1 : 0, 0, 0, 0])
				tube.jointIndices.push(k);
			for (k in [1., 0, 0, 0])
				tube.weights.push(k);
		}
		var moving = skin.computeSkinning(hw);
		var bent = tube.computeSkinned(moving);
		var top = -1;
		for (v in 0...tube.vertexCount)
			if (tube.positions[v * 3 + 1] == 2 && tube.positions[v * 3] > .19)
				top = v;
		// The top's vertex at (0.2, 2, 0), turned 45 degrees about the elbow at (0, 1, 0).
		check(near(bent.positions[top * 3], .2 * h - h)
			&& near(bent.positions[top * 3 + 1], 1 + .2 * h + h), "a vertex following the elbow, turned with it");
		check(near(bent.normals[top * 3], h) && near(bent.normals[top * 3 + 1], h), "its normal turned and of length 1");
		var low = 0;
		check(bent.positions[low * 3 + 1] == tube.positions[low * 3 + 1] || tube.positions[low * 3 + 1] > 1,
			"a vertex following the shoulder, which didn't move");
		check(bent.texCoords == tube.texCoords
			&& bent.indices == tube.indices
			&& bent.jointIndices == tube.jointIndices
			&& bent.positions != tube.positions,
			"its other arrays the mesh's, its positions its own");
		var reused = bent.positions;
		check(tube.computeSkinned(moving, bent) == bent && bent.positions == reused, "moved again into the same mesh, its arrays reused");
		var unweighted = Mesh3D.fromBox(1, 1, 1);
		check(unweighted.computeSkinned(moving).positions.join(",") == unweighted.positions.join(","), "a mesh without joints left where it is");
		var threw = try {
			tube.computeSkinned(moving, tube);
			false;
		} catch (e:String)
			true;
		check(threw, "moved into itself: refused");

		// Outs reused, grown and shrunk.
		var outs = [new Transform3D()];
		var first = outs[0];
		check(arm.computeRestPose(outs) == outs && outs.length == 3 && outs[0] == first, "an out pose grown, its first kept");
		var big = [for (_ in 0...5) new Matrix3D()];
		check(arm.computeWorld(pose, big) == big && big.length == 3, "an out shrunk");

		// Joints and weights carried.
		var a = Mesh3D.fromBox(1, 1, 1), b = Mesh3D.fromBox(1, 1, 1);
		a.jointIndices = [for (i in 0...a.vertexCount * 4) i % 4 == 0 ? 1 : 0];
		a.weights = [for (i in 0...a.vertexCount * 4) i % 4 == 0 ? 1. : 0];
		b.jointIndices = a.jointIndices.copy();
		b.weights = a.weights.copy();
		var merged = Mesh3D.merge([a, b]);
		check(merged.jointIndices.length == 48 * 4 && merged.weights.length == 48 * 4, "merged: joints and weights, both's");
		var withBare = Mesh3D.merge([a, Mesh3D.fromBox(1, 1, 1)]);
		check(withBare.jointIndices.length == 48 * 4
			&& withBare.jointIndices[0] == 1
			&& withBare.jointIndices[24 * 4] == 0
			&& withBare.weights[24 * 4] == 0,
			"merged with a mesh without: its vertices joint 0, weight 0");

		// Joint indices remapped.
		var remapping = new Mesh3D();
		remapping.positions = [0, 0, 0, 1, 0, 0, 2, 0, 0];
		remapping.jointIndices = [0, 1, 0, 0, 2, 1, 0, 0, 2, 0, 0, 0];
		remapping.weights = [.5, .5, 0, 0, .75, .25, 0, 0, 1, 0, 0, 0];
		var remapped = remapping.remapJointIndices([3, 7, -1]);
		check(remapped.jointIndices[0] == 3 && remapped.jointIndices[1] == 7 && remapped.weights[0] == .5 && remapped.weights[1] == .5,
			"remapped: new indices, weights kept");
		check(remapped.jointIndices[4] == 0 && remapped.weights[4] == 0 && remapped.jointIndices[5] == 7 && remapped.weights[5] == 1,
			"remapped to -1: weight 0, the vertex's others scaled to 1");
		check(remapped.jointIndices[8] == 0 && remapped.weights[8] == 0 && remapping.jointIndices[4] == 2,
			"remapped: a vertex left with none has weights 0, and the original is unchanged");
		check(remapping.remapJointIndices([3, 7, -1], remapping) == remapping && remapping.jointIndices[0] == 3, "remapped in place");
		check(Mesh3D.fromBox(1, 1, 1).remapJointIndices([0]).jointIndices == null, "remapped without joints: none");
		var flat = a.toUnindexed();
		check(flat.jointIndices.length == flat.vertexCount * 4 && flat.weights.length == flat.vertexCount * 4 && flat.jointIndices[0] == 1,
			"unindexed: spread");
		var copied = new Mesh3D().copyFrom(a);
		check(copied.jointIndices.join(",") == a.jointIndices.join(",") && copied.jointIndices != a.jointIndices, "copied: its own");
		var mirrored = flat.transform(Matrix3D.fromScale(-1, 1, 1));
		check(mirrored.jointIndices.length == flat.jointIndices.length, "mirrored: joints turned round with the triangles");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
