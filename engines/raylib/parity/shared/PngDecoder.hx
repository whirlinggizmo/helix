import haxe.io.Bytes;
import haxe.io.BytesInput;

// PNG files decoded to RGBA in Haxe, the same on every target, for a harness that reads an image's pixels (Node has no canvas to
// decode with): 8-bit grayscale, gray and alpha, RGB and RGBA, not interlaced, every filter. Each answer at the next poll.
class PngDecoder implements helix.platform.IImageDecoder {
	final waiting:Array<Void->Void> = [];

	public function new() {}

	public function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void {
		var result = null, error = null;
		try
			result = read(encoded)
		catch (e:Dynamic)
			error = Std.string(e);
		waiting.push(() -> result == null ? failed(error) : decoded(result.pixels, result.width, result.height));
	}

	public function decodeForGpu(encoded:Bytes, decoded:helix.platform.IDecodedImage->Void, failed:String->Void):Void
		decode(encoded, (pixels, width, height) -> decoded(new helix.platform.adapters.shared.PixelsImage(width, height, pixels)), failed);

	static function read(png:Bytes):{pixels:Bytes, width:Int, height:Int} {
		var at = 8, width = 0, height = 0, channels = 0;
		var idat = new haxe.io.BytesBuffer();
		while (at + 8 <= png.length) {
			var length = be32(png, at), kind = png.getString(at + 4, 4);
			var body = at + 8;
			if (kind == "IHDR") {
				width = be32(png, body);
				height = be32(png, body + 4);
				if (png.get(body + 8) != 8 || png.get(body + 12) != 0)
					throw "only 8-bit, not interlaced";
				channels = switch png.get(body + 9) {
					case 0: 1;
					case 4: 2;
					case 2: 3;
					case 6: 4;
					case _: throw "no palettes";
				}
			} else if (kind == "IDAT")
				idat.addBytes(png, body, length);
			at = body + length + 4;
		}
		var data = haxe.zip.InflateImpl.run(new BytesInput(idat.getBytes()));
		var stride = width * channels, rows = Bytes.alloc(stride * height);
		for (y in 0...height) {
			var filter = data.get(y * (stride + 1));
			for (i in 0...stride) {
				var x = data.get(y * (stride + 1) + 1 + i);
				var a = i >= channels ? rows.get(y * stride + i - channels) : 0;
				var b = y > 0 ? rows.get((y - 1) * stride + i) : 0;
				var c = i >= channels && y > 0 ? rows.get((y - 1) * stride + i - channels) : 0;
				var add = switch filter {
					case 0: 0;
					case 1: a;
					case 2: b;
					case 3: (a + b) >> 1;
					case _: var p = a + b - c, pa = Std.int(Math.abs(p - a)), pb = Std.int(Math.abs(p - b)), pc = Std.int(Math.abs(p - c)); pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
				}
				rows.set(y * stride + i, (x + add) & 255);
			}
		}
		var pixels = Bytes.alloc(width * height * 4);
		for (k in 0...width * height) {
			var s = k * channels;
			var gray = rows.get(s);
			pixels.set(k * 4, gray);
			pixels.set(k * 4 + 1, channels >= 3 ? rows.get(s + 1) : gray);
			pixels.set(k * 4 + 2, channels >= 3 ? rows.get(s + 2) : gray);
			pixels.set(k * 4 + 3, channels == 4 ? rows.get(s + 3) : channels == 2 ? rows.get(s + 1) : 255);
		}
		return {pixels: pixels, width: width, height: height};
	}

	static function be32(b:Bytes, at:Int):Int
		return (b.get(at) << 24) | (b.get(at + 1) << 16) | (b.get(at + 2) << 8) | b.get(at + 3);

	public function poll():Void {
		var now = waiting.copy();
		waiting.resize(0);
		for (f in now)
			f();
	}

	public function dispose():Void {}
}
