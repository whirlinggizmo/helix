package helix.services.shaders;

import haxe.macro.Expr;

/** Represents one shader compiled once for each combination of features while the program builds, and found by its features.

	A feature is a define a variant has on or off (`USE_MAP`, `SKINNED`): a name alone, defined as 1 when on. A value that differs
	between variants is a feature's business in the GLSL (`#ifdef MANY_LIGHTS`), so no two spellings of one feature exist. A feature's
	own uniforms are loose uniforms under its `#ifdef`, in either form of stage (`Shader`). The combinations are fixed by the build:
	`getShader` throws for one not compiled, naming it; `findShader` returns null.

	A shared block (`ShaderOptions.shared`) is laid out alike in every variant that declares it, which the build checks, refusing a
	feature that changes it: one `ShaderBlockValues` serves every variant.

	Each variant is a shader of its own, carried whole in the program, its size the size of its dialects: every combination of n
	features is 2^n of them, compiled when `ShaderVariantOptions.combinations` is omitted, at most 8 features. A library keeps them few
	by compiling only the combinations it draws with, and by making what doesn't change a stage's inputs a uniform.

	```haxe
	var lit = ShaderVariants.compile("lit.vert", "lit.frag", ["SKINNED", "INSTANCED"], {combinations: [[], ["SKINNED"], ["INSTANCED"]]});
	var skinned = lit.getShader(lit.getFeature("SKINNED"));
	```

	A class `ShaderValueClasses.buildVariants` makes holds the features as constants (`LitValues.SKINNED`), so the compiler checks
	them. With `ShaderOptions.file`, `Shaders.watchVariants` replaces each variant in place when the file changes. */
class ShaderVariants implements IShaderHandles {
	/** Gets the features, in order: feature i is bit i of a `ShaderFeatures`. */
	public final featureNames:Array<String>;

	/** Gets the variants compiled, in the order of `variantFeatures`. */
	public final shaders:Array<Shader>;

	/** Gets each variant's features, by its index in `shaders`. */
	public final variantFeatures:Array<ShaderFeatures>;

	/** Gets every uniform's handle any variant declares, each name once. */
	public var uniforms(get, never):Array<ShaderUniform>;

	/** Gets every sampled texture's handle any variant declares, each name once. */
	public var samplers(get, never):Array<ShaderSampler>;

	/** Gets the asset path of the variants' file (`ShaderOptions.file`), which `Shaders.watchVariants` watches, or null. It is set
		whatever the build. */
	public final filePath:Null<String>;

	/** Gets why the last change of the variants' file wasn't taken (another set of features, a file that doesn't read), or null. */
	public var reloadError(default, null):Null<String>;

	/** Gets the number of times a change of the variants' file has replaced them in place, each variant's `reloadCount` moving with it. */
	public var reloadCount(default, null):Int = 0;

	/** Gets the functions called after each replacement of the variants in place, once every variant, handle and values has followed,
		in the order added. Each variant's own `Shader.reloadListeners` are called too. */
	public final reloadListeners:Array<ShaderVariants->Void> = [];

	/** Creates variants from shaders compiled with the features given, as the macros do.

		@param featureNames  The features, in bit order.
		@param variantFeatures  Each shader's features.
		@param shaders  The shaders, by the same index.
		@param filePath  Optional. The asset path of their file.
		@throws String  Arrays of different lengths, or one combination given twice. */
	public function new(featureNames:Array<String>, variantFeatures:Array<ShaderFeatures>, shaders:Array<Shader>, ?filePath:String) {
		if (variantFeatures.length != shaders.length)
			throw 'shader variants: ${variantFeatures.length} combinations for ${shaders.length} shaders';
		for (k => f in variantFeatures)
			if (variantFeatures.indexOf(f) != k)
				throw 'shader variants: the combination [${computeFeatureNames(f).join(", ")}] given twice';
		this.featureNames = featureNames;
		this.variantFeatures = variantFeatures;
		this.shaders = shaders;
		this.filePath = filePath;
		gather();
	}

	function get_uniforms():Array<ShaderUniform> {
		return uniformList;
	}

	function get_samplers():Array<ShaderSampler> {
		return samplerList;
	}

	/** Compiles a vertex and a fragment stage once for each combination of features while the program builds, and returns the variants
		as a value in the program.

		Each variant compiles as `Shader.compile` does, with its features defined and the options' defines.
		@param vertex  The vertex stage's file, relative to the file holding the call.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@param features  The features, each a name, bit i of a `ShaderFeatures` the i-th: a constant array at the call or a class's static
			constant, as the options.
		@param options  Optional. The combinations, the defines every variant has, includes, shared blocks, a check, and a file: a constant
			object, at the call or a class's static constant (`Lit.OPTIONS`), so the combinations live in one place.
		@return  The variants. */
	public static macro function compile(vertex:String, fragment:String, features:ExprOf<Array<String>>,
			?options:ExprOf<ShaderVariantOptions>):ExprOf<ShaderVariants> {
		var pos = haxe.macro.Context.currentPos();
		return ShaderMacros.variantsFrom(ShaderMacros.file(vertex, pos), ShaderMacros.file(fragment, pos), features, options, pos);
	}

	/** Compiles stages from GLSL text known while the program builds once for each combination of features, and returns the variants.

		Each stage's text is as `Shader.compileText` takes it.
		@param vertex  The vertex stage's GLSL.
		@param fragment  The fragment stage's GLSL.
		@param features  The features, each a name.
		@param options  Optional. The combinations, defines, includes, shared blocks, a check, and a file.
		@return  The variants. */
	public static macro function compileText(vertex:ExprOf<String>, fragment:ExprOf<String>, features:ExprOf<Array<String>>,
			?options:ExprOf<ShaderVariantOptions>):ExprOf<ShaderVariants> {
		var pos = haxe.macro.Context.currentPos();
		var v = ShaderMacros.foldText(vertex),
			f = ShaderMacros.foldText(fragment);
		if (v == null || f == null)
			haxe.macro.Context.error("shader: compileText takes both stages' text", pos);
		return ShaderMacros.variantsFrom(v, f, features, options, pos);
	}

	#if macro
	/** Returns the expression of variants compiled from two stages' text, for a library's macro (a material system choosing its
		combinations from what the program's code sets and a list in its build).

		@param vertex  The vertex stage: a name for messages and its GLSL.
		@param fragment  The fragment stage: a name for messages and its GLSL.
		@param features  The features, each a name.
		@param combinations  The combinations to compile, each a list of features, or null for every combination (at most 8 features).
		@param options  The defines every variant has, includes, shared blocks, check and file.
		@param pos  Where an error is reported.
		@return  An expression of type `ShaderVariants`. */
	public static function makeExpr(vertex:{name:String, text:String}, fragment:{name:String, text:String}, features:Array<String>,
			combinations:Null<Array<Array<String>>>, options:ShaderBuildOptions, pos:Position):Expr {
		return ShaderMacros.variantsExpr(vertex, fragment, features, combinations, options, pos);
	}
	#end

	/** Returns a feature by name, as a set of one.

		@param name  The feature.
		@return  The set holding it.
		@throws String  A name that isn't one of the features. */
	public function getFeature(name:String):ShaderFeatures {
		var i = featureNames.indexOf(name);
		if (i < 0)
			throw 'shader variants: no feature $name; the features are ${featureNames.join(", ")}';
		return 1 << i;
	}

	/** Returns a combination from its features' names, as data or a by-name layer holds it.

		@param names  The features' names, in any order.
		@return  The combination.
		@throws String  A name that isn't one of the features. */
	public function getFeatures(names:Array<String>):ShaderFeatures {
		var set:ShaderFeatures = ShaderFeatures.NONE;
		for (name in names)
			set = set | getFeature(name);
		return set;
	}

	/** Returns the names of a combination's features, in bit order, as messages and logs show a combination
		(`computeFeatureNames(skinned | instanced)` is `["SKINNED", "INSTANCED"]`); `variantFeatures` lists the combinations compiled.

		@param features  The combination.
		@return  Its features' names. */
	public function computeFeatureNames(features:ShaderFeatures):Array<String> {
		return [
			for (i in 0...featureNames.length)
				if ((features : Int) & 1 << i != 0) featureNames[i]
		];
	}

	/** Returns whether any variant declares a uniform.

		@param name  Its path.
		@return  True when one does. */
	public function hasUniform(name:String):Bool {
		var u = handles.get(name);
		return u != null && u.declared;
	}

	/** Returns whether any variant names a shared block.

		@param blockName  The block's name.
		@return  True when one does. */
	public function hasSharedBlock(blockName:String):Bool {
		for (s in shaders)
			if (s.hasSharedBlock(blockName))
				return true;
		return false;
	}

	/** Returns a handle for a uniform no variant may declare until a replacement, binding when one does (`Shader.reserveUniform`).

		@param name  Its path.
		@return  The handle, the same each call. */
	public function reserveUniform(name:String):ShaderUniform {
		var u = handles.get(name);
		if (u == null) {
			u = new ShaderUniform(name, Float, 1, "", false);
			u.update(Float, 1, "", false, false, false);
			handles.set(name, u);
		}
		return u;
	}

	/** Returns a uniform and element for a bracketed path no variant may declare until a replacement (`Shader.reserveUniformPath`).

		@param path  The path.
		@return  The uniform and the element. */
	public function reserveUniformPath(path:String):ShaderUniformPath {
		var known = paths.get(path);
		if (known != null)
			return known;
		var open = path.indexOf("["), name = path, index = 0;
		if (open >= 0) {
			var close = path.indexOf("]", open);
			index = Std.parseInt(path.substring(open + 1, close));
			name = path.substr(0, open) + path.substr(close + 1);
		}
		var made = new ShaderUniformPath(path, reserveUniform(name), index);
		paths.set(path, made);
		return made;
	}

	/** Returns a handle for a texture no variant may sample until a replacement, binding when one does.

		@param name  Its GLSL name.
		@return  The handle, the same each call. */
	public function reserveSampler(name:String):ShaderSampler {
		var s = samplerHandles.get(name);
		if (s == null) {
			s = new ShaderSampler(name, Texture2D, -1);
			s.update(Texture2D, -1, false, false);
			samplerHandles.set(name, s);
		}
		return s;
	}

	/** Returns a vertex attribute, the first variant's that reads it.

		@param name  Its GLSL name.
		@return  The attribute.
		@throws String  A name no variant reads. */
	public function getAttribute(name:String):ShaderAttribute {
		var a = findAttribute(name);
		if (a == null)
			throw 'shader variants: no variant reads attribute $name';
		return a;
	}

	/** Finds a vertex attribute no variant may read.

		@param name  Its GLSL name.
		@return  The attribute, or null. */
	public function findAttribute(name:String):Null<ShaderAttribute> {
		for (s in shaders) {
			var a = s.findAttribute(name);
			if (a != null)
				return a;
		}
		return null;
	}

	/** Returns whether any variant samples a texture.

		@param name  Its GLSL name.
		@return  True when one does. */
	public function hasSampler(name:String):Bool {
		var s = samplerHandles.get(name);
		return s != null && s.declared;
	}

	/** Returns the variant with exactly a combination of features.

		@param features  The combination.
		@return  The variant.
		@throws String  A combination not compiled, naming its features. */
	public function getShader(features:ShaderFeatures):Shader {
		var s = findShader(features);
		if (s == null)
			throw 'shader variants: no variant [${computeFeatureNames(features).join(", ")}] was compiled; the combinations are '
				+ [for (f in variantFeatures) '[${computeFeatureNames(f).join(", ")}]'].join(", ");
		return s;
	}

	/** Finds the variant with exactly a combination of features, which may not have been compiled.

		@param features  The combination.
		@return  The variant, or null. */
	public function findShader(features:ShaderFeatures):Null<Shader> {
		var i = variantFeatures.indexOf(features);
		return i < 0 ? null : shaders[i];
	}

	/** Returns the handle of a uniform any variant declares, which works on every variant's values.

		@param name  Its path, or the name `Shader.withNames` gave it.
		@return  The handle, the same each call.
		@throws String  A name no variant declares; given `lights[0].position`, it names `lights.position` and `getUniformPath`. */
	public function getUniform(name:String):ShaderUniform {
		var u = findUniform(name);
		if (u == null) {
			if (name.indexOf("[") >= 0)
				throw 'shader variants: no uniform $name: an array of structs\' field is one uniform, its elements by index; getUniformPath turns $name into it and an element';
			throw 'shader variants: no variant declares uniform $name; they declare ${[for (u in uniformList) u.name].join(", ")}';
		}
		return u;
	}

	/** Finds the handle of a uniform that no variant may declare.

		@param name  Its path.
		@return  The handle, or null. */
	public function findUniform(name:String):Null<ShaderUniform> {
		var u = handles.get(name);
		return u != null && u.declared ? u : null;
	}

	/** Returns a uniform and element from a path as GLSL writes it, with brackets or without, from any variant.

		@param path  The path.
		@return  The uniform and the element, the same object for the same path.
		@throws String  A path whose uniform no variant declares, or an index past its elements. */
	public function getUniformPath(path:String):ShaderUniformPath {
		var found = findUniformPath(path);
		if (found == null)
			throw 'shader variants: no variant declares the path $path, or it is past the uniform\'s elements';
		return found;
	}

	/** Finds a uniform and element from a path no variant may declare.

		@param path  The path.
		@return  The uniform and the element, or null: for a uniform no variant declares, an index past its elements, or a path naming a
			struct or a struct's element rather than a field. */
	public function findUniformPath(path:String):Null<ShaderUniformPath> {
		var known = paths.get(path);
		if (known != null)
			return known.uniform.declared && known.elementIndex < known.uniform.elementCount ? known : null;
		var open = path.indexOf("["), name = path, index = 0;
		if (open >= 0) {
			var close = path.indexOf("]", open);
			var parsed = Std.parseInt(path.substring(open + 1, close));
			index = parsed == null ? 0 : parsed;
			name = path.substr(0, open) + path.substr(close + 1);
		}
		var u = findUniform(name);
		if (u == null || index >= u.elementCount)
			return null;
		var made = new ShaderUniformPath(path, u, index);
		paths.set(path, made);
		return made;
	}

	/** Returns the handle of a texture any variant samples, which works on every variant's values.

		@param name  Its GLSL name.
		@return  The handle, the same each call.
		@throws String  A name no variant declares. */
	public function getSampler(name:String):ShaderSampler {
		var s = findSampler(name);
		if (s == null)
			throw 'shader variants: no variant samples texture $name';
		return s;
	}

	/** Finds the handle of a texture no variant may sample.

		@param name  Its GLSL name.
		@return  The handle, or null. */
	public function findSampler(name:String):Null<ShaderSampler> {
		var s = samplerHandles.get(name);
		return s != null && s.declared ? s : null;
	}

	// The set's own handles: each name any variant declares, found by it on every variant's values.
	final handles = new Map<String, ShaderUniform>();
	final samplerHandles = new Map<String, ShaderSampler>();
	final paths = new Map<String, ShaderUniformPath>();
	var uniformList:Array<ShaderUniform> = [];
	var samplerList:Array<ShaderSampler> = [];

	// The set's handles from its variants' declarations, made before updated in place.
	function gather():Void {
		uniformList = [];
		samplerList = [];
		var seen = new Map<String, Bool>(), sampled = new Map<String, Bool>();
		for (s in shaders) {
			for (v in s.uniforms) {
				if (seen.exists(v.name)) {
					if (v.active)
						handles.get(v.name).update(v.type, v.elementCount, v.blockName, v.shared, true, true);
					continue;
				}
				seen.set(v.name, true);
				var u = handles.get(v.name);
				if (u == null) {
					u = new ShaderUniform(v.name, v.type, v.elementCount, v.blockName, v.shared);
					handles.set(v.name, u);
				}
				u.update(v.type, v.elementCount, v.blockName, v.shared, v.active, true);
				uniformList.push(u);
			}
			for (v in s.samplers) {
				if (sampled.exists(v.name))
					continue;
				sampled.set(v.name, true);
				var t = samplerHandles.get(v.name);
				if (t == null) {
					t = new ShaderSampler(v.name, v.kind, v.slot);
					samplerHandles.set(v.name, t);
				}
				t.update(v.kind, v.slot, v.active, true);
				samplerList.push(t);
			}
		}
		for (name => u in handles)
			if (!seen.exists(name))
				u.update(u.type, u.elementCount, u.blockName, u.shared, false, false);
		for (name => t in samplerHandles)
			if (!sampled.exists(name))
				t.update(t.kind, t.slot, false, false);
	}

	// Replaces every variant in place with the new programs, by the same index, the set's handles following.

	@:allow(helix.services.shaders)
	function replace(sources:Array<helix.platform.ShaderSource>):Void {
		for (k => s in shaders)
			s.replace(sources[k]);
		gather();
		reloadError = null;
		reloadCount++;
	}

	// Calls every variant's reload listeners, then the set's.

	@:allow(helix.services.shaders)
	function reloaded():Void {
		for (s in shaders)
			s.reloaded();
		for (f in reloadListeners.copy())
			f(this);
	}

	// Records why a replacement wasn't taken.

	@:allow(helix.services.shaders)
	function refuse(why:String):Void
		reloadError = why;

	/** Finds a shared block's layout, for the library's values. */
	@:noCompletion
	public function findSharedLayout(blockName:String):Null<helix.services.shaders.ShaderLayout.ShaderBlockLayout> {
		for (s in shaders) {
			var b = s.findSharedLayout(blockName);
			if (b != null)
				return b;
		}
		return null;
	}
}
