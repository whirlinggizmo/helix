package helix.render3d;

/** One piece of a Model3D: a mesh drawn with a material (a glTF primitive). A model's parts move together, as its node; each draws with the
	models alike in mesh and material. */
class Part3D {
	/** mesh (null for none yet: it draws nothing) drawn with material (a new white one when null). */
	public function new(mesh:Null<Mesh3D>, ?material:Material3D) {
		this.mesh = mesh;
		this.material = material != null ? material : new Material3D();
	}

	/** Its mesh, or null for none. */
	public var mesh:Null<Mesh3D>;

	/** Its material. */
	public var material:Material3D;
}
