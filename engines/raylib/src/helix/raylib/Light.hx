package helix.raylib;

/** Represents rlights' `Light` (raylib's examples' `rlights.h`): one light of a lit shader.

	Made by `CreateLight`.

	`UpdateLightValues` (`helix.raylib.extras.Lights`) sends a changed field to the shader. */
class Light {
	/** Gets or sets the light's type: `LIGHT_DIRECTIONAL` or `LIGHT_POINT`. */
	public var type:Int = 0;

	/** Gets or sets a value indicating whether the light shines. */
	public var enabled:Bool = false;

	/** Gets or sets the light's position. */
	public var position:Vector3 = new Vector3(0, 0, 0);

	/** Gets or sets the target, the point setting a directional light's direction. */
	public var target:Vector3 = new Vector3(0, 0, 0);

	/** Gets or sets the light's color. */
	public var color:Color = new Color(0, 0, 0, 0);

	/** Gets or sets the attenuation, which rlights keeps and its shader ignores. */
	public var attenuation:Float = 0;

	/** Gets or sets the location of `enabled` in the light's shader. */
	public var enabledLoc:Int = 0;

	/** Gets or sets the location of `type`. */
	public var typeLoc:Int = 0;

	/** Gets or sets the location of `position`. */
	public var positionLoc:Int = 0;

	/** Gets or sets the location of `target`. */
	public var targetLoc:Int = 0;

	/** Gets or sets the location of `color`. */
	public var colorLoc:Int = 0;

	/** Gets or sets the location of `attenuation`, which rlights never finds. */
	public var attenuationLoc:Int = 0;

	/** Creates a light that is off, every field 0, as C's `Light light = { 0 }`. See `CreateLight` for making a light that shines. */
	public function new() {}
}
