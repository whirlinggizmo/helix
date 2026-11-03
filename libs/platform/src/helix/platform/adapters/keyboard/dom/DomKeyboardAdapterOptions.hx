package helix.platform.adapters.keyboard.dom;

import helix.platform.adapters.events.dom.DomEventsAdapter;

/** Represents what `DomKeyboardAdapter` is built over. */
@:structInit
class DomKeyboardAdapterOptions {
	/** Gets the events adapter whose `poll` delivers its events. */
	public final events:DomEventsAdapter;
}
