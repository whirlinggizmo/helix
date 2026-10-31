package helix.services.input;

/** Specifies a gesture `Gestures` detects, as a flag: flags are or'd together to say which gestures are detected (`Gestures.enabled`). */
enum abstract Gesture(Int) from Int to Int {
	/** No gesture. */
	var None = 0;

	/** A finger, or a mouse button, went down. It lasts a frame, then is a hold. */
	var Tap = 1;

	/** A second tap soon after the first and near it. It lasts a frame, then is a hold. */
	var DoubleTap = 2;

	/** A finger or button kept down. */
	var Hold = 4;

	/** A finger or button held a moment and then moved. */
	var Drag = 8;

	/** A quick move to the right as the finger lifted. It lasts a frame. */
	var SwipeRight = 16;

	/** A quick move to the left as the finger lifted. It lasts a frame. */
	var SwipeLeft = 32;

	/** A quick move up as the finger lifted. It lasts a frame. */
	var SwipeUp = 64;

	/** A quick move down as the finger lifted. It lasts a frame. */
	var SwipeDown = 128;

	/** Two fingers moving together. */
	var PinchIn = 256;

	/** Two fingers moving apart. */
	var PinchOut = 512;

	/** Every gesture. */
	var All = 1023;
}
