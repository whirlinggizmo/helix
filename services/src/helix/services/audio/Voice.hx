package helix.services.audio;

import haxe.exceptions.NotImplementedException;

/** Represents a sound playing (`Audio.play`), until it ends or is stopped.

	Once it has ended its members change nothing, and `playing` is false. */
class Voice {
	@:allow(helix.services.audio)
	function new() {}

	/** Gets the sound it plays. */
	public var sound(default, null):Sound;

	/** Gets the group it plays in. */
	public var group(default, null):Group;

	/** Gets a value indicating whether it's still playing or paused: false once it ended or was stopped. */
	public var playing(get, never):Bool;

	function get_playing():Bool {
		throw new NotImplementedException();
	}

	/** Gets or sets its own volume, 0 to 1, before its groups'; setting it ends a fade. */
	public var volume(default, set):Float = 1;

	function set_volume(value:Float):Float {
		throw new NotImplementedException();
	}

	/** Gets or sets its playback rate, which changes its pitch and length together: 0.25 to 4, 1 as recorded. */
	public var pitch(default, set):Float = 1;

	function set_pitch(value:Float):Float {
		throw new NotImplementedException();
	}

	/** Gets or sets where it's heard: -1 left to 1 right, 0 the middle. */
	public var pan(default, set):Float = 0;

	function set_pan(value:Float):Float {
		throw new NotImplementedException();
	}

	/** Gets or sets a value indicating whether it's paused, holding its place. */
	public var paused(default, set):Bool = false;

	function set_paused(value:Bool):Bool {
		throw new NotImplementedException();
	}

	/** Fades its own volume to another over some real time, on a curve the ear hears as even (in decibels).

		@param volume  The volume to end at, 0 to 1.
		@param seconds  How long it takes, in real seconds; 0 sets it at once.
		@param done  Optional. Called once it's reached, unless another fade, a set volume or the voice's end comes first. */
	public function fadeTo(volume:Float, seconds:Float, ?done:Void->Void):Void {
		throw new NotImplementedException();
	}

	/** Stops it for good. Does nothing once it has ended. */
	public function stop():Void {
		throw new NotImplementedException();
	}
}
