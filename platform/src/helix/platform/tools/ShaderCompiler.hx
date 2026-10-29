package helix.platform.tools;

import haxe.macro.Context;
import haxe.macro.Expr;
#if sys
import haxe.io.Bytes;
import haxe.io.Path;
import sys.io.File;
#end

/** Represents a member of a compiled program's uniform block: its name, GLSL type, byte offset (std140) and element count (1 unless an
	array). */
@:noCompletion
typedef ShaderMember = {
	final name:String;
	final type:String;
	final offset:Int;
	final count:Int;
}

/** Represents a compiled program: its `ShaderSource`; the GLSL type of each vertex attribute, by slot, for a caller packing vertices; and
	the members of each of its uniform blocks by the block's name, for a caller that writes the blocks by member name. */
@:noCompletion
typedef CompiledShader = {
	final source:helix.platform.ShaderSource;
	final attributeTypes:Array<String>;
	final members:Map<String, Array<ShaderMember>>;
}

/** Represents which dialects a compile makes besides GLSL ES 300 (WebGL2), which every `ShaderSource` carries: GLSL 410 (GL natively)
	and SDL_GPU's (SPIR-V, MSL and HLSL). */
@:noCompletion
typedef ShaderDialects = {
	final glsl410:Bool;
	final sdlGpu:Bool;
}

/** Provides compiling a program's GLSL into a `ShaderSource` for every graphics adapter: standard Vulkan-style GLSL 450, a vertex stage and
	a fragment stage, compiled once to SPIR-V by glslang and translated by SPIRV-Cross (`ShaderTools`), which also reflects it.

	What a program's source declares is what it binds: each uniform block at `layout(binding = n)`, at its declared size rounded up to whole
	`vec4`s, and each texture, a combined sampler at `layout(binding = n)`, whether the code reads it or not; blocks and textures are
	numbered apart. A texture's kind comes from its type (`sampler2D`, `sampler2DArray`, `samplerCube`, `sampler2DArrayShadow` for a shadow
	map); one the program only reads with `texelFetch` is never filtered (`ShaderTexture.data`). Every adapter binds uniform blocks 0 to 3
	and textures 0 to 11; a binding past them is refused. The vertex attributes are the vertex
	stage's inputs, at `layout(location = n)` from 0 without gaps; the values passed between the stages may leave their locations out. The
	vertex stage writes GL's clip space, depth -1 to 1, as every adapter takes it.

	For GL each block becomes one `vec4` array named for the block, so a block's members must be all floating point (`float`, `vecN`,
	`matN`) or all integer (`int`, `ivecN`), and an array member a `vec4`, `ivec4` or `mat4` array.

	```haxe
	var shader = graphics.createShader(ShaderCompiler.compile("triangle.vert", "triangle.frag"));
	``` */
class ShaderCompiler {
	// SDL_GPU's descriptor sets: textures and uniform blocks, by stage.
	static final SDL_GPU_SETS = ["vertex" => {textures: 0, blocks: 1}, "fragment" => {textures: 2, blocks: 3}];
	static final FLOATS = ["float", "vec2", "vec3", "vec4", "mat2", "mat3", "mat4"];
	static final INTEGERS = ["int", "ivec2", "ivec3", "ivec4"];
	static final ARRAYS = ["vec4", "ivec4", "mat4"];
	// The bindings every graphics adapter has: uniform blocks 0 to 3, textures 0 to 11.
	static inline final BLOCK_SLOTS = 4;
	static inline final TEXTURE_SLOTS = 12;

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
			var compiled = compileText({name: vertexPath, text: File.getContent(vertexPath)}, {name: fragmentPath, text: File.getContent(fragmentPath)},
				{glsl410: !js, sdlGpu: !js});
			var source:helix.platform.ShaderSource = compiled.source;
			return macro(${Context.makeExpr(source, pos)} : helix.platform.ShaderSource);
		} catch (error:CommandException) {
			return Context.error(error.message, pos);
		}
	}

	#if sys
	/** Compiles a program's two stages.

		@param vertex  The vertex stage: a name for messages (its file's path) and its GLSL.
		@param fragment  The fragment stage: a name for messages and its GLSL.
		@param dialects  The dialects to make.
		@param includes  Optional. Directories `#include` looks in, after the directory of each stage's file (its name, when that's a path), so
			a quoted include resolves beside the file. A source using `#include` declares `#extension GL_GOOGLE_include_directive : require`.
		@return  The program and its blocks' members.
		@throws CommandException  A stage doesn't compile (glslang's errors, named for the stage), or the program breaks a rule above. */
	@:noCompletion
	public static function compileText(vertex:{name:String, text:String}, fragment:{name:String, text:String}, dialects:ShaderDialects,
			?includes:Array<String>):CompiledShader {
		var glslang = ShaderTools.glslang(), cross = ShaderTools.spirvCross();
		var scratch = Scratch.make("helix-shader-");
		try {
			// Each batch's programs run at once: glslang for both stages (and SDL_GPU's vertex stage), then SPIRV-Cross on what it made.
			var compiles = [
				{stage: "vertex", suffix: "vert", given: vertex},
				{stage: "fragment", suffix: "frag", given: fragment}
			];
			if (dialects.sdlGpu)
				compiles.push({stage: "vertex-sdlgpu", suffix: "vert", given: {name: vertex.name, text: sdlGpuVertex(vertex)}});
			var calls = [];
			for (c in compiles) {
				var file = Path.join([scratch, '${c.stage}.${c.suffix}']);
				File.saveContent(file, c.given.text);
				calls.push(compileCall(glslang, file, Path.join([scratch, '${c.stage}.spv']), besides(c.given.name, includes)));
			}
			var listings = new Map<String, String>();
			for (k => result in Scratch.runAll(calls))
				listings.set(compiles[k].stage, checked(result, Path.join([scratch, '${compiles[k].stage}.${compiles[k].suffix}']), compiles[k].given.name));
			var spv = stage -> Path.join([scratch, '$stage.spv']);
			var gl = [
				"--flatten-ubo",
				"--glsl-emit-ubo-as-plain-uniforms",
				"--no-420pack-extension",
				"--no-support-nonzero-baseinstance"
			];
			var crossCalls = [];
			for (stage in ["vertex", "fragment"]) {
				crossCalls.push({program: cross, args: [spv(stage), "--reflect"]});
				crossCalls.push({program: cross, args: [spv(stage), "--version", "300", "--es"].concat(gl)});
				if (dialects.glsl410)
					crossCalls.push({program: cross, args: [spv(stage), "--version", "410", "--no-es"].concat(gl)});
			}
			var results = Scratch.runAll(crossCalls);
			var per = dialects.glsl410 ? 3 : 2;
			var reflected = [
				"vertex" => haxe.Json.parse(crossOutput(results[0], crossCalls[0].args)),
				"fragment" => haxe.Json.parse(crossOutput(results[per], crossCalls[per].args))
			];
			var fetched = [
				"vertex" => fetchedOnly(listings.get("vertex")),
				"fragment" => fetchedOnly(listings.get("fragment"))
			];
			// The rules first, so a program breaking one is told why rather than how a translation failed.
			var described = describe(reflected, fetched, vertex.name, fragment.name);
			var outputs = [for (k => result in results) crossOutput(result, crossCalls[k].args)];
			var source:Dynamic = {
				attributes: described.attributes,
				uniformBlocks: described.blocks,
				textures: described.textures,
				glsl300es: {vertex: outputs[1], fragment: outputs[per + 1]}
			};
			if (dialects.glsl410)
				source.glsl410 = {vertex: outputs[2], fragment: outputs[per + 2]};
			if (dialects.sdlGpu)
				source.sdlGpu = sdlGpu(cross, scratch, [
					"vertex" => File.getBytes(spv("vertex-sdlgpu")),
					"fragment" => File.getBytes(spv("fragment"))
				], described);
			Files.removeDirectory(scratch);
			return {source: source, attributeTypes: described.attributeTypes, members: described.members};
		} catch (error:haxe.Exception) {
			Files.removeDirectory(scratch);
			throw error;
		}
	}

	// glslang compiling a stage to SPIR-V at spv, its listing (-H) on the standard output, from which fetched textures are read.
	static function compileCall(glslang:String, file:String, spv:String, includes:Array<String>):{program:String, args:Array<String>} {
		var args = ["-V", "--target-env", "vulkan1.0", "--auto-map-locations", "-H", "-o", spv];
		for (directory in includes)
			args.push('-I$directory');
		return {program: glslang, args: args.concat([file])};
	}

	// A stage's listing, or its errors named for name rather than the scratch file compiled.
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

	// The program's attributes, blocks and textures from each stage's reflection, its rules checked.
	static function describe(reflected:Map<String, Dynamic>, fetched:Map<String, Array<String>>, vertexName:String, fragmentName:String):{
		attributes:Array<String>,
		attributeTypes:Array<String>,
		blocks:Array<Dynamic>,
		textures:Array<Dynamic>,
		members:Map<String, Array<ShaderMember>>
	} {
		var inputs:Array<Dynamic> = reflected.get("vertex").inputs == null ? [] : reflected.get("vertex").inputs;
		var attributes = [for (_ in 0...inputs.length) ""],
			attributeTypes = [for (_ in 0...inputs.length) ""];
		for (input in inputs) {
			var location:Int = input.location;
			if (location >= inputs.length || attributes[location] != "")
				throw new CommandException('shader: $vertexName: the vertex inputs\' locations must run from 0 without gaps');
			attributes[location] = input.name;
			attributeTypes[location] = input.type;
		}
		var blocks:Array<Dynamic> = [],
			textures:Array<Dynamic> = [],
			members = new Map<String, Array<ShaderMember>>();
		var blockSlots = new Map<Int, String>(),
			textureSlots = new Map<Int, String>();
		for (stage in ["vertex", "fragment"]) {
			var r:Dynamic = reflected.get(stage),
				name = stage == "vertex" ? vertexName : fragmentName;
			var separate:Array<Dynamic> = r.separate_images == null ? [] : r.separate_images;
			if (separate.length > 0 || r.separate_samplers != null)
				throw new CommandException('shader: $name: a texture and its sampler are one combined sampler (sampler2D and its kin), not separate');
			var ubos:Array<Dynamic> = r.ubos == null ? [] : r.ubos;
			for (ubo in ubos) {
				var slot:Int = ubo.binding, blockName:String = ubo.name;
				if (slot >= BLOCK_SLOTS)
					throw new CommandException('shader: $name: uniform block $blockName at binding $slot; the adapters bind blocks 0 to ${BLOCK_SLOTS - 1}');
				if (blockSlots.exists(slot))
					throw new CommandException('shader: $name: uniform block $blockName at binding $slot, which ${blockSlots[slot]} has');
				blockSlots.set(slot, blockName);
				var size = Std.int((ubo.block_size + 15) / 16) * 16;
				blocks.push({
					slot: slot,
					stage: stage,
					size: size,
					glslName: blockName,
					vec4Count: Std.int(size / 16)
				});
				members.set(blockName, flattened(Reflect.field(r.types, ubo.type), blockName, name));
			}
			var samplers:Array<Dynamic> = r.textures == null ? [] : r.textures;
			for (t in samplers) {
				var slot:Int = t.binding,
					textureName:String = t.name,
					type:String = t.type;
				if (slot >= TEXTURE_SLOTS)
					throw new CommandException('shader: $name: texture $textureName at binding $slot; the adapters bind textures 0 to ${TEXTURE_SLOTS - 1}');
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
					data: fetched.get(stage).indexOf(textureName) >= 0
				});
			}
		}
		blocks.sort((a, b) -> a.slot - b.slot);
		textures.sort((a, b) -> a.slot - b.slot);
		return {
			attributes: attributes,
			attributeTypes: attributeTypes,
			blocks: blocks,
			textures: textures,
			members: members
		};
	}

	// A block's members, checked to flatten into one vec4 array for GL.
	static function flattened(type:Dynamic, block:String, name:String):Array<ShaderMember> {
		var out:Array<ShaderMember> = [], floats = 0, integers = 0;
		var given:Array<Dynamic> = type.members;
		for (m in given) {
			var memberType:String = m.type, array:Array<Int> = m.array;
			if (FLOATS.indexOf(memberType) >= 0)
				floats++;
			else if (INTEGERS.indexOf(memberType) >= 0)
				integers++;
			else
				throw new CommandException('shader: $name: block $block\'s ${m.name} is a $memberType; a block holds float, vecN, matN, int or ivecN members');
			if (array != null && (array.length != 1 || ARRAYS.indexOf(memberType) < 0))
				throw new CommandException('shader: $name: block $block\'s ${m.name} is an array of $memberType; arrays are of vec4, ivec4 or mat4, one-dimensional');
			out.push({
				name: m.name,
				type: memberType,
				offset: m.offset,
				count: array == null ? 1 : array[0]
			});
		}
		if (floats > 0 && integers > 0)
			throw new CommandException('shader: $name: block $block mixes floating-point and integer members; GL holds a block as one vec4 or ivec4 array');
		return out;
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

	// The vertex stage as SDL_GPU's is compiled: the program's main renamed by the preprocessor (wherever it is, an include's too), the line
	// count kept, and a main after it moving GL's clip depth to SDL_GPU's.
	static function sdlGpuVertex(vertex:{name:String, text:String}):String {
		var version = ~/^[ \t]*#version[^\n]*\n/m;
		if (!version.match(vertex.text))
			throw new CommandException('shader: ${vertex.name}: the vertex stage starts with #version');
		var before = version.matchedLeft() + version.matched(0);
		return before
			+ "#define main helix_main\n#line "
			+ before.split("\n").length
			+ "\n"
			+ version.matchedRight()
			+
			"\n#undef main\n// GL's clip depth (-1..1) as SDL_GPU's (0..1).\nvoid main()\n{\n    helix_main();\n    gl_Position.z = (gl_Position.z + gl_Position.w) * 0.5;\n}\n";
	}

	// SDL_GPU's dialects: each stage's resources bound at SDL_GPU's sets (numbered from 0 by slot within each), then MSL and HLSL from that.
	static function sdlGpu(cross:String, scratch:String, modules:Map<String, Bytes>, described:Dynamic):Dynamic {
		var out:Dynamic = {spirv: {}, msl: {}, hlsl: {}};
		var calls = [];
		for (stage in ["vertex", "fragment"]) {
			var sets = SDL_GPU_SETS[stage];
			var blocks:Array<Dynamic> = described.blocks,
				textures:Array<Dynamic> = described.textures;
			var blockSlots = [for (b in blocks) if (b.stage == stage) (b.slot : Int)],
				textureSlots = [for (t in textures) if (t.stage == stage) (t.slot : Int)];
			var rebound = Spirv.rebind(modules[stage], (storage, binding) -> {
				if (storage == Spirv.BLOCKS)
					return {set: sets.blocks, binding: blockSlots.indexOf(binding)};
				return {set: sets.textures, binding: textureSlots.indexOf(binding)};
			});
			var path = Path.join([scratch, '$stage-rebound.spv']);
			File.saveBytes(path, rebound);
			Reflect.setField(out.spirv, stage, haxe.crypto.Base64.encode(rebound));
			calls.push({program: cross, args: [path, "--msl", "--msl-version", "20100", "--msl-decoration-binding"]});
			calls.push({program: cross, args: [path, "--hlsl", "--shader-model", "51"]});
		}
		var outputs = [for (k => result in Scratch.runAll(calls)) crossOutput(result, calls[k].args)];
		Reflect.setField(out.msl, "vertex", outputs[0]);
		Reflect.setField(out.hlsl, "vertex", outputs[1]);
		Reflect.setField(out.msl, "fragment", outputs[2]);
		Reflect.setField(out.hlsl, "fragment", outputs[3]);
		return out;
	}
	#end
}
