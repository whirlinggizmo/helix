# helix.services.images

[Back to the index](README.md)

## Image

*class* in [`services/src/helix/services/images/Image.hx`](../../services/src/helix/services/images/Image.hx), `import helix.services.images.Image;`

Represents a decoded image: its size and its pixels.

```haxe
function new(path:String, width:Int, height:Int, pixels:haxe.io.Bytes)
final path:String
final width:Int
final height:Int
final pixels:haxe.io.Bytes
```

- `new`: Creates an image. Images are made by `Images.load` and `Images.decode`.
  - `path`: The path it was loaded from, or "".
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `pixels`: The pixels.
- `path`: Gets the path it was loaded from, or "" for one decoded from bytes.
- `width`: Gets the width, in pixels.
- `height`: Gets the height, in pixels.
- `pixels`: Gets the pixels: 8-bit red, green, blue and alpha, `width * height * 4` bytes, rows top first, alpha not premultiplied.

## Images

*class* in [`services/src/helix/services/images/Images.hx`](../../services/src/helix/services/images/Images.hx), `import helix.services.images.Images;`, implements `IPollable`

Provides images by path: each file found through the assets, decoded off the main thread where the platform can, into pixels.

Images draws nothing and holds nothing on the GPU: what a program draws with is its own (`IGraphics.createTexture` takes an image's pixels as they are). The program polls it once a frame, as it does the decoder.

```haxe
var images = new Images(decoder, assets);
images.load("player.png", image -> texture = graphics.createTexture(image.width, image.height, [image.pixels]));
```

```haxe
function new(decoder:IImageDecoder, assets:Assets)
function load(path:String, loaded:Image -> Void, ?failed:String -> Void):() -> Void
function decode(encoded:haxe.io.Bytes, decoded:Image -> Void, ?failed:String -> Void):() -> Void
function poll():Void
function dispose():Void
```

- `new`: Creates the images over the platform's decoder, finding files through the assets.
  - `decoder`: The platform's image decoder.
  - `assets`: Where files are found.
- `load`: Loads an image file and decodes it: PNG, JPEG, BMP, TGA, or a GIF's first frame.
  - `path`: The file, as the assets name it.
  - `loaded`: Receives the image.
  - `failed`: Optional. Receives why it couldn't be loaded or decoded. When omitted, the failure is logged.
  - returns: A function that aborts the load; neither callback is called after it, and once one was, it does nothing.

  One of `loaded` or `failed` is called once, at a later `poll`, never during this call.
- `decode`: Decodes an image held in other bytes, such as a model's.
  - `encoded`: The image file's bytes.
  - `decoded`: Receives the image, its `path` "".
  - `failed`: Optional. Receives why it couldn't be decoded. When omitted, the failure is logged.
  - returns: A function that aborts the decode; neither callback is called after it, and once one was, it does nothing.

  One of `decoded` or `failed` is called once, at a later `poll`, never during this call.
- `poll`: Delivers what was loaded and decoded since the last poll.
- `dispose`: Aborts every load and decode in flight. The images aren't used after it.
