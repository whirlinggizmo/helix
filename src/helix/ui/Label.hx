package helix.ui;

import helix.render2d.Node2D;

/** A line of text (wrapped, if given a width): shown, never focused. */
class Label extends Widget {
	var node:Node2D;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, text:String) {
		super(ui, name);
		var theme = ui.getTheme();
		node = Node2D.text(text, theme.getTextSize(), theme.getTextColor(), Left, theme.getFont());
		root.add(node);
		box = Box.of(node);
	}

	/** Its text. */
	public function getText():String
		return node.getText();

	/** Shows text. */
	public function setText(value:String):Void
		node.setText(value);

	/** Its text node: its color, size, alignment, wrap width. */
	public function getNode():Node2D
		return node;
}
