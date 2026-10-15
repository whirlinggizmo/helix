package helix.render3d;

import haxe.io.Bytes;

/** A glTF 2.0 file as read: its JSON document and its buffers, from a GLB (the binary container: a JSON chunk and a BIN chunk, its first
	buffer) or a .gltf (the JSON alone), with the reading of its accessors. A buffer inside the file (the GLB's, or a base64 data: URI) is read
	here; one in a file of its own (a uri beside the model) is the loader's to fetch and set (getMissingBuffers, setBuffer). Only what a
	ModelFile needs is interpreted; the document stays as parsed. Throws, saying why, for a file it can't read. */
class Gltf {
	static inline var JSON_CHUNK = 0x4E4F534A;
	static inline var BIN_CHUNK = 0x004E4942;

	/** The document: glTF's JSON, as parsed. */
	public var document(default, null):Dynamic;

	var buffers:Array<Null<Bytes>> = [];

	function new(document:Dynamic, binary:Null<Bytes>) {
		this.document = document;
		var version:String = field(field(document, "asset"), "version");
		if (version == null || !StringTools.startsWith(version, "2."))
			throw 'glTF version $version is not 2.x';
		var list = this.list("buffers");
		for (i in 0...list.length) {
			var uri:String = field(list[i], "uri");
			// A GLB's first buffer has no uri: its BIN chunk.
			buffers.push(uri == null ? (i == 0 ? binary : null) : dataUri(uri));
			if (uri == null && (i != 0 || binary == null))
				throw 'Buffer $i has no uri and no BIN chunk';
		}
	}

	/** Reads a GLB, or a .gltf (its JSON, as UTF-8 bytes): by its first bytes. */
	public static function read(bytes:Bytes):Gltf {
		if (bytes.length >= 4 && bytes.getString(0, 4) == "glTF")
			return readGlb(bytes);
		var text = bytes.toString(), at = 0;
		while (at < text.length && StringTools.isSpace(text, at))
			at++;
		if (at >= text.length || text.charAt(at) != "{")
			throw "Neither a GLB nor a glTF (JSON) file";
		return new Gltf(haxe.Json.parse(text), null);
	}

	/** Reads a GLB file. */
	public static function readGlb(bytes:Bytes):Gltf {
		if (bytes.length < 20 || bytes.getString(0, 4) != "glTF")
			throw "Not a GLB file";
		if (bytes.getInt32(4) != 2)
			throw 'GLB version ${bytes.getInt32(4)} is not 2';
		var length = bytes.getInt32(8);
		if (length > bytes.length)
			throw "GLB file is cut short";
		var at = 12, json:Null<String> = null, binary:Null<Bytes> = null;
		while (at + 8 <= length) {
			var size = bytes.getInt32(at), type = bytes.getInt32(at + 4);
			if (size < 0 || at + 8 + size > length)
				throw "GLB chunk runs past the file";
			if (type == JSON_CHUNK && json == null)
				json = bytes.getString(at + 8, size);
			else if (type == BIN_CHUNK && binary == null)
				binary = bytes.sub(at + 8, size);
			at += 8 + size;
			at += (4 - at % 4) % 4;
		}
		if (json == null)
			throw "GLB file has no JSON chunk";
		return new Gltf(haxe.Json.parse(json), binary);
	}

	/** The bytes of a base64 data: URI, or null for any other uri (a file's). Throws for a data: URI that isn't base64. */
	public static function dataUri(uri:String):Null<Bytes> {
		if (!StringTools.startsWith(uri, "data:"))
			return null;
		var comma = uri.indexOf(",");
		if (comma < 0 || !StringTools.endsWith(uri.substring(0, comma), ";base64"))
			throw "A data: URI that isn't base64";
		return haxe.crypto.Base64.decode(uri.substr(comma + 1));
	}

	/** The asset path of uri (a file the model names, relative to it) beside the model at path: its %-escapes decoded and its "." and ".."
		segments followed. Null for one that isn't a relative path inside the assets (a URL, an absolute path, one climbing above them). */
	public static function resolve(path:String, uri:String):Null<String> {
		var decoded = try StringTools.urlDecode(uri) catch (e:Dynamic) return null;
		if (decoded.indexOf(":") >= 0 || StringTools.startsWith(decoded, "/"))
			return null;
		var parts = path.split("/");
		parts.pop();
		for (part in decoded.split("/")) {
			if (part == "" || part == ".")
				continue;
			if (part == "..") {
				if (parts.length == 0)
					return null;
				parts.pop();
			} else
				parts.push(part);
		}
		var joined = parts.join("/");
		return helix.assets.AssetPath.isValid(joined) ? joined : null;
	}

	/** The buffers that are files of their own, not read yet: each its index and uri. */
	public function getMissingBuffers():Array<{index:Int, uri:String}> {
		var list = this.list("buffers");
		return [
			for (i in 0...buffers.length)
				if (buffers[i] == null) {index: i, uri: field(list[i], "uri")}
		];
	}

	/** Buffer index's bytes, or null while it waits for its file (or for an index out of range). */
	public function getBuffer(index:Int):Null<Bytes>
		return index >= 0 && index < buffers.length ? buffers[index] : null;

	/** Sets buffer index to bytes, the file its uri names. False, changing nothing, for an index out of range or bytes shorter than its
		byteLength. */
	public function setBuffer(index:Int, bytes:Bytes):Bool {
		var all = list("buffers");
		if (index < 0 || index >= all.length)
			return false;
		var length:Null<Int> = field(all[index], "byteLength");
		if (length != null && bytes.length < length)
			return false;
		buffers[index] = bytes;
		return true;
	}

	/** A field of a JSON object, or null. */
	public static function field(object:Dynamic, name:String):Dynamic
		return object == null ? null : Reflect.field(object, name);

	/** The array named name in the document, or an empty one. */
	public function list(name:String):Array<Dynamic> {
		var value:Dynamic = field(document, name);
		return value == null ? [] : value;
	}

	// The bytes of buffer view index: a slice of its buffer.
	function view(index:Int):{
		bytes:Bytes,
		offset:Int,
		length:Int,
		stride:Int
	} {
		var views = list("bufferViews");
		if (index < 0 || index >= views.length)
			throw 'No buffer view $index';
		var v = views[index], buffer:Int = field(v, "buffer");
		if (buffer < 0 || buffer >= buffers.length || buffers[buffer] == null)
			throw 'Buffer $buffer isn\'t read';
		var bytes = buffers[buffer];
		var offset:Int = field(v, "byteOffset") == null ? 0 : field(v, "byteOffset");
		var length:Int = field(v, "byteLength");
		if (offset < 0 || length < 0 || offset + length > bytes.length)
			throw 'Buffer view $index runs past its buffer';
		var stride:Int = field(v, "byteStride") == null ? 0 : field(v, "byteStride");
		return {
			bytes: bytes,
			offset: offset,
			length: length,
			stride: stride
		};
	}

	/** The bytes of buffer view index, copied: an embedded image's file. */
	public function viewBytes(index:Int):Bytes {
		var v = view(index);
		return v.bytes.sub(v.offset, v.length);
	}

	static function components(type:String):Int
		return switch type {
			case "SCALAR": 1;
			case "VEC2": 2;
			case "VEC3": 3;
			case "VEC4": 4;
			case "MAT4": 16;
			case _: throw 'Unsupported accessor type $type';
		}

	/** Accessor index's values, every component of every element in order, as floats: normalized integers scaled to 0..1 (unsigned) or -1..1
		(signed), others as they are. Throws for a sparse accessor, an unknown type, or one running past its view. */
	public function floats(index:Int):Array<Float> {
		var accessors = list("accessors");
		if (index < 0 || index >= accessors.length)
			throw 'No accessor $index';
		var a = accessors[index];
		if (field(a, "sparse") != null)
			throw "Sparse accessors aren't read";
		var count:Int = field(a, "count"),
			type:Int = field(a, "componentType"),
			n = components(field(a, "type"));
		var normalized = field(a, "normalized") == true;
		var size = switch type {
			case 5120 | 5121: 1;
			case 5122 | 5123: 2;
			case 5125 | 5126: 4;
			case _: throw 'Unsupported component type $type';
		}
		var out = [];
		if (field(a, "bufferView") == null) {
			for (_ in 0...count * n)
				out.push(0.);
			return out;
		}
		var v = view(field(a, "bufferView"));
		var start = v.offset + (field(a, "byteOffset") == null ? 0 : field(a, "byteOffset")),
			stride = v.stride > 0 ? v.stride : size * n;
		// The last element needs only its own bytes, not a whole stride.
		if (count > 0 && start - v.offset + (count - 1) * stride + size * n > v.length)
			throw 'Accessor $index runs past its buffer view';
		var b = v.bytes;
		for (i in 0...count)
			for (c in 0...n) {
				var at = start + i * stride + c * size;
				out.push(switch type {
					case 5126: b.getFloat(at);
					case 5121: normalized ? b.get(at) / 255 : b.get(at);
					case 5120:
						var x = b.get(at);
						x = x > 127 ? x - 256 : x;
						normalized ? Math.max(x / 127, -1) : x;
					case 5123: normalized ? b.getUInt16(at) / 65535 : b.getUInt16(at);
					case 5122:
						var x = b.getUInt16(at);
						x = x > 32767 ? x - 65536 : x;
						normalized ? Math.max(x / 32767, -1) : x;
					case _: b.getInt32(at);
				});
			}
		return out;
	}

	/** Accessor index's values as integers: indices (unsigned 8, 16 or 32 bits). */
	public function ints(index:Int):Array<Int>
		return [for (x in floats(index)) Std.int(x)];
}
