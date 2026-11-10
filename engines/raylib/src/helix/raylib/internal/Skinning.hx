package helix.raylib.internal;

import haxe.io.Bytes;
import helix.math.Matrix3D;
import helix.raylib.*;
import helix.raylib.modules.RMath.*;

/** Skins what `UpdateModelAnimation` and `UpdateModelAnimationEx` pose, linked only by a program calling one of them.

	A call stores the pose, not the vertices: each skinned mesh keeps the model's bone matrices as they are then (`MeshPose`), and is
	drawn by them:

	- through a shader including `<helix/raylib/shaders/skinning.glsl>` (raylib's default shader is drawn through its skinned twin,
	  `Defaults.skinnedShader`, written every uniform the default is), on the GPU: the draw's bones are written into the frame's bone palette, a data texture of four texels a
	  bone, 64 bones a row, uploaded once before the frame's passes, and the draw is given its first bone (`boneOffset`), so one model
	  drawn in many poses in one frame draws each as it was asked for;
	- through a shader reading the bone ids itself (raylib's `skinning.vs`), as it is: drawn with `boneMatrices`;
	- through any other shader, on the CPU, as raylib 6.2's `UpdateModelAnimationVertexBuffers`: every vertex moved, and the mesh's
	  positions and normals made into new buffers once a pose (`posedBuffers`).

	`Mesh.animVertices` and `animNormals` are worked out on the CPU when first read after a pose (`poseVertices`), for a mesh whose
	material's shader doesn't read the bone ids, as raylib's CPU skinning moves only those. */
@:noCompletion
@:access(helix.raylib.modules.RModels)
@:access(helix.raylib.Mesh)
@:access(helix.raylib.Model)
@:access(helix.raylib.Shader)
class Skinning {
	// The frame the hooks are installed in.
	static var installed:Null<Frame>;

	// The calls that have posed, each mesh posed by one given its number (MeshPose.stamp).
	static var stamp = 0;

	// The twin's locations, by SHADER_LOC_*: none set, so its maps bind as the default shader's (texture0 to texture2).
	static var twinLocs:Array<Int>;

	// The palette: its chunks, each a data texture with the bytes it is written from; the bones written this frame and the last; whether
	// a frame has been drawn since a bone was written (so the next write starts the palette again).
	static var chunks:Array<Chunk>;
	static var bones = 0;
	static var lastBones = 0;
	static var drawn = true;

	// The frames drawn since the hooks were installed.
	static var frames = 0;

	// The stamp of the last pose written into the palette this frame, and its first bone, so a model's meshes posed by one call share it.
	static var writtenStamp = -1;
	static var writtenOffset = 0;

	/** Stores a model's pose in each of its skinned meshes, their posed vertices and buffers then out of date; the hooks the draws and
		`Mesh.animVertices` reach installed the first time.

		@param model  The model, its bone matrices just computed.
		@param bonesOnly  Whether only the meshes whose shader reads the bones itself take the pose (`UpdateModelAnimationBones`, as
			raylib 6.2's moves no vertex): the rest keep the pose they had, or their bind pose. */
	public static function pose(model:Model, bonesOnly = false):Void {
		if (installed != Runtime.frame) {
			// A window made again (CloseWindow, InitWindow) has a frame and a GPU of its own.
			installed = Runtime.frame;
			twinLocs = [for (_ in 0...32) -1];
			chunks = [];
			drawn = true;
			Mesh.posing = poseVertices;
			installed.skinned = draw;
			installed.drawing.push(upload);
		}
		stamp++;
		var count = model.boneCount;
		// The model's bones as floats, copied once and shared by its meshes' poses: every mesh of a model is posed by the same bones.
		var shared:Null<Array<Float>> = null;
		for (m in 0...model.meshCount) {
			var mesh = model.meshes[m];
			if (mesh.boneWeights == null || mesh.boneIds == null)
				continue;
			// raylib's CPU skinning leaves a mesh whose shader reads the bone ids: its animVertices stay as they were.
			var material = model.materials[model.meshMaterial[m]];
			var cpu = !(material != null
				&& material.shader != null
				&& material.shader.locs != null
				&& material.shader.locs[Raylib.SHADER_LOC_VERTEX_BONEIDS] != -1);
			if (bonesOnly && cpu)
				continue;
			var pose = mesh.pose;
			if (pose == null)
				pose = mesh.pose = {
					bones: [],
					stamp: 0,
					changed: false,
					weightsRead: null,
					weighted: false,
					positionBuffer: 0,
					normalBuffer: 0,
					buffersFrame: -1
				};
			if (shared != null) {
				pose.bones = shared;
				pose.stamp = stamp;
				if (cpu)
					pose.changed = true;
				pose.buffersFrame = -1;
				continue;
			}
			var floats = shared = pose.bones;
			if (floats.length != count * 16)
				floats.resize(count * 16);
			for (b in 0...count) {
				var bone = model.boneMatrices[b], at = b * 16;
				floats[at] = bone.m0;
				floats[at + 1] = bone.m1;
				floats[at + 2] = bone.m2;
				floats[at + 3] = bone.m3;
				floats[at + 4] = bone.m4;
				floats[at + 5] = bone.m5;
				floats[at + 6] = bone.m6;
				floats[at + 7] = bone.m7;
				floats[at + 8] = bone.m8;
				floats[at + 9] = bone.m9;
				floats[at + 10] = bone.m10;
				floats[at + 11] = bone.m11;
				floats[at + 12] = bone.m12;
				floats[at + 13] = bone.m13;
				floats[at + 14] = bone.m14;
				floats[at + 15] = bone.m15;
			}
			pose.stamp = stamp;
			if (cpu)
				pose.changed = true;
			pose.buffersFrame = -1;
		}
	}

	// Draws a posed mesh: through a shader skinning from the palette (the default shader's skinned twin, or a program's own including
	// skinning.glsl), or through its own shader from buffers posed on the CPU. False for a draw left as it is: a shader reading the bone
	// ids itself (raylib's skinning.vs), or a mesh whose vertices no bone moves (raylib's CPU skinning leaves its buffers).
	static function draw(mesh:Mesh, shader:Shader, material:Material, transform:Matrix3D, diffuse:Array<Float>, instances:Int, instanceCount:Int):Bool {
		var pose = mesh.pose;
		if (!weighted(mesh, pose))
			return false;
		var frame = Runtime.frame;
		var p = shader.program;
		var locs = shader.locs;
		// The default shader's skinned twin.
		if (instances == 0) {
			var twin = p.twin;
			if (twin == null && p == frame.defaultProgram) {
				twin = new Program(Runtime.graphics, Defaults.skinnedShader());
				p.mirror(twin);
			}
			if (twin != null) {
				p = twin;
				locs = twinLocs;
			}
		}
		if (p.paletteSlot == -2) {
			var sampler = p.shader.findSampler("bonePalette");
			p.paletteSlot = sampler == null ? -1 : sampler.slot;
			p.boneOffset = p.shader.findUniform("boneOffset");
		}
		if (p.paletteSlot >= 0) {
			var palette = write(pose);
			// The draw's first bone plus one: 0, as every other draw through the program reads it, means no bones (the bind pose).
			if (p.boneOffset != null)
				p.values.writeInt(p.boneOffset, writtenOffset + 1);
			var textures = p.mapTextures(mesh, locs, material);
			textures[p.paletteSlot] = palette;
			frame.mesh(mesh, p, transform, diffuse, textures, instances, instanceCount);
			if (p.boneOffset != null)
				p.values.writeInt(p.boneOffset, 0);
			return true;
		}
		if (shader.locs[Raylib.SHADER_LOC_VERTEX_BONEIDS] != -1)
			return false;
		posedBuffers(mesh, pose);
		frame.mesh(mesh, p, transform, diffuse, shader.program.mapTextures(mesh, shader.locs, material), instances, instanceCount);
		// Its positions and normals from the posed buffers, in the draws just added (both eyes', in stereo, share the array).
		var buffers = frame.meshBuffers;
		if (buffers != null)
			for (i => name in p.attributes)
				if (name == "vertexPosition")
					buffers[i] = pose.positionBuffer;
				else if (name == "vertexNormal" && pose.normalBuffer != 0)
					buffers[i] = pose.normalBuffer;
		return true;
	}

	// Whether any of a mesh's vertices has a bone of some weight, as raylib's CPU skinning moves only those meshes' buffers; read again
	// only when its weights are other ones.
	static function weighted(mesh:Mesh, pose:MeshPose):Bool {
		var weights = mesh.boneWeights;
		if (weights == null)
			return false;
		if (weights != pose.weightsRead) {
			pose.weightsRead = weights;
			pose.weighted = false;
			for (w in weights)
				if (w != 0) {
					pose.weighted = true;
					break;
				}
		}
		return pose.weighted;
	}

	// Writes a pose into the frame's palette, unless the mesh before it from the same call has (writtenOffset its first bone), and returns
	// the texture it is in.
	static function write(pose:MeshPose):Int {
		if (drawn) {
			drawn = false;
			lastBones = bones;
			bones = 0;
			writtenStamp = -1;
			// One chunk of the rows the last frame needed, made again when it is four times too big; a frame needing more than it
			// holds makes others, each twice the one before.
			var wanted = Std.int(Math.max(1, Math.ceil(lastBones / 64)));
			if (chunks.length > 1 || chunks.length == 1 && (chunks[0].rows < wanted || chunks[0].rows > 16 && chunks[0].rows > wanted * 4))
				for (c in chunks.splice(0, chunks.length)) {
					Runtime.graphics.disposeTexture(c.handle);
				}
			for (c in chunks)
				c.used = 0;
		}
		var chunk = chunks.length > 0 ? chunks[chunks.length - 1] : null;
		if (pose.stamp == writtenStamp && chunk != null)
			return chunk.handle;
		var floats = pose.bones, n = Std.int(floats.length / 16);
		if (chunk == null || chunk.used + n > chunk.rows * 64) {
			var rows = Std.int(Math.max(Math.max(1, Math.ceil(lastBones / 64)), Math.ceil(n / 64)));
			if (chunk != null)
				rows = Std.int(Math.max(rows, chunk.rows * 2));
			chunks.push(chunk = new Chunk(Runtime.graphics.createDataTexture(256, rows), rows));
		}
		var data = chunk.bytes, at = chunk.used * 64;
		for (i in 0...floats.length)
			data.setFloat(at + i * 4, floats[i]);
		writtenStamp = pose.stamp;
		writtenOffset = chunk.used;
		chunk.used += n;
		bones += n;
		return chunk.handle;
	}

	// Uploads the palette's chunks written this frame, before its passes.
	static function upload():Void {
		frames++;
		if (drawn)
			return;
		for (c in chunks)
			if (c.used > 0)
				Runtime.graphics.updateTexture(c.handle, 0, 0, 256, c.rows, c.bytes);
		drawn = true;
	}

	// The CPU path's buffers: a mesh's posed positions and normals, made once a frame while its pose holds and again when it changes, so
	// draws asked for before keep theirs; each freed once its frame is drawn.
	static function posedBuffers(mesh:Mesh, pose:MeshPose):Void {
		if (pose.buffersFrame == frames)
			return;
		pose.buffersFrame = frames;
		// A mesh whose shader read the bone ids when it was posed has no CPU pose yet: it is worked out now.
		pose.changed = true;
		var positions = mesh.animVertices,
			normals = mesh.normals != null ? mesh.animNormals : null;
		pose.positionBuffer = replace(mesh, positions);
		if (normals != null)
			pose.normalBuffer = replace(mesh, normals);
	}

	// A buffer made of three numbers a vertex, as 32-bit floats, for this frame's draws: freed once it is drawn.
	static function replace(mesh:Mesh, values:Array<Float>):Int {
		var n = mesh.vertexCount * 3;
		var bytes = Bytes.alloc(n * 4);
		for (i in 0...n)
			bytes.setFloat(i * 4, i < values.length ? values[i] : 0);
		var buffer = Runtime.graphics.createStaticBuffer(bytes, bytes.length, false);
		Runtime.frame.retire(buffer);
		return buffer;
	}

	// Moves a mesh's vertices by its pose, as raylib 6.2's UpdateModelAnimationVertexBuffers: a vertex's position and normal (by the
	// matrices inverted and transposed, not normalized) each bone's times its weight, added.
	static function poseVertices(mesh:Mesh):Void {
		var pose = mesh.pose;
		if (!pose.changed)
			return;
		pose.changed = false;
		if (mesh.boneWeights == null || mesh.boneIds == null)
			return;
		var floats = pose.bones;
		var count = mesh.vertexCount * 3;
		var anim = mesh.animVertices, animNormals = mesh.animNormals;
		if (anim == null)
			anim = mesh.animVertices = mesh.vertices.slice(0, count);
		if (mesh.normals != null && animNormals == null)
			animNormals = mesh.animNormals = mesh.normals.slice(0, count);
		var boneCount = Std.int(floats.length / 16);
		// A normal's matrix depends on its bone alone: once a bone, not once a vertex.
		var normalMatrices = mesh.normals == null ? null : [
			for (b in 0...(boneCount < 256 ? boneCount : 256)) {
				var at = b * 16;
				MatrixTranspose(MatrixInvert(new Matrix(floats[at], floats[at + 4], floats[at + 8], floats[at + 12], floats[at + 1], floats[at + 5],
					floats[at + 9], floats[at + 13], floats[at + 2], floats[at + 6], floats[at + 10], floats[at + 14], floats[at + 3], floats[at + 7],
					floats[at + 11], floats[at + 15])));
			}
		];
		var vertices = mesh.vertices, normals = mesh.normals;
		var boneCounter = 0, v = 0;
		while (v < count) {
			anim[v] = 0;
			anim[v + 1] = 0;
			anim[v + 2] = 0;
			if (animNormals != null) {
				animNormals[v] = 0;
				animNormals[v + 1] = 0;
				animNormals[v + 2] = 0;
			}
			for (_ in 0...4) {
				var boneWeight = mesh.boneWeights[boneCounter];
				var boneIndex = mesh.boneIds[boneCounter];
				boneCounter++;
				// Nothing to add for a bone of no weight.
				if (boneWeight == 0)
					continue;
				var at = boneIndex * 16;
				var x = vertices[v], y = vertices[v + 1], z = vertices[v + 2];
				anim[v] += (floats[at] * x + floats[at + 4] * y + floats[at + 8] * z + floats[at + 12]) * boneWeight;
				anim[v + 1] += (floats[at + 1] * x + floats[at + 5] * y + floats[at + 9] * z + floats[at + 13]) * boneWeight;
				anim[v + 2] += (floats[at + 2] * x + floats[at + 6] * y + floats[at + 10] * z + floats[at + 14]) * boneWeight;
				if (normals != null && animNormals != null) {
					var n = normalMatrices[boneIndex];
					var nx = normals[v],
						ny = normals[v + 1],
						nz = normals[v + 2];
					animNormals[v] += (n.m0 * nx + n.m4 * ny + n.m8 * nz + n.m12) * boneWeight;
					animNormals[v + 1] += (n.m1 * nx + n.m5 * ny + n.m9 * nz + n.m13) * boneWeight;
					animNormals[v + 2] += (n.m2 * nx + n.m6 * ny + n.m10 * nz + n.m14) * boneWeight;
				}
			}
			v += 3;
		}
	}
}

/** One data texture of the bone palette, and the bytes it is written from. */
@:noCompletion
private class Chunk {
	/** The data texture. */
	public final handle:Int;

	/** Its rows of 64 bones. */
	public final rows:Int;

	/** What is uploaded to it each frame it is drawn from. */
	public final bytes:Bytes;

	/** The bones written to it this frame. */
	public var used = 0;

	/** Makes a palette texture of rows. */
	public function new(handle:Int, rows:Int) {
		this.handle = handle;
		this.rows = rows;
		bytes = Bytes.alloc(256 * rows * 16);
	}
}
