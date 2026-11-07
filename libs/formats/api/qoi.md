# helix.formats.qoi

[Back to the library](README.md)

## QoiFile

*class* in [`libs/formats/src/helix/formats/qoi/QoiFile.hx`](../src/helix/formats/qoi/QoiFile.hx), `import helix.formats.qoi.QoiFile;`

Represents an image read from a QOI file ("Quite OK Image"): its size, its channels and its pixels; and provides writing one.

Reading and writing are qoi.h's (raylib 5.5's copy) `qoi_decode` and `qoi_encode`, ported, so a file is written byte for byte as raylib's `ExportImage` writes it, and read as `LoadImage` reads it: with the channels the file has. The pixels are 8 bits a channel, rows top first.

```haxe
var qoi = QoiFile.write(64, 32, 4, pixels);
var image = QoiFile.read(qoi);
trace(image.width, image.height, image.channelCount);
```

```haxe
static function read(data:haxe.io.Bytes):QoiFile
static function write(width:Int, height:Int, channelCount:Int, pixels:haxe.io.Bytes):haxe.io.Bytes
final width:Int
final height:Int
final channelCount:Int
final linear:Bool
final pixels:haxe.io.Bytes
```

- `read`: Reads a QOI file.
  - `data`: The file.
  - returns: The image, with the channels the file has.
  - throws `String`: It isn't a QOI file: it is too short, its magic or header is wrong, or its size is over 400 million pixels.

  A file whose data ends early leaves its last pixels the color it ended on, as qoi.h does.
- `write`: Writes pixels as a QOI file.
  - `width`: The image's width, in pixels.
  - `height`: The image's height, in pixels.
  - `channelCount`: The channels a pixel has: 3 (RGB) or 4 (RGBA), a byte each.
  - `pixels`: The pixels, rows top first, each `width * channelCount` bytes.
  - returns: The QOI file.
  - throws `String`: The width or height is under 1, the size is over 400 million pixels, the channels are neither 3 nor 4, or there are fewer pixels than the size needs.

  The file says its color channels are sRGB with a linear alpha, as raylib's `ExportImage` writes it. Bytes past the image's are ignored.
- `width`: Gets the image's width, in pixels.
- `height`: Gets the image's height, in pixels.
- `channelCount`: Gets the number of channels a pixel has: 3 (RGB) or 4 (RGBA).
- `linear`: Gets a value indicating whether every channel is linear: false when the color channels are sRGB with a linear alpha, as raylib writes them. QOI only records it; the pixels are the same either way.
- `pixels`: Gets the pixels, rows top first, each pixel `channelCount` bytes.
