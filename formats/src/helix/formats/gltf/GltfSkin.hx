package helix.formats.gltf;

import helix.math.Matrix3D;

/** Represents a glTF skin: the nodes a skinned mesh's vertices follow, and how the mesh was bound to them. */
class GltfSkin {
	/** Gets its name: empty when the file gives none. */
	public final name:String;

	/** Gets its joints, as indices into `GltfFile.nodes`; a vertex's `GltfPrimitive.joints` index this. */
	public final joints:Array<Int>;

	/** Gets each joint's inverse bind matrix, taking a vertex from the mesh's space to the joint's at rest; identities when the file gives
		none. */
	public final inverseBindMatrices:Array<Matrix3D>;

	/** Gets the node at the skeleton's root, an index into `GltfFile.nodes`, or -1 when the file names none. */
	public final skeleton:Int;

	@:allow(helix.formats.gltf)
	function new(name:String, joints:Array<Int>, inverseBindMatrices:Array<Matrix3D>, skeleton:Int) {
		this.name = name;
		this.joints = joints;
		this.inverseBindMatrices = inverseBindMatrices;
		this.skeleton = skeleton;
	}
}
