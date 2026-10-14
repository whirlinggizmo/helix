import helix.input.IInput;
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

	public function read(input:IInput):Void {
		start = input.isPressed(Key.Enter) || input.isPadPressed(PadButton.South) || input.isPadPressed(PadButton.Start);
		title = false;
		quit = input.isPressed(Key.Escape);
		left = input.isDown(Key.Left) || input.isPressed(Key.Left) || input.isDown(Key.A) || input.isPadDown(PadButton.Left)
			|| input.getPadAxis(PadAxis.LeftX) < -.4;
		right = input.isDown(Key.Right) || input.isPressed(Key.Right) || input.isDown(Key.D) || input.isPadDown(PadButton.Right)
			|| input.getPadAxis(PadAxis.LeftX) > .4;
		thrust = input.isDown(Key.Up)
			|| input.isPressed(Key.Up)
			|| input.isDown(Key.W)
			|| input.isPadDown(PadButton.South)
			|| input.getPadAxis(PadAxis.RightTrigger) > .3;
		fire = input.isDown(Key.Space) || input.isPressed(Key.Space) || input.isPadDown(PadButton.East) || input.isPadDown(PadButton.RightBumper);
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
