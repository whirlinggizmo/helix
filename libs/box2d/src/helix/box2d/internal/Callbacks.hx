package helix.box2d.internal;

import helix.box2d.*;

/** Keeps the Haxe functions Box2D calls back. A call with a callback and a context (a query, a world's filter or pre-solve) holds them
	in a slot, whose number crosses as the C context and comes back with each callback. A query's slot lasts for the call, a world's
	until it is set again or the world is destroyed. The friction and restitution callbacks, which Box2D calls with no context, are
	kept by world and found by the world being stepped. */
@:noCompletion
class Callbacks {
	/** The function b2SetLogCallback set, or null for `print`. */
	public static var log:B2LogCallbackFcn;

	static var functions:Array<Array<Dynamic>> = [null];
	static var contexts:Array<Dynamic> = [null];
	static var free:Array<Int> = [];
	static var worlds = new Map<String, Int>();
	static var worldFunctions = new Map<String, Dynamic>();

	/** Holds `fns` and `context` in a slot, 1 or more, and returns its number. */
	public static function open(fns:Array<Dynamic>, context:Dynamic):Int {
		var slot = free.length > 0 ? free.pop() : functions.length;
		functions[slot] = fns;
		contexts[slot] = context;
		return slot;
	}

	public static function close(slot:Int):Void {
		functions[slot] = null;
		contexts[slot] = null;
		free.push(slot);
	}

	/** A world's slot for the callbacks a setter sets, the setter's earlier slot closed. */
	public static function world(worldId:B2WorldId, setter:String, fns:Array<Dynamic>, context:Dynamic):Int {
		var key = worldId.index1 + ":" + setter;
		if (worlds.exists(key))
			close(worlds.get(key));
		var slot = open(fns, context);
		worlds.set(key, slot);
		return slot;
	}

	public static function setWorldFunction(worldId:B2WorldId, kind:String, fn:Dynamic):Void {
		var key = worldId.index1 + ":" + kind;
		if (fn == null)
			worldFunctions.remove(key);
		else
			worldFunctions.set(key, fn);
	}

	/** The function of a kind kept for the world whose id's index1 is `world`. */
	public static function worldFunction(world:Int, kind:String):Dynamic
		return worldFunctions.get(world + ":" + kind);

	public static inline function get(slot:Int, index:Int):Dynamic
		return functions[slot][index];

	public static inline function context(slot:Int):Dynamic
		return contexts[slot];

	/** Closes a destroyed world's slots and drops its functions. */
	public static function clear(worldId:B2WorldId):Void {
		var prefix = worldId.index1 + ":";
		for (key in [for (k in worlds.keys()) k])
			if (StringTools.startsWith(key, prefix)) {
				close(worlds.get(key));
				worlds.remove(key);
			}
		for (key in [for (k in worldFunctions.keys()) k])
			if (StringTools.startsWith(key, prefix))
				worldFunctions.remove(key);
	}

	/** Box2D's log when the program set none: the process's error output natively, the console in a page. */
	public static function print(message:String):Void {
		#if sys
		Sys.stderr().writeString(message);
		#else
		js.Syntax.code("console.log({0})", StringTools.rtrim(message));
		#end
	}
}
