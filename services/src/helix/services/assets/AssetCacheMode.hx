package helix.services.assets;

/** Specifies when `Assets` uses its kept copy of an `HttpServer` file that no manifest lists, and when it asks the server. */
enum AssetCacheMode {
	/** Uses a copy the server said is still fresh (its Cache-Control) and asks about any other. Unchanged, the copy is used; changed, the
		new file replaces it; gone, the copy is removed and the load fails. When the server doesn't answer (offline, an error) the copy is
		used. The default. */
	Revalidate;

	/** Uses a copy without asking, however old: for files that never change, or a game that plays offline. */
	Trust;

	/** Keeps nothing between runs and uses nothing earlier runs kept; each file is downloaded once a run and held in memory. For
		development. */
	Off;
}
