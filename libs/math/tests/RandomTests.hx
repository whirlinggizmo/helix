import helix.math.Random;

/** Seeded random numbers (helix.math.Random): the sequence pinned to values raylib 5.5's rprand gives in C (xoshiro128**, seeded by
	SplitMix64), so every target's bits match them; seeds, states, ranges, picks, weights and shuffles;
	bell-shaped numbers, points in and on a circle and a sphere, directions in a cone and rotations, each spread evenly and the same bits
	on every target. */
class RandomTests {
	static var checks = 0;

	// The interpreter's hash of the numbers the last check draws, which Node's and hxcpp's must match.
	static inline var PINNED = -373190377;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		// Pinned: each seed's state and first values, from rprand in C.
		var r = new Random(12345);
		check(r.state.join(",") == "-1445916256,879680741,-2132381155,756420222", "Seed 12345's state is rprand's");
		check(r.nextBits() == -1100341093 && r.nextBits() == 1666268817 && r.nextBits() == -1513355689 && r.nextBits() == 1922866133,
			"The sequence from 12345 is rprand's");
		r.seed = 12345;
		check([for (_ in 0...5) r.nextInt(100)].join(",") == "3,17,7,33,30", "nextInt is the 32 bits, unsigned, modulo max, as GetRandomValue");
		r.seed = 12345;
		check(r.next() == 1597313101, "next is the 32 bits' top 31");
		r.seed = 12345;
		check(r.nextFloat() == (0xBE6A209B >>> 8) / 16777216, "nextFloat is the 32 bits' top 24 over 2^24");
		var zero = new Random(0);
		check(zero.seed == 0 && zero.nextBits() == -1712565836 && zero.nextBits() == -318179, "A seed of 0 is a seed of its own, rprand's");
		var seven = new Random(7);
		check(seven.nextBits() == -1286019622 && seven.nextBits() == -1277186213, "Seed 7's sequence is rprand's");
		var top = new Random(-1);
		check(top.nextBits() == 1441002626 && top.nextBits() == 751174168, "A seed is read as unsigned: -1 is 4294967295's");
		check(new Random().seed == 12345, "The default seed is 12345");

		// Two generators from one seed agree; a state resumes a sequence.
		var a = new Random(7), b = new Random(7);
		for (_ in 0...10)
			check(a.next() == b.next(), "The same seed gives the same sequence");
		var kept = a.state;
		var ahead = [for (_ in 0...5) a.next()];
		b.state = kept;
		check([for (_ in 0...5) b.next()].join(",") == ahead.join(","), "Setting a state goes on from where it was read");
		var refused = 0;
		for (bad in [[0, 0, 0, 0], [1, 2, 3]])
			try
				a.state = bad
			catch (_:String)
				refused++;
		check(refused == 2, "A state of four zeros, or not four words, is refused");

		// Ranges.
		r = new Random(99);
		var low = 1., high = 0.;
		for (_ in 0...1000) {
			var f = r.nextFloat();
			low = Math.min(low, f);
			high = Math.max(high, f);
		}
		check(low >= 0 && high < 1 && low < .01 && high > .99, "nextFloat spans 0 up to 1");
		var seen = [false, false, false];
		for (_ in 0...100)
			seen[r.nextInt(3)] = true;
		check(seen[0] && seen[1] && seen[2], "nextInt(3) gives each of 0, 1 and 2");
		check(r.nextInt(1) == 0 && r.nextInt(0) == 0 && r.nextInt(-4) == 0, "nextInt of 1 or less is 0");
		var inRange = true;
		for (_ in 0...100) {
			var v = r.nextRange(-2, 3);
			inRange = inRange && v >= -2 && v < 3;
		}
		check(inRange && r.nextRange(5, 5) == 5, "nextRange stays in its range, and is min when it's empty");
		var swapped = r.nextRange(3, -2);
		check(swapped >= -2 && swapped < 3, "nextRange swaps a max under min");
		var heads = 0;
		for (_ in 0...1000)
			if (r.nextBool())
				heads++;
		check(heads > 400 && heads < 600, "nextBool is a fair coin");
		check(!r.nextBool(0) && r.nextBool(1), "nextBool with 0 is never, with 1 always");

		// Picks, weights, shuffles.
		check(r.pick([]) == null && r.pick([4]) == 4, "pick gives null for nothing and the one item for one");
		var counts = [0, 0, 0];
		for (_ in 0...3000)
			counts[r.pickWeighted([1, 0, 3])]++;
		check(counts[1] == 0 && counts[2] > counts[0] * 2, "pickWeighted never picks a weight of 0 and favours the heavier");
		check(r.pickWeighted([]) == -1 && r.pickWeighted([0, -1]) == -1, "pickWeighted is -1 for no weight over 0");
		var items = [0, 1, 2, 3, 4, 5, 6];
		var shuffled = r.shuffle(items.copy());
		shuffled.sort((x, y) -> x - y);
		check(shuffled.join(",") == items.join(","), "shuffle keeps every item once");
		var same = new Random(3), again = new Random(3);
		check(same.shuffle([1, 2, 3, 4, 5]).join(",") == again.shuffle([1, 2, 3, 4, 5]).join(","), "shuffle is the seed's");

		// Bell-shaped numbers: the middle, the spread, and the share within one deviation.
		r = new Random(2024);
		var sum = 0., squares = 0., within = 0;
		for (_ in 0...20000) {
			var g = r.nextGaussian();
			sum += g;
			squares += g * g;
			if (Math.abs(g) < 1)
				within++;
		}
		check(Math.abs(sum / 20000) < .02 && Math.abs(squares / 20000 - 1) < .03, "nextGaussian: a middle of 0 and a deviation of 1");
		check(Math.abs(within / 20000 - .6827) < .01, "nextGaussian: 68 in 100 within one deviation");
		sum = 0;
		squares = 0;
		for (_ in 0...20000) {
			var g = r.nextGaussian(10, .5);
			sum += g;
			squares += (g - 10) * (g - 10);
		}
		check(Math.abs(sum / 20000 - 10) < .01
			&& Math.abs(Math.sqrt(squares / 20000) - .5) < .01, "nextGaussian: a middle and a deviation given");
		var logs = true;
		for (n in [1, 2, 3, 1000, 65536, 5931641, 11863283, 11863284, 16777215, 16777216]) {
			var x = n / 16777216;
			if (Math.abs(@:privateAccess Random.log(x) - Math.log(x)) > 4e-16 * Math.abs(Math.log(x)))
				logs = false;
		}
		check(logs && @:privateAccess Random.log(1) == 0, "the logarithm nextGaussian takes is Math.log's but for the last bit");

		// Points in and on a circle.
		var p2 = new helix.math.Vector2(), inner = 0;
		sum = 0;
		var inside = true, onEdge = true;
		for (_ in 0...8000) {
			r.nextInCircle(3, p2);
			if (p2.length > 3)
				inside = false;
			if (p2.length < 1.5)
				inner++;
			sum += p2.x;
			r.nextOnCircle(3, p2);
			if (Math.abs(p2.length - 3) > 1e-12)
				onEdge = false;
		}
		check(inside && Math.abs(inner / 8000 - .25) < .02 && Math.abs(sum / 8000) < .06, "nextInCircle: within the radius, even by area");
		check(onEdge, "nextOnCircle: at the radius");
		check(r.nextInCircle().length <= 1 && Math.abs(r.nextOnCircle().length - 1) < 1e-12, "a circle of radius 1 unless told");

		// Points in and on a sphere.
		var p3 = new helix.math.Vector3(), upper = 0;
		inner = 0;
		sum = 0;
		inside = true;
		onEdge = true;
		for (_ in 0...8000) {
			r.nextInSphere(2, p3);
			if (p3.length > 2)
				inside = false;
			if (p3.length < 1)
				inner++;
			r.nextOnSphere(2, p3);
			if (Math.abs(p3.length - 2) > 1e-12)
				onEdge = false;
			if (p3.z > 1)
				upper++;
			sum += p3.x + p3.y + p3.z;
		}
		check(inside && Math.abs(inner / 8000 - .125) < .015, "nextInSphere: within the radius, even by volume");
		check(onEdge && Math.abs(upper / 8000 - .25) < .02 && Math.abs(sum / 8000) < .1, "nextOnSphere: at the radius, even over the surface");
		check(r.nextInSphere().length <= 1 && Math.abs(r.nextOnSphere().length - 1) < 1e-12, "a sphere of radius 1 unless told");

		// Directions in a cone.
		var middle = new helix.math.Vector3(2, -3, 6),
			unit = middle.normalize();
		var kept = true, near = 0;
		for (_ in 0...8000) {
			r.nextInCone(middle, .6, p3);
			var along = p3.dot(unit);
			if (Math.abs(p3.length - 1) > 1e-12 || along < Math.cos(.6) - 1e-12)
				kept = false;
			if (along > (1 + Math.cos(.6)) / 2)
				near++;
		}
		check(kept && Math.abs(near / 8000 - .5) < .02, "nextInCone: of length 1, within the angle, even over the cone's cap");
		check(r.nextInCone(middle, 0).equals(unit, 1e-12)
			&& r.nextInCone(middle, -1).equals(unit, 1e-12), "nextInCone: an angle of 0 or less is the middle");
		sum = 0;
		for (_ in 0...8000)
			sum += r.nextInCone(middle, 9, p3).dot(unit);
		check(Math.abs(sum / 8000) < .03, "nextInCone: an angle past pi is any direction");
		for (axis in [
			new helix.math.Vector3(5, 0, 0),
			new helix.math.Vector3(0, -5, 0),
			new helix.math.Vector3(0, 0, 5)
		]) {
			r.nextInCone(axis, .3, p3);
			check(Math.abs(p3.length - 1) < 1e-12 && p3.dot(axis) / 5 >= Math.cos(.3) - 1e-12, "nextInCone: around an axis");
		}
		check(r.nextInCone(middle, .6, middle) == middle && Math.abs(middle.length - 1) < 1e-12, "nextInCone: into the middle given");
		var still = new Random(5), drawn = new Random(5);
		check(still.nextInCone(new helix.math.Vector3(), 1).length == 0, "nextInCone: a middle of length 0 gives a length of 0");
		drawn.nextInCone(unit, 1);
		check(still.nextBits() == drawn.nextBits(), "and draws as many numbers as any other");

		// Rotations.
		var q = new helix.math.Quaternion(), turned = new helix.math.Vector3();
		var unitLength = true;
		sum = 0;
		squares = 0;
		for (_ in 0...8000) {
			r.nextRotation(q);
			if (Math.abs(q.length - 1) > 1e-12)
				unitLength = false;
			squares += q.w * q.w;
			q.transformPoint(1, 0, 0, turned);
			sum += turned.x + turned.y + turned.z;
		}
		check(unitLength
			&& Math.abs(squares / 8000 - .25) < .01
			&& Math.abs(sum / 8000) < .06, "nextRotation: a rotation, each as likely");

		// With and without a vector to fill: the same numbers. Every target's bits match the interpreter's.
		var one = new Random(77), other = new Random(77);
		check(one.nextInCircle(2).equals(other.nextInCircle(2, p2))
			&& one.nextOnCircle(2).equals(other.nextOnCircle(2, p2))
			&& one.nextInSphere(2).equals(other.nextInSphere(2, p3))
			&& one.nextOnSphere(2).equals(other.nextOnSphere(2, p3))
			&& one.nextInCone(unit, 1).equals(other.nextInCone(unit, 1, p3))
			&& one.nextRotation().equals(other.nextRotation(q)),
			"each gives the same with a vector to fill as without");
		check(other.nextInCircle(1, p2) == p2 && other.nextInSphere(1, p3) == p3 && other.nextRotation(q) == q, "each returns the one given");
		var bits = haxe.io.Bytes.alloc(8 * 16 * 200);
		var at = 0;
		inline function note(v:Float):Void {
			bits.setDouble(at, v);
			at += 8;
		}
		one.seed = 31337;
		for (_ in 0...200) {
			note(one.nextGaussian(1, 3));
			one.nextInCircle(2, p2);
			note(p2.x);
			note(p2.y);
			one.nextInSphere(2, p3);
			note(p3.x);
			note(p3.y);
			note(p3.z);
			one.nextOnSphere(1, p3);
			note(p3.x);
			note(p3.y);
			note(p3.z);
			one.nextInCone(p3, 1.1, p3);
			note(p3.x);
			note(p3.y);
			note(p3.z);
			one.nextRotation(q);
			note(q.x);
			note(q.y);
			note(q.z);
			note(q.w);
		}
		var hash = haxe.crypto.Crc32.make(bits);
		check(at == bits.length && hash == PINNED, 'the bits of 200 of each from seed 31337: $hash');
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
