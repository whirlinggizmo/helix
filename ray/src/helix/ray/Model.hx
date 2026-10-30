package helix.ray;

/** Represents raylib's `Model`: meshes, materials, which material each mesh draws with, and a transform. */
class Model {
	/** Gets or sets the transform applied before `DrawModel`'s position, rotation and scale. */
	public var transform:Matrix;

	/** Gets the number of meshes. */
	public var meshCount:Int;

	/** Gets the number of materials. */
	public var materialCount:Int;

	/** Gets the meshes. */
	public var meshes:Array<Mesh>;

	/** Gets the materials. */
	public var materials:Array<Material>;

	/** Gets the material of each mesh, by its index in `materials`. */
	public var meshMaterial:Array<Int>;

	// The file it was loaded from, sharing its GPU data with the file's other loads, or "" for a model of a mesh.
	@:allow(helix.ray)
	var path = "";

	/** Creates a model. Models are made by `Raylib.LoadModel` and `Raylib.LoadModelFromMesh`.

		@param meshes  The meshes.
		@param materials  The materials.
		@param meshMaterial  Each mesh's material. */
	public function new(meshes:Array<Mesh>, materials:Array<Material>, meshMaterial:Array<Int>) {
		transform = new Matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
		this.meshes = meshes;
		this.materials = materials;
		this.meshMaterial = meshMaterial;
		meshCount = meshes.length;
		materialCount = materials.length;
	}
}
