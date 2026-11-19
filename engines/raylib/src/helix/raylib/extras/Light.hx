package helix.raylib.extras;

import helix.raylib.*;

/** Represents one light of the scene, the Lighting extra's, with the fields of `Light` in raylib's examples' `rlights.h`.

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

	/** Gets or sets how bright the light is (the Lighting extra's): its color times the intensity. Clamped to 0 or more; 1 by
		default. 0 makes no light, as `enabled` false does. */
	public var intensity:Float = 1;

	/** Gets or sets how far a point or spot light reaches, in world units (the Lighting extra's). The light dims with distance, fading
		to nothing at the range, and lights no draw whose bounds lie past it. Clamped to 0 or more; 0 by default, for no falloff and no
		limit. A directional light has no range. */
	public var range:Float = 0;

	/** Gets or sets a spot light's inner angle, in degrees from the cone's middle (the Lighting extra's `LIGHT_SPOT`): the cone is full
		inside it and fades toward `outerAngle`. Clamped to 0 to `outerAngle`; 30 by default. */
	public var innerAngle:Float = 30;

	/** Gets or sets a spot light's outer angle, in degrees from the cone's middle (the Lighting extra's `LIGHT_SPOT`): the cone fades to
		nothing there. Clamped to 0 to 89.9; 45 by default. */
	public var outerAngle:Float = 45;

	/** Gets the light's shadow options (the Lighting extra's): how its shadows are made, each field its default until set. Each shadow
		pass reads the fields, and a field set applies at the next pass, whether or not the light casts shadows yet. See
		`EnableLightShadows` for turning the light's shadows on. */
	public var shadows(get, null):ShadowOptions;

	// Whether it casts shadows (EnableLightShadows), and its shadows' index in the frame's shadows plus 1, 0 while it casts none
	// (Shadows).
	@:allow(helix.raylib)
	var shadowCasting = false;
	@:allow(helix.raylib)
	var shadowIndex = 0;

	/** Creates a light that is off, each of rlights' fields 0, as C's `Light light = { 0 }`. See `CreateLight` for making a light of the scene. */
	public function new() {}

	// The shadow options, made when first read, so a program that never reads them links none of them.
	function get_shadows():ShadowOptions {
		if (shadows == null)
			shadows = new ShadowOptions();
		return shadows;
	}
}
