package helix.box2d;

/** A callback that mixes the friction of two touching shapes into one coefficient. Box2D calls it for each contact when it is set on the world, instead of its own mixing. It has no context value because Box2D may call it from a worker thread. It must not modify Box2D's state or the program's.

	@param frictionA  The friction coefficient of the first shape.
	@param userMaterialIdA  The user material id of the first shape's material.
	@param frictionB  The friction coefficient of the second shape.
	@param userMaterialIdB  The user material id of the second shape's material.
	@return  The mixed friction coefficient the contact uses. */
typedef B2FrictionCallbackFcn = (frictionA:Float, userMaterialIdA:haxe.Int64, frictionB:Float, userMaterialIdB:haxe.Int64) -> Float;
