package helix.services.models;

/** Represents one of a model's meshes as `Models` reads it: triangles, its node's transform already in its positions and normals. */
class Mesh3D {
	/** Gets the positions, x, y and z each. */
	public final positions:Array<Float>;

	/** Gets the normals, x, y and z each, unit length; null when the file has none. */
	public final normals:Null<Array<Float>>;

	/** Gets the texture coordinates, u and v each; null when the file has none. */
	public final texCoords:Null<Array<Float>>;

	/** Gets the colors, red, green, blue and alpha each, 0 to 1; null when the file has none. */
	public final colors:Null<Array<Float>>;

	/** Gets the indices, three a triangle; null when the positions are the triangles in order. */
	public final indices:Null<Array<Int>>;

	/** Gets the material's index in `Model3D.materials`, or -1 for none. */
	public final material:Int;

	@:allow(helix.services.models)
	function new(positions:Array<Float>, normals:Null<Array<Float>>, texCoords:Null<Array<Float>>, colors:Null<Array<Float>>, indices:Null<Array<Int>>,
			material:Int) {
		this.positions = positions;
		this.normals = normals;
		this.texCoords = texCoords;
		this.colors = colors;
		this.indices = indices;
		this.material = material;
	}
}
