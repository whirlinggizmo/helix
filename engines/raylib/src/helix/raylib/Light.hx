package helix.raylib;

/** Represents rlights' `Light` (raylib's examples' `rlights.h`): one light of the scene.

	Made by `CreateLight`. Its fields are read at each draw, so a light changes by setting them. */
class Light {
	/** Gets or sets the light's type: `LIGHT_DIRECTIONAL`, `LIGHT_POINT`, or the Lighting extra's `LIGHT_SPOT`. */
	public var type:Int = 0;

	/** Gets or sets a value indicating whether the light shines. */
	public var enabled:Bool = false;

	/** Gets or sets the light's position. */
	public var position:Vector3 = new Vector3(0, 0, 0);

	/** Gets or sets the target: the point a directional or spot light shines toward. */
	public var target:Vector3 = new Vector3(0, 0, 0);

	/** Gets or sets the light's color. */
	public var color:Color = new Color(0, 0, 0, 0);

	/** Gets or sets the attenuation, which rlights keeps and its shader ignores. */
	public var attenuation:Float = 0;

	/** Gets or sets rlights' location of `enabled` in its shader. helix-raylib reads the light's fields at each draw instead. */
	public var enabledLoc:Int = 0;

	/** Gets or sets rlights' location of `type`. */
	public var typeLoc:Int = 0;

	/** Gets or sets rlights' location of `position`. */
	public var positionLoc:Int = 0;

	/** Gets or sets rlights' location of `target`. */
	public var targetLoc:Int = 0;

	/** Gets or sets rlights' location of `color`. */
	public var colorLoc:Int = 0;

	/** Gets or sets the location of `attenuation`, which rlights never finds. */
	public var attenuationLoc:Int = 0;

	// The Lighting extra's values: how bright (its color times this), how far it reaches (0 for no limit), and a spot light's cone, the
	// cosines of its inner and outer angles.
	@:allow(helix.raylib)
	var intensity = 1.;
	@:allow(helix.raylib)
	var range = 0.;
	@:allow(helix.raylib)
	var innerCosine = 1.;
	@:allow(helix.raylib)
	var outerCosine = 1.;

	/** Creates a light that is off, each of rlights' fields 0, as C's `Light light = { 0 }`. See `CreateLight` for making a light of the scene. */
	public function new() {}
}
