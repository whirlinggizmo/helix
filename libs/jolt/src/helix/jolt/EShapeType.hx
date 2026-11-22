package helix.jolt;

/** Specifies a shape's family. */
enum abstract EShapeType(Int) {
	/** A convex shape: box, sphere, capsule, cylinder, hull. */
	var EShapeType_Convex = 0;

	/** Shapes put together. */
	var EShapeType_Compound = 1;

	/** A shape changed by another: scaled, moved, its center of mass offset. */
	var EShapeType_Decorated = 2;

	/** Triangles. */
	var EShapeType_Mesh = 3;

	/** A grid of heights. */
	var EShapeType_HeightField = 4;

	/** A plane. */
	var EShapeType_Plane = 5;

	/** No shape. */
	var EShapeType_Empty = 6;
}
