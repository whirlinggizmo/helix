package helix.platform;

/** Represents a uniform block that a program declares.

	In GLSL the block is flattened to an array of vec4s. */
typedef ShaderBlock = {
	/** The binding slot. */
	final slot:Int;

	/** The stage that reads it: "vertex" or "fragment". */
	final stage:String;

	/** The size, in bytes. */
	final size:Int;

	/** The block's name in the GLSL. */
	final glslName:String;

	/** The number of vec4s the GLSL array holds. */
	final vec4Count:Int;
}
