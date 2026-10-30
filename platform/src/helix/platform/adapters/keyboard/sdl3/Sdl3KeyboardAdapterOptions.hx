package helix.platform.adapters.keyboard.sdl3;

import helix.platform.adapters.events.sdl3.Sdl3EventsAdapter;

/** Represents what `Sdl3KeyboardAdapter` is built over. */
@:structInit
class Sdl3KeyboardAdapterOptions {
	/** Gets the events adapter whose `poll` delivers its events. */
	public final events:Sdl3EventsAdapter;
}
