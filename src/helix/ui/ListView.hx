package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Shape2D;
import helix.render2d.ShapeShading2D;
import helix.render2d.Text2D;

/** A list of items in a window rows tall: scrolled by the wheel over it, a drag or its scrollbar (Scrollbar, at its right edge as
	scrollbarVisibility says, the rows narrowing for it while it shows: its thumb dragged, its track pressed above or below the thumb for a
	page), an item chosen by a click or, with focus, by Up and Down (scrolled into view), and activated by a click on the chosen one or Enter,
	Space or a pad's South. Ask selectedIndex, changed and activated once a frame. */
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
	var bar:Scrollbar;
	// Whether the press being held began on the scrollbar.
	var onBar = false;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, items:Array<String>, rows:Int) {
		super(ui, name);
		visibleRows = rows < 1 ? 1 : rows;
		var theme = ui.theme;
		face = Shape2D.rectangle(1, 1, theme.faceColor);
		face.setPivot(0, 0);
		window = new Node2D();
		content = new Node2D();
		window.addChild(content);
		root.addChild(face);
		root.addChild(window);
		bar = new Scrollbar(root, theme);
		layout = Layout2D.of(face);
		layout.themeSizing(Grow(1), Fit);
		// Its look from the theme, with its rows' (readTheme).
		this.items = items;
	}

	/** Its items. */
	public var items(get, set):Array<String>;

	function get_items():Array<String>
		return itemList.copy();

	function set_items(value:Array<String>):Array<String> {
		itemList = value.copy();
		for (r in rows) {
			content.removeChild(r.face);
			content.removeChild(r.text);
		}
		rows = [];
		for (i in 0...itemList.length) {
			// Sized, placed and styled from the theme by readTheme and update.
			var rowFace = Shape2D.rectangle(1, 1, 0);
			rowFace.setPivot(0, 0);
			rowFace.pickable = false;
			var text = new Text2D(itemList[i]);
			content.addChild(rowFace);
			content.addChild(text);
			rows.push({face: rowFace, text: text});
		}
		selected = -1;
		scroll = 0;
		readTheme(ui.theme);
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

	/** When its scrollbar is drawn, or null (to start) for the theme's scrollbarVisibility: a value is kept whatever the theme becomes. */
	public var scrollbarVisibility:Null<ScrollbarVisibility> = null;

	/** Whether its scrollbar is drawn, as last updated. */
	public var scrollbarShown(get, never):Bool;

	function get_scrollbarShown():Bool
		return bar.visible;

	override function get_focusable():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function takesUpDown():Bool
		return true;

	// "track" and "thumb", its scrollbar's while it shows; "row:<index>", that item's row where it's scrolled to (in view or not).
	override function locatePart(part:String, out:Array<Float>):Null<Node2D> {
		if (part == "")
			return super.locatePart(part, out);
		var row = Widget.rowPart(part);
		if (row < 0)
			return bar.computePart(part, out) ? root : null;
		if (row >= itemList.length)
			return null;
		var theme = ui.theme,
			pad = theme.listPadding,
			height = theme.listRowHeight;
		var inside = Math.max(0, layout.width - pad * 2 - (bar.visible ? bar.width + pad : 0));
		Widget.setRectangle(out, layout.x + pad, layout.y + pad + row * height - scroll, inside, height);
		return root;
	}

	function reveal():Void {
		var height = ui.theme.listRowHeight;
		if (selected < 0)
			return;
		scroll = Math.max(Math.min(scroll, selected * height), (selected + 1) * height - visibleRows * height);
	}

	override function readTheme(theme:Theme):Void {
		face.cornerRadius = theme.listCornerRadius;
		for (r in rows) {
			r.face.cornerRadius = theme.listRowCornerRadius;
			r.text.textSize = theme.textSize;
			r.text.font = theme.font;
		}
		themeFixed(layout, Math.NaN, visibleRows * theme.listRowHeight + theme.listPadding * 2);
		bar.readTheme(theme);
	}

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, stepX:Int, stepY:Int):Void {
		var theme = ui.theme, input = ui.input, camera = ui.camera, height = theme.listRowHeight, was = selected;
		this.activated = false;
		var wx = camera.screenToWorldX(input.pointerX),
			wy = camera.screenToWorldY(input.pointerY);
		var localY = face.toLocalY(wx, wy) - theme.listPadding + scroll;
		// The pointer in its layout's units, for the scrollbar inside the padding at the right.
		var px = face.toLocalX(wx, wy) + layout.x,
			py = face.toLocalY(wx, wy) + layout.y;
		var pad = theme.listPadding,
			view = visibleRows * height,
			total = itemList.length * height,
			shown = Scrollbar.isShown(scrollbarVisibility != null ? scrollbarVisibility : theme.scrollbarVisibility, view, total);
		bar.setTrack(layout.x + layout.width - pad - bar.width, layout.y + pad, Math.max(0, layout.height - pad * 2), view, total, shown);
		if (enabled && hovered && input.wheelY != 0)
			scroll -= input.wheelY * height;
		// A drag scrolls (on the scrollbar, the bar has it); a click without one chooses the row under it (again: activates it).
		if (enabled && held) {
			if (Math.isNaN(dragFrom)) {
				dragFrom = wy;
				scrollFrom = scroll;
				onBar = bar.isOver(px, py);
				if (onBar)
					scroll = bar.drive(px, py, true, true, scroll);
			} else if (onBar)
				scroll = bar.drive(px, py, false, true, scroll);
			else if (Math.abs(wy - dragFrom) > 4)
				scroll = scrollFrom - (wy - dragFrom);
		} else {
			bar.drive(px, py, false, false, scroll);
			if (clicked && !onBar && (Math.isNaN(dragFrom) || Math.abs(wy - dragFrom) <= 4)) {
				var row = Math.floor(localY / height);
				if (row >= 0 && row < itemList.length) {
					if (row == selected)
						this.activated = true;
					selected = row;
				}
			}
			dragFrom = Math.NaN;
			onBar = false;
		}
		if (enabled && stepY != 0 && itemList.length > 0) {
			selected = selected < 0 ? 0 : Std.int(Math.max(0, Math.min(itemList.length - 1, selected + stepY)));
			reveal();
		}
		if (enabled && activated && selected >= 0)
			this.activated = true;
		scroll = Math.max(0, Math.min(scroll, Math.max(0, itemList.length * height - visibleRows * height)));
		changed = selected != was;
		// The window clips the rows to the layout inside its padding (clear of its round corners), less the scrollbar and a padding's room
		// before it while it shows; the rows scroll inside it.
		var inside = Math.max(0, layout.width - pad * 2 - (shown ? bar.width + pad : 0));
		window.setPosition(layout.x + pad, layout.y + pad);
		window.setClip(inside, Math.max(0, layout.height - pad * 2));
		content.setPosition(0, -scroll);
		// The row under the pointer (in the window, off the scrollbar, and not while the list is dragged or the bar has the pointer) is over, or
		// down while a press on it may yet choose it; the chosen row is in the accent color whatever its state, the others clear at rest.
		var state = WidgetState.of(enabled, held, hovered, focused), pointed = -1;
		var inX = px - layout.x - pad, inY = py - layout.y - pad;
		if (hovered && !bar.dragging && !onBar && inX >= 0 && inX < inside && inY >= 0 && inY < view && (!held || Math.abs(wy - dragFrom) <= 4))
			pointed = Math.floor((inY + scroll) / height);
		face.color = state == Disabled ? WidgetState.dim(theme.faceColor) : theme.faceColor;
		for (i in 0...rows.length) {
			var r = rows[i];
			r.face.setSize(inside, height);
			r.face.setPosition(0, i * height);
			var rowState = WidgetState.of(enabled, held && i == pointed, i == pointed, false);
			r.face.color = i == selected ? (rowState == Disabled ? WidgetState.dim(theme.accentColor) : theme.accentColor) : rowState.pick(0,
				theme.hoveredColor, theme.pressedColor, 0, 0);
			r.text.color = rowState.text(theme);
			r.text.setPosition(theme.padding, i * height + (height - theme.textSize) / 2);
		}
		bar.place(scroll, hovered || bar.dragging ? px : Math.NaN, py, enabled, theme);
	}
}
