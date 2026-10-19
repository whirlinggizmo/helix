package helix.ui;

import helix.render2d.Font2D;

/** How the UI's widgets look: their colors (0xRRGGBBAA), font and sizes. Change one before making widgets; widgets read it as they're made
	and as they draw their states. */
class Theme {
	var text:Int = 0xf0f2f8ff;
	var disabledText:Int = 0x80869aff;
	var invalidText:Int = 0xff7070ff;
	var panel:Int = 0x1e2230e8;
	var face:Int = 0x2e3448ff;
	var hovered:Int = 0x3e4660ff;
	var pressed:Int = 0x56607eff;
	var accent:Int = 0x4c8ef0ff;
	var focus:Int = 0xffd25aff;
	var corner:Float = 8.;
	var height:Float = 40.;

	/** The colors and sizes as each getter says to start. */
	public function new() {}

	/** The font text is drawn in, or null for the stage's (the batch's built-in one). */
	public var font:Null<Font2D> = null;

	/** Text's height in units. (18 to start.) At least 1e-6 (0 or less, or NaN, is 1e-6). */
	public var textSize(default, set):Float = 18.;

	function set_textSize(value:Float):Float {
		value = value > 1e-6 ? value : 1e-6;
		textSize = value;
		return value;
	}

	/** Text's color. (0xf0f2f8ff to start.) */
	public var textColor(get, set):Int;

	function get_textColor():Int
		return text;

	function set_textColor(value:Int):Int {
		text = value;
		return value;
	}

	/** The color of text on a widget that can't be used now. (0x80869aff to start.) */
	public var disabledTextColor(get, set):Int;

	function get_disabledTextColor():Int
		return disabledText;

	function set_disabledTextColor(value:Int):Int {
		disabledText = value;
		return value;
	}

	/** The color of a text field's text marked as not accepted (TextField.invalid). (0xff7070ff to start.) */
	public var invalidTextColor(get, set):Int;

	function get_invalidTextColor():Int
		return invalidText;

	function set_invalidTextColor(value:Int):Int {
		invalidText = value;
		return value;
	}

	/** A panel's background color. (0x1e2230e8 to start.) */
	public var panelColor(get, set):Int;

	function get_panelColor():Int
		return panel;

	function set_panelColor(value:Int):Int {
		panel = value;
		return value;
	}

	/** The color of a button's (and a toggle's box's, a track's) face at rest. (0x2e3448ff to start.) */
	public var faceColor(get, set):Int;

	function get_faceColor():Int
		return face;

	function set_faceColor(value:Int):Int {
		face = value;
		return value;
	}

	/** The color of a face under the pointer. (0x3e4660ff to start.) */
	public var hoveredColor(get, set):Int;

	function get_hoveredColor():Int
		return hovered;

	function set_hoveredColor(value:Int):Int {
		hovered = value;
		return value;
	}

	/** The color of a face held down. (0x56607eff to start.) */
	public var pressedColor(get, set):Int;

	function get_pressedColor():Int
		return pressed;

	function set_pressedColor(value:Int):Int {
		pressed = value;
		return value;
	}

	/** The color of what's on, filled or chosen: a toggle's mark, a slider's fill and knob, a progress bar's fill, a list's selected row.
		(0x4c8ef0ff to start.) */
	public var accentColor(get, set):Int;

	function get_accentColor():Int
		return accent;

	function set_accentColor(value:Int):Int {
		accent = value;
		return value;
	}

	/** The color of the ring around the focused widget, shown when focus was moved by keys or a pad. (0xffd25aff to start.) */
	public var focusColor(get, set):Int;

	function get_focusColor():Int
		return focus;

	function set_focusColor(value:Int):Int {
		focus = value;
		return value;
	}

	/** The focus ring's width in units. (2 to start.) 0 or more (under 0, or NaN, is 0). */
	public var focusWidth(default, set):Float = 2.;

	function set_focusWidth(value:Float):Float {
		value = value >= 0 ? value : 0;
		focusWidth = value;
		return value;
	}

	/** The radius of a panel's, a button's and a list's corners in units (a track's, a bar's and a box's at most half their
		height); 0 for square. The focus ring follows them. (8 to start.) 0 or more (under 0, or NaN, is 0). */
	public var cornerRadius(get, set):Float;

	function get_cornerRadius():Float
		return corner;

	function set_cornerRadius(value:Float):Float {
		value = value >= 0 ? value : 0;
		corner = value;
		return value;
	}

	/** Room inside a button or panel, around its content, in units. (10 to start.) 0 or more (under 0, or NaN, is 0). */
	public var padding(default, set):Float = 10.;

	function set_padding(value:Float):Float {
		value = value >= 0 ? value : 0;
		padding = value;
		return value;
	}

	/** Room between widgets in a panel, in units. (8 to start.) 0 or more (under 0, or NaN, is 0). */
	public var gap(default, set):Float = 8.;

	function set_gap(value:Float):Float {
		value = value >= 0 ? value : 0;
		gap = value;
		return value;
	}

	/** A slider's track and a color picker's bars, their thickness in units. (6 to start.) At least 1 (under 1, or NaN, is 1). */
	public var trackThickness(default, set):Float = 6.;

	function set_trackThickness(value:Float):Float {
		value = value >= 1 ? value : 1;
		trackThickness = value;
		return value;
	}

	/** A color picker's handles on its bars, their diameter in units. (14 to start.) At least 1 (under 1, or NaN, is 1). */
	public var handleSize(default, set):Float = 14.;

	function set_handleSize(value:Float):Float {
		value = value >= 1 ? value : 1;
		handleSize = value;
		return value;
	}

	/** A color picker's width (its square's side) in units, unless its box is given another. (200 to start.) At least 1 (under 1, or NaN,
		is 1). */
	public var colorPickerWidth(default, set):Float = 200.;

	function set_colorPickerWidth(value:Float):Float {
		value = value >= 1 ? value : 1;
		colorPickerWidth = value;
		return value;
	}

	/** A button's (and a list row's, a slider's) height in units. (40 to start.) At least 1e-6 (0 or less, or NaN, is 1e-6). */
	public var widgetHeight(get, set):Float;

	function get_widgetHeight():Float
		return height;

	function set_widgetHeight(value:Float):Float {
		value = value > 1e-6 ? value : 1e-6;
		height = value;
		return value;
	}
}
