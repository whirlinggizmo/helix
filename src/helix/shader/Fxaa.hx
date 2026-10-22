package helix.shader;

/** FXAA, a screen effect of the library: Timothy Lottes's FXAA 3.11 (its quality version, preset 12), smoothing the stair steps along edges
	in the finished frame by the contrast of its luma, which it works out itself. Put it after the tone mapping (in an HDR chain, after the
	last effect wanting HDR: PostProcess runs the tone mapping there) and before effects that add their own detail (grain, scanlines), so
	what it smooths is the frame as shown. */
class Fxaa extends LibraryScreenEffect {
	/** FXAA at its defaults: subpixel .75, edgeThreshold .166, edgeThresholdMin .0833. */
	public function new() {
		super("fxaa", FxaaPacked.text());
		subpixel = .75;
		edgeThreshold = .166;
		edgeThresholdMin = .0833;
	}

	/** How much edges thinner than a pixel are smoothed, 0 (sharper; none) to 1 (softer): .75 by default. */
	public var subpixel(default, set):Float;

	function set_subpixel(value:Float):Float
		return subpixel = writeFloat("subpixel", value, 0, 1);

	/** The least contrast smoothed, a share of the brightest luma around a pixel, .063 (slower, more edges) to .333 (faster, fewer): .166 by
		default. */
	public var edgeThreshold(default, set):Float;

	function set_edgeThreshold(value:Float):Float
		return edgeThreshold = writeFloat("edge_threshold", value, .063, .333);

	/** The least contrast smoothed in all, so dark areas are left alone, 0 to .1 (luma): .0833 by default. */
	public var edgeThresholdMin(default, set):Float;

	function set_edgeThresholdMin(value:Float):Float
		return edgeThresholdMin = writeFloat("edge_threshold_min", value, 0, .1);
}
