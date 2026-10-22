package helix.scene;

/** A .scene file's stage section: what a Stage3D keeps apart from its tree (its ambient light, environment, background, tone mapping and
	exposure). Each null means the stage's default and is not written. Only a file instantiated onto a stage applies it; a prefab's is logged
	and ignored. */
class SceneStage {
	/** The ambient light's color, 0xAARRGGBB; null for the stage's. */
	public var ambientColor:Null<Int>;

	/** The ambient light's intensity, 0 or more; null for the stage's. */
	public var ambientIntensity:Null<Float>;

	/** The environment's file (an HDR, loaded through Environments); null for none. */
	public var environmentFile:Null<String>;

	/** How strongly the environment lights, 1 as its file has it; null for the stage's. */
	public var environmentIntensity:Null<Float>;

	/** How far the environment and the background turn about +y, in radians; null for the stage's. */
	public var environmentRotation:Null<Float>;

	/** The background's file (an HDR, loaded through Environments); null for none. */
	public var backgroundFile:Null<String>;

	/** How blurred the background is, 0 sharp to 1; null for the stage's. */
	public var backgroundBlur:Null<Float>;

	/** The tone mapping, "none", "neutral" or "aces" (Tonemap's cases in lower case); null for the stage's. */
	public var tonemap:Null<String>;

	/** The exposure in stops; null for the stage's. */
	public var exposure:Null<Float>;

	/** A stage section saying nothing: every setting the stage's own. */
	public function new() {}
}
