package helix.raylib.internal;

import helix.math.Matrix3D;
import haxe.io.Bytes;
import helix.raylib.*;
import helix.formats.gltf.GltfMaterial;
import helix.services.models.Model3D;
import helix.raylib.modules.RMath;
import helix.raylib.modules.RModels;

/** Makes raylib's meshes and models: a mesh's GPU buffers, and a model from what the models service read of a glTF file, or from an
	OBJ file's meshes and materials (`ObjModels`). */
@:noCompletion
class Models {
	/** Each of raylib's vertex buffers, by its index: the size of an element and its default, for a mesh without the attribute. A default
		is raylib 6.2's (normals 0, 0, 1; colors white; tangents 1, 0, 0, 1; second texture coordinates, bone ids and bone weights 0). Index
		6 is raylib's indices, kept apart. Each number is a 32-bit float on the GPU but a color's, a byte as raylib's (`bytesOf`). */
	static final SIZES = [3, 2, 3, 4, 4, 2, 0, 4, 4];

	static final DEFAULTS:Array<Array<Float>> = [
		[0, 0, 0],
		[0, 0],
		[0, 0, 1],
		[255, 255, 255, 255],
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
		if (!restoring) {
			restoring = true;
			Runtime.restoring.push(graphicsRestored);
		}
		if (!uploaded.contains(mesh.gpu))
			uploaded.push(mesh.gpu);
		mesh.gpu.buffers = [
			for (i in 0...9)
				i < 4 ? g.createStaticBuffer(bytesOf(mesh, i), bufferBytes(mesh, i), false) : 0
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
			buffers[index] = Runtime.graphics.createStaticBuffer(bytesOf(mesh, index), bufferBytes(mesh, index), false);
		return buffers[index];
	}

	// The bytes of one of a mesh's vertex buffers on the GPU: 32-bit floats, a color's numbers a byte each as raylib's.
	static function bufferBytes(mesh:Mesh, index:Int):Int
		return mesh.vertexCount * SIZES[index] * (index == 3 ? 1 : 4);

	// A buffer's bytes as the GPU takes them: the bytes UpdateMeshBuffer last left, or the mesh's numbers as 32-bit floats (colors a byte
	// each, as raylib's, read as UByte4Norm), those it lacks its default; the indices (6) as 32-bit integers.
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
			case 3: mesh.colors == null ? null : [for (c in mesh.colors) (c : Float)];
			case 4: mesh.tangents;
			case 5: mesh.texcoords2;
			case 7: mesh.boneIds == null ? null : [for (b in mesh.boneIds) (b : Float)];
			case _: mesh.boneWeights;
		}
		var size = SIZES[index],
			fallback = DEFAULTS[index],
			n = mesh.vertexCount * size;
		var bytes = Bytes.alloc(bufferBytes(mesh, index));
		for (i in 0...n) {
			var value = values != null && i < values.length ? values[i] : fallback[i % size];
			if (index == 3)
				bytes.set(i, Std.int(value));
			else
				bytes.setFloat(i * 4, value);
		}
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
		// A color's numbers are bytes on the GPU as in raylib's buffer, written where raylib writes them; the rest 32-bit.
		var width = index == 3 ? 1 : 4;
		for (i => value in values) {
			var at = (first + i) * width;
			if (at + width > bytes.length)
				break;
			if (index == 6)
				bytes.setInt32(at, Std.int(value));
			else if (index == 3)
				bytes.set(at, Std.int(value));
			else
				bytes.setFloat(at, value);
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

	// Frees a buffer a holder no longer draws with once the frame is drawn.
	static function retire(gpu:MeshGpu, buffer:Int):Void {
		if (buffer != 0)
			Runtime.frame.retire(buffer);
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

	/** Takes one more holder of a mesh: a model it is put in.

		@param mesh  The mesh, or null for nothing. */
	public static function retainMesh(mesh:Null<Mesh>):Void
		if (mesh != null && mesh.refs > 0)
			mesh.refs++;

	/** Releases one of a mesh's holders (the program's, or a model's), freeing its GPU buffers when it was the last: those it shares with
		its file's other loads when it was the last mesh using them. A mesh already at 0 stays there.

		@param mesh  The mesh, or null for nothing. */
	public static function releaseMesh(mesh:Null<Mesh>):Void {
		if (mesh == null || mesh.refs <= 0 || --mesh.refs > 0)
			return;
		freeGpu(mesh.gpu);
		mesh.gpu = new MeshGpu();
	}

	// Every holder of GPU buffers sent, until freed: what a restore forgets; and whether graphicsRestored is in Runtime.restoring, put
	// there as the first mesh is sent.
	static final uploaded:Array<MeshGpu> = [];
	static var restoring = false;

	/** Forgets every mesh's GPU buffers after the GPU's context was lost and given back (`Event.GraphicsRestored`): static buffers are
		gone with it, so each mesh is sent again when next drawn (`upload`), from its vertices and the bytes `UpdateMeshBuffer` left
		(`MeshGpu.contents`). */
	public static function graphicsRestored():Void {
		for (gpu in uploaded) {
			gpu.buffers = null;
			gpu.indexBuffer = 0;
			gpu.edgeBuffer = 0;
		}
		uploaded.resize(0);
	}

	// Lets go of a mesh's hold on a holder of GPU buffers, freeing them when it was the last.
	static function freeGpu(gpu:MeshGpu):Void {
		if (--gpu.holders > 0)
			return;
		uploaded.remove(gpu);
		function dispose(b:Int):Void
			if (b != 0)
				Runtime.graphics.disposeBuffer(b);
		if (gpu.buffers != null)
			for (b in gpu.buffers)
				dispose(b);
		dispose(gpu.indexBuffer);
		dispose(gpu.edgeBuffer);
		gpu.buffers = null;
		gpu.indexBuffer = 0;
		gpu.edgeBuffer = 0;
		for (i in 0...gpu.contents.length)
			gpu.contents[i] = null;
	}

	/** Takes one more holder of a material: a model it is put in.

		@param material  The material, or null for nothing. */
	public static function retainMaterial(material:Null<Material>):Void
		if (material != null && material.refs > 0)
			material.refs++;

	/** Releases one of a material's holders (the program's, or a model's): when it was the last, its maps let go of their textures and it
		of its shader, as raylib's `UnloadMaterial` frees them, each freed when nothing else holds it. A material already at 0 stays there.

		@param material  The material, or null for nothing. */
	public static function releaseMaterial(material:Null<Material>):Void {
		if (material == null || material.refs <= 0 || --material.refs > 0)
			return;
		if (material.shader != null)
			releaseShader(material.shader);
		if (material.maps != null)
			for (map in material.maps)
				releaseTexture(map.texture);
	}

	/** Lets go of a map's hold on its texture, unless `UnloadTexture` let go of it already (`Texture2D.spent`): its id set to 0 when the
		texture is gone. The default texture and none are left.

		@param texture  The map's texture. */
	public static function releaseTexture(texture:Texture2D):Void {
		if (texture.id == 0 || texture.id == Textures.DEFAULT || texture.spent)
			return;
		if (Textures.release(texture.id))
			texture.id = 0;
	}

	/** Lets go of the program's hold on a texture (`UnloadTexture`), its id set to 0. Given a map's copy (`Texture2D.mapped`), it lets
		go of one of the program's holds when there is one, else of the map's, and leaves the id while the texture lives, as the map still
		draws it.

		@param texture  The texture. */
	public static function unloadTexture(texture:Texture2D):Void {
		if (texture.id == 0 || texture.spent)
			return;
		if (texture.id == Textures.DEFAULT) {
			if (!texture.mapped)
				texture.id = 0;
			return;
		}
		if (!texture.mapped) {
			Textures.releaseHeld(texture.id);
			texture.id = 0;
		} else if (Textures.isHeld(texture.id)) {
			if (Textures.releaseHeld(texture.id))
				texture.id = 0;
		} else {
			texture.spent = true;
			if (Textures.release(texture.id))
				texture.id = 0;
		}
	}

	/** Takes one more holder of a shader: a material given it. The default shader isn't counted.

		@param shader  The shader. */
	public static function retainShader(shader:Shader):Void
		if (shader.program != null && shader.program != Runtime.frame.defaultProgram && shader.program.refs > 0)
			shader.program.refs++;

	/** Lets go of a material's hold on its shader, unless `UnloadShader` let go of it already (`Shader.spent`), freeing the program
		when it was the last holder. The default shader is never freed.

		@param shader  The material's shader. */
	public static function releaseShader(shader:Shader):Void
		if (!shader.spent)
			dropShader(shader, false);

	/** Lets go of the program's hold on a shader (`UnloadShader`): given a material's copy (`Shader.mapped`), one of the program's holds
		when there is one, else the material's. Its id and program are cleared when it is the program's own record or the program is
		freed. The default shader stays.

		@param shader  The shader. */
	public static function unloadShader(shader:Shader):Void {
		if (shader.spent)
			return;
		var p = shader.program;
		if (p == null || p == Runtime.frame.defaultProgram)
			return;
		var held = !shader.mapped || p.held > 0;
		if (!held)
			shader.spent = true;
		dropShader(shader, held);
		if (!shader.mapped) {
			shader.program = null;
			shader.id = 0;
		}
	}

	// One hold on a shader's program let go of, the program's own when held, the program freed and the record cleared at 0.
	static function dropShader(shader:Shader, held:Bool):Void {
		var p = shader.program;
		if (p == null || p == Runtime.frame.defaultProgram || p.refs <= 0)
			return;
		if (held && p.held > 0)
			p.held--;
		if (--p.refs > 0)
			return;
		p.dispose();
		shader.program = null;
		shader.id = 0;
	}

	/** Returns raylib's default material, as raylib 5.5's `LoadMaterialDefault`: the default shader, the diffuse map raylib's default
		texture (`Textures.DEFAULT`, a 1x1 white pixel), the diffuse and specular colors white, the rest of the maps empty.

		@param shader  The default shader.
		@return  The material. */
	public static function defaultMaterial(shader:Shader):Material {
		var maps = [for (_ in 0...12) new MaterialMap(new Texture2D(), new Color(0, 0, 0, 0), 0)];
		maps[0].texture = new Texture2D(Textures.DEFAULT, 1, 1, 1, Raylib.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
		maps[0].color = new Color(255, 255, 255, 255);
		maps[1].color = new Color(255, 255, 255, 255);
		return new Material(shader, maps);
	}

	// A file's model as read, its meshes made once (`template`), each with a holder of GPU buffers its loads share (holders 0 until a
	// load's mesh takes it); none of it counted.
	static function templateOf(read:Model3D, attached:Null<Array<Int>>):Model {
		var meshes = [], meshMaterial = [];
		for (i => found in read.meshes) {
			// raylib puts every mesh's node's transform into its vertices, a skinned mesh's too.
			var m = read.meshSkinIndices[i] >= 0 ? found.transform(read.meshTransforms[i]) : found;
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
			var gpu = new MeshGpu();
			gpu.holders = 0;
			gpu.shared = true;
			mesh.gpu = gpu;
			meshes.push(mesh);
			meshMaterial.push(read.meshMaterialIndices[i] + 1);
		}
		var model = new Model(meshes, [], meshMaterial);
		skeleton(model, read, attached);
		return model;
	}

	/** Lets go of the counts meshes and materials were made with, once a model holds them.

		@param meshes  The meshes.
		@param materials  The materials. */
	public static function disown(meshes:Array<Mesh>, materials:Array<Material>):Void {
		for (m in meshes)
			releaseMesh(m);
		for (m in materials)
			releaseMaterial(m);
	}

	// A load's materials: material 0 raylib's default, then the file's, as raylib numbers them and as raylib 6.2 reads them (`material`).
	static function materialsOf(read:Model3D, shader:Shader):Array<Material>
		return [defaultMaterial(shader)].concat([for (m in read.materials) material(read, m, shader)]);

	// raylib 6.2's LoadGLTF's materials part: the default material, and only when the material has a pbrMetallicRoughness block, the
	// base color image and factor; the metallic-roughness image split into two grayscale textures, roughness from its green, metalness
	// from its blue (raylib 5.5 put the image whole in the roughness map), and the roughness and metalness factors as those maps' values,
	// set only when the material has that image; the normal, occlusion and emissive images; the emissive factor, alpha 255, only when it
	// has an emissive image. A factor's byte is raylib's (unsigned char)(f*255), in floats. An image that couldn't be decoded leaves its
	// map as it was. Each texture is kept by its image's file, or the model's path and the image's index (and the split's name), so the
	// loads of a file share it while any holds it.
	static function material(read:Model3D, m:GltfMaterial, shader:Shader):Material {
		var material = defaultMaterial(shader), maps = material.maps;
		if (!m.hasPbrMetallicRoughness)
			return material;
		function set(map:Int, index:Int):Void {
			var image = index >= 0 ? read.images[index] : null;
			if (image != null)
				give(maps[map], image.path != "" ? image.path : '${read.path}#$index', () -> image, image.width, image.height,
					Raylib.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
		}
		set(Raylib.MATERIAL_MAP_ALBEDO, m.baseColorImageIndex);
		maps[Raylib.MATERIAL_MAP_ALBEDO].color = byteColor(m.baseColorFactor, byte(m.baseColorFactor[3]));
		if (m.metallicRoughnessImageIndex >= 0) {
			var image = read.images[m.metallicRoughnessImageIndex];
			if (image != null) {
				var w = image.width, h = image.height;
				// GetImageColor's green (roughness) or blue (metalness): the decoded image is RGBA. Made only when no load holds it.
				function split(channel:Int):helix.services.images.Image {
					var gray = Bytes.alloc(w * h);
					for (x in 0...w)
						for (y in 0...h)
							gray.set(y * w + x, image.pixels.get((y * w + x) * 4 + channel));
					return new helix.services.images.Image("", w, h, Pixels.colors(gray, w, h, Raylib.PIXELFORMAT_UNCOMPRESSED_GRAYSCALE));
				}
				var key = '${read.path}#${m.metallicRoughnessImageIndex}';
				give(maps[Raylib.MATERIAL_MAP_ROUGHNESS], '$key:roughness', () -> split(1), w, h, Raylib.PIXELFORMAT_UNCOMPRESSED_GRAYSCALE);
				give(maps[Raylib.MATERIAL_MAP_METALNESS], '$key:metalness', () -> split(2), w, h, Raylib.PIXELFORMAT_UNCOMPRESSED_GRAYSCALE);
			}
			maps[Raylib.MATERIAL_MAP_ROUGHNESS].value = Pixels.f32(m.roughness);
			maps[Raylib.MATERIAL_MAP_METALNESS].value = Pixels.f32(m.metallic);
		}
		set(Raylib.MATERIAL_MAP_NORMAL, m.normalImageIndex);
		set(Raylib.MATERIAL_MAP_OCCLUSION, m.occlusionImageIndex);
		if (m.emissiveImageIndex >= 0) {
			set(Raylib.MATERIAL_MAP_EMISSION, m.emissiveImageIndex);
			maps[Raylib.MATERIAL_MAP_EMISSION].color = byteColor(m.emissiveFactor, 255);
		}
		return material;
	}

	/** Gives a map the texture kept by a key, made of an image when no load holds it: the map holds it, the making's hold let go.

		@param map  The map.
		@param key  The texture's key: its file, or a key of its own.
		@param image  Returns its pixels, asked for only when no load holds it.
		@param width  Its width, in pixels.
		@param height  Its height, in pixels.
		@param format  Its pixel format, as raylib numbers them. */
	public static function give(map:MaterialMap, key:String, image:Void->helix.services.images.Image, width:Int, height:Int, format:Int):Void {
		var id = Textures.fromImage(key, Textures.hasPath(key) ? null : image());
		map.texture = new Texture2D(id, width, height, 1, format);
		Textures.releaseHeld(id);
	}

	// A color of a factor's red, green and blue as raylib's bytes, and an alpha.
	static function byteColor(factor:Array<Float>, alpha:Int):Color
		return new Color(byte(factor[0]), byte(factor[1]), byte(factor[2]), alpha);

	/** Returns raylib's (unsigned char)(f*255): f a float, the product a float, cut toward zero, kept to a byte.

		@param f  The value, usually 0 to 1.
		@return  The byte. */
	public static function byte(f:Float):Int
		return Std.int(Pixels.f32(Pixels.f32(f) * 255)) & 255;

	// raylib 6.2's LoadGLTF's skin part: the first skin's joints as the bones, each parent the nearest joint above it; the bind pose each
	// inverse bind matrix inverted, or the joint's world transform at rest when the file gives none (the models service gives identities
	// then, so a skin whose matrices are all exactly identity is taken as one without); each mesh's joints and weights as its bone ids
	// and weights (a joint above 255 cut to a byte, with raylib's warning), a mesh without joints on a bone's child all that bone's.
	static function skeleton(model:Model, read:Model3D, attached:Null<Array<Int>>):Void {
		var bones = read.skeleton;
		if (bones == null || read.skins.length == 0)
			return;
		var skin = read.skins[0], joints = skin.boneIndices;
		model.boneCount = joints.length;
		model.bones = [
			for (b in joints) {
				var parent = -1, above = bones.bones[b].parentIndex;
				while (above >= 0 && parent < 0) {
					parent = joints.indexOf(above);
					above = bones.bones[above].parentIndex;
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
			if (m.jointIndices != null && m.weights != null) {
				mesh.boneIds = [
					for (j in m.jointIndices) {
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

	// A model's bone matrices, at rest: identities, every mesh's boneMatrices those (raylib 5.5 gives each mesh of a skinned model its own).
	static function animated(model:Model):Void {
		if (model.boneCount == 0)
			return;
		RModels.boneWriter = writeBones;
		model.boneMatrices = [
			for (_ in 0...model.boneCount)
				new Matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
		];
		for (mesh in model.meshes) {
			mesh.boneCount = model.boneCount;
			mesh.boneMatrices = model.boneMatrices;
		}
	}

	// A mesh's bones' matrices written into a skinning shader's boneMatrices, as raylib 5.5's DrawMesh uploads them.
	static function writeBones(mesh:Mesh, shader:Shader):Void {
		var location = shader.locs[Raylib.SHADER_LOC_BONE_MATRICES];
		if (location != -1) {
			var count = mesh.boneCount < mesh.boneMatrices.length ? mesh.boneCount : mesh.boneMatrices.length;
			var values = bones;
			values.resize(count * 16);
			for (i in 0...count) {
				var m = mesh.boneMatrices[i], at = i * 16;
				values[at] = m.m0;
				values[at + 1] = m.m1;
				values[at + 2] = m.m2;
				values[at + 3] = m.m3;
				values[at + 4] = m.m4;
				values[at + 5] = m.m5;
				values[at + 6] = m.m6;
				values[at + 7] = m.m7;
				values[at + 8] = m.m8;
				values[at + 9] = m.m9;
				values[at + 10] = m.m10;
				values[at + 11] = m.m11;
				values[at + 12] = m.m12;
				values[at + 13] = m.m13;
				values[at + 14] = m.m14;
				values[at + 15] = m.m15;
			}
			shader.program.write(location, values);
		}
	}

	// What writeBones fills, read as the draw is recorded.
	static final bones:Array<Float> = [];

	/** Returns a name as raylib's 32 bytes hold it: its first 31 bytes, in UTF-8, less a character those bytes would cut in two (which
		a String can't hold).

		@param name  The name.
		@return  The name, cut. */
	public static function boneName(name:String):String {
		var bytes = Bytes.ofString(name);
		if (bytes.length <= 31)
			return name;
		var end = 31;
		// Back to the start of the character byte 31 is in, unless it starts one.
		while (end > 0 && bytes.get(end) & 0xC0 == 0x80)
			end--;
		return bytes.getString(0, end);
	}

	/** Keeps a model the models service read, so its loads share it, unless it is kept already: the file's meshes, made once with their
		bones, and what the file holds, its materials made of it for each load. It holds no count on anything; it stays while any load of
		the file lives (`release`).

		@param read  The model.
		@param shader  The default shader.
		@param attached  Optional. Each mesh's bone when its node is a child of one and it has no joints of its own, or -1. */
	public static function keep(read:Model3D, shader:Shader, ?attached:Array<Int>):Void {
		if (!loaded.exists(read.path))
			loaded.set(read.path, {
				template: templateOf(read, attached),
				materials: () -> materialsOf(read, shader),
				loads: 0
			});
	}

	/** Keeps a file's model made elsewhere (an OBJ file's, `ObjModels`), so its loads share it, unless it is kept already: its meshes,
		made once, each with a holder of GPU buffers its loads share (holders 0), and what makes each load's materials. It holds no count
		on anything, and stays while any load of the file lives (`release`).

		@param path  The file.
		@param template  The model: its meshes and meshMaterial, its materials none.
		@param materials  Returns a load's materials, each held once, as made. */
	public static function keepMade(path:String, template:Model, materials:Void->Array<Material>):Void {
		if (!loaded.exists(path))
			loaded.set(path, {
				template: template,
				materials: materials,
				loads: 0
			});
	}

	/** Returns whether a file's model is kept, so a load of it needs no read.

		@param path  The file.
		@return  True when it is. */
	public static function isKept(path:String):Bool
		return loaded.exists(path);

	static final loaded = new Map<String, {
		template:Model,
		materials:Void->Array<Material>,
		loads:Int
	}>();

	/** Returns a model loaded from a file kept (`keep`): its meshes copies of the file's, sharing their GPU buffers, and materials of its
		own, sharing the file's textures, so one load's changes don't reach another's. Each load holds its own counts on what it shares, so
		what one lets go of stays for the others, and what none holds is freed.

		@param path  The file.
		@return  The model, or null when none is kept. */
	public static function load(path:String):Null<Model> {
		var entry = loaded.get(path);
		if (entry == null)
			return null;
		entry.loads++;
		var template = entry.template;
		var meshes = [for (m in template.meshes) copyMesh(m)];
		var materials = entry.materials();
		var model = new Model(meshes, materials, template.meshMaterial.copy());
		disown(meshes, materials);
		model.path = path;
		if (template.bones != null) {
			model.boneCount = template.boneCount;
			model.bones = [for (b in template.bones) new BoneInfo(b.name, b.parent)];
			model.bindPose = [for (t in template.bindPose) copyTransform(t)];
			animated(model);
		}
		return model;
	}

	/** Lets go of one load of a file's model, its meshes and materials already released (`UnloadModel`): with the last, the file leaves
		the cache, so a later load reads it again.

		@param path  The file. */
	public static function release(path:String):Void {
		var entry = loaded.get(path);
		if (entry != null && --entry.loads <= 0)
			loaded.remove(path);
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
		m.gpu.holders++;
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
