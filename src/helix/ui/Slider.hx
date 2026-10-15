package helix.ui;

import helix.render2d.Node2D;

/** A value from min to max in steps (0: any), beside a line of text: dragged along its track by the pointer, or stepped by Left and Right
	with focus (a tenth of the way without steps). Ask getValue, and isChanged once a frame. */
class Slider extends Widget {
	var face:Node2D;
	var track:Node2D;
	var fill:Node2D;
	var knob:Node2D;
	var label:Node2D;
	var trackBox:Box;
	var min:Float;
	var max:Float;
	var step:Float;
	var value:Float;
	var changed = false;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, text:String, min:Float, max:Float, value:Float, step:Float) {
		super(ui, name);
		this.min = min;
		this.max = max > min ? max : min;
		this.step = step;
		this.value = snap(value);
		var theme = ui.getTheme();
		face = Node2D.rectangle(1, 1, 0);
		face.setPivot(0, 0);
		label = Node2D.text(text, theme.getTextSize(), theme.getTextColor(), Left, theme.getFont());
		track = Node2D.rectangle(1, 6, theme.getFaceColor());
		track.setPivot(0, 0);
		track.setCornerRadius(theme.getCornerRadius());
		track.setPickable(false);
		fill = Node2D.rectangle(1, 6, theme.getAccentColor());
		fill.setPivot(0, 0);
		fill.setCornerRadius(theme.getCornerRadius());
		fill.setPickable(false);
		knob = Node2D.rectangle(10, theme.getTextSize() + 4, theme.getAccentColor());
		knob.setPivot(.5, .5);
		knob.setCornerRadius(theme.getCornerRadius());
		knob.setPickable(false);
		for (n in [face, track, fill, knob, label])
			root.add(n);
		trackBox = Box.of(track);
		trackBox.setSizing(Grow(1), Fixed(6));
		var row = Box.row();
		row.setGap(theme.getGap() * 2);
		row.setAlign(Start, Center);
		row.setAnchor(Stretch, Center);
		row.add(Box.of(label));
		row.add(trackBox);
		box = Box.stack(face);
		box.setSizing(Grow(1), Fixed(theme.getWidgetHeight()));
		box.add(row);
	}

	/** Its value. */
	public function getValue():Float
		return value;

	/** Sets its value (held to min .. max and its steps; not counted as a change). */
	public function setValue(v:Float):Void
		value = snap(v);

	/** Whether its value changed this frame. */
	public function isChanged():Bool
		return changed;

	function snap(v:Float):Float {
		v = Math.max(min, Math.min(max, v));
		return step > 0 ? Math.max(min, Math.min(max, min + Math.round((v - min) / step) * step)) : v;
	}

	override public function isFocusable():Bool
		return true;

	override function takesSideways():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		var theme = ui.getTheme(), was = value;
		if (enabled && held) {
			// The pointer's place along the track, in the track's own units.
			var camera = ui.getCamera(), input = ui.getInput();
			var wx = camera.screenToWorldX(input.getPointerX()),
				wy = camera.screenToWorldY(input.getPointerY());
			var along = trackBox.getWidth() > 0 ? track.toLocalX(wx, wy) / trackBox.getWidth() : 0;
			value = snap(min + Math.max(0, Math.min(1, along)) * (max - min));
		}
		if (enabled && step != 0)
			value = snap(value + step * (this.step > 0 ? this.step : (max - min) / 10));
		changed = value != was;
		// The fill and knob where the value is along the track, as the layout last placed it.
		var fraction = max > min ? (value - min) / (max - min) : 0;
		fill.setSize(Math.max(0, trackBox.getWidth() * fraction), 6);
		fill.setPosition(trackBox.getX(), trackBox.getY());
		knob.setPosition(trackBox.getX() + trackBox.getWidth() * fraction, trackBox.getY() + 3);
		knob.setColor(held ? theme.getPressedColor() : hovered ? theme.getHoveredColor() : theme.getAccentColor());
		label.setColor(enabled ? theme.getTextColor() : theme.getDisabledTextColor());
	}
}
