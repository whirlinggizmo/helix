package helix.formats.obj;

import haxe.io.Bytes;

/** Represents a Wavefront OBJ model read from an .obj file: its vertex data, its faces and their groups, as the file gives them.

	The file's positions, texture coordinates and normals are numbered from 0 in the order of their lines (`v`, `vt`, `vn`); the
	file's own 1-based and negative (relative) numbers are turned into these. A face is a polygon of corners, kept as the file writes
	it, and each corner names a position by its number, and may name a texture coordinate and a normal. `computeTriangles` splits the
	faces into triangles.

	A face's material is named by the `usemtl` line before it, which holds across `o` and `g` lines until the next `usemtl`. The
	materials themselves are in the .mtl files `materialLibraryPaths` names, read by `MtlFile`; `computeMaterials` finds each name's.
	`computeParts` gathers the faces into parts, one for each object, group and material, split into triangles. Points, lines, curves and surfaces are not read; a face of fewer than 3 corners is left out of every face array.

	Values are as the file gives them: texture coordinates are not flipped (v is 0 at the image's bottom, as OBJ has it), normals are
	not normalized, and a face's corners go counter-clockwise seen from its front, as OBJ has them. Paths are resolved against the
	file's directory and normalized: `/` between parts, `.` and `..` taken out; an absolute path is kept as it is, and a `..` above
	the root is kept at its start. The arrays are the file's own, read-only.

	```haxe
	var obj = ObjFile.read(bytes, "models/house.obj");
	var libraries = [];
	for (path in obj.materialLibraryPaths) {
		var found = files.get(path); // a library that can't be found is the caller's to skip, as here, or refuse
		if (found != null)
			libraries.push(MtlFile.read(found, path));
	}
	var materials = obj.computeMaterials(MtlFile.combine(libraries));
	for (part in obj.computeParts(true)) {
		var material = part.materialIndex >= 0 ? materials[part.materialIndex] : MtlMaterial.DEFAULT;
		trace('${part.materialName}: ${material.defined ? "found" : "not found"}, ${part.triangleCount} triangles');
		var first = part.cornerIndices[0]; // the first triangle's first corner
		var x = obj.positions[3 * obj.cornerPositionIndices[first]];
	}
	``` */
class ObjFile {
	/** Gets how many positions the file has: one for each `v` line. */
	public final positionCount:Int;

	/** Gets the positions, three values for each (as every array here, the file's own: read it, don't change it): position i's x, y and z at `positions[3 * i]`, `[3 * i + 1]` and `[3 * i + 2]`. A
		fourth value a `v` line may give, w, is dropped. */
	public final positions:haxe.ds.ReadOnlyArray<Float>;

	/** Gets the positions' colors, three values for each, red, green and blue from 0 to 1: position i's at `colors[3 * i]` on, so a
		corner's color is its position's. Null unless every `v` line gives six values (a common extension): a file where only some do
		has none. */
	public final colors:Null<haxe.ds.ReadOnlyArray<Float>>;

	/** Gets how many texture coordinates the file has: one for each `vt` line. */
	public final texCoordCount:Int;

	/** Gets the texture coordinates, two values for each: coordinate i's u and v at `texCoords[2 * i]` and `[2 * i + 1]`. A third
		value, w, is dropped. */
	public final texCoords:haxe.ds.ReadOnlyArray<Float>;

	/** Gets how many normals the file has: one for each `vn` line. */
	public final normalCount:Int;

	/** Gets the normals, three values for each: normal i's x, y and z at `normals[3 * i]` on, as the file gives them, not normalized. */
	public final normals:haxe.ds.ReadOnlyArray<Float>;

	/** Gets how many faces the file has. */
	public final faceCount:Int;

	/** Gets how many corners each face has, in the file's order: 3 for a triangle, more for a polygon. */
	public final faceVertexCounts:haxe.ds.ReadOnlyArray<Int>;

	/** Gets where each face's corners start in the corner arrays: face f's corners are from `faceFirstCornerIndices[f]` up to, but
		not including, that plus `faceVertexCounts[f]`. */
	public final faceFirstCornerIndices:haxe.ds.ReadOnlyArray<Int>;

	/** Gets each face's material, by its index in `materialNames`, or -1 for a face before any `usemtl`. */
	public final faceMaterialIndices:haxe.ds.ReadOnlyArray<Int>;

	/** Gets how many corners the faces have in all: the length of each corner array. */
	public final cornerCount:Int;

	/** Gets each corner's position, by its number (0 to `positionCount` - 1), the corners of each face in turn. */
	public final cornerPositionIndices:haxe.ds.ReadOnlyArray<Int>;

	/** Gets each corner's texture coordinate, by its number (0 to `texCoordCount` - 1), or -1 when the corner names none. */
	public final cornerTexCoordIndices:haxe.ds.ReadOnlyArray<Int>;

	/** Gets each corner's normal, by its number (0 to `normalCount` - 1), or -1 when the corner names none. */
	public final cornerNormalIndices:haxe.ds.ReadOnlyArray<Int>;

	/** Gets the material names the `usemtl` lines give, each once, in the order the file first uses them, matched as written (case
		counts). */
	public final materialNames:haxe.ds.ReadOnlyArray<String>;

	/** Gets the paths of the .mtl files the `mtllib` lines name, in the file's order, ready to load: a line naming several files gives
		a path for each, split at spaces, so a file name can't hold one. */
	public final materialLibraryPaths:haxe.ds.ReadOnlyArray<String>;

	/** Gets the file's groups of faces: runs of faces in one object and one group, in the file's order, a new one wherever an `o` or
		`g` line between faces changes the object or group (two `g a` lines with no faces between are one group). A name can come
		back later in the file as a group of its own (`g a`, `g b`, `g a` are three groups); `computeParts` joins them. A `usemtl`
		line doesn't start a group: a group's faces may have several materials. A group with no faces is left out. */
	public final groups:Array<ObjGroup>;

	/** Returns some faces split into triangles, each polygon a fan from its first corner (corners 0, i and i + 1), as most readers
		do: a face of n corners gives n - 2 triangles, in the faces' order.

		@param firstFaceIndex  The first face.
		@param faceCount  How many faces, from it.
		@return  Three corners for each triangle, by their index in the corner arrays. */
	public function computeTriangles(firstFaceIndex:Int, faceCount:Int):Array<Int> {
		var triangles = [];
		for (f in firstFaceIndex...firstFaceIndex + faceCount) {
			var first = faceFirstCornerIndices[f];
			for (i in 1...faceVertexCounts[f] - 1) {
				triangles.push(first);
				triangles.push(first + i);
				triangles.push(first + i + 1);
			}
		}
		return triangles;
	}

	/** Returns the material of each name in `materialNames`, from a library: the library's of that name, or, for a name it doesn't
		give, a material of that name with every value its default (as `MtlMaterial.DEFAULT`'s). Whether a name was found is
		`library.findMaterial(name) != null`.

		@param library  The library: those `materialLibraryPaths` names, read and combined (`MtlFile.combine`).
		@return  A material for each of `materialNames`, in its order, so `faceMaterialIndices` and `ObjPart.materialIndex` index it
			too; never null. */
	public function computeMaterials(library:MtlFile):Array<MtlMaterial> {
		return [
			for (name in materialNames) {
				var found = library.findMaterial(name);
				found != null ? found : MtlMaterial.standIn(name);
			}
		];
	}

	/** Returns the faces gathered into parts, each split into triangles as `computeTriangles` splits them: one part for each object,
		group and material, the faces of a name that comes back later in the file joined to its part. Parts come in the order their
		first face does.

		Faces before any `usemtl` make a part of their own, its `materialIndex` -1 and its `materialName` "".

		@param byGroup  True for a part for each object, group and material; false for one for each material alone, the objects and
			groups ignored (their names "" in the parts).
		@return  The parts; none for a file without faces. */
	public function computeParts(byGroup:Bool):Array<ObjPart> {
		var parts:Array<{
			objectName:String,
			groupName:String,
			materialIndex:Int,
			corners:Array<Int>
		}> = [];
		var byKey = new Map<String, Int>();
		for (group in groups)
			for (f in group.firstFaceIndex...group.firstFaceIndex + group.faceCount) {
				var objectName = byGroup ? group.objectName : "",
					groupName = byGroup ? group.groupName : "",
					materialIndex = faceMaterialIndices[f];
				// Names can't hold a line break, so one keeps the three apart.
				var key = '$objectName\n$groupName\n$materialIndex';
				var index = byKey.get(key);
				if (index == null) {
					index = parts.length;
					byKey.set(key, index);
					parts.push({
						objectName: objectName,
						groupName: groupName,
						materialIndex: materialIndex,
						corners: []
					});
				}
				var corners = parts[index].corners;
				for (c in computeTriangles(f, 1))
					corners.push(c);
			}
		return [
			for (p in parts)
				new ObjPart(p.objectName, p.groupName, p.materialIndex, p.materialIndex >= 0 ? materialNames[p.materialIndex] : "", p.corners,
					Std.int(p.corners.length / 3))
		];
	}

	/** Reads an OBJ model.

		@param bytes  The file's bytes, as UTF-8 text.
		@param path  The file's path, whose directory `mtllib` paths are resolved against.
		@return  The model.
		@throws String  The file is refused, never read in part: its bytes aren't UTF-8 text, a line can't be read (naming its number),
			or a corner names a position, texture coordinate or normal the file doesn't have. Only a String is thrown. */
	public static function read(bytes:Bytes, path:String):ObjFile {
		var lines = ObjText.lines(bytes);
		var positions:Array<Float> = [], colors:Array<Float> = [], colored = 0, texCoords:Array<Float> = [], normals:Array<Float> = [];
		var faceVertexCounts:Array<Int> = [],
			faceFirstCornerIndices:Array<Int> = [],
			faceMaterialIndices:Array<Int> = [];
		var cornerPositionIndices:Array<Int> = [],
			cornerTexCoordIndices:Array<Int> = [],
			cornerNormalIndices:Array<Int> = [];
		var materialNames:Array<String> = [],
			materialOf = new Map<String, Int>(),
			materialLibraryPaths:Array<String> = [];
		var groups:Array<ObjGroup> = [];
		var objectName = "", groupName = "", material = -1;
		// The run of faces the last face is in: its object, group and first face; -1 before the first face.
		var runObject = "", runGroup = "", runFirst = -1;
		function close():Void {
			if (runFirst >= 0)
				groups.push(new ObjGroup(runObject, runGroup, runFirst, faceVertexCounts.length - runFirst));
		}
		// A corner's number of a position, texture coordinate or normal: 1-based, or negative, counting back from the last line so far.
		function index(word:String, count:Int, what:String, line:Int):Int {
			var n = ObjText.integer(word, line);
			var i = n > 0 ? n - 1 : count + n;
			if (n == 0 || i < 0 || i >= count)
				throw 'Line $line: a corner names $what $n, but the file has $count before it';
			return i;
		}
		for (k => text in lines) {
			var line = k + 1, words = ObjText.words(text);
			if (words.length == 0)
				continue;
			var values = words.length - 1;
			switch words[0] {
				case "v":
					if (values != 3 && values != 4 && values != 6)
						throw 'Line $line: a position has $values values, not 3, 4 or 6';
					for (i in 1...4)
						positions.push(ObjText.number(words[i], line));
					if (values == 4)
						ObjText.number(words[4], line);
					if (values == 6) {
						colored++;
						for (i in 4...7)
							colors.push(ObjText.number(words[i], line));
					} else
						for (_ in 0...3)
							colors.push(0);
				case "vt":
					if (values < 1 || values > 3)
						throw 'Line $line: a texture coordinate has $values values, not 1 to 3';
					texCoords.push(ObjText.number(words[1], line));
					texCoords.push(values > 1 ? ObjText.number(words[2], line) : 0);
					if (values > 2)
						ObjText.number(words[3], line);
				case "vn":
					if (values != 3)
						throw 'Line $line: a normal has $values values, not 3';
					for (i in 1...4)
						normals.push(ObjText.number(words[i], line));
				case "f":
					if (values == 0)
						throw 'Line $line: a face with no corners';
					var p = [], t = [], n = [];
					for (i in 1...words.length) {
						var parts = words[i].split("/");
						if (parts.length > 3 || parts[0] == "" || (parts.length == 3 && parts[2] == ""))
							throw 'Line $line: "${words[i]}" is not a corner';
						p.push(index(parts[0], Std.int(positions.length / 3), "position", line));
						t.push(parts.length > 1
							&& parts[1] != "" ? index(parts[1], Std.int(texCoords.length / 2), "texture coordinate", line) : -1);
						n.push(parts.length > 2 ? index(parts[2], Std.int(normals.length / 3), "normal", line) : -1);
					}
					if (values < 3)
						continue;
					if (runFirst < 0 || runObject != objectName || runGroup != groupName) {
						close();
						runObject = objectName;
						runGroup = groupName;
						runFirst = faceVertexCounts.length;
					}
					faceVertexCounts.push(values);
					faceFirstCornerIndices.push(cornerPositionIndices.length);
					faceMaterialIndices.push(material);
					for (i in 0...values) {
						cornerPositionIndices.push(p[i]);
						cornerTexCoordIndices.push(t[i]);
						cornerNormalIndices.push(n[i]);
					}
				case "o":
					objectName = ObjText.rest(text, "o");
					groupName = "";
				case "g":
					groupName = ObjText.rest(text, "g");
				case "usemtl":
					var name = ObjText.rest(text, "usemtl");
					if (name == "")
						throw 'Line $line: usemtl names no material';
					var found = materialOf.get(name);
					if (found == null) {
						found = materialNames.length;
						materialOf.set(name, found);
						materialNames.push(name);
					}
					material = found;
				case "mtllib":
					for (i in 1...words.length)
						materialLibraryPaths.push(ObjText.resolve(words[i], path));
				case _:
			}
		}
		close();
		var positionCount = Std.int(positions.length / 3);
		return new ObjFile(positionCount, positions, positionCount > 0
			&& colored == positionCount ? colors : null, Std.int(texCoords.length / 2), texCoords,
			Std.int(normals.length / 3), normals, faceVertexCounts.length, faceVertexCounts, faceFirstCornerIndices, faceMaterialIndices,
			cornerPositionIndices.length, cornerPositionIndices, cornerTexCoordIndices, cornerNormalIndices, materialNames, materialLibraryPaths, groups);
	}

	function new(positionCount:Int, positions:haxe.ds.ReadOnlyArray<Float>, colors:Null<haxe.ds.ReadOnlyArray<Float>>, texCoordCount:Int,
			texCoords:haxe.ds.ReadOnlyArray<Float>, normalCount:Int, normals:haxe.ds.ReadOnlyArray<Float>, faceCount:Int,
			faceVertexCounts:haxe.ds.ReadOnlyArray<Int>, faceFirstCornerIndices:haxe.ds.ReadOnlyArray<Int>, faceMaterialIndices:haxe.ds.ReadOnlyArray<Int>,
			cornerCount:Int, cornerPositionIndices:haxe.ds.ReadOnlyArray<Int>, cornerTexCoordIndices:haxe.ds.ReadOnlyArray<Int>,
			cornerNormalIndices:haxe.ds.ReadOnlyArray<Int>, materialNames:haxe.ds.ReadOnlyArray<String>, materialLibraryPaths:haxe.ds.ReadOnlyArray<String>,
			groups:Array<ObjGroup>) {
		this.positionCount = positionCount;
		this.positions = positions;
		this.colors = colors;
		this.texCoordCount = texCoordCount;
		this.texCoords = texCoords;
		this.normalCount = normalCount;
		this.normals = normals;
		this.faceCount = faceCount;
		this.faceVertexCounts = faceVertexCounts;
		this.faceFirstCornerIndices = faceFirstCornerIndices;
		this.faceMaterialIndices = faceMaterialIndices;
		this.cornerCount = cornerCount;
		this.cornerPositionIndices = cornerPositionIndices;
		this.cornerTexCoordIndices = cornerTexCoordIndices;
		this.cornerNormalIndices = cornerNormalIndices;
		this.materialNames = materialNames;
		this.materialLibraryPaths = materialLibraryPaths;
		this.groups = groups;
	}
}
