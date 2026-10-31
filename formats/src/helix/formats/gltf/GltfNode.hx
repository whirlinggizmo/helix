package helix.formats.gltf;

import helix.math.Matrix3D;

/** Represents one node of a glTF model: its name, its mesh, its children and its transform relative to its parent.

	A node is read from the file's `nodes`, as `GltfFile.nodes` lists them; its children and its mesh are indices into `GltfFile.nodes`
	and `GltfFile.meshes`. A node's world transform is its own composed with its ancestors', from a root in `GltfFile.scene` down. */
class GltfNode {
	/** Gets the node's name: empty when the file gives none. */
	public final name:String;

	/** Gets the index of the node's mesh in `GltfFile.meshes`, or -1 when it has none. */
	public final mesh:Int;

	/** Gets the indices of the node's children in `GltfFile.nodes`: empty when it has none. */
	public final children:Array<Int>;

	/** Gets the node's transform relative to its parent: its `matrix`, or its scale, then rotation, then translation, applied in that
		order. Identity when the file gives none. */
	public final transform:Matrix3D;

	@:allow(helix.formats.gltf)
	function new(name:String, mesh:Int, children:Array<Int>, transform:Matrix3D) {
		this.name = name;
		this.mesh = mesh;
		this.children = children;
		this.transform = transform;
	}
}
