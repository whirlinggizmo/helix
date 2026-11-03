package helix.ray.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/** Compiles raylib's shaders as the program builds, through helix-services' shaders, so they run on every backend.

	A raylib shader is GLSL 330 (or 100, for the web) with raylib's names: the attributes `vertexPosition`, `vertexTexCoord`, `vertexNormal`,
	`vertexColor`, `vertexTangent`, `vertexTexCoord2`, and for skinning `vertexBoneIds` (raylib 5.5's name; `vertexBoneIndices`, 6.2's)
	and `vertexBoneWeights`, and a `mat4` of the instances' transforms for `DrawMeshInstanced` (raylib's example's `instanceTransform`,
	after the others, a location a column), loose uniforms such as `mvp` and `colDiffuse`, and the textures `texture0` to `texture2`.
	What raylib's GLSL needs before helix-services compiles it is done here: GLSL 100 written as 330 (`attribute`, `varying`,
	`gl_FragColor` and `texture2D`), a stage left out given rlgl's default, the attributes declared in raylib's order, so each takes
	the location rlgl gives it, and each array uniform in a block of its own, so the rest stay within the 4 KiB of a block SDL_GPU's
	Vulkan reads, and each uniform's initializer taken out, its value written when the shader is made (`load`), as GL sets it
	when it links. The rest is the service's: GL's form, loose uniforms gathered, every type in its block, and the vertex
	stage wrapped with a clip scale (`ShaderOptions.clipScale`), which the platform turns over in a pass into a render target, and to
	write a point size of 1 (`ShaderOptions.points`), so any shader can draw in rlgl's point mode, as GL draws points with any shader. */
class ShaderMacro {
	/** raylib's attributes, in the order their locations are given. */
	static final ATTRIBUTES = [
		"vertexPosition",
		"vertexTexCoord",
		"vertexNormal",
		"vertexColor",
		"vertexTangent",
		"vertexTexCoord2",
		"vertexBoneIds",
		"vertexBoneIndices",
		"vertexBoneWeights"
	];

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

	/** Returns the expression of a raylib shader compiled from two stages' text, either null for raylib's default.

		@param vsName  The vertex stage's name, for errors (its file's path, which a quoted include resolves beside).
		@param vs  Its text, or null.
		@param fsName  The fragment stage's name.
		@param fs  Its text, or null.
		@param pos  Where errors point.
		@param initials  Optional. Receives each uniform the stages give an initializer (`uniform vec2 scale = vec2(0.25, 0.45);`), its
			name and its value's numbers; the initializers are taken out of the text, which the service refuses them in. When omitted, an
			initializer is refused.
		@return  An expression of type `helix.services.shaders.Shader`. */
	public static function program(vsName:String, vs:Null<String>, fsName:String, fs:Null<String>, pos:Position,
			?initials:Array<{name:String, numbers:Array<Float>}>):Expr {
		var vertex = adapt(vs == null ? DEFAULT_VS : vs, true, vsName, pos),
			fragment = adapt(fs == null ? DEFAULT_FS : fs, false, fsName, pos);
		if (initials != null) {
			vertex = initialize(vertex, vsName, pos, initials);
			fragment = initialize(fragment, fsName, pos, initials);
		}
		var sent = [for (d in declarations(vertex)) if (d.kind == "out") d.name];
		for (d in declarations(fragment))
			if (d.kind == "in" && sent.indexOf(d.name) < 0)
				Context.error('$fsName: "${d.name}" comes in, but the vertex stage doesn\'t send it', pos);
		for (d in declarations(vertex))
			if (d.kind == "in" && ATTRIBUTES.indexOf(d.name) < 0 && d.type != "mat4")
				Context.error('$vsName: the attribute "${d.name}" isn\'t one raylib gives here (${ATTRIBUTES.join(", ")}, or a mat4 of the instances\' transforms, `DrawMeshInstanced`\'s)',
					pos);
		return helix.services.shaders.Shader.makeExpr({name: vsName, text: vertex}, {name: fsName, text: fragment}, {clipScale: true, points: true}, pos);
	}

	/** Returns the expression of a raylib shader loaded from two stages' text (`LoadShader`, `LoadShaderFromMemory`), either null for
		raylib's default: the shader made, and each uniform given an initializer in the GLSL set to it, as GL sets one when it links.

		@param vsName  The vertex stage's name, for errors.
		@param vs  Its text, or null.
		@param fsName  The fragment stage's name.
		@param fs  Its text, or null.
		@param pos  Where errors point.
		@return  An expression of type `helix.ray.Shader`. */
	public static function load(vsName:String, vs:Null<String>, fsName:String, fs:Null<String>, pos:Position):Expr {
		var initials = [];
		var shader = program(vsName, vs, fsName, fs, pos, initials);
		var made = macro @:privateAccess helix.ray.raylib.RModels.makeShader($shader);
		if (initials.length == 0)
			return made;
		var writes = [
			for (i in initials) {
				var numbers = [for (n in i.numbers) macro $v{n}];
				macro @:privateAccess shader.program.writeNamed($v{i.name}, ([$a{numbers}] : Array<Float>));
			}
		];
		return macro {
			var shader = $made;
			$b{writes};
			shader;
		};
	}

	// A stage with its uniforms' initializers taken out, each uniform's name and value added to initials. A value is a constant: numbers,
	// true and false, and GLSL's constructors of them (float, int, vec2, ivec3, mat4 and the rest), as GL evaluates it.
	static function initialize(text:String, name:String, pos:Position, initials:Array<{name:String, numbers:Array<Float>}>):String {
		var declaration = ~/^([ \t]*uniform\s+(?:(?:lowp|mediump|highp)\s+)?(\w+)\s+(\w+))\s*=\s*([^;]*);/gm;
		return declaration.map(text, r -> {
			var type = r.matched(2), uniform = r.matched(3);
			var numbers = evaluate(r.matched(4));
			if (numbers == null || numbers.length != components(type))
				Context.error('$name: uniform $uniform\'s initializer "${StringTools.trim(r.matched(4))}" isn\'t a constant of its type helix-ray reads (numbers, and GLSL\'s constructors of them); set it with SetShaderValue',
					pos);
			var known = false;
			for (i in initials)
				if (i.name == uniform)
					known = true;
			if (!known)
				initials.push({name: uniform, numbers: numbers});
			r.matched(1) + ";";
		});
	}

	// How many numbers a GLSL type holds: 0 for one an initializer isn't read for.
	static function components(type:String):Int {
		var scalar = ~/^(float|int|uint|bool|double)$/,
			vector = ~/^[ibud]?vec([234])$/,
			matrix = ~/^d?mat([234])$/;
		if (scalar.match(type))
			return 1;
		if (vector.match(type))
			return Std.parseInt(vector.matched(1));
		if (matrix.match(type)) {
			var n = Std.parseInt(matrix.matched(1));
			return n * n;
		}
		return 0;
	}

	// A constant expression's numbers, in GLSL's order (a matrix by columns), or null for one not read here.
	static function evaluate(expression:String):Null<Array<Float>> {
		var tokens = [];
		var token = ~/^\s*([0-9]+\.[0-9]*(?:[eE][-+]?[0-9]+)?[fF]?|\.[0-9]+(?:[eE][-+]?[0-9]+)?[fF]?|[0-9]+(?:[eE][-+]?[0-9]+)?[fFuU]?|\w+|[(),+-])/;
		var rest = expression;
		while (StringTools.trim(rest) != "") {
			if (!token.match(rest))
				return null;
			tokens.push(token.matched(1));
			rest = token.matchedRight();
		}
		var at = 0;
		function value():Null<Array<Float>> {
			if (at >= tokens.length)
				return null;
			var t = tokens[at++];
			if (t == "-" || t == "+") {
				var v = value();
				return v == null ? null : t == "-" ? [for (x in v) -x] : v;
			}
			if (t == "true" || t == "false")
				return [t == "true" ? 1 : 0];
			if (~/^[0-9.]/.match(t))
				return [Std.parseFloat(~/[fFuU]$/.replace(t, ""))];
			var size = components(t);
			if (size == 0 || at >= tokens.length || tokens[at] != "(")
				return null;
			at++;
			var args = [];
			while (true) {
				var v = value();
				if (v == null)
					return null;
				for (x in v)
					args.push(x);
				if (at >= tokens.length)
					return null;
				var next = tokens[at++];
				if (next == ")")
					break;
				if (next != ",")
					return null;
			}
			var integer = ~/^(int|uint|[iu]vec[234])$/.match(t),
				boolean = ~/^(bool|bvec[234])$/.match(t);
			var out:Array<Float> = if (args.length == 1 && size > 1) {
				var n = Std.int(Math.sqrt(size));
				if (~/mat/.match(t))
					[for (i in 0...size) i % (n + 1) == 0 ? args[0] : 0];
				else
					[for (_ in 0...size) args[0]];
			} else if (args.length >= size && (args.length == size || size == 1)) args.slice(0, size); else null;
			if (out == null)
				return null;
			return [
				for (x in out)
					boolean ? (x != 0 ? 1 : 0) : integer ? (x < 0 ? Math.ceil(x) : Math.floor(x)) : x
			];
		}
		var v = value();
		return v == null || at != tokens.length ? null : v;
	}

	static function rank(name:String):Int {
		var i = ATTRIBUTES.indexOf(name);
		return i < 0 ? 100 : i;
	}

	// A stage as GLSL 330: GLSL 100's words for GL 3's, and the vertex stage's attributes in raylib's order, each on a line one held, so a
	// line in an error is the file's.
	static function adapt(text:String, vertex:Bool, name:String, pos:Position):String {
		text = StringTools.replace(text, "\r\n", "\n");
		var version = ~/^[ \t]*#version[ \t]+(\d+)[^\n]*/m;
		var old = !version.match(text) || version.matched(1) == "100";
		if (!version.match(text))
			text = "#version 330\n#line 1\n" + text;
		else if (old)
			text = version.replace(text, "#version 330");
		if (old) {
			text = ~/^([ \t]*)attribute\b/gm.replace(text, "$1in");
			text = ~/^([ \t]*)varying\b/gm.replace(text, vertex ? "$1out" : "$1in");
			if (!vertex && ~/\bgl_Frag(Color|Data)\b/.match(text)) {
				text = ~/\bgl_FragColor\b/g.replace(text, "helix_fragColor");
				text = ~/\bgl_FragData\s*\[\s*0\s*\]/g.replace(text, "helix_fragColor");
				// After the version line, on the line it ends.
				text = ~/^([ \t]*#version[^\n]*)/m.replace(text, "$1\nout vec4 helix_fragColor;\n#line 2");
			}
		}
		text = ~/\b(texture2D|textureCube|texture2DProj)\s*\(/g.replace(text, "texture(");
		// Each array uniform in a block of its own, on its line, so the loose uniforms (raylib's matrices and colDiffuse) stay in the first
		// 4 KiB of their block, all SDL_GPU's Vulkan reads of one, however long the arrays (boneMatrices).
		text = ~/^([ \t]*)uniform\s+((?:(?:lowp|mediump|highp)\s+)?(\w+)\s+(\w+)\s*\[[^\]\n]+\])\s*;/gm.map(text,
			r -> StringTools.startsWith(r.matched(3), "sampler") ? r.matched(0) : '${r.matched(1)}uniform raylib_array_${r.matched(4)} { ${r.matched(2)}; };');
		if (vertex) {
			// The attributes in raylib's order, each in the line of one before.
			var input = ~/^[ \t]*in\s+(?:(?:lowp|mediump|highp)\s+)?(\w+)\s+(\w+)\s*;[ \t]*$/;
			var lines = text.split("\n"), at = [], found = [];
			for (i => line in lines)
				if (input.match(line)) {
					at.push(i);
					found.push({line: line, name: input.matched(2)});
				}
			var sorted = found.copy();
			sorted.sort((a, b) -> rank(a.name) - rank(b.name));
			for (k => i in at)
				lines[i] = sorted[k].line;
			text = lines.join("\n");
		}
		return text;
	}

	// A stage's global in and out declarations, read for the checks above.
	static function declarations(text:String):Array<{kind:String, type:String, name:String}> {
		var out = [];
		var declaration = ~/^[ \t]*(?:flat\s+|smooth\s+)?(in|out)\s+(?:(?:lowp|mediump|highp)\s+)?(\w+)\s+(\w+)\s*(?:\[[^\]]*\])?\s*;/m;
		var rest = ~/\/\*[\s\S]*?\*\//g.replace(text, "");
		rest = ~/\/\/[^\n]*/g.replace(rest, "");
		while (declaration.match(rest)) {
			out.push({kind: declaration.matched(1), type: declaration.matched(2), name: declaration.matched(3)});
			rest = declaration.matchedRight();
		}
		return out;
	}

	/** Returns the text a shader argument names: a constant string, or a file's text by its path, relative to the program's files
		(`helix-ray-files`); null for a null argument.

		@param e  The argument.
		@param file  Whether it names a file.
		@return  The text and a name for errors, or null. */
	public static function text(e:Expr, file:Bool):Null<{name:String, text:String}> {
		var value = constant(e);
		if (value == null)
			return null;
		if (!file)
			return {name: "shader text", text: value};
		var files = Context.definedValue("helix-ray-files");
		if (files == null)
			files = "web";
		var path = Path.join([files, value]);
		if (!FileSystem.exists(path))
			Context.error('LoadShader: $path not found (the file is read as the program builds, from -D helix-ray-files, default web)', e.pos);
		Context.registerModuleDependency(Context.getLocalModule(), path);
		return {name: value, text: File.getContent(path)};
	}

	/** Returns a string known as the program builds: a constant, or constants joined with +.

		@param e  The expression.
		@return  The string, or null for anything else. */
	public static function known(e:Expr):Null<String> {
		switch e.expr {
			case EConst(CString(s, _)):
				return s;
			case EConst(CIdent("null")):
				return null;
			case _:
		}
		return try fold(Context.typeExpr(e)) catch (_:Dynamic) null;
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
#end
