package helix.services.models;

import haxe.io.Bytes;
import helix.formats.gltf.GltfFile;
import helix.geometry.Mesh3D;
import helix.log.Log;
import helix.math.Matrix3D;
import helix.services.assets.Assets;
import helix.services.images.Image;
import helix.services.images.Images;

/** Provides 3D models by path: a glTF 2.0 file (.gltf or .glb) read through the assets, with the files it names (its buffers and
	images) brought in and its images decoded, as one `Model3D`.

	The file is read by helix-formats' `GltfFile`. Each node of its scene puts its transform, and its parents', into its meshes'
	positions, normals and tangents (`Mesh3D.transform`), so a model's meshes are drawn as they are. Only triangles are read; skins and animations aren't yet. Its
	answers come as the assets and images it reads through are polled.

	```haxe
	var models = new Models(assets, images);
	models.load("trophy.glb", model -> trophy = model);
	``` */
class Models {
	final assets:Assets;
	final images:Images;

	/** Creates the models over the assets they are found in and the images that decode theirs.

		@param assets  The assets the files are read through.
		@param images  The images a model's are decoded by. */
	public function new(assets:Assets, images:Images) {
		this.assets = assets;
		this.images = images;
	}

	/** Loads a model, the files it names and its images.

		One of `loaded` or `failed` is called once, at a later poll, never during this call. A buffer the file names that can't be read
		fails the load; an image that can't be read or decoded is null in the model, and logged.
		@param path  The file, as the assets name it.
		@param loaded  Receives the model.
		@param failed  Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
		@return  A function that aborts the load; neither callback is called after it, and once one was, it does nothing. */
	public function load(path:String, loaded:Model3D->Void, ?failed:String->Void):Void->Void {
		var aborted = false, finished = false, aborts:Array<Void->Void> = [];
		function fail(message:String):Void {
			if (aborted || finished)
				return;
			finished = true;
			for (abort in aborts)
				abort();
			if (failed != null)
				failed(message);
			else
				Log.warn(message, "models");
		}
		aborts.push(assets.load(path, bytes -> {
			if (aborted)
				return;
			var file = try GltfFile.read(bytes, path) catch (e:String) {
				fail('$path: $e');
				return;
			}
			// What's left to come: each buffer the file names, then each image once the buffers are in.
			var left = 1, decoded:Array<Null<Image>> = [];
			function done():Void {
				if (--left > 0 || aborted || finished)
					return;
				finished = true;
				var found = meshes(file);
				loaded(new Model3D(path, found.meshes, found.materials, file.materials, decoded));
			}
			function decode():Void {
				var list = file.images;
				decoded.resize(list.length);
				for (i in 0...list.length) {
					var image = list[i];
					left++;
					var answer = (result:Image) -> {
						decoded[i] = result;
						done();
					}, missing = (message:String) -> {
						Log.warn(message, "models");
						done();
					};
					if (image.encoded != null)
						aborts.push(images.decode(image.encoded, answer, message -> missing('$path: image $i: $message')));
					else if (image.path != null)
						aborts.push(images.load(image.path, answer, missing));
					else
						done();
				}
				done();
			}
			var buffers = file.missingBuffers;
			if (buffers.length == 0) {
				decode();
				return;
			}
			var waiting = buffers.length;
			for (buffer in buffers)
				aborts.push(assets.load(buffer.path, (bytes:Bytes) -> {
					if (aborted || finished)
						return;
					try
						file.setBuffer(buffer.index, bytes)
					catch (e:String) {
						fail('${buffer.path}: $e');
						return;
					}
					if (--waiting == 0)
						decode();
				}, fail));
		}, fail));
		return () -> {
			aborted = true;
			for (abort in aborts)
				abort();
		};
	}

	// The scene's meshes, each node's transform, after its parents', in its positions, normals and tangents (a mirroring one turning its
	// triangles round, as glTF has it); triangles alone; and each one's material.
	static function meshes(file:GltfFile):{meshes:Array<Mesh3D>, materials:Array<Int>} {
		var meshes = [], materials = [], all = file.meshes;
		function visit(index:Int, parent:Matrix3D):Void {
			var node = file.nodes[index];
			var world = Matrix3D.compose(node.transform, parent);
			if (node.mesh >= 0)
				for (primitive in all[node.mesh].primitives)
					if (primitive.mode == 4) {
						var mesh = new Mesh3D();
						mesh.positions = primitive.positions;
						mesh.normals = primitive.normals;
						mesh.tangents = primitive.tangents;
						mesh.texCoords = primitive.texCoords;
						mesh.colors = primitive.colors;
						mesh.indices = primitive.indices;
						meshes.push(mesh.transform(world));
						materials.push(primitive.material);
					}
			for (child in node.children)
				visit(child, world);
		}
		for (root in file.scene)
			visit(root, new Matrix3D());
		return {meshes: meshes, materials: materials};
	}
}
