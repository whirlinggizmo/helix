package helix.platform.adapters.gamepads.sdl3;

import helix.platform.adapters.events.sdl3.Sdl3EventsAdapter;

/** Represents what `Sdl3GamepadsAdapter` is built over. */
@:structInit
class Sdl3GamepadsAdapterOptions {
	/** Gets the events adapter whose `poll` delivers its events. */
	public final events:Sdl3EventsAdapter;
}
