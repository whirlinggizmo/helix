package helix.jolt;

/** Represents a body's shape where the body is, returned by `BodyInterface.GetTransformedShape`, for asking about a query's hit. Read
	as the body was when returned. */
class TransformedShape {
	/** Gets the body. */
	public var mBodyID(default, null):BodyID;

	/** Gets the shape. */
	public var mShape(default, null):Shape;

	/** Creates an empty transformed shape, to fill with `BodyInterface.GetTransformedShape`. */
	public function new() {
		throw "not built yet";
	}

	/** Returns the transform of the shape.

		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public function GetWorldTransform(?out:RMat44):RMat44 {
		throw "not built yet";
	}

	/** Returns the shape's bounds in the world.

		@param out  Optional. The box to fill; a new one when omitted.
		@return  The bounds. */
	public function GetWorldSpaceBounds(?out:AABox):AABox {
		throw "not built yet";
	}

	/** Returns the normal of the shape's surface at a point a query hit.

		@param inSubShapeID  The part of the shape hit, from the query's result.
		@param inPosition  The point, in the world, in meters.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The normal, of length 1. */
	public function GetWorldSpaceSurfaceNormal(inSubShapeID:SubShapeID, inPosition:RVec3, ?out:Vec3):Vec3 {
		throw "not built yet";
	}
}
