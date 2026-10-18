package helix.scene;

/** A generated mesh as a .scene file writes it on a Model ("mesh", in place of a file): the shape's name (plane, cube, sphere, cylinder,
	cone, capsule or torus: SceneSchema.shapes) and its numbers by the generator's own argument names (a plane's width, length and
	subdivisions; a sphere's radius, rings and segments), an optional one absent when the generator's default. */
class SceneMesh {
	/** The shape's name, one of SceneSchema.shapes. */
	public var shape:String;

	/** Its arguments by name, those said; one absent is the generator's default. */
	public var arguments:Map<String, Float> = new Map();

	/** A mesh of shape with no argument said yet. */
	public function new(shape:String)
		this.shape = shape;
}
