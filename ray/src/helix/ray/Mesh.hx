package helix.ray;

/** Represents raylib's `Mesh`: vertices, and the indices of its triangles when it has them. `Raylib.UploadMesh` sends them to the GPU;
	`Raylib.LoadModelAsync` and the `GenMesh*` functions do it themselves. */
class Mesh {
	/** Gets or sets the number of vertices. */
	public var vertexCount:Int = 0;

	/** Gets or sets the number of triangles. */
	public var triangleCount:Int = 0;

	/** Gets or sets the positions, x, y and z a vertex. */
	public var vertices:Null<Array<Float>> = null;

	/** Gets or sets the texture coordinates, u and v a vertex, or null for none. */
	public var texcoords:Null<Array<Float>> = null;

	/** Gets or sets the second texture coordinates, u and v a vertex, or null for none. */
	public var texcoords2:Null<Array<Float>> = null;

	/** Gets or sets the normals, x, y and z a vertex, or null for none. */
	public var normals:Null<Array<Float>> = null;

	/** Gets or sets the tangents, x, y, z and w a vertex (w is 1 or -1, the way the bitangent turns), or null for none. `GenMeshTangents`
		makes them. */
	public var tangents:Null<Array<Float>> = null;

	/** Gets or sets the colors, r, g, b and a a vertex, 0 to 255, or null for white. */
	public var colors:Null<Array<Int>> = null;

	/** Gets or sets the indices, three a triangle, or null for vertices taken three at a time. */
	public var indices:Null<Array<Int>> = null;

	// Its GPU buffers, shared with the copies of the same mesh when its model is loaded again.
	@:allow(helix.ray)
	var gpu = new helix.ray.internal.MeshGpu();

	/** Creates an empty mesh. */
	public function new() {}
}
