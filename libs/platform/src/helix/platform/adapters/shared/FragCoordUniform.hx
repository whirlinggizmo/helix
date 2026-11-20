package helix.platform.adapters.shared;

import helix.platform.ShaderSource;

/** Finds the uniform the shader compiler adds to a program whose fragment stage reads `gl_FragCoord` or `dFdy`, the same for every
	graphics adapter. */
@:noCompletion
class FragCoordUniform {
	/** The uniform's name, a `vec2`: what `gl_FragCoord.y` is multiplied by, then what is added. */
	public static inline final NAME = "helix_fragCoordY";

	/** Returns the index, in a draw's uniforms, of the block holding the uniform, or -1 for a program without the uniform.
		@param source  The program. */
	public static function index(source:ShaderSource):Int {
		for (b in source.uniformBlocks)
			for (m in b.members)
				if (m.glslName == NAME)
					return b.stage == "fragment" ? 4 + b.slot : b.slot;
		return -1;
	}

	/** Returns the uniform's byte offset in its block, or -1 for a program without the uniform.
		@param source  The program. */
	public static function offset(source:ShaderSource):Int {
		for (b in source.uniformBlocks)
			for (m in b.members)
				if (m.glslName == NAME)
					return m.offset;
		return -1;
	}
}
