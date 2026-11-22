package helix.jolt;

/** Represents a body, returned by `BodyInterface.CreateBody` and, by its id, by `BodyLockInterfaceNoLock.TryGetBody`. Reads the body
	as it is now. `BodyInterface` changes it, by its id (`GetID`). */
class Body {
	function new() {}

	/** Returns the body's id.

		@return  The id. */
	public function GetID():BodyID {
		throw "not built yet";
	}

	/** Returns whether the body is awake.

		@return  True when awake. */
	public function IsActive():Bool {
		throw "not built yet";
	}

	/** Returns whether the body never moves.

		@return  True for a static body. */
	public function IsStatic():Bool {
		throw "not built yet";
	}

	/** Returns whether the program moves the body.

		@return  True for a kinematic body. */
	public function IsKinematic():Bool {
		throw "not built yet";
	}

	/** Returns whether the simulation moves the body.

		@return  True for a dynamic body. */
	public function IsDynamic():Bool {
		throw "not built yet";
	}

	/** Returns how the body moves.

		@return  The motion type. */
	public function GetMotionType():EMotionType {
		throw "not built yet";
	}

	/** Returns whether the body is a sensor.

		@return  True for a sensor. */
	public function IsSensor():Bool {
		throw "not built yet";
	}

	/** Returns the body's object layer.

		@return  The object layer. */
	public function GetObjectLayer():Int {
		throw "not built yet";
	}

	/** Returns the body's friction.

		@return  The friction. */
	public function GetFriction():Float {
		throw "not built yet";
	}

	/** Returns the body's bounce.

		@return  The bounce, 0 to 1. */
	public function GetRestitution():Float {
		throw "not built yet";
	}

	/** Returns the body's position.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The position, in meters. */
	public function GetPosition(?out:RVec3):RVec3 {
		throw "not built yet";
	}

	/** Returns the body's rotation.

		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The rotation. */
	public function GetRotation(?out:Quat):Quat {
		throw "not built yet";
	}

	/** Returns the body's transform.

		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public function GetWorldTransform(?out:RMat44):RMat44 {
		throw "not built yet";
	}

	/** Returns the body's velocity.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The velocity, in meters a second. */
	public function GetLinearVelocity(?out:Vec3):Vec3 {
		throw "not built yet";
	}

	/** Returns the body's angular velocity.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The angular velocity, in radians a second about each axis. */
	public function GetAngularVelocity(?out:Vec3):Vec3 {
		throw "not built yet";
	}

	/** Returns the body's bounds in the world.

		@param out  Optional. The box to fill; a new one when omitted.
		@return  The bounds. */
	public function GetWorldSpaceBounds(?out:AABox):AABox {
		throw "not built yet";
	}

	/** Returns the body's shape.

		@return  The shape. */
	public function GetShape():Shape {
		throw "not built yet";
	}

	/** Returns the normal of the body's surface at a point a query hit.

		@param inSubShapeID  The part of the shape hit, from the query's result.
		@param inPosition  The point, in the world, in meters.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The normal, of length 1. */
	public function GetWorldSpaceSurfaceNormal(inSubShapeID:SubShapeID, inPosition:RVec3, ?out:Vec3):Vec3 {
		throw "not built yet";
	}

	/** Returns the number the program keeps with the body.

		@return  The number. */
	public function GetUserData():Int {
		throw "not built yet";
	}
}
