package helix.scene;

/** A .scene file's environment section: the place's light (helix.render3d.Environment3D), set on the node the file is instantiated as (its
	root group, or a prefab's node), lighting what's under it. Each null means the default and is not written. How a camera photographs the
	place (exposure, tone mapping) is the view's (View3D), not the file's. */
class SceneEnvironment {
	/** The ambient light's color, 0xAARRGGBB; null for white. */
	public var ambientColor:Null<Int>;

	/** The ambient light's intensity, 0 or more; null for 0. */
	public var ambientIntensity:Null<Float>;

	/** The environment map's file (an HDR, loaded through Environments), lighting and reflecting; null for none. */
	public var mapFile:Null<String>;

	/** How strongly the map lights, 1 as its file has it; null for 1. */
	public var mapIntensity:Null<Float>;

	/** How far the map and the background turn about +y, in radians; null for 0. */
	public var rotation:Null<Float>;

	/** The background's file (an HDR, loaded through Environments); null for none. */
	public var backgroundFile:Null<String>;

	/** How blurred the background is, 0 sharp to 1; null for 0. */
	public var backgroundBlur:Null<Float>;

	/** A section that says nothing. */
	public function new() {}
}
