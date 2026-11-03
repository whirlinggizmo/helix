package helix.services.shaders;

/** Represents the value an attribute reads when no buffer feeds it, as raylib's `rlSetVertexAttributeDefault` sets one (a vertex color
	white): the same for every vertex. */
typedef ShaderVertexConstant = {
	/** The attribute's name. Optional; one of `name` and `slot` is given. */
	@:optional final name:String;

	/** The attribute's slot. Optional; one of `name` and `slot` is given. */
	@:optional final slot:Int;

	/** The value's components, up to four; the rest are 0, 0, 1 as GL's default (0, 0, 0, 1) has them. A matrix attribute takes four a
		column, column by column (16 for a `mat4`): past four, each four are the next slot's. */
	final values:Array<Float>;
}
