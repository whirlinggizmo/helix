package helix.jolt;

/** Represents what a mesh shape is built from: triangles, for a static body such as a level's floors and walls.

	```haxe
	var settings = MeshShapeSettings.sFromBuffers(mesh.vertices, mesh.indices);
	var level = settings.Create().Get();
	``` */
class MeshShapeSettings extends ShapeSettings {
	/** Gets or sets the vertices, in meters. */
	public var mTriangleVertices:VertexList;

	/** Gets or sets the triangles. */
	public var mIndexedTriangles:IndexedTriangleList;

	/** Gets or sets the most triangles in a leaf of the shape's tree, 1 to 8. Defaults to 8. */
	public var mMaxTrianglesPerLeaf:Int = 8;

	/** Creates the settings.

		@param inVertices  Optional. The vertices; none when omitted.
		@param inTriangles  Optional. The triangles; none when omitted. */
	public function new(?inVertices:VertexList, ?inTriangles:IndexedTriangleList) {
		super();
		throw "not built yet";
	}

	/** Returns settings for a mesh's vertices and indices as a renderer holds them, such as helix-raylib's `Mesh`: an extra of
		helix-jolt's.

		@param inVertices  Three floats a vertex: x, y and z, in meters.
		@param inIndices  Optional. Three indices a triangle, counterclockwise seen from the front. When omitted, every three vertices
		are a triangle.
		@return  The settings. */
	public static function sFromBuffers(inVertices:haxe.io.Float32Array, ?inIndices:haxe.io.UInt32Array):MeshShapeSettings {
		throw "not built yet";
	}

	/** Removes the triangles of no area, and the ones repeated. */
	public function Sanitize():Void {
		throw "not built yet";
	}
}
