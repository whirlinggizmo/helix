package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Shape2D;
import helix.render2d.Text2D;

/** A value from min to max in steps (0: any), beside a line of text: dragged along its track by the pointer, or stepped by Left and Right
	with focus (a tenth of the way without steps). Ask value, and changed once a frame. */
class Slider extends Widget {
	var face:Shape2D;
	var track:Shape2D;
	var fill:Shape2D;
	var knob:Shape2D;
	var label:Text2D;
	var trackBox:Box;
	var min:Float;
	var max:Float;
	var step:Float;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, text:String, min:Float, max:Float, value:Float, step:Float) {
		super(ui, name);
		this.min = min;
		this.max = max > min ? max : min;
		this.step = step;
		this.value = snap(value);
		var theme = ui.theme;
		face = Shape2D.rectangle(1, 1, 0);
		face.setPivot(0, 0);
		label = new Text2D(text, theme.textSize, theme.textColor, Left, theme.font);
		track = Shape2D.rectangle(1, 6, theme.faceColor);
		track.setPivot(0, 0);
		track.cornerRadius = theme.cornerRadius;
		track.pickable = false;
		fill = Shape2D.rectangle(1, 6, theme.accentColor);
		fill.setPivot(0, 0);
		fill.cornerRadius = theme.cornerRadius;
		fill.pickable = false;
		knob = Shape2D.rectangle(10, theme.textSize + 4, theme.accentColor);
		knob.setPivot(.5, .5);
		knob.cornerRadius = theme.cornerRadius;
		knob.pickable = false;
		for (n in [face, track, fill, knob, label])
			root.addChild(n);
		trackBox = Box.of(track);
		trackBox.setSizing(Grow(1), Fixed(6));
		var row = Box.row();
		row.gap = theme.gap * 2;
		row.setAlign(Start, Center);
		row.setAnchor(Stretch, Center);
		row.add(Box.of(label));
		row.add(trackBox);
		box = Box.stack(face);
		box.setSizing(Grow(1), Fixed(theme.widgetHeight));
		box.add(row);
	}

	/** Its value. */
	public var value(default, set):Float;

	function set_value(v:Float):Float {
		value = snap(v);
		return v;
	}

	/** Whether its value changed this frame. */
	public var changed(default, null):Bool = false;

	function snap(v:Float):Float {
		v = Math.max(min, Math.min(max, v));
		return step > 0 ? Math.max(min, Math.min(max, min + Math.round((v - min) / step) * step)) : v;
	}

	override function get_focusable():Bool
		return true;

	override function takesSideways():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, stepX:Int, stepY:Int):Void {
		var theme = ui.theme, was = value;
		if (enabled && held) {
			// The pointer's place along the track, in the track's own units.
			var camera = ui.camera, input = ui.input;
			var wx = camera.screenToWorldX(input.pointerX),
				wy = camera.screenToWorldY(input.pointerY);
			var along = trackBox.width > 0 ? track.toLocalX(wx, wy) / trackBox.width : 0;
			value = snap(min + Math.max(0, Math.min(1, along)) * (max - min));
		}
		if (enabled && stepX != 0)
			value = snap(value + stepX * (step > 0 ? step : (max - min) / 10));
		changed = value != was;
		// The fill and knob where the value is along the track, as the layout last placed it.
		var fraction = max > min ? (value - min) / (max - min) : 0;
		fill.setSize(Math.max(0, trackBox.width * fraction), 6);
		fill.setPosition(trackBox.x, trackBox.y);
		knob.setPosition(trackBox.x + trackBox.width * fraction, trackBox.y + 3);
		knob.color = held ? theme.pressedColor : hovered ? theme.hoveredColor : theme.accentColor;
		label.color = enabled ? theme.textColor : theme.disabledTextColor;
	}
}
