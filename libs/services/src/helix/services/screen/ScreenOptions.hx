package helix.services.screen;

/** Represents how `Screen` starts: its design size and how it fits the window. */
@:structInit
class ScreenOptions {
	/** Gets the design's width, in design pixels; 0, the default, for none: the window's own logical size. */
	public final designWidth:Int = 0;

	/** Gets the design's height, in design pixels; 0, the default, for none. */
	public final designHeight:Int = 0;

	/** Gets how the design fits the window. Defaults to `Letterbox`. */
	public final fit:ScreenFit = Letterbox;
}
