package helix.tiled;

import haxe.io.Bytes;
import helix.texture.Texture2D;

/** A layer of a Tiled map as read: its kind and what that holds, its name, whether it's shown, its opacity, its offset and its custom
	properties. A map's layers are drawn in their order, the first under the rest; a group's are under it, its offset and opacity
	applying to them (TiledMap2D.instantiate). */
class TiledLayer2D {
	@:allow(helix.tiled)
	function new() {}

	/** What it holds. */
	public var kind(default, null):TiledLayerKind2D = Tiles;

	/** Its name in Tiled. */
	public var name(default, null):String = "";

	/** Its class in Tiled, "" when it has none. */
	public var className(default, null):String = "";

	/** Whether it's shown. */
	public var visible(default, null):Bool = true;

	/** Its opacity, 0 to 1. */
	public var opacity(default, null):Float = 1;

	/** Its offset, pixels: where it's drawn from its parent's place. */
	public var offsetX(default, null):Float = 0;

	/** Its offset's y, pixels, down. */
	public var offsetY(default, null):Float = 0;

	/** A tile layer's columns. */
	public var columns(default, null):Int = 0;

	/** A tile layer's rows. */
	public var rows(default, null):Int = 0;

	/** A tile layer's global ids, row by row from the top-left, flip bits and all; 0 for an empty cell. */
	public var tiles(default, null):Array<Int> = [];

	/** An object layer's objects, in Tiled's order. */
	public var objects(default, null):Array<TiledObject2D> = [];

	/** An image layer's image path among the assets, "" otherwise. */
	public var image(default, null):String = "";

	/** An image layer's image once the map has loaded, or null. */
	public var texture(default, null):Null<Texture2D>;

	/** A group's layers, in their order. */
	public var layers(default, null):Array<TiledLayer2D> = [];

	/** Its custom properties. */
	public var properties(default, null):TiledProperties2D = new TiledProperties2D();

	/** A tile layer's global id at column, row, flip bits and all; 0 outside it or for an empty cell. */
	public function getTile(column:Int, row:Int):Int
		return column >= 0 && row >= 0 && column < columns && row < rows ? tiles[row * columns + column] : 0;

	@:allow(helix.tiled)
	function setTexture(texture:Texture2D):Void
		this.texture = texture;

	/** Reads Tiled's JSON for a layer of the map at path. Throws, saying why, for one it can't use. */
	@:allow(helix.tiled)
	static function read(json:Dynamic, path:String):TiledLayer2D {
		var made = new TiledLayer2D();
		made.name = json.name != null ? json.name : "";
		var className:Null<String> = Reflect.field(json, "class");
		made.className = className != null ? className : "";
		made.visible = json.visible != false;
		made.opacity = json.opacity != null ? json.opacity : 1;
		made.offsetX = json.offsetx != null ? json.offsetx : 0;
		made.offsetY = json.offsety != null ? json.offsety : 0;
		made.properties = TiledProperties2D.read(json.properties);
		switch (json.type : String) {
			case "tilelayer":
				made.kind = Tiles;
				if (json.chunks != null)
					throw 'Layer ${made.name} in $path is an infinite map\'s, which isn\'t read: untick Infinite in the map\'s properties';
				made.columns = Std.int(json.width);
				made.rows = Std.int(json.height);
				made.tiles = readTiles(json, made.columns * made.rows, '${made.name} in $path');
			case "objectgroup":
				made.kind = Objects;
				if (json.objects != null)
					for (o in (json.objects : Array<Dynamic>))
						made.objects.push(TiledObject2D.read(o));
			case "imagelayer":
				made.kind = Image;
				if (json.image != null && json.image != "") {
					var resolved = helix.asset.AssetPath.resolve(path, json.image);
					if (resolved == null)
						throw 'Layer ${made.name} in $path names an image outside the assets: ${json.image}';
					made.image = resolved;
				}
			case "group":
				made.kind = Group;
				if (json.layers != null)
					for (l in (json.layers : Array<Dynamic>))
						made.layers.push(read(l, path));
			case other:
				throw 'Layer ${made.name} in $path is of a kind not read: $other';
		}
		return made;
	}

	// A tile layer's cells, count of them, from its data: Tiled's array of ids, or base64 of little-endian 32-bit ids (uncompressed, zlib
	// or gzip; zstd isn't read).
	static function readTiles(json:Dynamic, count:Int, where:String):Array<Int> {
		if (json.encoding != "base64") {
			var data:Array<Dynamic> = json.data;
			if (data == null || data.length != count)
				throw 'Layer $where has ${data == null ? 0 : data.length} cells for its $count';
			// Ids past 2^31 (a horizontal flip) arrive as floats in JSON: their 32 bits kept.
			return [for (v in data) toInt(v)];
		}
		var bytes = haxe.crypto.Base64.decode(StringTools.trim(json.data));
		switch (json.compression : Null<String>) {
			case null | "":
			case "zlib":
				bytes = inflate(bytes, false, count * 4);
			case "gzip":
				bytes = inflate(bytes, true, count * 4);
			case other:
				throw 'Layer $where is compressed with $other, which isn\'t read: CSV, base64, or base64 with zlib or gzip';
		}
		if (bytes.length < count * 4)
			throw 'Layer $where has ${Std.int(bytes.length / 4)} cells for its $count';
		return [for (i in 0...count) bytes.getInt32(i * 4)];
	}

	static function toInt(v:Float):Int
		return v >= 2147483648.?Std.int(v - 4294967296.)

	:Std.int
	(v);
	// Data inflated to size bytes: zlib's (its 2-byte header), or gzip's (its header read past).
	static function inflate(data:Bytes, gzip:Bool, size:Int):Bytes {
		var input = new haxe.io.BytesInput(data);
		if (gzip) {
			if (data.length < 10 || data.get(0) != 0x1f || data.get(1) != 0x8b)
				throw "Not gzip data";
			var flags = data.get(3), at = 10;
			if (flags & 4 != 0)
				at += 2 + (data.get(at) | data.get(at + 1) << 8);
			if (flags & 8 != 0) {
				while (data.get(at) != 0)
					at++;
				at++;
			}
			if (flags & 16 != 0) {
				while (data.get(at) != 0)
					at++;
				at++;
			}
			if (flags & 2 != 0)
				at += 2;
			input.position = at;
		}
		var out = Bytes.alloc(size), inflater = new haxe.zip.InflateImpl(input, !gzip, false), got = 0;
		while (got < size) {
			var read = inflater.readBytes(out, got, size - got);
			if (read <= 0)
				break;
			got += read;
		}
		return got == size ? out : out.sub(0, got);
	}
}
