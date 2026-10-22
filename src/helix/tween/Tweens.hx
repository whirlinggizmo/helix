package helix.tween;

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

/** One tween of a Tweens set, made by Tweens.to: set its delay and repeats before its first update; read its value any time. */
class Tween {
	var from:Float;
	var to:Float;
	var seconds:Float;
	var ease:Float->Float;
	var update:Null<Float->Void>;
	var complete:Null<Void->Void>;
	var at = 0.;
	var played = 0;
	var forward = true;
	var started = false;

	@:allow(helix.tween.Tweens)
	function new(from:Float, to:Float, seconds:Float, ease:Float->Float, update:Null<Float->Void>) {
		this.from = from;
		this.to = to;
		this.seconds = seconds;
		this.ease = ease;
		this.update = update;
		value = from;
	}

	/** Waits seconds before starting (the first update comes then). False, changing nothing, for under 0 or once it has started. */
	public function setDelay(value:Float):Bool {
		if (!(value >= 0) || started)
			return false;
		delay = value;
		return true;
	}

	/** Seconds before it starts. */
	public var delay(default, null):Float = 0.;

	/** Plays count more times after the first (-1: for ever), and with yoyo each repeat goes back the way it came rather than jumping to the
		start. False, changing nothing, for a count under -1 or once it has started. */
	public function setRepeat(count:Int, yoyo = false):Bool {
		if (count < -1 || started)
			return false;
		repeat = count;
		this.yoyo = yoyo;
		return true;
	}

	/** How many more times it plays after the first; -1 for ever. */
	public var repeat(default, null):Int = 0;

	/** Whether repeats go back the way they came. */
	public var yoyo(default, null):Bool = false;

	/** Runs f once it ends (not when cancelled). */
	public function setComplete(f:Null<Void->Void>):Void
		complete = f;

	/** The value now: from before it starts, to once it ends. */
	public var value(default, null):Float;

	/** How far along the current play is, 0 to 1 (before easing). */
	public var progress(get, never):Float;

	function get_progress():Float
		return seconds <= 0 ? (started ? 1 : 0) : at / seconds;

	/** Whether it has ended or was cancelled. */
	public var done(default, null):Bool = false;

	/** Stops it where it is: no more updates, no completion. */
	public function cancel():Void {
		done = true;
		update = null;
		complete = null;
	}

	// Moves by delta seconds: through the delay, then the plays, telling update and, at the end, complete.

	@:allow(helix.tween.Tweens)
	function advance(delta:Float):Void {
		if (done)
			return;
		if (delay > 0) {
			if (delta < delay) {
				delay -= delta;
				return;
			}
			delta -= delay;
			delay = 0;
		}
		started = true;
		if (seconds <= 0) {
			tell(to);
			finish();
			return;
		}
		at += delta;
		while (at >= seconds) {
			// A play ends: its last value exact, then the next play (back the way it came, with yoyo) or the end.
			at -= seconds;
			tell(forward ? to : from);
			if (repeat != -1 && played >= repeat) {
				finish();
				return;
			}
			played++;
			if (yoyo)
				forward = !forward;
		}
		var p = at / seconds;
		tell(from + (to - from) * (forward ? ease(p) : ease(1 - p)));
	}

	function finish():Void {
		done = true;
		update = null;
		var f = complete;
		complete = null;
		if (f != null)
			f();
	}

	function tell(v:Float):Void {
		value = v;
		if (update != null)
			update(v);
	}
}
