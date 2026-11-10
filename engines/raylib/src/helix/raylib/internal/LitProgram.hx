package helix.raylib.internal;

import helix.services.shaders.ShaderUniform;

/** Holds the PBR shader on the GPU (`LoadPbrShader`), and its skinned twin: a program whose draws also write the material's values, and
	give a normal-mapped mesh its tangents first. Only `LoadPbrShader` makes one, so a program without it links none of it. */
@:noCompletion
class LitProgram extends Program {
	// The uniforms of the material's values, found when first written: null for one the shader doesn't declare.
	var metallicValue:Null<ShaderUniform>;
	var roughnessValue:Null<ShaderUniform>;
	var emissiveColor:Null<ShaderUniform>;
	var unlitValue:Null<ShaderUniform>;
	var found = false;

	// What a draw's values are written from, so a draw allocates none.
	static final one:Array<Float> = [0];
	static final four:Array<Float> = [0, 0, 0, 0];

	/** Returns the textures a draw binds, as `Program`'s, having written the material's values for the draw after:
		`maps[MATERIAL_MAP_METALNESS].value` as `metallicValue`, `maps[MATERIAL_MAP_ROUGHNESS].value` as `roughnessValue`,
		`maps[MATERIAL_MAP_EMISSION].color` as `emissiveColor`, taken as linear, and `unlit` as `unlitValue`, 1 or 0. A mesh without
		tangents whose material has a normal map gets them first (`GenMeshTangents`), as glTF asks of a file without them.

		@param mesh  The mesh drawn.
		@param locs  The locations it is drawn by, by `SHADER_LOC_*`.
		@param material  The material.
		@return  The textures' handles, by slot; -1 for a slot nothing binds. */
	override public function mapTextures(mesh:helix.raylib.Mesh, locs:Array<Int>, material:helix.raylib.Material):Array<Int> {
		if (!found) {
			found = true;
			metallicValue = shader.findUniform("metallicValue");
			roughnessValue = shader.findUniform("roughnessValue");
			emissiveColor = shader.findUniform("emissiveColor");
			unlitValue = shader.findUniform("unlitValue");
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
		if (emissiveColor != null) {
			var c = maps[helix.raylib.Raylib.MATERIAL_MAP_EMISSION].color;
			four[0] = c.r / 255;
			four[1] = c.g / 255;
			four[2] = c.b / 255;
			four[3] = c.a / 255;
			put(emissiveColor, four, 0);
		}
		if (unlitValue != null) {
			one[0] = material.unlit ? 1 : 0;
			put(unlitValue, one, 0);
		}
		return super.mapTextures(mesh, locs, material);
	}
}
