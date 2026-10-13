package helix.graphics;

/** What a pipeline draws, each with its framework shader (src/helix/graphics/shaders) and vertex layout. */
enum abstract PipelineKind(Int) {
	/** Textured, vertex-colored triangles in clip space: Sprite2DLayout's vertices, one texture. No depth test. */
	var Sprite2D = 0;

	/** Vertex-colored triangles through a view-projection matrix: Color3DLayout's vertices, the matrix as uniforms. Depth-tested and written. */
	var Color3D = 1;

	/** Color3D's vertices and uniforms drawn as lines, two vertices each. Depth-tested and written. */
	var Lines3D = 2;
}
