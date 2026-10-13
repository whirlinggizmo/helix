package helix.render3d;

/** What a light is: directional (the sun: everything lit from one direction, the light's node's -z) or a point (from its node's position in
	every direction, fading with distance, out to its range). Its color is 0xRRGGBBAA (sRGB, its alpha ignored), its intensity a multiplier:
	the earlier frameworks' sun is about 3. A light shines once a node holds it on a stage (Node.light). */
class Light {
	var kind:LightKind;
	var color = 0xffffffff;
	var intensity = 1.;
	var range = 0.;

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

	/** A point light's range in world units: past it, nothing; 0 for unlimited (falling off with the square of the distance). */
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
}
