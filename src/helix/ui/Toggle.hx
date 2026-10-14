package helix.ui;

import helix.render2d.Node2D;

/** A box that's on or off, beside a line of text: switched by a click or by activating it with focus. Ask getValue, and isChanged once a
	frame. */
class Toggle extends Widget {
	var face:Node2D;
	var check:Node2D;
	var mark:Node2D;
	var label:Node2D;
	var value:Bool;
	var changed = false;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, text:String, value:Bool) {
		super(ui, name);
		this.value = value;
		var theme = ui.getTheme(), side = theme.textSize + 4;
		face = Node2D.rectangle(1, 1, 0);
		face.setPivot(0, 0);
		check = Node2D.rectangle(side, side, theme.face);
		check.setPivot(0, 0);
		check.setPickable(false);
		mark = Node2D.rectangle(side - 8, side - 8, theme.accent);
		mark.setPivot(0, 0);
		mark.setPickable(false);
		label = Node2D.text(text, theme.textSize, theme.text, Left, theme.font);
		label.setPickable(false);
		for (n in [face, check, mark, label])
			root.add(n);
		var row = Box.row()
			.setGap(theme.gap)
			.setAlign(Start, Center)
			.add(Box.of(check).add(Box.of(mark).setAnchor(Center, Center)))
			.add(Box.of(label));
		box = Box.stack(face).setSize(Fit, Fixed(theme.height)).add(row.setAnchor(Start, Center));
	}

	/** Whether it's on. */
	public function getValue():Bool
		return value;

	/** Turns it on or off (not counted as a change). */
	public function setValue(on:Bool):Void
		value = on;

	/** Whether it was switched this frame. */
	public function isChanged():Bool
		return changed;

	override public function isFocusable():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		var theme = ui.getTheme();
		changed = enabled && (clicked || activated);
		if (changed)
			value = !value;
		check.setColor(held ? theme.pressed : hovered ? theme.hovered : theme.face);
		mark.setVisible(value);
		label.setColor(enabled ? theme.text : theme.disabledText);
	}
}
