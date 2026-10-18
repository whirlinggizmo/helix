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

/** One kind's table: its name, as the file's "kind" names the class, its properties in the order the writer writes them, and what the class
	starts its flags at (an unsaid flag in a file means the kind's own default, and a flag at it isn't written). */
class KindSchema {
	/** The class's name: Model, DirectionalLight, Camera3D. */
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

/** One argument of a mesh generator (Mesh.plane's width, Mesh.sphere's rings): its name as the generator's parameter is named, and the
	generator's default, null for one it requires. A count (rings, segments, subdivisions) is a whole number; a file's number is rounded
	toward zero for it. */
class ArgumentSchema {
	/** Its name, as the generator names the parameter (width, radius, segments). */
	public final name:String;

	/** The generator's default, which the writer leaves out of the file; null for an argument the generator requires. */
	public final defaultValue:Null<Float>;

	/** An argument name, with the generator's default or none. */
	public function new(name:String, ?defaultValue:Float) {
		this.name = name;
		this.defaultValue = defaultValue;
	}

	/** Whether the generator requires it: a file leaving it out is refused. */
	public var required(get, never):Bool;

	function get_required():Bool
		return defaultValue == null;
}

/** One shape a Model's "mesh" can name: Mesh's generator of that name and its arguments in the generator's order, the required ones
	first. */
class ShapeSchema {
	/** The generator's name: plane, cube, sphere, cylinder, cone, capsule or torus. */
	public final name:String;

	/** Its arguments in the generator's order, which the writer keeps. */
	public final arguments:Array<ArgumentSchema>;

	/** A shape name taking arguments. */
	public function new(name:String, arguments:Array<ArgumentSchema>) {
		this.name = name;
		this.arguments = arguments;
	}

	/** Its argument named name, or null for one it hasn't. */
	public function argument(name:String):Null<ArgumentSchema> {
		for (argument in arguments)
			if (argument.name == name)
				return argument;
		return null;
	}
}

/** The kinds a .scene file's nodes can be and what each writes flat beside its name and transform: one table per kind, the one place that
	says it, so the parser checks keys and shapes against it, the writer writes in its order leaving defaults out, and an inspector reads its
	controls from it; nothing can be written that can't be read. The names are the classes' own (helix.render3d), the defaults what each class
	starts with. A kind without properties (Node3D, a group; Particles3D, whose emitter is set in code) is still a kind. Beside the kinds, the
	shapes a Model's "mesh" can name (shapes): Mesh's generators with their arguments and defaults. */
class SceneSchema {
	/** Every kind's table, in the order the writer takes an override's properties (a node's own kind orders its own). */
	public static var kinds(default, null):Array<KindSchema> = [
		new KindSchema("Node3D", []),
		new KindSchema("Model",
			[
				new PropertySchema("tint", PropertyType.Color, SceneValue.Color(0xffffffff)),
				new PropertySchema("shadowCasting", PropertyType.Flag, SceneValue.Flag(true)),
				new PropertySchema("shadowReceiving", PropertyType.Flag, SceneValue.Flag(true))
			]),
		new KindSchema("DirectionalLight", light().concat(shadows())),
		new KindSchema("PointLight", light().concat([range()])),
		new KindSchema("SpotLight", light().concat(shadows()).concat([
			range(),
			new PropertySchema("innerCone", PropertyType.Number(0, Math.PI / 2), SceneValue.Number(0.3)),
			new PropertySchema("outerCone", PropertyType.Number(0, Math.PI / 2), SceneValue.Number(0.4))
		])),
		new KindSchema("Camera3D", [
			new PropertySchema("projection", PropertyType.Text, SceneValue.Text("perspective")),
			new PropertySchema("fovY", PropertyType.Number(0.001, Math.PI - 0.001), SceneValue.Number(Math.PI / 4)),
			new PropertySchema("near", PropertyType.Number(), SceneValue.Number(0.1)),
			new PropertySchema("far", PropertyType.Number(), SceneValue.Number(1000)),
			new PropertySchema("orthographicHeight", PropertyType.Number(1e-6), SceneValue.Number(10)),
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
		], true, true, false),
		new KindSchema("Particles3D", [])
	];

	/** The shapes a Model's "mesh" can name, one table per generator of Mesh with its arguments in the generator's order and the generator's
		defaults: the parser checks a mesh's keys against it, the writer writes them in its order leaving defaults out, and SceneKinds calls the
		generator from it. */
	public static var shapes(default, null):Array<ShapeSchema> = [
		new ShapeSchema("plane", [
			new ArgumentSchema("width"),
			new ArgumentSchema("length"),
			new ArgumentSchema("subdivisions", 0)
		]),
		new ShapeSchema("cube", [
			new ArgumentSchema("width"),
			new ArgumentSchema("height"),
			new ArgumentSchema("length")
		]),
		new ShapeSchema("sphere", [
			new ArgumentSchema("radius"),
			new ArgumentSchema("rings", 16),
			new ArgumentSchema("segments", 32)
		]),
		new ShapeSchema("cylinder", [
			new ArgumentSchema("radius"),
			new ArgumentSchema("height"),
			new ArgumentSchema("segments", 32)
		]),
		new ShapeSchema("cone", [
			new ArgumentSchema("radius"),
			new ArgumentSchema("height"),
			new ArgumentSchema("segments", 32)
		]),
		new ShapeSchema("capsule", [
			new ArgumentSchema("radius"),
			new ArgumentSchema("height"),
			new ArgumentSchema("rings", 16),
			new ArgumentSchema("segments", 32)
		]),
		new ShapeSchema("torus", [
			new ArgumentSchema("radius"),
			new ArgumentSchema("thickness"),
			new ArgumentSchema("rings", 32),
			new ArgumentSchema("segments", 16)
		])
	];

	/** What the stage's "tonemap" may say: Tonemap's cases in lower case, in its order, so the index of a name is the case's value. */
	public static final tonemaps = ["none", "neutral", "aces"];

	/** What a camera's "projection" may say: Projection's cases in lower case, in its order, so the index of a name is the case's value. */
	public static final projections = ["perspective", "orthographic"];

	/** The table of the kind named name (as the file's "kind" has it), or null for a kind the file can't hold. */
	public static function kind(name:String):Null<KindSchema> {
		for (kind in kinds)
			if (kind.name == name)
				return kind;
		return null;
	}

	/** The table of the shape named name (as a mesh's "shape" has it), or null for a shape no generator makes. */
	public static function shape(name:String):Null<ShapeSchema> {
		for (shape in shapes)
			if (shape.name == name)
				return shape;
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

	// What every light writes (Light's color and intensity), a fresh table each time, as each kind's table is its own.
	static function light():Array<PropertySchema>
		return [
			new PropertySchema("color", PropertyType.Color, SceneValue.Color(0xffffffff)),
			new PropertySchema("intensity", PropertyType.Number(0), SceneValue.Number(1))
		];

	// What a light that can cast shadows writes (a directional light or a spot; a point light casts none, so its table has none of these).
	static function shadows():Array<PropertySchema>
		return [
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
