package helix.math;

/** Holds a `Matrix4`'s 16 numbers in an array, which JavaScript's engines make and read fastest. `Matrix4Storage.cpp.hx` holds them
	for hxcpp. */
@:noCompletion
class Matrix4Storage {
	var values:Array<Float>;

	var n0(get, set):Float;
	var n1(get, set):Float;
	var n2(get, set):Float;
	var n3(get, set):Float;
	var n4(get, set):Float;
	var n5(get, set):Float;
	var n6(get, set):Float;
	var n7(get, set):Float;
	var n8(get, set):Float;
	var n9(get, set):Float;
	var n10(get, set):Float;
	var n11(get, set):Float;
	var n12(get, set):Float;
	var n13(get, set):Float;
	var n14(get, set):Float;
	var n15(get, set):Float;

	// Makes the 16 numbers the identity's, for the constructor of `Matrix4`. A constructor here would be a call for each new matrix on hxcpp.
	inline function start():Void
		values = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];

	inline function get_n0():Float
		return values[0];

	inline function set_n0(value:Float):Float
		return values[0] = value;

	inline function get_n1():Float
		return values[1];

	inline function set_n1(value:Float):Float
		return values[1] = value;

	inline function get_n2():Float
		return values[2];

	inline function set_n2(value:Float):Float
		return values[2] = value;

	inline function get_n3():Float
		return values[3];

	inline function set_n3(value:Float):Float
		return values[3] = value;

	inline function get_n4():Float
		return values[4];

	inline function set_n4(value:Float):Float
		return values[4] = value;

	inline function get_n5():Float
		return values[5];

	inline function set_n5(value:Float):Float
		return values[5] = value;

	inline function get_n6():Float
		return values[6];

	inline function set_n6(value:Float):Float
		return values[6] = value;

	inline function get_n7():Float
		return values[7];

	inline function set_n7(value:Float):Float
		return values[7] = value;

	inline function get_n8():Float
		return values[8];

	inline function set_n8(value:Float):Float
		return values[8] = value;

	inline function get_n9():Float
		return values[9];

	inline function set_n9(value:Float):Float
		return values[9] = value;

	inline function get_n10():Float
		return values[10];

	inline function set_n10(value:Float):Float
		return values[10] = value;

	inline function get_n11():Float
		return values[11];

	inline function set_n11(value:Float):Float
		return values[11] = value;

	inline function get_n12():Float
		return values[12];

	inline function set_n12(value:Float):Float
		return values[12] = value;

	inline function get_n13():Float
		return values[13];

	inline function set_n13(value:Float):Float
		return values[13] = value;

	inline function get_n14():Float
		return values[14];

	inline function set_n14(value:Float):Float
		return values[14] = value;

	inline function get_n15():Float
		return values[15];

	inline function set_n15(value:Float):Float
		return values[15] = value;
}
