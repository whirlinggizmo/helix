# helix.jolt

[Back to the library](README.md)

## AABox

*class* in [`libs/jolt/src/helix/jolt/AABox.hx`](../src/helix/jolt/AABox.hx), `import helix.jolt.AABox;`

Represents an axis-aligned box, by its lowest and highest corners.

```haxe
function new(?inMin:Vec3, ?inMax:Vec3)
var mMin:Vec3
var mMax:Vec3
function GetCenter(?out:Vec3):Vec3
function GetExtent(?out:Vec3):Vec3
```

- `new`: Creates a box.
  - `inMin`: Optional. The lowest corner; defaults to (0, 0, 0).
  - `inMax`: Optional. The highest corner; defaults to (0, 0, 0).
- `mMin`: Gets or sets the lowest corner.
- `mMax`: Gets or sets the highest corner.
- `GetCenter`: Returns the box's center.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The center.
- `GetExtent`: Returns half the box's size along each axis.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The half extent.

## Body

*class* in [`libs/jolt/src/helix/jolt/Body.hx`](../src/helix/jolt/Body.hx), `import helix.jolt.Body;`

Represents a body, returned by `BodyInterface.CreateBody` and, by its id, by `BodyLockInterfaceNoLock.TryGetBody`. Reads the body as it is now. `BodyInterface` changes it, by its id (`GetID`).

```haxe
function GetID():BodyID
function IsActive():Bool
function IsStatic():Bool
function IsKinematic():Bool
function IsDynamic():Bool
function GetMotionType():EMotionType
function IsSensor():Bool
function GetObjectLayer():Int
function GetFriction():Float
function GetRestitution():Float
function GetPosition(?out:RVec3):RVec3
function GetRotation(?out:Quat):Quat
function GetWorldTransform(?out:RMat44):RMat44
function GetLinearVelocity(?out:Vec3):Vec3
function GetAngularVelocity(?out:Vec3):Vec3
function GetWorldSpaceBounds(?out:AABox):AABox
function GetShape():Shape
function GetWorldSpaceSurfaceNormal(inSubShapeID:SubShapeID, inPosition:RVec3, ?out:Vec3):Vec3
function GetUserData():Int
```

- `GetID`: Returns the body's id.
  - returns: The id.
- `IsActive`: Returns whether the body is awake.
  - returns: True when awake.
- `IsStatic`: Returns whether the body never moves.
  - returns: True for a static body.
- `IsKinematic`: Returns whether the program moves the body.
  - returns: True for a kinematic body.
- `IsDynamic`: Returns whether the simulation moves the body.
  - returns: True for a dynamic body.
- `GetMotionType`: Returns how the body moves.
  - returns: The motion type.
- `IsSensor`: Returns whether the body is a sensor.
  - returns: True for a sensor.
- `GetObjectLayer`: Returns the body's object layer.
  - returns: The object layer.
- `GetFriction`: Returns the body's friction.
  - returns: The friction.
- `GetRestitution`: Returns the body's bounce.
  - returns: The bounce, 0 to 1.
- `GetPosition`: Returns the body's position.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The position, in meters.
- `GetRotation`: Returns the body's rotation.
  - `out`: Optional. The quaternion to fill; a new one when omitted.
  - returns: The rotation.
- `GetWorldTransform`: Returns the body's transform.
  - `out`: Optional. The transform to fill; a new one when omitted.
  - returns: The transform.
- `GetLinearVelocity`: Returns the body's velocity.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The velocity, in meters a second.
- `GetAngularVelocity`: Returns the body's angular velocity.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The angular velocity, in radians a second about each axis.
- `GetWorldSpaceBounds`: Returns the body's bounds in the world.
  - `out`: Optional. The box to fill; a new one when omitted.
  - returns: The bounds.
- `GetShape`: Returns the body's shape.
  - returns: The shape.
- `GetWorldSpaceSurfaceNormal`: Returns the normal of the body's surface at a point a query hit.
  - `inSubShapeID`: The part of the shape hit, from the query's result.
  - `inPosition`: The point, in the world, in meters.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The normal, of length 1.
- `GetUserData`: Returns the number the program keeps with the body.
  - returns: The number.

## BodyCreationSettings

*class* in [`libs/jolt/src/helix/jolt/BodyCreationSettings.hx`](../src/helix/jolt/BodyCreationSettings.hx), `import helix.jolt.BodyCreationSettings;`

Represents what a body is made from: its shape, where it starts and how it moves. Read once by `BodyInterface.CreateBody`, and may be changed and read again for another body.

```haxe
var settings = new BodyCreationSettings(new BoxShape(new Vec3(0.5, 0.5, 0.5)), new RVec3(0, 10, 0), Quat.sIdentity(),
EMotionType_Dynamic, LAYER_MOVING);
settings.mRestitution = 0.5;
var id = bodyInterface.CreateAndAddBody(settings, EActivation_Activate);
```

The defaults are Jolt's.

```haxe
function new(?inShape:Shape, ?inPosition:RVec3, ?inRotation:Quat, ?inMotionType:EMotionType = EMotionType_Dynamic, ?inObjectLayer:Int = 0)
var mPosition:RVec3
var mRotation:Quat
var mLinearVelocity:Vec3
var mAngularVelocity:Vec3
var mUserData:Int
var mObjectLayer:Int
var mMotionType:EMotionType
var mAllowedDOFs:EAllowedDOFs
var mAllowDynamicOrKinematic:Bool
var mIsSensor:Bool
var mMotionQuality:EMotionQuality
var mAllowSleeping:Bool
var mFriction:Float
var mRestitution:Float
var mLinearDamping:Float
var mAngularDamping:Float
var mMaxLinearVelocity:Float
var mMaxAngularVelocity:Float
var mGravityFactor:Float
var mOverrideMassProperties:EOverrideMassProperties
var mMassPropertiesOverride:MassProperties
function GetShape():Null<Shape>
function SetShape(inShape:Shape):Void
```

- `new`: Creates settings for a body.
  - `inShape`: Optional. The shape; when omitted, set with `SetShape` before the body is made.
  - `inPosition`: Optional. The starting position; defaults to (0, 0, 0).
  - `inRotation`: Optional. The starting rotation; defaults to the identity.
  - `inMotionType`: Optional. How the body moves; defaults to `EMotionType_Dynamic`.
  - `inObjectLayer`: Optional. The object layer; defaults to 0.
- `mPosition`: Gets or sets the starting position, in meters.
- `mRotation`: Gets or sets the starting rotation.
- `mLinearVelocity`: Gets or sets the starting velocity, in meters a second.
- `mAngularVelocity`: Gets or sets the starting angular velocity, in radians a second about each axis.
- `mUserData`: Gets or sets a number the program keeps with the body, such as an index into its own list. Defaults to 0.
- `mObjectLayer`: Gets or sets the body's object layer.
- `mMotionType`: Gets or sets how the body moves. Defaults to `EMotionType_Dynamic`.
- `mAllowedDOFs`: Gets or sets the directions the body may move and turn in. Defaults to `EAllowedDOFs_All`.
- `mAllowDynamicOrKinematic`: Gets or sets a value indicating whether a static body may later become kinematic or dynamic. Defaults to false.
- `mIsSensor`: Gets or sets a value indicating whether the body is a sensor: it collides with nothing, and its contacts are reported. Defaults to false.
  A static sensor detects the awake dynamic and kinematic bodies in layers its own layer collides with. A body falling asleep inside a static sensor is reported as leaving it. A kinematic sensor detects sleeping bodies too.
- `mMotionQuality`: Gets or sets how the body's motion is tested for collisions. Defaults to `EMotionQuality_Discrete`.
- `mAllowSleeping`: Gets or sets a value indicating whether the body may sleep. Defaults to true.
- `mFriction`: Gets or sets the friction, 0 or more: 0 ice, 1 rubber. Defaults to 0.2.
- `mRestitution`: Gets or sets the bounce, 0 to 1. Defaults to 0.
- `mLinearDamping`: Gets or sets the share of the velocity lost each second, 0 to 1. Defaults to 0.05.
- `mAngularDamping`: Gets or sets the share of the angular velocity lost each second, 0 to 1. Defaults to 0.05.
- `mMaxLinearVelocity`: Gets or sets the fastest the body moves, in meters a second. Defaults to 500.
- `mMaxAngularVelocity`: Gets or sets the fastest the body turns, in radians a second. Defaults to 0.25 pi times 60.
- `mGravityFactor`: Gets or sets how much of the gravity the body falls by. Defaults to 1.
- `mOverrideMassProperties`: Gets or sets how the mass and inertia are found. Defaults to `EOverrideMassProperties_CalculateMassAndInertia`.
- `mMassPropertiesOverride`: Gets or sets the mass and inertia used as `mOverrideMassProperties` says.
- `GetShape`: Returns the shape.
  - returns: The shape, or null if there is none.
- `SetShape`: Sets the shape.
  - `inShape`: The shape.

## BodyFilter

*class* in [`libs/jolt/src/helix/jolt/BodyFilter.hx`](../src/helix/jolt/BodyFilter.hx), `import helix.jolt.BodyFilter;`

Represents which bodies a query tests. Made as an `IgnoreSingleBodyFilter` or an `IgnoreMultipleBodiesFilter`.

## BodyID

*abstract* in [`libs/jolt/src/helix/jolt/BodyID.hx`](../src/helix/jolt/BodyID.hx), `import helix.jolt.BodyID;`

Represents a body's id: its index in the system and a sequence number, so a destroyed body's id is never another body's. Holds no object. Two ids are compared with `==` and `!=`, by value.

```haxe
function GetIndex():Int
function GetIndexAndSequenceNumber():Int
function IsInvalid():Bool
```

- `GetIndex`: Returns the body's index in the system.
  - returns: The index.
- `GetIndexAndSequenceNumber`: Returns the id's whole value, the index and the sequence number together.
  - returns: The value.
- `IsInvalid`: Returns whether the id names a body. A query that hits nothing leaves its result's body id invalid.
  - returns: False for the invalid id.

## BodyIDVector

*class* in [`libs/jolt/src/helix/jolt/BodyIDVector.hx`](../src/helix/jolt/BodyIDVector.hx), `import helix.jolt.BodyIDVector;`

Represents a list of body ids, filled by `PhysicsSystem.GetActiveBodies` and read by the bulk reads of `BodyInterface`. Reused from one step to the next, it allocates only when it grows.

```haxe
function new()
function size():Int
function at(inIndex:Int):BodyID
function push_back(inBodyID:BodyID):Void
function clear():Void
```

- `new`: Creates an empty list.
- `size`: Returns the number of ids.
  - returns: The count.
- `at`: Returns an id.
  - `inIndex`: The id's index, 0 to `size() - 1`.
  - returns: The id.
- `push_back`: Adds an id at the end.
  - `inBodyID`: The id.
- `clear`: Removes every id, keeping the memory.

## BodyInterface

*class* in [`libs/jolt/src/helix/jolt/BodyInterface.hx`](../src/helix/jolt/BodyInterface.hx), `import helix.jolt.BodyInterface;`

Provides the calls that make, change and read bodies, by their ids. Returned by `PhysicsSystem.GetBodyInterface`.

```haxe
var id = bodyInterface.CreateAndAddBody(settings, EActivation_Activate);
var position = new RVec3();
jolt.Step(1 / 60, 1);
bodyInterface.GetPosition(id, position);
```

A call on an id that names no body is skipped, and one returning a value returns zero, the identity or false.

```haxe
function CreateBody(inSettings:BodyCreationSettings):Body
function CreateAndAddBody(inSettings:BodyCreationSettings, inActivationMode:EActivation):BodyID
function DestroyBody(inBodyID:BodyID):Void
function AddBody(inBodyID:BodyID, inActivationMode:EActivation):Void
function RemoveBody(inBodyID:BodyID):Void
function IsAdded(inBodyID:BodyID):Bool
function CreateConstraint(inSettings:TwoBodyConstraintSettings<CreateConstraint.T>, inBodyID1:BodyID, inBodyID2:BodyID):CreateConstraint.T
function GetShape(inBodyID:BodyID):Shape
function SetShape(inBodyID:BodyID, inShape:Shape, inUpdateMassProperties:Bool, inActivationMode:EActivation):Void
function SetObjectLayer(inBodyID:BodyID, inLayer:Int):Void
function GetObjectLayer(inBodyID:BodyID):Int
function SetPositionAndRotation(inBodyID:BodyID, inPosition:RVec3, inRotation:Quat, inActivationMode:EActivation):Void
function GetPositionAndRotation(inBodyID:BodyID, outPosition:RVec3, outRotation:Quat):Void
function SetPosition(inBodyID:BodyID, inPosition:RVec3, inActivationMode:EActivation):Void
function GetPosition(inBodyID:BodyID, ?out:RVec3):RVec3
function SetRotation(inBodyID:BodyID, inRotation:Quat, inActivationMode:EActivation):Void
function GetRotation(inBodyID:BodyID, ?out:Quat):Quat
function GetWorldTransform(inBodyID:BodyID, ?out:RMat44):RMat44
function GetCenterOfMassTransform(inBodyID:BodyID, ?out:RMat44):RMat44
function MoveKinematic(inBodyID:BodyID, inTargetPosition:RVec3, inTargetRotation:Quat, inDeltaTime:Float):Void
function SetLinearVelocity(inBodyID:BodyID, inLinearVelocity:Vec3):Void
function GetLinearVelocity(inBodyID:BodyID, ?out:Vec3):Vec3
function AddLinearVelocity(inBodyID:BodyID, inLinearVelocity:Vec3):Void
function SetAngularVelocity(inBodyID:BodyID, inAngularVelocity:Vec3):Void
function GetAngularVelocity(inBodyID:BodyID, ?out:Vec3):Vec3
function GetPointVelocity(inBodyID:BodyID, inPoint:RVec3, ?out:Vec3):Vec3
function AddForce(inBodyID:BodyID, inForce:Vec3, ?inPoint:RVec3, inActivationMode:EActivation):Void
function AddTorque(inBodyID:BodyID, inTorque:Vec3, inActivationMode:EActivation):Void
function AddImpulse(inBodyID:BodyID, inImpulse:Vec3, ?inPoint:RVec3):Void
function AddAngularImpulse(inBodyID:BodyID, inAngularImpulse:Vec3):Void
function ActivateBody(inBodyID:BodyID):Void
function DeactivateBody(inBodyID:BodyID):Void
function IsActive(inBodyID:BodyID):Bool
function SetMotionType(inBodyID:BodyID, inMotionType:EMotionType, inActivationMode:EActivation):Void
function GetMotionType(inBodyID:BodyID):EMotionType
function SetMotionQuality(inBodyID:BodyID, inMotionQuality:EMotionQuality):Void
function SetRestitution(inBodyID:BodyID, inRestitution:Float):Void
function GetRestitution(inBodyID:BodyID):Float
function SetFriction(inBodyID:BodyID, inFriction:Float):Void
function GetFriction(inBodyID:BodyID):Float
function SetGravityFactor(inBodyID:BodyID, inFactor:Float):Void
function GetGravityFactor(inBodyID:BodyID):Float
function SetIsSensor(inBodyID:BodyID, inIsSensor:Bool):Void
function IsSensor(inBodyID:BodyID):Bool
function GetUserData(inBodyID:BodyID):Int
function SetUserData(inBodyID:BodyID, inUserData:Int):Void
function GetTransformedShape(inBodyID:BodyID, ?out:TransformedShape):TransformedShape
function GetPositionsAndRotations(inBodyIDs:BodyIDVector, outValues:haxe.io.Float32Array):Int
function GetWorldTransforms(inBodyIDs:BodyIDVector, outTransforms:Array<Mat44>):Int
```

- `CreateBody`: Makes a body, not yet in the simulation.
  - `inSettings`: What the body is made from, read once.
  - returns: The body, or null when the system holds `JoltSettings.mMaxBodies` already.

  `AddBody` puts the body in the simulation. See `CreateAndAddBody` for making and adding a body in one call.
- `CreateAndAddBody`: Makes a body and adds it to the simulation.
  - `inSettings`: What the body is made from, read once.
  - `inActivationMode`: Whether the body wakes.
  - returns: The body's id, invalid when the system holds `JoltSettings.mMaxBodies` already.
- `DestroyBody`: Destroys a body, which must have been removed. Its id names no body after.
  - `inBodyID`: The body.
- `AddBody`: Adds a body to the simulation.
  - `inBodyID`: The body.
  - `inActivationMode`: Whether the body wakes.
- `RemoveBody`: Removes a body from the simulation, keeping it to add again.
  - `inBodyID`: The body.
- `IsAdded`: Returns whether a body is in the simulation.
  - `inBodyID`: The body.
  - returns: True after `AddBody` and before `RemoveBody`.
- `CreateConstraint`: Makes a constraint between two bodies, not yet acting.
  - `inSettings`: The constraint's kind and settings, read once.
  - `inBodyID1`: The first body.
  - `inBodyID2`: The second body.
  - returns: The constraint, of the kind the settings make (a `HingeConstraint` from `HingeConstraintSettings`), or null when both ids are invalid.

  `PhysicsSystem.AddConstraint` makes it act. An invalid id for either body, such as `JoltInterface.sGetFixedToWorldBody().GetID()`, fixes the other body to the world.

  ```haxe
  var door = bodyInterface.CreateConstraint(hingeSettings, JoltInterface.sGetFixedToWorldBody().GetID(), doorID);
  physicsSystem.AddConstraint(door);
  door.SetMotorState(EMotorState_Velocity);
  ```
- `GetShape`: Returns a body's shape.
  - `inBodyID`: The body.
  - returns: The shape.
- `SetShape`: Replaces a body's shape.
  - `inBodyID`: The body.
  - `inShape`: The shape.
  - `inUpdateMassProperties`: Whether the mass and inertia are worked out again from the shape.
  - `inActivationMode`: Whether the body wakes.
- `SetObjectLayer`: Moves a body to another object layer.
  - `inBodyID`: The body.
  - `inLayer`: The object layer.
- `GetObjectLayer`: Returns a body's object layer.
  - `inBodyID`: The body.
  - returns: The object layer.
- `SetPositionAndRotation`: Places a body.
  - `inBodyID`: The body.
  - `inPosition`: The position, in meters.
  - `inRotation`: The rotation.
  - `inActivationMode`: Whether the body wakes.

  A body set somewhere moves there at once, through what is between. See `MoveKinematic` for moving a kinematic body that pushes what it meets.
- `GetPositionAndRotation`: Reads where a body is.
  - `inBodyID`: The body.
  - `outPosition`: Receives the position, in meters.
  - `outRotation`: Receives the rotation.
- `SetPosition`: Moves a body.
  - `inBodyID`: The body.
  - `inPosition`: The position, in meters.
  - `inActivationMode`: Whether the body wakes.
- `GetPosition`: Returns a body's position.
  - `inBodyID`: The body.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The position, in meters.
- `SetRotation`: Turns a body.
  - `inBodyID`: The body.
  - `inRotation`: The rotation.
  - `inActivationMode`: Whether the body wakes.
- `GetRotation`: Returns a body's rotation.
  - `inBodyID`: The body.
  - `out`: Optional. The quaternion to fill; a new one when omitted.
  - returns: The rotation.
- `GetWorldTransform`: Returns a body's transform: its rotation and position, for drawing it.
  - `inBodyID`: The body.
  - `out`: Optional. The transform to fill; a new one when omitted.
  - returns: The transform.
- `GetCenterOfMassTransform`: Returns the transform of a body's center of mass.
  - `inBodyID`: The body.
  - `out`: Optional. The transform to fill; a new one when omitted.
  - returns: The transform.
- `MoveKinematic`: Moves a kinematic body to a place over a step, pushing the dynamic bodies it meets.
  - `inBodyID`: The body.
  - `inTargetPosition`: Where the body arrives, in meters.
  - `inTargetRotation`: The rotation it arrives at.
  - `inDeltaTime`: The seconds of the next step, as passed to `JoltInterface.Step`.

  Called before `JoltInterface.Step`: the body arrives at the place at the end of that step.
- `SetLinearVelocity`: Sets a body's velocity.
  - `inBodyID`: The body.
  - `inLinearVelocity`: The velocity, in meters a second.
- `GetLinearVelocity`: Returns a body's velocity.
  - `inBodyID`: The body.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The velocity, in meters a second.
- `AddLinearVelocity`: Adds to a body's velocity.
  - `inBodyID`: The body.
  - `inLinearVelocity`: The velocity added, in meters a second.
- `SetAngularVelocity`: Sets a body's angular velocity.
  - `inBodyID`: The body.
  - `inAngularVelocity`: The angular velocity, in radians a second about each axis.
- `GetAngularVelocity`: Returns a body's angular velocity.
  - `inBodyID`: The body.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The angular velocity, in radians a second about each axis.
- `GetPointVelocity`: Returns the velocity of a point on a body.
  - `inBodyID`: The body.
  - `inPoint`: The point, in the world, in meters.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The velocity, in meters a second.
- `AddForce`: Adds a force through a body's center of mass, or at a point, for the next step.
  - `inBodyID`: The body.
  - `inForce`: The force, in newtons.
  - `inPoint`: Optional. Where the force pushes, in the world, in meters; the center of mass when omitted.
  - `inActivationMode`: Whether the body wakes.
- `AddTorque`: Adds a torque for the next step.
  - `inBodyID`: The body.
  - `inTorque`: The torque, in newton meters.
  - `inActivationMode`: Whether the body wakes.
- `AddImpulse`: Adds an impulse through a body's center of mass, or at a point, changing its velocity at once.
  - `inBodyID`: The body.
  - `inImpulse`: The impulse, in kilogram meters a second.
  - `inPoint`: Optional. Where the impulse pushes, in the world, in meters; the center of mass when omitted.
- `AddAngularImpulse`: Adds an angular impulse, changing a body's angular velocity at once.
  - `inBodyID`: The body.
  - `inAngularImpulse`: The angular impulse, in kilogram square meters a second.
- `ActivateBody`: Wakes a body.
  - `inBodyID`: The body.
- `DeactivateBody`: Puts a body to sleep.
  - `inBodyID`: The body.
- `IsActive`: Returns whether a body is awake.
  - `inBodyID`: The body.
  - returns: True when the body is awake.
- `SetMotionType`: Changes how a body moves.
  - `inBodyID`: The body.
  - `inMotionType`: How the body moves.
  - `inActivationMode`: Whether the body wakes.

  A body made static becomes kinematic or dynamic only when made with `BodyCreationSettings.mAllowDynamicOrKinematic`.
- `GetMotionType`: Returns how a body moves.
  - `inBodyID`: The body.
  - returns: The motion type.
- `SetMotionQuality`: Sets how a body's motion is tested for collisions.
  - `inBodyID`: The body.
  - `inMotionQuality`: The motion quality.
- `SetRestitution`: Sets a body's bounce.
  - `inBodyID`: The body.
  - `inRestitution`: The bounce, 0 to 1.
- `GetRestitution`: Returns a body's bounce.
  - `inBodyID`: The body.
  - returns: The bounce, 0 to 1.
- `SetFriction`: Sets a body's friction.
  - `inBodyID`: The body.
  - `inFriction`: The friction, 0 or more.
- `GetFriction`: Returns a body's friction.
  - `inBodyID`: The body.
  - returns: The friction.
- `SetGravityFactor`: Sets how much of the gravity a body falls by.
  - `inBodyID`: The body.
  - `inFactor`: The factor: 0 floats, 1 falls.
- `GetGravityFactor`: Returns how much of the gravity a body falls by.
  - `inBodyID`: The body.
  - returns: The factor.
- `SetIsSensor`: Makes a body a sensor or a solid body. `BodyCreationSettings.mIsSensor` says what a sensor detects.
  - `inBodyID`: The body.
  - `inIsSensor`: Whether the body is a sensor.
- `IsSensor`: Returns whether a body is a sensor.
  - `inBodyID`: The body.
  - returns: True for a sensor.
- `GetUserData`: Returns the number a program keeps with a body.
  - `inBodyID`: The body.
  - returns: The number.
- `SetUserData`: Sets the number a program keeps with a body.
  - `inBodyID`: The body.
  - `inUserData`: The number.
- `GetTransformedShape`: Returns a body's shape where the body is, for asking the shape about a query's hit.
  - `inBodyID`: The body.
  - `out`: Optional. The transformed shape to fill; a new one when omitted.
  - returns: The transformed shape.
- `GetPositionsAndRotations`: Reads where many bodies are, in one call: an extra of helix-jolt's, for drawing what moved.
  - `inBodyIDs`: The bodies, such as `PhysicsSystem.GetActiveBodies` fills.
  - `outValues`: Receives 7 floats a body: the floats from index `7 * i` are the body `inBodyIDs.at(i)`'s position x, y and z, then its rotation's x, y, z and w.
  - returns: The number of bodies read: fewer than `inBodyIDs` lists when `outValues` holds fewer.

  The bodies cross from the module in one copy, where `GetPositionAndRotation` crosses once a body. Only the floats of the bodies listed are written.
- `GetWorldTransforms`: Reads many bodies' transforms, in one call: an extra of helix-jolt's, for drawing them instanced.
  - `inBodyIDs`: The bodies.
  - `outTransforms`: Receives a transform a body, in the order of `inBodyIDs`. Transforms in the array are filled in place, and ones are added when it is shorter.
  - returns: The number of bodies read.

  The transforms suit helix-raylib's `DrawMeshInstanced`.

## BodyLockInterfaceNoLock

*class* in [`libs/jolt/src/helix/jolt/BodyLockInterfaceNoLock.hx`](../src/helix/jolt/BodyLockInterfaceNoLock.hx), `import helix.jolt.BodyLockInterfaceNoLock;`

Provides the bodies by their ids, returned by `PhysicsSystem.GetBodyLockInterfaceNoLock`. The module runs on one thread, so a body is read without a lock.

```haxe
function TryGetBody(inBodyID:BodyID):Null<Body>
```

- `TryGetBody`: Returns a body by its id.
  - `inBodyID`: The body's id.
  - returns: The body, or null when the id names no body.

  The `Body` returned for an id is the same object each time, so a call allocates nothing.

## BoxShape

*class* in [`libs/jolt/src/helix/jolt/BoxShape.hx`](../src/helix/jolt/BoxShape.hx), `import helix.jolt.BoxShape;`, extends `ConvexShape`

Represents a box, centered on its body.

```haxe
function new(inHalfExtent:Vec3, ?inConvexRadius:Float = 0.05)
function GetHalfExtent(?out:Vec3):Vec3
```

- `new`: Creates a box.
  - `inHalfExtent`: Half the box's size along each axis, in meters.
  - `inConvexRadius`: Optional. The rounding of the box's edges, in meters, no more than the smallest half extent; defaults to 0.05.
- `GetHalfExtent`: Returns half the box's size along each axis.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The half extent, in meters.

## BroadPhaseLayer

*abstract* in [`libs/jolt/src/helix/jolt/BroadPhaseLayer.hx`](../src/helix/jolt/BroadPhaseLayer.hx), `import helix.jolt.BroadPhaseLayer;`

Represents a broad phase layer: a group of object layers kept in a tree of their own, such as the bodies that never move. Holds no object.

```haxe
function GetValue():Int
```

- `GetValue`: Returns the layer's number.
  - returns: The number.

## BroadPhaseLayerFilter

*class* in [`libs/jolt/src/helix/jolt/BroadPhaseLayerFilter.hx`](../src/helix/jolt/BroadPhaseLayerFilter.hx), `import helix.jolt.BroadPhaseLayerFilter;`

Represents which broad phase layers a query tests. Made as a `DefaultBroadPhaseLayerFilter` or a `SpecifiedBroadPhaseLayerFilter`.

## BroadPhaseLayerInterface

*class* in [`libs/jolt/src/helix/jolt/BroadPhaseLayerInterface.hx`](../src/helix/jolt/BroadPhaseLayerInterface.hx), `import helix.jolt.BroadPhaseLayerInterface;`

Represents a map from object layers to broad phase layers, set as `JoltSettings.mBroadPhaseLayerInterface`. Made as a `BroadPhaseLayerInterfaceTable`.

## BroadPhaseLayerInterfaceTable

*class* in [`libs/jolt/src/helix/jolt/BroadPhaseLayerInterfaceTable.hx`](../src/helix/jolt/BroadPhaseLayerInterfaceTable.hx), `import helix.jolt.BroadPhaseLayerInterfaceTable;`, extends `BroadPhaseLayerInterface`

Represents a map from object layers to broad phase layers, set in a table.

```haxe
var broadPhaseLayers = new BroadPhaseLayerInterfaceTable(2, 2);
broadPhaseLayers.MapObjectToBroadPhaseLayer(LAYER_NON_MOVING, new BroadPhaseLayer(0));
broadPhaseLayers.MapObjectToBroadPhaseLayer(LAYER_MOVING, new BroadPhaseLayer(1));
```

```haxe
function new(inNumObjectLayers:Int, inNumBroadPhaseLayers:Int)
function MapObjectToBroadPhaseLayer(inObjectLayer:Int, inBroadPhaseLayer:BroadPhaseLayer):Void
```

- `new`: Creates a map with every object layer in broad phase layer 0.
  - `inNumObjectLayers`: The number of object layers.
  - `inNumBroadPhaseLayers`: The number of broad phase layers.
- `MapObjectToBroadPhaseLayer`: Puts an object layer in a broad phase layer.
  - `inObjectLayer`: The object layer.
  - `inBroadPhaseLayer`: The broad phase layer.

## CapsuleShape

*class* in [`libs/jolt/src/helix/jolt/CapsuleShape.hx`](../src/helix/jolt/CapsuleShape.hx), `import helix.jolt.CapsuleShape;`, extends `ConvexShape`

Represents a capsule along y, centered on its body: a cylinder with a half sphere on each end, as a standing character.

```haxe
function new(inHalfHeightOfCylinder:Float, inRadius:Float)
function GetRadius():Float
function GetHalfHeightOfCylinder():Float
```

- `new`: Creates a capsule.
  - `inHalfHeightOfCylinder`: Half the cylinder's height, without the ends, in meters.
  - `inRadius`: The radius, in meters.
- `GetRadius`: Returns the radius.
  - returns: The radius, in meters.
- `GetHalfHeightOfCylinder`: Returns half the cylinder's height, without the ends.
  - returns: The half height, in meters.

## CastRayAllHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CastRayAllHitCollisionCollector.hx`](../src/helix/jolt/CastRayAllHitCollisionCollector.hx), `import helix.jolt.CastRayAllHitCollisionCollector;`, extends `CastRayCollector`

Represents a collector of every one of a ray cast's hits, in no order until `Sort` is called.

```haxe
function new()
var mHits(default, null):Array<RayCastResult>
function HadHit():Bool
function Sort():Void
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHits`: Gets the hits. Their objects are reused by the next query after `Reset`.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHits` holds a hit.
- `Sort`: Sorts the hits, nearest first.

## CastRayAnyHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CastRayAnyHitCollisionCollector.hx`](../src/helix/jolt/CastRayAnyHitCollisionCollector.hx), `import helix.jolt.CastRayAnyHitCollisionCollector;`, extends `CastRayCollector`

Represents a collector of the first of a ray cast's hits found, which ends the query: the fastest answer to whether there is one.

```haxe
function new()
var mHit(default, null):RayCastResult
function HadHit():Bool
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHit`: Gets the hit, read when `HadHit` is true.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHit` holds a hit.

## CastRayClosestHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CastRayClosestHitCollisionCollector.hx`](../src/helix/jolt/CastRayClosestHitCollisionCollector.hx), `import helix.jolt.CastRayClosestHitCollisionCollector;`, extends `CastRayCollector`

Represents a collector of the hit nearest the ray's origin.

```haxe
function new()
var mHit(default, null):RayCastResult
function HadHit():Bool
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHit`: Gets the hit, read when `HadHit` is true.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHit` holds a hit.

## CastRayCollector

*class* in [`libs/jolt/src/helix/jolt/CastRayCollector.hx`](../src/helix/jolt/CastRayCollector.hx), `import helix.jolt.CastRayCollector;`

Represents what collects a ray cast's hits, passed to `NarrowPhaseQuery.CastRay`. Made as one of the collectors below it, and reused from one query to the next.

```haxe
function Reset():Void
```

- `Reset`: Empties the collector for another query. A query doesn't empty the collector itself.

## CastShapeAllHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CastShapeAllHitCollisionCollector.hx`](../src/helix/jolt/CastShapeAllHitCollisionCollector.hx), `import helix.jolt.CastShapeAllHitCollisionCollector;`, extends `CastShapeCollector`

Represents a collector of every one of a shape cast's hits, in no order until `Sort` is called.

```haxe
function new()
var mHits(default, null):Array<ShapeCastResult>
function HadHit():Bool
function Sort():Void
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHits`: Gets the hits. Their objects are reused by the next query after `Reset`.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHits` holds a hit.
- `Sort`: Sorts the hits, nearest first.

## CastShapeAnyHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CastShapeAnyHitCollisionCollector.hx`](../src/helix/jolt/CastShapeAnyHitCollisionCollector.hx), `import helix.jolt.CastShapeAnyHitCollisionCollector;`, extends `CastShapeCollector`

Represents a collector of the first of a shape cast's hits found, which ends the query: the fastest answer to whether there is one.

```haxe
function new()
var mHit(default, null):ShapeCastResult
function HadHit():Bool
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHit`: Gets the hit, read when `HadHit` is true.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHit` holds a hit.

## CastShapeClosestHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CastShapeClosestHitCollisionCollector.hx`](../src/helix/jolt/CastShapeClosestHitCollisionCollector.hx), `import helix.jolt.CastShapeClosestHitCollisionCollector;`, extends `CastShapeCollector`

Represents a collector of the hit nearest the cast's start.

```haxe
function new()
var mHit(default, null):ShapeCastResult
function HadHit():Bool
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHit`: Gets the hit, read when `HadHit` is true.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHit` holds a hit.

## CastShapeCollector

*class* in [`libs/jolt/src/helix/jolt/CastShapeCollector.hx`](../src/helix/jolt/CastShapeCollector.hx), `import helix.jolt.CastShapeCollector;`

Represents what collects a shape cast's hits, passed to `NarrowPhaseQuery.CastShape`. Made as one of the collectors below it, and reused from one query to the next.

```haxe
function Reset():Void
```

- `Reset`: Empties the collector for another query. A query doesn't empty the collector itself.

## CollidePointAllHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CollidePointAllHitCollisionCollector.hx`](../src/helix/jolt/CollidePointAllHitCollisionCollector.hx), `import helix.jolt.CollidePointAllHitCollisionCollector;`, extends `CollidePointCollector`

Represents a collector of every one of the bodies a point is inside, in no order until `Sort` is called.

```haxe
function new()
var mHits(default, null):Array<CollidePointResult>
function HadHit():Bool
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHits`: Gets the hits. Their objects are reused by the next query after `Reset`.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHits` holds a hit.

## CollidePointAnyHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CollidePointAnyHitCollisionCollector.hx`](../src/helix/jolt/CollidePointAnyHitCollisionCollector.hx), `import helix.jolt.CollidePointAnyHitCollisionCollector;`, extends `CollidePointCollector`

Represents a collector of the first of the bodies a point is inside found, which ends the query: the fastest answer to whether there is one.

```haxe
function new()
var mHit(default, null):CollidePointResult
function HadHit():Bool
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHit`: Gets the hit, read when `HadHit` is true.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHit` holds a hit.

## CollidePointCollector

*class* in [`libs/jolt/src/helix/jolt/CollidePointCollector.hx`](../src/helix/jolt/CollidePointCollector.hx), `import helix.jolt.CollidePointCollector;`

Represents what collects the bodies a point is inside, passed to `NarrowPhaseQuery.CollidePoint`. Made as one of the collectors below it, and reused from one query to the next.

```haxe
function Reset():Void
```

- `Reset`: Empties the collector for another query. A query doesn't empty the collector itself.

## CollidePointResult

*class* in [`libs/jolt/src/helix/jolt/CollidePointResult.hx`](../src/helix/jolt/CollidePointResult.hx), `import helix.jolt.CollidePointResult;`

Represents a body a point is inside.

```haxe
function new()
var mBodyID:BodyID
var mSubShapeID2:SubShapeID
```

- `new`: Creates an empty result.
- `mBodyID`: Gets or sets the body.
- `mSubShapeID2`: Gets or sets the part of the body's shape the point is inside.

## CollideShapeAllHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CollideShapeAllHitCollisionCollector.hx`](../src/helix/jolt/CollideShapeAllHitCollisionCollector.hx), `import helix.jolt.CollideShapeAllHitCollisionCollector;`, extends `CollideShapeCollector`

Represents a collector of every one of the bodies a shape overlaps, in no order until `Sort` is called.

```haxe
function new()
var mHits(default, null):Array<CollideShapeResult>
function HadHit():Bool
function Sort():Void
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHits`: Gets the hits. Their objects are reused by the next query after `Reset`.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHits` holds a hit.
- `Sort`: Sorts the hits, nearest first.

## CollideShapeAnyHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CollideShapeAnyHitCollisionCollector.hx`](../src/helix/jolt/CollideShapeAnyHitCollisionCollector.hx), `import helix.jolt.CollideShapeAnyHitCollisionCollector;`, extends `CollideShapeCollector`

Represents a collector of the first of the bodies a shape overlaps found, which ends the query: the fastest answer to whether there is one.

```haxe
function new()
var mHit(default, null):CollideShapeResult
function HadHit():Bool
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHit`: Gets the hit, read when `HadHit` is true.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHit` holds a hit.

## CollideShapeClosestHitCollisionCollector

*class* in [`libs/jolt/src/helix/jolt/CollideShapeClosestHitCollisionCollector.hx`](../src/helix/jolt/CollideShapeClosestHitCollisionCollector.hx), `import helix.jolt.CollideShapeClosestHitCollisionCollector;`, extends `CollideShapeCollector`

Represents a collector of the hit of deepest penetration.

```haxe
function new()
var mHit(default, null):CollideShapeResult
function HadHit():Bool
function Reset():Void
```

- `new`: Creates an empty collector.
- `mHit`: Gets the hit, read when `HadHit` is true.
- `HadHit`: Returns whether the query hit anything.
  - returns: True when `mHit` holds a hit.

## CollideShapeCollector

*class* in [`libs/jolt/src/helix/jolt/CollideShapeCollector.hx`](../src/helix/jolt/CollideShapeCollector.hx), `import helix.jolt.CollideShapeCollector;`

Represents what collects the bodies a shape overlaps, passed to `NarrowPhaseQuery.CollideShape`. Made as one of the collectors below it, and reused from one query to the next.

```haxe
function Reset():Void
```

- `Reset`: Empties the collector for another query. A query doesn't empty the collector itself.

## CollideShapeResult

*class* in [`libs/jolt/src/helix/jolt/CollideShapeResult.hx`](../src/helix/jolt/CollideShapeResult.hx), `import helix.jolt.CollideShapeResult;`

Represents a body a shape overlaps, and where.

```haxe
function new()
var mContactPointOn1:Vec3
var mContactPointOn2:Vec3
var mPenetrationAxis:Vec3
var mPenetrationDepth:Float
var mSubShapeID1:SubShapeID
var mSubShapeID2:SubShapeID
var mBodyID2:BodyID
```

- `new`: Creates an empty result.
- `mContactPointOn1`: Gets or sets the deepest point on the query's shape, in the world, in meters.
- `mContactPointOn2`: Gets or sets the deepest point on the body's shape, in the world, in meters.
- `mPenetrationAxis`: Gets or sets the direction the query's shape moves to leave the body, its length any.
- `mPenetrationDepth`: Gets or sets how deep the shapes overlap, in meters.
- `mSubShapeID1`: Gets or sets the part of the query's shape.
- `mSubShapeID2`: Gets or sets the part of the body's shape.
- `mBodyID2`: Gets or sets the body.

## CollideShapeSettings

*class* in [`libs/jolt/src/helix/jolt/CollideShapeSettings.hx`](../src/helix/jolt/CollideShapeSettings.hx), `import helix.jolt.CollideShapeSettings;`

Represents how a shape overlap is tested.

```haxe
function new()
var mMaxSeparationDistance:Float
var mBackFaceMode:EBackFaceMode
```

- `new`: Creates the default settings.
- `mMaxSeparationDistance`: Gets or sets the distance apart at which shapes still count as touching, in meters. Defaults to 0.
- `mBackFaceMode`: Gets or sets whether a mesh's triangle is hit from behind. Defaults to `EBackFaceMode_IgnoreBackFaces`.

## CompoundShapeSettings

*class* in [`libs/jolt/src/helix/jolt/CompoundShapeSettings.hx`](../src/helix/jolt/CompoundShapeSettings.hx), `import helix.jolt.CompoundShapeSettings;`, extends `ShapeSettings`

Represents what a compound shape is built from: shapes put together, each moved and turned.

```haxe
function AddShape(inPosition:Vec3, inRotation:Quat, inShape:Shape, ?inUserData:Int = 0):Void
```

- `AddShape`: Adds a shape.
  - `inPosition`: Where the part is, from the compound's origin, in meters.
  - `inRotation`: How the part is turned.
  - `inShape`: The part.
  - `inUserData`: Optional. A number the part keeps for the program; defaults to 0.

## ConeConstraint

*class* in [`libs/jolt/src/helix/jolt/ConeConstraint.hx`](../src/helix/jolt/ConeConstraint.hx), `import helix.jolt.ConeConstraint;`, extends `TwoBodyConstraint`

Represents a cone constraint, made by `ConeConstraintSettings`.

```haxe
function SetHalfConeAngle(inHalfConeAngle:Float):Void
```

- `SetHalfConeAngle`: Sets half the cone's angle.
  - `inHalfConeAngle`: The angle, in radians, 0 to pi.

## ConeConstraintSettings

*class* in [`libs/jolt/src/helix/jolt/ConeConstraintSettings.hx`](../src/helix/jolt/ConeConstraintSettings.hx), `import helix.jolt.ConeConstraintSettings;`, extends `TwoBodyConstraintSettings`

Represents a constraint holding a point of one body to another, the second body's axis kept within a cone about the first's: a shoulder.

```haxe
function new()
var mPoint1:RVec3
var mTwistAxis1:Vec3
var mPoint2:RVec3
var mTwistAxis2:Vec3
var mHalfConeAngle:Float
```

- `new`: Creates the settings.
- `mPoint1`: Gets or sets the point on the first body, in meters. Defaults to (0, 0, 0).
- `mTwistAxis1`: Gets or sets the cone's axis on the first body. Defaults to (1, 0, 0).
- `mPoint2`: Gets or sets the point on the second body, in meters. Defaults to (0, 0, 0).
- `mTwistAxis2`: Gets or sets the axis on the second body kept in the cone. Defaults to (1, 0, 0).
- `mHalfConeAngle`: Gets or sets half the cone's angle, in radians, 0 to pi. Defaults to 0.

## Constraint

*class* in [`libs/jolt/src/helix/jolt/Constraint.hx`](../src/helix/jolt/Constraint.hx), `import helix.jolt.Constraint;`

Represents a constraint, made by `BodyInterface.CreateConstraint` and acting once `PhysicsSystem.AddConstraint` has added it.

A constraint is counted by what holds it, as a shape is: the system holds it while added, and the program holds it with `AddRef` and lets go with `Release`. `Jolt.destroy` frees every constraint, held or not.

```haxe
function GetRefCount():Int
function AddRef():Void
function Release():Void
function GetType():EConstraintType
function GetSubType():EConstraintSubType
function SetEnabled(inEnabled:Bool):Void
function GetEnabled():Bool
function GetUserData():Int
function SetUserData(inUserData:Int):Void
```

- `GetRefCount`: Returns how many hold the constraint.
  - returns: The count.
- `AddRef`: Holds the constraint: it stays until `Release` is called as often.
- `Release`: Lets go of the constraint, freeing it when nothing else holds it.
- `GetType`: Returns the constraint's family.
  - returns: The family.
- `GetSubType`: Returns the constraint's kind.
  - returns: The kind.
- `SetEnabled`: Turns the constraint on or off, keeping it added.
  - `inEnabled`: Whether the constraint acts.
- `GetEnabled`: Returns whether the constraint is on.
  - returns: True when the constraint acts.
- `GetUserData`: Returns the number the program keeps with the constraint.
  - returns: The number.
- `SetUserData`: Sets the number the program keeps with the constraint.
  - `inUserData`: The number.

## ConstraintSettings

*class* in [`libs/jolt/src/helix/jolt/ConstraintSettings.hx`](../src/helix/jolt/ConstraintSettings.hx), `import helix.jolt.ConstraintSettings;`

Represents what a constraint is made from.

```haxe
var mEnabled:Bool
```

- `mEnabled`: Gets or sets a value indicating whether the constraint acts once added. Defaults to true.

## ContactEvent

*class* in [`libs/jolt/src/helix/jolt/ContactEvent.hx`](../src/helix/jolt/ContactEvent.hx), `import helix.jolt.ContactEvent;`

Represents a contact between two bodies in a step, read from a `ContactEventQueue`: an extra of helix-jolt's.

```haxe
function new()
var mType:EContactEventType
var mBodyID1:BodyID
var mBodyID2:BodyID
var mSubShapeID1:SubShapeID
var mSubShapeID2:SubShapeID
var mWorldSpaceNormal:Vec3
var mContactPoint:RVec3
var mPenetrationDepth:Float
```

- `new`: Creates an empty event.
- `mType`: Gets or sets what happened.
- `mBodyID1`: Gets or sets the first body. Of a sensor and another body, the sensor is the first. Of two other bodies, the one of the lower index (`BodyID.GetIndex`) is the first.
- `mBodyID2`: Gets or sets the second body.
- `mSubShapeID1`: Gets or sets the part of the first body's shape.
- `mSubShapeID2`: Gets or sets the part of the second body's shape.
- `mWorldSpaceNormal`: Gets or sets the normal from the first body to the second, of length 1. (0, 0, 0) when `mType` is `EContactEventType_Removed`.
- `mContactPoint`: Gets or sets the middle of the contact points on the first body, in the world, in meters. (0, 0, 0) when `mType` is `EContactEventType_Removed`.
- `mPenetrationDepth`: Gets or sets how deep the bodies overlap, in meters. 0 when `mType` is `EContactEventType_Removed`.

## ContactEventQueue

*class* in [`libs/jolt/src/helix/jolt/ContactEventQueue.hx`](../src/helix/jolt/ContactEventQueue.hx), `import helix.jolt.ContactEventQueue;`, extends `ContactListener`

Represents a listener recording the contacts of a step, read after the step: an extra of helix-jolt's, in place of Jolt's `ContactListener` calls made during it.

```haxe
var contacts = new ContactEventQueue(1024);
physicsSystem.SetContactListener(contacts);
var event = new ContactEvent();
// each frame:
jolt.Step(1 / 60, 1);
for (i in 0...contacts.GetNumEvents()) {
contacts.GetEvent(i, event);
if (event.mType == EContactEventType_Added && event.mBodyID1 == pickup)
collect(event.mBodyID2);
}
```

`JoltInterface.Step` empties the queue before the step, and the step fills it, in the order the contacts were found, which is the same natively and in a page. The events cross from the module in one copy after the step.

```haxe
function new(inMaxEvents:Int, ?inRecordPersisted:Bool = false)
function GetNumEvents():Int
function GetEvent(inIndex:Int, ?out:ContactEvent):ContactEvent
function GetNumDroppedEvents():Int
```

- `new`: Creates an empty queue.
  - `inMaxEvents`: The most events a step records: a pair of bodies starting to touch is one event, and stopping another. A step's events past it are counted by `GetNumDroppedEvents`.
  - `inRecordPersisted`: Optional. Whether `EContactEventType_Persisted` events are recorded, one a touching pair a step; defaults to false.
- `GetNumEvents`: Returns the number of events of the last step.
  - returns: The count.
- `GetEvent`: Returns an event of the last step.
  - `inIndex`: The event's index, 0 to `GetNumEvents() - 1`.
  - `out`: Optional. The event to fill; a new one when omitted.
  - returns: The event.
- `GetNumDroppedEvents`: Returns the number of events of the last step past `inMaxEvents`, which were not recorded.
  - returns: The count.

## ContactListener

*class* in [`libs/jolt/src/helix/jolt/ContactListener.hx`](../src/helix/jolt/ContactListener.hx), `import helix.jolt.ContactListener;`

Represents what hears of contacts between bodies during a step, set with `PhysicsSystem.SetContactListener`. Made as a `ContactEventQueue`.

## ConvexHullShapeSettings

*class* in [`libs/jolt/src/helix/jolt/ConvexHullShapeSettings.hx`](../src/helix/jolt/ConvexHullShapeSettings.hx), `import helix.jolt.ConvexHullShapeSettings;`, extends `ConvexShapeSettings`

Represents what a convex hull is built from: the smallest convex shape around a set of points.

```haxe
function new()
var mPoints:Array<Vec3>
var mMaxConvexRadius:Float
var mHullTolerance:Float
```

- `new`: Creates the settings with no points.
- `mPoints`: Gets or sets the points, in meters.
- `mMaxConvexRadius`: Gets or sets the most the hull's edges are rounded, in meters. Defaults to 0.05.
- `mHullTolerance`: Gets or sets how far a point may be from the hull built, in meters. Defaults to 0.001.

## ConvexShape

*class* in [`libs/jolt/src/helix/jolt/ConvexShape.hx`](../src/helix/jolt/ConvexShape.hx), `import helix.jolt.ConvexShape;`, extends `Shape`

Represents a convex shape: a box, sphere, capsule, cylinder or hull. Its mass comes from its volume and its density: at the default density of 1000 kilograms a cubic meter, a box of 1 meter weighs 1000 kilograms.

```haxe
function GetDensity():Float
function SetDensity(inDensity:Float):Void
```

- `GetDensity`: Returns the shape's density.
  - returns: The density, in kilograms a cubic meter.
- `SetDensity`: Sets the shape's density, for bodies made from the shape after.
  - `inDensity`: The density, in kilograms a cubic meter. Defaults to 1000.

## ConvexShapeSettings

*class* in [`libs/jolt/src/helix/jolt/ConvexShapeSettings.hx`](../src/helix/jolt/ConvexShapeSettings.hx), `import helix.jolt.ConvexShapeSettings;`, extends `ShapeSettings`

Represents what a convex shape is built from.

```haxe
var mDensity:Float
```

- `mDensity`: Gets or sets the density, in kilograms a cubic meter. Defaults to 1000.

## CylinderShape

*class* in [`libs/jolt/src/helix/jolt/CylinderShape.hx`](../src/helix/jolt/CylinderShape.hx), `import helix.jolt.CylinderShape;`, extends `ConvexShape`

Represents a cylinder along y, centered on its body.

```haxe
function new(inHalfHeight:Float, inRadius:Float, ?inConvexRadius:Float = 0.05)
function GetRadius():Float
function GetHalfHeight():Float
```

- `new`: Creates a cylinder.
  - `inHalfHeight`: Half the height, in meters.
  - `inRadius`: The radius, in meters.
  - `inConvexRadius`: Optional. The rounding of the edges, in meters; defaults to 0.05.
- `GetRadius`: Returns the radius.
  - returns: The radius, in meters.
- `GetHalfHeight`: Returns half the height.
  - returns: The half height, in meters.

## DefaultBroadPhaseLayerFilter

*class* in [`libs/jolt/src/helix/jolt/DefaultBroadPhaseLayerFilter.hx`](../src/helix/jolt/DefaultBroadPhaseLayerFilter.hx), `import helix.jolt.DefaultBroadPhaseLayerFilter;`, extends `BroadPhaseLayerFilter`

Represents the broad phase layers an object layer meets: a query testing what a body of that layer would collide with.

```haxe
function new(inObjectVsBroadPhaseLayerFilter:ObjectVsBroadPhaseLayerFilter, inObjectLayer:Int)
```

- `new`: Creates the filter.
  - `inObjectVsBroadPhaseLayerFilter`: The filter from the settings (`JoltInterface.GetObjectVsBroadPhaseLayerFilter`).
  - `inObjectLayer`: The object layer.

## DefaultObjectLayerFilter

*class* in [`libs/jolt/src/helix/jolt/DefaultObjectLayerFilter.hx`](../src/helix/jolt/DefaultObjectLayerFilter.hx), `import helix.jolt.DefaultObjectLayerFilter;`, extends `ObjectLayerFilter`

Represents the object layers an object layer collides with: a query testing what a body of that layer would collide with.

```haxe
function new(inObjectLayerPairFilter:ObjectLayerPairFilter, inObjectLayer:Int)
```

- `new`: Creates the filter.
  - `inObjectLayerPairFilter`: The filter from the settings (`JoltInterface.GetObjectLayerPairFilter`).
  - `inObjectLayer`: The object layer.

## DistanceConstraint

*class* in [`libs/jolt/src/helix/jolt/DistanceConstraint.hx`](../src/helix/jolt/DistanceConstraint.hx), `import helix.jolt.DistanceConstraint;`, extends `TwoBodyConstraint`

Represents a distance constraint, made by `DistanceConstraintSettings`.

```haxe
function SetDistance(inMinDistance:Float, inMaxDistance:Float):Void
function GetMinDistance():Float
function GetMaxDistance():Float
```

- `SetDistance`: Sets the range of distances.
  - `inMinDistance`: The shortest distance, in meters.
  - `inMaxDistance`: The longest distance, in meters.
- `GetMinDistance`: Returns the shortest distance.
  - returns: The distance, in meters.
- `GetMaxDistance`: Returns the longest distance.
  - returns: The distance, in meters.

## DistanceConstraintSettings

*class* in [`libs/jolt/src/helix/jolt/DistanceConstraintSettings.hx`](../src/helix/jolt/DistanceConstraintSettings.hx), `import helix.jolt.DistanceConstraintSettings;`, extends `TwoBodyConstraintSettings`

Represents a constraint keeping two points of two bodies within a range of distances: a rope, a rod, a spring.

```haxe
function new()
var mPoint1:RVec3
var mPoint2:RVec3
var mMinDistance:Float
var mMaxDistance:Float
var mLimitsSpringSettings:SpringSettings
```

- `new`: Creates the settings.
- `mPoint1`: Gets or sets the point on the first body, in meters. Defaults to (0, 0, 0).
- `mPoint2`: Gets or sets the point on the second body, in meters. Defaults to (0, 0, 0).
- `mMinDistance`: Gets or sets the shortest distance, in meters, or -1 for the distance when the constraint is made. Defaults to -1.
- `mMaxDistance`: Gets or sets the longest distance, in meters, or -1 for the distance when the constraint is made. Defaults to -1.
- `mLimitsSpringSettings`: Gets or sets the spring at the distances' limits. Rigid by default.

## EActivation

*abstract* in [`libs/jolt/src/helix/jolt/EActivation.hx`](../src/helix/jolt/EActivation.hx), `import helix.jolt.EActivation;`

Specifies whether a call wakes a body.

- `EActivation.EActivation_Activate`: Wakes the body.
- `EActivation.EActivation_DontActivate`: Leaves the body asleep or awake as it is.

## EAllowedDOFs

*abstract* in [`libs/jolt/src/helix/jolt/EAllowedDOFs.hx`](../src/helix/jolt/EAllowedDOFs.hx), `import helix.jolt.EAllowedDOFs;`

Specifies the directions a body may move and turn in, as bits combined with `|`.

- `EAllowedDOFs.EAllowedDOFs_TranslationX`: Moving along x.
- `EAllowedDOFs.EAllowedDOFs_TranslationY`: Moving along y.
- `EAllowedDOFs.EAllowedDOFs_TranslationZ`: Moving along z.
- `EAllowedDOFs.EAllowedDOFs_RotationX`: Turning about x.
- `EAllowedDOFs.EAllowedDOFs_RotationY`: Turning about y.
- `EAllowedDOFs.EAllowedDOFs_RotationZ`: Turning about z.
- `EAllowedDOFs.EAllowedDOFs_Plane2D`: Moving along x and y and turning about z: a body in 2D.
- `EAllowedDOFs.EAllowedDOFs_All`: Moving and turning freely.

## EBackFaceMode

*abstract* in [`libs/jolt/src/helix/jolt/EBackFaceMode.hx`](../src/helix/jolt/EBackFaceMode.hx), `import helix.jolt.EBackFaceMode;`

Specifies whether a query hits a face from behind.

- `EBackFaceMode.EBackFaceMode_IgnoreBackFaces`: Only a face's front is hit.
- `EBackFaceMode.EBackFaceMode_CollideWithBackFaces`: Both sides of a face are hit.

## EBodyType

*abstract* in [`libs/jolt/src/helix/jolt/EBodyType.hx`](../src/helix/jolt/EBodyType.hx), `import helix.jolt.EBodyType;`

Specifies a kind of body.

- `EBodyType.EBodyType_RigidBody`: A rigid body.
- `EBodyType.EBodyType_SoftBody`: A soft body, which this module doesn't make.

## EConstraintSpace

*abstract* in [`libs/jolt/src/helix/jolt/EConstraintSpace.hx`](../src/helix/jolt/EConstraintSpace.hx), `import helix.jolt.EConstraintSpace;`

Specifies the space a constraint's points and axes are in.

- `EConstraintSpace.EConstraintSpace_LocalToBodyCOM`: Each body's own, from its center of mass.
- `EConstraintSpace.EConstraintSpace_WorldSpace`: The world's, as the bodies are placed when the constraint is made.

## EConstraintSubType

*abstract* in [`libs/jolt/src/helix/jolt/EConstraintSubType.hx`](../src/helix/jolt/EConstraintSubType.hx), `import helix.jolt.EConstraintSubType;`

Specifies a constraint's kind.

- `EConstraintSubType.EConstraintSubType_Fixed`: Made by `FixedConstraintSettings`.
- `EConstraintSubType.EConstraintSubType_Point`: Made by `PointConstraintSettings`.
- `EConstraintSubType.EConstraintSubType_Hinge`: Made by `HingeConstraintSettings`.
- `EConstraintSubType.EConstraintSubType_Slider`: Made by `SliderConstraintSettings`.
- `EConstraintSubType.EConstraintSubType_Distance`: Made by `DistanceConstraintSettings`.
- `EConstraintSubType.EConstraintSubType_Cone`: Made by `ConeConstraintSettings`.
- `EConstraintSubType.EConstraintSubType_SwingTwist`: A swing twist constraint, for a ragdoll's joints.
- `EConstraintSubType.EConstraintSubType_SixDOF`: Made by `SixDOFConstraintSettings`.

## EConstraintType

*abstract* in [`libs/jolt/src/helix/jolt/EConstraintType.hx`](../src/helix/jolt/EConstraintType.hx), `import helix.jolt.EConstraintType;`

Specifies a constraint's family.

- `EConstraintType.EConstraintType_Constraint`: A constraint on one body.
- `EConstraintType.EConstraintType_TwoBodyConstraint`: A constraint between two bodies.

## EContactEventType

*abstract* in [`libs/jolt/src/helix/jolt/EContactEventType.hx`](../src/helix/jolt/EContactEventType.hx), `import helix.jolt.EContactEventType;`

Specifies what happened between two bodies in a step: an extra of helix-jolt's, read from a `ContactEvent`.

- `EContactEventType.EContactEventType_Added`: The bodies started touching, as Jolt's `ContactListener.OnContactAdded` reports. A sensor's body entering it.
- `EContactEventType.EContactEventType_Persisted`: The bodies were touching and still are, as Jolt's `ContactListener.OnContactPersisted` reports.
- `EContactEventType.EContactEventType_Removed`: The bodies stopped touching, as Jolt's `ContactListener.OnContactRemoved` reports. A sensor's body leaving it.

## EMotionQuality

*abstract* in [`libs/jolt/src/helix/jolt/EMotionQuality.hx`](../src/helix/jolt/EMotionQuality.hx), `import helix.jolt.EMotionQuality;`

Specifies how a moving body's motion is tested for collisions.

- `EMotionQuality.EMotionQuality_Discrete`: Tested where the body is at each step, so a fast, thin body may pass through another.
- `EMotionQuality.EMotionQuality_LinearCast`: Cast along its motion each step, so a fast body stops at what it would pass through: a bullet.

## EMotionType

*abstract* in [`libs/jolt/src/helix/jolt/EMotionType.hx`](../src/helix/jolt/EMotionType.hx), `import helix.jolt.EMotionType;`

Specifies how a body moves.

- `EMotionType.EMotionType_Static`: Never moves: the ground, a wall.
- `EMotionType.EMotionType_Kinematic`: Moved by the program (`BodyInterface.MoveKinematic`), pushing dynamic bodies aside.
- `EMotionType.EMotionType_Dynamic`: Moved by the simulation: falling, pushed, thrown.

## EMotorState

*abstract* in [`libs/jolt/src/helix/jolt/EMotorState.hx`](../src/helix/jolt/EMotorState.hx), `import helix.jolt.EMotorState;`

Specifies what a constraint's motor drives toward.

- `EMotorState.EMotorState_Off`: Nothing: the motor is off.
- `EMotorState.EMotorState_Velocity`: A target velocity.
- `EMotorState.EMotorState_Position`: A target position or angle.
- `EMotorState.EMotorState_PositionAndVelocity`: A target position or angle, at a target velocity.

## EOverrideMassProperties

*abstract* in [`libs/jolt/src/helix/jolt/EOverrideMassProperties.hx`](../src/helix/jolt/EOverrideMassProperties.hx), `import helix.jolt.EOverrideMassProperties;`

Specifies how a body's mass and inertia are found.

- `EOverrideMassProperties.EOverrideMassProperties_CalculateMassAndInertia`: Both from the shape and its density.
- `EOverrideMassProperties.EOverrideMassProperties_CalculateInertia`: The mass from `BodyCreationSettings.mMassPropertiesOverride`, the inertia from the shape scaled to it.
- `EOverrideMassProperties.EOverrideMassProperties_MassAndInertiaProvided`: Both from `BodyCreationSettings.mMassPropertiesOverride`.

## EShapeSubType

*abstract* in [`libs/jolt/src/helix/jolt/EShapeSubType.hx`](../src/helix/jolt/EShapeSubType.hx), `import helix.jolt.EShapeSubType;`

Specifies a shape's kind.

- `EShapeSubType.EShapeSubType_Sphere`: `SphereShape`.
- `EShapeSubType.EShapeSubType_Box`: `BoxShape`.
- `EShapeSubType.EShapeSubType_Capsule`: `CapsuleShape`.
- `EShapeSubType.EShapeSubType_TaperedCapsule`: A shape made by `TaperedCapsuleShapeSettings`.
- `EShapeSubType.EShapeSubType_Cylinder`: `CylinderShape`.
- `EShapeSubType.EShapeSubType_TaperedCylinder`: A tapered cylinder, which this module doesn't make.
- `EShapeSubType.EShapeSubType_ConvexHull`: A shape made by `ConvexHullShapeSettings`.
- `EShapeSubType.EShapeSubType_StaticCompound`: A shape made by `StaticCompoundShapeSettings`.
- `EShapeSubType.EShapeSubType_MutableCompound`: A mutable compound, which this module doesn't make.
- `EShapeSubType.EShapeSubType_RotatedTranslated`: A shape made by `RotatedTranslatedShapeSettings`.
- `EShapeSubType.EShapeSubType_Scaled`: `ScaledShape`.
- `EShapeSubType.EShapeSubType_OffsetCenterOfMass`: `OffsetCenterOfMassShape`.
- `EShapeSubType.EShapeSubType_Mesh`: A shape made by `MeshShapeSettings`.
- `EShapeSubType.EShapeSubType_HeightField`: A shape made by `HeightFieldShapeSettings`.
- `EShapeSubType.EShapeSubType_Plane`: `PlaneShape`.
- `EShapeSubType.EShapeSubType_Empty`: `EmptyShape`.

## EShapeType

*abstract* in [`libs/jolt/src/helix/jolt/EShapeType.hx`](../src/helix/jolt/EShapeType.hx), `import helix.jolt.EShapeType;`

Specifies a shape's family.

- `EShapeType.EShapeType_Convex`: A convex shape: box, sphere, capsule, cylinder, hull.
- `EShapeType.EShapeType_Compound`: Shapes put together.
- `EShapeType.EShapeType_Decorated`: A shape changed by another: scaled, moved, its center of mass offset.
- `EShapeType.EShapeType_Mesh`: Triangles.
- `EShapeType.EShapeType_HeightField`: A grid of heights.
- `EShapeType.EShapeType_Plane`: A plane.
- `EShapeType.EShapeType_Empty`: No shape.

## ESpringMode

*abstract* in [`libs/jolt/src/helix/jolt/ESpringMode.hx`](../src/helix/jolt/ESpringMode.hx), `import helix.jolt.ESpringMode;`

Specifies how a spring's strength is set.

- `ESpringMode.ESpringMode_FrequencyAndDamping`: By `SpringSettings.mFrequency` and `mDamping`.
- `ESpringMode.ESpringMode_StiffnessAndDamping`: By `SpringSettings.mStiffness` and `mDamping`.
- `ESpringMode.ESpringMode_MassNormalizedStiffnessAndDamping`: By `SpringSettings.mStiffness` divided by the mass, and `mDamping`.

## EmptyShape

*class* in [`libs/jolt/src/helix/jolt/EmptyShape.hx`](../src/helix/jolt/EmptyShape.hx), `import helix.jolt.EmptyShape;`, extends `Shape`

Represents no shape: a body that collides with nothing, such as one a constraint holds others to.

```haxe
function new(?inCenterOfMass:Vec3)
```

- `new`: Creates the shape.
  - `inCenterOfMass`: Optional. The center of mass; defaults to (0, 0, 0).

## FixedConstraintSettings

*class* in [`libs/jolt/src/helix/jolt/FixedConstraintSettings.hx`](../src/helix/jolt/FixedConstraintSettings.hx), `import helix.jolt.FixedConstraintSettings;`, extends `TwoBodyConstraintSettings`

Represents a constraint holding two bodies together, as if welded.

```haxe
function new()
var mAutoDetectPoint:Bool
var mPoint1:RVec3
var mPoint2:RVec3
```

- `new`: Creates the settings.
- `mAutoDetectPoint`: Gets or sets a value indicating whether the weld is where the bodies are when the constraint is made, the points and axes ignored. Defaults to false.
- `mPoint1`: Gets or sets the weld's point on the first body, in meters. Defaults to (0, 0, 0).
- `mPoint2`: Gets or sets the weld's point on the second body, in meters. Defaults to (0, 0, 0).

## Float3

*class* in [`libs/jolt/src/helix/jolt/Float3.hx`](../src/helix/jolt/Float3.hx), `import helix.jolt.Float3;`

Represents Jolt's `Float3`: three 32-bit floats, a mesh's vertex in a `VertexList`.

```haxe
function new(inX:Float, inY:Float, inZ:Float)
var x:Float
var y:Float
var z:Float
```

- `new`: Creates the three floats.
  - `inX`: The x component.
  - `inY`: The y component.
  - `inZ`: The z component.
- `x`: Gets or sets the x component.
- `y`: Gets or sets the y component.
- `z`: Gets or sets the z component.

## HeightFieldShapeConstantValues

*class* in [`libs/jolt/src/helix/jolt/HeightFieldShapeConstantValues.hx`](../src/helix/jolt/HeightFieldShapeConstantValues.hx), `import helix.jolt.HeightFieldShapeConstantValues;`

Provides the height field's constants.

```haxe
static final cNoCollisionValue(default, null):Float
```

- `cNoCollisionValue`: The height of a sample that is a hole.

## HeightFieldShapeSettings

*class* in [`libs/jolt/src/helix/jolt/HeightFieldShapeSettings.hx`](../src/helix/jolt/HeightFieldShapeSettings.hx), `import helix.jolt.HeightFieldShapeSettings;`, extends `ShapeSettings`

Represents what a height field is built from: a square grid of heights, for terrain. The grid lies along x and z, a sample's place being `mOffset + mScale * (x, height, z)`.

```haxe
function new()
var mOffset:Vec3
var mScale:Vec3
var mSampleCount:Int
var mHeightSamples:Array<Float>
var mBlockSize:Int
var mBitsPerSample:Int
```

- `new`: Creates the settings with no samples.
- `mOffset`: Gets or sets where the grid's first sample is, in meters. Defaults to (0, 0, 0).
- `mScale`: Gets or sets the size of a step between samples along x and z, and the scale of a height along y. Defaults to (1, 1, 1).
- `mSampleCount`: Gets or sets the number of samples along each side of the grid.
- `mHeightSamples`: Gets or sets the heights, row by row along x, `mSampleCount` squared of them. `HeightFieldShapeConstantValues.cNoCollisionValue` makes a hole.
- `mBlockSize`: Gets or sets the size of a block of samples, 2 to 8. Defaults to 2.
- `mBitsPerSample`: Gets or sets the bits a height is stored in, 1 to 8. Defaults to 8.

## HingeConstraint

*class* in [`libs/jolt/src/helix/jolt/HingeConstraint.hx`](../src/helix/jolt/HingeConstraint.hx), `import helix.jolt.HingeConstraint;`, extends `TwoBodyConstraint`

Represents a hinge, made by `HingeConstraintSettings`.

```haxe
function GetCurrentAngle():Float
function SetMaxFrictionTorque(inFrictionTorque:Float):Void
function GetMaxFrictionTorque():Float
function GetMotorSettings():MotorSettings
function SetMotorState(inState:EMotorState):Void
function GetMotorState():EMotorState
function SetTargetAngularVelocity(inAngularVelocity:Float):Void
function GetTargetAngularVelocity():Float
function SetTargetAngle(inAngle:Float):Void
function GetTargetAngle():Float
function SetLimits(inLimitsMin:Float, inLimitsMax:Float):Void
function GetLimitsMin():Float
function GetLimitsMax():Float
function HasLimits():Bool
```

- `GetCurrentAngle`: Returns the hinge's angle, 0 at the pose the bodies had when the constraint was made.
  - returns: The angle, in radians.
- `SetMaxFrictionTorque`: Sets the friction torque that slows the hinge.
  - `inFrictionTorque`: The torque, in newton meters.
- `GetMaxFrictionTorque`: Returns the friction torque that slows the hinge.
  - returns: The torque, in newton meters.
- `GetMotorSettings`: Returns the motor's settings, which may be changed in place.
  - returns: The settings.
- `SetMotorState`: Sets what the motor drives toward.
  - `inState`: The state.
- `GetMotorState`: Returns what the motor drives toward.
  - returns: The state.
- `SetTargetAngularVelocity`: Sets the angular velocity the motor drives to, under `EMotorState_Velocity`.
  - `inAngularVelocity`: The angular velocity, in radians a second.
- `GetTargetAngularVelocity`: Returns the angular velocity the motor drives to.
  - returns: The angular velocity, in radians a second.
- `SetTargetAngle`: Sets the angle the motor drives to, under `EMotorState_Position`.
  - `inAngle`: The angle, in radians.
- `GetTargetAngle`: Returns the angle the motor drives to.
  - returns: The angle, in radians.
- `SetLimits`: Sets the hinge's limits.
  - `inLimitsMin`: The smallest angle, in radians, -pi to 0.
  - `inLimitsMax`: The largest angle, in radians, 0 to pi.
- `GetLimitsMin`: Returns the smallest angle.
  - returns: The angle, in radians.
- `GetLimitsMax`: Returns the largest angle.
  - returns: The angle, in radians.
- `HasLimits`: Returns whether the hinge is limited.
  - returns: True when the limits are narrower than a whole turn.

## HingeConstraintSettings

*class* in [`libs/jolt/src/helix/jolt/HingeConstraintSettings.hx`](../src/helix/jolt/HingeConstraintSettings.hx), `import helix.jolt.HingeConstraintSettings;`, extends `TwoBodyConstraintSettings`

Represents a constraint letting two bodies turn about one axis: a door, a wheel.

```haxe
function new()
var mPoint1:RVec3
var mHingeAxis1:Vec3
var mNormalAxis1:Vec3
var mPoint2:RVec3
var mHingeAxis2:Vec3
var mNormalAxis2:Vec3
var mLimitsMin:Float
var mLimitsMax:Float
var mLimitsSpringSettings:SpringSettings
var mMaxFrictionTorque:Float
var mMotorSettings:MotorSettings
```

- `new`: Creates the settings.
- `mPoint1`: Gets or sets the hinge's point on the first body, in meters. Defaults to (0, 0, 0).
- `mHingeAxis1`: Gets or sets the hinge's axis on the first body. Defaults to (0, 1, 0).
- `mNormalAxis1`: Gets or sets an axis at right angles to the hinge's on the first body, from which the angle is measured. Defaults to (1, 0, 0).
- `mPoint2`: Gets or sets the hinge's point on the second body, in meters. Defaults to (0, 0, 0).
- `mHingeAxis2`: Gets or sets the hinge's axis on the second body. Defaults to (0, 1, 0).
- `mNormalAxis2`: Gets or sets an axis at right angles to the hinge's on the second body. Defaults to (1, 0, 0).
- `mLimitsMin`: Gets or sets the smallest angle, in radians, -pi to 0. Defaults to -pi: no limit.
- `mLimitsMax`: Gets or sets the largest angle, in radians, 0 to pi. Defaults to pi: no limit.
- `mLimitsSpringSettings`: Gets or sets the spring at the angles' limits. Rigid by default.
- `mMaxFrictionTorque`: Gets or sets the friction torque that slows the hinge, in newton meters. Defaults to 0.
- `mMotorSettings`: Gets or sets the motor: by default with no force limit, and off until the constraint's `SetMotorState`.

## IgnoreMultipleBodiesFilter

*class* in [`libs/jolt/src/helix/jolt/IgnoreMultipleBodiesFilter.hx`](../src/helix/jolt/IgnoreMultipleBodiesFilter.hx), `import helix.jolt.IgnoreMultipleBodiesFilter;`, extends `BodyFilter`

Represents every body but a list of them.

```haxe
function new()
function IgnoreBody(inBodyID:BodyID):Void
function Clear():Void
```

- `new`: Creates a filter that skips no body.
- `IgnoreBody`: Skips a body.
  - `inBodyID`: The body.
- `Clear`: Removes every body from the list, so the filter skips no body.

## IgnoreSingleBodyFilter

*class* in [`libs/jolt/src/helix/jolt/IgnoreSingleBodyFilter.hx`](../src/helix/jolt/IgnoreSingleBodyFilter.hx), `import helix.jolt.IgnoreSingleBodyFilter;`, extends `BodyFilter`

Represents every body but one: a ray cast from a body that skips the body casting it.

```haxe
function new(inBodyID:BodyID)
```

- `new`: Creates the filter.
  - `inBodyID`: The body skipped.

## IndexedTriangle

*class* in [`libs/jolt/src/helix/jolt/IndexedTriangle.hx`](../src/helix/jolt/IndexedTriangle.hx), `import helix.jolt.IndexedTriangle;`

Represents a mesh's triangle, by the indices of its three vertices, counterclockwise seen from the front.

```haxe
function new(inI1:Int, inI2:Int, inI3:Int)
var mIdx0:Int
var mIdx1:Int
var mIdx2:Int
```

- `new`: Creates a triangle.
  - `inI1`: The first vertex's index.
  - `inI2`: The second vertex's index.
  - `inI3`: The third vertex's index.
- `mIdx0`: Gets or sets the first vertex's index.
- `mIdx1`: Gets or sets the second vertex's index.
- `mIdx2`: Gets or sets the third vertex's index.

## IndexedTriangleList

*typedef* in [`libs/jolt/src/helix/jolt/IndexedTriangleList.hx`](../src/helix/jolt/IndexedTriangleList.hx), `import helix.jolt.IndexedTriangleList;`

Represents a mesh's triangles.

An alias of `Array<IndexedTriangle>`.

## Jolt

*class* in [`libs/jolt/src/helix/jolt/Jolt.hx`](../src/helix/jolt/Jolt.hx), `import helix.jolt.Jolt;`

Provides the Jolt Physics module: loading the module, and destroying what a program made in it.

A program loads the module once, before it constructs anything in this package:

```haxe
import helix.jolt.*;
import helix.jolt.Jolt.*;

Jolt.loadAsync(() -> {
var settings = new JoltSettings();
settings.mObjectLayerPairFilter = objectFilter;
settings.mBroadPhaseLayerInterface = broadPhaseLayers;
settings.mObjectVsBroadPhaseLayerFilter = new ObjectVsBroadPhaseLayerFilterTable(broadPhaseLayers, 2, objectFilter, 2);
jolt = new JoltInterface(settings);
});
```

Natively, Jolt is compiled into the program, and `loadAsync` calls `loaded` before returning. In a page, `loadAsync` fetches the module (`jolt.wasm`) and calls `loaded` once the module runs.

The build of Jolt the module holds is single precision, single threaded, and cross-platform deterministic: the same steps from the same state produce the same bits natively and in a page.

Jolt's value types (`Vec3`, `Quat`, the settings, a query's results) are Haxe objects, which the garbage collector frees. What Jolt holds (a `JoltInterface`, a body, a shape, a constraint) lives in the module until it is destroyed or released.

Jolt's constants are on this class, as JoltPhysics.js has them on its module: `Jolt.EMotionType_Dynamic`, or `EMotionType_Dynamic` after `import helix.jolt.Jolt.*;`.

```haxe
static inline var EActivation_Activate:EActivation
static inline var EActivation_DontActivate:EActivation
static inline var EAllowedDOFs_TranslationX:EAllowedDOFs
static inline var EAllowedDOFs_TranslationY:EAllowedDOFs
static inline var EAllowedDOFs_TranslationZ:EAllowedDOFs
static inline var EAllowedDOFs_RotationX:EAllowedDOFs
static inline var EAllowedDOFs_RotationY:EAllowedDOFs
static inline var EAllowedDOFs_RotationZ:EAllowedDOFs
static inline var EAllowedDOFs_Plane2D:EAllowedDOFs
static inline var EAllowedDOFs_All:EAllowedDOFs
static inline var EBackFaceMode_IgnoreBackFaces:EBackFaceMode
static inline var EBackFaceMode_CollideWithBackFaces:EBackFaceMode
static inline var EBodyType_RigidBody:EBodyType
static inline var EBodyType_SoftBody:EBodyType
static inline var EConstraintSpace_LocalToBodyCOM:EConstraintSpace
static inline var EConstraintSpace_WorldSpace:EConstraintSpace
static inline var EConstraintSubType_Fixed:EConstraintSubType
static inline var EConstraintSubType_Point:EConstraintSubType
static inline var EConstraintSubType_Hinge:EConstraintSubType
static inline var EConstraintSubType_Slider:EConstraintSubType
static inline var EConstraintSubType_Distance:EConstraintSubType
static inline var EConstraintSubType_Cone:EConstraintSubType
static inline var EConstraintSubType_SwingTwist:EConstraintSubType
static inline var EConstraintSubType_SixDOF:EConstraintSubType
static inline var EConstraintType_Constraint:EConstraintType
static inline var EConstraintType_TwoBodyConstraint:EConstraintType
static inline var EContactEventType_Added:EContactEventType
static inline var EContactEventType_Persisted:EContactEventType
static inline var EContactEventType_Removed:EContactEventType
static inline var EMotionQuality_Discrete:EMotionQuality
static inline var EMotionQuality_LinearCast:EMotionQuality
static inline var EMotionType_Static:EMotionType
static inline var EMotionType_Kinematic:EMotionType
static inline var EMotionType_Dynamic:EMotionType
static inline var EMotorState_Off:EMotorState
static inline var EMotorState_Velocity:EMotorState
static inline var EMotorState_Position:EMotorState
static inline var EMotorState_PositionAndVelocity:EMotorState
static inline var EOverrideMassProperties_CalculateMassAndInertia:EOverrideMassProperties
static inline var EOverrideMassProperties_CalculateInertia:EOverrideMassProperties
static inline var EOverrideMassProperties_MassAndInertiaProvided:EOverrideMassProperties
static inline var EShapeSubType_Sphere:EShapeSubType
static inline var EShapeSubType_Box:EShapeSubType
static inline var EShapeSubType_Capsule:EShapeSubType
static inline var EShapeSubType_TaperedCapsule:EShapeSubType
static inline var EShapeSubType_Cylinder:EShapeSubType
static inline var EShapeSubType_TaperedCylinder:EShapeSubType
static inline var EShapeSubType_ConvexHull:EShapeSubType
static inline var EShapeSubType_StaticCompound:EShapeSubType
static inline var EShapeSubType_MutableCompound:EShapeSubType
static inline var EShapeSubType_RotatedTranslated:EShapeSubType
static inline var EShapeSubType_Scaled:EShapeSubType
static inline var EShapeSubType_OffsetCenterOfMass:EShapeSubType
static inline var EShapeSubType_Mesh:EShapeSubType
static inline var EShapeSubType_HeightField:EShapeSubType
static inline var EShapeSubType_Plane:EShapeSubType
static inline var EShapeSubType_Empty:EShapeSubType
static inline var EShapeType_Convex:EShapeType
static inline var EShapeType_Compound:EShapeType
static inline var EShapeType_Decorated:EShapeType
static inline var EShapeType_Mesh:EShapeType
static inline var EShapeType_HeightField:EShapeType
static inline var EShapeType_Plane:EShapeType
static inline var EShapeType_Empty:EShapeType
static inline var ESpringMode_FrequencyAndDamping:ESpringMode
static inline var ESpringMode_StiffnessAndDamping:ESpringMode
static inline var ESpringMode_MassNormalizedStiffnessAndDamping:ESpringMode
static inline var SixDOFConstraintSettings_EAxis_TranslationX:SixDOFConstraintSettings_EAxis
static inline var SixDOFConstraintSettings_EAxis_TranslationY:SixDOFConstraintSettings_EAxis
static inline var SixDOFConstraintSettings_EAxis_TranslationZ:SixDOFConstraintSettings_EAxis
static inline var SixDOFConstraintSettings_EAxis_RotationX:SixDOFConstraintSettings_EAxis
static inline var SixDOFConstraintSettings_EAxis_RotationY:SixDOFConstraintSettings_EAxis
static inline var SixDOFConstraintSettings_EAxis_RotationZ:SixDOFConstraintSettings_EAxis
static function loadAsync(loaded:() -> Void, ?failed:String -> Void, ?wasmUrl:String):Void
static function isLoaded():Bool
static function destroy(inJoltInterface:JoltInterface):Void
static macro function copyWasm(directory:String):Void
```

- `EActivation_Activate`: The `EActivation` value EActivation_Activate: Wakes the body.
- `EActivation_DontActivate`: The `EActivation` value EActivation_DontActivate: Leaves the body asleep or awake as it is.
- `EAllowedDOFs_TranslationX`: The `EAllowedDOFs` value EAllowedDOFs_TranslationX: Moving along x.
- `EAllowedDOFs_TranslationY`: The `EAllowedDOFs` value EAllowedDOFs_TranslationY: Moving along y.
- `EAllowedDOFs_TranslationZ`: The `EAllowedDOFs` value EAllowedDOFs_TranslationZ: Moving along z.
- `EAllowedDOFs_RotationX`: The `EAllowedDOFs` value EAllowedDOFs_RotationX: Turning about x.
- `EAllowedDOFs_RotationY`: The `EAllowedDOFs` value EAllowedDOFs_RotationY: Turning about y.
- `EAllowedDOFs_RotationZ`: The `EAllowedDOFs` value EAllowedDOFs_RotationZ: Turning about z.
- `EAllowedDOFs_Plane2D`: The `EAllowedDOFs` value EAllowedDOFs_Plane2D: Moving along x and y and turning about z: a body in 2D.
- `EAllowedDOFs_All`: The `EAllowedDOFs` value EAllowedDOFs_All: Moving and turning freely.
- `EBackFaceMode_IgnoreBackFaces`: The `EBackFaceMode` value EBackFaceMode_IgnoreBackFaces: Only a face's front is hit.
- `EBackFaceMode_CollideWithBackFaces`: The `EBackFaceMode` value EBackFaceMode_CollideWithBackFaces: Both sides of a face are hit.
- `EBodyType_RigidBody`: The `EBodyType` value EBodyType_RigidBody: A rigid body.
- `EBodyType_SoftBody`: The `EBodyType` value EBodyType_SoftBody: A soft body, which this module doesn't make.
- `EConstraintSpace_LocalToBodyCOM`: The `EConstraintSpace` value EConstraintSpace_LocalToBodyCOM: Each body's own, from its center of mass.
- `EConstraintSpace_WorldSpace`: The `EConstraintSpace` value EConstraintSpace_WorldSpace: The world's, as the bodies are placed when the constraint is made.
- `EConstraintSubType_Fixed`: The `EConstraintSubType` value EConstraintSubType_Fixed: Made by `FixedConstraintSettings`.
- `EConstraintSubType_Point`: The `EConstraintSubType` value EConstraintSubType_Point: Made by `PointConstraintSettings`.
- `EConstraintSubType_Hinge`: The `EConstraintSubType` value EConstraintSubType_Hinge: Made by `HingeConstraintSettings`.
- `EConstraintSubType_Slider`: The `EConstraintSubType` value EConstraintSubType_Slider: Made by `SliderConstraintSettings`.
- `EConstraintSubType_Distance`: The `EConstraintSubType` value EConstraintSubType_Distance: Made by `DistanceConstraintSettings`.
- `EConstraintSubType_Cone`: The `EConstraintSubType` value EConstraintSubType_Cone: Made by `ConeConstraintSettings`.
- `EConstraintSubType_SwingTwist`: The `EConstraintSubType` value EConstraintSubType_SwingTwist: A swing twist constraint, for a ragdoll's joints.
- `EConstraintSubType_SixDOF`: The `EConstraintSubType` value EConstraintSubType_SixDOF: Made by `SixDOFConstraintSettings`.
- `EConstraintType_Constraint`: The `EConstraintType` value EConstraintType_Constraint: A constraint on one body.
- `EConstraintType_TwoBodyConstraint`: The `EConstraintType` value EConstraintType_TwoBodyConstraint: A constraint between two bodies.
- `EContactEventType_Added`: The `EContactEventType` value EContactEventType_Added: The bodies started touching, as Jolt's `ContactListener.OnContactAdded` reports. A sensor's body entering it.
- `EContactEventType_Persisted`: The `EContactEventType` value EContactEventType_Persisted: The bodies were touching and still are, as Jolt's `ContactListener.OnContactPersisted` reports.
- `EContactEventType_Removed`: The `EContactEventType` value EContactEventType_Removed: The bodies stopped touching, as Jolt's `ContactListener.OnContactRemoved` reports. A sensor's body leaving it.
- `EMotionQuality_Discrete`: The `EMotionQuality` value EMotionQuality_Discrete: Tested where the body is at each step, so a fast, thin body may pass through another.
- `EMotionQuality_LinearCast`: The `EMotionQuality` value EMotionQuality_LinearCast: Cast along its motion each step, so a fast body stops at what it would pass through: a bullet.
- `EMotionType_Static`: The `EMotionType` value EMotionType_Static: Never moves: the ground, a wall.
- `EMotionType_Kinematic`: The `EMotionType` value EMotionType_Kinematic: Moved by the program (`BodyInterface.MoveKinematic`), pushing dynamic bodies aside.
- `EMotionType_Dynamic`: The `EMotionType` value EMotionType_Dynamic: Moved by the simulation: falling, pushed, thrown.
- `EMotorState_Off`: The `EMotorState` value EMotorState_Off: Nothing: the motor is off.
- `EMotorState_Velocity`: The `EMotorState` value EMotorState_Velocity: A target velocity.
- `EMotorState_Position`: The `EMotorState` value EMotorState_Position: A target position or angle.
- `EMotorState_PositionAndVelocity`: The `EMotorState` value EMotorState_PositionAndVelocity: A target position or angle, at a target velocity.
- `EOverrideMassProperties_CalculateMassAndInertia`: The `EOverrideMassProperties` value EOverrideMassProperties_CalculateMassAndInertia: Both from the shape and its density.
- `EOverrideMassProperties_CalculateInertia`: The `EOverrideMassProperties` value EOverrideMassProperties_CalculateInertia: The mass from `BodyCreationSettings.mMassPropertiesOverride`, the inertia from the shape scaled to it.
- `EOverrideMassProperties_MassAndInertiaProvided`: The `EOverrideMassProperties` value EOverrideMassProperties_MassAndInertiaProvided: Both from `BodyCreationSettings.mMassPropertiesOverride`.
- `EShapeSubType_Sphere`: The `EShapeSubType` value EShapeSubType_Sphere: `SphereShape`.
- `EShapeSubType_Box`: The `EShapeSubType` value EShapeSubType_Box: `BoxShape`.
- `EShapeSubType_Capsule`: The `EShapeSubType` value EShapeSubType_Capsule: `CapsuleShape`.
- `EShapeSubType_TaperedCapsule`: The `EShapeSubType` value EShapeSubType_TaperedCapsule: A shape made by `TaperedCapsuleShapeSettings`.
- `EShapeSubType_Cylinder`: The `EShapeSubType` value EShapeSubType_Cylinder: `CylinderShape`.
- `EShapeSubType_TaperedCylinder`: The `EShapeSubType` value EShapeSubType_TaperedCylinder: A tapered cylinder, which this module doesn't make.
- `EShapeSubType_ConvexHull`: The `EShapeSubType` value EShapeSubType_ConvexHull: A shape made by `ConvexHullShapeSettings`.
- `EShapeSubType_StaticCompound`: The `EShapeSubType` value EShapeSubType_StaticCompound: A shape made by `StaticCompoundShapeSettings`.
- `EShapeSubType_MutableCompound`: The `EShapeSubType` value EShapeSubType_MutableCompound: A mutable compound, which this module doesn't make.
- `EShapeSubType_RotatedTranslated`: The `EShapeSubType` value EShapeSubType_RotatedTranslated: A shape made by `RotatedTranslatedShapeSettings`.
- `EShapeSubType_Scaled`: The `EShapeSubType` value EShapeSubType_Scaled: `ScaledShape`.
- `EShapeSubType_OffsetCenterOfMass`: The `EShapeSubType` value EShapeSubType_OffsetCenterOfMass: `OffsetCenterOfMassShape`.
- `EShapeSubType_Mesh`: The `EShapeSubType` value EShapeSubType_Mesh: A shape made by `MeshShapeSettings`.
- `EShapeSubType_HeightField`: The `EShapeSubType` value EShapeSubType_HeightField: A shape made by `HeightFieldShapeSettings`.
- `EShapeSubType_Plane`: The `EShapeSubType` value EShapeSubType_Plane: `PlaneShape`.
- `EShapeSubType_Empty`: The `EShapeSubType` value EShapeSubType_Empty: `EmptyShape`.
- `EShapeType_Convex`: The `EShapeType` value EShapeType_Convex: A convex shape: box, sphere, capsule, cylinder, hull.
- `EShapeType_Compound`: The `EShapeType` value EShapeType_Compound: Shapes put together.
- `EShapeType_Decorated`: The `EShapeType` value EShapeType_Decorated: A shape changed by another: scaled, moved, its center of mass offset.
- `EShapeType_Mesh`: The `EShapeType` value EShapeType_Mesh: Triangles.
- `EShapeType_HeightField`: The `EShapeType` value EShapeType_HeightField: A grid of heights.
- `EShapeType_Plane`: The `EShapeType` value EShapeType_Plane: A plane.
- `EShapeType_Empty`: The `EShapeType` value EShapeType_Empty: No shape.
- `ESpringMode_FrequencyAndDamping`: The `ESpringMode` value ESpringMode_FrequencyAndDamping: By `SpringSettings.mFrequency` and `mDamping`.
- `ESpringMode_StiffnessAndDamping`: The `ESpringMode` value ESpringMode_StiffnessAndDamping: By `SpringSettings.mStiffness` and `mDamping`.
- `ESpringMode_MassNormalizedStiffnessAndDamping`: The `ESpringMode` value ESpringMode_MassNormalizedStiffnessAndDamping: By `SpringSettings.mStiffness` divided by the mass, and `mDamping`.
- `SixDOFConstraintSettings_EAxis_TranslationX`: The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_TranslationX: Moving along x.
- `SixDOFConstraintSettings_EAxis_TranslationY`: The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_TranslationY: Moving along y.
- `SixDOFConstraintSettings_EAxis_TranslationZ`: The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_TranslationZ: Moving along z.
- `SixDOFConstraintSettings_EAxis_RotationX`: The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_RotationX: Turning about x.
- `SixDOFConstraintSettings_EAxis_RotationY`: The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_RotationY: Turning about y.
- `SixDOFConstraintSettings_EAxis_RotationZ`: The `SixDOFConstraintSettings_EAxis` value SixDOFConstraintSettings_EAxis_RotationZ: Turning about z.
- `loadAsync`: Asynchronously loads the module.
  - `loaded`: Called once the module is ready.
  - `failed`: Optional. Receives why the module couldn't be loaded; when omitted, it is thrown.
  - `wasmUrl`: Optional. In a page, the module's URL; defaults to `jolt.wasm`. Ignored natively.

  Calling it again after the module has loaded calls `loaded` again.

  _Note that in a page the module is `jolt.wasm` beside the page unless `wasmUrl` names another. The build copies it there with a line in the build's hxml:_

  ```hxml
  --macro helix.jolt.Jolt.copyWasm("web")
  ```
- `isLoaded`: Returns whether the module has loaded.
  - returns: True once `loaded` has been called.
- `destroy`: Destroys a `JoltInterface`, its `PhysicsSystem`, and every body, shape and constraint made in it, whether the program holds them or not.
  - `inJoltInterface`: The interface to destroy.

  A call on what was destroyed (`Release` among them) is skipped after.
- `copyWasm`: Copies the module (`jolt.wasm`) into a directory as the program builds: a build macro, called from the build's hxml.
  - `directory`: The page's directory, relative to the build's working directory.

  Skipped natively, where Jolt is compiled into the program.

## JoltInterface

*class* in [`libs/jolt/src/helix/jolt/JoltInterface.hx`](../src/helix/jolt/JoltInterface.hx), `import helix.jolt.JoltInterface;`

Represents a physics world: a `PhysicsSystem` with the memory and the thread it steps on.

```haxe
var jolt = new JoltInterface(settings);
var bodyInterface = jolt.GetPhysicsSystem().GetBodyInterface();
// each frame:
jolt.Step(1 / 60, 1);
```

`Jolt.destroy` destroys the world and what is in it.

```haxe
function new(inSettings:JoltSettings)
static function sGetFixedToWorldBody():Body
static function sGetTotalMemory():Int
static function sGetFreeMemory():Int
function Step(inDeltaTime:Float, inCollisionSteps:Int):Void
function GetPhysicsSystem():PhysicsSystem
function GetObjectLayerPairFilter():ObjectLayerPairFilter
function GetBroadPhaseLayerInterface():BroadPhaseLayerInterface
function GetObjectVsBroadPhaseLayerFilter():ObjectVsBroadPhaseLayerFilter
```

- `new`: Creates a world.
  - `inSettings`: The limits and the layers. Read once. The layer objects are kept.
- `sGetFixedToWorldBody`: Returns the body standing for the world, which a constraint fixes a body to.
  - returns: The body.

  Its id (`GetID`) is the invalid id, which `BodyInterface.CreateConstraint` reads as the world.
- `sGetTotalMemory`: Returns the bytes the module has reserved.
  - returns: The bytes.

  Natively, 0, as Jolt allocates from the program's own memory.
- `sGetFreeMemory`: Returns the bytes of the module's reserved memory not in use.
  - returns: The bytes.

  Natively, 0, as Jolt allocates from the program's own memory.
- `Step`: Advances the world.
  - `inDeltaTime`: The seconds to advance. A fixed step (1 / 60) keeps the world deterministic.
  - `inCollisionSteps`: The collision steps the time is split into; 1 at 60 steps a second, more for a longer step.

  Contact events recorded by a `ContactEventQueue` set on the system are cleared, then refilled during the step.
- `GetPhysicsSystem`: Returns the world's physics system.
  - returns: The system.
- `GetObjectLayerPairFilter`: Returns the filter deciding which object layers collide.
  - returns: The filter from the settings.
- `GetBroadPhaseLayerInterface`: Returns the map from object layers to broad phase layers.
  - returns: The map from the settings.
- `GetObjectVsBroadPhaseLayerFilter`: Returns the filter deciding which broad phase layers each object layer meets.
  - returns: The filter from the settings.

## JoltSettings

*class* in [`libs/jolt/src/helix/jolt/JoltSettings.hx`](../src/helix/jolt/JoltSettings.hx), `import helix.jolt.JoltSettings;`

Represents the settings a `JoltInterface` is constructed with: its limits and its collision layers.

The three layer fields must be set. `mObjectLayerPairFilter` decides which object layers collide, `mBroadPhaseLayerInterface` maps each object layer to a broad phase layer, and `mObjectVsBroadPhaseLayerFilter` decides which broad phase layers an object layer meets.

```haxe
function new()
var mMaxBodies:Int
var mMaxBodyPairs:Int
var mMaxContactConstraints:Int
var mObjectLayerPairFilter:ObjectLayerPairFilter
var mBroadPhaseLayerInterface:BroadPhaseLayerInterface
var mObjectVsBroadPhaseLayerFilter:ObjectVsBroadPhaseLayerFilter
```

- `new`: Creates settings with the default limits and no layers.
- `mMaxBodies`: Gets or sets the most bodies the system holds. Defaults to 10240.
- `mMaxBodyPairs`: Gets or sets the most pairs of bodies whose bounds overlap in one step. Defaults to 65536.
- `mMaxContactConstraints`: Gets or sets the most contacts between bodies in one step. Defaults to 10240.
- `mObjectLayerPairFilter`: Gets or sets which object layers collide. Must be set.
- `mBroadPhaseLayerInterface`: Gets or sets which broad phase layer each object layer is in. Must be set.
- `mObjectVsBroadPhaseLayerFilter`: Gets or sets which broad phase layers each object layer meets. Must be set.

## MassProperties

*class* in [`libs/jolt/src/helix/jolt/MassProperties.hx`](../src/helix/jolt/MassProperties.hx), `import helix.jolt.MassProperties;`

Represents a body's mass and inertia, set in `BodyCreationSettings.mMassPropertiesOverride`.

```haxe
function new()
var mMass:Float
var mInertia:Mat44
function SetMassAndInertiaOfSolidBox(inBoxSize:Vec3, inDensity:Float):Void
function ScaleToMass(inMass:Float):Void
```

- `new`: Creates mass properties of no mass.
- `mMass`: Gets or sets the mass, in kilograms.
- `mInertia`: Gets or sets the inertia tensor, about the center of mass.
- `SetMassAndInertiaOfSolidBox`: Sets the mass and inertia of a solid box.
  - `inBoxSize`: The box's full size.
  - `inDensity`: The density, in kilograms a cubic meter.
- `ScaleToMass`: Scales the mass to a value, and the inertia with it.
  - `inMass`: The mass, in kilograms.

## Mat44

*abstract* in [`libs/jolt/src/helix/jolt/Mat44.hx`](../src/helix/jolt/Mat44.hx), `import helix.jolt.Mat44;`

Represents Jolt's `Mat44`: a transform. Wraps helix-math's `Matrix4`, whose fields and methods it also has, and is passed as a `Matrix4` without a copy, as helix-raylib's `Matrix` and its `DrawMeshInstanced` accept it.

_Note that a `Mat44` is assigned by reference. An operation accepts an optional `out` that receives the result, and makes a new `Mat44` when `out` is omitted._

```haxe
static function sRotationTranslation(inR:Quat, inT:Vec3, ?out:Mat44):Mat44
static function sTranslation(inV:Vec3, ?out:Mat44):Mat44
function GetTranslation(?out:Vec3):Vec3
function GetQuaternion(?out:Quat):Quat
```

- `sRotationTranslation`: Returns the transform that rotates, then moves.
  - `inR`: The rotation.
  - `inT`: The translation.
  - `out`: Optional. The transform to fill; a new one when omitted.
  - returns: The transform.
- `sTranslation`: Returns the transform that moves.
  - `inV`: The translation.
  - `out`: Optional. The transform to fill; a new one when omitted.
  - returns: The transform.
- `GetTranslation`: Returns the transform's translation.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The translation.
- `GetQuaternion`: Returns the transform's rotation.
  - `out`: Optional. The quaternion to fill; a new one when omitted.
  - returns: The rotation.

## MeshShapeSettings

*class* in [`libs/jolt/src/helix/jolt/MeshShapeSettings.hx`](../src/helix/jolt/MeshShapeSettings.hx), `import helix.jolt.MeshShapeSettings;`, extends `ShapeSettings`

Represents what a mesh shape is built from: triangles, for a static body such as a level's floors and walls.

```haxe
var settings = MeshShapeSettings.sFromBuffers(mesh.vertices, mesh.indices);
var level = settings.Create().Get();
```

```haxe
function new(?inVertices:VertexList, ?inTriangles:IndexedTriangleList)
static function sFromBuffers(inVertices:haxe.io.Float32Array, ?inIndices:haxe.io.UInt32Array):MeshShapeSettings
var mTriangleVertices:VertexList
var mIndexedTriangles:IndexedTriangleList
var mMaxTrianglesPerLeaf:Int
function Sanitize():Void
```

- `new`: Creates the settings.
  - `inVertices`: Optional. The vertices; none when omitted.
  - `inTriangles`: Optional. The triangles; none when omitted.
- `sFromBuffers`: Returns settings for a mesh's vertices and indices as a renderer holds them, such as helix-raylib's `Mesh`: an extra of helix-jolt's.
  - `inVertices`: Three floats a vertex: x, y and z, in meters.
  - `inIndices`: Optional. Three indices a triangle, counterclockwise seen from the front. When omitted, every three vertices are a triangle.
  - returns: The settings.
- `mTriangleVertices`: Gets or sets the vertices, in meters.
- `mIndexedTriangles`: Gets or sets the triangles.
- `mMaxTrianglesPerLeaf`: Gets or sets the most triangles in a leaf of the shape's tree, 1 to 8. Defaults to 8.
- `Sanitize`: Removes the triangles of no area, and the ones repeated.

## MotorSettings

*class* in [`libs/jolt/src/helix/jolt/MotorSettings.hx`](../src/helix/jolt/MotorSettings.hx), `import helix.jolt.MotorSettings;`

Represents a constraint's motor: how hard it drives, and how its target is reached.

```haxe
function new()
var mSpringSettings:SpringSettings
var mMinForceLimit:Float
var mMaxForceLimit:Float
var mMinTorqueLimit:Float
var mMaxTorqueLimit:Float
```

- `new`: Creates a motor with no limit.
- `mSpringSettings`: Gets or sets the spring the motor drives to a position with. Defaults to 2 hertz, damping 1.
- `mMinForceLimit`: Gets or sets the most force the motor pushes back with, in newtons, 0 or less. Defaults to minus the largest float.
- `mMaxForceLimit`: Gets or sets the most force the motor pushes with, in newtons. Defaults to the largest float.
- `mMinTorqueLimit`: Gets or sets the most torque the motor turns back with, in newton meters, 0 or less. Defaults to minus the largest float.
- `mMaxTorqueLimit`: Gets or sets the most torque the motor turns with, in newton meters. Defaults to the largest float.

## NarrowPhaseQuery

*class* in [`libs/jolt/src/helix/jolt/NarrowPhaseQuery.hx`](../src/helix/jolt/NarrowPhaseQuery.hx), `import helix.jolt.NarrowPhaseQuery;`

Provides the queries against the bodies as they are after the last step: rays, points, overlapping shapes and swept shapes. Returned by `PhysicsSystem.GetNarrowPhaseQuery`.

```haxe
var ray = new RRayCast(origin, direction.MulFloat(100));
var collector = new CastRayClosestHitCollisionCollector();
query.CastRay(ray, settings, collector);
if (collector.HadHit())
var point = ray.GetPointOnRay(collector.mHit.mFraction);
```

A sensor is skipped by every query. Each query adds its hits to the collector, which is emptied with `Reset` before reuse.

```haxe
function CastRay(inRay:RRayCast, inRayCastSettings:RayCastSettings, ioCollector:CastRayCollector, ?inBroadPhaseLayerFilter:BroadPhaseLayerFilter, ?inObjectLayerFilter:ObjectLayerFilter, ?inBodyFilter:BodyFilter, ?inShapeFilter:ShapeFilter):Void
function CollidePoint(inPoint:RVec3, ioCollector:CollidePointCollector, ?inBroadPhaseLayerFilter:BroadPhaseLayerFilter, ?inObjectLayerFilter:ObjectLayerFilter, ?inBodyFilter:BodyFilter, ?inShapeFilter:ShapeFilter):Void
function CollideShape(inShape:Shape, inShapeScale:Vec3, inCenterOfMassTransform:RMat44, inCollideShapeSettings:CollideShapeSettings, inBaseOffset:RVec3, ioCollector:CollideShapeCollector, ?inBroadPhaseLayerFilter:BroadPhaseLayerFilter, ?inObjectLayerFilter:ObjectLayerFilter, ?inBodyFilter:BodyFilter, ?inShapeFilter:ShapeFilter):Void
function CastShape(inShapeCast:RShapeCast, inShapeCastSettings:ShapeCastSettings, inBaseOffset:RVec3, ioCollector:CastShapeCollector, ?inBroadPhaseLayerFilter:BroadPhaseLayerFilter, ?inObjectLayerFilter:ObjectLayerFilter, ?inBodyFilter:BodyFilter, ?inShapeFilter:ShapeFilter):Void
```

- `CastRay`: Casts a ray, collecting the bodies it hits.
  - `inRay`: The ray.
  - `inRayCastSettings`: How faces and solids are treated.
  - `ioCollector`: Receives the hits.
  - `inBroadPhaseLayerFilter`: Optional. The broad phase layers tested; all when omitted.
  - `inObjectLayerFilter`: Optional. The object layers tested; all when omitted.
  - `inBodyFilter`: Optional. The bodies tested; all when omitted.
  - `inShapeFilter`: Optional. The parts of shapes tested; all when omitted.

  The ray reaches as far as its direction is long.
- `CollidePoint`: Finds the bodies a point is inside.
  - `inPoint`: The point, in meters.
  - `ioCollector`: Receives the bodies.
  - `inBroadPhaseLayerFilter`: Optional. The broad phase layers tested; all when omitted.
  - `inObjectLayerFilter`: Optional. The object layers tested; all when omitted.
  - `inBodyFilter`: Optional. The bodies tested; all when omitted.
  - `inShapeFilter`: Optional. The parts of shapes tested; all when omitted.
- `CollideShape`: Finds the bodies a shape overlaps.
  - `inShape`: The shape.
  - `inShapeScale`: The shape's scale.
  - `inCenterOfMassTransform`: The transform of the shape's center of mass.
  - `inCollideShapeSettings`: How the overlap is tested.
  - `inBaseOffset`: A point subtracted from every position to keep the numbers small: the shape's position, or (0, 0, 0).
  - `ioCollector`: Receives the bodies.
  - `inBroadPhaseLayerFilter`: Optional. The broad phase layers tested; all when omitted.
  - `inObjectLayerFilter`: Optional. The object layers tested; all when omitted.
  - `inBodyFilter`: Optional. The bodies tested; all when omitted.
  - `inShapeFilter`: Optional. The parts of shapes tested; all when omitted.
- `CastShape`: Sweeps a shape along a line, collecting the bodies it hits.
  - `inShapeCast`: The shape and its sweep.
  - `inShapeCastSettings`: How faces are treated.
  - `inBaseOffset`: A point subtracted from every position to keep the numbers small: the cast's start, or (0, 0, 0).
  - `ioCollector`: Receives the hits.
  - `inBroadPhaseLayerFilter`: Optional. The broad phase layers tested; all when omitted.
  - `inObjectLayerFilter`: Optional. The object layers tested; all when omitted.
  - `inBodyFilter`: Optional. The bodies tested; all when omitted.
  - `inShapeFilter`: Optional. The parts of shapes tested; all when omitted.

## ObjectLayerFilter

*class* in [`libs/jolt/src/helix/jolt/ObjectLayerFilter.hx`](../src/helix/jolt/ObjectLayerFilter.hx), `import helix.jolt.ObjectLayerFilter;`

Represents which object layers a query tests. Made as a `DefaultObjectLayerFilter` or a `SpecifiedObjectLayerFilter`.

## ObjectLayerPairFilter

*class* in [`libs/jolt/src/helix/jolt/ObjectLayerPairFilter.hx`](../src/helix/jolt/ObjectLayerPairFilter.hx), `import helix.jolt.ObjectLayerPairFilter;`

Represents which object layers collide, set as `JoltSettings.mObjectLayerPairFilter`. Made as an `ObjectLayerPairFilterTable`.

```haxe
function ShouldCollide(inLayer1:Int, inLayer2:Int):Bool
```

- `ShouldCollide`: Returns whether two object layers collide.
  - `inLayer1`: One layer.
  - `inLayer2`: The other layer.
  - returns: True when bodies in the two layers collide.

## ObjectLayerPairFilterTable

*class* in [`libs/jolt/src/helix/jolt/ObjectLayerPairFilterTable.hx`](../src/helix/jolt/ObjectLayerPairFilterTable.hx), `import helix.jolt.ObjectLayerPairFilterTable;`, extends `ObjectLayerPairFilter`

Represents which object layers collide, set in a table.

```haxe
var objectFilter = new ObjectLayerPairFilterTable(2);
objectFilter.EnableCollision(LAYER_NON_MOVING, LAYER_MOVING);
objectFilter.EnableCollision(LAYER_MOVING, LAYER_MOVING);
```

```haxe
function new(inNumObjectLayers:Int)
function GetNumObjectLayers():Int
function EnableCollision(inLayer1:Int, inLayer2:Int):Void
function DisableCollision(inLayer1:Int, inLayer2:Int):Void
```

- `new`: Creates a table where no layers collide.
  - `inNumObjectLayers`: The number of object layers.
- `GetNumObjectLayers`: Returns the number of object layers.
  - returns: The count.
- `EnableCollision`: Makes two object layers collide, each with the other.
  - `inLayer1`: One layer.
  - `inLayer2`: The other layer, or the same one.
- `DisableCollision`: Makes two object layers pass through each other.
  - `inLayer1`: One layer.
  - `inLayer2`: The other layer, or the same one.

## ObjectVsBroadPhaseLayerFilter

*class* in [`libs/jolt/src/helix/jolt/ObjectVsBroadPhaseLayerFilter.hx`](../src/helix/jolt/ObjectVsBroadPhaseLayerFilter.hx), `import helix.jolt.ObjectVsBroadPhaseLayerFilter;`

Represents which broad phase layers each object layer meets, set as `JoltSettings.mObjectVsBroadPhaseLayerFilter`. Made as an `ObjectVsBroadPhaseLayerFilterTable`.

## ObjectVsBroadPhaseLayerFilterTable

*class* in [`libs/jolt/src/helix/jolt/ObjectVsBroadPhaseLayerFilterTable.hx`](../src/helix/jolt/ObjectVsBroadPhaseLayerFilterTable.hx), `import helix.jolt.ObjectVsBroadPhaseLayerFilterTable;`, extends `ObjectVsBroadPhaseLayerFilter`

Represents which broad phase layers each object layer meets, worked out from the object layers that collide and the broad phase layer each is in.

```haxe
function new(inBroadPhaseLayerInterface:BroadPhaseLayerInterfaceTable, inNumBroadPhaseLayers:Int, inObjectLayerPairFilter:ObjectLayerPairFilterTable, inNumObjectLayers:Int)
```

- `new`: Creates the filter.
  - `inBroadPhaseLayerInterface`: The map from object layers to broad phase layers.
  - `inNumBroadPhaseLayers`: The number of broad phase layers.
  - `inObjectLayerPairFilter`: The object layers that collide.
  - `inNumObjectLayers`: The number of object layers.

## OffsetCenterOfMassShape

*class* in [`libs/jolt/src/helix/jolt/OffsetCenterOfMassShape.hx`](../src/helix/jolt/OffsetCenterOfMassShape.hx), `import helix.jolt.OffsetCenterOfMassShape;`, extends `Shape`

Represents another shape with its center of mass moved: a car's, low, so it doesn't roll.

```haxe
function new(inShape:Shape, inOffset:Vec3)
```

- `new`: Creates the shape, holding the shape it changes.
  - `inShape`: The shape.
  - `inOffset`: How far the center of mass moves, in meters.

## PhysicsSettings

*class* in [`libs/jolt/src/helix/jolt/PhysicsSettings.hx`](../src/helix/jolt/PhysicsSettings.hx), `import helix.jolt.PhysicsSettings;`

Represents a `PhysicsSystem`'s solver and sleep settings. Read with `PhysicsSystem.GetPhysicsSettings`, changed, and set with `PhysicsSystem.SetPhysicsSettings`. The defaults are Jolt's.

```haxe
function new()
var mBaumgarte:Float
var mSpeculativeContactDistance:Float
var mPenetrationSlop:Float
var mLinearCastThreshold:Float
var mNumVelocitySteps:Int
var mNumPositionSteps:Int
var mMinVelocityForRestitution:Float
var mTimeBeforeSleep:Float
var mPointVelocitySleepThreshold:Float
var mAllowSleeping:Bool
var mCheckActiveEdges:Bool
```

- `new`: Creates settings with Jolt's defaults.
- `mBaumgarte`: Gets or sets the share of the penetration removed each step, 0 to 1. Defaults to 0.2.
- `mSpeculativeContactDistance`: Gets or sets the distance at which contacts are made before shapes touch, in meters. Defaults to 0.02.
- `mPenetrationSlop`: Gets or sets the penetration allowed, in meters. Defaults to 0.02.
- `mLinearCastThreshold`: Gets or sets the share of a body's inner radius it may move in a step before a `EMotionQuality_LinearCast` body is cast. Defaults to 0.75.
- `mNumVelocitySteps`: Gets or sets the velocity steps of the solver each collision step. Defaults to 10.
- `mNumPositionSteps`: Gets or sets the position steps of the solver each collision step. Defaults to 2.
- `mMinVelocityForRestitution`: Gets or sets the slowest closing speed that bounces, in meters a second. Defaults to 1.
- `mTimeBeforeSleep`: Gets or sets the seconds a body must be still before it sleeps. Defaults to 0.5.
- `mPointVelocitySleepThreshold`: Gets or sets the speed below which a body's points count as still, in meters a second. Defaults to 0.03.
- `mAllowSleeping`: Gets or sets a value indicating whether bodies may sleep. Defaults to true.
- `mCheckActiveEdges`: Gets or sets a value indicating whether a contact on a mesh's inner edge is corrected to the face's normal. Defaults to true.

## PhysicsSystem

*class* in [`libs/jolt/src/helix/jolt/PhysicsSystem.hx`](../src/helix/jolt/PhysicsSystem.hx), `import helix.jolt.PhysicsSystem;`

Represents the simulation inside a `JoltInterface`: its gravity, its bodies, its constraints and its queries. Returned by `JoltInterface.GetPhysicsSystem`.

```haxe
function SetGravity(inGravity:Vec3):Void
function GetGravity(?out:Vec3):Vec3
function GetPhysicsSettings(?out:PhysicsSettings):PhysicsSettings
function SetPhysicsSettings(inPhysicsSettings:PhysicsSettings):Void
function GetNumBodies():Int
function GetNumActiveBodies(inBodyType:EBodyType):Int
function GetMaxBodies():Int
function GetBodies(outBodies:BodyIDVector):Void
function GetActiveBodies(inBodyType:EBodyType, outBodies:BodyIDVector):Void
function GetBounds(?out:AABox):AABox
function AddConstraint(inConstraint:Constraint):Void
function RemoveConstraint(inConstraint:Constraint):Void
function SetContactListener(inListener:Null<ContactListener>):Void
function GetContactListener():Null<ContactListener>
function OptimizeBroadPhase():Void
function GetBodyInterface():BodyInterface
function GetBodyLockInterfaceNoLock():BodyLockInterfaceNoLock
function GetNarrowPhaseQuery():NarrowPhaseQuery
function WereBodiesInContact(inBodyID1:BodyID, inBodyID2:BodyID):Bool
```

- `SetGravity`: Sets the gravity every body falls by, scaled by each body's gravity factor.
  - `inGravity`: The acceleration, in meters a second squared. Defaults to (0, -9.81, 0).
- `GetGravity`: Returns the gravity.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The acceleration, in meters a second squared.
- `GetPhysicsSettings`: Returns the system's solver and sleep settings.
  - `out`: Optional. The settings to fill; new ones when omitted.
  - returns: A copy of the settings.
- `SetPhysicsSettings`: Sets the system's solver and sleep settings.
  - `inPhysicsSettings`: The settings, read once.
- `GetNumBodies`: Returns the number of bodies made, added or not.
  - returns: The count.
- `GetNumActiveBodies`: Returns the number of bodies awake.
  - `inBodyType`: The kind of body counted.
  - returns: The count.
- `GetMaxBodies`: Returns the most bodies the system holds, from `JoltSettings.mMaxBodies`.
  - returns: The limit.
- `GetBodies`: Fills a list with every body made.
  - `outBodies`: The list, emptied first.
- `GetActiveBodies`: Fills a list with every body awake, dynamic and kinematic: the bodies that moved in the last step, and the ones to read after it.
  - `inBodyType`: The kind of body listed.
  - `outBodies`: The list, emptied first.
- `GetBounds`: Returns the bounds of every body in the system.
  - `out`: Optional. The box to fill; a new one when omitted.
  - returns: The bounds.
- `AddConstraint`: Adds a constraint, which then acts at each step.
  - `inConstraint`: The constraint, made by `BodyInterface.CreateConstraint`.
- `RemoveConstraint`: Removes a constraint. The constraint is kept and may be added again.
  - `inConstraint`: The constraint.
- `SetContactListener`: Sets what hears of contacts between bodies during a step, or null for none.
  - `inListener`: The listener, a `ContactEventQueue`.
- `GetContactListener`: Returns what hears of contacts between bodies.
  - returns: The listener, or null if there is none.
- `OptimizeBroadPhase`: Rebuilds the broad phase's tree for the bodies added. Called once after adding many bodies, before the first step, it makes the first queries and steps faster.
- `GetBodyInterface`: Returns the interface that makes bodies and reads and changes them.
  - returns: The interface.
- `GetBodyLockInterfaceNoLock`: Returns the interface that returns a `Body` by its id.
  - returns: The interface.
- `GetNarrowPhaseQuery`: Returns the interface that answers ray casts, shape casts and overlaps against the bodies.
  - returns: The interface.
- `WereBodiesInContact`: Returns whether two bodies touched in the last step.
  - `inBodyID1`: One body.
  - `inBodyID2`: The other body.
  - returns: True when their shapes were in contact.

## Plane

*class* in [`libs/jolt/src/helix/jolt/Plane.hx`](../src/helix/jolt/Plane.hx), `import helix.jolt.Plane;`

Represents a plane, by its normal and its distance from the origin.

```haxe
function new(inNormal:Vec3, inConstant:Float)
function GetNormal(?out:Vec3):Vec3
function GetConstant():Float
```

- `new`: Creates a plane: the points p where `inNormal.Dot(p) + inConstant` is 0.
  - `inNormal`: The normal, of length 1.
  - `inConstant`: The plane's signed distance from the origin, along the normal, negated.
- `GetNormal`: Returns the normal.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The normal.
- `GetConstant`: Returns the plane's constant.
  - returns: The constant.

## PlaneShape

*class* in [`libs/jolt/src/helix/jolt/PlaneShape.hx`](../src/helix/jolt/PlaneShape.hx), `import helix.jolt.PlaneShape;`, extends `Shape`

Represents a plane, solid below it, for the ground of a static body.

```haxe
function new(inPlane:Plane, ?inHalfExtent:Float = 1000.)
```

- `new`: Creates the shape.
  - `inPlane`: The plane.
  - `inHalfExtent`: Optional. Half the size of the square of the plane used for the broad phase, in meters; defaults to 1000.

## PointConstraintSettings

*class* in [`libs/jolt/src/helix/jolt/PointConstraintSettings.hx`](../src/helix/jolt/PointConstraintSettings.hx), `import helix.jolt.PointConstraintSettings;`, extends `TwoBodyConstraintSettings`

Represents a constraint holding a point of one body to a point of another, the bodies free to turn: a ball joint.

```haxe
function new()
var mPoint1:RVec3
var mPoint2:RVec3
```

- `new`: Creates the settings.
- `mPoint1`: Gets or sets the point on the first body, in meters. Defaults to (0, 0, 0).
- `mPoint2`: Gets or sets the point on the second body, in meters. Defaults to (0, 0, 0).

## Quat

*abstract* in [`libs/jolt/src/helix/jolt/Quat.hx`](../src/helix/jolt/Quat.hx), `import helix.jolt.Quat;`

Represents Jolt's `Quat`: a rotation. Wraps helix-math's `Quaternion`, whose fields and methods it also has, and is passed as a `Quaternion` without a copy.

_Note that a `Quat` is assigned by reference. An operation accepts an optional `out` that receives the result, and makes a new `Quat` when `out` is omitted._

```haxe
static function sIdentity(?out:Quat):Quat
static function sRotation(inAxis:Vec3, inAngle:Float, ?out:Quat):Quat
static function sFromTo(inFrom:Vec3, inTo:Vec3, ?out:Quat):Quat
static function sEulerAngles(inInput:Vec3, ?out:Quat):Quat
function GetX():Float
function GetY():Float
function GetZ():Float
function GetW():Float
function Set(inX:Float, inY:Float, inZ:Float, inW:Float):Void
function GetEulerAngles(?out:Vec3):Vec3
function MulQuat(inQ:Quat, ?out:Quat):Quat
function MulVec3(inV:Vec3, ?out:Vec3):Vec3
function Normalized(?out:Quat):Quat
function Conjugated(?out:Quat):Quat
function SLERP(inDestination:Quat, inFraction:Float, ?out:Quat):Quat
```

- `sIdentity`: Returns the rotation that turns nothing.
  - `out`: Optional. The quaternion to fill; a new one when omitted.
  - returns: The quaternion.
- `sRotation`: Returns a rotation about an axis.
  - `inAxis`: The axis, of length 1.
  - `inAngle`: The angle, in radians.
  - `out`: Optional. The quaternion to fill; a new one when omitted.
  - returns: The quaternion.
- `sFromTo`: Returns the shortest rotation turning one direction onto another.
  - `inFrom`: The first direction.
  - `inTo`: The second direction.
  - `out`: Optional. The quaternion to fill; a new one when omitted.
  - returns: The quaternion.
- `sEulerAngles`: Returns the rotation of angles about x, then y, then z.
  - `inInput`: The angles, in radians.
  - `out`: Optional. The quaternion to fill; a new one when omitted.
  - returns: The quaternion.
- `GetX`: Returns the x component.
  - returns: The component.
- `GetY`: Returns the y component.
  - returns: The component.
- `GetZ`: Returns the z component.
  - returns: The component.
- `GetW`: Returns the w component.
  - returns: The component.
- `Set`: Sets the four components.
  - `inX`: The x component.
  - `inY`: The y component.
  - `inZ`: The z component.
  - `inW`: The w component.
- `GetEulerAngles`: Returns the angles about x, then y, then z, that make the rotation.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The angles, in radians.
- `MulQuat`: Returns another rotation followed by this one, as Jolt's `*` does.
  - `inQ`: The rotation applied first.
  - `out`: Optional. The quaternion to fill; a new one when omitted. It may be either quaternion.
  - returns: The product.
- `MulVec3`: Returns a vector turned by the rotation.
  - `inV`: The vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be inV.
  - returns: The turned vector.
- `Normalized`: Returns the rotation scaled to a length of 1.
  - `out`: Optional. The quaternion to fill; a new one when omitted. It may be this quaternion.
  - returns: The quaternion.
- `Conjugated`: Returns the opposite rotation.
  - `out`: Optional. The quaternion to fill; a new one when omitted. It may be this quaternion.
  - returns: The quaternion.
- `SLERP`: Returns the rotation a fraction of the way to another, along the sphere.
  - `inDestination`: The rotation at 1.
  - `inFraction`: The fraction, 0 to 1.
  - `out`: Optional. The quaternion to fill; a new one when omitted. It may be either quaternion.
  - returns: The rotation.

## RMat44

*typedef* in [`libs/jolt/src/helix/jolt/RMat44.hx`](../src/helix/jolt/RMat44.hx), `import helix.jolt.RMat44;`

Represents Jolt's `RMat44`: a transform in the world. The module is single precision, so an `RMat44` is a `Mat44`.

An alias of [`Mat44`](types.md#mat44).

## RRayCast

*class* in [`libs/jolt/src/helix/jolt/RRayCast.hx`](../src/helix/jolt/RRayCast.hx), `import helix.jolt.RRayCast;`

Represents a ray: an origin and a direction whose length is how far the ray reaches.

```haxe
function new(?inOrigin:RVec3, ?inDirection:Vec3)
var mOrigin:RVec3
var mDirection:Vec3
function GetPointOnRay(inFraction:Float, ?out:RVec3):RVec3
```

- `new`: Creates a ray.
  - `inOrigin`: Optional. The origin; defaults to (0, 0, 0).
  - `inDirection`: Optional. The direction and reach; defaults to (0, 0, 0).
- `mOrigin`: Gets or sets the origin, in meters.
- `mDirection`: Gets or sets the direction, its length how far the ray reaches, in meters.
- `GetPointOnRay`: Returns the point a fraction of the way along the ray, such as a hit's.
  - `inFraction`: The fraction, from a result's `mFraction`.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The point, in meters.

## RShapeCast

*class* in [`libs/jolt/src/helix/jolt/RShapeCast.hx`](../src/helix/jolt/RShapeCast.hx), `import helix.jolt.RShapeCast;`

Represents a shape swept along a line: a sphere for a thick ray, a character's capsule for where it would stop.

```haxe
function new(inShape:Shape, inScale:Vec3, inCenterOfMassStart:RMat44, inDirection:Vec3)
var mShape(default, null):Shape
var mScale(default, null):Vec3
var mCenterOfMassStart(default, null):RMat44
var mDirection(default, null):Vec3
function GetPointOnRay(inFraction:Float, ?out:RVec3):RVec3
```

- `new`: Creates a shape cast.
  - `inShape`: The shape.
  - `inScale`: The shape's scale.
  - `inCenterOfMassStart`: The transform of the shape's center of mass at the start.
  - `inDirection`: The direction, its length how far the shape is swept, in meters.
- `mShape`: Gets the shape.
- `mScale`: Gets the shape's scale.
- `mCenterOfMassStart`: Gets the transform of the shape's center of mass at the start.
- `mDirection`: Gets the direction, its length how far the shape is swept, in meters.
- `GetPointOnRay`: Returns where the shape's center of mass is a fraction of the way along the cast.
  - `inFraction`: The fraction, from a result's `mFraction`.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The point, in meters.

## RVec3

*typedef* in [`libs/jolt/src/helix/jolt/RVec3.hx`](../src/helix/jolt/RVec3.hx), `import helix.jolt.RVec3;`

Represents Jolt's `RVec3`: a position in the world. The module is single precision, so an `RVec3` is a `Vec3`.

An alias of [`Vec3`](types.md#vec3).

## RayCastResult

*class* in [`libs/jolt/src/helix/jolt/RayCastResult.hx`](../src/helix/jolt/RayCastResult.hx), `import helix.jolt.RayCastResult;`

Represents a ray cast's hit.

```haxe
function new()
var mBodyID:BodyID
var mFraction:Float
var mSubShapeID2:SubShapeID
```

- `new`: Creates a result of no hit.
- `mBodyID`: Gets or sets the body hit.
- `mFraction`: Gets or sets how far along the ray the hit is, 0 to 1: `RRayCast.GetPointOnRay` returns the point.
- `mSubShapeID2`: Gets or sets the part of the body's shape hit, for the normal there: `physicsSystem.GetBodyLockInterfaceNoLock().TryGetBody(hit.mBodyID).GetWorldSpaceSurfaceNormal(hit.mSubShapeID2, point)`.

## RayCastSettings

*class* in [`libs/jolt/src/helix/jolt/RayCastSettings.hx`](../src/helix/jolt/RayCastSettings.hx), `import helix.jolt.RayCastSettings;`

Represents how a ray cast treats faces and solids.

```haxe
function new()
var mBackFaceModeTriangles:EBackFaceMode
var mBackFaceModeConvex:EBackFaceMode
var mTreatConvexAsSolid:Bool
function SetBackFaceMode(inBackFaceMode:EBackFaceMode):Void
```

- `new`: Creates the default settings.
- `mBackFaceModeTriangles`: Gets or sets whether a mesh's triangle is hit from behind. Defaults to `EBackFaceMode_IgnoreBackFaces`.
- `mBackFaceModeConvex`: Gets or sets whether a convex shape is hit from inside, at its far side. Defaults to `EBackFaceMode_IgnoreBackFaces`.
- `mTreatConvexAsSolid`: Gets or sets a value indicating whether a ray starting inside a convex shape hits it at its origin. Defaults to true.
- `SetBackFaceMode`: Sets both back face modes.
  - `inBackFaceMode`: The mode.

## RotatedTranslatedShapeSettings

*class* in [`libs/jolt/src/helix/jolt/RotatedTranslatedShapeSettings.hx`](../src/helix/jolt/RotatedTranslatedShapeSettings.hx), `import helix.jolt.RotatedTranslatedShapeSettings;`, extends `ShapeSettings`

Represents what a moved and turned shape is built from: another shape, away from its body's origin.

```haxe
function new(inPosition:Vec3, inRotation:Quat, inShape:Shape)
var mPosition:Vec3
var mRotation:Quat
```

- `new`: Creates the settings.
  - `inPosition`: Where the shape is, from the body's origin, in meters.
  - `inRotation`: How the shape is turned.
  - `inShape`: The shape.
- `mPosition`: Gets or sets where the shape is, from the body's origin, in meters.
- `mRotation`: Gets or sets how the shape is turned.

## ScaledShape

*class* in [`libs/jolt/src/helix/jolt/ScaledShape.hx`](../src/helix/jolt/ScaledShape.hx), `import helix.jolt.ScaledShape;`, extends `Shape`

Represents another shape scaled.

```haxe
function new(inShape:Shape, inScale:Vec3)
function GetScale(?out:Vec3):Vec3
```

- `new`: Creates a scaled shape, holding the shape it scales.
  - `inShape`: The shape.
  - `inScale`: The scale along each axis. A sphere or capsule scales by the same amount along every axis.
- `GetScale`: Returns the scale.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The scale along each axis.

## Shape

*class* in [`libs/jolt/src/helix/jolt/Shape.hx`](../src/helix/jolt/Shape.hx), `import helix.jolt.Shape;`

Represents a shape, which bodies share: made directly (`BoxShape`, `SphereShape`) or by a settings object's `Create`.

A shape is counted by what holds it. A body made from a shape holds it, and the shape is freed when the last body holding it is destroyed. A shape kept to make bodies later is held by the program with `AddRef`, and let go with `Release`. `Jolt.destroy` frees every shape, held or not, and a shape no body ever held.

```haxe
function GetRefCount():Int
function AddRef():Void
function Release():Void
function GetType():EShapeType
function GetSubType():EShapeSubType
function MustBeStatic():Bool
function GetLocalBounds(?out:AABox):AABox
function GetCenterOfMass(?out:Vec3):Vec3
function GetVolume():Float
function GetMassProperties(?out:MassProperties):MassProperties
function GetUserData():Int
function SetUserData(inUserData:Int):Void
```

- `GetRefCount`: Returns how many hold the shape.
  - returns: The count.
- `AddRef`: Holds the shape: it stays until `Release` is called as often.
- `Release`: Lets go of the shape, freeing it when nothing else holds it.
- `GetType`: Returns the shape's family.
  - returns: The family.
- `GetSubType`: Returns the shape's kind.
  - returns: The kind.
- `MustBeStatic`: Returns whether only a static body may use the shape, as a mesh or a height field.
  - returns: True when the shape must be static.
- `GetLocalBounds`: Returns the shape's bounds about its own center of mass.
  - `out`: Optional. The box to fill; a new one when omitted.
  - returns: The bounds.
- `GetCenterOfMass`: Returns the shape's center of mass, from its own origin.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The center of mass, in meters.
- `GetVolume`: Returns the shape's volume.
  - returns: The volume, in cubic meters.
- `GetMassProperties`: Returns the shape's mass and inertia from its density.
  - `out`: Optional. The mass properties to fill; new ones when omitted.
  - returns: The mass properties.
- `GetUserData`: Returns the number a program keeps with the shape.
  - returns: The number.
- `SetUserData`: Sets the number a program keeps with the shape.
  - `inUserData`: The number.

## ShapeCastResult

*class* in [`libs/jolt/src/helix/jolt/ShapeCastResult.hx`](../src/helix/jolt/ShapeCastResult.hx), `import helix.jolt.ShapeCastResult;`, extends `CollideShapeResult`

Represents a shape cast's hit: where the swept shape first touches a body.

```haxe
function new()
var mFraction:Float
var mIsBackFaceHit:Bool
```

- `new`: Creates an empty result.
- `mFraction`: Gets or sets how far along the cast the hit is, 0 to 1.
- `mIsBackFaceHit`: Gets or sets a value indicating whether a face was hit from behind.

## ShapeCastSettings

*class* in [`libs/jolt/src/helix/jolt/ShapeCastSettings.hx`](../src/helix/jolt/ShapeCastSettings.hx), `import helix.jolt.ShapeCastSettings;`

Represents how a shape cast treats faces.

```haxe
function new()
var mBackFaceModeTriangles:EBackFaceMode
var mBackFaceModeConvex:EBackFaceMode
var mReturnDeepestPoint:Bool
```

- `new`: Creates the default settings.
- `mBackFaceModeTriangles`: Gets or sets whether a mesh's triangle is hit from behind. Defaults to `EBackFaceMode_IgnoreBackFaces`.
- `mBackFaceModeConvex`: Gets or sets whether a convex shape is hit from inside. Defaults to `EBackFaceMode_IgnoreBackFaces`.
- `mReturnDeepestPoint`: Gets or sets a value indicating whether a shape that starts overlapping returns its deepest point. Defaults to false.

## ShapeFilter

*class* in [`libs/jolt/src/helix/jolt/ShapeFilter.hx`](../src/helix/jolt/ShapeFilter.hx), `import helix.jolt.ShapeFilter;`

Represents which parts of shapes a query tests: every part.

```haxe
function new()
```

- `new`: Creates the filter.

## ShapeResult

*class* in [`libs/jolt/src/helix/jolt/ShapeResult.hx`](../src/helix/jolt/ShapeResult.hx), `import helix.jolt.ShapeResult;`

Represents the outcome of `ShapeSettings.Create`: the shape, or why it couldn't be built.

```haxe
function IsValid():Bool
function HasError():Bool
function GetError():String
function Get():Null<Shape>
```

- `IsValid`: Returns whether the shape was built.
  - returns: True when `Get` returns the shape.
- `HasError`: Returns whether the shape couldn't be built.
  - returns: True when `GetError` says why.
- `GetError`: Returns why the shape couldn't be built.
  - returns: The reason, or an empty string when the shape was built.
- `Get`: Returns the shape.
  - returns: The shape, or null when it couldn't be built.

## ShapeSettings

*class* in [`libs/jolt/src/helix/jolt/ShapeSettings.hx`](../src/helix/jolt/ShapeSettings.hx), `import helix.jolt.ShapeSettings;`

Represents what a shape is built from: a hull's points, a mesh's triangles, a compound's parts. `Create` builds the shape.

```haxe
var hull = new ConvexHullShapeSettings();
hull.mPoints = points;
var result = hull.Create();
if (result.HasError())
trace(result.GetError());
var shape = result.Get();
```

```haxe
var mUserData:Int
function Create():ShapeResult
```

- `mUserData`: Gets or sets the number the shape keeps for the program. Defaults to 0.
- `Create`: Builds the shape.
  - returns: The result: the shape, or why it couldn't be built.

## SixDOFConstraint

*class* in [`libs/jolt/src/helix/jolt/SixDOFConstraint.hx`](../src/helix/jolt/SixDOFConstraint.hx), `import helix.jolt.SixDOFConstraint;`, extends `TwoBodyConstraint`

Represents a six degrees of freedom constraint, made by `SixDOFConstraintSettings`. Its targets are in the constraint's space, which `CS` ends their names with.

```haxe
function SetTranslationLimits(inLimitMin:Vec3, inLimitMax:Vec3):Void
function SetRotationLimits(inLimitMin:Vec3, inLimitMax:Vec3):Void
function GetLimitsMin(inAxis:SixDOFConstraintSettings_EAxis):Float
function GetLimitsMax(inAxis:SixDOFConstraintSettings_EAxis):Float
function IsFixedAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool
function IsFreeAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool
function SetMaxFriction(inAxis:SixDOFConstraintSettings_EAxis, inFriction:Float):Void
function GetMotorSettings(inAxis:SixDOFConstraintSettings_EAxis):MotorSettings
function SetMotorState(inAxis:SixDOFConstraintSettings_EAxis, inState:EMotorState):Void
function GetMotorState(inAxis:SixDOFConstraintSettings_EAxis):EMotorState
function SetTargetVelocityCS(inVelocity:Vec3):Void
function SetTargetAngularVelocityCS(inAngularVelocity:Vec3):Void
function SetTargetPositionCS(inPosition:Vec3):Void
function SetTargetOrientationCS(inOrientation:Quat):Void
```

- `SetTranslationLimits`: Sets the limits of moving along each axis.
  - `inLimitMin`: The lowest positions, in meters.
  - `inLimitMax`: The highest positions, in meters.
- `SetRotationLimits`: Sets the limits of turning about each axis.
  - `inLimitMin`: The smallest angles, in radians.
  - `inLimitMax`: The largest angles, in radians.
- `GetLimitsMin`: Returns an axis' lowest value.
  - `inAxis`: The axis.
  - returns: The value: meters or radians.
- `GetLimitsMax`: Returns an axis' highest value.
  - `inAxis`: The axis.
  - returns: The value: meters or radians.
- `IsFixedAxis`: Returns whether an axis is fixed.
  - `inAxis`: The axis.
  - returns: True when fixed.
- `IsFreeAxis`: Returns whether an axis is free.
  - `inAxis`: The axis.
  - returns: True when free.
- `SetMaxFriction`: Sets an axis' friction.
  - `inAxis`: The axis.
  - `inFriction`: A force, in newtons, or a torque, in newton meters.
- `GetMotorSettings`: Returns an axis' motor settings, which may be changed in place.
  - `inAxis`: The axis.
  - returns: The settings.
- `SetMotorState`: Sets what an axis' motor drives toward.
  - `inAxis`: The axis.
  - `inState`: The state.
- `GetMotorState`: Returns what an axis' motor drives toward.
  - `inAxis`: The axis.
  - returns: The state.
- `SetTargetVelocityCS`: Sets the velocity the motors drive to.
  - `inVelocity`: The velocity, in meters a second.
- `SetTargetAngularVelocityCS`: Sets the angular velocity the motors drive to.
  - `inAngularVelocity`: The angular velocity, in radians a second about each axis.
- `SetTargetPositionCS`: Sets the position the motors drive to.
  - `inPosition`: The position, in meters.
- `SetTargetOrientationCS`: Sets the rotation the motors drive to.
  - `inOrientation`: The rotation.

## SixDOFConstraintSettings

*class* in [`libs/jolt/src/helix/jolt/SixDOFConstraintSettings.hx`](../src/helix/jolt/SixDOFConstraintSettings.hx), `import helix.jolt.SixDOFConstraintSettings;`, extends `TwoBodyConstraintSettings`

Represents a constraint whose six axes (three of moving, three of turning) are each free, fixed or limited, with a motor each.

```haxe
function new()
var mPosition1:RVec3
var mAxisX1:Vec3
var mAxisY1:Vec3
var mPosition2:RVec3
var mAxisX2:Vec3
var mAxisY2:Vec3
var mMaxFriction:Array<Float>
var mLimitMin:Array<Float>
var mLimitMax:Array<Float>
var mLimitsSpringSettings:Array<SpringSettings>
var mMotorSettings:Array<MotorSettings>
function MakeFreeAxis(inAxis:SixDOFConstraintSettings_EAxis):Void
function MakeFixedAxis(inAxis:SixDOFConstraintSettings_EAxis):Void
function SetLimitedAxis(inAxis:SixDOFConstraintSettings_EAxis, inMin:Float, inMax:Float):Void
function IsFreeAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool
function IsFixedAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool
```

- `new`: Creates the settings with every axis free.
- `mPosition1`: Gets or sets the constraint's point on the first body, in meters. Defaults to (0, 0, 0).
- `mAxisX1`: Gets or sets the constraint's x axis on the first body. Defaults to (1, 0, 0).
- `mAxisY1`: Gets or sets the constraint's y axis on the first body. Defaults to (0, 1, 0).
- `mPosition2`: Gets or sets the constraint's point on the second body, in meters. Defaults to (0, 0, 0).
- `mAxisX2`: Gets or sets the constraint's x axis on the second body. Defaults to (1, 0, 0).
- `mAxisY2`: Gets or sets the constraint's y axis on the second body. Defaults to (0, 1, 0).
- `mMaxFriction`: Gets or sets each axis' friction, by `SixDOFConstraintSettings_EAxis`: a force, in newtons, or a torque, in newton meters.
- `mLimitMin`: Gets or sets each axis' lowest value, by `SixDOFConstraintSettings_EAxis`: meters or radians.
- `mLimitMax`: Gets or sets each axis' highest value, by `SixDOFConstraintSettings_EAxis`: meters or radians.
- `mLimitsSpringSettings`: Gets or sets each axis' spring at its limits, by `SixDOFConstraintSettings_EAxis`.
- `mMotorSettings`: Gets or sets each axis' motor, by `SixDOFConstraintSettings_EAxis`.
- `MakeFreeAxis`: Frees an axis.
  - `inAxis`: The axis.
- `MakeFixedAxis`: Fixes an axis.
  - `inAxis`: The axis.
- `SetLimitedAxis`: Limits an axis to a range.
  - `inAxis`: The axis.
  - `inMin`: The lowest value: meters or radians.
  - `inMax`: The highest value: meters or radians.
- `IsFreeAxis`: Returns whether an axis is free.
  - `inAxis`: The axis.
  - returns: True when free.
- `IsFixedAxis`: Returns whether an axis is fixed.
  - `inAxis`: The axis.
  - returns: True when fixed.

## SixDOFConstraintSettings_EAxis

*abstract* in [`libs/jolt/src/helix/jolt/SixDOFConstraintSettings_EAxis.hx`](../src/helix/jolt/SixDOFConstraintSettings_EAxis.hx), `import helix.jolt.SixDOFConstraintSettings_EAxis;`

Specifies one of a six degrees of freedom constraint's axes.

- `SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_TranslationX`: Moving along x.
- `SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_TranslationY`: Moving along y.
- `SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_TranslationZ`: Moving along z.
- `SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_RotationX`: Turning about x.
- `SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_RotationY`: Turning about y.
- `SixDOFConstraintSettings_EAxis.SixDOFConstraintSettings_EAxis_RotationZ`: Turning about z.

## SliderConstraint

*class* in [`libs/jolt/src/helix/jolt/SliderConstraint.hx`](../src/helix/jolt/SliderConstraint.hx), `import helix.jolt.SliderConstraint;`, extends `TwoBodyConstraint`

Represents a slider, made by `SliderConstraintSettings`.

```haxe
function GetCurrentPosition():Float
function SetMaxFrictionForce(inFrictionForce:Float):Void
function GetMaxFrictionForce():Float
function GetMotorSettings():MotorSettings
function SetMotorState(inState:EMotorState):Void
function GetMotorState():EMotorState
function SetTargetVelocity(inVelocity:Float):Void
function GetTargetVelocity():Float
function SetTargetPosition(inPosition:Float):Void
function GetTargetPosition():Float
function SetLimits(inLimitsMin:Float, inLimitsMax:Float):Void
function GetLimitsMin():Float
function GetLimitsMax():Float
function HasLimits():Bool
```

- `GetCurrentPosition`: Returns the slider's position, 0 at the pose the bodies had when the constraint was made.
  - returns: The position, in meters.
- `SetMaxFrictionForce`: Sets the friction force that slows the slider.
  - `inFrictionForce`: The force, in newtons.
- `GetMaxFrictionForce`: Returns the friction force that slows the slider.
  - returns: The force, in newtons.
- `GetMotorSettings`: Returns the motor's settings, which may be changed in place.
  - returns: The settings.
- `SetMotorState`: Sets what the motor drives toward.
  - `inState`: The state.
- `GetMotorState`: Returns what the motor drives toward.
  - returns: The state.
- `SetTargetVelocity`: Sets the velocity the motor drives to, under `EMotorState_Velocity`.
  - `inVelocity`: The velocity, in meters a second.
- `GetTargetVelocity`: Returns the velocity the motor drives to.
  - returns: The velocity, in meters a second.
- `SetTargetPosition`: Sets the position the motor drives to, under `EMotorState_Position`.
  - `inPosition`: The position, in meters.
- `GetTargetPosition`: Returns the position the motor drives to.
  - returns: The position, in meters.
- `SetLimits`: Sets the slider's limits.
  - `inLimitsMin`: The lowest position, in meters.
  - `inLimitsMax`: The highest position, in meters.
- `GetLimitsMin`: Returns the lowest position.
  - returns: The position, in meters.
- `GetLimitsMax`: Returns the highest position.
  - returns: The position, in meters.
- `HasLimits`: Returns whether the slider is limited.
  - returns: True when the slider has a lowest or highest position.

## SliderConstraintSettings

*class* in [`libs/jolt/src/helix/jolt/SliderConstraintSettings.hx`](../src/helix/jolt/SliderConstraintSettings.hx), `import helix.jolt.SliderConstraintSettings;`, extends `TwoBodyConstraintSettings`

Represents a constraint letting two bodies move apart along one axis, without turning: a drawer, a piston.

```haxe
function new()
var mAutoDetectPoint:Bool
var mPoint1:RVec3
var mSliderAxis1:Vec3
var mNormalAxis1:Vec3
var mPoint2:RVec3
var mSliderAxis2:Vec3
var mNormalAxis2:Vec3
var mLimitsMin:Float
var mLimitsMax:Float
var mLimitsSpringSettings:SpringSettings
var mMaxFrictionForce:Float
var mMotorSettings:MotorSettings
```

- `new`: Creates the settings.
- `mAutoDetectPoint`: Gets or sets a value indicating whether the point is where the bodies are when the constraint is made. Defaults to false.
- `mPoint1`: Gets or sets the slider's point on the first body, in meters. Defaults to (0, 0, 0).
- `mSliderAxis1`: Gets or sets the slider's axis on the first body. Defaults to (1, 0, 0).
- `mNormalAxis1`: Gets or sets an axis at right angles to the slider's on the first body. Defaults to (0, 1, 0).
- `mPoint2`: Gets or sets the slider's point on the second body, in meters. Defaults to (0, 0, 0).
- `mSliderAxis2`: Gets or sets the slider's axis on the second body. Defaults to (1, 0, 0).
- `mNormalAxis2`: Gets or sets an axis at right angles to the slider's on the second body. Defaults to (0, 1, 0).
- `mLimitsMin`: Gets or sets the lowest position, in meters. Defaults to minus the largest float: no limit.
- `mLimitsMax`: Gets or sets the highest position, in meters. Defaults to the largest float: no limit.
- `mLimitsSpringSettings`: Gets or sets the spring at the positions' limits. Rigid by default.
- `mMaxFrictionForce`: Gets or sets the friction force that slows the slider, in newtons. Defaults to 0.
- `mMotorSettings`: Gets or sets the motor: by default with no force limit, and off until the constraint's `SetMotorState`.

## SpecifiedBroadPhaseLayerFilter

*class* in [`libs/jolt/src/helix/jolt/SpecifiedBroadPhaseLayerFilter.hx`](../src/helix/jolt/SpecifiedBroadPhaseLayerFilter.hx), `import helix.jolt.SpecifiedBroadPhaseLayerFilter;`, extends `BroadPhaseLayerFilter`

Represents one broad phase layer, the only one a query tests.

```haxe
function new(inBroadPhaseLayer:BroadPhaseLayer)
```

- `new`: Creates the filter.
  - `inBroadPhaseLayer`: The broad phase layer.

## SpecifiedObjectLayerFilter

*class* in [`libs/jolt/src/helix/jolt/SpecifiedObjectLayerFilter.hx`](../src/helix/jolt/SpecifiedObjectLayerFilter.hx), `import helix.jolt.SpecifiedObjectLayerFilter;`, extends `ObjectLayerFilter`

Represents one object layer, the only one a query tests.

```haxe
function new(inObjectLayer:Int)
```

- `new`: Creates the filter.
  - `inObjectLayer`: The object layer.

## SphereShape

*class* in [`libs/jolt/src/helix/jolt/SphereShape.hx`](../src/helix/jolt/SphereShape.hx), `import helix.jolt.SphereShape;`, extends `ConvexShape`

Represents a sphere, centered on its body.

```haxe
function new(inRadius:Float)
function GetRadius():Float
```

- `new`: Creates a sphere.
  - `inRadius`: The radius, in meters.
- `GetRadius`: Returns the radius.
  - returns: The radius, in meters.

## SpringSettings

*class* in [`libs/jolt/src/helix/jolt/SpringSettings.hx`](../src/helix/jolt/SpringSettings.hx), `import helix.jolt.SpringSettings;`

Represents a spring: how a constraint's limit or motor pulls back, soft rather than at once.

```haxe
function new()
var mMode:ESpringMode
var mFrequency:Float
var mStiffness:Float
var mDamping:Float
```

- `new`: Creates a rigid spring.
- `mMode`: Gets or sets how the strength is set. Defaults to `ESpringMode_FrequencyAndDamping`.
- `mFrequency`: Gets or sets the frequency, in hertz: 0 is rigid, at once. Defaults to 0.
- `mStiffness`: Gets or sets the stiffness, in newtons a meter, under `ESpringMode_StiffnessAndDamping`. Defaults to 0.
- `mDamping`: Gets or sets the damping: 0 swings forever, 1 settles without overshooting. Defaults to 0.

## StaticCompoundShapeSettings

*class* in [`libs/jolt/src/helix/jolt/StaticCompoundShapeSettings.hx`](../src/helix/jolt/StaticCompoundShapeSettings.hx), `import helix.jolt.StaticCompoundShapeSettings;`, extends `CompoundShapeSettings`

Represents what a static compound shape is built from: parts that don't change after the shape is built, such as a table's top and legs.

```haxe
function new()
```

- `new`: Creates the settings with no parts.

## SubShapeID

*abstract* in [`libs/jolt/src/helix/jolt/SubShapeID.hx`](../src/helix/jolt/SubShapeID.hx), `import helix.jolt.SubShapeID;`

Represents the part of a shape a query hit: a compound's child, a mesh's triangle. Holds no object, and compares by value.

```haxe
function GetValue():Int
```

- `GetValue`: Returns the id's value.
  - returns: The value.

## TaperedCapsuleShapeSettings

*class* in [`libs/jolt/src/helix/jolt/TaperedCapsuleShapeSettings.hx`](../src/helix/jolt/TaperedCapsuleShapeSettings.hx), `import helix.jolt.TaperedCapsuleShapeSettings;`, extends `ConvexShapeSettings`

Represents what a tapered capsule is built from: a capsule along y whose ends are spheres of different radii.

```haxe
function new(inHalfHeightOfTaperedCylinder:Float, inTopRadius:Float, inBottomRadius:Float)
var mHalfHeightOfTaperedCylinder:Float
var mTopRadius:Float
var mBottomRadius:Float
```

- `new`: Creates the settings.
  - `inHalfHeightOfTaperedCylinder`: Half the height between the ends' centers, in meters.
  - `inTopRadius`: The top end's radius, in meters.
  - `inBottomRadius`: The bottom end's radius, in meters.
- `mHalfHeightOfTaperedCylinder`: Gets or sets half the height between the ends' centers, in meters.
- `mTopRadius`: Gets or sets the top end's radius, in meters.
- `mBottomRadius`: Gets or sets the bottom end's radius, in meters.

## TransformedShape

*class* in [`libs/jolt/src/helix/jolt/TransformedShape.hx`](../src/helix/jolt/TransformedShape.hx), `import helix.jolt.TransformedShape;`

Represents a body's shape where the body is, returned by `BodyInterface.GetTransformedShape`, for asking about a query's hit. Read as the body was when returned.

```haxe
function new()
var mBodyID(default, null):BodyID
var mShape(default, null):Shape
function GetWorldTransform(?out:RMat44):RMat44
function GetWorldSpaceBounds(?out:AABox):AABox
function GetWorldSpaceSurfaceNormal(inSubShapeID:SubShapeID, inPosition:RVec3, ?out:Vec3):Vec3
```

- `new`: Creates an empty transformed shape, to fill with `BodyInterface.GetTransformedShape`.
- `mBodyID`: Gets the body.
- `mShape`: Gets the shape.
- `GetWorldTransform`: Returns the transform of the shape.
  - `out`: Optional. The transform to fill; a new one when omitted.
  - returns: The transform.
- `GetWorldSpaceBounds`: Returns the shape's bounds in the world.
  - `out`: Optional. The box to fill; a new one when omitted.
  - returns: The bounds.
- `GetWorldSpaceSurfaceNormal`: Returns the normal of the shape's surface at a point a query hit.
  - `inSubShapeID`: The part of the shape hit, from the query's result.
  - `inPosition`: The point, in the world, in meters.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The normal, of length 1.

## TwoBodyConstraint

*class* in [`libs/jolt/src/helix/jolt/TwoBodyConstraint.hx`](../src/helix/jolt/TwoBodyConstraint.hx), `import helix.jolt.TwoBodyConstraint;`, extends `Constraint`

Represents a constraint between two bodies. `BodyInterface.CreateConstraint` returns the kind its settings make.

```haxe
function GetBody1():BodyID
function GetBody2():BodyID
```

- `GetBody1`: Returns the first body.
  - returns: The body's id.
- `GetBody2`: Returns the second body.
  - returns: The body's id.

## TwoBodyConstraintSettings<T>

*class* in [`libs/jolt/src/helix/jolt/TwoBodyConstraintSettings.hx`](../src/helix/jolt/TwoBodyConstraintSettings.hx), `import helix.jolt.TwoBodyConstraintSettings;`, extends `ConstraintSettings`

Represents what a constraint between two bodies is made from, passed to `BodyInterface.CreateConstraint`, which returns the constraint as `T`.

```haxe
var mSpace:EConstraintSpace
```

- `mSpace`: Gets or sets the space the points and axes are in. Defaults to `EConstraintSpace_WorldSpace`.

## Vec3

*abstract* in [`libs/jolt/src/helix/jolt/Vec3.hx`](../src/helix/jolt/Vec3.hx), `import helix.jolt.Vec3;`

Represents Jolt's `Vec3`: a direction, a velocity or a size. Wraps helix-math's `Vector3`, whose fields and methods it also has, and is passed as a `Vector3` without a copy.

Jolt reads each component as a 32-bit float, so a value set here is rounded to the nearest 32-bit float as Jolt reads it.

_Note that a `Vec3` is assigned by reference. An operation accepts an optional `out` that receives the result, and makes a new `Vec3` when `out` is omitted._

```haxe
static function sZero(?out:Vec3):Vec3
static function sOne(?out:Vec3):Vec3
static function sAxisX(?out:Vec3):Vec3
static function sAxisY(?out:Vec3):Vec3
static function sAxisZ(?out:Vec3):Vec3
static function sReplicate(inValue:Float, ?out:Vec3):Vec3
function GetX():Float
function GetY():Float
function GetZ():Float
function SetX(inX:Float):Void
function SetY(inY:Float):Void
function SetZ(inZ:Float):Void
function Set(inX:Float, inY:Float, inZ:Float):Void
function Length():Float
function LengthSq():Float
function Normalized(?out:Vec3):Vec3
function Dot(inRHS:Vec3):Float
function Cross(inRHS:Vec3, ?out:Vec3):Vec3
function AddVec3(inV:Vec3, ?out:Vec3):Vec3
function SubVec3(inV:Vec3, ?out:Vec3):Vec3
function MulFloat(inV:Float, ?out:Vec3):Vec3
function IsNearZero(?inMaxDistSq:Float = 1e-12):Bool
function IsClose(inV:Vec3, ?inMaxDistSq:Float = 1e-12):Bool
```

- `sZero`: Returns (0, 0, 0).
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The vector.
- `sOne`: Returns (1, 1, 1).
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The vector.
- `sAxisX`: Returns (1, 0, 0).
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The vector.
- `sAxisY`: Returns (0, 1, 0).
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The vector.
- `sAxisZ`: Returns (0, 0, 1).
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The vector.
- `sReplicate`: Returns a vector with one value in each component.
  - `inValue`: The value.
  - `out`: Optional. The vector to fill; a new one when omitted.
  - returns: The vector.
- `GetX`: Returns the x component.
  - returns: The component.
- `GetY`: Returns the y component.
  - returns: The component.
- `GetZ`: Returns the z component.
  - returns: The component.
- `SetX`: Sets the x component.
  - `inX`: The component.
- `SetY`: Sets the y component.
  - `inY`: The component.
- `SetZ`: Sets the z component.
  - `inZ`: The component.
- `Set`: Sets the three components.
  - `inX`: The x component.
  - `inY`: The y component.
  - `inZ`: The z component.
- `Length`: Returns the vector's length.
  - returns: The length.
- `LengthSq`: Returns the square of the vector's length.
  - returns: The length squared.
- `Normalized`: Returns the vector scaled to a length of 1.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The vector.
- `Dot`: Returns the dot product with another vector.
  - `inRHS`: The other vector.
  - returns: The dot product.
- `Cross`: Returns the cross product with another vector.
  - `inRHS`: The other vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be either vector.
  - returns: The cross product.
- `AddVec3`: Returns the sum with another vector.
  - `inV`: The other vector.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be either vector.
  - returns: The sum.
- `SubVec3`: Returns the difference from another vector.
  - `inV`: The vector subtracted.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be either vector.
  - returns: The difference.
- `MulFloat`: Returns the vector multiplied by a number.
  - `inV`: The number.
  - `out`: Optional. The vector to fill; a new one when omitted. It may be this vector.
  - returns: The product.
- `IsNearZero`: Returns whether the vector is within a distance of (0, 0, 0).
  - `inMaxDistSq`: Optional. The square of the distance; defaults to 1e-12.
  - returns: True when the vector is that close.
- `IsClose`: Returns whether the vector is within a distance of another.
  - `inV`: The other vector.
  - `inMaxDistSq`: Optional. The square of the distance; defaults to 1e-12.
  - returns: True when the vectors are that close.

## VertexList

*typedef* in [`libs/jolt/src/helix/jolt/VertexList.hx`](../src/helix/jolt/VertexList.hx), `import helix.jolt.VertexList;`

Represents a mesh's vertices.

An alias of `Array<Float3>`.
