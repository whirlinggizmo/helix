package helix.render;

/** Represents text laid out in lines: broken at line breaks and, given a width, wrapped between words, each line aligned in its box.

	It is made once and kept while its text stays the same, so a paragraph is laid out once, not each frame; assigning a property lays it
	out again the next time it is measured or drawn. `Batch2D.drawTextLayout` draws it. Lines wrap where a space is, the spaces at the end
	of a line not counted in its width; a word wider than the box is broken between its characters.

	```haxe
	var story = new TextLayout2D(font, "A long paragraph...", 18);
	story.maxWidth = 300;
	story.align = Center;
	batch.drawTextLayout(story, 20, 40);
	var below = 40 + story.height;
	``` */
class TextLayout2D {
	/** Gets or sets the font. */
	public var font(default, set):GpuFont2D;

	/** Gets or sets the text. */
	public var text(default, set):String;

	/** Gets or sets the size it is drawn at, as the font's size is measured, in the units it is drawn in. */
	public var size(default, set):Float;

	/** Gets or sets the width of its box, past which lines wrap: 0 for none, so lines break at line breaks alone. 0 until set; below 0
		is clamped to 0. */
	public var maxWidth(default, set):Float = 0;

	/** Gets or sets where each line sits across the box: Left until set. */
	public var align(default, set):TextAlign2D = Left;

	/** Gets or sets the distance from one line's top to the next's, as a multiple of the font's line height at `size`: 1 until set. */
	public var lineSpacing(default, set):Float = 1;

	/** Gets or sets the space added after each character, in the units it is drawn in, as `Batch2D.drawText`'s `letterSpacing`: 0
		until set. */
	public var letterSpacing(default, set):Float = 0;

	/** Gets or sets a value indicating whether pairs of characters are kerned as the font gives them, as `Batch2D.drawText`'s `kerned`:
		true until set. raylib's `DrawTextEx` doesn't kern. */
	public var kerned(default, set):Bool = true;

	/** Gets the width of its widest line, in the units it is drawn in. */
	public var width(get, never):Float;

	/** Gets the height of its lines, from the first's top to the last's bottom. */
	public var height(get, never):Float;

	/** Gets the number of lines, wrapped and broken; 1 for empty text. */
	public var lineCount(get, never):Int;

	/** Creates a layout of text in a font.

		@param font  The font.
		@param text  Optional. The text; defaults to empty.
		@param size  Optional. The size it is drawn at; the font's own when omitted. */
	public function new(font:GpuFont2D, text = "", ?size:Float) {
		this.font = font;
		this.text = text;
		this.size = size != null ? size : font.font.size;
	}

	function set_font(value:GpuFont2D):GpuFont2D {
		throw "helix-render: TextLayout2D.set_font is not yet built (stage 1)";
	}

	function set_text(value:String):String {
		throw "helix-render: TextLayout2D.set_text is not yet built (stage 1)";
	}

	function set_size(value:Float):Float {
		throw "helix-render: TextLayout2D.set_size is not yet built (stage 1)";
	}

	function set_maxWidth(value:Float):Float {
		throw "helix-render: TextLayout2D.set_maxWidth is not yet built (stage 1)";
	}

	function set_align(value:TextAlign2D):TextAlign2D {
		throw "helix-render: TextLayout2D.set_align is not yet built (stage 1)";
	}

	function set_lineSpacing(value:Float):Float {
		throw "helix-render: TextLayout2D.set_lineSpacing is not yet built (stage 1)";
	}

	function set_letterSpacing(value:Float):Float {
		throw "helix-render: TextLayout2D.set_letterSpacing is not yet built (stage 1)";
	}

	function set_kerned(value:Bool):Bool {
		throw "helix-render: TextLayout2D.set_kerned is not yet built (stage 1)";
	}

	function get_width():Float {
		throw "helix-render: TextLayout2D.get_width is not yet built (stage 1)";
	}

	function get_height():Float {
		throw "helix-render: TextLayout2D.get_height is not yet built (stage 1)";
	}

	function get_lineCount():Int {
		throw "helix-render: TextLayout2D.get_lineCount is not yet built (stage 1)";
	}
}
