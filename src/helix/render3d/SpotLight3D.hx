package helix.render3d;

/** A point light's falloff out to its range, within a cone around its node's -z: full inside its inner cone, fading to nothing at its outer.
	It may cast shadows (shadowCasting), over its cone out to its range (or its shadow distance, the nearer). */
class SpotLight3D extends Light3D {
	var inner = .3;
	var outer = .4;

	/** A white spot of intensity 1 and unlimited range, its cones 0.3 and 0.4 radians from its axis. */
	public function new()
		super();

	/** Its range in world units: past it, nothing; 0 for unlimited (falling off with the square of the distance). 0 or more (under 0, or
		NaN, is 0). */
	public var range(default, set):Float = 0.;

	function set_range(value:Float):Float
		return range = value >= 0 ? value : 0;

	/** Its inner cone, radians from its axis: full light inside it. */
	public var innerCone(get, never):Float;

	function get_innerCone():Float
		return inner;

	/** Its outer cone, radians from its axis: no light past it, fading from the inner one. */
	public var outerCone(get, never):Float;

	function get_outerCone():Float
		return outer;

	/** Sets its cones, radians from its axis. False, changing nothing, unless 0 <= inner <= outer < pi/2. */
	public function setCone(inner:Float, outer:Float):Bool {
		if (!(inner >= 0 && inner <= outer && outer < Math.PI / 2))
			return false;
		this.inner = inner;
		this.outer = outer;
		return true;
	}
}
