package helix.platform.adapters.gamepads.dom;

import helix.platform.adapters.events.dom.DomEventsAdapter;

/** Represents what `DomGamepadsAdapter` is built over. */
@:structInit
class DomGamepadsAdapterOptions {
	/** Gets the events adapter whose `poll` delivers its events. */
	public final events:DomEventsAdapter;
}
