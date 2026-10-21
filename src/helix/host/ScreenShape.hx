package helix.host;

/** A design per window shape, as a page's breakpoints (Defold's display profiles): 1280 x 720 for a desktop window, 1000 x 560 for a
	short one (a phone on its side), 560 x 960 upright (a phone held so), each grown to the window's edges (Presentation's Expand), so text
	at one size stays readable on a phone in each. The examples' choice, called at the top of their frame; a game with designs of its own
	sets Screen itself. */
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
