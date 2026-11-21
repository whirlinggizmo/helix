package helix.services.assets;

import haxe.io.Bytes;
import helix.log.Log;
import helix.platform.FilePath;
import helix.platform.GrowingSource;
import helix.platform.IPollable;
import helix.platform.StreamSource;

/** Provides files by path, from file systems on this machine and from HTTP servers whose files it keeps copies of, and writes files
	to the file systems that accept them.

	It asks its sources in order, and the first that has the path answers. A file missing from one source is looked for in the next: a
	read of a file the program hasn't written yet asks the server after the data directory, and the server answers that it has none.
	A game whose files never change lists its file system alone (`FileSystemSource`). A game that writes files of its own lists a
	writable file system over its data directory first, so a file it writes is the one it reads back. A game patched from a server lists
	the server first, with a `ManifestCache` provided the shipped files, and its shipped files after it. A shipped file that the server's
	manifest lists at the same hash is then read in place, and only what changed is downloaded. A page, whose files are on the server
	that served it, lists a `ServerSource` at "".

	A path is passed to each source unchanged: a name (`levels/1.json`), a relative path (`./a.png`, `../b.png`), an absolute directory
	path, or a URL. Each source reads it by its own root's rules and resolves it against that root (`AssetSource.resolve`). A source the
	path isn't under is passed over. A relative path is under every root it doesn't climb above, and an absolute path or a URL is under
	the roots it is under. A source follows a path's `.` and `..`: `levels/../custom/1.json` reads `custom/1.json`. A path one file
	names relative to itself is made with `join`. A path not under any asset source's root is refused with "Invalid file path: <path> is
	outside every asset source's root". The name a path resolves to under a root is the kind `IFileSystem` accepts (`FilePath`), from
	every source, so a name is refused alike on every target.

	A failure names the path as passed. A file not found in any asset source fails with "<path>: file not found in any of the asset
	sources". Each call answers once, on the main thread, in a later poll, never during the call. The failure callback is optional;
	when it is omitted, the failure is logged with the path.

	The program polls the assets once a frame, with the HTTP client and file systems it was provided. Downloads and copies finish in their
	polls, and what Assets answers with nothing of theirs to wait on (a file held in memory, a refused path) in its own. Assets that
	are never polled answer nothing.

	A file can change while the program runs, as a development server's do. Assets doesn't watch for it: whoever knows a file changed
	calls `notifyChanged` with its path or the URL it was served at, and each `watch` of that file receives the new bytes. A page's
	development build wires hotreload-hx in one line, `reloader.assetsChanged = urls -> for (url in urls) assets.notifyChanged(url);`.
	Natively nothing calls it, and there is no watcher.

	```haxe
	var httpClient:IHttp = new HaxeHttpAdapter();
	var shipped:IFileSystem = new NativeFileSystemAdapter({directory: system.getProgramDirectory(), readOnly: true});
	var data:IFileSystem = new NativeFileSystemAdapter({directory: system.getDataDirectory()});
	var downloads:IFileSystem = new NativeFileSystemAdapter({directory: system.getCacheDirectory()});

	// The shipped files alone, never checked:
	var assets = new Assets([new FileSystemSource(shipped)]);
	// The game's own files first, written there, then the shipped files:
	var assets = new Assets([new FileSystemSource(data, true), new FileSystemSource(shipped)]);
	// The shipped files first, a server for what they don't have:
	var assets = new Assets([new FileSystemSource(shipped), new ServerSource("https://example.com/game/", httpClient, new RevalidateCache(downloads))]);
	// A server first, patching what shipped by its manifests:
	var patching = new ManifestCache(downloads, {shipped: [shipped]});
	var assets = new Assets([new ServerSource("https://example.com/game/", httpClient, patching), new FileSystemSource(shipped)]);
	// In a page, the game's own files in a database, then the files beside the page:
	var kept = new RevalidateCache(new BrowserFileSystemAdapter({name: system.getCacheDirectory()}));
	var own = new BrowserFileSystemAdapter({name: system.getDataDirectory()});
	var assets = new Assets([new FileSystemSource(own, true), new ServerSource("", new FetchApiHttpAdapter(), kept)]);

	assets.read("levels/1.json", bytes -> start(bytes));
	assets.write("progress.json", Bytes.ofString(progress));
	// each frame, with the platform's other polls:
	httpClient.poll();
	data.poll();
	downloads.poll();
	shipped.poll();
	assets.poll();
	``` */
class Assets implements IPollable {
	final sources:Array<AssetSource>;
	final requests:Array<AssetRequest> = [];
	// What answers at the next poll.
	final queue:Array<Void->Void> = [];
	// The functions watching each path, as passed, in the order added.
	final watches = new Map<String, Array<Bytes->Void>>();

	/** Creates the assets over their sources, asked in order.

		@param sources  The places files are found. A file missing from one source is looked for in the next. */
	public function new(sources:Array<AssetSource>) {
		this.sources = sources.copy();
	}

	/** Returns the path a file names relative to itself, as a link in a page does: the path joined to the directory of the file
		naming it. Its `.` and `..` are kept, for the sources to follow.

		`join("levels/1.json", "../custom/1.json")` returns `"levels/../custom/1.json"`, which reads `custom/1.json`.

		@param from  The path of the file naming the other, as passed to `read`.
		@param path  The path it names. An absolute path or a URL is returned as it is.
		@return  The path to pass to `read`. */
	public static function join(from:String, path:String):String {
		if (path.indexOf("://") >= 0 || StringTools.startsWith(path, "/") || StringTools.startsWith(path, "\\") || ~/^[A-Za-z]:[\/\\]/.match(path))
			return path;
		var slash = from.lastIndexOf("/");
		#if sys
		if (Sys.systemName() == "Windows")
			slash = Std.int(Math.max(slash, from.lastIndexOf("\\")));
		#end
		return slash < 0 ? path : from.substr(0, slash + 1) + path;
	}

	/** Reads a whole file.

		@param path  The file's path: a name, a relative or absolute directory path, or a URL.
		@param read  Receives the file's bytes.
		@param missing  Optional. Called when the file is not found in any asset source, or the path is invalid, and the reason is logged.
			When omitted, either is a failure.
		@param failed  Optional. Receives why the file can't be read: the last source asked failed, or, when `missing` is omitted, the file
			is not found in any asset source or the path is invalid.
		@return  The abort: nothing is called after it. */
	public function read(path:String, read:Bytes->Void, ?missing:Void->Void, ?failed:String->Void):Void->Void {
		var request = start(path, missing, failed);
		ask(request, (source, name, next) -> source.read(name, request, bytes -> request.answer(() -> read(bytes)), next, message -> {
			request.failure = message;
			next();
		}));
		return request.abort;
	}

	/** Writes a whole file, to the first source that resolves the path and is writable, and hands the bytes to each `watch` of it.

		A file written is read back from that source, unless a source before it has the path too.

		@param path  The file's path: a name, or a relative or absolute directory path.
		@param bytes  The file's bytes.
		@param written  Optional. Called once the file is written.
		@param failed  Optional. Receives why it wasn't: the path is not under any asset source's root, "<path>: not under any writable
			asset source's root", or the file system's failure.
		@return  The abort: nothing is called after it, though the write may still finish. */
	public function write(path:String, bytes:Bytes, ?written:Void->Void, ?failed:String->Void):Void->Void {
		var request = start(path, null, failed);
		request.reason = outside(path);
		for (source in sources) {
			var name = source.nameOf(path);
			if (name == null)
				continue;
			request.reason = '$path: not under any writable asset source\'s root';
			if (!source.writable)
				continue;
			source.write(name, bytes, () -> {
				changed(source, name, bytes);
				request.answer(() -> if (written != null) written());
			}, message -> {
				request.failure = message;
				request.fail();
			});
			return request.abort;
		}
		request.later(request.fail);
		return request.abort;
	}

	/** Lists a directory's files and subdirectories in every file system source that resolves it, as one sorted list.

		A server source's files aren't listed, since a server can't list a directory. Each server source that resolves the directory is
		logged at INFO: "<path>: files served from <url> aren't listed". Its cache's copies are listed by `listCache`.

		@param path  The directory's path: a name, a relative or absolute directory path, or "" for every root.
		@param listed  Receives the names, a subdirectory's ending in `/`, such as `["1.json", "bonus/"]`. A name in two sources is listed
			once. A directory not found in any file system source is listed as `[]`.
		@param failed  Optional. Receives why the directory can't be listed: the path is not under any asset source's root, or a file
			system's failure.
		@return  The abort: nothing is called after it. */
	public function list(path:String, listed:Array<String>->Void, ?failed:String->Void):Void->Void {
		var request = start(path, null, failed);
		var names = new Map<String, Bool>();
		gather(request, (source, name, found, failed) -> source.list(name, request, entries -> {
			for (entry in entries)
				names.set(entry, true);
			found();
		}, failed), true, () -> {
			var all = [for (name in names.keys()) name];
			all.sort(Reflect.compare);
			listed(all);
		});
		return request.abort;
	}

	/** Lists the files currently cached under a path.

		@param path  The directory's path: a name, a relative or absolute directory path, a URL, or "" for every root.
		@param listed  Receives the copies, sorted by path. Each has its path from its server source's root, the form `read` accepts
			(`levels/1.json` for `listCache("levels")`), and the URL it was downloaded from.
		@param failed  Optional. Receives why a cache can't be listed.
		@return  The abort: nothing is called after it. */
	public function listCache(path:String, listed:Array<{path:String, url:String}>->Void, ?failed:String->Void):Void->Void {
		var request = start(path, null, failed);
		var copies:Array<{path:String, url:String}> = [];
		gather(request, (source, name, found, failed) -> source.listCopies(name, request, paths -> {
			for (path in paths)
				copies.push({path: path, url: source.locationOf(path)});
			found();
		}, failed), false, () -> {
			copies.sort((a, b) -> Reflect.compare(a.path, b.path));
			listed(copies);
		});
		return request.abort;
	}

	/** Calls a function with a file's new bytes each time a change of it is brought in (`notifyChanged`) or written (`write`), until the
		returned function is called.

		Two paths are the same file when a source resolves them to the same location, so a change notified or written by one reaches a
		watch of the other: a watch of `levels/../custom/1.json` receives a change of `custom/1.json`, and the other way round.

		Nothing is read now: a path watched and never changed is never read by the watch.

		@param path  The file's path: a name, a relative or absolute directory path, or a URL.
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

		The file is asked of the sources in order, as `read` asks: a server's past the browser's HTTP cache (no-store) and past the copy
		its cache keeps, the new copy then kept in its place, so a later `read` gets it. A file that can't be brought in keeps the old
		copy, and no watch is called; the failure is logged with the path. Nothing is called during the call.

		A file a file system source has is read again from it, and a written file's watches already received it from `write`. A file no
		source has is logged with its path, and no watch receives anything.

		In a page at `https://example.com/game/` with a `ServerSource` at "", `notifyChanged("https://example.com/game/levels/2.json")`,
		`notifyChanged("/game/levels/2.json")` and `notifyChanged("levels/2.json")` each reach a watch of `levels/2.json`.

		@param path  The file's path: a name, a relative or absolute directory path, or a URL. A URL a development server reports is
			one: `reloader.assetsChanged = urls -> for (url in urls) assets.notifyChanged(url);`. */
	public function notifyChanged(path:String):Void {
		var request = start(path, () -> {}, null);
		ask(request, (source, name, next) -> source.refetch(name, request, bytes -> request.answer(() -> changed(source, name, bytes)), next, message -> {
			request.failure = message;
			next();
		}));
	}

	// Hands a file's new bytes to each watch of a path the source resolves to the same location.
	function changed(source:AssetSource, name:String, bytes:Bytes):Void {
		var location = source.locationOf(name);
		for (path => list in [for (path => list in watches) path => list])
			if (source.resolve(path) == location)
				for (watch in list.copy())
					if (list.indexOf(watch) >= 0)
						watch(bytes);
	}

	/** Finds a file to be played as it is read, without loading it whole, in the form `IAudio.openStream` accepts.

		A file system's file is located where it is. A server's file is its kept copy when there is one. Otherwise, natively, it plays as
		it downloads, and the copy is kept; in a page it is located once it is kept. A native download asks for the file's last 64 KiB
		first and then the rest, so the stream's length can be read before it has all arrived, as a browser's media element does. A
		server that doesn't accept range requests sends the whole file at the first request.

		@param path  The file's path: a name, a relative or absolute directory path, or a URL.
		@param located  Receives the source, and a release function to call once when the source is no longer read.
		@param failed  Optional. Receives why the file can't be found.
		@return  The abort: nothing is called after it. */
	public function locate(path:String, located:(source:StreamSource, release:Void->Void) -> Void, ?failed:String->Void):Void->Void {
		var request = start(path, null, failed);
		ask(request,
			(source, name, next) -> source.locate(name, request, (stream, release) -> request.answer(() -> located(stream, release)), next, message -> {
				request.failure = message;
				next();
			}));
		return request.abort;
	}

	/** Empties each server source's cache, so its files are downloaded again.

		@param cleared  Optional. Called once the caches are empty.
		@param failed  Optional. Receives why a cache can't be emptied. When omitted, the failure is logged. */
	public function clearCache(?cleared:Void->Void, ?failed:String->Void):Void
		each((source, done, fail) -> source.clearCache(done, fail), cleared, failed, 'the cache can\'t be emptied');

	/** Deletes every server source's kept copy of a file, and its record, so the next load downloads it.

		A file system source's file is left alone. A copy that isn't there is already deleted.
		@param path  The file's path: a name, a relative or absolute directory path, or a URL.
		@param deleted  Optional. Called once the copies are gone.
		@param failed  Optional. Receives why a copy can't be deleted. When omitted, the failure is logged with the path. */
	public function deleteCopy(path:String, ?deleted:Void->Void, ?failed:String->Void):Void
		each((source, done, fail) -> {
			var name = source.nameOf(path);
			var why = name == null ? null : FilePath.whyInvalid(name);
			if (name == null)
				done();
			else if (why != null)
				fail(why);
			else
				source.deleteCopy(name, done, fail);
		}, deleted, failed, '$path: its copy can\'t be deleted');

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

	/** Aborts every call in flight.

		Call it before disposing the HTTP client and file systems it was provided. */
	public function dispose():Void {
		for (request in requests.copy())
			request.abort();
	}

	/** Returns the last bytes of a stream downloading in two parts (`locate`), until its source is released.

		@param source  The download, as `locate` passed it.
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

	function start(path:String, missing:Null<Void->Void>, failed:Null<String->Void>):AssetRequest {
		var request = new AssetRequest(path, missing, failed, requests, queue);
		requests.push(request);
		return request;
	}

	// Asks each source the request's path is under, in order, until one answers: one receives the source, the path's name under its root,
	// and the function that asks the next. A name the file systems refuse is passed over, and is why the file is missing. Past the last
	// source, the request fails, or is missing.
	function ask(request:AssetRequest, one:(source:AssetSource, name:String, next:Void->Void) -> Void):Void {
		var under = [];
		for (source in sources) {
			var name = source.nameOf(request.path);
			if (name != null)
				under.push({source: source, name: name});
		}
		if (under.length == 0) {
			request.reason = outside(request.path);
			request.later(request.fail);
			return;
		}
		function from(i:Int):Void {
			if (i == under.length) {
				request.fail();
				return;
			}
			var why = FilePath.whyInvalid(under[i].name);
			if (why != null) {
				request.reason = '${request.path}: $why';
				request.later(() -> from(i + 1));
			} else
				one(under[i].source, under[i].name, () -> from(i + 1));
		} from(0);
	}

	// Asks every source the request's path is under, then answers at a poll once each has: the first failure, or done. A path not under
	// any source's root fails when outsideFails, and is done otherwise.
	function gather(request:AssetRequest, one:(source:AssetSource, name:String, found:Void->Void, failed:String->Void) -> Void, outsideFails:Bool,
			done:Void->Void):Void {
		var left = 1, any = false;
		function answered()
			if (--left == 0)
				request.later(() -> if (request.failure != null) request.fail() else request.answer(done));
		for (source in sources) {
			var name = source.nameOf(request.path);
			if (name == null)
				continue;
			any = true;
			left++;
			one(source, name, answered, message -> {
				if (request.failure == null)
					request.failure = message;
				answered();
			});
		}
		if (!any && outsideFails) {
			request.reason = outside(request.path);
			request.later(request.fail);
			return;
		}
		answered();
	}

	static function outside(path:String):String
		return 'Invalid file path: $path is outside every asset source\'s root';
}
