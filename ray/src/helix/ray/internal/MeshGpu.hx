package helix.ray.internal;

/** Holds a mesh's GPU buffers, shared by the copies of one model's mesh however often the model is loaded: positions, texture
	coordinates, normals, colors, and the indices (0 for none), null until the mesh is first drawn or `UploadMesh` sends it. */
@:noCompletion
class MeshGpu {
	/** The vertex buffers, by raylib's attribute order, or null until uploaded. */
	public var buffers:Null<Array<Int>> = null;

	/** The index buffer, or 0 for none. */
	public var indexBuffer = 0;

	/** Creates an empty holder. */
	public function new() {}
}
