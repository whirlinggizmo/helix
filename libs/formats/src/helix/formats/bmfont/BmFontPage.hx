package helix.formats.bmfont;

/** Represents one page of a BMFont: an image holding some of its glyphs, named by its id. */
class BmFontPage {
	/** Gets the page's id, by which a glyph names the page it is on (`BmFontChar.page`). */
	public final id:Int;

	/** Gets the path of the page's image, resolved against the .fnt file's directory. */
	public final path:String;

	@:allow(helix.formats.bmfont)
	function new(id:Int, path:String) {
		this.id = id;
		this.path = path;
	}
}
