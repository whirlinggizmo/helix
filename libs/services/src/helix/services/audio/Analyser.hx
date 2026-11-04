package helix.services.audio;

import haxe.exceptions.NotImplementedException;
import haxe.io.Bytes;

/** Represents a reading of what a group plays (`AudioEffects.addAnalyser`), for a level meter or a visualizer, until it is removed.

	It reads what was heard at the last `AudioEffects.poll`. Natively that is up to one output block late. */
class Analyser {
	@:allow(helix.services.audio)
	function new() {}

	/** Gets the group it reads. */
	public var group(default, null):Group;

	/** Gets how many of the latest frames it keeps. */
	public var frameCount(default, null):Int;

	/** Gets how many frames it has read since it was added, so a reader can tell which of the latest are new since its last read. */
	public var framesPassed(get, never):Float;

	function get_framesPassed():Float {
		throw new NotImplementedException();
	}

	/** Copies the latest frames heard.

		@param into  Receives the frames as 32-bit floats, -1 to 1, stereo interleaved, left first, the oldest first. Its length sets how
			many, up to `frameCount`.
		@return  The frames copied, fewer than asked until enough have played. */
	public function getSamples(into:Bytes):Int {
		throw new NotImplementedException();
	}

	/** Measures the latest frames heard by frequency, as Web Audio's `AnalyserNode` does.

		@param into  Receives the bands as 32-bit floats in decibels, from 0 Hz up to half the output's rate, evenly spaced. Its length
			sets how many, up to half of `frameCount`.
		@return  The bands written. */
	public function getSpectrum(into:Bytes):Int {
		throw new NotImplementedException();
	}

	/** Returns how loud the latest frames were, for a level meter.

		@return  Their root mean square across both channels, 0 (silent) to 1. */
	public function getLevel():Float {
		throw new NotImplementedException();
	}

	/** Removes it from its group. Its members change nothing after. */
	public function remove():Void {
		throw new NotImplementedException();
	}
}
