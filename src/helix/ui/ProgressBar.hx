package helix.ui;

import helix.render2d.Node2D;

/** How far along something is: a track filled from its left by a value, 0 to 1. Never focused. */
class ProgressBar extends Widget {
	var track:Node2D;
	var fill:Node2D;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, value:Float) {
		super(ui, name);
		this.value = Math.max(0, Math.min(1, value));
		var theme = ui.theme;
		track = Node2D.rectangle(1, 1, theme.faceColor);
		track.setPivot(0, 0);
		track.setCornerRadius(theme.cornerRadius);
		track.pickable = false;
		fill = Node2D.rectangle(1, 1, theme.accentColor);
		fill.setPivot(0, 0);
		fill.setCornerRadius(theme.cornerRadius);
		fill.pickable = false;
		root.addChild(track);
		root.addChild(fill);
		box = Box.of(track);
		box.setSizing(Grow(1), Fixed(theme.textSize * .75));
	}

	/** How far along, 0 to 1. */
	public var value(default, set):Float;

	function set_value(v:Float):Float {
		value = Math.max(0, Math.min(1, v));
		return v;
	}

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		fill.setSize(Math.max(0, box.width * value), box.height);
		fill.setPosition(box.x, box.y);
	}
}
