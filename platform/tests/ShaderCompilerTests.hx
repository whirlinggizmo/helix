import helix.platform.tools.CommandException;
import helix.platform.tools.ShaderCompiler;
import helix.platform.tools.ShaderTools;

/** Checks helix-platform's shader compiler on the interpreter, with the library alone: what it reflects (attributes by location, blocks at
	their declared size with their members, textures and their kinds, a texture only fetched never filtered, what's declared whether read
	or not), what it refuses and how it says so, its dialects, and SDL_GPU's bindings. Run by helix.py test; fetches glslang and builds
	SPIRV-Cross into the user's cache the first time. */
class ShaderCompilerTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function compile(vertex:String, fragment:String):CompiledShader
		return ShaderCompiler.compileText({name: "test.vert", text: vertex}, {name: "test.frag", text: fragment}, {glsl410: true, sdlGpu: true});

	// The message a compile refuses with.
	static function refusal(vertex:String, fragment:String):String {
		try {
			compile(vertex, fragment);
		} catch (error:CommandException) {
			return error.message;
		}
		return "";
	}

	static final VERTEX = "#version 450
layout(location = 0) in vec2 position;
layout(location = 1) in vec2 uv;
layout(location = 0) out vec2 v_uv;
void main() { gl_Position = vec4(position, 0.0, 1.0); v_uv = uv; }
";

	static final FRAGMENT = "#version 450
layout(location = 0) in vec2 v_uv;
layout(location = 0) out vec4 color;
layout(binding = 2) uniform params { float brightness; vec4 tint; mat4 turns[2]; };
layout(binding = 0) uniform sampler2D image;
layout(binding = 1) uniform samplerCube sky;
layout(binding = 2) uniform sampler2DArrayShadow shadows;
layout(binding = 3) uniform sampler2D table;
layout(binding = 4) uniform sampler2D unread;
void main() {
    vec4 c = texture(image, v_uv) * tint * brightness;
    c += texture(sky, vec3(v_uv, 1.0)) * texture(shadows, vec4(v_uv, 0.0, 0.5));
    c += texelFetch(table, ivec2(v_uv * 4.0), 0) + turns[1][0];
    color = c;
}
";

	static function main():Void {
		var compiled = compile(VERTEX, FRAGMENT);
		var source = compiled.source;
		// Attributes: the vertex stage's inputs, by location.
		check(source.attributes.join(",") == "position,uv", "Attributes by location: " + source.attributes);
		// The block: its binding and stage, its declared size in whole vec4s (4 + 12 padding + 16 + 128 = 160), named for GL by the block.
		check(source.uniformBlocks.length == 1, "One block");
		var block = source.uniformBlocks[0];
		check(block.slot == 2 && block.stage == "fragment" && block.size == 160 && block.vec4Count == 10 && block.glslName == "params",
			"The block's slot, stage, size and GL name: " + haxe.Json.stringify(block));
		var members = compiled.members.get("params");
		check(members.length == 3 && members[0].name == "brightness" && members[0].offset == 0 && members[1].name == "tint" && members[1].offset == 16
			&& members[2].name == "turns" && members[2].type == "mat4" && members[2].offset == 32 && members[2].count == 2,
			"Its members' std140 offsets and counts: "
			+ haxe.Json.stringify(members));
		// Textures: their kinds from their types; one only fetched is never filtered; one never read is still there.
		var byName = [for (t in source.textures) t.glslName => t];
		check(source.textures.length == 5, "Every declared texture, read or not");
		check(!byName["image"].shadow && !byName["image"].cube && !byName["image"].data, "A sampled 2D texture");
		check(byName["sky"].cube, "A cube's kind from samplerCube");
		check(byName["shadows"].shadow, "A shadow map's from sampler2DArrayShadow");
		check(byName["table"].data, "A texture only read by texelFetch is never filtered");
		check(!byName["unread"].data && byName["unread"].slot == 4, "A texture declared and not read keeps its binding");
		check([for (t in source.textures) t.slot].join(",") == "0,1,2,3,4", "Textures by slot");
		// The dialects: GL's flattened block, named for the block.
		check(source.glsl410.fragment.indexOf("uniform vec4 params[10];") >= 0, "GL 410 holds the block as one vec4 array");
		check(source.glsl300es.fragment.indexOf("uniform highp vec4 params[10];") >= 0
			|| source.glsl300es.fragment.indexOf("uniform vec4 params[10];") >= 0,
			"So does GLSL ES");
		check(source.sdlGpu.msl.vertex.indexOf("helix_main") >= 0, "SDL_GPU's vertex stage moves GL's clip depth after the program's main");
		// SDL_GPU's bindings: fragment textures in set 2 and blocks in set 3, numbered from 0 by slot.
		var scratch = helix.platform.tools.Scratch.make("helix-shader-test-");
		var spv = haxe.io.Path.join([scratch, "fragment.spv"]);
		sys.io.File.saveBytes(spv, haxe.crypto.Base64.decode(source.sdlGpu.spirv.fragment));
		var process = new sys.io.Process(ShaderTools.spirvCross(), [spv, "--reflect"]);
		var reflected:Dynamic = haxe.Json.parse(process.stdout.readAll().toString());
		process.close();
		sys.FileSystem.deleteFile(spv);
		sys.FileSystem.deleteDirectory(scratch);
		var ubos:Array<Dynamic> = reflected.ubos,
			textures:Array<Dynamic> = reflected.textures;
		check(ubos[0].set == 3 && ubos[0].binding == 0, "SDL_GPU: the fragment block in set 3 at 0");
		var bound = [for (t in textures) t.name => '${t.set}/${t.binding}'];
		check(bound["image"] == "2/0" && bound["sky"] == "2/1" && bound["shadows"] == "2/2" && bound["table"] == "2/3" && bound["unread"] == "2/4",
			"SDL_GPU: the fragment textures in set 2, by slot: " + bound);
		// Refusals, each saying what's wrong.
		var message = refusal(VERTEX, "#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = missing; }\n");
		check(message.indexOf("test.frag") >= 0 && message.indexOf(":3:") >= 0 && message.indexOf("missing") >= 0,
			"A compile error names the stage's file and line: " + message);
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 0) uniform texture2D t;\nlayout(binding = 0) uniform sampler s;\n" +
			"void main() { color = texture(sampler2D(t, s), vec2(0.0)); }\n");
		check(message.indexOf("combined sampler") >= 0, "A separate texture and sampler refused: " + message);
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 2) uniform p { float a; int b; };\nvoid main() { color = vec4(a + float(b)); }\n");
		check(message.indexOf("mixes") >= 0, "A block of floats and ints refused: " + message);
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 2) uniform p { float a[4]; };\nvoid main() { color = vec4(a[1]); }\n");
		check(message.indexOf("an array of float") >= 0, "An array of floats refused: " + message);
		message = refusal("#version 450\nlayout(location = 1) in vec2 position;\nvoid main() { gl_Position = vec4(position, 0.0, 1.0); }\n",
			"#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(1.0); }\n");
		check(message.indexOf("without gaps") >= 0, "Attribute locations with a gap refused: " + message);
		message = refusal("#version 450\nlayout(location = 0) in vec2 position;\nlayout(binding = 2) uniform a { vec4 x; };\n"
			+ "void main() { gl_Position = vec4(position, 0.0, 1.0) * x; }\n",
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 2) uniform b { vec4 y; };\nvoid main() { color = y; }\n");
		check(message.indexOf("binding 2") >= 0, "Two blocks at one binding refused: " + message);
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 4) uniform p { vec4 x; };\nvoid main() { color = x; }\n");
		check(message.indexOf("blocks 0 to 3") >= 0, "A block past the adapters' bindings refused: " + message);
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 12) uniform sampler2D t;\nvoid main() { color = texture(t, vec2(0.0)); }\n");
		check(message.indexOf("textures 0 to 11") >= 0, "A texture past the adapters' bindings refused: " + message);
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
