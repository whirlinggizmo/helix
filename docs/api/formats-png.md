# helix.formats.png

[Back to the index](README.md)

## PngFile

*class* in [`libs/formats/src/helix/formats/png/PngFile.hx`](../../libs/formats/src/helix/formats/png/PngFile.hx), `import helix.formats.png.PngFile;`

Provides writing a PNG file as raylib 5.5's `ExportImage` and `ExportImageToMemory` write one, byte for byte.

It is stb_image_write 1.16's PNG writer (`stbi_write_png_to_mem`), ported: each row's filter chosen by trying all five and keeping the one whose bytes, read as signed, sum smallest; then its own zlib compressor at its default quality (8), a single block of DEFLATE's fixed Huffman codes, stored instead when that would be smaller. The pixels are 8 bits a channel, rows top first, with no padding between them. Files are larger than an optimizing encoder's, as stb_image_write's are.

```haxe
var png = PngFile.write(64, 32, 4, pixels);
```

```haxe
static function write(width:Int, height:Int, channelCount:Int, pixels:haxe.io.Bytes):haxe.io.Bytes
```

- `write`: Writes pixels as a PNG file.
  - `width`: The image's width, in pixels.
  - `height`: The image's height, in pixels.
  - `channelCount`: The channels a pixel has, 1 to 4, a byte each.
  - `pixels`: The pixels, rows top first, each `width * channelCount` bytes.
  - returns: The PNG file.
  - throws `String`: The width or height is under 1, the channels are outside 1 to 4, or there are fewer pixels than the size needs.

  One channel is gray, two gray and alpha, three RGB and four RGBA, as raylib's grayscale, gray-alpha, R8G8B8 and R8G8B8A8 images are written. Bytes past the image's are ignored.
