package helix.tiled;

/** A tileset's terrain set (Tiled's "Terrain Set", its file's "wangset"): the terrains it has, numbered from 1 (0 is none), and for each
	tile that takes part which terrain is at each corner or edge, so a layer can pick the tile that fits its neighbors
	(TiledTileLayer2D.setTerrain). */
class TiledTerrainSet2D {
	@:allow(helix.tiled)
	function new(tileset:TiledTileset2D) {
		this.tileset = tileset;
	}

	/** Its name in Tiled. */
	public var name(default, null):String = "";

	/** How its tiles meet. */
	public var kind(default, null):TiledTerrainKind2D = Corner;

	/** The tileset it's in. */
	public var tileset(default, null):TiledTileset2D;

	/** Its terrains' names, the terrain numbered n at n - 1. */
	public var terrains(default, null):Array<String> = [];

	// Each tile's eight places (Tiled's order: top, top right, right, bottom right, bottom, bottom left, left, top left; edges the even ones,
	// corners the odd), by tile id; and the tiles of each arrangement, by its key.
	var places:Map<Int, Array<Int>> = new Map<Int, Array<Int>>();
	var byKey:Map<String, Array<Int>> = new Map<String, Array<Int>>();

	/** The terrain numbered name's number (from 1), or 0 when it has none of that name. */
	public function findTerrain(name:String):Int
		return terrains.indexOf(name) + 1;

	/** Tile id's terrain at place (0 to 7 in Tiled's order, from the top clockwise: edges even, corners odd), or 0 when it isn't in the
		set. */
	public function getTerrainAt(id:Int, place:Int):Int {
		var found = places.get(id);
		return found != null && place >= 0 && place < 8 ? found[place] : 0;
	}

	/** Whether tile id is in the set. */
	public function holds(id:Int):Bool
		return places.exists(id);

	/** The first tile (by id in its tileset) whose eight places are those given, or -1 when no tile is. */
	@:allow(helix.tiled)
	function find(eight:Array<Int>):Int {
		var tiles = byKey.get(eight.join(","));
		return tiles != null && tiles.length > 0 ? tiles[0] : -1;
	}

	@:allow(helix.tiled)
	static function read(json:Dynamic, tileset:TiledTileset2D):TiledTerrainSet2D {
		var made = new TiledTerrainSet2D(tileset);
		made.name = json.name != null ? json.name : "";
		made.kind = switch (json.type : String) {
			case "edge": Edge;
			case "mixed": Mixed;
			default: Corner;
		}
		if (json.colors != null)
			for (color in (json.colors : Array<Dynamic>))
				made.terrains.push(color.name != null ? color.name : "");
		if (json.wangtiles != null)
			for (tile in (json.wangtiles : Array<Dynamic>)) {
				var eight:Array<Int> = [for (v in (tile.wangid : Array<Dynamic>)) Std.int(v)];
				if (eight.length != 8)
					continue;
				var id = Std.int(tile.tileid);
				made.places.set(id, eight);
				var key = eight.join(",");
				if (!made.byKey.exists(key))
					made.byKey.set(key, []);
				made.byKey.get(key).push(id);
			}
		return made;
	}
}
