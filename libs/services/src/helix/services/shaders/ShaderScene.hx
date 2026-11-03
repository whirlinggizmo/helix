package helix.services.shaders;

/** Represents what a scene, or one pass of it, shares with every material drawn in it, whatever their shaders: its shared blocks (a
	camera, the lights) and shared textures (a shadow map), by name.

	A values reads a shared block or texture from, in order: what it shares itself, its base's (and its base's base), then its scene
	(`IShaderValues.scene`), its own or else its base's. So a material made once is drawn in any scene by giving its draw that scene, and
	one scene binds every material in it:

	```haxe
	var main = new ShaderScene();
	main.shareBlock(camera);
	main.shareBlock(lights);
	main.shareTexture("shadowMap", shadowMap);
	// a depth-only pass drawing the lit variants binds every shared block they name, its own camera among them
	var shadowPass = new ShaderScene();
	shadowPass.shareBlock(lightCamera);
	shadowPass.shareBlock(lights);
	// each draw:
	drawn.scene = pass == Shadow ? shadowPass : main;
	```

	Changing a values' scene, or a scene's blocks and textures, costs no copy: each shared slot of the values points at the new bytes or
	texture at its next read. A block a shader names shared that neither the values, its base nor the scene shares makes a draw throw,
	naming it. A block whose layout a shader doesn't have is refused where it is shared with the shader's values, and skipped by a
	scene for a shader that doesn't name it. */
class ShaderScene {
	/** Creates an empty scene. */
	public function new() {}

	/** Shares a block with every values reading this scene, replacing one of its name.

		@param block  The shared block. */
	public function shareBlock(block:ShaderBlockValues):Void {
		blocks.set(block.blockName, block);
	}

	/** Stops sharing a block of a name.

		@param blockName  The block's name. */
	public function unshareBlock(blockName:String):Void {
		blocks.remove(blockName);
	}

	/** Shares a texture, by sampler name, with every values reading this scene whose shader samples a texture of that name.

		@param samplerName  The sampler's GLSL name.
		@param shared  The shared texture. */
	public function shareTexture(samplerName:String, shared:ShaderSharedTexture):Void {
		textures.set(samplerName, shared);
	}

	/** Stops sharing a texture of a sampler name.

		@param samplerName  The sampler's GLSL name. */
	public function unshareTexture(samplerName:String):Void {
		textures.remove(samplerName);
	}

	/** Finds a shared block by name.

		@param blockName  The block's name.
		@return  The block, or null. */
	public function findSharedBlock(blockName:String):Null<ShaderBlockValues> {
		return blocks.get(blockName);
	}

	/** Finds the shared block holding a uniform, so a uniform of a shared block is written through the scene
		(`scene.findSharedBlockOf(viewProjection).writeMatrix(viewProjection, m)`).

		@param uniform  The uniform.
		@return  The block shared under its block's name, or null when the uniform isn't a shared block's or none is shared. */
	public function findSharedBlockOf(uniform:ShaderUniform):Null<ShaderBlockValues> {
		return uniform.shared ? blocks.get(uniform.blockName) : null;
	}

	/** Finds a shared texture by sampler name.

		@param samplerName  The sampler's GLSL name.
		@return  The shared texture, or null. */
	public function findSharedTexture(samplerName:String):Null<ShaderSharedTexture> {
		return textures.get(samplerName);
	}

	final blocks = new Map<String, ShaderBlockValues>();
	final textures = new Map<String, ShaderSharedTexture>();
}
