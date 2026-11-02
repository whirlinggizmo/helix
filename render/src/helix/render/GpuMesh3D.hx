package helix.render;

import helix.geometry.Mesh3D;
import helix.math.Bounds3D;
import helix.math.Matrix3D;

/** Represents a mesh on the GPU: its vertices and indices, uploaded once and drawn as often as wanted (`Batch3D.drawMesh`).

	`Renderer.createMesh` makes one from helix-geometry's `Mesh3D`, and `Renderer.createModel` one for each of a model's meshes. The
	program frees it with `dispose`. It keeps its positions on the CPU, and a skinned mesh its joints and weights, for `computeBounds`;
	for a skinned mesh it also records each joint's box of the vertices it moves, which `Batch3D` culls by. */
class GpuMesh3D {
	/** Gets the number of vertices. */
	public var vertexCount(default, null):Int;

	/** Gets the number of triangles. */
	public var triangleCount(default, null):Int;

	/** Gets the box around its positions as uploaded, in the mesh's own units (a skinned mesh's in its bind pose). */
	public final bounds = new Bounds3D();

	/** Gets a value indicating whether it has joints and weights, so it is drawn skinned when given a skin's matrices. */
	public var hasJoints(default, null):Bool;

	/** Gets the number of its morph targets: 0 for none. */
	public var morphTargetCount(default, null):Int;

	@:allow(helix.render)
	function new() {}

	/** Replaces its vertices and indices with a mesh's, for the draws after it.

		Draws already recorded this frame draw what it held before. A mesh made `updatedOften` (`Renderer.createMesh`) is replaced in place; another
		is uploaded again.
		@param mesh  The mesh. It may have other arrays and another vertex count than before.
		@throws String  A mesh without positions, or a disposed one. */
	public function update(mesh:Mesh3D):Void {
		if (disposed)
			throw "helix-render: update of a disposed mesh";
		var old = [buffer, indexBuffer, edgeBuffer];
		var r = renderer;
		upload(mesh);
		r.release(() -> {
			for (b in old)
				if (b != 0)
					r.graphics.disposeBuffer(b);
		});
	}

	/** Returns the box around the mesh as drawn: its vertices posed by a skin's matrices when given, on the CPU, then placed by a transform.

		It is exact where the box culling uses may be larger, so it suits framing a camera and picking. It goes through every vertex, so it
		is for now and then, not every mesh every frame.
		@param transform  The mesh's place in the world.
		@param skinning  Optional. Its skin's matrices, as `Batch3D.drawMesh` takes them; the mesh as uploaded when omitted.
		@param morphWeights  Optional. Its morph targets' weights, as `Batch3D.drawMesh` takes them; none when omitted.
		@param out  Optional. Set to the box; a new one when omitted.
		@return  The box, in world units.
		@throws String  A disposed mesh. */
	public function computeBounds(transform:Matrix3D, ?skinning:Array<Matrix3D>, ?morphWeights:Array<Float>, ?out:Bounds3D):Bounds3D {
		if (disposed)
			throw "helix-render: computeBounds of a disposed mesh";
		if (morphWeights != null && morphWeights.length > 0)
			throw "helix-render: GpuMesh3D.computeBounds with morph weights is not yet built (stage 7, morph targets)";
		if (out == null)
			out = new Bounds3D();
		out.makeEmpty();
		var m = transform.values, p = positions;
		for (v in 0...vertexCount) {
			var x = p[v * 3], y = p[v * 3 + 1], z = p[v * 3 + 2];
			if (skinning != null && joints != null) {
				var sx = 0., sy = 0., sz = 0.;
				for (k in 0...4) {
					var w = weights[v * 4 + k];
					if (w == 0)
						continue;
					var j = joints[v * 4 + k];
					if (j >= skinning.length)
						continue;
					var s = skinning[j].values;
					sx += w * (s[0] * x + s[4] * y + s[8] * z + s[12]);
					sy += w * (s[1] * x + s[5] * y + s[9] * z + s[13]);
					sz += w * (s[2] * x + s[6] * y + s[10] * z + s[14]);
				}
				x = sx;
				y = sy;
				z = sz;
			}
			out.expand(m[0] * x + m[4] * y + m[8] * z + m[12], m[1] * x + m[5] * y + m[9] * z + m[13], m[2] * x + m[6] * y + m[10] * z + m[14]);
		}
		return out;
	}

	/** Frees its buffers on the GPU, after the frame being recorded when it holds a draw of it. A second call does nothing. */
	public function dispose():Void {
		if (disposed)
			return;
		disposed = true;
		var r = renderer, held = [buffer, indexBuffer, edgeBuffer];
		buffer = indexBuffer = edgeBuffer = 0;
		if (r != null) {
			r.forget(this);
			r.release(() -> {
				for (b in held)
					if (b != 0)
						r.graphics.disposeBuffer(b);
			});
		}
	}

	// The renderer, its buffers, its records' layout, and what it keeps on the CPU: positions, joints and weights, indices, each joint's
	// box of the vertices it moves.
	@:allow(helix.render)
	var renderer:Null<Renderer> = null;

	@:allow(helix.render)
	var disposed = false;

	@:allow(helix.render)
	var buffer = 0;

	@:allow(helix.render)
	var indexBuffer = 0;

	@:allow(helix.render)
	var edgeBuffer = 0;

	@:allow(helix.render)
	var edgeCount = 0;

	@:allow(helix.render)
	var layout:Null<helix.services.shaders.ShaderVertexLayout> = null;

	var positions:Array<Float> = [];
	var joints:Null<Array<Int>> = null;
	var weights:Null<Array<Float>> = null;
	var indices:Null<Array<Int>> = null;

	@:allow(helix.render)
	final jointBoxes:Array<Bounds3D> = [];

	static final layouts = new Map<Int, helix.services.shaders.ShaderVertexLayout>();

	@:allow(helix.render)
	var indexed(get, never):Bool;

	inline function get_indexed():Bool
		return indexBuffer != 0;

	// Each attribute's place and format in a record, in order: position, normal, texture coordinates, second ones, tangent, color, joints,
	// weights.
	static final NAMES = [
		"vertexPosition",
		"vertexNormal",
		"vertexTexCoord",
		"vertexTexCoord2",
		"vertexTangent",
		"vertexColor",
		"vertexJoints",
		"vertexWeights"
	];
	static final SIZES = [12, 12, 8, 8, 16, 4, 8, 4];
	static final FORMATS:Array<helix.platform.VertexFormat> = [Float3, Float3, Float2, Float2, Float4, UByte4Norm, Half4, UByte4Norm];

	// The layout of records holding the attributes a set of bits names, and the instance buffer beside it; the same object for the same set.
	static function layoutOf(bits:Int):helix.services.shaders.ShaderVertexLayout {
		var found = layouts.get(bits);
		if (found != null)
			return found;
		var placements:Array<helix.services.shaders.ShaderVertexPlacement> = [], offset = 0, fed = [];
		for (i in 0...NAMES.length)
			if (bits & 1 << i != 0) {
				placements.push({
					name: NAMES[i],
					offset: offset,
					format: FORMATS[i],
					optional: i > 0
				});
				fed.push(NAMES[i]);
				offset += SIZES[i];
			}
		found = new helix.services.shaders.ShaderVertexLayout([
			{stride: offset, placements: placements},
			{
				stride: RenderConstants.MESH_STRIDE,
				instanced: true,
				placements: ([
					{name: "instanceModel", offset: 0, optional: true},
					{
						name: "instanceColor",
						offset: 64,
						format: UByte4Norm,
						optional: true
					}
				] : Array<helix.services.shaders.ShaderVertexPlacement>).concat(RenderConstants.placements(RenderConstants.MESH, fed))
			}
		]);
		layouts.set(bits, found);
		return found;
	}

	// A float as a half float's bits.
	static function half(value:Float):Int {
		if (value == 0 || !Math.isFinite(value))
			return value == 0 ? 0 : 0x7c00;
		var sign = value < 0 ? 0x8000 : 0, v = Math.abs(value), e = 0;
		while (v >= 2) {
			v /= 2;
			e++;
		}
		while (v < 1) {
			v *= 2;
			e--;
		}
		if (e > 15)
			return sign | 0x7c00;
		if (e < -14)
			return sign | Math.round(Math.abs(value) / Math.pow(2, -24));
		var mantissa = Math.round((v - 1) * 1024);
		if (mantissa == 1024) {
			mantissa = 0;
			e++;
		}
		return sign | (e + 15) << 10 | mantissa;
	}

	// Uploads a mesh: one buffer of records, its indices, and what is kept on the CPU.

	@:allow(helix.render)
	function upload(mesh:Mesh3D):Void {
		var count = Std.int(mesh.positions.length / 3);
		if (count == 0 || mesh.positions.length % 3 != 0)
			throw "helix-render: a mesh without positions, x, y and z each";
		inline function check(length:Int, per:Int, name:String)
			if (length >= 0 && length != count * per)
				throw 'helix-render: a mesh of $count vertices with $length $name; it takes $per a vertex';
		check(mesh.normals == null ? -1 : mesh.normals.length, 3, "normals");
		check(mesh.texCoords == null ? -1 : mesh.texCoords.length, 2, "texture coordinates");
		check(mesh.tangents == null ? -1 : mesh.tangents.length, 4, "tangents");
		check(mesh.colors == null ? -1 : mesh.colors.length, 4, "colors");
		check(mesh.jointIndices == null ? -1 : mesh.jointIndices.length, 4, "joints");
		check(mesh.weights == null ? -1 : mesh.weights.length, 4, "weights");
		var skinned = mesh.jointIndices != null && mesh.weights != null;
		var present = [
			true,
			mesh.normals != null,
			mesh.texCoords != null,
			false,
			mesh.tangents != null,
			mesh.colors != null,
			skinned,
			skinned
		];
		var bits = 0, stride = 0;
		for (i in 0...present.length)
			if (present[i]) {
				bits |= 1 << i;
				stride += SIZES[i];
			}
		var bytes = haxe.io.Bytes.alloc(stride * count);
		for (v in 0...count) {
			var at = v * stride;
			for (k in 0...3)
				bytes.setFloat(at + k * 4, mesh.positions[v * 3 + k]);
			at += 12;
			if (mesh.normals != null) {
				for (k in 0...3)
					bytes.setFloat(at + k * 4, mesh.normals[v * 3 + k]);
				at += 12;
			}
			if (mesh.texCoords != null) {
				for (k in 0...2)
					bytes.setFloat(at + k * 4, mesh.texCoords[v * 2 + k]);
				at += 8;
			}
			if (mesh.tangents != null) {
				for (k in 0...4)
					bytes.setFloat(at + k * 4, mesh.tangents[v * 4 + k]);
				at += 16;
			}
			if (mesh.colors != null) {
				for (k in 0...4)
					bytes.set(at + k, Math.round(Math.max(0, Math.min(1, mesh.colors[v * 4 + k])) * 255));
				at += 4;
			}
			if (skinned) {
				for (k in 0...4)
					bytes.setUInt16(at + k * 2, half(mesh.jointIndices[v * 4 + k]));
				at += 8;
				for (k in 0...4)
					bytes.set(at + k, Math.round(Math.max(0, Math.min(1, mesh.weights[v * 4 + k])) * 255));
				at += 4;
			}
		}
		var r = renderer;
		buffer = r.graphics.createStaticBuffer(bytes, bytes.length, false);
		indices = mesh.indices == null ? null : mesh.indices.copy();
		indexBuffer = 0;
		if (indices != null && indices.length > 0) {
			var ib = haxe.io.Bytes.alloc(indices.length * 4);
			for (i in 0...indices.length)
				ib.setInt32(i * 4, indices[i]);
			indexBuffer = r.graphics.createStaticBuffer(ib, ib.length, true);
		}
		edgeBuffer = 0;
		edgeCount = 0;
		layout = layoutOf(bits);
		positions = mesh.positions.copy();
		joints = skinned ? mesh.jointIndices.copy() : null;
		weights = skinned ? mesh.weights.copy() : null;
		vertexCount = count;
		triangleCount = Std.int((indices != null ? indices.length : count) / 3);
		hasJoints = skinned;
		morphTargetCount = 0;
		bounds.makeEmpty();
		for (v in 0...count)
			bounds.expand(positions[v * 3], positions[v * 3 + 1], positions[v * 3 + 2]);
		jointBoxes.resize(0);
		if (skinned)
			for (v in 0...count)
				for (k in 0...4)
					if (weights[v * 4 + k] > 0) {
						var j = joints[v * 4 + k];
						while (jointBoxes.length <= j)
							jointBoxes.push(new Bounds3D());
						jointBoxes[j].expand(positions[v * 3], positions[v * 3 + 1], positions[v * 3 + 2]);
					}
	}

	// The indices of each triangle's edges, made the first time the mesh is drawn as its edges.

	@:allow(helix.render)
	function edges():Int {
		if (edgeBuffer != 0)
			return edgeBuffer;
		var list = [];
		for (t in 0...triangleCount) {
			var a = indices != null ? indices[t * 3] : t * 3,
				b = indices != null ? indices[t * 3 + 1] : t * 3 + 1,
				c = indices != null ? indices[t * 3 + 2] : t * 3 + 2;
			for (i in [a, b, b, c, c, a])
				list.push(i);
		}
		var bytes = haxe.io.Bytes.alloc(Std.int(Math.max(4, list.length * 4)));
		for (i in 0...list.length)
			bytes.setInt32(i * 4, list[i]);
		edgeBuffer = renderer.graphics.createStaticBuffer(bytes, bytes.length, true);
		edgeCount = list.length;
		return edgeBuffer;
	}

	// The box around the mesh as a skin poses it, by its joints' boxes, in the mesh's units before its transform.

	@:allow(helix.render)
	function skinnedBounds(skinning:Array<Matrix3D>, out:Bounds3D):Bounds3D {
		out.makeEmpty();
		for (j in 0...jointBoxes.length) {
			var b = jointBoxes[j];
			if (b.isEmpty || j >= skinning.length)
				continue;
			var m = skinning[j].values;
			for (corner in 0...8) {
				var x = corner & 1 == 0 ? b.minX : b.maxX,
					y = corner & 2 == 0 ? b.minY : b.maxY,
					z = corner & 4 == 0 ? b.minZ : b.maxZ;
				out.expand(m[0] * x + m[4] * y + m[8] * z + m[12], m[1] * x + m[5] * y + m[9] * z + m[13], m[2] * x + m[6] * y + m[10] * z + m[14]);
			}
		}
		return out;
	}
}
