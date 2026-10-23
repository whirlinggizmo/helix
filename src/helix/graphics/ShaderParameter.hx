package helix.graphics;

/** One of a shader's own parameters: its uniform block's slot, its byte offset there, its type (float, vec2, vec3, vec4, mat4) and how many
	(1 unless an array). */
typedef ShaderParameter = {
	final slot:Int;
	final offset:Int;
	final type:String;
	final elementCount:Int;
}
