package helix.geometry;

import helix.math.Bounds3D;
import helix.math.Matrix3D;
import helix.math.Trig;

/** Represents a mesh: a surface made of triangles, as arrays a GPU or a file takes: positions, and for each vertex its normal, texture
	coordinates, tangent and color when it has them; and the indices of each triangle's corners, or none when the vertices are the
	triangles in order. A triangle's front is the side its corners are counterclockwise from.

	The `fromX` functions make the usual shapes, centered on the origin, +y up, a shape about an axis turning about y, and two triangles
	across each cell of their slices and stacks. Each has normals of length 1 from the shape itself, texture coordinates (u along the
	slices from 0 to 1, v from the top, 0, to the bottom, 1, as images are stored), indices, and no tangents or colors; the vertices on a
	seam are doubled, so each side has its own texture coordinates. They use `Trig`, so a shape is the same on every target. Each takes
	an optional out, last, whose arrays it reuses.

	A model read from a file (helix-services' `Model3D`) holds its meshes as these, each with its material's index beside it. */
class Mesh3D {
	/** Gets or sets the positions, x, y and z each. */
	public var positions:Array<Float> = [];

	/** Gets or sets the normals, x, y and z a vertex, of length 1; null for none. */
	public var normals:Null<Array<Float>> = null;

	/** Gets or sets the texture coordinates, u and v a vertex; null for none. */
	public var texCoords:Null<Array<Float>> = null;

	/** Gets or sets the tangents, x, y, z and w a vertex: the way u grows along the surface, square to the normal, w 1 or -1 for the way v
		grows (the bitangent is the normal crossed with the tangent, times w); null for none. */
	public var tangents:Null<Array<Float>> = null;

	/** Gets or sets the colors, red, green, blue and alpha a vertex, 0 to 1; null for none. */
	public var colors:Null<Array<Float>> = null;

	/** Gets or sets the indices, three a triangle; null when the vertices are the triangles in order. */
	public var indices:Null<Array<Int>> = null;

	/** Gets the number of vertices. */
	public var vertexCount(get, never):Int;

	function get_vertexCount():Int
		return Std.int(positions.length / 3);

	/** Gets the number of triangles. */
	public var triangleCount(get, never):Int;

	function get_triangleCount():Int
		return Std.int((indices != null ? indices.length : vertexCount) / 3);

	/** Creates an empty mesh: no positions, nothing else. */
	public function new() {}

	/** Returns a box.

		@param width  Its size along x.
		@param height  Along y.
		@param depth  Along z.
		@param out  Optional. Set to the box.
		@return  The box: four vertices a face, each face's texture its whole. */
	public static function fromBox(width:Float, height:Float, depth:Float, ?out:Mesh3D):Mesh3D {
		var m = start(out);
		var half = [width / 2, height / 2, depth / 2];
		// Each face: its normal, the way right across it and the way up it, so right crossed with up is the normal.
		for (face in [
			[1, 0, 0, 0, 0, -1, 0, 1, 0], [-1, 0, 0, 0, 0, 1, 0, 1, 0], [0, 1, 0, 1, 0, 0, 0, 0, -1],
			[0, -1, 0, 1, 0, 0, 0, 0, 1],  [0, 0, 1, 1, 0, 0, 0, 1, 0], [0, 0, -1, -1, 0, 0, 0, 1, 0]
		]) {
			var first = m.vertexCount;
			// Its corners from the top left, clockwise, with their texture coordinates.
			for (corner in [[-1, 1, 0, 0], [1, 1, 1, 0], [1, -1, 1, 1], [-1, -1, 0, 1]]) {
				for (axis in 0...3)
					m.positions.push((face[axis] + face[3 + axis] * corner[0] + face[6 + axis] * corner[1]) * half[axis]);
				for (axis in 0...3)
					m.normals.push(face[axis]);
				m.texCoords.push(corner[2]);
				m.texCoords.push(corner[3]);
			}
			for (i in [3, 2, 1, 3, 1, 0])
				m.indices.push(first + i);
		}
		return m;
	}

	/** Returns a flat rectangle on the XZ plane, facing +y.

		@param width  Its size along x.
		@param depth  Along z.
		@param columns  Cells along x, at least 1.
		@param rows  Cells along z, at least 1.
		@param out  Optional. Set to the plane.
		@return  The plane; its texture's top at -z. */
	public static function fromPlane(width:Float, depth:Float, columns:Int, rows:Int, ?out:Mesh3D):Mesh3D {
		var m = start(out);
		columns = columns < 1 ? 1 : columns;
		rows = rows < 1 ? 1 : rows;
		for (j in 0...rows + 1)
			for (i in 0...columns + 1) {
				var u = i / columns, v = j / rows;
				vertex(m, (u - .5) * width, 0, (v - .5) * depth, 0, 1, 0, u, v);
			}
		grid(m, 0, columns, rows, null);
		return m;
	}

	/** Returns a flat disk on the XZ plane, facing +y; with few slices, a regular polygon.

		@param radius  Its radius.
		@param slices  Its sides, at least 3.
		@param out  Optional. Set to the disk.
		@return  The disk: a vertex at its center and one at each corner, the texture a circle touching its edges. */
	public static function fromDisk(radius:Float, slices:Int, ?out:Mesh3D):Mesh3D {
		var m = start(out);
		disk(m, radius, 0, slices < 3 ? 3 : slices, true);
		return m;
	}

	/** Returns a sphere, its poles on y.

		@param radius  Its radius.
		@param slices  Around, at least 3.
		@param stacks  Pole to pole, at least 2.
		@param out  Optional. Set to the sphere.
		@return  The sphere. */
	public static function fromSphere(radius:Float, slices:Int, stacks:Int, ?out:Mesh3D):Mesh3D {
		var m = start(out);
		stacks = stacks < 2 ? 2 : stacks;
		var rows = [
			for (j in 0...stacks + 1) {
				var phi = Math.PI * j / stacks;
				var s = j == 0 || j == stacks ? 0 : Trig.sin(phi), c = j == 0 ? 1 : j == stacks ? -1 : Trig.cos(phi);
				new Row(radius * s, radius * c, s, c, j / stacks);
			}
		];
		lathe(m, rows, slices);
		return m;
	}

	/** Returns the top half of a sphere, open at its base, its pole at +y and its base on the XZ plane.

		@param radius  Its radius.
		@param slices  Around, at least 3.
		@param stacks  Pole to base, at least 1.
		@param out  Optional. Set to the hemisphere.
		@return  The hemisphere. */
	public static function fromHemisphere(radius:Float, slices:Int, stacks:Int, ?out:Mesh3D):Mesh3D {
		var m = start(out);
		stacks = stacks < 1 ? 1 : stacks;
		var rows = [
			for (j in 0...stacks + 1) {
				var phi = Math.PI / 2 * j / stacks;
				var s = j == 0 ? 0 : j == stacks ? 1 : Trig.sin(phi), c = j == 0 ? 1 : j == stacks ? 0 : Trig.cos(phi);
				new Row(radius * s, radius * c, s, c, j / stacks);
			}
		];
		lathe(m, rows, slices);
		return m;
	}

	/** Returns a cylinder along y, or a cone or a truncated one when the radii differ.

		@param bottomRadius  Its base's radius, at -height / 2.
		@param topRadius  Its top's, at height / 2; 0 makes a cone.
		@param height  Its height.
		@param slices  Around, at least 3.
		@param stacks  Base to top, at least 1.
		@param capped  Whether its ends are closed, each by a disk; an end of radius 0 has none.
		@param out  Optional. Set to the cylinder.
		@return  The cylinder. */
	public static function fromCylinder(bottomRadius:Float, topRadius:Float, height:Float, slices:Int, stacks:Int, capped:Bool, ?out:Mesh3D):Mesh3D {
		var m = start(out);
		stacks = stacks < 1 ? 1 : stacks;
		slices = slices < 3 ? 3 : slices;
		// The side's normal leans up as the side narrows toward the top.
		var nr = height, ny = bottomRadius - topRadius, length = Math.sqrt(nr * nr + ny * ny);
		if (length == 0) {
			nr = 1;
			length = 1;
		}
		var rows = [
			for (j in 0...stacks + 1) {
				var t = j / stacks;
				new Row(topRadius + (bottomRadius - topRadius) * t, height / 2 - height * t, nr / length, ny / length, t);
			}
		];
		lathe(m, rows, slices);
		if (capped && topRadius > 0)
			disk(m, topRadius, height / 2, slices, true);
		if (capped && bottomRadius > 0)
			disk(m, bottomRadius, -height / 2, slices, false);
		return m;
	}

	/** Returns a capsule along y: a cylinder with half a sphere on each end.

		@param radius  Its radius.
		@param height  Its height between the two half spheres' centers; its whole height is this and two radii.
		@param slices  Around, at least 3.
		@param stacks  In each half sphere, at least 1.
		@param out  Optional. Set to the capsule.
		@return  The capsule. */
	public static function fromCapsule(radius:Float, height:Float, slices:Int, stacks:Int, ?out:Mesh3D):Mesh3D {
		var m = start(out);
		stacks = stacks < 1 ? 1 : stacks;
		// Texture coordinates down the profile by its length: a quarter circle, the side, a quarter circle.
		var arc = Math.PI / 2 * radius, total = 2 * arc + height;
		if (total == 0)
			total = 1;
		var rows = [];
		for (half in 0...2)
			for (j in 0...stacks + 1) {
				var phi = Math.PI / 2 * j / stacks;
				var s = j == 0 ? 0 : j == stacks ? 1 : Trig.sin(phi),
					c = j == 0 ? 1 : j == stacks ? 0 : Trig.cos(phi);
				if (half == 1) {
					// The bottom half, from its rim down to its pole.
					var t = s;
					s = c;
					c = -t;
				}
				var y = radius * c + (half == 0 ? height / 2 : -height / 2);
				var along = half == 0 ? arc * j / stacks : arc + height + arc * j / stacks;
				rows.push(new Row(radius * s, y, s, c, along / total));
			}
		lathe(m, rows, slices);
		return m;
	}

	/** Returns a torus about y, lying on the XZ plane.

		@param radius  From its center to the middle of its tube.
		@param tubeRadius  The tube's radius.
		@param slices  Around the ring, at least 3.
		@param sides  Around the tube, at least 3.
		@param out  Optional. Set to the torus.
		@return  The torus. */
	public static function fromTorus(radius:Float, tubeRadius:Float, slices:Int, sides:Int, ?out:Mesh3D):Mesh3D {
		var m = start(out);
		slices = slices < 3 ? 3 : slices;
		sides = sides < 3 ? 3 : sides;
		for (k in 0...sides + 1) {
			// Around the tube from its outside, down under it and back, so the rows run down its outside as the front is seen.
			var phi = -2 * Math.PI * (k % sides) / sides,
				cp = Trig.cos(phi),
				sp = Trig.sin(phi);
			for (i in 0...slices + 1) {
				var theta = 2 * Math.PI * (i % slices) / slices,
					ct = Trig.cos(theta),
					st = Trig.sin(theta);
				var r = radius + tubeRadius * cp;
				vertex(m, r * ct, tubeRadius * sp, -r * st, cp * ct, sp, -cp * st, i / slices, k / sides);
			}
		}
		grid(m, 0, slices, sides, null);
		return m;
	}

	/** Returns a tube wound into a (p, q) torus knot about y: p times about the y axis while q times through the ring; p 2 and q 3
		make a trefoil.

		@param radius  The ring's radius, from its center to the tube's middle at its widest.
		@param tubeRadius  The tube's radius.
		@param slices  Along the knot, at least 3.
		@param sides  Around the tube, at least 3.
		@param p  Turns about the y axis, at least 1.
		@param q  Turns through the ring, at least 1.
		@param out  Optional. Set to the knot.
		@return  The knot. */
	public static function fromTorusKnot(radius:Float, tubeRadius:Float, slices:Int, sides:Int, p:Int, q:Int, ?out:Mesh3D):Mesh3D {
		var m = start(out);
		slices = slices < 3 ? 3 : slices;
		sides = sides < 3 ? 3 : sides;
		p = p < 1 ? 1 : p;
		q = q < 1 ? 1 : q;
		var ratio = q / p;
		for (k in 0...sides + 1) {
			var phi = 2 * Math.PI * (k % sides) / sides,
				cp = Trig.cos(phi),
				sp = Trig.sin(phi);
			for (i in 0...slices + 1) {
				// The knot's middle at u, its width (radius at its widest, a third of it at its narrowest) and its height.
				var u = 2 * Math.PI * p * (i % slices) / slices, a = ratio * u;
				var cu = Trig.cos(u),
					su = Trig.sin(u),
					ca = Trig.cos(a),
					sa = Trig.sin(a);
				var w = radius * (2 + ca) / 3, dw = -radius * sa * ratio / 3;
				var cx = w * cu, cy = radius * sa / 3, cz = -w * su;
				// Its way along, and a frame square to it: out from the y axis, made square, and the third way.
				var tx = dw * cu - w * su,
					ty = radius * ca * ratio / 3,
					tz = -(dw * su + w * cu);
				var tl = Math.sqrt(tx * tx + ty * ty + tz * tz);
				tx /= tl;
				ty /= tl;
				tz /= tl;
				var bx = ty * cz - tz * cy,
					by = tz * cx - tx * cz,
					bz = tx * cy - ty * cx;
				var bl = Math.sqrt(bx * bx + by * by + bz * bz);
				bx /= bl;
				by /= bl;
				bz /= bl;
				var nx = by * tz - bz * ty,
					ny = bz * tx - bx * tz,
					nz = bx * ty - by * tx;
				var ox = cp * nx + sp * bx,
					oy = cp * ny + sp * by,
					oz = cp * nz + sp * bz;
				vertex(m, cx + tubeRadius * ox, cy + tubeRadius * oy, cz + tubeRadius * oz, ox, oy, oz, i / slices, k / sides);
			}
		}
		grid(m, 0, slices, sides, null);
		return m;
	}

	/** Returns two meshes as one: the second's vertices after the first's. What one has and the other lacks (normals, texture
		coordinates, tangents, colors) is dropped; the result has indices when either has.

		@param first  One.
		@param second  The other.
		@param out  Optional. Set to the two; may be either.
		@return  The mesh. */
	public static function merge(first:Mesh3D, second:Mesh3D, ?out:Mesh3D):Mesh3D {
		inline function both(a:Null<Array<Float>>, b:Null<Array<Float>>):Null<Array<Float>>
			return a == null || b == null ? null : a.concat(b);
		var count = first.vertexCount;
		var positions = first.positions.concat(second.positions);
		var normals = both(first.normals, second.normals),
			texCoords = both(first.texCoords, second.texCoords),
			tangents = both(first.tangents, second.tangents),
			colors = both(first.colors, second.colors);
		var indices:Null<Array<Int>> = null;
		if (first.indices != null || second.indices != null) {
			indices = first.indices != null ? first.indices.copy() : [for (i in 0...count) i];
			if (second.indices != null)
				for (i in second.indices)
					indices.push(count + i);
			else
				for (i in 0...second.vertexCount)
					indices.push(count + i);
		}
		if (out == null)
			out = new Mesh3D();
		out.positions = positions;
		out.normals = normals;
		out.texCoords = texCoords;
		out.tangents = tangents;
		out.colors = colors;
		out.indices = indices;
		return out;
	}

	/** Copies another mesh into this one, its arrays copied.

		@param other  The mesh.
		@return  This mesh. */
	public function copyFrom(other:Mesh3D):Mesh3D {
		positions = other.positions.copy();
		normals = other.normals == null ? null : other.normals.copy();
		texCoords = other.texCoords == null ? null : other.texCoords.copy();
		tangents = other.tangents == null ? null : other.tangents.copy();
		colors = other.colors == null ? null : other.colors.copy();
		indices = other.indices == null ? null : other.indices.copy();
		return this;
	}

	/** Returns the mesh moved by a transform: its positions as points, its normals by the transform's inverse transposed, made length 1
		again, and its tangents' directions as directions. A transform that turns it inside out (a negative scale on one axis) turns its
		triangles round, so their fronts stay outside.

		@param matrix  The transform.
		@param out  Optional. Set to the moved mesh; may be this one.
		@return  The moved mesh. */
	public function transform(matrix:Matrix3D, ?out:Mesh3D):Mesh3D {
		if (out == null)
			out = new Mesh3D();
		if (out != this)
			out.copyFrom(this);
		var m = matrix.values, p = out.positions;
		for (i in 0...out.vertexCount) {
			var x = p[i * 3], y = p[i * 3 + 1], z = p[i * 3 + 2];
			p[i * 3] = m[0] * x + m[4] * y + m[8] * z + m[12];
			p[i * 3 + 1] = m[1] * x + m[5] * y + m[9] * z + m[13];
			p[i * 3 + 2] = m[2] * x + m[6] * y + m[10] * z + m[14];
		}
		// The upper 3 by 3's cofactors, row by row: its inverse transposed, times its determinant.
		var c0 = m[5] * m[10] - m[9] * m[6],
			c1 = m[9] * m[2] - m[1] * m[10],
			c2 = m[1] * m[6] - m[5] * m[2];
		var c3 = m[8] * m[6] - m[4] * m[10],
			c4 = m[0] * m[10] - m[8] * m[2],
			c5 = m[4] * m[2] - m[0] * m[6];
		var c6 = m[4] * m[9] - m[8] * m[5],
			c7 = m[8] * m[1] - m[0] * m[9],
			c8 = m[0] * m[5] - m[4] * m[1];
		var determinant = m[0] * c0 + m[4] * c1 + m[8] * c2;
		var sign = determinant < 0 ? -1 : 1;
		var n = out.normals;
		if (n != null)
			for (i in 0...Std.int(n.length / 3)) {
				var x = n[i * 3], y = n[i * 3 + 1], z = n[i * 3 + 2];
				setUnit(n, i * 3, (c0 * x + c1 * y + c2 * z) * sign, (c3 * x + c4 * y + c5 * z) * sign, (c6 * x + c7 * y + c8 * z) * sign);
			}
		var t = out.tangents;
		if (t != null)
			for (i in 0...Std.int(t.length / 4)) {
				var x = t[i * 4], y = t[i * 4 + 1], z = t[i * 4 + 2];
				setUnit(t, i * 4, m[0] * x + m[4] * y + m[8] * z, m[1] * x + m[5] * y + m[9] * z, m[2] * x + m[6] * y + m[10] * z);
				t[i * 4 + 3] *= sign;
			}
		if (determinant < 0)
			out.turnRound();
		return out;
	}

	/** Returns the mesh without indices: each triangle's three vertices its own, in order. With `computeNormals` after it, a shape whose
		triangles' normals are each their own, so its faces look flat.

		@param out  Optional. Set to the result; may be this one.
		@return  The mesh. */
	public function toUnindexed(?out:Mesh3D):Mesh3D {
		if (out == null)
			out = new Mesh3D();
		var order = indices;
		inline function spread(values:Null<Array<Float>>, size:Int):Null<Array<Float>>
			return values == null ? null : order == null ? values.copy() : [for (i in order) for (c in 0...size) values[i * size + c]];
		var positions = spread(this.positions, 3),
			normals = spread(this.normals, 3),
			texCoords = spread(this.texCoords, 2),
			tangents = spread(this.tangents, 4),
			colors = spread(this.colors, 4);
		out.positions = positions;
		out.normals = normals;
		out.texCoords = texCoords;
		out.tangents = tangents;
		out.colors = colors;
		out.indices = null;
		return out;
	}

	/** Returns normals from the triangles: each vertex's the sum of the triangles it is a corner of, weighted by their areas, made length
		1. Given a weld distance, vertices nearer each other than it share one normal, so a shape with doubled vertices on its seams stays
		smooth across them.

		@param weldDistance  Optional. How near vertices share a normal, 0 for those at the very same point. Omitted, none share: a
			vertex's normal is its own triangles' alone, so a mesh without indices (`toUnindexed`) has a flat normal on each triangle.
		@param out  Optional. Set to the normals, x, y and z a vertex.
		@return  The normals; assign them to `normals` to use them. */
	public function computeNormals(?weldDistance:Float, ?out:Array<Float>):Array<Float> {
		var count = vertexCount, p = positions;
		var sums = [for (_ in 0...count * 3) 0.];
		for (k in 0...triangleCount) {
			var a = corner(k, 0), b = corner(k, 1), c = corner(k, 2);
			var e1x = p[b * 3] - p[a * 3],
				e1y = p[b * 3 + 1] - p[a * 3 + 1],
				e1z = p[b * 3 + 2] - p[a * 3 + 2];
			var e2x = p[c * 3] - p[a * 3],
				e2y = p[c * 3 + 1] - p[a * 3 + 1],
				e2z = p[c * 3 + 2] - p[a * 3 + 2];
			// The cross product's length is twice the triangle's area, which weights it.
			var nx = e1y * e2z - e1z * e2y,
				ny = e1z * e2x - e1x * e2z,
				nz = e1x * e2y - e1y * e2x;
			for (v in [a, b, c]) {
				sums[v * 3] += nx;
				sums[v * 3 + 1] += ny;
				sums[v * 3 + 2] += nz;
			}
		}
		if (weldDistance != null) {
			var groups = weld(weldDistance);
			var shared = [for (_ in 0...count * 3) 0.];
			for (v in 0...count)
				for (c in 0...3)
					shared[groups[v] * 3 + c] += sums[v * 3 + c];
			for (v in 0...count)
				for (c in 0...3)
					sums[v * 3 + c] = shared[groups[v] * 3 + c];
		}
		if (out == null)
			out = [];
		out.resize(count * 3);
		for (v in 0...count)
			setUnit(out, v * 3, sums[v * 3], sums[v * 3 + 1], sums[v * 3 + 2]);
		return out;
	}

	/** Returns tangents from the positions, texture coordinates and normals, for normal mapping: for each vertex, the way u grows across
		the triangles it is a corner of, made square to its normal, and w the way v grows. It reads the triangles by their indices, or the
		vertices three at a time when there are none.

		@param out  Optional. Set to the tangents, x, y, z and w a vertex.
		@return  The tangents, to assign to `tangents`; null for a mesh without texture coordinates or normals. */
	public function computeTangents(?out:Array<Float>):Null<Array<Float>> {
		var uv = texCoords, n = normals, p = positions;
		if (uv == null || n == null)
			return null;
		var count = vertexCount;
		var along = [for (_ in 0...count * 3) 0.],
			up = [for (_ in 0...count * 3) 0.];
		for (k in 0...triangleCount) {
			var a = corner(k, 0), b = corner(k, 1), c = corner(k, 2);
			var x1 = p[b * 3] - p[a * 3],
				y1 = p[b * 3 + 1] - p[a * 3 + 1],
				z1 = p[b * 3 + 2] - p[a * 3 + 2];
			var x2 = p[c * 3] - p[a * 3],
				y2 = p[c * 3 + 1] - p[a * 3 + 1],
				z2 = p[c * 3 + 2] - p[a * 3 + 2];
			var s1 = uv[b * 2] - uv[a * 2], t1 = uv[b * 2 + 1] - uv[a * 2 + 1];
			var s2 = uv[c * 2] - uv[a * 2], t2 = uv[c * 2 + 1] - uv[a * 2 + 1];
			var d = s1 * t2 - s2 * t1;
			if (d == 0)
				continue;
			var r = 1 / d;
			var sx = (t2 * x1 - t1 * x2) * r,
				sy = (t2 * y1 - t1 * y2) * r,
				sz = (t2 * z1 - t1 * z2) * r;
			var tx = (s1 * x2 - s2 * x1) * r,
				ty = (s1 * y2 - s2 * y1) * r,
				tz = (s1 * z2 - s2 * z1) * r;
			for (v in [a, b, c]) {
				along[v * 3] += sx;
				along[v * 3 + 1] += sy;
				along[v * 3 + 2] += sz;
				up[v * 3] += tx;
				up[v * 3 + 1] += ty;
				up[v * 3 + 2] += tz;
			}
		}
		if (out == null)
			out = [];
		out.resize(count * 4);
		for (v in 0...count) {
			var nx = n[v * 3], ny = n[v * 3 + 1], nz = n[v * 3 + 2];
			var sx = along[v * 3],
				sy = along[v * 3 + 1],
				sz = along[v * 3 + 2];
			// Made square to the normal; where u doesn't grow, any way square to it.
			var dot = nx * sx + ny * sy + nz * sz;
			sx -= nx * dot;
			sy -= ny * dot;
			sz -= nz * dot;
			if (sx * sx + sy * sy + sz * sz < 1e-24) {
				if (Math.abs(nx) < .9) {
					sx = 0;
					sy = nz;
					sz = -ny;
				} else {
					sx = -nz;
					sy = 0;
					sz = nx;
				}
			}
			setUnit(out, v * 4, sx, sy, sz);
			var bx = ny * out[v * 4 + 2] - nz * out[v * 4 + 1],
				by = nz * out[v * 4] - nx * out[v * 4 + 2],
				bz = nx * out[v * 4 + 1] - ny * out[v * 4];
			out[v * 4 + 3] = bx * up[v * 3] + by * up[v * 3 + 1] + bz * up[v * 3 + 2] < 0 ? -1 : 1;
		}
		return out;
	}

	/** Returns the bounds of its positions.

		@param out  Optional. Set to the bounds.
		@return  The bounds; empty for a mesh without positions. */
	public function computeBounds(?out:Bounds3D):Bounds3D {
		if (out == null)
			out = new Bounds3D();
		out.makeEmpty();
		var p = positions;
		for (i in 0...vertexCount)
			out.expand(p[i * 3], p[i * 3 + 1], p[i * 3 + 2]);
		return out;
	}

	// The vertex at a triangle's corner.
	inline function corner(triangle:Int, at:Int):Int
		return indices == null ? triangle * 3 + at : indices[triangle * 3 + at];

	// Each vertex's group: the lowest vertex of those within the distance of it, or of one within it, as one.
	function weld(distance:Float):Array<Int> {
		var count = vertexCount, p = positions;
		var parent = [for (i in 0...count) i];
		function root(i:Int):Int {
			while (parent[i] != i) {
				parent[i] = parent[parent[i]];
				i = parent[i];
			}
			return i;
		}
		function join(a:Int, b:Int):Void {
			var ra = root(a), rb = root(b);
			if (ra < rb)
				parent[rb] = ra;
			else if (rb < ra)
				parent[ra] = rb;
		}
		// Vertices in cells of the distance's size, so only a cell and its neighbors need comparing; at 0, at the very same point.
		var cells = new Map<String, Array<Int>>();
		var size = distance > 0 ? distance : 1.;
		for (v in 0...count) {
			var x = p[v * 3], y = p[v * 3 + 1], z = p[v * 3 + 2];
			if (distance <= 0) {
				// Plus 0, so -0 and 0 are one point.
				var key = '${x + 0},${y + 0},${z + 0}';
				var found = cells.get(key);
				if (found == null)
					cells.set(key, [v]);
				else
					join(found[0], v);
				continue;
			}
			var cx = Math.floor(x / size),
				cy = Math.floor(y / size),
				cz = Math.floor(z / size);
			for (dx in -1...2)
				for (dy in -1...2)
					for (dz in -1...2) {
						var near = cells.get('${cx + dx},${cy + dy},${cz + dz}');
						if (near != null)
							for (w in near) {
								var ex = p[w * 3] - x,
									ey = p[w * 3 + 1] - y,
									ez = p[w * 3 + 2] - z;
								if (ex * ex + ey * ey + ez * ez < distance * distance)
									join(w, v);
							}
					}
			var key = '$cx,$cy,$cz';
			var own = cells.get(key);
			if (own == null)
				cells.set(key, [v]);
			else
				own.push(v);
		}
		return [for (v in 0...count) root(v)];
	}

	// Turns each triangle round: its second and third corners swapped.
	function turnRound():Void {
		if (indices != null) {
			var k = 0;
			while (k + 2 < indices.length) {
				var swap = indices[k + 1];
				indices[k + 1] = indices[k + 2];
				indices[k + 2] = swap;
				k += 3;
			}
			return;
		}
		for (values in [positions, normals, texCoords, tangents, colors]) {
			if (values == null)
				continue;
			var size = Std.int(values.length / vertexCount);
			for (k in 0...triangleCount)
				for (c in 0...size) {
					var b = (k * 3 + 1) * size + c, d = (k * 3 + 2) * size + c;
					var swap = values[b];
					values[b] = values[d];
					values[d] = swap;
				}
		}
	}

	// A mesh to make a shape into, its arrays emptied: the one given, or a new one.
	static function start(out:Null<Mesh3D>):Mesh3D {
		if (out == null)
			out = new Mesh3D();
		out.positions.resize(0);
		out.normals = empty(out.normals);
		out.texCoords = empty(out.texCoords);
		out.tangents = null;
		out.colors = null;
		out.indices = out.indices == null ? [] : out.indices;
		out.indices.resize(0);
		return out;
	}

	static function empty(values:Null<Array<Float>>):Array<Float> {
		if (values == null)
			return [];
		values.resize(0);
		return values;
	}

	static inline function vertex(m:Mesh3D, x:Float, y:Float, z:Float, nx:Float, ny:Float, nz:Float, u:Float, v:Float):Void {
		m.positions.push(x);
		m.positions.push(y);
		m.positions.push(z);
		m.normals.push(nx);
		m.normals.push(ny);
		m.normals.push(nz);
		m.texCoords.push(u);
		m.texCoords.push(v);
	}

	// Two triangles a cell of a grid of vertices from first, columns + 1 a row, row 0 the top as the front is seen. A row flat (of no
	// width, a pole) gives its cells one triangle, with the pole's vertex to the cell's right.
	static function grid(m:Mesh3D, first:Int, columns:Int, rows:Int, flat:Null<Array<Bool>>):Void {
		for (j in 0...rows)
			for (i in 0...columns) {
				var a = first + j * (columns + 1) + i, b = a + 1, c = a + columns + 1, d = c + 1;
				if (flat == null || !flat[j + 1]) {
					m.indices.push(c);
					m.indices.push(d);
					m.indices.push(b);
				}
				if (flat == null || !flat[j]) {
					m.indices.push(flat != null && flat[j + 1] ? d : c);
					m.indices.push(b);
					m.indices.push(a);
				}
			}
	}

	// A surface turned about y, its profile's rows from the top down; a row of radius 0 is a pole, each of its vertices' u in the middle of
	// the slice to its left, the one its triangle covers (the first, on no triangle, at 0).
	static function lathe(m:Mesh3D, rows:Array<Row>, slices:Int):Void {
		slices = slices < 3 ? 3 : slices;
		var first = m.vertexCount;
		for (row in rows)
			for (i in 0...slices + 1) {
				var u = row.radius == 0 ? (i == 0 ? 0 : (i - .5) / slices) : i / slices;
				// The seam's last column at the first's very angle, so its vertices are at the same points.
				var theta = 2 * Math.PI * (i % slices) / slices,
					ct = Trig.cos(theta),
					st = Trig.sin(theta);
				vertex(m, row.radius * ct, row.y, -row.radius * st, row.normalOut * ct, row.normalUp, -row.normalOut * st, u, row.v);
			}
		grid(m, first, slices, rows.length - 1, [for (row in rows) row.radius == 0]);
	}

	// A disk at a height, facing up or down, from its center.
	static function disk(m:Mesh3D, radius:Float, y:Float, slices:Int, up:Bool):Void {
		var first = m.vertexCount, ny = up ? 1 : -1;
		vertex(m, 0, y, 0, 0, ny, 0, .5, .5);
		for (i in 0...slices) {
			var theta = 2 * Math.PI * i / slices,
				ct = Trig.cos(theta),
				st = Trig.sin(theta);
			// Seen from the side it faces, the texture's top away from +z on top and toward it underneath.
			vertex(m, radius * ct, y, -radius * st, 0, ny, 0, .5 + .5 * ct, up ? .5 - .5 * st : .5 + .5 * st);
		}
		for (i in 0...slices) {
			var a = first + 1 + i, b = first + 1 + (i + 1) % slices;
			m.indices.push(first);
			m.indices.push(up ? a : b);
			m.indices.push(up ? b : a);
		}
	}

	// Sets three numbers made length 1, or 0 when they are all 0.
	static inline function setUnit(values:Array<Float>, at:Int, x:Float, y:Float, z:Float):Void {
		var length = Math.sqrt(x * x + y * y + z * z);
		if (length > 0) {
			x /= length;
			y /= length;
			z /= length;
		}
		values[at] = x;
		values[at + 1] = y;
		values[at + 2] = z;
	}
}

/** Represents a row of a turned surface's profile: its radius and height, its normal's way out and way up, and its texture's v. */
private class Row {
	/** Gets its distance from the y axis. */
	public final radius:Float;

	/** Gets its height. */
	public final y:Float;

	/** Gets its normal's part out from the axis. */
	public final normalOut:Float;

	/** Gets its normal's part along +y. */
	public final normalUp:Float;

	/** Gets its texture's v. */
	public final v:Float;

	/** Creates a row.

		@param radius  Its distance from the y axis.
		@param y  Its height.
		@param normalOut  Its normal's part out from the axis.
		@param normalUp  Its normal's part along +y.
		@param v  Its texture's v. */
	public function new(radius:Float, y:Float, normalOut:Float, normalUp:Float, v:Float) {
		this.radius = radius;
		this.y = y;
		this.normalOut = normalOut;
		this.normalUp = normalUp;
		this.v = v;
	}
}
