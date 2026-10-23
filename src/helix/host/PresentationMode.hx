package helix.host;

/** How a game's design is fitted to the window (Godot's stretch modes and aspects). */
enum PresentationMode {
	/** The default: a unit is a logical pixel (a framebuffer pixel over the pixel ratio), and the visible area is the window. */
	None;

	/** The design scaled to the window on each axis apart, its aspect lost. */
	Stretch;

	/** Scaled alike on both axes, as large as it fits whole, centered; the framebuffer around it is bars, nothing drawn in them. */
	Fit;

	/** Scaled alike, as small as covers the window, centered; what's past the window's edges is cropped. */
	Fill;

	/** Scaled as Fit is, but the visible area grows past the design to the window's edges, centered on it: the design is the least the game
		shows, and a layout arranged into the visible area keeps to the window's edges. */
	Expand;

	/** As Fit, at a whole number of framebuffer pixels to a unit (at least 1), for pixel art; bars around it. */
	Integer;
}
