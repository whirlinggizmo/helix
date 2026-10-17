package helix.graphics;

/** How a texture's edges repeat past 0..1. */
enum abstract Wrap(Int) to Int {
	/** The edge texel carries on. */
	var Clamp = 0;

	/** The texture tiles. */
	var Repeat = 1;

	/** The texture tiles, every other copy mirrored. */
	var Mirror = 2;
}

/** How a draw samples a texture: its filter (linear, smooth and through its mipmaps when it has them; or nearest, sharp, for pixel art) and how
	it wraps along u and v. A small value, passed with each texture a draw uses; adapters keep one sampler for each that is used. */
abstract Sampling(Int) to Int {
	/** Nearest, clamped: pixel art. */
	public static final NEAREST = new Sampling(false);

	/** Linear, clamped: smooth. */
	public static final LINEAR = new Sampling(true);

	/** Linear or nearest filtering, wrapping as wrapU and wrapV say. */
	public inline function new(linear:Bool, wrapU:Wrap = Clamp, wrapV:Wrap = Clamp)
		this = (linear ? 1 : 0) | (wrapU : Int) << 1 | (wrapV : Int) << 3;

	/** Whether it filters linearly. */
	public var linear(get, never):Bool;

	inline function get_linear():Bool
		return this & 1 != 0;

	/** How it wraps along u. */
	public var wrapU(get, never):Wrap;

	inline function get_wrapU():Wrap
		return cast(this >> 1) & 3;

	/** How it wraps along v. */
	public var wrapV(get, never):Wrap;

	inline function get_wrapV():Wrap
		return cast(this >> 3) & 3;

	/** The same with linear filtering or not. */
	public inline function withLinear(value:Bool):Sampling
		return new Sampling(value, get_wrapU(), get_wrapV());

	/** The same wrapping as wrapU and wrapV. */
	public inline function withWrap(wrapU:Wrap, wrapV:Wrap):Sampling
		return new Sampling(get_linear(), wrapU, wrapV);

	/** Every value there is, 0 to COUNT - 1, for an adapter's table of samplers. */
	public static inline var COUNT = 32;
}
