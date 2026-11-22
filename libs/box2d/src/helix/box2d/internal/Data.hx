package helix.box2d.internal;

import helix.box2d.*;

/** Keeps the user data of worlds, bodies, shapes, joints and chains on the Haxe side, by id: Box2D's own user data pointer is never
	set, as a Haxe value can't cross into box2d.wasm. An id's generation keeps a value from passing to a later object in the same
	place. A world's values go with it. */
@:noCompletion
class Data {
	static var values = new Map<String, Dynamic>();

	static function key(id:Dynamic):String {
		if (Std.isOfType(id, B2WorldId))
			return "w" + (id : B2WorldId).index1 + ":" + (id : B2WorldId).generation;
		var kind = Std.isOfType(id, B2BodyId) ? "b" : Std.isOfType(id, B2ShapeId) ? "s" : Std.isOfType(id, B2JointId) ? "j" : "c";
		var world:Int = id.world0;
		return world + kind + ":" + (id.index1 : Int) + ":" + (id.generation : Int);
	}

	public static function set(id:Dynamic, value:Dynamic):Void {
		if (value == null)
			values.remove(key(id));
		else
			values.set(key(id), value);
	}

	public static function get(id:Dynamic):Dynamic
		return values.get(key(id));

	/** Drops a destroyed world's values. */
	public static function clear(worldId:B2WorldId):Void {
		var world = "w" + worldId.index1 + ":";
		var inside = (worldId.index1 - 1) + "";
		for (k in [for (k in values.keys()) k])
			if (StringTools.startsWith(k, world)
				|| (StringTools.startsWith(k, inside) && !StringTools.startsWith(k, "w") && k.charAt(inside.length) >= "a"))
				values.remove(k);
	}
}
