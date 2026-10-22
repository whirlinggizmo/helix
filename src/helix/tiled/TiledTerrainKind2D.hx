package helix.tiled;

/** How a terrain set's tiles meet: at their corners, their edges, or both (Tiled's terrain set types). */
enum TiledTerrainKind2D {
	/** Each tile's four corners carry a terrain: the common one for ground. */
	Corner;

	/** Each tile's four edges carry a terrain: paths, roads, fences. */
	Edge;

	/** Corners and edges both: drawn as Tiled stored it, but not painted at run time (TiledTileLayer2D.setTerrain refuses it). */
	Mixed;
}
