package helix.tweens;

import helix.math.Ease;

/** Represents a play along an easing curve, from 0 to 1. `FloatTween`, `Vector3Tween` and the other kinds move a value by it, and a
	program moves a value of its own by `amount`.

	```haxe
	var grow = new EasedTween(0.5, Ease.outBack);
	// each frame
	grow.update(dt);
	rect.width = Interpolate.lerp(40, 200, grow.amount);
	rect.height = Interpolate.lerp(10, 60, grow.amount);
	``` */
class EasedTween extends Tween {
	/** Gets or sets the easing curve: the first leg's, where a kind's `append` added more legs. */
	public var ease:Ease;

	/** Gets how far along the move is, by the easing curve: 0 at the start and 1 at the end. A curve that overshoots
		(`Ease.outBack`) passes 1 on the way.

		Where a kind's `append` added legs, the amount is the current leg's, by that leg's curve, and 0 during a wait. */
	public var amount(default, null) = 0.;

	// The seconds one play lasts: every leg and wait together.
	var length:Float;

	// The seconds the first leg lasts.
	final first:Float;

	// The legs and waits after the first, null until a kind adds one: the seconds into a play each ends at, each one's curve (null
	// for a wait), and the values each starts and ends at, numbered as `legFrom` is.
	var legEnds:Null<Array<Float>>;
	var legEases:Null<Array<Null<Ease>>>;
	var legFroms:Null<Array<Int>>;
	var legTos:Null<Array<Int>>;

	// The value the legs so far end at, and how many values the kind holds, its `from` and `to` among them.
	var lastValue = 1;
	var valueCount = 2;

	// The values the current leg starts and ends at: 0 is the kind's `from`, 1 its `to`, and 2 and up the ends of the legs after
	// the first, in the order added.
	var legFrom = 0;
	var legTo = 1;

	/** Creates a tween at its start.

		@param duration  The seconds one play lasts, 0 or more. A play of 0 seconds jumps to its end.
		@param ease  Optional. The easing curve, one of `Ease`'s (`Ease.outBounce`) or a function of the program's own (`Ease.of`);
			a straight line when omitted. */
	public function new(duration:Float, ?ease:Ease) {
		super();
		length = first = duration > 0 ? duration : 0;
		this.ease = ease != null ? ease : Ease.linear;
	}

	override function get_duration():Float
		return length;

	override function render(seconds:Float, fraction:Float, backward:Bool, calls:Bool):Void {
		var ends = legEnds;
		if (ends == null) {
			// The ends are exact, whatever the curve rounds to there.
			amount = fraction <= 0 ? 0 : fraction >= 1 ? 1 : ease.at(fraction);
			apply();
			return;
		}
		// The leg the time falls in. The time two legs meet at is the later one's start, or the earlier one's end when reached
		// backwards, so a leg of no length is at its end once played and at its start once played backwards.
		var index = 0, start = 0., end = first;
		if (backward)
			while (index < ends.length && end < seconds) {
				start = end;
				end = ends[index++];
			}
		else
			while (index < ends.length && end <= seconds) {
				start = end;
				end = ends[index++];
			}
		var curve:Null<Ease> = ease;
		if (index == 0) {
			legFrom = 0;
			legTo = 1;
		} else {
			curve = legEases[index - 1];
			legFrom = legFroms[index - 1];
			legTo = legTos[index - 1];
		}
		var span = end - start;
		var along = span > 0 ? (seconds - start) / span : backward ? 0. : 1.;
		amount = curve == null || along <= 0 ? 0 : along >= 1 ? 1 : curve.at(along);
		apply();
	}

	// Moves the kind's value to `amount` of the way from the value numbered `legFrom` to the one numbered `legTo`.
	function apply():Void {}

	// Adds a leg ending at a value the kind keeps next among its own, or a wait when the curve is null.
	function addLeg(duration:Float, ease:Null<Ease>):Void {
		if (owned)
			throw "The tween is placed in a sequence, which took the tween's time when placed: append to the tween before placing it";
		if (legEnds == null) {
			legEnds = [];
			legEases = [];
			legFroms = [];
			legTos = [];
		}
		if (duration > 0)
			length += duration;
		legEnds.push(length);
		legEases.push(ease);
		legFroms.push(lastValue);
		if (ease != null)
			lastValue = valueCount++;
		legTos.push(lastValue);
	}
}
