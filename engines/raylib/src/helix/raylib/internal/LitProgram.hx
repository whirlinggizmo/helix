package helix.raylib.internal;

import helix.services.shaders.ShaderUniform;

/** Holds the PBR shader on the GPU (`LoadPbrShader`), and its skinned twin: a program whose draws also write the material's values, and
	give a normal-mapped mesh its tangents first. Only `LoadPbrShader` makes one, so a program without it links none of it. */
@:noCompletion
class LitProgram extends Program {
	// The uniforms of the material's values, found when first written: null for one the shader doesn't declare.
	var metallicValue:Null<ShaderUniform>;
	var roughnessValue:Null<ShaderUniform>;
	var found = false;

	// What a draw's values are written from, so a draw allocates none.
	static final one:Array<Float> = [0];

	/** Returns the textures a draw binds, as `Program`'s, having written the material's values for the draw after:
		`maps[MATERIAL_MAP_METALNESS].value` as `metallicValue` and `maps[MATERIAL_MAP_ROUGHNESS].value` as `roughnessValue` (the
		Materials extra's are `Surfaces`'). A mesh without tangents whose material has a normal map gets them first (`GenMeshTangents`),
		as glTF asks of a file without them.

		@param mesh  The mesh drawn.
		@param locs  The locations it is drawn by, by `SHADER_LOC_*`.
		@param material  The material.
		@return  The textures' handles, by slot; -1 for a slot nothing binds. */
	override public function mapTextures(mesh:helix.raylib.Mesh, locs:Array<Int>, material:helix.raylib.Material):Array<Int> {
		if (!found) {
			found = true;
			metallicValue = shader.findUniform("metallicValue");
			roughnessValue = shader.findUniform("roughnessValue");
		}
		var maps = material.maps;
		if (mesh.tangents == null
			&& mesh.texcoords != null
			&& mesh.normals != null
			&& maps[helix.raylib.Raylib.MATERIAL_MAP_NORMAL].texture.id > 0)
			@:privateAccess helix.raylib.modules.RModels.GenMeshTangents(mesh);
		if (metallicValue != null) {
			one[0] = maps[helix.raylib.Raylib.MATERIAL_MAP_METALNESS].value;
			put(metallicValue, one, 0);
		}
		if (roughnessValue != null) {
			one[0] = maps[helix.raylib.Raylib.MATERIAL_MAP_ROUGHNESS].value;
			put(roughnessValue, one, 0);
		}
		return super.mapTextures(mesh, locs, material);
	}
}
