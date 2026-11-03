package helix.platform;

/** Represents a uniform block that a program declares, and its members.

	A block's bytes are laid out by std140, as `members` places them, on every adapter. Blocks are numbered in each stage, 0 to 3; one both
	stages declare alike is one block, at the same slot in each. `IGraphics.draw` takes a block's bytes at its index in `uniforms`: its
	slot for the vertex stage's, 4 plus its slot for the fragment stage's, and both for a block both read. */
typedef ShaderBlock = {
	/** The binding slot in its stage, or in each stage for a block both read: 0 to 3. */
	final slot:Int;

	/** The stage that reads it: "vertex", "fragment", or "both" for a block both declare alike (the same name, slot and members). */
	final stage:String;

	/** The size, in bytes, rounded up to whole `vec4`s. */
	final size:Int;

	/** The block's name in the GLSL. */
	final glslName:String;

	/** The members, in the order the block declares them, at their std140 offsets. */
	final members:Array<ShaderMember>;
}
