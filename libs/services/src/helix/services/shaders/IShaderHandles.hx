package helix.services.shaders;

/** Defines finding what a shader, or any variant of a set, declares: `Shader` and `ShaderVariants` implement it, so a by-name layer
	works over either.

	A `get` form throws for a name nothing declares, listing what is declared and, for a path written with brackets, the spelling it
	takes; a `find` form returns null. On a set, a name is found when any variant declares it. */
interface IShaderHandles {
	/** Gets every uniform's handle: each block member, struct field and field of an array of structs, in block order. On a set, every
		variant's, each name once. */
	var uniforms(get, never):Array<ShaderUniform>;

	/** Gets every sampled texture's handle, in slot order; on a set, every variant's, each name once. */
	var samplers(get, never):Array<ShaderSampler>;

	/** Returns whether a uniform is declared.

		@param name  Its path, or the name `Shader.withNames` gave it.
		@return  True when it is declared (on a set, by any variant). */
	function hasUniform(name:String):Bool;

	/** Returns whether a texture is sampled.

		@param name  Its GLSL name, or the name `Shader.withNames` gave it.
		@return  True when it is declared (on a set, by any variant). */
	function hasSampler(name:String):Bool;

	/** Returns the handle of a uniform.

		@param name  Its path (`roughness`, `material.roughness`, `lights.color`), or the name `Shader.withNames` gave it.
		@return  The handle, the same each call.
		@throws String  A name nothing declares; given `lights[0].position`, it names `lights.position` and `getUniformPath`. */
	function getUniform(name:String):ShaderUniform;

	/** Finds the handle of a uniform that may not be declared.

		@param name  Its path, or the name `Shader.withNames` gave it.
		@return  The handle, the same each call, or null. */
	function findUniform(name:String):Null<ShaderUniform>;

	/** Returns a uniform and element from a path as GLSL writes it, with brackets (`pointLights[1].color`, `bones[3]`), or without.

		@param path  The path.
		@return  The uniform and the element, the same object for the same path.
		@throws String  A path whose uniform nothing declares, or an index past its elements. */
	function getUniformPath(path:String):ShaderUniformPath;

	/** Finds a uniform and element from a path that may not be declared.

		@param path  The path.
		@return  The uniform and the element, or null: for a uniform nothing declares, an index past its elements, a path naming a struct
			or a struct's element rather than a field (`lights[1]`, `lights`). */
	function findUniformPath(path:String):Null<ShaderUniformPath>;

	/** Returns the handle of a sampled texture.

		@param name  Its GLSL name, or the name `Shader.withNames` gave it.
		@return  The handle, the same each call.
		@throws String  A name nothing declares. */
	function getSampler(name:String):ShaderSampler;

	/** Finds the handle of a sampled texture that may not be declared.

		@param name  Its GLSL name, or the name `Shader.withNames` gave it.
		@return  The handle, or null. */
	function findSampler(name:String):Null<ShaderSampler>;

	/** Returns whether a shared block is named (`ShaderOptions.shared`).

		@param blockName  The block's name.
		@return  True when it is (on a set, by any variant). */
	function hasSharedBlock(blockName:String):Bool;

	/** Returns a handle for a uniform that may be declared only after a replacement, binding when it is (`Shader.reserveUniform`).

		@param name  Its path.
		@return  The handle, the same each call. */
	function reserveUniform(name:String):ShaderUniform;

	/** Returns a uniform and element for a bracketed path that may be declared only after a replacement.

		@param path  The path.
		@return  The uniform and the element. */
	function reserveUniformPath(path:String):ShaderUniformPath;

	/** Returns a handle for a texture that may be sampled only after a replacement, binding when it is.

		@param name  Its GLSL name.
		@return  The handle, the same each call. */
	function reserveSampler(name:String):ShaderSampler;

	/** Returns a vertex attribute (on a set, the first variant's that reads it).

		@param name  Its GLSL name, or the name `Shader.withNames` gave it.
		@return  The attribute.
		@throws String  A name nothing declares. */
	function getAttribute(name:String):ShaderAttribute;

	/** Finds a vertex attribute that may not be read.

		@param name  Its GLSL name.
		@return  The attribute, or null. */
	function findAttribute(name:String):Null<ShaderAttribute>;

	/** Finds a shared block's layout, for the library's values. */
	@:noCompletion
	function findSharedLayout(blockName:String):Null<helix.services.shaders.ShaderLayout.ShaderBlockLayout>;
}
