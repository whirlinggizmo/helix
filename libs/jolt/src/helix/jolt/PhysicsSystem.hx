package helix.jolt;

/** Represents the simulation inside a `JoltInterface`: its gravity, its bodies, its constraints and its queries. Returned by
	`JoltInterface.GetPhysicsSystem`. */
class PhysicsSystem {
	function new() {}

	/** Sets the gravity every body falls by, scaled by each body's gravity factor.

		@param inGravity  The acceleration, in meters a second squared. Defaults to (0, -9.81, 0). */
	public function SetGravity(inGravity:Vec3):Void {
		throw "not built yet";
	}

	/** Returns the gravity.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The acceleration, in meters a second squared. */
	public function GetGravity(?out:Vec3):Vec3 {
		throw "not built yet";
	}

	/** Returns the system's solver and sleep settings.

		@param out  Optional. The settings to fill; new ones when omitted.
		@return  A copy of the settings. */
	public function GetPhysicsSettings(?out:PhysicsSettings):PhysicsSettings {
		throw "not built yet";
	}

	/** Sets the system's solver and sleep settings.

		@param inPhysicsSettings  The settings, read once. */
	public function SetPhysicsSettings(inPhysicsSettings:PhysicsSettings):Void {
		throw "not built yet";
	}

	/** Returns the number of bodies made, added or not.

		@return  The count. */
	public function GetNumBodies():Int {
		throw "not built yet";
	}

	/** Returns the number of bodies awake.

		@param inBodyType  The kind of body counted.
		@return  The count. */
	public function GetNumActiveBodies(inBodyType:EBodyType):Int {
		throw "not built yet";
	}

	/** Returns the most bodies the system holds, from `JoltSettings.mMaxBodies`.

		@return  The limit. */
	public function GetMaxBodies():Int {
		throw "not built yet";
	}

	/** Fills a list with every body made.

		@param outBodies  The list, emptied first. */
	public function GetBodies(outBodies:BodyIDVector):Void {
		throw "not built yet";
	}

	/** Fills a list with every body awake, dynamic and kinematic: the bodies that moved in the last step, and the ones to read after it.

		@param inBodyType  The kind of body listed.
		@param outBodies  The list, emptied first. */
	public function GetActiveBodies(inBodyType:EBodyType, outBodies:BodyIDVector):Void {
		throw "not built yet";
	}

	/** Returns the bounds of every body in the system.

		@param out  Optional. The box to fill; a new one when omitted.
		@return  The bounds. */
	public function GetBounds(?out:AABox):AABox {
		throw "not built yet";
	}

	/** Adds a constraint, which then acts at each step.

		@param inConstraint  The constraint, made by `BodyInterface.CreateConstraint`. */
	public function AddConstraint(inConstraint:Constraint):Void {
		throw "not built yet";
	}

	/** Removes a constraint. The constraint is kept and may be added again.

		@param inConstraint  The constraint. */
	public function RemoveConstraint(inConstraint:Constraint):Void {
		throw "not built yet";
	}

	/** Sets what hears of contacts between bodies during a step, or null for none.

		@param inListener  The listener, a `ContactEventQueue`. */
	public function SetContactListener(inListener:Null<ContactListener>):Void {
		throw "not built yet";
	}

	/** Returns what hears of contacts between bodies.

		@return  The listener, or null if there is none. */
	public function GetContactListener():Null<ContactListener> {
		throw "not built yet";
	}

	/** Rebuilds the broad phase's tree for the bodies added. Called once after adding many bodies, before the first step, it makes the
		first queries and steps faster. */
	public function OptimizeBroadPhase():Void {
		throw "not built yet";
	}

	/** Returns the interface that makes bodies and reads and changes them.

		@return  The interface. */
	public function GetBodyInterface():BodyInterface {
		throw "not built yet";
	}

	/** Returns the interface that returns a `Body` by its id.

		@return  The interface. */
	public function GetBodyLockInterfaceNoLock():BodyLockInterfaceNoLock {
		throw "not built yet";
	}

	/** Returns the interface that answers ray casts, shape casts and overlaps against the bodies.

		@return  The interface. */
	public function GetNarrowPhaseQuery():NarrowPhaseQuery {
		throw "not built yet";
	}

	/** Returns whether two bodies touched in the last step.

		@param inBodyID1  One body.
		@param inBodyID2  The other body.
		@return  True when their shapes were in contact. */
	public function WereBodiesInContact(inBodyID1:BodyID, inBodyID2:BodyID):Bool {
		throw "not built yet";
	}
}
