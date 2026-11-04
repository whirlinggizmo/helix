package helix.render;

/** Represents a light that a `Batch3D` lights its lit materials with: a `DirectionalLight3D`, a `PointLight3D`, a `SpotLight3D` or a
	`HemisphereLight3D`.

	A program makes its lights and puts them in `Batch3D.lights`; each `begin` reads them as they are then. Its color is 0xAARRGGBB, its
	alpha ignored, decoded from sRGB and multiplied by its intensity into the light's radiance, which the shaders work in.

	**Intensity** is in three.js's units, so a three.js layer passes its lights' through: a directional or hemisphere light's is the
	light falling on a surface facing it; a point or spot light's is that light at 1 world unit, falling off with the square of the
	distance. Every light starts at π, at which a white surface facing it (a point or spot light 1 unit away) shows white, as a
	surface's diffuse light is its light over π.

	A directional, spot or point light casts shadows while `castsShadow` is set, as its `shadow` says; at most 4 lights of a batch cast,
	the first 4 casting in `lights`. A hemisphere light casts none.

	**What links the lighting.** Making a light, setting an ambient light (`Environment3D.setAmbient`), writing a lit
	`Material3D.shading`, an emissive color or a light map, or compiling a shader that reads the lighting links the lit shaders. A
	program that does none of them links none of it, and a lit material there is drawn as no light leaves it: black, its alpha kept. */
abstract class Light3D {
	/** Gets or sets its color: white until set. */
	public var color:Int = 0xffffffff;

	/** Gets or sets its intensity, a multiplier of its color, in the units the class says: π until set. Below 0 is clamped to 0. */
	public var intensity(default, set):Float = Math.PI;

	/** Gets or sets a value indicating whether it casts shadows: false until set, as a shadow map costs a pass and memory. Ignored for a
		hemisphere light. */
	public var castsShadow:Bool = false;

	/** Gets how its shadows are made, while it casts them. */
	public final shadow = new LightShadow3D();

	function new() {
		BatchLighting.install();
	}

	function set_intensity(value:Float):Float {
		return intensity = Math.max(0, value);
	}

	// Writes the light as the shaders read it, sixteen floats from an index: its position (w its range), its direction (w its kind: 0
	// directional, 1 point, 2 spot, 3 hemisphere), its radiance, and its cones' cosines (z its shadow, -1 for none). A hemisphere
	// light's ground radiance is its position.

	@:allow(helix.render)
	abstract function writeLight(out:Array<Float>, at:Int):Void;

	// Writes a color times an intensity as linear radiance, three floats from an index, and a 0.

	@:allow(helix.render)
	static function writeRadiance(color:Int, intensity:Float, out:Array<Float>, at:Int):Void {
		for (k in 0...3) {
			var c = (color >> (16 - k * 8) & 255) / 255;
			out[at + k] = (c <= .04045 ? c / 12.92 : Math.pow((c + .055) / 1.055, 2.4)) * intensity;
		}
		out[at + 3] = 0;
	}

	// Writes a direction made of length 1, straight down for one of length 0, and a kind, four floats from an index.

	@:allow(helix.render)
	static function writeDirection(x:Float, y:Float, z:Float, kind:Int, out:Array<Float>, at:Int):Void {
		var length = Math.sqrt(x * x + y * y + z * z);
		if (length > 0) {
			out[at] = x / length;
			out[at + 1] = y / length;
			out[at + 2] = z / length;
		} else {
			out[at] = 0;
			out[at + 1] = -1;
			out[at + 2] = 0;
		}
		out[at + 3] = kind;
	}

	// Writes a point and a range, four floats from an index.

	@:allow(helix.render)
	static function writePoint(x:Float, y:Float, z:Float, range:Float, out:Array<Float>, at:Int):Void {
		out[at] = x;
		out[at + 1] = y;
		out[at + 2] = z;
		out[at + 3] = range;
	}
}
