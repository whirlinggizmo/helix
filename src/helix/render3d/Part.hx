package helix.render3d;

/** One piece of a Model: a mesh drawn with a material (a glTF primitive). A model's parts move together, as its node; each draws with the
	models alike in mesh and material. */
class Part {
	/** mesh (null for none yet: it draws nothing) drawn with material (a new white one when null). */
	public function new(mesh:Null<Mesh>, ?material:Material) {
		this.mesh = mesh;
		this.material = material != null ? material : new Material();
	}

	/** Its mesh, or null for none. */
	public var mesh:Null<Mesh>;

	/** Its material. */
	public var material:Material;
}
