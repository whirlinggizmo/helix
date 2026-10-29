package helix.services.assets;

import helix.platform.IFileSystem;
import helix.platform.IHttp;

/** Specifies where `Assets` finds files, and, for an HTTP server source, what downloads them and where copies are kept. */
@:structInit
class AssetsOptions {
	/** Gets the places files are found, asked in order. A file missing from one source is looked for in the next. */
	public final sources:Array<AssetSource>;

	/** Gets the HTTP client that `HttpServer` sources download with. Defaults to null, and must be provided when there is an `HttpServer`
		source. */
	public final httpClient:IHttp = null;

	/** Gets the file system that `HttpServer` sources keep their copies in. Defaults to null, and must be provided when there is an
		`HttpServer` source.

		It must be a file system used for nothing else, because `clearCache` empties it. Make it over `ISystem.getCacheDirectory`: a
		`NativeFileSystemAdapter` natively, and a `BrowserFileSystemAdapter` in a page. */
	public final cacheFileSystem:IFileSystem = null;

	/** Gets the file name of each directory's manifest, which a `Manifest` source reads. Defaults to "manifest.json".

		It matches the name `AssetManifests` writes. */
	public final manifestName:String = "manifest.json";
}
