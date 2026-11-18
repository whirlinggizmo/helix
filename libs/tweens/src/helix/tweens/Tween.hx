package helix.tweens;

/** Represents something that plays over time: a value moving along an easing curve (`EasedTween` and its kinds) or tweens placed in
	time (`TweenSequence`). A program steps a tween with `update`, or adds the tween to a `Tweens` set or a sequence, which steps it.

	A tween's settings are its fields, read at each `update`. */
class Tween {
	/** Gets the seconds one play takes: a kind's legs and waits together, or what a sequence's tweens add up to. */
	public var duration(get, never):Float;

	/** Gets or sets the seconds the tween waits before its first play. Defaults to 0. */
	public var delay = 0.;

	/** Gets or sets how many more times the tween plays after the first: 0 for none, -1 for ever. Defaults to 0. */
	public var repeatCount = 0;

	/** Gets or sets the seconds the tween waits before each repeat. Defaults to 0. */
	public var repeatDelay = 0.;

	/** Gets or sets whether each repeat plays back the way the play before it came, where otherwise each repeat jumps to the start.
		Defaults to false. */
	public var yoyo = false;

	/** Gets or sets how fast the tween plays: 1 as timed, 2 twice as fast, 0.5 half as fast; 0 or more. Defaults to 1. */
	public var timeScale = 1.;

	/** Gets or sets whether `update` leaves the tween where it is. Defaults to false. */
	public var paused = false;

	/** Gets or sets the function called once, when the first play begins, after `delay`. */
	public var onStart:Null<Void->Void>;

	/** Gets or sets the function called after each `update` that moved the tween. */
	public var onUpdate:Null<Void->Void>;

	/** Gets or sets the function called as each repeat begins. */
	public var onRepeat:Null<Void->Void>;

	/** Gets or sets the function called when the tween ends: at the end of its last play, or at its start when it plays backwards.
		`cancel` doesn't call it. */
	public var onComplete:Null<Void->Void>;

	/** Gets the seconds played: 0 at the start, counting each repeat and the wait before each, and not `delay`. */
	public var time(default, null) = 0.;

	/** Gets how far through the current play the tween is, 0 to 1. */
	public var progress(default, null) = 0.;

	/** Gets a value indicating whether the tween plays backwards (`reverse`). */
	public var reversed(default, null) = false;

	/** Gets a value indicating whether the tween has ended or was cancelled. `play`, `reverse`, `seek` and `restart` set a tween that
		is done going again. */
	public var done(default, null) = false;

	// The seconds of delay waited so far.
	var waited = 0.;

	// Whether the first play has begun.
	var started = false;

	// Whether cancel stopped the tween, which a sequence holding the tween then leaves alone.
	var cancelled = false;

	// Whether a sequence holds the tween and steps it.
	var owned = false;

	function new() {}

	function get_duration():Float
		return 0;

	/** Steps the tween by some seconds: through its delay, then its plays.

		Each play ends exactly at its end. Seconds left over when a play ends go to the repeat after it. Does nothing when the tween
		is paused or done, or is placed in a sequence, which steps it.

		@param dt  The seconds to step by, multiplied by `timeScale`. Less than 0 counts as 0. */
	public function update(dt:Float):Void {
		if (paused || done || owned)
			return;
		dt = dt > 0 && timeScale > 0 ? dt * timeScale : 0;
		if (!Math.isFinite(dt))
			dt = 0;
		if (!reversed && waited < delay) {
			waited += dt;
			if (waited < delay)
				return;
			dt = waited - delay;
			waited = delay;
		}
		moveTo(reversed ? time - dt : time + dt, reversed, true);
		settle(reversed, true);
	}

	/** Plays the tween forwards from where it is. A paused tween is no longer paused. */
	public function play():Void {
		reversed = false;
		resume();
	}

	/** Plays the tween backwards from where it is, back through its repeats to its start. The delay isn't waited again. A paused
		tween is no longer paused. */
	public function reverse():Void {
		reversed = true;
		resume();
	}

	/** Jumps the tween to a time, forwards or backwards. No callback is made for what the jump passes.

		@param seconds  The time to jump to, as `time` counts it, kept between 0 and the tween's end. */
	public function seek(seconds:Float):Void {
		if (Math.isNaN(seconds))
			return;
		done = false;
		cancelled = false;
		waited = delay;
		moveTo(seconds, seconds < time, false);
		started = time > 0;
	}

	/** Puts the tween back at its start, playing forwards, its delay and its repeats to come again. A paused tween is no longer
		paused. */
	public function restart():Void {
		toStart();
		reversed = false;
		resume();
	}

	/** Jumps the tween to the end of its last play and calls `onComplete`, and no other callback for what the jump passes. A tween
		that repeats for ever jumps to the end of its current play. Does nothing when the tween is done. */
	public function finish():Void {
		if (done)
			return;
		var length = duration,
			cycle = getCycle(length),
			target = getTotal(length, cycle);
		if (!Math.isFinite(target))
			target = Math.isFinite(cycle) ? playAt(time, length, cycle) * cycle + length : time;
		waited = delay;
		moveTo(target, false, false);
		started = true;
		done = true;
		if (onComplete != null)
			onComplete();
	}

	/** Stops the tween where it is. The tween is done, and `onComplete` isn't called. */
	public function cancel():Void {
		done = true;
		cancelled = true;
	}

	function resume():Void {
		paused = false;
		done = false;
		cancelled = false;
	}

	// One play and the wait before the repeat after it, in seconds.
	inline function getCycle(length:Float):Float
		return length + (repeatDelay > 0 ? repeatDelay : 0);

	// The seconds every play and wait take, which `time` ends at: infinite for a tween that repeats for ever.
	function getTotal(length:Float, cycle:Float):Float
		return cycle <= 0 ? 0 : repeatCount < 0 ? Math.POSITIVE_INFINITY : length + repeatCount * cycle;

	// The play a time falls in, the first being 0. The time a repeat begins at is still the play before it, at its end; but a play
	// of no length is over at the time it begins.
	function playAt(seconds:Float, length:Float, cycle:Float):Int {
		if (seconds <= 0 || cycle <= 0 || !Math.isFinite(cycle))
			return 0;
		var play = length > 0 ? Math.ceil(seconds / cycle) - 1 : Math.floor(seconds / cycle);
		return play < 0 ? 0 : repeatCount >= 0 && play > repeatCount ? repeatCount : play;
	}

	// Moves the tween to a time, as `time` counts it, through each play on the way, and draws the tween there. Without calls no
	// callback is made.
	function moveTo(target:Float, backward:Bool, calls:Bool):Void {
		var length = duration,
			cycle = getCycle(length),
			total = getTotal(length, cycle);
		if (target > total)
			target = total;
		if (!(target > 0))
			target = 0;
		var moved = target != time || !started;
		if (!started && !backward) {
			started = true;
			if (calls && onStart != null)
				onStart();
		}
		var play = playAt(time, length, cycle),
			last = playAt(target, length, cycle);
		while (play < last) {
			// The play ends exactly at its end, and the repeat after it begins.
			draw(play, length, length, false, calls);
			if (!yoyo)
				rewind(false);
			play++;
			if (calls && onRepeat != null)
				onRepeat();
		}
		while (play > last) {
			draw(play, 0, length, true, calls);
			if (!yoyo)
				rewind(true);
			play--;
			if (calls && onRepeat != null)
				onRepeat();
		}
		time = target;
		var within = last == 0 ? target : target - last * cycle;
		draw(last, within > length ? length : within, length, backward, calls);
		if (moved && calls && onUpdate != null)
			onUpdate();
	}

	// Draws a play at some seconds into it: a yoyo's odd plays run back the way the play before came.
	function draw(play:Int, within:Float, length:Float, backward:Bool, calls:Bool):Void {
		// A play of no length is at its end once played, and at its start once played backwards.
		var fraction = length > 0 ? within / length : backward ? 0. : 1.;
		progress = fraction;
		if (yoyo && play & 1 == 1) {
			fraction = 1 - fraction;
			within = length - within;
			backward = !backward;
		}
		render(within, fraction, backward, calls);
	}

	// Marks the tween done when a move brought it to its end, or to its start when moving backwards.
	function settle(backward:Bool, calls:Bool):Void {
		var length = duration;
		var ended = backward ? time <= 0 : time >= getTotal(length, getCycle(length));
		if (ended && !done) {
			done = true;
			if (calls && onComplete != null)
				onComplete();
		} else if (!ended && !cancelled)
			done = false;
	}

	// Puts the tween at its start as when new, with no callback.
	function toStart():Void {
		time = 0;
		progress = 0;
		waited = 0;
		started = false;
		done = false;
		rewind(false);
		render(0, 0, true, false);
	}

	// Puts the tween at the end of its last play, with no callback. A tween that repeats for ever has none, and stays.
	function toEnd():Void {
		var length = duration, total = getTotal(length, getCycle(length));
		if (!Math.isFinite(total))
			return;
		moveTo(total, false, false);
		started = true;
		done = true;
	}

	// Shows a play at some seconds into it, which are the fraction of its length. `backward` says which way the play was reached.
	function render(seconds:Float, fraction:Float, backward:Bool, calls:Bool):Void {}

	// Puts what the tween holds at the start of a play, with no callback, for a repeat that jumps there; or at the end of a play,
	// for one reached backwards.
	function rewind(backward:Bool):Void {}
}
