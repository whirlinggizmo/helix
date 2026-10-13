package helix.input;

/** A gamepad's buttons, as on an Xbox-style pad, numbered as the W3C standard gamepad numbers them (6 and 7 are the triggers, which are axes here). */
enum abstract PadButton(Int) to Int {
	var South = 0;
	var East = 1;
	var West = 2;
	var North = 3;
	var LeftBumper = 4;
	var RightBumper = 5;
	var Back = 8;
	var Start = 9;
	var LeftStick = 10;
	var RightStick = 11;
	var Up = 12;
	var Down = 13;
	var Left = 14;
	var Right = 15;
	var Guide = 16;

	/** One past the largest value, for arrays indexed by button. */
	public static inline var COUNT = 17;

	/** Every button; 6 and 7 aren't buttons here. */
	public static final all:Array<PadButton> = [
		South,
		East,
		West,
		North,
		LeftBumper,
		RightBumper,
		Back,
		Start,
		LeftStick,
		RightStick,
		Up,
		Down,
		Left,
		Right,
		Guide
	];
}
