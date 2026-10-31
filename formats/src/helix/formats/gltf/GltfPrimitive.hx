package helix.formats.gltf;

/** Represents one primitive of a glTF mesh: its vertices, read from their accessors, its indices and its material.

	Each attribute is every component of every vertex in order, as floats: a normalized integer is scaled to 0..1 when unsigned and
	-1..1 when signed, any other value is as the file has it. Positions and normals are in the mesh's own units: no node's transform is
	applied. Only the first set of texture coordinates (`TEXCOORD_0`) and of colors (`COLOR_0`) is read. */
class GltfPrimitive {
	/** Gets what the primitive draws, glTF's `mode`: 0 points, 1 lines, 2 a line loop, 3 a line strip, 4 triangles, 5 a triangle strip,
		6 a triangle fan. Defaults to 4. */
	public final mode:Int;

	/** Gets the vertices' positions, `POSITION`: x, y and z for each vertex. Empty when the primitive has none. */
	public final positions:Array<Float>;

	/** Gets the vertices' normals, `NORMAL`: x, y and z for each vertex, or null when the primitive has none. */
	public final normals:Null<Array<Float>>;

	/** Gets the vertices' texture coordinates, `TEXCOORD_0`: u and v for each vertex, v down from the image's top, or null when the
		primitive has none. */
	public final texCoords:Null<Array<Float>>;

	/** Gets the vertices' colors, `COLOR_0`: red, green, blue and alpha for each vertex, each 0 to 1 (alpha 1 when the file gives three
		components), or null when the primitive has none. */
	public final colors:Null<Array<Float>>;

	/** Gets the vertices' indices, or null when the primitive has none and its vertices are drawn in order. */
	public final indices:Null<Array<Int>>;

	/** Gets the index of the primitive's material in `GltfFile.materials`, or -1 when it has none (glTF's default material). */
	public final material:Int;

	@:allow(helix.formats.gltf)
	function new(mode:Int, positions:Array<Float>, normals:Null<Array<Float>>, texCoords:Null<Array<Float>>, colors:Null<Array<Float>>,
			indices:Null<Array<Int>>, material:Int) {
		this.mode = mode;
		this.positions = positions;
		this.normals = normals;
		this.texCoords = texCoords;
		this.colors = colors;
		this.indices = indices;
		this.material = material;
	}
}
