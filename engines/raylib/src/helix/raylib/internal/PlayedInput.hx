package helix.raylib.internal;

/** Holds the input automation plays into, as the input functions read it once automation is used (`Automation`). The input functions read
	it through this, so a program that never uses automation doesn't carry it. */
@:noCompletion
interface PlayedInput {
	/** Each key down, by its number on the platform (`KEY_*`, a right-hand modifier as the left-hand one). */
	final keys:Array<Bool>;

	/** Each key down as the last frame had it. */
	final previousKeys:Array<Bool>;

	/** Each mouse button down (`MOUSE_BUTTON_*`), a finger as the left one. */
	final buttons:Array<Bool>;

	/** Each mouse button down as the last frame had it. */
	final previousButtons:Array<Bool>;

	/** The mouse's x, in the screen's pixels before `SetMouseOffset` and `SetMouseScale`. */
	var mouseX:Float;

	/** The mouse's y, in the screen's pixels before `SetMouseOffset` and `SetMouseScale`. */
	var mouseY:Float;

	/** The mouse's x as the last frame had it. */
	var previousMouseX:Float;

	/** The mouse's y as the last frame had it. */
	var previousMouseY:Float;

	/** How far the wheel turned across this frame. */
	var wheelX:Float;

	/** How far the wheel turned down this frame. */
	var wheelY:Float;

	/** Each finger down by its place, 0 for the first down. */
	final touches:Array<Bool>;

	/** Where each finger is across, in the screen's pixels. */
	final touchX:Array<Float>;

	/** Where each finger is down, in the screen's pixels. */
	final touchY:Array<Float>;

	/** Each gamepad connected. */
	final gamepads:Array<Bool>;

	/** Each gamepad's buttons down (`GAMEPAD_BUTTON_*`, gamepad times 32 plus the button). */
	final gamepadButtons:Array<Bool>;

	/** Each gamepad's buttons down as the last frame had it. */
	final previousGamepadButtons:Array<Bool>;

	/** Each gamepad's axes (gamepad times 8 plus the axis). */
	final gamepadAxes:Array<Float>;

	/** The gesture detected now (`GESTURE_*`). */
	var gesture:Int;
}
