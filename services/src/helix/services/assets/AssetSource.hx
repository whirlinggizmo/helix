package helix.services.assets;

import helix.platform.IFileSystem;

/** Specifies a place `Assets` finds files: a file system on this machine, or an HTTP server. */
enum AssetSource {
	/** Files read as they are from a file system: natively the files the program ships with, a read-only `NativeFileSystemAdapter` over
		`ISystem.getProgramDirectory()`. In a page a file system starts empty, so the page's files come from an `HttpServer`. */
	FileSystem(fileSystem:IFileSystem);

	/** Files on an HTTP server, under a URL: downloaded through `AssetsOptions.httpClient` and kept in `AssetsOptions.cacheFileSystem`, so
		a later run downloads one again only when it's missing or changed.

		The URL is the directory the paths are under; in a page it may be relative to the page, and "" is the page's own directory. When
		the server has manifests (`AssetsOptions.manifestName`), a kept copy with its manifest's hash is used without asking, and a file
		system source after it with the same hash is read in place of a download; without them, the cache mode decides. */
	HttpServer(url:String, ?cacheMode:AssetCacheMode);
}
