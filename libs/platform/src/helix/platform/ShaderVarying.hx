package helix.platform;

/** Represents a value one stage of a program passes to the next: an output of the vertex stage, or an input of the fragment stage.

	It is read from the compiled program, so it is what the stage declares, built-ins (`gl_Position`, `gl_FragCoord`) left out. */
typedef ShaderVarying = {
	/** Its GLSL name. */
	final glslName:String;

	/** Its GLSL type: `float`, `vec2`, `vec3`, `vec4`, `int`, `ivecN`, `uint`, `uvecN` or `matN`. */
	final type:String;

	/** The location it is passed at. A matrix takes a location a column, from its own. */
	final location:Int;
}
