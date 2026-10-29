package helix.platform.adapters.events.dom;

/** Represents what `DomEventsAdapter` listens to. */
@:structInit
class DomEventsAdapterOptions {
	/** Gets the id of the canvas the program draws in: where the pointer is read and what the WebGL context belongs to. */
	public final canvasId:String;
}
