package helix.audio;

import helix.assets.IRequest;
import haxe.io.Bytes;
import helix.assets.IAssets.AudioLocation;

/** How opening a stream ended: its backend id, a failure message, or cancellation. */
enum StreamResult {
	Created(id:Int);
	Failed(message:String);
	Cancelled;
}

/** How a decode ended: mono 32-bit float PCM at 44100 Hz, samples -1 to 1, a failure message, or cancellation. */
enum ClipDecodeResult {
	Decoded(samples:Bytes);
	Failed(message:String);
	Cancelled;
}

/** Adapter-level IDs. Public resource/playback lifetime lives in AudioResources. */
interface IAudio {
	/** Decodes a whole WAV (mono PCM16 at 44100 Hz, at most 4 seconds), Ogg (Vorbis, Opus) or MP3 file to PCM, off the host thread where the target allows; the caller keeps encoded. complete runs exactly once on the host thread; Failed for a closed adapter, more than 8 MiB encoded, more than 2Mi decoded frames, or an unsupported or corrupt file. */
	function decodeClip(encoded:Bytes, complete:ClipDecodeResult->Void):IRequest;

	/** Copies PCM samples (from decodeClip) into a new backend clip and returns its id. Throws for invalid PCM or when the backend has no room for a clip. */
	function createClip(samples:Bytes):Int;

	/** Opens source for progressive playback and completes on the host thread with a stream id; a Stored lease stays the caller's and must outlive the stream. Failed for a closed adapter or a source the adapter cannot open (natively a remote URL, a non-canonical WAV, or a compressed file libsndfile cannot read as Ogg Vorbis, Opus or MP3; in the browser a load error or no metadata within 15 seconds). */
	function createStream(source:AudioLocation, complete:StreamResult->Void):IRequest;

	/** Starts clip or stream resource at volume 0 to 1 and returns a playback id, or 0 when it can't play (no free voice, a closed backend). In a
		browser whose audio is still locked (no key press or click yet) the playback waits, and starts when audio unlocks. Throws for an unknown resource
		or a volume outside 0 to 1. */
	function play(resource:Int, loop:Bool = false, volume:Float = 1):Int;

	/** Stops playback and frees what it holds; does nothing for an unknown or ended playback. */
	function stop(playback:Int):Void;

	/** Pauses playback, or resumes it when paused is false; does nothing for an unknown playback. */
	function pause(playback:Int, paused:Bool):Void;

	/** Sets playback's volume, 0 to 1; does nothing for an unknown playback. Throws for a volume outside 0 to 1. */
	function setVolume(playback:Int, volume:Float):Void;

	/** Whether playback is still active, paused included; false once it ended or was stopped. */
	function isPlaying(playback:Int):Bool;

	/** Destroys clip and stops its playbacks. Throws for an unknown clip. */
	function destroyClip(clip:Int):Void;

	/** Destroys stream; the browser adapter stops its playbacks, the native one lets them play out. Throws for an unknown stream. */
	function destroyStream(stream:Int):Void;

	/** Runs completions on the host thread and, natively, starts queued decodes and refills stream playbacks. Call once per frame. */
	function poll():Void;

	/** Cancels pending requests (each completes Cancelled), stops every playback, destroys every stream and clip, and closes the audio device. */
	function shutdown():Void;
}
