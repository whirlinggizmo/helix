package helix.platform;

/** Represents one program's source in one dialect: its vertex and fragment stages. */
typedef ShaderStages = {
	/** The vertex stage's source. */
	final vertex:String;

	/** The fragment stage's source. */
	final fragment:String;
}
