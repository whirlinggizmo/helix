package helix.services.assets;

import helix.platform.IFileSystem;

/** Specifies a place `Assets` finds files: a file system on this machine, or an HTTP server. */
enum AssetSource {
	/** Reads files as they are from a file system.

		Natively this is usually the files the program ships with: a read-only `NativeFileSystemAdapter` over
		`ISystem.getProgramDirectory()`. In a page a file system starts empty, so the page's files come from an `HttpServer` instead. */
	FileSystem(fileSystem:IFileSystem);

	/** Downloads files from an HTTP server, under a URL.

		Files are downloaded through `AssetsOptions.httpClient` and kept in `AssetsOptions.cacheFileSystem`. A later run downloads a file
		again only when its copy is missing or changed.

		The URL is the directory the paths are under. In a page it may be relative to the page, and "" is the page's own directory. The
		optional cache mode decides how a kept copy is known to be current, and defaults to `Revalidate`. */
	HttpServer(url:String, ?cacheMode:AssetCacheMode);
}
