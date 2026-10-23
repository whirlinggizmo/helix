package helix.behavior;

import helix.behavior.BehaviorSchema;
import helix.behavior.BehaviorProp;
import helix.behavior.BehaviorPropType;

/** One registered behavior class: its schema, a new instance by make, and its props set and read by name through the setters and
	getters the build macro generated for the class, typed, with no reflection. */
class BehaviorEntry {
	var maker:Void->Behavior;
	var set:(Behavior, String, Dynamic) -> Bool;
	var get:(Behavior, String) -> Dynamic;

	@:allow(helix.behavior.BehaviorRegistry)
	function new(schema:BehaviorSchema, make:Void->Behavior, set:(Behavior, String, Dynamic) -> Bool, get:(Behavior, String) -> Dynamic) {
		this.schema = schema;
		this.maker = make;
		this.set = set;
		this.get = get;
	}

	/** The name it's registered under: the schema's. */
	public var name(get, never):String;

	function get_name():String
		return schema.name;

	/** Its props: names, types, defaults and ranges. */
	public var schema(default, null):BehaviorSchema;

	/** A new behavior of the class, its props at their defaults, in no pass. */
	public function make():Behavior
		return maker();

	/** Sets behavior's prop name to value. False, changing nothing, for a name the schema doesn't have, a value of the wrong type (a
		Float for an Int, a String for a number, a list with something but numbers in it, a node reference that isn't a Node3D or null),
		or a behavior that isn't of this class. */
	public function setProp(behavior:Behavior, name:String, value:Dynamic):Bool
		return set(behavior, name, value);

	/** Behavior's prop name as it is now; null for a name the schema doesn't have or a behavior that isn't of this class. */
	public function getProp(behavior:Behavior, name:String):Dynamic
		return get(behavior, name);
}
