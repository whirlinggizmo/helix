import helix.host.Host;
import helix.host.Screen;
import helix.host.Window;
import helix.input.Gamepad;
import helix.input.Input;
import helix.input.Key;
import helix.input.PadAxis;
import helix.input.PadButton;
import helix.render2d.Drawing2D;
import helix.render2d.Stage;
import helix.host.ScreenShape;

/** Every connected gamepad, live: up to four side by side, each with its name, both sticks (the dot is where the stick points, past the dead
	zone; the ring is its reach), the triggers as bars, and the buttons laid out as on an Xbox-style pad, lit while held and flashed the frame
	they're pressed. South on a pad cycles the dead zone; Escape quits where quitting means anything. In a browser, press a button on the pad
	first: a page sees gamepads only after that. */
class App extends helix.App {
	static inline var WIDTH = 1000;
	static inline var HEIGHT = 420;
	static final DEADZONES = [.1, .2, .3, 0.];

	// Everything shown, drawn again each update.
	var drawing = new Drawing2D();
	var deadzone = 0;

	override public function init():Void {
		Window.title = "HeliX gamepad";
		Window.requestSize(WIDTH, HEIGHT);
		Stage.color = 0xff181c26;
		Stage.addChild(drawing);
	}

	override public function update(dt:Float):Void {
		if (Host.canQuit() && Input.isFramePressed(Key.Escape))
			Host.quit();
		for (i in 0...Input.padCount)
			if (Input.getPad(i).isFramePressed(PadButton.South))
				deadzone = (deadzone + 1) % DEADZONES.length;
		// The design for the window's shape: the text wrapped to what's visible of it, and as many panels across as fit, the rest in rows below.
		ScreenShape.update();
		var vx = Screen.visibleX,
			vy = Screen.visibleY,
			vw = Screen.visibleWidth;
		drawing.clear();
		var connected = 0;
		for (i in 0...Input.padCount)
			if (Input.getPad(i).connected)
				connected++;
		var y = vy + 12;
		y += drawing.drawTextWrapped('HeliX gamepad   $connected connected   dead zone ${DEADZONES[deadzone]} (South cycles it)', vx + 12, y, 16, vw - 24,
			0xfff5f5f5)
			+ 12;
		if (connected == 0)
			drawing.drawTextWrapped("No gamepad: connect one, then press a button on it.", vx + 12, y, 16, vw - 24, 0xffc8c8c8);
		var columns = Std.int(Math.max(1, Math.floor((vw - 12) / 245))), placed = 0;
		for (i in 0...Input.padCount) {
			var pad = Input.getPad(i);
			if (!pad.connected)
				continue;
			pad.deadzone = DEADZONES[deadzone];
			drawPad(pad, i, vx + 12 + placed % columns * 245, y + Std.int(placed / columns) * 370);
			placed++;
		}
	}

	/** One pad's panel, its top-left at x, y. */
	function drawPad(pad:Gamepad, index:Int, x:Float, y:Float):Void {
		drawing.roundedRect(x, y, 235, 360, 8, 0xff232a38);
		var name = pad.name;
		drawing.drawText('pad $index: ' + (name.length > 26 ? name.substr(0, 25) + "~" : name), x + 10, y + 10, 13, 0xffc8c8c8);
		// Triggers as bars, filling upward.
		trigger(pad.getAxis(PadAxis.LeftTrigger), x + 14, y + 40);
		trigger(pad.getAxis(PadAxis.RightTrigger), x + 207, y + 40);
		// Bumpers above the face, the sticks, the d-pad and the face buttons, as on an Xbox-style pad.
		button(pad, PadButton.LeftBumper, x + 40, y + 44, 50, 14);
		button(pad, PadButton.RightBumper, x + 145, y + 44, 50, 14);
		stick(pad, PadAxis.LeftX, PadAxis.LeftY, PadButton.LeftStick, x + 70, y + 110);
		stick(pad, PadAxis.RightX, PadAxis.RightY, PadButton.RightStick, x + 150, y + 200);
		button(pad, PadButton.Up, x + 62, y + 168, 16, 16);
		button(pad, PadButton.Down, x + 62, y + 200, 16, 16);
		button(pad, PadButton.Left, x + 46, y + 184, 16, 16);
		button(pad, PadButton.Right, x + 78, y + 184, 16, 16);
		face(pad, PadButton.North, x + 170, y + 88);
		face(pad, PadButton.West, x + 150, y + 108);
		face(pad, PadButton.East, x + 190, y + 108);
		face(pad, PadButton.South, x + 170, y + 128);
		button(pad, PadButton.Back, x + 96, y + 110, 16, 10);
		button(pad, PadButton.Start, x + 124, y + 110, 16, 10);
		button(pad, PadButton.Guide, x + 110, y + 86, 16, 16);
		// The raw axes, for checking a mapping.
		var row = y + 260.;
		for (axis in PadAxis.all) {
			drawing.drawText(axisName(axis) + ' ${fixed(pad.getRawAxis(axis))}', x + 10, row, 12, 0xff8a93a6);
			row += 15;
		}
	}

	function trigger(value:Float, x:Float, y:Float):Void {
		drawing.frame(x, y, 14, 60, 1, 0xff8a93a6);
		drawing.rect(x + 1, y + 1 + 58 * (1 - value), 12, 58 * value, 0xff66bfff);
	}

	function stick(pad:Gamepad, axisX:PadAxis, axisY:PadAxis, click:PadButton, x:Float, y:Float):Void {
		drawing.circleLines(x, y, 28, 1, pad.isDown(click) ? 0xffffcb00 : 0xff8a93a6);
		drawing.circle(x + pad.getAxis(axisX) * 24, y + pad.getAxis(axisY) * 24, 6, 0xff66bfff);
	}

	function face(pad:Gamepad, button:PadButton, x:Float, y:Float):Void {
		drawing.circle(x, y, 9, color(pad, button));
		drawing.circleLines(x, y, 9, 1, 0xff8a93a6);
	}

	function button(pad:Gamepad, button:PadButton, x:Float, y:Float, w:Float, h:Float):Void {
		drawing.rect(x, y, w, h, color(pad, button));
		drawing.frame(x, y, w, h, 1, 0xff8a93a6);
	}

	/** White the frame it's pressed, lit while held, dark otherwise. */
	static function color(pad:Gamepad, button:PadButton):Int
		return pad.isFramePressed(button) ? 0xffffffff : pad.isDown(button) ? 0xff66bfff : 0xff181c26;

	static function axisName(axis:PadAxis):String
		return switch (axis) {
			case LeftX: "left x ";
			case LeftY: "left y ";
			case RightX: "right x";
			case RightY: "right y";
			case LeftTrigger: "left trigger ";
			case RightTrigger: "right trigger";
		};

	static function fixed(value:Float):String {
		var s = Std.string(Math.round(value * 100) / 100);
		return value >= 0 ? " " + s : s;
	}
}
