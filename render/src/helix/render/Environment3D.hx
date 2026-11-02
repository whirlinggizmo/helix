package helix.render;

/** Represents a place's light apart from its lights: the ambient light reaching every surface evenly, an environment map lighting and
	reflecting the lit materials, and the background behind everything.

	A `Batch3D` lights by its `environment`, which several batches may share; each `begin` reads it as it is then. It starts with no
	light at all: lighting is what the program sets. */
class Environment3D {
	/** Gets the ambient light's color, 0xAARRGGBB, its alpha ignored: white until set. */
	public var ambientColor(default, null):Int = 0xffffffff;

	/** Gets the ambient light's intensity: 0 until set, so there is none until the program sets it. */
	public var ambientIntensity(default, null):Float = 0;

	/** Gets the environment map lighting the lit materials, or null for none: null until set. */
	public var map(default, null):Null<EnvironmentMap3D> = null;

	/** Gets how strongly the map lights, and the background shows: 1, as its picture has it, until set. */
	public var mapIntensity(default, null):Float = 1;

	/** Gets how far the map and the background are turned about +y, in radians: 0 until set. */
	public var rotation(default, null):Float = 0;

	/** Gets the environment map shown behind everything by `Batch3D.drawBackground`, or null for none. */
	public var background(default, null):Null<EnvironmentMap3D> = null;

	/** Gets how blurred the background is: 0 sharp, at the picture's own resolution, to 1, a few texels. */
	public var backgroundBlur(default, null):Float = 0;

	/** Creates an environment of no light: no ambient light, no map, no background. */
	public function new() {}

	/** Sets the ambient light: its color decoded from sRGB, times its intensity.

		@param color  The color, as 0xAARRGGBB; its alpha is ignored.
		@param intensity  The intensity.
		@return  False, changing nothing, for an intensity below 0. */
	public function setAmbient(color:Int, intensity:Float):Bool {
		if (!(intensity >= 0))
			return false;
		ambientColor = color;
		ambientIntensity = intensity;
		return true;
	}

	/** Sets the environment map the lit materials are lit and reflect by, beside the lights and the ambient light: diffuse light from
		its irradiance, reflections from its prefiltered cube, sharp to blurred by roughness.

		@param map  The map, or null for none.
		@param intensity  Optional. How strongly it lights, and the background shows; defaults to 1.
		@param rotation  Optional. Its turn about +y, in radians, which the background shares; defaults to 0.
		@return  False, changing nothing, for an intensity below 0 or a rotation that isn't finite. */
	public function setMap(map:Null<EnvironmentMap3D>, intensity = 1., rotation = 0.):Bool {
		if (!(intensity >= 0) || !Math.isFinite(rotation))
			return false;
		this.map = map;
		mapIntensity = intensity;
		this.rotation = rotation;
		return true;
	}

	/** Sets one environment map as both the light and the background, as a sky picture usually is: `setMap` and `setBackground` in
		one call.

		@param map  The map, or null for none of either.
		@param intensity  Optional. How strongly it lights, and the background shows; defaults to 1.
		@param rotation  Optional. Its turn about +y, in radians; defaults to 0.
		@param blur  Optional. How blurred the background is, 0 sharp to 1 its blurriest; defaults to 0.
		@return  False, changing nothing, for an intensity below 0, a rotation that isn't finite, or a blur outside 0 to 1. */
	public function setMapAndBackground(map:Null<EnvironmentMap3D>, intensity = 1., rotation = 0., blur = 0.):Bool {
		if (!(intensity >= 0) || !Math.isFinite(rotation) || !(blur >= 0 && blur <= 1))
			return false;
		setMap(map, intensity, rotation);
		setBackground(map, blur);
		return true;
	}

	/** Sets the environment map `Batch3D.drawBackground` shows behind everything, turned and as bright as `setMap` says.

		@param map  The map, or null for none.
		@param blur  Optional. 0 sharp to 1 its blurriest; defaults to 0.
		@return  False, changing nothing, for a blur outside 0 to 1. */
	public function setBackground(map:Null<EnvironmentMap3D>, blur = 0.):Bool {
		if (!(blur >= 0 && blur <= 1))
			return false;
		background = map;
		backgroundBlur = blur;
		return true;
	}
}
