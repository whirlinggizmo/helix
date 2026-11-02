package helix.services.shaders;

/** Represents how a set of variants compiles: `ShaderOptions`, and which combinations of features. */
typedef ShaderVariantOptions = {
	> ShaderOptions,

	/** The combinations to compile, each a list of features (`[]` for none on). Optional; omitted, every combination of the features is
		compiled, at most 8 features (256 variants), and a larger set must give its combinations. */
	@:optional var combinations:Array<Array<String>>;
}
