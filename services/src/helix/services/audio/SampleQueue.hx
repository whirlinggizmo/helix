package helix.services.audio;

import haxe.io.Bytes;
import helix.platform.IAudio;

/** Represents samples played as they are added (`Audio.createSampleQueue`), for sound a program makes as it goes.

	Samples added ahead of what is heard play back to back without a gap. A queue that runs out keeps playing, silent, and goes on when
	more are added. It has one voice at a time, which plays in a group like any other: its group's volume, mute and fades apply.

	```haxe
	var queue = audio.createSampleQueue(1, 22050);
	queue.queueSamples(tone);
	var voice = queue.play(effects);
	// each frame, while fewer than a buffer's frames wait:
	if (queue.queuedFrames < 4096)
		queue.queueSamples(more());
	``` */
@:allow(helix.services.audio)
class SampleQueue {
	final audio:Audio;
	final output:IAudio;
	// The output's queue; disposed once let go.
	final id:Int;
	var disposed = false;
	var voice:Null<Voice> = null;

	@:allow(helix.services.audio)
	function new(audio:Audio, output:IAudio, id:Int) {
		this.audio = audio;
		this.output = output;
		this.id = id;
	}

	/** Adds samples to the end of the queue.

		They are copied. Samples added while the queue has no voice wait for `play`. A partial frame at the end is ignored.

		@param samples  32-bit float PCM at the queue's rate, -1 to 1, interleaved when stereo.
		@throws String  When the queue is disposed. */
	public function queueSamples(samples:Bytes):Void {
		if (disposed)
			throw 'queueSamples on a disposed queue';
		output.queueSamples(id, samples);
	}

	/** Gets how many frames the queue holds that haven't been heard yet; 0 once it is disposed. */
	public var queuedFrames(get, never):Int;

	function get_queuedFrames():Int {
		return disposed ? 0 : output.getQueuedFrames(id);
	}

	/** Starts the queue playing what it holds and what is added to it.

		Playing it again stops its earlier voice and keeps its samples. Its voice ends only when stopped, which drops the samples not yet
		heard. It can't be moved (`Voice.setPosition`).

		@param group  Optional. The group it plays in. Defaults to `Audio.master`.
		@param volume  Optional. The voice's own volume, 0 to 1, before its groups' volumes apply. Defaults to 1.
		@return  The voice.
		@throws String  When the queue is disposed. */
	public function play(?group:Group, volume = 1.):Voice {
		if (disposed)
			throw 'play on a disposed queue';
		// The output ends the earlier voice itself, keeping the samples, which stopping it would drop.
		if (voice != null)
			voice.ended = true;
		voice = audio.start(this, group, volume);
		return voice;
	}

	/** Stops its voice and lets go of the queue and its samples. Does nothing once disposed. */
	public function dispose():Void {
		if (disposed)
			return;
		disposed = true;
		if (voice != null)
			voice.stop();
		voice = null;
		output.disposeQueue(id);
		audio.forget(this);
	}
}
