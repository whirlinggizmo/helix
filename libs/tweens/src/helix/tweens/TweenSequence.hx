package helix.tweens;

/** Represents tweens placed in time: one after another, together, or each at a time of its own, with waits and calls between them.

	A sequence is a tween, so a sequence repeats, reverses and seeks as one, and can be placed in another sequence. The sequence steps
	the tweens in it: a program steps the sequence alone.

	```haxe
	var intro = new TweenSequence();
	intro.append(logoFade).join(logoGrow).appendDelay(0.5).append(titleSlide).appendCall(showMenu);
	// each frame
	intro.update(dt);
	``` */
class TweenSequence extends Tween {
	// What is placed, by the time each begins, and in the order placed where two begin together.
	final placements:Array<Placement> = [];

	// The seconds everything placed lasts.
	var length = 0.;

	// The time the tween placed last starts at, which `join` places at.
	var joinTime = 0.;

	/** Creates an empty sequence. */
	public function new() {
		super();
	}

	/** Places a tween after everything placed before it.

		The tween lasts the time its delay, its duration and its repeats add up to when it is placed, at its `timeScale` then.
		Nothing placed after a tween that repeats for ever is reached.

		@param tween  The tween, or another sequence.
		@return  This sequence.
		@throws String  A tween already placed in a sequence. */
	public function append(tween:Tween):TweenSequence
		return place(length, tween);

	/** Places a tween to start when the tween placed before it starts.

		@param tween  The tween, or another sequence.
		@return  This sequence.
		@throws String  A tween already placed in a sequence. */
	public function join(tween:Tween):TweenSequence
		return place(joinTime, tween);

	/** Places a tween at a time of its own, which may overlap the others.

		@param seconds  The time the tween starts at, from the sequence's start, 0 or more.
		@param tween  The tween, or another sequence.
		@return  This sequence.
		@throws String  A tween already placed in a sequence. */
	public function insert(seconds:Float, tween:Tween):TweenSequence
		return place(seconds > 0 ? seconds : 0, tween);

	/** Places a wait after everything placed before it.

		@param seconds  The seconds to wait, 0 or more.
		@return  This sequence. */
	public function appendDelay(seconds:Float):TweenSequence {
		if (seconds > 0)
			length += seconds;
		return this;
	}

	/** Places a call after everything placed before it.

		@param call  The function, called each time the sequence passes the call's time, forwards or backwards.
		@return  This sequence. */
	public function appendCall(call:Void->Void):TweenSequence
		return insertCall(length, call);

	/** Places a call at a time of its own.

		@param seconds  The time of the call, from the sequence's start, 0 or more.
		@param call  The function, called each time the sequence passes the call's time, forwards or backwards.
		@return  This sequence. */
	public function insertCall(seconds:Float, call:Void->Void):TweenSequence {
		var placement = new Placement(seconds > 0 ? seconds : 0);
		placement.call = call;
		add(placement);
		return this;
	}

	override function get_duration():Float
		return length;

	function place(at:Float, tween:Tween):TweenSequence {
		if (tween.owned)
			throw "The tween is already placed in a sequence";
		if (tween == this)
			throw "A sequence can't be placed in itself";
		tween.owned = true;
		var scale = tween.timeScale > 0 ? tween.timeScale : 0;
		var wait = tween.delay > 0 ? tween.delay : 0;
		var playing = tween.getTotal(tween.duration, tween.getCycle(tween.duration));
		var placement = new Placement(wait > 0 ? at + wait / scale : at);
		placement.tween = tween;
		placement.scale = scale;
		placement.instant = playing <= 0;
		add(placement);
		var end = wait + playing > 0 ? at + (wait + playing) / scale : at;
		if (end > length)
			length = end;
		joinTime = at;
		return this;
	}

	// Keeps the placements in the order of their times, a later one after those placed before at the same time.
	function add(placement:Placement):Void {
		var index = placements.length;
		while (index > 0 && placements[index - 1].time > placement.time)
			index--;
		placements.insert(index, placement);
		if (placement.time > length)
			length = placement.time;
	}

	// Forwards the tweens move in the order of their times, and backwards in the other, so that of two tweens writing one value
	// the one the sequence is in writes last.
	override function render(seconds:Float, fraction:Float, backward:Bool, calls:Bool):Void {
		if (backward) {
			var index = placements.length;
			while (index-- > 0)
				show(placements[index], seconds, true, calls);
		} else
			for (placement in placements)
				show(placement, seconds, false, calls);
	}

	function show(placement:Placement, seconds:Float, backward:Bool, calls:Bool):Void {
		var tween = placement.tween;
		if (tween == null || placement.instant) {
			// A call, or a tween of no length, has a time alone: reached forwards once, and once again backwards.
			if (backward ? !placement.passed || placement.time < seconds : placement.passed || placement.time > seconds)
				return;
			placement.passed = !backward;
			if (tween == null) {
				if (calls)
					placement.call();
				return;
			}
		}
		if (tween.cancelled)
			return;
		var target = (seconds - placement.time) * placement.scale;
		var total = tween.getTotal(tween.duration, tween.getCycle(tween.duration));
		if (target > total)
			target = total;
		if (!(target > 0))
			target = 0;
		if (target == tween.time && !placement.instant)
			return;
		// A tween moved off its end is no longer done, and ends again where the move brings it to an end.
		tween.done = false;
		tween.reversed = backward;
		tween.moveTo(target, backward, calls);
		tween.settle(backward, calls);
	}

	override function rewind(backward:Bool):Void {
		if (backward) {
			for (placement in placements) {
				placement.passed = true;
				if (placement.tween != null && !placement.tween.cancelled)
					placement.tween.toEnd();
			}
		} else {
			// The earliest tween last, so that of two tweens writing one value the first's start is left.
			var index = placements.length;
			while (index-- > 0) {
				var placement = placements[index];
				placement.passed = false;
				if (placement.tween != null && !placement.tween.cancelled)
					placement.tween.toStart();
			}
		}
	}
}

/** Represents a tween or a call at a time in a sequence. */
private class Placement {
	/** Gets the sequence's time the tween's first play begins at, after the tween's delay, or the time of the call. */
	public final time:Float;

	/** Gets or sets the tween, or null for a call. */
	public var tween:Null<Tween>;

	/** Gets or sets the function to call, or null for a tween. */
	public var call:Null<Void->Void>;

	/** Gets or sets the tween's seconds to one of the sequence's: the tween's `timeScale` when placed. */
	public var scale = 1.;

	/** Gets or sets whether the tween lasts no time, and is shown as the sequence passes its time, as a call is made. */
	public var instant = false;

	/** Gets or sets whether the sequence is past the call, or past the tween that lasts no time. */
	public var passed = false;

	/** Creates a placement.

		@param time  The sequence's time of the tween or the call. */
	public function new(time:Float) {
		this.time = time;
	}
}
