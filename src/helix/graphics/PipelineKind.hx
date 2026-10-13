package helix.graphics;

/** What a pipeline draws, each with its framework shader (src/helix/graphics/shaders) and vertex layout. */
enum abstract PipelineKind(Int) {
	/** Textured, vertex-colored triangles in clip space: Sprite2DLayout's vertices, one texture. No depth test. */
	var Sprite2D = 0;

	/** Vertex-colored triangles through a view-projection matrix: Color3DLayout's vertices, the matrix as uniforms. Depth-tested and written. */
	var Color3D = 1;

	/** Color3D's vertices and uniforms drawn as lines, two vertices each. Depth-tested and written. */
	var Lines3D = 2;

	/** Lit, textured models: Lit3DLayout's vertices from a static buffer, indexed by a static index buffer, each instance's record (its model and
		normal matrices' rows, its tint) from a stream buffer; lit by the fragment uniforms' lights. Depth-tested and written, back faces culled
		(counter-clockwise is the front). Drawn by IGraphics.drawMesh. */
	var Lit3D = 3;
}
