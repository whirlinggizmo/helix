package helix.assets;

import haxe.io.Bytes;

/** One directory's asset manifest (tools/gen_manifest.py writes them): the hash of each file in it, and of each subdirectory's own manifest,
	so an unchanged directory is known unchanged from its parent alone, as git knows a tree. The JSON is
	`{"manifest": 1, "files": {"name": "sha256:<64 hex>"}, "dirs": {"name": "sha256:<64 hex>"}}`; other top-level keys are ignored. */
class AssetManifest {
	/** The hash of each file, by name. */
	public final files:Map<String, String>;

	/** The hash of each subdirectory's manifest, by name. */
	public final dirs:Map<String, String>;

	function new(files:Map<String, String>, dirs:Map<String, String>) {
		this.files = files;
		this.dirs = dirs;
	}

	/** The manifest in bytes, or null for anything that isn't one exactly: not JSON, another version, a hash that isn't "sha256:" and 64
		lower-case hex digits, or a name that is empty, "." or "..", or holds a "/". A manifest wrong anywhere is trusted nowhere. */
	public static function parse(bytes:Bytes):Null<AssetManifest> {
		var value:Dynamic = try haxe.Json.parse(bytes.toString()) catch (_:Dynamic) null;
		if (value == null || Reflect.field(value, "manifest") != 1)
			return null;
		var files = entries(Reflect.field(value, "files")),
			dirs = entries(Reflect.field(value, "dirs"));
		return files == null || dirs == null ? null : new AssetManifest(files, dirs);
	}

	// An object of names and hashes, or null when it isn't one.
	static function entries(value:Dynamic):Null<Map<String, String>> {
		if (value == null || !Reflect.isObject(value) || Std.isOfType(value, Array))
			return null;
		var out:Map<String, String> = [];
		for (name in Reflect.fields(value)) {
			var hash:Dynamic = Reflect.field(value, name);
			if (!Std.isOfType(hash, String) || !isHash(hash) || name.indexOf("/") >= 0 || !AssetPath.isValid(name))
				return null;
			out[name] = hash;
		}
		return out;
	}

	/** Whether value is a hash as manifests write them: "sha256:" and 64 lower-case hex digits. */
	public static function isHash(value:String):Bool
		return ~/^sha256:[0-9a-f]{64}$/.match(value);

	/** bytes' hash as manifests write it. */
	public static function hash(bytes:Bytes):String
		return "sha256:" + haxe.crypto.Sha256.make(bytes).toHex();
}

/** What the cache keeps beside a downloaded file: the response's validators (its ETag and Last-Modified), until when the copy is fresh
	(seconds since 1970, from Cache-Control: max-age, or a year for immutable; no time at all otherwise), and the hash of the bytes kept. */
typedef CacheRecord = {
	@:optional final etag:String;
	@:optional final lastModified:String;
	final freshUntil:Float;
	final hash:String;
}

/** Reading and writing CacheRecords. */
class CacheRecords {
	/** The record in bytes, or null when they aren't one (or are from before records were kept). */
	public static function parse(bytes:Bytes):Null<CacheRecord> {
		var value:Dynamic = try haxe.Json.parse(bytes.toString()) catch (_:Dynamic) null;
		if (value == null || !Std.isOfType(value.hash, String) || !Std.isOfType(value.freshUntil, Float))
			return null;
		return {
			etag: Std.isOfType(value.etag, String) ? value.etag : null,
			lastModified: Std.isOfType(value.lastModified, String) ? value.lastModified : null,
			freshUntil: value.freshUntil,
			hash: value.hash
		};
	}

	/** The record for a response's headers (lower-case names) at now (seconds since 1970), for bytes of hash. */
	public static function of(headers:Map<String, String>, hash:String, now:Float):CacheRecord
		return {
			etag: headers["etag"],
			lastModified: headers["last-modified"],
			freshUntil: now + freshSeconds(headers["cache-control"]),
			hash: hash
		};

	/** How long a response stays fresh by its Cache-Control, in seconds: its max-age, a year for immutable without one, none when it says
		no-store or no-cache, or says nothing. */
	public static function freshSeconds(control:Null<String>):Float {
		if (control == null)
			return 0;
		var seconds = 0., immutable = false;
		for (part in control.toLowerCase().split(",")) {
			var directive = StringTools.trim(part);
			if (directive == "no-store" || directive == "no-cache")
				return 0;
			if (directive == "immutable")
				immutable = true;
			else if (StringTools.startsWith(directive, "max-age=")) {
				var value = Std.parseFloat(directive.substr(8));
				if (Math.isFinite(value) && value > 0)
					seconds = value;
			}
		}
		return seconds > 0 ? seconds : immutable ? 365 * 24 * 3600 : 0;
	}

	/** The record as bytes to keep. */
	public static function encode(record:CacheRecord):Bytes
		return Bytes.ofString(haxe.Json.stringify(record));
}
