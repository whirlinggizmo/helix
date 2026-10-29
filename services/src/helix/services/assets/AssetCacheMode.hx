package helix.services.assets;

/** Specifies how an `HttpServer` source decides whether its kept copy of a file is current.

	The copy can be checked with the server, trusted, not kept at all, or checked against the server's manifests. */
enum AssetCacheMode {
	/** Uses a copy without asking while the server's Cache-Control says it is fresh, and asks the server about any other copy.

		An unchanged file keeps its copy. A changed file replaces the copy. A file that is gone removes the copy, and the file is looked for in the next source. When
		the server doesn't answer, because the machine is offline or the server fails, the copy is used. This is the default. */
	Revalidate;

	/** Uses a copy without asking, however old it is.

		It suits files that never change, or a game that plays offline. */
	Trust;

	/** Keeps nothing between runs and ignores what earlier runs kept.

		Each file is downloaded once a run and held in memory. It is meant for development. */
	Off;

	/** Uses the server's manifests to tell whether a copy is current.

		The manifests are named by `AssetsOptions.manifestName`, and `AssetManifests` writes them. A copy with the hash its manifest lists
		is used without asking. Otherwise, a file system source after this one that has a file with that hash reads it in place; failing
		that, the file is downloaded, and the download must have that hash. A file that its directory's manifest omits is asked about,
		however fresh its copy. A server with no manifest is warned about once a run, and its files are treated as `Revalidate` treats
		them. */
	Manifest;
}
