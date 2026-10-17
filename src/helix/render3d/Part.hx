package helix.render3d;

/** One piece of a Model: a mesh drawn with a material (a glTF primitive). A model's parts move together, as its node; each draws with the
	models alike in mesh and material. */
class Part {
	var mesh:Null<Mesh>;
	var material:Material;

	/** mesh (null for none yet: it draws nothing) drawn with material (a new white one when null). */
	public function new(mesh:Null<Mesh>, ?material:Material) {
		this.mesh = mesh;
		this.material = material != null ? material : new Material();
	}

	/** Its mesh, or null for none. */
	public function getMesh():Null<Mesh>
		return mesh;

	/** Gives it another mesh (null: it draws nothing). */
	public function setMesh(value:Null<Mesh>):Void
		mesh = value;

	/** Its material. */
	public function getMaterial():Material
		return material;

	/** Gives it another material. */
	public function setMaterial(value:Material):Void
		material = value;
}
