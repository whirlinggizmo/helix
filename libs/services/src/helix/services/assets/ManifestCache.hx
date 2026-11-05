package helix.services.assets;

import haxe.DynamicAccess;
import haxe.Json;
#if !js
import haxe.crypto.Sha256;
#end
import haxe.io.Bytes;
import helix.log.Log;
import helix.platform.IFileSystem;

/** Uses the server's manifests to tell whether a copy is current, so a run asks for the root manifest alone.

	A copy kept under the hash its manifest lists is used without asking. A shipped file that its own manifests list at that hash is
	read in place. Otherwise the file is downloaded and hashed once: bytes that don't have the listed hash are not kept, and the load
	fails. A file its directory's manifest leaves out is asked about, and a copy of a name a newer manifest no longer lists is removed
	when that manifest arrives. A server with no manifest is warned about once a run and treated as `RevalidateCache` treats it.

	The manifests are the ones `AssetManifests` writes. */
class ManifestCache extends AssetCache {
	final copies:KeptCopies;
	final manifestName:String;
	final shipped:Array<ShippedTree>;
	// Each directory's manifest this run, by the server's directory and the directory ("" the root, then "levels/"): null for none;
	// waiting while it's fetched.
	var manifests = new Map<String, Null<Manifest>>();
	var manifestsWaiting = new Map<String, Array<Null<Manifest>->Void>>();

	/** Creates the cache over a file system used for nothing else.

		@param fileSystem  Where copies are kept.
		@param options  Optional. The manifests' file name, and the shipped file systems whose manifests show a file is already here. */
	public function new(fileSystem:IFileSystem, ?options:ManifestCacheOptions) {
		super();
		if (options == null)
			options = {};
		copies = new KeptCopies(fileSystem);
		manifestName = options.manifestName;
		shipped = [for (files in options.shipped) new ShippedTree(files, manifestName)];
	}

	// By the manifest when it lists the path; always asking about a copy its directory's manifest leaves out, as changed or gone since it
	// was kept; as RevalidateCache decides when there's no manifest for its directory.
	function decide(server:ServerSource, path:String, request:AssetRequest, decided:CacheDecision->Void):Void
		listedLabel(server, path, request, (listed, leftOut) -> copies.readRecord(server, path, request, (record, there) -> {
			if (listed != null) {
				if (record != null && record.label == listed)
					decided(UseCopy(record));
				else
					// Not kept, or kept at another hash: a shipped file with the same hash is read in place.
					shippedWith(path, listed, 0, request, files -> decided(files != null ? UseShipped(files, listed) : Download(null, listed, there)));
			} else if (record == null)
				decided(Download(null, null, there));
			else if (!leftOut && Date.now().getTime() / 1000 < record.freshUntil)
				decided(UseCopy(record));
			else
				decided(Download(record, null, true));
		}));

	function readCopy(server:ServerSource, path:String, request:AssetRequest, record:CopyRecord, loaded:Bytes->Void, gone:Void->Void):Void
		copies.readCopy(server, path, request, record, loaded, gone);

	function locateCopy(server:ServerSource, path:String, request:AssetRequest, record:CopyRecord, located:(String, Void->Void) -> Void, gone:Void->Void,
			failed:String->Void):Void
		copies.locateCopy(server, path, request, record, located, gone, failed);

	// A directory's manifest arriving anew: the old copy read first, and once the new one is kept, the copies of the names it dropped
	// deleted.
	function keep(server:ServerSource, path:String, bytes:Bytes, record:CopyRecord, replacing:Bool, kept:Void->Void, failed:String->Void):Void {
		if (path != manifestName && !StringTools.endsWith(path, "/" + manifestName)) {
			copies.keep(server, path, bytes, record, replacing, kept, failed);
			return;
		}
		var level = path.substr(0, path.length - manifestName.length);
		function write(old:Null<Bytes>)
			copies.keep(server, path, bytes, record, replacing, () -> {
				if (old != null)
					prune(server, level, parse(old), parse(bytes));
				kept();
			}, failed);
		copies.fileSystem.read(KeptCopies.filePath(server, path), 1 << 26, old -> write(old), () -> write(null), _ -> write(null));
	}

	function renew(server:ServerSource, path:String, record:CopyRecord):Void
		copies.writeRecord(server, path, record);

	function forget(server:ServerSource, path:String, forgotten:Void->Void, failed:String->Void):Void
		copies.forget(server, path, forgotten, failed);

	function clearCopies(server:ServerSource, cleared:Void->Void, failed:String->Void):Void {
		manifests = new Map();
		copies.clearCopies(cleared, failed);
	}

	override function verify(bytes:Bytes, label:String, request:AssetRequest, verified:Bool->Void):Void
		digest(bytes, hex -> request.later(() -> verified("sha256:" + hex == label)));

	// The copies of the names an old manifest listed and a new one doesn't: files, and whole subdirectories.
	function prune(server:ServerSource, level:String, old:Null<Manifest>, now:Null<Manifest>):Void {
		if (old == null || now == null)
			return;
		for (name in old.files.keys())
			if (!now.files.exists(name))
				copies.forget(server, level + name, () -> {}, _ -> {});
		for (name in old.dirs.keys())
			if (!now.dirs.exists(name))
				copies.forgetUnder(server, level + name, () -> {});
	}

	// The shipped trees from the i-th on: the first whose manifests give path the hash; null for none.
	function shippedWith(path:String, hash:String, i:Int, request:AssetRequest, found:Null<IFileSystem>->Void):Void {
		if (i == shipped.length) {
			found(null);
			return;
		}
		var tree = shipped[i];
		tree.hashOf(path, listed -> {
			if (request.aborted)
				return;
			if (listed == hash)
				found(tree.fileSystem);
			else
				shippedWith(path, hash, i + 1, request, found);
		});
	}

	// The manifests' hash of path, walking down from the root's manifest one directory at a time, and whether its directory's manifest
	// leaves it out; null and false when there's no manifest for its directory.
	function listedLabel(server:ServerSource, path:String, request:AssetRequest, found:(Null<String>, Bool) -> Void):Void {
		var names = path.split("/");
		function walk(depth:Int, level:String, hash:Null<String>) {
			manifestOf(server, level, hash, request, manifest -> {
				if (request.aborted)
					return;
				if (manifest == null)
					found(null, false);
				else if (depth == names.length - 1)
					found(manifest.files.get(names[depth]), !manifest.files.exists(names[depth]));
				else {
					var next = manifest.dirs.get(names[depth]);
					if (next == null)
						found(null, false);
					else
						walk(depth + 1, level + names[depth] + "/", next);
				}
			});
		}
		walk(0, "", null);
	}

	// A directory's manifest, once a run, kept as any file is. The root's is asked about each run (its copy's validators sent, its copy
	// used offline); a subdirectory's copy is used while its parent lists the same hash, and otherwise downloaded past HTTP caches. Its
	// loads belong to no one request, so aborting one leaves them running.
	function manifestOf(server:ServerSource, level:String, hash:Null<String>, request:AssetRequest, got:Null<Manifest>->Void):Void {
		var key = server.directory + "/" + level;
		if (manifests.exists(key)) {
			got(manifests.get(key));
			return;
		}
		var waiting = manifestsWaiting.get(key);
		if (waiting != null) {
			waiting.push(got);
			return;
		}
		manifestsWaiting.set(key, [got]);
		function finish(bytes:Null<Bytes>) {
			var manifest = bytes == null ? null : parse(bytes);
			manifests.set(key, manifest);
			var waiting = manifestsWaiting.get(key);
			manifestsWaiting.remove(key);
			for (f in waiting)
				f(manifest);
		}
		var path = level + manifestName, own = request.detached(path);
		function fetch(record:Null<CopyRecord>, replacing:Bool)
			server.download(path, own, hash == null ? record : null, hash, replacing, false, (bytes, _) -> finish(bytes), () -> {
				if (hash == null)
					Log.warn('no manifest at ${server.url}$path: its files are treated as RevalidateCache treats them', "assets");
				finish(null);
			}, _ -> finish(null));
		copies.readRecord(server, path, own, (record, there) -> {
			if (hash != null && record != null && record.label == hash)
				copies.readCopy(server, path, own, record, bytes -> finish(bytes), () -> fetch(null, false));
			else
				fetch(record, there);
		});
	}

	/** Hashes bytes with SHA-256 and gives the 64 hex digits, as manifests write them after "sha256:": the browser's digest in a page,
		off the main thread and so not during this call; Node's where a page's build runs there (the tests); Haxe's natively, during
		the call. */
	static function digest(bytes:Bytes, done:String->Void):Void {
		#if js
		// The bytes alone: a buffer's storage can run past its length.
		var view = new js.lib.Uint8Array(bytes.getData(), 0, bytes.length);
		if (js.Syntax.code("typeof process !== 'undefined' && process.versions && process.versions.node")) {
			done(js.Syntax.code("require('crypto').createHash('sha256').update({0}).digest('hex')", view));
			return;
		}
		js.Syntax.code("globalThis.crypto.subtle.digest('SHA-256', {0})", view).then((hashed:js.lib.ArrayBuffer) -> {
			var digits = new StringBuf(), view = new js.lib.Uint8Array(hashed);
			for (i in 0...view.length)
				digits.add(StringTools.hex(view[i], 2).toLowerCase());
			done(digits.toString());
		});
		#else
		done(Sha256.make(bytes).toHex());
		#end
	}

	/** Returns one directory's manifest, or null for anything that isn't one.

		A manifest is `{"manifest": 1, "files": {"name": "sha256:<hex>"}, "dirs": {"name": "sha256:<hex>"}}`. A subdirectory's hash is the
		hash of its own manifest. */
	static function parse(bytes:Bytes):Null<Manifest> {
		var value:Dynamic = try Json.parse(bytes.toString()) catch (_:Dynamic) null;
		if (value == null || value.manifest != 1)
			return null;
		return {files: hashes(value.files), dirs: hashes(value.dirs)};
	}

	static function hashes(value:Dynamic):Map<String, String> {
		var out = new Map<String, String>();
		if (!isRecord(value))
			return out;
		var entries:DynamicAccess<Dynamic> = value;
		for (name => hash in entries)
			if (name.indexOf("/") < 0 && Std.isOfType(hash, String) && ~/^sha256:[0-9a-f]{64}$/.match(hash))
				out.set(name, hash);
		return out;
	}

	// Whether a parsed JSON value is an object: not null, a string, a bool, a number or an array. Without Type.typeof, which links the
	// run-time type inspection every program with the assets would carry.
	static function isRecord(value:Dynamic):Bool {
		return value != null && !Std.isOfType(value, String) && !Std.isOfType(value, Bool) && !Std.isOfType(value, Float) && !Std.isOfType(value, Array);
	}
}

/** Represents one directory's manifest.

	It holds the hash of each file in the directory, and of each subdirectory's manifest, by name. */
private typedef Manifest = {
	files:Map<String, String>,
	dirs:Map<String, String>
}

/** Represents a file system's manifests, as `AssetManifests` writes them beside a program's files.

	Each directory's manifest is read once a run, when first needed. It tells whether a file there is the one a server's manifest
	lists. */
private class ShippedTree {
	/** Gets the file system. */
	public final fileSystem:IFileSystem;

	final name:String;
	var manifests = new Map<String, Null<Manifest>>();
	var waiting = new Map<String, Array<Null<Manifest>->Void>>();

	/** Creates the tree over a file system whose manifests are named name. */
	public function new(fileSystem:IFileSystem, name:String) {
		this.fileSystem = fileSystem;
		this.name = name;
	}

	/** Finds the hash its manifests list for path, and passes it to found, or null when they list none. */
	public function hashOf(path:String, found:Null<String>->Void):Void {
		var names = path.split("/");
		function walk(depth:Int, level:String) {
			manifestOf(level, manifest -> {
				if (manifest == null)
					found(null);
				else if (depth == names.length - 1)
					found(manifest.files.get(names[depth]));
				else if (!manifest.dirs.exists(names[depth]))
					found(null);
				else
					walk(depth + 1, level + names[depth] + "/");
			});
		}
		walk(0, "");
	}

	function manifestOf(level:String, got:Null<Manifest>->Void):Void {
		if (manifests.exists(level)) {
			got(manifests.get(level));
			return;
		}
		var queue = waiting.get(level);
		if (queue != null) {
			queue.push(got);
			return;
		}
		waiting.set(level, [got]);
		function finish(manifest:Null<Manifest>) {
			manifests.set(level, manifest);
			var queue = waiting.get(level);
			waiting.remove(level);
			for (f in queue)
				f(manifest);
		}
		fileSystem.read(level + name, 1 << 26, bytes -> finish(@:privateAccess ManifestCache.parse(bytes)), () -> finish(null), _ -> finish(null));
	}
}
