package helix.ui;

import helix.render2d.Node2D;

/** A line of text (wrapped, if given a width): shown, never focused. */
class Label extends Widget {
	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, text:String) {
		super(ui, name);
		var theme = ui.theme;
		node = Node2D.text(text, theme.textSize, theme.textColor, Left, theme.font);
		root.addChild(node);
		box = Box.of(node);
	}

	/** Its text. */
	public var text(get, set):String;

	function get_text():String
		return node.getText();

	function set_text(value:String):String {
		node.setText(value);
		return value;
	}

	/** Its text node: its color, size, alignment, wrap width. */
	public var node(default, null):Node2D;
}
