package helix.platform;

/** Specifies what a pipeline's uniform block 0 holds, so that an adapter can draw a render target the right way up.

	An adapter whose render targets are stored bottom row first (GL's) flips its draws into a target. With ClipScale it writes block 0 as
	(1, -1) in such a pass and (1, 1) otherwise; with ViewProjection it negates the y row of the column-major matrix in block 0's first 64
	bytes in such a pass. An adapter whose targets are stored top row first ignores it. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract ClipFlip(Int) to Int {
	/** Block 0 is not touched, or there is none. */
	var None = 0;

	/** Block 0 is a vec4 clip scale that the adapter writes. */
	var ClipScale = 1;

	/** Block 0 starts with a view-projection matrix whose y row the adapter negates. */
	var ViewProjection = 2;
}
