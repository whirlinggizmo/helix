package helix.services.tools;

import haxe.macro.Expr;
#if macro
import haxe.macro.Context;
import haxe.macro.Type;
import helix.platform.ShaderSource;
import helix.services.shaders.ShaderMacros;
#end

/** Provides the build macros that make typed values classes, as sokol-shdc's generated structs are: a member for each uniform and
	texture, checked by the compiler, each holding its handle, so nothing is looked up by name.

	**Members.** For each uniform a class gains members named for its path, the parts joined in camel case (`material.roughness` as
	`MaterialRoughness`, `lights.color` as `LightsColor`). A member of a block with no instance name is named alone (`uniform Glow {
	vec4 tint; };` gives `Tint`); with one, the instance name leads (`... } glow;` gives `GlowTint`). Loose uniforms are named alone.

	- A scalar (`float`, `int`, `uint`, `bool`): `setX(value)`.
	- A vector: `setX(x, y, ...)` with its components. A `vec3` or `vec4` whose name holds `color`, `colour` or `tint` (any case) also
	  gets `setXArgb(color)` from 0xAARRGGBB as stored and `setXLinearArgb(color)` decoded to linear light (`writeLinearColor`), and no
	  other vector does: a position has no color form.
	- A matrix: `setX(matrix)` for a `mat4`, `setX(values)` with its floats by columns for a `mat2` or `mat3`.
	- An array, or a field of an array of structs: the same, the element's index first (`setLightsRange(i, 10)`).
	- A texture: `setX(texture, ?sampling)` and `shareX(shared)` for a `ShaderSharedTexture`.

	Every generated member starts with `set` or `share`, and nothing of the values classes does but `shareBlock`, `shareTexture` and their
	`unshare` forms (their handle methods are `write`), so any uniform's name works (`color`, `matrix`, `texture`); a texture named
	`block` or `texture` (`shareBlock`, `shareTexture`) fails the build, as do two uniforms whose members would share a name. A uniform
	of a shared block (`ShaderOptions.shared`) gets no member on a shader's or a material's class: it is written once on the block's own
	class (`buildBlock`).

	**Statics.** A class gains its compiled `SHADER` or `VARIANTS` and a `ShaderFeatures` constant for each feature, named for it
	(`SKINNED`); a feature named `SHADER` or `VARIANTS` fails the build. These are the compiled program, a constant as a literal is;
	nothing a program writes is static. Defaults are values the program makes and passes (`base`), so two renderers have their own.

	**Binding.** A class is bound to any shader of its program, the compiled-in one by default, or one replaced in place or loaded from
	the same files (checked at construction: the shader declares what the class was generated for, with the same types), and follows a
	replacement as `ShaderValues` does. The same files and options compile once a build, so every class over them shares one `SHADER`
	or `VARIANTS`.

	**The exact shape**, for a class `X` (members as above, each with a doc comment naming its GLSL declaration and, for variants, the
	variants that have it):

	| Macro, base class | Statics | Constructor | Overrides |
	|---|---|---|---|
	| `build`, `ShaderValues` | `SHADER:Shader` | `new(?base:ShaderValues, ?scene:ShaderScene, ?shader:Shader)` | none |
	| `buildVariants`, `ShaderValues` | `VARIANTS:ShaderVariants`, a `ShaderFeatures` per feature | `new(features:ShaderFeatures, ?base:ShaderValues, ?scene:ShaderScene)` | none |
	| `buildVariants`, `ShaderVariantValues` | as above | `new(?base:X, ?scene:ShaderScene)` | `getValues(features):V` and `makeValues(shader, base):ShaderValues`, `V` the `values` class |
	| `buildBlock`, `ShaderBlockValues` | none | `new()` | none |

	A material class (`ShaderVariantValues`) has the texture members (`setX`, `shareX`) as well as the uniforms', each writing every
	variant that samples it. */
class ShaderValueClasses {
	/** Makes the class it builds, extending `ShaderValues`, a class of typed values for one shader, compiled as `Shader.compile` compiles.

		The class gains `SHADER` and a constructor `new(?base, ?scene, ?shader)`: the values it reads what it doesn't write from, the scene,
		and the shader, `SHADER` when omitted.

		```haxe
		@:build(helix.services.tools.ShaderValueClasses.build("glow.vert", "glow.frag", {file: "shaders/glow.shader"}))
		class GlowValues extends ShaderValues {}

		shaders.watch(GlowValues.SHADER);
		var defaults = new GlowValues();
		defaults.setStrength(1);
		var glow = new GlowValues(defaults, scene);
		glow.setTintArgb(0xffffc040);
		glow.setImage(texture);
		```
		@param vertex  The vertex stage's file, relative to the file holding the class.
		@param fragment  The fragment stage's file, relative to the file holding the class.
		@param options  Optional. Defines, includes, shared blocks, a check, and a file, as `Shader.compile` takes them, at the call or a
			class's static constant.
		@return  The class's fields with the generated ones. */
	public static macro function build(vertex:String, fragment:String, ?options:ExprOf<helix.services.shaders.ShaderOptions>):Array<Field> {
		var pos = Context.currentPos();
		var compiled = ShaderMacros.compileFiles(vertex, fragment, options);
		var info = ShaderMacros.compiled.get(holderOf(compiled));
		var fields = Context.getBuildFields();
		var self = selfPath();
		fields.push(staticField("SHADER", macro :helix.services.shaders.Shader, compiled, "The shader, compiled into the program.", pos));
		var declared = declarations(info.sources, info.shared, info.featureNames, info.variantFeatures);
		fields.push({name: "new",
			access: [APublic],
			doc: "Creates values for the shader, `SHADER` or one of the same program.\n\n"
			+ "@param base  Optional. The values these read what they don't write or share from.\n"
			+ "@param scene  Optional. The scene to read shared blocks and textures from.\n"
			+ "@param shader  Optional. The shader; defaults to `SHADER`.\n"
			+ "@throws String  A shader that doesn't declare what the class was made for.",
			kind: FFun({
				args: [
					{name: "base", type: macro :helix.services.shaders.ShaderValues, opt: true},
					{name: "scene", type: macro :helix.services.shaders.ShaderScene, opt: true},
					{name: "shader", type: macro :helix.services.shaders.Shader, opt: true}
				],
				ret: null,
				expr: macro {
					super(shader == null ? SHADER : shader, base, scene);
					if (shader != null)
						$i{"checkShader"}(shader);
				}
			}),
			pos: pos
		});
		fields.push(checkField(declared, pos));
		members(fields, declared, macro SHADER, false, pos);
		return fields;
	}

	/** Makes the class it builds a class of typed values for a set of variants, compiled as `ShaderVariants.compile` compiles: a member for
		every uniform and texture any variant has, each member's doc naming the variants that have it.

		What it gains besides `VARIANTS` and the feature constants depends on what it extends:

		- `ShaderValues`: values for one variant, and a constructor `new(features, ?base, ?scene)`.
		- `ShaderVariantValues`: one material's values across every variant, and a constructor `new(?base, ?scene)`. Its `getValues(features)`
		  returns the class named by `values`, typed values for one variant, so a draw's own uniforms keep their types.

		On values for a variant without a member, the member keeps the value and writes nothing, as a handle does.

		```haxe
		@:build(helix.services.tools.ShaderValueClasses.buildVariants("lit.vert", "lit.frag", ["SKINNED", "INSTANCED"], Lit.OPTIONS))
		class LitValues extends ShaderValues {}

		@:build(helix.services.tools.ShaderValueClasses.buildVariants("lit.vert", "lit.frag", ["SKINNED", "INSTANCED"], Lit.OPTIONS,
			"LitValues"))
		class LitMaterial extends ShaderVariantValues {}

		var red = new LitMaterial(sceneDefaults);
		red.setBaseColorArgb(0xffd04040);
		var drawn = new LitValues(LitMaterial.SKINNED);   // the renderer's draw values for the variant
		drawn.base = red.getValues(LitMaterial.SKINNED);  // a LitValues, typed
		drawn.setModel(transform);
		```
		@param vertex  The vertex stage's file, relative to the file holding the class.
		@param fragment  The fragment stage's file, relative to the file holding the class.
		@param features  The features, each a name, at the call or a class's static constant.
		@param options  Optional. The combinations, defines, includes, shared blocks, a check, and a file, at the call or a class's
			static constant.
		@param values  Optional. For a `ShaderVariantValues` class, the typed class of one variant's values (built over the same files and
			features) that `getValues` returns; `ShaderValues` when omitted.
		@return  The class's fields with the generated ones. */
	public static macro function buildVariants(vertex:String, fragment:String, features:ExprOf<Array<String>>,
			?options:ExprOf<helix.services.shaders.ShaderVariantOptions>, ?values:String):Array<Field> {
		var pos = Context.currentPos();
		var compiled = ShaderMacros.variantsFrom(ShaderMacros.file(vertex, pos), ShaderMacros.file(fragment, pos), features, options, pos);
		var info = ShaderMacros.compiled.get(holderOf(compiled));
		var fields = Context.getBuildFields();
		fields.push(staticField("VARIANTS", macro :helix.services.shaders.ShaderVariants, compiled, "The variants, compiled into the program.", pos));
		for (i => f in info.featureNames)
			fields.push(staticField(f, macro :helix.services.shaders.ShaderFeatures, macro $v{1 << i},
				'The feature `$f`, as a set of one (`ShaderVariants.getFeature("$f")`).', pos));
		var declared = declarations(info.sources, info.shared, info.featureNames, info.variantFeatures);
		var material = extendsVariantValues();
		if (material) {
			var typed = values == null ? "helix.services.shaders.ShaderValues" : values;
			var typedPath = typePath(typed);
			var typedType = TPath(typedPath);
			var selfType = TPath(selfPath());
			fields.push({
				name: "new",
				access: [APublic],
				doc: "Creates one material's values across every variant.\n\n" +
				"@param base  Optional. Values of the same variants these read what they don't write or share from.\n" +
				"@param scene  Optional. The scene every variant's values read shared blocks and textures from.",
				kind: FFun({
					args: [
						{name: "base", type: selfType, opt: true},
						{name: "scene", type: macro :helix.services.shaders.ShaderScene, opt: true}
					],
					ret: null,
					expr: macro {
						super(VARIANTS, base);
						if (scene != null)
							this.scene = scene;
					}
				}),
				pos: pos
			});
			fields.push({
				name: "getValues",
				access: [APublic, AOverride],
				doc: "Returns the typed values for the variant with a combination of features, made the first time and kept in step after.\n\n" +
				"@param features  The combination.\n@return  Its values, the same each call.\n@throws String  A combination not compiled.",
				kind: FFun({
					args: [{name: "features", type: macro :helix.services.shaders.ShaderFeatures}],
					ret: typedType,
					expr: macro return cast super.getValues(features)
				}),
				pos: pos
			});
			var make = values == null ? macro new helix.services.shaders.ShaderValues(shader,
				base) : macro new $typedPath(VARIANTS.variantFeatures[VARIANTS.shaders.indexOf(shader)], base);
			fields.push({
				name: "makeValues",
				access: [AOverride],
				doc: "Makes one variant's typed values.",
				kind: FFun({
					args: [
						{name: "shader", type: macro :helix.services.shaders.Shader},
						{name: "base", type: macro :Null<helix.services.shaders.ShaderValues>}
					],
					ret: macro :helix.services.shaders.ShaderValues,
					expr: macro return $make
				}),
				pos: pos
			});
		} else
			fields.push({name: "new",
				access: [APublic],
				doc: "Creates values for one variant.\n\n"
				+ "@param features  The variant's features.\n"
				+ "@param base  Optional. Values of the same variant these read what they don't write or share from.\n"
				+ "@param scene  Optional. The scene to read shared blocks and textures from.\n"
				+ "@throws String  A combination not compiled.",
				kind: FFun({
					args: [
						{name: "features", type: macro :helix.services.shaders.ShaderFeatures},
						{name: "base", type: macro :helix.services.shaders.ShaderValues, opt: true},
						{name: "scene", type: macro :helix.services.shaders.ShaderScene, opt: true}
					],
					ret: null,
					expr: macro super(VARIANTS.getShader(features), base, scene)
				}),
				pos: pos
			});
		members(fields, declared, macro VARIANTS, material, pos);
		return fields;
	}

	/** Makes the class it builds, extending `ShaderBlockValues`, a class of typed values for one shared block, as a shader or a set of
		variants names it shared.

		The class gains a member for each of the block's uniforms, named as above, and a constructor taking nothing, over the block as the
		shader or set given lays it out. It follows the block's layout as `ShaderBlockValues` does.

		```haxe
		@:build(helix.services.tools.ShaderValueClasses.buildBlock("LitMaterial.VARIANTS", "Camera"))
		class CameraValues extends ShaderBlockValues {}

		var camera = new CameraValues();          // each renderer its own
		scene.shareBlock(camera);
		// each frame, once:
		camera.setViewProjection(viewProjection);
		```
		@param source  A static field holding a `Shader` or `ShaderVariants` compiled by one of the macros, by its dotted path from the
			file holding the class (`LitMaterial.VARIANTS`, `Lighting.SHADER`).
		@param blockName  The shared block's name.
		@return  The class's fields with the generated ones. */
	public static macro function buildBlock(source:String, blockName:String):Array<Field> {
		var pos = Context.currentPos();
		var dot = source.lastIndexOf(".");
		var className = source.substr(0, dot),
			fieldName = source.substr(dot + 1);
		var holder:Null<String> = null;
		switch Context.getType(className) {
			case TInst(c, _):
				for (f in c.get().statics.get())
					if (f.name == fieldName) {
						var e = f.expr();
						holder = e == null ? null : holderOfTyped(e);
					}
			case _:
		}
		var info = holder == null ? null : ShaderMacros.compiled.get(holder);
		if (info == null)
			Context.error('shader: $source isn\'t a static holding a shader or variants a macro compiled', pos);
		var declared = declarations(info.sources, info.shared, [], [0]).filter((d:Dynamic) -> d.blockName == blockName);
		if (!Lambda.exists(info.shared, s -> s.name == blockName))
			Context.error('shader: $source names no shared block $blockName (ShaderOptions.shared)', pos);
		var fields = Context.getBuildFields();
		var sourceExpr = macro $p{source.split(".")};
		fields.push({
			name: "new",
			access: [APublic],
			doc: 'Creates the values of the shared block `$blockName`, every member 0.',
			kind: FFun({args: [], ret: null, expr: macro super($sourceExpr, $v{blockName})}),
			pos: pos
		});
		members(fields, declared, sourceExpr, false, pos, true);
		return fields;
	}

	#if macro
	// A declared uniform or texture of the program: its path, type, elements, block, and the variants that have it.
	static function declarations(sources:Array<ShaderSource>, shared:Array<helix.services.shaders.ShaderSharedBlock>, featureNames:Array<String>,
			variantFeatures:Array<Int>):Array<Dynamic> {
		var out:Array<Dynamic> = [];
		var sharedNames = [for (s in shared) s.name];
		for (k => source in sources) {
			for (b in source.uniformBlocks)
				for (m in b.members) {
					var found:Dynamic = Lambda.find(out, (d:Dynamic) -> !d.texture && d.path == m.glslName);
					if (found != null) {
						found.variants.push(k);
						continue;
					}
					out.push({
						path: m.glslName,
						type: m.type,
						array: m.elementCount > 1,
						blockName: sharedNames.indexOf(b.glslName) >= 0 ? b.glslName : "",
						texture: false,
						variants: [k],
						text: '`${m.type} ${m.glslName}${m.elementCount > 1 ? '[${m.elementCount}]' : ""}` in block `${b.glslName}`'
					});
				}
			for (t in source.textures) {
				var found:Dynamic = Lambda.find(out, (d:Dynamic) -> d.texture && d.path == t.glslName);
				if (found != null) {
					found.variants.push(k);
					continue;
				}
				out.push({
					path: t.glslName,
					type: t.shadow ? "sampler2DArrayShadow" : t.cube ? "samplerCube" : "sampler2D",
					array: false,
					blockName: "",
					texture: true,
					variants: [k],
					text: '`${t.shadow ? "sampler2DArrayShadow" : t.cube ? "samplerCube" : "sampler2D"} ${t.glslName}`'
				});
			}
		}
		if (featureNames.length > 0)
			for (d in out)
				d.text += d.variants.length == sources.length ? " (every variant)" : " (" + [
					for (k in (d.variants : Array<Int>))
						'[${[for (i in 0...featureNames.length) if (variantFeatures[k] & 1 << i != 0) featureNames[i]].join(", ")}]'
				].join(", ") + ")";
		return out;
	}

	// The members for each declared uniform and texture outside a shared block (inBlock: the block's own, which are all shared).
	static function members(fields:Array<Field>, declared:Array<Dynamic>, source:Expr, material:Bool, pos:Position, inBlock = false):Void {
		var names = new Map<String, Bool>();
		for (f in fields)
			names.set(f.name, true);
		function add(name:String, doc:String, args:Array<FunctionArg>, body:Expr):Void {
			if (names.exists(name))
				Context.error('shader: two of the shader\'s names make the member $name', pos);
			names.set(name, true);
			fields.push({
				name: name,
				access: [APublic],
				doc: doc,
				kind: FFun({args: args, ret: macro :Void, expr: body}),
				pos: pos
			});
		}
		var handleCount = 0;
		for (d in declared) {
			if (!inBlock && d.blockName != "")
				continue;
			var path:String = d.path,
				type:String = d.type,
				array:Bool = d.array,
				text:String = d.text;
			var camel = [for (part in path.split(".")) part.charAt(0).toUpperCase() + part.substr(1)].join("");
			var handle = '__handle${handleCount++}';
			if (d.texture) {
				if (path == "block" || path == "texture")
					Context.error('shader: a texture named $path, whose share member would be the values\' own share$camel', pos);
				fields.push({
					name: handle,
					access: [APrivate, AStatic, AFinal],
					kind: FVar(macro :helix.services.shaders.ShaderSampler, macro $source.reserveSampler($v{path})),
					meta: [
						{
							name: ":noCompletion",
							pos: pos
						}
					],
					pos: pos
				});
				add('set$camel',
					'Writes the texture $text samples, and how.\n\n@param texture  The texture, as an `IGraphics` handle, or 0 for none.\n' +
					"@param sampling  Optional. How it is sampled; defaults to `Sampling.LINEAR`.",
					[
						{
							name: "texture",
							type: macro :Int
						},
						{name: "sampling", type: macro :helix.platform.Sampling, opt: true}
					], macro writeTexture($i{handle}, texture, sampling));
				add('share$camel', 'Makes $text read a shared texture.\n\n@param shared  The shared texture.',
					[{name: "shared", type: macro :helix.services.shaders.ShaderSharedTexture}], macro shareTexture($i{handle}, shared));
				continue;
			}
			fields.push({
				name: handle,
				access: [APrivate, AStatic, AFinal],
				kind: FVar(macro :helix.services.shaders.ShaderUniform, macro $source.reserveUniform($v{path})),
				meta: [
					{
						name: ":noCompletion",
						pos: pos
					}
				],
				pos: pos
			});
			var index:Array<FunctionArg> = array ? [{name: "index", type: macro :Int}] : [];
			var at = array ? macro index : macro 0;
			var indexDoc = array ? "@param index  The element's index.\n" : "";
			var h = macro $i{handle};
			switch type {
				case "float":
					add('set$camel', 'Writes $text.\n\n$indexDoc@param value  The value.', index.concat([{name: "value", type: macro :Float}]),
						macro writeFloat($h, value, $at));
				case "int" | "uint":
					add('set$camel', 'Writes $text.\n\n$indexDoc@param value  The value.', index.concat([{name: "value", type: macro :Int}]),
						macro writeInt($h, value, $at));
				case "bool":
					add('set$camel', 'Writes $text.\n\n$indexDoc@param value  The value.', index.concat([{name: "value", type: macro :Bool}]),
						macro writeBool($h, value, $at));
				case "vec2" | "vec3" | "vec4":
					var n = Std.parseInt(type.charAt(3));
					var comps = ["x", "y", "z", "w"].slice(0, n);
					var call = n == 2 ? macro writeVector2($h, x, y,
						$at) : n == 3 ? macro writeVector3($h, x, y, z, $at) : macro writeVector($h, x, y, z, w, $at);
					add('set$camel', 'Writes $text.\n\n$indexDoc' + [for (c in comps) '@param $c  The $c component.'].join("\n"), index.concat([
						for (c in comps)
							{
								name: c,
								type: macro :Float
							}
					]), call);
					if (n >= 3 && ~/colou?r|tint/i.match(path)) {
						add('set${camel}Argb', 'Writes $text from a color, 0xAARRGGBB, as stored.\n\n$indexDoc@param color  The color.',
							index.concat([{name: "color", type: macro :Int}]), macro writeColor($h, color, $at));
						add('set${camel}LinearArgb',
							'Writes $text from a color, 0xAARRGGBB, decoded from sRGB to linear light.\n\n$indexDoc' + "@param color  The color.",
							index.concat([
								{
									name: "color",
									type: macro :Int
								}
							]), macro writeLinearColor($h, color, $at));
					}
				case "ivec2" | "ivec3" | "ivec4" | "uvec2" | "uvec3" | "uvec4":
					var n = Std.parseInt(type.charAt(4));
					var comps = ["x", "y", "z", "w"].slice(0, n);
					var values = [for (c in comps) macro $i{c}];
					add('set$camel', 'Writes $text.\n\n$indexDoc' + [for (c in comps) '@param $c  The $c component.'].join("\n"), index.concat([
						for (c in comps)
							{
								name: c,
								type: macro :Int
							}
					]), macro writeInts($h, $a{values}, $at));
				case "bvec2" | "bvec3" | "bvec4":
					var n = Std.parseInt(type.charAt(4));
					var comps = ["x", "y", "z", "w"].slice(0, n);
					var values = [for (c in comps) macro $i{c} ?1:0];
					add('set$camel', 'Writes $text.\n\n$indexDoc' + [for (c in comps) '@param $c  The $c component.'].join("\n"), index.concat([
						for (c in comps)
							{
								name: c,
								type: macro :Bool
							}
					]), macro writeInts($h, $a{values}, $at));
				case "mat4":
					add('set$camel', 'Writes $text.\n\n$indexDoc@param matrix  The matrix.',
						index.concat([{name: "matrix", type: macro :helix.math.Matrix3D}]), macro writeMatrix($h, matrix, $at));
				case "mat2" | "mat3":
					add('set$camel', 'Writes $text from its floats by columns.\n\n$indexDoc@param values  The floats.',
						index.concat([{name: "values", type: macro :Array<Float>}]), macro writeFloats($h, values, $at));
				case _:
			}
		}
	}

	// The check a class bound to another shader makes: the shader declares what the class was made for, with the same types.
	static function checkField(declared:Array<Dynamic>, pos:Position):Field {
		var checks = [
			for (d in declared)
				if (!d.texture) macro {
					var u = shader.findUniform($v{d.path});
					if (u != null && (u.type : String) != $v{d.type})
						throw 'shader values: the shader declares ' + $v{d.path} + ' a ' + (u.type : String) + ', not a ' + $v{d.type};
					if (u == null)
						throw 'shader values: the shader declares no ' + $v{d.path} + ', which the class was made for';
				}
		];
		return {
			name: "checkShader",
			access: [APrivate, AStatic],
			meta: [{name: ":noCompletion", pos: pos}],
			kind: FFun({args: [{name: "shader", type: macro :helix.services.shaders.Shader}], ret: macro :Void, expr: macro $b{checks}}),
			pos: pos
		};
	}

	static function staticField(name:String, type:ComplexType, init:Expr, doc:String, pos:Position):Field
		return {
			name: name,
			access: [APublic, AStatic, AFinal],
			doc: doc,
			kind: FVar(type, init),
			pos: pos
		};

	// The holder class a compile's expression names.
	static function holderOf(e:Expr):String
		return switch e.expr {
			case EMeta(_, inner) | EParenthesis(inner): holderOf(inner);
			case EField(owner, _):
				switch owner.expr {
					case EField(_, name): name;
					case _: throw "not a compiled shader";
				}
			case _: throw "not a compiled shader";
		}

	static function holderOfTyped(e:TypedExpr):Null<String>
		return switch e.expr {
			case TField(_, FStatic(c, _)): c.get().name;
			case TParenthesis(inner) | TMeta(_, inner) | TCast(inner, _): holderOfTyped(inner);
			case _: null;
		}

	static function selfPath():TypePath {
		var c = Context.getLocalClass().get();
		return {
			pack: c.pack,
			name: c.module.split(".").pop() == c.name ? c.name : c.module.split(".").pop(),
			sub: c.module.split(".").pop() == c.name ? null : c.name
		};
	}

	static function typePath(dotted:String):TypePath {
		var parts = dotted.split(".");
		var name = parts.pop();
		return {pack: parts, name: name};
	}

	static function extendsVariantValues():Bool {
		var c = Context.getLocalClass().get().superClass;
		while (c != null) {
			var t = c.t.get();
			if (t.name == "ShaderVariantValues" && t.pack.join(".") == "helix.services.shaders")
				return true;
			c = t.superClass;
		}
		return false;
	}
	#end
}
