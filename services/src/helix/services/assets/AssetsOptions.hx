package helix.services.assets;

import helix.platform.IFileSystem;
import helix.platform.IHttp;

/** Specifies where `Assets` finds files, and what it downloads with and keeps copies in when a source is an HTTP server. */
@:structInit
class AssetsOptions {
	/** Gets where files are found, asked in this order: a file missing from one is looked for in the next. */
	public final sources:Array<AssetSource>;

	/** Gets the HTTP client `HttpServer` sources download with; null by default, and needed when there is one. */
	public final httpClient:IHttp = null;

	/** Gets the file system `HttpServer` sources' files are kept in; null by default, and needed when there is one. A file system of its own, as
		`clearCache` empties it: natively a `NativeFileSystemAdapter` over `ISystem.getCacheDirectory`, in a page a
		`BrowserFileSystemAdapter` with its own name. */
	public final cacheFileSystem:IFileSystem = null;
}
