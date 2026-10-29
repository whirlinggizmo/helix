package helix.platform.adapters.window.sdl3;

/** Represents how `Sdl3WindowAdapter` opens its window. */
@:structInit
class Sdl3WindowAdapterOptions {
	/** Gets the graphics adapter that draws in the window. */
	public final graphics:Sdl3WindowGraphics;

	/** Gets the multisampling samples a pixel asks for; 1 for none, the default. The GPU may give fewer. */
	public final msaaSamples:Int = 1;
}
