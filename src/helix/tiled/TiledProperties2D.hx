package helix.tiled;

/** A Tiled map's, layer's, tile's or object's custom properties (Tiled's Custom Properties panel), read by name with what it is when
	missing. Colors come as 0xAARRGGBB; a file property is its path as Tiled wrote it (relative to the file it's in); a class property is
	its members as a JSON object (getRaw). */
class TiledProperties2D {
	var values:Map<String, Dynamic> = new Map<String, Dynamic>();
	var types:Map<String, String> = new Map<String, String>();

	/** None: what a thing without custom properties has. */
	public function new() {}

	/** Reads Tiled's JSON list ([{name, type, value}]); a missing list is none. */
	@:allow(helix.tiled)
	static function read(list:Null<Array<Dynamic>>):TiledProperties2D {
		var found = new TiledProperties2D();
		if (list != null)
			for (entry in list) {
				var name:String = entry.name;
				if (name == null)
					continue;
				found.values.set(name, entry.value);
				found.types.set(name, entry.type != null ? entry.type : "string");
			}
		return found;
	}

	/** Whether it has the property name. */
	public function has(name:String):Bool
		return values.exists(name);

	/** The names it has, in no particular order. */
	public function getNames():Array<String>
		return [for (name in values.keys()) name];

	/** Property name as text (a number or bool written out), or otherwise when missing. */
	public function getString(name:String, otherwise = ""):String {
		var value = values.get(name);
		return value == null ? otherwise : Std.string(value);
	}

	/** Property name as a whole number (a float's whole part, a bool 1 or 0), or otherwise when missing or not a number. */
	public function getInt(name:String, otherwise = 0):Int {
		var value:Dynamic = values.get(name);
		if (Std.isOfType(value, Bool))
			return value ? 1 : 0;
		if (Std.isOfType(value, Float))
			return Std.int(value);
		return otherwise;
	}

	/** Property name as a number, or otherwise when missing or not a number. */
	public function getFloat(name:String, otherwise = 0.):Float {
		var value:Dynamic = values.get(name);
		return Std.isOfType(value, Float) ? (value : Float) : otherwise;
	}

	/** Property name as a bool (true, or a number not 0), or otherwise when missing. */
	public function getBool(name:String, otherwise = false):Bool {
		var value:Dynamic = values.get(name);
		if (Std.isOfType(value, Bool))
			return value;
		if (Std.isOfType(value, Float))
			return value != 0;
		return otherwise;
	}

	/** Property name as a color, 0xAARRGGBB (Tiled writes "#AARRGGBB", or "#RRGGBB" opaque), or otherwise when missing or not a color. */
	public function getColor(name:String, otherwise = 0xffffffff):Int {
		var value:Dynamic = values.get(name);
		var parsed = Std.isOfType(value, String) ? TiledMap2D.parseColor(value) : null;
		return parsed != null ? parsed : otherwise;
	}

	/** Property name as Tiled's JSON has it (a class property's members as an object), or null when missing. */
	public function getRaw(name:String):Dynamic
		return values.get(name);

	/** Property name's Tiled type ("string", "int", "float", "bool", "color", "file", "object" or "class"), or null when missing. */
	public function getType(name:String):Null<String>
		return types.get(name);
}
