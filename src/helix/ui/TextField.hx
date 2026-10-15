package helix.ui;

import helix.input.Key;
import helix.render2d.Node2D;
import helix.render2d.Text2D;

/** A line of text typed in: with focus, the characters typed (after the keyboard layout) are added, Backspace takes the last off and Enter
	submits; the caret is at its end. While it has focus the UI has the keys (Ui.isCapturingKeys), however it got focus, so a game doesn't act on
	letters typed. Ask getText, isChanged and isSubmitted once a frame. No input method (IME) composition yet. */
class TextField extends Widget {
	var face:Node2D;
	var text:Node2D;
	var caret:Node2D;
	var hint:Node2D;
	var maxLength:Int;
	var changed = false;
	var submitted = false;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, value:String, hintText:String, maxLength:Int) {
		super(ui, name);
		this.maxLength = maxLength;
		var theme = ui.getTheme();
		face = Node2D.rectangle(1, 1, theme.face);
		face.setPivot(0, 0);
		face.setCornerRadius(theme.corner);
		text = Node2D.text(value.substr(0, maxLength), theme.textSize, theme.text, Left, theme.font);
		hint = Node2D.text(hintText, theme.textSize, theme.disabledText, Left, theme.font);
		caret = Node2D.rectangle(2, theme.textSize + 4, theme.focus);
		caret.setPivot(0, 0);
		caret.setPickable(false);
		for (n in [face, hint, text, caret])
			root.add(n);
		box = Box.stack(face).setSize(Grow(1), Fixed(theme.height)).setPadding(theme.padding, 0, theme.padding, 0);
		box.add(Box.of(text).setAnchor(Start, Center)).add(Box.of(hint).setAnchor(Start, Center));
	}

	/** Its text. */
	public function getText():String
		return text.getText();

	/** Shows value (cut to its longest; not counted as a change). */
	public function setText(value:String):Void
		text.setText(value.substr(0, maxLength));

	/** Whether its text changed this frame. */
	public function isChanged():Bool
		return changed;

	/** Whether Enter was pressed in it this frame. */
	public function isSubmitted():Bool
		return submitted;

	override public function isFocusable():Bool
		return true;

	override function takesSideways():Bool
		return true;

	override function takesText():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		var theme = ui.getTheme(), input = ui.getInput(), value = text.getText(), was = value;
		submitted = false;
		if (enabled && focused) {
			for (i in 0...input.getText().length) {
				var c = input.getText().charAt(i);
				if (value.length < maxLength && c.charCodeAt(0) >= 32)
					value += c;
			}
			if (input.isFramePressed(Key.Backspace) && value.length > 0)
				value = value.substr(0, value.length - 1);
			submitted = input.isFramePressed(Key.Enter);
		}
		text.setText(value);
		changed = value != was;
		hint.setVisible(value.length == 0);
		face.setColor(focused ? theme.hovered : hovered ? theme.hovered : theme.face);
		text.setColor(enabled ? theme.text : theme.disabledText);
		// The caret after the text, as the layout last placed it.
		var font = theme.font != null ? theme.font : ui.getFont();
		caret.setVisible(enabled && focused);
		caret.setPosition(box.getX()
			+ theme.padding
			+ (font != null ? Text2D.measure(font, value, theme.textSize) : 0)
			+ 1,
			box.getY()
			+ (box.getHeight() - theme.textSize - 4) / 2);
	}
}
