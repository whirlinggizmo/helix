package helix.platform;

import haxe.io.Bytes;

/** Defines the sound output, which plays clips held whole and streams played as they are read.

	Each playing of a clip or a stream is a voice. Clip, stream and voice ids are the adapter's. Samples are mono
	32-bit float PCM at 44100 Hz, -1 to 1.

	A browser starts its audio on the page's first key or pointer press, and suspends it while the page is hidden or blurred. Natively,
	audio runs once the device opens. */
interface IAudio extends IPollable {
	/** Gets a value indicating whether there is an output at all. It is false natively when there is no audio device. */
	var available(get, never):Bool;

	/** Gets a value indicating whether voices are heard now.

		In a browser it is false until the page's first key press, mouse button or tap. The adapter listens for that press and unlocks audio
		itself. It is false again while the page is hidden. Natively it is true once the device opens. A voice requested before audio runs
		waits, and starts once audio runs (`playClip`). */
	var running(get, never):Bool;

	/** Gets a value indicating whether `openStream` plays a `Remote` source's URL itself.

		It is true in a browser, whose media element streams the URL. It is false natively, where the caller downloads the file and opens
		the download as a `Downloading` source. */
	var playsUrls(get, never):Bool;

	/** Copies samples into a new clip.

		@param samples  Mono 32-bit float PCM at 44100 Hz, -1 to 1.
		@return  The clip's id.
		@throws String  When there is no room for the clip. */
	function createClip(samples:Bytes):Int;

	/** Disposes a clip and stops its voices.

		@param clip  The clip.
		@throws String  For an unknown clip. */
	function disposeClip(clip:Int):Void;

	/** Opens a source to play as it is read.

		One of `opened` or `failed` is called once, on the main thread, never during this call. A download is opened once enough of it has
		arrived for its codec. A `Local` source's file must outlive the stream.
		@param source  What to play.
		@param opened  Receives the stream's id.
		@param failed  Receives why the source can't be opened. Natively, the cause is a `Remote` source, a file its codec can't read, or a
			download that failed or ended unreadable. In a browser, it is a load error, no metadata within 15 seconds, or a `Downloading`
			source.
		@return  A function that aborts the open. Neither callback is called after it, and an opened stream is closed. */
	function openStream(source:StreamSource, opened:Int->Void, failed:String->Void):Void->Void;

	/** Disposes a stream and stops its voices.

		@param stream  The stream.
		@throws String  For an unknown stream. */
	function disposeStream(stream:Int):Void;

	/** Starts a clip playing.

		A voice requested before audio runs waits, and keeps any volume, pitch, pan and pause set on it. It starts at the first `poll` after
		audio runs. Meanwhile `isPlaying` is true for it.
		@param clip  The clip.
		@param loop  True to play it again from the start each time it ends.
		@param volume  The volume, 0 to 1.
		@return  The voice's id, or 0 when there is no output (`available`).
		@throws String  For an unknown clip. */
	function playClip(clip:Int, loop:Bool, volume:Float):Int;

	/** Starts a stream playing from its beginning.

		A voice requested before audio runs waits and starts once audio runs, as `playClip`'s does.
		@param stream  The stream.
		@param loop  True to play it again from the start each time it ends.
		@param volume  The volume, 0 to 1.
		@return  The voice's id, or 0 when there is no output (`available`) or, natively, when the file can't be played.
		@throws String  For an unknown stream. */
	function playStream(stream:Int, loop:Bool, volume:Float):Int;

	/** Stops a voice.

		It does nothing for an unknown or ended voice.
		@param voice  The voice. */
	function stop(voice:Int):Void;

	/** Pauses or resumes a voice.

		It does nothing for an unknown voice.
		@param voice  The voice.
		@param paused  True to pause it, false to resume it. */
	function pause(voice:Int, paused:Bool):Void;

	/** Sets a voice's volume.

		The change is ramped over a few milliseconds (the output's next block), so a fade stepped once a frame doesn't click.
		@param voice  The voice.
		@param volume  The volume, 0 to 1.
		@return  False, changing nothing, when the voice isn't playing (unknown, stopped or ended) or the volume is outside 0 to 1. */
	function setVolume(voice:Int, volume:Float):Bool;

	/** Sets a voice's playback rate, which changes its pitch and length together.

		@param voice  The voice.
		@param pitch  The rate, 0.25 to 4, where 1 plays as recorded.
		@return  False, changing nothing, when the voice isn't playing (unknown, stopped or ended). */
	function setPitch(voice:Int, pitch:Float):Bool;

	/** Sets a voice's pan, using equal-power panning.

		The change is ramped as a volume change is.
		@param voice  The voice.
		@param pan  The pan, -1 (left) to 1 (right), where 0 is the middle.
		@return  False, changing nothing, when the voice isn't playing (unknown, stopped or ended). */
	function setPan(voice:Int, pan:Float):Bool;

	/** Returns whether a voice is still playing or paused.

		@param voice  The voice.
		@return  False once the voice has ended or been stopped, and for an unknown voice. */
	function isPlaying(voice:Int):Bool;

	/** Feeds streamed voices, opens downloads that have arrived far enough, and delivers what the platform's threads finished.

		The program calls it once a frame. */
	function poll():Void;

	/** Stops every voice, disposes every stream and clip, and closes the output. */
	function dispose():Void;
}
