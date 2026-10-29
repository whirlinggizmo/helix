package helix.platform;

/** Represents a vertex buffer that a pipeline reads, by its index in a draw's buffers.

	A buffer with no attributes is a gap that the draw skips. */
typedef VertexBuffer = {
	/** The size of one record, in bytes. */
	final stride:Int;

	/** Whether a record is an instance's, stepped once an instance, rather than a vertex's. */
	final instanced:Bool;

	/** The attributes read from each record. */
	final attributes:Array<VertexAttribute>;
}
