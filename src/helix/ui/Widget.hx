package helix.ui;

import helix.render2d.Node2D;

/** A piece of UI: nodes it owns (under its root, on the Ui's stage) and the layout box placing them. A widget is asked what happened
	(isClicked, getValue ...), never calls anything (DECISIONS 61); the Ui updates it once a frame. */
class Widget {
	var ui:Ui;
	var root:Node2D;
	var box:Box;
	var name:String;
	var enabled = true;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String) {
		this.ui = ui;
		this.name = name;
		root = Node2D.group();
	}

	/** Its name: what the focus is published as (Ui.getFocusedName), for checks. */
	public function getName():String
		return name;

	/** The box placing it: put it in a layout. */
	public function getBox():Box
		return box;

	/** Its root node, everything it draws under it. */
	public function getRoot():Node2D
		return root;

	/** Whether it can be used: a disabled one is drawn dimmed, can't take focus and does nothing. */
	public function isEnabled():Bool
		return enabled;

	/** Lets it be used, or not (isEnabled). */
	public function setEnabled(value:Bool):Void
		enabled = value;

	/** Shows or hides it (and lets it take focus, or not). */
	public function setVisible(value:Bool):Void
		root.setEnabled(value);

	/** Whether it's shown. */
	public function isVisible():Bool
		return root.isEnabled();

	/** Whether focus can rest on it. */
	public function isFocusable():Bool
		return false;

	/** The node the pointer uses it through, or null. */
	@:allow(helix.ui.Ui)
	function target():Null<Node2D>
		return null;

	// Once a frame from the Ui: hovered and held by the pointer, focused, activated by keys or a pad (Enter, Space, South) this frame, and
	// the step it takes from keys or a pad (Left and Right for one that takes them sideways, Up and Down for one that takes them up and
	// down), only when it had focus as they were pressed.

	@:allow(helix.ui.Ui)
	function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {}

	// Whether it uses Left and Right itself while focused (a slider), so they don't move focus.

	@:allow(helix.ui.Ui)
	function takesSideways():Bool
		return false;

	// Whether it uses Up and Down itself while focused (a list), so they don't move focus.

	@:allow(helix.ui.Ui)
	function takesUpDown():Bool
		return false;
}
