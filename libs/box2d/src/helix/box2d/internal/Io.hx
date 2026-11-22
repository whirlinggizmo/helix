package helix.box2d.internal;

/** Provides hb_io.h's two buffers on each target: the call buffer, a call's structs, arrays and strings, and the callback buffer, a
	callback's. A read or a write goes to the buffer the last `begin` named, from its first word. Natively the buffers are the
	program's memory. In a page they are views of box2d.wasm's memory, made again when the memory grows. */
#if cpp
@:cppInclude("hb.h")
#end
@:noCompletion
class Io {
	static var back = false;
	static var base = 0;
	static var capacity = 0;
	static var position = 0;

	#if js
	static var buffer:js.lib.ArrayBuffer;
	static var floats:js.lib.Float32Array;
	static var ints:js.lib.Int32Array;

	/** Points at the named buffer's words, making the views again when box2d.wasm's memory has grown. */
	static function locate():Void {
		var address:Int = back ? js.Syntax.code("helixBox2d.hb_back_words()") : js.Syntax.code("helixBox2d.hb_call_words()");
		capacity = back ? js.Syntax.code("helixBox2d.hb_back_capacity()") : js.Syntax.code("helixBox2d.hb_call_capacity()");
		var current:js.lib.ArrayBuffer = js.Syntax.code("helixBox2d.memory.buffer");
		if (current != buffer) {
			buffer = current;
			floats = new js.lib.Float32Array(current);
			ints = new js.lib.Int32Array(current);
		}
		base = address >> 2;
	}

	static function grow():Void {
		if (back)
			js.Syntax.code("helixBox2d.hb_back_reserve({0})", capacity * 2);
		else
			js.Syntax.code("helixBox2d.hb_call_reserve({0})", capacity * 2);
		locate();
	}

	public static inline function wf(v:Float):Void {
		if (position >= capacity)
			grow();
		floats[base + position++] = v;
	}

	public static inline function wi(v:Int):Void {
		if (position >= capacity)
			grow();
		ints[base + position++] = v;
	}

	public static inline function rf():Float
		return floats[base + position++];

	public static inline function ri():Int
		return ints[base + position++];
	#elseif cpp
	static var floats:cpp.Pointer<cpp.Float32>;
	static var ints:cpp.Pointer<cpp.Int32>;

	/** Points at the named buffer's words. */
	static function locate():Void {
		var f:cpp.RawPointer<cpp.Float32> = back ? untyped __cpp__("(float *)hb_back_words()") : untyped __cpp__("(float *)hb_call_words()");
		var i:cpp.RawPointer<cpp.Int32> = back ? untyped __cpp__("(int *)hb_back_words()") : untyped __cpp__("(int *)hb_call_words()");
		capacity = back ? untyped __cpp__("hb_back_capacity()") : untyped __cpp__("hb_call_capacity()");
		floats = cpp.Pointer.fromRaw(f);
		ints = cpp.Pointer.fromRaw(i);
	}

	static function grow():Void {
		if (back)
			untyped __cpp__("hb_back_reserve({0})", capacity * 2);
		else
			untyped __cpp__("hb_call_reserve({0})", capacity * 2);
		locate();
	}

	public static inline function wf(v:Float):Void {
		if (position >= capacity)
			grow();
		floats[position++] = v;
	}

	public static inline function wi(v:Int):Void {
		if (position >= capacity)
			grow();
		ints[position++] = v;
	}

	public static inline function rf():Float
		return floats[position++];

	public static inline function ri():Int
		return ints[position++];
	#end

	/** Starts a call's writes or reads, from the call buffer's first word. */
	public static inline function begin():Void {
		back = false;
		position = 0;
		locate();
	}

	/** Starts a callback's reads or writes, from the callback buffer's first word. */
	public static inline function beginBack():Void {
		back = true;
		position = 0;
		locate();
	}

	public static inline function wb(v:Bool):Void
		wi(v ? 1 : 0);

	public static inline function rb():Bool
		return ri() != 0;

	public static inline function wl(v:haxe.Int64):Void {
		wi(v.low);
		wi(v.high);
	}

	public static inline function rl():haxe.Int64 {
		var low = ri();
		return haxe.Int64.make(ri(), low);
	}

	public static inline function wv(v:helix.box2d.B2Vec2):Void {
		wf(v.x);
		wf(v.y);
	}

	public static inline function rv(v:helix.box2d.B2Vec2):helix.box2d.B2Vec2 {
		v.x = rf();
		v.y = rf();
		return v;
	}

	/** Writes a string as hb_rs reads it: its length in bytes, -1 for null, then its bytes four to a word. */
	public static function ws(s:String):Void {
		if (s == null) {
			wi(-1);
			return;
		}
		var bytes = haxe.io.Bytes.ofString(s);
		wbytes(bytes, bytes.length, true);
	}

	public static function rs():String {
		var length = ri();
		if (length < 0)
			return null;
		var bytes = haxe.io.Bytes.alloc(length);
		rbytes(bytes, length);
		return bytes.toString();
	}

	/** Writes `count` bytes four to a word, after their count when `counted`. */
	public static function wbytes(bytes:haxe.io.Bytes, count:Int, counted = false):Void {
		if (counted)
			wi(count);
		var n = 0;
		while (n < count) {
			var word = 0;
			for (k in 0...4)
				if (n + k < count)
					word |= bytes.get(n + k) << (k * 8);
			wi(word);
			n += 4;
		}
	}

	/** Reads `count` bytes, four to a word, into `bytes` from its first. */
	public static function rbytes(bytes:haxe.io.Bytes, count:Int):Void {
		var n = 0;
		while (n < count) {
			var word = ri();
			for (k in 0...4)
				if (n + k < count)
					bytes.set(n + k, (word >>> (k * 8)) & 0xff);
			n += 4;
		}
	}
}
