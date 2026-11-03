package helix.formats.text;

import haxe.io.Bytes;

/** Provides text read from bytes that may not be text: UTF-8 checked before it is decoded, and tags compared byte by byte.

	Haxe's `Bytes.getString` and `toString` throw a `RangeError` in a browser for bytes that aren't UTF-8, which a `catch (e:String)`
	misses, and end the text at a NUL byte there alone. These check the bytes first, so a file that isn't text fails the same way on
	every target: `decode` throws a String, and `decodeReplacing` puts U+FFFD where the bytes aren't text.

	```haxe
	var text = Utf8Text.decode(bytes); // throws a String for bytes that aren't UTF-8 text
	if (Utf8Text.matchesAscii(bytes, 0, "glTF"))
		readBinary(bytes);
	``` */
class Utf8Text {
	/** Returns whether bytes are UTF-8 text: each sequence whole, none overlong, no surrogate, none past U+10FFFF, and no NUL byte.

		@param bytes  The bytes.
		@param at  Optional. The first byte to check; defaults to 0.
		@param length  Optional. The number of bytes to check; defaults to the rest.
		@return  True when they are. */
	public static function isValid(bytes:Bytes, at:Int = 0, length:Int = -1):Bool {
		var end = length < 0 ? bytes.length : at + length;
		while (at < end) {
			var size = sequence(bytes, at, end);
			if (size == 0)
				return false;
			at += size;
		}
		return true;
	}

	/** Returns bytes decoded as UTF-8 text.

		@param bytes  The bytes.
		@param at  Optional. The first byte to decode; defaults to 0.
		@param length  Optional. The number of bytes to decode; defaults to the rest.
		@return  The text.
		@throws String  The bytes aren't UTF-8 text (`isValid`), naming the first byte that isn't. */
	public static function decode(bytes:Bytes, at:Int = 0, length:Int = -1):String {
		if (length < 0)
			length = bytes.length - at;
		var end = at + length, p = at;
		while (p < end) {
			var size = sequence(bytes, p, end);
			if (size == 0)
				throw bytes.get(p) == 0 ? 'Not text: a NUL byte at ${p - at}' : 'Not UTF-8 text: byte 0x${StringTools.hex(bytes.get(p), 2)} at ${p - at}';
			p += size;
		}
		return bytes.getString(at, length);
	}

	/** Returns bytes decoded as UTF-8 text, each byte that doesn't start a whole UTF-8 sequence, and each NUL byte, read as U+FFFD (the
		replacement character).

		For text that may hold anything, where a stand-in is better than a refusal.

		@param bytes  The bytes.
		@param at  Optional. The first byte to decode; defaults to 0.
		@param length  Optional. The number of bytes to decode; defaults to the rest.
		@return  The text. */
	public static function decodeReplacing(bytes:Bytes, at:Int = 0, length:Int = -1):String {
		if (length < 0)
			length = bytes.length - at;
		var end = at + length;
		if (isValid(bytes, at, length))
			return bytes.getString(at, length);
		var text = new StringBuf(), start = at, p = at;
		while (p < end) {
			var size = sequence(bytes, p, end);
			if (size > 0) {
				p += size;
				continue;
			}
			if (p > start)
				text.add(bytes.getString(start, p - start));
			text.addChar(0xFFFD);
			p++;
			start = p;
		}
		if (end > start)
			text.add(bytes.getString(start, end - start));
		return text.toString();
	}

	/** Returns whether the bytes at a position are the given ASCII text, compared byte by byte: a file's tag or magic number, read
		without decoding bytes that may not be text.

		@param bytes  The bytes.
		@param at  The position of the first byte.
		@param text  The ASCII text.
		@return  True when they are; false when the text runs past the bytes' end. */
	public static function matchesAscii(bytes:Bytes, at:Int, text:String):Bool {
		if (at < 0 || at + text.length > bytes.length)
			return false;
		for (i in 0...text.length)
			if (bytes.get(at + i) != StringTools.fastCodeAt(text, i))
				return false;
		return true;
	}

	// The length of the whole UTF-8 sequence at `at`, ending by `end`, or 0 when there is none there or its byte is NUL.
	static function sequence(bytes:Bytes, at:Int, end:Int):Int {
		var b = bytes.get(at);
		if (b < 0x80)
			return b == 0 ? 0 : 1;
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
			return 0;
		if (at + count >= end)
			return 0;
		for (k in 1...count + 1) {
			var c = bytes.get(at + k);
			if (c & 0xC0 != 0x80)
				return 0;
			code = (code << 6) | (c & 0x3F);
		}
		if (code < least || code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF))
			return 0;
		return count + 1;
	}
}
