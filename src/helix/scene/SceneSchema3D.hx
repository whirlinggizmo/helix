package helix.scene;

import helix.scene.KindSchema;

/** One argument of a mesh generator (Mesh3D.plane's width, Mesh3D.sphere's rings): its name as the generator's parameter is named, and the
	generator's default, null for one it requires. A count (rings, segments, subdivisions) is a whole number; a file's number is rounded
	toward zero for it. */
class ArgumentSchema3D {
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

/** One shape a Model3D's "mesh" can name: Mesh3D's generator of that name and its arguments in the generator's order, the required ones
	first. */
class ShapeSchema3D {
	/** The generator's name: plane, cube, sphere, cylinder, cone, capsule or torus. */
	public final name:String;

	/** Its arguments in the generator's order, which the writer keeps. */
	public final arguments:Array<ArgumentSchema3D>;

	/** A shape name taking arguments. */
	public function new(name:String, arguments:Array<ArgumentSchema3D>) {
		this.name = name;
		this.arguments = arguments;
	}

	/** Its argument named name, or null for one it hasn't. */
	public function argument(name:String):Null<ArgumentSchema3D> {
		for (argument in arguments)
			if (argument.name == name)
				return argument;
		return null;
	}
}

/** The kinds a .scene3d file's nodes can be and what each writes flat beside its name and transform: one table per kind, the one place that
	says it, so the parser checks keys and shapes against it, the writer writes in its order leaving defaults out, and an inspector reads its
	controls from it; nothing can be written that can't be read. The names are the classes' own (helix.render3d), the defaults what each class
	starts with. A kind without properties (Node3D, a group; Particles3D, whose emitter is set in code) is still a kind. Beside the kinds, the
	shapes a Model3D's "mesh" can name (shapes): Mesh3D's generators with their arguments and defaults. */
class SceneSchema3D {
	/** Every kind's table, in the order the writer takes an override's properties (a node's own kind orders its own). */
	public static var kinds(default, null):Array<KindSchema> = [
		new KindSchema("Node3D", []),
		new KindSchema("Model3D",
			[
				new PropertySchema("tint", PropertyType.Color, SceneValue.Color(0xffffffff)),
				new PropertySchema("shadowCasting", PropertyType.Flag, SceneValue.Flag(true)),
				new PropertySchema("shadowReceiving", PropertyType.Flag, SceneValue.Flag(true))
			]),
		new KindSchema("DirectionalLight3D", light().concat(shadows())),
		new KindSchema("PointLight3D", light().concat([range()])),
		new KindSchema("SpotLight3D", light().concat(shadows()).concat([
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

	/** The shapes a Model3D's "mesh" can name, one table per generator of Mesh3D with its arguments in the generator's order and the generator's
		defaults: the parser checks a mesh's keys against it, the writer writes them in its order leaving defaults out, and SceneKinds3D calls the
		generator from it. */
	public static var shapes(default, null):Array<ShapeSchema3D> = [
		new ShapeSchema3D("plane", [
			new ArgumentSchema3D("width"),
			new ArgumentSchema3D("length"),
			new ArgumentSchema3D("subdivisions", 0)
		]),
		new ShapeSchema3D("cube", [
			new ArgumentSchema3D("width"),
			new ArgumentSchema3D("height"),
			new ArgumentSchema3D("length")
		]),
		new ShapeSchema3D("sphere", [
			new ArgumentSchema3D("radius"),
			new ArgumentSchema3D("rings", 16),
			new ArgumentSchema3D("segments", 32)
		]),
		new ShapeSchema3D("cylinder", [
			new ArgumentSchema3D("radius"),
			new ArgumentSchema3D("height"),
			new ArgumentSchema3D("segments", 32)
		]),
		new ShapeSchema3D("cone", [
			new ArgumentSchema3D("radius"),
			new ArgumentSchema3D("height"),
			new ArgumentSchema3D("segments", 32)
		]),
		new ShapeSchema3D("capsule", [
			new ArgumentSchema3D("radius"),
			new ArgumentSchema3D("height"),
			new ArgumentSchema3D("rings", 16),
			new ArgumentSchema3D("segments", 32)
		]),
		new ShapeSchema3D("torus", [
			new ArgumentSchema3D("radius"),
			new ArgumentSchema3D("thickness"),
			new ArgumentSchema3D("rings", 32),
			new ArgumentSchema3D("segments", 16)
		])
	];

	/** What a camera's "projection" may say: Projection3D's cases in lower case, in its order, so the index of a name is the case's value. */
	public static final projections = ["perspective", "orthographic"];

	/** The table of the kind named name (as the file's "kind" has it), or null for a kind the file can't hold. */
	public static function kind(name:String):Null<KindSchema> {
		for (kind in kinds)
			if (kind.name == name)
				return kind;
		return null;
	}

	/** The table of the shape named name (as a mesh's "shape" has it), or null for a shape no generator makes. */
	public static function shape(name:String):Null<ShapeSchema3D> {
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

	// What every light writes (Light3D's color and intensity), a fresh table each time, as each kind's table is its own.
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
			new PropertySchema("shadowColor", PropertyType.Color, SceneValue.Color(0xff000000))
		];

	// A point light's and a spot's range: 0 for unlimited.
	static function range():PropertySchema
		return new PropertySchema("range", PropertyType.Number(0), SceneValue.Number(0));
}
