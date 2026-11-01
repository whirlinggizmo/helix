import haxe.io.Bytes;
import haxe.io.BytesOutput;
import helix.formats.gltf.GltfFile;

/** Checks GltfFile with the library alone, on models made here: a GLB holding its buffer and an image, a .gltf holding its buffer as a
	data: URI, and a .gltf naming a buffer and an image in files of their own under a subdirectory, their names percent-encoded. Its
	nodes and transforms (and their parts), the default scene, meshes' values (floats, normalized integers, strides, indices, an accessor
	with no view, tangents, joints and weights), skins and their inverse binds, animations' channels and samplers,
	materials, their defaults and the blocks and textures they lack, images held and named, the missing buffers' paths, setBuffer and what it refuses, and what throws. */
class GltfTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The String a call throws, or null when it doesn't.
	static function thrown(call:Void->Void):Null<String> {
		try
			call()
		catch (e:String)
			return e;
		return null;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-6;

	static function same(a:Array<Float>, b:Array<Float>):Bool {
		if (a == null || b == null || a.length != b.length)
			return false;
		for (i in 0...a.length)
			if (!near(a[i], b[i]))
				return false;
		return true;
	}

	// Little-endian bytes: each value written as its kind says.
	static function floats(values:Array<Float>):Bytes {
		var out = new BytesOutput();
		for (v in values)
			out.writeFloat(v);
		return out.getBytes();
	}

	// A GLB: its JSON chunk padded with spaces, its BIN chunk with zeros, each to 4 bytes.
	static function glb(json:String, bin:Bytes):Bytes {
		var text = Bytes.ofString(json);
		var jsonLength = (text.length + 3) & ~3,
			binLength = (bin.length + 3) & ~3;
		var out = new BytesOutput();
		out.writeString("glTF");
		out.writeInt32(2);
		out.writeInt32(12 + 8 + jsonLength + 8 + binLength);
		out.writeInt32(jsonLength);
		out.writeInt32(0x4E4F534A);
		out.write(text);
		for (_ in text.length...jsonLength)
			out.writeByte(0x20);
		out.writeInt32(binLength);
		out.writeInt32(0x004E4942);
		out.write(bin);
		for (_ in bin.length...binLength)
			out.writeByte(0);
		return out.getBytes();
	}

	static function main():Void {
		embedded();
		dataUri();
		external();
		refused();
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// A GLB holding its buffer and an image.
	static function embedded():Void {
		var bin = new BytesOutput();
		bin.write(floats([0, 0, 0, 1, 0, 0, 0, 1, 0])); // 0: positions, 36 bytes
		bin.write(floats([0, 0, 1, 0, 0, 1])); // 36: texture coordinates, 24 bytes
		for (rgb in [[255, 0, 0], [0, 255, 0], [0, 0, 51]]) { // 60: colors, normalized bytes, a stride of 4
			for (c in rgb)
				bin.writeByte(c);
			bin.writeByte(0xEE);
		}
		for (i in [0, 1, 2]) // 72: indices, unsigned shorts
			bin.writeUInt16(i);
		bin.writeUInt16(0);
		var png = Bytes.ofHex("89504e470d0a1a0a"); // 80: an image, 8 bytes
		bin.write(png);
		var json = '{"asset":{"version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],
			"nodes":[{"name":"root","translation":[1,2,3],"scale":[2,2,2],"children":[1]},
				{"name":"child","mesh":0,"matrix":[1,0,0,0, 0,1,0,0, 0,0,1,0, 5,6,7,1]}],
			"meshes":[{"name":"triangle","primitives":[{"attributes":{"POSITION":0,"TEXCOORD_0":1,"COLOR_0":2},"indices":3,"material":0}]}],
			"materials":[{"name":"paint","pbrMetallicRoughness":{"baseColorFactor":[1,0.5,0.25,1],"baseColorTexture":{"index":0},"metallicFactor":0}}],
			"textures":[{"source":0}],
			"images":[{"bufferView":4,"mimeType":"image/png"}],
			"buffers":[{"byteLength":88}],
			"bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36},{"buffer":0,"byteOffset":36,"byteLength":24},
				{"buffer":0,"byteOffset":60,"byteLength":12,"byteStride":4},{"buffer":0,"byteOffset":72,"byteLength":6},
				{"buffer":0,"byteOffset":80,"byteLength":8}],
			"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3"},
				{"bufferView":1,"componentType":5126,"count":3,"type":"VEC2"},
				{"bufferView":2,"componentType":5121,"normalized":true,"count":3,"type":"VEC3"},
				{"bufferView":3,"componentType":5123,"count":3,"type":"SCALAR"}]}';
		var model = GltfFile.read(glb(json, bin.getBytes()), "models/ship.glb");
		check(model.missingBuffers.length == 0, "GLB: its buffer is its BIN chunk, none missing");
		check(model.nodes.length == 2
			&& model.nodes[0].name == "root"
			&& model.nodes[0].mesh == -1
			&& model.nodes[0].children.join(",") == "1",
			"GLB: a node's name, no mesh, its children");
		check(model.nodes[1].mesh == 0 && model.nodes[1].children.length == 0, "GLB: a node's mesh, no children");
		check(model.scene.join(",") == "0", "GLB: the default scene's roots");
		var p = model.nodes[0].transform.transformPoint(1, 0, 0);
		check(near(p.x, 3) && near(p.y, 2) && near(p.z, 3), "GLB: scale, then translation");
		var q = model.nodes[1].transform.transformPoint(1, 1, 1);
		check(near(q.x, 6) && near(q.y, 7) && near(q.z, 8), "GLB: a matrix, column by column");
		var mesh = model.meshes[0];
		check(model.meshes.length == 1 && mesh.name == "triangle" && mesh.primitives.length == 1, "GLB: a mesh and its primitive");
		var primitive = mesh.primitives[0];
		check(primitive.mode == 4 && primitive.material == 0, "GLB: triangles by default, its material");
		check(same(primitive.positions, [0, 0, 0, 1, 0, 0, 0, 1, 0]), "GLB: positions");
		check(same(primitive.texCoords, [0, 0, 1, 0, 0, 1]), "GLB: texture coordinates");
		check(same(primitive.colors, [1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0.2, 1]), "GLB: normalized colors over a stride, alpha 1 for three");
		check(primitive.normals == null && primitive.tangents == null, "GLB: no normals, no tangents");
		check(primitive.indices.join(",") == "0,1,2", "GLB: indices");
		var material = model.materials[0];
		check(model.materials.length == 1 && material.name == "paint" && same(material.baseColorFactor, [1, 0.5, 0.25, 1]),
			"GLB: a material's name and base color");
		check(material.baseColorImage == 0 && material.metallic == 0 && material.roughness == 1, "GLB: its texture's image, its factors");
		check(material.normalImage == -1 && material.emissiveImage == -1 && same(material.emissiveFactor, [0, 0, 0]),
			"GLB: no normal or emissive image, black emission");
		check(material.hasPbrMetallicRoughness && material.metallicRoughnessImage == -1 && material.occlusionImage == -1,
			"GLB: a pbrMetallicRoughness block, no metallic-roughness or occlusion image");
		var image = model.images[0];
		check(model.images.length == 1 && image.path == null && image.mimeType == "image/png" && image.encoded.compare(png) == 0,
			"GLB: an image held in a buffer view");
	}

	// A .gltf holding its buffer and an image as data: URIs.
	static function dataUri():Void {
		var bin = new BytesOutput();
		bin.write(floats([0, 0, 0, 2, 0, 0, 0, 2, 0])); // 0: positions, 36 bytes
		for (n in [0, 0, 127, 0, 0, -128, 0, 127, 0]) // 36: normals, normalized signed bytes
			bin.writeInt8(n);
		for (i in [2, 1, 0]) // 45: indices, unsigned bytes
			bin.writeByte(i);
		bin.write(floats([1, 0, 0, 1, 0, 1, 0, -1, 0, 0, 1, 1])); // 48: tangents, 48 bytes
		for (j in [0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0]) // 96: joints, unsigned bytes, 12
			bin.writeByte(j);
		bin.write(floats([.75, .25, 0, 0, 1, 0, 0, 0, .5, .5, 0, 0])); // 108: weights, 48
		bin.write(floats([
			1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -2, 0, 1
		])); // 156: 2 inverse binds, 128
		bin.write(floats([0, 1.5])); // 284: key times, 8
		bin.write(floats([0, 0, 0, 1, 0, 0, 0.7071067811865476, 0.7071067811865476])); // 292: rotations, 32
		bin.write(floats([0, 1, 0, 0, 2, 0])); // 324: translations, 24
		var buffer = haxe.crypto.Base64.encode(bin.getBytes());
		var png = Bytes.ofHex("89504e47");
		var json = '{"asset":{"version":"2.1"},
			"nodes":[{"mesh":0,"rotation":[0,0,0.7071067811865476,0.7071067811865476]},{"mesh":0,"skin":0},
				{"name":"hip","translation":[0,1,0],"children":[3]},{"name":"knee","matrix":[2,0,0,0, 0,2,0,0, 0,0,2,0, 0,1,0,1]}],
			"skins":[{"name":"legs","joints":[2,3],"inverseBindMatrices":7,"skeleton":2},{"joints":[3]}],
			"animations":[{"name":"Walk","channels":[{"sampler":0,"target":{"node":3,"path":"rotation"}},{"sampler":1,"target":{"node":2,"path":"translation"}}],
				"samplers":[{"input":8,"output":9},{"input":8,"output":10,"interpolation":"STEP"}]},{"channels":[],"samplers":[]}],
			"meshes":[{"primitives":[{"attributes":{"POSITION":0,"NORMAL":1,"TANGENT":4,"TEXCOORD_0":3,"JOINTS_0":5,"WEIGHTS_0":6},"indices":2},
				{"attributes":{"POSITION":0},"mode":1}]}],
			"materials":[{"emissiveFactor":[1,1,0],"emissiveTexture":{"index":0},"normalTexture":{"index":1}},
				{"pbrMetallicRoughness":{"metallicRoughnessTexture":{"index":0}},"occlusionTexture":{"index":0}}],
			"textures":[{"source":0},{}],
			"images":[{"uri":"data:image/png;base64,${haxe.crypto.Base64.encode(png)}"}],
			"buffers":[{"byteLength":348,"uri":"data:application/octet-stream;base64,$buffer"}],
			"bufferViews":[{"buffer":0,"byteOffset":0,"byteLength":36},{"buffer":0,"byteOffset":36,"byteLength":9},
				{"buffer":0,"byteOffset":45,"byteLength":3},{"buffer":0,"byteOffset":48,"byteLength":48},
				{"buffer":0,"byteOffset":96,"byteLength":12},{"buffer":0,"byteOffset":108,"byteLength":48},{"buffer":0,"byteOffset":156,"byteLength":128},
				{"buffer":0,"byteOffset":284,"byteLength":8},{"buffer":0,"byteOffset":292,"byteLength":32},{"buffer":0,"byteOffset":324,"byteLength":24}],
			"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3"},
				{"bufferView":1,"componentType":5120,"normalized":true,"count":3,"type":"VEC3"},
				{"bufferView":2,"componentType":5121,"count":3,"type":"SCALAR"},
				{"componentType":5126,"count":3,"type":"VEC2"},
				{"bufferView":3,"componentType":5126,"count":3,"type":"VEC4"},
				{"bufferView":4,"componentType":5121,"count":3,"type":"VEC4"},
				{"bufferView":5,"componentType":5126,"count":3,"type":"VEC4"},
				{"bufferView":6,"componentType":5126,"count":2,"type":"MAT4"},
				{"bufferView":7,"componentType":5126,"count":2,"type":"SCALAR"},
				{"bufferView":8,"componentType":5126,"count":2,"type":"VEC4"},
				{"bufferView":9,"componentType":5126,"count":2,"type":"VEC3"}]}';
		var model = GltfFile.read(Bytes.ofString(json), "ship.gltf");
		check(model.missingBuffers.length == 0, ".gltf: a data: URI buffer is read, none missing");
		check(model.scene.join(",") == "0,1,2", ".gltf: with no scenes, every node no node's child is a root");
		var p = model.nodes[0].transform.transformPoint(1, 0, 0);
		check(near(p.x, 0) && near(p.y, 1) && near(p.z, 0), ".gltf: a quaternion turns +x to +y");
		check(model.nodes[1].name == "" && model.meshes[0].name == "", ".gltf: no name is empty");
		var primitive = model.meshes[0].primitives[0];
		check(same(primitive.positions, [0, 0, 0, 2, 0, 0, 0, 2, 0])
			&& primitive.indices.join(",") == "2,1,0", ".gltf: positions, byte indices");
		check(same(primitive.normals, [0, 0, 1, 0, 0, -1, 0, 1, 0]), ".gltf: normalized signed bytes, -128 clamped to -1");
		check(same(primitive.texCoords, [0, 0, 0, 0, 0, 0]), ".gltf: an accessor with no buffer view is zeros");
		check(same(primitive.tangents, [1, 0, 0, 1, 0, 1, 0, -1, 0, 0, 1, 1]), ".gltf: tangents, their w");
		check(primitive.joints.join(",") == "0,1,0,0,1,0,0,0,0,1,0,0"
			&& same(primitive.weights, [.75, .25, 0, 0, 1, 0, 0, 0, .5, .5, 0, 0]),
			".gltf: joints and weights, four a vertex");
		var r = model.nodes[0].local.rotation;
		check(near(r.z, 0.7071067811865476)
			&& near(r.w, 0.7071067811865476)
			&& model.nodes[0].local.position.x == 0
			&& model.nodes[0].local.scale.y == 1,
			".gltf: a node's parts as it gives them, the rest their defaults");
		var knee = model.nodes[3].local;
		check(near(knee.scale.x, 2) && near(knee.position.y, 1) && near(knee.rotation.w, 1), ".gltf: a node's matrix taken apart");
		check(model.nodes[1].skin == 0 && model.nodes[0].skin == -1, ".gltf: a node's skin, or none");
		var skin = model.skins[0];
		check(model.skins.length == 2 && skin.name == "legs" && skin.joints.join(",") == "2,3" && skin.skeleton == 2,
			".gltf: a skin's name, joints and skeleton");
		check(near(skin.inverseBindMatrices[1].values[13], -2)
			&& near(skin.inverseBindMatrices[0].values[0], 1), ".gltf: its inverse binds");
		check(model.skins[1].inverseBindMatrices[0].values.join(",") == new helix.math.Matrix3D().values.join(",") && model.skins[1].skeleton == -1
			&& model.skins[1].name == "",
			".gltf: none given, identities; no skeleton, no name");
		var walk = model.animations[0];
		check(model.animations.length == 2 && walk.name == "Walk" && walk.channels.length == 2 && walk.channels[0].node == 3
			&& walk.channels[0].path == "rotation" && walk.channels[1].sampler == 1,
			".gltf: an animation's channels");
		check(same(walk.samplers[0].input, [0, 1.5])
			&& same(walk.samplers[0].output, [0, 0, 0, 1, 0, 0, 0.7071067811865476, 0.7071067811865476])
			&& walk.samplers[0].interpolation == "LINEAR"
			&& walk.samplers[1].interpolation == "STEP"
			&& same(walk.samplers[1].output, [0, 1, 0, 0, 2, 0]),
			".gltf: its samplers' keys, linear unless it says");
		check(model.animations[1].name == "" && model.animations[1].channels.length == 0, ".gltf: an empty animation");
		check(primitive.colors == null && primitive.material == -1, ".gltf: no colors, no material");
		var lines = model.meshes[0].primitives[1];
		check(lines.mode == 1 && lines.indices == null && lines.positions.length == 9, ".gltf: a primitive of lines, no indices");
		var material = model.materials[0];
		check(material.name == ""
			&& same(material.baseColorFactor, [1, 1, 1, 1])
			&& material.baseColorImage == -1
			&& material.metallic == 1,
			".gltf: a material's defaults");
		check(material.emissiveImage == 0 && same(material.emissiveFactor, [1, 1, 0]) && material.normalImage == -1,
			".gltf: emission; a texture with no source is no image");
		check(!material.hasPbrMetallicRoughness && material.metallicRoughnessImage == -1 && material.occlusionImage == -1,
			".gltf: no pbrMetallicRoughness block, no metallic-roughness or occlusion image");
		var pbr = model.materials[1];
		check(pbr.hasPbrMetallicRoughness && pbr.metallicRoughnessImage == 0 && pbr.occlusionImage == 0 && pbr.baseColorImage == -1 && pbr.roughness == 1,
			".gltf: a pbrMetallicRoughness block of a metallic-roughness texture alone; an occlusion texture");
		check(model.images[0].encoded.compare(png) == 0
			&& model.images[0].path == null
			&& model.images[0].mimeType == null, ".gltf: an image as a data: URI");
	}

	// A .gltf naming its buffer and an image in files of their own, under subdirectories, their names percent-encoded.
	static function external():Void {
		var json = '{"asset":{"version":"2.0"},"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],
			"meshes":[{"primitives":[{"attributes":{"POSITION":0},"material":0}]}],
			"materials":[{"pbrMetallicRoughness":{"baseColorTexture":{"index":0}}}],
			"textures":[{"source":0}],
			"images":[{"uri":"textures/my%20wood.png","mimeType":"image/png"}],
			"buffers":[{"byteLength":36,"uri":"bin/my%20mesh+1.bin"}],
			"bufferViews":[{"buffer":0,"byteLength":36}],
			"accessors":[{"bufferView":0,"componentType":5126,"count":3,"type":"VEC3"}]}';
		var model = GltfFile.read(Bytes.ofString(json), "assets/models/ship.gltf");
		var missing = model.missingBuffers;
		check(missing.length == 1 && missing[0].index == 0 && missing[0].path == "assets/models/bin/my mesh+1.bin",
			"external: a missing buffer, its path decoded (a + kept) and resolved");
		check(GltfFile.read(Bytes.ofString(json), "ship.gltf").missingBuffers[0].path == "bin/my mesh+1.bin",
			"external: a model with no directory leaves the path as decoded");
		check(model.nodes[0].mesh == 0 && model.materials[0].baseColorImage == 0, "external: nodes and materials are read without the buffer");
		var image = model.images[0];
		check(image.encoded == null && image.path == "assets/models/textures/my wood.png" && image.mimeType == "image/png",
			"external: an image in a file of its own, its path decoded and resolved");
		var error = thrown(() -> model.meshes);
		check(error != null && error.indexOf("assets/models/bin/my mesh+1.bin") >= 0, "external: meshes throw, naming the missing buffer");
		check(thrown(() -> model.setBuffer(0, floats([0, 0]))) != null && model.missingBuffers.length == 1,
			"external: setBuffer refuses bytes shorter than byteLength, changing nothing");
		check(thrown(() -> model.setBuffer(1, floats([0, 0, 0, 0, 0, 0, 0, 0, 0]))) != null, "external: setBuffer refuses an index out of range");
		model.setBuffer(0, floats([1, 2, 3, 4, 5, 6, 7, 8, 9]));
		check(model.missingBuffers.length == 0, "external: set, none missing");
		check(same(model.meshes[0].primitives[0].positions, [1, 2, 3, 4, 5, 6, 7, 8, 9]), "external: meshes read from the buffer set");
	}

	// What isn't a model it reads.
	static function refused():Void {
		check(thrown(() -> GltfFile.read(Bytes.ofString("hello"), "x.gltf")) != null, "neither GLB nor JSON throws");
		check(thrown(() -> GltfFile.read(Bytes.ofString("{\"asset\":{\"version\":\"1.0\"}}"), "x.gltf")) != null, "glTF 1.0 throws");
		check(thrown(() -> GltfFile.read(Bytes.ofString("{\"asset\":"), "x.gltf")) != null, "broken JSON throws a String");
		var v1 = glb('{"asset":{"version":"2.0"}}', Bytes.alloc(0));
		v1.setInt32(4, 1);
		check(thrown(() -> GltfFile.read(v1, "x.glb")) != null, "a GLB of version 1 throws");
		var sparse = '{"asset":{"version":"2.0"},"meshes":[{"primitives":[{"attributes":{"POSITION":0}}]}],
			"accessors":[{"componentType":5126,"count":3,"type":"VEC3","sparse":{"count":1}}]}';
		var model = GltfFile.read(Bytes.ofString(sparse), "x.gltf");
		check(thrown(() -> model.meshes) != null, "a sparse accessor throws when its mesh is read");
	}
}
