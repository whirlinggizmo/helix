package helix.ui;

import helix.input.Key;
import helix.render2d.Node2D;
import helix.render2d.Shape2D;

/** A window onto a column of widgets (add; content), clipping them, drawn and picked, to what's in view and scrolling them up and down: by the
	wheel over it, a drag on its empty space, its scrollbar (Scrollbar: its thumb dragged, its track pressed above or below the thumb for a
	page), and keys: focus moving by keys or a pad to a widget out of view scrolls it into view, Page Up and Page Down page while focus is in
	it, and with no widget in it that takes focus it takes focus itself, Up and Down then stepping it. The widgets in it work as anywhere,
	the pointer reaching them only where they're in view. Its height is its layout's (the height it was made with, to start), its width
	what its layout is given (Grow, to start); the column's gap the theme's. The scrollbar at its right edge shows as scrollbarVisibility says,
	the column narrowing for it while it shows. A wheel over a list in it scrolls the list, not it. Ask scroll (or set it) once a frame. */
class ScrollArea extends Widget {
	var face:Shape2D;
	var window:Node2D;
	var inner:Node2D;
	var bar:Scrollbar;
	var offset = 0.;
	var dragFrom = Math.NaN;
	var scrollFrom = 0.;
	var onBar = false;
	var lastFocused:Null<Widget>;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, height:Float) {
		super(ui, name);
		var theme = ui.theme;
		// A face of no color under everything, the pointer's for the wheel and drags; the window clipping the widgets, which sit under a node
		// moved by the scroll the layout hasn't caught up with yet (scrolled this frame, arranged next).
		face = Shape2D.rectangle(1, 1, 0);
		face.setPivot(0, 0);
		window = new Node2D();
		inner = new Node2D();
		window.addChild(inner);
		root.addChild(face);
		root.addChild(window);
		bar = new Scrollbar(root, theme);
		content = Layout2D.column();
		content.setAlign(Start, Stretch);
		content.setAnchor(Stretch, Start);
		layout = Layout2D.stack(face);
		layout.themeSizing(Grow(1), Fixed(height));
		layout.add(content);
		readTheme(theme);
	}

	/** The column its widgets go in (its gap the theme's until set), for layouts of other kinds (a row of widgets: put their layouts in a row,
		the row here, and the widgets in it with adopt). Its height is the content's: what's past the window is scrolled to. */
	public var content(default, null):Layout2D;

	/** Puts widget in it, last in its column: its nodes under the area's (clipped to its window, hidden with it), its layout in the column. */
	public function add(widget:Widget):Void {
		adopt(widget);
		content.add(widget.layout);
	}

	/** Puts widget's nodes under the area's (clipped to its window, hidden with it) without placing it: its layout goes in one of the caller's
		inside content. */
	public function adopt(widget:Widget):Void {
		widget.root.parent = null;
		inner.addChild(widget.root);
	}

	/** How far its content is scrolled, in units from its top: 0 to maxScroll as last arranged (out of that range is held to it by the next
		update). */
	public var scroll(get, set):Float;

	function get_scroll():Float
		return offset;

	function set_scroll(value:Float):Float {
		offset = clamp(value);
		return offset;
	}

	/** How far its content can scroll, in units, as last arranged: its height less the window's, 0 when it fits. */
	public var maxScroll(get, never):Float;

	function get_maxScroll():Float
		return Math.max(0, content.height - layout.height);

	/** When its scrollbar is drawn, or null (to start) for the theme's scrollbarVisibility: a value is kept whatever the theme becomes. */
	public var scrollbarVisibility:Null<ScrollbarVisibility> = null;

	/** Whether its scrollbar is drawn, as last updated. */
	public var scrollbarShown(get, never):Bool;

	function get_scrollbarShown():Bool
		return bar.visible;

	// Focus rests on it only when nothing in it takes focus (a column of labels): Up and Down then scroll it.
	override function get_focusable():Bool {
		for (w in ui.widgets)
			if (w != this && w.focusable && holds(w))
				return false;
		return true;
	}

	override function target():Null<Node2D>
		return face;

	override function takesUpDown():Bool
		return true;

	// Whether w's nodes are inside it.
	function holds(w:Widget):Bool {
		var at = w.root.parent;
		while (at != null) {
			if (at == root)
				return true;
			at = at.parent;
		}
		return false;
	}

	function clamp(value:Float):Float
		return Math.max(0, Math.min(value, maxScroll));

	// "track" and "thumb": its scrollbar's, while it shows.
	override function locatePart(part:String, out:Array<Float>):Null<Node2D>
		return part == "" ? super.locatePart(part, out) : bar.computePart(part, out) ? root : null;

	override function readTheme(theme:Theme):Void {
		content.themeGap(theme.gap);
		bar.readTheme(theme);
	}

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, stepX:Int, stepY:Int):Void {
		var theme = ui.theme,
			input = ui.input,
			camera = ui.camera,
			view = layout.height,
			total = content.height;
		var wx = camera.screenToWorldX(input.pointerX),
			wy = camera.screenToWorldY(input.pointerY);
		// The pointer in its layout's units.
		var px = face.toLocalX(wx, wy) + layout.x,
			py = face.toLocalY(wx, wy) + layout.y;
		var shown = Scrollbar.isShown(scrollbarVisibility != null ? scrollbarVisibility : theme.scrollbarVisibility, view, total);
		bar.setTrack(layout.x + layout.width - bar.width, layout.y, view, view, total, shown);
		var page = view;
		// The wheel anywhere over it (over a widget in it too) but over a list or another area in it, which scroll themselves.
		if (enabled && input.wheelY != 0 && wheelIsMine())
			offset -= input.wheelY * theme.widgetHeight;
		// A press on its empty space drags the content; on the scrollbar, the bar has it.
		if (enabled && held) {
			if (Math.isNaN(dragFrom)) {
				dragFrom = wy;
				scrollFrom = offset;
				onBar = bar.isOver(px, py);
				if (onBar)
					offset = bar.drive(px, py, true, true, offset);
			} else if (onBar)
				offset = bar.drive(px, py, false, true, offset);
			else if (Math.abs(wy - dragFrom) > 4)
				offset = scrollFrom - (wy - dragFrom);
		} else {
			bar.drive(px, py, false, false, offset);
			dragFrom = Math.NaN;
			onBar = false;
		}
		// Keys: Up and Down step it while it has focus itself; Page Up and Page Down page it while focus is in it.
		if (enabled && stepY != 0)
			offset += stepY * theme.widgetHeight;
		var inside = ui.focused != null && (ui.focused == this || holds(ui.focused));
		if (enabled && inside && !ui.focused.takesText()) {
			if (input.isFramePressed(Key.PageDown))
				offset += page;
			if (input.isFramePressed(Key.PageUp))
				offset -= page;
		}
		// Focus moved by keys or a pad (or the game) to a widget in it: scrolled into view, with room for the focus ring.
		var now = ui.focused;
		if (now != lastFocused && now != null && now != this && ui.showFocus && holds(now))
			reveal(now, view, theme.focusWidth * 3);
		lastFocused = now;
		offset = clamp(offset);
		// The column narrowed for the bar while it shows; the window clipping it; the widgets moved by the scroll the layout placed them at
		// (its content's top) less this frame's, until it's arranged again.
		var room = shown ? bar.width + theme.gap : 0;
		layout.themePadding(0, 0, room, 0);
		content.setAnchor(Stretch, Start, 0, -offset);
		var arranged = layout.y - content.y;
		window.setPosition(layout.x, layout.y);
		window.setClip(Math.max(0, layout.width - room), Math.max(0, view));
		inner.setPosition(-layout.x, -layout.y + arranged - offset);
		bar.place(offset, hovered || bar.dragging ? px : Math.NaN, py, enabled, theme);
	}

	// Scrolls w's layout (and margin around it) into view, as little as it takes.
	function reveal(w:Widget, view:Float, margin:Float):Void {
		var top = w.layout.y - content.y - margin,
			bottom = w.layout.y - content.y + w.layout.height + margin;
		offset = Math.max(Math.min(offset, top), bottom - view);
	}

	// Whether the node under the pointer is in it and not in a list or another scroll area in it.
	function wheelIsMine():Bool {
		var at = Std.downcast(ui.pointer.hovered, Node2D);
		while (at != null && at != root) {
			for (w in ui.widgets)
				if (w.root == at && (Std.isOfType(w, ListView) || Std.isOfType(w, ScrollArea)))
					return false;
			at = at.parent;
		}
		return at == root;
	}
}
