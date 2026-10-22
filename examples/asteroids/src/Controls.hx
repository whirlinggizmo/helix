import helix.input.Input;
import helix.input.Key;
import helix.input.PadButton;
import helix.input.PadAxis;

class Controls {
	public var start = false;
	public var title = false;
	public var quit = false;
	public var left = false;
	public var right = false;
	public var thrust = false;
	public var fire = false;

	public function new() {}

	public function read():Void {
		start = Input.isPressed(Key.Enter) || Input.isPadPressed(PadButton.South) || Input.isPadPressed(PadButton.Start);
		title = false;
		quit = Input.isPressed(Key.Escape);
		left = Input.isDown(Key.Left) || Input.isPressed(Key.Left) || Input.isDown(Key.A) || Input.isPadDown(PadButton.Left)
			|| Input.getPadAxis(PadAxis.LeftX) < -.4;
		right = Input.isDown(Key.Right) || Input.isPressed(Key.Right) || Input.isDown(Key.D) || Input.isPadDown(PadButton.Right)
			|| Input.getPadAxis(PadAxis.LeftX) > .4;
		thrust = Input.isDown(Key.Up)
			|| Input.isPressed(Key.Up)
			|| Input.isDown(Key.W)
			|| Input.isPadDown(PadButton.South)
			|| Input.getPadAxis(PadAxis.RightTrigger) > .3;
		fire = Input.isDown(Key.Space) || Input.isPressed(Key.Space) || Input.isPadDown(PadButton.East) || Input.isPadDown(PadButton.RightBumper);
	}

	public function replay(tick:Int):Void {
		start = tick == 0 || tick == 900;
		title = false;
		quit = false;
		fire = true;
		thrust = tick % 240 < 120;
		left = tick % 360 < 110;
		right = tick % 360 >= 240;
	}
}
