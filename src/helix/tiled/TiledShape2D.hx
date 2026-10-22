package helix.tiled;

/** What a Tiled object is: its shape in Tiled's toolbar. */
enum TiledShape2D {
	/** A rectangle, x and y its top-left corner. */
	Rectangle;

	/** A point: x and y alone, no size. */
	Point;

	/** An ellipse in the rectangle at x, y, width x height. */
	Ellipse;

	/** A closed polygon through points, relative to x, y. */
	Polygon;

	/** An open line through points, relative to x, y. */
	Polyline;

	/** A tile placed as an object (gid), x and y its bottom-left corner as Tiled places it; drawn on its layer. */
	Tile;

	/** Text, drawn in Tiled only: its rectangle as a Rectangle's. */
	Text;
}
