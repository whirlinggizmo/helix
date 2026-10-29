package helix.platform;

import helix.platform.Wrap;

/** Represents how a draw samples a texture, by its filter and how it wraps along u and v.

	It is a small value passed with each texture a draw uses. Adapters keep one sampler for each value used.

	```haxe
	var tiled = new Sampling(Nearest, Repeat, Repeat);
	```
 */
abstract Sampling(Int) to Int {
	/** Nearest filtering, clamped, for pixel art. */
	public static final NEAREST = new Sampling(Nearest);

	/** Linear filtering, clamped, for a smooth look. */
	public static final LINEAR = new Sampling(Linear);

	/** Creates a sampling.

		@param filter  How the texture is filtered.
		@param wrapU  Optional. How the texture wraps along u; defaults to Clamp.
		@param wrapV  Optional. How the texture wraps along v; defaults to Clamp. */
	public inline function new(filter:Filter, wrapU:Wrap = Clamp, wrapV:Wrap = Clamp)
		this = (filter : Int) | (wrapU : Int) << 1 | (wrapV : Int) << 3;

	/** Gets how the texture is filtered, Linear or Nearest. */
	public var filter(get, never):Filter;

	inline function get_filter():Filter
		return cast this & 1;

	/** Gets how the texture wraps along u. */
	public var wrapU(get, never):Wrap;

	inline function get_wrapU():Wrap
		return cast(this >> 1) & 3;

	/** Gets how the texture wraps along v. */
	public var wrapV(get, never):Wrap;

	inline function get_wrapV():Wrap
		return cast(this >> 3) & 3;

	/** Returns this sampling with another filter.

		@param filter  The new filter.
		@return  The sampling, its wrapping unchanged. */
	public inline function withFilter(filter:Filter):Sampling
		return new Sampling(filter, get_wrapU(), get_wrapV());

	/** Returns this sampling with other wrapping.

		@param wrapU  How the texture wraps along u.
		@param wrapV  How the texture wraps along v.
		@return  The sampling, its filter unchanged. */
	public inline function withWrap(wrapU:Wrap, wrapV:Wrap):Sampling
		return new Sampling(get_filter(), wrapU, wrapV);

	/** The number of distinct values, which run 0 to COUNT - 1. It is the size of an adapter's table of samplers. */
	public static inline var COUNT = 32;
}
