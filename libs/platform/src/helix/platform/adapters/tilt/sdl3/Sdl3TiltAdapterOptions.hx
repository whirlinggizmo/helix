package helix.platform.adapters.tilt.sdl3;

import helix.platform.adapters.events.sdl3.Sdl3EventsAdapter;

/** Represents what `Sdl3TiltAdapter` is built over. */
@:structInit
class Sdl3TiltAdapterOptions {
	/** Gets the events adapter whose `poll` delivers its events. */
	public final events:Sdl3EventsAdapter;
}
