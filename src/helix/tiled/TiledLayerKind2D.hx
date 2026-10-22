package helix.tiled;

/** What a Tiled layer holds. */
enum TiledLayerKind2D {
	/** A grid of tiles (tiles, columns, rows). */
	Tiles;

	/** Objects (objects). */
	Objects;

	/** One image (image). */
	Image;

	/** Other layers (layers). */
	Group;
}
