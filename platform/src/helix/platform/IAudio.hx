package helix.platform;

import haxe.io.Bytes;

/** Defines the sound output: clips held whole and streams played as they are read, each played as voices.

	Clip, stream and voice ids are the adapter's. Samples are mono 32-bit float PCM at 44100 Hz, -1 to 1. A browser starts its audio on the
	page's first key or pointer press and suspends it while the page is hidden or blurred; natively it runs once the device opens. */
interface IAudio {
	/** Gets a value indicating whether there is an output at all: false natively without an audio device. */
	var available(get, never):Bool;

	/** Gets a value indicating whether voices are heard now.

		In a browser it's false until the page's first key press, mouse button or tap, which the adapter listens for and unlocks audio at
		itself, and false again while the page is hidden. Natively it's true once the device opens. A voice asked for before then waits and
		starts once it runs (`playClip`). */
	var running(get, never):Bool;

	/** Gets a value indicating whether `openStream` plays a `Remote` source's URL itself.

		True in a browser, whose media element streams the URL. False natively: the caller downloads the file and opens the download
		(`Downloading`). */
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

	/** Opens a source for playing as it is read.

		One of `opened` or `failed` is called once, on the main thread, never during this call. A download is opened once enough of it has
		arrived for its codec. A `Local` source's file must outlive the stream.
		@param source  What to play.
		@param opened  Receives the stream's id.
		@param failed  Receives why it can't be opened: natively a `Remote` source, a file its codec can't read, or a download that failed or
			ended unreadable; in a browser a load error, no metadata within 15 seconds, or a `Downloading` source.
		@return  A function that aborts the open: neither callback is called after it, and an opened stream is closed. */
	function openStream(source:StreamSource, opened:Int->Void, failed:String->Void):Void->Void;

	/** Disposes a stream and stops its voices.

		@param stream  The stream.
		@throws String  For an unknown stream. */
	function disposeStream(stream:Int):Void;

	/** Starts a clip playing.

		@param clip  The clip.
		@param loop  True to play it again from the start each time it ends.
		@param volume  The volume, 0 to 1.
		@return  The voice's id, or 0 when there is no output (`available`). Asked for before audio runs, the voice waits, its volume, pitch,
			pan and pause kept, and starts at the first `poll` once it does; meanwhile `isPlaying` is true.
		@throws String  For an unknown clip. */
	function playClip(clip:Int, loop:Bool, volume:Float):Int;

	/** Starts a stream playing from its beginning.

		@param stream  The stream.
		@param loop  True to play it again from the start each time it ends.
		@param volume  The volume, 0 to 1.
		@return  The voice's id, or 0 when there is no output (`available`) or, natively, a file that can't be played. Asked for before audio
			runs, the voice waits and starts once it does, as `playClip`'s.
		@throws String  For an unknown stream. */
	function playStream(stream:Int, loop:Bool, volume:Float):Int;

	/** Stops a voice; does nothing for an unknown or ended one.

		@param voice  The voice. */
	function stop(voice:Int):Void;

	/** Pauses or resumes a voice; does nothing for an unknown one.

		@param voice  The voice.
		@param paused  True to pause it, false to resume it. */
	function pause(voice:Int, paused:Bool):Void;

	/** Sets a voice's volume.

		The change is ramped over a few milliseconds (the output's next block), so a fade stepped once a frame doesn't click.
		@param voice  The voice.
		@param volume  The volume, 0 to 1.
		@return  False, changing nothing, for a voice not playing (unknown, stopped or ended) or a volume outside 0 to 1. */
	function setVolume(voice:Int, volume:Float):Bool;

	/** Sets a voice's playback rate, which changes its pitch and length together.

		@param voice  The voice.
		@param pitch  The rate, 0.25 to 4; 1 as recorded.
		@return  False, changing nothing, for a voice not playing (unknown, stopped or ended). */
	function setPitch(voice:Int, pitch:Float):Bool;

	/** Sets a voice's pan, equal power.

		The change is ramped as a volume's is.
		@param voice  The voice.
		@param pan  -1 left to 1 right; 0 the middle.
		@return  False, changing nothing, for a voice not playing (unknown, stopped or ended). */
	function setPan(voice:Int, pan:Float):Bool;

	/** Returns whether a voice is still playing or paused.

		@param voice  The voice.
		@return  False once it ended or was stopped, and for an unknown voice. */
	function isPlaying(voice:Int):Bool;

	/** Keeps streamed voices fed, opens downloads that have arrived far enough, and delivers what the platform's threads finished; call once a
		frame. */
	function poll():Void;

	/** Stops every voice, disposes every stream and clip, and closes the output. */
	function dispose():Void;
}
