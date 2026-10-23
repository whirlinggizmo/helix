package helix.ui;

/** How a layout lays its children out. */
enum LayoutDirection2D {
	/** Left to right. */
	Row;

	/** Top to bottom. */
	Column;

	/** Over one another, each placed by its own alignment in the layout (anchored to an edge, a corner or the middle). */
	Stack;
}
