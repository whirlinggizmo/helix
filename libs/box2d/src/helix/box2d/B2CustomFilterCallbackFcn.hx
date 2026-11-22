package helix.box2d;

/** A callback that decides whether two shapes collide. Box2D calls it when two shapes' bounding boxes begin to overlap and one of them has custom filtering enabled in its `B2ShapeDef`. It may also be called for awake dynamic bodies and sensors. Natively it can be called from a worker thread, so it must not modify the world.

	@param shapeIdA  The first shape.
	@param shapeIdB  The second shape.
	@param context  The value the program provided with the callback, returned as it was.
	@return  False to disable the collision between the shapes, true to allow it. */
typedef B2CustomFilterCallbackFcn = (shapeIdA:B2ShapeId, shapeIdB:B2ShapeId, context:Dynamic) -> Bool;
