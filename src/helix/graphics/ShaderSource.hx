package helix.graphics;

/** One program's source for one backend dialect: its vertex and fragment stages. */
typedef ShaderStages = {
	final vertex:String;
	final fragment:String;
}

/** A uniform block a program declares: its binding slot, its stage ("vertex" or "fragment"), its size in bytes, and its name in the GLSL,
	which flattens it to an array of vec4s. */
typedef ShaderBlock = {
	final slot:Int;
	final stage:String;
	final size:Int;
	final glslName:String;
	final vec4Count:Int;
}

/** A texture a program samples: its binding slot (its sampler's too), its stage, the GLSL name of the pair, and its kind: a shadow map (a
	depth array read through a comparison sampler), a cubemap, a data texture (RGBA32F read texel by texel, never filtered), or a plain 2D
	texture when none of them. */
typedef ShaderTexture = {
	final slot:Int;
	final stage:String;
	final glslName:String;
	final shadow:Bool;
	final cube:Bool;
	final data:Bool;
}

/** A program in SDL_GPU's dialects (src/helix/tools/shader/GpuShaders.hx), laid out as SDL_GPU binds: SPIR-V for Vulkan (each stage base64), MSL for Metal
	(entry points main0) and HLSL for Direct3D 12 (shader model 5.1, entry points main). */
typedef SdlGpuStages = {
	final spirv:ShaderStages;
	final msl:ShaderStages;
	final hlsl:ShaderStages;
}

/** A compiled program: in every dialect HeliX's adapters use (GLSL 410 natively, GLSL ES 300 in the browser, and SDL_GPU's), its vertex
	attributes' names by slot, and the uniform blocks and textures it binds. The framework's are generated (each program class's source(); SDL_GPU's
	dialects only in SDL_GPU builds, which define helix_sdl3_gpu), an app's is a .hxshader (src/helix/tools/shader/ShaderPacker.hx, SDL_GPU's dialects only
	when packed for those builds);
	IGraphics.createShader builds either the same way. */
typedef ShaderSource = {
	final attributes:Array<String>;
	final glsl410:ShaderStages;
	final glsl300es:ShaderStages;
	@:optional final sdlGpu:SdlGpuStages;
	final uniformBlocks:Array<ShaderBlock>;
	final textures:Array<ShaderTexture>;
}
