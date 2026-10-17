package helix.ui;

import helix.render2d.Node2D;

/** A box that's on or off, beside a line of text: switched by a click or by activating it with focus. Ask on, and changed once a
	frame. */
class Toggle extends Widget {
	var face:Node2D;
	var check:Node2D;
	var mark:Node2D;
	var label:Node2D;
	var value:Bool;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, text:String, value:Bool) {
		super(ui, name);
		this.value = value;
		var theme = ui.theme, side = theme.textSize + 4;
		face = Node2D.rectangle(1, 1, 0);
		face.setPivot(0, 0);
		check = Node2D.rectangle(side, side, theme.faceColor);
		check.setPivot(0, 0);
		check.setCornerRadius(theme.cornerRadius / 2);
		check.pickable = false;
		mark = Node2D.rectangle(side - 8, side - 8, theme.accentColor);
		mark.setPivot(0, 0);
		mark.setCornerRadius(theme.cornerRadius / 4);
		mark.pickable = false;
		label = Node2D.text(text, theme.textSize, theme.textColor, Left, theme.font);
		for (n in [face, check, mark, label])
			root.addChild(n);
		var tick = Box.of(mark), square = Box.of(check), row = Box.row();
		tick.setAnchor(Center, Center);
		square.add(tick);
		row.gap = theme.gap;
		row.setAlign(Start, Center);
		row.setAnchor(Start, Center);
		row.add(square);
		row.add(Box.of(label));
		box = Box.stack(face);
		box.setSizing(Fit, Fixed(theme.widgetHeight));
		box.add(row);
	}

	/** Whether it's on. */
	public var on(get, set):Bool;

	function get_on():Bool
		return value;

	function set_on(on:Bool):Bool {
		value = on;
		return on;
	}

	/** Whether it was switched this frame. */
	public var changed(default, null):Bool = false;

	override function get_focusable():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		var theme = ui.theme;
		changed = enabled && (clicked || activated);
		if (changed)
			value = !value;
		check.color = held ? theme.pressedColor : hovered ? theme.hoveredColor : theme.faceColor;
		mark.visible = value;
		label.color = enabled ? theme.textColor : theme.disabledTextColor;
	}
}
