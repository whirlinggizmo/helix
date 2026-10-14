package helix.ui;

import helix.render2d.Node2D;

/** A list of items in a window rows tall: scrolled by the wheel over it or a drag, an item chosen by a click or, with focus, by Up and Down
	(scrolled into view), and activated by a click on the chosen one or Enter, Space or a pad's South. Ask getSelected, isChanged and
	isActivated once a frame. */
class ListView extends Widget {
	var face:Node2D;
	var window:Node2D;
	var content:Node2D;
	var rows:Array<{face:Node2D, text:Node2D}> = [];
	var items:Array<String> = [];
	var visibleRows:Int;
	var selected = -1;
	var scroll = 0.;
	var changed = false;
	var activated = false;
	var dragFrom = Math.NaN;
	var scrollFrom = 0.;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, items:Array<String>, rows:Int) {
		super(ui, name);
		visibleRows = rows < 1 ? 1 : rows;
		var theme = ui.getTheme();
		face = Node2D.rectangle(1, 1, theme.face);
		face.setPivot(0, 0);
		window = Node2D.group();
		content = Node2D.group();
		window.add(content);
		root.add(face);
		root.add(window);
		box = Box.of(face).setSize(Grow(1), Fixed(visibleRows * theme.height));
		setItems(items);
	}

	/** Its items. */
	public function getItems():Array<String>
		return items.copy();

	/** Shows items, choosing none. */
	public function setItems(value:Array<String>):Void {
		items = value.copy();
		var theme = ui.getTheme();
		for (r in rows) {
			content.remove(r.face);
			content.remove(r.text);
		}
		rows = [];
		for (i in 0...items.length) {
			var rowFace = Node2D.rectangle(1, theme.height, 0);
			rowFace.setPivot(0, 0);
			rowFace.setPickable(false);
			var text = Node2D.text(items[i], theme.textSize, theme.text, Left, theme.font);
			text.setPickable(false);
			content.add(rowFace);
			content.add(text);
			rows.push({face: rowFace, text: text});
		}
		selected = -1;
		scroll = 0;
	}

	/** The chosen item's index, or -1. */
	public function getSelected():Int
		return selected;

	/** Chooses item index (-1: none), scrolled into view; not counted as a change. */
	public function setSelected(index:Int):Void {
		selected = index >= 0 && index < items.length ? index : -1;
		reveal();
	}

	/** Whether the chosen item changed this frame. */
	public function isChanged():Bool
		return changed;

	/** Whether the chosen item was activated this frame: clicked again, or Enter, Space or South with focus. */
	public function isActivated():Bool
		return activated;

	override public function isFocusable():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function takesUpDown():Bool
		return true;

	function reveal():Void {
		var height = ui.getTheme().height;
		if (selected < 0)
			return;
		scroll = Math.max(Math.min(scroll, selected * height), (selected + 1) * height - visibleRows * height);
	}

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		var theme = ui.getTheme(), input = ui.getInput(), camera = ui.getCamera(), height = theme.height, was = selected;
		this.activated = false;
		var wx = camera.screenToWorldX(input.getPointerX()),
			wy = camera.screenToWorldY(input.getPointerY());
		var localY = face.toLocalY(wx, wy) + scroll;
		if (enabled && hovered && input.getWheelY() != 0)
			scroll -= input.getWheelY() * height;
		// A drag scrolls; a click without one chooses the row under it (again: activates it).
		if (enabled && held) {
			if (Math.isNaN(dragFrom)) {
				dragFrom = wy;
				scrollFrom = scroll;
			} else if (Math.abs(wy - dragFrom) > 4)
				scroll = scrollFrom - (wy - dragFrom);
		} else {
			if (clicked && (Math.isNaN(dragFrom) || Math.abs(wy - dragFrom) <= 4)) {
				var row = Std.int(localY / height);
				if (row >= 0 && row < items.length) {
					if (row == selected)
						this.activated = true;
					selected = row;
				}
			}
			dragFrom = Math.NaN;
		}
		if (enabled && step != 0 && items.length > 0) {
			selected = selected < 0 ? 0 : Std.int(Math.max(0, Math.min(items.length - 1, selected + step)));
			reveal();
		}
		if (enabled && activated && selected >= 0)
			this.activated = true;
		scroll = Math.max(0, Math.min(scroll, Math.max(0, items.length * height - visibleRows * height)));
		changed = selected != was;
		// The window clips the rows to the box; the rows scroll inside it.
		window.setPosition(box.getX(), box.getY());
		window.setClip(box.getWidth(), box.getHeight());
		content.setPosition(0, -scroll);
		for (i in 0...rows.length) {
			var r = rows[i];
			r.face.setSize(box.getWidth(), height);
			r.face.setPosition(0, i * height);
			r.face.setColor(i == selected ? theme.accent : 0);
			r.text.setPosition(theme.padding, i * height + (height - theme.textSize) / 2);
			r.text.setColor(enabled ? theme.text : theme.disabledText);
		}
	}
}
