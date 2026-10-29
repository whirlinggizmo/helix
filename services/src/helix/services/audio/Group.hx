package helix.services.audio;

import haxe.exceptions.NotImplementedException;

/** Represents voices whose volume is set together, such as the music or the effects (`Audio.createGroup`).

	A voice is heard at its own volume times its group's and each group's above it, and not at all while any of them is muted. */
class Group {
	@:allow(helix.services.audio)
	function new() {}

	/** Gets the group it's under, or null for `Audio.master`. */
	public var parent(default, null):Null<Group>;

	/** Gets or sets its volume, 0 to 1; setting it ends a fade. */
	public var volume(default, set):Float = 1;

	function set_volume(value:Float):Float {
		throw new NotImplementedException();
	}

	/** Gets or sets a value indicating whether its voices are silent, their volumes kept; false by default. */
	public var muted:Bool = false;

	/** Fades its volume to another over some real time, on a curve the ear hears as even (in decibels).

		@param volume  The volume to end at, 0 to 1.
		@param seconds  How long it takes, in real seconds; 0 sets it at once.
		@param done  Optional. Called once it's reached, unless another fade or a set volume ends it first. */
	public function fadeTo(volume:Float, seconds:Float, ?done:Void->Void):Void {
		throw new NotImplementedException();
	}
}
