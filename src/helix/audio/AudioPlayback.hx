package helix.audio;

/** One playback, playing or paused, through a bus; holds its resource until stopped or played to its end. While audio hasn't started (a
	browser before the page's first key or pointer press) it waits, its pause, volume, pitch and pan kept, and starts once audio runs. What
	the adapter hears is heardVolume, its own volume times its bus's heard volume, sent once a frame when either changed. */
class AudioPlayback {
	var waiting = true;
	var paused = false;
	var stopped = false;
	var resource:AudioResource;
	var loop:Bool;
	// The heard volume last sent to the voice.
	var sent = 0.;
	var fading:Null<Fade>;
	var stopWhenSilent = false;

	/** The adapter's voice; 0 while it waits for audio to start, or when it couldn't start. */
	public var id(default, null):Int = 0;

	/** Whether it was stopped, played to its end, or never started; its resource reference is released then. */
	public var finished(default, null):Bool = false;

	/** The adapter's resource it plays, kept as it started: a reload may replace the resource's. */
	public var source(default, null):Int;

	/** The bus it plays through. */
	public var bus(default, null):Bus;

	/** A playback of resource (whose playback reference the caller retained) through bus at volume, looping if asked: it starts now if audio
		runs, waits if audio is available but hasn't started, and finishes at once otherwise. AudioResources.play makes it. */
	public function new(resource:AudioResource, loop:Bool, volume:Float, bus:Bus) {
		this.resource = resource;
		this.loop = loop;
		this.bus = bus;
		this.volume = volume;
		source = resource.id;
		var backend = resource.backend;
		if (!backend.available) {
			waiting = false;
			stopped = true;
			end();
		} else if (backend.running)
			begin();
	}

	// Starts its voice at its heard volume, then its pitch and pan: one that can't start (no free voice) finishes it.
	function begin():Void {
		waiting = false;
		sent = heardVolume;
		id = resource.startVoice(loop, sent);
		if (id == 0) {
			stopped = true;
			end();
			return;
		}
		if (pitch != 1)
			resource.backend.setPitch(id, pitch);
		if (pan != 0)
			resource.backend.setPan(id, pan);
		if (paused)
			resource.backend.pause(id, true);
	}

	function end():Void {
		if (!finished) {
			finished = true;
			fading = null;
			resource.releasePlayback();
		}
	}

	/** Playing or Paused while it lasts (waiting counts as playing); then Stopped (stop(), or it never started) or Complete (it played to its
		end). */
	public var state(get, never):PlayState;

	function get_state():PlayState
		return finished ? (stopped ? Stopped : Complete) : paused ? Paused : Playing;

	/** Stops it and releases its resource reference. False once it has finished. */
	public function stop():Bool {
		if (finished)
			return false;
		if (id != 0)
			resource.backend.stop(id);
		stopped = true;
		end();
		return true;
	}

	/** Pauses it where it is. False unless it's playing. */
	public function pause():Bool {
		if (finished || paused)
			return false;
		if (id != 0)
			resource.backend.pause(id, true);
		paused = true;
		return true;
	}

	/** Plays on from where it was paused. False unless it's paused. */
	public function resume():Bool {
		if (finished || !paused)
			return false;
		if (id != 0)
			resource.backend.pause(id, false);
		paused = false;
		return true;
	}

	/** Its own volume, 0 to 1. Clamped to 0..1 (NaN is 0); once it has finished, kept but not heard. Assigning it ends a fade, whose done
		doesn't run. */
	public var volume(default, set):Float;

	function set_volume(value:Float):Float {
		fading = null;
		volume = value > 0 ? (value < 1 ? value : 1) : 0;
		refresh();
		return volume;
	}

	/** What it is heard at, 0 to 1: its volume times its bus's heardVolume. */
	public var heardVolume(get, never):Float;

	function get_heardVolume():Float
		return volume * bus.heardVolume;

	/** Its playback rate, 0.25 to 4 (1 as recorded; 2 an octave up and half as long), clamped (NaN is 1). */
	public var pitch(default, set):Float = 1;

	function set_pitch(value:Float):Float {
		pitch = value >= .25 ? (value <= 4 ? value : 4) : value < .25 ? .25 : 1;
		if (id != 0 && !finished)
			resource.backend.setPitch(id, pitch);
		return pitch;
	}

	/** Where it is heard, -1 (left) to 1 (right), 0 the middle, equal power; clamped (NaN is 0). */
	public var pan(default, set):Float = 0;

	function set_pan(value:Float):Float {
		pan = value >= -1 ? (value <= 1 ? value : 1) : value < -1 ? -1 : 0;
		if (id != 0 && !finished)
			resource.backend.setPan(id, pan);
		return pan;
	}

	/** Moves its volume to to (0 to 1, clamped) over seconds (0 or less, or NaN, sets it at once), linear in decibels, a silent end taken as
		-60 dB; at the end done runs (during this call for 0 seconds) and, with stopWhenSilent and an end of 0, it stops. A fade started over
		another, or a volume assigned, ends the earlier one, whose done doesn't run. Nothing once it has finished. */
	public function fade(to:Float, seconds:Float, ?done:Void->Void, stopWhenSilent = false):Void
		fadeAlong(to, seconds, done, stopWhenSilent, Decibels);

	/** fade along curve: Audio.crossfade's, linear in power. */
	@:allow(helix.audio.Audio)
	function fadeAlong(to:Float, seconds:Float, done:Null<Void->Void>, stopWhenSilent:Bool, curve:FadeCurve):Void {
		if (finished)
			return;
		var fade = new Fade(volume, to > 0 ? (to < 1 ? to : 1) : 0, seconds, done, curve);
		if (fade.finished) {
			volume = fade.step(0);
			ended(fade, stopWhenSilent);
		} else {
			fading = fade;
			this.stopWhenSilent = stopWhenSilent;
		}
	}

	// A fade reached its end: stopped when asked and silent, then its done.
	function ended(fade:Fade, stopWhenSilent:Bool):Void {
		if (stopWhenSilent && volume == 0)
			stop();
		if (fade.done != null)
			fade.done();
	}

	/** Steps its fade by delta seconds. AudioResources.poll calls it once a frame. */
	@:allow(helix.audio.AudioResources)
	function advance(delta:Float):Void {
		var fade = fading;
		if (fade == null || finished)
			return;
		volume = fade.step(delta);
		if (!fade.finished)
			fading = fade;
		else
			ended(fade, stopWhenSilent);
	}

	/** Sends its heard volume to its voice when it changed since the last sent. */
	@:allow(helix.audio.AudioResources)
	function refresh():Void {
		if (id == 0 || finished)
			return;
		var heard = heardVolume;
		if (heard != sent) {
			sent = heard;
			resource.backend.setVolume(id, heard);
		}
	}

	/** Starts it once audio runs, and finishes it, releasing its resource reference, once the adapter no longer plays it. AudioResources.poll
		calls it. */
	public function poll():Void {
		if (finished)
			return;
		if (waiting) {
			if (resource.backend.running)
				begin();
			return;
		}
		if (!resource.backend.isPlaying(id))
			end();
	}
}
