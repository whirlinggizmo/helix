package helix.services.assets;

import helix.platform.IFileSystem;

/** Specifies a place `Assets` finds files: a file system on this machine, or an HTTP server. */
enum AssetSource {
	/** Files read as they are from a file system: natively the files the program ships with, a read-only `NativeFileSystemAdapter` over
		`ISystem.getProgramDirectory()`. In a page a file system starts empty, so the page's files come from an `HttpServer`. */
	FileSystem(fileSystem:IFileSystem);

	/** Files on an HTTP server, under a URL: downloaded through `AssetsOptions.httpClient` and kept in `AssetsOptions.cacheFileSystem`, so
		a later run downloads one again only when it's missing or changed.

		The URL is the directory the paths are under; in a page it may be relative to the page, and "" is the page's own directory. The
		cache mode says how a kept copy is known to be current: Revalidate by default. */
	HttpServer(url:String, ?cacheMode:AssetCacheMode);
}
