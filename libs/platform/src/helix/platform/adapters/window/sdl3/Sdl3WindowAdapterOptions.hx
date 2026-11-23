package helix.platform.adapters.window.sdl3;

/** Represents how `Sdl3WindowAdapter` opens its window. */
@:structInit
class Sdl3WindowAdapterOptions {
	/** Gets the graphics adapter that draws in the window. */
	public final graphics:Sdl3WindowGraphics;

	/** Gets the number of multisampling samples a pixel asks for; 1 for none, the default. The GPU may use fewer. */
	public final msaaSampleCount:Int = 1;

	/** Gets whether presenting waits for the display's refresh, which paces the owner's loop: true, the default. False shows each frame
		as soon as it is drawn, which may tear. */
	public final vsync:Bool = true;

	/** Gets whether the window is see-through where drawing leaves alpha below 1, the desktop under it showing where the window system
		allows it; false by default, the window opaque. */
	public final transparent:Bool = false;
}
