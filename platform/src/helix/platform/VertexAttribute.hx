package helix.platform;

/** Represents a vertex attribute that a pipeline reads from one of its buffers. */
typedef VertexAttribute = {
	/** The shader's input slot. */
	final slot:Int;

	/** The number of floats, 1 to 4. */
	final componentCount:Int;

	/** The byte offset within each record. */
	final offset:Int;
}
