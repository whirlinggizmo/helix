# helix.formats.gif

[Back to the library](README.md)

## GifDisposal

*abstract* in [`libs/formats/src/helix/formats/gif/GifDisposal.hx`](../src/helix/formats/gif/GifDisposal.hx), `import helix.formats.gif.GifDisposal;`

Specifies what becomes of a GIF frame's rectangle before the next frame is drawn, as its graphic control block says.

- `GifDisposal.Unspecified`: Not said: the frame stays, as with `Keep`. A file's reserved values (4 to 7) are read as this.
- `GifDisposal.Keep`: The frame stays, and the next is drawn over it.
- `GifDisposal.Background`: The frame's rectangle is cleared, to transparent, as browsers clear it.
- `GifDisposal.Previous`: The frame's rectangle is put back as it was before the frame was drawn.

## GifFile

*class* in [`libs/formats/src/helix/formats/gif/GifFile.hx`](../src/helix/formats/gif/GifFile.hx), `import helix.formats.gif.GifFile;`

Represents a GIF file (GIF87a or GIF89a): its screen, its global color table and loop count, and its frames as the file gives them.

Every frame is read, its LZW data decoded and its interlaced rows put in order, with its graphic control block's transparency, disposal and delay. `computeFrames` draws them onto the screen in turn, as a browser shows them.

```haxe
var gif = GifFile.read(bytes);
var frames = gif.computeFrames();
trace(gif.width, gif.height, frames.length, gif.frames[0].delay);
```

```haxe
static function read(data:haxe.io.Bytes, ?maxFrameCount:Int):GifFile
final width:Int
final height:Int
final colors:Null<Array<Int>>
final backgroundIndex:Int
final loopCount:Int
final frames:Array<GifFrame>
function computeFrames():Array<haxe.io.Bytes>
```

- `read`: Reads a GIF file.
  - `data`: The file.
  - `maxFrameCount`: Optional. The most frames to read; every frame when omitted.
  - returns: The file's screen and frames.
  - throws `String`: It isn't a GIF file (its signature is wrong, or its screen is 0 pixels wide or high, or over 400 million pixels), or it is broken: it ends inside a block, a frame lies outside the screen, has no color table, or has image data that is wrong or ends before its last pixel, a graphic control block isn't 4 bytes, or a block is of no kind GIF has.

  A file ending where a block would start, without its trailer, is read up to there. Blocks after the trailer are ignored, and so are extensions other than the graphic control block and the NETSCAPE2.0 (or ANIMEXTS1.0) loop count. A frame's image data holding more pixels than its rectangle has the rest ignored. With a frame limit, nothing after that many frames is read, so a file broken after them reads as those frames.
- `width`: Gets the screen's width, in pixels: the width of every frame `computeFrames` returns.
- `height`: Gets the screen's height, in pixels.
- `colors`: Gets the global color table, each color `0xFFRRGGBB`, or null when the file has none.
- `backgroundIndex`: Gets the global color table's index of the background color, as the file gives it. Browsers don't draw it; the screen starts transparent.
- `loopCount`: Gets the loop count of the file's NETSCAPE2.0 block: 0 to loop forever, or how many times it loops; -1 when the file has none.
- `frames`: Gets the frames, in the file's order. A file may have none.
- `computeFrames`: Returns each frame as a browser shows it: the whole screen after the frame is drawn, RGBA, 8 bits a channel, rows top first.
  - returns: Each frame's pixels, `width * height * 4` bytes, in the frames' order.
  - throws `String`: The frames take over 2 GB.

  The screen starts transparent (every byte 0). Each frame is drawn over what the frames before left: its pixels of its transparent index, or of an index past its color table's end, aren't drawn, and the rest are opaque. Before the next frame is drawn, the frame's rectangle is disposed of as its `disposal` says: kept, cleared to transparent, or put back as it was before the frame.

## GifFrame

*class* in [`libs/formats/src/helix/formats/gif/GifFrame.hx`](../src/helix/formats/gif/GifFrame.hx), `import helix.formats.gif.GifFrame;`

Represents one frame of a GIF file as the file gives it: its rectangle of the screen, its color indices and color table, and its graphic control block's transparency, disposal and delay.

`GifFile.computeFrames` draws the frames onto the screen in turn, as a viewer shows them.

```haxe
final x:Int
final y:Int
final width:Int
final height:Int
final interlaced:Bool
final colors:Array<Int>
final indices:haxe.io.Bytes
final transparentIndex:Int
final disposal:GifDisposal
final delay:Float
```

- `x`: Gets the rectangle's left edge, in pixels from the screen's left.
- `y`: Gets the rectangle's top edge, in pixels from the screen's top.
- `width`: Gets the rectangle's width, in pixels.
- `height`: Gets the rectangle's height, in pixels.
- `interlaced`: Gets a value indicating whether the file stores the rows interlaced. `indices` holds them in order either way.
- `colors`: Gets the color table the frame's pixels are drawn from: its own, or else the file's global one. Each color is `0xFFRRGGBB`.
- `indices`: Gets the color index of each pixel, a byte each, rows top first, `width * height` bytes. An index past the color table's end is as the file gives it.
- `transparentIndex`: Gets the index whose pixels aren't drawn, or -1 when every pixel is drawn.
- `disposal`: Gets what becomes of the rectangle before the next frame is drawn.
- `delay`: Gets how long the frame shows before the next, in seconds: the file's hundredths of a second. 0 when the file gives none.
