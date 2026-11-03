package helix.services.audio;

import helix.platform.IAudio;

/** Represents a sound or a queue playing (`Audio.play`, `SampleQueue.play`), until it ends or is stopped.

	Once it has ended, its members change nothing and `playing` is false. */
@:allow(helix.services.audio)
class Voice {
	final output:IAudio;
	final audio:Audio;
	// The output's voice, 0 when there was none; ended once stopped or seen over.
	final id:Int;
	var ended:Bool;
	var fade:Null<Fade> = null;
	// The volume last given the output, so an unchanged one isn't sent again.
	var sent = -1.;

	@:allow(helix.services.audio)
	function new(audio:Audio, output:IAudio, id:Int, sound:Null<Sound>, group:Group, volume:Float) {
		this.audio = audio;
		this.output = output;
		this.id = id;
		this.sound = sound;
		this.group = group;
		@:bypassAccessor this.volume = clamp(volume);
		ended = id == 0;
	}

	/** Gets the sound it plays, or null for a queue's voice (`SampleQueue.play`). */
	public var sound(default, null):Null<Sound>;

	/** Gets the group it plays in. */
	public var group(default, null):Group;

	/** Gets a value indicating whether the voice is playing or paused. It is false once the voice ended or was stopped. */
	public var playing(get, never):Bool;

	function get_playing():Bool {
		return !ended && output.isPlaying(id);
	}

	/** Gets or sets the voice's own volume, 0 to 1, before its groups' volumes apply. Setting it ends a fade. */
	public var volume(default, set):Float = 1;

	function set_volume(value:Float):Float {
		fade = null;
		volume = clamp(value);
		apply();
		return volume;
	}

	/** Gets or sets the playback rate, which changes pitch and length together. Clamped to 0.25 to 4. Defaults to 1, as recorded. */
	public var pitch(default, set):Float = 1;

	function set_pitch(value:Float):Float {
		pitch = value > .25 ? (value < 4 ? value : 4) : .25;
		if (!ended)
			output.setPitch(id, pitch);
		return pitch;
	}

	/** Gets or sets where the voice is heard, from -1 for left to 1 for right. Clamped to -1 to 1. Defaults to 0, the middle. */
	public var pan(default, set):Float = 0;

	function set_pan(value:Float):Float {
		pan = value > -1 ? (value < 1 ? value : 1) : -1;
		if (!ended)
			output.setPan(id, pan);
		return pan;
	}

	/** Gets or sets a value indicating whether the voice is paused, holding its place. Defaults to false. */
	public var paused(default, set):Bool = false;

	function set_paused(value:Bool):Bool {
		if (!ended)
			output.pause(id, value);
		return paused = value;
	}

	/** Gets how far the voice has played, in seconds from the start of its sound.

		A looping voice goes back to 0 at each loop. A queue's voice counts what it has played since it started. It is 0 once the voice has
		ended. */
	public var position(get, never):Float;

	function get_position():Float {
		return ended ? 0 : output.getPosition(id);
	}

	/** Moves the voice to a position in its sound, playing or paused.

		A position past the end is clamped to the end, where a voice that doesn't loop ends. A queue's voice can't be moved, nor, in a page,
		a stream from a server that doesn't take range requests.

		@param seconds  The position in seconds from the start, 0 or more.
		@return  False, changing nothing, when the voice has ended, is a queue's, or can't be moved there. */
	public function setPosition(seconds:Float):Bool {
		return !ended && output.setPosition(id, seconds);
	}

	/** Fades the voice's own volume to another over some real time, on a curve the ear hears as even (in decibels).

		Does nothing once the voice has ended.

		@param volume  The volume to end at, 0 to 1.
		@param seconds  The fade's length, in real seconds. 0 or less sets the volume at once.
		@param done  Optional. Called once the volume is reached, unless another fade, a set volume or the voice's end comes first. */
	public function fadeTo(volume:Float, seconds:Float, ?done:Void->Void):Void {
		if (ended)
			return;
		if (seconds > 0)
			fade = new Fade(this.volume, clamp(volume), audio.now(), seconds, done);
		else {
			this.volume = volume;
			if (done != null)
				done();
		}
	}

	/** Stops the voice for good. Does nothing once it has ended. */
	public function stop():Void {
		if (ended)
			return;
		ended = true;
		fade = null;
		output.stop(id);
	}

	// Gives the output its volume as heard: its own times its groups'.
	function apply():Void {
		if (ended)
			return;
		var heard = clamp(volume * group.heard());
		if (heard != sent) {
			sent = heard;
			output.setVolume(id, heard);
		}
	}

	// Steps the fade and applies the volume; false once it has ended.
	function step(now:Float):Bool {
		if (ended || !output.isPlaying(id)) {
			ended = true;
			fade = null;
			return false;
		}
		var f = fade;
		if (f != null)
			@:bypassAccessor volume = f.at(now);
		apply();
		if (f != null && f.over(now)) {
			fade = null;
			if (f.done != null)
				f.done();
		}
		return true;
	}

	static function clamp(value:Float):Float
		return value > 0 ? (value < 1 ? value : 1) : 0;
}
