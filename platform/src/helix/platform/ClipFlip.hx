package helix.platform;

/** Specifies what a pipeline's uniform block 0 holds, so that an adapter can draw a render target the right way up.

	An adapter whose render targets are stored bottom row first, as GL's are, flips its draws into a target. With ClipScale, it writes
	block 0 as (1, -1) in a pass into a target and as (1, 1) otherwise. With ViewProjection, it negates the y row of the column-major
	matrix in block 0's first 64 bytes in a pass into a target. An adapter whose targets are stored top row first ignores this value. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract ClipFlip(Int) to Int {
	/** Block 0 is not touched, or there is none. */
	var None = 0;

	/** Block 0 is a vec4 clip scale that the adapter writes. */
	var ClipScale = 1;

	/** Block 0 starts with a view-projection matrix whose y row the adapter negates. */
	var ViewProjection = 2;
}
