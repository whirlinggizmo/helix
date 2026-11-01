package helix.ray.internal;

/** Holds a mesh's GPU buffers, shared by the copies of one model's mesh however often the model is loaded: by raylib's buffer index,
	positions, texture coordinates, normals, colors, tangents and second texture coordinates (0 for one not made yet), null until the
	mesh is first drawn or `UploadMesh` sends it; and the indices (0 for none). */
@:noCompletion
class MeshGpu {
	/** The vertex buffers, by raylib's buffer index, or null until uploaded. */
	public var buffers:Null<Array<Int>> = null;

	/** The index buffer, or 0 for none. */
	public var indexBuffer = 0;

	/** The bytes of each buffer `UpdateMeshBuffer` has changed, by raylib's buffer index (6 for the indices), so the next change starts
		from them; null for one not changed. */
	public final contents:Array<Null<haxe.io.Bytes>> = [for (_ in 0...7) null];

	/** Creates an empty holder. */
	public function new() {}
}
