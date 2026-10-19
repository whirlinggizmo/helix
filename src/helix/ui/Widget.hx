package helix.ui;

import helix.render2d.Node2D;

/** A piece of UI: nodes it owns (under its root, on the Ui's stage) and the layout box placing them. A widget is asked what happened
	(clicked, value ...), never calls anything (DECISIONS 61); the Ui updates it once a frame. */
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

	/** The box placing it: put it in a layout. */
	public var box(default, null):Box;

	/** Its root node, everything it draws under it. */
	public var root(default, null):Node2D;

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
