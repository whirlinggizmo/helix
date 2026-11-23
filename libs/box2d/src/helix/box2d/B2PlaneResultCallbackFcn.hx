package helix.box2d;

/** A callback for `b2World_CollideMover`. Box2D calls it for each collision plane it finds between the mover and a shape.

	@param shapeId  The shape the mover collides with.
	@param plane  The collision plane and point, relative to the query's origin. Box2D reuses it after the callback returns, so a program copies what it keeps.
	@param context  The value the program provided to `b2World_CollideMover`, returned as it was.
	@return  True to go on gathering planes, false to stop. */
typedef B2PlaneResultCallbackFcn = (shapeId:B2ShapeId, plane:B2PlaneResult, context:Dynamic) -> Bool;
