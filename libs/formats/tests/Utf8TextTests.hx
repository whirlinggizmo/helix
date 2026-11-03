import haxe.io.Bytes;
import helix.formats.text.Utf8Text;

/** Checks Utf8Text with the library alone: UTF-8 text told from bytes that aren't (a lead byte past U+10FFFF, a code point past it, a
	cut sequence, an overlong form, a surrogate, a NUL), decoded or refused with a String alike on every target, decoded with U+FFFD in
	place of what isn't text, a part of the bytes decoded, and tags matched byte by byte. */
class Utf8TextTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The String a call throws, or null when it doesn't; anything else it throws fails the test, naming it.
	static function thrown(call:Void->Void):Null<String> {
		try
			call()
		catch (e:String)
			return e
		catch (e:Dynamic)
			throw 'threw what isn\'t a String: $e';
		return null;
	}

	static function main():Void {
		var text = Bytes.ofString("café 一 \u{1F600}");
		check(Utf8Text.isValid(text), "UTF-8 text, one to four bytes a character, is valid");
		check(Utf8Text.decode(text) == "café 一 \u{1F600}", "and decodes as it was written");
		check(Utf8Text.decodeReplacing(text) == "café 一 \u{1F600}", "and decodes alike, replacing");
		check(Utf8Text.decode(text, 0, 3) == "caf" && Utf8Text.decode(text, 6) == "一 \u{1F600}", "a part of the bytes decodes");
		for (hex in [
			"fffb9064ffffffff", // an MP3's first bytes: 0xFF is no UTF-8 lead byte
			"f4908080", // past U+10FFFF
			"7b22f09f", // a four-byte sequence cut short
			"c0af", // an overlong "/"
			"eda080", // a surrogate, U+D800
			"616200", // a NUL byte
		]) {
			var bytes = Bytes.ofHex(hex);
			check(!Utf8Text.isValid(bytes), '$hex is not UTF-8 text');
			check(thrown(() -> Utf8Text.decode(bytes)) != null, '$hex: decode throws a String');
		}
		check(thrown(() -> Utf8Text.decode(Bytes.ofHex("616200"))) == "Not text: a NUL byte at 2", "a NUL is named, by its place");
		check(thrown(() -> Utf8Text.decode(Bytes.ofHex("6162ff"))) == "Not UTF-8 text: byte 0xFF at 2", "a byte that isn't text is named");
		check(Utf8Text.decodeReplacing(Bytes.ofHex("61ff62")) == "a\u{FFFD}b", "replacing: a byte that isn't text is U+FFFD");
		check(Utf8Text.decodeReplacing(Bytes.ofHex("6100f09f62")) == "a\u{FFFD}\u{FFFD}\u{FFFD}b", "replacing: a NUL and each byte of a cut sequence");
		check(Utf8Text.decodeReplacing(Bytes.ofHex("f4908080")).length == 4, "replacing: past U+10FFFF, a U+FFFD a byte");
		check(Utf8Text.isValid(Bytes.ofHex("ff6162"), 1) && Utf8Text.isValid(Bytes.ofHex("6162ff"), 0, 2), "a part of the bytes checks");
		var glb = Bytes.ofHex("676c5446ff");
		check(Utf8Text.matchesAscii(glb, 0, "glTF") && !Utf8Text.matchesAscii(glb, 0, "glTX"), "a tag matches byte by byte");
		check(!Utf8Text.matchesAscii(glb, 3, "Fxx")
			&& !Utf8Text.matchesAscii(glb, -1, "g"), "a tag past the bytes' end, or before their start, doesn't match");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
