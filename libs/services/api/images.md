# helix.services.images

[Back to the library](README.md)

## Image

*class* in [`libs/services/src/helix/services/images/Image.hx`](../src/helix/services/images/Image.hx), `import helix.services.images.Image;`

Represents an image in memory: its size and its pixels, 8-bit RGBA.

An image is made here, loaded by `Images.load`, or decoded by `Images.decode`; then changed, drawn into and copied, and made a texture. What changes the size (cropping, resizing, rotating) returns a new image; everything else changes the pixels in place and returns the image, so calls chain (`image.grayscale().contrast(20)`). Positions are in pixels from the top-left, and what falls outside the image is skipped. Colors are 0xAARRGGBB, as `helix.math.Color` reads them.

The operations are raylib's, in its arithmetic: each gives the pixels raylib's function of the same name gives an R8G8B8A8 image, byte for byte, on every target. They are raylib 5.5's, but for the lines and the filled circle (`drawLine`, `drawThickLine`, `drawCircle`), which are 6.2's, as it fixed them. Shapes overwrite the pixels they cover, as raylib's do; images and text blend over them.

```haxe
var badge = Image.filled(64, 64, 0);
badge.drawCircle(32, 32, 30, 0xffe03030);
badge.drawText(font, "7", 24, 16, 32, 0, 0xffffffff);
var small = badge.resize(32, 32, Bilinear);
```

Natively the generated C++ is compiled with `-fwrapv` on GCC and clang, as Haxe's Int wraps on overflow and C++'s int doesn't.

```haxe
function new(path:String, width:Int, height:Int, pixels:haxe.io.Bytes)
static function filled(width:Int, height:Int, color:Int):Image
static function gradientLinear(width:Int, height:Int, radians:Float, start:Int, end:Int):Image
static function gradientRadial(width:Int, height:Int, density:Float, inner:Int, outer:Int):Image
static function gradientSquare(width:Int, height:Int, density:Float, inner:Int, outer:Int):Image
static function checked(width:Int, height:Int, squareWidth:Int, squareHeight:Int, first:Int, second:Int):Image
static function whiteNoise(width:Int, height:Int, factor:Float, random:Random):Image
static function perlinNoise(width:Int, height:Int, offsetX:Int, offsetY:Int, scale:Float):Image
static function cellular(width:Int, height:Int, tileSize:Int, random:Random):Image
final path:String
final width:Int
final height:Int
final pixels:haxe.io.Bytes
function copy():Image
function getChannel(channel:Int):Image
function crop(x:Int, y:Int, width:Int, height:Int):Image
function resize(width:Int, height:Int, filter:ImageFilter):Image
function resizeCanvas(width:Int, height:Int, offsetX:Int, offsetY:Int, fill:Int):Image
function toPowerOfTwo(fill:Int):Image
function cropAlpha(threshold:Float):Image
function rotate(radians:Float):Image
function rotateClockwise():Image
function rotateCounterclockwise():Image
function getMipmaps():Array<Image>
function flipVertical():Image
function flipHorizontal():Image
function tint(color:Int):Image
function invert():Image
function grayscale():Image
function contrast(amount:Float):Image
function brighten(amount:Int):Image
function replaceColor(from:Int, to:Int):Image
function clearAlpha(color:Int, threshold:Float):Image
function maskAlpha(mask:Image):Image
function premultiplyAlpha():Image
function blur(radius:Int):Image
function convolve(kernel:Array<Float>):Image
function dither(redBits:Int, greenBits:Int, blueBits:Int, alphaBits:Int):Image
function getPixel(x:Int, y:Int):Int
function getPalette(max:Int):Array<Int>
function getAlphaBorder(threshold:Float, ?out:Bounds2D):Bounds2D
function fill(color:Int):Image
function setPixel(x:Int, y:Int, color:Int):Image
function drawLine(x0:Int, y0:Int, x1:Int, y1:Int, color:Int):Image
function drawThickLine(x0:Float, y0:Float, x1:Float, y1:Float, thickness:Int, color:Int):Image
function drawCircle(x:Int, y:Int, radius:Int, color:Int):Image
function drawCircleLines(x:Int, y:Int, radius:Int, color:Int):Image
function drawRectangle(x:Int, y:Int, width:Int, height:Int, color:Int):Image
function drawRectangleLines(x:Int, y:Int, width:Int, height:Int, thickness:Int, color:Int):Image
function drawTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color0:Int, color1:Int, color2:Int):Image
function drawTriangleLines(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int):Image
function drawImage(source:Image, sourceX:Float, sourceY:Float, sourceWidth:Float, sourceHeight:Float, x:Float, y:Float, width:Float, height:Float, tint:Int):Image
function drawText(font:Font2D, text:String, x:Float, y:Float, size:Float, spacing:Float, color:Int):Image
```

- `new`: Creates an image over its pixels, which it keeps rather than copies.
  - `path`: The path it was loaded from, or "".
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `pixels`: The pixels: `width * height * 4` bytes of red, green, blue and alpha, rows top first.
- `filled`: Returns an image of one color.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `color`: The color, as 0xAARRGGBB.
  - returns: The image.
- `gradientLinear`: Returns a gradient from one color to another along a direction.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `radians`: The direction, in radians clockwise: 0 left to right, π/2 top to bottom.
  - `start`: The color it starts from, as 0xAARRGGBB.
  - `end`: The color it ends at.
  - returns: The image.

  The colors are at the image's two farthest edges along the direction, and blend across the middle.
- `gradientRadial`: Returns a gradient out from the middle, round.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `density`: How far the inner color holds, 0 (the middle alone) to 1 (out to the edge).
  - `inner`: The color in the middle, as 0xAARRGGBB.
  - `outer`: The color at the edge and beyond.
  - returns: The image.

  The inner color holds out to `density` of the way to the nearer edge, then blends to the outer color at the edge; past it, the outer color holds.
- `gradientSquare`: Returns a gradient out from the middle to the edges, square.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `density`: How far the inner color holds, 0 (the middle alone) to 1 (out to the edges).
  - `inner`: The color in the middle, as 0xAARRGGBB.
  - `outer`: The color at the edges.
  - returns: The image.

  The inner color holds out to `density` of the way to the edges, then blends to the outer color at them.
- `checked`: Returns a checkerboard of two colors.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `squareWidth`: The width of each square, in pixels; clamped to 1 or more.
  - `squareHeight`: The height of each square, in pixels; clamped to 1 or more.
  - `first`: The color of the top-left square, as 0xAARRGGBB.
  - `second`: The color of the squares beside it.
  - returns: The image.
- `whiteNoise`: Returns white noise: each pixel white or black, opaque.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `factor`: The chance of white, 0 to 1, in hundredths: the rest of it is dropped.
  - `random`: The generator the pixels are drawn from, one number a pixel, rows top first.
  - returns: The image.
- `perlinNoise`: Returns Perlin noise in gray, opaque: fractal Brownian motion over 6 octaves of stb_perlin's noise.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `offsetX`: How far it is moved left, in pixels: images side by side at their widths join up.
  - `offsetY`: How far it is moved up, in pixels.
  - `scale`: How much of the noise it shows across the image: larger is finer.
  - returns: The image.

  The same arguments give the same image on every target. The longer side is scaled to keep the noise square.
- `cellular`: Returns cellular (Worley) noise in gray, opaque: each pixel's distance to the nearest of points scattered one to a tile.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `tileSize`: The size of the square tiles, in pixels; clamped to 1 or more. Bigger is bigger cells.
  - `random`: The generator the points are drawn from, two numbers a tile (its y, then its x), rows top first.
  - returns: The image.

  A tile left over at the right or bottom edge has no point of its own.
- `path`: Gets the path it was loaded from, or "" for one made or decoded from bytes.
- `width`: Gets the width, in pixels.
- `height`: Gets the height, in pixels.
- `pixels`: Gets the pixels: 8-bit red, green, blue and alpha, `width * height * 4` bytes, rows top first, alpha not premultiplied.
- `copy`: Returns a copy, its path "".
  - returns: The copy.
- `getChannel`: Returns one channel as gray, opaque.
  - `channel`: The channel: 0 red, 1 green, 2 blue, 3 alpha; clamped to 0 to 3.
  - returns: The image, each pixel's red, green and blue the channel's value.
- `crop`: Returns a rectangle of it.
  - `x`: The rectangle's left edge, in pixels.
  - `y`: Its top edge.
  - `width`: Its width, in pixels.
  - `height`: Its height.
  - returns: The image.

  The rectangle is clamped to the image; one wholly outside it gives an image 0 by 0.
- `resize`: Returns it scaled to a size.
  - `width`: The width, in pixels; 0 or less gives an image 0 by 0.
  - `height`: The height, in pixels; 0 or less gives an image 0 by 0.
  - `filter`: How the pixels between pixels are made.
  - returns: The image.

  `Nearest` is raylib's `ImageResizeNN`. `Bilinear` and `Bicubic` are this library's own (raylib's `ImageResize` is stb_image_resize2): they sample each pixel's middle, take the edge pixels beyond the edges, and weight colors by alpha, so clear pixels don't darken the colors beside them.
- `resizeCanvas`: Returns it on a canvas of another size.
  - `width`: The canvas's width, in pixels.
  - `height`: The canvas's height, in pixels.
  - `offsetX`: Where its left edge goes on the canvas, in pixels; negative crops its left.
  - `offsetY`: Where its top edge goes.
  - `fill`: The color of the canvas around it, as 0xAARRGGBB.
  - returns: The image.

  What falls outside the canvas is cropped.
- `toPowerOfTwo`: Returns it on the smallest canvas whose sides are powers of two, at the top-left.
  - `fill`: The color of the canvas around it, as 0xAARRGGBB.
  - returns: The image: a copy when its sides are powers of two already.
- `cropAlpha`: Returns it cropped to the pixels whose alpha is over a threshold.
  - `threshold`: The threshold, 0 to 1, in 255ths: the rest of it is dropped.
  - returns: The image: a copy when no pixel is over it.
- `rotate`: Returns it turned by an angle, on a canvas big enough to hold it, transparent around it.
  - `radians`: The angle, in radians clockwise.
  - returns: The image.

  Each pixel blends the four it falls between, alpha not weighted.
- `rotateClockwise`: Returns it turned a quarter turn clockwise.
  - returns: The image, its width and height swapped.
- `rotateCounterclockwise`: Returns it turned a quarter turn counterclockwise.
  - returns: The image, its width and height swapped.
- `getMipmaps`: Returns its mipmap chain, the levels after it: each half the size of the last, rounded down, down to 1 by 1.
  - returns: The levels, largest first; none for an image 1 by 1 or empty.

  Each level is the last one resized `Bilinear`, which at exactly half the size is the average of each 2 by 2 square, weighted by alpha. (raylib's `ImageMipmaps` resizes with stb_image_resize2.)
- `flipVertical`: Turns it upside down.
  - returns: This image.
- `flipHorizontal`: Mirrors it left to right.
  - returns: This image.
- `tint`: Multiplies each pixel by a color, channel by channel, alpha included: white leaves it unchanged.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.
- `invert`: Inverts each pixel's red, green and blue; alpha is unchanged.
  - returns: This image.
- `grayscale`: Makes it gray, by luminance (0.299 red, 0.587 green, 0.114 blue); alpha is unchanged.
  - returns: This image.
- `contrast`: Changes its contrast: red, green and blue pushed away from mid-gray, or pulled toward it; alpha is unchanged.
  - `amount`: How far, -100 (all mid-gray) to 100 (the most); 0 leaves it unchanged. Clamped to -100 to 100.
  - returns: This image.
- `brighten`: Changes its brightness: the same amount added to red, green and blue; alpha is unchanged.
  - `amount`: The amount, -255 to 255; clamped to that.
  - returns: This image.

  A channel taken below 0 becomes 1, not 0, as raylib's does; one taken over 255 becomes 255.
- `replaceColor`: Changes every pixel of one color to another.
  - `from`: The color changed, as 0xAARRGGBB, alpha included.
  - `to`: The color it becomes.
  - returns: This image.
- `clearAlpha`: Changes every pixel whose alpha is at or under a threshold to a color.
  - `color`: The color, as 0xAARRGGBB.
  - `threshold`: The threshold, 0 to 1, in 255ths: the rest of it is dropped.
  - returns: This image.
- `maskAlpha`: Takes its alpha from another image of the same size: the mask's luminance (0.299 red, 0.587 green, 0.114 blue).
  - `mask`: The mask.
  - returns: This image.

  A white mask leaves it opaque, a black one clear; the mask's own alpha is ignored. A mask of another size changes nothing.
- `premultiplyAlpha`: Multiplies each pixel's red, green and blue by its alpha, rounding down.
  - returns: This image.
- `blur`: Blurs it: an approximate Gaussian, four passes of a box blur across and down, over premultiplied alpha.
  - `radius`: How far each box reaches either side of a pixel, in pixels; 0 or less changes nothing.
  - returns: This image.
- `convolve`: Applies a square kernel to red, green and blue; alpha is unchanged.
  - `kernel`: The weights, rows top first: 9 for 3 by 3, 25 for 5 by 5, any square count. Another count changes nothing.
  - returns: This image.

  Each channel is the sum of the pixels around it times the kernel's weights, as fractions of 255, clamped to 0 to 1. A pixel past the left or right edge is taken from the row beside, and one past the top or bottom counts as black, as raylib's does. A kernel of even width reaches one pixel further up and left.
- `dither`: Dithers it to fewer bits a channel (Floyd-Steinberg), its pixels left 8-bit at the levels those bits hold.
  - `redBits`: Red's bits, 0 to 8; clamped to that. 8 keeps its levels.
  - `greenBits`: Green's bits.
  - `blueBits`: Blue's bits.
  - `alphaBits`: Alpha's bits.
  - returns: This image.

  Each channel is cut to its top bits, and what was cut is spread to the pixels right and below. A level is widened back as raylib's `ImageFormat` widens a 16-bit format to 8 bits: 5 bits' 31 becomes 255, 4 bits' 15 becomes 254. Alpha is cut and not spread; with 0 alpha bits it is opaque.
- `getPixel`: Returns a pixel's color.
  - `x`: The pixel's column, from the left.
  - `y`: Its row, from the top.
  - returns: The color, as 0xAARRGGBB; 0 (clear black) outside the image.
- `getPalette`: Returns its colors, each once, in the order first met, rows top first; clear pixels (alpha 0) are skipped.
  - `max`: The most colors returned.
  - returns: The colors, as 0xAARRGGBB.
- `getAlphaBorder`: Returns the smallest rectangle holding every pixel whose alpha is over a threshold.
  - `threshold`: The threshold, 0 to 1, in 255ths: the rest of it is dropped.
  - `out`: Optional. The bounds to set and return; new ones when omitted.
  - returns: The bounds, in pixels, from the first pixel's top-left to past the last's bottom-right; empty when no pixel is over it.
- `fill`: Fills it with a color.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.
- `setPixel`: Sets a pixel; one outside the image is skipped.
  - `x`: The pixel's column, from the left.
  - `y`: Its row, from the top.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.
- `drawLine`: Draws a line one pixel wide, from its start to its end, both drawn; the rows (or columns) it steps across are rounded to the nearest.
  - `x0`: The start's column, in pixels from the left.
  - `y0`: The start's row, from the top.
  - `x1`: The end's column.
  - `y1`: The end's row.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.
- `drawThickLine`: Draws a line of a thickness: as many `drawLine`s as it is thick, side by side, below and above the line for a line more across than down, right and left of it otherwise, the odd one out below or right.
  - `x0`: The start's x, in pixels from the left.
  - `y0`: The start's y, from the top.
  - `x1`: The end's x.
  - `y1`: The end's y.
  - `thickness`: The thickness, in pixels; less than 1 draws the line alone.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.

  The ends are rounded to whole pixels; a line from a pixel to itself draws nothing.
- `drawCircle`: Fills a circle (midpoint algorithm), each row as wide either side of the middle.
  - `x`: The middle's column, in pixels from the left.
  - `y`: The middle's row, from the top.
  - `radius`: The radius, in pixels.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.
- `drawCircleLines`: Outlines a circle, one pixel wide (midpoint algorithm).
  - `x`: The middle's column, in pixels from the left.
  - `y`: The middle's row, from the top.
  - `radius`: The radius, in pixels.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.
- `drawRectangle`: Fills a rectangle; what falls outside the image is skipped.
  - `x`: The left edge, in pixels.
  - `y`: The top edge.
  - `width`: The width, in pixels.
  - `height`: The height.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.

  A rectangle 0 wide still sets its top-left pixel, and one 0 high its top row, as raylib's does (its circles rely on it).
- `drawRectangleLines`: Outlines a rectangle, the outline inside it.
  - `x`: The left edge, in pixels.
  - `y`: The top edge.
  - `width`: The width, in pixels.
  - `height`: The height.
  - `thickness`: The outline's thickness, in pixels.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.
- `drawTriangle`: Fills a triangle, each corner its own color, blended across it.
  - `x0`: The first corner's x, in pixels from the left.
  - `y0`: The first corner's y, from the top.
  - `x1`: The second corner's x.
  - `y1`: The second corner's y.
  - `x2`: The third corner's x.
  - `y2`: The third corner's y.
  - `color0`: The first corner's color, as 0xAARRGGBB.
  - `color1`: The second corner's color.
  - `color2`: The third corner's color.
  - returns: This image.

  The corners may go either way round. When the three colors are the same the triangle is that color (raylib's `ImageDrawTriangle`); otherwise each channel is blended by the pixel's weights, each rounded down (raylib's `ImageDrawTriangleEx`).
- `drawTriangleLines`: Outlines a triangle with three `drawLine`s, its corners cut to whole pixels.
  - `x0`: The first corner's x, in pixels from the left.
  - `y0`: The first corner's y, from the top.
  - `x1`: The second corner's x.
  - `y1`: The second corner's y.
  - `x2`: The third corner's x.
  - `y2`: The third corner's y.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.
- `drawImage`: Draws a rectangle of another image into a rectangle of this one, tinted, blended over.
  - `source`: The image drawn from; it may be this one only when the rectangles don't overlap.
  - `sourceX`: The source rectangle's left edge, in the source's pixels.
  - `sourceY`: Its top edge.
  - `sourceWidth`: Its width.
  - `sourceHeight`: Its height.
  - `x`: The destination rectangle's left edge, in pixels.
  - `y`: Its top edge.
  - `width`: Its width.
  - `height`: Its height.
  - `tint`: The color the source is multiplied by, as 0xAARRGGBB: white leaves it unchanged.
  - returns: This image.

  The source rectangle is clamped to the source. When its whole-pixel size differs from the destination's it is resized `Bilinear` first (raylib's `ImageDraw` resizes with stb_image_resize2). Positions are cut to whole pixels.
- `drawText`: Draws text in a font, tinted, blended over.
  - `font`: The font.
  - `text`: The text.
  - `x`: The left edge of the text, in pixels.
  - `y`: The top of its first line, in pixels: its ascent above the baseline.
  - `size`: The height of a line, in pixels; the font's own size draws it unscaled.
  - `spacing`: The pixels added after each character, at the font's size.
  - `color`: The color, as 0xAARRGGBB.
  - returns: This image.

  The text is laid out at the font's size, as raylib's `ImageDrawTextEx` lays it, then scaled to `size` (`Bilinear`) and drawn: each glyph at the pen and its offsets, the pen moved by its advance (or its width, for a glyph advancing 0) and `spacing`. A newline starts the next line, the font's size and line gap below. A character the font lacks is drawn as its "?", or as its first glyph; spaces and tabs only move the pen.

## ImageFilter

*abstract* in [`libs/services/src/helix/services/images/ImageFilter.hx`](../src/helix/services/images/ImageFilter.hx), `import helix.services.images.ImageFilter;`

Specifies how `Image.resize` makes the pixels between the source's pixels.

- `ImageFilter.Nearest`: Takes the nearest pixel: hard edges, for pixel art.
- `ImageFilter.Bilinear`: Blends the nearest four pixels, weighted by distance and by alpha.
- `ImageFilter.Bicubic`: Blends the nearest sixteen pixels on a Catmull-Rom curve, weighted by alpha: sharper than `Bilinear`, for photographs.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Nearest, Bilinear): what Std.string, interpolation and trace show.

## Images

*class* in [`libs/services/src/helix/services/images/Images.hx`](../src/helix/services/images/Images.hx), `import helix.services.images.Images;`, implements `IPollable`

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
function decodeForGpu(encoded:haxe.io.Bytes, decoded:IDecodedImage -> Void, ?failed:String -> Void):() -> Void
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
- `decodeForGpu`: Decodes an image file for the GPU (`IImageDecoder.decodeForGpu`): in a page the browser's decoded image, uploaded as it is by `IGraphics.createTextureFromImage`, so the program never holds its pixels; natively the pixels.
  - `encoded`: The image file's bytes.
  - `decoded`: Receives the image, which the receiver disposes once uploaded.
  - `failed`: Optional. Receives why it couldn't be decoded. When omitted, the failure is logged.
  - returns: A function that aborts the decode; neither callback is called after it, and once one was, it does nothing. An image decoded after the abort is disposed.

  One of `decoded` or `failed` is called once, at a later `poll`, never during this call.
- `poll`: Delivers what was loaded and decoded since the last poll.
- `dispose`: Aborts every load and decode in flight. The images aren't used after it.
