package helix.platform.adapters.events.dom;

import js.html.CanvasElement;

/** Represents what `DomEventsAdapter` listens to. */
@:structInit
class DomEventsAdapterOptions {
	/** Gets the canvas the program draws in: where the pointer is read and what the WebGL context belongs to. */
	public final canvas:CanvasElement;
}
