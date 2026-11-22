package helix.jolt;

/** Represents a constraint, made by `BodyInterface.CreateConstraint` and acting once `PhysicsSystem.AddConstraint` has
	added it.

	A constraint is counted by what holds it, as a shape is: the system holds it while added, and the program holds it with `AddRef`
	and lets go with `Release`. `Jolt.destroy` frees every constraint, held or not. */
class Constraint {
	function new() {}

	/** Returns how many hold the constraint.

		@return  The count. */
	public function GetRefCount():Int {
		throw "not built yet";
	}

	/** Holds the constraint: it stays until `Release` is called as often. */
	public function AddRef():Void {
		throw "not built yet";
	}

	/** Lets go of the constraint, freeing it when nothing else holds it. */
	public function Release():Void {
		throw "not built yet";
	}

	/** Returns the constraint's family.

		@return  The family. */
	public function GetType():EConstraintType {
		throw "not built yet";
	}

	/** Returns the constraint's kind.

		@return  The kind. */
	public function GetSubType():EConstraintSubType {
		throw "not built yet";
	}

	/** Turns the constraint on or off, keeping it added.

		@param inEnabled  Whether the constraint acts. */
	public function SetEnabled(inEnabled:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the constraint is on.

		@return  True when the constraint acts. */
	public function GetEnabled():Bool {
		throw "not built yet";
	}

	/** Returns the number the program keeps with the constraint.

		@return  The number. */
	public function GetUserData():Int {
		throw "not built yet";
	}

	/** Sets the number the program keeps with the constraint.

		@param inUserData  The number. */
	public function SetUserData(inUserData:Int):Void {
		throw "not built yet";
	}
}
