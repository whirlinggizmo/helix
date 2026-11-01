package helix.services.models;

import haxe.io.Bytes;
import helix.formats.gltf.GltfFile;
import helix.formats.gltf.GltfMaterial;
import helix.formats.obj.MtlFile;
import helix.formats.obj.MtlMaterial;
import helix.formats.obj.ObjFile;
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

/** Provides 3D models by path: a glTF 2.0 file (.gltf or .glb) or a Wavefront OBJ file (.obj) read through the assets, with the files it
	names (a glTF file's buffers and images, an OBJ file's material libraries and their textures) brought in and its images decoded, as one
	`Model3D`. The file's extension decides how it is read.

	The file is read by helix-formats' `GltfFile`. Each node of its scene puts its transform, and its parents', into its meshes'
	positions, normals and tangents (`Mesh3D.transform`), so a model's meshes are drawn as they are; a skinned mesh's vertices stay as
	the file gives them, its skin's matrices placing it. Its skins become a skeleton (`Model3D.skeleton`), and its animations of that
	skeleton's bones `Animation3D`s. Only triangles are read; morph targets aren't yet.

	An OBJ file is read by helix-formats' `ObjFile`, and the .mtl files it names by `MtlFile`: a library that can't be read is logged and
	skipped, its materials' names then standing for materials with every value its default. Its faces become a mesh for each object,
	group and material (`ObjFile.computeParts`), each corner that differs a vertex of its own, its texture coordinates' v turned to run
	down the image as glTF's do, and its normals made length 1, or computed from the triangles where the file gives none for some of
	its corners. Its materials are given as `GltfMaterial`s (`Model3D.materials` says how), and the textures they name decoded. It has
	no skeleton or animations.

	Its answers come as the assets and images it reads through are polled.

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
		if (StringTools.endsWith(path.toLowerCase(), ".obj"))
			return loadObj(path, loaded, failed);
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
						file.setBuffer(buffer.bufferIndex, bytes)
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

	// An OBJ file's model: the file, then each library it names (one that can't be read logged and skipped), then each texture its
	// materials name, decoded (one that can't be, null and logged).
	function loadObj(path:String, loaded:Model3D->Void, ?failed:String->Void):Void->Void {
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
			var file = try ObjFile.read(bytes, path) catch (e:String) {
				fail('$path: $e');
				return;
			}
			var paths = file.materialLibraryPaths,
				libraries:Array<Null<MtlFile>> = [for (_ in paths) null],
				left = paths.length + 1;
			function textures():Void {
				var materials = file.computeMaterials(MtlFile.combine([for (l in libraries) if (l != null) l]));
				var imagePaths:Array<String> = [],
					decoded:Array<Null<Image>> = [];
				function image(texture:Null<String>):Int {
					if (texture == null)
						return -1;
					var i = imagePaths.indexOf(texture);
					if (i < 0) {
						i = imagePaths.length;
						imagePaths.push(texture);
					}
					return i;
				}
				var made = [for (m in materials) material(m, image)];
				var waiting = imagePaths.length + 1;
				function done():Void {
					if (--waiting > 0 || aborted || finished)
						return;
					finished = true;
					var meshes = [], indices = [];
					for (part in file.computeParts(true)) {
						meshes.push(objMesh(file, part.cornerIndices));
						indices.push(part.materialIndex);
					}
					loaded(new Model3D(path, meshes, indices, [for (_ in meshes) -1], [for (_ in meshes) new Matrix3D()], null, [], [], made, decoded));
				}
				decoded.resize(imagePaths.length);
				for (i => texture in imagePaths)
					aborts.push(images.load(texture, image -> {
						decoded[i] = image;
						done();
					}, message -> {
						Log.warn(message, "models");
						done();
					}));
				done();
			}
			function library():Void
				if (--left == 0 && !aborted && !finished)
					textures();
			for (i => libraryPath in paths)
				aborts.push(assets.load(libraryPath, (bytes:Bytes) -> {
					libraries[i] = try MtlFile.read(bytes, libraryPath) catch (e:String) {
						Log.warn('$libraryPath: $e', "models");
						null;
					}
					library();
				}, message -> {
					Log.warn('$path: material library $message', "models");
					library();
				}));
			library();
		}, fail));
		return () -> {
			aborted = true;
			for (abort in aborts)
				abort();
		};
	}

	// An MTL material as glTF's: its diffuse color and opacity the base color, its diffuse texture the base color image, its computed
	// metalness and roughness, its normal map, and its emissive color and texture (the color white when a texture comes without one).
	// The constructor is helix-formats' own; the models are where an OBJ material is made one.

	@:access(helix.formats.gltf.GltfMaterial)
	static function material(m:MtlMaterial, image:Null<String>->Int):GltfMaterial {
		var base = image(m.diffuseTexturePath),
			normal = image(m.computeNormalTexturePath()),
			emissive = image(m.emissionTexturePath);
		var emission = [m.emission[0], m.emission[1], m.emission[2]];
		if (emissive >= 0 && emission[0] == 0 && emission[1] == 0 && emission[2] == 0)
			emission = [1, 1, 1];
		return new GltfMaterial(m.name, true, [m.diffuse[0], m.diffuse[1], m.diffuse[2], m.opacity], base, m.computeMetalness(), m.computeRoughness(), -1,
			normal, -1, emission, emissive);
	}

	// A part's triangles as a mesh: a vertex for each corner whose position, texture coordinate and normal differ, the triangles indexing
	// them; v turned to run down the image; normals made length 1, or computed when a corner has none; colors from the positions'.
	static function objMesh(file:ObjFile, corners:haxe.ds.ReadOnlyArray<Int>):Mesh3D {
		var mesh = new Mesh3D();
		var positions = [], texCoords = [], normals = [], colors = [], indices = [];
		var made = new Map<String, Int>(),
			anyTexCoords = false,
			allNormals = true;
		for (c in corners) {
			var p = file.cornerPositionIndices[c],
				t = file.cornerTexCoordIndices[c],
				n = file.cornerNormalIndices[c];
			var key = '$p/$t/$n';
			var index = made.get(key);
			if (index == null) {
				index = Std.int(positions.length / 3);
				made.set(key, index);
				for (k in 0...3)
					positions.push(file.positions[p * 3 + k]);
				if (t >= 0) {
					anyTexCoords = true;
					texCoords.push(file.texCoords[t * 2]);
					texCoords.push(1 - file.texCoords[t * 2 + 1]);
				} else {
					texCoords.push(0);
					texCoords.push(0);
				}
				if (n >= 0) {
					var x = file.normals[n * 3],
						y = file.normals[n * 3 + 1],
						z = file.normals[n * 3 + 2];
					var length = Math.sqrt(x * x + y * y + z * z);
					if (length > 0) {
						x /= length;
						y /= length;
						z /= length;
					}
					normals.push(x);
					normals.push(y);
					normals.push(z);
				} else
					allNormals = false;
				if (file.colors != null) {
					for (k in 0...3)
						colors.push(file.colors[p * 3 + k]);
					colors.push(1);
				}
			}
			indices.push(index);
		}
		mesh.positions = positions;
		mesh.indices = indices;
		mesh.texCoords = anyTexCoords ? texCoords : null;
		mesh.colors = file.colors != null ? colors : null;
		mesh.normals = allNormals ? normals : mesh.computeNormals();
		return mesh;
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
			for (child in node.childIndices)
				parents.set(child, i);
		for (skin in fileSkins)
			for (joint in skin.jointIndices) {
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
			if (node.meshIndex >= 0)
				for (primitive in all[node.meshIndex].primitives)
					if (primitive.mode == 4) {
						var mesh = new Mesh3D();
						mesh.positions = primitive.positions;
						mesh.normals = primitive.normals;
						mesh.tangents = primitive.tangents;
						mesh.texCoords = primitive.texCoords;
						mesh.colors = primitive.colors;
						mesh.indices = primitive.indices;
						var skinned = node.skinIndex >= 0 && node.skinIndex < fileSkins.length && primitive.jointIndices != null && primitive.weights != null;
						if (skinned) {
							mesh.jointIndices = primitive.jointIndices;
							mesh.weights = primitive.weights;
						}
						meshes.push(skinned ? mesh : mesh.transform(world));
						materials.push(primitive.materialIndex);
						skins.push(skinned ? node.skinIndex : -1);
						transforms.push(world);
					}
			for (child in node.childIndices)
				visit(child, world, bone);
		}
		for (root in file.sceneNodeIndices)
			visit(root, new Matrix3D(), -1);
		var skeleton = bones.length > 0 ? new Skeleton3D(bones) : null;
		var madeSkins = [
			for (skin in fileSkins)
				new Skin3D(skin.name, [for (joint in skin.jointIndices) boneOf.exists(joint) ? boneOf.get(joint) : 0], skin.inverseBindMatrices)
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
						|| !boneOf.exists(channel.nodeIndex)
						|| channel.samplerIndex < 0
						|| channel.samplerIndex >= animation.samplers.length)
						continue;
					var sampler = animation.samplers[channel.samplerIndex];
					var interpolation:KeyInterpolation = switch sampler.interpolation {
						case "STEP": Step;
						case "CUBICSPLINE": CubicSpline;
						case _: Linear;
					}
					tracks.push(new AnimationTrack3D(boneOf.get(channel.nodeIndex), property, interpolation, sampler.input, sampler.output));
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
