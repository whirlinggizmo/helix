package helix.audio;

import haxe.io.Bytes;
import helix.assets.IAssets.AudioLocation;

/** How opening a stream ended: its id, or a failure message. */
enum StreamOpenResult {
	Opened(id:Int);
	Failed(message:String);
}

/** Sound output on a platform: clips (PCM held whole) and streams (played as they're read), each played as voices. Ids are the adapter's;
	lifetimes, volume checks, waiting for audio to start and decoding are the shared AudioResources' and AudioDecoding's. A browser starts its
	audio on the page's first key or pointer press and suspends it while the page is hidden or blurred; natively it runs once the device opens. */
interface IAudio {
	/** Whether there is an output at all: false natively without an audio device. */
	public function isAvailable():Bool;

	/** Whether voices start now: in a browser, once a key or pointer press has unlocked audio. */
	public function isRunning():Bool;

	/** Copies samples (mono 32-bit float PCM at 44100 Hz, checked) into a new clip and returns its id. Throws when there's no room for a clip. */
	public function createClip(samples:Bytes):Int;

	/** Destroys clip and stops its voices. Throws for an unknown clip. */
	public function destroyClip(clip:Int):Void;

	/** Opens source for playing as it's read; done runs once on the host thread, never during this call: Opened, or Failed for a source the
		platform can't open (natively a remote URL or a file its codec can't read; in a browser a load error or no metadata within 15 seconds).
		A Stored lease stays the caller's and must outlive the stream. Returns abort: nothing is called after it, and an opened stream is closed. */
	public function openStream(source:AudioLocation, done:StreamOpenResult->Void):Void->Void;

	/** Destroys stream and stops its voices. Throws for an unknown stream. */
	public function destroyStream(stream:Int):Void;

	/** Starts clip at volume (0 to 1), looping if asked, and returns its voice, or 0 when it can't start (no free voice). Throws for an unknown
		clip. */
	public function playClip(clip:Int, loop:Bool, volume:Float):Int;

	/** Starts stream from its beginning at volume (0 to 1), looping if asked, and returns its voice, or 0 when it can't start. Throws for an
		unknown stream. */
	public function playStream(stream:Int, loop:Bool, volume:Float):Int;

	/** Stops voice; nothing for an unknown or ended one. */
	public function stop(voice:Int):Void;

	/** Pauses voice, or resumes it when paused is false; nothing for an unknown one. */
	public function pause(voice:Int, paused:Bool):Void;

	/** Sets voice's volume, 0 to 1. False, changing nothing, for a voice not playing (unknown, stopped or ended) or a volume outside 0 to 1. */
	public function setVolume(voice:Int, volume:Float):Bool;

	/** Whether voice is still playing (or paused); false once it ended or was stopped. */
	public function isPlaying(voice:Int):Bool;

	/** Keeps streamed voices fed and delivers what arrived from the platform's threads; the shared AudioResources calls it once a frame. */
	public function poll():Void;

	/** Stops every voice, destroys every stream and clip, and closes the output. */
	public function shutdown():Void;
}
