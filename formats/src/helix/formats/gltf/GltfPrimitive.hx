package helix.formats.gltf;

/** Represents one primitive of a glTF mesh: its vertices, read from their accessors, its indices and its material.

	Each attribute is every component of every vertex in order, as floats: a normalized integer is scaled to 0..1 when unsigned and
	-1..1 when signed, any other value is as the file has it. Positions, normals and tangents are in the mesh's own units: no node's
	transform is applied. Only the first set of texture coordinates (`TEXCOORD_0`), of colors (`COLOR_0`) and of joints and weights (`JOINTS_0`,
	`WEIGHTS_0`) is read. */
class GltfPrimitive {
	/** Gets what the primitive draws, glTF's `mode`: 0 points, 1 lines, 2 a line loop, 3 a line strip, 4 triangles, 5 a triangle strip,
		6 a triangle fan. Defaults to 4. */
	public final mode:Int;

	/** Gets the vertices' positions, `POSITION`: x, y and z for each vertex. Empty when the primitive has none. */
	public final positions:Array<Float>;

	/** Gets the vertices' normals, `NORMAL`: x, y and z for each vertex, or null when the primitive has none. */
	public final normals:Null<Array<Float>>;

	/** Gets the vertices' tangents, `TANGENT`: x, y, z and w for each vertex, w 1 or -1 for the bitangent's side, or null when the
		primitive has none. */
	public final tangents:Null<Array<Float>>;

	/** Gets the vertices' joints, `JOINTS_0`: four indices into its node's skin's `jointIndices` for each vertex, or null when it has none. */
	public final jointIndices:Null<Array<Int>>;

	/** Gets the vertices' weights, `WEIGHTS_0`: four for each vertex, one for each of its joints, or null when it has none. */
	public final weights:Null<Array<Float>>;

	/** Gets the vertices' texture coordinates, `TEXCOORD_0`: u and v for each vertex, v down from the image's top, or null when the
		primitive has none. */
	public final texCoords:Null<Array<Float>>;

	/** Gets the vertices' colors, `COLOR_0`: red, green, blue and alpha for each vertex, each 0 to 1 (alpha 1 when the file gives three
		components), or null when the primitive has none. */
	public final colors:Null<Array<Float>>;

	/** Gets the vertices' indices, or null when the primitive has none and its vertices are drawn in order. */
	public final indices:Null<Array<Int>>;

	/** Gets the index of the primitive's material in `GltfFile.materials`, or -1 when it has none (glTF's default material). */
	public final materialIndex:Int;

	@:allow(helix.formats.gltf)
	function new(mode:Int, positions:Array<Float>, normals:Null<Array<Float>>, tangents:Null<Array<Float>>, texCoords:Null<Array<Float>>,
			colors:Null<Array<Float>>, jointIndices:Null<Array<Int>>, weights:Null<Array<Float>>, indices:Null<Array<Int>>, materialIndex:Int) {
		this.mode = mode;
		this.positions = positions;
		this.normals = normals;
		this.tangents = tangents;
		this.jointIndices = jointIndices;
		this.weights = weights;
		this.texCoords = texCoords;
		this.colors = colors;
		this.indices = indices;
		this.materialIndex = materialIndex;
	}
}
