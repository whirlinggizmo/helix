package helix.services.shaders;

/** Represents one of a shader's vertex attributes: the vertex stage's input at a slot, which a pipeline's `VertexAttribute` feeds. */
typedef ShaderAttribute = {
	/** The input's name in the GLSL. */
	final glslName:String;

	/** Its slot, its `layout(location = n)`: what `VertexAttribute.slot` names. A matrix takes a slot a column from it, each column fed
		as an attribute of its own. */
	final slot:Int;

	/** Its type, which says how many floats a record gives it (`Vec3` three). */
	final type:ShaderValueType;

	/** Whether the vertex stage's code reads it, as the compiler finds; one unread is still reflected and fed. */
	final active:Bool;
}
