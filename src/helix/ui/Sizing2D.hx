package helix.ui;

/** How a layout's width or height is decided. */
enum Sizing2D {
	/** This many units. */
	Fixed(units:Float);

	/** Its content's: its children's (and gaps and padding), or its node's own (a text's measured width, a sprite's or rectangle's size). */
	Fit;

	/** A share of the room its row or column has left, by weight against its siblings' (across, the whole room). */
	Grow(weight:Float);

	/** This fraction of its parent's room inside the padding, less its own margins that way (0 to 1). */
	Percent(fraction:Float);
}
