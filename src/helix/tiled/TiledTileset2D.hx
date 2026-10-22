package helix.tiled;

import helix.texture.Texture2D;

/** A Tiled tileset as a map uses it: one image cut into a grid of tiles (an image-collection tileset, a file a tile, isn't read), the
	global ids from firstGid on its tiles in order, and what its tiles carry: a class, custom properties, an animation, and the terrain
	sets auto-tiling picks from (TiledTerrainSet2D, the "Terrain Sets" Tiled draws with). Its texture is in once the map has loaded. */
class TiledTileset2D {
	@:allow(helix.tiled)
	function new() {}

	/** Its name in Tiled. */
	public var name(default, null):String = "";

	/** The global id of its first tile in the map; its tile n is firstGid + n. */
	public var firstGid(default, null):Int = 1;

	/** Each tile's size, pixels. */
	public var tileWidth(default, null):Int = 0;

	/** Each tile's height, pixels. */
	public var tileHeight(default, null):Int = 0;

	/** How many tiles it has. */
	public var tileCount(default, null):Int = 0;

	/** How many tiles a row of its image holds. */
	public var columns(default, null):Int = 0;

	/** Pixels round the image's edge before the first tile. */
	public var margin(default, null):Int = 0;

	/** Pixels between tiles. */
	public var spacing(default, null):Int = 0;

	/** Its image's path among the assets. */
	public var image(default, null):String = "";

	/** Its image, nearest-sampled for pixel art; null until the map has loaded (or when it's parsed alone). */
	public var texture(default, null):Null<Texture2D>;

	/** Where its tiles are drawn from their cell, pixels (Tiled's Drawing Offset). */
	public var offsetX(default, null):Int = 0;

	/** The drawing offset's y, pixels, down. */
	public var offsetY(default, null):Int = 0;

	/** Its terrain sets, in Tiled's order. */
	public var terrainSets(default, null):Array<TiledTerrainSet2D> = [];

	/** Its own custom properties. */
	public var properties(default, null):TiledProperties2D = new TiledProperties2D();

	var classes:Map<Int, String> = new Map<Int, String>();
	var tileProperties:Map<Int, TiledProperties2D> = new Map<Int, TiledProperties2D>();
	var animations:Map<Int, Array<TiledFrame2D>> = new Map<Int, Array<TiledFrame2D>>();

	/** Whether global id gid (its flip bits ignored) is one of its tiles. */
	public function holds(gid:Int):Bool {
		var id = (gid & TiledMap2D.GID_MASK) - firstGid;
		return id >= 0 && id < tileCount;
	}

	/** Tile id's (counted from 0 in this tileset) region of the image, x, y, width and height in pixels, into out (4 numbers). */
	public function getRegion(id:Int, out:Array<Float>):Array<Float> {
		var across = columns > 0 ? columns : 1;
		out[0] = margin + (id % across) * (tileWidth + spacing);
		out[1] = margin + Std.int(id / across) * (tileHeight + spacing);
		out[2] = tileWidth;
		out[3] = tileHeight;
		return out;
	}

	/** How far inside its texels a tile's region is drawn, each side: a tile edge on its neighbor's in the image would otherwise sample a
		line of the neighbor when the map is scaled or between pixels (the atlas's bleed). */
	public static inline var INSET = .02;

	/** Tile id's region as drawn: getRegion's, INSET inside it on each side. */
	@:allow(helix.tiled)
	function getDrawnRegion(id:Int, out:Array<Float>):Array<Float> {
		getRegion(id, out);
		out[0] += INSET;
		out[1] += INSET;
		out[2] -= 2 * INSET;
		out[3] -= 2 * INSET;
		return out;
	}

	/** Tile id's class (Tiled's Class, or Type before 1.9), "" when it has none. */
	public function getClass(id:Int):String {
		var found = classes.get(id);
		return found != null ? found : "";
	}

	/** Tile id's custom properties (none when it has none). */
	public function getTileProperties(id:Int):TiledProperties2D {
		var found = tileProperties.get(id);
		return found != null ? found : new TiledProperties2D();
	}

	/** Tile id's animation, its frames in order, or null when it isn't animated. */
	public function getAnimation(id:Int):Null<Array<TiledFrame2D>>
		return animations.get(id);

	/** The terrain set named name, or null. */
	public function findTerrainSet(name:String):Null<TiledTerrainSet2D> {
		for (set in terrainSets)
			if (set.name == name)
				return set;
		return null;
	}

	/** Reads Tiled's JSON for a tileset (embedded in a map, or a .tsj file's), its image relative to the file at path, its first global id
		firstGid. Throws, saying why, for one it can't use. */
	@:allow(helix.tiled)
	static function read(json:Dynamic, path:String, firstGid:Int):TiledTileset2D {
		var made = new TiledTileset2D();
		made.firstGid = firstGid;
		made.name = json.name != null ? json.name : "";
		if (json.image == null)
			throw 'Tileset ${made.name} in $path is an image collection (an image a tile), which isn\'t read: one image for the tileset';
		made.tileWidth = Std.int(json.tilewidth);
		made.tileHeight = Std.int(json.tileheight);
		made.tileCount = Std.int(json.tilecount);
		made.columns = Std.int(json.columns);
		made.margin = json.margin != null ? Std.int(json.margin) : 0;
		made.spacing = json.spacing != null ? Std.int(json.spacing) : 0;
		var resolved = helix.asset.AssetPath.resolve(path, json.image);
		if (resolved == null)
			throw 'Tileset ${made.name} in $path names an image outside the assets: ${json.image}';
		made.image = resolved;
		if (json.tileoffset != null) {
			made.offsetX = Std.int(json.tileoffset.x);
			made.offsetY = Std.int(json.tileoffset.y);
		}
		made.properties = TiledProperties2D.read(json.properties);
		if (json.tiles != null)
			for (tile in (json.tiles : Array<Dynamic>)) {
				var id = Std.int(tile.id);
				var className:Null<String> = tile.type != null ? tile.type : Reflect.field(tile, "class");
				if (className != null && className != "")
					made.classes.set(id, className);
				if (tile.properties != null)
					made.tileProperties.set(id, TiledProperties2D.read(tile.properties));
				if (tile.animation != null)
					made.animations.set(id, [
						for (frame in (tile.animation : Array<Dynamic>))
							new TiledFrame2D(Std.int(frame.tileid), frame.duration / 1000)
					]);
			}
		if (json.wangsets != null)
			for (set in (json.wangsets : Array<Dynamic>))
				made.terrainSets.push(TiledTerrainSet2D.read(set, made));
		return made;
	}

	@:allow(helix.tiled)
	function setTexture(texture:Texture2D):Void
		this.texture = texture;
}
