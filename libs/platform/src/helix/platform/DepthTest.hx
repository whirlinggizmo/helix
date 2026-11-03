package helix.platform;

/** Specifies which fragments a pipeline's depth test passes, compared with the depth already in the target. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract DepthTest(Int) to Int {
	/** There is no test, so every fragment is drawn. */
	var Off = 0;

	/** Fragments as near as or nearer than the depth there pass. This is the usual test. */
	var LessEqual = 1;

	/** Fragments farther than the depth there pass, so only what is hidden behind something drawn before is drawn. */
	var Greater = 2;
}
