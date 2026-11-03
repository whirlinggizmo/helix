package helix.services.shaders;

import haxe.macro.Expr;
import helix.platform.ShaderSource;
import helix.services.shaders.ShaderLayout.ShaderBlockLayout;
import helix.services.shaders.ShaderLayout.ShaderPlace;
import helix.platform.VertexBuffer;

/** Represents a compiled shader: the program `IGraphics.createShader` builds, and what it declares, found by name.

	A shader is compiled while the program builds, never while it runs: `compile` from GLSL files, `compileText` from GLSL text known
	then, `ShaderVariants.compile` for a set of variants, `makeExpr` for a library's macro. With `ShaderOptions.file`, `Shaders.watch`
	replaces it in place each time its file changes, so one shader, never null, serves a release build and a development build alike.
	It holds no GPU resource and no values: `ShaderPrograms` builds it on the GPU, and `ShaderValues` hold what it reads, the defaults
	included, as values the program makes (`ShaderValues.base`).

	**Stages.** Both stages are written in one of two forms, told apart by the `#version` line:

	- **`#version 450`**, Vulkan-style: attributes may give `layout(location = n)`, blocks and textures `layout(binding = n)`.
	- **`#version 300 es`, or 330 to 440,** as WebGL2 and GL write it: nothing gives a location or a binding, as GLSL ES 3.0 can't, and
	  the compiler places everything; a `binding` or `location` written in this form is refused. GLSL ES 100's `attribute`, `varying`,
	  `gl_FragColor` and `texture2D` are not taken.

	**Loose uniforms** (`uniform vec4 tint;`, outside a block) are taken in either form, so a variant's own uniforms, declared under its
	`#ifdef`, need no block of their own. Both stages' are gathered into one block, `helix_uniforms`, read by both (platform proposal 6):
	the vertex stage's in the order it declares them (an include's where it is included), then the fragment stage's not already there.
	A uniform both stages declare loose is one member; declared with two types, it is refused. A program with none has no such block.
	Every block is laid out by std140, whether or not it says `layout(std140)`.

	**Types.** Blocks hold `float`, `vecN`, `matN`, `int`, `ivecN`, `uint`, `uvecN`, `bool` and `bvecN` members together, structs, and
	arrays of any of them. Each struct field is a uniform found by its path (`material.roughness`); a field of an array of structs is one
	uniform whose elements are the array's (`lights.color`). An array inside an array of structs, a `double`, and a sampler array
	(`sampler2D maps[4]`) are refused, naming them.

	**Placement**, where nothing gives it. Blocks and textures are numbered apart: blocks 0 to 3 in each stage (platform proposal 10, as
	SDL_GPU binds four a stage; a block both stages read takes a slot in each), textures 0 to 11, as every adapter binds them; one past
	them is refused. Named blocks without a binding take the lowest free
	block bindings in the order declared, then `helix_uniforms`, then the shared blocks gathered from loose uniforms
	(`ShaderSharedBlock.uniforms`). Textures without a binding take the lowest free texture bindings, in the order declared. Attributes
	without a location take the lowest free locations in the order declared, a matrix a location a column. A block both stages declare
	alike is one block at one binding, read by both. Since everything is found by name, and a pipeline names the uniform it flips by its
	place (`ShaderPipelineState.flipUniform`, platform proposal 9), no rule of placement is the program's to keep: `findUniformPlace`
	says where a uniform is, and a library with a rule of its own passes a `check`.

	**Includes and defines.** A quoted `#include` resolves beside the including file, then in `ShaderOptions.includeDirectories`; one in
	angle brackets in the texts `ShaderOptions.includes` names, then in each of the build's class paths (`#include <helix/draw/color.glsl>`).
	No stage declares the include extension: the compiler enables it. Defines are given to the compiler, so a line in an error is the
	file's; each stage also has `HELIX_VERTEX` or `HELIX_FRAGMENT`.

	**Macros and the program's own types.** The service's types that hold macros import nothing with a build macro, so they type in the
	macro context. A program's own class holding a macro, or calling one at its class level, that also names a platform enum built by a
	macro (`Sampling`'s `Filter`) puts that use under `#if !macro`, or keeps the macro in a class of its own, as `ShaderValueClasses` is.

	**Strict, where GL is lenient.** A write of the wrong kind throws, where GL ignores a `glUniform` of the wrong type; a layer matching
	GL (helix-raylib's `SetShaderValue`) checks the handle's `type` itself and skips.

	**With hotreload-hx's code reload**, statics keep their values, so a `static final` holding a compiled shader keeps the old one
	when its text constant changes and the code reloads: an edit reaches a running page through the shader's `file` and
	`Shaders.watch`, not through the code reload.

	A uniform's initializer in the GLSL (`uniform float roughness = 0.5;`) is refused, naming `ShaderValues.base`, as the compiler would
	drop it. Every declared uniform is reflected, read by the code or not (`ShaderUniform.active` says which). An error stops the build at
	the call, naming the file and line.

	```haxe
	var glow = Shader.compile("quad.vert", "glow.frag", {file: "shaders/glow.shader"});
	var defaults = new ShaderValues(glow);
	defaults.writeFloat(glow.getUniform("strength"), 1);
	var values = new ShaderValues(glow, defaults);
	values.writeColor(glow.getUniform("tint"), 0xffffc040);
	values.writeTexture(glow.getSampler("image"), texture);
	``` */
class Shader implements IShaderHandles {
	/** Gets the compiled program in every dialect the build's adapters take, as `IGraphics.createShader` takes it, with its reflection:
		its blocks' members (`ShaderBlock.members`) and its attributes' types. */
	public var source(default, null):ShaderSource;

	/** Gets the vertex attributes, by slot: entry i is the attribute at slot i, so a matrix, which takes a slot a column from its own,
		is the entry at each of its columns' slots, the same record each time. */
	public var attributes(default, null):Array<ShaderAttribute>;

	/** Gets every uniform's handle, in block order. */
	public var uniforms(get, never):Array<ShaderUniform>;

	/** Gets every sampled texture's handle, in slot order. */
	public var samplers(get, never):Array<ShaderSampler>;

	/** Gets the number of times a change of its file has replaced it in place (`Shaders.watch`): 0 until then.

		After a replacement, `source` and the reflection are the new file's, and every handle and values made for it follows on its own.
		What was built on the GPU from it is its holder's to build again (`ShaderPrograms` does). A shader `withNames` made from it is
		replaced with it. A replacement happens at `Shaders.prepareFrame`, never mid-frame. Code that acts on one adds a
		`reloadListeners` function rather than watching this count. */
	public var reloadCount(default, null):Int = 0;

	/** Gets the functions called after each replacement in place, once the reflection, every handle and every values made for it have
		followed, in the order added: a program adds and removes its own (`reloadListeners.push(f)`, `reloadListeners.remove(f)`). Each
		receives the shader. A rejected replacement (`reloadError`) calls none. */
	public final reloadListeners:Array<Shader->Void> = [];

	/** Gets why the last replacement wasn't taken, or null when it was: a file that doesn't read or holds another kind of shader or
		other features (`Shaders`), or a replaced program the GPU refused (`ShaderPrograms`). The shader, and what was built from it, stay
		as they were, and this says so where a holder can see it as well as in the log. */
	public var reloadError(default, null):Null<String>;

	/** Gets the asset path of its file (`ShaderOptions.file`), which `Shaders.watch` watches, or null when it was compiled without one.
		It is set whatever the build, whether or not the build wrote the file. */
	public final filePath:Null<String>;

	/** Creates a shader from a compiled program, reading its reflection.

		The macros put a call to it in the program, and `Shaders.load` makes one for each file it loads.
		@param source  The program, with its blocks' members and its attributes' types.
		@param filePath  Optional. The asset path of its file. */
	public function new(source:ShaderSource, ?filePath:String) {
		this.filePath = filePath;
		read(source);
	}

	function get_uniforms():Array<ShaderUniform> {
		return uniformList;
	}

	function get_samplers():Array<ShaderSampler> {
		return samplerList;
	}

	/** Compiles a vertex and a fragment stage while the program builds, and returns the shader as a value in the program.

		A browser build carries GLSL ES 300 alone; a native build GLSL 410 and SDL_GPU's dialects besides. Both stages are given: a layer
		whose users may leave one out (raylib's `LoadShader(null, "x.fs")`) supplies its own default, through `makeExpr`.
		@param vertex  The vertex stage's file, relative to the file holding the call.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@param options  Optional. Defines, includes, shared blocks, a check, and a file: a constant object, at the call or a class's static
			constant (`LitShader.OPTIONS`), so options many calls share live in one place.
		@return  The shader. */
	public static macro function compile(vertex:String, fragment:String, ?options:ExprOf<ShaderOptions>):ExprOf<Shader> {
		return ShaderMacros.compileFiles(vertex, fragment, options);
	}

	/** Compiles a vertex and a fragment stage from GLSL text known while the program builds, and returns the shader as a value in the
		program.

		Each stage's text is a string literal, a static `String` constant of a class (`static inline final` or `static final` with a
		constant value), or such strings joined with `+`, so a class can keep its GLSL where it is used (`StandardMaterial.VERTEX`). A
		quoted `#include` resolves beside the file declaring the text: the call's for a literal, the constant's class's for a constant.
		@param vertex  The vertex stage's GLSL.
		@param fragment  The fragment stage's GLSL.
		@param options  Optional. Defines, includes, shared blocks, a check, and a file.
		@return  The shader. */
	public static macro function compileText(vertex:ExprOf<String>, fragment:ExprOf<String>, ?options:ExprOf<ShaderOptions>):ExprOf<Shader> {
		return ShaderMacros.compileTexts(vertex, fragment, options);
	}

	#if macro
	/** Returns the GLSL text an expression stands for while the program builds, for a library's macro that forwards a program's shader
		text (helix-raylib's `LoadShaderFromMemory`) to `makeExpr`.

		The expression is as `compileText` takes it: a literal, a static `String` constant, or such strings joined with `+`, typed where it
		was written. A `null` gives null: a stage the program left out (raylib's `LoadShader(null, "x.fs")`) is the caller's to supply, as
		helix-raylib supplies rlgl's default.
		@param text  The expression.
		@return  The text, and the file a quoted include in it resolves beside (the file declaring it), or null for `null`.
		@throws String  An expression whose value isn't known while the program builds. */
	public static function foldText(text:Expr):Null<{name:String, text:String}> {
		return ShaderMacros.foldText(text);
	}

	/** Returns the expression of a shader compiled from two stages' text, for a library's macro that makes or reads the text itself.

		Every compile goes through it, the macros above, `ShaderVariants`' and `ShaderValueClasses`' included. It compiles through
		`ShaderCompiler.compileText` with the dialects the build's target takes, runs the options' `check`, writes the options' `file`
		when `-D helix-asset-directory` is given, and reports an error at the position given. Both stages are given: a stage left out is
		the caller's to supply (`foldText`).

		The expression it returns is one shader for each distinct pair of stage texts and options in the build: a static the macro adds
		holds it, made once, so every evaluation (a load in a loop, a load after an unload) and every call site compiling the same text
		with the same options gives the same `Shader`; any difference in text or options is another. A shader holds no GPU resource, so what a layer's
		unload frees is the GPU's (`ShaderPrograms.disposeShader`), and a later load builds it again.
		@param vertex  The vertex stage: a name for messages (its file's path, when it has one, which quoted includes resolve beside) and its
			GLSL.
		@param fragment  The fragment stage: a name for messages and its GLSL.
		@param options  The defines, includes, shared blocks, check and file.
		@param pos  Where an error is reported.
		@return  An expression of type `Shader`. */
	public static function makeExpr(vertex:{name:String, text:String}, fragment:{name:String, text:String}, options:ShaderBuildOptions, pos:Position):Expr {
		return ShaderMacros.shaderExpr(vertex, fragment, options, pos);
	}
	#end

	/** Returns whether the shader declares a uniform.

		@param name  Its path, or the name `withNames` gave it.
		@return  True when it is declared. */
	public function hasUniform(name:String):Bool {
		var u = handles.get(name);
		return u != null && u.declared;
	}

	/** Returns whether the shader names a shared block (`ShaderOptions.shared`).

		@param blockName  The block's name.
		@return  True when it does. */
	public function hasSharedBlock(blockName:String):Bool {
		return sharedNames.indexOf(blockName) >= 0;
	}

	/** Returns a handle for a uniform the shader may declare now or only after a replacement, for code written ahead of the GLSL: one not
		declared now is `declared` false, keeps what is written through it, and binds when a replacement declares it, its type then the
		declaration's. A value kept that the declared type doesn't take is logged and dropped.

		@param name  Its path, or the name `withNames` gave it.
		@return  The handle, the same each call; the declared one's when the shader declares it. */
	public function reserveUniform(name:String):ShaderUniform {
		var u = handles.get(name);
		if (u == null) {
			u = new ShaderUniform(name, Float, 1, "", false);
			u.update(Float, 1, "", false, false, false);
			handles.set(name, u);
		}
		return u;
	}

	/** Returns a uniform and element for a path as GLSL writes it (`pointLights[1].color`) that the shader may declare only after a
		replacement, binding as `reserveUniform` does.

		@param path  The path.
		@return  The uniform and the element, the same object for the same path. */
	public function reserveUniformPath(path:String):ShaderUniformPath {
		var known = paths.get(path);
		if (known != null)
			return known;
		var parsed = parsePath(path);
		var made = new ShaderUniformPath(path, reserveUniform(parsed.name), parsed.elementIndex);
		paths.set(path, made);
		return made;
	}

	/** Returns a handle for a texture the shader may sample now or only after a replacement, binding, its kind then the declaration's,
		when a replacement declares it.

		@param name  Its GLSL name, or the name `withNames` gave it.
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

	/** Returns whether the shader samples a texture.

		@param name  Its GLSL name, or the name `withNames` gave it.
		@return  True when it is declared. */
	public function hasSampler(name:String):Bool {
		var s = samplerHandles.get(name);
		return s != null && s.declared;
	}

	/** Returns the handle of a uniform the shader declares.

		@param name  Its path (`roughness`, `material.roughness`, `lights.color`), or the name `withNames` gave it.
		@return  The handle, the same each call.
		@throws String  A name the shader doesn't declare, listing those it does; given `lights[0].position`, it names
			`lights.position` and `getUniformPath`. */
	public function getUniform(name:String):ShaderUniform {
		var u = findUniform(name);
		if (u == null)
			throw missingUniform(name, [for (u in uniformList) u.name]);
		return u;
	}

	/** Finds the handle of a uniform the shader may not declare.

		@param name  Its path, or the name `withNames` gave it.
		@return  The handle, the same each call, or null. */
	public function findUniform(name:String):Null<ShaderUniform> {
		var u = handles.get(name);
		return u != null && u.declared ? u : null;
	}

	/** Returns a uniform and element from a path as GLSL writes it, with brackets (`pointLights[1].color`, `bones[3]`), or without.

		@param path  The path.
		@return  The uniform and the element, the same object for the same path.
		@throws String  A path whose uniform the shader doesn't declare, or an index past its elements. */
	public function getUniformPath(path:String):ShaderUniformPath {
		var found = findUniformPath(path);
		if (found == null) {
			var parsed = parsePath(path);
			var u = findUniform(parsed.name);
			if (u == null)
				throw 'shader: no uniform ${parsed.name} for the path $path; it declares ${[for (u in uniformList) u.name].join(", ")}';
			throw 'shader: the path $path is past ${u.name}\'s ${u.elementCount} elements';
		}
		return found;
	}

	/** Finds a uniform and element from a path that may not be declared.

		@param path  The path.
		@return  The uniform and the element, or null: for a uniform the shader doesn't declare, an index past its elements, a path
			naming a struct or a struct's element rather than a field (`lights[1]`, `lights`), or a sampler's name. */
	public function findUniformPath(path:String):Null<ShaderUniformPath> {
		var known = paths.get(path);
		if (known != null)
			return known.uniform.declared && known.elementIndex < known.uniform.elementCount ? known : null;
		var parsed = parsePath(path);
		var u = findUniform(parsed.name);
		if (u == null || parsed.elementIndex >= u.elementCount)
			return null;
		var made = new ShaderUniformPath(path, u, parsed.elementIndex);
		paths.set(path, made);
		return made;
	}

	/** Returns the handle of a texture the shader samples.

		@param name  Its GLSL name, or the name `withNames` gave it.
		@return  The handle, the same each call.
		@throws String  A name the shader doesn't declare, listing those it does. */
	public function getSampler(name:String):ShaderSampler {
		var s = findSampler(name);
		if (s == null)
			throw 'shader: no texture $name; it samples ${[for (s in samplerList) s.name].join(", ")}';
		return s;
	}

	/** Finds the handle of a texture the shader may not sample.

		@param name  Its GLSL name, or the name `withNames` gave it.
		@return  The handle, or null. */
	public function findSampler(name:String):Null<ShaderSampler> {
		var s = samplerHandles.get(name);
		return s != null && s.declared ? s : null;
	}

	/** Returns where a uniform is in this shader: its block's slot and its byte offset, as a pipeline's flip (proposal 9) or a check
		reads them.

		@param uniform  The uniform.
		@return  The slot and offset, the first block's when two stages' blocks hold it, or null when this shader doesn't declare it. */
	public function findUniformPlace(uniform:ShaderUniform):Null<{blockSlot:Int, offset:Int}> {
		var found = placesOf(uniform);
		if (found == null)
			return null;
		for (p in found)
			if (p.block.stage != "fragment")
				return {blockSlot: p.block.slot, offset: p.offset};
		return {blockSlot: found[0].block.slot, offset: found[0].offset};
	}

	/** Returns a vertex attribute the shader reads.

		@param name  Its GLSL name, or the name `withNames` gave it.
		@return  The attribute, with its slot and type.
		@throws String  A name the shader doesn't declare, listing those it does. */
	public function getAttribute(name:String):ShaderAttribute {
		var a = findAttribute(name);
		if (a == null)
			throw 'shader: no attribute $name; it reads ${[for (a in uniqueAttributes()) nameOf(a.glslName)].join(", ")}';
		return a;
	}

	/** Finds a vertex attribute the shader may not read.

		@param name  Its GLSL name, or the name `withNames` gave it.
		@return  The attribute, or null. */
	public function findAttribute(name:String):Null<ShaderAttribute> {
		var glsl = glslNameOf(name);
		for (a in attributes)
			if (a != null && a.glslName == glsl)
				return a;
		return null;
	}

	/** Returns the layout of a vertex buffer built for this shader, its records holding the attributes named, packed as floats in the
		order given.

		It suits a buffer a program fills for this shader (a sprite batch's, a variant's own). A mesh whose records are laid out already,
		drawn by any shader, is a `ShaderVertexLayout` (`ShaderVertexLayout.fromAttributes` packs one the same way for any shader). Each attribute takes its
		type's floats (`ShaderValueType.componentCount` times `columnCount`), and a matrix a `VertexAttribute` a column at consecutive
		slots, as `PipelineDesc.buffers` takes them.

		```haxe
		var layout = shader.computeVertexBuffer(["position", "normal", "texCoord"]);   // 32-byte records
		var instances = shader.computeVertexBuffer(["instanceTransform"], true);       // 64-byte records, a slot a column
		```
		@param names  The attributes, in their order in a record, by GLSL name or the name `withNames` gave them.
		@param instanced  Optional. Whether the buffer steps once an instance; defaults to false.
		@return  The buffer's layout: its stride, the sum of the attributes' sizes, and an attribute a column.
		@throws String  A name the shader doesn't declare, or an integer attribute (`ivec4`), which the platform can't feed yet. */
	public function computeVertexBuffer(names:Array<String>, instanced:Bool = false):VertexBuffer {
		var attributes:Array<helix.platform.VertexAttribute> = [], offset = 0;
		for (name in names) {
			var a = getAttribute(name);
			if (a.type.integer)
				throw 'shader: attribute $name is a ${a.type}, an integer input, which the platform can\'t feed yet';
			var format = ShaderVertexLayout.floats(a.type.componentCount);
			for (c in 0...a.type.columnCount) {
				attributes.push({slot: a.slot + c, format: format, offset: offset});
				offset += format.bytes;
			}
		}
		return {stride: offset, instanced: instanced, attributes: attributes};
	}

	/** Returns the attributes the shader reads that no buffer of a layout feeds, for a check before a pipeline is made.

		Such an attribute reads its layout's constant (`ShaderVertexLayout.constants`), or (0, 0, 0, 1) (platform proposal 8).
		@param buffers  The layout, as `PipelineDesc.buffers` holds it.
		@return  The attributes no buffer feeds, empty when every one is fed. */
	public function computeUnfedAttributes(buffers:Array<VertexBuffer>):Array<ShaderAttribute> {
		var fed = new Map<Int, Bool>();
		for (b in buffers)
			for (a in b.attributes)
				fed.set(a.slot, true);
		return [for (a in uniqueAttributes()) if (!fed.exists(a.slot)) a];
	}

	/** Returns this shader with some of its names changed, for code that finds what a shader declares by names other than its GLSL's.

		The program is the same: only the names the finds and gets take change. A renamed thing is found by its new name alone; a struct's
		name renames the paths that start with it (`light` the `light.color`); a name in the map that the shader doesn't declare is
		skipped, so one map serves shaders that declare different parts of it. The shader returned is
		replaced with it; this one is unchanged.

		```haxe
		// raylib's names, as helix-draw fills them
		var lit = Shader.compile("lit.vs", "lit.fs").withNames([
			"vertexPosition" => "position", "vertexTexCoord" => "texCoord", "vertexColor" => "color",
			"mvp" => "modelViewProjection", "colDiffuse" => "baseColor", "texture0" => "baseColorTexture"
		]);
		```
		@param names  Each GLSL name, mapped to the name it is to be found by.
		@return  The shader with the names changed.
		@throws String  Two names mapped to one, or a new name that another attribute, uniform or texture of the same kind already has. */
	public function withNames(names:Map<String, String>):Shader {
		var seen = new Map<String, String>();
		for (glsl => given in names) {
			if (seen.exists(given))
				throw 'shader: withNames maps ${seen.get(given)} and $glsl both to $given';
			seen.set(given, glsl);
		}
		var renamed = new Shader(source, filePath);
		renamed.renames = names.copy();
		for (glsl => given in names)
			renamed.unnames.set(given, glsl);
		renamed.markShared(sharedNames);
		renamed.checkNames();
		renamedFrom.push(renamed);
		return renamed;
	}

	// The names withNames gave, by GLSL name, and back; empty for a shader of its GLSL names.
	var renames:Null<Map<String, String>> = null;
	final unnames = new Map<String, String>();
	// The shaders withNames made from this one, replaced with it.
	final renamedFrom:Array<Shader> = [];
	// The blocks ShaderOptions.shared names.
	var sharedNames:Array<String> = [];
	// What it declares: blocks, each uniform's places by GLSL path, the handles by the name they're found by (reserved ones too).
	@:allow(helix.services.shaders)
	var blocks(default, null):Array<ShaderBlockLayout> = [];
	final placesByPath = new Map<String, Array<ShaderPlace>>();
	final handles = new Map<String, ShaderUniform>();
	final samplerHandles = new Map<String, ShaderSampler>();
	final paths = new Map<String, ShaderUniformPath>();
	var uniformList:Array<ShaderUniform> = [];
	var samplerList:Array<ShaderSampler> = [];
	// The size of a draw's uniforms for it: the highest block index and 1.
	@:allow(helix.services.shaders)
	var uniformCount(default, null) = 0;
	// The texture slots it binds: the highest and 1.
	@:allow(helix.services.shaders)
	var textureCount(default, null) = 0;
	// Each texture slot's sampler name, "" for none.
	@:allow(helix.services.shaders)
	var slotSamplers(default, null):Array<String> = [];

	// Reads a program's reflection: its blocks, uniforms, textures and attributes, the handles made before updated in place.
	function read(source:ShaderSource):Void {
		this.source = source;
		blocks = [];
		placesByPath.clear();
		var order:Array<String> = [];
		var declared = new Map<String, {
			type:ShaderValueType,
			elementCount:Int,
			blockName:String,
			shared:Bool,
			active:Bool
		}>();
		uniformCount = 0;
		for (b in source.uniformBlocks) {
			var layout = new ShaderBlockLayout(b, sharedNames.indexOf(b.glslName) >= 0);
			var index = blocks.length;
			blocks.push(layout);
			for (i in layout.indices)
				if (i + 1 > uniformCount)
					uniformCount = i + 1;
			for (m in b.members) {
				var list = placesByPath.get(m.glslName);
				if (list == null) {
					placesByPath.set(m.glslName, list = []);
					order.push(m.glslName);
					declared.set(m.glslName, {
						type: cast m.type,
						elementCount: m.elementCount,
						blockName: b.glslName,
						shared: layout.shared,
						active: m.active
					});
				} else if (m.active)
					declared.get(m.glslName).active = true;
				list.push(new ShaderPlace(layout, index, m));
			}
		}
		var seen = new Map<String, Bool>();
		uniformList = [];
		for (path in order) {
			var name = nameOf(path), d = declared.get(path);
			var u = handles.get(name);
			if (u == null) {
				u = new ShaderUniform(name, d.type, d.elementCount, d.blockName, d.shared);
				handles.set(name, u);
			}
			u.update(d.type, d.elementCount, d.blockName, d.shared, d.active, true);
			seen.set(name, true);
			uniformList.push(u);
		}
		for (name => u in handles)
			if (!seen.exists(name))
				u.update(u.type, u.elementCount, u.blockName, u.shared, false, false);
		// Textures, by slot.
		var sampled = new Map<String, Bool>();
		samplerList = [];
		textureCount = 0;
		slotSamplers = [];
		var textures = source.textures.copy();
		textures.sort((a, b) -> a.slot - b.slot);
		for (t in textures) {
			var name = nameOf(t.glslName);
			var kind:ShaderSamplerKind = t.shadow ? Shadow : t.cube ? Cube : t.data ? Data : Texture2D;
			var s = samplerHandles.get(name);
			if (s == null) {
				s = new ShaderSampler(name, kind, t.slot);
				samplerHandles.set(name, s);
			}
			s.update(kind, t.slot, t.active, true);
			sampled.set(name, true);
			samplerList.push(s);
			if (t.slot + 1 > textureCount)
				textureCount = t.slot + 1;
			while (slotSamplers.length <= t.slot)
				slotSamplers.push("");
			slotSamplers[t.slot] = name;
		}
		for (name => s in samplerHandles)
			if (!sampled.exists(name))
				s.update(s.kind, s.slot, false, false);
		// Attributes by slot, a matrix the same record at each of its columns' slots.
		var types = source.attributeTypes == null ? [] : source.attributeTypes;
		var active = source.activeAttributes == null ? [] : source.activeAttributes;
		attributes = [for (_ in 0...source.attributes.length) null];
		for (slot => glsl in source.attributes)
			if (glsl != "") {
				var type:ShaderValueType = cast types[slot];
				var record:ShaderAttribute = {
					glslName: glsl,
					slot: slot,
					type: type,
					active: active.indexOf(slot) >= 0
				};
				for (c in 0...type.columnCount)
					if (slot + c < attributes.length)
						attributes[slot + c] = record;
			}
	}

	// Marks the blocks ShaderOptions.shared names, as the macros and Shaders.load make a shader.

	@:allow(helix.services.shaders)
	function markShared(names:Array<String>):Void {
		sharedNames = names.copy();
		read(source);
	}

	// Marks the shared blocks for the next read, as a replacement's file names them.

	@:allow(helix.services.shaders)
	function markSharedQuiet(names:Array<String>):Void
		sharedNames = names.copy();

	// The shared blocks' names.

	@:allow(helix.services.shaders)
	function sharedBlockNames():Array<String>
		return sharedNames;

	// Replaces it in place with a new program, every handle following; the shaders withNames made with it.

	@:allow(helix.services.shaders)
	function replace(next:ShaderSource):Void {
		#if !macro
		ShaderPrograms.rebuilding = ShaderPrograms.rebuildReplaced;
		#end
		read(next);
		reloadError = null;
		reloadCount++;
		for (renamed in renamedFrom)
			renamed.replace(next);
	}

	// Calls the reload listeners, once everything has followed.

	@:allow(helix.services.shaders)
	function reloaded():Void {
		for (f in reloadListeners.copy())
			f(this);
		for (renamed in renamedFrom)
			renamed.reloaded();
	}

	// Records why a replacement wasn't taken.

	@:allow(helix.services.shaders)
	function refuse(why:String):Void {
		reloadError = why;
		for (renamed in renamedFrom)
			renamed.refuse(why);
	}

	// The places of a uniform, by its name here (a handle of another shader is found by its name), or null when not declared.

	@:allow(helix.services.shaders)
	function placesOf(uniform:ShaderUniform):Null<Array<ShaderPlace>>
		return placesByPath.get(glslNameOf(uniform.name));

	// The block layout of a name, or null.

	@:allow(helix.services.shaders)
	function blockNamed(name:String):Null<ShaderBlockLayout> {
		for (b in blocks)
			if (b.name == name)
				return b;
		return null;
	}

	// A sampler's slot here, by its name, or -1.

	@:allow(helix.services.shaders)
	function slotOf(sampler:ShaderSampler):Int {
		var s = samplerHandles.get(sampler.name);
		return s != null && s.declared ? s.slot : -1;
	}

	// The attributes, each once.
	function uniqueAttributes():Array<ShaderAttribute> {
		var out = [];
		for (a in attributes)
			if (a != null && out.indexOf(a) < 0)
				out.push(a);
		return out;
	}

	// The name a GLSL name is found by, and back.

	@:allow(helix.services.shaders)
	function nameOf(glsl:String):String {
		if (renames == null)
			return glsl;
		var whole = renames.get(glsl);
		if (whole != null)
			return whole;
		// A struct's name renames the paths starting with it.
		var dot = glsl.indexOf(".");
		if (dot > 0) {
			var head = renames.get(glsl.substr(0, dot));
			if (head != null)
				return head + glsl.substr(dot);
		}
		return glsl;
	}

	function glslNameOf(name:String):String {
		if (renames == null)
			return name;
		var whole = unnames.get(name);
		if (whole != null)
			return whole;
		var dot = name.indexOf(".");
		if (dot > 0) {
			var head = unnames.get(name.substr(0, dot));
			if (head != null)
				return head + name.substr(dot);
		}
		return renames.exists(name) ? "" : name;
	}

	// Refuses a new name another uniform, texture or attribute of the same kind already has.
	function checkNames():Void {
		var kinds = [
			[for (u in uniformList) u.name],
			[for (s in samplerList) s.name],
			[for (a in uniqueAttributes()) nameOf(a.glslName)]
		];
		for (list in kinds) {
			var seen = new Map<String, Bool>();
			for (n in list) {
				if (seen.exists(n))
					throw 'shader: withNames gives two of its names the name $n';
				seen.set(n, true);
			}
		}
	}

	// A path's uniform name and element: `lights[1].color` is `lights.color` and 1, `bones[3]` `bones` and 3.
	static function parsePath(path:String):{name:String, elementIndex:Int} {
		var open = path.indexOf("[");
		if (open < 0)
			return {name: path, elementIndex: 0};
		var close = path.indexOf("]", open);
		var index = Std.parseInt(path.substring(open + 1, close));
		return {name: path.substr(0, open) + path.substr(close + 1), elementIndex: index == null ? 0 : index};
	}

	// The message for a name not declared, naming the bracket-free form and getUniformPath for a bracketed one.
	static function missingUniform(name:String, declared:Array<String>):String {
		if (name.indexOf("[") >= 0)
			return 'shader: no uniform $name: an array of structs\' field is one uniform (${parsePath(name).name}), its elements by index; '
				+ 'getUniformPath turns $name into it and an element';
		return 'shader: no uniform $name; it declares ${declared.join(", ")}';
	}

	/** Finds a shared block's layout, for the library's values. */
	@:noCompletion
	public function findSharedLayout(blockName:String):Null<helix.services.shaders.ShaderLayout.ShaderBlockLayout> {
		var b = blockNamed(blockName);
		return b != null && b.shared ? b : null;
	}
}
