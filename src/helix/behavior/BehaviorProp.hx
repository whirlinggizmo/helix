package helix.behavior;

/** One `@:prop` of a behavior class: the field's name, what it holds, the value it starts with (the field's initializer, read by the
	macro) and, from `@:range(min, max)`, the least and most an inspector offers; null for no range. The range is for an inspector's
	slider: setting a prop through the registry doesn't clamp to it. */
typedef BehaviorProp = {
	/** The field's name, which the file and the registry use. */
	final name:String;

	/** What the field holds. */
	final type:BehaviorPropType;

	/** The field's initializer: what a fresh behavior has until the file or the game sets it (a node reference's is null). */
	final value:Dynamic;

	/** The least from `@:range`, or null. */
	final min:Null<Float>;

	/** The most from `@:range`, or null. */
	final max:Null<Float>;
}
