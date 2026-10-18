package helix.scene;

/** What a kind's property holds in a .scene file: the shape the parser checks a value against, the writer writes, and an inspector makes a
	control for. */
enum PropertyType {
	/** A number, held from min to max where given (null for no bound), as the class clamps it. */
	Number(?min:Float, ?max:Float);

	/** Text: a path to an asset, or a named choice in lower case (a sprite's facing: "camera", "upright", "ground", "free"). */
	Text;

	/** A bool. */
	Flag;

	/** A list of count numbers. */
	Numbers(count:Int);

	/** A color, "#RRGGBB" or "#RRGGBBAA" in the file, 0xRRGGBBAA in memory. */
	Color;

	/** A reference to a node of the file, "@name" or "@path/from/root" in the file. */
	Reference;
}

/** One property of a kind: its name as the class names it, its type, and the class's default, which the writer leaves out of the file. */
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

/** One kind's table: its name, as the file's "kind" names the class, and its properties in the order the writer writes them. */
class KindSchema {
	/** The class's name: Model, DirectionalLight, Camera3D. */
	public final name:String;

	/** Its properties, in writing order: a parent class's first (a light's before a spot's range and cones). */
	public final properties:Array<PropertySchema>;

	/** A kind name with properties. */
	public function new(name:String, properties:Array<PropertySchema>) {
		this.name = name;
		this.properties = properties;
	}

	/** Its property named name, or null for one it hasn't. */
	public function property(name:String):Null<PropertySchema> {
		for (property in properties)
			if (property.name == name)
				return property;
		return null;
	}
}

/** The kinds a .scene file's nodes can be and what each writes flat beside its name and transform: one table per kind, the one place that
	says it, so the parser checks keys and shapes against it, the writer writes in its order leaving defaults out, and an inspector reads its
	controls from it; nothing can be written that can't be read. The names are the classes' own (helix.render3d), the defaults what each class
	starts with. A kind without properties (Node3D, a group; Particles3D, whose emitter is set in code) is still a kind. */
class SceneSchema {
	/** Every kind's table, in the order the writer takes an override's properties (a node's own kind orders its own). */
	public static var kinds(default, null):Array<KindSchema> = [
		new KindSchema("Node3D", []),
		new KindSchema("Model", [
			new PropertySchema("tint", PropertyType.Color, SceneValue.Color(0xffffffff)),
			new PropertySchema("shadowCasting", PropertyType.Flag, SceneValue.Flag(true)),
			new PropertySchema("shadowReceiving", PropertyType.Flag, SceneValue.Flag(true))
		]),
		new KindSchema("DirectionalLight", light()),
		new KindSchema("PointLight", light().concat([range()])),
		new KindSchema("SpotLight", light().concat([
			range(),
			new PropertySchema("innerCone", PropertyType.Number(0, Math.PI / 2), SceneValue.Number(0.3)),
			new PropertySchema("outerCone", PropertyType.Number(0, Math.PI / 2), SceneValue.Number(0.4))
		])),
		new KindSchema("Camera3D", [
			new PropertySchema("fovY", PropertyType.Number(0, Math.PI), SceneValue.Number(Math.PI / 4)),
			new PropertySchema("near", PropertyType.Number(0), SceneValue.Number(0.1)),
			new PropertySchema("far", PropertyType.Number(0), SceneValue.Number(1000)),
			new PropertySchema("orthographicHeight", PropertyType.Number(0), SceneValue.Number(0)),
			new PropertySchema("minAspect", PropertyType.Number(0), SceneValue.Number(0))
		]),
		new KindSchema("Sprite3D", [
			new PropertySchema("texture", PropertyType.Text, SceneValue.Text("")),
			new PropertySchema("tint", PropertyType.Color, SceneValue.Color(0xffffffff)),
			new PropertySchema("regionX", PropertyType.Number(), SceneValue.Number(0)),
			new PropertySchema("regionY", PropertyType.Number(), SceneValue.Number(0)),
			new PropertySchema("regionWidth", PropertyType.Number(), SceneValue.Number(0)),
			new PropertySchema("regionHeight", PropertyType.Number(), SceneValue.Number(0)),
			new PropertySchema("spriteWidth", PropertyType.Number(0), SceneValue.Number(1)),
			new PropertySchema("spriteHeight", PropertyType.Number(0), SceneValue.Number(1)),
			new PropertySchema("pivotX", PropertyType.Number(), SceneValue.Number(0.5)),
			new PropertySchema("pivotY", PropertyType.Number(), SceneValue.Number(0.5)),
			new PropertySchema("facing", PropertyType.Text, SceneValue.Text("camera")),
			new PropertySchema("alphaMode", PropertyType.Text, SceneValue.Text("blend")),
			new PropertySchema("alphaCutoff", PropertyType.Number(0, 1), SceneValue.Number(0.5))
		]),
		new KindSchema("Text3D", [
			new PropertySchema("text", PropertyType.Text, SceneValue.Text("")),
			new PropertySchema("textSize", PropertyType.Number(1e-6), SceneValue.Number(0.5)),
			new PropertySchema("color", PropertyType.Color, SceneValue.Color(0xffffffff)),
			new PropertySchema("font", PropertyType.Text, SceneValue.Text("")),
			new PropertySchema("pivotX", PropertyType.Number(), SceneValue.Number(0.5)),
			new PropertySchema("pivotY", PropertyType.Number(), SceneValue.Number(0.5)),
			new PropertySchema("facing", PropertyType.Text, SceneValue.Text("camera"))
		]),
		new KindSchema("Particles3D", [])
	];

	/** What the stage's "tonemap" may say: Tonemap's cases in lower case, in its order, so the index of a name is the case's value. */
	public static final tonemaps = ["none", "neutral", "aces"];

	/** The table of the kind named name (as the file's "kind" has it), or null for a kind the file can't hold. */
	public static function kind(name:String):Null<KindSchema> {
		for (kind in kinds)
			if (kind.name == name)
				return kind;
		return null;
	}

	/** The property named name on whichever kind has it first, or null for a name no kind has: for an override, whose node's kind is the
		model's or the prefab's to know, not the file's. A name means one type wherever it is (color is a color on a light and on text). */
	public static function property(name:String):Null<PropertySchema> {
		for (kind in kinds) {
			var found = kind.property(name);
			if (found != null)
				return found;
		}
		return null;
	}

	// What every light writes (Light's properties), a fresh table each time, as each kind's table is its own.
	static function light():Array<PropertySchema>
		return [
			new PropertySchema("color", PropertyType.Color, SceneValue.Color(0xffffffff)),
			new PropertySchema("intensity", PropertyType.Number(0), SceneValue.Number(1)),
			new PropertySchema("shadowCasting", PropertyType.Flag, SceneValue.Flag(false)),
			new PropertySchema("shadowDistance", PropertyType.Number(1e-6), SceneValue.Number(50)),
			new PropertySchema("shadowMapSize", PropertyType.Number(256, 4096), SceneValue.Number(2048)),
			new PropertySchema("shadowStrength", PropertyType.Number(0, 1), SceneValue.Number(1)),
			new PropertySchema("shadowColor", PropertyType.Color, SceneValue.Color(0x000000ff))
		];

	// A point light's and a spot's range: 0 for unlimited.
	static function range():PropertySchema
		return new PropertySchema("range", PropertyType.Number(0), SceneValue.Number(0));
}
