import helix.app.BaseApp;
import helix.host.IHost;
import helix.input.Gamepad;
import helix.input.Key;
import helix.input.PadAxis;
import helix.input.PadButton;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Text2D;

/** Every connected gamepad, live: up to four side by side, each with its name, both sticks (the dot is where the stick points, past the dead
	zone; the ring is its reach), the triggers as bars, and the buttons laid out as on an Xbox-style pad, lit while held and flashed the frame
	they're pressed. South on a pad cycles the dead zone; Escape quits where quitting means anything. In a browser, press a button on the pad
	first: a page sees gamepads only after that. */
class App extends BaseApp {
	static inline var WIDTH = 1000;
	static inline var HEIGHT = 420;
	static final DEADZONES = [.1, .2, .3, 0.];

	var host:IHost;
	var batch:Batch2D;
	var camera = new Camera2D();
	var deadzone = 0;

	public function new(host:IHost) {
		super();
		this.host = host;
	}

	override public function init():Void {
		host.window.setTitle("HeliX gamepad");
		host.window.setSize(WIDTH, HEIGHT);
		batch = new Batch2D(host.graphics);
	}

	override public function frame(dt:Float):Void {
		var input = host.input;
		if (host.canQuit() && input.isFramePressed(Key.Escape))
			host.quit();
		for (i in 0...input.getPadCount())
			if (input.getPad(i).isFramePressed(PadButton.South))
				deadzone = (deadzone + 1) % DEADZONES.length;
		camera.setViewport(host.getFramebufferWidth(), host.getFramebufferHeight());
		camera.pixels(host.getPixelRatio());
		batch.begin(camera, 0x181c26ff);
		var connected = 0;
		for (i in 0...input.getPadCount())
			if (input.getPad(i).isConnected())
				connected++;
		Text2D.draw(batch, 'HeliX gamepad   $connected connected   dead zone ${DEADZONES[deadzone]} (South cycles it)', 12, 12, 16, 0xf5f5f5ff);
		if (connected == 0)
			Text2D.draw(batch, "No gamepad: connect one, then press a button on it.", 12, 44, 16, 0xc8c8c8ff);
		var column = 0;
		for (i in 0...input.getPadCount()) {
			var pad = input.getPad(i);
			if (!pad.isConnected())
				continue;
			pad.setDeadzone(DEADZONES[deadzone]);
			drawPad(pad, i, 12 + column * 245, 44);
			column++;
		}
		batch.end();
	}

	/** One pad's panel, its top-left at x, y. */
	function drawPad(pad:Gamepad, index:Int, x:Float, y:Float):Void {
		batch.roundedRect(x, y, 235, 360, 8, 0x232a38ff);
		var name = pad.getName();
		Text2D.draw(batch, 'pad $index: ' + (name.length > 26 ? name.substr(0, 25) + "~" : name), x + 10, y + 10, 13, 0xc8c8c8ff);
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
			Text2D.draw(batch, axisName(axis) + ' ${fixed(pad.getRawAxis(axis))}', x + 10, row, 12, 0x8a93a6ff);
			row += 15;
		}
	}

	function trigger(value:Float, x:Float, y:Float):Void {
		batch.frame(x, y, 14, 60, 1, 0x8a93a6ff);
		batch.rect(x + 1, y + 1 + 58 * (1 - value), 12, 58 * value, 0x66bfffff);
	}

	function stick(pad:Gamepad, axisX:PadAxis, axisY:PadAxis, click:PadButton, x:Float, y:Float):Void {
		batch.circleLines(x, y, 28, 1, pad.isDown(click) ? 0xffcb00ff : 0x8a93a6ff);
		batch.circle(x + pad.getAxis(axisX) * 24, y + pad.getAxis(axisY) * 24, 6, 0x66bfffff);
	}

	function face(pad:Gamepad, button:PadButton, x:Float, y:Float):Void {
		batch.circle(x, y, 9, color(pad, button));
		batch.circleLines(x, y, 9, 1, 0x8a93a6ff);
	}

	function button(pad:Gamepad, button:PadButton, x:Float, y:Float, w:Float, h:Float):Void {
		batch.rect(x, y, w, h, color(pad, button));
		batch.frame(x, y, w, h, 1, 0x8a93a6ff);
	}

	/** White the frame it's pressed, lit while held, dark otherwise. */
	static function color(pad:Gamepad, button:PadButton):Int
		return pad.isFramePressed(button) ? 0xffffffff : pad.isDown(button) ? 0x66bfffff : 0x181c26ff;

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
