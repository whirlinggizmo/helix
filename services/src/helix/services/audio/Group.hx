package helix.services.audio;

/** Represents voices whose volume is set together, such as the music or the effects (`Audio.createGroup`).

	A voice is heard at its own volume times its group's and each group's above it, and not at all while any of them is muted. */
@:allow(helix.services.audio)
class Group {
	final audio:Audio;
	var fade:Null<Fade> = null;

	@:allow(helix.services.audio)
	function new(audio:Audio, parent:Null<Group>) {
		this.audio = audio;
		this.parent = parent;
	}

	/** Gets the group it's under, or null for `Audio.master`. */
	public var parent(default, null):Null<Group>;

	/** Gets or sets its volume, 0 to 1; setting it ends a fade. */
	public var volume(default, set):Float = 1;

	function set_volume(value:Float):Float {
		fade = null;
		return volume = clamp(value);
	}

	/** Gets or sets a value indicating whether its voices are silent, their volumes kept; false by default. */
	public var muted:Bool = false;

	/** Fades its volume to another over some real time, on a curve the ear hears as even (in decibels).

		@param volume  The volume to end at, 0 to 1.
		@param seconds  How long it takes, in real seconds; 0 sets it at once.
		@param done  Optional. Called once it's reached, unless another fade or a set volume ends it first. */
	public function fadeTo(volume:Float, seconds:Float, ?done:Void->Void):Void {
		if (seconds > 0)
			fade = new Fade(this.volume, clamp(volume), audio.now(), seconds, done);
		else {
			this.volume = volume;
			if (done != null)
				done();
		}
	}

	/** Its volume times every group's above it, or 0 while any of them is muted. */
	function heard():Float
		return muted ? 0 : parent == null ? volume : volume * parent.heard();

	// Steps the fade; its done is called after the volume is set.
	function step(now:Float):Void {
		if (fade == null)
			return;
		var f = fade;
		@:bypassAccessor volume = f.at(now);
		if (f.over(now)) {
			fade = null;
			if (f.done != null)
				f.done();
		}
	}

	static function clamp(value:Float):Float
		return value > 0 ? (value < 1 ? value : 1) : 0;
}
