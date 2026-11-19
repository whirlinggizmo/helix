package helix.raylib.modules;

#if !macro
import helix.raylib.*;
#end

/** Holds what a material emits, where it is cut out, and whether light and shadows fall on it, read by every draw with it. Each is
	written here, and `helix.raylib.extras.Materials` forwards to each (`tools/gen_raylib.py`).

	A program naming any of them links this class, and its start sets the draws' hook (`RModels.surfacing`) to `draw`, so every draw
	from the first frame on reads a material's values, a glTF file's among them; a program naming none draws as raylib does. */
@:noCompletion
@:allow(helix.raylib)
@:access(helix.raylib.Material)
@:access(helix.raylib.Model)
class RMaterials {
	#if !macro
	static function __init__():Void {
		RModels.surfacing = draw;
	}

	// The default shader's variant reading a material's values (Defaults.materialShader), with its skinned twin, made for the frame it
	// is drawn in: a window made again has a GPU of its own.
	static var variant:Null<Shader>;
	static var variantFrame:Null<helix.raylib.internal.Frame>;

	// The hook: a material drawn with the default shader that is cut out or emits light is drawn through the default shader's
	// variant; then its values are written for the draw (Surfaces).
	static function draw(shader:Shader, material:Material, modelEmissive:Null<Array<Float>>):Shader {
		var frame = helix.raylib.internal.Runtime.frame;
		if (shader.program == frame.defaultProgram
			&& (material.alphaCutoff > 0
				|| material.emissiveRed != 0
				|| material.emissiveGreen != 0
				|| material.emissiveBlue != 0
				|| (modelEmissive != null && (modelEmissive[0] != 0 || modelEmissive[1] != 0 || modelEmissive[2] != 0)))) {
			if (variant == null || variantFrame != frame) {
				variant = RModels.makeShader(helix.raylib.internal.Defaults.materialShader());
				variant.program.mirror(new helix.raylib.internal.Program(helix.raylib.internal.Runtime.graphics,
					helix.raylib.internal.Defaults.materialSkinnedShader()));
				variantFrame = frame;
			}
			shader = variant;
		}
		helix.raylib.internal.Surfaces.write(shader.program, material, modelEmissive);
		return shader;
	}

	/** Sets a material's alpha cutoff: where its albedo's alpha, the albedo map's times its color's, is below the cutoff, the material
		draws nothing, as a leaf cut from a square does. 0 turns the cutoff off. A glTF material whose `alphaMode` is glTF's `MASK` loads
		with its `alphaCutoff`, 0.5 when the file sets none.

		Read at each draw by helix-raylib's default shader, which draws exactly as raylib's while the cutoff is 0, and by `LoadPbrShader`'s
		and `LoadLightingShader`'s draws.

		@param material  The material.
		@param cutoff  The cutoff, 0 to 1. */
	static function SetMaterialAlphaCutoff(material:Material, cutoff:Float):Void {
		material.alphaCutoff = cutoff < 0 ? 0 : cutoff > 1 ? 1 : cutoff;
	}

	/** Returns a material's alpha cutoff, as `SetMaterialAlphaCutoff` set it or its glTF file set it: 0 for none.

		@param material  The material.
		@return  The cutoff, 0 to 1. */
	static function GetMaterialAlphaCutoff(material:Material):Float {
		return material.alphaCutoff;
	}

	/** Sets the light a material emits whatever lights it: its color times the intensity, added to the lit color, as a glowing
		lamp. A glTF material loads with its `emissiveFactor`, and the emission map stays in `maps[MATERIAL_MAP_EMISSION]`. Black or an
		intensity of 0, the default, emits no light. See `SetModelEmissive` for every material of a model at once.

		Read at each draw by `LoadPbrShader`'s and `LoadLightingShader`'s draws, and by helix-raylib's default shader, which draws
		exactly as raylib's while the material emits no light.

		@param material  The material.
		@param color  The color.
		@param intensity  How strong, 0 or more; 1 adds the color itself. */
	static function SetMaterialEmissive(material:Material, color:Color, intensity:Float):Void {
		var strength = intensity > 0 ? intensity / 255 : 0;
		material.emissiveRed = color.r * strength;
		material.emissiveGreen = color.g * strength;
		material.emissiveBlue = color.b * strength;
	}

	/** Returns the light a material emits, as `SetMaterialEmissive` set it or its glTF file set it: its color times its intensity,
		red, green and blue, 0 for none.

		@param material  The material.
		@param out  Optional. The vector filled; a new one when omitted.
		@return  out, or the new vector. */
	static function GetMaterialEmissive(material:Material, ?out:Vector3):Vector3 {
		if (out == null)
			return new Vector3(material.emissiveRed, material.emissiveGreen, material.emissiveBlue);
		out.x = material.emissiveRed;
		out.y = material.emissiveGreen;
		out.z = material.emissiveBlue;
		return out;
	}

	/** Sets whether a material is unlit: drawn in its albedo, the map's times its color, with no light and no shadow falling on it, as a
		glowing lamp, a sky or a sign drawn in the world is. A glTF material marked by glTF's `KHR_materials_unlit` loads
		unlit. Lit until set.

		Read at each draw by `LoadPbrShader`'s and `LoadLightingShader`'s draws. Its emission is still added.

		@param material  The material.
		@param unlit  Whether it is unlit. */
	static function SetMaterialUnlit(material:Material, unlit:Bool):Void {
		material.unlit = unlit;
	}

	/** Returns whether a material is unlit, as `SetMaterialUnlit` set it or its glTF file set it.

		@param material  The material.
		@return  Whether it is unlit. */
	static function IsMaterialUnlit(material:Material):Bool {
		return material.unlit;
	}

	/** Sets whether shadows fall on a material: when not, it is lit as if nothing stood between it and each light, as water, a
		hologram or a decal often is. Shadows fall on every material until set.

		A program's own shader reads it as the uniform `int shadowed`, 1 or 0, written at each draw.

		@param material  The material.
		@param shadowed  Whether shadows fall on it. */
	static function SetMaterialShadowed(material:Material, shadowed:Bool):Void {
		material.shadowed = shadowed;
	}

	/** Returns whether shadows fall on a material, as `SetMaterialShadowed` set it: true until set.

		@param material  The material.
		@return  Whether shadows fall on it. */
	static function IsMaterialShadowed(material:Material):Bool {
		return material.shadowed;
	}

	/** Sets light a whole model emits, added to each of its materials' own: a hit flash, or a model glowing whole. Its materials'
		emission, as `SetMaterialEmissive` set it or the glTF file set it, is kept, so an intensity of 0 leaves the model as authored.
		Read at each draw of the model (`DrawModel`, `DrawModelEx`), not by a draw of one of its meshes alone.

		```haxe
		SetModelEmissive(enemy, WHITE, hitTime > 0 ? 0.8 : 0);
		DrawModel(enemy, position, 1, WHITE);
		```

		@param model  The model.
		@param color  The color.
		@param intensity  How strong, 0 or more; 1 adds the color itself. */
	static function SetModelEmissive(model:Model, color:Color, intensity:Float):Void {
		var strength = intensity > 0 ? intensity / 255 : 0;
		if (strength == 0) {
			model.emissive = null;
			return;
		}
		if (model.emissive == null)
			model.emissive = [0, 0, 0];
		model.emissive[0] = color.r * strength;
		model.emissive[1] = color.g * strength;
		model.emissive[2] = color.b * strength;
	}
	#end
}
