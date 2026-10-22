package helix.tiled;

/** An object of a Tiled object layer: a spawn point, a trigger area, a path, a placed tile. Its place is the map's pixels, from its
	top-left; what it means is the game's, from its name, class and custom properties (TiledInstance2D.findObject, getObjects). */
class TiledObject2D {
	@:allow(helix.tiled)
	function new() {}

	/** Its id, unique in its map. */
	public var id(default, null):Int = 0;

	/** Its name, "" when it has none. */
	public var name(default, null):String = "";

	/** Its class (Tiled's Class, or Type before 1.9), "" when it has none: what kind of thing the game should make of it. */
	public var className(default, null):String = "";

	/** Its shape. */
	public var shape(default, null):TiledShape2D = Rectangle;

	/** Its x, map pixels: a tile object's left edge, anything else's left or the point. */
	public var x(default, null):Float = 0;

	/** Its y, map pixels, down: a tile object's bottom edge (as Tiled places them), anything else's top or the point. */
	public var y(default, null):Float = 0;

	/** Its width, pixels (0 for a point, a polygon or a polyline). */
	public var width(default, null):Float = 0;

	/** Its height, pixels. */
	public var height(default, null):Float = 0;

	/** Its turn about x, y, radians, clockwise on screen. */
	public var rotation(default, null):Float = 0;

	/** Whether it's shown in Tiled (a tile object hidden is drawn hidden). */
	public var visible(default, null):Bool = true;

	/** A polygon's or a polyline's points relative to x, y, x and y in turn; empty for the other shapes. */
	public var points(default, null):Array<Float> = [];

	/** A tile object's global id, flip bits and all (TiledMap2D.GID_MASK takes them off); 0 for the other shapes. */
	public var gid(default, null):Int = 0;

	/** Its custom properties. */
	public var properties(default, null):TiledProperties2D = new TiledProperties2D();

	@:allow(helix.tiled)
	static function read(json:Dynamic):TiledObject2D {
		var made = new TiledObject2D();
		made.id = json.id != null ? Std.int(json.id) : 0;
		made.name = json.name != null ? json.name : "";
		var className:Null<String> = json.type != null && json.type != "" ? json.type : Reflect.field(json, "class");
		made.className = className != null ? className : "";
		made.x = json.x != null ? json.x : 0;
		made.y = json.y != null ? json.y : 0;
		made.width = json.width != null ? json.width : 0;
		made.height = json.height != null ? json.height : 0;
		made.rotation = json.rotation != null ? json.rotation * Math.PI / 180 : 0;
		made.visible = json.visible != false;
		made.properties = TiledProperties2D.read(json.properties);
		if (json.gid != null) {
			made.shape = Tile;
			made.gid = Std.int(json.gid);
		} else if (json.point == true)
			made.shape = Point;
		else if (json.ellipse == true)
			made.shape = Ellipse;
		else if (json.polygon != null || json.polyline != null) {
			made.shape = json.polygon != null ? Polygon : Polyline;
			var corners:Array<Dynamic> = json.polygon != null ? json.polygon : json.polyline;
			for (p in corners) {
				made.points.push(p.x);
				made.points.push(p.y);
			}
		} else if (json.text != null)
			made.shape = Text;
		return made;
	}
}
