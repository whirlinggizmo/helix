package helix.formats.gltf;

import haxe.io.Bytes;
import helix.math.Matrix3D;
import helix.math.Transform3D;

/** Represents a glTF 2.0 model read from a .gltf or GLB file: its nodes, its scene, its meshes, materials and images, as plain data.

	`read` takes the file's bytes and its path. A buffer held in the file (a GLB's BIN chunk, a base64 `data:` URI) is read then; one in a
	file of its own is listed in `missingBuffers`, its path resolved against the model's, for the caller to fetch and give to `setBuffer`.
	`nodes`, `scene` and `materials` are read with the file; `meshes` and `images` read the buffers when asked for, and throw while a
	buffer they need is missing.

	Accessors of every component type are read, normalized integers scaled to 0..1 or -1..1; one with no buffer view is zeros, and a
	sparse accessor throws. Positions and normals are in each mesh's own units: no node's transform is applied. Skins and animations are
	read as the file has them, as `meshes` are; morph targets, cameras, texture samplers and extensions are not read yet.

	```haxe
	var model = GltfFile.read(bytes, "models/ship.gltf");
	for (missing in model.missingBuffers) model.setBuffer(missing.index, fetched(missing.path));
	var positions = model.meshes[0].primitives[0].positions;
	``` */
class GltfFile {
	static inline var JSON_CHUNK = 0x4E4F534A;
	static inline var BIN_CHUNK = 0x004E4942;

	/** Gets the model's nodes, in the file's order: nodes name each other, and `scene` names its roots, by their index here. */
	public final nodes:Array<GltfNode>;

	/** Gets the indices in `nodes` of the default scene's roots: the file's `scene`, or its first scene; with no scenes, every node that
		is no node's child. */
	public final scene:Array<Int>;

	/** Gets the model's materials, in the file's order: a primitive names its own by its index here. */
	public final materials:Array<GltfMaterial>;

	/** Gets the model's meshes, in the file's order, read from the buffers when first asked for.

		@throws String  A buffer a mesh needs is missing (`missingBuffers`, which the message names), or an accessor can't be read. */
	public var meshes(get, never):Array<GltfMesh>;

	/** Gets the model's skins, in the file's order: a node names its own by its index here. Read from the buffers when first asked for.

		@throws String  A buffer a skin's inverse bind matrices need is missing, or an accessor can't be read. */
	public var skins(get, never):Array<GltfSkin>;

	/** Gets the model's animations, in the file's order, read from the buffers when first asked for.

		@throws String  A buffer a sampler needs is missing, or an accessor can't be read. */
	public var animations(get, never):Array<GltfAnimation>;

	/** Gets the model's images, in the file's order, those held in a buffer read from it when first asked for.

		@throws String  A buffer an image needs is missing (`missingBuffers`, which the message names). */
	public var images(get, never):Array<GltfImage>;

	/** Gets the buffers in files of their own that are still missing, each its index and its file's path: URI-decoded and resolved
		against the model's directory. Empty when every buffer is read. */
	public var missingBuffers(get, never):Array<{index:Int, path:String}>;

	final document:Dynamic;
	final directory:String;
	final buffers:Array<Null<Bytes>> = [];
	var readMeshes:Null<Array<GltfMesh>>;
	var readImages:Null<Array<GltfImage>>;
	var readSkins:Null<Array<GltfSkin>>;
	var readAnimations:Null<Array<GltfAnimation>>;

	/** Reads a glTF 2.0 model: a .gltf (its JSON, as UTF-8) or a GLB, told apart by its first bytes.

		Buffers held in the file are read now; those in files of their own are listed in `missingBuffers`.

		@param bytes  The file's bytes.
		@param path  The file's path, against whose directory the paths of its buffers and images are resolved.
		@return  The model.
		@throws String  It is neither a glTF 2.0 file nor a GLB, or its JSON or a chunk is broken. */
	public static function read(bytes:Bytes, path:String):GltfFile {
		if (bytes.length >= 4 && bytes.getString(0, 4) == "glTF")
			return readGlb(bytes, path);
		var text = bytes.toString(), at = 0;
		while (at < text.length && StringTools.isSpace(text, at))
			at++;
		if (at >= text.length || text.charAt(at) != "{")
			throw "Neither a GLB nor a glTF (JSON) file";
		return new GltfFile(parse(text), null, path);
	}

	/** Sets a buffer in a file of its own to that file's bytes, so the meshes and images that need it can be read.

		@param index  The buffer's index, as `missingBuffers` gives it.
		@param bytes  The buffer's file.
		@throws String  The index is out of range, or the bytes are fewer than the buffer's `byteLength`. */
	public function setBuffer(index:Int, bytes:Bytes):Void {
		var all = list(document, "buffers");
		if (index < 0 || index >= all.length)
			throw 'No buffer $index';
		var length:Null<Int> = field(all[index], "byteLength");
		if (length != null && bytes.length < length)
			throw 'Buffer $index is $length bytes, but ${bytes.length} were given';
		buffers[index] = bytes;
		readMeshes = null;
		readImages = null;
		readSkins = null;
		readAnimations = null;
	}

	function new(document:Dynamic, binary:Null<Bytes>, path:String) {
		this.document = document;
		directory = haxe.io.Path.directory(path);
		var version:String = field(field(document, "asset"), "version");
		if (version == null || !StringTools.startsWith(version, "2."))
			throw 'glTF version $version is not 2.x';
		var declared = list(document, "buffers");
		for (i in 0...declared.length) {
			var uri:String = field(declared[i], "uri");
			// A GLB's first buffer has no uri: its BIN chunk.
			buffers.push(uri == null ? (i == 0 ? binary : null) : dataUri(uri));
			if (uri == null && (i != 0 || binary == null))
				throw 'Buffer $i has no uri and no BIN chunk';
		}
		var textures = list(document, "textures");
		// A texture's image: its source, or -1 for none.
		function image(info:Dynamic):Int {
			if (info == null)
				return -1;
			var index:Null<Int> = field(info, "index");
			if (index == null || index < 0 || index >= textures.length)
				return -1;
			var source:Null<Int> = field(textures[index], "source");
			return source == null ? -1 : source;
		}
		materials = [
			for (m in list(document, "materials")) {
				var pbr = field(m, "pbrMetallicRoughness");
				new GltfMaterial(text(m, "name"), pbr != null, numbers(field(pbr, "baseColorFactor"), [1, 1, 1, 1]), image(field(pbr, "baseColorTexture")),
					number(pbr, "metallicFactor", 1), number(pbr, "roughnessFactor", 1), image(field(pbr, "metallicRoughnessTexture")),
					image(field(m, "normalTexture")), image(field(m, "occlusionTexture")), numbers(field(m, "emissiveFactor"), [0, 0, 0]),
					image(field(m, "emissiveTexture")));
			}
		];
		nodes = [
			for (n in list(document, "nodes")) {
				var mesh:Null<Int> = field(n, "mesh");
				var skin:Null<Int> = field(n, "skin");
				var transform = local(n);
				new GltfNode(text(n, "name"), mesh == null ? -1 : mesh, integers(field(n, "children")), transform, parts(n, transform),
					skin == null ? -1 : skin);
			}
		];
		var scenes = list(document, "scenes");
		var sceneIndex:Null<Int> = field(document, "scene");
		var roots:Null<Array<Int>> = scenes.length > 0 ? optionalIntegers(field(scenes[sceneIndex == null ? 0 : sceneIndex], "nodes")) : null;
		if (roots == null) {
			var children = new Map<Int, Bool>();
			for (node in nodes)
				for (i in node.children)
					children.set(i, true);
			roots = [for (i in 0...nodes.length) if (!children.exists(i)) i];
		}
		scene = roots;
	}

	// Reads a GLB file: its JSON chunk, and its BIN chunk as the first buffer.
	static function readGlb(bytes:Bytes, path:String):GltfFile {
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
		return new GltfFile(parse(json), binary, path);
	}

	// The JSON parsed, its failure a String.
	static function parse(text:String):Dynamic {
		return try haxe.Json.parse(text) catch (e:Dynamic) throw 'The glTF JSON is broken: $e';
	}

	// The bytes of a base64 data: URI, or null for any other uri (a file's). Throws for a data: URI that isn't base64.
	static function dataUri(uri:String):Null<Bytes> {
		if (!StringTools.startsWith(uri, "data:"))
			return null;
		var comma = uri.indexOf(",");
		if (comma < 0 || !StringTools.endsWith(uri.substring(0, comma), ";base64"))
			throw "A data: URI that isn't base64";
		return haxe.crypto.Base64.decode(uri.substr(comma + 1));
	}

	// A file's uri as a path: percent-decoded (a + is itself, not a space, in a URI's path), resolved against the model's directory.
	function resolve(uri:String):String {
		var decoded = try StringTools.urlDecode(StringTools.replace(uri, "+", "%2B")) catch (e:Dynamic) throw 'A uri that isn\'t percent-encoded: $uri';
		return directory == "" ? decoded : directory + "/" + decoded;
	}

	function get_missingBuffers():Array<{index:Int, path:String}> {
		var declared = list(document, "buffers");
		return [
			for (i in 0...buffers.length)
				if (buffers[i] == null) {index: i, path: resolve(field(declared[i], "uri"))}
		];
	}

	function get_meshes():Array<GltfMesh> {
		if (readMeshes == null)
			readMeshes = [
				for (m in list(document, "meshes"))
					new GltfMesh(text(m, "name"), [for (p in (list(m, "primitives") : Array<Dynamic>)) primitive(p)])
			];
		return readMeshes;
	}

	function get_skins():Array<GltfSkin> {
		if (readSkins == null)
			readSkins = [
				for (s in list(document, "skins")) {
					var joints = integers(field(s, "joints"));
					var inverse:Null<Int> = field(s, "inverseBindMatrices");
					var values = inverse == null ? null : floats(inverse);
					var matrices = [
						for (j in 0...joints.length) {
							var m = new Matrix3D();
							if (values != null) for (i in 0...16)
								m.values[i] = values[j * 16 + i];
							m;
						}
					];
					var skeleton:Null<Int> = field(s, "skeleton");
					new GltfSkin(text(s, "name"), joints, matrices, skeleton == null ? -1 : skeleton);
				}
			];
		return readSkins;
	}

	function get_animations():Array<GltfAnimation> {
		if (readAnimations == null)
			readAnimations = [
				for (a in list(document, "animations")) {
					var channels = [
						for (c in list(a, "channels")) {
							var target = field(c, "target"), node:Null<Int> = field(target, "node");
							new GltfChannel(node == null ? -1 : node, text(target, "path"), Std.int(number(c, "sampler", 0)));
						}
					];
					var samplers = [
						for (s in list(a, "samplers")) {
							var interpolation:Null<String> = field(s, "interpolation");
							new GltfSampler(floats(field(s, "input")), floats(field(s, "output")), interpolation == null ? "LINEAR" : interpolation);
						}
					];
					new GltfAnimation(text(a, "name"), channels, samplers);
				}
			];
		return readAnimations;
	}

	function get_images():Array<GltfImage> {
		if (readImages == null)
			readImages = [
				for (info in list(document, "images")) {
					var view:Null<Int> = field(info, "bufferView");
					var uri:String = field(info, "uri");
					var mimeType:Null<String> = field(info, "mimeType");
					if (view != null) new GltfImage(viewBytes(view), null,
						mimeType); else if (uri != null && StringTools.startsWith(uri,
						"data:")) new GltfImage(dataUri(uri), null, mimeType); else new GltfImage(null, uri == null ? null : resolve(uri), mimeType);
				}
			];
		return readImages;
	}

	// One primitive's vertices, read from its accessors.
	function primitive(primitive:Dynamic):GltfPrimitive {
		var attributes = field(primitive, "attributes");
		var mode:Null<Int> = field(primitive, "mode");
		var position:Null<Int> = field(attributes, "POSITION");
		var normal:Null<Int> = field(attributes, "NORMAL");
		var tangent:Null<Int> = field(attributes, "TANGENT");
		var joint:Null<Int> = field(attributes, "JOINTS_0");
		var weight:Null<Int> = field(attributes, "WEIGHTS_0");
		var uv:Null<Int> = field(attributes, "TEXCOORD_0");
		var color:Null<Int> = field(attributes, "COLOR_0");
		var colors:Null<Array<Float>> = null;
		if (color != null) {
			var values = floats(color),
				size = components(field(list(document, "accessors")[color], "type")),
				count = Std.int(values.length / size);
			colors = [];
			for (i in 0...count)
				for (c in 0...4)
					colors.push(c < size ? values[i * size + c] : 1);
		}
		var indices:Null<Int> = field(primitive, "indices");
		var material:Null<Int> = field(primitive, "material");
		return new GltfPrimitive(mode == null ? 4 : mode, position == null ? [] : floats(position), normal == null ? null : floats(normal),
			tangent == null ? null : floats(tangent), uv == null ? null : floats(uv), colors, joint == null ? null : ints(joint),
			weight == null ? null : floats(weight), indices == null ? null : ints(indices), material == null ? -1 : material);
	}

	// A node's own transform: its matrix, or its scale, then rotation, then translation.
	static function local(node:Dynamic):Matrix3D {
		var matrix = optionalNumbers(field(node, "matrix"));
		if (matrix != null) {
			var m = new Matrix3D();
			for (i in 0...16)
				m.values[i] = matrix[i];
			return m;
		}
		var s = optionalNumbers(field(node, "scale")),
			r = optionalNumbers(field(node, "rotation")),
			t = optionalNumbers(field(node, "translation"));
		var m = s == null ? new Matrix3D() : Matrix3D.fromScale(s[0], s[1], s[2]);
		if (r != null)
			m = Matrix3D.compose(m, Matrix3D.fromQuaternion(r[0], r[1], r[2], r[3]));
		if (t != null)
			m = Matrix3D.compose(m, Matrix3D.fromTranslation(t[0], t[1], t[2]));
		return m;
	}

	// A node's translation, rotation and scale: as it gives them, or its matrix taken apart.
	static function parts(node:Dynamic, transform:Matrix3D):Transform3D {
		if (field(node, "matrix") != null)
			return Transform3D.fromMatrix(transform);
		var t = numbers(field(node, "translation"), [0, 0, 0]),
			r = numbers(field(node, "rotation"), [0, 0, 0, 1]),
			s = numbers(field(node, "scale"), [1, 1, 1]);
		var parts = new Transform3D();
		parts.position.set(t[0], t[1], t[2]);
		parts.rotation.set(r[0], r[1], r[2], r[3]);
		parts.scale.set(s[0], s[1], s[2]);
		return parts;
	}

	// The bytes of buffer view index: a slice of its buffer.
	function view(index:Int):{
		bytes:Bytes,
		offset:Int,
		length:Int,
		stride:Int
	} {
		var views = list(document, "bufferViews");
		if (index < 0 || index >= views.length)
			throw 'No buffer view $index';
		var v = views[index], buffer:Int = field(v, "buffer");
		if (buffer < 0 || buffer >= buffers.length)
			throw 'Buffer view $index names no buffer $buffer';
		if (buffers[buffer] == null)
			throw 'Buffer $buffer is missing; set the missing buffers first: ' + [for (m in missingBuffers) '${m.index} (${m.path})'].join(", ");
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

	// The bytes of buffer view index, copied: an embedded image's file.
	function viewBytes(index:Int):Bytes {
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

	// Accessor index's values, every component of every element in order, as floats: normalized integers scaled to 0..1 (unsigned) or
	// -1..1 (signed), others as they are. Throws for a sparse accessor, an unknown type, or one running past its view.
	function floats(index:Int):Array<Float> {
		var accessors = list(document, "accessors");
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

	// Accessor index's values as integers: indices (unsigned 8, 16 or 32 bits).
	function ints(index:Int):Array<Int>
		return [for (x in floats(index)) Std.int(x)];

	// A field of a JSON object, or null.
	static function field(object:Dynamic, name:String):Dynamic
		return object == null ? null : Reflect.field(object, name);

	// The array named name in a JSON object, or an empty one.
	static function list(object:Dynamic, name:String):Array<Dynamic> {
		var value:Dynamic = field(object, name);
		return value == null ? [] : value;
	}

	// A string field, or empty.
	static function text(object:Dynamic, name:String):String {
		var value:Null<String> = field(object, name);
		return value == null ? "" : value;
	}

	// A number field, or a default.
	static function number(object:Dynamic, name:String, fallback:Float):Float {
		var value:Dynamic = field(object, name);
		return value == null ? fallback : (value : Float);
	}

	// A JSON array of numbers, each read as a Float (JSON's integers among them), or a default.
	static function numbers(value:Dynamic, fallback:Array<Float>):Array<Float> {
		var read = optionalNumbers(value);
		return read == null ? fallback : read;
	}

	static function optionalNumbers(value:Dynamic):Null<Array<Float>> {
		return value == null ? null : [for (x in (value : Array<Dynamic>)) (x : Float)];
	}

	// A JSON array of integers, or an empty one.
	static function integers(value:Dynamic):Array<Int> {
		var read = optionalIntegers(value);
		return read == null ? [] : read;
	}

	static function optionalIntegers(value:Dynamic):Null<Array<Int>> {
		return value == null ? null : [for (x in (value : Array<Dynamic>)) Std.int((x : Float))];
	}
}
