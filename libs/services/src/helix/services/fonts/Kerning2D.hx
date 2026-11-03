package helix.services.fonts;

/** Represents a kerning pair of a font: how far the pen moves when one character follows another, beyond the first's advance. */
typedef Kerning2D = {
	/** The first character. */
	final first:Int;

	/** The character following it. */
	final second:Int;

	/** How far the pen moves right between them, in pixels at the font's size: negative to close up. */
	final amount:Float;
}
