package helix.formats.obj;

/** Represents one material of an .mtl file: its colors, factors and the textures it names, as paths resolved against the file's
	directory and normalized as `ObjFile`'s are (null for none). A value the file doesn't give is null, and its `computeX` method gives
	the default to draw with. Its colors are arrays the material holds, and the defaults' are shared: read them, don't change them. A
	texture line's options (`-s`, `-o`, `-bm` and the rest) are read past; only the path is kept.

	Besides the classic statements, it reads the PBR extension Blender and others write (`Pr`, `Pm`, `map_Pr`, `map_Pm`, `norm`), whose
	values are absent from older files. Each color is three values, red, green and blue, each usually 0 to 1; a color written with one
	value is that value three times, as the format has it. */
class MtlMaterial {
	/** The material a face uses when it names none: named "", not `defined`, giving no value and no texture, so each `computeX` gives
		its default (white, opaque). */
	public static final DEFAULT:MtlMaterial = standIn("");

	/** Gets the name `newmtl` gives it. */
	public final name:String;

	/** Gets whether a library gives it: false for `DEFAULT` and for the stand-in `ObjFile.computeMaterials` makes for a name no
		library gives. */
	public final defined:Bool;

	/** Gets the ambient color (`Ka`), or null when the file gives none: `computeAmbient` gives one either way. */
	public final ambient:Null<haxe.ds.ReadOnlyArray<Float>>;

	/** Gets the diffuse color (`Kd`), or null when the file gives none: `computeDiffuse` gives one either way. */
	public final diffuse:Null<haxe.ds.ReadOnlyArray<Float>>;

	/** Gets the specular color (`Ks`), or null when the file gives none: `computeSpecular` gives one either way. */
	public final specular:Null<haxe.ds.ReadOnlyArray<Float>>;

	/** Gets the emissive color (`Ke`), or null when the file gives none: `computeEmission` gives one either way. */
	public final emission:Null<haxe.ds.ReadOnlyArray<Float>>;

	/** Gets the transmission filter (`Tf`), or null when the file gives none: `computeTransmission` gives one either way. */
	public final transmission:Null<haxe.ds.ReadOnlyArray<Float>>;

	/** Gets the specular exponent (`Ns`), usually 0 to 1000, or null when the file gives none: `computeShininess` gives one either
		way. */
	public final shininess:Null<Float>;

	/** Gets the optical density (`Ni`), the material's index of refraction, or null when the file gives none: `computeOpticalDensity`
		gives one either way. */
	public final opticalDensity:Null<Float>;

	/** Gets the opacity, 0 to 1: `d`, or 1 minus `Tr` when only that is given (`d` wins when both are); null when the file gives
		neither: `computeOpacity` gives one either way. */
	public final opacity:Null<Float>;

	/** Gets the illumination model (`illum`), 0 to 10, or null when the file gives none: `computeIllumination` gives one either way. */
	public final illumination:Null<Int>;

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

	/** Gets the bump texture's path (the last `map_bump`, `map_Bump` or `bump` line's): a height map, or a normal map in many files (Blender writes
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

	/** Returns the ambient color to draw with: the file's (`ambient`), or 0, 0, 0 when it gives none.

		@return  Its red, green and blue. */
	public function computeAmbient():haxe.ds.ReadOnlyArray<Float>
		return ambient != null ? ambient : BLACK;

	/** Returns the diffuse color to draw with: the file's (`diffuse`), or 1, 1, 1 when it gives none.

		@return  Its red, green and blue. */
	public function computeDiffuse():haxe.ds.ReadOnlyArray<Float>
		return diffuse != null ? diffuse : WHITE;

	/** Returns the specular color to draw with: the file's (`specular`), or 0, 0, 0 when it gives none.

		@return  Its red, green and blue. */
	public function computeSpecular():haxe.ds.ReadOnlyArray<Float>
		return specular != null ? specular : BLACK;

	/** Returns the emissive color to draw with: the file's (`emission`), or 0, 0, 0 when it gives none.

		@return  Its red, green and blue. */
	public function computeEmission():haxe.ds.ReadOnlyArray<Float>
		return emission != null ? emission : BLACK;

	/** Returns the transmission filter to draw with: the file's (`transmission`), or 1, 1, 1 when it gives none, letting all light
		through.

		@return  Its red, green and blue. */
	public function computeTransmission():haxe.ds.ReadOnlyArray<Float>
		return transmission != null ? transmission : WHITE;

	/** Returns the specular exponent to draw with: the file's (`shininess`), or 0 when it gives none.

		@return  The exponent. */
	public function computeShininess():Float
		return shininess != null ? shininess : 0;

	/** Returns the optical density to draw with: the file's (`opticalDensity`), or 1 when it gives none, as light passes through air.

		@return  The index of refraction. */
	public function computeOpticalDensity():Float
		return opticalDensity != null ? opticalDensity : 1;

	/** Returns the opacity to draw with, 0 to 1 as the file gives it: its own (`opacity`), or 1, opaque, when it gives none.

		@return  The opacity. */
	public function computeOpacity():Float
		return opacity != null ? opacity : 1;

	/** Returns the illumination model to draw with: the file's (`illumination`), or 0 when it gives none.

		@return  The model. */
	public function computeIllumination():Int
		return illumination != null ? illumination : 0;

	/** Returns the roughness to draw with, 0 to 1: the file's (`roughness`), or one made from the specular exponent when it gives
		none, `1 - sqrt(computeShininess() / 1000)` held to 0 to 1, as Blender reads older files: the shinier, the smoother.

		@return  The roughness. */
	public function computeRoughness():Float {
		if (roughness != null)
			return clamp(roughness);
		return clamp(1 - Math.sqrt(Math.max(0, computeShininess()) / 1000));
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

	/** Returns the path the last of some texture statements gives, in the file's order: for a reader that takes some of the statements
		a field joins and not others (`bumpTexturePath` is the last of `bump`, `map_bump` and `map_Bump`).

		@param statements  The statements, as the file writes them (case counts): any of `map_Ka`, `map_Kd`, `map_Ks`, `map_Ns`, `map_Ke`,
			`map_d`, `map_bump`, `map_Bump`, `bump`, `disp`, `norm`, `map_Pr` and `map_Pm`.
		@return  The path, resolved as the fields' are, or null when the material has none of them. */
	public function findTexturePath(statements:Array<String>):Null<String> {
		var i = textureStatements.length;
		while (--i >= 0)
			if (statements.indexOf(textureStatements[i]) >= 0)
				return texturePaths[i];
		return null;
	}

	// The material's texture lines, in its order: each one's statement and path.
	final textureStatements:Array<String>;
	final texturePaths:Array<String>;

	static final BLACK:haxe.ds.ReadOnlyArray<Float> = [0, 0, 0];
	static final WHITE:haxe.ds.ReadOnlyArray<Float> = [1, 1, 1];

	// A material of a name no library gives: not defined, giving nothing.

	@:allow(helix.formats.obj)
	static function standIn(name:String):MtlMaterial
		return new MtlMaterial(name, false, new Map(), new Map(), null, null, [], []);

	// A material of its colors and numbers by statement (Ka Kd Ks Ke Tf; Ns Ni Pr Pm), its opacity and illumination model, and its texture
	// lines in order.

	@:allow(helix.formats.obj)
	function new(name:String, defined:Bool, colors:Map<String, haxe.ds.ReadOnlyArray<Float>>, numbers:Map<String, Float>, opacity:Null<Float>,
			illumination:Null<Int>, textureStatements:Array<String>, texturePaths:Array<String>) {
		this.name = name;
		this.defined = defined;
		this.ambient = colors.get("Ka");
		this.diffuse = colors.get("Kd");
		this.specular = colors.get("Ks");
		this.emission = colors.get("Ke");
		this.transmission = colors.get("Tf");
		this.shininess = numbers.get("Ns");
		this.opticalDensity = numbers.get("Ni");
		this.opacity = opacity;
		this.illumination = illumination;
		this.roughness = numbers.get("Pr");
		this.metalness = numbers.get("Pm");
		this.textureStatements = textureStatements;
		this.texturePaths = texturePaths;
		this.ambientTexturePath = findTexturePath(["map_Ka"]);
		this.diffuseTexturePath = findTexturePath(["map_Kd"]);
		this.specularTexturePath = findTexturePath(["map_Ks"]);
		this.shininessTexturePath = findTexturePath(["map_Ns"]);
		this.emissionTexturePath = findTexturePath(["map_Ke"]);
		this.opacityTexturePath = findTexturePath(["map_d"]);
		this.bumpTexturePath = findTexturePath(["map_bump", "map_Bump", "bump"]);
		this.displacementTexturePath = findTexturePath(["disp"]);
		this.normalTexturePath = findTexturePath(["norm"]);
		this.roughnessTexturePath = findTexturePath(["map_Pr"]);
		this.metalnessTexturePath = findTexturePath(["map_Pm"]);
	}
}
