package helix.jolt;

/** Represents a mesh's triangle, by the indices of its three vertices, counterclockwise seen from the front. */
class IndexedTriangle {
	/** Gets or sets the first vertex's index. */
	public var mIdx0:Int;

	/** Gets or sets the second vertex's index. */
	public var mIdx1:Int;

	/** Gets or sets the third vertex's index. */
	public var mIdx2:Int;

	/** Creates a triangle.

		@param inI1  The first vertex's index.
		@param inI2  The second vertex's index.
		@param inI3  The third vertex's index. */
	public function new(inI1:Int, inI2:Int, inI3:Int) {
		throw "not built yet";
	}
}
