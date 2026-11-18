import helix.math.Curve;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.extras.tweens.*;

/** Checks the tweens package with raylib's types: a `Color` faded by its channels, set, and kept to 0 to 255; a color tween added to
	a set and placed in a sequence as any tween; raylib's vectors written in place; a `Quaternion` turned as `QuaternionSlerp` turns
	one; and a point moved along a curve. */
class TweensTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		// A color, by raylib's Color.
		var fade = new ColorTween(new Color(255, 0, 100, 255), new Color(0, 200, 50, 0), 1);
		check(fade.value == new Color(255, 0, 100, 255) && fade.value.r == 255, "a color tween starts at its start, a Color");
		fade.update(.5);
		var half:Color = fade.value;
		check(half.r == 128 && half.g == 100 && half.b == 75 && half.a == 128, "each channel half way, rounded");
		fade.update(.5);
		check(fade.value == new Color(0, 200, 50, 0) && fade.done && fade.time == 1, "to its end, with a tween's own members");
		fade.from = RED;
		fade.to = BLUE;
		check(fade.from == RED && fade.to == BLUE, "its start and end are set as Colors");
		fade.restart();
		fade.ease = Ease.outBack;
		fade.update(.6);
		check(fade.amount > 1 && fade.value.r == 0 && fade.value.b == 255 && fade.value.a == 255, "a curve that overshoots is kept to 0 to 255");

		// A set and a sequence take a color tween as any tween, and a set gives the tween back as a color tween.
		var tweens = new Tweens();
		var blink = tweens.add(new ColorTween(WHITE, BLANK, 2));
		var grow = tweens.add(new FloatTween(1, 3, 2));
		tweens.update(1);
		check(blink.value.a == 128 && grow.value == 2 && tweens.tweenCount == 2, "a set steps a color tween with the others");
		var first = new ColorTween(BLACK, WHITE, 1),
			then = new FloatTween(0, 4, 2);
		var called = 0;
		var sequence = new TweenSequence().append(first).append(then).appendCall(() -> called++);
		sequence.update(2);
		check(first.value == WHITE && then.value == 2 && called == 0, "a sequence places a color tween");
		sequence.update(1);
		check(sequence.done && called == 1, "and ends");
		var plain:Tween = first, eased:EasedTween = first;
		check(plain.done && eased.amount == 1, "a color tween passes for a Tween and an EasedTween");

		// raylib's vectors, in place.
		var door = new Vector3(0, 0, 0);
		var rise = new Vector3Tween(door, new Vector3(0, 3, 0), 1.5, Ease.inOutCubic, door);
		rise.update(.75);
		check(door.y == 1.5 && rise.value == door, "a Vector3 moved in place");
		var spot = new Vector2(10, 10);
		var slide = new Vector2Tween(spot, new Vector2(20, 30), 1, null, spot);
		slide.update(1);
		check(Vector2Equals(spot, new Vector2(20, 30)) != 0, "a Vector2 too");
		var four = new Vector4Tween(new Vector4(0, 0, 0, 0), new Vector4(1, 2, 3, 4), 1);
		four.update(.5);
		check(four.value.w == 2, "and a Vector4");

		// A rotation, as QuaternionSlerp turns one.
		var from = QuaternionFromAxisAngle(new Vector3(0, 1, 0), 0),
			to = QuaternionFromAxisAngle(new Vector3(0, 1, 0), 2);
		var turn = new QuaternionTween(from, to, 1);
		turn.update(.25);
		check(QuaternionEquals(turn.value, QuaternionSlerp(from, to, .25)) != 0, "a Quaternion turned as QuaternionSlerp");

		// Along a curve, by distance.
		var path = Curve.polyline([0, 0, 0, 6, 0, 0, 6, 0, 2], 3);
		var cart = new Vector3(0, 0, 0);
		var ride = new Vector3CurveTween(path, 4, cart);
		ride.update(2);
		check(Math.abs(cart.x - 4) < 1e-9 && Math.abs(ride.direction.x - 1) < 1e-9, "a Vector3 along a curve, with its heading");
		var flat = new Vector2CurveTween(Curve.polyline([0, 0, 8, 0], 2), 2);
		flat.from = .5;
		flat.update(1);
		check(Math.abs(flat.value.x - 6) < 1e-9, "a Vector2 along a part of one");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
