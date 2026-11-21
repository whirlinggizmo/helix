package helix.raylib.internal;

/** Holds the PBR shader on the GPU (`LoadPbrShader`), and its skinned and instanced twins: a program whose draws compute a normal-mapped
	mesh's tangents first. Only `LoadPbrShader` makes one, so a program without it links none of it. */
@:noCompletion
class LitProgram extends Program {
	/** Returns the textures a draw binds, as `Program`'s. A mesh without tangents whose material has a normal map gets them first
		(`GenMeshTangents`), as glTF asks of a file without them.

		@param mesh  The mesh drawn.
		@param locs  The locations it is drawn by, by `SHADER_LOC_*`.
		@param material  The material.
		@return  The textures' handles, by slot; -1 for a slot nothing binds. */
	override public function mapTextures(mesh:helix.raylib.Mesh, locs:Array<Int>, material:helix.raylib.Material):Array<Int> {
		var maps = material.maps;
		if (mesh.tangents == null
			&& mesh.texcoords != null
			&& mesh.normals != null
			&& maps[helix.raylib.Raylib.MATERIAL_MAP_NORMAL].texture.id > 0)
			@:privateAccess helix.raylib.modules.RModels.GenMeshTangents(mesh);
		return super.mapTextures(mesh, locs, material);
	}
}
