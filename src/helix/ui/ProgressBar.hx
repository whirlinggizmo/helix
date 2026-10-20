package helix.ui;

import helix.render2d.Shape2D;

/** How far along something is: a track filled from its left by a value, 0 to 1. Never focused. */
class ProgressBar extends Widget {
	var track:Shape2D;
	var fill:Shape2D;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, value:Float) {
		super(ui, name);
		this.value = Math.max(0, Math.min(1, value));
		var theme = ui.theme;
		track = Shape2D.rectangle(1, 1, theme.faceColor);
		track.setPivot(0, 0);
		track.pickable = false;
		fill = Shape2D.rectangle(1, 1, theme.accentColor);
		fill.setPivot(0, 0);
		fill.pickable = false;
		root.addChild(track);
		root.addChild(fill);
		layout = Layout2D.of(track);
		layout.themeSizing(Grow(1), Fit);
		readTheme(theme);
	}

	/** How far along, 0 to 1. */
	public var value(default, set):Float;

	function set_value(v:Float):Float {
		value = Math.max(0, Math.min(1, v));
		return v;
	}

	override function readTheme(theme:Theme):Void {
		track.color = theme.faceColor;
		fill.color = theme.accentColor;
		track.cornerRadius = fill.cornerRadius = theme.cornerRadius;
		themeFixed(layout, Math.NaN, theme.textSize * .75);
	}

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, stepX:Int, stepY:Int):Void {
		fill.setSize(Math.max(0, layout.width * value), layout.height);
		fill.setPosition(layout.x, layout.y);
	}
}
