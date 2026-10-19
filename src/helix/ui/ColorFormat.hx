package helix.ui;

/** How a color picker's text field writes and reads its color (ColorPicker.format). */
enum ColorFormat {
	/** Hex digits: RRGGBBAA, or RRGGBB without alpha (ColorPicker.formatHex, parseHex). */
	Hex;

	/** The channels in decimal, 0 to 255 each: r g b a, or r g b without alpha (ColorPicker.formatRgba, parseRgba). */
	Rgba;
}
