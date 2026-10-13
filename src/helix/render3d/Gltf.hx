package helix.render3d;

import haxe.io.Bytes;

/** A glTF 2.0 file as read: its JSON document and its binary buffer, from a GLB (the binary container: a JSON chunk and a BIN chunk), with
	the reading of its accessors. Only what a ModelFile needs is interpreted here; the document stays as parsed. Throws, saying why, for a file
	it can't read. */
class Gltf {
	static inline var JSON_CHUNK = 0x4E4F534A;
	static inline var BIN_CHUNK = 0x004E4942;

	/** The document: glTF's JSON, as parsed. */
	public var document(default, null):Dynamic;

	/** The binary chunk: the file's first buffer, or null for none. */
	public var binary(default, null):Null<Bytes>;

	function new(document:Dynamic, binary:Null<Bytes>) {
		this.document = document;
		this.binary = binary;
		var version:String = field(field(document, "asset"), "version");
		if (version == null || !StringTools.startsWith(version, "2."))
			throw 'glTF version $version is not 2.x';
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

	/** A field of a JSON object, or null. */
	public static function field(object:Dynamic, name:String):Dynamic
		return object == null ? null : Reflect.field(object, name);

	/** The array named name in the document, or an empty one. */
	public function list(name:String):Array<Dynamic> {
		var value:Dynamic = field(document, name);
		return value == null ? [] : value;
	}

	// The bytes of buffer view index: a slice of the binary chunk (a GLB's only buffer).
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
		if (buffer != 0 || binary == null)
			throw "Only a GLB's own buffer is read";
		var offset:Int = field(v, "byteOffset") == null ? 0 : field(v, "byteOffset");
		var length:Int = field(v, "byteLength");
		if (offset < 0 || length < 0 || offset + length > binary.length)
			throw 'Buffer view $index runs past its buffer';
		var stride:Int = field(v, "byteStride") == null ? 0 : field(v, "byteStride");
		return {
			bytes: binary,
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
