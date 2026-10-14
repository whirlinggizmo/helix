package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Texture2D;

/** A background holding a column of widgets: add their boxes to getContent(). A plain rectangle in the theme's panel color, or a nine-slice
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

	/** The column its widgets go in. */
	public function getContent():Box
		return content;

	/** Draws it as texture's nine-slice frame, its corners left, top, right and bottom texels in, tinted tint; returns false for no texture. */
	public function setFrame(texture:Null<Texture2D>, left:Float, top:Float, right:Float, bottom:Float, tint = 0xffffffff):Bool {
		if (texture == null)
			return false;
		root.remove(background);
		background = Node2D.sprite(texture);
		background.setColor(tint);
		background.setPivot(0, 0);
		background.setNineSlice(left, top, right, bottom);
		root.add(background);
		box = Box.stack(background).add(content);
		return true;
	}

	override function target():Null<Node2D>
		return background;
}
