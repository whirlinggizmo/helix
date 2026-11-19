package helix.raylib;

/** Represents one character of a `Font`: its code point, where it sits against the pen, how far the pen moves after it, and its
	image. `Font.glyphs` holds a font's, and `GetGlyphInfo` returns one. */
class GlyphInfo {
	/** Gets or sets the character's code point (Unicode). */
	public var value:Int = 0;

	/** Gets or sets how far right of the pen the character's image is drawn, in pixels. */
	public var offsetX:Int = 0;

	/** Gets or sets how far below the line's top the character's image is drawn, in pixels. */
	public var offsetY:Int = 0;

	/** Gets or sets how far the pen moves right after the character, in pixels; 0 to move by its rectangle's width and `offsetX`. */
	public var advanceX:Int = 0;

	/** Gets or sets the character's image. */
	public var image:Image;

	/** Creates a glyph, its fields zero and its image null. */
	public function new() {}
}
