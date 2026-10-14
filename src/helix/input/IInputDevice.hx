package helix.input;

/** An input adapter as the Runner drives it: the input the app reads (IInput) plus the frame's two steps and shutdown. Focus is the
	adapter's own: while its window doesn't have the input, it lets go of everything. */
interface IInputDevice extends IInput {
	/** Before the app's frame: takes the input that arrived since the last frame. */
	public function poll():Void;

	/** After the app's frame: the frame's edges, text, wheel and lifted touches end. */
	public function endFrame():Void;

	/** Releases the device, after the app's cleanup. */
	public function shutdown():Void;
}
