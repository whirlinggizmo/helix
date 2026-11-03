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
		font = value;
		dirty = true;
		return value;
	}

	function set_text(value:String):String {
		text = value == null ? "" : value;
		dirty = true;
		return value;
	}

	function set_size(value:Float):Float {
		size = value;
		dirty = true;
		return value;
	}

	function set_maxWidth(value:Float):Float {
		maxWidth = value > 0 ? value : 0;
		dirty = true;
		return maxWidth;
	}

	function set_align(value:TextAlign2D):TextAlign2D {
		align = value;
		dirty = true;
		return value;
	}

	function set_lineSpacing(value:Float):Float {
		lineSpacing = value;
		dirty = true;
		return value;
	}

	function set_letterSpacing(value:Float):Float {
		letterSpacing = value;
		dirty = true;
		return value;
	}

	function set_kerned(value:Bool):Bool {
		kerned = value;
		dirty = true;
		return value;
	}

	function get_width():Float {
		layOut();
		return widest;
	}

	function get_height():Float {
		layOut();
		return font.heightOf(lines.length, scale, lineSpacing);
	}

	function get_lineCount():Int {
		layOut();
		return lines.length;
	}

	// The lines as laid out, each its characters and width; whether a property changed since.
	var dirty = true;

	@:allow(helix.render)
	final lines:Array<Array<Int>> = [];

	@:allow(helix.render)
	final widths:Array<Float> = [];

	var widest = 0.;

	@:allow(helix.render)
	var scale = 1.;

	// Lays the text out when a property changed: broken at line breaks, wrapped between words past maxWidth, a word wider than the box
	// broken between its characters; a line's spaces at its end not counted.

	@:allow(helix.render)
	function layOut():Void {
		if (!dirty)
			return;
		dirty = false;
		lines.resize(0);
		widths.resize(0);
		scale = font.scaleOf(size);
		for (paragraph in text.split("\n")) {
			var codes = GpuFont2D.codes(paragraph);
			if (maxWidth <= 0) {
				add(codes);
				continue;
			}
			var line:Array<Int> = [];
			var i = 0;
			while (i < codes.length) {
				// The next word, with the spaces before it.
				var start = i;
				while (i < codes.length && codes[i] == 32)
					i++;
				while (i < codes.length && codes[i] != 32)
					i++;
				var word = codes.slice(start, i);
				var joined = line.concat(word);
				if (line.length == 0 || measure(joined) <= maxWidth) {
					line = joined;
				} else {
					add(line);
					while (word.length > 0 && word[0] == 32)
						word.shift();
					line = word;
				}
				// A word wider than the box, broken between its characters.
				while (measure(line) > maxWidth && line.length > 1) {
					var cut = line.length - 1;
					while (cut > 1 && measure(line.slice(0, cut)) > maxWidth)
						cut--;
					add(line.slice(0, cut));
					line = line.slice(cut);
				}
			}
			add(line);
		}
		widest = 0;
		for (w in widths)
			widest = Math.max(widest, w);
	}

	// The width of characters on a line, its spaces at the end left out.
	function measure(line:Array<Int>):Float {
		var end = line.length;
		while (end > 0 && line[end - 1] == 32)
			end--;
		return font.widthOf(line, scale, letterSpacing, kerned, 0, end);
	}

	function add(line:Array<Int>):Void {
		lines.push(line);
		widths.push(measure(line));
	}
}
