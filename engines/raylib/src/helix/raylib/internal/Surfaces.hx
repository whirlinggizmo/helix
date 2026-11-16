package helix.raylib.internal;

import helix.services.shaders.ShaderUniform;

/** Writes a material's values (the Materials extra's) into each draw through a shader declaring them: `emissiveColor`, the light the
	material gives off; `modelEmissiveColor`, the light its model gives off (`SetModelEmissive`), 0 for a draw of a mesh alone;
	`alphaCutoff`; `unlitValue`, 1 for an unlit material; and `shadowed`, 1 when shadows fall on it.

	Set as the draws' hook (`RModels.surfacing`) by the first lit or PBR shader and the first compiled shader declaring one of them, so a
	program using none links none of it. The Materials extra sets its own hook, which also chooses the default shader's variant. */
@:noCompletion
@:access(helix.raylib.Material)
class Surfaces {
	// The uniforms, by the indices of a program's surfaceFields.
	static final FIELDS = ["emissiveColor", "modelEmissiveColor", "alphaCutoff", "unlitValue", "shadowed"];
	static final NONE:Array<Null<ShaderUniform>> = [];

	/** Sets the draws' hook to this writer, unless one is set. */
	public static function install():Void {
		if (helix.raylib.modules.RModels.surfacing == null)
			helix.raylib.modules.RModels.surfacing = draw;
	}

	/** Returns whether a shader declares one of the values a draw writes.

		@param shader  The shader as compiled. */
	public static function declares(shader:helix.services.shaders.Shader):Bool {
		for (name in FIELDS)
			if (shader.findUniform(name) != null)
				return true;
		return false;
	}

	// The hook: the material's values written for its draw through its own shader.
	static function draw(shader:helix.raylib.Shader, material:helix.raylib.Material, modelEmissive:Null<Array<Float>>):helix.raylib.Shader {
		write(shader.program, material, modelEmissive);
		return shader;
	}

	/** Writes a material's values into a program and its skinned twin, for the draw after.

		@param p  The program.
		@param material  The material.
		@param modelEmissive  The light its model gives off, red, green and blue; null for none. */
	public static function write(p:Program, material:helix.raylib.Material, modelEmissive:Null<Array<Float>>):Void {
		writeOne(p, material, modelEmissive);
		if (p.twin != null)
			writeOne(p.twin, material, modelEmissive);
	}

	static function writeOne(p:Program, material:helix.raylib.Material, modelEmissive:Null<Array<Float>>):Void {
		if (p.surfaceFields == null) {
			var found = [for (name in FIELDS) p.shader.findUniform(name)];
			p.surfaceFields = [for (u in found) if (u != null) u].length == 0 ? NONE : found;
		}
		var f = p.surfaceFields;
		if (f.length == 0)
			return;
		var values = p.values;
		if (f[0] != null)
			color(p, f[0], material.emissiveRed, material.emissiveGreen, material.emissiveBlue);
		if (f[1] != null)
			if (modelEmissive == null)
				color(p, f[1], 0, 0, 0);
			else
				color(p, f[1], modelEmissive[0], modelEmissive[1], modelEmissive[2]);
		if (f[2] != null)
			values.writeFloat(f[2], material.alphaCutoff);
		if (f[3] != null)
			number(p, f[3], material.unlit ? 1 : 0);
		if (f[4] != null)
			number(p, f[4], material.shadowed ? 1 : 0);
	}

	// A color written as a vec3, or a vec4 of alpha 1.
	static function color(p:Program, u:ShaderUniform, r:Float, g:Float, b:Float):Void {
		if (u.type.componentCount == 4)
			p.values.writeVector(u, r, g, b, 1);
		else
			p.values.writeVector3(u, r, g, b);
	}

	// A number written as the uniform's type: an int or a float.
	static function number(p:Program, u:ShaderUniform, value:Int):Void {
		if (u.type.integer)
			p.values.writeInt(u, value);
		else
			p.values.writeFloat(u, value);
	}
}
