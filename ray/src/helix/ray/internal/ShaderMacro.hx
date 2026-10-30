package helix.ray.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/** Compiles raylib's shaders as the program builds, through helix-platform's shader pipeline, so they run on every backend.

	A raylib shader is GLSL 330 (or 100, for the web) with raylib's names: the attributes `vertexPosition`, `vertexTexCoord`, `vertexNormal`
	and `vertexColor`, loose uniforms such as `mvp` and `colDiffuse`, and the textures `texture0` to `texture2`. Each stage is turned into
	GLSL 450: the attributes and the values between the stages get locations; each stage's uniforms become one block of its own (an
	integer or a boolean held as a float, read back through a `#define`); the textures get bindings; the vertex stage scales its
	`gl_Position.y` by block 0, which the platform turns over in a pass into a render target (`ClipFlip.ClipScale`). */
class ShaderMacro {
	/** raylib's attributes, in the order their locations are given. */
	static final ATTRIBUTES = ["vertexPosition", "vertexTexCoord", "vertexNormal", "vertexColor"];

	/** raylib's default vertex stage, as its rlgl writes it. */
	public static final DEFAULT_VS = "#version 330
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
out vec2 fragTexCoord;
out vec4 fragColor;
uniform mat4 mvp;
void main() {
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    gl_Position = mvp*vec4(vertexPosition, 1.0);
}
";

	/** raylib's default fragment stage, as its rlgl writes it. */
	public static final DEFAULT_FS = "#version 330
in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
void main() {
    vec4 texelColor = texture(texture0, fragTexCoord);
    finalColor = texelColor*colDiffuse*fragColor;
}
";

	/** Returns the expression making a program from two stages' text, either null for raylib's default.

		@param vsName  The vertex stage's name, for errors.
		@param vs  Its text, or null.
		@param fsName  The fragment stage's name.
		@param fs  Its text, or null.
		@param pos  Where errors point.
		@return  An expression of type `helix.ray.internal.ProgramSource`. */
	public static function program(vsName:String, vs:Null<String>, fsName:String, fs:Null<String>, pos:Position):Expr {
		var vertex = vs == null ? DEFAULT_VS : vs,
			fragment = fs == null ? DEFAULT_FS : fs;
		var v = parse(vertex, true, vsName, pos),
			f = parse(fragment, false, fsName, pos);
		var varyings = [for (d in v.decls) if (d.kind == "out") d];
		for (d in f.decls)
			if (d.kind == "in" && !Lambda.exists(varyings, o -> o.name == d.name))
				Context.error('$fsName: "${d.name}" comes in, but the vertex stage doesn\'t send it', pos);
		var inputs = [for (d in v.decls) if (d.kind == "in") d];
		inputs.sort((a, b) -> rank(a.name) - rank(b.name));
		for (d in inputs)
			if (ATTRIBUTES.indexOf(d.name) < 0)
				Context.error('$vsName: the attribute "${d.name}" isn\'t one raylib gives here (${ATTRIBUTES.join(", ")})', pos);
		// Textures: texture0 to texture2 at their own numbers, the rest after, in the order declared.
		var samplers:Array<String> = [];
		for (stage in [v, f])
			for (d in stage.decls)
				if (d.kind == "uniform" && d.type.startsWith("sampler") && samplers.indexOf(d.name) < 0)
					samplers.push(d.name);
		var slots = new Map<String, Int>(), next = 3;
		for (name in samplers)
			slots.set(name, switch name {
				case "texture0": 0;
				case "texture1": 1;
				case "texture2": 2;
				case _: next++;
			});
		var vertexText = emit(v, true, inputs, varyings, slots, 1, vsName, pos);
		var fragmentText = emit(f, false, inputs, varyings, slots, 2, fsName, pos);
		var compiled = try {
			helix.platform.tools.ShaderCompiler.compileText({name: vsName, text: vertexText}, {name: fsName, text: fragmentText}, {
				glsl410: !Context.defined("js"),
				sdlGpu: !Context.defined("js")
			});
		} catch (e:haxe.Exception) {
			Context.error('$vsName, $fsName: ${e.message}\n--- vertex as compiled:\n$vertexText\n--- fragment as compiled:\n$fragmentText', pos);
		}
		var uniforms = [];
		for (block => members in compiled.members) {
			var slot = block == "raylib_vs" ? 1 : block == "raylib_fs" ? 2 : 0;
			if (slot == 0)
				continue;
			for (m in members) {
				var integer = m.name.startsWith("helix_i_"),
					boolean = m.name.startsWith("helix_b_");
				uniforms.push({
					name: integer || boolean ? m.name.substr(8) : m.name,
					block: slot,
					offset: m.offset,
					type: m.type,
					count: m.count,
					integer: integer || boolean});
			}
		}
		var source:helix.platform.ShaderSource = compiled.source;
		var textures = [for (name => slot in slots) {name: name, slot: slot}];
		var attributes:Array<String> = compiled.source.attributes;
		return macro({
			source: (${Context.makeExpr(source, pos)} : helix.platform.ShaderSource),
			attributes: $v{attributes},
			uniforms: $v{uniforms},
			textures: $v{textures}
		} : helix.ray.internal.ProgramSource);
	}

	static function rank(name:String):Int {
		var i = ATTRIBUTES.indexOf(name);
		return i < 0 ? 100 : i;
	}

	// A stage's declarations, taken out of its text, and what remains.
	static function parse(text:String, vertex:Bool, name:String, pos:Position):{decls:Array<Decl>, body:String, defines:String} {
		// Comments out first, so a declaration in one isn't read.
		text = ~/\/\*[\s\S]*?\*\//g.replace(text, "");
		text = ~/\/\/[^\n]*/g.replace(text, "");
		text = ~/^[ \t]*#version[^\n]*/m.replace(text, "");
		text = ~/^[ \t]*precision\s+\w+\s+\w+\s*;/gm.replace(text, "");
		var defines = new Map<String, String>();
		var define = ~/^[ \t]*#define\s+(\w+)\s+([^\n]+)/m;
		var scan = text;
		while (define.match(scan)) {
			defines.set(define.matched(1), StringTools.trim(define.matched(2)));
			scan = define.matchedRight();
		}
		var decls:Array<Decl> = [];
		var declaration = ~/^[ \t]*(attribute|varying|in|out|uniform)\s+(?:(?:lowp|mediump|highp|flat|smooth)\s+)*(\w+)\s+(\w+)\s*(?:\[\s*(\w+)\s*\])?\s*;[ \t]*$/m;
		var body = new StringBuf();
		while (declaration.match(text)) {
			body.add(declaration.matchedLeft());
			var kind = declaration.matched(1), size = declaration.matched(4);
			kind = switch kind {
				case "attribute": "in";
				case "varying": vertex ? "out" : "in";
				case k: k;
			}
			var count = 1;
			if (size != null) {
				var value = defines.exists(size) ? defines.get(size) : size;
				var n = Std.parseInt(value);
				if (n == null)
					Context.error('$name: the array "${declaration.matched(3)}" is sized by "$size", which isn\'t a number', pos);
				count = n;
			}
			decls.push({
				kind: kind,
				type: declaration.matched(2),
				name: declaration.matched(3),
				count: count,
				sized: size != null
			});
			text = declaration.matchedRight();
		}
		body.add(text);
		return {decls: decls, body: body.toString(), defines: ""};
	}

	// A stage as GLSL 450.
	static function emit(stage:{decls:Array<Decl>, body:String, defines:String}, vertex:Bool, inputs:Array<Decl>, varyings:Array<Decl>,
			slots:Map<String, Int>, block:Int, name:String, pos:Position):String {
		var out = new StringBuf();
		out.add("#version 450\n");
		if (vertex)
			for (i => d in inputs)
				out.add('layout(location = $i) in ${d.type} ${d.name};\n');
		for (i => d in varyings)
			if (vertex || Lambda.exists(stage.decls, x -> x.kind == "in" && x.name == d.name))
				out.add('layout(location = $i) ${vertex ? "out" : "in"} ${d.type} ${d.name};\n');
		var body = stage.body;
		if (!vertex) {
			var output = Lambda.find(stage.decls, d -> d.kind == "out");
			if (output != null)
				out.add('layout(location = 0) out ${output.type} ${output.name};\n');
			else {
				out.add("layout(location = 0) out vec4 helix_fragColor;\n");
				body = ~/\bgl_FragColor\b/g.replace(body, "helix_fragColor");
				body = ~/\bgl_FragData\s*\[\s*0\s*\]/g.replace(body, "helix_fragColor");
			}
		}
		body = ~/\b(texture2D|textureCube|texture2DProj)\s*\(/g.replace(body, "texture(");
		if (vertex)
			out.add("layout(binding = 0) uniform helix_flip { vec4 helix_clip; };\n");
		var values = [
			for (d in stage.decls)
				if (d.kind == "uniform" && !d.type.startsWith("sampler")) d
		];
		var reads = new StringBuf();
		if (values.length > 0) {
			out.add('layout(binding = $block) uniform raylib_${vertex ? "vs" : "fs"} {\n');
			for (d in values) {
				var array = d.sized ? '[${d.count}]' : "";
				switch d.type {
					case "int" | "ivec2" | "ivec3" | "ivec4" | "bool" | "bvec2" | "bvec3" | "bvec4":
						if (d.sized)
							Context.error('$name: "${d.name}" is an array of ${d.type}; only float arrays of vec4 or mat4 are held here', pos);
						var floatType = d.type.length == 3 || d.type == "bool" ? "float" : "vec" + d.type.charAt(d.type.length - 1);
						var prefix = d.type.startsWith("b") ? "helix_b_" : "helix_i_";
						out.add('    $floatType $prefix${d.name};\n');
						reads.add('#define ${d.name} ${d.type}($prefix${d.name})\n');
					case "float" | "vec2" | "vec3" | "vec4" | "mat2" | "mat3" | "mat4":
						if (d.sized && d.type != "vec4" && d.type != "mat4")
							Context.error('$name: "${d.name}" is an array of ${d.type}; only arrays of vec4 or mat4 are held here', pos);
						out.add('    ${d.type} ${d.name}$array;\n');
					case t:
						Context.error('$name: the uniform "${d.name}" is a $t; a struct or other type isn\'t held here yet', pos);
				}
			}
			out.add("};\n");
		}
		for (d in stage.decls)
			if (d.kind == "uniform" && d.type.startsWith("sampler"))
				out.add('layout(binding = ${slots.get(d.name)}) uniform ${d.type} ${d.name};\n');
		out.add(reads.toString());
		if (vertex) {
			var start = body.indexOf("void main");
			var open = start < 0 ? -1 : body.indexOf("{", start);
			if (open < 0)
				Context.error('$name: no main', pos);
			var depth = 0, close = -1;
			for (i in open...body.length) {
				var c = body.charAt(i);
				if (c == "{")
					depth++;
				else if (c == "}" && --depth == 0) {
					close = i;
					break;
				}
			}
			if (close < 0)
				Context.error('$name: main isn\'t closed', pos);
			body = body.substring(0, close) + "    gl_Position.y *= helix_clip.y;\n" + body.substring(close);
		}
		out.add(body);
		return out.toString();
	}

	/** Returns the text a shader argument names: a constant string, or a file's text by its path, relative to the program's files
		(`ray-files`); null for a null argument.

		@param e  The argument.
		@param file  Whether it names a file.
		@return  The text and a name for errors, or null. */
	public static function text(e:Expr, file:Bool):Null<{name:String, text:String}> {
		var value = constant(e);
		if (value == null)
			return null;
		if (!file)
			return {name: "shader text", text: value};
		var files = Context.definedValue("ray-files");
		if (files == null)
			files = "web";
		var path = Path.join([files, value]);
		if (!FileSystem.exists(path))
			Context.error('LoadShader: $path not found (the file is read as the program builds, from -D ray-files, default web)', e.pos);
		Context.registerModuleDependency(Context.getLocalModule(), path);
		return {name: value, text: File.getContent(path)};
	}

	// A constant string, a null, or one made of constants with +: what the program builds with.
	static function constant(e:Expr):Null<String> {
		switch e.expr {
			case EConst(CIdent("null")):
				return null;
			case EConst(CString(s, _)):
				return s;
			case _:
		}
		var typed = Context.typeExpr(e);
		var value = fold(typed);
		if (value == null)
			Context.error("A shader is compiled as the program builds, so its file name or text must be known then: a constant string, or "
				+ "constants joined with +",
				e.pos);
		return value;
	}

	static function fold(t:TypedExpr):Null<String> {
		return switch t.expr {
			case TConst(TString(s)): s;
			case TConst(TInt(i)): Std.string(i);
			case TConst(TNull): null;
			case TParenthesis(inner) | TCast(inner, _) | TMeta(_, inner): fold(inner);
			case TBinop(OpAdd, a, b): var x = fold(a), y = fold(b); x == null || y == null ? null : x + y;
			case TField(_, FStatic(_, field)):
				var f = field.get();
				var expr = f.expr();
				expr == null ? null : fold(expr);
			case _: null;
		}
	}
}

private typedef Decl = {
	final kind:String;
	final type:String;
	final name:String;
	final count:Int;
	final sized:Bool;
}
#end
