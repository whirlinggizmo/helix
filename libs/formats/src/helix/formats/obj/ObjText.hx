package helix.formats.obj;

import haxe.io.Bytes;
import helix.formats.text.Utf8Text;

/** Reads the text an OBJ or MTL file is made of: its lines, their words and numbers, and the paths they name. */
@:noCompletion
@:allow(helix.formats.obj)
class ObjText {
	/** Returns a file's lines: its bytes decoded as UTF-8 when they are UTF-8 (a byte order mark at the start skipped), and otherwise as
		Latin-1, each byte the character of its value (U+0000 to U+00FF), as older tools write OBJ and MTL files in their system's
		8-bit encoding; split at `\n`, `\r\n` and `\r`.

		@param bytes  The file's bytes.
		@return  The lines, the first line 1's.
		@throws String  The bytes hold a NUL byte, so aren't text, naming its line. */
	static function lines(bytes:Bytes):Array<String> {
		var line = 1;
		for (at in 0...bytes.length) {
			var b = bytes.get(at);
			if (b == 10)
				line++;
			else if (b == 0)
				throw 'Line $line: not text (a NUL byte)';
		}
		var text = if (Utf8Text.isValid(bytes)) {
			var start = bytes.length >= 3 && bytes.get(0) == 0xEF && bytes.get(1) == 0xBB && bytes.get(2) == 0xBF ? 3 : 0;
			Utf8Text.decode(bytes, start);
		} else {
			var latin1 = new StringBuf();
			for (at in 0...bytes.length)
				latin1.addChar(bytes.get(at));
			latin1.toString();
		}
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
