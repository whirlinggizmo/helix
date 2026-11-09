import helix.geometry.Mesh3D;
import helix.math.Bounds3D;
import helix.math.Matrix3D;

/** Checks Mesh3D with the library alone: each shape's triangles facing out (its volume, summed from them, positive and near the
	shape's), its closed shapes closed (each edge, its seams' doubled vertices as one, on two triangles), no triangle of no area, its
	points on the shape, its normals of length 1 and out of it, its texture coordinates 0 to 1; normals computed smooth, welded across
	seams, and flat once unindexed; tangents along u, square to the normal, their w the way v grows; a transform moving points, turning
	normals and tangents and, mirrored, turning the triangles round; merging; copying; bounds; and each shape into the mesh given. */
class Mesh3DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-9):Bool
		return Math.abs(a - b) <= tolerance;

	static inline function corner(m:Mesh3D, k:Int, c:Int):Int
		return m.indices == null ? k * 3 + c : m.indices[k * 3 + c];

	// The volume the triangles enclose, by the divergence theorem: positive when they face out.
	static function volume(m:Mesh3D):Float {
		var p = m.positions, sum = 0.;
		for (k in 0...m.triangleCount) {
			var a = corner(m, k, 0) * 3,
				b = corner(m, k, 1) * 3,
				c = corner(m, k, 2) * 3;
			sum += p[a] * (p[b + 1] * p[c + 2] - p[b + 2] * p[c + 1])
				- p[a + 1] * (p[b] * p[c + 2] - p[b + 2] * p[c]) + p[a + 2] * (p[b] * p[c + 1] - p[b + 1] * p[c]);
		}
		return sum / 6;
	}

	// Whether every edge is on exactly two triangles, once and once the other way, the vertices at one point taken as one.
	static function closed(m:Mesh3D):Bool {
		var p = m.positions,
			ids = new Map<String, Int>(),
			edges = new Map<String, Int>();
		function id(v:Int):Int {
			var key = '${Math.round(p[v * 3] * 1e9)},${Math.round(p[v * 3 + 1] * 1e9)},${Math.round(p[v * 3 + 2] * 1e9)}';
			if (!ids.exists(key))
				ids.set(key, Lambda.count(ids));
			return ids.get(key);
		}
		for (k in 0...m.triangleCount) {
			var a = id(corner(m, k, 0)),
				b = id(corner(m, k, 1)),
				c = id(corner(m, k, 2));
			for (e in [[a, b], [b, c], [c, a]]) {
				var key = '${e[0]},${e[1]}';
				edges.set(key, (edges.exists(key) ? edges.get(key) : 0) + 1);
			}
		}
		for (key => count in edges) {
			var parts = key.split(","), back = '${parts[1]},${parts[0]}';
			if (count != 1 || edges.get(back) != 1)
				return false;
		}
		return true;
	}

	// Each triangle has area; each normal is of length 1 and on the side its triangles face; texture coordinates in 0 to 1.
	static function sound(m:Mesh3D, name:String, made = true):Void {
		var p = m.positions, n = m.normals, uv = m.texCoords;
		var area = true, facing = true, unit = true, inside = true;
		for (k in 0...m.triangleCount) {
			var a = corner(m, k, 0), b = corner(m, k, 1), c = corner(m, k, 2);
			var e1 = [for (i in 0...3) p[b * 3 + i] - p[a * 3 + i]],
				e2 = [for (i in 0...3) p[c * 3 + i] - p[a * 3 + i]];
			var f = [
				e1[1] * e2[2] - e1[2] * e2[1],
				e1[2] * e2[0] - e1[0] * e2[2],
				e1[0] * e2[1] - e1[1] * e2[0]
			];
			area = area && f[0] * f[0] + f[1] * f[1] + f[2] * f[2] > 1e-20;
			for (v in [a, b, c])
				facing = facing && f[0] * n[v * 3] + f[1] * n[v * 3 + 1] + f[2] * n[v * 3 + 2] > 0;
		}
		for (v in 0...m.vertexCount) {
			unit = unit && near(Math.sqrt(n[v * 3] * n[v * 3] + n[v * 3 + 1] * n[v * 3 + 1] + n[v * 3 + 2] * n[v * 3 + 2]), 1, 1e-12);
			inside = inside && uv[v * 2] >= -1e-12 && uv[v * 2] <= 1 + 1e-12 && uv[v * 2 + 1] >= -1e-12 && uv[v * 2 + 1] <= 1 + 1e-12;
		}
		check(area, '$name: every triangle has area');
		check(facing, '$name: each vertex\'s normal on the side its triangles face');
		check(unit, '$name: normals of length 1');
		check(inside, '$name: texture coordinates 0 to 1');
		if (made)
			check(m.tangents == null && m.colors == null && m.indices != null, '$name: indexed, no tangents or colors');
	}

	static function main():Void {
		// Box.
		var box = Mesh3D.fromBox(2, 1, 3);
		sound(box, "box");
		check(box.vertexCount == 24 && box.triangleCount == 12, "box: four vertices a face, two triangles");
		check(near(volume(box), 6) && closed(box), "box: closed, facing out, its volume");
		var b = box.computeBounds();
		check(b.minX == -1 && b.maxX == 1 && b.minY == -.5 && b.maxY == .5 && b.minZ == -1.5 && b.maxZ == 1.5, "box: centered, its size");
		// The +z face: its top left corner at -x, +y, texture 0, 0.
		var topLeft = false;
		for (v in 0...24)
			if (box.normals[v * 3 + 2] == 1 && box.positions[v * 3] == -1 && box.positions[v * 3 + 1] == .5)
				topLeft = box.texCoords[v * 2] == 0 && box.texCoords[v * 2 + 1] == 0;
		check(topLeft, "box: a face's texture upright, seen from outside");

		// Plane.
		var plane = Mesh3D.fromPlane(10, 6, 4, 3);
		sound(plane, "plane");
		check(plane.vertexCount == 20 && plane.triangleCount == 24, "plane: (columns + 1) by (rows + 1) vertices, two triangles a cell");
		var flatUp = true;
		for (v in 0...plane.vertexCount) {
			flatUp = flatUp && plane.positions[v * 3 + 1] == 0 && plane.normals[v * 3 + 1] == 1;
			if (plane.positions[v * 3 + 2] == -3)
				flatUp = flatUp && plane.texCoords[v * 2 + 1] == 0;
		}
		check(flatUp, "plane: on y = 0, facing +y, its texture's top at -z");
		check(Mesh3D.fromPlane(1, 1, 0, -2).triangleCount == 2, "plane: at least a cell each way");

		// Disk.
		var disk = Mesh3D.fromDisk(2, 6);
		sound(disk, "disk");
		check(disk.vertexCount == 7 && disk.triangleCount == 6 && near(disk.computeBounds().maxX, 2), "disk: its center and a corner a side");

		// Sphere.
		var sphere = Mesh3D.fromSphere(1.5, 24, 12);
		sound(sphere, "sphere");
		check(closed(sphere), "sphere: closed");
		var v = volume(sphere), exact = 4 / 3 * Math.PI * 1.5 * 1.5 * 1.5;
		check(v > 0 && v < exact && v > exact * .97, "sphere: facing out, near its volume");
		var onIt = true;
		for (i in 0...sphere.vertexCount) {
			var x = sphere.positions[i * 3],
				y = sphere.positions[i * 3 + 1],
				z = sphere.positions[i * 3 + 2];
			onIt = onIt
				&& near(Math.sqrt(x * x + y * y + z * z), 1.5, 1e-12)
				&& near(sphere.normals[i * 3], x / 1.5, 1e-12)
				&& near(sphere.normals[i * 3 + 1], y / 1.5, 1e-12);
		}
		check(onIt, "sphere: points on it, normals out from its center");
		check(sphere.computeBounds().maxY == 1.5 && sphere.computeBounds().minY == -1.5, "sphere: its poles on y");
		check(sphere.triangleCount == 24 * 12 * 2 - 2 * 24, "sphere: one triangle a slice at each pole");
		var given = new Mesh3D();
		check(Mesh3D.fromSphere(1, 8, 4, given) == given
			&& given.triangleCount == 8 * 4 * 2 - 16
			&& Mesh3D.fromBox(1, 1, 1, given) == given
			&& given.vertexCount == 24,
			"a shape into the mesh given, again");

		// Hemisphere.
		var dome = Mesh3D.fromHemisphere(2, 16, 6);
		sound(dome, "hemisphere");
		check(near(dome.computeBounds().minY, 0) && near(dome.computeBounds().maxY, 2), "hemisphere: its base on y = 0, its pole at 2");

		// Cylinder, cone, a truncated cone.
		var cylinder = Mesh3D.fromCylinder(1, 1, 2, 16, 3, true);
		sound(cylinder, "cylinder");
		check(closed(cylinder), "cylinder: closed by its caps");
		var cv = volume(cylinder);
		check(cv > 0 && near(cv, 16 * Math.sin(2 * Math.PI / 16) / 2 * 2, 1e-9), "cylinder: facing out, its volume a prism's");
		var cone = Mesh3D.fromCylinder(1, 0, 2, 16, 1, true);
		sound(cone, "cone");
		check(closed(cone), "cone: closed by its base alone");
		check(near(volume(cone), 16 * Math.sin(2 * Math.PI / 16) / 2 * 2 / 3, 1e-9), "cone: its volume a pyramid's");
		check(cone.normals[1] > 0, "cone: its side's normals lean up");
		var open = Mesh3D.fromCylinder(1, .5, 2, 8, 2, false);
		sound(open, "truncated cone");
		check(!closed(open) && open.triangleCount == 8 * 2 * 2, "uncapped: open, its side alone");

		// Capsule.
		var capsule = Mesh3D.fromCapsule(.3, 1, 16, 6);
		sound(capsule, "capsule");
		check(closed(capsule), "capsule: closed");
		var cb = capsule.computeBounds();
		check(near(cb.minY, -.8) && near(cb.maxY, .8) && near(cb.maxX, .3), "capsule: its whole height the height and two radii");
		var capsuleVolume = Math.PI * .09 * 1 + 4 / 3 * Math.PI * .027;
		check(volume(capsule) > capsuleVolume * .95 && volume(capsule) < capsuleVolume, "capsule: facing out, near its volume");

		// Torus.
		var torus = Mesh3D.fromTorus(2, .5, 32, 12);
		sound(torus, "torus");
		check(closed(torus), "torus: closed");
		var tv = 2 * Math.PI * Math.PI * 2 * .25;
		check(volume(torus) > tv * .93 && volume(torus) < tv, "torus: facing out, near its volume");
		var tb = torus.computeBounds();
		check(near(tb.maxX, 2.5) && near(tb.maxY, .5) && near(tb.minZ, -2.5), "torus: on the XZ plane about y");

		// Torus knot.
		var knot = Mesh3D.fromTorusKnot(1, .1, 128, 12, 2, 3);
		sound(knot, "trefoil");
		check(closed(knot), "trefoil: closed");
		check(volume(knot) > 0, "trefoil: facing out");
		var kb = knot.computeBounds();
		check(near(kb.maxX, 1.1, .02) && kb.maxY < .5, "trefoil: its widest the radius and the tube's");

		// Normals computed.
		var smooth = sphere.computeNormals(0), close = true;
		for (i in 0...sphere.vertexCount)
			close = close
				&& smooth[i * 3] * sphere.normals[i * 3] + smooth[i * 3 + 1] * sphere.normals[i * 3 + 1] + smooth[i * 3 + 2] * sphere.normals[i * 3 + 2] > .99;
		check(close, "computed and welded: near the sphere's own");
		var seam = Mesh3D.fromSphere(1, 8, 4),
			unwelded = seam.computeNormals(),
			welded = seam.computeNormals(0);
		var differ = false, same = true;
		for (i in 0...seam.vertexCount)
			if (seam.texCoords[i * 2] == 0 && seam.texCoords[i * 2 + 1] == .5) {
				// The seam's vertex at the equator, and its double at u 1.
				for (j in 0...seam.vertexCount)
					if (seam.texCoords[j * 2] == 1 && seam.texCoords[j * 2 + 1] == .5) {
						differ = !near(unwelded[i * 3 + 2], unwelded[j * 3 + 2], 1e-6);
						same = near(welded[i * 3], welded[j * 3], 1e-12) && near(welded[i * 3 + 2], welded[j * 3 + 2], 1e-12);
					}
			}
		check(differ && same, "unwelded, a seam's two vertices apart; welded at 0, one normal");
		var faceted = Mesh3D.fromSphere(1, 8, 6).toUnindexed();
		check(faceted.indices == null && faceted.vertexCount == faceted.triangleCount * 3, "unindexed: three vertices a triangle");
		faceted.normals = faceted.computeNormals();
		var flat = true;
		for (k in 0...faceted.triangleCount)
			for (c in 1...3)
				for (i in 0...3)
					flat = flat && near(faceted.normals[(k * 3 + c) * 3 + i], faceted.normals[k * 9 + i], 1e-12);
		check(flat, "unindexed, its normals computed: each triangle flat");
		check(near(volume(faceted), volume(Mesh3D.fromSphere(1, 8, 6)), 1e-12), "unindexed: the same triangles");
		var near2 = Mesh3D.fromSphere(1, 8, 6).toUnindexed();
		var weldedFar = near2.computeNormals(.01);
		check(weldedFar[0] * near2.positions[0] + weldedFar[1] * near2.positions[1] + weldedFar[2] * near2.positions[2] > .99,
			"welded within a distance: smooth again");

		// Tangents.
		var t = plane.computeTangents();
		var along = true;
		for (i in 0...plane.vertexCount)
			along = along && near(t[i * 4], 1, 1e-12) && near(t[i * 4 + 1], 0, 1e-12) && near(t[i * 4 + 2], 0, 1e-12) && t[i * 4 + 3] == -1;
		check(along, "a plane's tangents along +x, w turning the bitangent to +z, where v grows");
		var st = sphere.computeTangents(), square = true;
		for (i in 0...sphere.vertexCount) {
			var dot = st[i * 4] * sphere.normals[i * 3] + st[i * 4 + 1] * sphere.normals[i * 3 + 1] + st[i * 4 + 2] * sphere.normals[i * 3 + 2];
			square = square
				&& near(dot, 0, 1e-9)
				&& near(Math.sqrt(st[i * 4] * st[i * 4] + st[i * 4 + 1] * st[i * 4 + 1] + st[i * 4 + 2] * st[i * 4 + 2]), 1, 1e-9);
		}
		check(square, "a sphere's tangents: length 1, square to its normals");
		check(faceted.computeTangents() != null
			&& faceted.computeTangents().length == faceted.vertexCount * 4, "tangents without indices");
		check(new Mesh3D().computeTangents() == null, "no tangents without texture coordinates and normals");

		// Transforms.
		var moved = Mesh3D.fromCylinder(1, 1, 2, 12, 1, true);
		moved.tangents = moved.computeTangents();
		var m = Matrix3D.fromRotation(1, 0, 0, Math.PI / 2).appendTranslation(5, 0, 0);
		var turned = moved.transform(m);
		check(turned != moved && near(volume(turned), volume(moved), 1e-9), "moved: the same volume, the original unchanged");
		check(near(turned.computeBounds().minX, 4) && near(turned.computeBounds().maxZ, 1), "moved: turned on its side and along x");
		sound(new Mesh3D().copyFrom(turned).transform(new Matrix3D(), null), "moved", false);
		var mirror = moved.transform(Matrix3D.fromScale(-1, 2, 1));
		check(volume(mirror) > 0 && near(volume(mirror), 2 * volume(moved), 1e-9), "mirrored: its triangles turned round, facing out");
		var facingOut = true;
		for (k in 0...mirror.triangleCount) {
			var a = corner(mirror, k, 0),
				b = corner(mirror, k, 1),
				c = corner(mirror, k, 2),
				p = mirror.positions;
			var e1 = [for (i in 0...3) p[b * 3 + i] - p[a * 3 + i]],
				e2 = [for (i in 0...3) p[c * 3 + i] - p[a * 3 + i]];
			var f = [
				e1[1] * e2[2] - e1[2] * e2[1],
				e1[2] * e2[0] - e1[0] * e2[2],
				e1[0] * e2[1] - e1[1] * e2[0]
			];
			facingOut = facingOut
				&& f[0] * mirror.normals[a * 3] + f[1] * mirror.normals[a * 3 + 1] + f[2] * mirror.normals[a * 3 + 2] > 0;
		}
		check(facingOut, "mirrored: its normals still out");
		check(mirror.tangents[3] == -moved.tangents[3], "mirrored: its tangents' w turned");
		var inPlace = Mesh3D.fromBox(1, 1, 1);
		check(inPlace.transform(Matrix3D.fromTranslation(0, 3, 0), inPlace) == inPlace
			&& near(inPlace.computeBounds().minY, 2.5), "moved in place");
		var flatMirror = Mesh3D.fromBox(1, 1, 1).toUnindexed().transform(Matrix3D.fromScale(1, 1, -1));
		check(near(volume(flatMirror), 1, 1e-12), "mirrored without indices: its vertices turned round");

		// Merging and copying.
		var lamp = Mesh3D.merge([
			Mesh3D.fromCylinder(.1, .1, 3, 12, 1, true),
			Mesh3D.fromCylinder(.4, 0, .5, 16, 1, false)
		]);
		check(lamp.vertexCount == Mesh3D.fromCylinder(.1, .1, 3, 12, 1, true).vertexCount + Mesh3D.fromCylinder(.4, 0, .5, 16, 1, false).vertexCount
			&& lamp.triangleCount == Mesh3D.fromCylinder(.1, .1, 3, 12, 1, true).triangleCount + Mesh3D.fromCylinder(.4, 0, .5, 16, 1, false).triangleCount,
			"merged: both's vertices and triangles");
		check(lamp.normals != null && lamp.texCoords != null, "merged: what both have kept");
		var withTangents = Mesh3D.fromBox(1, 1, 1);
		withTangents.tangents = withTangents.computeTangents();
		check(Mesh3D.merge([withTangents, Mesh3D.fromBox(1, 1, 1)]).tangents == null, "merged: tangents only when every mesh has them");
		check(Mesh3D.merge([withTangents, withTangents]).tangents.length == 48 * 4, "merged: tangents every mesh has kept");
		var bare = new Mesh3D();
		bare.positions = [0, 0, 0, 1, 0, 0, 0, 1, 0];
		var filled = Mesh3D.merge([Mesh3D.fromBox(1, 1, 1).tint(0xff808080), bare]);
		check(filled.vertexCount == 27
			&& filled.normals[24 * 3 + 1] == 1
			&& filled.normals[24 * 3] == 0
			&& filled.texCoords[24 * 2] == 0,
			"merged: normals and texture coordinates given to the mesh without");
		check(filled.colors[24 * 4] == 1 && filled.colors[24 * 4 + 3] == 1 && filled.triangleCount == 13,
			"merged: white given to the mesh without colors, indexed with it");
		check(Mesh3D.merge([]).vertexCount == 0 && Mesh3D.merge([]).indices == null, "merged: an empty list, an empty mesh");
		var single = Mesh3D.merge([bare]);
		check(single != bare && single.vertexCount == 3 && single.normals == null && single.indices == null, "merged: one mesh, a copy of what it has");

		// Tinted.
		var tinted = Mesh3D.fromBox(1, 1, 1).tint(0x80ff0000);
		check(tinted.colors.length == 24 * 4
			&& tinted.colors[0] == 1
			&& tinted.colors[1] == 0
			&& tinted.colors[2] == 0
			&& near(tinted.colors[3], 128 / 255, 1e-12),
			"tinted: the mesh without colors gets the color");
		var twice = tinted.tint(0xff808080);
		check(near(twice.colors[0], 128 / 255, 1e-12)
			&& twice.colors[1] == 0
			&& near(twice.colors[3], 128 / 255, 1e-12)
			&& tinted.colors[0] == 1,
			"tinted again: multiplied, the original unchanged");
		check(tinted.tint(0xffffffff, tinted) == tinted && tinted.colors[0] == 1, "tinted in place");
		var mixed = Mesh3D.merge([Mesh3D.fromBox(1, 1, 1), Mesh3D.fromBox(1, 1, 1).toUnindexed()]);
		check(mixed.indices != null && mixed.triangleCount == 24 && near(volume(mixed), 2, 1e-12), "merged with one unindexed: indexed, both whole");
		var first = Mesh3D.fromBox(1, 1, 1);
		check(Mesh3D.merge([first, Mesh3D.fromBox(2, 2, 2)], first) == first && near(volume(first), 9, 1e-12), "merged into the first");
		var copy = new Mesh3D().copyFrom(sphere);
		copy.positions[0] = 99;
		check(sphere.positions[0] != 99 && copy.vertexCount == sphere.vertexCount, "copied: its own arrays");
		var bounds = new Bounds3D();
		check(sphere.computeBounds(bounds) == bounds
			&& new Mesh3D().computeBounds().isEmpty, "bounds into those given; none for no positions");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
