package helix.services.assets;

/** Specifies how an `HttpServer` source knows its kept copy of a file is current: by asking the server, by trusting it, by keeping none, or
	by the server's manifests. */
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

	/** Uses the server's manifests (`AssetsOptions.manifestName`, which `AssetManifests` writes): a copy with the hash its manifest lists is
		used without asking, and otherwise a file system source after this one with that hash is read in place, or the file is downloaded
		and must have it. A file its directory's manifest leaves out is asked about, however fresh. A server with no manifest is warned
		about once a run, and its files are treated as Revalidate treats them. */
	Manifest;
}
