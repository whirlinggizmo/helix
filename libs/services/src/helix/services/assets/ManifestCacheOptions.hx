package helix.services.assets;

import helix.platform.IFileSystem;

/** Specifies how a `ManifestCache` finds manifests. */
@:structInit
class ManifestCacheOptions {
	/** Gets each directory's manifest's file name. Defaults to "manifest.json", the name `AssetManifests` writes. */
	public final manifestName:String = "manifest.json";

	/** Gets the file systems whose files may be read in place of a download, by their own manifests. Defaults to none.

		List the same file systems as `FileSystemSource`s after the server, so they also answer offline. */
	public final shipped:Array<IFileSystem> = [];
}
