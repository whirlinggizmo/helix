package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.raylib.RCore.*;
import helix.ray.raylib.RShapes.*;
import helix.ray.raylib.RTextures.*;
import helix.ray.raylib.RText.*;
import helix.ray.raylib.RModels.*;
import helix.ray.raylib.RAudio.*;
import helix.ray.raylib.RMath.*;
import helix.ray.raylib.HelixRay.*;
#end

/** Holds raylib's rtext (text in the default font), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RText {
	#if !macro
	// ---- Text ----

	/** Draws text in raylib's default font. A size under 10 is drawn at 10, and letters are a tenth of the size apart.

		@param text  The text; "\n" starts a line.
		@param posX  The left edge.
		@param posY  The top edge.
		@param fontSize  The height of a line, in pixels.
		@param color  The color. */
	static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void {
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		var spacing = Std.int(fontSize / DefaultFont.HEIGHT),
			scale = fontSize / DefaultFont.HEIGHT;
		var font = defaultFont();
		var x = 0., y = 0.;
		for (code in new haxe.iterators.StringIteratorUnicode(text)) {
			if (code == "\n".code) {
				y += fontSize + 2;
				x = 0;
				continue;
			}
			var index = glyph(code);
			var w = DefaultFont.WIDTHS[index];
			if (code != " ".code && code != "\t".code) {
				var gx = fontRecs[index * 2], gy = fontRecs[index * 2 + 1];
				DrawTexturePro(font, new Rectangle(gx, gy, w, DefaultFont.HEIGHT), new Rectangle(posX + x, posY + y, w * scale, fontSize), new Vector2(), 0,
					color);
			}
			x += w * scale + spacing;
		}
	}

	/** Returns the width text is drawn at by `DrawText`, its widest line's.

		@param text  The text.
		@param fontSize  The height of a line, in pixels.
		@return  The width, in pixels. */
	static function MeasureText(text:String, fontSize:Int):Int {
		if (text.length == 0)
			return 0;
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		var spacing = Std.int(fontSize / DefaultFont.HEIGHT),
			scale = fontSize / DefaultFont.HEIGHT;
		var width = 0., widest = 0., count = 0, most = 0;
		for (code in new haxe.iterators.StringIteratorUnicode(text)) {
			count++;
			if (code == "\n".code) {
				if (width > widest)
					widest = width;
				width = 0;
				count = 0;
			} else
				width += DefaultFont.WIDTHS[glyph(code)];
			if (count > most)
				most = count;
		}
		if (width > widest)
			widest = width;
		return Std.int(widest * scale + (most - 1) * spacing);
	}

	/** Draws the frames a second, as "60 FPS", in green.

		@param posX  The left edge.
		@param posY  The top edge. */
	static function DrawFPS(posX:Int, posY:Int):Void {
		var fps = GetFPS();
		var color = fps < 15 ? RED : fps < 30 ? ORANGE : LIME;
		DrawText('${fps < 10 ? " " : ""}$fps FPS', posX, posY, 20, color);
	}

	// ---- Text strings ----

	/** Formats text as C's `printf` does. It takes `%d` and `%i`, `%u`, `%f` and `%F` (6 places unless a precision is given, as in
		`%.2f`), `%e`, `%g`, `%x`, `%X`, `%o`, `%c` (a character code), `%s` and `%%`. It also takes C's flags (`-`, `0`, `+`, space,
		`#`), widths and precisions, as in `%5d`, `%-8s`, `%03i` and `%*d`. C's length modifiers (`l`, `ll`, `h`, `z`) are read and
		ignored.

		@param text  The format.
		@param args  The values, one for each conversion.
		@return  The text. */
	static function TextFormat(text:String, args:haxe.extern.Rest<Dynamic>):String {
		var out = new StringBuf();
		var next = 0;
		var i = 0;
		function take():Dynamic
			return next < args.length ? args[next++] : null;
		function digits():Int {
			var n = 0;
			while (i < text.length && text.charCodeAt(i) >= "0".code && text.charCodeAt(i) <= "9".code)
				n = n * 10 + text.charCodeAt(i++) - "0".code;
			return n;
		}
		while (i < text.length) {
			var c = text.charAt(i++);
			if (c != "%") {
				out.add(c);
				continue;
			}
			var flags = "";
			while (i < text.length && "-0+ #".indexOf(text.charAt(i)) >= 0)
				flags += text.charAt(i++);
			var width = 0;
			if (text.charAt(i) == "*") {
				i++;
				width = Std.int(number(take()));
				if (width < 0) {
					flags += "-";
					width = -width;
				}
			} else
				width = digits();
			var precision = -1;
			if (text.charAt(i) == ".") {
				i++;
				if (text.charAt(i) == "*") {
					i++;
					precision = Std.int(number(take()));
				} else
					precision = digits();
			}
			while (i < text.length && "hlLqjzt".indexOf(text.charAt(i)) >= 0)
				i++;
			if (i >= text.length)
				break;
			var conversion = text.charAt(i++);
			if (conversion == "%") {
				out.add("%");
				continue;
			}
			out.add(formatted(conversion, take(), flags, width, precision));
		}
		return out.toString();
	}

	// One conversion of TextFormat's, padded to its width.
	static function formatted(conversion:String, value:Dynamic, flags:String, width:Int, precision:Int):String {
		var sign = "", body = "", numeric = true;
		var v = number(value);
		switch conversion {
			case "d" | "i":
				var whole = Std.int(v);
				sign = whole < 0 ? "-" : flags.indexOf("+") >= 0 ? "+" : flags.indexOf(" ") >= 0 ? " " : "";
				body = wholeDigits(Math.abs(whole));
				while (body.length < precision)
					body = "0" + body;
			case "u":
				var whole:Float = Std.int(v);
				body = wholeDigits(whole < 0 ? whole + 4294967296.0 : whole);
			case "x" | "X" | "o":
				var whole = Std.int(v);
				if (conversion == "o") {
					body = whole == 0 ? "0" : "";
					while (whole != 0) {
						body = (whole & 7) + body;
						whole = whole >>> 3;
					}
				} else {
					body = StringTools.hex(whole);
					if (whole < 0)
						body = body.substr(body.length - 8);
					if (conversion == "x")
						body = body.toLowerCase();
				}
				while (body.length < precision)
					body = "0" + body;
				if (flags.indexOf("#") >= 0 && Std.int(v) != 0)
					body = (conversion == "o" ? "0" : conversion == "x" ? "0x" : "0X") + body;
			case "f" | "F" | "e" | "E" | "g" | "G":
				sign = v < 0 || 1 / v < 0 ? "-" : flags.indexOf("+") >= 0 ? "+" : flags.indexOf(" ") >= 0 ? " " : "";
				var size = Math.abs(v);
				var upper = conversion == conversion.toUpperCase();
				var places = precision < 0 ? 6 : precision;
				if (Math.isNaN(size))
					body = upper ? "NAN" : "nan";
				else if (!Math.isFinite(size))
					body = upper ? "INF" : "inf";
				else if (conversion == "f" || conversion == "F")
					body = fixed(size, places);
				else if (conversion == "e" || conversion == "E")
					body = exponent(size, places, upper);
				else {
					var p = precision < 0 ? 6 : precision == 0 ? 1 : precision;
					var e = size == 0 ? 0 : Std.parseInt(exponent(size, p - 1, false).split("e")[1]);
					body = p > e && e >= -4 ? fixed(size, p - 1 - e) : exponent(size, p - 1, upper);
					if (flags.indexOf("#") < 0)
						body = trimmed(body);
				}
				if (!Math.isFinite(size))
					numeric = false;
			case "c":
				numeric = false;
				body = String.fromCharCode(Std.int(v));
			case _:
				numeric = false;
				body = value == null ? "(null)" : Std.string(value);
				if (precision >= 0 && conversion == "s")
					body = body.substr(0, precision);
		}
		var length = sign.length + body.length;
		if (width <= length)
			return sign + body;
		var fill = StringTools.rpad("", " ", width - length);
		if (flags.indexOf("-") >= 0)
			return sign + body + fill;
		var zeros = numeric && flags.indexOf("0") >= 0 && !(precision >= 0 && "dixXou".indexOf(conversion) >= 0);
		return zeros ? sign + StringTools.rpad("", "0", width - length) + body : fill + sign + body;
	}

	// A value of TextFormat's as a number: an Int's or a Float's own, a Bool's 1 or 0, text's as parsed.
	static function number(value:Dynamic):Float {
		if (value == null)
			return 0;
		if (Std.isOfType(value, Int))
			return (value : Int);
		if (Std.isOfType(value, Float))
			return (value : Float);
		if (Std.isOfType(value, Bool))
			return value ? 1 : 0;
		return Std.parseFloat(Std.string(value));
	}

	// A whole number held in a Float, in decimal digits, however large.
	static function wholeDigits(x:Float):String {
		if (x < 2147483648.0)
			return Std.string(Std.int(x));
		var out = "";
		while (x >= 1) {
			out = Std.int(x % 10) + out;
			x = Math.ffloor(x / 10);
		}
		return out;
	}

	// A number not below 0 with a number of decimal places, rounded as C rounds it.
	static function fixed(x:Float, places:Int):String {
		var scale = Math.pow(10, places);
		var rounded = scaled(x, scale);
		var whole = Math.ffloor(rounded / scale);
		if (places == 0)
			return wholeDigits(whole);
		var fraction = wholeDigits(rounded - whole * scale);
		while (fraction.length < places)
			fraction = "0" + fraction;
		return wholeDigits(whole) + "." + fraction;
	}

	// x times scale, a power of 10, rounded to a whole number as C's printf rounds: to the nearest, a tie to even, judged on the exact
	// product. A product that rounds to a half is a tie only when the multiplication was exact; its error, found as Dekker's product
	// finds it, says which way it leans.
	static function scaled(x:Float, scale:Float):Float {
		var product = x * scale;
		var whole = Math.ffloor(product);
		var fraction = product - whole;
		if (fraction != 0.5)
			return fraction < 0.5 ? whole : whole + 1;
		var error = productError(x, scale, product);
		return error < 0 ? whole : error > 0 ? whole + 1 : whole % 2 == 0 ? whole : whole + 1;
	}

	// a * b - product, exactly, for product the rounded a * b.
	static function productError(a:Float, b:Float, product:Float):Float {
		var ca = 134217729.0 * a, cb = 134217729.0 * b;
		var aHigh = ca - (ca - a), bHigh = cb - (cb - b);
		var aLow = a - aHigh, bLow = b - bHigh;
		return ((aHigh * bHigh - product) + aHigh * bLow + aLow * bHigh) + aLow * bLow;
	}

	// A number not below 0 as C's %e has it: one digit, the places after it, and the exponent of 10, at least two digits.
	static function exponent(x:Float, places:Int, upper:Bool):String {
		var e = x == 0 ? 0 : Math.floor(Math.log(x) / Math.log(10));
		var mantissa = x == 0 ? "0" : fixed(x / Math.pow(10, e), places);
		// The logarithm can miss by one, and rounding can carry to 10.
		if (x != 0 && Std.parseFloat(mantissa) >= 10) {
			e++;
			mantissa = fixed(x / Math.pow(10, e), places);
		} else if (x != 0 && Std.parseFloat(mantissa) < 1) {
			e--;
			mantissa = fixed(x / Math.pow(10, e), places);
		}
		if (x == 0 && places > 0)
			mantissa = fixed(0, places);
		var power = Std.string(Std.int(Math.abs(e)));
		return mantissa + (upper ? "E" : "e") + (e < 0 ? "-" : "+") + (power.length < 2 ? "0" + power : power);
	}

	// %g's text without the zeros ending its fraction, nor a point left alone.
	static function trimmed(text:String):String {
		var parts = text.split(text.indexOf("E") >= 0 ? "E" : "e");
		var number = parts[0];
		if (number.indexOf(".") >= 0) {
			while (StringTools.endsWith(number, "0"))
				number = number.substr(0, number.length - 1);
			if (StringTools.endsWith(number, "."))
				number = number.substr(0, number.length - 1);
		}
		return parts.length > 1 ? number + (text.indexOf("E") >= 0 ? "E" : "e") + parts[1] : number;
	}
	#end
}
