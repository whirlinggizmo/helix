package helix.render3d;

/** What a light is: directional (the sun: everything lit from one direction, the light's node's -z), a point (from its node's position in
	every direction, fading with distance, out to its range) or a spot (a point light's falloff, within a cone around its node's -z). Its color is 0xRRGGBBAA (sRGB, its alpha ignored), its intensity a multiplier:
	the earlier frameworks' sun is about 3. A light shines once a node holds it on a stage (Node.light). */
class Light {
	var kind:LightKind;
	var color = 0xffffffff;
	var intensity = 1.;
	var range = 0.;
	var inner = .3;
	var outer = .4;

	/** A white light of intensity 1 of kind; a point light of unlimited range. */
	public function new(kind:LightKind) {
		this.kind = kind;
	}

	/** Its kind. */
	public function getKind():LightKind
		return kind;

	/** Its color, 0xRRGGBBAA. */
	public function getColor():Int
		return color;

	/** Sets its color, 0xRRGGBBAA. */
	public function setColor(value:Int):Void
		color = value;

	/** Its intensity. */
	public function getIntensity():Float
		return intensity;

	/** False for an intensity under 0. */
	public function setIntensity(value:Float):Bool {
		if (!(value >= 0))
			return false;
		intensity = value;
		return true;
	}

	/** A spot's inner cone, radians from its axis: full light inside it. */
	public function getInnerCone():Float
		return inner;

	/** A spot's outer cone, radians from its axis: no light past it, fading from the inner one. */
	public function getOuterCone():Float
		return outer;

	/** Sets a spot's cones, radians from its axis. False, changing nothing, unless 0 <= inner <= outer < pi/2. */
	public function setCone(inner:Float, outer:Float):Bool {
		if (!(inner >= 0 && inner <= outer && outer < Math.PI / 2))
			return false;
		this.inner = inner;
		this.outer = outer;
		return true;
	}

	/** A point light's or a spot's range in world units: past it, nothing; 0 for unlimited (falling off with the square of the distance). */
	public function getRange():Float
		return range;

	/** False for a range under 0. */
	public function setRange(value:Float):Bool {
		if (!(value >= 0))
			return false;
		range = value;
		return true;
	}
}

/** A light's kind. */
enum abstract LightKind(Int) {
	/** From one direction everywhere: its node's -z. */
	var Directional = 0;

	/** From its node's position, in every direction. */
	var Point = 1;

	/** From its node's position, within a cone around its node's -z. */
	var Spot = 2;
}
