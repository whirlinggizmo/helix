package helix.ray.internal;

import haxe.io.Bytes;
import helix.ray.*;

/** Makes raylib's meshes and models: a mesh's GPU buffers, a model from a glTF file (its nodes' transforms put into its meshes, as
	raylib does), and the meshes raylib generates. */
@:noCompletion
class Models {
	/** Sends a mesh's vertices to the GPU, those it lacks as raylib's defaults (no texture coordinates, normals facing +z, white).

		@param mesh  The mesh. */
	public static function upload(mesh:Mesh):Void {
		var g = Runtime.graphics, n = mesh.vertexCount;
		if (mesh.buffers != null || n == 0)
			return;
		function floats(values:Null<Array<Float>>, size:Int, fallback:Array<Float>):Int {
			var bytes = Bytes.alloc(n * size * 4);
			for (i in 0...n * size)
				bytes.setFloat(i * 4, values != null && i < values.length ? values[i] : fallback[i % size]);
			return g.createStaticBuffer(bytes, bytes.length, false);
		}
		var colors:Null<Array<Float>> = mesh.colors == null ? null : [for (c in mesh.colors) c / 255];
		mesh.buffers = [
			floats(mesh.vertices, 3, [0, 0, 0]),
			floats(mesh.texcoords, 2, [0, 0]),
			floats(mesh.normals, 3, [0, 0, 1]),
			floats(colors, 4, [1, 1, 1, 1])
		];
		if (mesh.indices != null && mesh.indices.length > 0) {
			var bytes = Bytes.alloc(mesh.indices.length * 4);
			for (i => index in mesh.indices)
				bytes.setInt32(i * 4, index);
			mesh.indexBuffer = g.createStaticBuffer(bytes, bytes.length, true);
		}
	}

	/** Frees a mesh's GPU buffers.

		@param mesh  The mesh. */
	public static function unload(mesh:Mesh):Void {
		if (mesh.buffers != null)
			for (b in mesh.buffers)
				Runtime.graphics.disposeBuffer(b);
		if (mesh.indexBuffer != 0)
			Runtime.graphics.disposeBuffer(mesh.indexBuffer);
		mesh.buffers = null;
		mesh.indexBuffer = 0;
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

	/** Reads a glTF or GLB file as a model: material 0 raylib's default, then the file's, as raylib numbers them.

		@param path  The file, as the program names it.
		@param bytes  Its bytes.
		@param shader  The default shader.
		@return  The model. */
	public static function gltf(path:String, bytes:Bytes, shader:Shader):Model {
		var file = Gltf.read(bytes);
		var directory = haxe.io.Path.directory(path);
		for (missing in file.missingBuffers) {
			var other = Runtime.files.get(directory == "" ? missing.uri : directory + "/" + missing.uri);
			if (other != null)
				file.setBuffer(missing.index, other);
		}
		var textures = new Map<Int, Texture2D>();
		function texture(index:Int):Texture2D {
			if (textures.exists(index))
				return textures.get(index);
			var t = Gltf.field(file.list("textures")[index], "source");
			var image = Runtime.images.get(imageKey(path, file, t));
			var made = image == null ? new Texture2D() : new Texture2D(Runtime.graphics.createTexture(image.width, image.height, [image.pixels]), image.width,
				image.height);
			textures.set(index, made);
			return made;
		}
		var materials = [defaultMaterial(shader)];
		for (m in file.list("materials")) {
			var material = defaultMaterial(shader);
			var pbr = Gltf.field(m, "pbrMetallicRoughness");
			var factor:Array<Float> = Gltf.field(pbr, "baseColorFactor");
			if (factor != null)
				material.maps[0].color = new Color(Std.int(factor[0] * 255), Std.int(factor[1] * 255), Std.int(factor[2] * 255), Std.int(factor[3] * 255));
			var base = Gltf.field(pbr, "baseColorTexture");
			if (base != null)
				material.maps[0].texture = texture(Gltf.field(base, "index"));
			materials.push(material);
		}
		var meshes = [], meshMaterial = [];
		var nodes = file.list("nodes");
		function visit(index:Int, parent:Array<Float>):Void {
			var node = nodes[index];
			var world = Matrices.multiply(local(node), parent);
			var m:Null<Int> = Gltf.field(node, "mesh");
			if (m != null)
				for (primitive in (Gltf.field(file.list("meshes")[m], "primitives") : Array<Dynamic>)) {
					var mode:Null<Int> = Gltf.field(primitive, "mode");
					if (mode != null && mode != 4)
						continue;
					meshes.push(primitiveMesh(file, primitive, world));
					var material:Null<Int> = Gltf.field(primitive, "material");
					meshMaterial.push(material == null ? 0 : material + 1);
				}
			var children:Array<Int> = Gltf.field(node, "children");
			if (children != null)
				for (c in children)
					visit(c, world);
		}
		var scenes = file.list("scenes");
		var sceneIndex:Null<Int> = Gltf.field(file.document, "scene");
		var roots:Array<Int> = scenes.length > 0 ? Gltf.field(scenes[sceneIndex == null ? 0 : sceneIndex], "nodes") : null;
		if (roots == null) {
			var children = new Map<Int, Bool>();
			for (node in nodes) {
				var c:Array<Int> = Gltf.field(node, "children");
				if (c != null)
					for (i in c)
						children.set(i, true);
			}
			roots = [for (i in 0...nodes.length) if (!children.exists(i)) i];
		}
		for (r in roots)
			visit(r, Matrices.identity());
		for (mesh in meshes)
			upload(mesh);
		return new Model(meshes, materials, meshMaterial);
	}

	/** Returns the key a glTF file's image is decoded under before `main`: its own file's path, or the file and the image's index.

		@param path  The glTF file.
		@param file  The file, read.
		@param image  The image's index.
		@return  The key. */
	public static function imageKey(path:String, file:Gltf, image:Int):String {
		var info = file.list("images")[image];
		var uri:String = Gltf.field(info, "uri");
		if (uri != null && !StringTools.startsWith(uri, "data:")) {
			var directory = haxe.io.Path.directory(path);
			return directory == "" ? uri : directory + "/" + uri;
		}
		return '$path#$image';
	}

	/** Returns an image of a glTF file held in it (a buffer view or a data: URI), or null for one in a file of its own.

		@param file  The file.
		@param image  The image's index.
		@return  Its encoded bytes. */
	public static function imageBytes(file:Gltf, image:Int):Null<Bytes> {
		var info = file.list("images")[image];
		var view:Null<Int> = Gltf.field(info, "bufferView");
		if (view != null)
			return file.viewBytes(view);
		var uri:String = Gltf.field(info, "uri");
		return uri != null && StringTools.startsWith(uri, "data:") ? Gltf.dataUri(uri) : null;
	}

	// A node's own transform: its matrix, or its scale, then rotation, then translation.
	static function local(node:Dynamic):Array<Float> {
		var matrix:Array<Float> = Gltf.field(node, "matrix");
		if (matrix != null)
			return matrix.copy();
		var s:Array<Float> = Gltf.field(node, "scale"),
			r:Array<Float> = Gltf.field(node, "rotation"),
			t:Array<Float> = Gltf.field(node, "translation");
		var m = s == null ? Matrices.identity() : Matrices.scale(s[0], s[1], s[2]);
		if (r != null)
			m = Matrices.multiply(m, Matrices.quaternion(r[0], r[1], r[2], r[3]));
		if (t != null)
			m = Matrices.multiply(m, Matrices.translate(t[0], t[1], t[2]));
		return m;
	}

	// One primitive as a mesh, its node's transform put into its positions and normals.
	static function primitiveMesh(file:Gltf, primitive:Dynamic, world:Array<Float>):Mesh {
		var attributes = Gltf.field(primitive, "attributes");
		var mesh = new Mesh();
		var positions = file.floats(Gltf.field(attributes, "POSITION"));
		mesh.vertexCount = Std.int(positions.length / 3);
		mesh.vertices = [];
		for (i in 0...mesh.vertexCount)
			for (v in Matrices.point(world, positions[i * 3], positions[i * 3 + 1], positions[i * 3 + 2]))
				mesh.vertices.push(v);
		var normal:Null<Int> = Gltf.field(attributes, "NORMAL");
		if (normal != null) {
			var normals = file.floats(normal),
				turn = Matrices.transpose(Matrices.invert(world));
			mesh.normals = [];
			for (i in 0...mesh.vertexCount) {
				var x = normals[i * 3],
					y = normals[i * 3 + 1],
					z = normals[i * 3 + 2];
				var nx = turn[0] * x + turn[4] * y + turn[8] * z,
					ny = turn[1] * x + turn[5] * y + turn[9] * z,
					nz = turn[2] * x + turn[6] * y + turn[10] * z;
				var l = Math.sqrt(nx * nx + ny * ny + nz * nz);
				if (l == 0)
					l = 1;
				mesh.normals.push(nx / l);
				mesh.normals.push(ny / l);
				mesh.normals.push(nz / l);
			}
		}
		var uv:Null<Int> = Gltf.field(attributes, "TEXCOORD_0");
		if (uv != null)
			mesh.texcoords = file.floats(uv);
		var color:Null<Int> = Gltf.field(attributes, "COLOR_0");
		if (color != null) {
			var values = file.floats(color),
				size = Std.int(values.length / mesh.vertexCount);
			mesh.colors = [];
			for (i in 0...mesh.vertexCount)
				for (c in 0...4)
					mesh.colors.push(c < size ? Std.int(values[i * size + c] * 255) : 255);
		}
		var indices:Null<Int> = Gltf.field(primitive, "indices");
		if (indices != null)
			mesh.indices = file.ints(indices);
		mesh.triangleCount = Std.int((mesh.indices != null ? mesh.indices.length : mesh.vertexCount) / 3);
		return mesh;
	}

	/** Returns raylib's `GenMeshCube`. */
	public static function cube(width:Float, height:Float, length:Float):Mesh {
		var x = width / 2, y = height / 2, z = length / 2;
		// Each face: its normal, then its corners counterclockwise from outside, as raylib's.
		var faces:Array<Array<Float>> = [
			[0, 0, 1, -x, -y, z, x, -y, z, x, y, z, -x, y, z],
			[0, 0, -1, -x, -y, -z, -x, y, -z, x, y, -z, x, -y, -z],
			[0, 1, 0, -x, y, -z, -x, y, z, x, y, z, x, y, -z],
			[0, -1, 0, -x, -y, -z, x, -y, -z, x, -y, z, -x, -y, z],
			[1, 0, 0, x, -y, -z, x, y, -z, x, y, z, x, -y, z],
			[-1, 0, 0, -x, -y, -z, -x, -y, z, -x, y, z, -x, y, -z]
		];
		var mesh = new Mesh();
		mesh.vertices = [];
		mesh.normals = [];
		mesh.texcoords = [];
		mesh.indices = [];
		var uvs = [0., 0, 1, 0, 1, 1, 0, 1];
		for (f => face in faces) {
			for (c in 0...4) {
				mesh.vertices.push(face[3 + c * 3]);
				mesh.vertices.push(face[4 + c * 3]);
				mesh.vertices.push(face[5 + c * 3]);
				mesh.normals.push(face[0]);
				mesh.normals.push(face[1]);
				mesh.normals.push(face[2]);
				mesh.texcoords.push(uvs[c * 2]);
				mesh.texcoords.push(1 - uvs[c * 2 + 1]);
			}
			var b = f * 4;
			for (i in [0, 1, 2, 0, 2, 3])
				mesh.indices.push(b + i);
		}
		mesh.vertexCount = 24;
		mesh.triangleCount = 12;
		upload(mesh);
		return mesh;
	}

	/** Returns raylib's `GenMeshPlane`: on the XZ plane, facing up. */
	public static function plane(width:Float, length:Float, resX:Int, resZ:Int):Mesh {
		if (resX < 1)
			resX = 1;
		if (resZ < 1)
			resZ = 1;
		var mesh = new Mesh();
		mesh.vertices = [];
		mesh.normals = [];
		mesh.texcoords = [];
		mesh.indices = [];
		for (j in 0...resZ + 1)
			for (i in 0...resX + 1) {
				mesh.vertices.push(i / resX * width - width / 2);
				mesh.vertices.push(0);
				mesh.vertices.push(j / resZ * length - length / 2);
				mesh.normals.push(0);
				mesh.normals.push(1);
				mesh.normals.push(0);
				mesh.texcoords.push(i / resX);
				mesh.texcoords.push(j / resZ);
			}
		for (j in 0...resZ)
			for (i in 0...resX) {
				var a = j * (resX + 1) + i, b = a + 1, c = a + resX + 1, d = c + 1;
				for (k in [a, c, b, b, c, d])
					mesh.indices.push(k);
			}
		mesh.vertexCount = (resX + 1) * (resZ + 1);
		mesh.triangleCount = resX * resZ * 2;
		upload(mesh);
		return mesh;
	}

	/** Returns raylib's `GenMeshSphere`. */
	public static function sphere(radius:Float, rings:Int, slices:Int):Mesh {
		if (rings < 3)
			rings = 3;
		if (slices < 3)
			slices = 3;
		var mesh = new Mesh();
		mesh.vertices = [];
		mesh.normals = [];
		mesh.texcoords = [];
		mesh.indices = [];
		for (r in 0...rings + 1) {
			var phi = Math.PI * r / rings;
			for (s in 0...slices + 1) {
				var theta = Math.PI * 2 * s / slices;
				var x = Math.sin(phi) * Math.cos(theta),
					y = Math.cos(phi),
					z = Math.sin(phi) * Math.sin(theta);
				mesh.vertices.push(x * radius);
				mesh.vertices.push(y * radius);
				mesh.vertices.push(z * radius);
				mesh.normals.push(x);
				mesh.normals.push(y);
				mesh.normals.push(z);
				mesh.texcoords.push(s / slices);
				mesh.texcoords.push(r / rings);
			}
		}
		for (r in 0...rings)
			for (s in 0...slices) {
				var a = r * (slices + 1) + s, b = a + slices + 1;
				for (k in [a, a + 1, b, b, a + 1, b + 1])
					mesh.indices.push(k);
			}
		mesh.vertexCount = (rings + 1) * (slices + 1);
		mesh.triangleCount = rings * slices * 2;
		upload(mesh);
		return mesh;
	}

	/** Returns a mesh's bounds, as raylib's `GetMeshBoundingBox`. */
	public static function bounds(mesh:Mesh):BoundingBox {
		var v = mesh.vertices;
		if (v == null || v.length < 3)
			return new BoundingBox(new Vector3(), new Vector3());
		var min = [v[0], v[1], v[2]], max = [v[0], v[1], v[2]];
		var i = 3;
		while (i + 2 < v.length) {
			for (c in 0...3) {
				if (v[i + c] < min[c])
					min[c] = v[i + c];
				if (v[i + c] > max[c])
					max[c] = v[i + c];
			}
			i += 3;
		}
		return new BoundingBox(new Vector3(min[0], min[1], min[2]), new Vector3(max[0], max[1], max[2]));
	}
}
