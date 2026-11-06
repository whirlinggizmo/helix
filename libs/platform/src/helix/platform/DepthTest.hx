package helix.platform;

/** Specifies which fragments a pipeline's depth test passes, compared with the depth already in the target. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract DepthTest(Int) to Int {
	/** The depth buffer is off for the draws: no test, so every fragment is drawn, and no depth written whatever `PipelineDesc.depthWrite`
		says. */
	var Off = 0;

	/** Fragments as near as or nearer than the depth there pass. This is the usual test. */
	var LessEqual = 1;

	/** Fragments farther than the depth there pass, so only what is hidden behind something drawn before is drawn. */
	var Greater = 2;

	/** Every fragment passes, and its depth is written as `PipelineDesc.depthWrite` says: the depth buffer is on, unlike `Off`, so a draw
		can lay down depth without testing it. */
	var Always = 3;

	/** Fragments nearer than the depth there pass; one exactly as near doesn't, so a second draw of the same surface leaves the first. */
	var Less = 4;
}
