package helix.raylib;

/** Represents raylib's `Font`: its glyphs, their places on its texture, and the texture. */
class Font {
	/** Gets or sets the size it was made at: its glyphs' height, in pixels. */
	public var baseSize:Int = 0;

	/** Gets or sets how many glyphs it has. */
	public var glyphCount:Int = 0;

	/** Gets or sets the padding around each glyph on its texture, in pixels. */
	public var glyphPadding:Int = 0;

	/** Gets or sets the texture its glyphs are drawn from. */
	public var texture:Texture2D;

	/** Gets or sets each glyph's rectangle on the texture. */
	public var recs:Array<Rectangle> = [];

	/** Gets or sets each glyph's character, offsets, advance and image. */
	public var glyphs:Array<GlyphInfo> = [];

	// The image its texture was made from, and the texture's id, so ExportFontAsCode reads the texture's pixels as raylib reads them back
	// from the GPU, in the texture's format; null for a font made otherwise.
	@:allow(helix.raylib)
	var atlas:Null<Image> = null;

	@:allow(helix.raylib)
	var atlasTexture = 0;

	/** Creates a font, its fields zero or empty. Fonts are made by `Raylib.GetFontDefault`, `Raylib.LoadFontExAsync` and the other loads. */
	public function new() {}
}
