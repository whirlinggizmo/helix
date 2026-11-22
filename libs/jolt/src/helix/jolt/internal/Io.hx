package helix.jolt.internal;

/** Provides the shared areas of hj.h on each target: `f` and `i`, a call's small values (hj_io_f's floats and hj_io_i's ints), and the
	bulk buffer, a call's arrays, by its float or int index. Natively they are pointers into the program's memory. In a page they are
	views of jolt.wasm's memory, made again when the memory grows. */
#if cpp
@:cppInclude("hj.h")
#end
@:noCompletion
class Io {
	#if js
	static var buffer:js.lib.ArrayBuffer;
	static var floats:js.lib.Float32Array;
	static var ints:js.lib.Int32Array;
	static var ioF:Int;
	static var ioI:Int;

	/** Makes the views again when jolt.wasm's memory has grown, as growing detaches the old buffer. */
	static inline function views():Void {
		var current:js.lib.ArrayBuffer = js.Syntax.code("helixJolt.memory.buffer");
		if (current != buffer) {
			buffer = current;
			floats = new js.lib.Float32Array(current);
			ints = new js.lib.Int32Array(current);
			ioF = js.Syntax.code("helixJolt.hj_io_f()") >> 2;
			ioI = js.Syntax.code("helixJolt.hj_io_i()") >> 2;
		}
	}

	public static inline function f(index:Int):Float {
		views();
		return floats[ioF + index];
	}

	public static inline function setF(index:Int, value:Float):Void {
		views();
		floats[ioF + index] = value;
	}

	public static inline function i(index:Int):Int {
		views();
		return ints[ioI + index];
	}

	public static inline function setI(index:Int, value:Int):Void {
		views();
		ints[ioI + index] = value;
	}

	/** Makes the bulk buffer hold at least `bytes` and returns its first float's index, for `bulkF` and `bulkI`. */
	public static inline function bulk(bytes:Int):Int {
		var address:Int = js.Syntax.code("helixJolt.hj_bulk({0})", bytes);
		views();
		return address >> 2;
	}

	public static inline function bulkF(base:Int, index:Int):Float
		return floats[base + index];

	public static inline function setBulkF(base:Int, index:Int, value:Float):Void
		floats[base + index] = value;

	public static inline function bulkI(base:Int, index:Int):Int
		return ints[base + index];

	public static inline function setBulkI(base:Int, index:Int, value:Int):Void
		ints[base + index] = value;
	#elseif cpp
	static var floats:cpp.Pointer<cpp.Float32>;
	static var ints:cpp.Pointer<cpp.Int32>;
	static var bulkFloats:cpp.Pointer<cpp.Float32>;
	static var bulkInts:cpp.Pointer<cpp.Int32>;

	static function areas():Void {
		if (floats == null) {
			var f:cpp.RawPointer<cpp.Float32> = untyped __cpp__("hj_io_f()");
			var i:cpp.RawPointer<cpp.Int32> = untyped __cpp__("hj_io_i()");
			floats = cpp.Pointer.fromRaw(f);
			ints = cpp.Pointer.fromRaw(i);
		}
	}

	public static inline function f(index:Int):Float {
		areas();
		return floats[index];
	}

	public static inline function setF(index:Int, value:Float):Void {
		areas();
		floats[index] = value;
	}

	public static inline function i(index:Int):Int {
		areas();
		return ints[index];
	}

	public static inline function setI(index:Int, value:Int):Void {
		areas();
		ints[index] = value;
	}

	/** Makes the bulk buffer hold at least `bytes` and returns its first float's index, for `bulkF` and `bulkI`: 0, as the pointers
		are made again here. */
	public static function bulk(bytes:Int):Int {
		var f:cpp.RawPointer<cpp.Float32> = untyped __cpp__("(float *)hj_bulk({0})", bytes);
		var i:cpp.RawPointer<cpp.Int32> = untyped __cpp__("(int32_t *)hj_bulk({0})", bytes);
		bulkFloats = cpp.Pointer.fromRaw(f);
		bulkInts = cpp.Pointer.fromRaw(i);
		return 0;
	}

	public static inline function bulkF(base:Int, index:Int):Float
		return bulkFloats[base + index];

	public static inline function setBulkF(base:Int, index:Int, value:Float):Void
		bulkFloats[base + index] = value;

	public static inline function bulkI(base:Int, index:Int):Int
		return bulkInts[base + index];

	public static inline function setBulkI(base:Int, index:Int, value:Int):Void
		bulkInts[base + index] = value;
	#end

	/** Reads three floats of `f` from `index` into a vector. */
	public static function vec3(index:Int, ?out:helix.jolt.Vec3):helix.jolt.Vec3 {
		var v:helix.math.Vector3 = out == null ? new helix.math.Vector3() : out;
		return v.set(f(index), f(index + 1), f(index + 2));
	}

	/** Reads four floats of `f` from `index` into a quaternion. */
	public static function quat(index:Int, ?out:helix.jolt.Quat):helix.jolt.Quat {
		var q:helix.math.Quaternion = out == null ? new helix.math.Quaternion() : out;
		return q.set(f(index), f(index + 1), f(index + 2), f(index + 3));
	}

	/** Reads 16 floats of `f` from `index`, by columns, into a transform. */
	public static function mat44(index:Int, ?out:helix.jolt.Mat44):helix.jolt.Mat44 {
		var m:helix.math.Matrix4 = out == null ? new helix.math.Matrix4() : out;
		m.m0 = f(index);
		m.m1 = f(index + 1);
		m.m2 = f(index + 2);
		m.m3 = f(index + 3);
		m.m4 = f(index + 4);
		m.m5 = f(index + 5);
		m.m6 = f(index + 6);
		m.m7 = f(index + 7);
		m.m8 = f(index + 8);
		m.m9 = f(index + 9);
		m.m10 = f(index + 10);
		m.m11 = f(index + 11);
		m.m12 = f(index + 12);
		m.m13 = f(index + 13);
		m.m14 = f(index + 14);
		m.m15 = f(index + 15);
		return m;
	}

	/** Writes a transform into 16 floats of `f` from `index`, by columns. */
	public static function setMat44(index:Int, m:helix.math.Matrix4):Void {
		setF(index, m.m0);
		setF(index + 1, m.m1);
		setF(index + 2, m.m2);
		setF(index + 3, m.m3);
		setF(index + 4, m.m4);
		setF(index + 5, m.m5);
		setF(index + 6, m.m6);
		setF(index + 7, m.m7);
		setF(index + 8, m.m8);
		setF(index + 9, m.m9);
		setF(index + 10, m.m10);
		setF(index + 11, m.m11);
		setF(index + 12, m.m12);
		setF(index + 13, m.m13);
		setF(index + 14, m.m14);
		setF(index + 15, m.m15);
	}

	/** Reads six floats of `f` from `index`, the lowest corner then the highest, into a box. */
	public static function box(index:Int, ?out:helix.jolt.AABox):helix.jolt.AABox {
		var b = out == null ? new helix.jolt.AABox() : out;
		vec3(index, b.mMin);
		vec3(index + 3, b.mMax);
		return b;
	}

	/** Returns the bulk buffer's first `length` bytes as a UTF-8 string. */
	public static function bulkString(length:Int):String {
		var base = bulk(length);
		var bytes = haxe.io.Bytes.alloc(length);
		for (n in 0...length)
			bytes.set(n, (bulkI(base, n >> 2) >>> ((n & 3) * 8)) & 0xff);
		return bytes.toString();
	}
}
