package helix.ray.internal;

import helix.math.Matrix3D;
import haxe.io.Bytes;
import helix.ray.*;
import helix.services.models.Model3D;
import helix.ray.raylib.RMath;
import helix.ray.raylib.RModels;

/** Makes raylib's meshes and models: a mesh's GPU buffers, and a model from what the models service read of a glTF file. */
@:noCompletion
class Models {
	/** Each of raylib's vertex buffers, by its index: the size of an element and its default, for a mesh without the attribute. A default
		is raylib 6.2's (normals 0, 0, 1; colors white; tangents 1, 0, 0, 1; second texture coordinates, bone ids and bone weights 0). Index
		6 is raylib's indices, kept apart. */
	static final SIZES = [3, 2, 3, 4, 4, 2, 0, 4, 4];

	static final DEFAULTS:Array<Array<Float>> = [
		[0, 0, 0],
		[0, 0],
		[0, 0, 1],
		[1, 1, 1, 1],
		[1, 0, 0, 1],
		[0, 0],
		[],
		[0, 0, 0, 0],
		[0, 0, 0, 0]
	];

	/** Sends a mesh's vertices to the GPU: its positions, texture coordinates, normals and colors, those it lacks as raylib's defaults, and
		its indices. Its tangents, second texture coordinates, bone ids and bone weights go when a shader first reads them (`buffer`).

		@param mesh  The mesh. */
	public static function upload(mesh:Mesh):Void {
		if (mesh.gpu.buffers != null || mesh.vertexCount == 0)
			return;
		var g = Runtime.graphics;
		mesh.gpu.buffers = [
			for (i in 0...9)
				i < 4 ? g.createStaticBuffer(bytesOf(mesh, i), mesh.vertexCount * SIZES[i] * 4, false) : 0
		];
		if (mesh.indices != null && mesh.indices.length > 0) {
			var bytes = bytesOf(mesh, 6);
			mesh.gpu.indexBuffer = g.createStaticBuffer(bytes, bytes.length, true);
		}
	}

	/** Returns one of an uploaded mesh's vertex buffers, making it first when it isn't yet.

		@param mesh  The mesh, uploaded.
		@param index  raylib's buffer index, 0 to 5, 7 or 8.
		@return  The buffer. */
	public static function buffer(mesh:Mesh, index:Int):Int {
		var buffers = mesh.gpu.buffers;
		if (buffers[index] == 0)
			buffers[index] = Runtime.graphics.createStaticBuffer(bytesOf(mesh, index), mesh.vertexCount * SIZES[index] * 4, false);
		return buffers[index];
	}

	// A buffer's bytes as the GPU takes them: the bytes UpdateMeshBuffer last left, or the mesh's numbers as 32-bit floats (colors 0 to 1),
	// those it lacks its default; the indices (6) as 32-bit integers.
	static function bytesOf(mesh:Mesh, index:Int):Bytes {
		var kept = mesh.gpu.contents[index];
		if (kept != null)
			return kept;
		if (index == 6) {
			var bytes = Bytes.alloc(mesh.indices.length * 4);
			for (i => value in mesh.indices)
				bytes.setInt32(i * 4, value);
			return bytes;
		}
		var values:Null<Array<Float>> = switch index {
			case 0: mesh.vertices;
			case 1: mesh.texcoords;
			case 2: mesh.normals;
			case 3: mesh.colors == null ? null : [for (c in mesh.colors) c / 255];
			case 4: mesh.tangents;
			case 5: mesh.texcoords2;
			case 7: mesh.boneIds == null ? null : [for (b in mesh.boneIds) (b : Float)];
			case _: mesh.boneWeights;
		}
		var size = SIZES[index],
			fallback = DEFAULTS[index],
			n = mesh.vertexCount * size;
		var bytes = Bytes.alloc(n * 4);
		for (i in 0...n)
			bytes.setFloat(i * 4, values != null && i < values.length ? values[i] : fallback[i % size]);
		return bytes;
	}

	/** Changes part of an uploaded mesh's buffer, as raylib's `UpdateMeshBuffer`: its bytes are counted as raylib lays them out (colors a
		byte each, indices two), and those of a buffer not made yet, or of a mesh not uploaded, change nothing. The buffer is made again
		with the change, so the draws asked for before it keep the old one, freed when the frame is drawn.

		@param mesh  The mesh.
		@param index  raylib's buffer index: 0 positions, 1 texture coordinates, 2 normals, 3 colors, 4 tangents, 5 second texture
			coordinates, 6 indices.
		@param values  The numbers written, as raylib's elements (colors 0 to 255).
		@param offset  Where they go, in raylib's bytes. */
	public static function update(mesh:Mesh, index:Int, values:Array<Float>, offset:Int):Void {
		var buffers = mesh.gpu.buffers;
		if (buffers == null || index < 0 || index > 6)
			return;
		if (index == 6 ? mesh.gpu.indexBuffer == 0 : buffers[index] == 0 && (index == 4 ? mesh.tangents : mesh.texcoords2) == null)
			return;
		var size = [4, 4, 4, 1, 4, 4, 2][index];
		var current = bytesOf(mesh, index);
		var bytes = current.sub(0, current.length);
		var first = Std.int(offset / size);
		for (i => value in values) {
			var at = (first + i) * 4;
			if (at + 4 > bytes.length)
				break;
			if (index == 6)
				bytes.setInt32(at, Std.int(value));
			else
				bytes.setFloat(at, index == 3 ? value / 255 : value);
		}
		mesh.gpu.contents[index] = bytes;
		var g = Runtime.graphics,
			old = index == 6 ? mesh.gpu.indexBuffer : buffers[index];
		var made = g.createStaticBuffer(bytes, bytes.length, index == 6);
		if (index == 6) {
			mesh.gpu.indexBuffer = made;
			// The edges are the old indices'; made again from the mesh's when next drawn in wire mode.
			retire(mesh.gpu, mesh.gpu.edgeBuffer);
			mesh.gpu.edgeBuffer = 0;
		} else
			buffers[index] = made;
		retire(mesh.gpu, old);
	}

	// Frees a buffer a holder no longer draws with once the frame is drawn, unless it is borrowed from the holder it was made from.
	static function retire(gpu:MeshGpu, buffer:Int):Void {
		if (buffer != 0 && !gpu.borrowed.remove(buffer))
			Runtime.frame.retire(buffer);
	}

	/** Puts an animation's positions and normals in a mesh's GPU buffers, as raylib's `UpdateModelAnimation` does: each buffer made
		again, so the draws asked for before keep the old one, freed when the frame is drawn. A mesh sharing its buffers with other loads
		of its file takes its own first (`own`), so the others don't move.

		@param mesh  The mesh.
		@param positions  The positions, x, y and z a vertex.
		@param normals  The normals, or null to leave them. */
	public static function animate(mesh:Mesh, positions:Array<Float>, normals:Null<Array<Float>>):Void {
		upload(mesh);
		if (mesh.gpu.buffers == null)
			return;
		own(mesh);
		replace(mesh, 0, positions);
		if (normals != null)
			replace(mesh, 2, normals);
	}

	// A buffer made again of numbers, as 32-bit floats, the old one retired.
	static function replace(mesh:Mesh, index:Int, values:Array<Float>):Void {
		var n = mesh.vertexCount * SIZES[index];
		var bytes = haxe.io.Bytes.alloc(n * 4);
		for (i in 0...n)
			bytes.setFloat(i * 4, i < values.length ? values[i] : 0);
		mesh.gpu.contents[index] = bytes;
		var old = mesh.gpu.buffers[index];
		mesh.gpu.buffers[index] = Runtime.graphics.createStaticBuffer(bytes, bytes.length, false);
		retire(mesh.gpu, old);
	}

	/** Gives a mesh copied from its file's first load (`load`) a holder of GPU buffers of its own, borrowing the shared one's until it
		replaces them; nothing for a mesh with its own already.

		@param mesh  The mesh, uploaded. */
	public static function own(mesh:Mesh):Void {
		var shared = mesh.gpu;
		if (!shared.shared || shared.buffers == null)
			return;
		var own = new MeshGpu();
		own.buffers = shared.buffers.copy();
		own.indexBuffer = shared.indexBuffer;
		own.edgeBuffer = shared.edgeBuffer;
		for (i => bytes in shared.contents)
			own.contents[i] = bytes;
		for (b in own.buffers.concat([own.indexBuffer, own.edgeBuffer]))
			if (b != 0)
				own.borrowed.push(b);
		mesh.gpu = own;
	}

	/** Returns an uploaded mesh's edges, as an index buffer of two indices an edge, three a triangle, made when first asked for.

		@param mesh  The mesh, uploaded.
		@return  The buffer. */
	public static function edges(mesh:Mesh):Int {
		if (mesh.gpu.edgeBuffer == 0) {
			var bytes = Bytes.alloc(mesh.triangleCount * 6 * 4), at = 0;
			for (k in 0...mesh.triangleCount) {
				var a = mesh.indices == null ? k * 3 : mesh.indices[k * 3],
					b = mesh.indices == null ? k * 3 + 1 : mesh.indices[k * 3 + 1],
					c = mesh.indices == null ? k * 3 + 2 : mesh.indices[k * 3 + 2];
				for (i in [a, b, b, c, c, a]) {
					bytes.setInt32(at, i);
					at += 4;
				}
			}
			mesh.gpu.edgeBuffer = Runtime.graphics.createStaticBuffer(bytes, bytes.length, true);
		}
		return mesh.gpu.edgeBuffer;
	}

	/** Frees a mesh's GPU buffers.

		@param mesh  The mesh. */
	public static function unload(mesh:Mesh):Void {
		var gpu = mesh.gpu;
		function dispose(b:Int):Void
			if (b != 0 && gpu.borrowed.indexOf(b) < 0)
				Runtime.graphics.disposeBuffer(b);
		if (gpu.buffers != null)
			for (b in gpu.buffers)
				dispose(b);
		dispose(gpu.indexBuffer);
		dispose(gpu.edgeBuffer);
		gpu.borrowed.resize(0);
		mesh.gpu.buffers = null;
		mesh.gpu.indexBuffer = 0;
		mesh.gpu.edgeBuffer = 0;
		for (i in 0...mesh.gpu.contents.length)
			mesh.gpu.contents[i] = null;
	}

	/** Returns raylib's default material: the default shader, a white diffuse map.

		@param shader  The default shader.
		@return  The material. */
	public static function defaultMaterial(shader:Shader):Material {
		var maps = [for (_ in 0...12) new MaterialMap(new Texture2D(), new Color(0, 0, 0, 0), 0)];
		maps[0].color = new Color(255, 255, 255, 255);
		maps[1].color = new Color(255, 255, 255, 255);
		return new Material(shader, maps);
	}

	/** Makes a raylib model of a model the models service read: material 0 raylib's default, then the file's, as raylib numbers them,
		each image a texture kept by its file's path, or the model's and the image's index for one the model holds; and its bones, as
		raylib 6.2 reads them (`skeleton`).

		@param read  The model.
		@param shader  The default shader.
		@param attached  Each mesh's bone when its node is a child of one and it has no joints of its own, or -1; null for none.
		@return  The model. */
	static function fromModel3D(read:Model3D, shader:Shader, attached:Null<Array<Int>>):Model {
		var textures = new Map<Int, Texture2D>();
		function texture(index:Int):Texture2D {
			if (textures.exists(index))
				return textures.get(index);
			var image = read.images[index];
			var made = image == null ? new Texture2D() : new Texture2D(Textures.fromImage(image.path != "" ? image.path : '${read.path}#$index', image),
				image.width, image.height);
			textures.set(index, made);
			return made;
		}
		var materials = [defaultMaterial(shader)];
		for (m in read.materials) {
			var material = defaultMaterial(shader), factor = m.baseColorFactor;
			material.maps[0].color = new Color(Std.int(factor[0] * 255), Std.int(factor[1] * 255), Std.int(factor[2] * 255), Std.int(factor[3] * 255));
			if (m.baseColorImage >= 0)
				material.maps[0].texture = texture(m.baseColorImage);
			materials.push(material);
		}
		var meshes = [], meshMaterial = [];
		for (i => found in read.meshes) {
			// raylib puts every mesh's node's transform into its vertices, a skinned mesh's too.
			var m = read.meshSkins[i] >= 0 ? found.transform(read.meshTransforms[i]) : found;
			var mesh = new Mesh();
			mesh.vertexCount = m.vertexCount;
			mesh.vertices = m.positions;
			mesh.normals = m.normals;
			mesh.tangents = m.tangents;
			mesh.texcoords = m.texCoords;
			if (m.colors != null)
				mesh.colors = [for (c in m.colors) Std.int(c * 255)];
			mesh.indices = m.indices;
			mesh.triangleCount = m.triangleCount;
			meshes.push(mesh);
			meshMaterial.push(read.meshMaterials[i] + 1);
		}
		// Its meshes go to the GPU when first drawn.
		var model = new Model(meshes, materials, meshMaterial);
		skeleton(model, read, attached);
		return model;
	}

	// raylib 6.2's LoadGLTF's skin part: the first skin's joints as the bones, each parent the nearest joint above it; the bind pose each
	// inverse bind matrix inverted, or the joint's world transform at rest when the file gives none (the models service gives identities
	// then, so a skin whose matrices are all exactly identity is taken as one without); each mesh's joints and weights as its bone ids
	// and weights (a joint above 255 cut to a byte, with raylib's warning), a mesh without joints on a bone's child all that bone's.
	static function skeleton(model:Model, read:Model3D, attached:Null<Array<Int>>):Void {
		var bones = read.skeleton;
		if (bones == null || read.skins.length == 0)
			return;
		var skin = read.skins[0], joints = skin.bones;
		model.boneCount = joints.length;
		model.bones = [
			for (b in joints) {
				var parent = -1, above = bones.bones[b].parent;
				while (above >= 0 && parent < 0) {
					parent = joints.indexOf(above);
					above = bones.bones[above].parent;
				}
				new BoneInfo(boneName(bones.bones[b].name), parent);
			}
		];
		var identity = new Matrix3D(), given = false;
		for (m in skin.inverseBinds)
			for (k in 0...16)
				if (m.values[k] != identity.values[k])
					given = true;
		// raylib reads the matrices when there are as many as joints.
		if (skin.inverseBinds.length < joints.length)
			given = false;
		var world = given ? null : bones.computeWorld(bones.computeRestPose());
		model.bindPose = [
			for (i => b in joints) {
				var bind = world == null ? RMath.MatrixInvert(RModels.toMatrix(skin.inverseBinds[i])) : RModels.toMatrix(world[b]);
				var pose = new Transform();
				RMath.MatrixDecompose(bind, pose.translation, pose.rotation, pose.scale);
				pose;
			}
		];
		if (read.skins.length > 1)
			Runtime.log(4, 'MODEL: [${read.path}] can only load one skin (armature) per model, but gltf skins_count == ${read.skins.length}');
		var warned = false;
		for (i => mesh in model.meshes) {
			var m = read.meshes[i];
			if (m.joints != null && m.weights != null) {
				mesh.boneIds = [
					for (j in m.joints) {
						if (j > 255 && !warned) {
							Runtime.log(4, 'MODEL: [${read.path}] Joint attribute data format (u16) overflow');
							warned = true;
						}
						j & 255;
					}
				];
				mesh.boneWeights = m.weights;
			} else if (attached != null && attached[i] >= 0) {
				mesh.boneIds = [for (k in 0...mesh.vertexCount * 4) k % 4 == 0 ? attached[i] : 0];
				mesh.boneWeights = [for (k in 0...mesh.vertexCount * 4) k % 4 == 0 ? 1 : 0];
			}
		}
		animated(model);
	}

	// A model's pose and bone matrices, at rest: raylib 6.2's currentPose zeros, its matrices identities, every mesh's boneMatrices
	// those (raylib 5.5 gives each mesh of a skinned model its own).
	static function animated(model:Model):Void {
		if (model.boneCount == 0)
			return;
		model.pose = [for (_ in 0...model.boneCount) new Transform()];
		model.boneMatrices = [
			for (_ in 0...model.boneCount)
				new Matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
		];
		for (mesh in model.meshes) {
			mesh.boneCount = model.boneCount;
			mesh.boneMatrices = model.boneMatrices;
		}
	}

	/** Returns a name as raylib's 32 bytes hold it: its first 31 bytes, in UTF-8.

		@param name  The name.
		@return  The name, cut. */
	public static function boneName(name:String):String {
		var bytes = Bytes.ofString(name);
		return bytes.length <= 31 ? name : bytes.getString(0, 31);
	}

	/** Keeps a model the models service read, as its file's first load, unless one is kept already.

		@param read  The model.
		@param shader  The default shader.
		@param attached  Optional. Each mesh's bone when its node is a child of one and it has no joints of its own, or -1. */
	public static function keep(read:Model3D, shader:Shader, ?attached:Array<Int>):Void {
		if (!loaded.exists(read.path))
			loaded.set(read.path, {model: fromModel3D(read, shader, attached), refs: 0});
	}

	/** Returns whether a file's model is kept, so a load of it needs no read.

		@param path  The file.
		@return  True when it is. */
	public static function isKept(path:String):Bool
		return loaded.exists(path);

	static final loaded = new Map<String, {model:Model, refs:Int}>();

	/** Returns a model loaded from a file: a copy of its first load (`keep`), sharing its meshes' GPU buffers and its textures, with
		materials of its own, so one load's changes don't reach another's.

		@param path  The file.
		@return  The model, or null when none is kept. */
	public static function load(path:String):Null<Model> {
		var entry = loaded.get(path);
		if (entry == null)
			return null;
		entry.refs++;
		var original = entry.model;
		var meshes = [for (m in original.meshes) copyMesh(m)];
		var materials = [
			for (m in original.materials)
				new Material(m.shader, [
					for (map in m.maps)
						new MaterialMap(new Texture2D(map.texture.id, map.texture.width, map.texture.height),
							new Color(map.color.r, map.color.g, map.color.b, map.color.a), map.value)
				], m.params.copy())
		];
		var model = new Model(meshes, materials, original.meshMaterial.copy());
		model.path = path;
		if (original.bones != null) {
			model.boneCount = original.boneCount;
			model.bones = [for (b in original.bones) new BoneInfo(b.name, b.parent)];
			model.bindPose = [for (t in original.bindPose) copyTransform(t)];
			animated(model);
		}
		return model;
	}

	/** Releases one load of a file's model, freeing its meshes' GPU buffers and its textures with the last.

		@param model  The model. */
	public static function release(model:Model):Void {
		var entry = loaded.get(model.path);
		if (entry == null)
			return;
		// A mesh an animation moved has buffers of its own.
		for (mesh in model.meshes)
			if (!mesh.gpu.shared)
				unload(mesh);
		if (--entry.refs > 0)
			return;
		loaded.remove(model.path);
		for (mesh in entry.model.meshes)
			unload(mesh);
		for (m in entry.model.materials)
			for (map in m.maps)
				if (map.texture.id != 0)
					Textures.release(map.texture.id);
	}

	static function copyMesh(m:Mesh):Mesh {
		var mesh = new Mesh();
		mesh.vertexCount = m.vertexCount;
		mesh.triangleCount = m.triangleCount;
		mesh.vertices = m.vertices;
		mesh.texcoords = m.texcoords;
		mesh.texcoords2 = m.texcoords2;
		mesh.normals = m.normals;
		mesh.tangents = m.tangents;
		mesh.colors = m.colors;
		mesh.indices = m.indices;
		mesh.boneIds = m.boneIds;
		mesh.boneWeights = m.boneWeights;
		m.gpu.shared = true;
		mesh.gpu = m.gpu;
		return mesh;
	}

	/** Returns a copy of a transform, its parts new.

		@param t  The transform.
		@return  The copy. */
	public static function copyTransform(t:Transform):Transform {
		return new Transform(new Vector3(t.translation.x, t.translation.y, t.translation.z),
			new Quaternion(t.rotation.x, t.rotation.y, t.rotation.z, t.rotation.w), new Vector3(t.scale.x, t.scale.y, t.scale.z));
	}
}
