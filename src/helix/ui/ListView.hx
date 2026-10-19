package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Shape2D;
import helix.render2d.Text2D;

/** A list of items in a window rows tall: scrolled by the wheel over it or a drag, an item chosen by a click or, with focus, by Up and Down
	(scrolled into view), and activated by a click on the chosen one or Enter, Space or a pad's South. Ask selectedIndex, changed and
	activated once a frame. */
class ListView extends Widget {
	var face:Shape2D;
	var window:Node2D;
	var content:Node2D;
	var rows:Array<{face:Shape2D, text:Text2D}> = [];
	var itemList:Array<String> = [];
	var visibleRows:Int;
	var selected = -1;
	var scroll = 0.;
	var dragFrom = Math.NaN;
	var scrollFrom = 0.;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, items:Array<String>, rows:Int) {
		super(ui, name);
		visibleRows = rows < 1 ? 1 : rows;
		var theme = ui.theme;
		face = Shape2D.rectangle(1, 1, theme.faceColor);
		face.setPivot(0, 0);
		face.cornerRadius = theme.cornerRadius;
		window = new Node2D();
		content = new Node2D();
		window.addChild(content);
		root.addChild(face);
		root.addChild(window);
		box = Box.of(face);
		box.setSizing(Grow(1), Fixed(visibleRows * theme.widgetHeight));
		this.items = items;
	}

	/** Its items. */
	public var items(get, set):Array<String>;

	function get_items():Array<String>
		return itemList.copy();

	function set_items(value:Array<String>):Array<String> {
		itemList = value.copy();
		var theme = ui.theme;
		for (r in rows) {
			content.removeChild(r.face);
			content.removeChild(r.text);
		}
		rows = [];
		for (i in 0...itemList.length) {
			var rowFace = Shape2D.rectangle(1, theme.widgetHeight, 0);
			rowFace.setPivot(0, 0);
			rowFace.cornerRadius = theme.cornerRadius;
			rowFace.pickable = false;
			var text = new Text2D(itemList[i], theme.textSize, theme.textColor, Left, theme.font);
			content.addChild(rowFace);
			content.addChild(text);
			rows.push({face: rowFace, text: text});
		}
		selected = -1;
		scroll = 0;
		return value;
	}

	/** The chosen item's index, or -1 for none; assigning one scrolls it into view, not counted as a change. Clamped to -1 to the last
		item's index. */
	public var selectedIndex(get, set):Int;

	function get_selectedIndex():Int
		return selected;

	function set_selectedIndex(index:Int):Int {
		index = index < -1 ? -1 : index >= itemList.length ? itemList.length - 1 : index;
		selected = index;
		reveal();
		return index;
	}

	/** Whether the chosen item changed this frame. */
	public var changed(default, null):Bool = false;

	/** Whether the chosen item was activated this frame: clicked again, or Enter, Space or South with focus. */
	public var activated(default, null):Bool = false;

	override function get_focusable():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function takesUpDown():Bool
		return true;

	function reveal():Void {
		var height = ui.theme.widgetHeight;
		if (selected < 0)
			return;
		scroll = Math.max(Math.min(scroll, selected * height), (selected + 1) * height - visibleRows * height);
	}

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, stepX:Int, stepY:Int):Void {
		var theme = ui.theme, input = ui.input, camera = ui.camera, height = theme.widgetHeight, was = selected;
		this.activated = false;
		var wx = camera.screenToWorldX(input.pointerX),
			wy = camera.screenToWorldY(input.pointerY);
		var localY = face.toLocalY(wx, wy) + scroll;
		if (enabled && hovered && input.wheelY != 0)
			scroll -= input.wheelY * height;
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
				if (row >= 0 && row < itemList.length) {
					if (row == selected)
						this.activated = true;
					selected = row;
				}
			}
			dragFrom = Math.NaN;
		}
		if (enabled && stepY != 0 && itemList.length > 0) {
			selected = selected < 0 ? 0 : Std.int(Math.max(0, Math.min(itemList.length - 1, selected + stepY)));
			reveal();
		}
		if (enabled && activated && selected >= 0)
			this.activated = true;
		scroll = Math.max(0, Math.min(scroll, Math.max(0, itemList.length * height - visibleRows * height)));
		changed = selected != was;
		// The window clips the rows to the box; the rows scroll inside it.
		window.setPosition(box.x, box.y);
		window.setClip(box.width, box.height);
		content.setPosition(0, -scroll);
		for (i in 0...rows.length) {
			var r = rows[i];
			r.face.setSize(box.width, height);
			r.face.setPosition(0, i * height);
			r.face.color = i == selected ? theme.accentColor : 0;
			r.text.setPosition(theme.padding, i * height + (height - theme.textSize) / 2);
			r.text.color = enabled ? theme.textColor : theme.disabledTextColor;
		}
	}
}
