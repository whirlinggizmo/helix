package helix.formats.gltf;

/** Represents one mesh of a glTF model: its name and its primitives, each drawn with a material of its own.

	A mesh is read from the file's `meshes`, as `GltfFile.meshes` lists them; nodes name it by its index there. */
class GltfMesh {
	/** Gets the mesh's name: empty when the file gives none. */
	public final name:String;

	/** Gets the mesh's primitives, in the file's order. */
	public final primitives:Array<GltfPrimitive>;

	@:allow(helix.formats.gltf)
	function new(name:String, primitives:Array<GltfPrimitive>) {
		this.name = name;
		this.primitives = primitives;
	}
}
