import helix.raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;

/** Checks raymath's optional out, and rlgl's matrix getters': a call with an out fills it and returns it, one whose out is also an
	argument answers as one without, and one without an out returns a new value. */
class RaymathTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var m = MatrixMultiply(MatrixRotateY(.7), MatrixTranslate(1, -2, 3));
		var q = QuaternionFromEuler(.3, -.5, 1.1);

		// Vector2
		var a2 = new Vector2(1, 2), b2 = new Vector2(-3, .5);
		binary("Vector2Add", (a, b, o) -> Vector2Add(a, b, o), a2, b2, copy2, same2);
		binary("Vector2Lerp", (a, b, o) -> Vector2Lerp(a, b, .25, o), a2, b2, copy2, same2);
		unary("Vector2Transform", (v, o) -> Vector2Transform(v, m, o), a2, copy2, same2);
		unary("Vector2Rotate", (v, o) -> Vector2Rotate(v, .4, o), a2, copy2, same2);
		unary("Vector2Normalize", (v, o) -> Vector2Normalize(v, o), a2, copy2, same2);
		var zero2 = new Vector2(4, 4);
		check(Vector2Zero(zero2) == zero2 && zero2.x == 0 && zero2.y == 0, "Vector2Zero: out filled and returned");

		// Vector3
		var a3 = new Vector3(1, 2, 3), b3 = new Vector3(-2, .5, 4);
		binary("Vector3CrossProduct", (a, b, o) -> Vector3CrossProduct(a, b, o), a3, b3, copy3, same3);
		binary("Vector3SubtractValue", (a, b, o) -> Vector3SubtractValue(a, b.x, o), a3, b3, copy3, same3);
		unary("Vector3Transform", (v, o) -> Vector3Transform(v, m, o), a3, copy3, same3);
		unary("Vector3RotateByQuaternion", (v, o) -> Vector3RotateByQuaternion(v, q, o), a3, copy3, same3);
		unary("Vector3Unproject", (v, o) -> Vector3Unproject(v, MatrixPerspective(1, 1.5, .1, 100), m, o), new Vector3(.2, -.3, .5), copy3, same3);

		// Vector4
		var a4 = new Vector4(1, 2, 3, 4), b4 = new Vector4(-1, .5, 2, -3);
		binary("Vector4Add", (a, b, o) -> Vector4Add(a, b, o), a4, b4, copy4, same4);
		binary("Vector4Lerp", (a, b, o) -> Vector4Lerp(a, b, .75, o), a4, b4, copy4, same4);
		unary("Vector4Normalize", (v, o) -> Vector4Normalize(v, o), a4, copy4, same4);

		// Quaternion
		var p = QuaternionFromAxisAngle(new Vector3(1, 1, 0), .9);
		binary("QuaternionMultiply", (a, b, o) -> QuaternionMultiply(a, b, o), q, p, copyQ, sameQ);
		binary("QuaternionAdd", (a, b, o) -> QuaternionAdd(a, b, o), q, p, copyQ, sameQ);
		binary("QuaternionLerp", (a, b, o) -> QuaternionLerp(a, b, .3, o), q, p, copyQ, sameQ);
		binary("QuaternionSlerp", (a, b, o) -> QuaternionSlerp(a, b, .3, o), q, p, copyQ, sameQ);
		unary("QuaternionTransform", (v, o) -> QuaternionTransform(v, m, o), q, copyQ, sameQ);
		unary("QuaternionInvert", (v, o) -> QuaternionInvert(v, o), q, copyQ, sameQ);
		var identity = new Quaternion(1, 2, 3, 4);
		check(QuaternionIdentity(identity) == identity
			&& sameQ(identity, new Quaternion()), "QuaternionIdentity: out filled and returned");
		var fromMatrix = new Quaternion();
		check(QuaternionFromMatrix(m, fromMatrix) == fromMatrix
			&& sameQ(fromMatrix, QuaternionFromMatrix(m)), "QuaternionFromMatrix: out filled");

		// Matrix
		var n = MatrixMultiply(MatrixScale(2, 3, 4), MatrixRotateX(-.4));
		binary("MatrixMultiply", (a, b, o) -> MatrixMultiply(a, b, o), m, n, copyM, sameM);
		binary("MatrixSubtract", (a, b, o) -> MatrixSubtract(a, b, o), m, n, copyM, sameM);
		unary("MatrixInvert", (v, o) -> MatrixInvert(v, o), m, copyM, sameM);
		unary("MatrixTranspose", (v, o) -> MatrixTranspose(v, o), m, copyM, sameM);
		var singular = MatrixScale(1, 0, 1), inverted = MatrixIdentity();
		check(MatrixInvert(singular, inverted) == inverted && Math.isNaN(inverted.m0) && Math.isNaN(inverted.m15),
			"MatrixInvert: a matrix without an inverse fills out with NaN");
		check(MatrixInvert(singular, singular) == singular && Math.isNaN(singular.m5), "MatrixInvert: NaN into the matrix itself");
		var made = copyM(m);
		check(MatrixIdentity(made) == made && sameM(made, MatrixIdentity()), "MatrixIdentity: out filled and returned");
		made = copyM(m);
		check(QuaternionToMatrix(q, made) == made && sameM(made, QuaternionToMatrix(q)), "QuaternionToMatrix: out filled and returned");
		made = copyM(m);
		var eye = new Vector3(1, 2, 3),
			target = new Vector3(0, 0, 0),
			up = new Vector3(0, 1, 0);
		check(MatrixLookAt(eye, target, up, made) == made
			&& sameM(made, MatrixLookAt(eye, target, up)), "MatrixLookAt: out filled and returned");

		// Array<Float>
		var long = [9., 9, 9, 9, 9];
		check(Vector3ToFloatV(a3, long) == long && long.length == 3 && long[0] == 1 && long[2] == 3, "Vector3ToFloatV: out resized and filled");
		var short = [9.];
		check(Vector3ToFloat(a3, short) == short && short.length == 3 && short[1] == 2, "Vector3ToFloat: out resized and filled");
		var array = [9., 9];
		check(MatrixToFloatV(m, array) == array && array.length == 16 && array[12] == m.m12 && array[15] == m.m15, "MatrixToFloatV: out resized and filled");
		array = [for (_ in 0...20) 9.];
		check(MatrixToFloat(m, array) == array && array.length == 16 && array[0] == m.m0, "MatrixToFloat: out resized and filled");
		var fresh = MatrixToFloatV(m);
		check(fresh != array && fresh.length == 16 && fresh[13] == m.m13, "MatrixToFloatV: a new array without out");

		// rlgl's matrix getters that need no window
		made = copyM(m);
		check(rlGetMatrixTransform(made) == made && sameM(made, MatrixIdentity()) && rlGetMatrixTransform() != made,
			"rlGetMatrixTransform: out filled with the identity when none is pushed");
		made = copyM(m);
		check(rlGetMatrixProjectionStereo(2, made) == made
			&& sameM(made, new Matrix()), "rlGetMatrixProjectionStereo: out zeroed for eye 2");
		made = copyM(m);
		check(rlGetMatrixViewOffsetStereo(0, made) == made
			&& sameM(made, rlGetMatrixViewOffsetStereo(0)), "rlGetMatrixViewOffsetStereo: out filled");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// A call of two values of its type: without out it returns a new one, with one it fills it, and with either argument as the out it
	// answers the same.
	static function binary<T>(name:String, call:(T, T, Null<T>) -> T, a:T, b:T, copy:T->T, same:(T, T) -> Bool):Void {
		var fresh = call(a, b, null);
		check(fresh != a && fresh != b, '$name: a new value without out');
		var out = copy(b);
		check(call(a, b, out) == out && same(out, fresh), '$name: out filled and returned');
		var first = copy(a);
		check(call(first, b, first) == first && same(first, fresh), '$name: out as its first argument');
		var second = copy(b);
		check(call(a, second, second) == second && same(second, fresh), '$name: out as its second argument');
	}

	// A call of one value of its type, checked as binary checks a call of two.
	static function unary<T>(name:String, call:(T, Null<T>) -> T, a:T, copy:T->T, same:(T, T) -> Bool):Void {
		var fresh = call(a, null);
		check(fresh != a, '$name: a new value without out');
		var out = copy(a);
		var filled = call(a, out);
		check(filled == out && same(out, fresh), '$name: out filled and returned');
		var first = copy(a);
		check(call(first, first) == first && same(first, fresh), '$name: out as its argument');
	}

	static function copy2(v:Vector2):Vector2
		return new Vector2(v.x, v.y);

	static function same2(a:Vector2, b:Vector2):Bool
		return a.x == b.x && a.y == b.y;

	static function copy3(v:Vector3):Vector3
		return new Vector3(v.x, v.y, v.z);

	static function same3(a:Vector3, b:Vector3):Bool
		return a.x == b.x && a.y == b.y && a.z == b.z;

	static function copy4(v:Vector4):Vector4
		return new Vector4(v.x, v.y, v.z, v.w);

	static function same4(a:Vector4, b:Vector4):Bool
		return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;

	static function copyQ(v:Quaternion):Quaternion
		return new Quaternion(v.x, v.y, v.z, v.w);

	static function sameQ(a:Quaternion, b:Quaternion):Bool
		return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;

	static function copyM(v:Matrix):Matrix
		return v.copy();

	static function sameM(a:Matrix, b:Matrix):Bool {
		var x = a.toArray(), y = b.toArray();
		for (i in 0...16)
			if (x[i] != y[i])
				return false;
		return true;
	}
}
