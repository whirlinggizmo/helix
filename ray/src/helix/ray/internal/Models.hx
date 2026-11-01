package helix.ray.internal;

import helix.math.Matrix3D;
import haxe.io.Bytes;
import helix.ray.*;
import helix.services.models.Model3D;

/** Makes raylib's meshes and models: a mesh's GPU buffers, and a model from what the models service read of a glTF file. */
@:noCompletion
class Models {
	/** Each of raylib's vertex buffers, by its index: the size of an element and its default, for a mesh without the attribute. A default
		is raylib's (normals 1, 1, 1; colors white; tangents and second texture coordinates 0). */
	static final SIZES = [3, 2, 3, 4, 4, 2];

	static final DEFAULTS:Array<Array<Float>> = [[0, 0, 0], [0, 0], [1, 1, 1], [1, 1, 1, 1], [0, 0, 0, 0], [0, 0]];

	/** Sends a mesh's vertices to the GPU: its positions, texture coordinates, normals and colors, those it lacks as raylib's defaults, and
		its indices. Its tangents and second texture coordinates go when a shader first reads them (`buffer`).

		@param mesh  The mesh. */
	public static function upload(mesh:Mesh):Void {
		if (mesh.gpu.buffers != null || mesh.vertexCount == 0)
			return;
		var g = Runtime.graphics;
		mesh.gpu.buffers = [
			for (i in 0...6)
				i < 4 ? g.createStaticBuffer(bytesOf(mesh, i), mesh.vertexCount * SIZES[i] * 4, false) : 0
		];
		if (mesh.indices != null && mesh.indices.length > 0) {
			var bytes = bytesOf(mesh, 6);
			mesh.gpu.indexBuffer = g.createStaticBuffer(bytes, bytes.length, true);
		}
	}

	/** Returns one of an uploaded mesh's vertex buffers, making it first when it isn't yet.

		@param mesh  The mesh, uploaded.
		@param index  raylib's buffer index, 0 to 5.
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
			case _: mesh.texcoords2;
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
		if (index == 6)
			mesh.gpu.indexBuffer = made;
		else
			buffers[index] = made;
		if (old != 0)
			Runtime.frame.retire(old);
	}

	/** Frees a mesh's GPU buffers.

		@param mesh  The mesh. */
	public static function unload(mesh:Mesh):Void {
		if (mesh.gpu.buffers != null)
			for (b in mesh.gpu.buffers)
				if (b != 0)
					Runtime.graphics.disposeBuffer(b);
		if (mesh.gpu.indexBuffer != 0)
			Runtime.graphics.disposeBuffer(mesh.gpu.indexBuffer);
		mesh.gpu.buffers = null;
		mesh.gpu.indexBuffer = 0;
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
		each image a texture kept by its file's path, or the model's and the image's index for one the model holds.

		@param read  The model.
		@param shader  The default shader.
		@return  The model. */
	static function fromModel3D(read:Model3D, shader:Shader):Model {
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
		for (i => m in read.meshes) {
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
		return new Model(meshes, materials, meshMaterial);
	}

	/** Keeps a model the models service read, as its file's first load, unless one is kept already.

		@param read  The model.
		@param shader  The default shader. */
	public static function keep(read:Model3D, shader:Shader):Void {
		if (!loaded.exists(read.path))
			loaded.set(read.path, {model: fromModel3D(read, shader), refs: 0});
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
		return model;
	}

	/** Releases one load of a file's model, freeing its meshes' GPU buffers and its textures with the last.

		@param model  The model. */
	public static function release(model:Model):Void {
		var entry = loaded.get(model.path);
		if (entry == null || --entry.refs > 0)
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
		mesh.gpu = m.gpu;
		return mesh;
	}
}
