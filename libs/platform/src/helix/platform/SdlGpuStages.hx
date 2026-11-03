package helix.platform;

/** Represents a program in SDL_GPU's dialects, laid out as SDL_GPU binds them. */
typedef SdlGpuStages = {
	/** SPIR-V for Vulkan, each stage base64-encoded. */
	final spirv:ShaderStages;

	/** MSL for Metal, entry points main0. */
	final msl:ShaderStages;

	/** HLSL for Direct3D 12, shader model 5.1, entry points main. */
	final hlsl:ShaderStages;
}
