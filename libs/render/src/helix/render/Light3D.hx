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
	the first 4 casting in `lights`. A hemisphere light casts none. */
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

	function new() {}

	function set_intensity(value:Float):Float {
		return intensity = Math.max(0, value);
	}
}
