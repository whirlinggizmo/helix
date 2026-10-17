package helix.ui;

import helix.input.Key;
import helix.render2d.Node2D;
import helix.render2d.Text2D;

/** A line of text typed in: with focus, the characters typed (after the keyboard layout) are added, Backspace takes the last off and Enter
	submits; the caret is at its end. While it has focus the UI has the keys (Ui.capturingKeys) and asks for typed text (IInput.setTextEntry,
	so a platform's keyboard shows for it), however it got focus, so a game doesn't act on
	letters typed. Ask text, changed and submitted once a frame. No input method (IME) composition yet. */
class TextField extends Widget {
	var face:Node2D;
	var textNode:Node2D;
	var caret:Node2D;
	var hint:Node2D;
	var maxLength:Int;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, value:String, hintText:String, maxLength:Int) {
		super(ui, name);
		this.maxLength = maxLength;
		var theme = ui.theme;
		face = Node2D.rectangle(1, 1, theme.faceColor);
		face.setPivot(0, 0);
		face.setCornerRadius(theme.cornerRadius);
		textNode = Node2D.text(value.substr(0, maxLength), theme.textSize, theme.textColor, Left, theme.font);
		hint = Node2D.text(hintText, theme.textSize, theme.disabledTextColor, Left, theme.font);
		caret = Node2D.rectangle(2, theme.textSize + 4, theme.focusColor);
		caret.setPivot(0, 0);
		caret.pickable = false;
		for (n in [face, hint, textNode, caret])
			root.addChild(n);
		box = Box.stack(face);
		box.setSizing(Grow(1), Fixed(theme.widgetHeight));
		box.setPadding(theme.padding, 0, theme.padding, 0);
		var typed = Box.of(textNode), hinted = Box.of(hint);
		typed.setAnchor(Start, Center);
		hinted.setAnchor(Start, Center);
		box.add(typed);
		box.add(hinted);
	}

	/** Its text. */
	public var text(get, set):String;

	function get_text():String
		return textNode.getText();

	function set_text(value:String):String {
		textNode.setText(value.substr(0, maxLength));
		return value;
	}

	/** Whether its text changed this frame. */
	public var changed(default, null):Bool = false;

	/** Whether Enter was pressed in it this frame. */
	public var submitted(default, null):Bool = false;

	override function get_focusable():Bool
		return true;

	override function takesSideways():Bool
		return true;

	override function takesText():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		var theme = ui.theme, input = ui.input, value = textNode.getText(), was = value;
		submitted = false;
		if (enabled && focused) {
			for (i in 0...input.text.length) {
				var c = input.text.charAt(i);
				if (value.length < maxLength && c.charCodeAt(0) >= 32)
					value += c;
			}
			if (input.isFramePressed(Key.Backspace) && value.length > 0)
				value = value.substr(0, value.length - 1);
			submitted = input.isFramePressed(Key.Enter);
		}
		textNode.setText(value);
		changed = value != was;
		hint.visible = value.length == 0;
		face.color = focused ? theme.hoveredColor : hovered ? theme.hoveredColor : theme.faceColor;
		textNode.color = enabled ? theme.textColor : theme.disabledTextColor;
		// The caret after the text, as the layout last placed it.
		var font = theme.font != null ? theme.font : ui.font;
		caret.visible = enabled && focused;
		caret.setPosition(box.x
			+ theme.padding
			+ (font != null ? Text2D.measure(font, value, theme.textSize) : 0)
			+ 1,
			box.y
			+ (box.height - theme.textSize - 4) / 2);
	}
}
