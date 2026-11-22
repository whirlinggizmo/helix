package helix.box2d;

/** A callback for overlap queries. Box2D calls it for each shape the query finds.

	@param shapeId  The shape found.
	@param context  The value the program provided to the query call, returned as it was.
	@return  True to continue the query, false to stop it. */
typedef B2OverlapResultCallbackFcn = (shapeId:B2ShapeId, context:Dynamic) -> Bool;
