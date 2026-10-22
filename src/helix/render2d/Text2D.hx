package helix.render2d;

import helix.font.Font;
import helix.math.Bounds2D;

/** A line of text in the 2D world: its value, size units tall (ascent to descent), in a color (0xAARRGGBB) and a font (null: the drawing batch's
	built-in one); its position is the top of the text and, by align, its left edge, center or right edge. Wrapped to a width, it is a block of
	lines (setWrapWidth). Not pickable until pickable is set: a label lets the pointer through to what it's on. Batch2D.drawText draws text
	without a node; Font.measure measures it. */
class Text2D extends Node2D {
	var size:Float;

	/** value, size units tall (0 or less, or NaN, is 1e-6), in color, aligned on its position by align, in font (null: the batch's built-in
		one). */
	public function new(value:String, size = 16., color = 0xffffffff, align:Align2D = Left, ?font:Font) {
		super();
		text = value;
		this.size = size > 1e-6 ? size : 1e-6;
		this.color = color;
		this.align = align;
		this.font = font;
		pickable = false;
	}

	/** Its text. */
	public var text:String;

	/** Its size, units tall (ascent to descent). At least 1e-6 (0 or less, or NaN, is 1e-6). */
	public var textSize(get, set):Float;

	function get_textSize():Float
		return size;

	function set_textSize(value:Float):Float {
		size = value > 1e-6 ? value : 1e-6;
		return size;
	}

	/** Its color, 0xAARRGGBB. */
	public var color:Int;

	/** Which point of it its position's x is: its left edge, center or right edge. */
	public var align:Align2D;

	/** Its font, or null for the drawing batch's built-in one. */
	public var font:Null<Font>;

	/** Its wrap width in its own units: 0 for one line. */
	public var wrapWidth(default, null):Float = 0.;

	/** Its wrapped lines apart, times its size. */
	public var lineHeight(default, null):Float = 1.25;

	/** Wraps it to width in its own units (Font.wrap), its lines lineHeight times its size apart; 0 for one line. False, changing nothing, for a
		width below 0 or a line height of 0 or less. */
	public function setWrapWidth(width:Float, lineHeight = 1.25):Bool {
		if (!(width >= 0) || !(lineHeight > 0))
			return false;
		wrapWidth = width;
		this.lineHeight = lineHeight;
		return true;
	}

	/** Its width in its own units as drawn in font (its own, if it has one): its wrap width, or its one line's. */
	public function measureWidth(font:Font):Float
		return wrapWidth > 0 ? wrapWidth : (this.font != null ? this.font : font).measure(text, size);

	/** Its height in its own units as drawn in font (its own, if it has one): its size, or its wrapped lines'. */
	public function measureHeight(font:Font):Float {
		if (wrapWidth <= 0)
			return size;
		var lines = (this.font != null ? this.font : font).wrap(text, size, wrapWidth).length;
		return size * (1 + lineHeight * (lines - 1));
	}

	override function measureOwn(font:Null<Font>, out:Bounds2D):Bool {
		var f = this.font != null ? this.font : font;
		if (f == null)
			return false;
		var w = measureWidth(f), h = measureHeight(f);
		var x = align == Center ? -w / 2 : align == Right ? -w : 0;
		out.set(x, 0, x + w, h);
		return true;
	}
}
