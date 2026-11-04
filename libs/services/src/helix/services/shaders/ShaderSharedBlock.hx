package helix.services.shaders;

/** Represents a block whose values many shaders share (`ShaderBlockValues`), named in `ShaderOptions.shared`.

	A block the shader declares is named alone (`{name: "Frame"}`). Loose uniforms are gathered into one by naming them
	(`{name: "Lights", uniforms: ["lights", "ambient", "viewPos"]}`), so a shader written with loose uniforms, as raylib's `lighting.fs`
	is, shares them without its GLSL changing: they become one block both stages read, laid out in the order given, each uniform's
	declaration taken from wherever the stages declare it. */
typedef ShaderSharedBlock = {
	/** The block's name: one the shader declares, or the name of the block the `uniforms` are gathered into. */
	var name:String;

	/** Loose uniforms gathered into the block, by name, a struct array whole (`lights`). Optional; when omitted, the shader declares the
		block itself. */
	@:optional var uniforms:Array<String>;

	/** Whether the block is shared only where the shader declares it, and left out where it doesn't. Optional; false when omitted, when a
		block the shader doesn't declare stops the build. A library naming its own blocks for every shader it compiles sets it, so the
		compiled shader decides, not the library reading its text. */
	@:optional var whereDeclared:Bool;
}
