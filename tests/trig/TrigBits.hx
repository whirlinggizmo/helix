import haxe.io.Bytes;
import helix.math.Trig;

/** A run of doubles hashed on its own. */
typedef Part = {name:String, bytes:Bytes, at:Int};

/** helix.math.Trig's results over fixed inputs, every result's 64 bits hashed: the hash must be the same under the interpreter, in JS and in
	hxcpp (helix.py test runs each). Inputs from a generator exact in doubles on every target, in four ranges and two
	past the three-part reduction (fewer: the interpreter is slow there), and the functions' own edges.
	Each part (the inputs, each function in each range, the edges) is hashed too, so a difference between targets or machines can be placed. */
class TrigBits {
	static inline var COUNT = 50000;
	static inline var LARGE_COUNT = 5000;

	static var all:Bytes;
	static var at = 0;
	static var parts:Array<Part> = [];

	// Statics, not local functions: hxcpp calls a local function through Dynamic, which turns -0.0 into the integer 0.

	/** A new part, size doubles long. */
	static function part(name:String, size:Int):Part {
		var p = {name: name, bytes: Bytes.alloc(size * 8), at: 0};
		parts.push(p);
		return p;
	}

	/** Appends v to the part only. */
	static function note(p:Part, v:Float):Void {
		write(p.bytes, p.at, v);
		p.at += 8;
	}

	/** v's bits at `at`, every NaN as one: a NaN's sign and payload aren't promised (an x86 makes negative ones, an arm64 positive ones). */
	static function write(bytes:Bytes, at:Int, v:Float):Void {
		if (Math.isNaN(v)) {
			bytes.setInt32(at, 0);
			bytes.setInt32(at + 4, 0x7FF80000);
		} else
			bytes.setDouble(at, v);
	}

	/** Appends v to the whole and to the part. */
	static function put(p:Part, v:Float):Void {
		write(all, at, v);
		at += 8;
		note(p, v);
	}

	static function main():Void {
		var names = ['pi', '1e3', '1e6', '1e-3', '1e12', '1e300'];
		var ranges = [Math.PI, 1000., 1e6, 1e-3, 1e12, 1e300];
		var counts = [COUNT, COUNT, COUNT, COUNT, LARGE_COUNT, LARGE_COUNT];
		all = Bytes.alloc(((COUNT * 4 + LARGE_COUNT * 2) * 6 + 64) * 8);
		for (r in 0...ranges.length) {
			var range = ranges[r], name = names[r], count = counts[r];
			var inputs = part('$name inputs', count * 4),
				sin = part('$name sin', count),
				cos = part('$name cos', count),
				tan = part('$name tan', count),
				atan2 = part('$name atan2', count),
				asin = part('$name asin', count),
				acos = part('$name acos', count);
			var seed = 12345.;
			for (_ in 0...count) {
				seed = (seed * 16807) % 2147483647;
				var a = seed / 1073741823.5 - 1;
				seed = (seed * 16807) % 2147483647;
				var b = seed / 1073741823.5 - 1;
				var x = a * range, y = b * range;
				note(inputs, a);
				note(inputs, b);
				note(inputs, x);
				note(inputs, y);
				put(sin, Trig.sin(x));
				put(cos, Trig.cos(x));
				put(tan, Trig.tan(x));
				put(atan2, Trig.atan2(y, x));
				put(asin, Trig.asin(a));
				put(acos, Trig.acos(b));
			}
		}
		// Each edge is its own part, named by its input's bits: the compiler reads these literals and folds the products itself.
		for (x in [
			0.,
			-0.,
			1.,
			-1.,
			Math.PI / 2,
			Math.PI,
			2 * Math.PI,
			1e-300,
			1e300,
			0.5,
			0.41421356237309504880,
			2.41421356237309504880
		]) {
			var bits = haxe.io.FPHelper.doubleToI64(x);
			var edges = part('edge ${StringTools.hex(bits.high, 8)}${StringTools.hex(bits.low, 8)}', 5);
			put(edges, Trig.sin(x));
			put(edges, Trig.cos(x));
			put(edges, Trig.tan(x));
			put(edges, Trig.atan2(x, -1));
			put(edges, Trig.asin(x > 1 ? 1 : x));
		}
		var lines = ['trig bits: ${haxe.crypto.Sha256.make(all.sub(0, at)).toHex()}'];
		for (p in parts)
			lines.push('trig part ${p.name}: ${haxe.crypto.Sha256.make(p.bytes.sub(0, p.at)).toHex().substr(0, 16)}');
		for (line in lines)
			#if js untyped console.log(line) #else Sys.println(line) #end;
	}
}
