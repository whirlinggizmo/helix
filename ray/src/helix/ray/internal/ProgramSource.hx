package helix.ray.internal;

/** Represents a raylib shader as compiled while the program builds (`ShaderMacro`): the platform's program, raylib's attributes by
	slot, each uniform's place in its stage's block, and each texture's slot. */
@:noCompletion
typedef ProgramSource = {
	final source:helix.platform.ShaderSource;
	final attributes:Array<String>;
	final uniforms:Array<{
		name:String,
		block:Int,
		offset:Int,
		type:String,
		count:Int,
		integer:Bool
	}>;
	final textures:Array<{name:String, slot:Int}>;
}
