package helix.ui;

import helix.input.IInput;
import helix.input.Key;
import helix.input.PadButton;
import helix.render2d.Camera2D;
import helix.render2d.Node2D;
import helix.render2d.Stage2D;
import helix.scene.Pointer;

/** A screen's widgets on a Stage2D, used by the pointer, keys and pads alike (libwgf's focus, wgrender-c's widgets of nodes): made here,
	placed by their boxes (Box.arrange), asked what happened. update() once a frame, after the pointer's:

	- Focus moves in the order widgets were made: Down, Tab or a pad's Down to the next; Up, Shift+Tab or Up to the one before; Left and Right
	  too, unless the focused widget uses them (a slider). Enter, Space or a pad's South activates it; Escape or East is back (isBackPressed).
	- The ring around the focused widget shows only when keys or a pad moved focus, not the pointer (as the web's :focus-visible); after keys or
	  a pad, something always has focus (the first widget, if nothing did).
	- A key or button already held when a screen begins (reset) does nothing until it's let go: a fire key held into a menu doesn't press its
	  first button (libwgf's friction).
	- While a widget has the keys (hasKeys), a game should leave arrows and Enter be (libwgf's arrows driving the game and the menu at once).

	The widgets' nodes are under one node (getRoot) on the stage, in the order made, the ring above them. The pointer must be looking at the
	stage, through camera. */
class Ui {
	var stage:Stage2D;
	var camera:Camera2D;
	var pointer:Pointer;
	var input:IInput;
	var theme:Theme;
	var root = Node2D.group();
	var ring:Node2D;
	var widgets:Array<Widget> = [];
	var focused:Null<Widget>;
	var showFocus = false;
	var keys = false;
	var guarded = false;
	var back = false;
	var lastX = -1.;
	var lastY = -1.;

	/** A UI on stage (drawn through camera, which pointer looks at), read from input, in theme's look (a new Theme when not given). */
	public function new(stage:Stage2D, camera:Camera2D, pointer:Pointer, input:IInput, ?theme:Theme) {
		this.stage = stage;
		this.camera = camera;
		this.pointer = pointer;
		this.input = input;
		this.theme = theme != null ? theme : new Theme();
		ring = Node2D.rectangle(1, 1, this.theme.focus);
		ring.setOutline(this.theme.focusWidth);
		ring.setPickable(false);
		ring.setVisible(false);
		root.add(ring);
		stage.add(root);
	}

	/** Its look. */
	public function getTheme():Theme
		return theme;

	/** The node its widgets are under. */
	public function getRoot():Node2D
		return root;

	/** The camera it's drawn through. */
	public function getCamera():Camera2D
		return camera;

	/** The input it reads. */
	public function getInput():IInput
		return input;

	/** A line of text. */
	public function label(text:String, ?name:String):Label
		return adopt(new Label(this, name != null ? name : text, text));

	/** A background holding a column of widgets (add their boxes to its getContent()). */
	public function panel(?name:String):Panel
		return adopt(new Panel(this, name != null ? name : "panel"));

	/** A button reading text: clicked by the pointer, or activated with focus. */
	public function button(text:String, ?name:String):Button
		return adopt(new Button(this, name != null ? name : text, text));

	/** A box that's on or off, beside text. */
	public function toggle(text:String, value:Bool, ?name:String):Toggle
		return adopt(new Toggle(this, name != null ? name : text, text, value));

	/** A value from min to max in steps of step (0: any), dragged along a track or stepped by Left and Right, beside text. */
	public function slider(text:String, min:Float, max:Float, value:Float, step = 0., ?name:String):Slider
		return adopt(new Slider(this, name != null ? name : text, text, min, max, value, step));

	/** How far along something is, 0 to 1. */
	public function progress(value:Float, ?name:String):ProgressBar
		return adopt(new ProgressBar(this, name != null ? name : "progress", value));

	/** A list of items rows tall, scrolled by the wheel or a drag, an item chosen by the pointer or Up and Down. */
	public function list(items:Array<String>, rows:Int, ?name:String):ListView
		return adopt(new ListView(this, name != null ? name : "list", items, rows));

	function adopt<T:Widget>(widget:T):T {
		widgets.push(widget);
		root.remove(ring);
		root.add(widget.getRoot());
		root.add(ring);
		return widget;
	}

	/** Takes widget out, its nodes off the stage. */
	public function remove(widget:Widget):Void {
		widgets.remove(widget);
		root.remove(widget.getRoot());
		if (focused == widget)
			focused = null;
	}

	/** The widget with focus, or null. */
	public function getFocused():Null<Widget>
		return focused;

	/** The focused widget's name, or "" (for a check's probe). */
	public function getFocusedName():String
		return focused == null ? "" : focused.getName();

	/** Gives widget focus (null: none), shown as keys would show it. */
	public function setFocus(widget:Null<Widget>):Void {
		focused = widget;
		showFocus = widget != null;
	}

	/** Whether a widget has the keys: a game should leave arrows, Enter and Space be. */
	public function hasKeys():Bool
		return focused != null && keys;

	/** Whether Escape or a pad's East was pressed this frame (not held over from before reset). */
	public function isBackPressed():Bool
		return back;

	/** A new screen begins: no focus, and keys and buttons held now do nothing until they're let go. */
	public function reset():Void {
		focused = null;
		showFocus = false;
		guarded = true;
	}

	/** Once a frame, after the pointer's update and before reading the widgets: moves focus, activates, and brings each widget up to date. */
	public function update():Void {
		if (guarded && !anyHeld())
			guarded = false;
		// The pointer moving or pressing hides the ring and hands back the keys.
		var x = input.getPointerX(), y = input.getPointerY();
		if ((x != lastX || y != lastY) && x >= 0 || input.isPointerFramePressed()) {
			showFocus = false;
			keys = false;
		}
		lastX = x;
		lastY = y;
		var shift = input.isDown(Key.Shift),
			sideways = focused != null && focused.takesSideways(),
			vertical = focused != null && focused.takesUpDown();
		var step = 0, move = 0;
		if (input.isFramePressed(Key.Tab))
			move = shift ? -1 : 1;
		if (!vertical) {
			if (input.isFramePressed(Key.Down) || pad(PadButton.Down))
				move = 1;
			if (input.isFramePressed(Key.Up) || pad(PadButton.Up))
				move = -1;
		}
		var left = input.isFramePressed(Key.Left) || pad(PadButton.Left),
			right = input.isFramePressed(Key.Right) || pad(PadButton.Right);
		if (sideways)
			step = right ? 1 : left ? -1 : 0;
		else if (left || right)
			move = right ? 1 : -1;
		if (vertical) {
			var up = input.isFramePressed(Key.Up) || pad(PadButton.Up),
				down = input.isFramePressed(Key.Down) || pad(PadButton.Down);
			step = down ? 1 : up ? -1 : 0;
		}
		// The widget the keys were pressed on: a key moving focus onto a list doesn't also move in it.
		var stepped = step != 0 ? focused : null;
		var navigated = move != 0 || step != 0;
		if (navigated) {
			keys = true;
			showFocus = true;
		}
		if (focused != null && (!focused.isFocusable() || !focused.isEnabled() || !focused.isVisible()))
			focused = null;
		if (move != 0)
			focused = focused == null ? first() : next(focused, move);
		else if (keys && focused == null)
			focused = first();
		var activated = !guarded
			&& focused != null
			&& (input.isFramePressed(Key.Enter) || input.isFramePressed(Key.Space) || pad(PadButton.South));
		if (activated) {
			keys = true;
			showFocus = true;
		}
		back = !guarded && (input.isFramePressed(Key.Escape) || pad(PadButton.East));
		for (w in widgets) {
			var target = w.target(),
				usable = w.isEnabled() && w.isVisible() && !guarded;
			var hovered = target != null && pointer.isHovered(target),
				held = target != null && pointer.isDown(target),
				clicked = usable && target != null && pointer.isClicked(target);
			// The pointer pressing a widget gives it focus, unshown.
			if (usable && target != null && pointer.isPressed(target) && w.isFocusable())
				focused = w;
			w.update(hovered && usable, held && usable, clicked, w == focused, activated && w == focused && usable, w == stepped && usable ? step : 0);
		}
		// The ring around the focused widget, a little outside it, when keys or a pad moved focus.
		if (showFocus && focused != null) {
			var b = focused.getBox(), out = theme.focusWidth * 2;
			ring.setSize(b.getWidth() + out * 2, b.getHeight() + out * 2);
			ring.setPivot(0, 0);
			ring.setPosition(b.getX() - out, b.getY() - out);
			ring.setVisible(true);
		} else
			ring.setVisible(false);
	}

	// Whether a pad's button went down this frame, on any pad.
	function pad(button:PadButton):Bool {
		for (i in 0...input.getPadCount()) {
			var p = input.getPad(i);
			if (p != null && p.isConnected() && p.isFramePressed(button))
				return true;
		}
		return false;
	}

	// Whether anything that activates or goes back is held.
	function anyHeld():Bool
		return input.isDown(Key.Enter) || input.isDown(Key.Space) || input.isDown(Key.Escape) || input.isPadDown(PadButton.South)
			|| input.isPadDown(PadButton.East) || input.isPointerDown();

	function first():Null<Widget> {
		for (w in widgets)
			if (w.isFocusable() && w.isEnabled() && w.isVisible())
				return w;
		return null;
	}

	// The focusable widget after from (direction 1) or before it (-1), wrapping.
	function next(from:Widget, direction:Int):Null<Widget> {
		var n = widgets.length, at = widgets.indexOf(from);
		for (k in 1...n + 1) {
			var w = widgets[((at + direction * k) % n + n) % n];
			if (w.isFocusable() && w.isEnabled() && w.isVisible())
				return w;
		}
		return from;
	}
}
