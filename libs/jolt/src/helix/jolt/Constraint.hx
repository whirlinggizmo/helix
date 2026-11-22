package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;
import helix.jolt.Jolt.*;

/** Represents a constraint, made by `BodyInterface.CreateConstraint` and acting once `PhysicsSystem.AddConstraint` has
	added it.

	A constraint is counted by what holds it, as a shape is: the system holds it while added, and the program holds it with `AddRef`
	and lets go with `Release`. `Jolt.destroy` frees every constraint, held or not. */
class Constraint {
	@:allow(helix.jolt) var world:Int;
	@:allow(helix.jolt) var handle:Int;
	var motors:Array<MotorSettings> = [];
	var motorAxes:Array<Int> = [];

	static var watched = new Map<Int, Array<Constraint>>();

	@:allow(helix.jolt) function new(world:Int, handle:Int) {
		this.world = world;
		this.handle = handle;
	}

	/** Returns the motor settings of an axis (-1 for a hinge's or slider's), kept and written to the module before each step, so a
		change made in place applies at the next step. */
	function motor(axis:Int):MotorSettings {
		var index = motorAxes.indexOf(axis);
		if (index >= 0)
			return motors[index];
		Hj.constraintGetMotor(world, handle, axis);
		var motor = new MotorSettings();
		motor.mSpringSettings.mMode = cast Io.i(0);
		motor.mSpringSettings.mFrequency = Io.f(0);
		motor.mSpringSettings.mStiffness = Io.f(1);
		motor.mSpringSettings.mDamping = Io.f(2);
		motor.mMinForceLimit = Io.f(3);
		motor.mMaxForceLimit = Io.f(4);
		motor.mMinTorqueLimit = Io.f(5);
		motor.mMaxTorqueLimit = Io.f(6);
		motors.push(motor);
		motorAxes.push(axis);
		var list = watched.get(world);
		if (list == null)
			watched.set(world, list = []);
		if (list.indexOf(this) < 0)
			list.push(this);
		return motor;
	}

	/** Writes every motor setting handed out in a world to the module, before a step. */
	@:allow(helix.jolt) static function writeMotors(world:Int):Void {
		var list = watched.get(world);
		if (list == null)
			return;
		for (constraint in list)
			for (n in 0...constraint.motors.length) {
				var m = constraint.motors[n];
				Io.setI(0, cast m.mSpringSettings.mMode);
				Io.setF(0, m.mSpringSettings.mFrequency);
				Io.setF(1, m.mSpringSettings.mStiffness);
				Io.setF(2, m.mSpringSettings.mDamping);
				Io.setF(3, m.mMinForceLimit);
				Io.setF(4, m.mMaxForceLimit);
				Io.setF(5, m.mMinTorqueLimit);
				Io.setF(6, m.mMaxTorqueLimit);
				Hj.constraintSetMotor(constraint.world, constraint.handle, constraint.motorAxes[n]);
			}
	}

	/** Forgets a world's constraints, when it is destroyed. */
	@:allow(helix.jolt) static function forgetWorld(world:Int):Void {
		watched.remove(world);
	}

	/** Returns how many hold the constraint.

		@return  The count. */
	public function GetRefCount():Int {
		return Hj.constraintGetRefCount(world, handle);
	}

	/** Holds the constraint: it stays until `Release` is called as often. */
	public function AddRef():Void {
		Hj.constraintAddRef(world, handle);
	}

	/** Lets go of the constraint, freeing it when nothing else holds it. */
	public function Release():Void {
		Hj.constraintRelease(world, handle);
	}

	/** Returns the constraint's family.

		@return  The family. */
	public function GetType():EConstraintType {
		return EConstraintType_TwoBodyConstraint;
	}

	/** Returns the constraint's kind.

		@return  The kind. */
	public function GetSubType():EConstraintSubType {
		return cast Hj.constraintGetSubType(world, handle);
	}

	/** Turns the constraint on or off, keeping it added.

		@param inEnabled  Whether the constraint acts. */
	public function SetEnabled(inEnabled:Bool):Void {
		Hj.constraintSetEnabled(world, handle, inEnabled ? 1 : 0);
	}

	/** Returns whether the constraint is on.

		@return  True when the constraint acts. */
	public function GetEnabled():Bool {
		return Hj.constraintGetEnabled(world, handle) != 0;
	}

	/** Returns the number the program keeps with the constraint.

		@return  The number. */
	public function GetUserData():Int {
		return Hj.constraintGetUserData(world, handle);
	}

	/** Sets the number the program keeps with the constraint.

		@param inUserData  The number. */
	public function SetUserData(inUserData:Int):Void {
		Hj.constraintSetUserData(world, handle, inUserData);
	}
}
