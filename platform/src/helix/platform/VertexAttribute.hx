package helix.platform;

/** Represents a vertex attribute that a pipeline reads from one of its buffers. */
typedef VertexAttribute = {
	/** The shader's input slot, 0 to 15. The input must be a float one (`float`, `vecN` or a matrix's column). */
	final slot:Int;

	/** How its values are stored. */
	final format:VertexFormat;

	/** The byte offset within each record: a multiple of 4, its format's `bytes` ending within the record. */
	final offset:Int;
}
