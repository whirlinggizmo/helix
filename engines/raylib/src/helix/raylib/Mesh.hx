package helix.raylib;

/** Represents raylib's `Mesh`: vertices, and the indices of its triangles when it has them. `Raylib.UploadMesh` sends them to the GPU;
	`extras.Models.LoadModelAsync` and the `GenMesh*` functions do it themselves.

	It is counted (docs/DECISIONS.md 25): the program holds it from `new` or a `GenMesh*` function until `UnloadMesh`, and each model
	whose `meshes` holds it holds it too. When the last lets go, its GPU buffers are freed. */
class Mesh {
	// Its holders: the program until UnloadMesh, and each model whose meshes holds it. At 0 its GPU buffers go (`Models.releaseMesh`).
	@:allow(helix.raylib)
	var refs = 1;

	/** Gets or sets the number of vertices. */
	public var vertexCount:Int = 0;

	/** Gets or sets the number of triangles. */
	public var triangleCount:Int = 0;

	/** Gets or sets the positions, x, y and z a vertex. */
	public var vertices:Null<Array<Float>> = null;

	/** Gets or sets the texture coordinates, u and v a vertex, or null for none. */
	public var texcoords:Null<Array<Float>> = null;

	/** Gets or sets the second texture coordinates, u and v a vertex, or null for none. */
	public var texcoords2:Null<Array<Float>> = null;

	/** Gets or sets the normals, x, y and z a vertex, or null for none. */
	public var normals:Null<Array<Float>> = null;

	/** Gets or sets the tangents, x, y, z and w a vertex (w is 1 or -1, the way the bitangent turns), or null for none. `GenMeshTangents`
		makes them. */
	public var tangents:Null<Array<Float>> = null;

	/** Gets or sets the colors, r, g, b and a a vertex, 0 to 255, or null for white. */
	public var colors:Null<Array<Int>> = null;

	/** Gets or sets the indices, three a triangle, or null for vertices taken three at a time. */
	public var indices:Null<Array<Int>> = null;

	/** Gets or sets the positions `UpdateModelAnimation` last moved its vertices to, x, y and z a vertex, or null until it has.

		They are worked out on the CPU when first read after a call that moved them, from the pose that call left, as raylib's
		`UpdateModelAnimation` moves them; a draw doesn't read them, but for a mesh drawn through the CPU path (see
		`UpdateModelAnimation`), or in wire or point mode. */
	@:isVar public var animVertices(get, default):Null<Array<Float>>;

	/** Gets or sets the normals `UpdateModelAnimation` last turned its vertices' to, or null until it has (or for a mesh without
		normals). Each is moved by its bones' matrices inverted and transposed, and not normalized, as raylib's; like `animVertices`,
		they are worked out when first read. */
	@:isVar public var animNormals(get, default):Null<Array<Float>>;

	/** Gets or sets the bones each vertex follows, four a vertex, as indices into its model's `bones` (0 to 255), or null for none. A
		shader reads them as the attribute `vertexBoneIds` (raylib 5.5's name) or `vertexBoneIndices` (6.2's), floats. */
	public var boneIds:Null<Array<Int>> = null;

	/** Gets or sets how much each of a vertex's four bones moves it, or null for none: the attribute `vertexBoneWeights`. */
	public var boneWeights:Null<Array<Float>> = null;

	/** Gets or sets the bones' matrices, by bone, each taking a vertex from where the skin was bound to where the bone is now:
		`UpdateModelAnimationBones` sets them, and a shader declaring `uniform mat4 boneMatrices[N]` is given them as the mesh is drawn.
		Shared by a model's meshes; null for a mesh without bones. A shader including `<helix/raylib/shaders/skinning.glsl>` reads the
		pose the model was given at its last `UpdateModelAnimation` or `UpdateModelAnimationBones`, not this array as it is drawn, so
		giving one model's array to another model's meshes doesn't pose them: pose each model. */
	public var boneMatrices:Null<Array<Matrix>> = null;

	/** Gets or sets the number of bones, its model's. */
	public var boneCount:Int = 0;

	// The pose UpdateModelAnimation last left it in (Skinning), null until a call poses it.
	@:allow(helix.raylib)
	var pose:Null<helix.raylib.internal.MeshPose> = null;

	// Works out animVertices and animNormals from the pose: set by the first UpdateModelAnimation, as only it makes a pose.
	@:allow(helix.raylib)
	static var posing:Mesh->Void;

	function get_animVertices():Null<Array<Float>> {
		if (pose != null)
			posing(this);
		return animVertices;
	}

	function get_animNormals():Null<Array<Float>> {
		if (pose != null)
			posing(this);
		return animNormals;
	}

	// Its GPU buffers, shared with the copies of the same mesh when its model is loaded again.
	@:allow(helix.raylib)
	var gpu = new helix.raylib.internal.MeshGpu();

	/** Creates an empty mesh. */
	public function new() {}
}
