import haxe.io.Bytes;
import helix.math.Trig;

/** helix.math.Trig's results over fixed inputs, every result's 64 bits hashed: the hash must be the same under the interpreter, in JS and in
	hxcpp (helix.py test runs each). Inputs from a generator exact in doubles on every target, in four ranges, and the functions' own edges. */
class TrigBits {
	static inline var COUNT = 50000;

	static var out:Bytes;
	static var at = 0;

	// A static, not a local function: hxcpp calls a local function through Dynamic, which turns -0.0 into the integer 0.
	static function put(v:Float):Void {
		out.setDouble(at, v);
		at += 8;
	}

	static function main():Void {
		out = Bytes.alloc((COUNT * 4 * 6 + 64) * 8);
		for (range in [Math.PI, 1000., 1e6, 1e-3]) {
			var seed = 12345.;
			for (_ in 0...COUNT) {
				seed = (seed * 16807) % 2147483647;
				var a = seed / 1073741823.5 - 1;
				seed = (seed * 16807) % 2147483647;
				var b = seed / 1073741823.5 - 1;
				var x = a * range, y = b * range;
				put(Trig.sin(x));
				put(Trig.cos(x));
				put(Trig.tan(x));
				put(Trig.atan2(y, x));
				put(Trig.asin(a));
				put(Trig.acos(b));
			}
		}
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
			put(Trig.sin(x));
			put(Trig.cos(x));
			put(Trig.tan(x));
			put(Trig.atan2(x, -1));
			put(Trig.asin(x > 1 ? 1 : x));
		}
		var line = 'trig bits: ${haxe.crypto.Sha256.make(out.sub(0, at)).toHex()}';
		#if js untyped console.log(line) #else Sys.println(line) #end;
	}
}
