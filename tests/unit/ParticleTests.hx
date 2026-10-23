import haxe.io.Bytes;
import helix.particle.Emitter;
import helix.particle.ParticlePreset;

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
		var out = Bytes.alloc(e.particleCount * 48),
			n = e.writeRecords(out, 0);
		return [for (i in 0...n * 12) out.getFloat(i * 4)];
	}

	static function main():Void {
		var e = new Emitter(null, 1000);
		e.rate = 100;
		e.setLife(10, 10);
		for (_ in 0...10)
			e.advance(.1, 0, 0, 0);
		check(e.particleCount == 100, "A rate of 100 a second makes 100 in a second");
		e.setLife(.5, .5);
		e.clear();
		for (_ in 0...20)
			e.advance(.1, 0, 0, 0);
		check(e.particleCount >= 49 && e.particleCount <= 51, "Particles die after their life: about half a second's worth alive");
		var small = new Emitter(null, 8);
		small.jump(0, 0, 0);
		small.burst(20);
		check(small.particleCount == 8, "At most max alive: newer replace the oldest");
		var warm = new Emitter(null, 1000);
		warm.rate = 50;
		warm.setLife(1, 1);
		warm.jump(0, 0, 0);
		warm.prewarm(5);
		check(warm.particleCount == 50, "Prewarming leaves those still alive: a second's worth of a 1-second life");
		// Before it's first placed, a burst and a prewarm wait for where it first is (a preset's node made, then placed).
		var unplaced = new Emitter(null, 1000);
		unplaced.rate = 50;
		unplaced.setLife(1, 1);
		unplaced.prewarm(5);
		unplaced.burst(10);
		check(unplaced.particleCount == 0, "Unplaced: nothing born yet");
		unplaced.advance(0, 7, 8, 9);
		check(unplaced.particleCount == 60
			&& unplaced.writeRecords(haxe.io.Bytes.alloc(60 * 48), 0) == 60
			&& @:privateAccess unplaced.ring.getFloat(0) > 6.9
			&& @:privateAccess unplaced.ring.getFloat(0) < 7.1,
			"Placed: the prewarm's and the burst's born where it first is");
		// The same seed and settings give the same particles.
		var a = new Emitter(null, 64), b = new Emitter(null, 64);
		for (x in [a, b]) {
			x.seed = 42;
			x.setVelocity(1, 2, 3, .5, .3);
			x.setSpawnSphere(2);
			x.jump(0, 0, 0);
			x.burst(10);
		}
		check(a.particleCount == 10 && records(a).join(",") == records(b).join(","), "A seed repeats its particles exactly");
		// Spawns spread along a move: a rate's particles between where it was and where it is.
		var trail = new Emitter(null, 1000);
		trail.rate = 100;
		trail.setLife(10, 10);
		trail.advance(.1, 0, 0, 0);
		trail.advance(.1, 10, 0, 0);
		var r = records(trail), xs = [for (i in 10...20) r[i * 12]];
		check(xs[0] > 0 && xs[0] < 2 && xs[9] == 10, "A move spreads its spawns along the way, the last where it is");
		// Flat: everything in the x-y plane.
		var flat = new Emitter(null, 64, true);
		flat.setVelocity(0, -1, 5, 1, 0);
		flat.setSpawnBox(1, 1, 1);
		flat.jump(0, 0, 0);
		flat.burst(16);
		var f = records(flat), plane = true;
		for (i in 0...16)
			plane = plane && f[i * 12 + 2] == 0 && f[i * 12 + 6] == 0;
		check(plane, "A flat emitter's particles are born and move in the x-y plane");
		check(!e.setLife(0, 1) && !e.addSizeKey(2, 1), "Bad settings are refused");
		e.rate = -1;
		check(e.rate == 0, "A rate under 0 is 0");
		// The presets: each makes an emitter, drawn with the built-in dot; a one-shot bursts where it's first placed and is spent once its
		// particles have died; a steady one keeps going; a 2D one is flat.
		@:privateAccess helix.graphics.Graphics.bind(new Render2DTests.CountingGraphics());
		var oneShots = [Explosion, SmokePuff, Sparks, Dust, Confetti],
			steady = [Fire, Smoke, Rain, Snow];
		for (flat in [true, false]) {
			for (kind in oneShots) {
				var made = kind.make(10, flat ? 1 : -1, flat);
				check(made.texture == Emitter.getDot() && made.particleCount == 0 && !made.spent, 'A one-shot waits for its place ($kind)');
				made.advance(1 / 60, 5, 5, 5);
				check(made.particleCount > 0 && !made.spent, 'Placed, it bursts ($kind)');
				for (_ in 0...300)
					made.advance(1 / 60, 5, 5, 5);
				check(made.spent, 'Its particles dead, it is spent ($kind)');
			}
			for (kind in steady) {
				var made = kind.make(10, flat ? 1 : -1, flat);
				made.advance(1 / 60, 0, 0, 0);
				for (_ in 0...600)
					made.advance(1 / 60, 0, 0, 0);
				check(made.particleCount > 0 && !made.spent, 'A steady one keeps going ($kind)');
			}
		}
		check(Emitter.getDot() == Emitter.getDot() && Emitter.getDot().width == 32, "One dot, made once");
		// A one-shot preset's node takes itself off its parent the frame after it's spent; a steady one, or one told not to, stays.
		var parent2D = new helix.render2d.Node2D(),
			burst = helix.render2d.Particles2D.explosion(10),
			kept = helix.render2d.Particles2D.sparks(10),
			flame = helix.render2d.Particles2D.fire(10);
		kept.removeWhenSpent = false;
		parent2D.addChild(burst);
		parent2D.addChild(kept);
		parent2D.addChild(flame);
		check(burst.removeWhenSpent && !flame.removeWhenSpent, "One-shot presets go when spent; steady ones don't");
		for (node in [burst, kept, flame])
			for (_ in 0...300) {
				node.emitter.advance(1 / 60, 0, 0, 0);
				@:privateAccess node.removeIfSpent();
			}
		check(burst.emitter.spent && burst.parent == parent2D, "Spent: still there in the frame that found it");
		@:privateAccess helix.scene.Flow.tick(1 / 60);
		check(burst.parent == null && kept.parent == parent2D && flame.parent == parent2D, "Off its parent the frame after; the others stay");
		var parent3D = new helix.render3d.Node3D(),
			burst3D = helix.render3d.Particles3D.explosion(1);
		parent3D.addChild(burst3D);
		for (_ in 0...300) {
			burst3D.emitter.advance(1 / 60, 0, 0, 0);
			@:privateAccess burst3D.removeIfSpent();
		}
		@:privateAccess helix.scene.Flow.tick(1 / 60);
		check(burst3D.parent == null, "In 3D too");
		@:privateAccess helix.graphics.Graphics.bind(null);
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
