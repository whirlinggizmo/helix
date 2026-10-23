package helix.tween;

import helix.tween.Tween;

/** Tweens on a clock: a value moved from one number to another over seconds by an easing, told to the game each update (a node's x, an
	alpha, a camera's zoom), with a delay before, repeats and a yoyo back, and a completion. update runs each frame with the clock's delta
	(Clock.delta), so tweens pause and slow with the game. Each tween moves in the order made; one made inside a callback starts from the
	next update. */
class Tweens {
	var tweens:Array<Tween> = [];
	var updating = false;
	var pending:Array<Tween> = [];

	/** No tweens yet. */
	public function new() {}

	/** Moves from from to to over seconds by ease (linear when not given), calling update with the value each frame, the first at the start
		and the last with to exactly. Throws for seconds under 0. */
	public function to(from:Float, to:Float, seconds:Float, ?ease:Float->Float, ?update:Float->Void):Tween {
		if (!(seconds >= 0))
			throw 'Tweens.to needs seconds of 0 or more, not $seconds';
		var tween = new Tween(from, to, seconds, ease == null ? t->t : ease, update);
		(updating ? pending : tweens).push(tween);
		return tween;
	}

	/** How many are moving or waiting, done ones gone. */
	public var count(get, never):Int;

	function get_count():Int
		return tweens.length + pending.length;

	/** Cancels every tween where it is. */
	public function clear():Void {
		for (t in tweens)
			t.cancel();
		for (t in pending)
			t.cancel();
		tweens = [];
		pending = [];
	}

	/** Advances every tween by delta seconds (a clock's delta). Once a frame. */
	public function update(delta:Float):Void {
		if (delta < 0)
			delta = 0;
		updating = true;
		for (t in tweens)
			t.advance(delta);
		updating = false;
		var kept = [];
		for (t in tweens)
			if (!t.done)
				kept.push(t);
		for (t in pending)
			if (!t.done)
				kept.push(t);
		pending = [];
		tweens = kept;
	}
}
