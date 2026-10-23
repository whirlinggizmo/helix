package helix.behavior;

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
