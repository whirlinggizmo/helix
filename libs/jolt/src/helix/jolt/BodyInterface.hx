package helix.jolt;

/** Provides the calls that make, change and read bodies, by their ids. Returned by `PhysicsSystem.GetBodyInterface`.

	```haxe
	var id = bodyInterface.CreateAndAddBody(settings, EActivation_Activate);
	var position = new RVec3();
	jolt.Step(1 / 60, 1);
	bodyInterface.GetPosition(id, position);
	```

	A call on an id that names no body is skipped, and one returning a value returns zero, the identity or false. */
class BodyInterface {
	function new() {}

	/** Makes a body, not yet in the simulation.

		`AddBody` puts the body in the simulation. See `CreateAndAddBody` for making and adding a body in one call.

		@param inSettings  What the body is made from, read once.
		@return  The body, or null when the system holds `JoltSettings.mMaxBodies` already. */
	public function CreateBody(inSettings:BodyCreationSettings):Body {
		throw "not built yet";
	}

	/** Makes a body and adds it to the simulation.

		@param inSettings  What the body is made from, read once.
		@param inActivationMode  Whether the body wakes.
		@return  The body's id, invalid when the system holds `JoltSettings.mMaxBodies` already. */
	public function CreateAndAddBody(inSettings:BodyCreationSettings, inActivationMode:EActivation):BodyID {
		throw "not built yet";
	}

	/** Destroys a body, which must have been removed. Its id names no body after.

		@param inBodyID  The body. */
	public function DestroyBody(inBodyID:BodyID):Void {
		throw "not built yet";
	}

	/** Adds a body to the simulation.

		@param inBodyID  The body.
		@param inActivationMode  Whether the body wakes. */
	public function AddBody(inBodyID:BodyID, inActivationMode:EActivation):Void {
		throw "not built yet";
	}

	/** Removes a body from the simulation, keeping it to add again.

		@param inBodyID  The body. */
	public function RemoveBody(inBodyID:BodyID):Void {
		throw "not built yet";
	}

	/** Returns whether a body is in the simulation.

		@param inBodyID  The body.
		@return  True after `AddBody` and before `RemoveBody`. */
	public function IsAdded(inBodyID:BodyID):Bool {
		throw "not built yet";
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
		throw "not built yet";
	}

	/** Returns a body's shape.

		@param inBodyID  The body.
		@return  The shape. */
	public function GetShape(inBodyID:BodyID):Shape {
		throw "not built yet";
	}

	/** Replaces a body's shape.

		@param inBodyID  The body.
		@param inShape  The shape.
		@param inUpdateMassProperties  Whether the mass and inertia are worked out again from the shape.
		@param inActivationMode  Whether the body wakes. */
	public function SetShape(inBodyID:BodyID, inShape:Shape, inUpdateMassProperties:Bool, inActivationMode:EActivation):Void {
		throw "not built yet";
	}

	/** Moves a body to another object layer.

		@param inBodyID  The body.
		@param inLayer  The object layer. */
	public function SetObjectLayer(inBodyID:BodyID, inLayer:Int):Void {
		throw "not built yet";
	}

	/** Returns a body's object layer.

		@param inBodyID  The body.
		@return  The object layer. */
	public function GetObjectLayer(inBodyID:BodyID):Int {
		throw "not built yet";
	}

	/** Places a body.

		A body set somewhere moves there at once, through what is between. See `MoveKinematic` for moving a kinematic body that pushes what it meets.

		@param inBodyID  The body.
		@param inPosition  The position, in meters.
		@param inRotation  The rotation.
		@param inActivationMode  Whether the body wakes. */
	public function SetPositionAndRotation(inBodyID:BodyID, inPosition:RVec3, inRotation:Quat, inActivationMode:EActivation):Void {
		throw "not built yet";
	}

	/** Reads where a body is.

		@param inBodyID  The body.
		@param outPosition  Receives the position, in meters.
		@param outRotation  Receives the rotation. */
	public function GetPositionAndRotation(inBodyID:BodyID, outPosition:RVec3, outRotation:Quat):Void {
		throw "not built yet";
	}

	/** Moves a body.

		@param inBodyID  The body.
		@param inPosition  The position, in meters.
		@param inActivationMode  Whether the body wakes. */
	public function SetPosition(inBodyID:BodyID, inPosition:RVec3, inActivationMode:EActivation):Void {
		throw "not built yet";
	}

	/** Returns a body's position.

		@param inBodyID  The body.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The position, in meters. */
	public function GetPosition(inBodyID:BodyID, ?out:RVec3):RVec3 {
		throw "not built yet";
	}

	/** Turns a body.

		@param inBodyID  The body.
		@param inRotation  The rotation.
		@param inActivationMode  Whether the body wakes. */
	public function SetRotation(inBodyID:BodyID, inRotation:Quat, inActivationMode:EActivation):Void {
		throw "not built yet";
	}

	/** Returns a body's rotation.

		@param inBodyID  The body.
		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The rotation. */
	public function GetRotation(inBodyID:BodyID, ?out:Quat):Quat {
		throw "not built yet";
	}

	/** Returns a body's transform: its rotation and position, for drawing it.

		@param inBodyID  The body.
		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public function GetWorldTransform(inBodyID:BodyID, ?out:RMat44):RMat44 {
		throw "not built yet";
	}

	/** Returns the transform of a body's center of mass.

		@param inBodyID  The body.
		@param out  Optional. The transform to fill; a new one when omitted.
		@return  The transform. */
	public function GetCenterOfMassTransform(inBodyID:BodyID, ?out:RMat44):RMat44 {
		throw "not built yet";
	}

	/** Moves a kinematic body to a place over a step, pushing the dynamic bodies it meets.

		Called before `JoltInterface.Step`: the body arrives at the place at the end of that step.

		@param inBodyID  The body.
		@param inTargetPosition  Where the body arrives, in meters.
		@param inTargetRotation  The rotation it arrives at.
		@param inDeltaTime  The seconds of the next step, as passed to `JoltInterface.Step`. */
	public function MoveKinematic(inBodyID:BodyID, inTargetPosition:RVec3, inTargetRotation:Quat, inDeltaTime:Float):Void {
		throw "not built yet";
	}

	/** Sets a body's velocity.

		@param inBodyID  The body.
		@param inLinearVelocity  The velocity, in meters a second. */
	public function SetLinearVelocity(inBodyID:BodyID, inLinearVelocity:Vec3):Void {
		throw "not built yet";
	}

	/** Returns a body's velocity.

		@param inBodyID  The body.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The velocity, in meters a second. */
	public function GetLinearVelocity(inBodyID:BodyID, ?out:Vec3):Vec3 {
		throw "not built yet";
	}

	/** Adds to a body's velocity.

		@param inBodyID  The body.
		@param inLinearVelocity  The velocity added, in meters a second. */
	public function AddLinearVelocity(inBodyID:BodyID, inLinearVelocity:Vec3):Void {
		throw "not built yet";
	}

	/** Sets a body's angular velocity.

		@param inBodyID  The body.
		@param inAngularVelocity  The angular velocity, in radians a second about each axis. */
	public function SetAngularVelocity(inBodyID:BodyID, inAngularVelocity:Vec3):Void {
		throw "not built yet";
	}

	/** Returns a body's angular velocity.

		@param inBodyID  The body.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The angular velocity, in radians a second about each axis. */
	public function GetAngularVelocity(inBodyID:BodyID, ?out:Vec3):Vec3 {
		throw "not built yet";
	}

	/** Returns the velocity of a point on a body.

		@param inBodyID  The body.
		@param inPoint  The point, in the world, in meters.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The velocity, in meters a second. */
	public function GetPointVelocity(inBodyID:BodyID, inPoint:RVec3, ?out:Vec3):Vec3 {
		throw "not built yet";
	}

	/** Adds a force through a body's center of mass, or at a point, for the next step.

		@param inBodyID  The body.
		@param inForce  The force, in newtons.
		@param inPoint  Optional. Where the force pushes, in the world, in meters; the center of mass when omitted.
		@param inActivationMode  Whether the body wakes. */
	public function AddForce(inBodyID:BodyID, inForce:Vec3, ?inPoint:RVec3, inActivationMode:EActivation):Void {
		throw "not built yet";
	}

	/** Adds a torque for the next step.

		@param inBodyID  The body.
		@param inTorque  The torque, in newton meters.
		@param inActivationMode  Whether the body wakes. */
	public function AddTorque(inBodyID:BodyID, inTorque:Vec3, inActivationMode:EActivation):Void {
		throw "not built yet";
	}

	/** Adds an impulse through a body's center of mass, or at a point, changing its velocity at once.

		@param inBodyID  The body.
		@param inImpulse  The impulse, in kilogram meters a second.
		@param inPoint  Optional. Where the impulse pushes, in the world, in meters; the center of mass when omitted. */
	public function AddImpulse(inBodyID:BodyID, inImpulse:Vec3, ?inPoint:RVec3):Void {
		throw "not built yet";
	}

	/** Adds an angular impulse, changing a body's angular velocity at once.

		@param inBodyID  The body.
		@param inAngularImpulse  The angular impulse, in kilogram square meters a second. */
	public function AddAngularImpulse(inBodyID:BodyID, inAngularImpulse:Vec3):Void {
		throw "not built yet";
	}

	/** Wakes a body.

		@param inBodyID  The body. */
	public function ActivateBody(inBodyID:BodyID):Void {
		throw "not built yet";
	}

	/** Puts a body to sleep.

		@param inBodyID  The body. */
	public function DeactivateBody(inBodyID:BodyID):Void {
		throw "not built yet";
	}

	/** Returns whether a body is awake.

		@param inBodyID  The body.
		@return  True when the body is awake. */
	public function IsActive(inBodyID:BodyID):Bool {
		throw "not built yet";
	}

	/** Changes how a body moves.

		A body made static becomes kinematic or dynamic only when made with `BodyCreationSettings.mAllowDynamicOrKinematic`.

		@param inBodyID  The body.
		@param inMotionType  How the body moves.
		@param inActivationMode  Whether the body wakes. */
	public function SetMotionType(inBodyID:BodyID, inMotionType:EMotionType, inActivationMode:EActivation):Void {
		throw "not built yet";
	}

	/** Returns how a body moves.

		@param inBodyID  The body.
		@return  The motion type. */
	public function GetMotionType(inBodyID:BodyID):EMotionType {
		throw "not built yet";
	}

	/** Sets how a body's motion is tested for collisions.

		@param inBodyID  The body.
		@param inMotionQuality  The motion quality. */
	public function SetMotionQuality(inBodyID:BodyID, inMotionQuality:EMotionQuality):Void {
		throw "not built yet";
	}

	/** Sets a body's bounce.

		@param inBodyID  The body.
		@param inRestitution  The bounce, 0 to 1. */
	public function SetRestitution(inBodyID:BodyID, inRestitution:Float):Void {
		throw "not built yet";
	}

	/** Returns a body's bounce.

		@param inBodyID  The body.
		@return  The bounce, 0 to 1. */
	public function GetRestitution(inBodyID:BodyID):Float {
		throw "not built yet";
	}

	/** Sets a body's friction.

		@param inBodyID  The body.
		@param inFriction  The friction, 0 or more. */
	public function SetFriction(inBodyID:BodyID, inFriction:Float):Void {
		throw "not built yet";
	}

	/** Returns a body's friction.

		@param inBodyID  The body.
		@return  The friction. */
	public function GetFriction(inBodyID:BodyID):Float {
		throw "not built yet";
	}

	/** Sets how much of the gravity a body falls by.

		@param inBodyID  The body.
		@param inFactor  The factor: 0 floats, 1 falls. */
	public function SetGravityFactor(inBodyID:BodyID, inFactor:Float):Void {
		throw "not built yet";
	}

	/** Returns how much of the gravity a body falls by.

		@param inBodyID  The body.
		@return  The factor. */
	public function GetGravityFactor(inBodyID:BodyID):Float {
		throw "not built yet";
	}

	/** Makes a body a sensor or a solid body. `BodyCreationSettings.mIsSensor` says what a sensor detects.

		@param inBodyID  The body.
		@param inIsSensor  Whether the body is a sensor. */
	public function SetIsSensor(inBodyID:BodyID, inIsSensor:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether a body is a sensor.

		@param inBodyID  The body.
		@return  True for a sensor. */
	public function IsSensor(inBodyID:BodyID):Bool {
		throw "not built yet";
	}

	/** Returns the number a program keeps with a body.

		@param inBodyID  The body.
		@return  The number. */
	public function GetUserData(inBodyID:BodyID):Int {
		throw "not built yet";
	}

	/** Sets the number a program keeps with a body.

		@param inBodyID  The body.
		@param inUserData  The number. */
	public function SetUserData(inBodyID:BodyID, inUserData:Int):Void {
		throw "not built yet";
	}

	/** Returns a body's shape where the body is, for asking the shape about a query's hit.

		@param inBodyID  The body.
		@param out  Optional. The transformed shape to fill; a new one when omitted.
		@return  The transformed shape. */
	public function GetTransformedShape(inBodyID:BodyID, ?out:TransformedShape):TransformedShape {
		throw "not built yet";
	}

	/** Reads where many bodies are, in one call: an extra of helix-jolt's, for drawing what moved.

		The bodies cross from the module in one copy, where `GetPositionAndRotation` crosses once a body. Only the floats of the
		bodies listed are written.

		@param inBodyIDs  The bodies, such as `PhysicsSystem.GetActiveBodies` fills.
		@param outValues  Receives 7 floats a body: the floats from index `7 * i` are the body `inBodyIDs.at(i)`'s position x, y and z,
		then its rotation's x, y, z and w.
		@return  The number of bodies read: fewer than `inBodyIDs` lists when `outValues` holds fewer. */
	public function GetPositionsAndRotations(inBodyIDs:BodyIDVector, outValues:haxe.io.Float32Array):Int {
		throw "not built yet";
	}

	/** Reads many bodies' transforms, in one call: an extra of helix-jolt's, for drawing them instanced.

		The transforms suit helix-raylib's `DrawMeshInstanced`.

		@param inBodyIDs  The bodies.
		@param outTransforms  Receives a transform a body, in the order of `inBodyIDs`. Transforms in the array are filled in place, and ones are added when it is shorter.
		@return  The number of bodies read. */
	public function GetWorldTransforms(inBodyIDs:BodyIDVector, outTransforms:Array<Mat44>):Int {
		throw "not built yet";
	}
}
