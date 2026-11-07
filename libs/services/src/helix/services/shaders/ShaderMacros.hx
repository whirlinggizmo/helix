package helix.services.shaders;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import helix.platform.ShaderSource;
import helix.platform.tools.CommandException;
import helix.platform.tools.ShaderCompiler;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/** The shaders' build-time work, which the macros of `Shader`, `ShaderVariants`, `ShaderValueClasses` and `ShaderBlockCompiler` call:
	reading the options a call gives, folding text, compiling through the platform's compiler, writing a shader's file, and putting one
	static a compile into the program.

	It imports nothing a build macro makes, so it types in the macro context. */
@:noCompletion
class ShaderMacros {
	/** The programs compiled this build, by the class holding them: what `ShaderValueClasses.buildBlock` reads. */
	public static final compiled = new Map<String, {
		kind:String,
		sources:Array<ShaderSource>,
		featureNames:Array<String>,
		variantFeatures:Array<Int>,
		shared:Array<ShaderSharedBlock>
	}>();

	/** `Shader.compile`: both stages' files, relative to the calling file. */
	public static function compileFiles(vertex:String, fragment:String, options:Null<Expr>):Expr {
		var pos = Context.currentPos();
		return shaderExpr(file(vertex, pos), file(fragment, pos), buildOptions(options, pos), pos);
	}

	/** `Shader.compileText`: both stages' text, known while the program builds. */
	public static function compileTexts(vertex:Expr, fragment:Expr, options:Null<Expr>):Expr {
		var pos = Context.currentPos();
		var v = foldText(vertex), f = foldText(fragment);
		if (v == null || f == null)
			Context.error("shader: compileText takes both stages' text; a layer supplies a stage left out through makeExpr", pos);
		return shaderExpr(v, f, buildOptions(options, pos), pos);
	}

	/** `ShaderVariants.compile` and `compileText`. */
	public static function variantsFrom(vertex:{name:String, text:String}, fragment:{name:String, text:String}, features:Expr, options:Null<Expr>,
			pos:Position):Expr {
		var names:Array<String> = constant(features, pos);
		if (!Std.isOfType(names, Array))
			Context.error("shader: the features are a constant array of names", pos);
		var value:Dynamic = optionsValue(options, pos);
		var combinations:Null<Array<Array<String>>> = value == null ? null : value.combinations;
		return variantsExpr(vertex, fragment, names, combinations, toBuild(value, pos), pos);
	}

	/** A file relative to the calling file, read, a dependency of the calling module. */
	public static function file(path:String, pos:Position):{name:String, text:String} {
		var here = Path.directory(Context.getPosInfos(pos).file);
		var full = Path.isAbsolute(path) ? path : Path.join([here, path]);
		if (!FileSystem.exists(full))
			Context.error('shader: $full not found', pos);
		Context.registerModuleDependency(Context.getLocalModule(), full);
		return {name: full, text: File.getContent(full)};
	}

	/** `Shader.foldText`. */
	public static function foldText(text:Expr):Null<{name:String, text:String}> {
		switch text.expr {
			case EConst(CIdent("null")):
				return null;
			case _:
		}
		var typed = try Context.typeExpr(text) catch (e:Dynamic) Context.error('shader: the text isn\'t known while the program builds: $e', text.pos);
		var name = Context.getPosInfos(text.pos).file;
		var folded = fold(typed, f -> name = f);
		if (folded == null)
			Context.error("shader: a stage's text is known while the program builds: a string literal, a static String constant, or such strings "
				+ "joined with +",
				text.pos);
		if (!Path.isAbsolute(name))
			name = FileSystem.absolutePath(name);
		return {name: name, text: folded};
	}

	// A typed string constant's value: a literal, a static constant, or such joined with +; declared receives the first constant's file.
	static function fold(t:TypedExpr, declared:String->Void):Null<String> {
		return switch t.expr {
			case TConst(TString(s)): s;
			case TConst(TNull): null;
			case TParenthesis(inner) | TCast(inner, _) | TMeta(_, inner): fold(inner, declared);
			case TBinop(OpAdd, a, b): var x = fold(a, declared),
					y = fold(b, _ -> {}); x == null || y == null ? null : x + y;
			case TField(_, FStatic(_, field)):
				var f = field.get();
				var expr = f.expr();
				if (expr == null) null; else {
					declared(Context.getPosInfos(f.pos).file);
					fold(expr, _ -> {});
				}
			case _: null;
		}
	}

	/** A constant expression's value while the program builds: literals, arrays, objects, and static constants holding them. */
	public static function constant(e:Expr, pos:Position):Dynamic {
		switch e.expr {
			case EConst(CIdent("null")):
				return null;
			case _:
		}
		return value(Context.typeExpr(e), pos);
	}

	static function value(t:TypedExpr, pos:Position):Dynamic {
		return switch t.expr {
			case TConst(TString(s)): s;
			case TConst(TInt(i)): i;
			case TConst(TFloat(f)): Std.parseFloat(f);
			case TConst(TBool(b)): b;
			case TConst(TNull): null;
			case TParenthesis(inner) | TCast(inner, _) | TMeta(_, inner): value(inner, pos);
			case TArrayDecl(items): [for (i in items) value(i, pos)];
			case TObjectDecl(fields):
				var out = {};
				for (f in fields)
					Reflect.setField(out, f.name, value(f.expr, pos));
				out;
			case TBinop(OpAdd, a, b):
				var x:Dynamic = value(a, pos), y:Dynamic = value(b, pos);
				x + y;
			case TField(_, FStatic(_, field)):
				var expr = field.get().expr();
				if (expr == null)
					Context.error('shader: ${field.get().name} isn\'t a constant known while the program builds', pos);
				value(expr, pos);
			case _: Context.error("shader: options are a constant object (or an array of them), at the call or a class's static constant", t.pos);
		}
	}

	// The options a call gives: an object, a static constant, or an array of them composed left to right.
	static function optionsValue(options:Null<Expr>, pos:Position):Dynamic {
		if (options == null)
			return null;
		var given:Dynamic = constant(options, pos);
		if (given == null)
			return null;
		if (!Std.isOfType(given, Array))
			return given;
		var out:Dynamic = {};
		var list:Array<Dynamic> = given;
		for (part in list)
			for (key in Reflect.fields(part)) {
				var v:Dynamic = Reflect.field(part, key),
					had:Dynamic = Reflect.field(out, key);
				Reflect.setField(out, key, had != null
					&& Std.isOfType(had, Array)
					&& Std.isOfType(v, Array) ? (had : Array<Dynamic>).concat(v) : v);
			}
		return out;
	}

	/** The options a call gives, as `makeExpr` takes them. */
	public static function buildOptions(options:Null<Expr>, pos:Position):ShaderBuildOptions
		return toBuild(optionsValue(options, pos), pos);

	static function toBuild(value:Dynamic, pos:Position):ShaderBuildOptions {
		if (value == null)
			return {};
		var known = [
			"defines",
			"includes",
			"includeDirectories",
			"shared",
			"clipScale",
			"points",
			"check",
			"file",
			"combinations"
		];
		for (key in Reflect.fields(value))
			if (known.indexOf(key) < 0)
				Context.error('shader: no option $key (${known.join(", ")})', pos);
		var here = Path.directory(Context.getPosInfos(pos).file);
		var directories:Array<String> = value.includeDirectories == null ? [] : value.includeDirectories;
		var checkName:Null<String> = value.check;
		return {
			defines: value.defines,
			includes: value.includes == null ? null : includeTexts(value.includes, pos),
			includeDirectories: [for (d in directories) Path.isAbsolute(d) ? d : Path.join([here, d])],
			shared: value.shared,
			clipScale: value.clipScale,
			points: value.points,
			check: checkName == null ? null : checkFunction(checkName, pos),
			file: value.file
		};
	}

	// A class's static String constants, by name: the texts an angle-bracket include takes.
	static function includeTexts(className:String, pos:Position):Map<String, String> {
		var type = try Context.getType(className) catch (e:Dynamic) Context.error('shader: no class $className for includes', pos);
		var out = new Map<String, String>();
		switch type {
			case TInst(c, _):
				for (f in c.get().statics.get()) {
					var expr = f.expr();
					if (expr == null)
						continue;
					var text = fold(expr, _ -> {});
					if (text != null)
						out.set(f.name, text);
				}
			case _:
				Context.error('shader: $className holds no static constants', pos);
		}
		return out;
	}

	// A static function by its dotted path, called while the program builds.
	static function checkFunction(path:String, pos:Position):Shader->Null<String> {
		var dot = path.lastIndexOf(".");
		var className = path.substr(0, dot), name = path.substr(dot + 1);
		var c = Type.resolveClass(className);
		if (c == null) {
			Context.getType(className);
			c = Type.resolveClass(className);
		}
		var f:Dynamic = c == null ? null : Reflect.field(c, name);
		if (f == null)
			Context.error('shader: check $path isn\'t a static function the build can run (its class must be on the class path)', pos);
		return shader -> f(shader);
	}

	/** `Shader.makeExpr`: one static holding the shader for each distinct text and options in the build. */
	public static function shaderExpr(vertex:{name:String, text:String}, fragment:{name:String, text:String}, options:ShaderBuildOptions, pos:Position):Expr {
		var source = compileProgram(vertex, fragment, options, [], pos);
		var shared = declaredShared(source, options.shared);
		var sharedNames = [for (s in shared) s.name];
		checkShared(source, shared, vertex.name, pos);
		var shader = new Shader(source, options.file);
		shader.markShared(sharedNames);
		if (options.check != null) {
			var why = options.check(shader);
			if (why != null)
				Context.error('shader: $why', pos);
		}
		if (options.file != null)
			writeFile(options.file, {kind: "shader", source: source, shared: sharedNames}, pos);
		var name = holderName("Shader", [haxe.Json.stringify(source), haxe.Json.stringify(key(options))]);
		compiled.set(name, {
			kind: "shader",
			sources: [source],
			featureNames: [],
			variantFeatures: [],
			shared: shared
		});
		define(name, macro {
			var shader = new helix.services.shaders.Shader(${Context.makeExpr(source, pos)}, $v{options.file});
			@:privateAccess shader.markShared($v{sharedNames});
			shader;
		}, macro :helix.services.shaders.Shader, "SHADER", pos);
		return macro @:pos(pos) helix.services.shaders.compiled.$name.SHADER;
	}

	/** `ShaderVariants.makeExpr`. */
	public static function variantsExpr(vertex:{name:String, text:String}, fragment:{name:String, text:String}, features:Array<String>,
			combinations:Null<Array<Array<String>>>, options:ShaderBuildOptions, pos:Position):Expr {
		for (f in features)
			if (f == "SHADER" || f == "VARIANTS" || !~/^[A-Za-z_]\w*$/.match(f))
				Context.error('shader: a feature named $f; a feature is a name, not SHADER or VARIANTS', pos);
		if (combinations == null) {
			if (features.length > 8)
				Context.error('shader: ${features.length} features, past the 8 every combination of which is compiled; give the combinations', pos);
			combinations = [
				for (bits in 0...1 << features.length) [for (i in 0...features.length) if (bits & 1 << i != 0) features[i]]
			];
		}
		var shared = options.shared == null ? [] : options.shared;
		var sharedNames = [for (s in shared) s.name];
		var sources = [], bits = [];
		for (combination in combinations) {
			var set = 0;
			for (f in combination) {
				var i = features.indexOf(f);
				if (i < 0)
					Context.error('shader: the combination [${combination.join(", ")}] names $f, which isn\'t one of the features', pos);
				set |= 1 << i;
			}
			if (bits.indexOf(set) >= 0)
				Context.error('shader: the combination [${combination.join(", ")}] is given twice', pos);
			bits.push(set);
			var source = compileProgram(vertex, fragment, options, combination, pos);
			checkShared(source, declaredShared(source, shared), vertex.name, pos);
			var shader = new Shader(source, options.file);
			shader.markShared([for (s in declaredShared(source, shared)) s.name]);
			if (options.check != null) {
				var why = options.check(shader);
				if (why != null)
					Context.error('shader: [${combination.join(", ")}]: $why', pos);
			}
			sources.push(source);
		}
		// A shared block alike in every variant that declares it.
		for (name in sharedNames) {
			var first:Null<String> = null;
			for (k => source in sources)
				for (b in source.uniformBlocks)
					if (b.glslName == name) {
						var key = new helix.services.shaders.ShaderLayout.ShaderBlockLayout(b, true).key;
						if (first == null)
							first = key;
						else if (key != first)
							Context.error('shader: shared block $name is laid out differently in [${combinations[k].join(", ")}]; a feature may not change it',
								pos);
					}
		}
		if (options.file != null)
			writeFile(options.file, {
				kind: "variants",
				featureNames: features,
				variantFeatures: bits,
				sources: sources,
				shared: sharedNames
			}, pos);
		var name = holderName("Variants", [
			haxe.Json.stringify(sources),
			features.join(","),
			haxe.Json.stringify(combinations),
			haxe.Json.stringify(key(options))
		]);
		compiled.set(name, {
			kind: "variants",
			sources: sources,
			featureNames: features,
			variantFeatures: bits,
			shared: shared
		});
		var made = [
			for (source in sources)
				macro {
					var shader = new helix.services.shaders.Shader(${Context.makeExpr(source, pos)}, $v{options.file});
					@:privateAccess shader.markShared($v{sharedNames});
					shader;
				}
		];
		define(name, macro new helix.services.shaders.ShaderVariants($v{features}, $v{bits}, $a{made}, $v{options.file}),
			macro :helix.services.shaders.ShaderVariants, "VARIANTS", pos);
		return macro @:pos(pos) helix.services.shaders.compiled.$name.VARIANTS;
	}

	// The options as a key: without the check (a function), and without the include directories, which are paths and reach the key
	// through what the compile made.
	static function key(options:ShaderBuildOptions):Dynamic
		return {
			defines: options.defines,
			includes: options.includes == null ? null : [for (k => v in options.includes) '$k=$v'],
			shared: options.shared,
			clipScale: options.clipScale,
			points: options.points,
			file: options.file
		};

	// The holder class's name for a compile: its kind and a hash of what the compile made and the options it was made with, never of a
	// file's path, so a build names its holders alike wherever the checkout is.
	static function holderName(kind:String, parts:Array<String>):String
		return kind + haxe.crypto.Sha1.encode(parts.join("\u0000")).substr(0, 16);

	// Adds the class holding a compile's one static, unless this build has it already.
	static function define(name:String, init:Expr, type:ComplexType, field:String, pos:Position):Void {
		var exists = try Context.getType('helix.services.shaders.compiled.$name') != null catch (_:Dynamic) false;
		if (exists)
			return;
		var holder = macro class $name {};
		holder.pack = ["helix", "services", "shaders", "compiled"];
		holder.meta = [{name: ":noCompletion", pos: pos}];
		holder.fields = [
			{
				name: field,
				access: [APublic, AStatic, AFinal],
				kind: FVar(type, init),
				pos: pos
			}
		];
		Context.defineType(holder);
	}

	/** Compiles a program: each stage with its own define, the options' defines and a combination's features, includes from texts and the
		class paths, loose uniforms taken and the shared ones gathered. */
	public static function compileProgram(vertex:{name:String, text:String}, fragment:{name:String, text:String}, options:ShaderBuildOptions,
			features:Array<String>, pos:Position):ShaderSource {
		var js = Context.defined("js");
		var includes:Array<String> = [];
		var scratch:Null<String> = null;
		if (options.includes != null) {
			scratch = helix.platform.tools.Scratch.make("helix-includes-");
			for (name => text in options.includes) {
				var path = Path.join([scratch, name]);
				FileSystem.createDirectory(Path.directory(path));
				File.saveContent(path, text);
			}
			includes.push(scratch);
		}
		if (options.includeDirectories != null)
			includes = includes.concat(options.includeDirectories);
		includes = includes.concat([for (c in Context.getClassPath()) c == "" ? "." : c]);
		var gathered = [
			for (s in (options.shared == null ? [] : options.shared))
				if (s.uniforms != null) {name: s.name, uniforms: s.uniforms}
		];
		try {
			var source = ShaderCompiler.compileText({name: vertex.name, text: staged(vertex, "HELIX_VERTEX")},
				{name: fragment.name, text: staged(fragment, "HELIX_FRAGMENT")}, {
					glsl410: !js,
					sdlGpu: !js,
					includeDirectories: includes,
					defines: (options.defines == null ? [] : options.defines).concat(features),
					looseUniforms: true,
					gatheredBlocks: gathered,
					clipScale: options.clipScale == true,
					points: options.points == true
				});
			if (scratch != null)
				helix.platform.tools.Files.removeDirectory(scratch);
			return source;
		} catch (error:CommandException) {
			if (scratch != null)
				helix.platform.tools.Files.removeDirectory(scratch);
			var message = error.message;
			if (message.indexOf("initializer") >= 0)
				message += "; a uniform's starting value is written on values a program makes, as a base (ShaderValues.base)";
			return Context.error(features.length > 0 ? '$message\n(compiled with ${features.join(", ")})' : message, pos);
		}
	}

	// A stage with its own define after its version line, its lines counted as they were.
	static function staged(stage:{name:String, text:String}, define:String):String {
		var text = stage.text.replace("\r\n", "\n");
		var version = ~/^[ \t]*#version[^\n]*\n/m;
		if (!version.match(text))
			return text;
		var before = version.matchedLeft() + version.matched(0);
		return before + '#define $define 1\n#line ${before.split("\n").length}\n' + version.matchedRight();
	}

	// Refuses a shared block the shader neither declares nor gathers.
	// The shared blocks a source takes: those named, less the ones shared only where declared (whereDeclared) that it doesn't declare.
	static function declaredShared(source:ShaderSource, shared:Null<Array<ShaderSharedBlock>>):Array<ShaderSharedBlock>
		return shared == null ? [] : [
			for (s in shared)
				if (s.whereDeclared != true || Lambda.exists(source.uniformBlocks, b -> b.glslName == s.name)) s
		];

	static function checkShared(source:ShaderSource, shared:Array<ShaderSharedBlock>, name:String, pos:Position):Void
		for (s in shared)
			if (!Lambda.exists(source.uniformBlocks, b -> b.glslName == s.name))
				Context.error('shader: $name: shared block ${s.name} isn\'t declared; name a block the shader declares, or the loose uniforms to gather (uniforms)',
					pos);

	// Writes a compiled shader's file under -D helix-asset-directory, with this target's dialects; nothing without the define.
	static function writeFile(path:String, contents:Dynamic, pos:Position):Void {
		var directory = Context.definedValue("helix-asset-directory");
		if (directory == null || directory == "")
			return;
		var full = Path.join([directory, path]);
		FileSystem.createDirectory(Path.directory(full));
		var text = haxe.Json.stringify(contents);
		if (!FileSystem.exists(full) || File.getContent(full) != text)
			File.saveContent(full, text);
	}
}
#end
