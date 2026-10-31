package helix.formats.bmfont;

/** Represents one glyph of a BMFont: where it is on its page, and how it is placed and advanced, in pixels. */
class BmFontChar {
	/** Gets the glyph's character: its Unicode codepoint (or its code in the font's charset when not Unicode). */
	public final id:Int;

	/** Gets the left of the glyph's rectangle on its page, in pixels. */
	public final x:Int;

	/** Gets the top of the glyph's rectangle on its page, in pixels, y down. */
	public final y:Int;

	/** Gets the width of the glyph's rectangle on its page, in pixels. */
	public final width:Int;

	/** Gets the height of the glyph's rectangle on its page, in pixels. */
	public final height:Int;

	/** Gets how far right of the pen the rectangle is drawn, in pixels. */
	public final xOffset:Int;

	/** Gets how far below the line's top the rectangle is drawn, in pixels, y down. */
	public final yOffset:Int;

	/** Gets how far the pen moves right after the glyph, in pixels. */
	public final xAdvance:Int;

	/** Gets the id of the page the glyph is on (`BmFontPage.id`). */
	public final page:Int;

	/** Gets the color channels the glyph is in: 1 blue, 2 green, 4 red, 8 alpha, 15 all four. */
	public final channel:Int;

	@:allow(helix.formats.bmfont)
	function new(id:Int, x:Int, y:Int, width:Int, height:Int, xOffset:Int, yOffset:Int, xAdvance:Int, page:Int, channel:Int) {
		this.id = id;
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.xOffset = xOffset;
		this.yOffset = yOffset;
		this.xAdvance = xAdvance;
		this.page = page;
		this.channel = channel;
	}
}
