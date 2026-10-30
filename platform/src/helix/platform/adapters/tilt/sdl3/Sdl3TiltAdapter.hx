package helix.platform.adapters.tilt.sdl3;

import helix.platform.ITilt;
import helix.platform.adapters.shared.EventStream;

/** Provides `ITilt` on SDL3, natively. No motion sensor is read yet, so the tilt is unavailable on every target. */
class Sdl3TiltAdapter implements ITilt {
	final stream:EventStream;

	/** Creates the tilt.

		@param options  The events adapter its events are delivered by. */
	public function new(options:Sdl3TiltAdapterOptions) {
		stream = options.events.stream;
	}

	/** Returns false, calling neither callback, and reports `Unavailable` at the next poll: no motion sensor is read. */
	public function requestAccess(?done:Void->Void, ?failed:String->Void):Bool {
		stream.record(TiltState(Unavailable));
		return false;
	}

	/** Does nothing: nothing is read. */
	public function releaseAccess():Void {}

	/** Does nothing: nothing is read. */
	public function dispose():Void {}
}
