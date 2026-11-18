import helix.math.Ease;
import helix.math.Vector3;
import helix.tweens.FloatTween;
import helix.tweens.Tween;
import helix.tweens.TweenSequence;
import helix.tweens.Tweens;
import helix.tweens.Vector3Tween;

/** Checks a sequence and a set with the library alone: tweens one after another, together and at times of their own, waits and
	calls, two tweens writing one vector, the tweens' own delays, repeats, speeds and callbacks, a sequence repeating, playing back
	and forth, backwards and sought, a sequence in a sequence, a tween that repeats for ever, tweens of no seconds, a sequence stepped
	frame by frame against the same one sought; then a set stepping its tweens, dropping the done, and changed by a callback. */
class TweenSequenceTests {
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
		placing();
		ball();
		callbacks();
		asOne();
		nesting();
		stepping();
		sets();
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	static function placing():Void {
		var a = new FloatTween(0, 2, 2),
			b = new FloatTween(10, 14, 4),
			c = new FloatTween(0, 1, 1),
			d = new FloatTween(0, 3, 3);
		var sequence = new TweenSequence();
		check(sequence.duration == 0, "an empty sequence takes no time");
		check(sequence.append(a) == sequence, "placing returns the sequence");
		sequence.appendDelay(1).append(b).join(c).insert(1, d);
		check(sequence.duration == 7, "a sequence takes what its tweens and waits add up to");
		sequence.update(1.5);
		check(a.value == 1.5 && b.value == 10 && c.value == 0 && d.value == .5, "appended first, and inserted at a time of its own");
		sequence.update(1);
		check(a.value == 2 && a.done && b.value == 10 && d.value == 1.5, "the wait after the first");
		sequence.update(1);
		check(b.value == 10.5 && c.value == .5 && d.value == 2.5, "joined tweens start together");
		sequence.update(10);
		check(b.value == 14 && c.value == 1 && d.value == 3 && sequence.done && sequence.time == 7, "to the end");
		check(b.done && c.done && d.done, "each tween done");

		check(refuses(() -> new TweenSequence().append(a)), "a tween already placed is refused");
		check(refuses(() -> sequence.append(sequence)), "a sequence isn't placed in itself");
		check(refuses(() -> new Tweens().add(a)), "a set refuses a tween placed in a sequence");
		a.seek(0);
		a.update(1);
		check(a.time == 0, "the sequence alone steps a tween placed in it");

		// The first join starts at the sequence's start, and a join after a wait starts with the tween before the wait.
		var e = new FloatTween(0, 1, 1),
			f = new FloatTween(0, 1, 1),
			g = new FloatTween(0, 1, 1);
		var joined = new TweenSequence().join(e).appendDelay(2).join(f).append(g);
		check(joined.duration == 4, "a wait is kept by what is placed after it");
		joined.update(.5);
		check(e.value == .5 && f.value == .5 && g.value == 0, "join starts with the tween placed before it");
		joined.update(3);
		check(g.value == .5, "append comes after the wait");

		// The time a tween takes when placed: its delay, its repeats, at its speed.
		var slow = new FloatTween(0, 2, 2), after = new FloatTween(0, 1, 1);
		slow.delay = 1;
		slow.repeatCount = 1;
		slow.repeatDelay = 1;
		slow.timeScale = 2;
		var timed = new TweenSequence().append(slow).append(after);
		check(timed.duration == 4, "a placed tween takes its delay, its plays and their waits, at its timeScale");
		timed.update(.25);
		check(slow.time == 0 && slow.value == 0, "a placed tween waits its delay");
		timed.update(.5);
		check(slow.time == .5 && slow.value == .5, "then plays at its speed");
		timed.update(1.5);
		check(slow.time == 3.5 && slow.value == .5 && after.value == 0, "through its repeat");
		timed.update(1.25);
		check(slow.done && slow.value == 2 && after.value == .5, "the next after it");
	}

	static function ball():Void {
		// Two tweens writing one vector: the one the sequence is in writes it.
		var left = new Vector3(-4, 0, 0),
			right = new Vector3(4, 0, 0),
			position = new Vector3(9, 9, 9);
		var over = new Vector3Tween(left, right, 2, null, position);
		var back = new Vector3Tween(right, left, 2, Ease.inOutSine, position);
		var path = new TweenSequence();
		path.append(over).appendDelay(1).append(back).appendDelay(1);
		path.repeatCount = -1;
		check(position.x == 9, "placing writes nothing");
		path.update(.5);
		check(position.x == -2 && position.y == 0, "the first tween moves the vector");
		path.update(2);
		check(position.x == 4, "held through the wait");
		path.update(1.5);
		check(near(position.x, 0), "the second tween takes over");
		path.update(1.5);
		check(position.x == -4 && path.time == 5.5, "held at the second's end");
		path.update(1);
		check(position.x == -2 && path.time == 6.5 && !path.done, "the repeat starts the first again");
		path.update(600.5);
		check(near(position.x, 4 * Math.cos(Math.PI * .5)) && path.time == 607, "and again, for ever");
		path.seek(1);
		check(position.x == 0, "sought back into the first, the first writes");
		path.reverse();
		path.update(.5);
		check(position.x == -2, "backwards the first still writes last");
	}

	static function callbacks():Void {
		var log:Array<String> = [];
		var a = new FloatTween(0, 1, 1), b = new FloatTween(0, 1, 1);
		a.onStart = () -> log.push("a starts");
		a.onComplete = () -> log.push("a ends");
		b.onStart = () -> log.push("b starts");
		b.onComplete = () -> log.push("b ends");
		b.onUpdate = () -> log.push("b moves");
		var sequence = new TweenSequence();
		sequence.appendCall(() -> log.push("first"))
			.append(a)
			.appendCall(() -> log.push("middle"))
			.append(b)
			.appendCall(() -> log.push("last"));
		sequence.insertCall(.5, () -> log.push("half"));
		sequence.onStart = () -> log.push("starts");
		sequence.onRepeat = () -> log.push("repeats");
		sequence.onComplete = () -> log.push("ends");
		sequence.update(0);
		check(log.join(", ") == "starts, first", "a call at the start is made with the first step");
		log.resize(0);
		sequence.update(.75);
		check(log.join(", ") == "a starts, half", "a call is made as the sequence passes its time");
		log.resize(0);
		sequence.update(.75);
		check(log.join(", ") == "a ends, middle, b starts, b moves", "in the order of their times, a tween's own callbacks with them");
		log.resize(0);
		sequence.update(.25);
		check(log.join(", ") == "b moves", "a call is made once");
		log.resize(0);
		sequence.update(1);
		check(log.join(", ") == "b moves, b ends, last, ends" && sequence.done, "a call at the end is made as the sequence ends");

		// Backwards, each call again.
		log.resize(0);
		sequence.reverse();
		sequence.update(.5);
		check(log.join(", ") == "last, b moves", "backwards, a call is made as the sequence passes it again");
		log.resize(0);
		sequence.update(5);
		check(log.join(", ") == "b moves, b ends, middle, half, a ends, first, ends", "back to the start, each tween ending at its start");

		// A repeat makes each call again, and starts each tween again.
		log.resize(0);
		sequence.restart();
		sequence.repeatCount = 1;
		sequence.update(2.25);
		check(log.join(", ") == "starts, first, a starts, a ends, half, middle, b starts, b moves, b ends, last, repeats, first, a starts",
			"a repeat ends the play before it, then makes each call and starts each tween again");
		check(a.value == .25 && b.value == 0, "the tweens back at their starts");
		log.resize(0);
		sequence.seek(3.75);
		check(log.length == 0 && a.value == 1 && b.value == .75, "seek makes no call, and no tween's callback");
		sequence.update(.25);
		check(log.join(", ") == "b moves, b ends, last, ends", "what the jump passed stays passed");
	}

	static function asOne():Void {
		// Back and forth.
		var a = new FloatTween(0, 2, 2), b = new FloatTween(0, 2, 2);
		var passes = 0;
		var sequence = new TweenSequence().append(a).appendCall(() -> passes++).append(b);
		sequence.yoyo = true;
		sequence.repeatCount = 1;
		sequence.update(3);
		check(a.value == 2 && b.value == 1 && passes == 1, "forwards");
		sequence.update(2);
		check(a.value == 2 && b.value == 1 && sequence.time == 5 && sequence.progress == .25, "a yoyo sequence plays back the way it came");
		sequence.update(2);
		check(a.value == 1 && b.value == 0 && passes == 2, "passing its call again");
		sequence.update(2);
		check(a.value == 0 && sequence.done, "to its start");

		// Speed, pausing and finishing are the sequence's.
		var c = new FloatTween(0, 4, 4), d = new FloatTween(0, 4, 4);
		var called = 0, ended = 0;
		var quick = new TweenSequence().append(c).append(d).appendCall(() -> called++);
		quick.onComplete = () -> ended++;
		quick.timeScale = 2;
		quick.update(1);
		check(c.value == 2, "a sequence's speed");
		quick.paused = true;
		quick.update(1);
		check(c.value == 2, "paused");
		quick.paused = false;
		quick.finish();
		check(c.value == 4 && d.value == 4 && quick.done && ended == 1 && called == 0, "finish jumps every tween to its end, calling onComplete alone");
		quick.restart();
		check(c.value == 0 && d.value == 0 && !c.done && quick.time == 0, "restart puts every tween at its start");
		quick.update(4);
		check(c.value == 4 && d.value == 4 && called == 1, "and plays again");

		// A cancelled tween is left where it is.
		var e = new FloatTween(0, 2, 2), f = new FloatTween(0, 2, 2);
		var partly = new TweenSequence().append(e).join(f);
		partly.update(1);
		e.cancel();
		partly.update(1);
		check(e.value == 1 && f.value == 2 && partly.done, "a sequence leaves a cancelled tween where it is");
	}

	static function nesting():Void {
		var a = new FloatTween(0, 1, 1),
			b = new FloatTween(0, 1, 1),
			c = new FloatTween(0, 2, 2);
		var innerCalls = 0;
		var inner = new TweenSequence().append(a).appendCall(() -> innerCalls++).append(b);
		inner.repeatCount = 1;
		var outer = new TweenSequence().append(c).append(inner);
		check(outer.duration == 6, "a sequence in a sequence takes its plays");
		outer.update(3.5);
		check(c.value == 2 && a.value == 1 && b.value == .5 && innerCalls == 1, "the sequence within plays its tweens");
		outer.update(1);
		check(a.value == .5 && b.value == 0 && innerCalls == 1, "and repeats");
		outer.update(1.5);
		check(a.value == 1 && b.value == 1 && innerCalls == 2 && outer.done && inner.done, "to its end");
		outer.seek(2.5);
		check(c.value == 2 && a.value == .5 && b.value == 0, "sought as one");

		// A tween that repeats for ever: nothing after it is reached.
		var spin = new FloatTween(0, 1, 1), never = new FloatTween(0, 1, 1);
		spin.repeatCount = -1;
		var reached = 0;
		var endless = new TweenSequence().append(new FloatTween(0, 1, 1))
			.append(spin)
			.append(never)
			.appendCall(() -> reached++);
		check(endless.duration == Math.POSITIVE_INFINITY, "a sequence holding a tween that repeats for ever has no end");
		endless.update(1000.25);
		check(spin.value == .25 && never.value == 0 && reached == 0 && !endless.done, "nothing placed after is reached");
		endless.finish();
		check(endless.done, "finish ends such a sequence where it is");

		// Tweens of no seconds are set as the sequence passes them.
		var set = new FloatTween(0, 5, 0), move = new FloatTween(0, 1, 1);
		var sets = 0;
		set.onComplete = () -> sets++;
		var instant = new TweenSequence().append(move).append(set);
		instant.update(.5);
		check(set.value == 0 && sets == 0, "a tween of 0 seconds isn't set before its time");
		instant.update(.5);
		check(set.value == 5 && sets == 1 && instant.done, "set as the sequence reaches it");
		instant.reverse();
		instant.update(.5);
		check(set.value == 0 && move.value == .5, "and put back as the sequence passes it backwards");
		var only = new TweenSequence().append(new FloatTween(0, 1, 0));
		var onlyCalls = 0;
		only.appendCall(() -> onlyCalls++);
		only.update(0);
		check(only.done && onlyCalls == 1 && only.duration == 0, "a sequence of no seconds is done with its first step");
	}

	// The same sequence stepped in frames and sought: where each tween is depends on the time alone.
	static function stepping():Void {
		function make(values:Array<FloatTween>, yoyo:Bool):TweenSequence {
			var a = new FloatTween(0, 1, .7, Ease.outBounce),
				b = new FloatTween(5, -5, 1.3, Ease.inOutSine);
			var c = new FloatTween(0, 100, .4),
				d = new FloatTween(1, 2, .9, Ease.inBack);
			b.repeatCount = 2;
			b.yoyo = true;
			c.delay = .3;
			c.repeatCount = 1;
			c.repeatDelay = .2;
			d.timeScale = 1.5;
			var inner = new TweenSequence().append(c).appendDelay(.1).append(d);
			inner.repeatCount = 1;
			var sequence = new TweenSequence().append(a).join(b).insert(.5, inner);
			sequence.repeatCount = 2;
			sequence.yoyo = yoyo;
			for (tween in [a, b, c, d])
				values.push(tween);
			return sequence;
		}
		for (yoyo in [false, true]) {
			var same = true, end = 0.;
			for (frames in [7, 61, 240, 395, 611, 899]) {
				var steppedValues:Array<FloatTween> = [],
					soughtValues:Array<FloatTween> = [];
				var stepped = make(steppedValues, yoyo),
					sought = make(soughtValues, yoyo);
				for (_ in 0...frames)
					stepped.update(1 / 60);
				sought.seek(stepped.time);
				for (index in 0...4)
					same = same && near(steppedValues[index].value, soughtValues[index].value);
				// And backwards from the end.
				sought.seek(1e9);
				end = sought.time;
				sought.reverse();
				for (_ in 0...frames)
					sought.update(1 / 60);
				stepped.seek(sought.time);
				for (index in 0...4)
					same = same && near(steppedValues[index].value, soughtValues[index].value);
			}
			check(same && end > 10, 'stepped in frames and sought agree, forwards and backwards${yoyo ? ", back and forth" : ""}');
		}
	}

	static function sets():Void {
		var tweens = new Tweens();
		var order:Array<String> = [];
		var a = tweens.add(new FloatTween(0, 1, 1)),
			b = tweens.add(new FloatTween(0, 2, 2));
		var sequence = tweens.add(new TweenSequence().append(new FloatTween(0, 3, 3)));
		a.onUpdate = () -> order.push("a");
		b.onUpdate = () -> order.push("b");
		sequence.onUpdate = () -> order.push("sequence");
		check(tweens.tweenCount == 3 && a.value == 0, "add returns the tween as its own kind, and the set holds it");
		tweens.update(.5);
		check(a.value == .5 && b.value == .5 && sequence.time == .5 && order.join(", ") == "a, b, sequence", "a set steps each tween, in the order added");
		tweens.update(1);
		check(a.done && tweens.tweenCount == 2, "a done tween leaves the set");
		tweens.update(1);
		check(b.done && tweens.tweenCount == 1, "each as it is done");

		// A tween added by a callback is first stepped by the next step.
		var chained:Null<FloatTween> = null;
		var first = tweens.add(new FloatTween(0, 1, 1));
		first.onComplete = () -> chained = tweens.add(new FloatTween(0, 1, 1));
		tweens.update(1);
		check(chained != null && chained.time == 0 && tweens.tweenCount == 1, "a tween added during a step waits for the next");
		tweens.update(.25);
		check(chained.time == .25, "and is stepped by it");

		// Emptied, between steps and by a callback.
		tweens.cancelAll();
		check(tweens.tweenCount == 0 && chained.done && sequence.done, "cancelAll cancels every tween and empties the set");
		var completes = 0;
		var c = tweens.add(new FloatTween(0, 1, 1)),
			d = tweens.add(new FloatTween(0, 1, 1));
		d.onComplete = () -> completes++;
		c.onUpdate = () -> tweens.cancelAll();
		tweens.update(2);
		check(tweens.tweenCount == 0 && d.time == 0 && d.done && completes == 0, "a callback can empty the set during a step");
		var kept = tweens.add(new FloatTween(0, 1, 1));
		tweens.update(.5);
		check(kept.time == .5 && tweens.tweenCount == 1, "and the set goes on");
		var paused = tweens.add(new FloatTween(0, 1, 1));
		paused.paused = true;
		tweens.update(1);
		check(tweens.tweenCount == 1 && paused.time == 0, "a paused tween stays in the set");
	}
}
