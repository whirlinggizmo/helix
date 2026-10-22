package helix.scene;

/** What a kind's property holds in a .scene3d file: the shape the parser checks a value against, the writer writes, and an inspector makes a
	control for. */
@:noCompletion
enum PropertyType {
	/** A number, held from min to max where given (null for no bound), as the class clamps it. */
	Number(?min:Float, ?max:Float);

	/** Text: a path to an asset, or a named choice in lower case (a sprite's facing: "camera", "upright", "ground", "free"). */
	Text;

	/** A bool. */
	Flag;

	/** A list of count numbers. */
	Numbers(count:Int);

	/** A color, "#RRGGBB" or "#RRGGBBAA" in the file, 0xAARRGGBB in memory. */
	Color;

	/** A reference to a node of the file, "@name" or "@path/from/root" in the file. */
	Reference;
}

/** One property of a kind: its name as the class names it, its type, and the class's default, which the writer leaves out of the file. */
@:noCompletion
class PropertySchema {
	/** Its name, as the class names the property (intensity, fovY, shadowCasting). */
	public final name:String;

	/** The shape of its value. */
	public final type:PropertyType;

	/** What the class starts with: a value equal to it is not written, and an absent key means it. */
	public final defaultValue:SceneValue;

	/** A property name of type type, whose class starts it at defaultValue. */
	public function new(name:String, type:PropertyType, defaultValue:SceneValue) {
		this.name = name;
		this.type = type;
		this.defaultValue = defaultValue;
	}
}

/** One kind's table: its name, as the file's "kind" names the class, its properties in the order the writer writes them, and what the class
	starts its flags at (an unsaid flag in a file means the kind's own default, and a flag at it isn't written). */
@:noCompletion
class KindSchema {
	/** The class's name: Model3D, DirectionalLight3D, Camera3D. */
	public final name:String;

	/** Its properties, in writing order: a parent class's first (a light's before a spot's range and cones). */
	public final properties:Array<PropertySchema>;

	/** What the class starts Node.enabled at: true for every kind. */
	public final enabled:Bool;

	/** What the class starts Node.visible at: true for every kind. */
	public final visible:Bool;

	/** What the class starts Node.pickable at: false for a Text3D (a label lets a pick through to what it names), true elsewhere. */
	public final pickable:Bool;

	/** A kind name with properties, its flags starting at enabled, visible and pickable (each true unless said). */
	public function new(name:String, properties:Array<PropertySchema>, enabled = true, visible = true, pickable = true) {
		this.name = name;
		this.properties = properties;
		this.enabled = enabled;
		this.visible = visible;
		this.pickable = pickable;
	}

	/** Its property named name, or null for one it hasn't. */
	public function property(name:String):Null<PropertySchema> {
		for (property in properties)
			if (property.name == name)
				return property;
		return null;
	}
}
