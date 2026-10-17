package helix.render3d;

/** A light, shining from its node's place and orientation once it is on a stage: a DirectionalLight, a PointLight or a SpotLight (a stage
	never holds a bare Light). Its color is 0xRRGGBBAA (sRGB, its alpha ignored), its intensity a multiplier: the earlier frameworks' sun is
	about 3. Under a model, a lamp's bulb, it moves with it; it has children as any node.

	A directional light or a spot may cast shadows (setShadowCasting; a stage draws them with Stage3D.drawShadows): from the models that cast
	them onto those that receive them (Model.setShadowCasting, setShadowReceiving; both by default). A directional light's map covers what the
	camera sees out to its shadow distance; a spot's, its cone out to its range (or the shadow distance, the nearer). */
abstract class Light extends Node3D {
	var color = 0xffffffff;
	var intensity = 1.;
	var shadowCasting = false;
	var shadowDistance = 50.;
	var shadowMapSize = 2048;
	var shadowStrength = 1.;
	var shadowColor = 0x000000ff;
	var shadowBiasConstant = 1.;
	var shadowBiasSlope = 4.;

	/** A white light of intensity 1, casting no shadows. */
	function new()
		super();

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

	/** Whether it casts shadows. */
	public function isShadowCasting():Bool
		return shadowCasting;

	/** Makes it cast shadows or stop. False, changing nothing, for a point light casting: it would need a map each way. */
	public function setShadowCasting(value:Bool):Bool {
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
