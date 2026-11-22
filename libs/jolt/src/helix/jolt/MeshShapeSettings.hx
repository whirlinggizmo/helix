package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

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
		mTriangleVertices = inVertices == null ? [] : inVertices;
		mIndexedTriangles = inTriangles == null ? [] : inTriangles;
	}

	/** Returns settings for a mesh's vertices and indices as a renderer holds them, such as helix-raylib's `Mesh`: an extra of
		helix-jolt's.

		@param inVertices  Three floats a vertex: x, y and z, in meters.
		@param inIndices  Optional. Three indices a triangle, counterclockwise seen from the front. When omitted, every three vertices
		are a triangle.
		@return  The settings. */
	public static function sFromBuffers(inVertices:haxe.io.Float32Array, ?inIndices:haxe.io.UInt32Array):MeshShapeSettings {
		var settings = new MeshShapeSettings();
		settings.vertexBuffer = inVertices;
		settings.indexBuffer = inIndices;
		return settings;
	}

	/** Removes the triangles of no area, and the ones repeated. */
	public function Sanitize():Void {
		var seen = new Map<String, Bool>();
		var kept:IndexedTriangleList = [];
		for (t in mIndexedTriangles) {
			if (t.mIdx0 == t.mIdx1 || t.mIdx1 == t.mIdx2 || t.mIdx0 == t.mIdx2)
				continue;
			var lowest = t.mIdx0 < t.mIdx1 ? (t.mIdx0 < t.mIdx2 ? 0 : 2) : (t.mIdx1 < t.mIdx2 ? 1 : 2);
			var order = [t.mIdx0, t.mIdx1, t.mIdx2];
			var key = order[lowest] + "," + order[(lowest + 1) % 3] + "," + order[(lowest + 2) % 3];
			if (seen.exists(key))
				continue;
			seen.set(key, true);
			kept.push(t);
		}
		mIndexedTriangles = kept;
	}

	var vertexBuffer:Null<haxe.io.Float32Array>;
	var indexBuffer:Null<haxe.io.UInt32Array>;

	override function make():Int {
		if (vertexBuffer != null) {
			var vertexCount = Std.int(vertexBuffer.length / 3);
			var triangleCount = indexBuffer != null ? Std.int(indexBuffer.length / 3) : Std.int(vertexCount / 3);
			var base = Io.bulk(vertexCount * 12 + triangleCount * 12);
			for (n in 0...vertexCount * 3)
				Io.setBulkF(base, n, vertexBuffer[n]);
			for (n in 0...triangleCount * 3)
				Io.setBulkI(base, vertexCount * 3 + n, indexBuffer != null ? indexBuffer[n] : n);
			return Hj.shapeMesh(vertexCount, triangleCount, mMaxTrianglesPerLeaf, mUserData);
		}
		var vertexCount = mTriangleVertices.length,
			triangleCount = mIndexedTriangles.length;
		var base = Io.bulk(vertexCount * 12 + triangleCount * 12);
		for (n in 0...vertexCount) {
			Io.setBulkF(base, n * 3, mTriangleVertices[n].x);
			Io.setBulkF(base, n * 3 + 1, mTriangleVertices[n].y);
			Io.setBulkF(base, n * 3 + 2, mTriangleVertices[n].z);
		}
		for (n in 0...triangleCount) {
			var t = mIndexedTriangles[n];
			Io.setBulkI(base, vertexCount * 3 + n * 3, t.mIdx0);
			Io.setBulkI(base, vertexCount * 3 + n * 3 + 1, t.mIdx1);
			Io.setBulkI(base, vertexCount * 3 + n * 3 + 2, t.mIdx2);
		}
		return Hj.shapeMesh(vertexCount, triangleCount, mMaxTrianglesPerLeaf, mUserData);
	}
}
