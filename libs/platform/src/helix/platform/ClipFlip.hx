package helix.platform;

/** Specifies what a pipeline's flip uniform holds, so that an adapter can draw a render target the right way up.

	The uniform is the one at `PipelineDesc.flipBlockSlot` and `flipOffset`, in the vertex stage's block of that slot. An adapter whose
	render targets are stored bottom row first, as GL's are, flips its draws into a target. With ClipScale every adapter writes the vec4
	there, all four components: (1, -1, 1, 1) in a pass into a target on an adapter storing targets bottom row first, and (1, 1, 1, 1)
	otherwise, so a shader multiplying `gl_Position` by it is right everywhere. With ViewProjection an adapter storing targets bottom
	row first negates the y row of the column-major matrix there in a pass into a target. An adapter flips its own copy of the bytes,
	never the caller's, and reverses the winding with it. A shadow pass is never flipped. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract ClipFlip(Int) to Int {
	/** Nothing is touched. */
	var None = 0;

	/** The uniform is a vec4 clip scale that the adapter writes. */
	var ClipScale = 1;

	/** The uniform is a view-projection matrix whose y row the adapter negates. */
	var ViewProjection = 2;
}
