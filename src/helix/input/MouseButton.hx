package helix.input;

/** The mouse buttons HeliX reads, numbered as Sokol numbers them. */
enum abstract MouseButton(Int) to Int {
	var Left = 0;
	var Right = 1;
	var Middle = 2;

	/** Every button. */
	public static final all:Array<MouseButton> = [Left, Right, Middle];
}
