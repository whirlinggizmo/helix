package helix.ui;

import helix.render2d.Node2D;

/** A piece of UI: nodes it owns (on the Ui's stage) and the layout (Layout2D) placing them. A widget is asked what happened (clicked, value ...),
	never calls anything (DECISIONS 61); the Ui updates it once a frame. Its look is its Ui's theme's (Theme), read every frame, except what
	the game set: its layout's sizing, padding and gap once the game sets them (Layout2D), and the look properties a widget has for one of its own
	(Label.textSize and color: null for the theme's). Its nodes are its own: a game changes them through its properties, never directly. */
class Widget {
	var ui:Ui;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String) {
		this.ui = ui;
		this.name = name;
		root = new Node2D();
	}

	/** Its name: what the focus is published as (Ui.focusedName), for checks. */
	public var name(default, null):String;

	/** The layout placing it: put it in another (a row, a column, a panel's content). */
	public var layout(default, null):Layout2D;

	// Its root node, everything it draws under it: its own, put under a panel's or a picker's by them.
	@:allow(helix.ui)
	var root(default, null):Node2D;

	/** Whether it can be used: a disabled one is drawn dimmed, can't take focus and does nothing. */
	public var enabled:Bool = true;

	/** Whether it's shown: it, and any panel holding it. */
	public var visible(get, set):Bool;

	function get_visible():Bool {
		var at = root;
		while (at != null && at != ui.root) {
			if (!at.enabled)
				return false;
			at = at.parent;
		}
		return true;
	}

	function set_visible(value:Bool):Bool {
		root.enabled = value;
		return value;
	}

	/** Whether focus can rest on it. */
	public var focusable(get, never):Bool;

	function get_focusable():Bool
		return false;

	/** The node the pointer uses it through, or null. */
	@:allow(helix.ui.Ui)
	function target():Null<Node2D>
		return null;

	// Once a frame from the Ui: hovered and held by the pointer, focused, activated by keys or a pad (Enter, Space, South) this frame, and
	// the steps it takes from keys or a pad, only when it had focus as they were pressed: stepX from Left (-1) and Right (1) for one that
	// takes them sideways, stepY from Up (-1) and Down (1) for one that takes them up and down.

	@:allow(helix.ui.Ui)
	function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, stepX:Int, stepY:Int):Void {}

	// Its look from theme: its shapes' colors (those not decided by its state, which update picks), corners and sizes, its texts' size and
	// font, its layouts' sizing, padding and gaps. Called by its constructor, once its parts are made, and by the Ui every frame before update,
	// so a theme changed at run time (a settings screen, a reloaded stylesheet) shows at the next frame with no widget made again. One method
	// every widget overrides, rather than each update reading what it needs, so what comes from the theme is in one place, apart from the
	// state update works out. Cheap: plain assignments; text measured and polygons remade only when what they come from changed. A size that
	// moves the layout shows once the layout is arranged again (Layout2D.arrange). Every value is the theme's or the game's, decided by what was
	// set, never by comparing values: a layout's sizing, padding and gap go through Layout2D.themeSizing, themePadding and themeGap (themeFixed),
	// which leave a value the game set (Layout2D.setSizing ...); a look a game may give one widget is a property of it, null for the theme's
	// (Label.textSize, Label.color), read here. A widget's parts (its Text2D and Shape2D nodes) are its own: games change them through its
	// properties, never directly.

	@:allow(helix.ui.Ui)
	function readTheme(theme:Theme):Void {}

	// A layout's sizing from the theme (its own, or one of its parts'): Fixed(width) and Fixed(height) (NaN: that way's left be) through
	// Layout2D.themeSizing, so what a game set is kept; nothing made when the layout is sized so already.
	function themeFixed(target:Layout2D, width:Float, height:Float):Void {
		var w = Math.isNaN(width) || isFixed(target.widthSizing, width),
			h = Math.isNaN(height) || isFixed(target.heightSizing, height);
		if (!w || !h)
			target.themeSizing(w ? null : Fixed(width), h ? null : Fixed(height));
	}

	// Whether sizing is Fixed(units).
	static function isFixed(sizing:Layout2D.Sizing, units:Float):Bool
		return switch sizing {
			case Fixed(u): u == units;
			case _: false;
		}

	// The widgets it made through the Ui as parts of itself (a color picker's hex field): taken out with it.
	@:allow(helix.ui.Ui)
	var parts:Array<Widget> = [];

	// Whether it uses Left and Right itself while focused (a slider), so they don't move focus.

	@:allow(helix.ui.Ui)
	function takesSideways():Bool
		return false;

	// Whether it takes typed text while focused (a text field): the UI has the keys however it got focus, and Space is typed, not activating.

	@:allow(helix.ui.Ui)
	function takesText():Bool
		return false;

	// Whether it uses Up and Down itself while focused (a list), so they don't move focus.

	@:allow(helix.ui.Ui)
	function takesUpDown():Bool
		return false;
}
