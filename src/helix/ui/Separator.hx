package helix.ui;

import helix.render2d.Shape2D;

/** A thin line between widgets: across its column (horizontal, made so to start) or down its row (vertical), as told when made, spanning its
	parent that way (its layout grows that way: Grow(1)), as thick as the theme's focusWidth, in the theme's faceColor, with half the theme's gap
	of room either side of it. Never focused, never picked, no states. */
class Separator extends Widget {
	var line:Shape2D;
	var lineLayout:Layout2D;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, vertical:Bool) {
		super(ui, name);
		this.vertical = vertical;
		var theme = ui.theme;
		line = Shape2D.rectangle(1, 1, theme.faceColor);
		line.setPivot(0, 0);
		line.pickable = false;
		root.addChild(line);
		lineLayout = Layout2D.of(line);
		layout = Layout2D.stack();
		layout.add(lineLayout);
		if (vertical) {
			layout.themeSizing(Fit, Grow(1));
			lineLayout.themeSizing(null, Grow(1));
		} else {
			layout.themeSizing(Grow(1), Fit);
			lineLayout.themeSizing(Grow(1), null);
		}
		readTheme(theme);
	}

	/** Whether it's a vertical line, down a row; false for a horizontal one, across a column. */
	public var vertical(default, null):Bool;

	override function readTheme(theme:Theme):Void {
		line.color = theme.faceColor;
		var room = theme.gap / 2;
		if (vertical) {
			themeFixed(lineLayout, theme.focusWidth, Math.NaN);
			layout.themePadding(room, 0, room, 0);
		} else {
			themeFixed(lineLayout, Math.NaN, theme.focusWidth);
			layout.themePadding(0, room, 0, room);
		}
	}
}
