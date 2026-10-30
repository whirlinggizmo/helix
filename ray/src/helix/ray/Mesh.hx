package helix.ray;

/** Represents raylib's `Mesh`: vertices, and the indices of its triangles when it has them. `Raylib.UploadMesh` sends them to the GPU;
	`Raylib.LoadModel` and the `GenMesh*` functions do it themselves. */
class Mesh {
	/** Gets or sets the number of vertices. */
	public var vertexCount:Int = 0;

	/** Gets or sets the number of triangles. */
	public var triangleCount:Int = 0;

	/** Gets or sets the positions, x, y and z a vertex. */
	public var vertices:Null<Array<Float>> = null;

	/** Gets or sets the texture coordinates, u and v a vertex, or null for none. */
	public var texcoords:Null<Array<Float>> = null;

	/** Gets or sets the normals, x, y and z a vertex, or null for none. */
	public var normals:Null<Array<Float>> = null;

	/** Gets or sets the colors, r, g, b and a a vertex, 0 to 255, or null for white. */
	public var colors:Null<Array<Int>> = null;

	/** Gets or sets the indices, three a triangle, or null for vertices taken three at a time. */
	public var indices:Null<Array<Int>> = null;

	// Its GPU buffers once uploaded: positions, texture coordinates, normals, colors, and the indices (0 for none).
	@:allow(helix.ray)
	var buffers:Null<Array<Int>> = null;
	@:allow(helix.ray)
	var indexBuffer = 0;

	/** Creates an empty mesh. */
	public function new() {}
}
