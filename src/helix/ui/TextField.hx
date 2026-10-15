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
		face = Node2D.rectangle(1, 1, theme.getFaceColor());
		face.setPivot(0, 0);
		face.setCornerRadius(theme.getCornerRadius());
		text = Node2D.text(value.substr(0, maxLength), theme.getTextSize(), theme.getTextColor(), Left, theme.getFont());
		hint = Node2D.text(hintText, theme.getTextSize(), theme.getDisabledTextColor(), Left, theme.getFont());
		caret = Node2D.rectangle(2, theme.getTextSize() + 4, theme.getFocusColor());
		caret.setPivot(0, 0);
		caret.setPickable(false);
		for (n in [face, hint, text, caret])
			root.add(n);
		box = Box.stack(face);
		box.setSizing(Grow(1), Fixed(theme.getWidgetHeight()));
		box.setPadding(theme.getPadding(), 0, theme.getPadding(), 0);
		var typed = Box.of(text), hinted = Box.of(hint);
		typed.setAnchor(Start, Center);
		hinted.setAnchor(Start, Center);
		box.add(typed);
		box.add(hinted);
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
		face.setColor(focused ? theme.getHoveredColor() : hovered ? theme.getHoveredColor() : theme.getFaceColor());
		text.setColor(enabled ? theme.getTextColor() : theme.getDisabledTextColor());
		// The caret after the text, as the layout last placed it.
		var font = theme.getFont() != null ? theme.getFont() : ui.getFont();
		caret.setVisible(enabled && focused);
		caret.setPosition(box.getX()
			+ theme.getPadding()
			+ (font != null ? Text2D.measure(font, value, theme.getTextSize()) : 0)
			+ 1,
			box.getY()
			+ (box.getHeight() - theme.getTextSize() - 4) / 2);
	}
}
