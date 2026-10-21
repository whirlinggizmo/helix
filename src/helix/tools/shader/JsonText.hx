package helix.tools.shader;

/** A JSON value whose objects keep their keys' order, as the packer writes .hxshader files: the same text on every system and every run. */
enum JsonValue {
	JObject(fields:Array<JsonField>);
	JArray(items:Array<JsonValue>);
	JString(text:String);
	JInt(value:Int);
	JBool(value:Bool);
}

/** One key of a JObject and its value. */
typedef JsonField = {
	key:String,
	value:JsonValue
};

/** JSON text written as Python's json module writes it, which the packer's output has always matched: compact (`,` and `:`), or indented by
	one space a level (`, ` within a line, `: ` after a key), characters past ASCII escaped as \u and four lowercase hex digits. */
class JsonText {
	/** value with no spaces. */
	public static function compact(value:JsonValue):String {
		var out = new StringBuf();
		write(out, value, -1, 0);
		return out.toString();
	}

	/** value indented one space a level. */
	public static function indented(value:JsonValue):String {
		var out = new StringBuf();
		write(out, value, 1, 0);
		return out.toString();
	}

	/** text as a JSON string, quotes included: also a Haxe string literal (JSON's escapes are Haxe's too). */
	public static function quote(text:String):String {
		var out = new StringBuf();
		out.addChar('"'.code);
		for (c in new haxe.iterators.StringIteratorUnicode(text)) {
			switch c {
				case '"'.code:
					out.add('\\"');
				case '\\'.code:
					out.add('\\\\');
				case '\n'.code:
					out.add('\\n');
				case '\r'.code:
					out.add('\\r');
				case '\t'.code:
					out.add('\\t');
				case 8:
					out.add('\\b');
				case 12:
					out.add('\\f');
				default:
					if (c < 0x20 || (c >= 0x80 && c < 0x10000))
						out.add('\\u' + StringTools.hex(c, 4).toLowerCase());
					else if (c >= 0x10000) {
						var v = c - 0x10000;
						out.add('\\u' + StringTools.hex(0xd800 | (v >> 10), 4).toLowerCase());
						out.add('\\u' + StringTools.hex(0xdc00 | (v & 0x3ff), 4).toLowerCase());
					} else
						out.addChar(c);
			}
		}
		out.addChar('"'.code);
		return out.toString();
	}

	// value at depth; indent -1 writes it compact.
	static function write(out:StringBuf, value:JsonValue, indent:Int, depth:Int):Void {
		switch value {
			case JString(text):
				out.add(quote(text));
			case JInt(v):
				out.add(Std.string(v));
			case JBool(v):
				out.add(v ? "true" : "false");
			case JArray(items):
				if (items.length == 0) {
					out.add("[]");
					return;
				}
				out.add("[");
				for (i in 0...items.length) {
					if (i > 0)
						out.add(",");
					newline(out, indent, depth + 1);
					write(out, items[i], indent, depth + 1);
				}
				newline(out, indent, depth);
				out.add("]");
			case JObject(fields):
				if (fields.length == 0) {
					out.add("{}");
					return;
				}
				out.add("{");
				for (i in 0...fields.length) {
					if (i > 0)
						out.add(",");
					newline(out, indent, depth + 1);
					out.add(quote(fields[i].key));
					out.add(indent < 0 ? ":" : ": ");
					write(out, fields[i].value, indent, depth + 1);
				}
				newline(out, indent, depth);
				out.add("}");
		}
	}

	static function newline(out:StringBuf, indent:Int, depth:Int):Void {
		if (indent < 0)
			return;
		out.add("\n");
		for (_ in 0...indent * depth)
			out.add(" ");
	}
}
