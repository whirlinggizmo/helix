package helix.ui;

/** Where layouts go in the room they have, along an axis. */
enum Alignment2D {
	/** At its start: the left, or the top. */
	Start;

	/** In its middle. */
	Center;

	/** At its end: the right, or the bottom. */
	End;

	/** Across a row or column only: filling it, for the children that grow that way or whose size that way nobody set (widthSizing,
		heightSizing; the theme's included); the others keep their size there, at their anchor that way or at its start. In a stack, as an
		anchor: filling it that way. */
	Stretch;
}
