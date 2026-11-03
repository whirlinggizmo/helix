package helix.raylib.internal;

import helix.math.Trig;

/** The part of par_shapes (Philip Rideout's, MIT, `vendor/par_shapes/LICENSE`) raylib's `GenMesh*` functions use, ported: its parametric
	surfaces, its disk, and its moves, merge and welded normals, step for step, so a generated mesh has raylib's vertices in raylib's order.
	Its trigonometry is `Trig`'s, so a mesh comes out the same on every target. */
@:noCompletion
class ParShapes {
	static inline final PI = 3.14159265359;

	/** The distance squared under which two points share a normal, `par_shapes__epsilon_welded_normals`. */
	static final epsilonWeldedNormals = 0.001;

	/** The area under which a sphere's triangles are dropped, set by `setEpsilonDegenerateSphere` and kept, as par_shapes keeps it, until
		it is set again. */
	static var epsilonDegenerateSphere = 0.0001;

	/** Sets the area under which a sphere's or a hemisphere's triangles are dropped, from then on.

		@param epsilon  The area. */
	public static function setEpsilonDegenerateSphere(epsilon:Float):Void {
		epsilonDegenerateSphere = epsilon;
	}

	/** Returns a cylinder of radius 1 along z from 0 to 1, open at both ends.

		@param slices  Around.
		@param stacks  Along.
		@return  The mesh, or null for fewer than 3 slices or 1 stack. */
	public static function cylinder(slices:Int, stacks:Int):Null<ParMesh> {
		if (slices < 3 || stacks < 1)
			return null;
		return parametric((u, v, xyz) -> {
			var theta = v * 2 * PI;
			xyz[0] = Trig.sin(theta);
			xyz[1] = Trig.cos(theta);
			xyz[2] = u;
		}, slices, stacks);
	}

	/** Returns a cone of radius 1 at z 0 to its point at z 1, open at its base.

		@param slices  Around.
		@param stacks  Along.
		@return  The mesh, or null for fewer than 3 slices or 1 stack. */
	public static function cone(slices:Int, stacks:Int):Null<ParMesh> {
		if (slices < 3 || stacks < 1)
			return null;
		return parametric((u, v, xyz) -> {
			var r = 1.0 - u, theta = v * 2 * PI;
			xyz[0] = r * Trig.sin(theta);
			xyz[1] = r * Trig.cos(theta);
			xyz[2] = u;
		}, slices, stacks);
	}

	/** Returns a sphere of radius 1, its poles on z, its triangles under the degenerate area dropped.

		@param slices  Around.
		@param stacks  Pole to pole.
		@return  The mesh, or null for fewer than 3 of either. */
	public static function sphere(slices:Int, stacks:Int):Null<ParMesh> {
		if (slices < 3 || stacks < 3)
			return null;
		var m = parametric((u, v, xyz) -> {
			var phi = u * PI, theta = v * 2 * PI;
			xyz[0] = Trig.cos(theta) * Trig.sin(phi);
			xyz[1] = Trig.sin(theta) * Trig.sin(phi);
			xyz[2] = Trig.cos(phi);
		}, slices, stacks);
		removeDegenerate(m, epsilonDegenerateSphere);
		return m;
	}

	/** Returns half a sphere of radius 1, on the side of +y, its triangles under the degenerate area dropped.

		@param slices  Around.
		@param stacks  Pole to pole.
		@return  The mesh, or null for fewer than 3 of either. */
	public static function hemisphere(slices:Int, stacks:Int):Null<ParMesh> {
		if (slices < 3 || stacks < 3)
			return null;
		var m = parametric((u, v, xyz) -> {
			var phi = u * PI, theta = v * PI;
			xyz[0] = Trig.cos(theta) * Trig.sin(phi);
			xyz[1] = Trig.sin(theta) * Trig.sin(phi);
			xyz[2] = Trig.cos(phi);
		}, slices, stacks);
		removeDegenerate(m, epsilonDegenerateSphere);
		return m;
	}

	/** Returns a torus about z, its ring of radius 1.

		@param slices  Around the ring.
		@param stacks  Around the tube.
		@param radius  The tube's radius.
		@return  The mesh, or null for fewer than 3 of either. */
	public static function torus(slices:Int, stacks:Int, radius:Float):Null<ParMesh> {
		if (slices < 3 || stacks < 3)
			return null;
		return parametric((u, v, xyz) -> {
			var major = 1, minor = radius;
			var theta = u * 2 * PI, phi = v * 2 * PI;
			var beta = major + minor * Trig.cos(phi);
			xyz[0] = Trig.cos(theta) * beta;
			xyz[1] = Trig.sin(theta) * beta;
			xyz[2] = Trig.sin(phi) * minor;
		}, slices, stacks);
	}

	/** Returns a trefoil knot.

		@param slices  Along the knot.
		@param stacks  Around its tube.
		@param radius  The tube's radius, a tenth of it.
		@return  The mesh, or null for fewer than 3 of either. */
	public static function trefoilKnot(slices:Int, stacks:Int, radius:Float):Null<ParMesh> {
		if (slices < 3 || stacks < 3)
			return null;
		return parametric((uv0, uv1, xyz) -> {
			var minor = radius;
			var a = 0.5, b = 0.3, c = 0.5, d = minor * 0.1;
			var u = (1 - uv0) * 4 * PI, v = uv1 * 2 * PI;
			var r = a + b * Trig.cos(1.5 * u);
			var x = r * Trig.cos(u),
				y = r * Trig.sin(u),
				z = c * Trig.sin(1.5 * u);
			var q = [
				-1.5 * b * Trig.sin(1.5 * u) * Trig.cos(u) - (a + b * Trig.cos(1.5 * u)) * Trig.sin(u),
				-1.5 * b * Trig.sin(1.5 * u) * Trig.sin(u) + (a + b * Trig.cos(1.5 * u)) * Trig.cos(u),
				1.5 * c * Trig.cos(1.5 * u)
			];
			normalize3(q, 0);
			var qvn = [q[1], -q[0], 0.];
			normalize3(qvn, 0);
			var ww = cross3(q, qvn);
			xyz[0] = x + d * (qvn[0] * Trig.cos(v) + ww[0] * Trig.sin(v));
			xyz[1] = y + d * (qvn[1] * Trig.cos(v) + ww[1] * Trig.sin(v));
			xyz[2] = z + d * ww[2] * Trig.sin(v);
		}, slices, stacks);
	}

	/** Returns a disk, its normal on each point and no texture coordinates.

		@param radius  Its radius.
		@param slices  Around.
		@param center  Its center, x, y and z.
		@param normal  The way it faces.
		@return  The mesh. */
	public static function disk(radius:Float, slices:Int, center:Array<Float>, normal:Array<Float>):ParMesh {
		var points = [0., 0, 0];
		for (i in 0...slices) {
			var theta = i * PI * 2 / slices;
			points.push(radius * Trig.cos(theta));
			points.push(radius * Trig.sin(theta));
			points.push(0);
		}
		var n = normal.copy();
		normalize3(n, 0);
		var mesh = new ParMesh(points, [], [for (_ in 0...slices + 1) for (c in n) c], null);
		for (i in 0...slices) {
			mesh.triangles.push(0);
			mesh.triangles.push(1 + i);
			mesh.triangles.push(1 + (i + 1) % slices);
		}
		var axis = cross3(n, [0, 0, -1]);
		normalize3(axis, 0);
		rotate(mesh, Trig.acos(n[2]), axis);
		translate(mesh, center[0], center[1], center[2]);
		return mesh;
	}

	/** Moves a mesh's points.

		@param m  The mesh.
		@param x  By x.
		@param y  By y.
		@param z  By z. */
	public static function translate(m:ParMesh, x:Float, y:Float, z:Float):Void {
		var p = m.points;
		for (i in 0...m.npoints) {
			p[i * 3] += x;
			p[i * 3 + 1] += y;
			p[i * 3 + 2] += z;
		}
	}

	/** Turns a mesh's points and normals about an axis through the origin.

		@param mesh  The mesh.
		@param radians  The angle.
		@param axis  The axis, of length 1. */
	public static function rotate(mesh:ParMesh, radians:Float, axis:Array<Float>):Void {
		var s = Trig.sin(radians), c = Trig.cos(radians);
		var x = axis[0], y = axis[1], z = axis[2];
		var xy = x * y, yz = y * z, zx = z * x, oneMinusC = 1.0 - c;
		var col0 = [((x * x) * oneMinusC) + c, (xy * oneMinusC) + (z * s), (zx * oneMinusC) - (y * s)];
		var col1 = [(xy * oneMinusC) - (z * s), ((y * y) * oneMinusC) + c, (yz * oneMinusC) + (x * s)];
		var col2 = [(zx * oneMinusC) + (y * s), (yz * oneMinusC) - (x * s), ((z * z) * oneMinusC) + c];
		function turn(v:Array<Float>):Void {
			for (i in 0...mesh.npoints) {
				var a = v[i * 3], b = v[i * 3 + 1], d = v[i * 3 + 2];
				v[i * 3] = col0[0] * a + col1[0] * b + col2[0] * d;
				v[i * 3 + 1] = col0[1] * a + col1[1] * b + col2[1] * d;
				v[i * 3 + 2] = col0[2] * a + col1[2] * b + col2[2] * d;
			}
		}
		turn(mesh.points);
		if (mesh.normals != null)
			turn(mesh.normals);
	}

	/** Scales a mesh's points, and turns its normals to match when the scale isn't the same each way.

		@param m  The mesh.
		@param x  By x.
		@param y  By y.
		@param z  By z. */
	public static function scale(m:ParMesh, x:Float, y:Float, z:Float):Void {
		var p = m.points;
		for (i in 0...m.npoints) {
			p[i * 3] *= x;
			p[i * 3 + 1] *= y;
			p[i * 3 + 2] *= z;
		}
		var n = m.normals;
		if (n != null && !(x == y && y == z)) {
			var xZero = x == 0, yZero = y == 0, zZero = z == 0;
			if (!xZero && !yZero && !zZero) {
				x = 1.0 / x;
				y = 1.0 / y;
				z = 1.0 / z;
			} else {
				x = xZero && !yZero && !zZero ? 1 : 0;
				y = yZero && !xZero && !zZero ? 1 : 0;
				z = zZero && !xZero && !yZero ? 1 : 0;
			}
			for (i in 0...m.npoints) {
				n[i * 3] *= x;
				n[i * 3 + 1] *= y;
				n[i * 3 + 2] *= z;
				normalize3(n, i * 3);
			}
		}
	}

	/** Adds a mesh's points and triangles to another's, after its own; the normals and texture coordinates of a mesh without them read
		as 0.

		@param dst  The mesh added to.
		@param src  The mesh added. */
	public static function merge(dst:ParMesh, src:ParMesh):Void {
		var offset = dst.npoints;
		var npoints = dst.npoints + src.npoints;
		for (v in src.points)
			dst.points.push(v);
		if (src.normals != null || dst.normals != null) {
			if (dst.normals == null)
				dst.normals = [for (_ in 0...offset * 3) 0.];
			for (i in 0...src.npoints * 3)
				dst.normals.push(src.normals != null ? src.normals[i] : 0);
		}
		if (src.tcoords != null || dst.tcoords != null) {
			if (dst.tcoords == null)
				dst.tcoords = [for (_ in 0...offset * 2) 0.];
			for (i in 0...src.npoints * 2)
				dst.tcoords.push(src.tcoords != null ? src.tcoords[i] : 0);
		}
		for (t in src.triangles)
			dst.triangles.push(offset + t);
		dst.npoints = npoints;
	}

	// par_shapes_create_parametric: (slices + 1) by (stacks + 1) points, two triangles a cell, and normals shared by points that meet.
	static function parametric(fn:(u:Float, v:Float, xyz:Array<Float>) -> Void, slices:Int, stacks:Int):ParMesh {
		var points = [], tcoords = [], xyz = [0., 0, 0];
		for (stack in 0...stacks + 1) {
			var u = stack / stacks;
			for (slice in 0...slices + 1) {
				fn(u, slice / slices, xyz);
				points.push(xyz[0]);
				points.push(xyz[1]);
				points.push(xyz[2]);
			}
		}
		for (stack in 0...stacks + 1)
			for (slice in 0...slices + 1) {
				tcoords.push(stack / stacks);
				tcoords.push(slice / slices);
			}
		var triangles = [], v = 0;
		for (stack in 0...stacks) {
			for (slice in 0...slices) {
				var next = slice + 1;
				for (t in [
					v + slice + slices + 1,
					v + next,
					v + slice,
					v + slice + slices + 1,
					v + next + slices + 1,
					v + next
				])
					triangles.push(t);
			}
			v += slices + 1;
		}
		var mesh = new ParMesh(points, triangles, null, tcoords);
		computeWeldedNormals(mesh);
		return mesh;
	}

	// Each point's normal, that of all the points within the weld's distance of it, as if they were one.
	static function computeWeldedNormals(m:ParMesh):Void {
		var weldmap = [];
		var welded = weld(m, epsilonWeldedNormals, weldmap);
		computeNormals(welded);
		m.normals = [];
		for (i in 0...m.npoints) {
			var d = weldmap[i];
			for (c in 0...3)
				m.normals.push(welded.normals[d * 3 + c]);
		}
	}

	// Each point's normal, the sum of its triangles' cross products, made length 1.
	static function computeNormals(m:ParMesh):Void {
		var n = [for (_ in 0...m.npoints * 3) 0.], p = m.points, t = m.triangles;
		for (f in 0...m.ntriangles) {
			var a = t[f * 3], b = t[f * 3 + 1], c = t[f * 3 + 2];
			for (corner in [[a, b, c], [b, c, a], [c, a, b]]) {
				var o = corner[0] * 3, i = corner[1] * 3, j = corner[2] * 3;
				var nx = p[i] - p[o],
					ny = p[i + 1] - p[o + 1],
					nz = p[i + 2] - p[o + 2];
				var px = p[j] - p[o],
					py = p[j + 1] - p[o + 1],
					pz = p[j + 2] - p[o + 2];
				n[o] += ny * pz - nz * py;
				n[o + 1] += nz * px - nx * pz;
				n[o + 2] += nx * py - ny * px;
			}
		}
		for (i in 0...m.npoints)
			normalize3(n, i * 3);
		m.normals = n;
	}

	// par_shapes_weld: a copy with the points nearer than epsilon (squared, as par_shapes compares) made one, found in a 20-cell grid
	// over the mesh's bounds; weldmap gets each point's index in it.
	static function weld(mesh:ParMesh, epsilon:Float, weldmap:Array<Int>):ParMesh {
		var clone = new ParMesh(mesh.points.copy(), mesh.triangles.copy(), null, null);
		var gridsize = 20, maxcell = gridsize - 1.;
		var aabb = computeAabb(clone);
		var s = [
			aabb[3] == aabb[0] ? 1.0 : maxcell / (aabb[3] - aabb[0]),
			aabb[4] == aabb[1] ? 1.0 : maxcell / (aabb[4] - aabb[1]),
			aabb[5] == aabb[2] ? 1.0 : maxcell / (aabb[5] - aabb[2])
		];
		translate(clone, -aabb[0], -aabb[1], -aabb[2]);
		scale(clone, s[0], s[1], s[2]);
		var sortmap = sortPoints(clone, gridsize);
		for (i in 0...mesh.npoints)
			weldmap[i] = i;
		weldPoints(clone, gridsize, epsilon, weldmap);
		var newmap = [for (i in 0...mesh.npoints) weldmap[sortmap[i]]];
		for (i in 0...mesh.npoints)
			weldmap[i] = newmap[i];
		scale(clone, 1.0 / s[0], 1.0 / s[1], 1.0 / s[2]);
		translate(clone, aabb[0], aabb[1], aabb[2]);
		return clone;
	}

	static function computeAabb(m:ParMesh):Array<Float> {
		var p = m.points;
		var aabb = [p[0], p[1], p[2], p[0], p[1], p[2]];
		for (i in 1...m.npoints)
			for (c in 0...3) {
				var v = p[i * 3 + c];
				if (aabb[c] > v)
					aabb[c] = v;
				if (v > aabb[c + 3])
					aabb[c + 3] = v;
			}
		return aabb;
	}

	// The flattened grid cell a point (in grid units) is in.
	static inline function cell(p:Array<Float>, at:Int, g:Int):Int {
		return Std.int(p[at]) + g * Std.int(p[at + 1]) + g * g * Std.int(p[at + 2]);
	}

	// Sorts the points by their cell, renumbering the triangles; returns each point's new index by its old.
	static function sortPoints(mesh:ParMesh, gridsize:Int):Array<Int> {
		var sortmap = [for (i in 0...mesh.npoints) i];
		var points = mesh.points;
		haxe.ds.ArraySort.sort(sortmap, (a, b) -> {
			var i0 = cell(points, a * 3, gridsize),
				i1 = cell(points, b * 3, gridsize);
			i0 < i1 ? -1 : i0 > i1 ? 1 : 0;
		});
		var newpts = [], invmap = [for (_ in 0...mesh.npoints) 0];
		for (i in 0...mesh.npoints) {
			invmap[sortmap[i]] = i;
			for (c in 0...3)
				newpts.push(points[sortmap[i] * 3 + c]);
		}
		mesh.points = newpts;
		mesh.triangles = [for (t in mesh.triangles) invmap[t]];
		return invmap;
	}

	static function weldPoints(mesh:ParMesh, gridsize:Int, epsilon:Float, weldmap:Array<Int>):Void {
		// Each cell's first point, plus 1, 0 for none; the points are sorted by cell.
		var bins = [for (_ in 0...gridsize * gridsize * gridsize) 0];
		var pts = mesh.points;
		var prev = -1;
		for (p in 0...mesh.npoints) {
			var index = cell(pts, p * 3, gridsize);
			if (index != prev)
				bins[index] = 1 + p;
			prev = index;
		}
		var nremoved = 0;
		for (p in 0...mesh.npoints) {
			if (weldmap[p] != p)
				continue;
			var nearby = [];
			var minp = [for (c in 0...3) Std.int(pts[p * 3 + c] - epsilon)],
				maxp = [for (c in 0...3) Std.int(pts[p * 3 + c] + epsilon)];
			for (i in minp[0]...maxp[0] + 1)
				for (j in minp[1]...maxp[1] + 1)
					for (k in minp[2]...maxp[2] + 1) {
						var index = i + gridsize * j + gridsize * gridsize * k;
						if (index >= 0 && index < bins.length && bins[index] > 0 && nearby.length < 8)
							nearby.push(index);
					}
			for (binindex in nearby) {
				var nindex = bins[binindex] - 1;
				while (true) {
					if (nindex != p && weldmap[nindex] == nindex) {
						var dx = pts[nindex * 3] - pts[p * 3],
							dy = pts[nindex * 3 + 1] - pts[p * 3 + 1],
							dz = pts[nindex * 3 + 2] - pts[p * 3 + 2];
						if (dx * dx + dy * dy + dz * dz < epsilon) {
							weldmap[nindex] = p;
							nremoved++;
						}
					}
					if (++nindex >= mesh.npoints)
						break;
					if (cell(pts, nindex * 3, gridsize) != binindex)
						break;
				}
			}
		}
		var newpts = [], condensed = [for (_ in 0...mesh.npoints) 0], ci = 0;
		for (p in 0...mesh.npoints) {
			if (weldmap[p] == p) {
				for (c in 0...3)
					newpts.push(pts[p * 3 + c]);
				condensed[p] = ci++;
			} else
				condensed[p] = condensed[weldmap[p]];
		}
		for (p in 0...mesh.npoints)
			weldmap[p] = condensed[p];
		mesh.points = newpts;
		mesh.npoints = mesh.npoints - nremoved;
		var triangles = [], t = mesh.triangles;
		for (i in 0...mesh.ntriangles) {
			var a = weldmap[t[i * 3]],
				b = weldmap[t[i * 3 + 1]],
				c = weldmap[t[i * 3 + 2]];
			if (a != b && a != c && b != c) {
				triangles.push(a);
				triangles.push(b);
				triangles.push(c);
			}
		}
		mesh.triangles = triangles;
	}

	// Drops the triangles whose area is under mintriarea.
	static function removeDegenerate(mesh:ParMesh, mintriarea:Float):Void {
		var triangles = [], p = mesh.points, t = mesh.triangles;
		var mincplen2 = (mintriarea * 2) * (mintriarea * 2);
		for (f in 0...mesh.ntriangles) {
			var a = t[f * 3] * 3, b = t[f * 3 + 1] * 3, c = t[f * 3 + 2] * 3;
			var next = [p[b] - p[a], p[b + 1] - p[a + 1], p[b + 2] - p[a + 2]],
				prev = [p[c] - p[a], p[c + 1] - p[a + 1], p[c + 2] - p[a + 2]];
			var cp = cross3(next, prev);
			if (cp[0] * cp[0] + cp[1] * cp[1] + cp[2] * cp[2] >= mincplen2) {
				triangles.push(t[f * 3]);
				triangles.push(t[f * 3 + 1]);
				triangles.push(t[f * 3 + 2]);
			}
		}
		mesh.triangles = triangles;
	}

	static function cross3(a:Array<Float>, b:Array<Float>):Array<Float> {
		return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
	}

	static function normalize3(v:Array<Float>, at:Int):Void {
		var lsqr = Math.sqrt(v[at] * v[at] + v[at + 1] * v[at + 1] + v[at + 2] * v[at + 2]);
		if (lsqr > 0) {
			var s = 1.0 / lsqr;
			v[at] *= s;
			v[at + 1] *= s;
			v[at + 2] *= s;
		}
	}
}

/** A mesh as par_shapes holds it: points, three numbers each; triangles, three indices each; and normals and texture coordinates a
	point, either null for none. */
@:noCompletion
class ParMesh {
	/** The points, x, y and z each. */
	public var points:Array<Float>;

	/** The triangles, three point indices each, counterclockwise from the front. */
	public var triangles:Array<Int>;

	/** The normals, x, y and z a point, or null. */
	public var normals:Null<Array<Float>>;

	/** The texture coordinates, u and v a point, or null. */
	public var tcoords:Null<Array<Float>>;

	/** Gets or sets the number of points. */
	public var npoints:Int;

	/** Gets the number of triangles. */
	public var ntriangles(get, never):Int;

	function get_ntriangles():Int
		return Std.int(triangles.length / 3);

	/** Creates a mesh.

		@param points  The points.
		@param triangles  The triangles.
		@param normals  The normals, or null.
		@param tcoords  The texture coordinates, or null. */
	public function new(points:Array<Float>, triangles:Array<Int>, normals:Null<Array<Float>>, tcoords:Null<Array<Float>>) {
		this.points = points;
		this.triangles = triangles;
		this.normals = normals;
		this.tcoords = tcoords;
		npoints = Std.int(points.length / 3);
	}
}
