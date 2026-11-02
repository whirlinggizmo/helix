# helix.formats.text

[Back to the index](README.md)

## Utf8Text

*class* in [`formats/src/helix/formats/text/Utf8Text.hx`](../../formats/src/helix/formats/text/Utf8Text.hx), `import helix.formats.text.Utf8Text;`

Provides text read from bytes that may not be text: UTF-8 checked before it is decoded, and tags compared byte by byte.

Haxe's `Bytes.getString` and `toString` throw a `RangeError` in a browser for bytes that aren't UTF-8, which a `catch (e:String)` misses, and end the text at a NUL byte there alone. These check the bytes first, so a file that isn't text fails the same way on every target: `decode` throws a String, and `decodeReplacing` puts U+FFFD where the bytes aren't text.

```haxe
var text = Utf8Text.decode(bytes); // throws a String for bytes that aren't UTF-8 text
if (Utf8Text.matchesAscii(bytes, 0, "glTF"))
readBinary(bytes);
```

```haxe
static function isValid(bytes:haxe.io.Bytes, ?at:Int = 0, ?length:Int = -1):Bool
static function decode(bytes:haxe.io.Bytes, ?at:Int = 0, ?length:Int = -1):String
static function decodeReplacing(bytes:haxe.io.Bytes, ?at:Int = 0, ?length:Int = -1):String
static function matchesAscii(bytes:haxe.io.Bytes, at:Int, text:String):Bool
```

- `isValid`: Returns whether bytes are UTF-8 text: each sequence whole, none overlong, no surrogate, none past U+10FFFF, and no NUL byte.
  - `bytes`: The bytes.
  - `at`: Optional. The first byte to check; defaults to 0.
  - `length`: Optional. The number of bytes to check; defaults to the rest.
  - returns: True when they are.
- `decode`: Returns bytes decoded as UTF-8 text.
  - `bytes`: The bytes.
  - `at`: Optional. The first byte to decode; defaults to 0.
  - `length`: Optional. The number of bytes to decode; defaults to the rest.
  - returns: The text.
  - throws `String`: The bytes aren't UTF-8 text (`isValid`), naming the first byte that isn't.
- `decodeReplacing`: Returns bytes decoded as UTF-8 text, each byte that doesn't start a whole UTF-8 sequence, and each NUL byte, read as U+FFFD (the replacement character).
  - `bytes`: The bytes.
  - `at`: Optional. The first byte to decode; defaults to 0.
  - `length`: Optional. The number of bytes to decode; defaults to the rest.
  - returns: The text.

  For text that may hold anything, where a stand-in is better than a refusal.
- `matchesAscii`: Returns whether the bytes at a position are the given ASCII text, compared byte by byte: a file's tag or magic number, read without decoding bytes that may not be text.
  - `bytes`: The bytes.
  - `at`: The position of the first byte.
  - `text`: The ASCII text.
  - returns: True when they are; false when the text runs past the bytes' end.
