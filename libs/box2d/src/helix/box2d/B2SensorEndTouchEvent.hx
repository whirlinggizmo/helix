package helix.box2d;

/** Reports that a shape stopped overlapping a sensor shape. It is also reported when something other than movement ends the overlap: setting a body's transform, destroying a body or shape, or changing a filter. It is reported too when the sensor is destroyed, so check the ids with `b2Shape_IsValid`. */
class B2SensorEndTouchEvent {
	/** The id of the sensor shape. The shape may have been destroyed, so check it with `b2Shape_IsValid`. */
	public var sensorShapeId:B2ShapeId;

	/** The id of the shape that stopped overlapping the sensor shape. The shape may have been destroyed, so check it with `b2Shape_IsValid`. */
	public var visitorShapeId:B2ShapeId;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2SensorEndTouchEvent(this);
	}
}
