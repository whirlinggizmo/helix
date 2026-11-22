package helix.box2d;

/** A callback that can skip a continuous collision event. Box2D calls it when a time of impact event is computed for a shape that has pre-solve events enabled, on an awake dynamic body. It is not called for sensors. Natively it can be called from a worker thread, so it must not modify the world. Only a point and normal are provided because the contact's manifold may not exist yet or may be stale.

	@param shapeIdA  The first shape.
	@param shapeIdB  The second shape.
	@param point  The point of the event, in world coordinates.
	@param normal  The unit normal of the event.
	@param context  The value the program provided with the callback, returned as it was.
	@return  False to skip the time of impact event, true to keep it. */
typedef B2PreContinuousCallbackFcn = (shapeIdA:B2ShapeId, shapeIdB:B2ShapeId, point:B2Pos, normal:B2Vec2, context:Dynamic) -> Bool;
