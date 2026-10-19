package helix.ui;

import helix.input.Key;
import helix.render2d.Node2D;
import helix.render2d.Shape2D;
import helix.render2d.Text2D;

/** A line of text typed in: with focus, the characters typed (after the keyboard layout) are added, Backspace takes the last off and Enter
	submits; the caret is at its end. While it has focus the UI has the keys (Ui.capturingKeys) and asks for typed text (IInput.setTextEntry,
	so a platform's keyboard shows for it), however it got focus, so a game doesn't act on
	letters typed. Ask text, changed and submitted once a frame. No input method (IME) composition yet. */
class TextField extends Widget {
	var face:Shape2D;
	var textNode:Text2D;
	var caret:Shape2D;
	var hintNode:Text2D;
	var maxLength:Int;
	var typed:Box;
	var hinted:Box;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, value:String, hintText:String, maxLength:Int) {
		super(ui, name);
		this.maxLength = maxLength;
		var theme = ui.theme;
		face = Shape2D.rectangle(1, 1, theme.faceColor);
		face.setPivot(0, 0);
		textNode = new Text2D(value.substr(0, maxLength), theme.textSize, theme.textColor, Left, theme.font);
		hintNode = new Text2D(hintText, theme.textSize, theme.disabledTextColor, Left, theme.font);
		caret = Shape2D.rectangle(2, theme.textSize + 4, theme.focusColor);
		caret.setPivot(0, 0);
		caret.pickable = false;
		for (n in [face, hintNode, textNode, caret])
			root.addChild(n);
		box = Box.stack(face);
		box.setSizing(Grow(1), Fixed(theme.widgetHeight));
		box.setPadding(theme.padding, 0, theme.padding, 0);
		typed = Box.of(textNode);
		hinted = Box.of(hintNode);
		typed.setAnchor(Start, Center);
		hinted.setAnchor(Start, Center);
		box.add(typed);
		box.add(hinted);
	}

	/** Its text. */
	public var text(get, set):String;

	function get_text():String
		return textNode.text;

	function set_text(value:String):String {
		textNode.text = value.substr(0, maxLength);
		return value;
	}

	/** The text shown, dimmed, while it's empty. */
	public var hint(get, set):String;

	function get_hint():String
		return hintNode.text;

	function set_hint(value:String):String {
		hintNode.text = value;
		return value;
	}

	/** Whether its text and hint are centered in it rather than at its start (false, to start). */
	public var centered(default, set):Bool = false;

	function set_centered(value:Bool):Bool {
		centered = value;
		typed.setAnchor(value ? Center : Start, Center);
		hinted.setAnchor(value ? Center : Start, Center);
		return value;
	}

	/** Whether its text changed this frame. */
	public var changed(default, null):Bool = false;

	/** Whether Enter was pressed in it this frame. */
	public var submitted(default, null):Bool = false;

	/** Whether its text is marked as not accepted (what reads it decides: a color picker's field holding no color): drawn in the theme's
		invalidTextColor. */
	public var invalid:Bool = false;

	override function get_focusable():Bool
		return true;

	override function takesSideways():Bool
		return true;

	override function takesText():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, stepX:Int, stepY:Int):Void {
		var theme = ui.theme, input = ui.input, value = textNode.text, was = value;
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
		textNode.text = value;
		changed = value != was;
		hintNode.visible = value.length == 0;
		face.color = focused ? theme.hoveredColor : hovered ? theme.hoveredColor : theme.faceColor;
		textNode.color = !enabled ? theme.disabledTextColor : invalid ? theme.invalidTextColor : theme.textColor;
		// The caret after the text, as the layout last placed it.
		var font = theme.font != null ? theme.font : ui.font;
		caret.visible = enabled && focused;
		caret.setPosition(typed.x + (font != null ? font.measure(value, theme.textSize) : 0) + 1, box.y + (box.height - theme.textSize - 4) / 2);
	}
}
