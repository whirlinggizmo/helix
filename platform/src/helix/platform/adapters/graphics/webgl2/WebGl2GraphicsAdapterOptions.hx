package helix.platform.adapters.graphics.webgl2;

import js.html.CanvasElement;

/** Represents how `WebGl2GraphicsAdapter` makes its context. */
@:structInit
class WebGl2GraphicsAdapterOptions {
	/** Gets the canvas whose WebGL2 context is drawn with. */
	public final canvas:CanvasElement;

	/** Gets the multisampling samples a pixel asks for; 1 for none, the default. Over 1 makes the context antialiased, and the browser
		chooses the number, nearly always 4. */
	public final msaaSamples:Int = 1;

	/** Gets a value indicating whether the drawing buffer is kept after a frame is shown, so it can be read back later; false by default. */
	public final preserveDrawingBuffer:Bool = false;
}
