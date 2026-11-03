package helix.platform;

/** Represents a vertex buffer that a pipeline reads, by its index in a draw's buffers.

	A buffer with no attributes is a gap that the draw skips. */
typedef VertexBuffer = {
	/** The size of one record, in bytes: a multiple of 4, at most 255. */
	final stride:Int;

	/** Whether each record belongs to an instance rather than a vertex, so the buffer steps once per instance. */
	final instanced:Bool;

	/** The attributes read from each record. */
	final attributes:Array<VertexAttribute>;
}
