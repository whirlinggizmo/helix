package helix.box2d;

/** Shape type. */
enum abstract B2ShapeType(Int) to Int {
	/** A circle with an offset. */
	var b2_circleShape = 0;

	/** A capsule is an extruded circle. */
	var b2_capsuleShape = 1;

	/** A line segment. */
	var b2_segmentShape = 2;

	/** A convex polygon. */
	var b2_polygonShape = 3;

	/** A line segment owned by a chain shape. */
	var b2_chainSegmentShape = 4;

	/** The number of shape types. */
	var b2_shapeTypeCount = 5;
}
