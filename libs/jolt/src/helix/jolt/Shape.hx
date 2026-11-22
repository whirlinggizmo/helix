package helix.jolt;

/** Represents a shape, which bodies share: made directly (`BoxShape`, `SphereShape`) or by a settings object's `Create`.

	A shape is counted by what holds it. A body made from a shape holds it, and the shape is freed when the last body holding it is
	destroyed. A shape kept to make bodies later is held by the program with `AddRef`, and let go with `Release`. `Jolt.destroy` frees every shape, held or not,
	and a shape no body ever held. */
class Shape {
	function new() {}

	/** Returns how many hold the shape.

		@return  The count. */
	public function GetRefCount():Int {
		throw "not built yet";
	}

	/** Holds the shape: it stays until `Release` is called as often. */
	public function AddRef():Void {
		throw "not built yet";
	}

	/** Lets go of the shape, freeing it when nothing else holds it. */
	public function Release():Void {
		throw "not built yet";
	}

	/** Returns the shape's family.

		@return  The family. */
	public function GetType():EShapeType {
		throw "not built yet";
	}

	/** Returns the shape's kind.

		@return  The kind. */
	public function GetSubType():EShapeSubType {
		throw "not built yet";
	}

	/** Returns whether only a static body may use the shape, as a mesh or a height field.

		@return  True when the shape must be static. */
	public function MustBeStatic():Bool {
		throw "not built yet";
	}

	/** Returns the shape's bounds about its own center of mass.

		@param out  Optional. The box to fill; a new one when omitted.
		@return  The bounds. */
	public function GetLocalBounds(?out:AABox):AABox {
		throw "not built yet";
	}

	/** Returns the shape's center of mass, from its own origin.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The center of mass, in meters. */
	public function GetCenterOfMass(?out:Vec3):Vec3 {
		throw "not built yet";
	}

	/** Returns the shape's volume.

		@return  The volume, in cubic meters. */
	public function GetVolume():Float {
		throw "not built yet";
	}

	/** Returns the shape's mass and inertia from its density.

		@param out  Optional. The mass properties to fill; new ones when omitted.
		@return  The mass properties. */
	public function GetMassProperties(?out:MassProperties):MassProperties {
		throw "not built yet";
	}

	/** Returns the number a program keeps with the shape.

		@return  The number. */
	public function GetUserData():Int {
		throw "not built yet";
	}

	/** Sets the number a program keeps with the shape.

		@param inUserData  The number. */
	public function SetUserData(inUserData:Int):Void {
		throw "not built yet";
	}
}
