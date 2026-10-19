package helix.audio;

/** A volume (0 to 1) moving from one level to another over seconds along a curve (FadeCurve): linear in decibels so it sounds even, a silent
	end taken as FLOOR_DB, or linear in power for a crossfade; the last step lands on the end exactly. A bus's and a playback's fades each step
	one, once a frame. */
class Fade {
	/** The level a silent end (a volume of 0) is taken as, in decibels. */
	public static inline var FLOOR_DB = -60.;

	final from:Float;
	final to:Float;
	final seconds:Float;
	final curve:FadeCurve;
	var elapsed = 0.;

	/** Runs once it reaches its end; null for none. */
	public final done:Null<Void->Void>;

	/** From volume from to volume to (each 0 to 1) over seconds (0 or less ends at the first step) along curve, done run at the end by its
		owner. */
	public function new(from:Float, to:Float, seconds:Float, ?done:Void->Void, curve = FadeCurve.Decibels) {
		this.from = from;
		this.to = to;
		this.seconds = seconds > 0 ? seconds : 0;
		this.done = done;
		this.curve = curve;
	}

	/** Whether it has reached its end. */
	public var finished(get, never):Bool;

	function get_finished():Bool
		return elapsed >= seconds;

	/** Moves it on by delta seconds (under 0 as 0) and returns the volume there: to exactly once finished. */
	public function step(delta:Float):Float {
		elapsed += delta > 0 ? delta : 0;
		return finished ? to : at(from, to, elapsed / seconds, curve);
	}

	/** The volume fraction (0 to 1) of the way from volume from to volume to along curve: linear in decibels, each end under FLOOR_DB's level
		taken as FLOOR_DB, or linear in power; to itself at 1. */
	public static function at(from:Float, to:Float, fraction:Float, curve = FadeCurve.Decibels):Float {
		if (fraction >= 1)
			return to;
		if (curve == Power)
			return Math.sqrt(from * from + (to * to - from * from) * fraction);
		var a = decibels(from), b = decibels(to);
		return Math.pow(10, (a + (b - a) * fraction) / 20);
	}

	// A volume in decibels, held at FLOOR_DB.
	static function decibels(volume:Float):Float {
		var db = volume > 0 ? 20 * Math.log(volume) / Math.log(10) : FLOOR_DB;
		return db > FLOOR_DB ? db : FLOOR_DB;
	}
}
