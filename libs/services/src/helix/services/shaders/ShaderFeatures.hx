package helix.services.shaders;

/** Represents a set of a `ShaderVariants`' features, the defines its variants differ by, as bits: `ShaderVariants.getShader` takes it.

	A feature is a name alone, defined as 1 when on and not defined when off; a define with a value is a shared define
	(`ShaderOptions.defines`), the same in every variant. A set's features come from its variants (`ShaderVariants.getFeature`), or
	as static constants of a class `ShaderValueClasses.buildVariants` made (`LitValues.SKINNED | LitValues.INSTANCED`), so the compiler
	checks the names. */
abstract ShaderFeatures(Int) from Int to Int {
	/** No features: the variant compiled with none on. */
	public static inline final NONE:ShaderFeatures = 0;

	/** Returns the set with another set's features added.

		@param other  The other set.
		@return  The union. */
	@:op(A | B)
	public inline function with(other:ShaderFeatures):ShaderFeatures
		return this | (other : Int);

	/** Returns the set with another set's features removed.

		@param other  The features to remove.
		@return  The set without them. */
	public inline function without(other:ShaderFeatures):ShaderFeatures
		return this & ~(other : Int);

	/** Returns the set with another set's features turned over: each on turned off, each off turned on.

		@param other  The features to turn over.
		@return  The set with them turned over. */
	public inline function toggled(other:ShaderFeatures):ShaderFeatures
		return this ^ (other : Int);

	/** Returns the set with another set's features on or off, as a flag says.

		```haxe
		features = features.switched(USE_MAP, map != 0).switched(USE_FOG, fog);
		```
		@param other  The features.
		@param on  Whether they are on.
		@return  The set with them on or off. */
	public inline function switched(other:ShaderFeatures, on:Bool):ShaderFeatures
		return on ? this | (other : Int) : this & ~(other : Int);

	/** Returns whether the set holds every feature of another.

		@param other  The other set.
		@return  True when each of its features is in this one. */
	public inline function hasFeatures(other:ShaderFeatures):Bool
		return this & (other : Int) == (other : Int);
}
