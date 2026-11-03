package helix.platform.adapters.mouse.dom;

import helix.platform.adapters.events.dom.DomEventsAdapter;

/** Represents what `DomMouseAdapter` is built over. */
@:structInit
class DomMouseAdapterOptions {
	/** Gets the events adapter whose `poll` delivers its events. */
	public final events:DomEventsAdapter;
}
