package helix.tool.shader;

import helix.tool.shader.JsonText;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import helix.tool.shared.CommandError;
import helix.tool.shared.AssetManifests;
import helix.tool.shared.Files;

/** An app's shader (.glsl) packed into a HeliX shader file (.hxshader): JSON holding its program for every graphics backend HeliX has (GLSL
	410 natively, GLSL ES 300 in the browser, compiled by sokol-shdc; and on request SDL_GPU's SPIR-V, MSL and HLSL from the GLSL 410, by
	GpuShaders), and what the program needs bound (attributes, uniform blocks and their members, textures). Programs load it as any asset
	(helix.graphics.Shaders) and the adapters build the program from it at run time.

	A shader is a fragment stage `@fs fs` that includes one framework block, which decides its kind and supplies the rest:

	- `@include_block helix_screen`: a screen effect, drawn over a whole finished frame (helix.graphics.ScreenEffect).
	- `@include_block helix_surface`: a material's surface on a Renderer3D (helix.render3d.Material3D.setShader): lit models, the stage's lights and
	  their shadows, the material's base color and textures, its hit flash and rim light (applied by helix_output), where it is on the model
	  at rest (helix_model_position, helix_model_normal: its own space before skinning and the hook, alike in every variant); optionally a
	  vertex hook, `@block vertex` defining `void helix_vertex(inout vec3 position, inout vec3 normal)` (model space, as posed, before placing).
	- `@include_block helix_sprite`: a sprite's (helix.graphics.SpriteEffect: Node2D.effect, Batch2D.effect, Sprite3D.effect): its texture,
	  region and tint, the texel size and the time (the kind's vertex stage and block are src/helix/graphics/shaders/effect2d.glsl's).

	A surface shader is packed with its variants: a skinned one (the same fragment stage over a vertex stage moving each vertex by its joints
	first), and, for a shader with a vertex hook or a `discard`, its shadow casters, static and skinned (the depth pass drawn with the hook,
	and the fragment stage run for what it discards, its output writing nothing), so its shadow moves and opens as it does; a shader with
	neither casts through the framework's depth program. A sprite shader is packed with a variant drawing a Renderer3D's sprites: the same
	fragment stage over the framework's sprite3d vertex stage, its output applying the sprite's alpha mode.

	Its own parameters are uniform blocks at binding 2 and up (float, vec2, vec3, vec4 and mat4 members, and arrays of vec4 and mat4), set by
	name, in either stage; its own textures follow the framework's (screen and sprite: from binding 1; surface: from binding 6, as 5 is the
	skinned variants' joint texture), each with a sampler at the same binding. Uniform blocks 0 and 1 are the framework's.

	The framework's half of each kind is GLSL in src/helix/tool/shader/kinds: screen.glsl (the screen kind's vertex stage and block), surface_vs.glsl
	(the surface kind's vertex stage, {name} it, {skin_inputs} and {skin_call} what its skinned one adds: surface_skin_inputs.glsl and
	SKIN_CALL, which src/helix/graphics/shaders/skinning.glsl supplies), surface_fs.glsl (the surface kind's fragment block less its output),
	surface_output.glsl (its output: rim light, hit flash, tone mapping and sRGB, or an HDR scene's light) and sprite3d_output.glsl (the
	sprite kind's output in its Renderer3D variant, applying the alpha mode). */
class ShaderPacker {
	/** The .hxshader format written (helix.graphics.Shader.FORMAT). */
	public static inline final FORMAT = 2;

	static final KINDS = ["helix_screen", "helix_surface", "helix_sprite"];
	static final VERTEX = [
		"helix_screen" => "helix_screen_vs",
		"helix_surface" => "helix_surface_vs",
		"helix_sprite" => "effect2d_vs"
	];
	static final SURFACE_ATTRIBUTES = [
		"position",
		"normal",
		"uv",
		"tangent",
		"i_model0",
		"i_model1",
		"i_model2",
		"i_normal0",
		"i_normal1",
		"i_normal2",
		"i_tint",
		"i_lights0",
		"i_lights1"
	];
	static final SPRITE3D_ATTRIBUTES = ["corner", "i_position", "i_size", "i_region", "i_right", "i_up", "i_tint"];
	static final ATTRIBUTES = [
		"helix_screen" => [],
		"helix_surface" => SURFACE_ATTRIBUTES,
		"helix_sprite" => ["position", "uv", "color", "region"]
	];
	// The first texture binding an app's own may use (a surface's 5 is its skinned variants' joint texture).
	static final FIRST_TEXTURE = ["helix_screen" => 1, "helix_surface" => 6, "helix_sprite" => 1];
	// The skinned vertex stage's call, moving the vertex by its joints before the hook.
	static final SKIN_CALL = "    skin(int(i_normal2.w + 0.5), joints, weights, moved, bent, turned);\n";
	// A shadow caster's output: the fragment stage runs for what it discards alone, writing nothing (the depth pass has no color).
	static final CASTER_OUTPUT = "void helix_output(vec3 color, float alpha) {}\n";
	static final NO_VERTEX_HOOK = "\n@block vertex\nvoid helix_vertex(inout vec3 position, inout vec3 normal) {}\n@end\n";
	// effect2d.glsl's helix_sprite output, which the Renderer3D variant's replaces.
	static final SPRITE_OUTPUT = "void helix_output(vec3 color, float alpha) { helix_frag_color = vec4(color, alpha); }";
	// std140: each member's size and alignment in bytes; an array's elements are each 16 aligned.
	static final TYPES = [
		"float" => [4, 4],
		"vec2" => [8, 8],
		"vec3" => [12, 16],
		"vec4" => [16, 16],
		"mat4" => [64, 16]
	];
	static final COMMENTS = ~/\/\/[^\n]*|\/\*[\s\S]*?\*\//g;

	/** The library's directory (dependencies.json, src/, src/helix/tool/shader/kinds). */
	public final root:String;

	var shdc:Null<String>;
	var kinds = new Map<String, String>();

	/** A packer for the library at root; shdc, sokol-shdc's path, is found when first needed when not given. */
	public function new(root:String, ?shdc:String) {
		this.root = root;
		this.shdc = shdc;
	}

	/** source (a .glsl file) packed into output (a .hxshader), with SDL_GPU's dialects only when sdlGpu. */
	public function pack(source:String, output:String, sdlGpu = false):Void
		Files.writeText(output, JsonText.indented(packed(source, sdlGpu)) + "\n");

	/** source packed: the .hxshader's content, with SDL_GPU's dialects only when sdlGpu, so other builds need neither glslang nor
		SPIRV-Cross. A surface shader carries its variants beside its program (skinned, and the shadow casters when it has a vertex hook or a
		discard), a sprite shader its sprite3D, each a program of its own over the same parameters. */
	public function packed(sourcePath:String, sdlGpu = false):JsonValue {
		var source = File.getContent(sourcePath);
		var found = KINDS.filter(k -> new EReg("@include_block\\s+" + k + "\\b", "").match(source));
		if (found.length != 1)
			fail('$sourcePath: include exactly one framework block (${KINDS.join(", ")})');
		var fragment = ~/@fs\s+fs\b([\s\S]*?)@end/;
		if (!fragment.match(source))
			fail('$sourcePath: the fragment stage must be "@fs fs"');
		var fragmentBody = fragment.matched(1);
		var kind = found[0];
		// The vertex hook block comes first, as the framework's vertex stage includes it.
		var hookBlock = ~/@block\s+vertex\b[\s\S]*?@end/;
		var hook:String, rest:String;
		if (hookBlock.match(source)) {
			if (kind != "helix_surface")
				fail('$sourcePath: only a surface shader has a vertex hook');
			hook = hookBlock.matched(0);
			rest = hookBlock.matchedLeft() + hookBlock.matchedRight();
		} else {
			hook = kind == "helix_surface" ? NO_VERTEX_HOOK : "";
			rest = source;
		}
		var programs:Array<{
			name:String,
			vs:String,
			fs:String,
			attributes:Array<String>
		}> = [
			{
				name: "shader",
				vs: VERTEX[kind],
				fs: "fs",
				attributes: ATTRIBUTES[kind]
			}
			];
		var extra = "";
		if (kind == "helix_surface") {
			var skinned = SURFACE_ATTRIBUTES.concat(["joints", "weights"]);
			programs.push({
				name: "skinned",
				vs: "helix_surface_skinned_vs",
				fs: "fs",
				attributes: skinned
			});
			if (needsCaster(source)) {
				programs.push({
					name: "caster",
					vs: "helix_surface_vs",
					fs: "helix_caster_fs",
					attributes: SURFACE_ATTRIBUTES
				});
				programs.push({
					name: "skinnedCaster",
					vs: "helix_surface_skinned_vs",
					fs: "helix_caster_fs",
					attributes: skinned
				});
				// The caster's fragment stage: the app's, over the caster's block (its output writes nothing).
				var body = ~/@include_block\s+helix_surface\b/.replace(fragmentBody, "@include_block helix_surface_caster");
				rest += '\n@fs helix_caster_fs$body@end\n';
			}
			extra = File.getContent(srcPath("src/helix/graphics/shaders/skinning.glsl")) + "\n";
		} else if (kind == "helix_sprite") {
			programs.push({
				name: "sprite3D",
				vs: "sprite3d_vs",
				fs: "helix_sprite3d_fs",
				attributes: SPRITE3D_ATTRIBUTES
			});
			// The variant's fragment stage: the app's, over the block whose output applies the sprite's alpha mode.
			var body = ~/@include_block\s+helix_sprite\b/.replace(fragmentBody, "@include_block helix_sprite_3d");
			rest += '\n@fs helix_sprite3d_fs$body@end\n';
		}
		var full = hook
			+ "\n"
			+ extra
			+ kindText(kind)
			+ "\n"
			+ rest
			+ "\n"
			+ [for (p in programs) '@program ${p.name} ${p.vs} ${p.fs}\n'].join("");
		var reflected = compile(sourcePath, full);
		var fields:Array<JsonField> = [
			{key: "helixShader", value: JInt(FORMAT)},
			{key: "kind", value: JString(kind.substr("helix_".length))},
			{key: "attributes", value: JArray([for (a in ATTRIBUTES[kind]) JString(a)])}
		];
		fields = fields.concat(described(sourcePath, source, kind, reflected.get("shader"), sdlGpu));
		for (p in programs)
			if (p.name != "shader")
				fields.push({
					key: p.name,
					value: JObject([{key: "attributes", value: JArray([for (a in p.attributes) JString(a)])}].concat(described(sourcePath, source, kind,
						reflected.get(p.name), sdlGpu)))
				});
		return JObject(fields);
	}

	/** Whether a surface shader's shadow differs from the framework caster's: it has a vertex hook (`@block vertex`, moving its vertices) or
		a `discard` (cutting holes), comments aside. */
	public static function needsCaster(source:String):Bool {
		var code = COMMENTS.replace(source, "");
		return ~/@block\s+vertex\b/.match(code) || ~/\bdiscard\b/.match(code);
	}

	/** The members of uniform block `block` in the app's source, with their std140 offsets: name, type, offset, count (1 unless an array). */
	public static function members(source:String, block:String):Array<{
		name:String,
		type:String,
		offset:Int,
		count:Int
	}> {
		var found = new EReg("uniform\\s+" + block + "\\s*\\{([\\s\\S]*?)\\}", "");
		if (!found.match(source))
			fail('uniform block $block not found in the source');
		var body = COMMENTS.replace(found.matched(1), "");
		var out = [], offset = 0;
		var member = ~/^(\w+)\s+(\w+)(?:\s*\[\s*(\d+)\s*\])?$/;
		for (part in body.split(";")) {
			var declaration = StringTools.trim(part);
			if (declaration == "")
				continue;
			if (!member.match(declaration) || !TYPES.exists(member.matched(1)))
				fail('unsupported member in $block: \'$declaration\' (float, vec2, vec3, vec4, mat4, and arrays of vec4 and mat4)');
			var kind = member.matched(1),
				name = member.matched(2),
				array = member.matched(3);
			var count = array == null ? 1 : Std.parseInt(array);
			if (array != null && kind != "vec4" && kind != "mat4")
				fail('$block: $name is an array of $kind; arrays must be of vec4 or mat4 (sokol-shdc\'s rule)');
			var size = TYPES[kind][0], align = TYPES[kind][1];
			if (array != null) {
				align = 16;
				size = kind != "mat4" ? 16 * count : 64 * count;
			}
			offset = Std.int((offset + align - 1) / align) * align;
			out.push({
				name: name,
				type: kind,
				offset: offset,
				count: count
			});
			offset += size;
		}
		return out;
	}

	// One program of the reflection (p) as the .hxshader holds it: its dialects, uniform blocks (the app's with their members) and textures,
	// with SDL_GPU's dialects when sdlGpu; its attributes come from the caller.
	function described(sourcePath:String, source:String, kind:String, p:Dynamic, sdlGpu:Bool):Array<JsonField> {
		var blocks:Array<Dynamic> = [];
		var reflectedBlocks:Array<Dynamic> = p.uniform_blocks == null ? [] : p.uniform_blocks;
		for (b in reflectedBlocks) {
			var uniforms:Array<Dynamic> = b.glsl_uniforms;
			if (uniforms.length != 1 || uniforms[0].type != "vec4")
				fail('$sourcePath: uniform block ${b.struct_name} must flatten to one vec4 array');
			var name:String = b.struct_name;
			var block:Dynamic = {
				slot: b.slot,
				stage: b.stage,
				size: b.size,
				glslName: uniforms[0].glsl_name,
				vec4s: uniforms[0].array_count,
				name: name
			};
			var framework = StringTools.startsWith(name, "helix_");
			if (!framework)
				block.members = members(source, name);
			if (framework ? b.slot >= 2 : b.slot < 2)
				fail('$sourcePath: uniform blocks 0 and 1 are the framework\'s; give $name binding 2 or more');
			blocks.push(block);
		}
		var views = new Map<Int, Dynamic>();
		var reflectedViews:Array<Dynamic> = p.views == null ? [] : p.views;
		for (v in reflectedViews)
			views.set(v.texture.slot, v.texture);
		var textures:Array<Dynamic> = [];
		var pairs:Array<Dynamic> = p.texture_sampler_pairs == null ? [] : p.texture_sampler_pairs;
		for (pair in pairs) {
			if (pair.view_slot != pair.sampler_slot)
				fail('$sourcePath: texture ${pair.view_name} and its sampler must share a binding');
			if (!StringTools.startsWith(pair.view_name, "helix_") && pair.view_slot < FIRST_TEXTURE[kind])
				fail('$sourcePath: texture ${pair.view_name} needs binding ${FIRST_TEXTURE[kind]} or more; the lower ones are the framework\'s');
			var view:Dynamic = views.exists(pair.view_slot) ? views.get(pair.view_slot) : {};
			textures.push({
				slot: pair.view_slot,
				stage: pair.stage,
				name: pair.view_name,
				glslName: pair.glsl_name,
				shadow: view.sample_type == "depth",
				cube: view.type == "cube",
				data: view.sample_type == "unfilterable_float"
			});
		}
		var textureSlots = [for (t in textures) (t.slot : Int)];
		for (slot in views.keys())
			if (textureSlots.indexOf(slot) < 0)
				fail('$sourcePath: every texture needs a sampler');
		for (slot in textureSlots)
			if (!views.exists(slot))
				fail('$sourcePath: every texture needs a sampler');
		var sortedBlocks = blocks.copy();
		haxe.ds.ArraySort.sort(sortedBlocks, (a, b) -> a.slot - b.slot);
		var sortedTextures = textures.copy();
		haxe.ds.ArraySort.sort(sortedTextures, (a, b) -> a.slot - b.slot);
		var dialects:Dynamic = p.dialects;
		var out:Array<JsonField> = [
			{key: "glsl410", value: stages(dialects.glsl410)},
			{key: "glsl300es", value: stages(dialects.glsl300es)},
			{key: "uniformBlocks", value: JArray([for (b in sortedBlocks) blockJson(b)])},
			{key: "textures", value: JArray([for (t in sortedTextures) textureJson(t)])}
		];
		if (sdlGpu)
			out.push({key: "sdlGpu", value: GpuShaders.translate(root, dialects.glsl410.vertex, dialects.glsl410.fragment, blocks, textures)});
		return out;
	}

	static function stages(dialect:Dynamic):JsonValue
		return JObject([
			{key: "vertex", value: JString(dialect.vertex)},
			{key: "fragment", value: JString(dialect.fragment)}
		]);

	static function blockJson(b:Dynamic):JsonValue {
		var fields:Array<JsonField> = [
			{key: "slot", value: JInt(b.slot)},
			{key: "stage", value: JString(b.stage)},
			{key: "size", value: JInt(b.size)},
			{key: "glslName", value: JString(b.glslName)},
			{key: "vec4s", value: JInt(b.vec4s)},
			{key: "name", value: JString(b.name)}
		];
		if (b.members != null) {
			var members:Array<Dynamic> = b.members;
			fields.push({
				key: "members",
				value: JArray([
					for (m in members)
						JObject([
							{key: "name", value: JString(m.name)},
							{key: "type", value: JString(m.type)},
							{key: "offset", value: JInt(m.offset)},
							{key: "count", value: JInt(m.count)}
						])
				])
			});
		}
		return JObject(fields);
	}

	static function textureJson(t:Dynamic):JsonValue {
		return JObject([
			{key: "slot", value: JInt(t.slot)},
			{key: "stage", value: JString(t.stage)},
			{key: "name", value: JString(t.name)},
			{key: "glslName", value: JString(t.glslName)},
			{key: "shadow", value: JBool(t.shadow)},
			{key: "cube", value: JBool(t.cube)},
			{key: "data", value: JBool(t.data)}
		]);
	}

	// full compiled by sokol-shdc (its C header and its reflection, both dialects): each program's reflection by name, with its dialects'
	// sources read in (dialects: {glsl410, glsl300es}, each {vertex, fragment}).
	function compile(sourcePath:String, full:String):Map<String, Dynamic> {
		if (shdc == null)
			shdc = Shdc.path(root);
		var scratch = Scratch.make("helix-shader-");
		try {
			var glsl = Path.join([scratch, "shader.glsl"]);
			File.saveContent(glsl, full);
			for (args in [
				["-o", Path.join([scratch, "shader.h"])],
				["-o", Path.join([scratch, "shader"]), "-f", "bare_yaml"]
			]) {
				var done = Scratch.run(shdc, ["-i", glsl].concat(args).concat(["-l", "glsl410:glsl300es", "--no-log-cmdline"]));
				if (done.code != 0)
					fail(StringTools.replace('$sourcePath: sokol-shdc failed\n${done.out}${done.err}', glsl, sourcePath));
			}
			var reflectionPath = Path.join([scratch, "shader_reflection.yaml"]);
			var reflection:Dynamic = Reflection.parse(File.getContent(reflectionPath), reflectionPath);
			var found = new Map<String, Dynamic>();
			var shaders:Array<Dynamic> = reflection.shaders;
			for (entry in shaders) {
				var programs:Array<Dynamic> = entry.programs;
				for (p in programs) {
					if (!found.exists(p.name)) {
						p.dialects = {};
						found.set(p.name, p);
					}
					Reflect.setField(found.get(p.name).dialects, entry.slang, {
						vertex: File.getContent(p.vertex_func.path),
						fragment: File.getContent(p.fragment_func.path)
					});
				}
			}
			Files.removeDirectory(scratch);
			return found;
		} catch (error:haxe.Exception) {
			Files.removeDirectory(scratch);
			throw error;
		}
	}

	// The framework's half of a kind: its vertex stages and blocks, the text sokol-shdc compiles before the app's.
	function kindText(kind:String):String {
		if (!kinds.exists(kind))
			kinds.set(kind, switch kind {
				case "helix_screen":
					kindFile("screen.glsl");
				case "helix_surface":
					var vs = kindFile("surface_vs.glsl");
					var fs = kindFile("surface_fs.glsl");
					surfaceVs(vs, "helix_surface_vs", "", "")
					+ surfaceVs(vs, "helix_surface_skinned_vs", kindFile("surface_skin_inputs.glsl"),
						SKIN_CALL) // The shadow map's kind, said once for both blocks declaring it.
					+ "\n@image_sample_type helix_shadow_texture depth\n@sampler_type helix_shadow_sampler comparison\n"
					+ "\n@block helix_surface"
					+ fs
					+ kindFile("surface_output.glsl")
					+ "@end\n"
					+ "\n@block helix_surface_caster"
					+ fs
					+ CASTER_OUTPUT
					+ "@end\n";
				default:
					spriteKind();
			});
		return kinds.get(kind);
	}

	static function surfaceVs(template:String, name:String, skinInputs:String, skinCall:String):String {
		return StringTools.replace(StringTools.replace(StringTools.replace(template, "{name}", name), "{skin_inputs}", skinInputs), "{skin_call}", skinCall);
	}

	// The sprite kind's half: effect2d.glsl's vertex stage and helix_sprite block, without its comment, fragment stage and program; and for
	// its variant, sprite3d.glsl's vertex stage and the block as helix_sprite_3d, its output applying the alpha mode.
	function spriteKind():String {
		var effect = srcPath("src/helix/graphics/shaders/effect2d.glsl");
		var text = File.getContent(effect);
		text = ~/@fs\s+effect2d_fs\b[\s\S]*?@end/.replace(text, "");
		text = ~/@program[^\n]*\n?/g.replace(text, "");
		text = text.substr(text.indexOf("@vs"));
		var blockPattern = ~/@block\s+helix_sprite\b[\s\S]*?@end/;
		if (!blockPattern.match(text))
			fail('$effect: no helix_sprite block');
		var block = blockPattern.matched(0);
		if (block.indexOf(SPRITE_OUTPUT) < 0)
			fail('$effect: helix_sprite\'s output must read "$SPRITE_OUTPUT", which its Renderer3D variant replaces');
		var block3d = StringTools.replace(~/@block\s+helix_sprite\b/.replace(block, "@block helix_sprite_3d"), SPRITE_OUTPUT, kindFile("sprite3d_output.glsl"));
		var vertex3d = ~/@vs\s+sprite3d_vs\b[\s\S]*?@end/;
		vertex3d.match(File.getContent(srcPath("src/helix/graphics/shaders/sprite3d.glsl")));
		return text + "\n" + vertex3d.matched(0) + "\n\n" + block3d + "\n";
	}

	function kindFile(name:String):String
		return File.getContent(Path.join([root, "src", "helix", "tool", "shader", "kinds", name]));

	function srcPath(relative:String):String
		return Path.join([root, relative]);

	// A packed shader with the GLSL 410 left out of each program, as a browser build reads only the GLSL ES.
	static function browserOnly(value:JsonValue):JsonValue {
		return switch value {
			case JObject(fields): JObject([
					for (f in fields)
						if (f.key != "glsl410") {key: f.key, value: browserOnly(f.value)}
				]);
			case JArray(items): JArray([for (item in items) browserOnly(item)]);
			case other: other;
		}
	}

	/** The newest change to what a library shader's packing reads besides its source (the framework's stages it includes, the kinds, this
		tool, and for SDL_GPU's dialects the pins of their translators): a packed library shader older than it is stale. In milliseconds. */
	public function toolStamp(sdlGpu:Bool):Float {
		var newest = 0.0;
		var directories = [
			Path.join([root, "src", "helix", "tool", "shader"]),
			Path.join([root, "src", "helix", "tool", "shader", "kinds"])
		];
		for (directory in directories)
			for (name in FileSystem.readDirectory(directory)) {
				var path = Path.join([directory, name]);
				if (!FileSystem.isDirectory(path))
					newest = Math.max(newest, FileSystem.stat(path).mtime.getTime());
			}
		var read = [
			"src/helix/graphics/shaders/skinning.glsl",
			"src/helix/graphics/shaders/effect2d.glsl",
			"src/helix/graphics/shaders/sprite3d.glsl"
		];
		if (sdlGpu)
			read.push("dependencies.json");
		for (relative in read)
			newest = Math.max(newest, FileSystem.stat(srcPath(relative)).mtime.getTime());
		return newest;
	}

	/** The shader library (src/helix/shader/*.glsl, or sources) packed into generated Haxe in out, so a class in helix.shader gets its
		shader with no load: <Name>Packed.hx, whose text() is the .hxshader's text, and PackedShaders.hx naming them all (for the dev loop's hot
		reload); with gpuOut (SDL_GPU builds), SDL_GPU's dialects too, as <Name>PackedSdlGpu.hx there, which text() returns in builds defining
		helix_sdl3_gpu. A shader is packed again only when its source or toolStamp is newer than its output; generated files whose source is
		gone are removed. Returns the stems packed. */
	public function packLibrary(out:String, ?gpuOut:String, ?sources:String):Array<String> {
		if (sources == null)
			sources = srcPath("src/helix/shader");
		Files.makeDirectory(out);
		var stems = [
			for (name in FileSystem.readDirectory(sources))
				if (StringTools.endsWith(name, ".glsl")) name.substr(0, name.length - 5)
		];
		stems.sort(Reflect.compare);
		var made = [];
		var outputs = [{directory: out, suffix: "Packed", sdlGpu: false}];
		if (gpuOut != null)
			outputs.push({directory: gpuOut, suffix: "PackedSdlGpu", sdlGpu: true});
		for (output in outputs) {
			Files.makeDirectory(output.directory);
			var wanted = [for (stem in stems) className(stem) + output.suffix];
			for (name in FileSystem.readDirectory(output.directory))
				if (StringTools.endsWith(name, output.suffix + ".hx") && wanted.indexOf(name.substr(0, name.length - 3)) < 0)
					FileSystem.deleteFile(Path.join([output.directory, name]));
			var stamp = toolStamp(output.sdlGpu);
			for (stem in stems) {
				var source = Path.join([sources, stem + ".glsl"]),
					name = className(stem);
				var target = Path.join([output.directory, name + output.suffix + ".hx"]);
				if (Files.isFile(target)
					&& FileSystem.stat(target).mtime.getTime() >= Math.max(FileSystem.stat(source).mtime.getTime(), stamp))
					continue;
				var whole = packed(source, output.sdlGpu);
				var text = JsonText.compact(whole);
				var full = Files.resolve(Sys.getCwd(), source),
					library = Files.resolve(Sys.getCwd(), root);
				var origin = StringTools.startsWith(full, library + "/") ? full.substr(library.length + 1) : Path.withoutDirectory(source);
				var lines = output.sdlGpu ? [
					'// Generated by src/helix/tool/shader/ShaderPacker.hx from $origin: its .hxshader with SDL_GPU\'s dialects, for builds defining helix_sdl3_gpu.',
					'class $name${output.suffix} {',
					" /** The .hxshader's text, with SDL_GPU's dialects. */",
					" public static function text():String",
					'  return ${JsonText.quote(text)};',
					"}"
				] : [
					'// Generated by src/helix/tool/shader/ShaderPacker.hx from $origin: its .hxshader, packed into the program.',
					'class $name${output.suffix} {',
					" /** The .hxshader's text (helix.graphics.Shader.fromText reads it): with SDL_GPU's dialects in builds defining helix_sdl3_gpu, and",
					"  in a browser build (the webgl2 backend) only the GLSL ES it reads. */",
					" public static function text():String",
					"  #if helix_sdl3_gpu",
					'  return ${name}PackedSdlGpu.text();',
					'  #elseif (helix_backend == "webgl2")',
					'  return ${JsonText.quote(JsonText.compact(browserOnly(whole)))};',
					"  #else",
					'  return ${JsonText.quote(text)};',
					"  #end",
					"}"
					];
				File.saveContent(target, lines.join("\n") + "\n");
				if (made.indexOf(stem) < 0)
					made.push(stem);
			}
		}
		var registry = Path.join([out, "PackedShaders.hx"]);
		var entries = [for (stem in stems) '"$stem" => () -> ${className(stem)}Packed.text()'].join(", ");
		var content = [
			"// Generated by src/helix/tool/shader/ShaderPacker.hx: the shader library packed into the program (src/helix/shader), by file stem.",
			"class PackedShaders {",
			" /** Each library shader's .hxshader text, by its file's stem: what a hot reload builds them again from. */",
			" public static function texts():Map<String, Void->String>",
			stems.length > 0 ? '  return [$entries];' : "  return new Map();",
			"}"
		].join("\n") + "\n";
		if (!Files.isFile(registry) || File.getContent(registry) != content)
			File.saveContent(registry, content);
		return made;
	}

	/** The Haxe class name of a library shader's file stem: its words capitalized, "color_lut" ColorLut. */
	public static function className(stem:String):String
		return [
			for (word in ~/[_-]/g.split(stem))
				if (word != "") word.charAt(0).toUpperCase() + word.substr(1)
		].join("");

	static function fail(message:String):Void
		throw new CommandError('shader: $message');

	// How often a watch looks for changes, in seconds.
	static inline final WATCH_POLL = 0.25;

	/** A game's shaders packed: those of the game in game, into out as <name>.hxshader, with SDL_GPU's dialects when sdlGpu; with watch, again as each
		changes (and new ones in shaders/ when none were named), until Ctrl+C. With current, a shader whose packed file is newer than its
		source (and carries SDL_GPU's dialects when they're asked for) isn't packed again, and finding none isn't a refusal. Returns the
		outputs written. */
	public function packShaders(game:String, files:Array<String>, out:String, sdlGpu:Bool, watch:Bool, current = false):Array<String> {
		var gameDirectory = Files.resolve(Sys.getCwd(), game);
		var target = Files.resolve(gameDirectory, out);
		var named = [for (f in files) Files.resolve(gameDirectory, f)];
		for (source in named)
			if (!Files.isFile(source))
				throw new CommandError('shader: ${Files.relative(source, gameDirectory)} is not a file');
		function sources():Array<String> {
			if (named.length > 0)
				return named;
			var directory = Path.join([gameDirectory, "shaders"]);
			if (!Files.isDirectory(directory))
				return [];
			var found = [
				for (name in FileSystem.readDirectory(directory))
					if (StringTools.endsWith(name, ".glsl") && Files.isFile(Path.join([directory, name]))) Path.join([directory, name])
			];
			found.sort(Reflect.compare);
			return found;
		}
		if (!watch && !current && sources().length == 0)
			throw new CommandError('shader: nothing to pack: no shaders/*.glsl in $gameDirectory and no file named');
		var written = [];
		var packed = new Map<String, Float>();
		function packChanged():Void {
			var changed = false;
			for (source in sources()) {
				var stamp = FileSystem.stat(source).mtime.getTime();
				if (packed.get(source) == stamp)
					continue;
				packed.set(source, stamp);
				var output = Path.join([target, Path.withoutExtension(Path.withoutDirectory(source)) + ".hxshader"]);
				if (current && isCurrent(source, output, sdlGpu))
					continue;
				try {
					pack(source, output, sdlGpu);
				} catch (error:CommandError) {
					if (!watch)
						throw error;
					Sys.println('shader: ${Path.withoutDirectory(source)} failed, kept as it was: ${error.message}');
					continue;
				}
				Sys.println('shader: ${Files.relative(source, gameDirectory)} -> ${Files.relative(output, gameDirectory)}');
				written.push(output);
				changed = true;
			}
			if (changed) {
				var manifests = manifestRoot(target, gameDirectory);
				if (manifests != null) {
					AssetManifests.rewrite(manifests, target);
					Sys.println('shader: manifests rewritten under ${Files.relative(manifests, gameDirectory)}');
				}
			}
		}
		packChanged();
		if (watch) {
			Sys.println('shader: watching ${named.length == 0 ? "shaders/" : named.length + " file(s)"} for changes; Ctrl+C stops');
			while (true) {
				Sys.sleep(WATCH_POLL);
				packChanged();
			}
		}
		return written;
	}

	// Whether output was packed from source since it last changed, with SDL_GPU's dialects when they're asked for.
	static function isCurrent(source:String, output:String, sdlGpu:Bool):Bool {
		if (!Files.isFile(output) || FileSystem.stat(output).mtime.getTime() < FileSystem.stat(source).mtime.getTime())
			return false;
		return !sdlGpu || sys.io.File.getContent(output).indexOf('"sdlGpu"') >= 0;
	}

	/** The root of the manifests that out is under: the highest directory from out up to game holding a manifest.json; null when there is none,
		as a game without a manifest needs nothing. */
	public static function manifestRoot(out:String, game:String):Null<String> {
		var directory = out, found:Null<String> = null;
		while (true) {
			if (Files.isFile(Path.join([directory, "manifest.json"])))
				found = directory;
			var parent = Path.directory(directory);
			if (directory == game || parent == directory || parent == "")
				return found;
			directory = parent;
		}
	}
}
