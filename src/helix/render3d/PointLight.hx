package helix.render3d;

/** A light from its node's position in every direction, fading with distance, out to its range. It casts no shadows: it would need a map
	each way. */
class PointLight extends Light {
	var range = 0.;

	/** A white point light of intensity 1 and unlimited range. */
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

	/** Makes it cast shadows or stop: false, changing nothing, for casting, which a point light can't. */
	override public function setShadowCasting(value:Bool):Bool {
		if (value)
			return false;
		return super.setShadowCasting(value);
	}
}
