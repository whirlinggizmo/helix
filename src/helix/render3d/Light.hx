package helix.render3d;

/** A light, shining from its node's place and orientation once it is on a stage: a DirectionalLight, a PointLight or a SpotLight (a stage
	never holds a bare Light). Its color is 0xAARRGGBB (sRGB, its alpha ignored), its intensity a multiplier: the earlier frameworks' sun is
	about 3. Under a model, a lamp's bulb, it moves with it; it has children as any node.

	A directional light or a spot may cast shadows (shadowCasting; a stage draws them with Renderer3D.drawShadows): from the models that cast
	them onto those that receive them (Model.shadowCasting, shadowReceiving; both by default). A directional light's map covers what the
	camera sees out to its shadow distance; a spot's, its cone out to its range (or the shadow distance, the nearer). */
abstract class Light extends Node3D {
	/** A white light of intensity 1, casting no shadows. */
	function new()
		super();

	/** Its color, 0xAARRGGBB. */
	public var color:Int = 0xffffffff;

	/** Its intensity, a multiplier: 0 or more (under 0, or NaN, is 0). */
	public var intensity(default, set):Float = 1.;

	function set_intensity(value:Float):Float
		return intensity = value >= 0 ? value : 0;

	/** Whether it casts shadows (always false for a point light: it would need a map each way). */
	@:isVar public var shadowCasting(get, set):Bool = false;

	function get_shadowCasting():Bool
		return shadowCasting;

	function set_shadowCasting(value:Bool):Bool {
		shadowCasting = value;
		return value;
	}

	/** How far from the camera a directional light's shadows reach, in world units (50 by default); a spot's reach no further. Shorter is
		sharper: the map covers less. At least 1e-6 (0 or less, or NaN, is 1e-6) and finite (infinity is the largest finite Float). */
	public var shadowDistance(default, set):Float = 50.;

	function set_shadowDistance(distance:Float):Float
		return shadowDistance = distance > 1e-6 ? Math.min(distance, 1.7976931348623157e308) : 1e-6;

	/** Its shadow map's side in texels (2048 by default): a power of two from 256 to 4096, what it's given rounded down to one and into that
		range. A stage's casting lights share the largest asked for. */
	public var shadowMapSize(default, set):Int = 2048;

	function set_shadowMapSize(size:Int):Int {
		var clamped = 256;
		while (clamped * 2 <= size && clamped < 4096)
			clamped *= 2;
		return shadowMapSize = clamped;
	}

	/** How much of its light a shadow takes away, clamped to 0..1 (1 by default; NaN is 0). */
	public var shadowStrength(default, set):Float = 1.;

	function set_shadowStrength(strength:Float):Float
		return shadowStrength = strength > 0 ? (strength > 1 ? 1 : strength) : 0;

	/** What its shadows leave of the surface's own color, 0xAARRGGBB (sRGB, alpha ignored; black by default: nothing): a cold blue for a sunny
		day's shade. */
	public var shadowColor:Int = 0xff000000;

	/** Its shadows' depth bias, constant part, in shadow-map texels (1 by default). */
	public var shadowBiasConstant(default, null):Float = 1.;

	/** Its shadows' depth bias, slope part: texels more where the light grazes a surface (4 by default). */
	public var shadowBiasSlope(default, null):Float = 4.;

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
