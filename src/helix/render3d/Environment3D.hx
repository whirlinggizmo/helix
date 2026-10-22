package helix.render3d;

/** A place's light (docs/DISPLAY_MODEL.md): the ambient light reaching everything evenly, the environment map lighting and reflecting the lit
	models, and the background drawn behind them. Data, set as a 3D node's environment (Node3D.environment, where a scene file's
	"environment" section puts it) or as a view's, which overrides what it shows (View3D.environment). How a camera photographs the place
	(exposure, tone mapping) is the view's, not this. Unlit to start: no ambient light, no map, no background. */
class Environment3D {
	/** An environment of no light: no ambient light, no map, no background. */
	public function new() {}

	/** The ambient light's color, 0xAARRGGBB (sRGB). White to start. */
	public var ambientColor(default, null):Int = 0xffffffff;

	/** The ambient light's intensity, 0 or more. 0 to start. */
	public var ambientIntensity(default, null):Float = 0.;

	/** The light reaching everything evenly, from no direction: color 0xAARRGGBB (sRGB) times intensity. False, changing nothing, for an
		intensity under 0. */
	public function setAmbient(color:Int, intensity:Float):Bool {
		if (!(intensity >= 0))
			return false;
		ambientColor = color;
		ambientIntensity = intensity;
		return true;
	}

	/** The environment map lighting and reflecting the lit models (Environments3D.load), or null. */
	public var map(default, null):Null<EnvironmentMap3D>;

	/** How strongly the map lights, and the background shows: 1 as its file has it. */
	public var mapIntensity(default, null):Float = 1.;

	/** How far the map, and the background, turn about +y, in radians. */
	public var rotation(default, null):Float = 0.;

	/** Lights the lit models with map (null: none) as well as the lights and the ambient light: its intensity (1 as its file has it) and its
		turn about +y (radians), which the background shares. False, changing nothing, for an intensity under 0 or a rotation that isn't
		finite. */
	public function setMap(map:Null<EnvironmentMap3D>, intensity = 1., rotation = 0.):Bool {
		if (!(intensity >= 0) || !Math.isFinite(rotation))
			return false;
		this.map = map;
		mapIntensity = intensity;
		this.rotation = rotation;
		return true;
	}

	/** The environment map drawn behind everything, or null. */
	public var background(default, null):Null<EnvironmentMap3D>;

	/** How blurred the background is: 0 sharp to 1 its blurriest. */
	public var backgroundBlur(default, null):Float = 0.;

	/** Draws map (null: none) behind everything, at blur 0 (sharp, the image's own resolution) to 1 (blurred to a few texels), turned and as
		bright as setMap says. False, changing nothing, for a blur outside 0..1. */
	public function setBackground(map:Null<EnvironmentMap3D>, blur = 0.):Bool {
		if (!(blur >= 0 && blur <= 1))
			return false;
		background = map;
		backgroundBlur = blur;
		return true;
	}
}
