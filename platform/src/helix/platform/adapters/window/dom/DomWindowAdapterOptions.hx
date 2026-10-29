package helix.platform.adapters.window.dom;

import js.html.CanvasElement;

/** Represents what `DomWindowAdapter` is made over. */
@:structInit
class DomWindowAdapterOptions {
	/** Gets the canvas the program draws in: what goes fullscreen or hides, and the drawing surface. */
	public final canvas:CanvasElement;
}
