package helix.services.assets;

import haxe.exceptions.NotImplementedException;
import haxe.io.Bytes;
import helix.platform.StreamSource;

/** Provides files by path, from the places its sources name: a file system on this machine, or an HTTP server whose files it keeps
	copies of.

	It asks its sources in order, and the first that has the path answers: a file missing from one is looked for in the next. A game
	that ships its files lists the file system first and a server after it for the rest; a page, whose files are on the server that
	served it, lists `HttpServer("")`. A path is plain names joined by `/`, as `IFileSystem`'s. Each call answers once, on the main
	thread, in the platform's `poll` that finished it, never during the call; the failure's lambda may be left out, and the failure is
	then logged with the path. Its downloads and copies finish in the polls of the HTTP client and file systems it was given, which
	the program polls each frame; Assets has no `poll` of its own.

	```haxe
	#if js
	var httpClient:IHttp = new FetchApiHttpAdapter();
	var downloads:IFileSystem = new BrowserFileSystemAdapter({name: "cache"});
	var assets = new Assets({sources: [HttpServer("")], httpClient: httpClient, cacheFileSystem: downloads});
	#else
	var httpClient:IHttp = new HaxeHttpAdapter();
	var shipped:IFileSystem = new NativeFileSystemAdapter({directory: system.getProgramDirectory(), readOnly: true});
	var downloads:IFileSystem = new NativeFileSystemAdapter({directory: system.getCacheDirectory("Company", "Game")});
	var assets = new Assets({
		sources: [FileSystem(shipped), HttpServer("https://example.com/game/", Trust)],
		httpClient: httpClient,
		cacheFileSystem: downloads,
	});
	#end
	assets.load("levels/1.json", bytes -> start(bytes));
	// each frame, with the platform's other polls:
	httpClient.poll();
	downloads.poll();
	``` */
class Assets {
	/** Creates the assets over their sources.

		@param options  The sources, and the HTTP client and file system an `HttpServer` source needs.
		@throws String  When a source is an `HttpServer` and `httpClient` or `cacheFileSystem` is null. */
	public function new(options:AssetsOptions) {
		throw new NotImplementedException();
	}

	/** Loads a whole file.

		@param path  The file's path.
		@param loaded  Receives its bytes.
		@param failed  Optional. Receives why it can't be had: no source has it, or the last one asked failed.
		@return  The abort: nothing is called after it. */
	public function load(path:String, loaded:Bytes->Void, ?failed:String->Void):Void->Void {
		throw new NotImplementedException();
	}

	/** Finds a file for playing as it's read, without loading it whole, as `IAudio.openStream` takes it.

		A file system's file is located where it is; a server's file is its kept copy when there is one, and otherwise is played as it
		downloads while the copy is kept.
		@param path  The file's path.
		@param located  Receives the source, and the function that lets it go, called once when it's no longer read.
		@param failed  Optional. Receives why it can't be had.
		@return  The abort: nothing is called after it. */
	public function locate(path:String, located:(source:StreamSource, release:Void->Void) -> Void, ?failed:String->Void):Void->Void {
		throw new NotImplementedException();
	}

	/** Empties `cacheFileSystem`, so each server's file is downloaded again.

		@param cleared  Optional. Called once it's empty.
		@param failed  Optional. Receives why it can't be emptied. */
	public function clearCache(?cleared:Void->Void, ?failed:String->Void):Void {
		throw new NotImplementedException();
	}

	/** Aborts every load and locate in flight; before the HTTP client and file systems it was given are disposed. */
	public function dispose():Void {
		throw new NotImplementedException();
	}
}
