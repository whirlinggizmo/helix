package helix.formats.obj;

import haxe.io.Bytes;

/** Reads the text an OBJ or MTL file is made of: its lines, their words and numbers, and the paths they name. */
@:noCompletion
@:allow(helix.formats.obj)
class ObjText {
	/** Returns a file's lines: its bytes checked as UTF-8 text (a byte order mark at the start skipped, no NUL byte), split at `\n`,
		`\r\n` and `\r`.

		@param bytes  The file's bytes.
		@return  The lines, the first line 1's.
		@throws String  The bytes aren't UTF-8 text. */
	static function lines(bytes:Bytes):Array<String> {
		var start = bytes.length >= 3 && bytes.get(0) == 0xEF && bytes.get(1) == 0xBB && bytes.get(2) == 0xBF ? 3 : 0;
		var at = start, line = 1;
		while (at < bytes.length) {
			var b = bytes.get(at);
			if (b == 10)
				line++;
			if (b == 0)
				throw 'Line $line: not text (a NUL byte)';
			if (b < 0x80) {
				at++;
				continue;
			}
			// A lead byte, its count of continuation bytes, and the least code point it may give (no overlong forms).
			var count = 0, least = 0, code = 0;
			if (b >= 0xC2 && b <= 0xDF) {
				count = 1;
				least = 0x80;
				code = b & 0x1F;
			} else if (b >= 0xE0 && b <= 0xEF) {
				count = 2;
				least = 0x800;
				code = b & 0x0F;
			} else if (b >= 0xF0 && b <= 0xF4) {
				count = 3;
				least = 0x10000;
				code = b & 0x07;
			} else
				throw 'Line $line: not UTF-8 text';
			if (at + count >= bytes.length)
				throw 'Line $line: not UTF-8 text';
			for (k in 1...count + 1) {
				var c = bytes.get(at + k);
				if (c & 0xC0 != 0x80)
					throw 'Line $line: not UTF-8 text';
				code = (code << 6) | (c & 0x3F);
			}
			if (code < least || code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF))
				throw 'Line $line: not UTF-8 text';
			at += count + 1;
		}
		var text = bytes.getString(start, bytes.length - start);
		return ~/\r\n|\r|\n/g.split(text);
	}

	/** Returns a line's words: what's between spaces and tabs, up to a `#` that starts a word, which begins a comment.

		@param line  The line.
		@return  The words; none for an empty line or a comment. */
	static function words(line:String):Array<String> {
		var found = [];
		for (word in ~/[ \t]+/g.split(line)) {
			if (word == "")
				continue;
			if (word.charAt(0) == "#")
				break;
			found.push(word);
		}
		return found;
	}

	/** Returns the rest of a line after its keyword, its spaces at either end taken off, up to a comment.

		@param line  The line.
		@param keyword  The keyword it starts with, after any spaces.
		@return  The rest; "" for none. */
	static function rest(line:String, keyword:String):String {
		var at = line.indexOf(keyword) + keyword.length;
		var text = line.substr(at);
		var comment = ~/(^|[ \t])#/;
		if (comment.match(text))
			text = text.substr(0, comment.matchedPos().pos);
		return StringTools.trim(text);
	}

	static final NUMBER = ~/^[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?$/;

	/** Returns whether a word is a number, written as OBJ writes them: an optional sign, digits with an optional point (or a point and
		digits), and an optional exponent.

		@param word  The word.
		@return  True when it is. */
	static function isNumber(word:String):Bool
		return NUMBER.match(word);

	/** Returns a word read as a number.

		@param word  The word.
		@param line  The line's number, for the message.
		@return  The number.
		@throws String  It isn't one. */
	static function number(word:String, line:Int):Float {
		if (!NUMBER.match(word))
			throw 'Line $line: "$word" is not a number';
		return Std.parseFloat(word);
	}

	/** Returns a word read as a whole number.

		@param word  The word.
		@param line  The line's number, for the message.
		@return  The number.
		@throws String  It isn't one. */
	static function integer(word:String, line:Int):Int {
		if (!~/^[+-]?[0-9]+$/.match(word))
			throw 'Line $line: "$word" is not a whole number';
		var value = Std.parseInt(word);
		if (value == null)
			throw 'Line $line: "$word" is not a whole number';
		return value;
	}

	/** Returns a path a file names, resolved against the file's directory and normalized: `/` between parts (a `\` taken as one), `.`
		and `..` taken out, a `..` above the root kept at its start. An absolute path is kept as it is.

		@param path  The path the file gives.
		@param file  The file's own path.
		@return  The path. */
	static function resolve(path:String, file:String):String {
		if (StringTools.startsWith(path, "/") || StringTools.startsWith(path, "\\") || ~/^[A-Za-z]:[\/\\]/.match(path))
			return path;
		var directory = haxe.io.Path.directory(StringTools.replace(file, "\\", "/"));
		return normalize(directory == "" ? path : directory + "/" + path);
	}

	// A path with `/` between its parts, `.` and `..` taken out, a `..` above the root kept at its start, a leading `/` kept.
	static function normalize(path:String):String {
		var parts = [], absolute = StringTools.startsWith(path, "/");
		for (part in StringTools.replace(path, "\\", "/").split("/")) {
			if (part == "" || part == ".")
				continue;
			if (part == ".." && parts.length > 0 && parts[parts.length - 1] != "..")
				parts.pop();
			else if (part != ".." || !absolute)
				parts.push(part);
		}
		return (absolute ? "/" : "") + parts.join("/");
	}
}
