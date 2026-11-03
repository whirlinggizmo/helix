import helix.platform.ShaderBlock;
import helix.platform.ShaderMember;
import helix.platform.ShaderSource;
import helix.platform.tools.CommandException;
import helix.platform.tools.ShaderCompileOptions;
import helix.platform.tools.ShaderCompiler;
import helix.platform.tools.ShaderTools;

/** Checks helix-platform's shader compiler on the interpreter, with the library alone: what it reflects (attributes by location with
	their types and whether they're read, a matrix's columns too, blocks at their size with their members at std140 offsets, structs
	and arrays of structs, floats and integers together, textures and their kinds, a texture only fetched never filtered, what's
	declared whether read or not), GL's form and its loose uniforms gathered, a block both stages declare as one, gathered blocks, the
	clip-scale wrap, includes without an extension line, what it refuses and how it says so, its dialects, and SDL_GPU's bindings. Run
	by helix.py test; fetches glslang and builds SPIRV-Cross into the user's cache the first time. */
class ShaderCompilerTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static final ALL:ShaderCompileOptions = {glsl410: true, sdlGpu: true};

	static function compile(vertex:String, fragment:String, ?options:ShaderCompileOptions):ShaderSource
		return ShaderCompiler.compileText({name: "test.vert", text: vertex}, {name: "test.frag", text: fragment}, options == null ? ALL : options);

	// The message a compile refuses with.
	static function refusal(vertex:String, fragment:String, ?options:ShaderCompileOptions):String {
		try {
			compile(vertex, fragment, options);
		} catch (error:CommandException) {
			return error.message;
		}
		return "";
	}

	static function block(source:ShaderSource, name:String):ShaderBlock
		return Lambda.find(source.uniformBlocks, b -> b.glslName == name);

	static function member(b:ShaderBlock, name:String):ShaderMember
		return Lambda.find(b.members, m -> m.glslName == name);

	static function describe(m:ShaderMember):String
		return m == null ? "none" : '${m.glslName} ${m.type} @${m.offset} x${m.elementCount} /${m.stride}${m.active ? " read" : ""}';

	static final VERTEX = "#version 450
layout(location = 0) in vec2 position;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec3 unused;
layout(location = 0) out vec2 v_uv;
void main() { gl_Position = vec4(position, 0.0, 1.0); v_uv = uv; }
";

	static final FRAGMENT = "#version 450
layout(location = 0) in vec2 v_uv;
layout(location = 0) out vec4 color;
layout(binding = 2) uniform params { float brightness; vec4 tint; mat4 turns[2]; int mode; float spare; };
layout(binding = 0) uniform sampler2D image;
layout(binding = 1) uniform samplerCube sky;
layout(binding = 2) uniform sampler2DArrayShadow shadows;
layout(binding = 3) uniform sampler2D table;
layout(binding = 4) uniform sampler2D unread;
void main() {
    vec4 c = texture(image, v_uv) * tint * brightness * float(mode);
    c += texture(sky, vec3(v_uv, 1.0)) * texture(shadows, vec4(v_uv, 0.0, 0.5));
    c += texelFetch(table, ivec2(v_uv * 4.0), 0) + turns[1][0];
    color = c;
}
";

	static final STRUCTS = "#version 450
layout(location = 0) out vec4 color;
struct Light { int enabled; vec3 position; vec4 color; };
struct Surface { float roughness; bool metal; };
layout(binding = 1) uniform Scene { vec4 ambient; Light lights[4]; Surface surface; mat3 turn; uint flags; bvec2 switches; float weights[3]; } scene;
void main() { color = scene.ambient + scene.lights[1].color * scene.surface.roughness + vec4(scene.turn[0], scene.weights[2]); }
";

	static function main():Void {
		var message:String;
		var source = compile(VERTEX, FRAGMENT);
		// Attributes: the vertex stage's inputs, by location, their types, and which are read.
		check(source.attributes.join(",") == "position,uv,unused", "Attributes by location: " + source.attributes);
		check(source.attributeTypes.join(",") == "vec2,vec2,vec3", "Their types: " + source.attributeTypes);
		check(source.activeAttributes.join(",") == "0,1", "Those read: " + source.activeAttributes);
		// The block: its binding and stage, its size in whole vec4s, its members at std140 offsets, floats and integers together.
		check(source.uniformBlocks.length == 1, "One block");
		var params = source.uniformBlocks[0];
		check(params.slot == 2 && params.stage == "fragment" && params.size == 176 && params.glslName == "params",
			"The block's slot, stage, size and name: " + haxe.Json.stringify(params));
		check([for (m in params.members) describe(m)].join("; ") == "brightness float @0 x1 /16 read; tint vec4 @16 x1 /16 read; "
			+ "turns mat4 @32 x2 /64 read; mode int @160 x1 /16 read; spare float @164 x1 /16",
			"Its members: "
			+ [for (m in params.members) describe(m)].join("; "));
		// Textures: their kinds from their types; one only fetched is never filtered; one never read is still there, unread.
		var byName = [for (t in source.textures) t.glslName => t];
		check(source.textures.length == 5, "Every declared texture, read or not");
		check(!byName["image"].shadow && !byName["image"].cube && !byName["image"].data && byName["image"].active, "A sampled 2D texture");
		check(byName["sky"].cube, "A cube's kind from samplerCube");
		check(byName["shadows"].shadow, "A shadow map's from sampler2DArrayShadow");
		check(byName["table"].data, "A texture only read by texelFetch is never filtered");
		check(!byName["unread"].data && byName["unread"].slot == 4 && !byName["unread"].active, "A texture declared and not read keeps its binding");
		check([for (t in source.textures) t.slot].join(",") == "0,1,2,3,4", "Textures by slot");
		// The dialects: WebGL2 a std140 block, GL its members as uniforms of a struct.
		check(source.glsl300es.fragment.indexOf("layout(std140) uniform params") >= 0, "GLSL ES keeps the block: " + source.glsl300es.fragment);
		check(~/uniform params \w+;/.match(source.glsl410.fragment), "GL 410 holds it as a struct's uniforms: " + source.glsl410.fragment);
		check(source.sdlGpu.msl.vertex.indexOf("helix_gpu_main") >= 0, "SDL_GPU's vertex stage moves GL's clip depth after the program's main");
		// SDL_GPU's bindings: fragment textures in set 2, numbered from 0 by slot, and blocks in set 3 at their slots.
		var reflected = reflectSpirv(source.sdlGpu.spirv.fragment);
		var ubos:Array<Dynamic> = reflected.ubos,
			textures:Array<Dynamic> = reflected.textures;
		check(ubos[0].set == 3 && ubos[0].binding == 2, "SDL_GPU: the fragment block in set 3 at its slot");
		var bound = [for (t in textures) t.name => '${t.set}/${t.binding}'];
		check(bound["image"] == "2/0" && bound["sky"] == "2/1" && bound["shadows"] == "2/2" && bound["table"] == "2/3" && bound["unread"] == "2/4",
			"SDL_GPU: the fragment textures in set 2, by slot: " + bound);
		// Structs, arrays of structs, mat3, uint, bool and float arrays, under an instance name.
		var scene = block(compile(VERTEX, STRUCTS, {glsl410: true, sdlGpu: false}), "Scene");
		check([for (m in scene.members) describe(m)].join("; ") == "scene.ambient vec4 @0 x1 /16 read; scene.lights.enabled int @16 x4 /48; "
			+ "scene.lights.position vec3 @32 x4 /48; scene.lights.color vec4 @48 x4 /48 read; scene.surface.roughness float @208 x1 /16 read; "
			+ "scene.surface.metal bool @212 x1 /16; scene.turn mat3 @224 x1 /48 read; scene.flags uint @272 x1 /16; "
			+ "scene.switches bvec2 @280 x1 /16; scene.weights float @288 x3 /16 read",
			"A struct's fields and an array of structs' fields as members: "
			+ [for (m in scene.members) describe(m)].join("; "));
		check(scene.size == 336 && scene.slot == 1, "Its size and slot: " + scene.size);
		var packed = STRUCTS.split("struct Light { int enabled; vec3 position; vec4 color; };")
			.join("struct Light { vec3 position; int enabled; vec4 color; };");
		var sdl = block(compile(VERTEX, packed), "Scene");
		check(member(sdl, "scene.lights.enabled").offset == 28
			&& member(sdl, "scene.lights.color").offset == 32, "A struct Direct3D packs alike, for SDL_GPU");
		message = refusal(VERTEX, STRUCTS);
		check(message.indexOf("Direct3D") >= 0 && message.indexOf("lights") >= 0, "One it can't, refused for SDL_GPU: " + message);
		// A matrix input: a location a column, its name at the first, and the columns' type at the rest.
		var instanced = compile("#version 450\nlayout(location = 0) in vec2 position;\nlayout(location = 1) in mat4 placement;\n"
			+ "layout(location = 5) in vec3 tint;\nlayout(location = 0) out vec3 v_tint;\n"
			+ "void main() { gl_Position = placement * vec4(position, 0.0, 1.0); v_tint = tint; }\n",
			"#version 450\nlayout(location = 0) in vec3 v_tint;\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(v_tint, 1.0); }\n");
		check(instanced.attributes.join(",") == "position,placement,,,,tint"
			&& instanced.attributeTypes.join(",") == "vec2,mat4,vec4,vec4,vec4,vec3",
			"A mat4 input takes four locations: "
			+ instanced.attributes
			+ " "
			+ instanced.attributeTypes);
		glForm();
		bothStages();
		gathered();
		clipScale();
		points();
		semantics();
		linkage();
		floats();
		includes();
		// Refusals, each saying what's wrong.
		message = refusal("#version 450\nlayout(location = 0) in mat3 turn;\nlayout(location = 4) in vec3 position;\n"
			+ "void main() { gl_Position = vec4(turn * position, 1.0); }\n",
			"#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(1.0); }\n");
		check(message.indexOf("without gaps") >= 0, "A gap after a matrix's columns refused: " + message);
		message = refusal(VERTEX, "#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = missing; }\n");
		check(message.indexOf("test.frag") >= 0 && message.indexOf(":3:") >= 0 && message.indexOf("missing") >= 0,
			"A compile error names the stage's file and line: " + message);
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 0) uniform texture2D t;\nlayout(binding = 0) uniform sampler s;\n" +
			"void main() { color = texture(sampler2D(t, s), vec2(0.0)); }\n");
		check(message.indexOf("combined sampler") >= 0, "A separate texture and sampler refused: " + message);
		message = refusal("#version 450\nlayout(location = 1) in vec2 position;\nvoid main() { gl_Position = vec4(position, 0.0, 1.0); }\n",
			"#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(1.0); }\n");
		check(message.indexOf("without gaps") >= 0, "Attribute locations with a gap refused: " + message);
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 2) uniform a { vec4 x; };\nlayout(binding = 2) uniform b { vec4 y; };\nvoid main() { color = x + y; }\n");
		check(message.indexOf("binding 2") >= 0 && message.indexOf("test.frag:4") >= 0, "Two blocks at one binding of a stage refused: " + message);
		check(refusal("#version 450\nlayout(location = 0) in vec2 position;\nlayout(binding = 2) uniform a { vec4 x; };\n"
			+ "void main() { gl_Position = vec4(position, 0.0, 1.0) * x; }\n",
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 2) uniform b { vec4 y; };\nvoid main() { color = y; }\n") == "",
			"A block at one binding in each stage is taken: blocks are numbered by stage");
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 4) uniform p { vec4 x; };\nvoid main() { color = x; }\n");
		check(message.indexOf("blocks 0 to 3") >= 0, "A block past the adapters' bindings refused: " + message);
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 12) uniform sampler2D t;\nvoid main() { color = texture(t, vec2(0.0)); }\n");
		check(message.indexOf("textures 0 to 11") >= 0, "A texture past the adapters' bindings refused: " + message);
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nuniform sampler2D maps[4];\nvoid main() { color = texture(maps[1], vec2(0.0)); }\n");
		check(message.indexOf("maps is an array") >= 0 && message.indexOf("test.frag:3") >= 0, "A sampler array refused: " + message);
		message = refusal(VERTEX,
			"#version 450\nlayout(location = 0) out vec4 color;\nstruct L { float w[2]; };\n" +
			"layout(binding = 0) uniform B { L lights[2]; };\nvoid main() { color = vec4(lights[1].w[0]); }\n");
		check(message.indexOf("an array inside an array of structs") >= 0, "An array inside an array of structs refused: " + message);
		message = refusal(VERTEX, "#version 450\nlayout(location = 0) out vec4 color;\nuniform vec4 tint;\nvoid main() { color = tint; }\n");
		check(message.indexOf("outside a block") >= 0
			&& message.indexOf("test.frag:3") >= 0, "A loose uniform refused without looseUniforms: " + message);
		message = refusal("#version 410\nin vec2 p;\nvoid main() { gl_Position = vec4(p, 0.0, 1.0); }\n",
			"#version 410\nout vec4 color;\nvoid main() { color = vec4(1.0); }\n");
		check(message.indexOf("330 to 440") < 0 && message == "", "GLSL 410 is GL's form: " + message);
		message = refusal("#version 100\nvoid main() { gl_Position = vec4(0.0); }\n", "#version 100\nvoid main() { gl_FragColor = vec4(1.0); }\n");
		check(message.indexOf("#version 450, 300 es, or 330 to 440") >= 0, "GLSL ES 100 refused: " + message);
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	// GL's form: nothing placed in the source, loose uniforms in both stages gathered into helix_uniforms, the vertex stage's first.
	static function glForm():Void {
		var loose:ShaderCompileOptions = {glsl410: true, sdlGpu: true, looseUniforms: true};
		var source = compile("#version 330
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
out vec2 fragTexCoord;
out vec4 fragColor;
uniform mat4 mvp;
uniform float time;
void main() { fragTexCoord = vertexTexCoord; fragColor = vertexColor; gl_Position = mvp * vec4(vertexPosition, 1.0); }
", "#version 330
in vec4 fragColor;
in vec2 fragTexCoord;
out vec4 finalColor;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform float time;
struct Light { vec3 position; int enabled; vec4 color; };
uniform Light lights[2];
uniform sampler2D texture1;
void main() { finalColor = texture(texture0, fragTexCoord) * colDiffuse * fragColor * lights[1].color + texture(texture1, fragTexCoord) * time; }
", loose);
		check(source.attributes.join(",") == "vertexPosition,vertexTexCoord,vertexColor", "GL's form: attributes placed in declared order");
		var u = block(source, "helix_uniforms");
		check(u != null && u.stage == "both" && u.slot == 0, "Loose uniforms are one block both stages read: " + haxe.Json.stringify(u));
		check([for (m in u.members) describe(m)].join("; ") == "mvp mat4 @0 x1 /64 read; time float @64 x1 /16 read; colDiffuse vec4 @80 x1 /16 read; "
			+ "lights.position vec3 @96 x2 /32; lights.enabled int @108 x2 /32; lights.color vec4 @112 x2 /32 read",
			"The vertex stage's first, then the fragment's not already there: "
			+ [for (m in u.members) describe(m)].join("; "));
		check([for (t in source.textures) '${t.glslName}@${t.slot}'].join(",") == "texture0@0,texture1@1", "Loose textures placed in declared order");
		check(source.glsl300es.vertex.indexOf("uniform helix_uniforms") >= 0
			&& source.glsl300es.fragment.indexOf("uniform helix_uniforms") >= 0,
			"Both stages declare the block");
		var message = refusal("#version 330\nin vec2 p;\nlayout(location = 2) in vec2 q;\nvoid main() { gl_Position = vec4(p + q, 0.0, 1.0); }\n",
			"#version 330\nout vec4 color;\nvoid main() { color = vec4(1.0); }\n", loose);
		check(message.indexOf("test.vert:3") >= 0
			&& message.indexOf("binding or location") >= 0, "GL's form refuses a location: " + message);
		message = refusal("#version 330\nin vec2 p;\nuniform float roughness = 0.5;\nvoid main() { gl_Position = vec4(p, roughness, 1.0); }\n",
			"#version 330\nout vec4 color;\nvoid main() { color = vec4(1.0); }\n", loose);
		check(message.indexOf("initializer") >= 0 && message.indexOf("test.vert:3") >= 0, "An initializer refused: " + message);
		message = refusal("#version 330\nin vec2 p;\nuniform float scale;\nvoid main() { gl_Position = vec4(p, scale, 1.0); }\n",
			"#version 330\nout vec4 color;\nuniform vec2 scale;\nvoid main() { color = vec4(scale, 0.0, 1.0); }\n", loose);
		check(message.indexOf("scale") >= 0 && message.indexOf("vec2") >= 0, "One name of two types refused: " + message);
		message = refusal("#version 330\nin vec2 p;\nvoid main() { gl_Position = vec4(p, 0.0, 1.0); }\n",
			"#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(1.0); }\n", loose);
		check(message.indexOf("one form") >= 0, "Two forms refused: " + message);
		// The varyings matched by name, whatever the order.
		check(source.sdlGpu.spirv.fragment != null, "SDL_GPU's stages of GL's form");
	}

	// A block declared alike in both stages is one block, at one slot in each.
	static function bothStages():Void {
		var frame = "layout(std140) uniform Frame { mat4 viewProjection; vec4 time; };\n";
		var source = compile('#version 450\nlayout(location = 0) in vec3 p;\n$frame'
			+ "layout(binding = 1) uniform Model { mat4 model; };\nvoid main() { gl_Position = viewProjection * model * vec4(p, 1.0); }\n",
			'#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 0) uniform Look { vec4 tint; };\n$frame'
			+ "void main() { color = tint * time; }\n");
		var f = block(source, "Frame"),
			m = block(source, "Model"),
			l = block(source, "Look");
		check(f.stage == "both" && f.slot == 2 && m.stage == "vertex" && m.slot == 1 && l.stage == "fragment" && l.slot == 0,
			"A shared block takes the lowest slot free in both stages: " + haxe.Json.stringify([f.slot, m.slot, l.slot]));
		check(member(f, "viewProjection").active && member(f, "time").active, "Read in either stage is read");
		check(source.glsl410.vertex.indexOf("uniform Frame helix_block_Frame;") >= 0
			&& source.glsl410.fragment.indexOf("uniform Frame helix_block_Frame;") >= 0
			&& source.glsl410.vertex.indexOf("uniform Model helix_block_Model;") >= 0
			&& source.glsl410.fragment.indexOf("uniform Look helix_block_Look;") >= 0,
			"GL 410 names each block's uniform for the block, alike in both stages: "
			+ source.glsl410.vertex);
		var message = refusal('#version 450\nlayout(location = 0) in vec3 p;\n$frame' + "void main() { gl_Position = viewProjection * vec4(p, 1.0); }\n",
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(std140) uniform Frame { mat4 viewProjection; };\nvoid main() { color = vec4(1.0); }\n");
		check(message.indexOf("differently") >= 0, "One block declared two ways refused: " + message);
	}

	// Loose uniforms gathered by name into blocks of their own, after helix_uniforms.
	static function gathered():Void {
		var source = compile("#version 330\nin vec3 p;\nuniform mat4 mvp;\nuniform vec3 viewPos;\nvoid main() { gl_Position = mvp * vec4(p + viewPos, 1.0); }\n",
			"#version 330\nout vec4 color;\nstruct Light { vec3 position; vec4 color; };\nuniform Light lights[4];\nuniform vec4 ambient;\nuniform vec4 tint;\n"
			+ "uniform vec3 viewPos;\nvoid main() { color = lights[0].color * ambient * tint + vec4(viewPos, 1.0); }\n",
			{
				glsl410: false,
				sdlGpu: false,
				looseUniforms: true,
				gatheredBlocks: [{name: "Lights", uniforms: ["lights", "ambient", "viewPos"]}]
			});
		var lights = block(source, "Lights"),
			rest = block(source, "helix_uniforms");
		check(lights.stage == "both" && lights.slot == 1 && rest.slot == 0, "Gathered after helix_uniforms");
		check([for (m in lights.members) m.glslName].join(",") == "lights.position,lights.color,ambient,viewPos", "In the order given");
		check([for (m in rest.members) m.glslName].join(",") == "mvp,tint", "The rest in helix_uniforms");
		check(source.glsl300es.vertex.indexOf("struct Light") >= 0, "A gathered struct's declaration copied into the stage lacking it");
		var message = refusal("#version 330\nin vec3 p;\nvoid main() { gl_Position = vec4(p, 1.0); }\n",
			"#version 330\nout vec4 color;\nvoid main() { color = vec4(1.0); }\n", {
				glsl410: false,
				sdlGpu: false,
				looseUniforms: true,
				gatheredBlocks: [{name: "Lights", uniforms: ["lights"]}]
			});
		check(message.indexOf("neither stage") >= 0, "A gathered name nothing declares refused: " + message);
	}

	// The clip-scale wrap: a loose helix_clipScale the vertex stage's gl_Position is multiplied by after its main.
	static function clipScale():Void {
		var source = compile("#version 450\nlayout(location = 0) in vec2 p;\nlayout(binding = 0) uniform Placement { vec4 offsetScale; };\n"
			+ "void main() { gl_Position = vec4(p * offsetScale.zw, 0.0, 1.0); }\n",
			"#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(1.0); }\n", {
				glsl410: true,
				sdlGpu: false,
				clipScale: true
			});
		var u = block(source, "helix_uniforms");
		check(u != null && u.slot == 1 && member(u, "helix_clipScale").type == "vec4" && member(u, "helix_clipScale").active,
			"The clip scale a loose uniform in helix_uniforms: " + haxe.Json.stringify(u));
		check(source.glsl300es.vertex.indexOf("helix_clipScale") >= 0 && source.glsl300es.vertex.indexOf("helix_main") >= 0,
			"The vertex stage wrapped: " + source.glsl300es.vertex);
	}

	// GLSL's float literals in the fewest digits that read back as their 32-bit values, plain or with an exponent, in both GL forms; a
	// value with a short form written so, 1.0 kept.
	static function floats():Void {
		var source = compile("#version 450\nlayout(location = 0) in vec2 p;\nvoid main() { gl_Position = vec4(p * 0.055, 1e-7, 1.0); }\n",
			"#version 450\nlayout(location = 0) out vec4 color;\nlayout(binding = 0) uniform B { float k; };\n" +
			"void main() { color = vec4(k * 12.92, k * 0.0031308, k * 2.4, 1.0); }\n",
			{
				glsl410: true,
				sdlGpu: false
			});
		for (text in [source.glsl300es.vertex, source.glsl410.vertex])
			check(text.indexOf("0.055") >= 0 && text.indexOf("1e-7") >= 0 && text.indexOf("0.0549999") < 0, "Short vertex floats: " + text);
		for (text in [source.glsl300es.fragment, source.glsl410.fragment])
			check(text.indexOf("12.92") >= 0 && text.indexOf("0.0031308") >= 0 && text.indexOf("2.4") >= 0 && text.indexOf("2.40000") < 0
				&& text.indexOf("1.0") >= 0,
				"Short fragment floats: "
				+ text);
	}

	// The point size: written after main in every dialect, with the clip scale or without it, the result marked; HLSL in its compatibility
	// mode, which takes it; none without the option.
	static function points():Void {
		var vertex = "#version 450\nlayout(location = 0) in vec2 p;\nvoid main() { gl_Position = vec4(p, 0.0, 1.0); gl_PointSize = 4.0; }\n",
			fragment = "#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(1.0); }\n";
		for (clipScale in [false, true]) {
			var source = compile(vertex, fragment, {
				glsl410: true,
				sdlGpu: true,
				clipScale: clipScale,
				points: true
			});
			var written = ~/gl_PointSize = 1\.0/;
			check(source.points == true, 'Points marked (clip scale $clipScale)');
			check(written.match(source.glsl300es.vertex)
				&& written.match(source.glsl410.vertex)
				&& written.match(source.sdlGpu.msl.vertex),
				'The point size written after main (clip scale $clipScale): ${source.glsl300es.vertex}');
			check(source.glsl300es.vertex.lastIndexOf("gl_PointSize = 1.0") > source.glsl300es.vertex.lastIndexOf("gl_PointSize = 4.0"),
				'The program\'s own size replaced (clip scale $clipScale)');
			check(source.sdlGpu.hlsl.vertex.indexOf("gl_PointSize") >= 0, 'HLSL takes the size (clip scale $clipScale)');
			check((source.glsl300es.vertex.indexOf("helix_clipScale") >= 0) == clipScale, 'The clip scale as asked (clip scale $clipScale)');
		}
		var plain = compile("#version 450\nlayout(location = 0) in vec2 p;\nvoid main() { gl_Position = vec4(p, 0.0, 1.0); }\n", fragment, {
			glsl410: false,
			sdlGpu: false
		});
		check(plain.points != true && plain.glsl300es.vertex.indexOf("gl_PointSize") < 0, "No point size without the option");
	}

	// SDL_GPU's Direct3D 12 input layout names the attribute at location n TEXCOORDn: the HLSL reads each input by that name, a matrix's
	// columns each by its own location's, as Direct3D refuses a pipeline whose shader reads a name the layout doesn't give.
	static function semantics():Void {
		var source = compile("#version 450\nlayout(location = 0) in vec2 p;\nlayout(location = 1) in mat4 placed;\nlayout(location = 5) in vec4 tint;\n"
			+ "layout(location = 0) out vec4 v;\nvoid main() { gl_Position = placed * vec4(p, 0.0, 1.0); v = tint; }\n",
			"#version 450\nlayout(location = 0) in vec4 v;\nlayout(location = 0) out vec4 color;\nvoid main() { color = v; }\n");
		var hlsl = source.sdlGpu.hlsl.vertex;
		var input = hlsl.substring(hlsl.indexOf("struct SPIRV_Cross_Input"), hlsl.indexOf("};", hlsl.indexOf("struct SPIRV_Cross_Input")));
		var semantic = ~/:\s*(\w+)\s*;/g, found = [];
		semantic.map(input, r -> {
			found.push(r.matched(1));
			return "";
		});
		found.sort(Reflect.compare);
		check(found.join(",") == [for (n in 0...6) 'TEXCOORD$n'].join(","),
			"HLSL's inputs read TEXCOORD and the location, a matrix's columns each its own: " + input);
	}

	// Direct3D links a vertex stage's outputs to the fragment stage's inputs by register, in location order: SDL_GPU's fragment HLSL
	// reads every value the vertex stage writes, with its interpolation, though the fragment stage reads only some, and the GL
	// dialects' fragment stage stays as written.
	static function linkage():Void {
		var source = compile("#version 300 es\nin vec3 p;\nout vec3 worldPosition;\nout vec3 normal;\nflat out int kind;\nout vec2 texCoord;\n"
			+ "void main() { worldPosition = p; normal = p; kind = 1; texCoord = p.xy; gl_Position = vec4(p, 1.0); }\n",
			"#version 300 es\nprecision highp float;\nin vec2 texCoord;\nin vec3 worldPosition;\nout vec4 color;\n"
			+ "void main() { color = vec4(texCoord, worldPosition.x, 1.0); }\n");
		function members(hlsl:String, name:String):String {
			var at = hlsl.indexOf('struct $name');
			var struct = hlsl.substring(at, hlsl.indexOf("};", at)), found = [];
			~/(nointerpolation\s+)?\w+\s+\w+\s*:\s*(TEXCOORD\d+)\s*;/g.map(struct, r -> {
				found.push((r.matched(1) != null ? "flat " : "") + r.matched(2));
				return "";
			});
			return found.join(",");
		}
		var written = members(source.sdlGpu.hlsl.vertex, "SPIRV_Cross_Output"),
			read = members(source.sdlGpu.hlsl.fragment, "SPIRV_Cross_Input");
		check(written == "TEXCOORD0,TEXCOORD1,flat TEXCOORD2,TEXCOORD3" && read == written,
			'SDL_GPU\'s fragment HLSL reads every value the vertex stage writes, at its register: $written, $read');
		check(source.glsl300es.fragment.indexOf("helix_unread") < 0 && source.glsl300es.fragment.indexOf("normal") < 0,
			"The GL dialects' fragment stage reads only what it declares");
	}

	// A quoted include resolves beside the file and in the include directories, with no extension line.
	static function includes():Void {
		var scratch = helix.platform.tools.Scratch.make("helix-shader-include-");
		sys.io.File.saveContent(haxe.io.Path.join([scratch, "common.glsl"]), "#ifdef HELIX_VERTEX\nvec4 twice(vec4 v) { return v * 2.0; }\n#endif\n");
		var source = ShaderCompiler.compileText({
			name: "test.vert",
			text: "#version 450\n#include \"common.glsl\"\nlayout(location = 0) in vec4 p;\nvoid main() { gl_Position = twice(p); }\n"
		},
			{name: "test.frag", text: "#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(1.0); }\n"}, {
				glsl410: false,
				sdlGpu: false,
				includeDirectories: [scratch],
				defines: ["HELIX_VERTEX"]
			});
		check(source.glsl300es.vertex.indexOf("twice") >= 0, "An include without the extension line, under a define");
		var message = "";
		try {
			ShaderCompiler.compileText({
				name: "test.vert",
				text: "#version 450\n#include \"broken.glsl\"\nlayout(location = 0) in vec4 p;\nvoid main() { gl_Position = p; }\n"
			},
				{name: "test.frag", text: "#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(1.0); }\n"},
				{glsl410: false, sdlGpu: false, includeDirectories: [scratch]});
		} catch (e:CommandException)
			message = e.message;
		check(message.indexOf("broken.glsl") >= 0, "A missing include named: " + message);
		sys.io.File.saveContent(haxe.io.Path.join([scratch, "bad.glsl"]), "// a comment\nfloat f() { return nothing; }\n");
		message = "";
		try {
			ShaderCompiler.compileText({
				name: "test.vert",
				text: "#version 450\n#include \"bad.glsl\"\nlayout(location = 0) in vec4 p;\nvoid main() { gl_Position = p; }\n"
			},
				{name: "test.frag", text: "#version 450\nlayout(location = 0) out vec4 color;\nvoid main() { color = vec4(1.0); }\n"},
				{glsl410: false, sdlGpu: false, includeDirectories: [scratch]});
		} catch (e:CommandException)
			message = e.message;
		check(message.indexOf("bad.glsl:2") >= 0 && message.indexOf("nothing") >= 0, "An error in an include names its file and line: " + message);
		helix.platform.tools.Files.removeDirectory(scratch);
	}

	static function reflectSpirv(base64:String):Dynamic {
		var scratch = helix.platform.tools.Scratch.make("helix-shader-test-");
		var spv = haxe.io.Path.join([scratch, "stage.spv"]);
		sys.io.File.saveBytes(spv, haxe.crypto.Base64.decode(base64));
		var process = new sys.io.Process(ShaderTools.spirvCross(), [spv, "--reflect"]);
		var reflected:Dynamic = haxe.Json.parse(process.stdout.readAll().toString());
		process.close();
		helix.platform.tools.Files.removeDirectory(scratch);
		return reflected;
	}
}
