package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;
import helix.jolt.Jolt.*;

/** Represents the simulation inside a `JoltInterface`: its gravity, its bodies, its constraints and its queries. Returned by
	`JoltInterface.GetPhysicsSystem`. */
class PhysicsSystem {
	@:allow(helix.jolt) var world:Int;
	var bodyInterface:BodyInterface;
	var narrowPhaseQuery:NarrowPhaseQuery;
	var bodyLockInterface:BodyLockInterfaceNoLock;
	var contactListener:Null<ContactListener>;

	@:allow(helix.jolt) function new(world:Int) {
		this.world = world;
		bodyLockInterface = new BodyLockInterfaceNoLock(world);
		bodyInterface = new BodyInterface(world, bodyLockInterface);
		narrowPhaseQuery = new NarrowPhaseQuery(world);
	}

	/** Reads what the step recorded for the program. */
	@:allow(helix.jolt) function stepped():Void {
		if (contactListener != null)
			contactListener.stepped(world);
	}

	/** Sets the gravity every body falls by, scaled by each body's gravity factor.

		@param inGravity  The acceleration, in meters a second squared. Defaults to (0, -9.81, 0). */
	public function SetGravity(inGravity:Vec3):Void {
		Hj.worldSetGravity(world, inGravity.x, inGravity.y, inGravity.z);
	}

	/** Returns the gravity.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The acceleration, in meters a second squared. */
	public function GetGravity(?out:Vec3):Vec3 {
		Hj.worldGetGravity(world);
		return Io.vec3(0, out);
	}

	/** Returns the system's solver and sleep settings.

		@param out  Optional. The settings to fill; new ones when omitted.
		@return  A copy of the settings. */
	public function GetPhysicsSettings(?out:PhysicsSettings):PhysicsSettings {
		Hj.worldGetSettings(world);
		var settings = out == null ? new PhysicsSettings() : out;
		settings.mBaumgarte = Io.f(0);
		settings.mSpeculativeContactDistance = Io.f(1);
		settings.mPenetrationSlop = Io.f(2);
		settings.mLinearCastThreshold = Io.f(3);
		settings.mMinVelocityForRestitution = Io.f(4);
		settings.mTimeBeforeSleep = Io.f(5);
		settings.mPointVelocitySleepThreshold = Io.f(6);
		settings.mNumVelocitySteps = Io.i(0);
		settings.mNumPositionSteps = Io.i(1);
		settings.mAllowSleeping = Io.i(2) != 0;
		settings.mCheckActiveEdges = Io.i(3) != 0;
		return settings;
	}

	/** Sets the system's solver and sleep settings.

		@param inPhysicsSettings  The settings, read once. */
	public function SetPhysicsSettings(inPhysicsSettings:PhysicsSettings):Void {
		var s = inPhysicsSettings;
		Io.setF(0, s.mBaumgarte);
		Io.setF(1, s.mSpeculativeContactDistance);
		Io.setF(2, s.mPenetrationSlop);
		Io.setF(3, s.mLinearCastThreshold);
		Io.setF(4, s.mMinVelocityForRestitution);
		Io.setF(5, s.mTimeBeforeSleep);
		Io.setF(6, s.mPointVelocitySleepThreshold);
		Io.setI(0, s.mNumVelocitySteps);
		Io.setI(1, s.mNumPositionSteps);
		Io.setI(2, s.mAllowSleeping ? 1 : 0);
		Io.setI(3, s.mCheckActiveEdges ? 1 : 0);
		Hj.worldSetSettings(world);
	}

	/** Returns the number of bodies made, added or not.

		@return  The count. */
	public function GetNumBodies():Int {
		return Hj.worldNumBodies(world);
	}

	/** Returns the number of bodies awake.

		@param inBodyType  The kind of body counted.
		@return  The count. */
	public function GetNumActiveBodies(inBodyType:EBodyType):Int {
		return inBodyType == EBodyType_RigidBody ? Hj.worldNumActiveBodies(world) : 0;
	}

	/** Returns the most bodies the system holds, from `JoltSettings.mMaxBodies`.

		@return  The limit. */
	public function GetMaxBodies():Int {
		return Hj.worldMaxBodies(world);
	}

	/** Fills a list with every body made.

		@param outBodies  The list, emptied first. */
	public function GetBodies(outBodies:BodyIDVector):Void {
		outBodies.readBulk(Hj.worldGetBodies(world, 0));
	}

	/** Fills a list with every body awake, dynamic and kinematic: the bodies that moved in the last step, and the ones to read after it.

		@param inBodyType  The kind of body listed.
		@param outBodies  The list, emptied first. */
	public function GetActiveBodies(inBodyType:EBodyType, outBodies:BodyIDVector):Void {
		if (inBodyType == EBodyType_RigidBody)
			outBodies.readBulk(Hj.worldGetBodies(world, 1));
		else
			outBodies.clear();
	}

	/** Returns the bounds of every body in the system.

		@param out  Optional. The box to fill; a new one when omitted.
		@return  The bounds. */
	public function GetBounds(?out:AABox):AABox {
		Hj.worldGetBounds(world);
		return Io.box(0, out);
	}

	/** Adds a constraint, which then acts at each step.

		@param inConstraint  The constraint, made by `BodyInterface.CreateConstraint`. */
	public function AddConstraint(inConstraint:Constraint):Void {
		Hj.constraintAdd(world, inConstraint.handle);
	}

	/** Removes a constraint. The constraint is kept and may be added again.

		@param inConstraint  The constraint. */
	public function RemoveConstraint(inConstraint:Constraint):Void {
		Hj.constraintRemove(world, inConstraint.handle);
	}

	/** Sets what hears of contacts between bodies during a step, or null for none.

		@param inListener  The listener, a `ContactEventQueue`. */
	public function SetContactListener(inListener:Null<ContactListener>):Void {
		if (contactListener != null)
			contactListener.detach();
		contactListener = inListener;
		if (inListener != null)
			inListener.attach(world);
		else
			Hj.worldSetContactQueue(world, 0, 0);
	}

	/** Returns what hears of contacts between bodies.

		@return  The listener, or null if there is none. */
	public function GetContactListener():Null<ContactListener> {
		return contactListener;
	}

	/** Rebuilds the broad phase's tree for the bodies added. Called once after adding many bodies, before the first step, it makes the
		first queries and steps faster. */
	public function OptimizeBroadPhase():Void {
		Hj.worldOptimizeBroadPhase(world);
	}

	/** Returns the interface that makes bodies and reads and changes them.

		@return  The interface. */
	public function GetBodyInterface():BodyInterface {
		return bodyInterface;
	}

	/** Returns the interface that returns a `Body` by its id.

		@return  The interface. */
	public function GetBodyLockInterfaceNoLock():BodyLockInterfaceNoLock {
		return bodyLockInterface;
	}

	/** Returns the interface that answers ray casts, shape casts and overlaps against the bodies.

		@return  The interface. */
	public function GetNarrowPhaseQuery():NarrowPhaseQuery {
		return narrowPhaseQuery;
	}

	/** Returns whether two bodies touched in the last step.

		@param inBodyID1  One body.
		@param inBodyID2  The other body.
		@return  True when their shapes were in contact. */
	public function WereBodiesInContact(inBodyID1:BodyID, inBodyID2:BodyID):Bool {
		return Hj.worldWereInContact(world, inBodyID1.GetIndexAndSequenceNumber(), inBodyID2.GetIndexAndSequenceNumber()) != 0;
	}
}
