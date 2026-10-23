import helix.tween.Ease;
import helix.tween.Tweens;
import helix.tween.Tween;

/** Easings (helix.tween.Ease): each from 0 to 1, in and out mirrored, inOut through the middle; tweens (Tweens): values along the way, the
	end exact, delays, repeats and yoyo, completion, cancelling, ones made inside callbacks. */
class TweenTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, e = 1e-9):Bool
		return Math.abs(a - b) < e;

	static function main():Void {
		var eases:Array<{name:String, f:Float->Float}> = [
			{name: "linear", f: Ease.linear},
			{name: "quadIn", f: Ease.quadIn},
			{name: "quadOut", f: Ease.quadOut},
			{name: "quadInOut", f: Ease.quadInOut},
			{name: "cubicIn", f: Ease.cubicIn},
			{name: "cubicOut", f: Ease.cubicOut},
			{name: "cubicInOut", f: Ease.cubicInOut},
			{name: "quartIn", f: Ease.quartIn},
			{name: "quartOut", f: Ease.quartOut},
			{name: "quartInOut", f: Ease.quartInOut},
			{name: "sineIn", f: Ease.sineIn},
			{name: "sineOut", f: Ease.sineOut},
			{name: "sineInOut", f: Ease.sineInOut},
			{name: "expoIn", f: Ease.expoIn},
			{name: "expoOut", f: Ease.expoOut},
			{name: "expoInOut", f: Ease.expoInOut},
			{name: "circIn", f: Ease.circIn},
			{name: "circOut", f: Ease.circOut},
			{name: "circInOut", f: Ease.circInOut},
			{name: "backIn", f: Ease.backIn},
			{name: "backOut", f: Ease.backOut},
			{name: "backInOut", f: Ease.backInOut},
			{name: "elasticIn", f: Ease.elasticIn},
			{name: "elasticOut", f: Ease.elasticOut},
			{name: "elasticInOut", f: Ease.elasticInOut},
			{name: "bounceIn", f: Ease.bounceIn},
			{name: "bounceOut", f: Ease.bounceOut},
			{name: "bounceInOut", f: Ease.bounceInOut}
		];
		for (e in eases)
			check(near(e.f(0), 0, 1e-6) && near(e.f(1), 1, 1e-6), '${e.name} goes from 0 to 1');
		// In and out mirror each other: out(t) = 1 - in(1 - t); inOut passes through the middle.
		var pairs = ["quad", "cubic", "quart", "sine", "expo", "circ", "back", "elastic", "bounce"];
		for (name in pairs) {
			var fin = Reflect.field(Ease, name + "In"),
				fout = Reflect.field(Ease, name + "Out"),
				finout = Reflect.field(Ease, name + "InOut");
			var mirrored = true;
			for (i in 0...11) {
				var t = i / 10;
				mirrored = mirrored && near(fout(t), 1 - fin(1 - t), 1e-6);
			}
			check(mirrored, '${name}Out mirrors ${name}In');
			check(near(finout(.5), .5, 1e-6), '${name}InOut is halfway at the middle');
		}
		// The plain ones never leave 0 to 1 and rise; back and elastic go past, and bounce bounces.
		var monotone = true;
		for (name in ["quadIn", "cubicOut", "sineInOut", "expoIn", "circOut", "quartInOut"]) {
			var f = Reflect.field(Ease, name), last = -1.;
			for (i in 0...101) {
				var v = f(i / 100);
				monotone = monotone && v >= last - 1e-9 && v >= -1e-9 && v <= 1 + 1e-9;
				last = v;
			}
		}
		check(monotone, "The plain easings rise within 0 to 1");
		check(Ease.backIn(.3) < 0 && Ease.backOut(.7) > 1 && Ease.elasticOut(.2) > 1, "back and elastic go past the ends");

		// A tween's values along the way.
		var tweens = new Tweens(), seen = [];
		var t = tweens.to(10, 20, 1, null, v -> seen.push(v));
		check(t.value == 10 && t.progress == 0 && tweens.count == 1, "A tween starts at from");
		tweens.update(.25);
		check(near(t.value, 12.5) && near(t.progress, .25) && seen.length == 1, "A quarter along, linear");
		tweens.update(.5);
		check(near(t.value, 17.5), "Three quarters");
		var ended = false;
		t.setComplete(() -> ended = true);
		tweens.update(.5);
		check(t.value == 20 && t.done && ended && seen[seen.length - 1] == 20 && tweens.count == 0, "The end is exact, told once, then complete");
		// Eased.
		var eased = tweens.to(0, 1, 1, Ease.quadIn);
		tweens.update(.5);
		check(near(eased.value, .25), "Eased by quadIn");
		tweens.clear();
		// A delay, then repeats with yoyo.
		var yo = tweens.to(0, 1, 1);
		check(yo.setDelay(.5) && yo.setRepeat(1, true) && !yo.setDelay(-1) && !yo.setRepeat(-2) && yo.delay == .5 && yo.repeat == 1 && yo.yoyo,
			"A delay and a repeat are set before the start");
		tweens.update(.25);
		check(yo.value == 0 && yo.progress == 0, "Waiting through the delay");
		tweens.update(.75);
		check(near(yo.value, .5), "The delay's remainder counts toward the first play");
		check(!yo.setDelay(1) && !yo.setRepeat(3), "Once started, the delay and repeats are fixed");
		tweens.update(.5);
		check(near(yo.value, 1) && !yo.done, "The first play ends at to; a repeat is left");
		tweens.update(.5);
		check(near(yo.value, .5), "and yoyo goes back");
		var yoDone = false;
		yo.setComplete(() -> yoDone = true);
		tweens.update(.5);
		check(near(yo.value, 0) && yo.done && yoDone, "Back at from, done");
		// For ever, without yoyo: jumps back to from.
		var ever = tweens.to(0, 1, 1);
		ever.setRepeat(-1);
		tweens.update(1.25);
		check(near(ever.value, .25) && !ever.done, "A tween for ever starts over");
		tweens.update(10.5);
		check(near(ever.value, .75) && !ever.done, "however far time jumps");
		ever.cancel();
		var cancelledTold = false;
		ever.setComplete(() -> cancelledTold = true);
		tweens.update(1);
		check(ever.done && !cancelledTold && tweens.count == 0, "Cancelled: no completion, gone from the set");
		// Zero seconds, and one made inside a callback.
		var zero = tweens.to(3, 4, 0), zeroDone = false;
		zero.setComplete(() -> zeroDone = true);
		var chained:Null<helix.tween.Tween> = null;
		var first = tweens.to(0, 1, .5);
		first.setComplete(() -> chained = tweens.to(1, 2, .5));
		tweens.update(.5);
		check(zero.value == 4 && zeroDone && first.done && chained != null && chained.value == 1,
			"0 seconds ends at once; a chained tween waits for the next update");
		tweens.update(.25);
		check(near(chained.value, 1.5), "and moves from then");
		var threw = false;
		try
			tweens.to(0, 1, -1)
		catch (e:Dynamic)
			threw = true;
		check(threw, "Negative seconds are refused");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
