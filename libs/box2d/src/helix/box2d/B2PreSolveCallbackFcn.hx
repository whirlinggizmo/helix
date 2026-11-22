package helix.box2d;

/** A callback that inspects a contact manifold before it goes to the solver. Box2D calls it after a contact's manifold is updated, for a shape that has pre-solve events enabled, on an awake dynamic body. It is not called for sensors. Natively it can be called from a worker thread, so it must not modify the world. It may change the manifold, such as its normal, and setting the manifold's `pointCount` to 0 disables the collision. The manifold's impulses are not reliable here.

	@param shapeIdA  The first shape.
	@param shapeIdB  The second shape.
	@param manifold  The contact manifold, which the callback may modify.
	@param context  The value the program provided with the callback, returned as it was. */
typedef B2PreSolveCallbackFcn = (shapeIdA:B2ShapeId, shapeIdB:B2ShapeId, manifold:B2Manifold, context:Dynamic) -> Void;
