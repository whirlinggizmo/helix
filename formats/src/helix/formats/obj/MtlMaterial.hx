package helix.formats.obj;

/** Represents one material of an .mtl file: its colors, factors and the textures it names, as paths resolved against the file's
	directory and normalized as `ObjFile`'s are (null for none). Its colors are arrays the material holds, `DEFAULT`'s too: read them,
	don't change them. A texture line's options (`-s`, `-o`, `-bm` and the rest) are read past; only the path is kept.

	Besides the classic statements, it reads the PBR extension Blender and others write (`Pr`, `Pm`, `map_Pr`, `map_Pm`, `norm`), whose
	values are absent from older files. Each color is three values, red, green and blue, each usually 0 to 1. */
class MtlMaterial {
	/** The material a face uses when it names none: named "", not `defined`, with every value its default (white, opaque, no
		textures). */
	public static final DEFAULT:MtlMaterial = standIn("");

	/** Gets the name `newmtl` gives it. */
	public final name:String;

	/** Gets whether a library gives it: false for `DEFAULT` and for the stand-in `ObjFile.computeMaterials` makes for a name no
		library gives. */
	public final defined:Bool;

	/** Gets the ambient color (`Ka`). Defaults to 0, 0, 0. */
	public final ambient:haxe.ds.ReadOnlyArray<Float>;

	/** Gets the diffuse color (`Kd`). Defaults to 1, 1, 1. */
	public final diffuse:haxe.ds.ReadOnlyArray<Float>;

	/** Gets the specular color (`Ks`). Defaults to 0, 0, 0. */
	public final specular:haxe.ds.ReadOnlyArray<Float>;

	/** Gets the emissive color (`Ke`). Defaults to 0, 0, 0. */
	public final emission:haxe.ds.ReadOnlyArray<Float>;

	/** Gets the transmission filter (`Tf`). Defaults to 1, 1, 1. */
	public final transmission:haxe.ds.ReadOnlyArray<Float>;

	/** Gets the specular exponent (`Ns`), usually 0 to 1000. Defaults to 0. */
	public final shininess:Float;

	/** Gets the optical density (`Ni`), the material's index of refraction. Defaults to 1. */
	public final opticalDensity:Float;

	/** Gets the opacity, 0 to 1: `d`, or 1 minus `Tr` when only that is given (`d` wins when both are). Defaults to 1. */
	public final opacity:Float;

	/** Gets the illumination model (`illum`), 0 to 10. Defaults to 0. */
	public final illumination:Int;

	/** Gets the roughness (`Pr`), 0 to 1, or null when the file gives none: `computeRoughness` gives one either way. */
	public final roughness:Null<Float>;

	/** Gets the metalness (`Pm`), 0 to 1, or null when the file gives none: `computeMetalness` gives one either way. */
	public final metalness:Null<Float>;

	/** Gets the ambient texture's path (`map_Ka`). */
	public final ambientTexturePath:Null<String>;

	/** Gets the diffuse texture's path (`map_Kd`). */
	public final diffuseTexturePath:Null<String>;

	/** Gets the specular texture's path (`map_Ks`). */
	public final specularTexturePath:Null<String>;

	/** Gets the specular exponent texture's path (`map_Ns`). */
	public final shininessTexturePath:Null<String>;

	/** Gets the emissive texture's path (`map_Ke`). */
	public final emissionTexturePath:Null<String>;

	/** Gets the opacity texture's path (`map_d`): the opacity on its own, apart from any alpha the diffuse texture has. */
	public final opacityTexturePath:Null<String>;

	/** Gets the bump texture's path (`map_bump`, `map_Bump` or `bump`): a height map, or a normal map in many files (Blender writes
		its normal maps here); `computeNormalTexturePath` picks the normal map either way. */
	public final bumpTexturePath:Null<String>;

	/** Gets the displacement texture's path (`disp`). */
	public final displacementTexturePath:Null<String>;

	/** Gets the normal map's path (`norm`, the PBR extension). */
	public final normalTexturePath:Null<String>;

	/** Gets the roughness texture's path (`map_Pr`). */
	public final roughnessTexturePath:Null<String>;

	/** Gets the metalness texture's path (`map_Pm`). */
	public final metalnessTexturePath:Null<String>;

	/** Returns the roughness to draw with, 0 to 1: the file's (`roughness`), or one made from the specular exponent when it gives
		none, `1 - sqrt(shininess / 1000)` held to 0 to 1, as Blender reads older files: the shinier, the smoother.

		@return  The roughness. */
	public function computeRoughness():Float {
		if (roughness != null)
			return clamp(roughness);
		return clamp(1 - Math.sqrt(Math.max(0, shininess) / 1000));
	}

	/** Returns the metalness to draw with, 0 to 1: the file's (`metalness`), or 0 when it gives none, as older files describe no
		metals.

		@return  The metalness. */
	public function computeMetalness():Float {
		return metalness != null ? clamp(metalness) : 0;
	}

	/** Returns the normal map to draw with: the file's normal map (`norm`), or its bump texture when it gives none, as most exporters
		write normal maps there; null when it gives neither.

		@return  The path, or null. */
	public function computeNormalTexturePath():Null<String> {
		return normalTexturePath != null ? normalTexturePath : bumpTexturePath;
	}

	// A value held to 0 to 1.
	static function clamp(value:Float):Float
		return value < 0 ? 0 : value > 1 ? 1 : value;

	// A material of a name no library gives: not defined, every value its default.

	@:allow(helix.formats.obj)
	static function standIn(name:String):MtlMaterial
		return new MtlMaterial(name, false, [0, 0, 0], [1, 1, 1], [0, 0, 0], [0, 0, 0], [1, 1, 1], 0, 1, 1, 0, null, null, null, null, null, null, null, null,
			null, null, null, null, null);

	@:allow(helix.formats.obj)
	function new(name:String, defined:Bool, ambient:haxe.ds.ReadOnlyArray<Float>, diffuse:haxe.ds.ReadOnlyArray<Float>, specular:haxe.ds.ReadOnlyArray<Float>,
			emission:haxe.ds.ReadOnlyArray<Float>, transmission:haxe.ds.ReadOnlyArray<Float>, shininess:Float, opticalDensity:Float, opacity:Float,
			illumination:Int, roughness:Null<Float>, metalness:Null<Float>, ambientTexturePath:Null<String>, diffuseTexturePath:Null<String>,
			specularTexturePath:Null<String>, shininessTexturePath:Null<String>, emissionTexturePath:Null<String>, opacityTexturePath:Null<String>,
			bumpTexturePath:Null<String>, displacementTexturePath:Null<String>, normalTexturePath:Null<String>, roughnessTexturePath:Null<String>,
			metalnessTexturePath:Null<String>) {
		this.name = name;
		this.defined = defined;
		this.ambient = ambient;
		this.diffuse = diffuse;
		this.specular = specular;
		this.emission = emission;
		this.transmission = transmission;
		this.shininess = shininess;
		this.opticalDensity = opticalDensity;
		this.opacity = opacity;
		this.illumination = illumination;
		this.roughness = roughness;
		this.metalness = metalness;
		this.ambientTexturePath = ambientTexturePath;
		this.diffuseTexturePath = diffuseTexturePath;
		this.specularTexturePath = specularTexturePath;
		this.shininessTexturePath = shininessTexturePath;
		this.emissionTexturePath = emissionTexturePath;
		this.opacityTexturePath = opacityTexturePath;
		this.bumpTexturePath = bumpTexturePath;
		this.displacementTexturePath = displacementTexturePath;
		this.normalTexturePath = normalTexturePath;
		this.roughnessTexturePath = roughnessTexturePath;
		this.metalnessTexturePath = metalnessTexturePath;
	}
}
