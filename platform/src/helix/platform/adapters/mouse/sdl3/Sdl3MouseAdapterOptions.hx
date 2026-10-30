package helix.platform.adapters.mouse.sdl3;

import helix.platform.adapters.events.sdl3.Sdl3EventsAdapter;

/** Represents what `Sdl3MouseAdapter` is built over. */
@:structInit
class Sdl3MouseAdapterOptions {
	/** Gets the events adapter whose `poll` delivers its events. */
	public final events:Sdl3EventsAdapter;
}
