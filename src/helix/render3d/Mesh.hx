package helix.render3d;

import haxe.io.Bytes;
import helix.graphics.IGraphics;

/** Triangles for lit models: each vertex a position, a normal, texture coordinates and a tangent (Lit3DLayout's packing; the tangent's w its
	bitangent's sign, glTF's convention), indexed, with the box around them. Made once and never changed; a Stage3D uploads it the first time it draws it. The shapes made here are centered on the origin, y up,
	counter-clockwise from outside (the front face), in world units, as the earlier frameworks' generated meshes. */
class Mesh {
	static var nextId = 1;

	// Which one it is, for sorting alike draws together.
	@:allow(helix.render3d.Stage3D) var id = nextId++;
	var vertexData:Bytes;
	var vertexCount:Int;
	var indexData:Bytes;
	var indexCount:Int;
	var loX = 0.;
	var loY = 0.;
	var loZ = 0.;
	var hiX = 0.;
	var hiY = 0.;
	var hiZ = 0.;
	var gpu:IGraphics;
	var vertexBuffer = 0;
	var indexBuffer = 0;

	/** A mesh of vertexCount vertices in vertices (Lit3DLayout.stride bytes each) and indexCount uint32 indices (whole triangles) in indices.
		Throws for a count of 0 or less, too few bytes, or an index past the vertices. */
	public function new(vertices:Bytes, vertexCount:Int, indices:Bytes, indexCount:Int) {
		if (vertexCount <= 0
			|| indexCount <= 0
			|| indexCount % 3 != 0
			|| vertices.length < vertexCount * Lit3DLayout.stride
			|| indices.length < indexCount * 4)
			throw "Invalid mesh";
		for (i in 0...indexCount)
			if (indices.getInt32(i * 4) < 0 || indices.getInt32(i * 4) >= vertexCount)
				throw "Mesh index out of range";
		vertexData = vertices;
		this.vertexCount = vertexCount;
		indexData = indices;
		this.indexCount = indexCount;
		loX = loY = loZ = Math.POSITIVE_INFINITY;
		hiX = hiY = hiZ = Math.NEGATIVE_INFINITY;
		for (i in 0...vertexCount) {
			var at = i * Lit3DLayout.stride + Lit3DLayout.positionOffset;
			var x = vertices.getFloat(at),
				y = vertices.getFloat(at + 4),
				z = vertices.getFloat(at + 8);
			loX = Math.min(loX, x);
			loY = Math.min(loY, y);
			loZ = Math.min(loZ, z);
			hiX = Math.max(hiX, x);
			hiY = Math.max(hiY, y);
			hiZ = Math.max(hiZ, z);
		}
	}

	/** Its vertices. */
	public function getVertexCount():Int
		return vertexCount;

	/** Its indices: three a triangle. */
	public function getIndexCount():Int
		return indexCount;

	/** The vertex data, Lit3DLayout.stride bytes a vertex. */
	public function getVertices():Bytes
		return vertexData;

	/** The indices, uint32 each. */
	public function getIndices():Bytes
		return indexData;

	/** The box around it: its smallest x. */
	public function getMinX():Float
		return loX;

	/** Its smallest y. */
	public function getMinY():Float
		return loY;

	/** Its smallest z. */
	public function getMinZ():Float
		return loZ;

	/** Its largest x. */
	public function getMaxX():Float
		return hiX;

	/** Its largest y. */
	public function getMaxY():Float
		return hiY;

	/** Its largest z. */
	public function getMaxZ():Float
		return hiZ;

	/** Its static vertex buffer on gpu, made the first time it's asked for. */
	public function getVertexBuffer(gpu:IGraphics):Int {
		upload(gpu);
		return vertexBuffer;
	}

	/** Its static index buffer on gpu, made the first time it's asked for. */
	public function getIndexBuffer(gpu:IGraphics):Int {
		upload(gpu);
		return indexBuffer;
	}

	function upload(gpu:IGraphics):Void {
		if (this.gpu == gpu && vertexBuffer != 0)
			return;
		if (this.gpu != null && this.gpu != gpu)
			throw "A mesh lives on one IGraphics";
		this.gpu = gpu;
		vertexBuffer = gpu.createStaticBuffer(vertexData, vertexCount * Lit3DLayout.stride, false);
		indexBuffer = gpu.createStaticBuffer(indexData, indexCount * 4, true);
	}

	/** Frees its buffers, if it was uploaded; drawing it again uploads it again. */
	public function destroy():Void {
		if (gpu == null)
			return;
		gpu.destroyBuffer(vertexBuffer);
		gpu.destroyBuffer(indexBuffer);
		vertexBuffer = indexBuffer = 0;
		gpu = null;
	}

	/** A mesh from arrays: positions (x, y, z each), normals (one a position, unit length; null to work them out from the triangles), texture
		coordinates (u, v each; null for zeros), tangents (x, y, z, w each, w the bitangent's sign; null to work them out) and indices (whole
		triangles; null for each three positions a triangle, in order). Throws for arrays that don't agree. */
	public static function fromArrays(positions:Array<Float>, normals:Null<Array<Float>>, uvs:Null<Array<Float>>, tangents:Null<Array<Float>>,
			indices:Null<Array<Int>>):Mesh {
		var count = Std.int(positions.length / 3);
		if (count == 0 || positions.length != count * 3 || normals != null && normals.length != count * 3 || uvs != null && uvs.length != count * 2
			|| tangents != null && tangents.length != count * 4)
			throw "Mesh arrays disagree";
		var b = new MeshBuilder();
		for (i in 0...count)
			b.vertex(positions[i * 3], positions[i * 3 + 1], positions[i * 3 + 2], normals == null ? 0 : normals[i * 3],
				normals == null ? 0 : normals[i * 3 + 1], normals == null ? 0 : normals[i * 3 + 2], uvs == null ? 0 : uvs[i * 2],
				uvs == null ? 0 : uvs[i * 2 + 1]);
		var order = indices == null ? [for (i in 0...count) i] : indices;
		if (order.length % 3 != 0)
			throw "Mesh indices aren't whole triangles";
		// The file's winding is the truth here: triangles go in as given, not turned to their normals.
		for (i in order)
			if (i < 0 || i >= count)
				throw "Mesh index out of range";
		b.raw(order);
		if (normals == null)
			b.smoothNormals();
		return b.build(tangents);
	}

	/** Flat in x and z, facing +y, width along x and length along z, subdivisions (0..256) more cells each way; texture coordinates span it
		once. */
	public static function plane(width:Float, length:Float, subdivisions = 0):Mesh {
		var cells = clamp(subdivisions, 0, 256) + 1, b = new MeshBuilder();
		for (j in 0...cells + 1)
			for (i in 0...cells + 1)
				b.vertex((i / cells - .5) * width, 0, (j / cells - .5) * length, 0, 1, 0, i / cells, j / cells);
		for (j in 0...cells)
			for (i in 0...cells)
				b.quad(j * (cells + 1) + i, j * (cells + 1) + i + 1, (j + 1) * (cells + 1) + i + 1, (j + 1) * (cells + 1) + i);
		return b.build();
	}

	/** A box width along x, height along y and length along z, each face its own vertices (sharp edges), textured 0..1 a face. */
	public static function cube(width:Float, height:Float, length:Float):Mesh {
		var b = new MeshBuilder(), x = width / 2, y = height / 2, z = length / 2;
		// Each face: its normal, then its u and v axes (scaled to the half extents), so corners are center -u-v, +u-v, +u+v, -u+v.
		var faces = [
			[0, 0, 1, x, 0, 0, 0, y, 0],
			[0, 0, -1, -x, 0, 0, 0, y, 0],
			[1, 0, 0, 0, 0, -z, 0, y, 0],
			[-1, 0, 0, 0, 0, z, 0, y, 0],
			[0, 1, 0, x, 0, 0, 0, 0, -z],
			[0, -1, 0, x, 0, 0, 0, 0, z]
		];
		for (f in faces) {
			var nx = f[0], ny = f[1], nz = f[2], cx = nx * x, cy = ny * y, cz = nz * z;
			var first = b.getVertexCount();
			for (corner in [[-1, -1, 0, 1], [1, -1, 1, 1], [1, 1, 1, 0], [-1, 1, 0, 0]])
				b.vertex(cx
					+ corner[0] * f[3] + corner[1] * f[6], cy
					+ corner[0] * f[4] + corner[1] * f[7], cz
					+ corner[0] * f[5] + corner[1] * f[8], nx, ny,
					nz, corner[2], corner[3]);
			b.quad(first, first + 1, first + 2, first + 3);
		}
		return b.build();
	}

	/** A sphere of radius, rings (2..256) from pole to pole and segments (3..512) around; u around, v from the top pole to the bottom. */
	public static function sphere(radius:Float, rings = 16, segments = 32):Mesh {
		var b = new MeshBuilder();
		band(b, clamp(rings, 2, 256), clamp(segments, 3, 512), radius, 0, Math.PI, 0, 0, 1);
		return b.build();
	}

	/** A capped cylinder along y, of radius and height, segments (3..512) around. */
	public static function cylinder(radius:Float, height:Float, segments = 32):Mesh {
		var b = new MeshBuilder(), n = clamp(segments, 3, 512), h = height / 2;
		side(b, n, radius, radius, -h, h);
		cap(b, n, radius, h, 1);
		cap(b, n, radius, -h, -1);
		return b.build();
	}

	/** A cone along y, tip up, of base radius and height, its base capped, segments (3..512) around. */
	public static function cone(radius:Float, height:Float, segments = 32):Mesh {
		var b = new MeshBuilder(), n = clamp(segments, 3, 512), h = height / 2;
		side(b, n, radius, 0, -h, h);
		cap(b, n, radius, -h, -1);
		return b.build();
	}

	/** A capsule along y: height from end to end (at least twice the radius; less is a sphere), rings (2..256) across both round ends, segments
		(3..512) around. */
	public static function capsule(radius:Float, height:Float, rings = 16, segments = 32):Mesh {
		var b = new MeshBuilder(),
			n = clamp(segments, 3, 512),
			half = Std.int(Math.max(1, clamp(rings, 2, 256) / 2));
		var straight = Math.max(0, height / 2 - radius);
		var total = 2 * (radius + straight);
		band(b, half, n, radius, 0, Math.PI / 2, straight, 0, radius / total);
		side(b, n, radius, radius, -straight, straight, (radius + straight) / total, (radius + straight * 3) / total);
		band(b, half, n, radius, Math.PI / 2, Math.PI, -straight, (total - radius) / total, 1);
		return b.build();
	}

	/** A ring around y: radius to the middle of the tube, thickness the tube's radius, rings (3..512) around the ring and segments (3..512)
		around the tube. */
	public static function torus(radius:Float, thickness:Float, rings = 32, segments = 16):Mesh {
		var b = new MeshBuilder(),
			nr = clamp(rings, 3, 512),
			ns = clamp(segments, 3, 512);
		for (i in 0...nr + 1) {
			var u = i / nr * Math.PI * 2, cu = Math.cos(u), su = Math.sin(u);
			for (j in 0...ns + 1) {
				var v = j / ns * Math.PI * 2,
					cv = Math.cos(v),
					sv = Math.sin(v);
				b.vertex((radius + thickness * cv) * cu, thickness * sv, (radius + thickness * cv) * su, cv * cu, sv, cv * su, i / nr, j / ns);
			}
		}
		for (i in 0...nr)
			for (j in 0...ns)
				b.quad(i * (ns + 1) + j, (i + 1) * (ns + 1) + j, (i + 1) * (ns + 1) + j + 1, i * (ns + 1) + j + 1);
		return b.build();
	}

	static function clamp(value:Int, min:Int, max:Int):Int
		return value < min ? min : value > max ? max : value;

	// Part of a sphere from latitude from to to (0 the top pole, pi the bottom), raised by lift, v from v0 to v1.
	static function band(b:MeshBuilder, rings:Int, segments:Int, radius:Float, from:Float, to:Float, lift:Float, v0:Float, v1:Float):Void {
		var first = b.getVertexCount();
		for (r in 0...rings + 1) {
			var a = from + (to - from) * r / rings,
				y = Math.cos(a),
				ring = Math.sin(a);
			for (s in 0...segments + 1) {
				var t = s / segments * Math.PI * 2,
					nx = ring * Math.cos(t),
					nz = ring * Math.sin(t);
				b.vertex(nx * radius, y * radius + lift, nz * radius, nx, y, nz, s / segments, v0 + (v1 - v0) * r / rings);
			}
		}
		for (r in 0...rings)
			for (s in 0...segments)
				b.quad(first
					+ r * (segments + 1)
					+ s, first
					+ r * (segments + 1)
					+ s
					+ 1, first
					+ (r + 1) * (segments + 1)
					+ s
					+ 1,
					first
					+ (r + 1) * (segments + 1)
					+ s);
	}

	// A side around y from radius bottom at y0 to radius top at y1, normals tilted by the slope, v from v0 at the top to v1 at the bottom.
	static function side(b:MeshBuilder, segments:Int, bottom:Float, top:Float, y0:Float, y1:Float, v0 = 0., v1 = 1.):Void {
		var first = b.getVertexCount(),
			slope = (bottom - top) / (y1 - y0),
			length = Math.sqrt(1 + slope * slope);
		for (s in 0...segments + 1) {
			var t = s / segments * Math.PI * 2,
				c = Math.cos(t),
				sn = Math.sin(t);
			b.vertex(c * top, y1, sn * top, c / length, slope / length, sn / length, s / segments, v0);
			b.vertex(c * bottom, y0, sn * bottom, c / length, slope / length, sn / length, s / segments, v1);
		}
		for (s in 0...segments)
			b.quad(first + s * 2, first + s * 2 + 2, first + s * 2 + 3, first + s * 2 + 1);
	}

	// A flat disc of radius at y, facing up (1) or down (-1).
	static function cap(b:MeshBuilder, segments:Int, radius:Float, y:Float, facing:Int):Void {
		var center = b.getVertexCount();
		b.vertex(0, y, 0, 0, facing, 0, .5, .5);
		for (s in 0...segments + 1) {
			var t = s / segments * Math.PI * 2,
				c = Math.cos(t),
				sn = Math.sin(t);
			b.vertex(c * radius, y, sn * radius, 0, facing, 0, .5 + c / 2, .5 + sn / 2);
		}
		for (s in 0...segments)
			b.triangle(center, center + 1 + s, center + 2 + s);
	}
}

/** Collects a mesh's vertices and triangles; each triangle is wound counter-clockwise from the side its vertices' normals face. */
private class MeshBuilder {
	var positions:Array<Float> = [];
	var normals:Array<Float> = [];
	var uvs:Array<Float> = [];
	var indices:Array<Int> = [];

	/** An empty builder. */
	public function new() {}

	/** The vertices so far. */
	public function getVertexCount():Int
		return Std.int(positions.length / 3);

	/** A vertex: its position, its normal (unit length) and its texture coordinates. */
	public function vertex(x:Float, y:Float, z:Float, nx:Float, ny:Float, nz:Float, u:Float, v:Float):Void {
		positions.push(x);
		positions.push(y);
		positions.push(z);
		normals.push(nx);
		normals.push(ny);
		normals.push(nz);
		uvs.push(u);
		uvs.push(v);
	}

	/** The triangle, its winding turned to face its normals; nothing for one of no area (a pole's). */
	public function triangle(a:Int, b:Int, c:Int):Void {
		var ax = positions[a * 3],
			ay = positions[a * 3 + 1],
			az = positions[a * 3 + 2];
		var ux = positions[b * 3] - ax,
			uy = positions[b * 3 + 1] - ay,
			uz = positions[b * 3 + 2] - az;
		var vx = positions[c * 3] - ax,
			vy = positions[c * 3 + 1] - ay,
			vz = positions[c * 3 + 2] - az;
		var cx = uy * vz - uz * vy,
			cy = uz * vx - ux * vz,
			cz = ux * vy - uy * vx;
		if (cx * cx + cy * cy + cz * cz < 1e-20)
			return;
		var nx = normals[a * 3] + normals[b * 3] + normals[c * 3],
			ny = normals[a * 3 + 1] + normals[b * 3 + 1] + normals[c * 3 + 1],
			nz = normals[a * 3 + 2] + normals[b * 3 + 2] + normals[c * 3 + 2];
		indices.push(a);
		if (cx * nx + cy * ny + cz * nz >= 0) {
			indices.push(b);
			indices.push(c);
		} else {
			indices.push(c);
			indices.push(b);
		}
	}

	/** Triangles as given, winding and all. */
	public function raw(order:Array<Int>):Void
		for (i in order)
			indices.push(i);

	/** Each vertex's normal: the area-weighted sum of its triangles' normals, made unit length. */
	public function smoothNormals():Void {
		for (i in 0...normals.length)
			normals[i] = 0;
		var k = 0;
		while (k + 2 < indices.length) {
			var a = indices[k], b = indices[k + 1], c = indices[k + 2];
			k += 3;
			var ux = positions[b * 3] - positions[a * 3],
				uy = positions[b * 3 + 1] - positions[a * 3 + 1],
				uz = positions[b * 3 + 2] - positions[a * 3 + 2];
			var vx = positions[c * 3] - positions[a * 3],
				vy = positions[c * 3 + 1] - positions[a * 3 + 1],
				vz = positions[c * 3 + 2] - positions[a * 3 + 2];
			var nx = uy * vz - uz * vy,
				ny = uz * vx - ux * vz,
				nz = ux * vy - uy * vx;
			for (v in [a, b, c]) {
				normals[v * 3] += nx;
				normals[v * 3 + 1] += ny;
				normals[v * 3 + 2] += nz;
			}
		}
		for (v in 0...getVertexCount()) {
			var x = normals[v * 3],
				y = normals[v * 3 + 1],
				z = normals[v * 3 + 2],
				l = Math.sqrt(x * x + y * y + z * z);
			normals[v * 3] = l > 0 ? x / l : 0;
			normals[v * 3 + 1] = l > 0 ? y / l : 1;
			normals[v * 3 + 2] = l > 0 ? z / l : 0;
		}
	}

	/** Two triangles: a, b, c and a, c, d. */
	public function quad(a:Int, b:Int, c:Int, d:Int):Void {
		triangle(a, b, c);
		triangle(a, c, d);
	}

	/** Tangents for normal mapping (the earlier frameworks' way): from each triangle's positions and texture coordinates, averaged at each
		vertex and made perpendicular to its normal, following increasing u; w is the bitangent's sign, the bitangent cross(normal, tangent) * w
		pointing toward decreasing v (the texture's up). A vertex with no usable mapping gets any tangent perpendicular to its normal. */
	function tangentsOf():Array<Float> {
		var count = getVertexCount(),
			tangents = [for (_ in 0...count * 4) 0.],
			bitangents = [for (_ in 0...count * 3) 0.];
		var k = 0;
		while (k + 2 < indices.length) {
			var i0 = indices[k], i1 = indices[k + 1], i2 = indices[k + 2];
			k += 3;
			var e1x = positions[i1 * 3] - positions[i0 * 3],
				e1y = positions[i1 * 3 + 1] - positions[i0 * 3 + 1],
				e1z = positions[i1 * 3 + 2] - positions[i0 * 3 + 2];
			var e2x = positions[i2 * 3] - positions[i0 * 3],
				e2y = positions[i2 * 3 + 1] - positions[i0 * 3 + 1],
				e2z = positions[i2 * 3 + 2] - positions[i0 * 3 + 2];
			var du1 = uvs[i1 * 2] - uvs[i0 * 2],
				dv1 = uvs[i1 * 2 + 1] - uvs[i0 * 2 + 1],
				du2 = uvs[i2 * 2] - uvs[i0 * 2],
				dv2 = uvs[i2 * 2 + 1] - uvs[i0 * 2 + 1];
			var det = du1 * dv2 - du2 * dv1;
			if (Math.abs(det) < 1e-12)
				continue;
			det = 1 / det;
			var sx = (e1x * dv2 - e2x * dv1) * det,
				sy = (e1y * dv2 - e2y * dv1) * det,
				sz = (e1z * dv2 - e2z * dv1) * det;
			var tx = (e2x * du1 - e1x * du2) * det,
				ty = (e2y * du1 - e1y * du2) * det,
				tz = (e2z * du1 - e1z * du2) * det;
			for (v in [i0, i1, i2]) {
				tangents[v * 4] += sx;
				tangents[v * 4 + 1] += sy;
				tangents[v * 4 + 2] += sz;
				bitangents[v * 3] += tx;
				bitangents[v * 3 + 1] += ty;
				bitangents[v * 3 + 2] += tz;
			}
		}
		for (i in 0...count) {
			var nx = normals[i * 3],
				ny = normals[i * 3 + 1],
				nz = normals[i * 3 + 2];
			var tx = tangents[i * 4],
				ty = tangents[i * 4 + 1],
				tz = tangents[i * 4 + 2];
			var d = nx * tx + ny * ty + nz * tz;
			tx -= nx * d;
			ty -= ny * d;
			tz -= nz * d;
			var w = 1.;
			if (tx * tx + ty * ty + tz * tz < 1e-12) {
				// No texture mapping here: any direction perpendicular to the normal.
				tx = Math.abs(nx) < .9 ? 1 : 0;
				ty = Math.abs(nx) < .9 ? 0 : 1;
				tz = 0;
				d = nx * tx + ny * ty;
				tx -= nx * d;
				ty -= ny * d;
				tz -= nz * d;
			} else {
				// cross(n, t) against the bitangent: the map's up (green) points toward decreasing v.
				var cx = ny * tz - nz * ty,
					cy = nz * tx - nx * tz,
					cz = nx * ty - ny * tx;
				if (cx * bitangents[i * 3] + cy * bitangents[i * 3 + 1] + cz * bitangents[i * 3 + 2] > 0)
					w = -1;
			}
			var l = Math.sqrt(tx * tx + ty * ty + tz * tz);
			tangents[i * 4] = tx / l;
			tangents[i * 4 + 1] = ty / l;
			tangents[i * 4 + 2] = tz / l;
			tangents[i * 4 + 3] = w;
		}
		return tangents;
	}

	/** The mesh of everything added, with given tangents or, without, its tangents worked out from the triangles' positions and texture
		coordinates. */
	public function build(?given:Array<Float>):Mesh {
		var count = getVertexCount(),
			data = Bytes.alloc(count * Lit3DLayout.stride),
			tangents = given != null ? given : tangentsOf();
		for (i in 0...count) {
			var at = i * Lit3DLayout.stride;
			data.setFloat(at + Lit3DLayout.positionOffset, positions[i * 3]);
			data.setFloat(at + Lit3DLayout.positionOffset + 4, positions[i * 3 + 1]);
			data.setFloat(at + Lit3DLayout.positionOffset + 8, positions[i * 3 + 2]);
			data.setFloat(at + Lit3DLayout.normalOffset, normals[i * 3]);
			data.setFloat(at + Lit3DLayout.normalOffset + 4, normals[i * 3 + 1]);
			data.setFloat(at + Lit3DLayout.normalOffset + 8, normals[i * 3 + 2]);
			data.setFloat(at + Lit3DLayout.uvOffset, uvs[i * 2]);
			data.setFloat(at + Lit3DLayout.uvOffset + 4, uvs[i * 2 + 1]);
			for (k in 0...4)
				data.setFloat(at + Lit3DLayout.tangentOffset + k * 4, tangents[i * 4 + k]);
		}
		var index = Bytes.alloc(indices.length * 4);
		for (i in 0...indices.length)
			index.setInt32(i * 4, indices[i]);
		return new Mesh(data, count, index, indices.length);
	}
}
