package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;
import helix.jolt.Jolt.*;

/** Represents a body, returned by `BodyInterface.CreateBody` and, by its id, by `BodyLockInterfaceNoLock.TryGetBody`. Reads the body
	as it is now. `BodyInterface` changes it, by its id (`GetID`). */
class Body {
	var world:Int;
	var id:BodyID;

	@:allow(helix.jolt) function new(world:Int, id:BodyID) {
		this.world = world;
		this.id = id;
	}

	/** Returns the body's id.

		@return  The id. */
	public function GetID():BodyID {
		return id;
	}

	/** Returns whether the body is awake.

		@return  True when awake. */
	public function IsActive():Bool {
		return Hj.bodyIsActive(world, id.GetIndexAndSequenceNumber()) != 0;
	}

	/** Returns whether the body never moves.

		@return  True for a static body. */
	public function IsStatic():Bool {
		return GetMotionType() == EMotionType_Static;
	}

	/** Returns whether the program moves the body.

		@return  True for a kinematic body. */
	public function IsKinematic():Bool {
		return GetMotionType() == EMotionType_Kinematic;
	}

	/** Returns whether the simulation moves the body.

		@return  True for a dynamic body. */
	public function IsDynamic():Bool {
		return GetMotionType() == EMotionType_Dynamic;
	}

	/** Returns how the body moves.

		@return  The motion type. */
	public function GetMotionType():EMotionType {
		return cast Hj.bodyGetMotionType(world, id.GetIndexAndSequenceNumber());
	}

	/** Returns whether the body is a sensor.

		@return  True for a sensor. */
	public function IsSensor():Bool {
		return Hj.bodyIsSensor(world, id.GetIndexAndSequenceNumber()) != 0;
	}

	/** Returns the body's object layer.

		@return  The object layer. */
	public function GetObjectLayer():Int {
		return Hj.bodyGetObjectLayer(world, id.GetIndexAndSequenceNumber());
	}

	/** Returns the body's friction.

		@return  The friction. */
	public function GetFriction():Float {
		return Hj.bodyGetFriction(world, id.GetIndexAndSequenceNumber());
	}

	/** Returns the body's bounce.

		@return  The bounce, 0 to 1. */
	public function GetRestitution():Float {
		return Hj.bodyGetRestitution(world, id.GetIndexAndSequenceNumber());
	}

	/** Returns the body's position.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The position, in meters. */
	public function GetPosition(?out:RVec3):RVec3 {
		Hj.bodyGetPositionAndRotation(world, id.GetIndexAndSequenceNumber());
		return Io.vec3(0, out);
	}

	/** Returns the body's rotation.

		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The rotation. */
	public function GetRotation(?out:Quat):Quat {
		Hj.bodyGetPositionAndRotation(world, id.GetIndexAndSequenceNumber());
		return Io.quat(3, out);
	}

	/** Returns the body's transform.

		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public function GetWorldTransform(?out:RMat44):RMat44 {
		Hj.bodyGetWorldTransform(world, id.GetIndexAndSequenceNumber());
		return Io.mat44(0, out);
	}

	/** Returns the body's velocity.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The velocity, in meters a second. */
	public function GetLinearVelocity(?out:Vec3):Vec3 {
		Hj.bodyGetVelocities(world, id.GetIndexAndSequenceNumber());
		return Io.vec3(0, out);
	}

	/** Returns the body's angular velocity.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The angular velocity, in radians a second about each axis. */
	public function GetAngularVelocity(?out:Vec3):Vec3 {
		Hj.bodyGetVelocities(world, id.GetIndexAndSequenceNumber());
		return Io.vec3(3, out);
	}

	/** Returns the body's bounds in the world.

		@param out  Optional. The box to fill; a new one when omitted.
		@return  The bounds. */
	public function GetWorldSpaceBounds(?out:AABox):AABox {
		Hj.bodyGetWorldSpaceBounds(world, id.GetIndexAndSequenceNumber());
		return Io.box(0, out);
	}

	/** Returns the body's shape.

		@return  The shape. */
	public function GetShape():Shape {
		return Shape.of(Hj.bodyGetShape(world, id.GetIndexAndSequenceNumber()));
	}

	/** Returns the normal of the body's surface at a point a query hit.

		@param inSubShapeID  The part of the shape hit, from the query's result.
		@param inPosition  The point, in the world, in meters.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The normal, of length 1. */
	public function GetWorldSpaceSurfaceNormal(inSubShapeID:SubShapeID, inPosition:RVec3, ?out:Vec3):Vec3 {
		Hj.bodyGetWorldSpaceSurfaceNormal(world, id.GetIndexAndSequenceNumber(), inSubShapeID.GetValue(), inPosition.x, inPosition.y, inPosition.z);
		return Io.vec3(0, out);
	}

	/** Returns the number the program keeps with the body.

		@return  The number. */
	public function GetUserData():Int {
		return Hj.bodyGetUserData(world, id.GetIndexAndSequenceNumber());
	}
}
