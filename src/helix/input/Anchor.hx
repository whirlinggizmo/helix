package helix.input;

/** A point of the visible area (Screen's), which a touch region is placed from: a corner, an edge's middle or the center. */
enum Anchor {
	/** The visible area's top left corner. */
	TopLeft;

	/** The middle of its top edge. */
	Top;

	/** Its top right corner. */
	TopRight;

	/** The middle of its left edge. */
	Left;

	/** Its center. */
	Center;

	/** The middle of its right edge. */
	Right;

	/** Its bottom left corner. */
	BottomLeft;

	/** The middle of its bottom edge. */
	Bottom;

	/** Its bottom right corner. */
	BottomRight;
}
