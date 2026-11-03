package helix.formats.gif;

import haxe.io.Bytes;

/** Represents one frame of a GIF file as the file gives it: its rectangle of the screen, its color indices and color table, and its
	graphic control block's transparency, disposal and delay.

	`GifFile.computeFrames` draws the frames onto the screen in turn, as a viewer shows them. */
class GifFrame {
	/** Gets the rectangle's left edge, in pixels from the screen's left. */
	public final x:Int;

	/** Gets the rectangle's top edge, in pixels from the screen's top. */
	public final y:Int;

	/** Gets the rectangle's width, in pixels. */
	public final width:Int;

	/** Gets the rectangle's height, in pixels. */
	public final height:Int;

	/** Gets a value indicating whether the file stores the rows interlaced. `indices` holds them in order either way. */
	public final interlaced:Bool;

	/** Gets the color table the frame's pixels are drawn from: its own, or else the file's global one. Each color is `0xFFRRGGBB`. */
	public final colors:Array<Int>;

	/** Gets the color index of each pixel, a byte each, rows top first, `width * height` bytes. An index past the color table's end is
		as the file gives it. */
	public final indices:Bytes;

	/** Gets the index whose pixels aren't drawn, or -1 when every pixel is drawn. */
	public final transparentIndex:Int;

	/** Gets what becomes of the rectangle before the next frame is drawn. */
	public final disposal:GifDisposal;

	/** Gets how long the frame shows before the next, in seconds: the file's hundredths of a second. 0 when the file gives none. */
	public final delay:Float;

	@:allow(helix.formats.gif)
	function new(x:Int, y:Int, width:Int, height:Int, interlaced:Bool, colors:Array<Int>, indices:Bytes, transparentIndex:Int, disposal:GifDisposal,
			delay:Float) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.interlaced = interlaced;
		this.colors = colors;
		this.indices = indices;
		this.transparentIndex = transparentIndex;
		this.disposal = disposal;
		this.delay = delay;
	}
}
