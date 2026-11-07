package helix.services.assets;

import haxe.io.Bytes;
import helix.log.Log;
import helix.platform.GrowingSource;
import helix.platform.IPollable;
import helix.platform.StreamSource;

/** Provides files by path, from a file system on this machine or from an HTTP server whose files it keeps copies of.

	It asks its sources in order, and the first that has the path answers. A file missing from one source is looked for in the next.
	A game whose files never change lists its file system alone (`FileSystemSource`). A game patched from a server lists the server first,
	with a `ManifestCache` given the shipped files, and its shipped files after it. A shipped file that the server's manifest lists at the
	same hash is then read in place, and only what changed is downloaded. A page, whose files are on the server that served it, lists a
	`ServerSource` at "".

	A path is plain names joined by `/`, as in `IFileSystem` (`FilePath`), from every source: a server is never asked for one the file
	systems would refuse, so a name fails alike on every target. Each call answers once, on the main thread, in a later poll,
	never during the call. The failure callback is optional; when it is omitted, the failure is logged with the path.

	The program polls the assets once a frame, with the HTTP client and file systems it was given. Downloads and copies finish in their
	polls, and what Assets answers with nothing of theirs to wait on (a file held in memory, a refused path) in its own. Assets that
	are never polled answer nothing.

	A file can change while the program runs, as a development server's do. Assets doesn't watch for it: whoever knows a file changed
	calls `notifyChanged` with its path, or `notifyUrlChanged` with the URL it was served at, and each `watch` of that path receives the
	new bytes. A page's development build wires hotreload-hx in one line, `reloader.assetsChanged = urls -> for (url in urls)
	assets.notifyUrlChanged(url);`. Natively nothing calls it, and there is no watcher.

	```haxe
	var httpClient:IHttp = new HaxeHttpAdapter();
	var shipped:IFileSystem = new NativeFileSystemAdapter({directory: system.getProgramDirectory(), readOnly: true});
	var downloads:IFileSystem = new NativeFileSystemAdapter({directory: system.getCacheDirectory()});

	// The shipped files alone, never checked:
	var assets = new Assets([new FileSystemSource(shipped)]);
	// The shipped files first, a server for what they don't have:
	var assets = new Assets([new FileSystemSource(shipped), new ServerSource("https://example.com/game/", httpClient, new RevalidateCache(downloads))]);
	// A server first, patching what shipped by its manifests:
	var patching = new ManifestCache(downloads, {shipped: [shipped]});
	var assets = new Assets([new ServerSource("https://example.com/game/", httpClient, patching), new FileSystemSource(shipped)]);
	// In a page, the files beside the page:
	var kept = new RevalidateCache(new BrowserFileSystemAdapter({name: system.getCacheDirectory()}));
	var assets = new Assets([new ServerSource("", new FetchApiHttpAdapter(), kept)]);

	assets.load("levels/1.json", bytes -> start(bytes));
	// each frame, with the platform's other polls:
	httpClient.poll();
	downloads.poll();
	shipped.poll();
	assets.poll();
	``` */
class Assets implements IPollable {
	final sources:Array<AssetSource>;
	final requests:Array<AssetRequest> = [];
	// What answers at the next poll.
	final queue:Array<Void->Void> = [];
	// The functions watching each path, in the order added.
	final watches = new Map<String, Array<Bytes->Void>>();

	/** Creates the assets over their sources, asked in order.

		@param sources  The places files are found. A file missing from one source is looked for in the next. */
	public function new(sources:Array<AssetSource>) {
		this.sources = sources.copy();
	}

	/** Loads a whole file.

		@param path  The file's path.
		@param loaded  Receives the file's bytes.
		@param failed  Optional. Receives why the file can't be loaded, because no source has it or the last source asked failed.
		@return  The abort: nothing is called after it. */
	public function load(path:String, loaded:Bytes->Void, ?failed:String->Void):Void->Void {
		var request = start(path, failed);
		function from(i:Int):Void {
			if (i == sources.length) {
				// Every source answers later, so only a call with no sources waits for a poll to fail.
				if (i == 0)
					request.later(request.fail)
				else
					request.fail();
				return;
			}
			sources[i].load(path, request, bytes -> request.answer(() -> loaded(bytes)), () -> from(i + 1), message -> {
				request.failure = message;
				from(i + 1);
			});
		} from(0);
		return request.abort;
	}

	/** Calls a function with a file's new bytes each time a change of it is brought in (`notifyChanged`), until the returned function is
		called.

		Nothing is read now: a path watched and never changed is never read by the watch.
		@param path  The file's path.
		@param changed  Receives the file's bytes, each time a change brings a new copy.
		@return  A function that stops the watch; nothing is called after it. */
	public function watch(path:String, changed:Bytes->Void):Void->Void {
		var list = watches.get(path);
		if (list == null)
			watches.set(path, list = []);
		// A watch of its own, so the same function watching twice is stopped once a stop.
		var own = bytes -> changed(bytes);
		list.push(own);
		return () -> {
			list.remove(own);
			if (list.length == 0 && watches.get(path) == list)
				watches.remove(path);
		};
	}

	/** Brings a file in again because it changed, past every cache, and hands the new bytes to each `watch` of it.

		The file is asked of the sources in order, as `load` asks: a server's past the browser's HTTP cache (no-store) and past the copy
		its cache keeps, the new copy then kept in its place, so a later `load` gets it. A file that can't be brought in keeps the old copy,
		and no watch is called; the failure is logged with the path. Nothing is called during the call.
		@param path  The file's path. */
	public function notifyChanged(path:String):Void {
		var request = start(path, null);
		function from(i:Int):Void {
			if (i == sources.length) {
				// Every source answers later, so only a call with no sources waits for a poll to fail.
				if (i == 0)
					request.later(request.fail)
				else
					request.fail();
				return;
			}
			sources[i].refetch(path, request, bytes -> request.answer(() -> changed(path, bytes)), () -> from(i + 1), message -> {
				request.failure = message;
				from(i + 1);
			});
		} from(0);
	}

	/** Brings a file in again because the URL it is served at changed, as `notifyChanged` does for its path.

		The URL is matched against each `ServerSource`'s, resolved against the page's location in a page (a source `"assets/"` on a page
		at `http://localhost:8080/` serves `/assets/shaders/glow.shader` as `shaders/glow.shader`); a URL no source serves is skipped.
		@param url  The URL, absolute or from the server's root, as a development server reports it. */
	public function notifyUrlChanged(url:String):Void {
		for (source in sources) {
			var path = source.pathOf(url);
			if (path != null) {
				notifyChanged(path);
				return;
			}
		}
	}

	// Hands a file's new bytes to each of its watches.
	function changed(path:String, bytes:Bytes):Void {
		var list = watches.get(path);
		if (list != null)
			for (watch in list.copy())
				if (list.indexOf(watch) >= 0)
					watch(bytes);
	}

	/** Finds a file to be played as it is read, without loading it whole, in the form `IAudio.openStream` takes.

		A file system's file is located where it is. A server's file is its kept copy when there is one. Otherwise, natively, it plays as
		it downloads, and the copy is kept; in a page it is located once it is kept. A native download asks for the file's last 64 KiB
		first and then the rest, so the stream's length can be read before it has all arrived, as a browser's media element does. A
		server that doesn't take range requests sends the whole file at the first request.

		@param path  The file's path.
		@param located  Receives the source, and a release function to call once when the source is no longer read.
		@param failed  Optional. Receives why the file can't be found.
		@return  The abort: nothing is called after it. */
	public function locate(path:String, located:(source:StreamSource, release:Void->Void) -> Void, ?failed:String->Void):Void->Void {
		var request = start(path, failed);
		function from(i:Int):Void {
			if (i == sources.length) {
				// Every source answers later, so only a call with no sources waits for a poll to fail.
				if (i == 0)
					request.later(request.fail)
				else
					request.fail();
				return;
			}
			sources[i].locate(path, request, (source, release) -> request.answer(() -> located(source, release)), () -> from(i + 1), message -> {
				request.failure = message;
				from(i + 1);
			});
		} from(0);
		return request.abort;
	}

	/** Empties each server source's cache, so its files are downloaded again.

		@param cleared  Optional. Called once the caches are empty.
		@param failed  Optional. Receives why a cache can't be emptied. When omitted, the failure is logged. */
	public function clearCache(?cleared:Void->Void, ?failed:String->Void):Void
		each((source, done, fail) -> source.clearCache(done, fail), cleared, failed, 'the cache can\'t be emptied');

	/** Deletes every server source's kept copy of a file, and its record, so the next load downloads it.

		A file system source's file is left alone. A copy that isn't there is already deleted.
		@param path  The file's path.
		@param deleted  Optional. Called once the copies are gone.
		@param failed  Optional. Receives why a copy can't be deleted. When omitted, the failure is logged with the path. */
	public function deleteCopy(path:String, ?deleted:Void->Void, ?failed:String->Void):Void
		each((source, done, fail) -> source.deleteCopy(path, done, fail), deleted, failed, '$path: its copy can\'t be deleted');

	// Asks every source, then answers at a poll once each has: the first failure, or done.
	function each(ask:(AssetSource, Void->Void, String->Void) -> Void, done:Null<Void->Void>, failed:Null<String->Void>, what:String):Void {
		var left = sources.length + 1, failure:Null<String> = null;
		function one()
			if (--left == 0)
				queue.push(() -> if (failure == null) {
					if (done != null)
						done();
				} else if (failed != null) failed(failure); else Log.warn('$what: $failure', "assets"));
		for (source in sources)
			ask(source, one, message -> {
				if (failure == null)
					failure = message;
				one();
			});
		one();
	}

	/** Answers what finished with nothing of the platform's to wait on: a file held in memory, a refused path, a clearCache or deleteCopy.

		The program calls it once a frame, with the HTTP client's and file systems' polls. */
	public function poll():Void {
		var due = queue.splice(0, queue.length);
		for (f in due)
			f();
	}

	/** Aborts every load and locate in flight.

		Call it before disposing the HTTP client and file systems it was given. */
	public function dispose():Void {
		for (request in requests.copy())
			request.abort();
	}

	/** Returns the last bytes of a stream downloading in two parts (`locate`), until its source is released.

		@param source  The download, as `locate` gave it.
		@return  Its last 64 KiB or fewer, or null when it was downloaded whole from its start. */
	@:noCompletion
	@:allow(helix.services.audio)
	function tailOf(source:GrowingSource):Null<Bytes> {
		for (s in sources) {
			var tail = s.tailOf(source);
			if (tail != null)
				return tail;
		}
		return null;
	}

	function start(path:String, failed:Null<String->Void>):AssetRequest {
		var request = new AssetRequest(path, failed, requests, queue);
		requests.push(request);
		return request;
	}
}
