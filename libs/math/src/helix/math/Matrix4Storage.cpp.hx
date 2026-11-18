package helix.math;

/** Holds a `Matrix4`'s 16 numbers as 16 fields, which hxcpp makes as one object and reads without a bounds check.
	`Matrix4Storage.hx` holds them for the other targets. */
@:noCompletion
class Matrix4Storage {
	var n0:Float;
	var n1:Float;
	var n2:Float;
	var n3:Float;
	var n4:Float;
	var n5:Float;
	var n6:Float;
	var n7:Float;
	var n8:Float;
	var n9:Float;
	var n10:Float;
	var n11:Float;
	var n12:Float;
	var n13:Float;
	var n14:Float;
	var n15:Float;

	// Makes the 16 numbers the identity's, for the constructor of `Matrix4`: each starts at 0. A constructor here would be a call for
	// each new matrix.
	inline function start():Void {
		n0 = 1;
		n5 = 1;
		n10 = 1;
		n15 = 1;
	}
}
