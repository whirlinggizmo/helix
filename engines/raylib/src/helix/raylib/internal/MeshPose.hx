package helix.raylib.internal;

/** Holds the pose `UpdateModelAnimation` left a mesh in (`Skinning`), made by the first call that poses the mesh. A structure, not a
	class, so `Mesh.pose`, which every program drawing a mesh links, links no class of it. */
@:noCompletion
typedef MeshPose = {
	/** The bone matrices, 16 floats a bone, column by column: one array shared by the meshes one call posed, as a model's meshes are
		posed by the same bones. */
	var bones:Array<Float>;

	/** Which call posed it: equal for the meshes one call posed, so a frame's palette holds their bones once. */
	var stamp:Int;

	/** Whether the pose changed since `Mesh.animVertices` and `animNormals` were worked out: true only for a mesh raylib skins on the CPU. */
	var changed:Bool;

	/** The weights last read for whether any vertex has a bone of some weight. */
	var weightsRead:Null<Array<Float>>;

	/** Whether any of those weights is above 0. */
	var weighted:Bool;

	/** The position buffer the CPU path draws (0 for none), freed once its frame is drawn. */
	var positionBuffer:Int;

	/** The normal buffer the CPU path draws (0 for none), freed once its frame is drawn. */
	var normalBuffer:Int;

	/** The frame those buffers were made in (`Skinning`'s count), -1 when the pose changed since. */
	var buffersFrame:Int;
}
