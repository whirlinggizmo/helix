package helix.platform;

import helix.platform.BlendFactor;
import helix.platform.BlendOperation;

/** Represents how a pipeline's colors are combined with the colors already in the target: a factor for each side and an operation, for
	red, green and blue, and for alpha.

	The source is the color a draw writes, and the destination the color in the target. Each channel becomes `source * sourceFactor`
	combined by the operation with `destination * destinationFactor`, then clamped to what the target stores (0 to 1 in an RGBA8 target).
	Colors are straight alpha, not premultiplied, unless a program premultiplies its own. It is a small value, like `Sampling`; adapters
	keep a GPU blend state for each value used.

	```haxe
	var multiply = new Blend(DestinationColor, OneMinusSourceAlpha);
	var keepAlpha = new Blend(SourceAlpha, OneMinusSourceAlpha, Add, Zero, One);
	``` */
abstract Blend(Int) to Int {
	/** No blending: the color replaces the target's. */
	public static final OPAQUE = new Blend(One, Zero);

	/** The color blended over the target's by its alpha. The target's alpha becomes `a + destination alpha * (1 - a)`, so what is drawn over
		a clear target stays as opaque as it was drawn. */
	public static final ALPHA = new Blend(SourceAlpha, OneMinusSourceAlpha, Add, One, OneMinusSourceAlpha);

	/** The color, multiplied by its alpha, added to the target's. It suits light, fire and glows. */
	public static final ADDITIVE = new Blend(SourceAlpha, One, Add, One, One);

	/** Creates a blend.

		@param colorSource  The factor for the source's red, green and blue.
		@param colorDestination  The factor for the destination's red, green and blue.
		@param colorOperation  Optional. How red, green and blue are combined; defaults to Add.
		@param alphaSource  Optional. The factor for the source's alpha; defaults to colorSource.
		@param alphaDestination  Optional. The factor for the destination's alpha; defaults to colorDestination.
		@param alphaOperation  Optional. How the alphas are combined; defaults to colorOperation. */
	public inline function new(colorSource:BlendFactor, colorDestination:BlendFactor, colorOperation:BlendOperation = Add, ?alphaSource:BlendFactor,
			?alphaDestination:BlendFactor, ?alphaOperation:BlendOperation)
		this = (colorSource : Int) | (colorDestination : Int) << 4 | ((alphaSource == null ? colorSource : alphaSource) : Int) << 8 | ((alphaDestination == null ? colorDestination : alphaDestination) : Int) << 12 | (colorOperation : Int) << 16 | ((alphaOperation == null ? colorOperation : alphaOperation) : Int) << 19;

	/** Gets the factor for the source's red, green and blue. */
	public var colorSource(get, never):BlendFactor;

	inline function get_colorSource():BlendFactor
		return cast this & 15;

	/** Gets the factor for the destination's red, green and blue. */
	public var colorDestination(get, never):BlendFactor;

	inline function get_colorDestination():BlendFactor
		return cast(this >> 4) & 15;

	/** Gets the factor for the source's alpha. */
	public var alphaSource(get, never):BlendFactor;

	inline function get_alphaSource():BlendFactor
		return cast(this >> 8) & 15;

	/** Gets the factor for the destination's alpha. */
	public var alphaDestination(get, never):BlendFactor;

	inline function get_alphaDestination():BlendFactor
		return cast(this >> 12) & 15;

	/** Gets how red, green and blue are combined. */
	public var colorOperation(get, never):BlendOperation;

	inline function get_colorOperation():BlendOperation
		return cast(this >> 16) & 7;

	/** Gets how the alphas are combined. */
	public var alphaOperation(get, never):BlendOperation;

	inline function get_alphaOperation():BlendOperation
		return cast(this >> 19) & 7;
}
