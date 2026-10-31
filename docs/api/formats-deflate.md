# helix.formats.deflate

[Back to the index](README.md)

## Deflate

*class* in [`formats/src/helix/formats/deflate/Deflate.hx`](../../formats/src/helix/formats/deflate/Deflate.hx), `import helix.formats.deflate.Deflate;`

Provides DEFLATE compression (RFC 1951) as raylib 5.5's `CompressData` compresses, byte for byte.

It is sdefl 1.0 (`sdefl.h`, raylib 5.5's copy), ported: a hash chain matcher, its lazy match from level 5, and a dynamic Huffman block for each 256 KiB of input, stored as raw blocks when that is smaller. The stream is raw DEFLATE, with no zlib header or checksum; `haxe.zip.InflateImpl` reads it back with its header off. Empty input compresses to no bytes, as sdefl's does.

```haxe
var compressed = Deflate.compress(bytes, 8);
```

```haxe
static function compress(data:haxe.io.Bytes, level:Int):haxe.io.Bytes
```

- `compress`: Compresses bytes into a raw DEFLATE stream.
  - `data`: The bytes to compress.
  - `level`: The compression level, from 0 (fastest) to 8 (smallest).
  - returns: The DEFLATE stream.
  - throws `String`: The level is outside 0 to 8.

  Level 8 is raylib's `CompressData`'s; sdefl's own default is 5. Each level searches longer for matches: 0 and 1 skip ahead over a long match, 5 and up look one byte on for a longer one.
