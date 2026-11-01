import haxe.io.Bytes;
import helix.formats.obj.MtlFile;
import helix.formats.obj.MtlMaterial;
import helix.formats.obj.ObjFile;

/** Checks ObjFile and MtlFile with the library alone, on files written here: positions, texture coordinates and normals and their
	1-based and negative numbers, w dropped, six-value positions' colors (all or none), faces of fewer than 3 corners left out, groups
	(o resetting g, a g repeated as one, a name coming back as a run of its own, empty ones left out), usemtl across groups, triangle fans,
	parts by group and by material (repeats joined, faces before usemtl, their order), materials found and stood in for, libraries
	combined, every MTL statement read (Tr against d, texture options read past, the PBR extension), the computed roughness, metalness and
	normal map, paths resolved and normalized, UTF-8, and refusals naming their line. */
class ObjTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The String a call throws, or null when it doesn't.
	static function thrown(call:Void->Void):Null<String> {
		try
			call()
		catch (e:String)
			return e;
		return null;
	}

	static function same<T>(a:Iterable<T>, b:Array<T>):Bool {
		if (a == null)
			return false;
		var i = 0;
		for (x in a) {
			if (i >= b.length || x != b[i])
				return false;
			i++;
		}
		return i == b.length;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function obj(text:String, path = "models/m.obj"):ObjFile
		return ObjFile.read(Bytes.ofString(text), path);

	static function mtl(text:String, path = "models/m.mtl"):MtlFile
		return MtlFile.read(Bytes.ofString(text), path);

	static function main():Void {
		vertices();
		faces();
		groups();
		parts();
		materials();
		library();
		paths();
		text();
		refused();
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// Positions, texture coordinates and normals, as the file gives them.
	static function vertices():Void {
		var m = obj("# a comment\nv 1 2 3\nv 4 5 6 0.5\n  v\t-7 8e1 .25  # trailing\nvt 0.5 0.25\nvt 1\nvt 0.1 0.2 0.3\nvn 0 0 2\n");
		check(m.positionCount == 3
			&& same(m.positions, [1.0, 2, 3, 4, 5, 6, -7, 80, 0.25]), "positions, w dropped, leading spaces and tabs");
		check(m.colors == null, "no colors without six values");
		check(m.texCoordCount == 3
			&& same(m.texCoords, [0.5, 0.25, 1, 0, 0.1, 0.2]), "texture coordinates: v defaults to 0, w dropped, v not flipped");
		check(m.normalCount == 1 && same(m.normals, [0.0, 0, 2]), "normals not normalized");
		check(m.faceCount == 0 && m.cornerCount == 0 && m.groups.length == 0, "no faces");
		var c = obj("v 0 0 0 1 0.5 0\nv 1 0 0 0 1 0.25\n");
		check(same(c.colors, [1.0, 0.5, 0, 0, 1, 0.25]), "six values give colors");
		check(obj("v 0 0 0 1 0.5 0\nv 1 0 0\n").colors == null, "colors only when every position has them");
		check(obj("").positionCount == 0 && obj("").colors == null, "an empty file");
		// Points, lines, curves, smoothing and unknown statements are read past.
		var other = obj("v 0 0 0\nv 1 0 0\np 1\nl 1 2\ns 1\nvp 0.5\ncstype bezier\nfoo bar\n");
		check(other.positionCount == 2 && other.faceCount == 0, "points, lines and the rest read past");
	}

	// Faces: their corners, numbers made 0-based, fans.
	static function faces():Void {
		var text = "v 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nvt 0 0\nvt 1 0\nvt 1 1\nvn 0 0 1\nvn 0 0 -1\n"
			+ "f 1/1/1 2/2/1 3/3/2\n" // all three
			+ "f -4//-2 -3//-1 -2//-2 -1//-1\n" // relative, normals alone, a quad
			+ "f 1/3 2/2 4/1\n" // texture coordinates alone
			+ "f 1 2\n" // fewer than 3: left out
			+ "f 2 3 4\n"; // positions alone
		var m = obj(text);
		check(m.faceCount == 4 && same(m.faceVertexCounts, [3, 4, 3, 3]), "faces of fewer than 3 corners left out");
		check(same(m.faceFirstCornerIndices, [0, 3, 7, 10]) && m.cornerCount == 13, "each face's first corner");
		check(same(m.cornerPositionIndices, [0, 1, 2, 0, 1, 2, 3, 0, 1, 3, 1, 2, 3]), "positions: 1-based and negative numbers made 0-based");
		check(same(m.cornerTexCoordIndices, [0, 1, 2, -1, -1, -1, -1, 2, 1, 0, -1, -1, -1]), "texture coordinates, -1 for none");
		check(same(m.cornerNormalIndices, [0, 0, 1, 0, 1, 0, 1, -1, -1, -1, -1, -1, -1]), "normals, -1 for none");
		check(same(m.computeTriangles(0, m.faceCount), [0, 1, 2, 3, 4, 5, 3, 5, 6, 7, 8, 9, 10, 11, 12]), "triangles: a fan from each face's first corner");
		check(same(m.computeTriangles(1, 1), [3, 4, 5, 3, 5, 6]) && m.computeTriangles(2, 0).length == 0, "triangles of some faces");
		var pentagon = obj("v 0 0 0\nv 1 0 0\nv 2 1 0\nv 1 2 0\nv 0 1 0\nf 1 2 3 4 5\n");
		check(same(pentagon.computeTriangles(0, 1), [0, 1, 2, 0, 2, 3, 0, 3, 4]), "a pentagon's fan: n - 2 triangles");
		// A negative number counts back from the lines read so far.
		var relative = obj("v 0 0 0\nv 1 0 0\nv 0 1 0\nf -3 -2 -1\nv 5 5 5\nf -1 -2 -3\n");
		check(same(relative.cornerPositionIndices, [0, 1, 2, 3, 2, 1]), "negative numbers count back from the lines so far");
	}

	// Runs of faces in one object and group.
	static function groups():Void {
		var tri = "f 1 2 3\n";
		var m = obj("v 0 0 0\nv 1 0 0\nv 0 1 0\n"
			+ tri // before any o or g
			+ "g a\n"
			+ tri
			+ tri
			+ "g a\n"
			+ tri // a g repeated with faces between is the same group
			+ "g b\ng a\n"
			+ tri // a b with no faces, then a again: still the same run
			+ "g b\n"
			+ tri // b
			+ "g a\n"
			+ tri // a again: a run of its own
			+ "g empty\n" // a group with no faces, then an object
			+ "o ship\n"
			+ tri // o resets the group
			+ "g hull part\n"
			+ tri // a line naming several groups keeps them as written
			+ "o ship\n"
			+ tri // the same object again, its group reset
			+ "f 1 2\n"
			+ "g never\nf 1 2\n" // faces left out make no group
		);
		var g = [
			for (x in m.groups)
				'${x.objectName}|${x.groupName}|${x.firstFaceIndex}|${x.faceCount}'
		];
		check(same(g,
			[
				"||0|1",
				"|a|1|4",
				"|b|5|1",
				"|a|6|1",
				"ship||7|1",
				"ship|hull part|8|1",
				"ship||9|1"
			]), "groups: o resets g, repeats and returns as runs, empty ones left out: " + g);
		// usemtl doesn't start a group, and holds across o and g lines.
		var u = obj("v 0 0 0\nv 1 0 0\nv 0 1 0\n"
			+ tri
			+ "usemtl red\n"
			+ tri
			+ "g a\n"
			+ tri
			+ "usemtl blue\n"
			+ tri
			+ "o b\n"
			+ tri
			+ "usemtl red\n"
			+ tri);
		check(same([for (x in u.groups) x.faceCount], [2, 2, 2]), "usemtl starts no group");
		check(same(u.faceMaterialIndices, [-1, 0, 0, 1, 1, 0]) && same(u.materialNames, ["red", "blue"]),
			"usemtl holds across o and g; names once each, in their first use's order");
	}

	// Parts: by object, group and material, and by material alone.
	static function parts():Void {
		var tri = "f 1 2 3\n", quad = "f 1 2 3 4\n";
		var m = obj("v 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\n"
			+ tri // no group, no material
			+ "usemtl red\n"
			+ tri // no group, red
			+ "g a\n"
			+ quad // a, red
			+ "usemtl blue\n"
			+ tri // a, blue
			+ "g b\nusemtl red\n"
			+ tri // b, red
			+ "g a\n"
			+ tri // a, red again: joined to a's red
			+ "usemtl blue\n"
			+ tri); // a, blue again
		var parts = m.computeParts(true);
		var p = [
			for (x in parts)
				'${x.objectName}|${x.groupName}|${x.materialIndex}|${x.materialName}|${x.triangleCount}'
		];
		check(same(p, ["||-1||1", "||0|red|1", "|a|0|red|3", "|a|1|blue|2", "|b|0|red|1"]),
			"parts by group: repeats joined, the -1 part, in their first face's order: " + p);
		check(same(parts[2].cornerIndices, [6, 7, 8, 6, 8, 9, 16, 17, 18]), "a joined part's triangles, in the faces' order");
		var byMaterial = m.computeParts(false);
		var q = [
			for (x in byMaterial)
				'${x.objectName}|${x.groupName}|${x.materialIndex}|${x.materialName}|${x.triangleCount}'
		];
		check(same(q, ["||-1||1", "||0|red|5", "||1|blue|2"]), "parts by material alone: " + q);
		check(same(byMaterial[1].cornerIndices, [3, 4, 5, 6, 7, 8, 6, 8, 9, 13, 14, 15, 16, 17, 18]), "by material: every red triangle");
		check(obj("v 0 0 0\n").computeParts(true).length == 0, "no parts without faces");
	}

	// MTL statements, and materials found for an OBJ's names.
	static function materials():Void {
		var lib = mtl("# a library\nKd 0 0 0\n" // before any newmtl: ignored
			+ "newmtl full\nKa 0.1 0.2 0.3\nKd 0.4 0.5 0.6\nKs 0.7 0.8 0.9\nKe 1 0.5 0\nTf 0.2 0.3 0.4\nNs 250\nNi 1.45\nd 0.75\nTr 0.9\nillum 2\n"
			+ "map_Ka amb.png\nmap_Kd -s 1 1 1 -o 0.5 0.5 -bm 0.2 -clamp on diffuse map.png\nmap_Ks spec.png\nmap_Ns shine.png\nmap_Ke glow.png\n"
			+ "map_d alpha.png\nmap_Bump -bm 0.5 bumpy.png\ndisp height.png\n"
			+ "newmtl only tr\nTr 0.25\nKd 0.5\n" // Tr alone; one value for a color
			+ "newmtl pbr\nPr 0.3\nPm 0.8\nmap_Pr rough.png\nmap_Pm metal.png\nnorm normal.png\nbump height.png\n"
			+ "newmtl empty\n"
			+ "newmtl full\nKd 0 0 0\n" // a name given twice
			+ "newmtl halo\nd -halo 0.5\nKa spectral file.rfl 1\nNs 1000\n");
		check(lib.materials.length == 6, "a material at each newmtl, its name the rest of the line");
		var full = lib.findMaterial("full");
		check(full == lib.materials[0] && full.defined && full.name == "full", "findMaterial: the first of a name");
		check(same(full.ambient, [0.1, 0.2, 0.3])
			&& same(full.diffuse, [0.4, 0.5, 0.6])
			&& same(full.specular, [0.7, 0.8, 0.9])
			&& same(full.emission, [1.0, 0.5, 0])
			&& same(full.transmission, [0.2, 0.3, 0.4]),
			"colors");
		check(full.shininess == 250 && full.opticalDensity == 1.45 && full.opacity == 0.75 && full.illumination == 2, "numbers; d wins over Tr");
		check(full.roughness == null && full.metalness == null, "no PBR values in a classic material");
		check(full.ambientTexturePath == "models/amb.png"
			&& full.diffuseTexturePath == "models/diffuse map.png"
			&& full.specularTexturePath == "models/spec.png"
			&& full.shininessTexturePath == "models/shine.png"
			&& full.emissionTexturePath == "models/glow.png"
			&& full.opacityTexturePath == "models/alpha.png"
			&& full.bumpTexturePath == "models/bumpy.png"
			&& full.displacementTexturePath == "models/height.png",
			"textures: options read past, paths resolved");
		check(full.normalTexturePath == null
			&& full.computeNormalTexturePath() == "models/bumpy.png", "the bump texture as the normal map");
		check(near(full.computeRoughness(), 1 - Math.sqrt(0.25)) && full.computeMetalness() == 0, "roughness from Ns, metalness 0");
		var tr = lib.findMaterial("only tr");
		check(tr != null && near(tr.opacity, 0.75), "Tr alone: opacity 1 - Tr");
		check(same(tr.diffuse, [0.5, 0.5, 0.5]), "one value for a color gives all three");
		var pbr = lib.findMaterial("pbr");
		check(pbr.roughness == 0.3 && pbr.metalness == 0.8 && pbr.computeRoughness() == 0.3 && pbr.computeMetalness() == 0.8, "Pr and Pm");
		check(pbr.roughnessTexturePath == "models/rough.png"
			&& pbr.metalnessTexturePath == "models/metal.png"
			&& pbr.normalTexturePath == "models/normal.png"
			&& pbr.bumpTexturePath == "models/height.png",
			"the PBR textures");
		check(pbr.computeNormalTexturePath() == "models/normal.png", "norm wins over bump");
		var empty = lib.findMaterial("empty");
		check(empty.defined
			&& same(empty.ambient, [0.0, 0, 0])
			&& same(empty.diffuse, [1.0, 1, 1])
			&& same(empty.specular, [0.0, 0, 0])
			&& same(empty.emission, [0.0, 0, 0])
			&& same(empty.transmission, [1.0, 1, 1])
			&& empty.shininess == 0
			&& empty.opticalDensity == 1
			&& empty.opacity == 1
			&& empty.illumination == 0
			&& empty.diffuseTexturePath == null
			&& empty.computeNormalTexturePath() == null,
			"a material's defaults");
		check(empty.computeRoughness() == 1, "Ns 0: roughness 1");
		var halo = lib.findMaterial("halo");
		check(halo.opacity == 0.5 && same(halo.ambient, [0.0, 0, 0]) && halo.computeRoughness() == 0,
			"d -halo read past, a spectral color skipped, Ns 1000: roughness 0");
		check(lib.findMaterial("Full") == null && lib.findMaterial("nothing") == null, "names: case counts, none for an unknown");
		check(mtl("newmtl a\nNs 4000\n").materials[0].computeRoughness() == 0
			&& mtl("newmtl a\nPr 2\nPm -1\n").materials[0].computeRoughness() == 1
			&& mtl("newmtl a\nPm -1\n").materials[0].computeMetalness() == 0,
			"roughness and metalness held to 0 to 1");
		// DEFAULT, and stand-ins for names no library gives.
		var d = MtlMaterial.DEFAULT;
		check(d != null
			&& d.name == ""
			&& !d.defined
			&& same(d.diffuse, [1.0, 1, 1])
			&& d.opacity == 1
			&& d.diffuseTexturePath == null,
			"DEFAULT: white, opaque, no textures, not defined");
		var model = obj("v 0 0 0\nv 1 0 0\nv 0 1 0\nusemtl pbr\nf 1 2 3\nusemtl missing\nf 1 2 3\nusemtl full\nf 1 2 3\n");
		var found = model.computeMaterials(lib);
		check(found.length == 3 && found[0] == pbr && found[2] == full, "computeMaterials: the library's, in materialNames' order");
		check(found[1].name == "missing" && !found[1].defined && same(found[1].diffuse, [1.0, 1, 1]), "a stand-in, named, not defined");
	}

	// Libraries combined, as an OBJ naming several uses them.
	static function library():Void {
		var a = mtl("newmtl wood\nKd 1 0 0\nnewmtl stone\nKd 0 1 0\n", "a.mtl");
		var b = mtl("newmtl stone\nKd 0 0 1\nnewmtl metal\nKd 1 1 0\n", "b.mtl");
		var both = MtlFile.combine([a, b]);
		check(same([for (m in both.materials) m.name], ["wood", "stone", "metal"]), "combine: in turn, a name given before left out");
		check(same(both.findMaterial("stone").diffuse, [0.0, 1, 0]), "combine: the first library's wins");
		check(MtlFile.combine([]).materials.length == 0, "combine: none gives an empty library");
		var m = obj("mtllib a.mtl b.mtl\nmtllib ../shared/c.mtl\nv 0 0 0\n", "models/cars/m.obj");
		check(same(m.materialLibraryPaths, ["models/cars/a.mtl", "models/cars/b.mtl", "models/shared/c.mtl"]),
			"mtllib: several on a line, paths resolved and normalized");
	}

	// Paths resolved against the file's directory and normalized.
	static function paths():Void {
		function path(name:String, file:String):String
			return mtl('newmtl a\nmap_Kd $name\n', file).materials[0].diffuseTexturePath;
		check(path("tex.png", "m.mtl") == "tex.png", "a file with no directory");
		check(path("./img/../tex.png", "a/b/m.mtl") == "a/b/tex.png", "./ and .. taken out");
		check(path("..\\..\\..\\tex.png", "a/b/m.mtl") == "../tex.png", "a backslash as a /, a .. above the root kept at its start");
		check(path("../../x/tex.png", "../m.mtl") == "../../../x/tex.png", "..s kept at the start");
		check(path("/abs/tex.png", "a/m.mtl") == "/abs/tex.png"
			&& path("C:\\tex\\a.png", "a/m.mtl") == "C:\\tex\\a.png", "an absolute path kept as it is");
		check(path("img//tex.png", "a//b/m.mtl") == "a/b/img/tex.png", "empty parts taken out");
	}

	// UTF-8 text, line endings and a byte order mark.
	static function text():Void {
		var m = obj("\u{FEFF}v 0 0 0\r\nv 1 0 0\rv 0 1 0\no caf\u00e9 \u{1F680}\r\nusemtl \u00fcber\nf 1 2 3\n");
		check(m.positionCount == 3 && m.groups[0].objectName == "caf\u00e9 \u{1F680}" && m.materialNames[0] == "\u00fcber",
			"UTF-8 names, a byte order mark, \\r\\n, \\r and \\n");
		var bad = Bytes.ofString("v 0 0 0\nv 1 0 0\no x\n");
		bad.set(bad.length - 2, 0xFF);
		var error = thrown(() -> ObjFile.read(bad, "m.obj"));
		check(error != null && error.indexOf("Line 3") >= 0, "bytes that aren't UTF-8 refused, naming the line: " + error);
		var overlong = Bytes.ofString("newmtl a\nnewmtl b\n");
		overlong.set(8, 0xC0);
		check(thrown(() -> MtlFile.read(overlong, "m.mtl")) != null, "an overlong form refused");
		var cut = Bytes.ofString("newmtl \u00e9");
		check(thrown(() -> MtlFile.read(cut.sub(0, cut.length - 1), "m.mtl")) != null, "a sequence cut short refused");
	}

	// What can't be read, each naming its line.
	static function refused():Void {
		function names(text:String, line:Int):Bool {
			var error = thrown(() -> obj(text));
			return error != null && error.indexOf('Line $line') >= 0;
		}
		check(names("v 0 0\n", 1), "a position of 2 values");
		check(names("v 0 0 0 1 1\n", 1), "a position of 5 values");
		check(names("v 0 0 0\nv 0 x 0\n", 2), "a value that isn't a number");
		check(names("v 0 0 0\nv 1.5.2 0 0\n", 2), "a malformed number");
		check(names("vn 0 0\n", 1), "a normal of 2 values");
		check(names("vt\n", 1), "a texture coordinate of no values");
		check(names("v 0 0 0\nf 1 1 2\n", 2), "a corner naming a position not yet given");
		check(names("v 0 0 0\nf 0 1 1\n", 2), "a corner numbered 0");
		check(names("v 0 0 0\nf -2 1 1\n", 2), "a negative number before the first line");
		check(names("v 0 0 0\nvt 0 0\nf 1/2 1/1 1/1\n", 3), "a texture coordinate the file doesn't have");
		check(names("v 0 0 0\nf 1//1 1//1 1//1\n", 2), "a normal the file doesn't have");
		check(names("v 0 0 0\nf 1 2\n", 2), "a corner out of range, in a face left out");
		check(names("v 0 0 0\nf 1/x 1 1\n", 2), "a corner number that isn't a number");
		check(names("v 0 0 0\nf 1/1/1/1 1 1\n", 2), "a corner of four numbers");
		check(names("v 0 0 0\n\nusemtl\n", 3), "usemtl without a name");
		check(names("f\n", 1), "a face of no corners");
		function mtlNames(text:String, line:Int):Bool {
			var error = thrown(() -> mtl(text));
			return error != null && error.indexOf('Line $line') >= 0;
		}
		check(mtlNames("newmtl a\nKd 1 1\n", 2), "a color of 2 values");
		check(mtlNames("newmtl a\nNs\n", 2), "Ns without a value");
		check(mtlNames("newmtl a\nillum 2.5\n", 2), "illum not a whole number");
		check(mtlNames("newmtl a\nmap_Kd -s 1 1 1\n", 2), "a texture line naming no texture");
		check(mtlNames("newmtl\n", 1), "newmtl without a name");
	}
}
