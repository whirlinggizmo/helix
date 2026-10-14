package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Texture2D;

/** A background holding a column of widgets (add): hidden, they're hidden with it. A plain rectangle in the theme's panel color, or a nine-slice
	frame (setFrame). Never focused; the pointer stops at it, so what's under a panel doesn't see it. */
class Panel extends Widget {
	var background:Node2D;
	var content:Box;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String) {
		super(ui, name);
		var theme = ui.getTheme();
		background = Node2D.rectangle(1, 1, theme.panel);
		background.setPivot(0, 0);
		root.add(background);
		content = Box.column()
			.setPadding(theme.padding, theme.padding, theme.padding, theme.padding)
			.setGap(theme.gap)
			.setAlign(Start, Stretch);
		box = Box.stack(background).add(content.setAnchor(Stretch, Stretch));
	}

	/** Puts widget in it, last in its column: its nodes under the panel's (hidden with it), its box in the column. Returns this panel. */
	public function add(widget:Widget):Panel {
		widget.getRoot().getParent().remove(widget.getRoot());
		root.add(widget.getRoot());
		content.add(widget.getBox());
		return this;
	}

	/** The column its widgets go in, for boxes of other kinds (a row of buttons: put the buttons' boxes in a row, and the buttons in the panel
		with adopt). */
	public function getContent():Box
		return content;

	/** Puts widget's nodes under the panel's (hidden with it) without placing it: its box goes in a layout of the caller's inside getContent().
		Returns this panel. */
	public function adopt(widget:Widget):Panel {
		widget.getRoot().getParent().remove(widget.getRoot());
		root.add(widget.getRoot());
		return this;
	}

	/** Draws it as texture's nine-slice frame, its corners left, top, right and bottom texels in, tinted tint; returns false for no texture. */
	public function setFrame(texture:Null<Texture2D>, left:Float, top:Float, right:Float, bottom:Float, tint = 0xffffffff):Bool {
		if (texture == null)
			return false;
		var frame = Node2D.sprite(texture);
		frame.setColor(tint);
		frame.setPivot(0, 0);
		frame.setNineSlice(left, top, right, bottom);
		// In the background's place, first: under its widgets.
		root.remove(background);
		var others = [for (i in 0...root.getChildCount()) root.getChild(i)];
		for (n in others)
			root.remove(n);
		root.add(frame);
		for (n in others)
			root.add(n);
		background = frame;
		box = Box.stack(background).add(content.setAnchor(Stretch, Stretch));
		return true;
	}

	override function target():Null<Node2D>
		return background;
}
