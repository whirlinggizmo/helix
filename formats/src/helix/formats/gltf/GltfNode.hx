package helix.formats.gltf;

import helix.math.Matrix3D;
import helix.math.Transform3D;

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

	/** Gets the node's translation, rotation and scale relative to its parent: as the file gives them, or its matrix taken apart; an
		animation's channels replace these. */
	public final local:Transform3D;

	/** Gets the index of the node's skin in `GltfFile.skins`, or -1 when it has none. */
	public final skin:Int;

	@:allow(helix.formats.gltf)
	function new(name:String, mesh:Int, children:Array<Int>, transform:Matrix3D, local:Transform3D, skin:Int) {
		this.name = name;
		this.mesh = mesh;
		this.children = children;
		this.transform = transform;
		this.local = local;
		this.skin = skin;
	}
}
