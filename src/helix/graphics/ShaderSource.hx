package helix.graphics;

/** One program's source for one backend dialect: its vertex and fragment stages. */
typedef ShaderStages = {
	var vertex:String;
	var fragment:String;
}

/** A uniform block a program declares: its binding slot, its stage ("vertex" or "fragment"), its size in bytes, and its name in the GLSL,
	which flattens it to an array of vec4s. */
typedef ShaderBlock = {
	var slot:Int;
	var stage:String;
	var size:Int;
	var glslName:String;
	var vec4s:Int;
}

/** A texture a program samples: its binding slot (its sampler's too), its stage, the GLSL name of the pair, and its kind: a shadow map (a
	depth array read through a comparison sampler), a cubemap, a data texture (RGBA32F read texel by texel, never filtered), or a plain 2D
	texture when none of them. */
typedef ShaderTexture = {
	var slot:Int;
	var stage:String;
	var glslName:String;
	var shadow:Bool;
	var cube:Bool;
	var data:Bool;
}

/** A compiled program: in every dialect HeliX's adapters use (GLSL 410 natively, GLSL ES 300 in the browser), its vertex attributes' names by
	slot, and the uniform blocks and textures it binds. The framework's are generated (each layout's source()), an app's is a .hxshader
	(tools/pack_shader.py); IGraphics.createShader builds either the same way. */
typedef ShaderSource = {
	var attributes:Array<String>;
	var glsl410:ShaderStages;
	var glsl300es:ShaderStages;
	var uniformBlocks:Array<ShaderBlock>;
	var textures:Array<ShaderTexture>;
}
