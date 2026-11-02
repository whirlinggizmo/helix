package helix.platform.tools;

import haxe.macro.Context;
import haxe.macro.Expr;
#if sys
import haxe.io.Bytes;
import haxe.io.Path;
import sys.io.File;
import helix.platform.tools.ShaderText.ShaderDeclaration;
#end

/** Provides compiling a program's GLSL into a `ShaderSource` for every graphics adapter: a vertex stage and a fragment stage, compiled
	once to SPIR-V by glslang and translated by SPIRV-Cross (`ShaderTools`), and reflected.

	**Two forms of source**, told apart by the `#version` line: `#version 450`, Vulkan-style, where attributes may give
	`layout(location = n)` and blocks and textures `layout(binding = n)`; and `#version 300 es`, or 330 to 440, as WebGL2 and GL write
	it, where nothing gives a location or a binding (one written is refused, as GLSL ES 3.0 has none) and the compiler places
	everything. Both stages are one form. `#include` needs no extension line: the compiler enables `GL_GOOGLE_include_directive` for
	every stage, and a stage declaring it is still taken.

	What a program's source declares is what it binds: each uniform block, at its size rounded up to whole `vec4`s, and each texture, a
	combined sampler, whether the code reads it or not (`ShaderMember.active` and `ShaderTexture.active` say whether it does). Blocks
	and textures are numbered apart: every adapter binds blocks 0 to 3 in each stage and textures 0 to 11, and a binding past them is
	refused. A block both stages declare alike (the same name, binding and members) is one block at one slot, read by both
	(`ShaderBlock.stage` "both"); two declarations of one name that differ are refused. A block holds `float`, `vecN`, `matN`, `int`,
	`ivecN`, `uint`, `uvecN`, `bool` and `bvecN` members together, structs, and arrays of any of them, laid out by std140; a field of an
	array of structs is reflected as one member whose elements are the array's (`lights.color`). An array inside an array of structs,
	an array of arrays, a `double` and a sampler array are refused. A texture's kind comes from its type (`sampler2D`, `sampler2DArray`,
	`samplerCube`, `sampler2DArrayShadow`); one only read with `texelFetch` is never filtered. The vertex attributes are the vertex
	stage's inputs, at locations from 0 without gaps, a matrix a location a column; the values passed between the stages may leave
	their locations out, matched by name. The vertex stage writes GL's clip space.

	**Loose uniforms** (`ShaderCompileOptions.looseUniforms`): uniforms outside a block, in either form, both stages' gathered into one
	block, `helix_uniforms`, read by both: the vertex stage's in declared order, then the fragment stage's not already there. A uniform
	both declare is one member; with two types it is refused, and so is an initializer, which the compiler would drop. Loose uniforms
	named in `ShaderCompileOptions.gatheredBlocks` go into their own blocks, read by both. Gathering is a strict text step over glslang's
	preprocessed output (`-E`): each global `uniform` declaration is one statement there and is moved whole, and glslang then compiles
	and validates the result, so a rewrite gone wrong fails the build.

	**Placement**, where a source gives none: named blocks at the lowest free block bindings of their stages in the order declared (the
	vertex stage's first), then `helix_uniforms`, then the gathered blocks, each at the lowest binding free in both stages; textures at
	the lowest free texture bindings in the order declared; attributes at the lowest free locations in the order declared, a matrix a
	location a column.

	With `ShaderCompileOptions.clipScale` the compiler wraps the vertex stage: `#define main helix_main` before the stage's text, a loose
	`uniform vec4 helix_clipScale;`, and after it `void main() { helix_main(); gl_Position *= helix_clipScale; }`, so any vertex stage
	can be flipped through `ClipFlip.ClipScale`.

	```haxe
	var shader = graphics.createShader(ShaderCompiler.compile("triangle.vert", "triangle.frag"));
	``` */
class ShaderCompiler {
	// SDL_GPU's descriptor sets: textures and uniform blocks, by stage.
	static final SDL_GPU_SETS = ["vertex" => {textures: 0, blocks: 1}, "fragment" => {textures: 2, blocks: 3}];
	// The bindings every graphics adapter has: uniform blocks 0 to 3 in each stage, textures 0 to 11.
	static inline final BLOCK_SLOTS = 4;
	static inline final TEXTURE_SLOTS = 12;
	// GL's type enums, as glslang's reflection gives them, as GLSL names.
	static final GL_TYPES = [
		0x1406 => "float",
		0x8b50 => "vec2",
		0x8b51 => "vec3",
		0x8b52 => "vec4",
		0x1404 => "int",
		0x8b53 => "ivec2",
		0x8b54 => "ivec3",
		0x8b55 => "ivec4",
		0x1405 => "uint",
		0x8dc6 => "uvec2",
		0x8dc7 => "uvec3",
		0x8dc8 => "uvec4",
		0x8b56 => "bool",
		0x8b57 => "bvec2",
		0x8b58 => "bvec3",
		0x8b59 => "bvec4",
		0x8b5a => "mat2",
		0x8b5b => "mat3",
		0x8b5c => "mat4"
	];
	static final GL_TYPES_BY_NAME = [for (name in GL_TYPES) name];

	/** Compiles a program while the build runs, and returns its `ShaderSource` as a value in the program.

		A browser build carries GLSL ES 300 alone; a native build GLSL 410 and SDL_GPU's dialects besides. An error stops the build at the call, saying
		where in the shader it is.
		@param vertex  The vertex stage's file, relative to the file holding the call.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@return  The program, as `IGraphics.createShader` takes it. */
	public static macro function compile(vertex:String, fragment:String):ExprOf<helix.platform.ShaderSource> {
		var pos = Context.currentPos();
		var here = Path.directory(Context.getPosInfos(pos).file);
		function locate(path:String):String {
			var full = Path.isAbsolute(path) ? path : Path.join([here, path]);
			if (!sys.FileSystem.exists(full))
				Context.error('shader: $full not found', pos);
			Context.registerModuleDependency(Context.getLocalModule(), full);
			return full;
		}
		var vertexPath = locate(vertex), fragmentPath = locate(fragment);
		var js = Context.defined("js");
		try {
			var source = compileText({name: vertexPath, text: File.getContent(vertexPath)}, {name: fragmentPath, text: File.getContent(fragmentPath)},
				{glsl410: !js, sdlGpu: !js});
			return macro(${Context.makeExpr(source, pos)} : helix.platform.ShaderSource);
		} catch (error:CommandException) {
			return Context.error(error.message, pos);
		}
	}

	/** Compiles a program's two stages from their text, in the compiler or a tool.

		A macro calls it to compile text it has made or read (a library rewriting another dialect, a library adding defines), and puts the
		result in the program with `Context.makeExpr`.

		A quoted `#include` resolves beside the stage's file (its name, when that's a path), then in the include directories; the include
		extension is enabled for every stage. It runs where the system is reachable, in the compiler or a tool; in a program it throws.
		@param vertex  The vertex stage: a name for messages (its file's path, when it has one) and its GLSL.
		@param fragment  The fragment stage: a name for messages and its GLSL.
		@param options  The dialects to make, the include directories, the defines, and whether loose uniforms are taken.
		@return  The program, with its reflection.
		@throws CommandException  A stage doesn't compile (glslang's errors, named for the stage), or the program breaks a rule above. */
	public static function compileText(vertex:{name:String, text:String}, fragment:{name:String, text:String},
			options:ShaderCompileOptions):helix.platform.ShaderSource {
		#if !sys
		throw new CommandException("shader: compileText runs in the compiler or a tool, not in a program");
		#else
		var glslang = ShaderTools.glslang(), cross = ShaderTools.spirvCross();
		var scratch = Scratch.make("helix-shader-");
		try {
			var source = compileIn(scratch, glslang, cross, vertex, fragment, options);
			Files.removeDirectory(scratch);
			return source;
		} catch (error:haxe.Exception) {
			Files.removeDirectory(scratch);
			throw error;
		}
		#end
	}

	#if sys
	static function compileIn(scratch:String, glslang:String, cross:String, vertex:{name:String, text:String}, fragment:{name:String, text:String},
			options:ShaderCompileOptions):helix.platform.ShaderSource {
		var given = [
			{
				stage: "vertex",
				suffix: "vert",
				name: vertex.name,
				text: StringTools.replace(vertex.text, "\r\n", "\n")
			},
			{
				stage: "fragment",
				suffix: "frag",
				name: fragment.name,
				text: StringTools.replace(fragment.text, "\r\n", "\n")
			}
		];
		if (options.clipScale == true)
			given[0].text = wrapMain(given[0].text, vertex.name, "helix_main", "uniform vec4 helix_clipScale;", "gl_Position *= helix_clipScale;");
		var include = "-P#extension GL_GOOGLE_include_directive : enable";
		// Preprocessed, includes and defines resolved: the text step reads this.
		var calls = [];
		for (g in given) {
			var file = Path.join([scratch, '${g.stage}.${g.suffix}']);
			File.saveContent(file, g.text);
			var args = ["-E", include];
			for (d in (options.defines == null ? [] : options.defines))
				args.push('-D$d');
			for (directory in besides(g.name, options.includeDirectories))
				args.push('-I$directory');
			calls.push({program: glslang, args: args.concat([file])});
		}
		var preprocessed = [
			for (k => run in Scratch.runAll(calls))
				dropPreamble(checked(run, Path.join([scratch, '${given[k].stage}.${given[k].suffix}']), given[k].name))
		];
		var arranged = arrange(preprocessed, given, options);
		// Compiled, with glslang's listing (fetched textures) and its reflection (types and what the code reads).
		var compiles = [
			for (k => g in given)
				{
					stage: g.stage,
					suffix: g.suffix,
					name: g.name,
					text: arranged.texts[k]
				}
		];
		if (options.sdlGpu)
			compiles.push({
				stage: "vertex-sdlgpu",
				suffix: "vert",
				name: vertex.name,
				// GL's clip depth (-1..1) as SDL_GPU's (0..1).
				text: wrapMain(arranged.texts[0], vertex.name, "helix_gpu_main", "", "gl_Position.z = (gl_Position.z + gl_Position.w) * 0.5;")
			});
		var compileCalls = [];
		for (c in compiles) {
			var file = Path.join([scratch, '${c.stage}.c.${c.suffix}']);
			File.saveContent(file, c.text);
			var common = [
				"-V",
				"--target-env",
				"vulkan1.0",
				"--auto-map-locations",
				"-P#extension GL_GOOGLE_cpp_style_line_directive : enable"
			];
			compileCalls.push({program: glslang, args: common.concat(["-H", "-o", Path.join([scratch, '${c.stage}.spv']), file])});
			// glslang writes SPIR-V wherever it's asked to reflect: into the scratch, not the working directory.
			compileCalls.push({
				program: glslang,
				args: common.concat([
					"-q",
					"--reflect-all-block-variables",
					"-o",
					Path.join([scratch, '${c.stage}.q.spv']),
					file
				])
			});
		}
		var listings = new Map<String, String>();
		for (k => run in Scratch.runAll(compileCalls)) {
			var c = compiles[k >> 1];
			var out = checked(run, Path.join([scratch, '${c.stage}.c.${c.suffix}']), c.name);
			listings.set(c.stage, (k & 1 == 0 ? "" : listings.get(c.stage)) + "\n" + out);
		}
		var spv = stage -> Path.join([scratch, '$stage.spv']);
		var crossCalls = [];
		var gl = ["--no-420pack-extension", "--no-support-nonzero-baseinstance"];
		for (stage in ["vertex", "fragment"]) {
			crossCalls.push({program: cross, args: [spv(stage), "--reflect"]});
			crossCalls.push({program: cross, args: [spv(stage), "--version", "300", "--es"].concat(gl)});
			if (options.glsl410)
				crossCalls.push({program: cross, args: [spv(stage), "--version", "410", "--no-es", "--glsl-emit-ubo-as-plain-uniforms"].concat(gl)});
		}
		var results = Scratch.runAll(crossCalls);
		var per = options.glsl410 ? 3 : 2;
		var outputs = [for (k => result in results) crossOutput(result, crossCalls[k].args)];
		var described = describe([
			"vertex" => haxe.Json.parse(outputs[0]),
			"fragment" => haxe.Json.parse(outputs[per])
		], listings, arranged, vertex.name, fragment.name);
		var source:Dynamic = {
			attributes: described.attributes,
			attributeTypes: described.attributeTypes,
			activeAttributes: described.activeAttributes,
			uniformBlocks: described.blocks,
			textures: described.textures,
			glsl300es: {
				vertex: outputs[1],
				fragment: outputs[per + 1]
			}
		};
		if (options.glsl410)
			source.glsl410 = {vertex: namedBlocks(outputs[2], described.blocks), fragment: namedBlocks(outputs[per + 2], described.blocks)};
		if (options.sdlGpu)
			source.sdlGpu = sdlGpu(cross, scratch, [
				"vertex" => File.getBytes(spv("vertex-sdlgpu")),
				"fragment" => File.getBytes(spv("fragment"))
			], described);
		return source;
	}

	// GL 410 holds each block as a uniform of its struct type, a block without an instance name under a name SPIRV-Cross numbers by the
	// stage's ids, so two stages' blocks could take one name: each such uniform named for its block (`helix_block_Name`), alike in every
	// stage, so a block both stages read is one uniform and two blocks are never one name.
	static function namedBlocks(text:String, blocks:Array<Dynamic>):String {
		var declared = ~/^uniform (\w+) (_\d+);$/m;
		var names = [for (b in blocks) (b.glslName : String)];
		var scan = text, renames = [];
		while (declared.match(scan)) {
			if (names.indexOf(declared.matched(1)) >= 0)
				renames.push({from: declared.matched(2), to: 'helix_block_${declared.matched(1)}'});
			scan = declared.matchedRight();
		}
		for (r in renames)
			text = new EReg('\\b${r.from}\\b', "g").replace(text, r.to);
		return text;
	}

	// The text with its main renamed by the preprocessor (an include's too) and a main after it calling it, then doing more; a declaration
	// before it; the line count kept.
	static function wrapMain(text:String, name:String, renamed:String, declaration:String, after:String):String {
		var version = ~/^[ \t]*#version[^\n]*\n/m;
		if (!version.match(text))
			throw new CommandException('shader: $name: the vertex stage starts with #version');
		var before = version.matchedLeft() + version.matched(0);
		return before
			+ '#define main $renamed\n$declaration\n#line ${before.split("\n").length}\n'
			+ version.matchedRight()
			+ '\n#undef main\nvoid main()\n{\n    $renamed();\n    $after\n}\n';
	}

	// glslang -E writes its preamble (the include extension) first; the text from the version on is the stage's.
	static function dropPreamble(text:String):String {
		var first = text.indexOf("\n");
		return StringTools.startsWith(text, "#extension GL_GOOGLE_include_directive") && first >= 0 ? text.substr(first + 1) : text;
	}

	// A stage's output, or its errors named for name rather than the scratch file compiled.
	static function checked(run:{code:Int, out:String, err:String}, file:String, name:String):String {
		if (run.code != 0) {
			var lines = [
				for (line in '${run.out}${run.err}'.split("\n"))
					if (StringTools.startsWith(line, "ERROR:")
						|| StringTools.startsWith(line, "WARNING:")) StringTools.replace(line, file, name)
			];
			throw new CommandException('shader: $name doesn\'t compile\n${lines.join("\n")}');
		}
		return run.out;
	}

	// SPIRV-Cross's output, or a refusal saying its error.
	static function crossOutput(run:{code:Int, out:String, err:String}, args:Array<String>):String {
		if (run.code != 0)
			throw new CommandException('spirv-cross failed (exit ${run.code}) on ${args.join(" ")}:\n${run.out}${run.err}');
		return run.out;
	}

	// The directories a stage's `#include` looks in: its own file's first, when it has one, so a quoted include resolves beside it.
	static function besides(name:String, includes:Null<Array<String>>):Array<String> {
		var directory = Path.directory(name);
		var own = directory != "" && sys.FileSystem.exists(directory) && sys.FileSystem.isDirectory(directory) ? [directory] : [];
		return own.concat(includes == null ? [] : includes);
	}

	// The locations a value of a GLSL type takes: a matrix's columns, or one; an array's elements times that.
	static function columns(type:String):Int
		return switch type {
			case "mat2" | "dmat2": 2;
			case "mat3" | "dmat3": 3;
			case "mat4" | "dmat4": 4;
			case _: 1;
		}

	static function locationCount(type:String, array:String):Int {
		var count = 1;
		if (array != "") {
			var n = Std.parseInt(array.substring(1, array.length - 1));
			count = n == null ? 1 : n;
		}
		var words = type.split(" ");
		return columns(words[words.length - 1]) * count;
	}

	/** The text step: both stages placed and their loose uniforms gathered. Returns each stage's text to compile, and what the reflection
		is checked against: each block's stage and slot, and the instance names of blocks that have one. */
	static function arrange(preprocessed:Array<String>, given:Array<{
		stage:String,
		suffix:String,
		name:String,
		text:String
	}>,
			options:ShaderCompileOptions):{texts:Array<String>, blocks:Map<String, {stage:String, slot:Int}>, instances:Map<String, String>} {
		var stages = [for (k in 0...2) new ShaderText(preprocessed[k], given[k].name)];
		var gl = [];
		for (k => s in stages) {
			if (s.versionStart < 0)
				throw new CommandException('shader: ${given[k].name}: no #version line');
			var form = s.version == 450
				&& !s.es ? false : (s.es && s.version == 300) || (!s.es && s.version >= 330 && s.version <= 440) ? true : null;
			if (form == null)
				throw new CommandException('shader: ${given[k].name}: #version ${s.version}${s.es ? " es" : ""}; a stage is #version 450, 300 es, or 330 to 440');
			gl.push(form);
		}
		if (gl[0] != gl[1])
			throw new CommandException('shader: ${given[0].name}, ${given[1].name}: both stages are written in one form, #version 450 or GL\'s');
		var glForm = gl[0];
		var instances = new Map<String, String>();
		// What each stage declares, by kind.
		function all(k:Int, kind:String)
			return [for (d in stages[k].declarations) if (d.kind == kind) d];
		for (k => s in stages)
			for (d in s.declarations) {
				if (glForm && d.placed)
					s.refuse(d.start, '${d.name} gives a binding or location, which a stage in GL\'s form leaves to the compiler');
				if (d.kind == "block" && d.instance != "")
					instances.set(d.name, d.instance);
			}
		// Loose uniforms, each stage's in order, the clip scale the compiler's own.
		var loose = [for (k in 0...2) all(k, "uniform")];
		for (k in 0...2)
			for (d in loose[k]) {
				if (d.initialized)
					stages[k].refuse(d.start, 'uniform ${d.name} has an initializer, which the compiler would drop');
				if (options.looseUniforms != true && d.name != "helix_clipScale")
					stages[k].refuse(d.start, 'uniform ${d.name} is outside a block; a stage declares its uniforms in blocks');
			}
		function declaration(d:ShaderDeclaration):String
			return '${d.type} ${d.name}${d.array}';
		function plain(d:ShaderDeclaration):String
			return ~/\b(highp|mediump|lowp)\s+/g.replace(declaration(d), "");
		function find(name:String):Null<{stage:Int, d:ShaderDeclaration}> {
			for (k in 0...2)
				for (d in loose[k])
					if (d.name == name)
						return {stage: k, d: d};
			return null;
		}
		// The same name in both stages is one uniform, of one type.
		for (d in loose[1]) {
			var other = Lambda.find(loose[0], v -> v.name == d.name);
			if (other != null && plain(other) != plain(d))
				stages[1].refuse(d.start, 'uniform ${d.name} is a ${plain(d)} here and a ${plain(other)} in the vertex stage');
		}
		// Gathered blocks, then helix_uniforms with the rest.
		var taken = new Map<String, Bool>();
		var newBlocks:Array<{name:String, members:Array<ShaderDeclaration>}> = [];
		for (g in (options.gatheredBlocks == null ? [] : options.gatheredBlocks)) {
			var members:Array<ShaderDeclaration> = [];
			for (u in g.uniforms) {
				var found = find(u);
				if (found == null)
					throw new CommandException('shader: ${given[0].name}, ${given[1].name}: block ${g.name} gathers uniform $u, which neither stage declares outside a block');
				if (taken.exists(u))
					throw new CommandException('shader: ${given[0].name}, ${given[1].name}: uniform $u is gathered twice');
				taken.set(u, true);
				members.push(found.d);
			}
			newBlocks.push({name: g.name, members: members});
		}
		var rest:Array<ShaderDeclaration> = [];
		for (k in 0...2)
			for (d in loose[k])
				if (!taken.exists(d.name) && !Lambda.exists(rest, r -> r.name == d.name))
					rest.push(d);
		if (rest.length > 0)
			newBlocks.unshift({name: "helix_uniforms", members: rest});
		// Blocks: named ones by stage, merged by name; explicit bindings first, then the lowest free in declared order.
		var used = [new Map<Int, String>(), new Map<Int, String>()];
		var blocks = new Map<String, {stage:String, slot:Int}>();
		var order:Array<{name:String, stages:Array<Int>, decls:Array<{k:Int, d:ShaderDeclaration}>}> = [];
		for (k in 0...2)
			for (d in all(k, "block")) {
				var entry = Lambda.find(order, o -> o.name == d.name);
				if (entry == null)
					order.push({name: d.name, stages: [k], decls: [{k: k, d: d}]});
				else if (entry.stages.indexOf(k) >= 0)
					stages[k].refuse(d.start, 'uniform block ${d.name} is declared twice');
				else {
					entry.stages.push(k);
					entry.decls.push({k: k, d: d});
				}
			}
		function claim(name:String, stageList:Array<Int>, slot:Int, k:Int, at:Int):Void {
			if (slot < 0 || slot >= BLOCK_SLOTS)
				stages[k].refuse(at, 'uniform block $name at binding $slot; the adapters bind blocks 0 to ${BLOCK_SLOTS - 1} in each stage');
			for (s in stageList) {
				if (used[s].exists(slot))
					stages[k].refuse(at, 'uniform block $name at binding $slot, which ${used[s].get(slot)} has');
				used[s].set(slot, name);
			}
		}
		for (o in order) {
			var bindings = [for (x in o.decls) x.d.binding];
			if (bindings.length == 2 && bindings[0] != bindings[1])
				stages[1].refuse(o.decls[1].d.start, 'uniform block ${o.name} is at another binding than in the vertex stage');
			if (bindings[0] != null) {
				claim(o.name, o.stages, bindings[0], o.decls[0].k, o.decls[0].d.start);
				blocks.set(o.name, {stage: o.stages.length == 2 ? "both" : o.stages[0] == 0 ? "vertex" : "fragment", slot: bindings[0]});
			}
		}
		function lowest(name:String, stageList:Array<Int>):Int {
			for (slot in 0...BLOCK_SLOTS)
				if (!Lambda.exists(stageList, s -> used[s].exists(slot))) {
					for (s in stageList)
						used[s].set(slot, name);
					return slot;
				}
			throw new CommandException('shader: ${given[0].name}, ${given[1].name}: uniform block $name has no binding left; the adapters bind blocks 0 to ${BLOCK_SLOTS - 1} in each stage');
		}
		for (o in order)
			if (!blocks.exists(o.name)) {
				var slot = lowest(o.name, o.stages);
				blocks.set(o.name, {stage: o.stages.length == 2 ? "both" : o.stages[0] == 0 ? "vertex" : "fragment", slot: slot});
				for (x in o.decls)
					stages[x.k].insert(x.d.start, 'layout(binding = $slot) ');
			}
		for (b in newBlocks) {
			if (blocks.exists(b.name))
				throw new CommandException('shader: ${given[0].name}, ${given[1].name}: a block named ${b.name} is declared already');
			blocks.set(b.name, {stage: "both", slot: lowest(b.name, [0, 1])});
		}
		// Textures: explicit bindings first, then the lowest free, the vertex stage's first, in declared order.
		var textureUsed = new Map<Int, String>();
		var textures = [for (k in 0...2) for (d in all(k, "texture")) {k: k, d: d}];
		for (t in textures) {
			if (~/^(i|u)?texture|^sampler(Shadow)?$/.match(t.d.uses[0]))
				stages[t.k].refuse(t.d.start, 'a texture and its sampler are one combined sampler (sampler2D and its kin), not separate');
			if (t.d.array != "")
				stages[t.k].refuse(t.d.start, 'texture ${t.d.name} is an array; every adapter binds one texture a slot');
			if (Lambda.exists(textures, o -> o.k != t.k && o.d.name == t.d.name))
				stages[t.k].refuse(t.d.start, 'texture ${t.d.name} is declared in both stages; a texture is sampled by one');
			if (t.d.binding != null) {
				if (t.d.binding >= TEXTURE_SLOTS || t.d.binding < 0)
					stages[t.k].refuse(t.d.start, 'texture ${t.d.name} at binding ${t.d.binding}; the adapters bind textures 0 to ${TEXTURE_SLOTS - 1}');
				if (textureUsed.exists(t.d.binding))
					stages[t.k].refuse(t.d.start, 'texture ${t.d.name} at binding ${t.d.binding}, which ${textureUsed.get(t.d.binding)} has');
				textureUsed.set(t.d.binding, t.d.name);
			}
		}
		for (t in textures)
			if (t.d.binding == null) {
				var slot = 0;
				while (slot < TEXTURE_SLOTS && textureUsed.exists(slot))
					slot++;
				if (slot == TEXTURE_SLOTS)
					stages[t.k].refuse(t.d.start, 'texture ${t.d.name} has no binding left; the adapters bind textures 0 to ${TEXTURE_SLOTS - 1}');
				textureUsed.set(slot, t.d.name);
				if (t.d.shared)
					stages[t.k].refuse(t.d.start, 'texture ${t.d.name} is declared with others in one statement; declare each texture on its own');
				stages[t.k].insert(t.d.start, 'layout(binding = $slot) ');
			}
		// Locations: the attributes and the fragment outputs in declared order, the values between the stages matched by name.
		function place(k:Int, kind:String, matched:Null<Map<String, Int>>):Map<String, Int> {
			var taken = new Map<Int, Bool>(), out = new Map<String, Int>();
			var list = all(k, kind);
			for (d in list)
				if (d.location != null) {
					for (c in 0...locationCount(d.type, d.array))
						taken.set(d.location + c, true);
					out.set(d.name, d.location);
				}
			for (d in list)
				if (d.location == null && !d.shared) {
					var location = -1;
					if (matched != null && matched.exists(d.name))
						location = matched.get(d.name);
					else {
						location = 0;
						var span = locationCount(d.type, d.array);
						while (Lambda.exists([for (c in 0...span) c], c -> taken.exists(location + c)))
							location++;
					}
					for (c in 0...locationCount(d.type, d.array))
						taken.set(location + c, true);
					out.set(d.name, location);
					stages[k].insert(d.start, 'layout(location = $location) ');
				}
			return out;
		}
		place(0, "in", null);
		var sent = place(0, "out", null);
		place(1, "in", sent);
		place(1, "out", null);
		// The loose uniforms out, their blocks in, after the structs they name (copied from the other stage where this one lacks them).
		var structs = [for (k in 0...2) [for (d in all(k, "struct")) d.name => d]];
		for (k => s in stages) {
			var at = -1;
			for (d in loose[k]) {
				if (d.shared && Lambda.exists(s.declarations, o -> o.start == d.start && o.kind != "uniform"))
					s.refuse(d.start, 'uniform ${d.name} is declared with a texture in one statement; declare each on its own');
				if (at < 0)
					at = d.start;
			}
			var removed = new Map<Int, Bool>();
			for (d in loose[k])
				if (!removed.exists(d.start)) {
					removed.set(d.start, true);
					s.remove(d.start, d.end);
				}
			var needed:Array<String> = [];
			function need(type:String):Void {
				for (k2 in 0...2)
					if (structs[k2].exists(type) && needed.indexOf(type) < 0) {
						for (u in structs[k2].get(type).uses)
							if (u != type)
								need(u);
						needed.push(type);
						return;
					}
			}
			for (b in newBlocks)
				for (m in b.members)
					need(m.uses[0]);
			var copies = new StringBuf();
			if (at < 0)
				at = s.firstStatement();
			for (type in needed)
				if (structs[k].exists(type)) {
					if (structs[k].get(type).end > at)
						at = structs[k].get(type).end;
				} else
					copies.add(stages[1 - k].source(structs[1 - k].get(type)) + " ");
			for (b in newBlocks) {
				var slot = blocks.get(b.name).slot;
				copies.add('layout(std140, binding = $slot) uniform ${b.name} { ${[for (m in b.members) declaration(m) + ";"].join(" ")} }; ');
			}
			if (newBlocks.length > 0)
				s.insertBefore(at, copies.toString());
			if (glForm)
				s.setVersion450();
		}
		return {texts: [for (s in stages) s.edited()], blocks: blocks, instances: instances};
	}

	// One entry of glslang's reflection: `name: offset 0, type 8b52, size 1, index 0, binding -1, stages 16, ...`.
	static function reflection(listing:String):Map<String, Array<{name:String, fields:Map<String, Int>}>> {
		var out = new Map<String, Array<{name:String, fields:Map<String, Int>}>>();
		var section:Null<Array<{name:String, fields:Map<String, Int>}>> = null;
		var at = listing.indexOf("\nUniform reflection:");
		if (at < 0)
			return out;
		for (line in listing.substr(at + 1).split("\n")) {
			if (StringTools.endsWith(line, "reflection:")) {
				section = [];
				out.set(line.substr(0, line.length - " reflection:".length), section);
				continue;
			}
			var colon = line.indexOf(": ");
			if (section == null || colon < 0)
				continue;
			var fields = new Map<String, Int>();
			for (part in line.substr(colon + 2).split(", ")) {
				var kv = part.split(" ");
				if (kv.length == 2)
					fields.set(kv[0], kv[0] == "type" ? Std.parseInt("0x" + kv[1]) : Std.parseInt(kv[1]));
			}
			section.push({name: line.substr(0, colon), fields: fields});
		}
		return out;
	}

	// A block's members: their layout from SPIRV-Cross's reflection of the block's type (leaves in declared order, a field of an array of
	// structs one member), their GLSL types (a bool, which SPIR-V holds as a uint, among them) and whether the code reads them from
	// glslang's reflection, which lists a block only when the code reads some of it.
	static function members(types:Dynamic, typeId:String, entries:Array<{name:String, fields:Map<String, Int>}>, blockName:String, instance:Null<String>,
			name:String):Array<Dynamic> {
		var out:Array<Dynamic> = [];
		var prefix = instance != null ? instance + "." : "";
		function flatten(id:String, path:String, base:Int, array:Null<{count:Int, stride:Int}>):Void {
			var type:Dynamic = Reflect.field(types, id);
			var fields:Array<Dynamic> = type.members;
			for (m in fields) {
				var memberPath = path + m.name,
					offset:Int = base + m.offset,
					memberType:String = m.type;
				var dims:Array<Int> = m.array;
				if (dims != null && dims.length > 1)
					throw new CommandException('shader: $name: block $blockName\'s $memberPath is an array of arrays');
				if (dims != null && array != null)
					throw new CommandException('shader: $name: block $blockName\'s $memberPath is an array inside an array of structs');
				if (StringTools.startsWith(memberType, "_")) {
					flatten(memberType, memberPath + ".", offset, dims != null ? {count: dims[0], stride: m.array_stride} : array);
					continue;
				}
				if (GL_TYPES_BY_NAME.indexOf(memberType) < 0)
					throw new CommandException('shader: $name: block $blockName\'s $memberPath is a $memberType; a block holds float, vecN, matN, int, ivecN, uint, uvecN, bool and bvecN');
				out.push({
					glslName: prefix + memberPath,
					type: memberType,
					offset: offset,
					elementCount: dims != null ? dims[0] : array != null ? array.count : 1,
					active: false,
					stride: dims != null ? m.array_stride : array != null ? array.stride : columns(memberType) * 16
				});
			}
		}
		flatten(typeId, "", 0, null);
		var byPath = [for (m in out) (m.glslName : String) => m];
		var element = ~/^(\w+)\[\d+\]\.(.+)$/;
		for (e in entries) {
			var path = e.name;
			if (instance != null && StringTools.startsWith(path, blockName + "."))
				path = instance + path.substr(blockName.length);
			var inner = path.substr(prefix.length);
			var perElement = element.match(inner);
			if (perElement)
				path = prefix + element.matched(1) + "." + element.matched(2);
			var m = byPath.get(path);
			if (m == null)
				continue;
			var type = GL_TYPES.get(e.fields.get("type"));
			if (type != null && StringTools.startsWith(type, "b"))
				m.type = type;
			if (e.fields.get("stages") != 0 && !perElement)
				m.active = true;
		}
		return out;
	}

	// The program's attributes, blocks and textures from each stage's reflection, its rules checked.
	static function describe(reflected:Map<String, Dynamic>, listings:Map<String, String>, arranged:{
		texts:Array<String>,
		blocks:Map<String, {stage:String, slot:Int}>,
		instances:Map<String, String>
	}, vertexName:String, fragmentName:String):Dynamic {
		var queried = [
			"vertex" => reflection(listings.get("vertex")),
			"fragment" => reflection(listings.get("fragment"))
		];
		var inputs:Array<Dynamic> = reflected.get("vertex").inputs == null ? [] : reflected.get("vertex").inputs;
		var activeInputs = [for (e in queried.get("vertex").get("Pipeline input")) e.name];
		// A matrix input takes a location a column, from its own: mat4's four vec4s.
		var slots = 0;
		for (input in inputs)
			slots += columns(input.type);
		var attributes = [for (_ in 0...slots) ""],
			attributeTypes = [for (_ in 0...slots) ""],
			activeAttributes = [];
		for (input in inputs) {
			var location:Int = input.location,
				type:String = input.type,
				count = columns(type);
			if (input.array != null)
				throw new CommandException('shader: $vertexName: the vertex input ${input.name} is an array');
			for (column in 0...count)
				if (location + column >= slots || attributeTypes[location + column] != "")
					throw new CommandException('shader: $vertexName: the vertex inputs\' locations must run from 0 without gaps');
			attributes[location] = input.name;
			attributeTypes[location] = type;
			for (column in 1...count)
				attributeTypes[location + column] = 'vec${type.charAt(3)}';
			if (activeInputs.indexOf(input.name) >= 0)
				activeAttributes.push(location);
		}
		activeAttributes.sort((a, b) -> a - b);
		var blocks:Array<Dynamic> = [], textures:Array<Dynamic> = [];
		var textureSlots = new Map<Int, String>();
		for (stage in ["vertex", "fragment"]) {
			var r:Dynamic = reflected.get(stage),
				name = stage == "vertex" ? vertexName : fragmentName,
				query = queried.get(stage);
			var separate:Array<Dynamic> = r.separate_images == null ? [] : r.separate_images;
			if (separate.length > 0 || r.separate_samplers != null)
				throw new CommandException('shader: $name: a texture and its sampler are one combined sampler (sampler2D and its kin), not separate');
			if (r.ssbos != null)
				throw new CommandException('shader: $name: a storage buffer, which WebGL2 has none of');
			var queriedBlocks = query.get("Uniform block");
			var uniforms = query.get("Uniform");
			var ubos:Array<Dynamic> = r.ubos == null ? [] : r.ubos;
			for (ubo in ubos) {
				var blockName:String = ubo.name;
				var placed = arranged.blocks.get(blockName);
				var size = Std.int((ubo.block_size + 15) / 16) * 16;
				var index = -1;
				for (k => qb in queriedBlocks)
					if (qb.name == blockName)
						index = k;
				var list = members(r.types, ubo.type, [for (u in uniforms) if (index >= 0 && u.fields.get("index") == index) u], blockName,
					arranged.instances.get(blockName), name);
				var existing:Dynamic = Lambda.find(blocks, (b:Dynamic) -> b.glslName == blockName);
				if (existing != null) {
					// Declared in both stages: one block, alike.
					var same = existing.size == size && existing.members.length == list.length;
					if (same)
						for (k => m in list) {
							var o = existing.members[k];
							if (o.glslName != m.glslName || o.type != m.type || o.offset != m.offset || o.elementCount != m.elementCount)
								same = false;
						}
					if (!same)
						throw new CommandException('shader: $vertexName, $fragmentName: uniform block $blockName is declared differently in the two stages');
					for (k => m in list)
						if (m.active)
							existing.members[k].active = true;
					continue;
				}
				blocks.push({
					slot: placed.slot,
					stage: placed.stage,
					size: size,
					glslName: blockName,
					members: list
				});
			}
			var samplers:Array<Dynamic> = r.textures == null ? [] : r.textures;
			var activeSamplers = [for (u in uniforms) if (u.fields.get("index") == -1) u.name];
			for (t in samplers) {
				var slot:Int = t.binding,
					textureName:String = t.name,
					type:String = t.type;
				if (t.array != null)
					throw new CommandException('shader: $name: texture $textureName is an array; every adapter binds one texture a slot');
				if (textureSlots.exists(slot))
					throw new CommandException('shader: $name: texture $textureName at binding $slot, which ${textureSlots[slot]} has');
				textureSlots.set(slot, textureName);
				if (type != "sampler2D" && type != "sampler2DArray" && type != "samplerCube" && type != "sampler2DArrayShadow")
					throw new CommandException('shader: $name: texture $textureName is a $type (sampler2D, sampler2DArray, samplerCube or sampler2DArrayShadow)');
				textures.push({
					slot: slot,
					stage: stage,
					glslName: textureName,
					shadow: type == "sampler2DArrayShadow",
					cube: type == "samplerCube",
					data: fetchedOnly(listings.get(stage)).indexOf(textureName) >= 0,
					active: activeSamplers.indexOf(textureName) >= 0
				});
			}
		}
		blocks.sort((a, b) -> a.slot != b.slot ? a.slot - b.slot : (a.stage < b.stage ? -1 : a.stage > b.stage ? 1 : 0));
		textures.sort((a, b) -> a.slot - b.slot);
		return {
			attributes: attributes,
			attributeTypes: attributeTypes,
			activeAttributes: activeAttributes,
			blocks: blocks,
			textures: textures
		};
	}

	// The textures a stage's listing only ever fetches from (texelFetch: OpImageFetch through OpImage), never samples.
	static function fetchedOnly(listing:String):Array<String> {
		var names = new Map<String, String>(),
			loads = new Map<String, String>(),
			images = new Map<String, String>();
		var fetched = new Map<String, Bool>(),
			sampled = new Map<String, Bool>();
		var name = ~/Name (\d+)\s+"(\w+)"/,
			load = ~/^\s*(\d+):\s+\S+\s+Load (\d+)/,
			image = ~/^\s*(\d+):\s+\S+\s+Image (\d+)/;
		var use = ~/\s(ImageFetch|ImageSample\w*|ImageGather|ImageDrefGather|ImageQueryLod)\s+(\d+)/;
		for (line in listing.split("\n")) {
			if (name.match(line))
				names.set(name.matched(1), name.matched(2));
			else if (load.match(line))
				loads.set(load.matched(1), load.matched(2));
			else if (image.match(line))
				images.set(image.matched(1), loads.get(image.matched(2)));
			if (use.match(line)) {
				var op = use.matched(1), operand = use.matched(2);
				var variable = op == "ImageFetch" ? images.get(operand) : loads.get(operand);
				if (variable != null && names.exists(variable))
					(op == "ImageFetch" ? fetched : sampled).set(names.get(variable), true);
			}
		}
		return [for (texture in fetched.keys()) if (!sampled.exists(texture)) texture];
	}

	// SDL_GPU's dialects: each stage's resources bound at SDL_GPU's sets (blocks at their slots, textures numbered from 0 by slot within
	// each stage), then MSL and HLSL from that.
	static function sdlGpu(cross:String, scratch:String, modules:Map<String, Bytes>, described:Dynamic):Dynamic {
		var out:Dynamic = {spirv: {}, msl: {}, hlsl: {}};
		var calls = [];
		for (stage in ["vertex", "fragment"]) {
			var sets = SDL_GPU_SETS[stage];
			var textures:Array<Dynamic> = described.textures;
			var textureSlots = [for (t in textures) if (t.stage == stage) (t.slot : Int)];
			var rebound = Spirv.rebind(modules[stage], (storage, binding) -> {
				if (storage == Spirv.BLOCKS)
					return {set: sets.blocks, binding: binding};
				return {set: sets.textures, binding: textureSlots.indexOf(binding)};
			});
			var path = Path.join([scratch, '$stage-rebound.spv']);
			File.saveBytes(path, rebound);
			Reflect.setField(out.spirv, stage, haxe.crypto.Base64.encode(rebound));
			calls.push({program: cross, args: [path, "--msl", "--msl-version", "20100", "--msl-decoration-binding"]});
			calls.push({program: cross, args: [path, "--hlsl", "--shader-model", "51"]});
		}
		var results = Scratch.runAll(calls);
		var packing = ~/cbuffer ID \d+ \(name: (\w+)\), member index \d+ \(name: (\w+)\) cannot be expressed/;
		for (k => result in results)
			if (result.code != 0 && packing.match(result.out + result.err))
				throw new CommandException('shader: block ${packing.matched(1)}\'s ${packing.matched(2)} is laid out so Direct3D\'s constant buffers can\'t hold it '
					+ 'for SDL_GPU (a vector after a scalar in a struct, which std140 starts on 16 bytes and Direct3D packs beside it): '
					+ 'put the vector first, or pad before it');
		var outputs = [for (k => result in results) crossOutput(result, calls[k].args)];
		Reflect.setField(out.msl, "vertex", outputs[0]);
		Reflect.setField(out.hlsl, "vertex", outputs[1]);
		Reflect.setField(out.msl, "fragment", outputs[2]);
		Reflect.setField(out.hlsl, "fragment", outputs[3]);
		return out;
	}
	#end
}
