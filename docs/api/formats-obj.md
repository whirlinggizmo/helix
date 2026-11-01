# helix.formats.obj

[Back to the index](README.md)

## MtlFile

*class* in [`formats/src/helix/formats/obj/MtlFile.hx`](../../formats/src/helix/formats/obj/MtlFile.hx), `import helix.formats.obj.MtlFile;`

Represents a Wavefront material library read from an .mtl file, or several combined: the materials an OBJ model's `usemtl` lines name.

```haxe
var library = MtlFile.read(bytes, "models/house.mtl");
var wall = library.findMaterial("wall");
var color = wall != null ? wall.diffuse : MtlMaterial.DEFAULT.diffuse;
```

```haxe
static function combine(libraries:Array<MtlFile>):MtlFile
static function read(bytes:haxe.io.Bytes, path:String):MtlFile
final materials:haxe.ds.ReadOnlyArray<MtlMaterial>
function findMaterial(name:String):Null<MtlMaterial>
```

- `combine`: Returns several libraries as one, as an OBJ model that names them all uses them: their materials in turn, a name already given by an earlier library left out.
  - `libraries`: The libraries, in the order the model names them; none gives a library with no materials.
  - returns: The library.
- `read`: Reads a material library.
  - `bytes`: The file's bytes, as UTF-8 text.
  - `path`: The file's path, whose directory texture paths are resolved against.
  - returns: The library.
  - throws `String`: Its bytes aren't UTF-8 text, or a line can't be read, naming its number: read each library apart to skip one that's broken. Only a String is thrown.
- `materials`: Gets the materials, in the file's order: a new one at each `newmtl` line.
- `findMaterial`: Returns the material of a name.
  - `name`: The name, as `newmtl` gives it; case counts.
  - returns: The material, the first when several share the name, or null when there is none of that name.

## MtlMaterial

*class* in [`formats/src/helix/formats/obj/MtlMaterial.hx`](../../formats/src/helix/formats/obj/MtlMaterial.hx), `import helix.formats.obj.MtlMaterial;`

Represents one material of an .mtl file: its colors, factors and the textures it names, as paths resolved against the file's directory and normalized as `ObjFile`'s are (null for none). Its colors are arrays the material holds, `DEFAULT`'s too: read them, don't change them. A texture line's options (`-s`, `-o`, `-bm` and the rest) are read past; only the path is kept.

Besides the classic statements, it reads the PBR extension Blender and others write (`Pr`, `Pm`, `map_Pr`, `map_Pm`, `norm`), whose values are absent from older files. Each color is three values, red, green and blue, each usually 0 to 1.

```haxe
static final DEFAULT(default, null):MtlMaterial
final name:String
final defined:Bool
final ambient:haxe.ds.ReadOnlyArray<Float>
final diffuse:haxe.ds.ReadOnlyArray<Float>
final specular:haxe.ds.ReadOnlyArray<Float>
final emission:haxe.ds.ReadOnlyArray<Float>
final transmission:haxe.ds.ReadOnlyArray<Float>
final shininess:Float
final opticalDensity:Float
final opacity:Float
final illumination:Int
final roughness:Null<Float>
final metalness:Null<Float>
final ambientTexturePath:Null<String>
final diffuseTexturePath:Null<String>
final specularTexturePath:Null<String>
final shininessTexturePath:Null<String>
final emissionTexturePath:Null<String>
final opacityTexturePath:Null<String>
final bumpTexturePath:Null<String>
final displacementTexturePath:Null<String>
final normalTexturePath:Null<String>
final roughnessTexturePath:Null<String>
final metalnessTexturePath:Null<String>
function computeRoughness():Float
function computeMetalness():Float
function computeNormalTexturePath():Null<String>
```

- `DEFAULT`: The material a face uses when it names none: named "", not `defined`, with every value its default (white, opaque, no textures).
- `name`: Gets the name `newmtl` gives it.
- `defined`: Gets whether a library gives it: false for `DEFAULT` and for the stand-in `ObjFile.computeMaterials` makes for a name no library gives.
- `ambient`: Gets the ambient color (`Ka`). Defaults to 0, 0, 0.
- `diffuse`: Gets the diffuse color (`Kd`). Defaults to 1, 1, 1.
- `specular`: Gets the specular color (`Ks`). Defaults to 0, 0, 0.
- `emission`: Gets the emissive color (`Ke`). Defaults to 0, 0, 0.
- `transmission`: Gets the transmission filter (`Tf`). Defaults to 1, 1, 1.
- `shininess`: Gets the specular exponent (`Ns`), usually 0 to 1000. Defaults to 0.
- `opticalDensity`: Gets the optical density (`Ni`), the material's index of refraction. Defaults to 1.
- `opacity`: Gets the opacity, 0 to 1: `d`, or 1 minus `Tr` when only that is given (`d` wins when both are). Defaults to 1.
- `illumination`: Gets the illumination model (`illum`), 0 to 10. Defaults to 0.
- `roughness`: Gets the roughness (`Pr`), 0 to 1, or null when the file gives none: `computeRoughness` gives one either way.
- `metalness`: Gets the metalness (`Pm`), 0 to 1, or null when the file gives none: `computeMetalness` gives one either way.
- `ambientTexturePath`: Gets the ambient texture's path (`map_Ka`).
- `diffuseTexturePath`: Gets the diffuse texture's path (`map_Kd`).
- `specularTexturePath`: Gets the specular texture's path (`map_Ks`).
- `shininessTexturePath`: Gets the specular exponent texture's path (`map_Ns`).
- `emissionTexturePath`: Gets the emissive texture's path (`map_Ke`).
- `opacityTexturePath`: Gets the opacity texture's path (`map_d`): the opacity on its own, apart from any alpha the diffuse texture has.
- `bumpTexturePath`: Gets the bump texture's path (`map_bump`, `map_Bump` or `bump`): a height map, or a normal map in many files (Blender writes its normal maps here); `computeNormalTexturePath` picks the normal map either way.
- `displacementTexturePath`: Gets the displacement texture's path (`disp`).
- `normalTexturePath`: Gets the normal map's path (`norm`, the PBR extension).
- `roughnessTexturePath`: Gets the roughness texture's path (`map_Pr`).
- `metalnessTexturePath`: Gets the metalness texture's path (`map_Pm`).
- `computeRoughness`: Returns the roughness to draw with, 0 to 1: the file's (`roughness`), or one made from the specular exponent when it gives none, `1 - sqrt(shininess / 1000)` held to 0 to 1, as Blender reads older files: the shinier, the smoother.
  - returns: The roughness.
- `computeMetalness`: Returns the metalness to draw with, 0 to 1: the file's (`metalness`), or 0 when it gives none, as older files describe no metals.
  - returns: The metalness.
- `computeNormalTexturePath`: Returns the normal map to draw with: the file's normal map (`norm`), or its bump texture when it gives none, as most exporters write normal maps there; null when it gives neither.
  - returns: The path, or null.

## ObjFile

*class* in [`formats/src/helix/formats/obj/ObjFile.hx`](../../formats/src/helix/formats/obj/ObjFile.hx), `import helix.formats.obj.ObjFile;`

Represents a Wavefront OBJ model read from an .obj file: its vertex data, its faces and their groups, as the file gives them.

The file's positions, texture coordinates and normals are numbered from 0 in the order of their lines (`v`, `vt`, `vn`); the file's own 1-based and negative (relative) numbers are turned into these. A face is a polygon of corners, kept as the file writes it, and each corner names a position by its number, and may name a texture coordinate and a normal. `computeTriangles` splits the faces into triangles.

A face's material is named by the `usemtl` line before it, which holds across `o` and `g` lines until the next `usemtl`. The materials themselves are in the .mtl files `materialLibraryPaths` names, read by `MtlFile`; `computeMaterials` finds each name's. `computeParts` gathers the faces into parts, one for each object, group and material, split into triangles. Points, lines, curves and surfaces are not read; a face of fewer than 3 corners is left out of every face array.

Values are as the file gives them: texture coordinates are not flipped (v is 0 at the image's bottom, as OBJ has it), normals are not normalized, and a face's corners go counter-clockwise seen from its front, as OBJ has them. Paths are resolved against the file's directory and normalized: `/` between parts, `.` and `..` taken out; an absolute path is kept as it is, and a `..` above the root is kept at its start. The arrays are the file's own, read-only.

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
```

```haxe
static function read(bytes:haxe.io.Bytes, path:String):ObjFile
final positionCount:Int
final positions:haxe.ds.ReadOnlyArray<Float>
final colors:Null<haxe.ds.ReadOnlyArray<Float>>
final texCoordCount:Int
final texCoords:haxe.ds.ReadOnlyArray<Float>
final normalCount:Int
final normals:haxe.ds.ReadOnlyArray<Float>
final faceCount:Int
final faceVertexCounts:haxe.ds.ReadOnlyArray<Int>
final faceFirstCornerIndices:haxe.ds.ReadOnlyArray<Int>
final faceMaterialIndices:haxe.ds.ReadOnlyArray<Int>
final cornerCount:Int
final cornerPositionIndices:haxe.ds.ReadOnlyArray<Int>
final cornerTexCoordIndices:haxe.ds.ReadOnlyArray<Int>
final cornerNormalIndices:haxe.ds.ReadOnlyArray<Int>
final materialNames:haxe.ds.ReadOnlyArray<String>
final materialLibraryPaths:haxe.ds.ReadOnlyArray<String>
final groups:Array<ObjGroup>
function computeTriangles(firstFaceIndex:Int, faceCount:Int):Array<Int>
function computeMaterials(library:MtlFile):Array<MtlMaterial>
function computeParts(byGroup:Bool):Array<ObjPart>
```

- `read`: Reads an OBJ model.
  - `bytes`: The file's bytes, as UTF-8 text.
  - `path`: The file's path, whose directory `mtllib` paths are resolved against.
  - returns: The model.
  - throws `String`: The file is refused, never read in part: its bytes aren't UTF-8 text, a line can't be read (naming its number), or a corner names a position, texture coordinate or normal the file doesn't have. Only a String is thrown.
- `positionCount`: Gets how many positions the file has: one for each `v` line.
- `positions`: Gets the positions, three values for each (as every array here, the file's own: read it, don't change it): position i's x, y and z at `positions[3 * i]`, `[3 * i + 1]` and `[3 * i + 2]`. A fourth value a `v` line may give, w, is dropped.
- `colors`: Gets the positions' colors, three values for each, red, green and blue from 0 to 1: position i's at `colors[3 * i]` on, so a corner's color is its position's. Null unless every `v` line gives six values (a common extension): a file where only some do has none.
- `texCoordCount`: Gets how many texture coordinates the file has: one for each `vt` line.
- `texCoords`: Gets the texture coordinates, two values for each: coordinate i's u and v at `texCoords[2 * i]` and `[2 * i + 1]`. A third value, w, is dropped.
- `normalCount`: Gets how many normals the file has: one for each `vn` line.
- `normals`: Gets the normals, three values for each: normal i's x, y and z at `normals[3 * i]` on, as the file gives them, not normalized.
- `faceCount`: Gets how many faces the file has.
- `faceVertexCounts`: Gets how many corners each face has, in the file's order: 3 for a triangle, more for a polygon.
- `faceFirstCornerIndices`: Gets where each face's corners start in the corner arrays: face f's corners are from `faceFirstCornerIndices[f]` up to, but not including, that plus `faceVertexCounts[f]`.
- `faceMaterialIndices`: Gets each face's material, by its index in `materialNames`, or -1 for a face before any `usemtl`.
- `cornerCount`: Gets how many corners the faces have in all: the length of each corner array.
- `cornerPositionIndices`: Gets each corner's position, by its number (0 to `positionCount` - 1), the corners of each face in turn.
- `cornerTexCoordIndices`: Gets each corner's texture coordinate, by its number (0 to `texCoordCount` - 1), or -1 when the corner names none.
- `cornerNormalIndices`: Gets each corner's normal, by its number (0 to `normalCount` - 1), or -1 when the corner names none.
- `materialNames`: Gets the material names the `usemtl` lines give, each once, in the order the file first uses them, matched as written (case counts).
- `materialLibraryPaths`: Gets the paths of the .mtl files the `mtllib` lines name, in the file's order, ready to load: a line naming several files gives a path for each, split at spaces, so a file name can't hold one.
- `groups`: Gets the file's groups of faces: runs of faces in one object and one group, in the file's order, a new one wherever an `o` or `g` line between faces changes the object or group (two `g a` lines with no faces between are one group). A name can come back later in the file as a group of its own (`g a`, `g b`, `g a` are three groups); `computeParts` joins them. A `usemtl` line doesn't start a group: a group's faces may have several materials. A group with no faces is left out.
- `computeTriangles`: Returns some faces split into triangles, each polygon a fan from its first corner (corners 0, i and i + 1), as most readers do: a face of n corners gives n - 2 triangles, in the faces' order.
  - `firstFaceIndex`: The first face.
  - `faceCount`: How many faces, from it.
  - returns: Three corners for each triangle, by their index in the corner arrays.
- `computeMaterials`: Returns the material of each name in `materialNames`, from a library: the library's of that name, or, for a name it doesn't give, a material of that name with every value its default (as `MtlMaterial.DEFAULT`'s). Whether a name was found is `library.findMaterial(name) != null`.
  - `library`: The library: those `materialLibraryPaths` names, read and combined (`MtlFile.combine`).
  - returns: A material for each of `materialNames`, in its order, so `faceMaterialIndices` and `ObjPart.materialIndex` index it too; never null.
- `computeParts`: Returns the faces gathered into parts, each split into triangles as `computeTriangles` splits them: one part for each object, group and material, the faces of a name that comes back later in the file joined to its part. Parts come in the order their first face does.
  - `byGroup`: True for a part for each object, group and material; false for one for each material alone, the objects and groups ignored (their names "" in the parts).
  - returns: The parts; none for a file without faces.

  Faces before any `usemtl` make a part of their own, its `materialIndex` -1 and its `materialName` "".

## ObjGroup

*class* in [`formats/src/helix/formats/obj/ObjGroup.hx`](../../formats/src/helix/formats/obj/ObjGroup.hx), `import helix.formats.obj.ObjGroup;`

Represents a run of an OBJ model's faces that are in one object and one group: the faces after an `o` or `g` line, up to the next such line.

```haxe
final objectName:String
final groupName:String
final firstFaceIndex:Int
final faceCount:Int
```

- `objectName`: Gets the object the faces are in: the name the last `o` line gives, the whole rest of its line, or "" before the first.
- `groupName`: Gets the group the faces are in: the name the last `g` line in this object gives, the whole rest of its line (a line naming several groups keeps them as written), or "" when the object has none yet: an `o` line starts its object with no group.
- `firstFaceIndex`: Gets the index of its first face in the face arrays (`ObjFile.faceVertexCounts` and the others).
- `faceCount`: Gets how many faces it has; at least 1.

## ObjPart

*class* in [`formats/src/helix/formats/obj/ObjPart.hx`](../../formats/src/helix/formats/obj/ObjPart.hx), `import helix.formats.obj.ObjPart;`

Represents a part of an OBJ model, as `ObjFile.computeParts` gathers them: the faces of one object, group and material, split into triangles.

```haxe
final objectName:String
final groupName:String
final materialIndex:Int
final materialName:String
final cornerIndices:haxe.ds.ReadOnlyArray<Int>
final triangleCount:Int
```

- `objectName`: Gets the object's name, as `ObjGroup.objectName`; "" when parts aren't by group.
- `groupName`: Gets the group's name, as `ObjGroup.groupName`; "" when parts aren't by group.
- `materialIndex`: Gets the material, by its index in `ObjFile.materialNames` (and in what `ObjFile.computeMaterials` returns), or -1 for faces before any `usemtl`.
- `materialName`: Gets the material's name, as the file's `usemtl` gives it, or "" for faces before any `usemtl`.
- `cornerIndices`: Gets the triangles, three corners each, by their index in the corner arrays (`ObjFile.cornerPositionIndices` and the others).
- `triangleCount`: Gets how many triangles it has: a third of `cornerIndices`' length.
