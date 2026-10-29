package helix.platform.adapters.window.sdl3;

/** Specifies the graphics adapter an SDL3 window is opened for. */
enum Sdl3WindowGraphics {
	/** A GL 4.1 context, for `SokolGraphicsAdapter`. */
	Gl;

	/** No GL context, for `Sdl3GpuGraphicsAdapter`. */
	Gpu;
}
