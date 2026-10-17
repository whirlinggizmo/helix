package helix.ui;

import helix.render2d.Node2D;

/** A button reading a line of text: clicked by the pointer (released over it, as pressed), or activated with focus by Enter, Space or a pad's
	South. Ask clicked once a frame. */
class Button extends Widget {
	var face:Node2D;
	var label:Node2D;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, text:String) {
		super(ui, name);
		var theme = ui.theme;
		face = Node2D.rectangle(1, 1, theme.faceColor);
		face.setPivot(0, 0);
		face.setCornerRadius(theme.cornerRadius);
		label = Node2D.text(text, theme.textSize, theme.textColor, Center, theme.font);
		root.addChild(face);
		root.addChild(label);
		box = Box.stack(face);
		box.setSizing(Fit, Fixed(theme.widgetHeight));
		box.setPadding(theme.padding * 2, 0, theme.padding * 2, 0);
		var text = Box.of(label);
		text.setAnchor(Center, Center);
		box.add(text);
	}

	/** Whether it was clicked or activated this frame. */
	public var clicked(default, null):Bool = false;

	/** Its text. */
	public var text(get, set):String;

	function get_text():String
		return label.getText();

	function set_text(value:String):String {
		label.setText(value);
		return value;
	}

	override function get_focusable():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		var theme = ui.theme;
		this.clicked = enabled && (clicked || activated);
		face.color = held ? theme.pressedColor : hovered ? theme.hoveredColor : theme.faceColor;
		label.color = enabled ? theme.textColor : theme.disabledTextColor;
	}
}
