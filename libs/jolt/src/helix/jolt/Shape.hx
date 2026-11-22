package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

/** Represents a shape, which bodies share: made directly (`BoxShape`, `SphereShape`) or by a settings object's `Create`.

	A shape is counted by what holds it. A body made from a shape holds it, and the shape is freed when the last body holding it is
	destroyed. A shape kept to make bodies later is held by the program with `AddRef`, and let go with `Release`. `Jolt.destroy` frees every shape, held or not,
	and a shape no body ever held. */
class Shape {
	@:allow(helix.jolt) var handle = -1;

	static var shapes = new Map<Int, Shape>();

	function new() {}

	/** Makes the shape the one a handle names, kept for `of`. */
	function register(handle:Int):Void {
		this.handle = handle;
		if (handle >= 0)
			shapes.set(handle, this);
	}

	/** Returns the shape a handle names: the one made for it, or one made now for a shape the module made. */
	@:allow(helix.jolt) static function of(handle:Int):Null<Shape> {
		if (handle < 0)
			return null;
		var found = shapes.get(handle);
		if (found == null) {
			found = Hj.shapeGetType(handle) == 0 ? new ConvexShape() : new Shape();
			found.register(handle);
		}
		return found;
	}

	/** Lets go of every shape, when the last world is destroyed. */
	@:allow(helix.jolt) static function forgetAll():Void {
		shapes.clear();
	}

	/** Returns how many hold the shape.

		@return  The count. */
	public function GetRefCount():Int {
		return Hj.shapeGetRefCount(handle);
	}

	/** Holds the shape: it stays until `Release` is called as often. */
	public function AddRef():Void {
		Hj.shapeAddRef(handle);
	}

	/** Lets go of the shape, freeing it when nothing else holds it. */
	public function Release():Void {
		Hj.shapeRelease(handle);
	}

	/** Returns the shape's family.

		@return  The family. */
	public function GetType():EShapeType {
		return cast Hj.shapeGetType(handle);
	}

	/** Returns the shape's kind.

		@return  The kind. */
	public function GetSubType():EShapeSubType {
		return cast Hj.shapeGetSubType(handle);
	}

	/** Returns whether only a static body may use the shape, as a mesh or a height field.

		@return  True when the shape must be static. */
	public function MustBeStatic():Bool {
		return Hj.shapeMustBeStatic(handle) != 0;
	}

	/** Returns the shape's bounds about its own center of mass.

		@param out  Optional. The box to fill; a new one when omitted.
		@return  The bounds. */
	public function GetLocalBounds(?out:AABox):AABox {
		Hj.shapeGetLocalBounds(handle);
		return Io.box(0, out);
	}

	/** Returns the shape's center of mass, from its own origin.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The center of mass, in meters. */
	public function GetCenterOfMass(?out:Vec3):Vec3 {
		Hj.shapeGetCenterOfMass(handle);
		return Io.vec3(0, out);
	}

	/** Returns the shape's volume.

		@return  The volume, in cubic meters. */
	public function GetVolume():Float {
		return Hj.shapeGetVolume(handle);
	}

	/** Returns the shape's mass and inertia from its density.

		@param out  Optional. The mass properties to fill; new ones when omitted.
		@return  The mass properties. */
	public function GetMassProperties(?out:MassProperties):MassProperties {
		Hj.shapeGetMassProperties(handle);
		var properties = out == null ? new MassProperties() : out;
		properties.mMass = Io.f(0);
		Io.mat44(1, properties.mInertia);
		return properties;
	}

	/** Returns the number a program keeps with the shape.

		@return  The number. */
	public function GetUserData():Int {
		return Hj.shapeGetUserData(handle);
	}

	/** Sets the number a program keeps with the shape.

		@param inUserData  The number. */
	public function SetUserData(inUserData:Int):Void {
		Hj.shapeSetUserData(handle, inUserData);
	}
}
