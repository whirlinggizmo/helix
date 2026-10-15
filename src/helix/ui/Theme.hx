package helix.ui;

import helix.render2d.Font2D;

/** How the UI's widgets look: their colors (0xRRGGBBAA), font and sizes. Change one before making widgets; widgets read it as they're made
	and as they draw their states. */
class Theme {
	var font:Null<Font2D> = null;
	var textSize:Float = 18.;
	var text:Int = 0xf0f2f8ff;
	var disabledText:Int = 0x80869aff;
	var panel:Int = 0x1e2230e8;
	var face:Int = 0x2e3448ff;
	var hovered:Int = 0x3e4660ff;
	var pressed:Int = 0x56607eff;
	var accent:Int = 0x4c8ef0ff;
	var focus:Int = 0xffd25aff;
	var focusWidth:Float = 2.;
	var corner:Float = 8.;
	var padding:Float = 10.;
	var gap:Float = 8.;
	var height:Float = 40.;

	/** The colors and sizes as each getter says to start. */
	public function new() {}

	/** The font text is drawn in, or null for the stage's (the batch's built-in one). */
	public function getFont():Null<Font2D>
		return font;

	/** Sets it, as getFont says. */
	public function setFont(value:Null<Font2D>):Void
		font = value;

	/** Text's height in units. (18 to start.) */
	public function getTextSize():Float
		return textSize;

	/** Sets it, as getTextSize says. False, changing nothing, for 0 or less. */
	public function setTextSize(value:Float):Bool {
		if (!(value > 0))
			return false;
		textSize = value;
		return true;
	}

	/** Text's color. (0xf0f2f8ff to start.) */
	public function getTextColor():Int
		return text;

	/** Sets it, as getTextColor says. */
	public function setTextColor(value:Int):Void
		text = value;

	/** The color of text on a widget that can't be used now. (0x80869aff to start.) */
	public function getDisabledTextColor():Int
		return disabledText;

	/** Sets it, as getDisabledTextColor says. */
	public function setDisabledTextColor(value:Int):Void
		disabledText = value;

	/** A panel's background color. (0x1e2230e8 to start.) */
	public function getPanelColor():Int
		return panel;

	/** Sets it, as getPanelColor says. */
	public function setPanelColor(value:Int):Void
		panel = value;

	/** The color of a button's (and a toggle's box's, a track's) face at rest. (0x2e3448ff to start.) */
	public function getFaceColor():Int
		return face;

	/** Sets it, as getFaceColor says. */
	public function setFaceColor(value:Int):Void
		face = value;

	/** The color of a face under the pointer. (0x3e4660ff to start.) */
	public function getHoveredColor():Int
		return hovered;

	/** Sets it, as getHoveredColor says. */
	public function setHoveredColor(value:Int):Void
		hovered = value;

	/** The color of a face held down. (0x56607eff to start.) */
	public function getPressedColor():Int
		return pressed;

	/** Sets it, as getPressedColor says. */
	public function setPressedColor(value:Int):Void
		pressed = value;

	/** The color of what's on, filled or chosen: a toggle's mark, a slider's fill and knob, a progress bar's fill, a list's selected row. (0x4c8ef0ff to start.) */
	public function getAccentColor():Int
		return accent;

	/** Sets it, as getAccentColor says. */
	public function setAccentColor(value:Int):Void
		accent = value;

	/** The color of the ring around the focused widget, shown when focus was moved by keys or a pad. (0xffd25aff to start.) */
	public function getFocusColor():Int
		return focus;

	/** Sets it, as getFocusColor says. */
	public function setFocusColor(value:Int):Void
		focus = value;

	/** The focus ring's width in units. (2 to start.) */
	public function getFocusWidth():Float
		return focusWidth;

	/** Sets it, as getFocusWidth says. False, changing nothing, for below 0. */
	public function setFocusWidth(value:Float):Bool {
		if (!(value >= 0))
			return false;
		focusWidth = value;
		return true;
	}

	/** The radius of a panel's, a button's, a field's and a list's corners in units (a track's, a bar's and a box's at most half their height); 0 for square. The focus ring follows them. (8 to start.) */
	public function getCornerRadius():Float
		return corner;

	/** Sets it, as getCornerRadius says. False, changing nothing, for below 0. */
	public function setCornerRadius(value:Float):Bool {
		if (!(value >= 0))
			return false;
		corner = value;
		return true;
	}

	/** Room inside a button or panel, around its content, in units. (10 to start.) */
	public function getPadding():Float
		return padding;

	/** Sets it, as getPadding says. False, changing nothing, for below 0. */
	public function setPadding(value:Float):Bool {
		if (!(value >= 0))
			return false;
		padding = value;
		return true;
	}

	/** Room between widgets in a panel, in units. (8 to start.) */
	public function getGap():Float
		return gap;

	/** Sets it, as getGap says. False, changing nothing, for below 0. */
	public function setGap(value:Float):Bool {
		if (!(value >= 0))
			return false;
		gap = value;
		return true;
	}

	/** A button's (and a list row's, a slider's) height in units. (40 to start.) */
	public function getWidgetHeight():Float
		return height;

	/** Sets it, as getWidgetHeight says. False, changing nothing, for 0 or less. */
	public function setWidgetHeight(value:Float):Bool {
		if (!(value > 0))
			return false;
		height = value;
		return true;
	}
}
