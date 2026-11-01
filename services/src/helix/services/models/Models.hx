package helix.services.models;

import haxe.io.Bytes;
import helix.formats.gltf.GltfFile;
import helix.geometry.Animation3D;
import helix.geometry.AnimationProperty3D;
import helix.geometry.AnimationTrack3D;
import helix.geometry.Bone3D;
import helix.geometry.KeyInterpolation;
import helix.geometry.Mesh3D;
import helix.geometry.Skeleton3D;
import helix.geometry.Skin3D;
import helix.math.Transform3D;
import helix.log.Log;
import helix.math.Matrix3D;
import helix.services.assets.Assets;
import helix.services.images.Image;
import helix.services.images.Images;

/** Provides 3D models by path: a glTF 2.0 file (.gltf or .glb) read through the assets, with the files it names (its buffers and
	images) brought in and its images decoded, as one `Model3D`.

	The file is read by helix-formats' `GltfFile`. Each node of its scene puts its transform, and its parents', into its meshes'
	positions, normals and tangents (`Mesh3D.transform`), so a model's meshes are drawn as they are; a skinned mesh's vertices stay as
	the file gives them, its skin's matrices placing it. Its skins become a skeleton (`Model3D.skeleton`), and its animations of that
	skeleton's bones `Animation3D`s. Only triangles are read; morph targets aren't yet. Its answers come as the assets and images it
	reads through are polled.

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
				var found = try contents(file, path) catch (e:String) {
					fail('$path: $e');
					return;
				}
				loaded(new Model3D(path, found.meshes, found.materials, found.skins, found.transforms, found.skeleton, found.madeSkins, found.animations,
					file.materials, decoded));
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

	// What a model has: the scene's meshes, each node's transform, after its parents', in its positions, normals and tangents (a
	// mirroring one turning its triangles round, as glTF has it), a skinned mesh's left as it is; triangles alone; each one's material,
	// skin and node's transform; and the skeleton, its skins and its animations.
	static function contents(file:GltfFile, path:String) {
		var meshes = [], materials = [], skins = [], transforms = [], all = file.meshes, nodes = file.nodes;
		// The skeleton: every joint and the nodes above it, parents first, in the scene's order.
		var fileSkins = file.skins,
			wanted = new Map<Int, Bool>(),
			parents = new Map<Int, Int>();
		for (i => node in nodes)
			for (child in node.children)
				parents.set(child, i);
		for (skin in fileSkins)
			for (joint in skin.joints) {
				var n:Null<Int> = joint;
				while (n != null && !wanted.exists(n)) {
					wanted.set(n, true);
					n = parents.get(n);
				}
			}
		var bones = [], boneOf = new Map<Int, Int>();
		function visit(index:Int, parent:Matrix3D, bone:Int):Void {
			var node = nodes[index];
			var world = Matrix3D.compose(node.transform, parent);
			if (wanted.exists(index)) {
				boneOf.set(index, bones.length);
				bones.push(new Bone3D(node.name, bone, new Transform3D().copyFrom(node.local)));
				bone = bones.length - 1;
			}
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
						var skinned = node.skin >= 0 && node.skin < fileSkins.length && primitive.joints != null && primitive.weights != null;
						if (skinned) {
							mesh.joints = primitive.joints;
							mesh.weights = primitive.weights;
						}
						meshes.push(skinned ? mesh : mesh.transform(world));
						materials.push(primitive.material);
						skins.push(skinned ? node.skin : -1);
						transforms.push(world);
					}
			for (child in node.children)
				visit(child, world, bone);
		}
		for (root in file.scene)
			visit(root, new Matrix3D(), -1);
		var skeleton = bones.length > 0 ? new Skeleton3D(bones) : null;
		var madeSkins = [
			for (skin in fileSkins)
				new Skin3D(skin.name, [for (joint in skin.joints) boneOf.exists(joint) ? boneOf.get(joint) : 0], skin.inverseBindMatrices)
		];
		var animations = [];
		if (skeleton != null)
			for (animation in file.animations) {
				var tracks = [];
				for (channel in animation.channels) {
					var property:Null<AnimationProperty3D> = switch channel.path {
						case "translation": Translation;
						case "rotation": Rotation;
						case "scale": Scale;
						case _: null;
					}
					if (property == null
						|| !boneOf.exists(channel.node)
						|| channel.sampler < 0
						|| channel.sampler >= animation.samplers.length)
						continue;
					var sampler = animation.samplers[channel.sampler];
					var interpolation:KeyInterpolation = switch sampler.interpolation {
						case "STEP": Step;
						case "CUBICSPLINE": CubicSpline;
						case _: Linear;
					}
					tracks.push(new AnimationTrack3D(boneOf.get(channel.node), property, interpolation, sampler.input, sampler.output));
				}
				animations.push(new Animation3D(animation.name, tracks));
			}
		return {
			meshes: meshes,
			materials: materials,
			skins: skins,
			transforms: transforms,
			skeleton: skeleton,
			madeSkins: madeSkins,
			animations: animations
		};
	}
}
