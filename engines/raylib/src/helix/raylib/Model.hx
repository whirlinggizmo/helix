package helix.raylib;

/** Represents raylib's `Model`: meshes, materials, each mesh's material, and a transform.

	Holds a reference to each of its meshes and materials, released by `UnloadModel` or by replacing them. */
class Model {
	/** Gets or sets the transform applied before `DrawModel`'s position, rotation and scale. */
	public var transform:Matrix;

	/** Gets the number of meshes, set when `meshes` is. */
	public var meshCount:Int;

	/** Gets the number of materials, set when `materials` is. */
	public var materialCount:Int;

	/** Gets or sets the meshes, each held by the model.

		Setting copies the array, retains its meshes, releases the ones it replaces and sets `meshCount`. */
	public var meshes(default, set):ModelMeshes;

	/** Gets or sets the materials, each held by the model.

		Setting copies the array, retains its materials, releases the ones it replaces and sets `materialCount`. */
	public var materials(default, set):ModelMaterials;

	/** Gets the material of each mesh, by its index in `materials`. */
	public var meshMaterial:Array<Int>;

	/** Gets the number of bones, the joints of the file's first skin, or 0 for a model without one. */
	public var boneCount:Int = 0;

	/** Gets the bones, or null without a skin.

		The file's first skin's joints, in its order, each parent the nearest joint above it. */
	public var bones:Null<Array<BoneInfo>> = null;

	/** Gets each bone's transform in the model as the skin was bound to it, or null without a skin.

		Each is its inverse bind matrix inverted, or its node's at rest for a file that gives none. */
	public var bindPose:Null<Array<Transform>> = null;

	// The pose UpdateModelAnimation last set, by bone (raylib 6.2's currentPose); null until a call sets it (Animations.setPose), so a
	// model never posed is the one without it.
	@:allow(helix.raylib)
	var pose:Null<Array<Transform>> = null;

	// The bone matrices UpdateModelAnimation last computed, each skinned mesh's boneMatrices (raylib 6.2's model.boneMatrices); null
	// without bones.
	@:allow(helix.raylib)
	var boneMatrices:Null<Array<Matrix>> = null;

	// Each bone's bind pose inverted, as the animations last needed it, and the bind pose's numbers it was made from (Animations).
	@:allow(helix.raylib)
	var inverseBinds:Array<Null<helix.math.Matrix3D>> = [];

	@:allow(helix.raylib)
	var inverseBindKeys:Array<Float> = [];

	// The file it was loaded from, sharing its GPU data with the file's other loads, or "" for a model of a mesh.
	@:allow(helix.raylib)
	var path = "";

	/** Creates a model holding the meshes and materials. See `extras.Models.LoadModelAsync` for loading a model, and
		`Raylib.LoadModelFromMesh` for making one of a mesh.

		@param meshes  The meshes.
		@param materials  The materials.
		@param meshMaterial  Each mesh's material. */
	public function new(meshes:Array<Mesh>, materials:Array<Material>, meshMaterial:Array<Int>) {
		transform = new Matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
		this.meshes = meshes;
		this.materials = materials;
		this.meshMaterial = meshMaterial;
	}

	function set_meshes(value:ModelMeshes):ModelMeshes {
		var next = value == null ? [] : (cast value : Array<Mesh>).copy();
		for (m in next)
			helix.raylib.internal.Models.retainMesh(m);
		var old = meshes;
		meshes = next;
		if (old != null)
			for (m in old)
				helix.raylib.internal.Models.releaseMesh(m);
		meshCount = next.length;
		return meshes;
	}

	function set_materials(value:ModelMaterials):ModelMaterials {
		var next = value == null ? [] : (cast value : Array<Material>).copy();
		for (m in next)
			helix.raylib.internal.Models.retainMaterial(m);
		var old = materials;
		materials = next;
		if (old != null)
			for (m in old)
				helix.raylib.internal.Models.releaseMaterial(m);
		materialCount = next.length;
		return materials;
	}
}
