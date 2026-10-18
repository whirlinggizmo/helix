package helix.input;

/** Told by an IInput (watch) as a tick's edges and a frame's end, before they are cleared: what keeps a state of its own from tick to tick
	and frame to frame over the input, as an action map (Actions) keeps whether each action was down. */
interface IInputWatcher {
	/** A simulation tick ended: the input's consume() is taking one of each tick edge, after this. */
	public function tickEnded():Void;

	/** The frame ended: its frame edges, text, wheel and lifted touches end after this. */
	public function frameEnded():Void;
}
