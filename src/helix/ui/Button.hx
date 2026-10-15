package helix.ui;

import helix.render2d.Node2D;

/** A button reading a line of text: clicked by the pointer (released over it, as pressed), or activated with focus by Enter, Space or a pad's
	South. Ask isClicked once a frame. */
class Button extends Widget {
	var face:Node2D;
	var label:Node2D;
	var clicked = false;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, text:String) {
		super(ui, name);
		var theme = ui.getTheme();
		face = Node2D.rectangle(1, 1, theme.getFaceColor());
		face.setPivot(0, 0);
		face.setCornerRadius(theme.getCornerRadius());
		label = Node2D.text(text, theme.getTextSize(), theme.getTextColor(), Center, theme.getFont());
		root.add(face);
		root.add(label);
		box = Box.stack(face);
		box.setSizing(Fit, Fixed(theme.getWidgetHeight()));
		box.setPadding(theme.getPadding() * 2, 0, theme.getPadding() * 2, 0);
		var text = Box.of(label);
		text.setAnchor(Center, Center);
		box.add(text);
	}

	/** Whether it was clicked or activated this frame. */
	public function isClicked():Bool
		return clicked;

	/** Its text. */
	public function getText():String
		return label.getText();

	/** Reads text. */
	public function setText(value:String):Void
		label.setText(value);

	override public function isFocusable():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		var theme = ui.getTheme();
		this.clicked = enabled && (clicked || activated);
		face.setColor(held ? theme.getPressedColor() : hovered ? theme.getHoveredColor() : theme.getFaceColor());
		label.setColor(enabled ? theme.getTextColor() : theme.getDisabledTextColor());
	}
}
