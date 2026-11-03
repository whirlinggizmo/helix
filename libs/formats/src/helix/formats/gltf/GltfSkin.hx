package helix.formats.gltf;

import helix.math.Matrix3D;

/** Represents a glTF skin: the nodes a skinned mesh's vertices follow, and how the mesh was bound to them. */
class GltfSkin {
	/** Gets its name: empty when the file gives none. */
	public final name:String;

	/** Gets the indices of its joints in `GltfFile.nodes`; a vertex's `GltfPrimitive.jointIndices` index this. */
	public final jointIndices:Array<Int>;

	/** Gets each joint's inverse bind matrix, taking a vertex from the mesh's space to the joint's at rest; identities when the file gives
		none. */
	public final inverseBindMatrices:Array<Matrix3D>;

	/** Gets the node at the skeleton's root, an index into `GltfFile.nodes`, or -1 when the file names none. */
	public final skeletonIndex:Int;

	@:allow(helix.formats.gltf)
	function new(name:String, jointIndices:Array<Int>, inverseBindMatrices:Array<Matrix3D>, skeletonIndex:Int) {
		this.name = name;
		this.jointIndices = jointIndices;
		this.inverseBindMatrices = inverseBindMatrices;
		this.skeletonIndex = skeletonIndex;
	}
}
