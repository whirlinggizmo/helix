package helix.ray.internal;

import helix.formats.obj.MtlFile;
import helix.formats.obj.MtlMaterial;
import helix.formats.obj.ObjFile;
import helix.ray.*;

/** Makes raylib's models of OBJ files and its materials of MTL files, as raylib 6.2's `LoadOBJ` and `ProcessMaterialsOBJ` make them
	from what tinyobj_loader_c reads, from helix-formats' `ObjFile` and `MtlFile`. */
@:noCompletion
class ObjModels {
	/** Returns the library raylib reads for an OBJ file: tinyobj_loader_c reads only the last `mtllib` line's.

		@param obj  The file.
		@return  The library's path, or null when it names none. */
	public static function libraryPath(obj:ObjFile):Null<String> {
		var paths = obj.materialLibraryPaths;
		return paths.length > 0 ? paths[paths.length - 1] : null;
	}

	/** Returns the textures a library's materials name that raylib loads: each material's diffuse, specular, bump (`bumpTexture`) and
		displacement textures, each file once.

		@param library  The library, or null for none.
		@return  Their paths. */
	public static function texturePaths(library:Null<MtlFile>):Array<String> {
		var paths = [];
		if (library != null)
			for (m in library.materials)
				for (path in [
					m.diffuseTexturePath,
					m.specularTexturePath,
					bumpTexture(m),
					m.displacementTexturePath
				])
					if (path != null && paths.indexOf(path) < 0)
						paths.push(path);
		return paths;
	}

	/** Returns a material's bump texture as tinyobj_loader_c reads it: the last `bump` or `map_bump` line's, `map_Bump` not among them.

		@param m  The material.
		@return  The path, or null for none. */
	public static function bumpTexture(m:MtlMaterial):Null<String>
		return m.findTexturePath(["bump", "map_bump"]);

	/** Returns an OBJ file's model as raylib 6.2's `LoadOBJ` makes it, its materials none (`materials` makes them for each load).

		Its faces are tinyobj_loader_c's: each polygon a fan from its first corner, a triangle a face, one of 1 or 2 corners none. A new
		mesh starts at a face where the next of the file's groups (tinyobj's shapes: one at each `o` or `g` line with faces after it)
		starts, counting the groups' starts in the file's `f` lines where the faces walked are triangles, as raylib counts them, so a
		polygon, or a face of 1 or 2 corners, before a group moves the mesh's start; and at a face whose material differs from the face
		before's, unless that face had none, so faces before any `usemtl` join the next material's mesh. Each mesh's vertices are its
		corners, three a triangle, unindexed: its positions, (0, 0, 0) for a corner naming one the file doesn't have; its normals,
		(0, 1, 0) for a corner without one or naming one the file doesn't have; its texture coordinates, v turned (1 - v), (0, 0) for a
		corner without them or naming ones the file doesn't have; its colors white. A mesh's material is its last
		face's, when that material is in the library, else 0. A file without faces has one mesh, empty.

		@param obj  The file.
		@param library  The library raylib reads (`libraryPath`), or null when it names none or it couldn't be read.
		@return  The model, its meshes' GPU buffers shared by its loads (holders 0). */
	public static function template(obj:ObjFile, library:Null<MtlFile>):Model {
		// tinyobj's material ids: a name's index in the library, the last of a name when several share it; -1 for one it lacks.
		var ids = new Map<String, Int>(),
			count = library != null ? library.materials.length : 0;
		if (library != null)
			for (i => m in library.materials)
				ids.set(m.name, i);
		var faceIds = [for (name in obj.materialNames) ids.exists(name) ? ids.get(name) : -1];
		// Each triangle's material id and corners, as tinyobj lists its faces.
		var materialIds = [], corners = [];
		for (f in 0...obj.faceCount) {
			var id = obj.faceMaterialIndices[f] >= 0 ? faceIds[obj.faceMaterialIndices[f]] : -1;
			var triangles = obj.computeTriangles(f, 1);
			for (t in 0...Std.int(triangles.length / 3)) {
				materialIds.push(id);
				for (k in 0...3)
					corners.push(triangles[t * 3 + k]);
			}
		}
		var faces = materialIds.length;
		// tinyobj's shapes start where the file's groups do, counted in the file's faces.
		var shapeStarts = [for (g in obj.groups) g.firstFaceIndex];
		// raylib's walk: a mesh for each run, and each mesh's corners.
		var meshCorners:Array<Array<Int>> = [[]], meshMaterial = [0];
		var nextShape = 1, nextShapeEnd = shapeStarts.length > 1 ? shapeStarts[1] : faces * 3, lastMaterial = -1;
		for (faceId in 0...faces) {
			var newMesh = false;
			if (faceId >= nextShapeEnd) {
				nextShape++;
				nextShapeEnd = nextShape < shapeStarts.length ? shapeStarts[nextShape] : faces * 3;
				newMesh = true;
			}
			if (lastMaterial != -1 && materialIds[faceId] != lastMaterial)
				newMesh = true;
			lastMaterial = materialIds[faceId];
			if (newMesh) {
				meshCorners.push([]);
				meshMaterial.push(0);
			}
			meshMaterial[meshMaterial.length - 1] = lastMaterial >= 0 && lastMaterial < count ? lastMaterial : 0;
			for (k in 0...3)
				meshCorners[meshCorners.length - 1].push(corners[faceId * 3 + k]);
		}
		var meshes = [for (c in meshCorners) mesh(obj, c)];
		return new Model(meshes, [], meshMaterial);
	}

	// A mesh of corners, as raylib 6.2 fills one: positions ((0, 0, 0) for one the file lacks), normals ((0, 1, 0) without one or for
	// one it lacks), texture coordinates (v turned, (0, 0) without them or for ones it lacks) and white colors, as floats and bytes; its GPU buffers to be shared by the file's loads.
	static function mesh(obj:ObjFile, corners:Array<Int>):Mesh {
		var f32 = Pixels.f32;
		var vertices = [], normals = [], texcoords = [], colors = [];
		for (c in corners) {
			var p = obj.cornerPositionIndices[c],
				n = obj.cornerNormalIndices[c],
				t = obj.cornerTexCoordIndices[c];
			for (k in 0...3)
				vertices.push(p < obj.positionCount ? f32(obj.positions[p * 3 + k]) : 0);
			if (n >= 0 && n < obj.normalCount)
				for (k in 0...3)
					normals.push(f32(obj.normals[n * 3 + k]));
			else {
				normals.push(0);
				normals.push(1);
				normals.push(0);
			}
			if (t >= 0 && t < obj.texCoordCount) {
				texcoords.push(f32(obj.texCoords[t * 2]));
				texcoords.push(f32(1 - f32(obj.texCoords[t * 2 + 1])));
			} else {
				texcoords.push(0);
				texcoords.push(0);
			}
			for (_ in 0...4)
				colors.push(255);
		}
		var mesh = new Mesh();
		mesh.vertexCount = corners.length;
		mesh.triangleCount = Std.int(corners.length / 3);
		mesh.vertices = vertices;
		mesh.normals = normals;
		mesh.texcoords = texcoords;
		mesh.colors = colors;
		var gpu = new MeshGpu();
		gpu.holders = 0;
		gpu.shared = true;
		mesh.gpu = gpu;
		return mesh;
	}

	/** Returns a library's materials as raylib's `ProcessMaterialsOBJ` makes them, each held once: raylib's default material, then the
		diffuse texture (`map_Kd`), or with none the diffuse color (`Kd`, alpha 255); the specular texture (`map_Ks`) and color (`Ks`);
		the normal map the bump texture (`bumpTexture`), its color white and its value the specular exponent (`Ns`); the emission
		color (`Ke`); the height map the displacement texture (`disp`); each value 0 but the normal map's. What the file doesn't give is
		tinyobj_loader_c's default: each color black, the specular exponent 1. A color's bytes are raylib's
		(unsigned char)(f*255). A texture is its file's, decoded already (`Runtime.image`), shared with every load of the file; one that
		couldn't be read is none (id 0). With no materials, a model has the default material alone (`LoadOBJ`).

		@param library  The library.
		@param shader  The default shader.
		@return  The materials, in the library's order. */
	public static function materials(library:MtlFile, shader:Shader):Array<Material>
		return [for (m in library.materials) material(m, shader)];

	static function material(m:MtlMaterial, shader:Shader):Material {
		var material = Models.defaultMaterial(shader), maps = material.maps;
		// tinyobj_loader_c's colors: black where the file gives none.
		function color(c:Null<haxe.ds.ReadOnlyArray<Float>>):Color
			return c == null ? new Color(0, 0, 0, 255) : new Color(Models.byte(c[0]), Models.byte(c[1]), Models.byte(c[2]), 255);
		function texture(map:MaterialMap, path:String):Void {
			var image = Runtime.image(path);
			if (image == null) {
				Runtime.log(4, 'IMAGE: Failed to load image data');
				map.texture = new Texture2D();
				return;
			}
			Models.give(map, path, () -> image, image.width, image.height, Raylib.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
		}
		var diffuse = maps[Raylib.MATERIAL_MAP_DIFFUSE];
		if (m.diffuseTexturePath != null)
			texture(diffuse, m.diffuseTexturePath);
		else
			diffuse.color = color(m.diffuse);
		diffuse.value = 0;
		var specular = maps[Raylib.MATERIAL_MAP_SPECULAR];
		if (m.specularTexturePath != null)
			texture(specular, m.specularTexturePath);
		specular.color = color(m.specular);
		specular.value = 0;
		var normal = maps[Raylib.MATERIAL_MAP_NORMAL];
		var bump = bumpTexture(m);
		if (bump != null)
			texture(normal, bump);
		normal.color = new Color(255, 255, 255, 255);
		// tinyobj_loader_c's specular exponent: 1 where the file gives none.
		normal.value = Pixels.f32(m.shininess != null ? m.shininess : 1);
		maps[Raylib.MATERIAL_MAP_EMISSION].color = color(m.emission);
		if (m.displacementTexturePath != null)
			texture(maps[Raylib.MATERIAL_MAP_HEIGHT], m.displacementTexturePath);
		return material;
	}
}
