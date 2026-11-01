import haxe.io.Bytes;
import helix.services.assets.Assets;
import helix.services.images.Images;
import helix.services.models.Model3D;
import helix.services.models.Models;

/** Checks Models over fakes: a .gltf whose buffer and image are files of their own (named URI-encoded, beside it in a folder) and whose
	second image is held in it, read with what it names; its nodes' transforms put into its mesh's positions and normals; a lines primitive
	left out; the images decoded by index, one that won't decode null; a rig's skeleton (its joints and the node above them), skin,
	skinned mesh left unplaced beside its node's transform, and animation of its bones alone; a missing buffer failing the load by
	name; and OBJ files: their libraries (a missing and a broken one skipped) and textures (a missing one null), a mesh for each group
	and material, vertices made of corners, v turned, normals made length 1 or computed, MTL materials as glTF's, positions' colors, an
	.OBJ, and a file that can't be read failing by its line. */
class ModelsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-6;

	// A rig held in one .gltf: an armature node above a hip and a knee, a skinned triangle on a node of its own, and an animation turning
	// the knee, moving an unrelated node and morph weights.
	static function rig():String {
		var b = new haxe.io.BytesOutput();
		for (v in [0., 0, 0, 1, 0, 0, 0, 1, 0])
			b.writeFloat(v);
		for (j in [0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0])
			b.writeByte(j);
		for (w in [.5, .5, 0, 0, 1, 0, 0, 0, .25, .75, 0, 0])
			b.writeFloat(w);
		for (t in [0., 2])
			b.writeFloat(t);
		for (r in [0., 0, 0, 1, 0, 0, 1, 0])
			b.writeFloat(r);
		for (v in [0., 0, 0, 1, 1, 1])
			b.writeFloat(v);
		var buffer = haxe.crypto.Base64.encode(b.getBytes());
		var document:Dynamic = {
			asset: {version: "2.0"},
			scene: 0,
			scenes: [{nodes: [0, 4]}],
			nodes: ([
				{name: "armature", translation: [0, 0, 5], children: [1, 3]},
				{name: "hip", translation: [0, 1, 0], children: [2]},
				{name: "knee", translation: [0, 1, 0]},
				{
					name: "body",
					mesh: 0,
					skin: 0,
					translation: [7, 0, 0]
				},
				{name: "lamp"}
			] : Array<Dynamic>),
			skins: [{joints: [2, 1]}],
			meshes: [
				{primitives: [({attributes: {POSITION: 0, JOINTS_0: 1, WEIGHTS_0: 2}} : Dynamic)]}
			],
			animations: [
				{
					name: "Kick",
					channels: ([
						{sampler: 0, target: {node: 2, path: "rotation"}},
						{sampler: 1, target: {node: 4, path: "translation"}},
						{sampler: 1, target: {node: 1, path: "weights"}}
					] : Array<Dynamic>),
					samplers: [{input: 3, output: 4}, {input: 3, output: 5}]
				}
			],
			buffers: [{byteLength: 160, uri: "data:application/octet-stream;base64," + buffer}],
			bufferViews: ([
				{buffer: 0, byteOffset: 0, byteLength: 36},
				{buffer: 0, byteOffset: 36, byteLength: 12},
				{buffer: 0, byteOffset: 48, byteLength: 48},
				{buffer: 0, byteOffset: 96, byteLength: 8},
				{buffer: 0, byteOffset: 104, byteLength: 32},
				{buffer: 0, byteOffset: 136, byteLength: 24}
			] : Array<Dynamic>),
			accessors: ([
				{
					bufferView: 0,
					componentType: 5126,
					count: 3,
					type: "VEC3"
				},
				{
					bufferView: 1,
					componentType: 5121,
					count: 3,
					type: "VEC4"
				},
				{
					bufferView: 2,
					componentType: 5126,
					count: 3,
					type: "VEC4"
				},
				{
					bufferView: 3,
					componentType: 5126,
					count: 2,
					type: "SCALAR"
				},
				{
					bufferView: 4,
					componentType: 5126,
					count: 2,
					type: "VEC4"
				},
				{
					bufferView: 5,
					componentType: 5126,
					count: 2,
					type: "VEC3"
				}
			] : Array<Dynamic>)
		};
		return haxe.Json.stringify(document);
	}

	// OBJ files: a house naming three libraries (one missing, one broken) whose materials name textures (one missing), its faces before
	// any usemtl, in two groups, a material no library gives; a colored triangle; a file that can't be read.
	static function obj(files:FakeFileSystem, models:Models, pump:Void->Void):Void {
		files.files.set("objs/house.obj",
			Bytes.ofString("mtllib house.mtl missing.mtl broken.mtl\n"
				+ "v 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nvt 0 0\nvt 1 0\nvt 1 0.25\nvt 0 1\nvn 0 0 2\n"
				+ "f 1 2 3\n" // before any usemtl
				+ "g a\nusemtl wall\nf 1/1/1 2/2/1 3/3/1 4/4/1\n" // a quad, its corners' normals given
				+ "g b\nusemtl roof\nf 1/1 2/2 3/3\n" // no normals
				+ "usemtl nowhere\nf 1 3 4\n"));
		files.files.set("objs/house.mtl",
			Bytes.ofString("newmtl wall\nKd 0.5 0.25 1\nd 0.5\nNs 250\nmap_Kd tex/wall.png\nbump gone.png\n"
				+ "map_Ke glow.png\nnewmtl roof\nPr 0.2\nPm 1\nKe 0.5 0.5 0.5\nmap_Kd tex/wall.png\nnorm roof.png\n"));
		files.files.set("objs/broken.mtl", Bytes.ofString("newmtl\n"));
		files.files.set("objs/tex/wall.png", Bytes.ofString("2x2"));
		files.files.set("objs/glow.png", Bytes.ofString("1x1"));
		files.files.set("objs/roof.png", Bytes.ofString("3x3"));
		var house:Model3D = null;
		models.load("objs/house.obj", m -> house = m, e -> throw e);
		pump();
		check(house != null && house.path == "objs/house.obj", "an OBJ file loaded, a missing and a broken library skipped");
		check(house.meshes.length == 4
			&& house.meshMaterialIndices.join(",") == "-1,0,1,2", "a mesh for each group and material, -1 before usemtl");
		check(house.skeleton == null
			&& house.skins.length == 0
			&& house.animations.length == 0
			&& house.meshSkinIndices.join(",") == "-1,-1,-1,-1"
			&& house.meshTransforms[0].values[12] == 0
			&& house.meshTransforms[0].values[0] == 1,
			"no skeleton; identity transforms");
		var quad = house.meshes[1];
		check(quad.vertexCount == 4 && quad.indices.join(",") == "0,1,2,0,2,3", "a quad: a vertex a corner, two triangles indexing them");
		check(quad.texCoords.join(",") == "0,1,1,1,1,0.75,0,0", "texture coordinates' v turned to run down the image");
		check(near(quad.normals[2], 1) && near(quad.normals[11], 1), "normals made length 1");
		var roof = house.meshes[2];
		check(roof.normals != null && near(roof.normals[2], 1), "normals computed where the file gives none");
		check(house.meshes[0].texCoords == null && house.meshes[0].colors == null, "no texture coordinates or colors where there are none");
		check(house.materials.length == 3 && house.materials[0].name == "wall" && house.materials[2].name == "nowhere", "a material each usemtl name");
		var wall = house.materials[0];
		check(wall.hasPbrMetallicRoughness
			&& wall.baseColorFactor.join(",") == "0.5,0.25,1,0.5"
			&& wall.metallic == 0
			&& near(wall.roughness, 0.5)
			&& wall.metallicRoughnessImageIndex == -1
			&& wall.occlusionImageIndex == -1,
			"Kd and d the base color; metalness and roughness computed");
		check(wall.baseColorImageIndex == 0
			&& wall.normalImageIndex == 1
			&& wall.emissiveImageIndex == 2
			&& wall.emissiveFactor.join(",") == "1,1,1",
			"its textures by index; the emissive color white with a texture and no Ke");
		var r = house.materials[1];
		check(r.baseColorImageIndex == 0
			&& r.metallic == 1
			&& r.roughness == 0.2
			&& r.normalImageIndex == 3
			&& r.emissiveImageIndex == -1
			&& r.emissiveFactor.join(",") == "0.5,0.5,0.5",
			"a texture two materials name is one image; Pr, Pm, norm and Ke");
		var nowhere = house.materials[2];
		check(nowhere.baseColorFactor.join(",") == "1,1,1,1" && nowhere.baseColorImageIndex == -1 && nowhere.normalImageIndex == -1,
			"a name no library gives: every default");
		check(house.images.length == 4
			&& house.images[0].path == "objs/tex/wall.png"
			&& house.images[0].width == 2
			&& house.images[1] == null
			&& house.images[2].width == 1
			&& house.images[3].width == 3,
			"its textures decoded, a missing one null");

		files.files.set("objs/colors.OBJ", Bytes.ofString("v 0 0 0 1 0 0\nv 1 0 0 0 1 0\nv 0 1 0 0 0 1\nf 1 2 3\n"));
		var colored:Model3D = null;
		models.load("objs/colors.OBJ", m -> colored = m, e -> throw e);
		pump();
		check(colored != null
			&& colored.materials.length == 0
			&& colored.meshMaterialIndices.join(",") == "-1"
			&& colored.meshes[0].colors.join(",") == "1,0,0,1,0,1,0,1,0,0,1,1",
			"an .OBJ: positions' colors, alpha 1; no libraries, no materials");

		files.files.set("objs/bad.obj", Bytes.ofString("v 0 0 0\nf 1 2 3\n"));
		var why = "";
		models.load("objs/bad.obj", _ -> throw "loaded a bad file", message -> why = message);
		pump();
		check(why.indexOf("objs/bad.obj") >= 0 && why.indexOf("Line 2") >= 0, "a file that can't be read fails, by its path and line");
	}

	static function main():Void {
		// One triangle's positions and normals, in a buffer of their own.
		var bin = Bytes.alloc(72);
		var values = [0., 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1];
		for (i in 0...values.length)
			bin.setFloat(i * 4, values[i]);
		var document:Dynamic = {
			asset: {version: "2.0"},
			scene: 0,
			scenes: [{nodes: [0]}],
			nodes: ([{translation: [10, 0, 0], children: [1]}, {scale: [2, 2, 2], mesh: 0}] : Array<Dynamic>),
			meshes: [
				{
					primitives: [
						({attributes: {POSITION: 0, NORMAL: 1}, material: 0} : Dynamic),
						({attributes: {POSITION: 0}, mode: 1} : Dynamic)
					]
				}
			],
			materials: [{pbrMetallicRoughness: {baseColorTexture: {index: 0}}}],
			textures: [{source: 0}, {source: 1}],
			images: [
				{uri: "wood%20grain.png"},
				{uri: "data:image/png;base64," + haxe.crypto.Base64.encode(Bytes.ofString("junk"))}
			],
			buffers: [{uri: "mesh%20data.bin", byteLength: 72}],
			bufferViews: [
				{buffer: 0, byteOffset: 0, byteLength: 36},
				{buffer: 0, byteOffset: 36, byteLength: 36}
			],
			accessors: [
				{
					bufferView: 0,
					componentType: 5126,
					count: 3,
					type: "VEC3"
				},
				{
					bufferView: 1,
					componentType: 5126,
					count: 3,
					type: "VEC3"
				}
			]
		};
		var gltf = haxe.Json.stringify(document);
		var files = new FakeFileSystem();
		files.files.set("models/thing.gltf", Bytes.ofString(gltf));
		files.files.set("models/mesh data.bin", bin);
		files.files.set("models/wood grain.png", Bytes.ofString("4x4"));
		files.files.set("broken/thing.gltf", Bytes.ofString(gltf));
		files.files.set("models/rig.gltf", Bytes.ofString(rig()));
		var decoder = new FakeImageDecoder();
		var assets = new Assets({sources: [FileSystem(files)]});
		var images = new Images(decoder, assets);
		var models = new Models(assets, images);
		function pump()
			for (_ in 0...10) {
				files.poll();
				decoder.poll();
				images.poll();
			}

		var model:Model3D = null;
		models.load("models/thing.gltf", m -> model = m);
		check(model == null, "not answered during the call");
		pump();
		check(model != null && model.path == "models/thing.gltf", "loaded, with what it names");
		check(model.meshes.length == 1, "the lines primitive left out");
		var mesh = model.meshes[0];
		check(near(mesh.positions[0], 10) && near(mesh.positions[3], 12) && near(mesh.positions[7], 2), "the nodes' transforms in its positions");
		check(near(mesh.normals[2], 1) && mesh.indices == null && model.meshMaterialIndices.join(",") == "0",
			"its normals kept unit length; no indices; its material beside it");
		check(model.materials[0].baseColorImageIndex == 0 && model.images.length == 2, "materials name images by index");
		check(model.images[0] != null && model.images[0].width == 4 && model.images[0].path == "models/wood grain.png",
			"the image beside it, its name decoded, decoded");
		check(model.images[1] == null, "an image that won't decode: null");
		check(model.skeleton == null
			&& model.skins.length == 0
			&& model.animations.length == 0
			&& model.meshSkinIndices.join(",") == "-1"
			&& near(model.meshTransforms[0].values[12], 10),
			"no skin: no skeleton, no animations; its node's transform beside it");

		var rigged:Model3D = null;
		models.load("models/rig.gltf", m -> rigged = m);
		pump();
		var bones = rigged.skeleton.bones;
		check(bones.length == 3 && bones[0].name == "armature" && bones[0].parentIndex == -1 && bones[1].name == "hip" && bones[1].parentIndex == 0
			&& bones[2].name == "knee" && bones[2].parentIndex == 1,
			"the skeleton: its joints and the node above them, parents first");
		check(near(bones[0].rest.position.z, 5) && near(bones[2].rest.position.y, 1), "each bone at rest its node's own transform");
		check(rigged.skins.length == 1
			&& rigged.skins[0].boneIndices.join(",") == "2,1", "the skin's joints as the skeleton's bones, in its order");
		var body = rigged.meshes[0];
		check(rigged.meshSkinIndices.join(",") == "0"
			&& near(body.positions[3], 1)
			&& body.jointIndices.join(",") == "0,1,0,0,1,0,0,0,0,1,0,0"
			&& near(body.weights[0], .5),
			"a skinned mesh: its vertices as the file has them, its joints and weights");
		var placed = rigged.meshTransforms[0].values;
		check(near(placed[12], 7) && near(placed[14], 5), "its node's transform kept beside it, not put into it");
		var kick = rigged.animations[0];
		check(rigged.animations.length == 1
			&& kick.name == "Kick"
			&& kick.tracks.length == 1
			&& kick.tracks[0].boneIndex == 2
			&& kick.tracks[0].property == Rotation
			&& kick.tracks[0].interpolation == Linear
			&& near(kick.duration, 2),
			"its animation's tracks: a channel moving another node, or weights, left out");
		check(rigged.findAnimation("Kick") == 0 && rigged.findAnimation("Nope") == -1, "an animation found by name");

		var why = "";
		models.load("broken/thing.gltf", _ -> throw "loaded without its buffer", message -> why = message);
		pump();
		check(why.indexOf("broken/mesh data.bin") >= 0, "a missing buffer fails the load, by its path");
		obj(files, models, pump);
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
