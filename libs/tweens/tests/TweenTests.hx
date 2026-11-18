import helix.math.Curve;
import helix.math.Ease;
import helix.math.Quaternion;
import helix.math.Vector2;
import helix.math.Vector3;
import helix.math.Vector4;
import helix.tweens.ColorTween;
import helix.tweens.EasedTween;
import helix.tweens.FloatTween;
import helix.tweens.QuaternionTween;
import helix.tweens.Vector2CurveTween;
import helix.tweens.Vector2Tween;
import helix.tweens.Vector3CurveTween;
import helix.tweens.Vector3Tween;
import helix.tweens.Vector4Tween;

/** Checks a tween's timing and each kind with the library alone: a play from its start to exactly its end, the delay, repeats and
	the wait before each, yoyo, a tween that repeats for ever, the speed, pausing, playing backwards, seeking, restarting, finishing
	and cancelling, each callback and when it is made; then a number, the vectors written in place, a rotation, a color, and a point
	along a curve by distance with its heading. */
class TweenTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function refuses(make:Void->Void):Bool {
		try {
			make();
		} catch (error:String) {
			return true;
		}
		return false;
	}

	static function main():Void {
		timing();
		repeats();
		control();
		kinds();
		curves();
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	static function timing():Void {
		var tween = new FloatTween(10, 20, 2);
		var starts = 0, updates = 0, completes = 0;
		tween.onStart = () -> starts++;
		tween.onUpdate = () -> updates++;
		tween.onComplete = () -> completes++;
		check(tween.value == 10 && tween.time == 0 && tween.progress == 0 && !tween.done && tween.duration == 2, "a new tween is at its start");
		tween.update(.5);
		check(tween.value == 12.5 && tween.time == .5 && tween.progress == .25 && tween.amount == .25, "a quarter of the way after a quarter of the time");
		check(starts == 1 && updates == 1 && completes == 0, "onStart and onUpdate with the first step");
		tween.update(1);
		tween.update(5);
		check(tween.value == 20 && tween.time == 2 && tween.progress == 1 && tween.done, "a step past the end stops at the end");
		check(starts == 1 && updates == 3 && completes == 1, "onStart once, onUpdate each step, onComplete once");
		tween.update(1);
		check(updates == 3 && completes == 1 && tween.time == 2, "a done tween isn't stepped");

		// Sums that round: the end is the end's own number.
		var exact = new FloatTween(.1, .3, 1);
		for (_ in 0...10)
			exact.update(.1);
		exact.update(.1);
		check(exact.done && exact.value == .3, "the end exactly, where from + (to - from) rounds");
		var eases:Array<Ease> = [
			Ease.inSine,
			Ease.outSine,
			Ease.inOutSine,
			Ease.inQuad,
			Ease.outQuad,
			Ease.inOutQuad,
			Ease.inCubic,
			Ease.outCubic,
			Ease.inOutCubic,
			Ease.inQuart,
			Ease.outQuart,
			Ease.inOutQuart,
			Ease.inQuint,
			Ease.outQuint,
			Ease.inOutQuint,
			Ease.inExpo,
			Ease.outExpo,
			Ease.inOutExpo,
			Ease.inCirc,
			Ease.outCirc,
			Ease.inOutCirc,
			Ease.inBack,
			Ease.outBack,
			Ease.inOutBack,
			Ease.inElastic,
			Ease.outElastic,
			Ease.inOutElastic,
			Ease.inBounce,
			Ease.outBounce,
			Ease.inOutBounce
		];
		var ends = true, starts = true, between = true;
		for (ease in eases) {
			var eased = new FloatTween(.1, .7, 1, ease);
			eased.update(0);
			starts = starts && eased.value == .1 && eased.amount == 0;
			eased.update(.25);
			between = between && near(eased.amount, ease.at(.25)) && near(eased.value, .1 + .6 * ease.at(.25));
			eased.update(.75);
			ends = ends && eased.value == .7 && eased.amount == 1 && eased.done;
		}
		check(starts && between && ends, "each of the thirty easing curves: exactly the start, the curve between, exactly the end");

		// The delay isn't played time, and what is left of a step after the delay is played.
		var late = new FloatTween(0, 4, 4);
		late.delay = 1;
		var began = 0;
		late.onStart = () -> began++;
		late.update(.75);
		check(late.time == 0 && late.value == 0 && began == 0, "nothing moves during the delay");
		late.update(.75);
		check(late.time == .5 && late.value == .5 && began == 1, "the step past the delay plays what is left of it");

		// A step of no time, or less.
		var still = new FloatTween(0, 1, 1);
		var stillUpdates = 0;
		still.onUpdate = () -> stillUpdates++;
		still.update(.5);
		still.update(0);
		still.update(-3);
		still.update(Math.NaN);
		check(still.time == .5 && stillUpdates == 1, "a step of 0, less than 0 or not a number moves nothing and makes no call");

		// A play of no seconds jumps to its end with any step.
		var jump = new FloatTween(3, 9, 0);
		var jumped = 0;
		jump.onComplete = () -> jumped++;
		check(jump.value == 3, "a tween of 0 seconds is at its start when new");
		jump.update(0);
		check(jump.value == 9 && jump.done && jumped == 1, "a tween of 0 seconds jumps to its end");
		check(new FloatTween(0, 1, -5).duration == 0, "a duration less than 0 is 0");

		// The speed.
		var fast = new FloatTween(0, 8, 8);
		fast.timeScale = 2;
		fast.update(1);
		check(fast.time == 2, "twice as fast at a timeScale of 2");
		fast.timeScale = .5;
		fast.update(1);
		check(fast.time == 2.5, "half as fast at 0.5");
		fast.timeScale = 0;
		fast.update(1);
		fast.timeScale = -1;
		fast.update(1);
		check(fast.time == 2.5, "still at 0, and at less than 0");

		// Paused.
		var held = new FloatTween(0, 1, 1);
		held.paused = true;
		held.update(.5);
		check(held.time == 0, "a paused tween stays");
		held.paused = false;
		held.update(.5);
		check(held.time == .5, "and goes on when no longer paused");
	}

	static function repeats():Void {
		var tween = new FloatTween(0, 4, 4);
		tween.repeatCount = 2;
		var repeats = 0, completes = 0, seen = -1.;
		tween.onRepeat = () -> {
			repeats++;
			seen = tween.value;
		};
		tween.onComplete = () -> completes++;
		tween.update(4);
		check(tween.value == 4 && tween.progress == 1 && !tween.done && repeats == 0, "the end of a play is held until the repeat begins");
		tween.update(1);
		check(tween.value == 1 && tween.time == 5 && tween.progress == .25 && repeats == 1, "the repeat jumps to the start, with what the step had left");
		check(seen == 4, "the play ended exactly at its end before the repeat began");
		tween.update(9);
		check(tween.value == 4 && tween.time == 12 && tween.done && repeats == 2 && completes == 1, "two repeats are three plays, then done");

		// The wait before each repeat.
		var waiting = new FloatTween(0, 2, 2);
		waiting.repeatCount = 1;
		waiting.repeatDelay = 1;
		var waited = 0;
		waiting.onRepeat = () -> waited++;
		waiting.update(2.5);
		check(waiting.value == 2 && waiting.time == 2.5 && waited == 0 && !waiting.done, "the end is held through the wait before a repeat");
		waiting.update(1);
		check(waiting.value == .5 && waited == 1, "the repeat begins after its wait");
		waiting.update(2);
		check(waiting.done && waiting.time == 5 && waiting.value == 2, "time counts each repeat and the wait before it");

		// Yoyo.
		var yoyo = new FloatTween(0, 4, 4);
		yoyo.repeatCount = 1;
		yoyo.yoyo = true;
		yoyo.update(5);
		check(yoyo.value == 3 && yoyo.progress == .25, "a yoyo's repeat plays back the way the play came");
		yoyo.update(3);
		check(yoyo.value == 0 && yoyo.done, "and ends where the tween began");

		// For ever.
		var endless = new FloatTween(0, 1, 1);
		endless.repeatCount = -1;
		var ended = 0;
		endless.onComplete = () -> ended++;
		endless.update(1000.25);
		check(!endless.done && endless.value == .25 && ended == 0, "a tween that repeats for ever isn't done");
		endless.finish();
		check(endless.done && endless.value == 1 && ended == 1 && endless.time == 1001, "finish ends its current play");

		// A play of no seconds with a wait: each repeat is an instant.
		var blink = new FloatTween(0, 1, 0);
		blink.repeatCount = 2;
		blink.repeatDelay = 1;
		var blinks = 0;
		blink.onRepeat = () -> blinks++;
		blink.update(1.5);
		check(blink.value == 1 && blinks == 1 && !blink.done, "a tween of 0 seconds repeats after each wait");
		blink.update(1);
		check(blink.done && blinks == 2, "and is done after its last");
	}

	static function control():Void {
		// Backwards.
		var tween = new FloatTween(0, 4, 4);
		var completes = 0;
		tween.onComplete = () -> completes++;
		tween.update(3);
		tween.reverse();
		check(tween.reversed, "reverse plays backwards");
		tween.update(1);
		check(tween.value == 2 && tween.time == 2, "back the way the tween came");
		tween.update(5);
		check(tween.value == 0 && tween.done && completes == 1, "done at its start, with onComplete");
		tween.play();
		check(!tween.reversed && !tween.done, "play sets a done tween going forwards");
		tween.update(4);
		check(tween.value == 4 && tween.done && completes == 2, "to its end again");

		// Backwards through repeats.
		var looped = new FloatTween(0, 2, 2);
		looped.repeatCount = 2;
		var repeats = 0;
		looped.onRepeat = () -> repeats++;
		looped.update(5);
		check(looped.value == 1 && repeats == 2, "in its third play");
		looped.reverse();
		looped.update(2);
		check(looped.value == 1 && looped.time == 3 && repeats == 3, "backwards into the play before, from its end");
		looped.update(10);
		check(looped.value == 0 && looped.done && repeats == 4, "back through each repeat to the start");

		// play and reverse set a paused tween going.
		var paused = new FloatTween(0, 1, 1);
		paused.paused = true;
		paused.play();
		check(!paused.paused, "play sets a paused tween going");
		paused.paused = true;
		paused.reverse();
		check(!paused.paused, "reverse does too");

		// Seeking.
		var sought = new FloatTween(0, 4, 4);
		sought.repeatCount = 1;
		var calls = 0;
		sought.onStart = () -> calls++;
		sought.onUpdate = () -> calls++;
		sought.onRepeat = () -> calls++;
		sought.onComplete = () -> calls++;
		sought.seek(5);
		check(sought.value == 1 && sought.time == 5 && calls == 0, "seek jumps, with no callback");
		sought.seek(1);
		check(sought.value == 1 && sought.time == 1 && calls == 0, "backwards too");
		sought.seek(100);
		check(sought.time == 8 && sought.value == 4 && !sought.done && calls == 0, "kept to the tween's end, and not done by the jump");
		sought.seek(-1);
		check(sought.time == 0 && sought.value == 0, "kept to 0");
		sought.seek(Math.NaN);
		check(sought.time == 0, "not a number is no jump");
		sought.seek(8);
		sought.update(.1);
		check(sought.done && calls == 1, "the step after a jump to the end ends the tween");
		sought.seek(2);
		check(!sought.done, "seek sets a done tween going");
		var skipped = new FloatTween(0, 4, 4);
		skipped.delay = 3;
		skipped.seek(1);
		skipped.update(1);
		check(skipped.time == 2, "a tween sought doesn't wait its delay");

		// Restarting.
		var again = new FloatTween(0, 4, 4);
		again.delay = 1;
		again.repeatCount = 1;
		var starts = 0;
		again.onStart = () -> starts++;
		again.update(20);
		check(again.done && starts == 1, "played out");
		again.restart();
		check(!again.done && again.time == 0 && again.value == 0, "restart puts the tween at its start");
		again.update(.5);
		check(again.time == 0, "its delay to come again");
		again.update(1.5);
		check(again.time == 1 && starts == 2, "and its first play");
		again.update(8);
		check(again.done && again.time == 8, "and its repeats");

		// Finishing.
		var finished = new FloatTween(0, 4, 4);
		finished.delay = 2;
		finished.repeatCount = 3;
		var ends = 0, others = 0;
		finished.onComplete = () -> ends++;
		finished.onStart = () -> others++;
		finished.onRepeat = () -> others++;
		finished.onUpdate = () -> others++;
		finished.finish();
		check(finished.done && finished.value == 4 && finished.time == 16 && ends == 1 && others == 0,
			"finish jumps to the end of the last play and calls onComplete alone");
		finished.finish();
		check(ends == 1, "finish does nothing when done");

		// Cancelling.
		var cancelled = new FloatTween(0, 4, 4);
		var cancelCalls = 0;
		cancelled.onComplete = () -> cancelCalls++;
		cancelled.update(1);
		cancelled.cancel();
		cancelled.update(1);
		check(cancelled.done && cancelled.value == 1 && cancelCalls == 0, "cancel stops the tween where it is, without onComplete");
		cancelled.play();
		cancelled.update(1);
		check(cancelled.value == 2 && !cancelled.done, "play sets a cancelled tween going");
		var stopper = new FloatTween(0, 2, 2);
		stopper.repeatCount = -1;
		stopper.onRepeat = () -> stopper.cancel();
		stopper.update(3);
		stopper.update(1);
		check(stopper.done && stopper.time == 3, "a callback can cancel its tween");
	}

	static function kinds():Void {
		// The curve alone.
		var eased = new EasedTween(1, Ease.outBack);
		eased.update(.5);
		check(eased.amount > 1, "a curve that overshoots passes 1 on the way");
		eased.ease = Ease.of(t -> t * t);
		eased.update(.25);
		check(eased.amount == .5625, "a function of the program's own is a curve, and can be set");

		// Vectors, written in place.
		var position = new Vector3(1, 2, 3), open = new Vector3(5, 2, -1);
		var slide = new Vector3Tween(position, open, 2, null, position);
		check(slide.value == position && slide.from != position && slide.to != open, "the out is written, the start and the end are copies");
		slide.update(1);
		check(position.x == 3 && position.y == 2 && position.z == 1, "the out is moved, though it was the start");
		slide.to.set(9, 2, 1);
		slide.update(.5);
		check(position.x == 7 && position.z == 1.5, "moving the end's components moves where the tween goes");
		slide.update(1);
		check(position.x == 9 && position.y == 2 && position.z == 1 && slide.done, "to the end");
		var untouched = new Vector3(7, 7, 7);
		var waiting = new Vector3Tween(new Vector3(), new Vector3(1, 1, 1), 1, null, untouched);
		waiting.delay = 1;
		waiting.update(.5);
		check(untouched.x == 7, "an out isn't written before the tween starts");
		var own = new Vector3Tween(new Vector3(1, 2, 3), new Vector3(3, 2, 1), 1);
		check(own.value.x == 1 && own.value.z == 3 && own.value != own.from, "with no out the tween's own vector starts at the start");
		var third = new Vector3Tween(new Vector3(.1, .1, .1), new Vector3(.3, .7, .9), 3);
		for (_ in 0...3)
			third.update(1);
		check(third.value.x == .3 && third.value.y == .7 && third.value.z == .9, "a vector ends exactly at its end");

		var flat = new Vector2Tween(new Vector2(0, 10), new Vector2(4, 20), 1, Ease.inQuad);
		flat.update(.5);
		check(flat.value.x == 1 && flat.value.y == 12.5, "a Vector2 by its curve");
		var four = new Vector4Tween(new Vector4(0, 0, 0, 0), new Vector4(4, 8, 12, 16), 4);
		four.update(1);
		check(four.value.x == 1 && four.value.y == 2 && four.value.z == 3 && four.value.w == 4, "a Vector4, each number on its own");

		// A rotation, the short way round.
		var from = Quaternion.fromAxisAngle(0, 1, 0, 0),
			to = Quaternion.fromAxisAngle(0, 1, 0, Math.PI / 2);
		var facing = new Quaternion();
		var turn = new QuaternionTween(from, to, 1, null, facing);
		turn.update(.5);
		var half = Quaternion.slerp(from, to, .5);
		check(facing.x == half.x && facing.y == half.y && facing.z == half.z && facing.w == half.w, "a rotation turns as Quaternion.slerp");
		check(near(facing.y, Math.sin(Math.PI / 8)) && near(facing.w, Math.cos(Math.PI / 8)), "half of a quarter turn at the middle");
		turn.update(.5);
		check(facing.x == to.x && facing.y == to.y && facing.z == to.z && facing.w == to.w, "a rotation ends exactly at its end");

		// A color, each channel on its own, in any one order.
		var fade = new ColorTween(0xff000080, 0x00ff8040, 1);
		check(fade.value == 0xff000080, "a color starts at its start");
		fade.update(.5);
		check(fade.value == 0x80804060, "each of the four channels half way, rounded");
		fade.update(.5);
		check(fade.value == 0x00ff8040, "a color ends at its end");
		var over = new ColorTween(0x00000000, 0xc8c8c8c8, 1, Ease.of(t -> 2 * t));
		over.update(.75);
		check(over.value == 0xffffffff, "a curve that overshoots is kept to 255");
		over.ease = Ease.of(t -> -t);
		over.restart();
		over.update(.5);
		check(over.value == 0, "and to 0");
		var flash = new ColorTween(0, 0, 1);
		flash.from = 0x10;
		flash.to = 0x30;
		flash.update(.5);
		check(flash.value == 0x20, "the start and the end can be set");
	}

	static function curves():Void {
		// Two straight pieces, 3 long and 1 long: equal steps of the curve's parameter aren't equal distances.
		var path = Curve.polyline([0, 0, 0, 3, 0, 0, 3, 1, 0], 3);
		var cart = new Vector3();
		var ride = new Vector3CurveTween(path, 4, null, cart);
		check(ride.value == cart && ride.curve == path && cart.x == 0, "the out, the curve, and nothing written yet");
		check(near(ride.direction.x, 1) && near(ride.direction.y, 0), "the heading at the curve's start when new");
		ride.update(2);
		check(near(cart.x, 2) && near(cart.y, 0), "half the time is half the distance, not half the parameter");
		check(near(ride.direction.x, 1) && near(ride.direction.y, 0) && near(ride.direction.z, 0), "the heading along the first piece");
		ride.update(1.5);
		check(near(cart.x, 3) && near(cart.y, .5) && near(ride.direction.y, 1) && near(ride.direction.x, 0), "on the second piece, heading its way");
		ride.update(.5);
		check(cart.x == 3 && cart.y == 1 && ride.done, "at the curve's end");
		ride.reverse();
		ride.update(1);
		check(near(cart.y, 0) && near(cart.x, 3) && ride.direction.x >= 0 && ride.direction.y >= 0, "backwards the heading is still the curve's own");

		// A part of the curve.
		var part = new Vector3CurveTween(path, 2);
		part.from = .5;
		part.update(0);
		check(near(part.value.x, 2), "from sets where along the curve the point starts");
		part.update(1);
		check(near(part.value.x, 3) && near(part.value.y, 0), "half way from the middle to the end");
		part.update(1);
		check(part.value.x == 3 && part.value.y == 1, "to the end");
		var back = new Vector3CurveTween(path, 4);
		back.from = 1;
		back.to = 0;
		back.update(.5);
		check(near(back.value.x, 3) && near(back.value.y, .5) && near(back.direction.x, 0) && near(back.direction.y, 1),
			"a to less than from moves back along the curve");
		back.update(3.5);
		check(back.value.x == 0 && back.value.y == 0, "to the curve's start");

		// Past the ends.
		var past = new Vector3CurveTween(path, 1, Ease.of(t -> 2 * t));
		past.update(.75);
		check(past.value.x == 3 && past.value.y == 1, "an open curve holds the point at its end");
		var square = Curve.polyline([0, 0, 4, 0, 4, 4, 0, 4], 2, true);
		var guard = new Vector2();
		var patrol = new Vector2CurveTween(square, 16, guard);
		patrol.to = 2;
		patrol.update(4);
		check(near(guard.x, 4) && near(guard.y, 4), "a Vector2 along a closed curve, the easing curve left out");
		patrol.update(6);
		check(near(guard.x, 4) && near(guard.y, 0), "a to past 1 carries on round a closed curve");
		patrol.update(1);
		check(near(guard.x, 4) && near(guard.y, 2) && near(patrol.direction.x, 0) && near(patrol.direction.y, 1), "heading the curve's way");
		var corners = [0., 0, 0, 4, 0, 0, 4, 0, 4];
		var walk = new Vector3CurveTween(Curve.through(corners, 3, true), 12, cart);
		walk.update(1);
		check(near(walk.direction.length, 1) && cart == walk.value, "a Vector3 through points, the easing curve left out");

		check(refuses(() -> new Vector3CurveTween(square, 1)), "a Vector3CurveTween refuses a curve in 2 dimensions");
		check(refuses(() -> new Vector2CurveTween(path, 1)), "a Vector2CurveTween refuses a curve in 3");
	}
}
