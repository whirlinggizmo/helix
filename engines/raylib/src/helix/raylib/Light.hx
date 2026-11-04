package helix.raylib;

/** Represents rlights' `Light` (raylib's examples' `rlights.h`): a light of a lit shader, made by `CreateLight` and set again by
	`UpdateLightValues` (`helix.raylib.extras.Lights`) after a field changes. */
class Light {
	/** Gets or sets its type: `LIGHT_DIRECTIONAL` or `LIGHT_POINT`. */
	public var type:Int = 0;

	/** Gets or sets a value indicating whether it shines. */
	public var enabled:Bool = false;

	/** Gets or sets where it is. */
	public var position:Vector3 = new Vector3(0, 0, 0);

	/** Gets or sets where it points, for a directional light. */
	public var target:Vector3 = new Vector3(0, 0, 0);

	/** Gets or sets its color. */
	public var color:Color = new Color(0, 0, 0, 0);

	/** Gets or sets its attenuation, which rlights keeps and its shader doesn't read. */
	public var attenuation:Float = 0;

	/** Gets or sets the location of its `enabled` in its shader. */
	public var enabledLoc:Int = 0;

	/** Gets or sets the location of its `type`. */
	public var typeLoc:Int = 0;

	/** Gets or sets the location of its `position`. */
	public var positionLoc:Int = 0;

	/** Gets or sets the location of its `target`. */
	public var targetLoc:Int = 0;

	/** Gets or sets the location of its `color`. */
	public var colorLoc:Int = 0;

	/** Gets or sets the location of its `attenuation`, which rlights never finds. */
	public var attenuationLoc:Int = 0;

	/** Creates a light that is off, every field 0, as C's `Light light = { 0 }`. Lights are made by `CreateLight`. */
	public function new() {}
}
