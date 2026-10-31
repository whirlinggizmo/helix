package helix.platform;

import haxe.io.Bytes;

/** Defines the sound output, which plays clips held whole, streams played as they are read, and queues of samples fed as they play.

	Each playing of a clip, a stream or a queue is a voice. Clip, stream, queue and voice ids are the adapter's. Samples are 32-bit float
	PCM, -1 to 1, mono or stereo; stereo samples are interleaved, left first. A clip's rate is 44100 Hz. A stream plays its file's channels.

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

		A partial frame at the end is ignored.
		@param samples  32-bit float PCM at 44100 Hz, -1 to 1, interleaved when stereo.
		@param channels  The channels, 1 (mono) or 2 (stereo).
		@return  The clip's id.
		@throws String  When channels isn't 1 or 2, the samples hold no whole frame, or there is no room for the clip. */
	function createClip(samples:Bytes, channels:Int):Int;

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

	/** Returns a stream's length.

		The length may be unknown at first and known later. Natively, a `Downloading` source's length is unknown until all of it has
		arrived. In a page, it is unknown for a live stream.
		@param stream  The stream.
		@return  The length in seconds, or 0 while it is unknown.
		@throws String  For an unknown stream. */
	function getStreamDuration(stream:Int):Float;

	/** Returns how many channels a stream plays.

		@param stream  The stream.
		@return  1 (mono) or 2 (stereo); a file of more plays as stereo. 0 when it can't tell: in a page, where a stream's channels are
			read from its file's first bytes (helix-formats' `AudioHeader`), a kind it doesn't read or a fetch that failed.
		@throws String  For an unknown stream. */
	function getStreamChannels(stream:Int):Int;

	/** Creates a queue, which plays samples given to it as it goes.

		Samples are added with `queueSamples` and played by `playQueue`, back to back without a gap while they are added ahead of what is
		heard. The platform resamples them to the output's rate.
		@param channels  The channels, 1 (mono) or 2 (stereo).
		@param sampleRate  The samples' rate in frames a second, 8000 to 96000.
		@return  The queue's id.
		@throws String  When channels or sampleRate is out of range. */
	function createQueue(channels:Int, sampleRate:Int):Int;

	/** Adds samples to the end of a queue.

		They are copied. Samples added while the queue has no voice wait for `playQueue`. A partial frame at the end is ignored.
		@param queue  The queue.
		@param samples  32-bit float PCM at the queue's rate, -1 to 1, interleaved when stereo.
		@throws String  For an unknown queue. */
	function queueSamples(queue:Int, samples:Bytes):Void;

	/** Returns how many frames a queue holds that haven't been heard yet.

		@param queue  The queue.
		@return  The frames queued and not yet played.
		@throws String  For an unknown queue. */
	function getQueuedFrames(queue:Int):Int;

	/** Disposes a queue and stops its voice.

		@param queue  The queue.
		@throws String  For an unknown queue. */
	function disposeQueue(queue:Int):Void;

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

	/** Starts a queue playing what it holds and what is added to it.

		A queue has one voice at a time: playing it again stops its earlier voice and keeps its samples. A queue that runs out of samples
		keeps playing, silent, and goes on as soon as more are added; its voice ends only when stopped. A voice requested before audio runs
		waits and starts once audio runs, as `playClip`'s does.
		@param queue  The queue.
		@param volume  The volume, 0 to 1.
		@return  The voice's id, or 0 when there is no output (`available`).
		@throws String  For an unknown queue. */
	function playQueue(queue:Int, volume:Float):Int;

	/** Stops a voice.

		Stopping a queue's voice drops the samples it hadn't played yet. It does nothing for an unknown or ended voice.
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

		On a queue's voice in a page, the block playing (what one `queueSamples` call added) finishes at the rate it had, and the blocks
		after it play at the new rate. Natively the change is immediate.
		@param voice  The voice.
		@param pitch  The rate, 0.25 to 4, where 1 plays as recorded.
		@return  False, changing nothing, when the voice isn't playing (unknown, stopped or ended). */
	function setPitch(voice:Int, pitch:Float):Bool;

	/** Sets a voice's pan.

		A mono voice is panned by equal power: at 0 each side hears it at about 0.71. A stereo voice is balanced: at 0 each side hears its
		own channel unchanged, and toward one side the far channel fades by equal power and is mixed into the near one, as Web Audio's
		`StereoPannerNode` does. The change is ramped as a volume change is.
		@param voice  The voice.
		@param pan  The pan, -1 (left) to 1 (right), where 0 is the middle.
		@return  False, changing nothing, when the voice isn't playing (unknown, stopped or ended). */
	function setPan(voice:Int, pan:Float):Bool;

	/** Returns how far a voice has played.

		A looping voice goes back to 0 at each loop. A queue's voice counts the frames it has played since `playQueue`. Natively a stream's
		voice counts what the output has taken from it, a few milliseconds ahead of what is heard.
		@param voice  The voice.
		@return  The position in seconds from the start of its clip, stream or queue; 0 for an unknown or ended voice. */
	function getPosition(voice:Int):Float;

	/** Moves a playing or paused voice to a position.

		A position past the end is clamped to the end, where a voice that doesn't loop ends. A queue's voice can't be moved. In a page, a
		stream moves only within what its media element can seek (`HTMLMediaElement.seekable`), which a server that doesn't take range
		requests prevents.
		@param voice  The voice.
		@param seconds  The position in seconds from the start, 0 or more.
		@return  False, changing nothing, when the voice isn't playing (unknown, stopped or ended), is a queue's, or can't be moved there. */
	function setPosition(voice:Int, seconds:Float):Bool;

	/** Returns whether a voice is still playing or paused.

		@param voice  The voice.
		@return  False once the voice has ended or been stopped, and for an unknown voice. */
	function isPlaying(voice:Int):Bool;

	/** Feeds streamed voices, opens downloads that have arrived far enough, and delivers what the platform's threads finished.

		The program calls it once a frame. */
	function poll():Void;

	/** Stops every voice, disposes every stream, queue and clip, and closes the output. */
	function dispose():Void;
}
