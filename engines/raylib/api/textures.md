# rtextures: textures, render textures and colors

[Back to the library](README.md)


```haxe
static function UnloadTexture(texture:Texture2D):Void
static function IsTextureValid(texture:Texture2D):Bool
static function DrawTexture(texture:Texture2D, posX:Int, posY:Int, tint:Color):Void
static function DrawTextureV(texture:Texture2D, position:Vector2, tint:Color):Void
static function DrawTextureEx(texture:Texture2D, position:Vector2, rotation:Float, scale:Float, tint:Color):Void
static function DrawTextureRec(texture:Texture2D, source:Rectangle, position:Vector2, tint:Color):Void
static function DrawTexturePro(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void
static function ColorNormalize(color:Color):Vector4
static function ColorFromNormalized(normalized:Vector4):Color
static function Fade(color:Color, alpha:Float):Color
static function ColorAlpha(color:Color, alpha:Float):Color
static function ColorIsEqual(col1:Color, col2:Color):Bool
static function ColorToInt(color:Color):Int
static function ColorToHSV(color:Color):Vector3
static function ColorFromHSV(hue:Float, saturation:Float, value:Float):Color
static function ColorTint(color:Color, tint:Color):Color
static function ColorBrightness(color:Color, factor:Float):Color
static function ColorContrast(color:Color, contrast:Float):Color
static function ColorAlphaBlend(dst:Color, src:Color, tint:Color):Color
static function ColorLerp(color1:Color, color2:Color, factor:Float):Color
static function GetColor(hexValue:Int):Color
static function GetPixelDataSize(width:Int, height:Int, format:Int):Int
static function LoadRenderTexture(width:Int, height:Int):RenderTexture2D
static function IsRenderTextureValid(target:RenderTexture2D):Bool
static function UnloadRenderTexture(target:RenderTexture2D):Void
static function BeginTextureMode(target:RenderTexture2D):Void
static function EndTextureMode():Void
static function SetTextureFilter(texture:Texture2D, filter:Int):Void
static function GenTextureMipmaps(texture:Texture2D):Void
static function IsImageValid(image:Image):Bool
static function UnloadImage(image:Image):Void
static function ExportImageToMemory(image:Image, fileType:String, fileSize:Array<Int>):haxe.io.Bytes
static function GenImageColor(width:Int, height:Int, color:Color):Image
static function GenImageGradientLinear(width:Int, height:Int, direction:Int, start:Color, end:Color):Image
static function GenImageGradientRadial(width:Int, height:Int, density:Float, inner:Color, outer:Color):Image
static function GenImageGradientSquare(width:Int, height:Int, density:Float, inner:Color, outer:Color):Image
static function GenImageChecked(width:Int, height:Int, checksX:Int, checksY:Int, col1:Color, col2:Color):Image
static function GenImageWhiteNoise(width:Int, height:Int, factor:Float):Image
static function GenImagePerlinNoise(width:Int, height:Int, offsetX:Int, offsetY:Int, scale:Float):Image
static function GenImageCellular(width:Int, height:Int, tileSize:Int):Image
static function GenImageText(width:Int, height:Int, text:String):Image
static function ImageCopy(image:Image):Image
static function ImageFromImage(image:Image, rec:Rectangle):Image
static function ImageFromChannel(image:Image, selectedChannel:Int):Image
static function ImageText(text:String, fontSize:Int, color:Color):Image
static function ImageTextEx(font:Font, text:String, fontSize:Float, spacing:Float, tint:Color):Image
static function ImageFormat(image:Image, newFormat:Int):Void
static function ImageToPOT(image:Image, fill:Color):Void
static function ImageCrop(image:Image, crop:Rectangle):Void
static function ImageAlphaCrop(image:Image, threshold:Float):Void
static function ImageAlphaClear(image:Image, color:Color, threshold:Float):Void
static function ImageAlphaMask(image:Image, alphaMask:Image):Void
static function ImageAlphaPremultiply(image:Image):Void
static function ImageBlurGaussian(image:Image, blurSize:Int):Void
static function ImageKernelConvolution(image:Image, kernel:Array<Float>, kernelSize:Int):Void
static function ImageResize(image:Image, newWidth:Int, newHeight:Int):Void
static function ImageResizeNN(image:Image, newWidth:Int, newHeight:Int):Void
static function ImageResizeCanvas(image:Image, newWidth:Int, newHeight:Int, offsetX:Int, offsetY:Int, fill:Color):Void
static function ImageMipmaps(image:Image):Void
static function ImageDither(image:Image, rBpp:Int, gBpp:Int, bBpp:Int, aBpp:Int):Void
static function ImageFlipVertical(image:Image):Void
static function ImageFlipHorizontal(image:Image):Void
static function ImageRotate(image:Image, degrees:Int):Void
static function ImageRotateCW(image:Image):Void
static function ImageRotateCCW(image:Image):Void
static function ImageColorTint(image:Image, color:Color):Void
static function ImageColorInvert(image:Image):Void
static function ImageColorGrayscale(image:Image):Void
static function ImageColorContrast(image:Image, contrast:Float):Void
static function ImageColorBrightness(image:Image, brightness:Int):Void
static function ImageColorReplace(image:Image, color:Color, replace:Color):Void
static function LoadImageColors(image:Image):Array<Color>
static function LoadImagePalette(image:Image, maxPaletteSize:Int, colorCount:Array<Int>):Array<Color>
static function UnloadImageColors(colors:Array<Color>):Void
static function UnloadImagePalette(colors:Array<Color>):Void
static function GetImageAlphaBorder(image:Image, threshold:Float):Rectangle
static function GetImageColor(image:Image, x:Int, y:Int):Color
static function ImageClearBackground(dst:Image, color:Color):Void
static function ImageDrawPixel(dst:Image, posX:Int, posY:Int, color:Color):Void
static function ImageDrawPixelV(dst:Image, position:Vector2, color:Color):Void
static function ImageDrawLine(dst:Image, startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void
static function ImageDrawLineV(dst:Image, start:Vector2, end:Vector2, color:Color):Void
static function ImageDrawLineEx(dst:Image, start:Vector2, end:Vector2, thick:Int, color:Color):Void
static function ImageDrawCircle(dst:Image, centerX:Int, centerY:Int, radius:Int, color:Color):Void
static function ImageDrawCircleV(dst:Image, center:Vector2, radius:Int, color:Color):Void
static function ImageDrawCircleLines(dst:Image, centerX:Int, centerY:Int, radius:Int, color:Color):Void
static function ImageDrawCircleLinesV(dst:Image, center:Vector2, radius:Int, color:Color):Void
static function ImageDrawRectangle(dst:Image, posX:Int, posY:Int, width:Int, height:Int, color:Color):Void
static function ImageDrawRectangleV(dst:Image, position:Vector2, size:Vector2, color:Color):Void
static function ImageDrawRectangleRec(dst:Image, rec:Rectangle, color:Color):Void
static function ImageDrawRectangleLines(dst:Image, rec:Rectangle, thick:Int, color:Color):Void
static function ImageDrawTriangle(dst:Image, v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void
static function ImageDrawTriangleEx(dst:Image, v1:Vector2, v2:Vector2, v3:Vector2, c1:Color, c2:Color, c3:Color):Void
static function ImageDrawTriangleLines(dst:Image, v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void
static function ImageDrawTriangleFan(dst:Image, points:Array<Vector2>, pointCount:Int, color:Color):Void
static function ImageDrawTriangleStrip(dst:Image, points:Array<Vector2>, pointCount:Int, color:Color):Void
static function ImageDraw(dst:Image, src:Image, srcRec:Rectangle, dstRec:Rectangle, tint:Color):Void
static function ImageDrawText(dst:Image, text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void
static function ImageDrawTextEx(dst:Image, font:Font, text:String, position:Vector2, fontSize:Float, spacing:Float, tint:Color):Void
static function LoadTextureFromImage(image:Image):Texture2D
static function LoadTextureCubemap(image:Image, layout:Int):TextureCubemap
static function UpdateTexture(texture:Texture2D, pixels:Dynamic):Void
static function UpdateTextureRec(texture:Texture2D, rec:Rectangle, pixels:Dynamic):Void
static function SetTextureWrap(texture:Texture2D, wrap:Int):Void
static function DrawTextureNPatch(texture:Texture2D, nPatchInfo:NPatchInfo, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void
static function GetPixelColor(srcPtr:haxe.io.Bytes, format:Int, ?offset:Int = 0):Color
static function SetPixelColor(dstPtr:haxe.io.Bytes, color:Color, format:Int, ?offset:Int = 0):Void
static macro function LoadImageRaw(fileName:String, width:Int, height:Int, format:Int, headerSize:Int):Image
static macro function ExportImage(image:Image, fileName:String):Bool
static macro function ExportImageAsCode(image:Image, fileName:String):Bool
```

- `UnloadTexture`: Lets go of the program's hold on a texture from its load, and sets the texture's id to 0.
  - `texture`: The texture.

  The texture and its GPU copy are freed once nothing else holds them. Another load of its file, or a material map given it, keeps it until that lets go.

  Given a map's texture (`map.texture`), lets go of one hold and leaves the map's id. The map draws the texture while anything holds it, and lets go in turn when its material is freed. So `UnloadTexture(model.materials[0].maps[0].texture)` frees a texture a program gave a map without keeping it.
- `IsTextureValid`: Returns whether a texture was loaded.
  - `texture`: The texture.
  - returns: True when it holds an image.
- `DrawTexture`: Draws a texture, its top-left corner at a point.
  - `texture`: The texture.
  - `posX`: The x.
  - `posY`: The y.
  - `tint`: The color it is multiplied by; `WHITE` keeps it as it is.
- `DrawTextureV`: Draws a texture, its top-left corner at a point.
  - `texture`: The texture.
  - `position`: The point.
  - `tint`: The color it is multiplied by.
- `DrawTextureEx`: Draws a texture turned about its top-left corner and scaled.
  - `texture`: The texture.
  - `position`: The top-left corner.
  - `rotation`: Clockwise, in degrees.
  - `scale`: The scale.
  - `tint`: The color it is multiplied by.
- `DrawTextureRec`: Draws part of a texture.
  - `texture`: The texture.
  - `source`: The part, in the texture's pixels.
  - `position`: Where its top-left corner goes.
  - `tint`: The color it is multiplied by.

  A negative source width or height flips the part.
- `DrawTexturePro`: Draws part of a texture into a rectangle, turned about an origin.
  - `texture`: The texture.
  - `source`: The part, in the texture's pixels.
  - `dest`: Where it goes; its x and y are where the origin lands.
  - `origin`: The point it turns about, from dest's top-left corner.
  - `rotation`: Clockwise, in degrees.
  - `tint`: The color it is multiplied by.

  A negative source width or height flips the part.
- `ColorNormalize`: Returns a color as four numbers, 0 to 1 each.
  - `color`: The color.
  - returns: Red, green, blue and alpha as x, y, z and w.
- `ColorFromNormalized`: Returns a color from four numbers, 0 to 1 each.
  - `normalized`: Red, green, blue and alpha as x, y, z and w.
  - returns: The color.
- `Fade`: Returns a color with its alpha scaled.
  - `color`: The color.
  - `alpha`: 0 (clear) to 1 (as it is).
  - returns: The new color.
- `ColorAlpha`: Returns a color with an alpha.
  - `color`: The color.
  - `alpha`: 0 (clear) to 1 (opaque).
  - returns: The new color.
- `ColorIsEqual`: Returns whether two colors are the same, alpha too.
  - `col1`: One color.
  - `col2`: The other.
  - returns: True when red, green, blue and alpha are each equal.
- `ColorToInt`: Returns a color as one number, 0xRRGGBBAA.
  - `color`: The color.
  - returns: Red in the top byte, alpha in the bottom; a red of 128 or more makes it negative.
- `ColorToHSV`: Returns a color's hue, saturation and value.
  - `color`: The color; its alpha is ignored.
  - returns: The hue in degrees, 0 to 360, as x; the saturation and value, 0 to 1 each, as y and z. A gray's hue and saturation are 0.
- `ColorFromHSV`: Returns the color of a hue, saturation and value, its alpha 255.
  - `hue`: The hue, in degrees, 0 to 360.
  - `saturation`: 0 (gray) to 1.
  - `value`: 0 (black) to 1.
  - returns: The color.
- `ColorTint`: Returns a color multiplied by another, channel by channel.
  - `color`: The color.
  - `tint`: The color it is multiplied by; `WHITE` keeps it as it is.
  - returns: The new color.
- `ColorBrightness`: Returns a color made darker or lighter, its alpha kept.
  - `color`: The color.
  - `factor`: -1 (black) to 1 (white); 0 keeps it as it is.
  - returns: The new color.
- `ColorContrast`: Returns a color with more or less contrast about the middle gray, its alpha kept.
  - `color`: The color.
  - `contrast`: -1 (all middle gray) to 1; 0 keeps it as it is.
  - returns: The new color.
- `ColorAlphaBlend`: Returns a color drawn over another: the source, multiplied by a tint, blended into the destination by its alpha.
  - `dst`: The color underneath.
  - `src`: The color drawn over it.
  - `tint`: The color the source is multiplied by; `WHITE` keeps it as it is.
  - returns: The blend.
- `ColorLerp`: Returns a color part way from one color to another.
  - `color1`: The color at 0.
  - `color2`: The color at 1.
  - `factor`: How far, 0 to 1.
  - returns: The color between them.
- `GetColor`: Returns the color of one number, 0xRRGGBBAA.
  - `hexValue`: Red in the top byte, alpha in the bottom.
  - returns: The color.
- `GetPixelDataSize`: Returns how many bytes an image's pixels take in a format.
  - `width`: The width, in pixels.
  - `height`: The height.
  - `format`: The format (`PIXELFORMAT_*`).
  - returns: The bytes; a compressed format smaller than 4 by 4 pixels takes a whole block, 8 or 16 bytes. An unknown format, a width or height of 0 or less, and a size of 2 GB or more (with a warning) give 0.
- `LoadRenderTexture`: Makes a texture to draw into, with depth, 8-bit RGBA.
  - `width`: Its width, in pixels.
  - `height`: Its height.
  - returns: The render texture.

  What is drawn into the render texture stays from frame to frame.

  After a lost GPU context, the render texture is cleared and stays empty until drawn into again.
- `IsRenderTextureValid`: Returns whether a render texture was made.
  - `target`: The render texture.
  - returns: True when it was.
- `UnloadRenderTexture`: Frees a render texture.
  - `target`: The render texture.
- `BeginTextureMode`: Draws into a render texture until `EndTextureMode`, over what it holds.
  - `target`: The render texture.

  What was drawn into the render texture before, in this frame or an earlier one, stays until `ClearBackground` clears it.

  A render texture never drawn into holds transparent black.
- `EndTextureMode`: Goes back to drawing on the screen.
- `SetTextureFilter`: Sets how a texture is sampled when drawn larger or smaller, by whether it has mipmaps (`texture.mipmaps`, as this copy of it says).
  - `texture`: The texture.
  - `filter`: The filter (`TEXTURE_FILTER_*`).

  The filters:

  - `TEXTURE_FILTER_POINT`, the default: the nearest texel, of the nearest mipmap. - `TEXTURE_FILTER_BILINEAR`: the nearest four texels blended, of the nearest mipmap. - `TEXTURE_FILTER_TRILINEAR`: the nearest four of the two nearest mipmaps blended. Without mipmaps it is `TEXTURE_FILTER_BILINEAR`, with a warning. - `TEXTURE_FILTER_ANISOTROPIC_4X`, `8X` and `16X`: up to that many texels read along a surface seen at a slant, the filter left as it was. The GPU uses the anisotropy only with `TEXTURE_FILTER_TRILINEAR` on a mipmapped texture.

  A cubemap (`LoadTextureCubemap`) is left unchanged.
- `GenTextureMipmaps`: Makes a texture's mipmaps, down to 1 by 1, and sets `texture.mipmaps` to their count.
  - `texture`: The texture.

  The texture's filter is unchanged. A `SetTextureFilter` after the call reads the mipmaps.

  Each level is the rounded average of the 2 by 2 above it, made on the CPU, so the same on every target.

  A texture already drawn gets its mipmaps from its pixels read back from the GPU. Draws asked for before the call this frame don't use them.

  Skipped for a render texture or a cubemap, with a warning.
- `IsImageValid`: Returns whether an image holds pixels: data, a size, a format and a mipmap level.
  - `image`: The image.
  - returns: True when it does.
- `UnloadImage`: Frees an image's pixels.
  - `image`: The image.
- `ExportImageToMemory`: Returns an image encoded as a PNG file in memory.
  - `image`: The image.
  - `fileType`: ".png" or ".PNG".
  - `fileSize`: Its first element is set to the file's size, 0 for none.
  - returns: The file, or null for another type or an empty image.

  An image's bytes are read by its format as 8-bit gray, gray and alpha, RGB or RGBA.

  Any other format's bytes are read as RGBA. A 16-bit format has too few, and those it lacks read as 0.
- `GenImageColor`: Returns an image of one color, RGBA.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `color`: The color.
  - returns: The image.
- `GenImageGradientLinear`: Returns a gradient from one color to another, RGBA.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `direction`: The direction, in degrees: 0 top to bottom, 90 left to right.
  - `start`: The color it starts from.
  - `end`: The color it ends at.
  - returns: The image.
- `GenImageGradientRadial`: Returns a round gradient out from the middle, RGBA.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `density`: How far the inner color holds, 0 (the middle alone) to 1 (out to the nearer edge).
  - `inner`: The color in the middle.
  - `outer`: The color at the edge and beyond.
  - returns: The image.
- `GenImageGradientSquare`: Returns a square gradient out from the middle, RGBA.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `density`: How far the inner color holds, 0 (the middle alone) to 1 (out to the edges).
  - `inner`: The color in the middle.
  - `outer`: The color at the edges.
  - returns: The image.
- `GenImageChecked`: Returns a checkerboard of two colors, RGBA.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `checksX`: Each square's width, in pixels.
  - `checksY`: Each square's height, in pixels.
  - `col1`: The top-left square's color.
  - `col2`: The color of the squares beside it.
  - returns: The image.

  A square size under 1 is taken as 1.
- `GenImageWhiteNoise`: Returns white noise, RGBA, each pixel white or black.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `factor`: The chance of white, 0 to 1.
  - returns: The image.

  Each pixel draws one number from `GetRandomValue`, so `SetRandomSeed` repeats the image.
- `GenImagePerlinNoise`: Returns Perlin noise in gray, RGBA: stb_perlin's fractal noise, 6 octaves.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `offsetX`: How far it is moved left, in pixels.
  - `offsetY`: How far it is moved up, in pixels.
  - `scale`: How much of the noise it shows: larger is finer.
  - returns: The image.
- `GenImageCellular`: Returns cellular noise in gray, RGBA, each pixel its distance to the nearest of points scattered one a tile.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `tileSize`: The tiles' size, in pixels: bigger is bigger cells.
  - returns: The image.

  The points are drawn from `GetRandomValue`, so `SetRandomSeed` repeats the image.

  A tile size under 1 is taken as 1.
- `GenImageText`: Returns an image of text's bytes, grayscale: its UTF-8, a byte a pixel, rows top first, the rest black.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `text`: The text; null gives a black image.
  - returns: The image.
- `ImageCopy`: Returns a copy of an image, its mipmaps too.
  - `image`: The image.
  - returns: The copy.
- `ImageFromImage`: Returns a rectangle of an image, in its format.
  - `image`: The image.
  - `rec`: The rectangle, in pixels, cut to whole pixels.
  - returns: The image.

  A rectangle not wholly inside the image, of no size, or of a compressed image gives an empty image, with a warning.
- `ImageFromChannel`: Returns one channel of an image as grayscale: 0 red, 1 green, 2 blue, 3 alpha.
  - `image`: The image.
  - `selectedChannel`: The channel.
  - returns: The image.

  A channel the format lacks is taken from another, with a warning:

  - a one-channel format: its only channel - gray and alpha: its alpha - an RGB format: its red
- `ImageText`: Returns text in raylib's default font as an RGBA image.
  - `text`: The text.
  - `fontSize`: The height of a line, in pixels.
  - `color`: The color.
  - returns: The image.

  A size under 10 is drawn at 10.

  The letters are a tenth of the size apart.
- `ImageTextEx`: Returns text in a font as an RGBA image.
  - `font`: The font, its glyphs' images drawn.
  - `text`: The text; null gives an empty image.
  - `fontSize`: The height of a line, in pixels.
  - `spacing`: The space between letters, at the font's size.
  - `tint`: The color the glyphs are multiplied by.
  - returns: The image.

  Each glyph's image is drawn tinted at the font's size, then the whole is scaled to the size, nearest for the default font. Another font is scaled by `ImageResize`, whose pixels differ from raylib's.

  A newline starts a line one and a half of the font's size down. The image's height still counts each line as the size and `SetTextLineSpacing`'s spacing.
- `ImageFormat`: Converts an image to another pixel format.
  - `image`: The image.
  - `newFormat`: The format (`PIXELFORMAT_UNCOMPRESSED_*`); a compressed one is refused, with a warning.

  The conversion runs through floats. Grayscale is by luminance (0.299 red, 0.587 green, 0.114 blue), R32 and R16 become their luminance, and 16-bit channels are rounded.

  An image with mipmaps has them made again.
- `ImageToPOT`: Puts an image on the smallest canvas whose sides are powers of two, at its top-left.
  - `image`: The image.
  - `fill`: The color of the canvas around it.
- `ImageCrop`: Crops an image to a rectangle, cut to the image.
  - `image`: The image.
  - `crop`: The rectangle, in pixels.

  A rectangle whose corner is past the image's right or bottom edge leaves the image unchanged, with a warning.

  The image's mipmaps are dropped, though its mipmap count is kept.
- `ImageAlphaCrop`: Crops an image to the pixels whose alpha is over a threshold, when any is.
  - `image`: The image.
  - `threshold`: The threshold, 0 to 1.
- `ImageAlphaClear`: Sets every pixel whose alpha is at or under a threshold to a color.
  - `image`: The image.
  - `color`: The color.
  - `threshold`: The threshold, 0 to 1.

  The formats with alpha change:

  - gray and alpha - R5G5B5A1: the alpha bit tested against a threshold of 0.5, the color's channels cut to 5 bits, unscaled - R4G4B4A4: the alpha's 4 bits tested against the threshold in 16 steps, the color's channels cut to 4 bits, unscaled - RGBA, and its 32-bit and 16-bit float forms

  Another format is unchanged.
- `ImageAlphaMask`: Sets an image's alpha from the grayscale of a mask the same size.
  - `image`: The image.
  - `alphaMask`: The mask.

  A grayscale image becomes gray and alpha, any other RGBA.

  A mask of another size changes nothing, with a warning.
- `ImageAlphaPremultiply`: Multiplies each pixel's red, green and blue by its alpha, rounding down, in the image's format.
  - `image`: The image.
- `ImageBlurGaussian`: Blurs an image with an approximate Gaussian, four passes of a box blur across and down.
  - `image`: The image.
  - `blurSize`: How far each box reaches either side of a pixel, in pixels.

  The blur runs over premultiplied alpha, and each channel taken back from it is no higher than 255.

  A box reaching past the image's last pixel reads 0 there.
- `ImageKernelConvolution`: Applies a square kernel to an image, each channel, alpha too, the sum of the pixels around it times the weights.
  - `image`: The image.
  - `kernel`: The weights, rows top first.
  - `kernelSize`: How many: 9 for 3 by 3, 25 for 5 by 5.

  The pixels are taken as fractions, and each sum is clamped to 0 to 1.

  A pixel past an edge is taken from the edge.

  A count that isn't square changes nothing, with a warning.
- `ImageResize`: Resizes an image with helix-services' `Bicubic` (Catmull-Rom, alpha-weighted).
  - `image`: The image.
  - `newWidth`: The width, in pixels.
  - `newHeight`: The height, in pixels.

  The pixels differ from raylib's, which come from `stb_image_resize2`.

  An 8-bit format is resized in its channels, any other through RGBA.
- `ImageResizeNN`: Resizes an image to the nearest pixels, through RGBA, keeping its format.
  - `image`: The image.
  - `newWidth`: The width, in pixels.
  - `newHeight`: The height, in pixels.
- `ImageResizeCanvas`: Puts an image on a canvas of another size, in its format, at an offset, cropping what falls outside.
  - `image`: The image.
  - `newWidth`: The canvas's width, in pixels.
  - `newHeight`: The canvas's height, in pixels.
  - `offsetX`: Where the image's left edge goes; negative crops its left.
  - `offsetY`: Where its top edge goes.
  - `fill`: The canvas's color.

  The canvas is filled with a color as `SetPixelColor` writes it, so a float format's canvas stays zero.

  A canvas the image's size leaves the image unchanged.
- `ImageMipmaps`: Makes an image's mipmaps, down to 1 by 1, after its pixels, in its format.
  - `image`: The image.

  Levels the image has are kept.

  Each level is made by `ImageResize` from the last, so the levels differ from raylib's.
- `ImageDither`: Dithers an image to 16 bits a pixel or fewer (Floyd-Steinberg).
  - `image`: The image.
  - `rBpp`: Red's bits.
  - `gBpp`: Green's bits.
  - `bBpp`: Blue's bits.
  - `aBpp`: Alpha's bits.

  The image becomes R5G6B5, R5G5B5A1 or R4G4B4A4 when the bits are one of those. Other bits give format 0 with the bits packed in 16, and a warning.

  More than 16 bits changes nothing, with a warning.
- `ImageFlipVertical`: Turns an image upside down, in its format.
  - `image`: The image.

  The image's mipmaps are dropped, though its mipmap count is kept.
- `ImageFlipHorizontal`: Mirrors an image left to right, in its format.
  - `image`: The image.

  The image's mipmaps are dropped, though its mipmap count is kept.
- `ImageRotate`: Turns an image by an angle, on a canvas big enough to hold it, clear around it.
  - `image`: The image.
  - `degrees`: The angle, in degrees clockwise.

  Each byte of a pixel blends the four it falls between, in every format.
- `ImageRotateCW`: Turns an image a quarter turn clockwise, in its format.
  - `image`: The image.
- `ImageRotateCCW`: Turns an image a quarter turn counterclockwise, in its format.
  - `image`: The image.
- `ImageColorTint`: Multiplies each pixel by a color, channel by channel, alpha too, in the image's format.
  - `image`: The image.
  - `color`: The color; `WHITE` keeps it unchanged.
- `ImageColorInvert`: Inverts each pixel's red, green and blue, in the image's format.
  - `image`: The image.
- `ImageColorGrayscale`: Makes an image `PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`, its alpha dropped.
  - `image`: The image.
- `ImageColorContrast`: Changes an image's contrast, in its format.
  - `image`: The image.
  - `contrast`: -100 (all mid-gray) to 100; 0 leaves it unchanged.
- `ImageColorBrightness`: Changes an image's brightness by adding to red, green and blue, in its format.
  - `image`: The image.
  - `brightness`: -255 to 255.

  A channel taken below 0 becomes 1.
- `ImageColorReplace`: Changes every pixel of one color to another, in the image's format.
  - `image`: The image.
  - `color`: The color changed, alpha too.
  - `replace`: The color it becomes.
- `LoadImageColors`: Returns an image's pixels as colors.
  - `image`: The image.
  - returns: The colors, rows top first, or null for an image 0 wide or high.

  A 5-bit channel is read times 8, a 6-bit times 4 and a 4-bit times 17. R32 and R16 are read as red alone.
- `LoadImagePalette`: Returns an image's colors, each once, in the order first met.
  - `image`: The image.
  - `maxPaletteSize`: The most colors.
  - `colorCount`: Its first element is set to how many colors were found.
  - returns: `maxPaletteSize` colors, those found first, the rest `BLANK`; null for an image 0 wide or high.

  Clear pixels are skipped.
- `UnloadImageColors`: Frees colors `LoadImageColors` gave.
  - `colors`: The colors.

  Does nothing, as the colors need no freeing.
- `UnloadImagePalette`: Frees colors `LoadImagePalette` gave.
  - `colors`: The colors.

  Does nothing, as the colors need no freeing.
- `GetImageAlphaBorder`: Returns the smallest rectangle holding every pixel whose alpha is over a threshold.
  - `image`: The image.
  - `threshold`: The threshold, 0 to 1.
  - returns: The rectangle, in pixels; all zero when no pixel is over it.
- `GetImageColor`: Returns a pixel's color, as `LoadImageColors` reads it.
  - `image`: The image.
  - `x`: The pixel's column.
  - `y`: Its row.
  - returns: The color.

  A pixel outside the image is clear black, with a warning.
- `ImageClearBackground`: Fills an image with a color, in its format, as `ImageDrawPixel` writes it.
  - `dst`: The image.
  - `color`: The color.
- `ImageDrawPixel`: Sets a pixel, in the image's format.
  - `dst`: The image.
  - `posX`: The pixel's column.
  - `posY`: Its row.
  - `color`: The color.

  Grayscale is by luminance, a 16-bit format's channels are rounded, and R5G5B5A1's alpha bit is set over an alpha of 50.

  A pixel outside the image is skipped.
- `ImageDrawPixelV`: Sets a pixel, as `ImageDrawPixel` does, its position cut to whole pixels.
  - `dst`: The image.
  - `position`: The pixel.
  - `color`: The color.
- `ImageDrawLine`: Draws a line one pixel wide, from its start to its end, both drawn.
  - `dst`: The image.
  - `startPosX`: The start's column.
  - `startPosY`: The start's row.
  - `endPosX`: The end's column.
  - `endPosY`: The end's row.
  - `color`: The color.
- `ImageDrawLineV`: Draws a line one pixel wide, its ends rounded to whole pixels.
  - `dst`: The image.
  - `start`: The start.
  - `end`: The end.
  - `color`: The color.
- `ImageDrawLineEx`: Draws a line of a thickness, as many one-pixel lines side by side as it is thick.
  - `dst`: The image.
  - `start`: The start.
  - `end`: The end.
  - `thick`: The thickness, in pixels; less than 1 draws the line alone.
  - `color`: The color.

  A line more across than down gets its lines below and above it, any other right and left of it, the odd one out below or right.

  The ends are rounded to whole pixels. A line from a pixel to itself draws nothing.
- `ImageDrawCircle`: Fills a circle, each row as wide either side of the middle.
  - `dst`: The image.
  - `centerX`: The middle's column.
  - `centerY`: The middle's row.
  - `radius`: The radius, in pixels.
  - `color`: The color.
- `ImageDrawCircleV`: Fills a circle, its middle cut to whole pixels.
  - `dst`: The image.
  - `center`: The middle.
  - `radius`: The radius, in pixels.
  - `color`: The color.
- `ImageDrawCircleLines`: Outlines a circle, one pixel wide.
  - `dst`: The image.
  - `centerX`: The middle's column.
  - `centerY`: The middle's row.
  - `radius`: The radius, in pixels.
  - `color`: The color.
- `ImageDrawCircleLinesV`: Outlines a circle, one pixel wide, its middle cut to whole pixels.
  - `dst`: The image.
  - `center`: The middle.
  - `radius`: The radius, in pixels.
  - `color`: The color.
- `ImageDrawRectangle`: Fills a rectangle, skipping what falls outside the image.
  - `dst`: The image.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `color`: The color.
- `ImageDrawRectangleV`: Fills a rectangle, its corner and size cut to whole pixels.
  - `dst`: The image.
  - `position`: The top-left corner.
  - `size`: The width and height.
  - `color`: The color.
- `ImageDrawRectangleRec`: Fills a rectangle, cut to the image, then to whole pixels.
  - `dst`: The image.
  - `rec`: The rectangle, in pixels.
  - `color`: The color.

  A rectangle 0 wide still sets its top-left pixel.
- `ImageDrawRectangleLines`: Outlines a rectangle, the outline inside it: its top and bottom across its whole width, its sides between them.
  - `dst`: The image.
  - `rec`: The rectangle, in pixels, cut to whole pixels.
  - `thick`: The outline's thickness, in pixels.
  - `color`: The color.
- `ImageDrawTriangle`: Fills a triangle whose corners may go either way round.
  - `dst`: The image.
  - `v1`: The first corner.
  - `v2`: The second corner.
  - `v3`: The third corner.
  - `color`: The color.
- `ImageDrawTriangleEx`: Fills a triangle, each corner its own color, blended across it.
  - `dst`: The image.
  - `v1`: The first corner.
  - `v2`: The second corner.
  - `v3`: The third corner.
  - `c1`: The first corner's color.
  - `c2`: The second corner's color.
  - `c3`: The third corner's color.

  Each channel is weighted by the pixel's weights and rounded down, so three corners of one color may not give that color exactly.
- `ImageDrawTriangleLines`: Outlines a triangle with three `ImageDrawLine`s, its corners cut to whole pixels.
  - `dst`: The image.
  - `v1`: The first corner.
  - `v2`: The second corner.
  - `v3`: The third corner.
  - `color`: The color.
- `ImageDrawTriangleFan`: Fills a fan of triangles, each from the first point to the next two.
  - `dst`: The image.
  - `points`: The points, the first the fan's middle.
  - `pointCount`: How many; under 3 draws nothing.
  - `color`: The color.
- `ImageDrawTriangleStrip`: Fills a strip of triangles, each of three points in a row.
  - `dst`: The image.
  - `points`: The points.
  - `pointCount`: How many; under 3 draws nothing.
  - `color`: The color.
- `ImageDraw`: Draws a rectangle of one image into a rectangle of another, tinted and blended over (`ColorAlphaBlend`), in their formats.
  - `dst`: The image drawn into.
  - `src`: The image drawn from.
  - `srcRec`: The source rectangle, in its pixels, cut to it.
  - `dstRec`: The destination rectangle.
  - `tint`: The color the source is multiplied by; `WHITE` keeps it unchanged.

  A source with no alpha under an opaque tint is copied, the tint's color ignored.

  A float destination is unchanged, as `SetPixelColor` writes none.

  A source rectangle of another whole-pixel size than the destination's is first resized by `ImageResize`, whose pixels differ from raylib's.

  The images' mipmaps are drawn too, when both have them.
- `ImageDrawText`: Draws text in raylib's default font into an image, letters 1 pixel apart, as `ImageDrawTextEx` draws it.
  - `dst`: The image.
  - `text`: The text.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `fontSize`: The height of a line, in pixels.
  - `color`: The color.
- `ImageDrawTextEx`: Draws text in a font into an image: `ImageTextEx`'s image, drawn at a point.
  - `dst`: The image.
  - `font`: The font.
  - `text`: The text.
  - `position`: The top-left corner.
  - `fontSize`: The height of a line, in pixels.
  - `spacing`: The space between letters, at the font's size.
  - `tint`: The color.
- `LoadTextureFromImage`: Makes a texture of an image in any uncompressed format.
  - `image`: The image.
  - returns: The texture.

  The image's pixels go to the GPU as RGBA when the texture is first drawn, its mipmaps too when it has them (`ImageMipmaps`). A texture with mipmaps is filtered through them, trilinear.

  The texture's format is the image's, so a grayscale image's texture has `PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`.

  A compressed format gives no texture, with a warning.
- `LoadTextureCubemap`: Makes a cubemap of an image, its six faces laid out by a layout.
  - `image`: The image.
  - `layout`: The layout (`CUBEMAP_LAYOUT_*`).
  - returns: The cubemap; id 0 for none.

  The layouts:

  - `CUBEMAP_LAYOUT_LINE_VERTICAL`: a column, +X, -X, +Y, -Y, +Z, -Z from the top. A face is the image's height over 6. - `CUBEMAP_LAYOUT_LINE_HORIZONTAL`: a row, in that order from the left. A face is the image's width over 6. - `CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR`: 3 faces wide, 4 high, +Y, +X, -Y and -X down the middle column, +Z left of +X and -Z right of it. A face is the image's width over 3. - `CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE`: 4 faces wide, 3 high, +Y at the top of the second column, then -X, +Z, +X, -Z across, then -Y below +Z. A face is the image's width over 4. - `CUBEMAP_LAYOUT_AUTO_DETECT`: the layout the image's shape gives. A shape it doesn't know gives no cubemap, with a warning.

  Each face's rows run top first, as GL's cube faces take them.

  A column is read as it is, the face size squared times 6 pixels from the image's first, row after row. An image not 1 face by 6 is read across its rows.

  The other layouts draw each face onto magenta (`ImageDraw`). A translucent pixel is blended over the magenta. A face partly past the image's edge has its part inside stretched to the face, and a face wholly past it stays magenta.

  The cubemap's format is the image's. Its pixels are RGBA on the GPU, sampled linearly.

  An image with mipmaps gives a cubemap with mipmaps, sampled through them. A column's come from the image's levels, read as its first is. The other layouts' are made from each face, as GL's `glGenerateMipmap` makes them.

  No cubemap comes back, with a warning, for a face size of 0 (an image too small for its layout, or a layout raylib doesn't have), a compressed format, or an image too small for the column it is read as.

  The cubemap is a `Texture2D`'s record. A material's `MATERIAL_MAP_CUBEMAP`, `MATERIAL_MAP_IRRADIANCE` or `MATERIAL_MAP_PREFILTER` binds it to a shader's `samplerCube` (`DrawMesh`), as `SetShaderValueTexture` does. Drawn as a 2D texture, the cubemap draws nothing.

  `UnloadTexture` lets go of the cubemap, which is counted as any texture is.
- `UpdateTexture`: Replaces a texture's pixels on the GPU.
  - `texture`: The texture.
  - `pixels`: The pixels: their bytes (`haxe.io.Bytes`), or an array of `Color` (R8G8B8A8's bytes, as raylib's `Color *` is).

  The pixels are in the texture's format (`texture.format`), rows top first, its width by its height.

  Draws asked for before the call this frame show the new pixels too when they are on the screen or in a render texture drawn into since. Those in render textures drawn into before the call keep the old.

  Changes nothing, with a warning, for a render texture, a cubemap, a compressed format or too few pixels.
- `UpdateTextureRec`: Replaces a rectangle of a texture's pixels, as `UpdateTexture` does the whole.
  - `texture`: The texture.
  - `rec`: The rectangle, in pixels from the texture's top-left corner; its numbers are cut to whole pixels.
  - `pixels`: The rectangle's pixels, rows top first, in the texture's format: bytes, or an array of `Color`.

  A rectangle not inside the texture changes nothing.
- `SetTextureWrap`: Sets how a texture wraps past its edges: `TEXTURE_WRAP_REPEAT` (the default), `TEXTURE_WRAP_CLAMP` or `TEXTURE_WRAP_MIRROR_REPEAT`.
  - `texture`: The texture.
  - `wrap`: The wrap (`TEXTURE_WRAP_*`).

  `TEXTURE_WRAP_MIRROR_CLAMP` leaves the texture unchanged, with a warning.

  A cubemap is left unchanged.
- `DrawTextureNPatch`: Draws a texture as a nine-patch or a three-patch into a rectangle, turned about an origin, its corners kept and its edges and middle stretched.
  - `texture`: The texture.
  - `nPatchInfo`: The patch: its rectangle on the texture, its borders and its layout (`NPATCH_*`).
  - `dest`: Where it goes; its x and y are where the origin lands.
  - `origin`: The point it turns about, from dest's top-left corner.
  - `rotation`: Clockwise, in degrees.
  - `tint`: The color it is multiplied by.

  A rectangle smaller than the borders shrinks them and drops the middle.
- `GetPixelColor`: Returns one pixel's color from pixels in a format.
  - `srcPtr`: The pixels.
  - `format`: Their format (`PIXELFORMAT_UNCOMPRESSED_*`).
  - `offset`: Optional. The pixel's first byte; 0 when omitted.
  - returns: The color; clear black for a compressed format.

  16-bit channels are widened by integers, and floats are multiplied by 255.

  Takes the pixels and the pixel's first byte in place of raylib's pointer to the pixel.
- `SetPixelColor`: Writes one pixel's color into pixels in a format.
  - `dstPtr`: The pixels.
  - `color`: The color.
  - `format`: Their format (`PIXELFORMAT_UNCOMPRESSED_*`).
  - `offset`: Optional. The pixel's first byte; 0 when omitted.

  Grayscale is by luminance, and 16-bit channels are rounded. A float format is left unchanged.

  Takes the pixels and the pixel's first byte in place of raylib's pointer to the pixel.
- `LoadImageRaw`: Loads an image's raw pixels from a file, as `LoadImageRawAsync` loads them, and returns the image once they are read. See `LoadImage` for an encoded image file.
  - `fileName`: The file.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `format`: The pixel format (`PIXELFORMAT_*`).
  - `headerSize`: The bytes before the pixels.
  - returns: The image, or one that isn't valid (`IsImageValid`) when it couldn't be loaded. Why it couldn't is logged.
- `ExportImage`: Writes an image to a PNG, QOI or raw file, as `ExportImageAsync` writes it, and returns once it is written. See `ExportImageAsCode` for writing a C header.
  - `image`: The image.
  - `fileName`: The file; its extension chooses the format.
  - returns: Whether it was written. Why it wasn't is logged.
- `ExportImageAsCode`: Writes an image as a C header, as `ExportImageAsCodeAsync` writes it, and returns once it is written. See `ExportImage` for writing a PNG, QOI or raw file.
  - `image`: The image.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - returns: Whether it was written. Why it wasn't is logged.


```haxe
static function LoadImageRawAsync(fileName:String, width:Int, height:Int, format:Int, headerSize:Int, loaded:Image -> Void, ?failed:String -> Void):Void
static function LoadImageFromTextureAsync(texture:Texture2D, loaded:Image -> Void, ?failed:String -> Void):Void
static function LoadImageFromScreenAsync(loaded:Image -> Void, ?failed:String -> Void):Void
static function ExportImageAsync(image:Image, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function ExportImageAsCodeAsync(image:Image, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadImageRawAsync`: Asynchronously loads an image's raw pixels from a file, replacing raylib's `LoadImageRaw`. See `LoadImageAsync` for an encoded image file.
  - `fileName`: The file.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `format`: The pixel format (`PIXELFORMAT_*`).
  - `headerSize`: The bytes before the pixels, skipped when the file holds them and the pixels.
  - `loaded`: Receives the image.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  A file with fewer bytes than the pixels need fails.

  A file too small for the header and the pixels is read from its first byte.
- `LoadImageFromTextureAsync`: Asynchronously reads a texture's pixels into an RGBA image, replacing raylib's `LoadImageFromTexture`. See `LoadImageFromScreenAsync` for the screen.
  - `texture`: The texture.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The image is RGBA, whatever the texture's format.

  A texture on the GPU (one drawn, or a render texture) is read as the frames drawn so far left it.

  A render texture's rows come bottom first, as raylib's do, so its image is upside down.

  A texture updated this frame (`UpdateTexture`) is read once the frame is drawn, so the update shows.

  A texture not drawn yet is read from memory. raylib's default texture is its white pixel.

  A cubemap is read from the image it was made from while that is kept in memory. Its faces on the GPU aren't read.
- `LoadImageFromScreenAsync`: Asynchronously reads the screen into an RGBA image as the next frame ends, replacing raylib's `LoadImageFromScreen`. See `TakeScreenshotAsync` for saving the screen to a file.
  - `loaded`: Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The image is the framebuffer's size, not the screen's, rows top first, its alpha opaque.

  A call before `InitWindow` fails.
- `ExportImageAsync`: Asynchronously writes an image to a PNG, QOI or raw file through `SaveFileDataAsync`, replacing raylib's `ExportImage`. See `ExportImageAsCodeAsync` for writing a C header.
  - `image`: The image.
  - `fileName`: The file; its extension chooses the format.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't, such as an empty image or another extension; when omitted, it is logged.

  The file's extension chooses the format:

  - ".png": any uncompressed format. A format other than 8-bit grayscale, grayscale and alpha, RGB or RGBA is written as RGBA. - ".qoi": RGB or RGBA alone. - ".raw": the pixels as they are.

  The file is kept as `SaveFileDataAsync` keeps it. `TakeScreenshotAsync` writes a real file.
- `ExportImageAsCodeAsync`: Asynchronously writes an image as a C header through `SaveFileTextAsync`, replacing raylib's `ExportImageAsCode`. See `ExportImageAsync` for writing a PNG, QOI or raw file.
  - `image`: The image.
  - `fileName`: The file; its name, upper case, names the defines and the array.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The header holds:

  - the image's size and format, as defines. - its first level's pixels, as an array of bytes, 20 a line.
