package helix.behavior;

/** What a behavior class takes from a scene file or an inspector: its name (the class's, or what `@:behavior("Name")` gave it), its
	phase and its props, each a `@:prop` field with its type, its default and its range. Generated on each subclass by the build macro
	(helix.macro.Behaviors, its `schema()`), and kept by BehaviorRegistry by name. */
typedef BehaviorSchema = {
	/** The name a file or the registry knows the class by. */
	final name:String;

	/** Its props, a superclass's first, each in the order declared. */
	final props:Array<BehaviorProp>;

	/** When in a frame it runs: `@:phase` on the class, its superclass's without one, Simulate when none says. */
	final phase:Phase;
}

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

/** The types a `@:prop` field can have, as a scene file writes them: a number, a string, a bool, a list of numbers, a color or a node
	reference. A field of any other type is a compile error naming it. */
enum BehaviorPropType {
	/** An `Int`. */
	IntProp;

	/** A `Float`. */
	FloatProp;

	/** A `Bool`. */
	BoolProp;

	/** A `String`. */
	StringProp;

	/** An `Array<Float>` (the type declared on the field). */
	FloatsProp;

	/** An `Int` holding a color, 0xAARRGGBB, marked `@:prop("color")`: a file writes it `"#RRGGBB"` or `"#RRGGBBAA"`. */
	ColorProp;

	/** A `helix.render3d.Node3D`, a reference to a node of the file (`"@name"` or `"@path/from/root"`), null until resolved. */
	NodeProp;
}
