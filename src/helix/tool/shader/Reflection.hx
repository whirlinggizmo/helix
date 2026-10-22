package helix.tool.shader;

/** sokol-shdc's reflection (`-f bare_yaml`'s `<name>_reflection.yaml`) read into Haxe values: mappings as objects, sequences as arrays,
	integers as Int, true and false as Bool, the rest as String. It reads the YAML sokol-shdc writes, block mappings and sequences of them
	indented by spaces, and refuses what it doesn't know (a flow collection, an anchor, a tab, a repeated key) rather than guess. */
class Reflection {
	var lines:Array<{indent:Int, text:String, number:Int}> = [];
	var at = 0;
	var source:String;

	/** The YAML text, named source in messages, read. */
	public static function parse(text:String, source:String):Dynamic {
		var reader = new Reflection(text, source);
		if (reader.lines.length == 0)
			return null;
		var value = reader.block(reader.lines[0].indent);
		if (reader.at < reader.lines.length)
			reader.fail(reader.lines[reader.at].number, "a line out of place");
		return value;
	}

	function new(text:String, source:String) {
		this.source = source;
		var number = 0;
		for (raw in text.split("\n")) {
			number++;
			var line = StringTools.rtrim(raw);
			var content = StringTools.ltrim(line);
			if (content == "" || StringTools.startsWith(content, "#") || content == "---")
				continue;
			if (line.indexOf("\t") >= 0)
				fail(number, "a tab");
			lines.push({indent: line.length - content.length, text: content, number: number});
		}
	}

	// The mapping or sequence whose lines start at indent.
	function block(indent:Int):Dynamic {
		return lines[at].text == "-" || StringTools.startsWith(lines[at].text, "- ") ? sequence(indent) : mapping(indent);
	}

	function sequence(indent:Int):Array<Dynamic> {
		var items:Array<Dynamic> = [];
		while (at < lines.length
			&& lines[at].indent == indent
			&& (lines[at].text == "-" || StringTools.startsWith(lines[at].text, "- "))) {
			var line = lines[at++];
			if (line.text == "-")
				items.push(nested(indent));
			else
				items.push(scalar(StringTools.trim(line.text.substr(2)), line.number));
		}
		return items;
	}

	function mapping(indent:Int):Dynamic {
		var out = {};
		while (at < lines.length && lines[at].indent == indent) {
			var line = lines[at++];
			var colon = line.text.indexOf(":");
			if (colon <= 0 || (colon + 1 < line.text.length && line.text.charAt(colon + 1) != " "))
				fail(line.number, "not a key and value");
			var key = line.text.substr(0, colon);
			if (Reflect.hasField(out, key))
				fail(line.number, 'key $key repeated');
			var rest = StringTools.trim(line.text.substr(colon + 1));
			Reflect.setField(out, key, rest == "" ? nested(indent) : scalar(rest, line.number));
		}
		return out;
	}

	// What's indented under the line just read: a block, or null when nothing is.
	function nested(indent:Int):Dynamic {
		if (at >= lines.length || lines[at].indent <= indent)
			return null;
		return block(lines[at].indent);
	}

	function scalar(text:String, number:Int):Dynamic {
		if (~/^-?[0-9]+$/.match(text))
			return Std.parseInt(text);
		if (text == "true")
			return true;
		if (text == "false")
			return false;
		var first = text.charAt(0);
		if (first == "'" && StringTools.endsWith(text, "'") && text.length >= 2)
			return StringTools.replace(text.substr(1, text.length - 2), "''", "'");
		if (first == "["
			|| first == "{"
			|| first == "&"
			|| first == "*"
			|| first == "!"
			|| first == "|"
			|| first == ">"
			|| first == '"')
			fail(number, 'a value this reader doesn\'t know: $text');
		return text;
	}

	function fail(number:Int, problem:String):Void
		throw new helix.tool.shared.CommandError('shader: $source:$number: $problem in sokol-shdc\'s reflection');
}
