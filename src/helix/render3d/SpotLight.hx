package helix.render3d;

/** A point light's falloff out to its range, within a cone around its node's -z: full inside its inner cone, fading to nothing at its outer.
	It may cast shadows (setShadowCasting), over its cone out to its range (or its shadow distance, the nearer). */
class SpotLight extends Light {
	var range = 0.;
	var inner = .3;
	var outer = .4;

	/** A white spot of intensity 1 and unlimited range, its cones 0.3 and 0.4 radians from its axis. */
	public function new()
		super();

	/** Its range in world units: past it, nothing; 0 for unlimited (falling off with the square of the distance). */
	public function getRange():Float
		return range;

	/** Sets its range in world units (0 for unlimited). False for a range under 0. */
	public function setRange(value:Float):Bool {
		if (!(value >= 0))
			return false;
		range = value;
		return true;
	}

	/** Its inner cone, radians from its axis: full light inside it. */
	public function getInnerCone():Float
		return inner;

	/** Its outer cone, radians from its axis: no light past it, fading from the inner one. */
	public function getOuterCone():Float
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
