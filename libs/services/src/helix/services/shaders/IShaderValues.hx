package helix.services.shaders;

import helix.platform.Sampling;

/** Defines what values for a whole program take besides uniforms: textures, and the blocks and textures they share. `ShaderValues` and
	`ShaderVariantValues` implement it.

	Sharing on a values made over a base (`ShaderValues.base`) is its own; what it doesn't share itself it reads from its base, so
	sharing once on a scene's defaults shares on every values made over them, before or after. */
interface IShaderValues {
	/** Gets or sets the scene the values read shared blocks and textures from when neither they nor their base share them, or null
		for their base's. Changing it copies nothing (`ShaderScene`). */
	var scene(get, set):Null<ShaderScene>;

	/** Writes the texture a sampler reads, and how.

		The handle is trusted: it is passed to `IGraphics.draw` as it is, so a layer above that hands out textures checks they are alive.
		A shadow map or a data texture is sampled as its kind requires, whatever the sampling.
		@param sampler  The sampler.
		@param texture  The texture, as an `IGraphics` handle of the sampler's kind, or 0 for none.
		@param sampling  Optional. How it is sampled; defaults to `Sampling.LINEAR`. */
	function writeTexture(sampler:ShaderSampler, texture:Int, ?sampling:Sampling):Void;

	/** Writes a sampler from a value held as data, as a by-name layer's table holds a texture beside its uniforms.

		@param sampler  The sampler.
		@param value  A `ShaderValue.Texture`.
		@throws String  A value of another case. */
	function writeSamplerValue(sampler:ShaderSampler, value:ShaderValue):Void;

	/** Makes a sampler read a shared texture, until `unshareTexture`, in place of a texture written.

		@param sampler  The sampler.
		@param shared  The shared texture. */
	function shareTexture(sampler:ShaderSampler, shared:ShaderSharedTexture):Void;

	/** Stops a sampler reading a shared texture.

		@param sampler  The sampler. */
	function unshareTexture(sampler:ShaderSampler):Void;

	/** Makes the shader's block of a shared block's name read the shared block's bytes, until `unshareBlock`. A block of that name
		already shared is replaced, as a shadow pass's values swap the camera's block for the light's.

		@param block  The shared block.
		@throws String  A shader (none of a set's variants) that names no shared block of that name (`ShaderOptions.shared`). */
	function shareBlock(block:ShaderBlockValues):Void;

	/** Stops sharing a block of a name; what it reads is then its base's, or nothing, and a draw throws until one is shared.

		@param blockName  The block's name. */
	function unshareBlock(blockName:String):Void;

	/** Returns the shared block a block of a name reads now: its own, or its base's.

		@param blockName  The block's name.
		@return  The shared block, or null when none is shared. */
	function findSharedBlock(blockName:String):Null<ShaderBlockValues>;
}
