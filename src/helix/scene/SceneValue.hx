package helix.scene;

/** A value as a .scene3d file holds it: a kind's property, a behavior's prop, or one of a node's own props. JSON's own shapes (a number, text,
	a bool, a list of numbers), and two shapes of string the file gives a meaning: a color, "#RRGGBB" or "#RRGGBBAA", and a reference to a
	node of the file, "@name" or "@path/from/root". */
enum SceneValue {
	/** A number. */
	Number(value:Float);

	/** Text: a path to an asset, a named choice ("camera"), or what a behavior wants. */
	Text(value:String);

	/** A bool. */
	Flag(value:Bool);

	/** A list of numbers. */
	Numbers(values:Array<Float>);

	/** A color, 0xAARRGGBB; "#RRGGBB" in the file is alpha ff. */
	Color(rgba:Int);

	/** A reference to a node of the file: the name or path after the "@", resolved once every node is made. */
	Reference(path:String);
}
