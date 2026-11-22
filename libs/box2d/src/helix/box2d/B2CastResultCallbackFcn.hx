package helix.box2d;

/** A callback for ray and shape casts. Box2D calls it for each shape the cast finds. The return value controls how the cast goes on: -1 ignores this shape and continues, 0 terminates the cast, the fraction clips the ray to that point (use it to find the closest hit), and 1 continues without clipping. A shape cast that starts overlapping a shape reports a fraction of 0 and a zero normal.

	@param shapeId  The shape hit by the cast.
	@param point  The point where the cast first meets the shape, in world coordinates.
	@param normal  The unit normal of the shape at that point. Zero for a shape cast that starts overlapping.
	@param fraction  How far along the cast the hit is, from 0 to 1. Zero for a shape cast that starts overlapping.
	@param context  The value the program provided to the cast call, returned as it was.
	@return  -1 to ignore the shape, 0 to stop, the fraction to clip the ray, or 1 to continue. */
typedef B2CastResultCallbackFcn = (shapeId:B2ShapeId, point:B2Pos, normal:B2Vec2, fraction:Float, context:Dynamic) -> Float;
