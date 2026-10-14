package helix.graphics;

/** What a pipeline draws: its vertex layout and state, and its framework shader (src/helix/graphics/shaders) unless an app's is given
	(IGraphics.createPipeline's shader). */
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

	/** A screen effect: one triangle over the whole viewport, no vertex buffers, an app's shader (a .hxshader of kind screen) sampling textures
		such as a finished frame. No depth test. Drawn by IGraphics.drawScreen; it has no framework shader. */
	var Screen = 4;

	/** 3D sprites: a quad (Sprite3DLayout's corners, a static buffer, indexed) drawn once an instance, each instance's record its place, facing,
		size, pivot, texture region, alpha mode and tint (a stream buffer); one texture, unlit. Depth-tested, written only when opaque; nothing
		culled. Drawn by IGraphics.drawMesh. */
	var Sprite3D = 5;

	/** Particles: a quad (Particle3DLayout's corners, as Sprite3D's) drawn once a particle, each particle's birth record (where and when, its
		velocity and life, its size, spin and a random value) from a stream buffer; where it is, its size, color and turn follow from its age in
		the vertex stage, by the emitter's settings in its uniforms. One texture, unlit; depth written only when opaque; nothing culled. Drawn by
		IGraphics.drawMesh. */
	var Particle3D = 6;

	/** Shadow-map depth: Lit3D's vertices (Lit3DLayout's stride, Depth3DLayout reads their positions), each instance's placement (Depth3DLayout's
		record: its model matrix's rows) from a stream buffer, through a light's view-projection (the vertex uniforms). Depth only, tested and
		written; nothing culled, so a one-sided floor still casts. Drawn by IGraphics.drawMesh in a shadow pass (beginShadowPass). */
	var Depth3D = 7;
}
