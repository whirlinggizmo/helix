package helix.formats.bmfont;

/** Represents one kerning pair of a BMFont: how far the pen moves when one glyph follows another. */
class BmFontKerning {
	/** Gets the first glyph's character (`BmFontChar.id`). */
	public final first:Int;

	/** Gets the second glyph's character, the one following the first (`BmFontChar.id`). */
	public final second:Int;

	/** Gets how far the pen moves right, in pixels, after the first glyph's advance and before the second: negative to close up. */
	public final amount:Int;

	@:allow(helix.formats.bmfont)
	function new(first:Int, second:Int, amount:Int) {
		this.first = first;
		this.second = second;
		this.amount = amount;
	}
}
