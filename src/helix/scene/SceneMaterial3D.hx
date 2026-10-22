package helix.scene;

/** A material as a .scene3d file writes it inline on a Model3D: Material3D's values, each null when the file doesn't say it, so an override
	changes one value and leaves the rest. */
class SceneMaterial3D {
	/** The base color, 0xAARRGGBB; null for unsaid. */
	public var baseColor:Null<Int>;

	/** How metallic, 0..1; null for unsaid. */
	public var metallic:Null<Float>;

	/** How rough, 0..1; null for unsaid. */
	public var roughness:Null<Float>;

	/** The base color texture's path; null for unsaid. */
	public var texture:Null<String>;

	/** The normal map's path; null for unsaid. */
	public var normalTexture:Null<String>;

	/** How strongly the normal map bends the surface, 0 or more; null for unsaid. */
	public var normalScale:Null<Float>;

	/** The light it gives off, 0xAARRGGBB; null for unsaid. */
	public var emissive:Null<Int>;

	/** How bright its emissive light is, 0 or more; null for unsaid. */
	public var emissiveStrength:Null<Float>;

	/** Whether both sides of its triangles draw; null for unsaid. */
	public var doubleSided:Null<Bool>;

	/** A material saying nothing. */
	public function new() {}
}
