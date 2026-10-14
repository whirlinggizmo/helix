package helix.ui;

import helix.render2d.Font2D;

/** How the UI's widgets look: their colors (0xRRGGBBAA), font and sizes. Change one before making widgets; widgets read it as they're made
	and as they draw their states. */
class Theme {
	/** The font text is drawn in, or null for the stage's (the batch's built-in one). */
	public var font:Null<Font2D> = null;

	/** Text's height in units. */
	public var textSize = 18.;

	/** Text's color. */
	public var text = 0xf0f2f8ff;

	/** Text on a widget that can't be used now. */
	public var disabledText = 0x80869aff;

	/** A panel's background. */
	public var panel = 0x1e2230e8;

	/** A button's (and a toggle's box's, a track's) face at rest. */
	public var face = 0x2e3448ff;

	/** A face under the pointer. */
	public var hovered = 0x3e4660ff;

	/** A face held down. */
	public var pressed = 0x56607eff;

	/** What's on, filled or chosen: a toggle's mark, a slider's fill and knob, a progress bar's fill, a list's selected row. */
	public var accent = 0x4c8ef0ff;

	/** The ring around the focused widget, shown when focus was moved by keys or a pad. */
	public var focus = 0xffd25aff;

	/** The focus ring's width. */
	public var focusWidth = 2.;

	/** The radius of a panel's, a button's, a field's and a list's corners (a track's, a bar's and a box's at most half their height); 0 for
		square. The focus ring follows them. */
	public var corner = 8.;

	/** Room inside a button or panel, around its content. */
	public var padding = 10.;

	/** Room between widgets in a panel. */
	public var gap = 8.;

	/** A button's (and a list row's, a slider's) height. */
	public var height = 40.;

	/** The colors and sizes above. */
	public function new() {}
}
