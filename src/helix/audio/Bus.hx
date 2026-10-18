package helix.audio;

/** A bus sounds are played through: a name, a parent, a volume, a mute and a fade, plain engine data. Audio.master is the root, Audio.music
	and Audio.effects are under it from the program's start, and Audio.addBus makes a game's own. A playback's heard volume is its own times
	its bus's heardVolume; the buses' fades advance and the heard volumes reach the voices once a frame (AudioResources.poll). A bus is held as
	a reference; its name is used only to save and load the volumes (Audio.saveBuses, Audio.loadBuses). */
class Bus {
	/** Its name, unique among the buses: what saving and loading the volumes know it by. */
	public final name:String;

	/** The bus it plays into: null only for the master. */
	public final parent:Null<Bus>;

	var children:Array<Bus> = [];
	var fading:Null<Fade>;

	/** A bus named name under parent (null for the master); Audio makes them. */
	@:allow(helix.audio.Audio)
	function new(name:String, parent:Null<Bus>) {
		this.name = name;
		this.parent = parent;
		if (parent != null)
			parent.children.push(this);
	}

	/** Its volume, 0 to 1, clamped (NaN is 0). Assigning it ends a fade, whose done doesn't run. */
	public var volume(default, set):Float = 1;

	function set_volume(value:Float):Float {
		fading = null;
		return volume = clamp(value);
	}

	/** Whether it is muted: its heard volume, and everything played through it or a bus under it, is then 0, its volume kept for unmuting. */
	public var muted:Bool = false;

	/** What it plays at: its volume times its parents' up to the master, 0 when it or a parent is muted. */
	public var heardVolume(get, never):Float;

	function get_heardVolume():Float
		return muted ? 0 : parent == null ? volume : volume * parent.heardVolume;

	/** Moves its volume to to (0 to 1, clamped) over seconds (0 or less, or NaN, sets it at once), linear in decibels, a silent end taken as
		-60 dB; done runs at the end, during this call for 0 seconds. A fade started over another, or a volume assigned, ends the earlier one,
		whose done doesn't run. */
	public function fade(to:Float, seconds:Float, ?done:Void->Void):Void {
		var fade = new Fade(volume, clamp(to), seconds, done);
		if (fade.finished) {
			volume = fade.step(0);
			if (done != null)
				done();
		} else
			fading = fade;
	}

	/** Plays sound through it from the beginning at volume (0 to 1), looping if asked: AudioResources.play on the program's (Audio.instance).
		Throws before the runner has bound one, and as AudioResources.play throws. */
	public function play(sound:AudioResource, loop = false, volume = 1.):AudioPlayback {
		if (Audio.instance == null)
			throw "No audio service";
		return Audio.instance.play(sound, loop, volume, this);
	}

	/** This bus and every bus under it, parents before their children. */
	public function all():Array<Bus> {
		var found = [this];
		var i = 0;
		while (i < found.length)
			for (child in found[i++].children)
				found.push(child);
		return found;
	}

	/** Steps its fade and those under it by delta seconds, running a finished fade's done. AudioResources.poll calls it on the master. */
	@:allow(helix.audio.AudioResources)
	function advance(delta:Float):Void {
		for (bus in all()) {
			var fade = bus.fading;
			if (fade == null)
				continue;
			var level = fade.step(delta);
			bus.volume = level;
			if (!fade.finished)
				bus.fading = fade;
			else if (fade.done != null)
				fade.done();
		}
	}

	static function clamp(value:Float):Float
		return value > 0 ? (value < 1 ? value : 1) : 0;
}
