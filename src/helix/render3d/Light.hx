package helix.render3d;

/** What a light is: directional (the sun: everything lit from one direction, the light's node's -z), a point (from its node's position in
	every direction, fading with distance, out to its range) or a spot (a point light's falloff, within a cone around its node's -z). Its color is 0xRRGGBBAA (sRGB, its alpha ignored), its intensity a multiplier:
	the earlier frameworks' sun is about 3. A light shines once a node holds it on a stage (Node.light).

	A directional light or a spot may cast shadows (setShadowCasting; a stage draws them with Stage3D.drawShadows): from the models that cast
	them onto those that receive them (Node.setShadowCasting, setShadowReceiving; both by default). A directional light's map covers what the
	camera sees out to its shadow distance; a spot's, its cone out to its range (or the shadow distance, the nearer). */
class Light {
	var kind:LightKind;
	var color = 0xffffffff;
	var intensity = 1.;
	var range = 0.;
	var inner = .3;
	var outer = .4;
	var shadowCasting = false;
	var shadowDistance = 50.;
	var shadowMapSize = 2048;
	var shadowStrength = 1.;
	var shadowColor = 0x000000ff;
	var shadowBiasConstant = 1.;
	var shadowBiasSlope = 4.;

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

	/** Whether it casts shadows. */
	public function isShadowCasting():Bool
		return shadowCasting;

	/** Makes it cast shadows or stop. False, changing nothing, for a point light casting: it would need a map each way. */
	public function setShadowCasting(value:Bool):Bool {
		if (value && kind == Point)
			return false;
		shadowCasting = value;
		return true;
	}

	/** How far from the camera a directional light's shadows reach, in world units (50 by default); a spot's reach no further. */
	public function getShadowDistance():Float
		return shadowDistance;

	/** False, changing nothing, unless distance is above 0 and finite. Shorter is sharper: the map covers less. */
	public function setShadowDistance(distance:Float):Bool {
		if (!(distance > 0 && distance < Math.POSITIVE_INFINITY))
			return false;
		shadowDistance = distance;
		return true;
	}

	/** Its shadow map's side in texels (2048 by default). */
	public function getShadowMapSize():Int
		return shadowMapSize;

	/** Sets its shadow map's side: a power of two from 256 to 4096, size rounded down to one (and into that range). A stage's casting lights
		share the largest asked for. False for a size under 1. */
	public function setShadowMapSize(size:Int):Bool {
		if (size < 1)
			return false;
		var clamped = 256;
		while (clamped * 2 <= size && clamped < 4096)
			clamped *= 2;
		shadowMapSize = clamped;
		return true;
	}

	/** How much of its light a shadow takes away, 0..1 (1 by default). */
	public function getShadowStrength():Float
		return shadowStrength;

	/** Sets how much of its light a shadow takes away, clamped to 0..1. False for NaN. */
	public function setShadowStrength(strength:Float):Bool {
		if (Math.isNaN(strength))
			return false;
		shadowStrength = strength < 0 ? 0 : strength > 1 ? 1 : strength;
		return true;
	}

	/** What its shadows leave of the surface's own color, 0xRRGGBBAA (sRGB, alpha ignored; black by default: nothing). */
	public function getShadowColor():Int
		return shadowColor;

	/** Sets what its shadows leave of the surface's own color, 0xRRGGBBAA: a cold blue for a sunny day's shade. */
	public function setShadowColor(color:Int):Void
		shadowColor = color;

	/** Its shadows' depth bias, constant part, in shadow-map texels (1 by default). */
	public function getShadowBiasConstant():Float
		return shadowBiasConstant;

	/** Its shadows' depth bias, slope part: texels more where the light grazes a surface (4 by default). */
	public function getShadowBiasSlope():Float
		return shadowBiasSlope;

	/** Sets its shadows' depth bias in texels: constant everywhere, plus slope where the light grazes. More stops a surface shadowing itself in
		stripes ("acne"); too much lifts a shadow off its caster's foot. False, changing nothing, for a negative or infinite one. */
	public function setShadowBias(constant:Float, slope:Float):Bool {
		if (!(constant >= 0 && slope >= 0 && constant < Math.POSITIVE_INFINITY && slope < Math.POSITIVE_INFINITY))
			return false;
		shadowBiasConstant = constant;
		shadowBiasSlope = slope;
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
