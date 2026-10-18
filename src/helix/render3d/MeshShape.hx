package helix.render3d;

/** What made a generated mesh (Mesh.shape): the generator's name, plane, cube, sphere, cylinder, cone, capsule or torus, and its
	arguments as it was called, by the generator's own parameter names (a plane's width, length and subdivisions; a sphere's radius, rings
	and segments), the ones left at their defaults included, a count as a whole number. A scene file writes a Model's generated mesh from
	it; a mesh from arrays or from a file has none. */
class MeshShape {
	/** The generator's name: plane, cube, sphere, cylinder, cone, capsule or torus. */
	public final name:String;

	/** Its arguments by the generator's parameter names, every one said, as the generator was called (before any clamping). */
	public final arguments:Map<String, Float>;

	/** The record of a call of the generator name with arguments. */
	public function new(name:String, arguments:Map<String, Float>) {
		this.name = name;
		this.arguments = arguments;
	}
}
