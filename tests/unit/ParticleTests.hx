import haxe.io.Bytes;
import helix.particles.Emitter;

/** Emitter: spawning by rate and bursts, deaths, the ring's limit, prewarming, seeds, and flat emitters. */
class ParticleTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// Its records now, 12 floats each.
	static function records(e:Emitter):Array<Float> {
		var out = Bytes.alloc(e.getCount() * 48), n = e.writeRecords(out, 0);
		return [for (i in 0...n * 12) out.getFloat(i * 4)];
	}

	static function main():Void {
		var e = new Emitter(null, 1000);
		e.setRate(100);
		e.setLife(10, 10);
		for (_ in 0...10)
			e.advance(.1, 0, 0, 0);
		check(e.getCount() == 100, "A rate of 100 a second makes 100 in a second");
		e.setLife(.5, .5);
		e.clear();
		for (_ in 0...20)
			e.advance(.1, 0, 0, 0);
		check(e.getCount() >= 49 && e.getCount() <= 51, "Particles die after their life: about half a second's worth alive");
		var small = new Emitter(null, 8);
		small.burst(20);
		check(small.getCount() == 8, "At most max alive: newer replace the oldest");
		var warm = new Emitter(null, 1000);
		warm.setRate(50);
		warm.setLife(1, 1);
		warm.prewarm(5);
		check(warm.getCount() == 50, "Prewarming leaves those still alive: a second's worth of a 1-second life");
		// The same seed and settings give the same particles.
		var a = new Emitter(null, 64), b = new Emitter(null, 64);
		for (x in [a, b]) {
			x.setSeed(42);
			x.setVelocity(1, 2, 3, .5, .3);
			x.setSpawnSphere(2);
			x.burst(10);
		}
		check(records(a).join(",") == records(b).join(","), "A seed repeats its particles exactly");
		// Spawns spread along a move: a rate's particles between where it was and where it is.
		var trail = new Emitter(null, 1000);
		trail.setRate(100);
		trail.setLife(10, 10);
		trail.advance(.1, 0, 0, 0);
		trail.advance(.1, 10, 0, 0);
		var r = records(trail), xs = [for (i in 10...20) r[i * 12]];
		check(xs[0] > 0 && xs[0] < 2 && xs[9] == 10, "A move spreads its spawns along the way, the last where it is");
		// Flat: everything in the x-y plane.
		var flat = new Emitter(null, 64, true);
		flat.setVelocity(0, -1, 5, 1, 0);
		flat.setSpawnBox(1, 1, 1);
		flat.burst(16);
		var f = records(flat), plane = true;
		for (i in 0...16)
			plane = plane && f[i * 12 + 2] == 0 && f[i * 12 + 6] == 0;
		check(plane, "A flat emitter's particles are born and move in the x-y plane");
		check(!e.setLife(0, 1) && !e.setRate(-1) && !e.addSizeKey(2, 1), "Bad settings are refused");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
