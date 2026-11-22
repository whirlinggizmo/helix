package helix.box2d;

/** Reports that a shape began overlapping a sensor shape. */
class B2SensorBeginTouchEvent {
	/** The id of the sensor shape. */
	public var sensorShapeId:B2ShapeId;

	/** The id of the shape that began overlapping the sensor shape. */
	public var visitorShapeId:B2ShapeId;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2SensorBeginTouchEvent(this);
	}
}
