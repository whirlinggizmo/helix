package helix.platform.adapters.touch.sdl3;

import helix.platform.adapters.events.sdl3.Sdl3EventsAdapter;

/** Represents what `Sdl3TouchAdapter` is built over. */
@:structInit
class Sdl3TouchAdapterOptions {
	/** Gets the events adapter whose `poll` delivers its events. */
	public final events:Sdl3EventsAdapter;
}
