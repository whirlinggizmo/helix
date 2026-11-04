package helix.render;

/** Specifies how a `Batch3D` draws the triangles of a mesh or of `drawTriangles`: filled, as their edges, or as their corners. */
#if !macro
@:build(helix.platform.macros.EnumNames.build())
#end
enum abstract PolygonMode3D(Int) {
	/** Filled: the triangles themselves. */
	var Fill = 0;

	/** Each triangle's edges, as one-pixel lines: raylib's wire mode, three.js's `wireframe`. */
	var Lines = 1;

	/** Each triangle's corners, as points of `Batch3D.pointSize`: raylib's point mode, three.js's `Points`. Points of one pixel are drawn
		a point an index for an indexed mesh, so a corner shared by triangles is drawn once each, as raylib draws them. A mesh's larger
		points are drawn once a vertex, each a square made in the vertex stage, and an instanced mesh's a GPU draw for each copy. */
	var Points = 2;
}
