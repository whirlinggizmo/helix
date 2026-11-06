package helix.platform.adapters.window.dom;

/** Represents what `DomWindowAdapter` is made over. */
@:structInit
class DomWindowAdapterOptions {
	/** Gets the id of the canvas the program draws in: what goes fullscreen or hides, and the drawing surface. */
	public final canvasId:String;

	/** Gets whether the drawing buffer is the canvas's size times the device's pixel ratio, sharp on a dense screen at the ratio squared
		in pixels filled, or the canvas's logical size, one framebuffer pixel a CSS pixel, which the browser scales to the screen. False
		until set. */
	public final highDpi:Bool = false;
}
