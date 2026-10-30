package helix.platform.adapters.tilt.dom;

import helix.platform.adapters.events.dom.DomEventsAdapter;

/** Represents what `DomTiltAdapter` is built over. */
@:structInit
class DomTiltAdapterOptions {
	/** Gets the events adapter whose `poll` delivers its events. */
	public final events:DomEventsAdapter;
}
