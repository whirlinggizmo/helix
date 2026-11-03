package helix.services.audio;

/** A volume moving from one value to another over real seconds, on a curve the ear hears as even: straight in decibels, from and to a
	floor of -60 dB for silence. */
@:noCompletion @:allow(helix.services.audio)
class Fade {
	/** The decibels taken as silence. */
	static inline final FLOOR = -60.;

	final from:Float;
	final to:Float;
	final start:Float;
	final seconds:Float;
	final done:Null<Void->Void>;

	function new(from:Float, to:Float, start:Float, seconds:Float, done:Null<Void->Void>) {
		this.from = from;
		this.to = to;
		this.start = start;
		this.seconds = seconds;
		this.done = done;
	}

	/** The volume at a time; exactly `to` once the fade is over. */
	function at(now:Float):Float {
		var t = (now - start) / seconds;
		if (!(t < 1))
			return to;
		if (t <= 0)
			return from;
		var db = decibels(from) + (decibels(to) - decibels(from)) * t;
		return db <= FLOOR ? 0 : Math.pow(10, db / 20);
	}

	function over(now:Float):Bool
		return !((now - start) < seconds);

	static function decibels(volume:Float):Float
		return volume <= 0 ? FLOOR : Math.max(FLOOR, 20 * Math.log(volume) / Math.log(10));
}
