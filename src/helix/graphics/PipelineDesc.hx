package helix.graphics;

/** A vertex attribute a pipeline reads from one of its buffers: its shader's input slot, its float count (1 to 4) and its byte offset in
	each record. */
typedef VertexAttribute = {
	final slot:Int;
	final componentCount:Int;
	final offset:Int;
}

/** A vertex buffer a pipeline reads, by its index in a draw's buffers: its record's bytes, whether a record is an instance's (stepped once
	an instance) or a vertex's, and the attributes read from it. A buffer with no attributes is a gap the draw skips. */
typedef VertexBuffer = {
	final stride:Int;
	final instanced:Bool;
	final attributes:Array<VertexAttribute>;
}

/** What a pipeline's draws make: triangles, three vertices (or indices) each, or lines, two each. */
enum abstract Primitive(Int) to Int {
	/** Triangles, three vertices (or indices) each. */
	var Triangles = 0;

	/** Lines, two each. */
	var Lines = 1;
}

/** What uniform block 0 holds, so an adapter whose render targets are stored upside down (GL's bottom-left origin) can draw a target the
	right way up: nothing it touches, a clip scale it writes (x 1, y -1 in such a pass, else 1), or a view-projection matrix (column-major,
	its first 64 bytes) whose y row it negates in such a pass. */
enum abstract ClipFlip(Int) to Int {
	/** Block 0 isn't touched (or there is none). */
	var None = 0;

	/** Block 0 is a vec4 clip scale the adapter writes. */
	var ClipScale = 1;

	/** Block 0 starts with a view-projection matrix whose y row the adapter negates. */
	var ViewProjection = 2;
}

/** A pipeline, everything a draw through it fixes: the program (an IGraphics.createShader handle), its vertex buffers' layout, what it
	draws, whether its draws are indexed (uint32 indices), how its colors meet the target's (blend), the depth test (less or equal) and
	write, back-face culling and which winding is the front, whether it writes depth alone (a shadow pass's), and its block 0's clip flip.
	Shared code describes the framework's pipelines (Pipelines); an adapter only makes what the description says. */
typedef PipelineDesc = {
	final shader:Int;
	final buffers:Array<VertexBuffer>;
	final primitive:Primitive;
	final indexed:Bool;
	final blend:BlendMode;
	final depthTest:Bool;
	final depthWrite:Bool;
	final cullBack:Bool;
	final clockwise:Bool;
	final depthOnly:Bool;
	final flip:ClipFlip;
}
