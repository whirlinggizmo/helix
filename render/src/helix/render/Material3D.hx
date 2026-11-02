package helix.render;

#if !macro
import helix.math.Matrix2D;
import helix.platform.Blend;
import helix.platform.ColorChannels;
import helix.platform.CullFace;
import helix.platform.DepthTest;
import helix.services.shaders.ShaderValues;
#end

/** Represents how a mesh's surface is drawn: its shading and the colors, textures and values it takes, how it is blended, culled and
	depth-tested, and the program's own shader when it has one.

	A program makes one, or `Renderer.createModel` makes them from a model's materials. A material names its textures and environment map
	without owning them. A draw reads the material as it is when it is called, so one material may be changed between draws.

	**Shading** (`shading`): `MetallicRoughness` (the default) shades it as glTF's model has it under the batch's lights, ambient light
	and environment map (a GGX highlight, a Lambert diffuse, image-based light from the map's irradiance and prefiltered cube), with
	`clearcoat`, `sheenColor` and `ior` and `specularColor` as glTF's extensions add them; `Phong` and `Lambert` are the older, cheaper
	models; `Unlit` shows its colors as they are. Every model adds the emissive light, discards a texel whose alpha is below
	`alphaCutoff`, and is fogged by the batch's `fog` unless `fog` is off.

	**Colors** are 0xAARRGGBB, sRGB; a texture is decoded or not as its `colorSpace` says (`Auto`: color slots decoded, data slots read
	as they are). How the base color, its texture and the vertex color are multiplied is `colorSpace`'s: Linear (the default) decodes the
	first two, reads the vertex color as linear, and multiplies in linear light, as glTF and three.js do; Srgb multiplies the three as
	stored and decodes the product once, as raylib does. Light, ambient light and the environment are linear. The result is encoded as
	the target needs (`Batch3D`), so an `Unlit` material with `colorSpace` Srgb, `toneMapped` off and no fog shows its product in an sRGB
	target as stored: a 0x80 base color over a 0x80 texel gives 0x40, as raylib's does.

	**A program's shader** (`shaderValues`) is compiled by `compileShader` (a fragment stage over helix-render's mesh vertex stage) or
	`compileShaderStages`. One shader draws every kind of mesh: `instanceModel` and `instanceColor` read identity and white where no
	instances feed them, and skinning and morphing are read from `skinned` and `morphTargetCount`. A fragment stage is cut by
	`clipPlanes` before it runs, whichever compiled it. The batch fills, by name, what the shader declares; a name the program writes on
	its values is overwritten.

	**The material include.** `#include <helix/render/material.glsl>` (fragment stage) declares every name of the material below (its
	colors, values and textures, as loose uniforms in the shader's own loose block) and the mesh vertex stage's outputs as inputs, and
	includes `lighting.glsl` (with `view.glsl` and `color.glsl`), so the shader declares none of them and shades as the built-in materials
	do. A shader without it declares the names it reads itself, each with the type listed; one declared with another type stops the
	build.

	```glsl
	// The material's surface at this fragment, its maps read at uv (occlusionTexture and lightTexture at texCoord2 when the mesh has a
	// second set): the base color, alpha and vertex color multiplied as colorSpace says, metallic and roughness by their map, the normal
	// map through the tangent frame (or the face's normal under flatShading), occlusion, the light map as bakedLight, emissive by its
	// color, strength and map, and every factor; its normal turned toward the viewer. Discards the fragment when its alpha is below
	// alphaCutoff, as the built-in materials do.
	Surface readMaterialSurface(vec2 uv);
	// The surface shaded as the material's shading says: shadeMetallicRoughness, shadePhong or shadeLambert, or for Unlit its baseColor.
	vec3 shadeMaterial(Surface surface);
	// The color the built-in materials write: the light plus surface.emissive, faded by the batch's fog where the material's fog is on,
	// then writeColor with surface.alpha.
	vec4 writeMaterialColor(Surface surface, vec3 light);
	```

	A shader that only moves its texture coordinates is lit, cut, fogged and written as the built-in materials are:

	```glsl
	#version 300 es
	precision highp float;
	#include <helix/render/material.glsl>
	uniform vec2 scrollOffset;
	out vec4 fragColor;
	void main() {
		Surface surface = readMaterialSurface(texCoord + scrollOffset);
		fragColor = writeMaterialColor(surface, shadeMaterial(surface));
	}
	```

	A texture scrolled, turned or tiled alike over every map needs no shader: `textureTransform`, written each frame, moves it.

	**The mesh vertex stage** passes, read by name in a fragment stage: `worldPosition` (vec3), `normal` (vec3, world space, not yet
	turned toward the viewer), `tangent` (vec4, world space, w the bitangent's sign), `texCoord` and `texCoord2` (vec2, moved by
	`textureTransform`) and `color` (vec4, the vertex color as the mesh holds it: as stored when `colorSpace` is Srgb, linear otherwise).
	A program's own vertex stage (`compileShaderStages`) gets the same by `#include <helix/render/mesh.glsl>`, which includes `view.glsl`
	and declares the attributes and the per-draw uniforms below and those six outputs, so the stage declares none of them, and gives
	`vec4 placeVertex()`: the vertex skinned, morphed and instanced as `skinned`, `morphTargetCount` and the instance attributes say,
	its clip position returned and the six outputs written. The stage may write any of them again after the call.

	Attributes, 0 where the mesh lacks one, but `vertexColor` white:

	| Name | Type | What |
	|---|---|---|
	| `vertexPosition`, `vertexNormal` | vec3 | The mesh's position and normal. |
	| `vertexTangent` | vec4 | The tangent, w the bitangent's sign. |
	| `vertexTexCoord`, `vertexTexCoord2` | vec2 | The texture coordinates, v down the image; the second set. |
	| `vertexColor` | vec4 | The vertex color, 0 to 1, as the mesh holds it. |
	| `vertexJoints`, `vertexWeights` | vec4 | Four bones by their index in the skin, as floats, and their weights. |
	| `instanceModel`, `instanceColor` | mat4, vec4 | An instance's transform and color (`Batch3D.drawMeshInstanced`). |

	The material's, as stored: `baseColor` (times the draw's tint), `emissiveColor` (its alpha `emissiveStrength`), `specularColor`,
	`sheenColor` (vec4); `metallic`, `roughness`, `normalScale`, `alphaCutoff`, `occlusionIntensity`, `lightIntensity`,
	`environmentIntensity`, `specularIntensity`, `shininess`, `ior`, `clearcoat`, `clearcoatRoughness`, `sheenRoughness` (float);
	`textureTransform` (mat3); `shading`, `toneMapped`, `fog`, `flatShading`, `vertexColors` (int, 1 for true), `colorSpaceSrgb` (int, 1
	when `colorSpace` is Srgb); and its textures by their property's name, white where it has none (a normal map flat).

	Per draw:

	| Name | Type | What |
	|---|---|---|
	| `model`, `normalMatrix`, `modelViewProjection` | mat4 | The draw's transform; its inverse, transposed; it, then the view's `viewProjection`. |
	| `lightCount` | int | The lights lighting this draw, 0 to 8. |
	| `receiveShadows` | int | 1 when the draw is darkened by shadows: the batch's and the material's `receiveShadows` both on. |
	| `lightPositions`, `lightDirections`, `lightColors`, `lightCones` | vec4[8] | Each light's position (w its range, 0 for none); direction (w its kind: 0 directional, 1 point, 2 spot, 3 hemisphere); linear radiance; cone cosines (x inner, y outer) and shadow (z its index in `Lighting`'s, -1 for none). A hemisphere light's ground radiance is its position. |
	| `clipPlanes`, `clipPlaneCount` | vec4[4], int | `Batch3D.clipPlanes`. |
	| `morphWeights`, `morphTargetCount` | vec4[16], int | A morphed mesh's weights, four a vec4, and how many. |
	| `skinned` | int | 1 when the draw is skinned by `boneTexture` (four texels a bone, its skinning matrix's columns, read with `texelFetch`). |
	| `boneMatrices` | mat4 array | The skin's matrices, as many as declared, for a shader written with an array (raylib's); zero past the skin's bones. |
	| `boneTexture`, `morphTexture` | sampler2D | The skin's matrices; the targets' deltas. |

	The lights and `receiveShadows` are declared by `lighting.glsl`, not by the shader. With them the view's names (`View3D`) and the
	lighting block's (`Batch3D`). A shader is given colors as stored but light, which is linear; nothing it writes is encoded after it:
	`writeMaterialColor`, or `color.glsl`'s `writeColor`, exposes and tone maps where `toneMapped` says and encodes for the target
	(`View3D` lists its functions).

	**Texture coordinates:** `occlusionTexture` and `lightTexture` read the mesh's second set when it has one, the others its first; all
	are moved by `textureTransform`.

	```haxe
	var crate = new Material3D();
	crate.baseColorTexture = crateTexture;
	crate.roughness = .8;
	batch.drawMesh(cube, crate, Matrix3D.fromTranslation(0, .5, 0, placement));
	``` */
class Material3D {
	#if !macro
	/** Gets or sets how the batch's lights shade it: MetallicRoughness until set. */
	public var shading:Shading3D = MetallicRoughness;

	/** Gets or sets the base color, multiplied with the base color texture and the vertex color: white until set.

		Its alpha, times the texture's, the vertex color's and `alphaTexture`'s, is the drawn alpha: what `blend` mixes by (Alpha's
		source alpha), what `alphaCutoff` tests, and what an RGBA target keeps. */
	public var baseColor:Int = 0xffffffff;

	/** Gets or sets the base color texture, or null for none (white). */
	public var baseColorTexture:Null<Texture2D> = null;

	/** Gets or sets the texture whose green multiplies the alpha, three.js's alphaMap, or null for none. */
	public var alphaTexture:Null<Texture2D> = null;

	/** Gets or sets a value indicating whether the mesh's vertex colors multiply the base color: true until set. */
	public var vertexColors:Bool = true;

	/** Gets or sets how the base color, the base color texture and the vertex color are multiplied: Linear until set.

		Linear decodes the base color and the texture (as its `colorSpace` says), reads the vertex colors as linear, as glTF and three.js
		hold them, and multiplies in linear light. Srgb multiplies the three as stored, whatever the texture's `colorSpace`, and decodes
		the product once, as raylib does: an `Unlit` material with `toneMapped` off and no fog then shows the product in an sRGB target as
		stored (`Renderer.createModel`'s `colorSpace` sets it). Auto is read as Linear. */
	public var colorSpace:ColorSpace = Linear;

	/** Gets or sets how metallic the surface is, in MetallicRoughness: 0 until set. Clamped to 0 to 1. */
	public var metallic(default, set):Float = 0;

	/** Gets or sets how rough the surface is, in MetallicRoughness: 0.5 until set. Clamped to 0 to 1. */
	public var roughness(default, set):Float = .5;

	/** Gets or sets the texture whose blue is the metalness and green the roughness, multiplying `metallic` and `roughness`; null for
		none. */
	public var metallicRoughnessTexture:Null<Texture2D> = null;

	/** Gets or sets the highlight's color: in Phong its specular color, in MetallicRoughness glTF's specular color factor
		(KHR_materials_specular). White until set. */
	public var specularColor:Int = 0xffffffff;

	/** Gets or sets how strong the highlight is, multiplying `specularColor` in MetallicRoughness (glTF's specular factor): 1 until set.
		Clamped to 0 to 1. */
	public var specularIntensity(default, set):Float = 1;

	/** Gets or sets how tight Phong's highlight is, its exponent: 30 until set, as three.js has it. Below 0 is clamped to 0. */
	public var shininess(default, set):Float = 30;

	/** Gets or sets the index of refraction a dielectric's reflectance follows, in MetallicRoughness (KHR_materials_ior): 1.5 until set.
		Clamped to 1 to 2.333. */
	public var ior(default, set):Float = 1.5;

	/** Gets or sets how strong a clear lacquer layer over the surface is, in MetallicRoughness (KHR_materials_clearcoat): 0 until set,
		none. Clamped to 0 to 1. */
	public var clearcoat(default, set):Float = 0;

	/** Gets or sets how rough the clear layer is: 0 until set. Clamped to 0 to 1. */
	public var clearcoatRoughness(default, set):Float = 0;

	/** Gets or sets the color of a cloth's sheen at grazing angles, in MetallicRoughness (KHR_materials_sheen): black until set, none. */
	public var sheenColor:Int = 0xff000000;

	/** Gets or sets how rough the sheen is: 0 until set. Clamped to 0 to 1. */
	public var sheenRoughness(default, set):Float = 0;

	/** Gets or sets the normal map, in tangent space with green up; null for none. A mesh without tangents ignores it. */
	public var normalTexture:Null<Texture2D> = null;

	/** Gets or sets how strongly the normal map bends the surface: 1 until set, 0 flat. Below 0 is clamped to 0. */
	public var normalScale(default, set):Float = 1;

	/** Gets or sets a value indicating whether each triangle is shaded flat, by its own face's normal: false until set. */
	public var flatShading:Bool = false;

	/** Gets or sets the occlusion map, its red how much of the ambient and environment light reaches the surface; null for none. */
	public var occlusionTexture:Null<Texture2D> = null;

	/** Gets or sets how strongly the occlusion map darkens: 1 until set. Clamped to 0 to 1. */
	public var occlusionIntensity(default, set):Float = 1;

	/** Gets or sets a baked light map, linear light added as the ambient light is, three.js's lightMap; null for none. */
	public var lightTexture:Null<Texture2D> = null;

	/** Gets or sets how strongly the light map lights: 1 until set. Below 0 is clamped to 0. */
	public var lightIntensity(default, set):Float = 1;

	/** Gets or sets the light it gives off, lit or not: black until set. */
	public var emissiveColor:Int = 0xff000000;

	/** Gets or sets how bright its emissive light is, multiplying `emissiveColor`: 1 until set. Below 0 is clamped to 0. */
	public var emissiveStrength(default, set):Float = 1;

	/** Gets or sets the emissive texture, multiplying `emissiveColor`; null for none. */
	public var emissiveTexture:Null<Texture2D> = null;

	/** Gets or sets an environment map of its own, in place of the batch's environment's; null until set, for the batch's. */
	public var environmentMap:Null<EnvironmentMap3D> = null;

	/** Gets or sets how strongly the environment map lights it, three.js's envMapIntensity: 1 until set. Below 0 is clamped to 0. */
	public var environmentIntensity(default, set):Float = 1;

	/** Gets the matrix its texture coordinates are moved by, before every texture is read: identity until changed, as glTF's
		KHR_texture_transform and a three.js texture's offset, repeat and rotation give it.

		It is read at each draw, so changing it each frame scrolls, turns or tiles the material's textures with no shader of the
		program's (`material.textureTransform.makeIdentity().appendTranslation(time * .1, 0, material.textureTransform)`). */
	public final textureTransform = new Matrix2D();

	/** Gets or sets the alpha below which a texel isn't drawn, for cut-out leaves and fences, in the color and the shadow pass alike: 0
		until set, so nothing is cut. Clamped to 0 to 1. */
	public var alphaCutoff(default, set):Float = 0;

	/** Gets or sets how it is combined with what is behind it: `Blend.OPAQUE` until set; any factors and operations the platform's
		`Blend` takes, three.js's custom blending among them. A blended surface is drawn where it is in the order, so the program draws it
		after what is behind it, farthest first. */
	public var blend:Blend = Blend.OPAQUE;

	/** Gets or sets the color channels it writes: all four until set; none for a depth-only draw, as three.js's `colorWrite` false. */
	public var colorWrite:ColorChannels = All;

	/** Gets or sets which faces aren't drawn: Back until set; None for a surface seen from both sides; Front for its inside alone (a
		room's walls seen from out of it, a sky dome). A back face drawn is lit as the side the viewer sees: its normal turned toward the
		viewer. */
	public var cull:CullFace = Back;

	/** Gets or sets the depth test: LessEqual until set. */
	public var depthTest:DepthTest = LessEqual;

	/** Gets or sets a value indicating whether it writes depth: true until set; false suits a blended surface. */
	public var depthWrite:Bool = true;

	/** Gets or sets a value indicating whether the batch's fog fades it: true until set. */
	public var fog:Bool = true;

	/** Gets or sets a value indicating whether its color is exposed and tone mapped into an sRGB target, as lit color is: true until
		set; false keeps a light's bulb or a sign as bright as its color says. Into an RGBA16F target nothing is tone mapped as it is
		drawn, and the resolve (`PostProcess`) maps the whole frame, this material's light too. */
	public var toneMapped:Bool = true;

	/** Gets or sets a value indicating whether meshes drawn with it cast shadows, where the batch's `castShadows` is on too: true until
		set. Off for glass, a light's bulb, a decal. */
	public var castShadows:Bool = true;

	/** Gets or sets a value indicating whether meshes drawn with it are darkened by shadows, where the batch's `receiveShadows` is on
		too: true until set. */
	public var receiveShadows:Bool = true;

	/** Gets or sets the program's own shader that draws it, as values over it carrying the shader's own uniforms and textures, or null
		for the batch's default for its `shading`: null until set.

		Its shader is compiled by `compileShader` or `compileShaderStages`, and reads the names the class lists, this material's colors,
		values and textures among them. Names given by `Shader.withNames` are filled exactly as names declared in the GLSL, and the batch
		shares `View` and `Lighting` with each draw itself, so the program sets no `ShaderValues.scene` and shares no block. Several
		materials may share one values, or each have values of its own over a shared base (`ShaderValues.base`). */
	public var shaderValues:Null<ShaderValues> = null;

	/** Creates a material: white, metallic-roughness, not metallic, roughness 0.5, opaque, culling back faces. */
	public function new() {}

	function set_metallic(value:Float):Float {
		throw "helix-render: Material3D.set_metallic is not yet built (stage 1)";
	}

	function set_roughness(value:Float):Float {
		throw "helix-render: Material3D.set_roughness is not yet built (stage 1)";
	}

	function set_specularIntensity(value:Float):Float {
		throw "helix-render: Material3D.set_specularIntensity is not yet built (stage 1)";
	}

	function set_shininess(value:Float):Float {
		throw "helix-render: Material3D.set_shininess is not yet built (stage 1)";
	}

	function set_ior(value:Float):Float {
		throw "helix-render: Material3D.set_ior is not yet built (stage 1)";
	}

	function set_clearcoat(value:Float):Float {
		throw "helix-render: Material3D.set_clearcoat is not yet built (stage 1)";
	}

	function set_clearcoatRoughness(value:Float):Float {
		throw "helix-render: Material3D.set_clearcoatRoughness is not yet built (stage 1)";
	}

	function set_sheenRoughness(value:Float):Float {
		throw "helix-render: Material3D.set_sheenRoughness is not yet built (stage 1)";
	}

	function set_normalScale(value:Float):Float {
		throw "helix-render: Material3D.set_normalScale is not yet built (stage 1)";
	}

	function set_occlusionIntensity(value:Float):Float {
		throw "helix-render: Material3D.set_occlusionIntensity is not yet built (stage 1)";
	}

	function set_lightIntensity(value:Float):Float {
		throw "helix-render: Material3D.set_lightIntensity is not yet built (stage 1)";
	}

	function set_emissiveStrength(value:Float):Float {
		throw "helix-render: Material3D.set_emissiveStrength is not yet built (stage 1)";
	}

	function set_environmentIntensity(value:Float):Float {
		throw "helix-render: Material3D.set_environmentIntensity is not yet built (stage 1)";
	}

	function set_alphaCutoff(value:Float):Float {
		throw "helix-render: Material3D.set_alphaCutoff is not yet built (stage 1)";
	}
	#end

	/** Compiles a fragment stage over helix-render's mesh vertex stage, for a `Material3D` (`shaderValues`).

		It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its
		vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw
		one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/color.glsl>`). A name the class
		lists declared with another type stops the build at the call.
		The fragment stage is GLSL as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440 (GL's form), or
		`#version 450` (Vulkan's), the mesh vertex stage given in the same form; GLSL ES 100 (raylib's) is not taken, and a layer adapts
		it first. The vertex stage passes `worldPosition`, `normal`, `tangent`, `texCoord`, `texCoord2` and `color`, as the class says,
		read by name; `#include <helix/render/material.glsl>` declares them, with the material's names.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@param options  Optional. Defines, includes and a file to watch, as `Shader.compile` takes them.
		@return  The shader, for a `ShaderValues` over it. */
	public static macro function compileShader(fragment:String,
			?options:haxe.macro.Expr.ExprOf<helix.services.shaders.ShaderOptions>):haxe.macro.Expr.ExprOf<helix.services.shaders.Shader> {
		throw "helix-render: Material3D.compileShader is not yet built (stage 1)";
	}

	/** Compiles a vertex and a fragment stage, both the program's, for a `Material3D` (`shaderValues`).

		It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its
		vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw
		one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/color.glsl>`). A name the class
		lists declared with another type stops the build at the call.
		Both stages are GLSL in one form, as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440, or
		`#version 450`. The vertex stage may place its vertices itself, declaring what it reads, as raylib's GLSL 330 vertex stages do;
		it then skins, morphs and instances only as it does so itself, and is cut by the clip planes only where it writes
		`worldPosition`. Placed by `placeVertex()` (`#include <helix/render/mesh.glsl>`), skinning, morphing and instancing are done and
		the outputs a fragment stage reads written, `worldPosition` among them, as the class says.
		@param vertex  The vertex stage's file, relative to the file holding the call.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@param options  Optional. Defines, includes and a file to watch.
		@return  The shader, for a `ShaderValues` over it. */
	public static macro function compileShaderStages(vertex:String, fragment:String,
			?options:haxe.macro.Expr.ExprOf<helix.services.shaders.ShaderOptions>):haxe.macro.Expr.ExprOf<helix.services.shaders.Shader> {
		throw "helix-render: Material3D.compileShaderStages is not yet built (stage 1)";
	}
}
