import helix.math.Random;

/** Seeded random numbers (helix.math.Random): the sequence pinned to values computed outside Haxe (xorshift32 in Python, 32-bit), so every
	target's bits match them; seeds, states, ranges, picks, weights and shuffles. */
class RandomTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		// Pinned: seed 12345's first values, computed apart from Haxe.
		var r = new Random(12345);
		check(r.next() == 1189442682 && r.next() == 1697253807 && r.next() == 669028256, "The sequence from 12345 is the pinned one");
		r.seed = 12345;
		var third = 0;
		for (_ in 0...3)
			third = r.nextInt(100);
		check(third == 56, "nextInt is next() % max");
		r.seed = 12345;
		check(Math.abs(r.nextFloat() - 0.7769386768341064) < 1e-15 && Math.abs(r.nextFloat() - 0.395172655582428) < 1e-15,
			"nextFloat is the state's top 24 bits over 2^24");
		check(new Random(0).next() == 270369 && new Random(0).seed == 1, "A seed of 0 is taken as 1");
		check(new Random().seed == 12345, "The default seed is 12345");

		// Two generators from one seed agree; a state resumes a sequence.
		var a = new Random(7), b = new Random(7);
		for (_ in 0...10)
			check(a.next() == b.next(), "The same seed gives the same sequence");
		var kept = a.state;
		var ahead = [for (_ in 0...5) a.next()];
		b.state = kept;
		check([for (_ in 0...5) b.next()].join(",") == ahead.join(","), "setState goes on from where getState was");
		a.state = 0;
		check(a.state == 1, "A state of 0 is taken as 1");

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
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
