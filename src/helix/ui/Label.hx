package helix.ui;

import helix.render2d.Text2D;

/** A line of text (wrapped, if given a width): shown, never focused. */
class Label extends Widget {
	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, text:String) {
		super(ui, name);
		var theme = ui.theme;
		node = new Text2D(text, theme.textSize, theme.textColor, Left, theme.font);
		root.addChild(node);
		box = Box.of(node);
	}

	/** Its text. */
	public var text(get, set):String;

	function get_text():String
		return node.text;

	function set_text(value:String):String {
		node.text = value;
		return value;
	}

	/** Its text node: its color, size, alignment, wrap width. */
	public var node(default, null):Text2D;
}
