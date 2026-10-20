package helix.ui;

import helix.render2d.Font2D;

/** How the UI's widgets look: their colors (0xRRGGBBAA), font and sizes. Change any value at any time (a settings screen, a reloaded
	stylesheet): every widget, and the focus ring, reads its look from its Ui's theme at each Ui.update, so the change shows on the next frame
	with no widget made again; a size that moves the layout shows once the layout is next arranged (Layout2D.arrange). Ui.theme can also be given
	another theme whole. Every value is the theme's or the game's, decided by what the game set, never guessed from the value: a theme's value
	applies unless the game set that value itself, and a game's setting wins, as an inline style wins over a stylesheet. A widget's layout's
	sizing, padding, gap and margin are the game's once set through Layout2D (setSizing, widthSizing, heightSizing, setPadding, gap,
	setMargin), even to what the theme has; a widget's own look properties (Label.textSize, Label.color) are null for the theme's, a value for the game's. A widget's
	nodes are never changed directly: its properties are the way. */
class Theme {
	var text:Int = 0xf0f2f8ff;
	var disabledText:Int = 0x80869aff;
	var invalidText:Int = 0xff7070ff;
	var panel:Int = 0x1e2230ff;
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

	/** A panel's background color. (0x1e2230ff to start: opaque, so faces show on it whatever is behind.) */
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

	/** The radius of a list's corners in units, its frame's (cornerRadius for the others); 0 for square. (0 to start.) 0 or more (under 0, or
		NaN, is 0). */
	public var listCornerRadius(default, set):Float = 0.;

	function set_listCornerRadius(value:Float):Float {
		value = value >= 0 ? value : 0;
		listCornerRadius = value;
		return value;
	}

	/** Room between a list's frame and its rows in units, so a chosen row's band keeps clear of the frame's round corners. (4 to start.) 0 or
		more (under 0, or NaN, is 0). */
	public var listPadding(default, set):Float = 4.;

	function set_listPadding(value:Float):Float {
		value = value >= 0 ? value : 0;
		listPadding = value;
		return value;
	}

	/** A list's rows' height in units. (40 to start.) At least 1 (under 1, or NaN, is 1). */
	public var listRowHeight(default, set):Float = 40.;

	function set_listRowHeight(value:Float):Float {
		value = value >= 1 ? value : 1;
		listRowHeight = value;
		return value;
	}

	/** The radius of a list's rows' corners in units (their hover and selection), apart from the frames' cornerRadius; 0 for square. (0 to
		start.) 0 or more (under 0, or NaN, is 0). */
	public var listRowCornerRadius(default, set):Float = 0.;

	function set_listRowCornerRadius(value:Float):Float {
		value = value >= 0 ? value : 0;
		listRowCornerRadius = value;
		return value;
	}

	/** The radius of a panel's and a button's corners in units (a list's is listCornerRadius) (a track's, a bar's and a box's at most half their
		height); 0 for square. The focus ring follows them. (8 to start.) 0 or more (under 0, or NaN, is 0). */
	public var cornerRadius(get, set):Float;

	function get_cornerRadius():Float
		return corner;

	function set_cornerRadius(value:Float):Float {
		value = value >= 0 ? value : 0;
		corner = value;
		return value;
	}

	/** Room inside a button or panel, around its content, in units. (8 to start.) 0 or more (under 0, or NaN, is 0). */
	public var padding(default, set):Float = 8.;

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

	/** A handle's color (a slider's, a color picker's bars'; Handle), 0xRRGGBBAA. (White to start.) */
	public var handleColor:Int = 0xffffffff;

	/** The ring around a handle, so it shows on any color under it, 0xRRGGBBAA. (Black at half alpha to start.) */
	public var handleShadowColor:Int = 0x00000080;

	/** A handle's diameter in units (a slider's, a color picker's bars'; Handle). (14 to start.) At least 1 (under 1, or NaN, is 1). */
	public var handleSize(default, set):Float = 14.;

	function set_handleSize(value:Float):Float {
		value = value >= 1 ? value : 1;
		handleSize = value;
		return value;
	}

	/** A scrollbar's width in units (a list's, a scroll area's; Scrollbar), apart from a slider's trackThickness. (8 to start.) At least 1
		(under 1, or NaN, is 1). */
	public var scrollbarThickness(default, set):Float = 8.;

	function set_scrollbarThickness(value:Float):Float {
		value = value >= 1 ? value : 1;
		scrollbarThickness = value;
		return value;
	}

	/** A scrollbar's track's color, 0xRRGGBBAA, under its thumb (whose colors are a handle's: WidgetState.handle). (Black at a quarter alpha
		to start, so it shows on a list's face and a panel alike.) */
	public var scrollbarTrackColor:Int = 0x00000040;

	/** When a list's and a scroll area's scrollbars are drawn, unless the widget is given its own (scrollbarVisibility). (WhenNeeded to
		start.) Null is WhenNeeded. */
	public var scrollbarVisibility(default, set):ScrollbarVisibility = WhenNeeded;

	function set_scrollbarVisibility(value:ScrollbarVisibility):ScrollbarVisibility {
		value = value != null ? value : WhenNeeded;
		scrollbarVisibility = value;
		return value;
	}

	/** A color picker's width (its square's side) in units, unless its layout is given another. (200 to start.) At least 1 (under 1, or NaN,
		is 1). */
	public var colorPickerWidth(default, set):Float = 200.;

	function set_colorPickerWidth(value:Float):Float {
		value = value >= 1 ? value : 1;
		colorPickerWidth = value;
		return value;
	}

	/** A button's (and a slider's, a field's) height in units. (40 to start.) At least 1e-6 (0 or less, or NaN, is 1e-6). */
	public var widgetHeight(get, set):Float;

	function get_widgetHeight():Float
		return height;

	function set_widgetHeight(value:Float):Float {
		value = value > 1e-6 ? value : 1e-6;
		height = value;
		return value;
	}
}
