package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

/** Provides the calls that make, change and read bodies, by their ids. Returned by `PhysicsSystem.GetBodyInterface`.

	```haxe
	var id = bodyInterface.CreateAndAddBody(settings, EActivation_Activate);
	var position = new RVec3();
	jolt.Step(1 / 60, 1);
	bodyInterface.GetPosition(id, position);
	```

	A call on an id that names no body is skipped, and one returning a value returns zero, the identity or false. */
class BodyInterface {
	var world:Int;
	var bodies:BodyLockInterfaceNoLock;

	@:allow(helix.jolt) function new(world:Int, bodies:BodyLockInterfaceNoLock) {
		this.world = world;
		this.bodies = bodies;
	}

	/** Makes a body, not yet in the simulation.

		`AddBody` puts the body in the simulation. See `CreateAndAddBody` for making and adding a body in one call.

		@param inSettings  What the body is made from, read once.
		@return  The body, or null when the system holds `JoltSettings.mMaxBodies` already. */
	public function CreateBody(inSettings:BodyCreationSettings):Body {
		var shape = inSettings.GetShape();
		if (shape == null)
			return null;
		inSettings.write();
		var id = Hj.bodyCreate(world, shape.handle, 0, 0);
		return id == -1 ? null : bodies.body(new BodyID(id));
	}

	/** Makes a body and adds it to the simulation.

		@param inSettings  What the body is made from, read once.
		@param inActivationMode  Whether the body wakes.
		@return  The body's id, invalid when the system holds `JoltSettings.mMaxBodies` already. */
	public function CreateAndAddBody(inSettings:BodyCreationSettings, inActivationMode:EActivation):BodyID {
		var shape = inSettings.GetShape();
		if (shape == null)
			return new BodyID();
		inSettings.write();
		return new BodyID(Hj.bodyCreate(world, shape.handle, 1, cast inActivationMode));
	}

	/** Destroys a body, which must have been removed. Its id names no body after.

		@param inBodyID  The body. */
	public function DestroyBody(inBodyID:BodyID):Void {
		Hj.bodyDestroy(world, inBodyID.GetIndexAndSequenceNumber());
		bodies.forget(inBodyID);
	}

	/** Adds a body to the simulation.

		@param inBodyID  The body.
		@param inActivationMode  Whether the body wakes. */
	public function AddBody(inBodyID:BodyID, inActivationMode:EActivation):Void {
		Hj.bodyAdd(world, inBodyID.GetIndexAndSequenceNumber(), (cast inActivationMode : Int));
	}

	/** Removes a body from the simulation, keeping it to add again.

		@param inBodyID  The body. */
	public function RemoveBody(inBodyID:BodyID):Void {
		Hj.bodyRemove(world, inBodyID.GetIndexAndSequenceNumber());
	}

	/** Returns whether a body is in the simulation.

		@param inBodyID  The body.
		@return  True after `AddBody` and before `RemoveBody`. */
	public function IsAdded(inBodyID:BodyID):Bool {
		return Hj.bodyIsAdded(world, inBodyID.GetIndexAndSequenceNumber()) != 0;
	}

	/** Makes a constraint between two bodies, not yet acting.

		`PhysicsSystem.AddConstraint` makes it act. An invalid id for either body, such as
		`JoltInterface.sGetFixedToWorldBody().GetID()`, fixes the other body to the world.

		```haxe
		var door = bodyInterface.CreateConstraint(hingeSettings, JoltInterface.sGetFixedToWorldBody().GetID(), doorID);
		physicsSystem.AddConstraint(door);
		door.SetMotorState(EMotorState_Velocity);
		```

		@param inSettings  The constraint's kind and settings, read once.
		@param inBodyID1  The first body.
		@param inBodyID2  The second body.
		@return  The constraint, of the kind the settings make (a `HingeConstraint` from `HingeConstraintSettings`), or null when both
		ids are invalid. */
	public function CreateConstraint<T:TwoBodyConstraint>(inSettings:TwoBodyConstraintSettings<T>, inBodyID1:BodyID, inBodyID2:BodyID):T {
		var handle = Hj.constraintCreate(world, inSettings.write(), inBodyID1.GetIndexAndSequenceNumber(), inBodyID2.GetIndexAndSequenceNumber());
		return handle == -1 ? null : inSettings.make(world, handle);
	}

	/** Returns a body's shape.

		@param inBodyID  The body.
		@return  The shape. */
	public function GetShape(inBodyID:BodyID):Shape {
		return Shape.of(Hj.bodyGetShape(world, inBodyID.GetIndexAndSequenceNumber()));
	}

	/** Replaces a body's shape.

		@param inBodyID  The body.
		@param inShape  The shape.
		@param inUpdateMassProperties  Whether the mass and inertia are worked out again from the shape.
		@param inActivationMode  Whether the body wakes. */
	public function SetShape(inBodyID:BodyID, inShape:Shape, inUpdateMassProperties:Bool, inActivationMode:EActivation):Void {
		Hj.bodySetShape(world, inBodyID.GetIndexAndSequenceNumber(), inShape.handle, inUpdateMassProperties ? 1 : 0, (cast inActivationMode : Int));
	}

	/** Moves a body to another object layer.

		@param inBodyID  The body.
		@param inLayer  The object layer. */
	public function SetObjectLayer(inBodyID:BodyID, inLayer:Int):Void {
		Hj.bodySetObjectLayer(world, inBodyID.GetIndexAndSequenceNumber(), inLayer);
	}

	/** Returns a body's object layer.

		@param inBodyID  The body.
		@return  The object layer. */
	public function GetObjectLayer(inBodyID:BodyID):Int {
		return Hj.bodyGetObjectLayer(world, inBodyID.GetIndexAndSequenceNumber());
	}

	/** Places a body.

		A body set somewhere moves there at once, through what is between. See `MoveKinematic` for moving a kinematic body that pushes what it meets.

		@param inBodyID  The body.
		@param inPosition  The position, in meters.
		@param inRotation  The rotation.
		@param inActivationMode  Whether the body wakes. */
	public function SetPositionAndRotation(inBodyID:BodyID, inPosition:RVec3, inRotation:Quat, inActivationMode:EActivation):Void {
		Hj.bodySetPositionAndRotation(world, inBodyID.GetIndexAndSequenceNumber(), inPosition.x, inPosition.y, inPosition.z, inRotation.x, inRotation.y,
			inRotation.z, inRotation.w, (cast inActivationMode : Int));
	}

	/** Reads where a body is.

		@param inBodyID  The body.
		@param outPosition  Receives the position, in meters.
		@param outRotation  Receives the rotation. */
	public function GetPositionAndRotation(inBodyID:BodyID, outPosition:RVec3, outRotation:Quat):Void {
		Hj.bodyGetPositionAndRotation(world, inBodyID.GetIndexAndSequenceNumber());
		Io.vec3(0, outPosition);
		Io.quat(3, outRotation);
	}

	/** Moves a body.

		@param inBodyID  The body.
		@param inPosition  The position, in meters.
		@param inActivationMode  Whether the body wakes. */
	public function SetPosition(inBodyID:BodyID, inPosition:RVec3, inActivationMode:EActivation):Void {
		Hj.bodySetPosition(world, inBodyID.GetIndexAndSequenceNumber(), inPosition.x, inPosition.y, inPosition.z, (cast inActivationMode : Int));
	}

	/** Returns a body's position.

		@param inBodyID  The body.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The position, in meters. */
	public function GetPosition(inBodyID:BodyID, ?out:RVec3):RVec3 {
		Hj.bodyGetPositionAndRotation(world, inBodyID.GetIndexAndSequenceNumber());
		return Io.vec3(0, out);
	}

	/** Turns a body.

		@param inBodyID  The body.
		@param inRotation  The rotation.
		@param inActivationMode  Whether the body wakes. */
	public function SetRotation(inBodyID:BodyID, inRotation:Quat, inActivationMode:EActivation):Void {
		Hj.bodySetRotation(world, inBodyID.GetIndexAndSequenceNumber(), inRotation.x, inRotation.y, inRotation.z, inRotation.w, (cast inActivationMode : Int));
	}

	/** Returns a body's rotation.

		@param inBodyID  The body.
		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The rotation. */
	public function GetRotation(inBodyID:BodyID, ?out:Quat):Quat {
		Hj.bodyGetPositionAndRotation(world, inBodyID.GetIndexAndSequenceNumber());
		return Io.quat(3, out);
	}

	/** Returns a body's transform: its rotation and position, for drawing it.

		@param inBodyID  The body.
		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public function GetWorldTransform(inBodyID:BodyID, ?out:RMat44):RMat44 {
		Hj.bodyGetWorldTransform(world, inBodyID.GetIndexAndSequenceNumber());
		return Io.mat44(0, out);
	}

	/** Returns the transform of a body's center of mass.

		@param inBodyID  The body.
		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public function GetCenterOfMassTransform(inBodyID:BodyID, ?out:RMat44):RMat44 {
		Hj.bodyGetCenterOfMassTransform(world, inBodyID.GetIndexAndSequenceNumber());
		return Io.mat44(0, out);
	}

	/** Moves a kinematic body to a place over a step, pushing the dynamic bodies it meets.

		Called before `JoltInterface.Step`: the body arrives at the place at the end of that step.

		@param inBodyID  The body.
		@param inTargetPosition  Where the body arrives, in meters.
		@param inTargetRotation  The rotation it arrives at.
		@param inDeltaTime  The seconds of the next step, as passed to `JoltInterface.Step`. */
	public function MoveKinematic(inBodyID:BodyID, inTargetPosition:RVec3, inTargetRotation:Quat, inDeltaTime:Float):Void {
		Hj.bodyMoveKinematic(world, inBodyID.GetIndexAndSequenceNumber(), inTargetPosition.x, inTargetPosition.y, inTargetPosition.z, inTargetRotation.x,
			inTargetRotation.y, inTargetRotation.z, inTargetRotation.w, inDeltaTime);
	}

	/** Sets a body's velocity.

		@param inBodyID  The body.
		@param inLinearVelocity  The velocity, in meters a second. */
	public function SetLinearVelocity(inBodyID:BodyID, inLinearVelocity:Vec3):Void {
		Hj.bodySetLinearVelocity(world, inBodyID.GetIndexAndSequenceNumber(), inLinearVelocity.x, inLinearVelocity.y, inLinearVelocity.z);
	}

	/** Returns a body's velocity.

		@param inBodyID  The body.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The velocity, in meters a second. */
	public function GetLinearVelocity(inBodyID:BodyID, ?out:Vec3):Vec3 {
		Hj.bodyGetVelocities(world, inBodyID.GetIndexAndSequenceNumber());
		return Io.vec3(0, out);
	}

	/** Adds to a body's velocity.

		@param inBodyID  The body.
		@param inLinearVelocity  The velocity added, in meters a second. */
	public function AddLinearVelocity(inBodyID:BodyID, inLinearVelocity:Vec3):Void {
		Hj.bodyAddLinearVelocity(world, inBodyID.GetIndexAndSequenceNumber(), inLinearVelocity.x, inLinearVelocity.y, inLinearVelocity.z);
	}

	/** Sets a body's angular velocity.

		@param inBodyID  The body.
		@param inAngularVelocity  The angular velocity, in radians a second about each axis. */
	public function SetAngularVelocity(inBodyID:BodyID, inAngularVelocity:Vec3):Void {
		Hj.bodySetAngularVelocity(world, inBodyID.GetIndexAndSequenceNumber(), inAngularVelocity.x, inAngularVelocity.y, inAngularVelocity.z);
	}

	/** Returns a body's angular velocity.

		@param inBodyID  The body.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The angular velocity, in radians a second about each axis. */
	public function GetAngularVelocity(inBodyID:BodyID, ?out:Vec3):Vec3 {
		Hj.bodyGetVelocities(world, inBodyID.GetIndexAndSequenceNumber());
		return Io.vec3(3, out);
	}

	/** Returns the velocity of a point on a body.

		@param inBodyID  The body.
		@param inPoint  The point, in the world, in meters.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The velocity, in meters a second. */
	public function GetPointVelocity(inBodyID:BodyID, inPoint:RVec3, ?out:Vec3):Vec3 {
		Hj.bodyGetPointVelocity(world, inBodyID.GetIndexAndSequenceNumber(), inPoint.x, inPoint.y, inPoint.z);
		return Io.vec3(0, out);
	}

	/** Adds a force through a body's center of mass, or at a point, for the next step.

		@param inBodyID  The body.
		@param inForce  The force, in newtons.
		@param inPoint  Optional. Where the force pushes, in the world, in meters; the center of mass when omitted.
		@param inActivationMode  Whether the body wakes. */
	public function AddForce(inBodyID:BodyID, inForce:Vec3, ?inPoint:RVec3, inActivationMode:EActivation):Void {
		if (inPoint == null)
			Hj.bodyAddForce(world, inBodyID.GetIndexAndSequenceNumber(), inForce.x, inForce.y, inForce.z, 0, 0, 0, 0, (cast inActivationMode : Int));
		else
			Hj.bodyAddForce(world, inBodyID.GetIndexAndSequenceNumber(), inForce.x, inForce.y, inForce.z, 1, inPoint.x, inPoint.y, inPoint.z,
				(cast inActivationMode : Int));
	}

	/** Adds a torque for the next step.

		@param inBodyID  The body.
		@param inTorque  The torque, in newton meters.
		@param inActivationMode  Whether the body wakes. */
	public function AddTorque(inBodyID:BodyID, inTorque:Vec3, inActivationMode:EActivation):Void {
		Hj.bodyAddTorque(world, inBodyID.GetIndexAndSequenceNumber(), inTorque.x, inTorque.y, inTorque.z, (cast inActivationMode : Int));
	}

	/** Adds an impulse through a body's center of mass, or at a point, changing its velocity at once.

		@param inBodyID  The body.
		@param inImpulse  The impulse, in kilogram meters a second.
		@param inPoint  Optional. Where the impulse pushes, in the world, in meters; the center of mass when omitted. */
	public function AddImpulse(inBodyID:BodyID, inImpulse:Vec3, ?inPoint:RVec3):Void {
		if (inPoint == null)
			Hj.bodyAddImpulse(world, inBodyID.GetIndexAndSequenceNumber(), inImpulse.x, inImpulse.y, inImpulse.z, 0, 0, 0, 0);
		else
			Hj.bodyAddImpulse(world, inBodyID.GetIndexAndSequenceNumber(), inImpulse.x, inImpulse.y, inImpulse.z, 1, inPoint.x, inPoint.y, inPoint.z);
	}

	/** Adds an angular impulse, changing a body's angular velocity at once.

		@param inBodyID  The body.
		@param inAngularImpulse  The angular impulse, in kilogram square meters a second. */
	public function AddAngularImpulse(inBodyID:BodyID, inAngularImpulse:Vec3):Void {
		Hj.bodyAddAngularImpulse(world, inBodyID.GetIndexAndSequenceNumber(), inAngularImpulse.x, inAngularImpulse.y, inAngularImpulse.z);
	}

	/** Wakes a body.

		@param inBodyID  The body. */
	public function ActivateBody(inBodyID:BodyID):Void {
		Hj.bodyActivate(world, inBodyID.GetIndexAndSequenceNumber());
	}

	/** Puts a body to sleep.

		@param inBodyID  The body. */
	public function DeactivateBody(inBodyID:BodyID):Void {
		Hj.bodyDeactivate(world, inBodyID.GetIndexAndSequenceNumber());
	}

	/** Returns whether a body is awake.

		@param inBodyID  The body.
		@return  True when the body is awake. */
	public function IsActive(inBodyID:BodyID):Bool {
		return Hj.bodyIsActive(world, inBodyID.GetIndexAndSequenceNumber()) != 0;
	}

	/** Changes how a body moves.

		A body made static becomes kinematic or dynamic only when made with `BodyCreationSettings.mAllowDynamicOrKinematic`.

		@param inBodyID  The body.
		@param inMotionType  How the body moves.
		@param inActivationMode  Whether the body wakes. */
	public function SetMotionType(inBodyID:BodyID, inMotionType:EMotionType, inActivationMode:EActivation):Void {
		Hj.bodySetMotionType(world, inBodyID.GetIndexAndSequenceNumber(), cast inMotionType, (cast inActivationMode : Int));
	}

	/** Returns how a body moves.

		@param inBodyID  The body.
		@return  The motion type. */
	public function GetMotionType(inBodyID:BodyID):EMotionType {
		return cast Hj.bodyGetMotionType(world, inBodyID.GetIndexAndSequenceNumber());
	}

	/** Sets how a body's motion is tested for collisions.

		@param inBodyID  The body.
		@param inMotionQuality  The motion quality. */
	public function SetMotionQuality(inBodyID:BodyID, inMotionQuality:EMotionQuality):Void {
		Hj.bodySetMotionQuality(world, inBodyID.GetIndexAndSequenceNumber(), cast inMotionQuality);
	}

	/** Sets a body's bounce.

		@param inBodyID  The body.
		@param inRestitution  The bounce, 0 to 1. */
	public function SetRestitution(inBodyID:BodyID, inRestitution:Float):Void {
		Hj.bodySetRestitution(world, inBodyID.GetIndexAndSequenceNumber(), inRestitution);
	}

	/** Returns a body's bounce.

		@param inBodyID  The body.
		@return  The bounce, 0 to 1. */
	public function GetRestitution(inBodyID:BodyID):Float {
		return Hj.bodyGetRestitution(world, inBodyID.GetIndexAndSequenceNumber());
	}

	/** Sets a body's friction.

		@param inBodyID  The body.
		@param inFriction  The friction, 0 or more. */
	public function SetFriction(inBodyID:BodyID, inFriction:Float):Void {
		Hj.bodySetFriction(world, inBodyID.GetIndexAndSequenceNumber(), inFriction);
	}

	/** Returns a body's friction.

		@param inBodyID  The body.
		@return  The friction. */
	public function GetFriction(inBodyID:BodyID):Float {
		return Hj.bodyGetFriction(world, inBodyID.GetIndexAndSequenceNumber());
	}

	/** Sets how much of the gravity a body falls by.

		@param inBodyID  The body.
		@param inFactor  The factor: 0 floats, 1 falls. */
	public function SetGravityFactor(inBodyID:BodyID, inFactor:Float):Void {
		Hj.bodySetGravityFactor(world, inBodyID.GetIndexAndSequenceNumber(), inFactor);
	}

	/** Returns how much of the gravity a body falls by.

		@param inBodyID  The body.
		@return  The factor. */
	public function GetGravityFactor(inBodyID:BodyID):Float {
		return Hj.bodyGetGravityFactor(world, inBodyID.GetIndexAndSequenceNumber());
	}

	/** Makes a body a sensor or a solid body. `BodyCreationSettings.mIsSensor` says what a sensor detects.

		@param inBodyID  The body.
		@param inIsSensor  Whether the body is a sensor. */
	public function SetIsSensor(inBodyID:BodyID, inIsSensor:Bool):Void {
		Hj.bodySetIsSensor(world, inBodyID.GetIndexAndSequenceNumber(), inIsSensor ? 1 : 0);
	}

	/** Returns whether a body is a sensor.

		@param inBodyID  The body.
		@return  True for a sensor. */
	public function IsSensor(inBodyID:BodyID):Bool {
		return Hj.bodyIsSensor(world, inBodyID.GetIndexAndSequenceNumber()) != 0;
	}

	/** Returns the number a program keeps with a body.

		@param inBodyID  The body.
		@return  The number. */
	public function GetUserData(inBodyID:BodyID):Int {
		return Hj.bodyGetUserData(world, inBodyID.GetIndexAndSequenceNumber());
	}

	/** Sets the number a program keeps with a body.

		@param inBodyID  The body.
		@param inUserData  The number. */
	public function SetUserData(inBodyID:BodyID, inUserData:Int):Void {
		Hj.bodySetUserData(world, inBodyID.GetIndexAndSequenceNumber(), inUserData);
	}

	/** Returns a body's shape where the body is, for asking the shape about a query's hit.

		@param inBodyID  The body.
		@param out  Optional. The transformed shape to fill; a new one when omitted.
		@return  The transformed shape. */
	public function GetTransformedShape(inBodyID:BodyID, ?out:TransformedShape):TransformedShape {
		var transformed = out == null ? new TransformedShape() : out;
		transformed.read(inBodyID, Shape.of(Hj.bodyGetTransformedShape(world, inBodyID.GetIndexAndSequenceNumber())));
		return transformed;
	}

	/** Reads where many bodies are, in one call: an extra of helix-jolt's, for drawing what moved.

		The bodies cross from the module in one copy, where `GetPositionAndRotation` crosses once a body. Only the floats of the
		bodies listed are written.

		@param inBodyIDs  The bodies, such as `PhysicsSystem.GetActiveBodies` fills.
		@param outValues  Receives 7 floats a body: the floats from index `7 * i` are the body `inBodyIDs.at(i)`'s position x, y and z,
		then its rotation's x, y, z and w.
		@return  The number of bodies read: fewer than `inBodyIDs` lists when `outValues` holds fewer. */
	public function GetPositionsAndRotations(inBodyIDs:BodyIDVector, outValues:haxe.io.Float32Array):Int {
		var count = inBodyIDs.size();
		if (outValues.length < count * 7)
			count = Std.int(outValues.length / 7);
		var base = Io.bulk(count * 32);
		for (n in 0...count)
			Io.setBulkI(base, n, inBodyIDs.at(n).GetIndexAndSequenceNumber());
		Hj.bodiesGetPositionsAndRotations(world, count);
		base = Io.bulk(count * 32);
		for (n in 0...count * 7)
			outValues[n] = Io.bulkF(base, count + n);
		return count;
	}

	/** Reads many bodies' transforms, in one call: an extra of helix-jolt's, for drawing them instanced.

		The transforms suit helix-raylib's `DrawMeshInstanced`.

		@param inBodyIDs  The bodies.
		@param outTransforms  Receives a transform a body, in the order of `inBodyIDs`. Transforms in the array are filled in place, and ones are added when it is shorter.
		@return  The number of bodies read. */
	public function GetWorldTransforms(inBodyIDs:BodyIDVector, outTransforms:Array<Mat44>):Int {
		var count = inBodyIDs.size();
		var base = Io.bulk(count * 68);
		for (n in 0...count)
			Io.setBulkI(base, n, inBodyIDs.at(n).GetIndexAndSequenceNumber());
		Hj.bodiesGetWorldTransforms(world, count);
		base = Io.bulk(count * 68);
		for (n in 0...count) {
			if (n == outTransforms.length)
				outTransforms.push(new Mat44());
			var m:helix.math.Matrix4 = outTransforms[n];
			var at = count + n * 16;
			m.m0 = Io.bulkF(base, at);
			m.m1 = Io.bulkF(base, at + 1);
			m.m2 = Io.bulkF(base, at + 2);
			m.m3 = Io.bulkF(base, at + 3);
			m.m4 = Io.bulkF(base, at + 4);
			m.m5 = Io.bulkF(base, at + 5);
			m.m6 = Io.bulkF(base, at + 6);
			m.m7 = Io.bulkF(base, at + 7);
			m.m8 = Io.bulkF(base, at + 8);
			m.m9 = Io.bulkF(base, at + 9);
			m.m10 = Io.bulkF(base, at + 10);
			m.m11 = Io.bulkF(base, at + 11);
			m.m12 = Io.bulkF(base, at + 12);
			m.m13 = Io.bulkF(base, at + 13);
			m.m14 = Io.bulkF(base, at + 14);
			m.m15 = Io.bulkF(base, at + 15);
		}
		return count;
	}
}
