package helix.render3d;

/** A light from its node's position in every direction, fading with distance, out to its range. It casts no shadows: it would need a map
	each way. */
class PointLight extends Light {
	/** A white point light of intensity 1 and unlimited range. */
	public function new()
		super();

	/** Its range in world units: past it, nothing; 0 for unlimited (falling off with the square of the distance). 0 or more (under 0, or
		NaN, is 0). */
	public var range(default, set):Float = 0.;

	function set_range(value:Float):Float
		return range = value >= 0 ? value : 0;

	// A point light never casts: true is taken as false.
	override function set_shadowCasting(value:Bool):Bool
		return super.set_shadowCasting(false);
}
