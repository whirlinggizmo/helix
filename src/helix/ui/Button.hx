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
		face = Node2D.rectangle(1, 1, theme.face);
		face.setPivot(0, 0);
		label = Node2D.text(text, theme.textSize, theme.text, Center, theme.font);
		label.setPickable(false);
		root.add(face);
		root.add(label);
		box = Box.stack(face).setSize(Fit, Fixed(theme.height)).setPadding(theme.padding * 2, 0, theme.padding * 2, 0);
		box.add(Box.of(label).setAnchor(Center, Center));
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
		face.setColor(held ? theme.pressed : hovered ? theme.hovered : theme.face);
		label.setColor(enabled ? theme.text : theme.disabledText);
	}
}
