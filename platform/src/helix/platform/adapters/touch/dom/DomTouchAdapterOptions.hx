package helix.platform.adapters.touch.dom;

import helix.platform.adapters.events.dom.DomEventsAdapter;

/** Represents what `DomTouchAdapter` is built over. */
@:structInit
class DomTouchAdapterOptions {
	/** Gets the events adapter whose `poll` delivers its events. */
	public final events:DomEventsAdapter;
}
