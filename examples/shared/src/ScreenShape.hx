import helix.host.Screen;
import helix.host.Window;

/** The examples' designs by the window's shape, as a page's breakpoints (Defold's display profiles): 1280 x 720 for a desktop window, 1000 x
	560 for a short one (a phone on its side), 560 x 960 upright (a phone held so), each grown to the window's edges (Presentation's Expand).
	Text at the examples' sizes stays readable on a phone in each. A game chooses its own; this is the examples' choice. */
class ScreenShape {
	/** The window's shape now, the design set for it: "landscape", "short" or "portrait". Once a frame, before the presentation is used: the
		design changes only when the shape does. */
	public static function update():String {
		var window = Window.instance, presentation = Screen.instance;
		var shape = window.height > window.width ? "portrait" : window.height < 600 ? "short" : "landscape";
		var width = shape == "portrait" ? 560 : shape == "short" ? 1000 : 1280,
			height = shape == "portrait" ? 960 : shape == "short" ? 560 : 720;
		if (presentation.mode != Expand || presentation.width != width || presentation.height != height)
			presentation.set(Expand, width, height);
		return shape;
	}
}
