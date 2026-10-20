package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Shape2D;

/** The bar along a scrolling widget's right edge (a list's, a scroll area's): a track theme.scrollbarThickness wide in
	theme.scrollbarTrackColor, and on it a thumb as long as the share of the content in view and as far down as the content is scrolled, both
	with round ends. The thumb is colored as a handle by its state (WidgetState.handle: theme.handleColor, theme.accentColor under the
	pointer, theme.focusColor dragged), dimmed as disabled when its owner is disabled or has nothing to scroll. Never picked: its
	owner's face takes the pointer and hands it on (drive). One part, so every widget's scrollbar looks and works alike. Its places are in its
	parent's units. */
class Scrollbar {
	var track:Shape2D;
	var thumb:Shape2D;
	var left = 0.;
	var top = 0.;
	var length = 0.;
	var view = 0.;
	var total = 0.;
	var thickness = 1.;
	// Where along the thumb the pointer took it, NaN while it isn't held.
	var grab = Math.NaN;

	/** Makes a scrollbar in theme's look under parent, hidden until placed (setTrack). */
	public function new(parent:Node2D, theme:Theme) {
		track = Shape2D.rectangle(1, 1, 0);
		thumb = Shape2D.rectangle(1, 1, 0);
		for (shape in [track, thumb]) {
			shape.setPivot(0, 0);
			shape.pickable = false;
			shape.visible = false;
			parent.addChild(shape);
		}
		readTheme(theme);
	}

	/** Whether visibility shows a scrollbar for view units of content seen of total: Always; WhenNeeded only when total is more than view;
		Never not. */
	public static function isShown(visibility:ScrollbarVisibility, view:Float, total:Float):Bool
		return switch visibility {
			case Always: true;
			case WhenNeeded: total > view + 1e-6;
			case Never: false;
		}

	/** Takes its thickness, its track's color and its round ends from theme (its thumb's color is decided as it's placed: place). Its owner
		calls it as it reads the theme, every frame, so a changed theme shows at once. */
	public function readTheme(theme:Theme):Void {
		thickness = theme.scrollbarThickness;
		track.color = theme.scrollbarTrackColor;
		track.cornerRadius = thumb.cornerRadius = thickness / 2;
	}

	/** Whether it's drawn: as setTrack was last told. */
	public var visible(default, null):Bool = false;

	/** Its width in units (theme.scrollbarThickness as last read): the room its owner leaves it. */
	public var width(get, never):Float;

	function get_width():Float
		return thickness;

	/** Its thumb's length in units, as last placed: the track's length times the share of the content in view, at least three times its
		width (or the track's whole length), the track's whole length when the content fits. */
	public var thumbLength(default, null):Float = 0.;

	/** How far its thumb's top is below the track's top in units, as last placed: 0 at the top of the content, the track's length less the
		thumb's at its end. */
	public var thumbOffset(default, null):Float = 0.;

	/** Whether the pointer holds its thumb (a drag). */
	public var dragging(get, never):Bool;

	function get_dragging():Bool
		return !Math.isNaN(grab);

	/** Lays its track down from x, y (its top left) length long, for view units of content in view of total, drawn when shown. Its owner calls
		it first each frame, before drive and place. */
	public function setTrack(x:Float, y:Float, length:Float, view:Float, total:Float, shown:Bool):Void {
		left = x;
		top = y;
		this.length = Math.max(0, length);
		this.view = Math.max(0, view);
		this.total = Math.max(0, total);
		visible = shown;
		track.visible = thumb.visible = shown;
		if (!shown)
			grab = Math.NaN;
	}

	/** Its part named part as last placed, while it's drawn: "track" (all of it) or "thumb", its rectangle written to out as [left, top, width,
		height] in its parent's units. False, writing nothing, for another name or while it's hidden. */
	public function computePart(part:String, out:Array<Float>):Bool {
		if (!visible || part != "track" && part != "thumb")
			return false;
		var thumb = part == "thumb";
		out[0] = left;
		out[1] = thumb ? top + thumbOffset : top;
		out[2] = thickness;
		out[3] = thumb ? thumbLength : length;
		return true;
	}

	/** Whether x, y is on it, while it's drawn. */
	public function isOver(x:Float, y:Float):Bool
		return visible && x >= left && x <= left + thickness && y >= top && y <= top + length;

	/** The scroll (units of content scrolled past) after the pointer at x, y: a press beginning on its owner this frame (pressed) on the thumb
		takes it, and while it's held after that the thumb follows the pointer; one on the track above or below the thumb moves a page (the
		units in view) toward it. Unchanged otherwise, and let go once the pointer isn't held. Its owner clamps what it returns. */
	public function drive(x:Float, y:Float, pressed:Bool, held:Bool, scroll:Float):Float {
		if (!held || !visible) {
			grab = Math.NaN;
			return scroll;
		}
		measure(scroll);
		var along = y - top;
		if (pressed && isOver(x, y)) {
			if (along >= thumbOffset && along <= thumbOffset + thumbLength)
				grab = along - thumbOffset;
			else
				return scroll + (along < thumbOffset ? -view : view);
		}
		if (!Math.isNaN(grab)) {
			var room = length - thumbLength;
			return room > 0 ? (along - grab) / room * Math.max(0, total - view) : 0;
		}
		return scroll;
	}

	/** Places the thumb for scroll and colors it: dragged, under the pointer at x, y (NaN: not over its owner), or at rest; dimmed when
		enabled is false or there's nothing to scroll. */
	public function place(scroll:Float, x:Float, y:Float, enabled:Bool, theme:Theme):Void {
		measure(scroll);
		track.setSize(thickness, length);
		track.setPosition(left, top);
		thumb.setSize(thickness, thumbLength);
		thumb.setPosition(left, top + thumbOffset);
		var over = x >= left && x <= left + thickness && y >= top + thumbOffset && y <= top + thumbOffset + thumbLength;
		thumb.color = WidgetState.of(enabled && total > view, dragging, over, false).handle(theme);
	}

	// The thumb's length and offset for scroll.
	function measure(scroll:Float):Void {
		var most = Math.max(0, total - view);
		thumbLength = most <= 0 ? length : Math.min(length, Math.max(thickness * 3, length * view / total));
		thumbOffset = most <= 0 ? 0 : (length - thumbLength) * Math.max(0, Math.min(1, scroll / most));
	}
}
