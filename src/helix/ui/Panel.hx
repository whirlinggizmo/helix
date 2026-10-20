package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Sprite2D;
import helix.render2d.Shape2D;
import helix.render2d.Texture2D;

/** A background holding a column of widgets (add): hidden, they're hidden with it. A plain rectangle in the theme's panel color, or a nine-slice
	frame (setFrame). Never focused; the pointer stops at it, so what's under a panel doesn't see it. */
class Panel extends Widget {
	var background:Node2D;
	var rectangle:Shape2D;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String) {
		super(ui, name);
		var theme = ui.theme;
		rectangle = Shape2D.rectangle(1, 1, theme.panelColor);
		rectangle.setPivot(0, 0);
		background = rectangle;
		root.addChild(background);
		content = Layout2D.column();
		content.setAlign(Start, Stretch);
		content.setAnchor(Stretch, Stretch);
		layout = Layout2D.stack(background);
		layout.add(content);
		readTheme(theme);
	}

	// The rectangle's color and corners (unused under a frame), the column's padding and gap, the theme's unless a game set its own.
	override function readTheme(theme:Theme):Void {
		rectangle.color = theme.panelColor;
		rectangle.cornerRadius = theme.cornerRadius;
		var pad = theme.padding;
		content.themePadding(pad, pad, pad, pad);
		content.themeGap(theme.gap);
	}

	/** Puts widget in it, last in its column: its nodes under the panel's (hidden with it), its layout in the column. */
	public function add(widget:Widget):Void {
		widget.root.parent = null;
		root.addChild(widget.root);
		content.add(widget.layout);
	}

	/** The column its widgets go in, for layouts of other kinds (a row of buttons: put the buttons' layouts in a row, and the buttons in the
		panel with adopt). */
	public var content(default, null):Layout2D;

	/** Puts widget's nodes under the panel's (hidden with it) without placing it: its layout goes in one of the caller's inside this.content. */
	public function adopt(widget:Widget):Void {
		widget.root.parent = null;
		root.addChild(widget.root);
	}

	// Its nine-slice frame (setFrame), or null for the theme's rectangle.
	var frame:Null<Sprite2D>;

	/** Draws it as texture's nine-slice frame, its corners left, top, right and bottom texels in, tinted tint. False, changing nothing, for no texture. */
	public function setFrame(texture:Null<Texture2D>, left:Float, top:Float, right:Float, bottom:Float, tint = 0xffffffff):Bool {
		if (texture == null)
			return false;
		frame = new Sprite2D(texture);
		frame.tint = tint;
		frame.setPivot(0, 0);
		frame.setNineSlice(left, top, right, bottom);
		// In the background's place, first: under its widgets.
		root.removeChild(background);
		var others = [for (i in 0...root.childCount) root.getChild(i)];
		for (n in others)
			root.removeChild(n);
		root.addChild(frame);
		for (n in others)
			root.addChild(n);
		background = frame;
		layout = Layout2D.stack(background);
		layout.add(content);
		return true;
	}

	override function target():Null<Node2D>
		return background;
}
