package helix.ray.internal;

/** Holds a mesh's GPU buffers, shared by the copies of one model's mesh however often the model is loaded: by raylib's buffer index,
	positions, texture coordinates, normals, colors, tangents, second texture coordinates, then (at 7 and 8) bone ids and bone weights
	(0 for one not made yet, and at 6, where raylib keeps its indices), null until the mesh is first drawn or `UploadMesh` sends it; and
	the indices (0 for none).

	A copy whose vertices an animation moves takes a holder of its own (`Models.own`), its positions and normals its own, the rest still
	the shared holder's, listed in `borrowed` so it doesn't free them. */
@:noCompletion
class MeshGpu {
	/** The vertex buffers, by raylib's buffer index, or null until uploaded. */
	public var buffers:Null<Array<Int>> = null;

	/** The index buffer, or 0 for none. */
	public var indexBuffer = 0;

	/** The edges of its triangles, two indices each, for wire mode; 0 until first drawn so. */
	public var edgeBuffer = 0;

	/** The bytes of each buffer `UpdateMeshBuffer` or an animation has changed, by raylib's buffer index (6 for the indices), so the
		next change starts from them; null for one not changed. */
	public final contents:Array<Null<haxe.io.Bytes>> = [for (_ in 0...9) null];

	/** Whether the copies of a file's mesh share it, each load's (`Models.load`). */
	public var shared = false;

	/** The buffers it shares with the holder it was made from, which that holder frees; empty for a holder of its own. */
	public final borrowed:Array<Int> = [];

	/** How many meshes use it: the copies of a file's mesh, one a load; its buffers are freed when the last lets go
		(`Models.releaseMesh`). */
	public var holders = 1;

	/** The holder it borrows from (`Models.own`), which it keeps a mesh's hold on until it is freed itself; null for none. */
	public var source:Null<MeshGpu> = null;

	/** Creates an empty holder. */
	public function new() {}
}
