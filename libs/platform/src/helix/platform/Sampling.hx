package helix.platform;

import helix.platform.MipmapFilter;
import helix.platform.Wrap;

/** Represents how a draw samples a texture: its filter, how it wraps along u and v, how its mipmaps are read, and its anisotropy.

	It is a small value passed with each texture a draw uses. Adapters keep one sampler for each value used.

	```haxe
	var tiled = new Sampling(Nearest, Repeat, Repeat);
	var floor = new Sampling(Linear, Repeat, Repeat, Linear, 8);
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
		@param wrapV  Optional. How the texture wraps along v; defaults to Clamp.
		@param mipmapFilter  Optional. How a texture's mipmaps are read; defaults to Linear for a Linear filter and Nearest for a Nearest one.
		@param anisotropy  Optional. The most texels read along a surface seen at a slant, 1 to 16, rounded down to 1, 2, 4, 8 or 16 and
			clamped to what the GPU has; defaults to 1, for none. It is used only with a Linear filter and Linear mipmaps, and ignored
			otherwise. */
	public inline function new(filter:Filter, wrapU:Wrap = Clamp, wrapV:Wrap = Clamp, ?mipmapFilter:MipmapFilter, anisotropy:Int = 1)
		this = (filter : Int) | (wrapU : Int) << 1 | (wrapV : Int) << 3 | ((mipmapFilter == null ? (filter : Int) == 1 ? MipmapFilter.Linear : MipmapFilter.Nearest : mipmapFilter) : Int) << 5 | (anisotropy >= 16 ? 4 : anisotropy >= 8 ? 3 : anisotropy >= 4 ? 2 : anisotropy >= 2 ? 1 : 0) << 7;

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

	/** Gets how the texture's mipmaps are read. */
	public var mipmapFilter(get, never):MipmapFilter;

	inline function get_mipmapFilter():MipmapFilter
		return cast(this >> 5) & 3;

	/** Gets the most texels read along a surface seen at a slant: 1, 2, 4, 8 or 16. */
	public var anisotropy(get, never):Int;

	inline function get_anisotropy():Int
		return 1 << ((this >> 7) & 7);

	/** Returns this sampling with another filter.

		@param filter  The new filter.
		@return  The sampling, its wrapping, mipmap filter and anisotropy unchanged. */
	public inline function withFilter(filter:Filter):Sampling
		return new Sampling(filter, get_wrapU(), get_wrapV(), get_mipmapFilter(), get_anisotropy());

	/** Returns this sampling with other wrapping.

		@param wrapU  How the texture wraps along u.
		@param wrapV  How the texture wraps along v.
		@return  The sampling, its filters and anisotropy unchanged. */
	public inline function withWrap(wrapU:Wrap, wrapV:Wrap):Sampling
		return new Sampling(get_filter(), wrapU, wrapV, get_mipmapFilter(), get_anisotropy());

	/** Returns this sampling with another mipmap filter.

		@param mipmapFilter  How the texture's mipmaps are read.
		@return  The sampling, its filter, wrapping and anisotropy unchanged. */
	public inline function withMipmapFilter(mipmapFilter:MipmapFilter):Sampling
		return new Sampling(get_filter(), get_wrapU(), get_wrapV(), mipmapFilter, get_anisotropy());

	/** Returns this sampling with another anisotropy.

		@param anisotropy  The most texels read along a surface seen at a slant, 1 to 16, as the constructor takes it.
		@return  The sampling, its filters and wrapping unchanged. */
	public inline function withAnisotropy(anisotropy:Int):Sampling
		return new Sampling(get_filter(), get_wrapU(), get_wrapV(), get_mipmapFilter(), anisotropy);

	/** The number of distinct values, which run 0 to COUNT - 1. It is the size of an adapter's table of samplers. */
	public static inline var COUNT = 1024;
}
