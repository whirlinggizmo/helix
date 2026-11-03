package helix.services.input;

/** Specifies which side of a stick's axis a binding reads (`Binding.Axis`). A trigger reads as `Positive`. */
enum AxisDirection {
	/** Left on an X axis, up on a Y axis. */
	Negative;

	/** Right on an X axis, down on a Y axis, or a trigger pulled. */
	Positive;
}
