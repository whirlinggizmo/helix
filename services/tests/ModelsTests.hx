import haxe.io.Bytes;
import helix.services.assets.Assets;
import helix.services.images.Images;
import helix.services.models.Model3D;
import helix.services.models.Models;

/** Checks Models over fakes: a .gltf whose buffer and image are files of their own (named URI-encoded, beside it in a folder) and whose
	second image is held in it, read with what it names; its nodes' transforms put into its mesh's positions and normals; a lines primitive
	left out; the images decoded by index, one that won't decode null; and a missing buffer failing the load by name. */
class ModelsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-6;

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
		check(near(mesh.normals[2], 1) && mesh.indices == null && mesh.material == 0, "its normals kept unit length; no indices; its material");
		check(model.materials[0].baseColorImage == 0 && model.images.length == 2, "materials name images by index");
		check(model.images[0] != null && model.images[0].width == 4 && model.images[0].path == "models/wood grain.png",
			"the image beside it, its name decoded, decoded");
		check(model.images[1] == null, "an image that won't decode: null");

		var why = "";
		models.load("broken/thing.gltf", _ -> throw "loaded without its buffer", message -> why = message);
		pump();
		check(why.indexOf("broken/mesh data.bin") >= 0, "a missing buffer fails the load, by its path");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
