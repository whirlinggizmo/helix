package helix.ui;

import helix.render2d.Node2D;

/** How far along something is: a track filled from its left by a value, 0 to 1. Never focused. */
class ProgressBar extends Widget {
	var track:Node2D;
	var fill:Node2D;
	var value:Float;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, value:Float) {
		super(ui, name);
		this.value = Math.max(0, Math.min(1, value));
		var theme = ui.getTheme();
		track = Node2D.rectangle(1, 1, theme.face);
		track.setPivot(0, 0);
		track.setCornerRadius(theme.corner);
		track.setPickable(false);
		fill = Node2D.rectangle(1, 1, theme.accent);
		fill.setPivot(0, 0);
		fill.setCornerRadius(theme.corner);
		fill.setPickable(false);
		root.add(track);
		root.add(fill);
		box = Box.of(track).setSize(Grow(1), Fixed(theme.textSize * .75));
	}

	/** How far along, 0 to 1. */
	public function getValue():Float
		return value;

	/** Sets how far along (held to 0 .. 1). */
	public function setValue(v:Float):Void
		value = Math.max(0, Math.min(1, v));

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		fill.setSize(Math.max(0, box.getWidth() * value), box.getHeight());
		fill.setPosition(box.getX(), box.getY());
	}
}
