package helix.render2d;

import haxe.io.Bytes;
import helix.graphics.TextureFormat;

/** A compressed texture as a KTX 1 file holds it: BC7, ASTC 4x4 or ETC2 RGBA8, 2D, with its mipmaps
	(https://registry.khronos.org/KTX/specs/1.0/ktxspec.v1.html). Read in Haxe, the same on every target; Textures2D loads them. */
class Ktx {
	static inline var HEADER = 64;
	static var IDENTIFIER = [0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A];

	/** The texels' format. */
	public final format:TextureFormat;

	/** Width in texels. */
	public final width:Int;

	/** Height in texels. */
	public final height:Int;

	/** The image, then its mipmaps, each format.levelBytes of its size. */
	public final levels:Array<Bytes>;

	function new(format:TextureFormat, width:Int, height:Int, levels:Array<Bytes>) {
		this.format = format;
		this.width = width;
		this.height = height;
		this.levels = levels;
	}

	/** Reads a KTX 1 file. Throws, saying why, for anything but a little-endian, 2D, BC7, ASTC 4x4 or ETC2 RGBA8 one whose levels are all there. */
	public static function read(bytes:Bytes):Ktx {
		if (bytes.length < HEADER)
			throw "Not a KTX 1 file";
		for (i in 0...IDENTIFIER.length)
			if (bytes.get(i) != IDENTIFIER[i])
				throw "Not a KTX 1 file";
		inline function field(index:Int):Int
			return bytes.getInt32(12 + index * 4);
		if (field(0) != 0x04030201)
			throw "Big-endian KTX files aren't read";
		if (field(1) != 0 || field(3) != 0)
			throw "Not a compressed texture (glType or glFormat set)";
		var format:TextureFormat = switch field(4) {
			case 0x8E8C: Bc7;
			case 0x93B0: Astc4x4;
			case 0x9278: Etc2Rgba8;
			case other: throw 'Not BC7, ASTC 4x4 or ETC2 RGBA8 (glInternalFormat 0x${StringTools.hex(other)})';
		}
		var width = field(6), height = field(7);
		if (width < 1 || height < 1 || width > 16384 || height > 16384)
			throw 'Bad size $width x $height';
		if (field(8) > 1 || field(9) > 1 || field(10) != 1)
			throw "Only 2D textures are read, not 3D ones, arrays or cubemaps";
		var count = field(11) == 0 ? 1 : field(11);
		if (count > 16)
			throw "Too many mipmap levels";
		var keyValueBytes = field(12);
		if (keyValueBytes < 0 || keyValueBytes > bytes.length - HEADER)
			throw "Cut short (key/value data)";
		var at = HEADER + keyValueBytes, w = width, h = height, levels = [];
		for (_ in 0...count) {
			var expected = format.levelBytes(w, h);
			if (at + 4 > bytes.length)
				throw "Cut short (a level's size)";
			var size = bytes.getInt32(at);
			at += 4;
			if (size != expected)
				throw "A level's size doesn't match its dimensions";
			if (size > bytes.length - at)
				throw "Cut short (a level's data)";
			levels.push(bytes.sub(at, size));
			at += (size + 3) & ~3;
			w = w > 1 ? w >> 1 : 1;
			h = h > 1 ? h >> 1 : 1;
		}
		return new Ktx(format, width, height, levels);
	}
}
