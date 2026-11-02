package helix.platform.tools;

/** A declaration at a stage's top level, as the text step reads it from glslang's preprocessed output. */
@:noCompletion
typedef ShaderDeclaration = {
	/** struct, block, uniform, texture, in, out, function or other. */
	final kind:String;

	/** The statement's first and past-last character. */
	final start:Int;

	final end:Int;

	/** The declared name (a struct's, a block's, a variable's). */
	final name:String;

	/** A block's instance name, or "". */
	final instance:String;

	/** The type as written, its precision with it (`highp vec4`, `Light`). */
	final type:String;

	/** The array suffix as written (`[4]`), or "". */
	final array:String;

	/** The layout qualifier's binding or location, or null. */
	final binding:Null<Int>;

	final location:Null<Int>;

	/** Whether a layout qualifier names binding or location. */
	final placed:Bool;

	/** Whether the declarator has an initializer. */
	final initialized:Bool;

	/** Whether the statement declares more than one name. */
	final shared:Bool;

	/** The names a struct's or a block's members name as types. */
	final uses:Array<String>;
}

/** The shader compiler's text step: reading a stage's top-level declarations from glslang's preprocessed output (`-E`), and rewriting it
	so every resource is placed (bindings and locations written out, loose uniforms gathered into blocks), each rewrite on the line it
	replaces so a line in an error stays the file's. Anything it can't read as a declaration it leaves to glslang, which compiles and
	validates the result. */
@:noCompletion
class ShaderText {
	static final QUALIFIERS = [
		"uniform",
		"in",
		"out",
		"attribute",
		"varying",
		"flat",
		"smooth",
		"noperspective",
		"centroid",
		"sample",
		"patch",
		"const",
		"highp",
		"mediump",
		"lowp",
		"precise",
		"invariant",
		"buffer",
		"shared",
		"coherent",
		"volatile",
		"restrict",
		"readonly",
		"writeonly"
	];

	/** The text. */
	public final text:String;

	/** Its stage's name, for messages. */
	public final name:String;

	/** The declarations, in order. */
	public final declarations:Array<ShaderDeclaration> = [];

	/** The `#version` line's start, or -1 for none. */
	public var versionStart(default, null) = -1;

	/** The `#version` line's end. */
	public var versionEnd(default, null) = -1;

	/** The version's number. */
	public var version(default, null) = 0;

	/** Whether the version is an ES one. */
	public var es(default, null) = false;

	// Each line's start, and the file and line number it stands for (#line markers followed).
	final lineStarts:Array<Int> = [];
	final lineFiles:Array<String> = [];
	final lineNumbers:Array<Int> = [];
	final edits:Array<{
		at:Int,
		remove:Int,
		insert:String,
		rank:Int
	}> = [];

	/** Reads a stage's preprocessed text.

		@param text  glslang's `-E` output.
		@param name  The stage's name, for messages. */
	public function new(text:String, name:String) {
		this.text = text;
		this.name = name;
		lines();
		statements();
	}

	/** Returns where a position is, as `file:line`. */
	public function where(at:Int):String {
		var low = 0, high = lineStarts.length - 1;
		while (low < high) {
			var mid = (low + high + 1) >> 1;
			if (lineStarts[mid] <= at)
				low = mid;
			else
				high = mid - 1;
		}
		return '${lineFiles[low]}:${lineNumbers[low]}';
	}

	/** Throws a refusal naming where a declaration is. */
	public function refuse(at:Int, why:String):Dynamic
		throw new CommandException('shader: ${where(at)}: $why');

	// The lines, the version, and the #line markers glslang wrote (`#line N "file"` or `#line N`): the line after a marker is N.
	function lines():Void {
		var file = name, number = 1, at = 0;
		var marker = ~/^[ \t]*#[ \t]*line[ \t]+(\d+)(?:[ \t]+"([^"]*)")?/;
		var versionLine = ~/^[ \t]*#[ \t]*version[ \t]+(\d+)(?:[ \t]+(\w+))?/;
		while (at <= text.length) {
			var end = text.indexOf("\n", at);
			if (end < 0)
				end = text.length;
			var line = text.substring(at, end);
			lineStarts.push(at);
			lineFiles.push(file);
			lineNumbers.push(number);
			if (marker.match(line)) {
				number = Std.parseInt(marker.matched(1));
				if (marker.matched(2) != null)
					file = marker.matched(2);
			} else {
				if (versionStart < 0 && versionLine.match(line)) {
					versionStart = at;
					versionEnd = end;
					version = Std.parseInt(versionLine.matched(1));
					es = versionLine.matched(2) == "es";
				}
				number++;
			}
			at = end + 1;
		}
	}

	static inline function isIdentifierStart(c:Int):Bool
		return c == "_".code || (c >= "a".code && c <= "z".code) || (c >= "A".code && c <= "Z".code);

	static inline function isIdentifierPart(c:Int):Bool
		return isIdentifierStart(c) || (c >= "0".code && c <= "9".code);

	// The top-level statements: each run to its `;` at depth 0, or a function's body's closing brace; directives skipped.
	function statements():Void {
		var at = 0, n = text.length;
		var start = -1, depth = 0, braces = 0, lineStart = true;
		while (at < n) {
			var c = StringTools.fastCodeAt(text, at);
			if (c == "\n".code) {
				lineStart = true;
				at++;
				continue;
			}
			if (lineStart && c == "#".code && start < 0) {
				var end = text.indexOf("\n", at);
				at = end < 0 ? n : end;
				continue;
			}
			if (c != " ".code && c != "\t".code && c != "\r".code)
				lineStart = false;
			if (start < 0 && c != " ".code && c != "\t".code && c != "\r".code)
				start = at;
			if (c == "(".code || c == "[".code)
				depth++;
			else if (c == ")".code || c == "]".code)
				depth--;
			else if (c == "{".code)
				braces++;
			else if (c == "}".code) {
				braces--;
				if (braces == 0 && depth == 0 && start >= 0 && isFunction(start, at)) {
					declare(start, at + 1);
					start = -1;
				}
			} else if (c == ";".code && braces == 0 && depth == 0 && start >= 0) {
				declare(start, at + 1);
				start = -1;
			}
			at++;
		}
	}

	// Whether the statement up to its first brace is a function's head: a parenthesis before the brace, and no `=` (an initializer).
	function isFunction(start:Int, close:Int):Bool {
		var open = text.indexOf("{", start);
		if (open < 0 || open > close)
			return false;
		var head = ~/\blayout\s*\([^)]*\)/g.replace(text.substring(start, open), " ");
		return head.indexOf("(") >= 0 && head.indexOf("=") < 0 && !~/\b(struct|uniform|in|out|buffer)\b/.match(head.split("(")[0]);
	}

	// The tokens of a statement: identifiers, numbers, and single characters, each with its position.
	function tokens(start:Int, end:Int):Array<{text:String, at:Int}> {
		var out = [], at = start;
		while (at < end) {
			var c = StringTools.fastCodeAt(text, at);
			if (c == " ".code || c == "\t".code || c == "\n".code || c == "\r".code) {
				at++;
				continue;
			}
			var from = at;
			if (isIdentifierStart(c)) {
				while (at < end && isIdentifierPart(StringTools.fastCodeAt(text, at)))
					at++;
			} else if (c >= "0".code
				&& c <= "9".code
				|| c == ".".code
				&& at + 1 < end
				&& StringTools.fastCodeAt(text, at + 1) >= "0".code
				&& StringTools.fastCodeAt(text, at + 1) <= "9".code) {
				while (at < end && (isIdentifierPart(StringTools.fastCodeAt(text, at)) || StringTools.fastCodeAt(text, at) == ".".code))
					at++;
			} else
				at++;
			out.push({text: text.substring(from, at), at: from});
		}
		return out;
	}

	// The index past the bracket matching the one at i.
	static function matching(t:Array<{text:String, at:Int}>, i:Int, open:String, close:String):Int {
		var depth = 0;
		while (i < t.length) {
			if (t[i].text == open)
				depth++;
			else if (t[i].text == close && --depth == 0)
				return i + 1;
			i++;
		}
		return t.length;
	}

	static function isIdentifier(s:String):Bool
		return s.length > 0 && isIdentifierStart(StringTools.fastCodeAt(s, 0));

	function declare(start:Int, end:Int):Void {
		var t = tokens(start, end);
		var i = 0, quals = [], binding:Null<Int> = null, location:Null<Int> = null, placed = false;
		while (i < t.length) {
			if (t[i].text == "layout" && i + 1 < t.length && t[i + 1].text == "(") {
				var past = matching(t, i + 1, "(", ")");
				var parts = [for (k in i + 2...past - 1) t[k].text].join(" ").split(",");
				for (p in parts) {
					var kv = p.split("=");
					var key = StringTools.trim(kv[0]);
					var value = kv.length > 1 ? Std.parseInt(StringTools.trim(kv[1])) : null;
					if (key == "binding") {
						binding = value;
						placed = true;
					} else if (key == "location") {
						location = value;
						placed = true;
					}
				}
				i = past;
			} else if (QUALIFIERS.indexOf(t[i].text) >= 0) {
				quals.push(t[i].text);
				i++;
			} else
				break;
		}
		function add(kind:String, name:String, instance:String, type:String, array:String, initialized:Bool, shared:Bool, uses:Array<String>)
			declarations.push({
				kind: kind,
				start: start,
				end: end,
				name: name,
				instance: instance,
				type: type,
				array: array,
				binding: binding,
				location: location,
				placed: placed,
				initialized: initialized,
				shared: shared,
				uses: uses
			});
		if (i >= t.length)
			return add("other", "", "", "", "", false, false, []);
		if (t[i].text == "struct" && i + 2 < t.length && t[i + 2].text == "{") {
			var close = matching(t, i + 2, "{", "}");
			return add("struct", t[i + 1].text, "", "", "", false, false, [for (k in i + 3...close - 1) if (isIdentifier(t[k].text)) t[k].text]);
		}
		var uniform = quals.indexOf("uniform") >= 0,
			input = quals.indexOf("in") >= 0 || quals.indexOf("attribute") >= 0,
			output = quals.indexOf("out") >= 0;
		if (!uniform && !input && !output)
			return add(t[t.length - 1].text == "}" ? "function" : "other", "", "", "", "", false, false, []);
		var kindOf = uniform ? "uniform" : input ? "in" : "out";
		if (i + 1 < t.length && t[i + 1].text == "{") {
			var close = matching(t, i + 1, "{", "}");
			var instance = close < t.length && isIdentifier(t[close].text) ? t[close].text : "";
			return add(uniform ? "block" : kindOf + "block", t[i].text, instance, "", "", false, false,
				[for (k in i + 2...close - 1) if (isIdentifier(t[k].text)) t[k].text]);
		}
		// The type: a precision before it, then its name.
		var typeStart = i;
		while (i < t.length && (t[i].text == "highp" || t[i].text == "mediump" || t[i].text == "lowp"))
			i++;
		if (i >= t.length)
			return add("other", "", "", "", "", false, false, []);
		var type = [for (k in typeStart...i + 1) t[k].text].join(" "),
			base = t[i].text;
		i++;
		// The declarators: name, an array, an initializer, separated by commas.
		var declared = [];
		while (i < t.length && isIdentifier(t[i].text)) {
			var declName = t[i].text, array = "", initialized = false;
			i++;
			if (i < t.length && t[i].text == "[") {
				var past = matching(t, i, "[", "]");
				array = text.substring(t[i].at, t[past - 1].at + 1);
				array = ~/\s+/g.replace(array, "");
				i = past;
			}
			if (i < t.length && t[i].text == "=") {
				initialized = true;
				var depth = 0;
				while (i < t.length && !(depth == 0 && (t[i].text == "," || t[i].text == ";"))) {
					if (t[i].text == "(" || t[i].text == "[" || t[i].text == "{")
						depth++;
					else if (t[i].text == ")" || t[i].text == "]" || t[i].text == "}")
						depth--;
					i++;
				}
			}
			declared.push({name: declName, array: array, initialized: initialized});
			if (i < t.length && t[i].text == ",")
				i++;
			else
				break;
		}
		var opaque = ~/^(sampler|isampler|usampler|texture|itexture|utexture|image|iimage|uimage|subpass)/.match(base);
		for (d in declared)
			add(uniform ? (opaque ? "texture" : "uniform") : kindOf, d.name, "", type, d.array, d.initialized, declared.length > 1, [base]);
	}

	/** Replaces a statement's characters with spaces, its line ends kept. */
	public function remove(start:Int, end:Int):Void {
		var blank = new StringBuf();
		for (k in start...end) {
			var c = text.charAt(k);
			blank.add(c == "\n" ? "\n" : " ");
		}
		edits.push({
			at: start,
			remove: end - start,
			insert: blank.toString(),
			rank: 2
		});
	}

	/** Inserts text, which must hold no line end, at a position: after what `insertBefore` puts there. */
	public function insert(at:Int, what:String):Void
		edits.push({
			at: at,
			remove: 0,
			insert: what,
			rank: 1
		});

	/** Inserts text, which must hold no line end, at a position, before anything else inserted there (whole declarations, so a layout
		inserted for the statement there stays with it). */
	public function insertBefore(at:Int, what:String):Void
		edits.push({
			at: at,
			remove: 0,
			insert: what,
			rank: 0
		});

	/** Replaces the version line with `#version 450`. */
	public function setVersion450():Void
		edits.push({
			at: versionStart,
			remove: versionEnd - versionStart,
			insert: "#version 450",
			rank: 2
		});

	/** Returns the text with every edit made. At one position, `insertBefore`'s text comes first, then `insert`'s, each in the order made, then a replacement. */
	public function edited():String {
		var order = [for (k in 0...edits.length) k];
		order.sort((a, b) -> edits[a].at != edits[b].at ? edits[a].at - edits[b].at : edits[a].rank != edits[b].rank ? edits[a].rank - edits[b].rank : a - b);
		var out = new StringBuf(), at = 0;
		for (k in order) {
			var e = edits[k];
			if (e.at < at)
				continue;
			out.add(text.substring(at, e.at));
			out.add(e.insert);
			at = e.at + e.remove;
		}
		out.add(text.substring(at));
		return out.toString();
	}

	/** Returns the position of the first statement, where text before every declaration goes. */
	public function firstStatement():Int
		return declarations.length > 0 ? declarations[0].start : text.length;

	/** Returns the declaration text of a statement, for copying into the other stage (a struct). */
	public function source(d:ShaderDeclaration):String
		return ~/\s+/g.replace(text.substring(d.start, d.end), " ");
}
