package helix.platform;

/** Specifies a set of a color's channels, combined with `|`, such as the ones a pipeline's draws write (`PipelineDesc.colorWrite`).

	```haxe
	var noAlpha:ColorChannels = Red | Green | Blue;
	``` */
@:build(helix.platform.macros.EnumNames.build())
enum abstract ColorChannels(Int) to Int {
	/** No channel. */
	var None = 0;

	/** Red. */
	var Red = 1;

	/** Green. */
	var Green = 2;

	/** Blue. */
	var Blue = 4;

	/** Alpha. */
	var Alpha = 8;

	/** Red, green, blue and alpha. */
	var All = 15;

	/** Returns the channels in either set.

		@param other  The other set.
		@return  The channels of both sets together. */
	@:op(A | B) public inline function or(other:ColorChannels):ColorChannels
		return cast(this | (other : Int));

	/** Returns whether the set has every channel of another.

		@param channels  The channels looked for.
		@return  True when each of them is in the set. */
	public inline function hasChannels(channels:ColorChannels):Bool
		return this & (channels : Int) == (channels : Int);
}
