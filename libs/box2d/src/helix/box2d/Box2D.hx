package helix.box2d;

/** Provides Box2D 3.2: loading the module, Box2D's functions under their C names, and its constants.

	A program loads the module once, then calls Box2D as C does:

	```haxe
	import helix.box2d.*;
	import helix.box2d.Box2D.*;

	Box2D.loadAsync(() -> {
		var worldDef = b2DefaultWorldDef();
		worldDef.gravity = new B2Vec2(0, -10);
		var worldId = b2CreateWorld(worldDef);

		var bodyDef = b2DefaultBodyDef();
		bodyDef.type = b2_dynamicBody;
		bodyDef.position = new B2Vec2(0, 4);
		var bodyId = b2CreateBody(worldId, bodyDef);
		b2CreatePolygonShape(bodyId, b2DefaultShapeDef(), b2MakeBox(1, 1));

		for (i in 0...90)
			b2World_Step(worldId, 1 / 60, 4);
	});
	```

	Natively, Box2D is compiled into the program, and `loadAsync` calls `loaded` before returning. In a page, `loadAsync` fetches the
	module (`box2d.wasm`) and calls `loaded` once the module runs.

	The build of Box2D the module holds is single precision and cross-platform deterministic: the same steps from the same state
	produce the same bits natively and in a page.

	Box2D's types are Haxe types named as Box2D names them with a capital first letter (`b2BodyDef` is `B2BodyDef`), as Haxe requires;
	functions, fields, enum values and constants keep Box2D's names. A struct Box2D passes by value is a Haxe object, which the garbage
	collector frees; a function returning one accepts an optional `out` that receives the result. What Box2D holds (a world, a body,
	a shape, a joint, a chain) is reached by its id and lives in the module until it is destroyed.

	A def from its `b2Default` function, or from its constructor, holds Box2D's defaults, with the structs it holds already made
	(`def.base.localFrameA.p`, `shapeDef.material.friction`), so their fields are set directly. An `out` is filled in place, and an
	array a call fills reuses the elements it holds and grows as needed, so a step's reads allocate nothing when each is passed the same one. */
class Box2D {
	#if !macro
	/** Asynchronously loads the module.

		Calling it again after the module has loaded calls `loaded` again.

		_Note that in a page the module is `box2d.wasm` beside the page unless `wasmUrl` names another. The build copies it there with
		a line in the build's hxml:_

		```hxml
		--macro helix.box2d.Box2D.copyWasm("web")
		```

		@param loaded  Called once the module is ready.
		@param failed  Optional. Receives why the module couldn't be loaded; when omitted, it is thrown.
		@param wasmUrl  Optional. In a page, the module's URL; defaults to `box2d.wasm`. Ignored natively. */
	public static function loadAsync(loaded:Void->Void, ?failed:String->Void, ?wasmUrl:String):Void {
		throw "not built yet";
	}

	/** For small objects the margin is limited to this fraction times the maximum extent. */
	public static inline final B2_AABB_MARGIN_FRACTION = 0.125;

	/** The default contact recycling world angle threshold: 0.98, about 11.5 degrees. */
	public static inline final B2_CONTACT_RECYCLE_COS_ANGLE = 0.98;

	/** The default contact recycling distance: 10 times `B2_LINEAR_SLOP`. */
	public static var B2_CONTACT_RECYCLE_DISTANCE(get, never):Float;

	/** The default category bits of a shape's filter: 1. */
	public static var B2_DEFAULT_CATEGORY_BITS(get, never):haxe.Int64;

	/** The default mask bits of a shape's filter: every bit set. */
	public static var B2_DEFAULT_MASK_BITS(get, never):haxe.Int64;

	/** The number of graph colors the solver uses. */
	public static inline final B2_GRAPH_COLOR_COUNT = 24;

	/** The value `b2Hash` starts from. */
	public static inline final B2_HASH_INIT = 5381;

	/** Used to detect bad values: 100 kilometers in length units. */
	public static var B2_HUGE(get, never):Float;

	/** A small length used as a collision and constraint tolerance: 0.005 meters in length units. */
	public static var B2_LINEAR_SLOP(get, never):Float;

	/** The maximum margin of a shape's bounding box: 0.05 meters in length units. */
	public static var B2_MAX_AABB_MARGIN(get, never):Float;

	/** The maximum number of vertices on a convex polygon. */
	public static inline final B2_MAX_POLYGON_VERTICES = 8;

	/** The maximum number of restitution iterations. */
	public static inline final B2_MAX_RESTITUTION_ITERATIONS = 63;

	/** The maximum rotation of a body in one step, in radians: a quarter of `B2_PI`. */
	public static inline final B2_MAX_ROTATION = 0.25 * B2_PI;

	/** The maximum number of tasks in a step. */
	public static inline final B2_MAX_TASKS = 256;

	/** The maximum number of workers. */
	public static inline final B2_MAX_WORKERS = 32;

	/** The maximum number of worlds at once. */
	public static inline final B2_MAX_WORLDS = 128;

	/** The longest body name kept, in characters. */
	public static inline final B2_NAME_LENGTH = 10;

	/** The index that stands for none. */
	public static inline final B2_NULL_INDEX = -1;

	/** Pi, as Box2D uses it. */
	public static inline final B2_PI = 3.14159265359;

	/** The distance at which contacts are made ahead of touching: 4 times `B2_LINEAR_SLOP`. */
	public static var B2_SPECULATIVE_DISTANCE(get, never):Float;

	/** The time a body must be still before it sleeps, in seconds. */
	public static inline final B2_TIME_TO_SLEEP = 0.5;

	/** Box2D's major version. */
	public static inline final B2_VERSION_MAJOR = 3;

	/** Box2D's minor version. */
	public static inline final B2_VERSION_MINOR = 2;

	/** Box2D's revision. */
	public static inline final B2_VERSION_REVISION = 0;

	/** Whether an id is null.

		@param id  A world, body, shape, joint, chain or contact id.
		@return  Whether it is null. */
	public static function B2_IS_NULL(id:{index1:Int}):Bool {
		throw "not built yet";
	}

	/** Whether an id isn't null.

		@param id  A world, body, shape, joint, chain or contact id.
		@return  Whether it isn't null. */
	public static function B2_IS_NON_NULL(id:{index1:Int}):Bool {
		throw "not built yet";
	}

	/** Whether two ids of one kind are the same.

		@param id1  An id.
		@param id2  Another id of the same kind.
		@return  Whether they are the same. */
	public static function B2_ID_EQUALS(id1:{index1:Int, world0:Int, generation:Int}, id2:{index1:Int, world0:Int, generation:Int}):Bool {
		throw "not built yet";
	}

	/** A 2x2 matrix of zeros, new each time it is read. */
	public static var b2Mat22_zero(get, never):B2Mat22;

	/** The position (0, 0), new each time it is read. */
	public static var b2Pos_zero(get, never):B2Pos;

	/** The rotation that turns nothing, new each time it is read. */
	public static var b2Rot_identity(get, never):B2Rot;

	/** The transform that moves and turns nothing, new each time it is read. */
	public static var b2Transform_identity(get, never):B2Transform;

	/** The vector (0, 0), new each time it is read. */
	public static var b2Vec2_zero(get, never):B2Vec2;

	/** The world transform that moves and turns nothing, new each time it is read. */
	public static var b2WorldTransform_identity(get, never):B2WorldTransform;

	/** An empty simplex cache, for a first call of `b2ComputeShapeDistance`, new each time it is read. */
	public static var b2_emptySimplexCache(get, never):B2SimplexCache;

	/** The length units per meter, which `b2SetLengthUnitsPerMeter` sets. */
	public static var b2_lengthUnitsPerMeter(get, never):Float;

	/** The null world id, new each time it is read. */
	public static var b2_nullWorldId(get, never):B2WorldId;

	/** The null body id, new each time it is read. */
	public static var b2_nullBodyId(get, never):B2BodyId;

	/** The null shape id, new each time it is read. */
	public static var b2_nullShapeId(get, never):B2ShapeId;

	/** The null chain id, new each time it is read. */
	public static var b2_nullChainId(get, never):B2ChainId;

	/** The null joint id, new each time it is read. */
	public static var b2_nullJointId(get, never):B2JointId;

	/** The null contact id, new each time it is read. */
	public static var b2_nullContactId(get, never):B2ContactId;

	static function get_B2_CONTACT_RECYCLE_DISTANCE():Float
		throw "not built yet";

	static function get_B2_DEFAULT_CATEGORY_BITS():haxe.Int64
		throw "not built yet";

	static function get_B2_DEFAULT_MASK_BITS():haxe.Int64
		throw "not built yet";

	static function get_B2_HUGE():Float
		throw "not built yet";

	static function get_B2_LINEAR_SLOP():Float
		throw "not built yet";

	static function get_B2_MAX_AABB_MARGIN():Float
		throw "not built yet";

	static function get_B2_SPECULATIVE_DISTANCE():Float
		throw "not built yet";

	static function get_b2Mat22_zero():B2Mat22
		throw "not built yet";

	static function get_b2Pos_zero():B2Pos
		throw "not built yet";

	static function get_b2Rot_identity():B2Rot
		throw "not built yet";

	static function get_b2Transform_identity():B2Transform
		throw "not built yet";

	static function get_b2Vec2_zero():B2Vec2
		throw "not built yet";

	static function get_b2WorldTransform_identity():B2WorldTransform
		throw "not built yet";

	static function get_b2_emptySimplexCache():B2SimplexCache
		throw "not built yet";

	static function get_b2_lengthUnitsPerMeter():Float
		throw "not built yet";

	static function get_b2_nullWorldId():B2WorldId
		throw "not built yet";

	static function get_b2_nullBodyId():B2BodyId
		throw "not built yet";

	static function get_b2_nullShapeId():B2ShapeId
		throw "not built yet";

	static function get_b2_nullChainId():B2ChainId
		throw "not built yet";

	static function get_b2_nullJointId():B2JointId
		throw "not built yet";

	static function get_b2_nullContactId():B2ContactId
		throw "not built yet";

	/** The `B2BodyType` value b2_staticBody: Zero mass, zero velocity, may be manually moved. */
	public static inline final b2_staticBody:B2BodyType = B2BodyType.b2_staticBody;

	/** The `B2BodyType` value b2_kinematicBody: Zero mass, velocity set by user, moved by solver. */
	public static inline final b2_kinematicBody:B2BodyType = B2BodyType.b2_kinematicBody;

	/** The `B2BodyType` value b2_dynamicBody: Positive mass, velocity determined by forces, moved by solver. */
	public static inline final b2_dynamicBody:B2BodyType = B2BodyType.b2_dynamicBody;

	/** The `B2BodyType` value b2_bodyTypeCount: Number of body types. */
	public static inline final b2_bodyTypeCount:B2BodyType = B2BodyType.b2_bodyTypeCount;

	/** The `B2HexColor` value b2_colorAliceBlue: The SVG color alice blue, 0xF0F8FF. */
	public static inline final b2_colorAliceBlue:B2HexColor = B2HexColor.b2_colorAliceBlue;

	/** The `B2HexColor` value b2_colorAntiqueWhite: The SVG color antique white, 0xFAEBD7. */
	public static inline final b2_colorAntiqueWhite:B2HexColor = B2HexColor.b2_colorAntiqueWhite;

	/** The `B2HexColor` value b2_colorAqua: The SVG color aqua, 0x00FFFF. */
	public static inline final b2_colorAqua:B2HexColor = B2HexColor.b2_colorAqua;

	/** The `B2HexColor` value b2_colorAquamarine: The SVG color aquamarine, 0x7FFFD4. */
	public static inline final b2_colorAquamarine:B2HexColor = B2HexColor.b2_colorAquamarine;

	/** The `B2HexColor` value b2_colorAzure: The SVG color azure, 0xF0FFFF. */
	public static inline final b2_colorAzure:B2HexColor = B2HexColor.b2_colorAzure;

	/** The `B2HexColor` value b2_colorBeige: The SVG color beige, 0xF5F5DC. */
	public static inline final b2_colorBeige:B2HexColor = B2HexColor.b2_colorBeige;

	/** The `B2HexColor` value b2_colorBisque: The SVG color bisque, 0xFFE4C4. */
	public static inline final b2_colorBisque:B2HexColor = B2HexColor.b2_colorBisque;

	/** The `B2HexColor` value b2_colorBlack: The SVG color black, 0x000000. */
	public static inline final b2_colorBlack:B2HexColor = B2HexColor.b2_colorBlack;

	/** The `B2HexColor` value b2_colorBlanchedAlmond: The SVG color blanched almond, 0xFFEBCD. */
	public static inline final b2_colorBlanchedAlmond:B2HexColor = B2HexColor.b2_colorBlanchedAlmond;

	/** The `B2HexColor` value b2_colorBlue: The SVG color blue, 0x0000FF. */
	public static inline final b2_colorBlue:B2HexColor = B2HexColor.b2_colorBlue;

	/** The `B2HexColor` value b2_colorBlueViolet: The SVG color blue violet, 0x8A2BE2. */
	public static inline final b2_colorBlueViolet:B2HexColor = B2HexColor.b2_colorBlueViolet;

	/** The `B2HexColor` value b2_colorBrown: The SVG color brown, 0xA52A2A. */
	public static inline final b2_colorBrown:B2HexColor = B2HexColor.b2_colorBrown;

	/** The `B2HexColor` value b2_colorBurlywood: The SVG color burlywood, 0xDEB887. */
	public static inline final b2_colorBurlywood:B2HexColor = B2HexColor.b2_colorBurlywood;

	/** The `B2HexColor` value b2_colorCadetBlue: The SVG color cadet blue, 0x5F9EA0. */
	public static inline final b2_colorCadetBlue:B2HexColor = B2HexColor.b2_colorCadetBlue;

	/** The `B2HexColor` value b2_colorChartreuse: The SVG color chartreuse, 0x7FFF00. */
	public static inline final b2_colorChartreuse:B2HexColor = B2HexColor.b2_colorChartreuse;

	/** The `B2HexColor` value b2_colorChocolate: The SVG color chocolate, 0xD2691E. */
	public static inline final b2_colorChocolate:B2HexColor = B2HexColor.b2_colorChocolate;

	/** The `B2HexColor` value b2_colorCoral: The SVG color coral, 0xFF7F50. */
	public static inline final b2_colorCoral:B2HexColor = B2HexColor.b2_colorCoral;

	/** The `B2HexColor` value b2_colorCornflowerBlue: The SVG color cornflower blue, 0x6495ED. */
	public static inline final b2_colorCornflowerBlue:B2HexColor = B2HexColor.b2_colorCornflowerBlue;

	/** The `B2HexColor` value b2_colorCornsilk: The SVG color cornsilk, 0xFFF8DC. */
	public static inline final b2_colorCornsilk:B2HexColor = B2HexColor.b2_colorCornsilk;

	/** The `B2HexColor` value b2_colorCrimson: The SVG color crimson, 0xDC143C. */
	public static inline final b2_colorCrimson:B2HexColor = B2HexColor.b2_colorCrimson;

	/** The `B2HexColor` value b2_colorCyan: The SVG color cyan, 0x00FFFF. */
	public static inline final b2_colorCyan:B2HexColor = B2HexColor.b2_colorCyan;

	/** The `B2HexColor` value b2_colorDarkBlue: The SVG color dark blue, 0x00008B. */
	public static inline final b2_colorDarkBlue:B2HexColor = B2HexColor.b2_colorDarkBlue;

	/** The `B2HexColor` value b2_colorDarkCyan: The SVG color dark cyan, 0x008B8B. */
	public static inline final b2_colorDarkCyan:B2HexColor = B2HexColor.b2_colorDarkCyan;

	/** The `B2HexColor` value b2_colorDarkGoldenRod: The SVG color dark golden rod, 0xB8860B. */
	public static inline final b2_colorDarkGoldenRod:B2HexColor = B2HexColor.b2_colorDarkGoldenRod;

	/** The `B2HexColor` value b2_colorDarkGray: The SVG color dark gray, 0xA9A9A9. */
	public static inline final b2_colorDarkGray:B2HexColor = B2HexColor.b2_colorDarkGray;

	/** The `B2HexColor` value b2_colorDarkGreen: The SVG color dark green, 0x006400. */
	public static inline final b2_colorDarkGreen:B2HexColor = B2HexColor.b2_colorDarkGreen;

	/** The `B2HexColor` value b2_colorDarkKhaki: The SVG color dark khaki, 0xBDB76B. */
	public static inline final b2_colorDarkKhaki:B2HexColor = B2HexColor.b2_colorDarkKhaki;

	/** The `B2HexColor` value b2_colorDarkMagenta: The SVG color dark magenta, 0x8B008B. */
	public static inline final b2_colorDarkMagenta:B2HexColor = B2HexColor.b2_colorDarkMagenta;

	/** The `B2HexColor` value b2_colorDarkOliveGreen: The SVG color dark olive green, 0x556B2F. */
	public static inline final b2_colorDarkOliveGreen:B2HexColor = B2HexColor.b2_colorDarkOliveGreen;

	/** The `B2HexColor` value b2_colorDarkOrange: The SVG color dark orange, 0xFF8C00. */
	public static inline final b2_colorDarkOrange:B2HexColor = B2HexColor.b2_colorDarkOrange;

	/** The `B2HexColor` value b2_colorDarkOrchid: The SVG color dark orchid, 0x9932CC. */
	public static inline final b2_colorDarkOrchid:B2HexColor = B2HexColor.b2_colorDarkOrchid;

	/** The `B2HexColor` value b2_colorDarkRed: The SVG color dark red, 0x8B0000. */
	public static inline final b2_colorDarkRed:B2HexColor = B2HexColor.b2_colorDarkRed;

	/** The `B2HexColor` value b2_colorDarkSalmon: The SVG color dark salmon, 0xE9967A. */
	public static inline final b2_colorDarkSalmon:B2HexColor = B2HexColor.b2_colorDarkSalmon;

	/** The `B2HexColor` value b2_colorDarkSeaGreen: The SVG color dark sea green, 0x8FBC8F. */
	public static inline final b2_colorDarkSeaGreen:B2HexColor = B2HexColor.b2_colorDarkSeaGreen;

	/** The `B2HexColor` value b2_colorDarkSlateBlue: The SVG color dark slate blue, 0x483D8B. */
	public static inline final b2_colorDarkSlateBlue:B2HexColor = B2HexColor.b2_colorDarkSlateBlue;

	/** The `B2HexColor` value b2_colorDarkSlateGray: The SVG color dark slate gray, 0x2F4F4F. */
	public static inline final b2_colorDarkSlateGray:B2HexColor = B2HexColor.b2_colorDarkSlateGray;

	/** The `B2HexColor` value b2_colorDarkTurquoise: The SVG color dark turquoise, 0x00CED1. */
	public static inline final b2_colorDarkTurquoise:B2HexColor = B2HexColor.b2_colorDarkTurquoise;

	/** The `B2HexColor` value b2_colorDarkViolet: The SVG color dark violet, 0x9400D3. */
	public static inline final b2_colorDarkViolet:B2HexColor = B2HexColor.b2_colorDarkViolet;

	/** The `B2HexColor` value b2_colorDeepPink: The SVG color deep pink, 0xFF1493. */
	public static inline final b2_colorDeepPink:B2HexColor = B2HexColor.b2_colorDeepPink;

	/** The `B2HexColor` value b2_colorDeepSkyBlue: The SVG color deep sky blue, 0x00BFFF. */
	public static inline final b2_colorDeepSkyBlue:B2HexColor = B2HexColor.b2_colorDeepSkyBlue;

	/** The `B2HexColor` value b2_colorDimGray: The SVG color dim gray, 0x696969. */
	public static inline final b2_colorDimGray:B2HexColor = B2HexColor.b2_colorDimGray;

	/** The `B2HexColor` value b2_colorDodgerBlue: The SVG color dodger blue, 0x1E90FF. */
	public static inline final b2_colorDodgerBlue:B2HexColor = B2HexColor.b2_colorDodgerBlue;

	/** The `B2HexColor` value b2_colorFireBrick: The SVG color fire brick, 0xB22222. */
	public static inline final b2_colorFireBrick:B2HexColor = B2HexColor.b2_colorFireBrick;

	/** The `B2HexColor` value b2_colorFloralWhite: The SVG color floral white, 0xFFFAF0. */
	public static inline final b2_colorFloralWhite:B2HexColor = B2HexColor.b2_colorFloralWhite;

	/** The `B2HexColor` value b2_colorForestGreen: The SVG color forest green, 0x228B22. */
	public static inline final b2_colorForestGreen:B2HexColor = B2HexColor.b2_colorForestGreen;

	/** The `B2HexColor` value b2_colorFuchsia: The SVG color fuchsia, 0xFF00FF. */
	public static inline final b2_colorFuchsia:B2HexColor = B2HexColor.b2_colorFuchsia;

	/** The `B2HexColor` value b2_colorGainsboro: The SVG color gainsboro, 0xDCDCDC. */
	public static inline final b2_colorGainsboro:B2HexColor = B2HexColor.b2_colorGainsboro;

	/** The `B2HexColor` value b2_colorGhostWhite: The SVG color ghost white, 0xF8F8FF. */
	public static inline final b2_colorGhostWhite:B2HexColor = B2HexColor.b2_colorGhostWhite;

	/** The `B2HexColor` value b2_colorGold: The SVG color gold, 0xFFD700. */
	public static inline final b2_colorGold:B2HexColor = B2HexColor.b2_colorGold;

	/** The `B2HexColor` value b2_colorGoldenRod: The SVG color golden rod, 0xDAA520. */
	public static inline final b2_colorGoldenRod:B2HexColor = B2HexColor.b2_colorGoldenRod;

	/** The `B2HexColor` value b2_colorGray: The SVG color gray, 0x808080. */
	public static inline final b2_colorGray:B2HexColor = B2HexColor.b2_colorGray;

	/** The `B2HexColor` value b2_colorGreen: The SVG color green, 0x008000. */
	public static inline final b2_colorGreen:B2HexColor = B2HexColor.b2_colorGreen;

	/** The `B2HexColor` value b2_colorGreenYellow: The SVG color green yellow, 0xADFF2F. */
	public static inline final b2_colorGreenYellow:B2HexColor = B2HexColor.b2_colorGreenYellow;

	/** The `B2HexColor` value b2_colorHoneyDew: The SVG color honey dew, 0xF0FFF0. */
	public static inline final b2_colorHoneyDew:B2HexColor = B2HexColor.b2_colorHoneyDew;

	/** The `B2HexColor` value b2_colorHotPink: The SVG color hot pink, 0xFF69B4. */
	public static inline final b2_colorHotPink:B2HexColor = B2HexColor.b2_colorHotPink;

	/** The `B2HexColor` value b2_colorIndianRed: The SVG color indian red, 0xCD5C5C. */
	public static inline final b2_colorIndianRed:B2HexColor = B2HexColor.b2_colorIndianRed;

	/** The `B2HexColor` value b2_colorIndigo: The SVG color indigo, 0x4B0082. */
	public static inline final b2_colorIndigo:B2HexColor = B2HexColor.b2_colorIndigo;

	/** The `B2HexColor` value b2_colorIvory: The SVG color ivory, 0xFFFFF0. */
	public static inline final b2_colorIvory:B2HexColor = B2HexColor.b2_colorIvory;

	/** The `B2HexColor` value b2_colorKhaki: The SVG color khaki, 0xF0E68C. */
	public static inline final b2_colorKhaki:B2HexColor = B2HexColor.b2_colorKhaki;

	/** The `B2HexColor` value b2_colorLavender: The SVG color lavender, 0xE6E6FA. */
	public static inline final b2_colorLavender:B2HexColor = B2HexColor.b2_colorLavender;

	/** The `B2HexColor` value b2_colorLavenderBlush: The SVG color lavender blush, 0xFFF0F5. */
	public static inline final b2_colorLavenderBlush:B2HexColor = B2HexColor.b2_colorLavenderBlush;

	/** The `B2HexColor` value b2_colorLawnGreen: The SVG color lawn green, 0x7CFC00. */
	public static inline final b2_colorLawnGreen:B2HexColor = B2HexColor.b2_colorLawnGreen;

	/** The `B2HexColor` value b2_colorLemonChiffon: The SVG color lemon chiffon, 0xFFFACD. */
	public static inline final b2_colorLemonChiffon:B2HexColor = B2HexColor.b2_colorLemonChiffon;

	/** The `B2HexColor` value b2_colorLightBlue: The SVG color light blue, 0xADD8E6. */
	public static inline final b2_colorLightBlue:B2HexColor = B2HexColor.b2_colorLightBlue;

	/** The `B2HexColor` value b2_colorLightCoral: The SVG color light coral, 0xF08080. */
	public static inline final b2_colorLightCoral:B2HexColor = B2HexColor.b2_colorLightCoral;

	/** The `B2HexColor` value b2_colorLightCyan: The SVG color light cyan, 0xE0FFFF. */
	public static inline final b2_colorLightCyan:B2HexColor = B2HexColor.b2_colorLightCyan;

	/** The `B2HexColor` value b2_colorLightGoldenRodYellow: The SVG color light golden rod yellow, 0xFAFAD2. */
	public static inline final b2_colorLightGoldenRodYellow:B2HexColor = B2HexColor.b2_colorLightGoldenRodYellow;

	/** The `B2HexColor` value b2_colorLightGray: The SVG color light gray, 0xD3D3D3. */
	public static inline final b2_colorLightGray:B2HexColor = B2HexColor.b2_colorLightGray;

	/** The `B2HexColor` value b2_colorLightGreen: The SVG color light green, 0x90EE90. */
	public static inline final b2_colorLightGreen:B2HexColor = B2HexColor.b2_colorLightGreen;

	/** The `B2HexColor` value b2_colorLightPink: The SVG color light pink, 0xFFB6C1. */
	public static inline final b2_colorLightPink:B2HexColor = B2HexColor.b2_colorLightPink;

	/** The `B2HexColor` value b2_colorLightSalmon: The SVG color light salmon, 0xFFA07A. */
	public static inline final b2_colorLightSalmon:B2HexColor = B2HexColor.b2_colorLightSalmon;

	/** The `B2HexColor` value b2_colorLightSeaGreen: The SVG color light sea green, 0x20B2AA. */
	public static inline final b2_colorLightSeaGreen:B2HexColor = B2HexColor.b2_colorLightSeaGreen;

	/** The `B2HexColor` value b2_colorLightSkyBlue: The SVG color light sky blue, 0x87CEFA. */
	public static inline final b2_colorLightSkyBlue:B2HexColor = B2HexColor.b2_colorLightSkyBlue;

	/** The `B2HexColor` value b2_colorLightSlateGray: The SVG color light slate gray, 0x778899. */
	public static inline final b2_colorLightSlateGray:B2HexColor = B2HexColor.b2_colorLightSlateGray;

	/** The `B2HexColor` value b2_colorLightSteelBlue: The SVG color light steel blue, 0xB0C4DE. */
	public static inline final b2_colorLightSteelBlue:B2HexColor = B2HexColor.b2_colorLightSteelBlue;

	/** The `B2HexColor` value b2_colorLightYellow: The SVG color light yellow, 0xFFFFE0. */
	public static inline final b2_colorLightYellow:B2HexColor = B2HexColor.b2_colorLightYellow;

	/** The `B2HexColor` value b2_colorLime: The SVG color lime, 0x00FF00. */
	public static inline final b2_colorLime:B2HexColor = B2HexColor.b2_colorLime;

	/** The `B2HexColor` value b2_colorLimeGreen: The SVG color lime green, 0x32CD32. */
	public static inline final b2_colorLimeGreen:B2HexColor = B2HexColor.b2_colorLimeGreen;

	/** The `B2HexColor` value b2_colorLinen: The SVG color linen, 0xFAF0E6. */
	public static inline final b2_colorLinen:B2HexColor = B2HexColor.b2_colorLinen;

	/** The `B2HexColor` value b2_colorMagenta: The SVG color magenta, 0xFF00FF. */
	public static inline final b2_colorMagenta:B2HexColor = B2HexColor.b2_colorMagenta;

	/** The `B2HexColor` value b2_colorMaroon: The SVG color maroon, 0x800000. */
	public static inline final b2_colorMaroon:B2HexColor = B2HexColor.b2_colorMaroon;

	/** The `B2HexColor` value b2_colorMediumAquaMarine: The SVG color medium aqua marine, 0x66CDAA. */
	public static inline final b2_colorMediumAquaMarine:B2HexColor = B2HexColor.b2_colorMediumAquaMarine;

	/** The `B2HexColor` value b2_colorMediumBlue: The SVG color medium blue, 0x0000CD. */
	public static inline final b2_colorMediumBlue:B2HexColor = B2HexColor.b2_colorMediumBlue;

	/** The `B2HexColor` value b2_colorMediumOrchid: The SVG color medium orchid, 0xBA55D3. */
	public static inline final b2_colorMediumOrchid:B2HexColor = B2HexColor.b2_colorMediumOrchid;

	/** The `B2HexColor` value b2_colorMediumPurple: The SVG color medium purple, 0x9370DB. */
	public static inline final b2_colorMediumPurple:B2HexColor = B2HexColor.b2_colorMediumPurple;

	/** The `B2HexColor` value b2_colorMediumSeaGreen: The SVG color medium sea green, 0x3CB371. */
	public static inline final b2_colorMediumSeaGreen:B2HexColor = B2HexColor.b2_colorMediumSeaGreen;

	/** The `B2HexColor` value b2_colorMediumSlateBlue: The SVG color medium slate blue, 0x7B68EE. */
	public static inline final b2_colorMediumSlateBlue:B2HexColor = B2HexColor.b2_colorMediumSlateBlue;

	/** The `B2HexColor` value b2_colorMediumSpringGreen: The SVG color medium spring green, 0x00FA9A. */
	public static inline final b2_colorMediumSpringGreen:B2HexColor = B2HexColor.b2_colorMediumSpringGreen;

	/** The `B2HexColor` value b2_colorMediumTurquoise: The SVG color medium turquoise, 0x48D1CC. */
	public static inline final b2_colorMediumTurquoise:B2HexColor = B2HexColor.b2_colorMediumTurquoise;

	/** The `B2HexColor` value b2_colorMediumVioletRed: The SVG color medium violet red, 0xC71585. */
	public static inline final b2_colorMediumVioletRed:B2HexColor = B2HexColor.b2_colorMediumVioletRed;

	/** The `B2HexColor` value b2_colorMidnightBlue: The SVG color midnight blue, 0x191970. */
	public static inline final b2_colorMidnightBlue:B2HexColor = B2HexColor.b2_colorMidnightBlue;

	/** The `B2HexColor` value b2_colorMintCream: The SVG color mint cream, 0xF5FFFA. */
	public static inline final b2_colorMintCream:B2HexColor = B2HexColor.b2_colorMintCream;

	/** The `B2HexColor` value b2_colorMistyRose: The SVG color misty rose, 0xFFE4E1. */
	public static inline final b2_colorMistyRose:B2HexColor = B2HexColor.b2_colorMistyRose;

	/** The `B2HexColor` value b2_colorMoccasin: The SVG color moccasin, 0xFFE4B5. */
	public static inline final b2_colorMoccasin:B2HexColor = B2HexColor.b2_colorMoccasin;

	/** The `B2HexColor` value b2_colorNavajoWhite: The SVG color navajo white, 0xFFDEAD. */
	public static inline final b2_colorNavajoWhite:B2HexColor = B2HexColor.b2_colorNavajoWhite;

	/** The `B2HexColor` value b2_colorNavy: The SVG color navy, 0x000080. */
	public static inline final b2_colorNavy:B2HexColor = B2HexColor.b2_colorNavy;

	/** The `B2HexColor` value b2_colorOldLace: The SVG color old lace, 0xFDF5E6. */
	public static inline final b2_colorOldLace:B2HexColor = B2HexColor.b2_colorOldLace;

	/** The `B2HexColor` value b2_colorOlive: The SVG color olive, 0x808000. */
	public static inline final b2_colorOlive:B2HexColor = B2HexColor.b2_colorOlive;

	/** The `B2HexColor` value b2_colorOliveDrab: The SVG color olive drab, 0x6B8E23. */
	public static inline final b2_colorOliveDrab:B2HexColor = B2HexColor.b2_colorOliveDrab;

	/** The `B2HexColor` value b2_colorOrange: The SVG color orange, 0xFFA500. */
	public static inline final b2_colorOrange:B2HexColor = B2HexColor.b2_colorOrange;

	/** The `B2HexColor` value b2_colorOrangeRed: The SVG color orange red, 0xFF4500. */
	public static inline final b2_colorOrangeRed:B2HexColor = B2HexColor.b2_colorOrangeRed;

	/** The `B2HexColor` value b2_colorOrchid: The SVG color orchid, 0xDA70D6. */
	public static inline final b2_colorOrchid:B2HexColor = B2HexColor.b2_colorOrchid;

	/** The `B2HexColor` value b2_colorPaleGoldenRod: The SVG color pale golden rod, 0xEEE8AA. */
	public static inline final b2_colorPaleGoldenRod:B2HexColor = B2HexColor.b2_colorPaleGoldenRod;

	/** The `B2HexColor` value b2_colorPaleGreen: The SVG color pale green, 0x98FB98. */
	public static inline final b2_colorPaleGreen:B2HexColor = B2HexColor.b2_colorPaleGreen;

	/** The `B2HexColor` value b2_colorPaleTurquoise: The SVG color pale turquoise, 0xAFEEEE. */
	public static inline final b2_colorPaleTurquoise:B2HexColor = B2HexColor.b2_colorPaleTurquoise;

	/** The `B2HexColor` value b2_colorPaleVioletRed: The SVG color pale violet red, 0xDB7093. */
	public static inline final b2_colorPaleVioletRed:B2HexColor = B2HexColor.b2_colorPaleVioletRed;

	/** The `B2HexColor` value b2_colorPapayaWhip: The SVG color papaya whip, 0xFFEFD5. */
	public static inline final b2_colorPapayaWhip:B2HexColor = B2HexColor.b2_colorPapayaWhip;

	/** The `B2HexColor` value b2_colorPeachPuff: The SVG color peach puff, 0xFFDAB9. */
	public static inline final b2_colorPeachPuff:B2HexColor = B2HexColor.b2_colorPeachPuff;

	/** The `B2HexColor` value b2_colorPeru: The SVG color peru, 0xCD853F. */
	public static inline final b2_colorPeru:B2HexColor = B2HexColor.b2_colorPeru;

	/** The `B2HexColor` value b2_colorPink: The SVG color pink, 0xFFC0CB. */
	public static inline final b2_colorPink:B2HexColor = B2HexColor.b2_colorPink;

	/** The `B2HexColor` value b2_colorPlum: The SVG color plum, 0xDDA0DD. */
	public static inline final b2_colorPlum:B2HexColor = B2HexColor.b2_colorPlum;

	/** The `B2HexColor` value b2_colorPowderBlue: The SVG color powder blue, 0xB0E0E6. */
	public static inline final b2_colorPowderBlue:B2HexColor = B2HexColor.b2_colorPowderBlue;

	/** The `B2HexColor` value b2_colorPurple: The SVG color purple, 0x800080. */
	public static inline final b2_colorPurple:B2HexColor = B2HexColor.b2_colorPurple;

	/** The `B2HexColor` value b2_colorRebeccaPurple: The SVG color rebecca purple, 0x663399. */
	public static inline final b2_colorRebeccaPurple:B2HexColor = B2HexColor.b2_colorRebeccaPurple;

	/** The `B2HexColor` value b2_colorRed: The SVG color red, 0xFF0000. */
	public static inline final b2_colorRed:B2HexColor = B2HexColor.b2_colorRed;

	/** The `B2HexColor` value b2_colorRosyBrown: The SVG color rosy brown, 0xBC8F8F. */
	public static inline final b2_colorRosyBrown:B2HexColor = B2HexColor.b2_colorRosyBrown;

	/** The `B2HexColor` value b2_colorRoyalBlue: The SVG color royal blue, 0x4169E1. */
	public static inline final b2_colorRoyalBlue:B2HexColor = B2HexColor.b2_colorRoyalBlue;

	/** The `B2HexColor` value b2_colorSaddleBrown: The SVG color saddle brown, 0x8B4513. */
	public static inline final b2_colorSaddleBrown:B2HexColor = B2HexColor.b2_colorSaddleBrown;

	/** The `B2HexColor` value b2_colorSalmon: The SVG color salmon, 0xFA8072. */
	public static inline final b2_colorSalmon:B2HexColor = B2HexColor.b2_colorSalmon;

	/** The `B2HexColor` value b2_colorSandyBrown: The SVG color sandy brown, 0xF4A460. */
	public static inline final b2_colorSandyBrown:B2HexColor = B2HexColor.b2_colorSandyBrown;

	/** The `B2HexColor` value b2_colorSeaGreen: The SVG color sea green, 0x2E8B57. */
	public static inline final b2_colorSeaGreen:B2HexColor = B2HexColor.b2_colorSeaGreen;

	/** The `B2HexColor` value b2_colorSeaShell: The SVG color sea shell, 0xFFF5EE. */
	public static inline final b2_colorSeaShell:B2HexColor = B2HexColor.b2_colorSeaShell;

	/** The `B2HexColor` value b2_colorSienna: The SVG color sienna, 0xA0522D. */
	public static inline final b2_colorSienna:B2HexColor = B2HexColor.b2_colorSienna;

	/** The `B2HexColor` value b2_colorSilver: The SVG color silver, 0xC0C0C0. */
	public static inline final b2_colorSilver:B2HexColor = B2HexColor.b2_colorSilver;

	/** The `B2HexColor` value b2_colorSkyBlue: The SVG color sky blue, 0x87CEEB. */
	public static inline final b2_colorSkyBlue:B2HexColor = B2HexColor.b2_colorSkyBlue;

	/** The `B2HexColor` value b2_colorSlateBlue: The SVG color slate blue, 0x6A5ACD. */
	public static inline final b2_colorSlateBlue:B2HexColor = B2HexColor.b2_colorSlateBlue;

	/** The `B2HexColor` value b2_colorSlateGray: The SVG color slate gray, 0x708090. */
	public static inline final b2_colorSlateGray:B2HexColor = B2HexColor.b2_colorSlateGray;

	/** The `B2HexColor` value b2_colorSnow: The SVG color snow, 0xFFFAFA. */
	public static inline final b2_colorSnow:B2HexColor = B2HexColor.b2_colorSnow;

	/** The `B2HexColor` value b2_colorSpringGreen: The SVG color spring green, 0x00FF7F. */
	public static inline final b2_colorSpringGreen:B2HexColor = B2HexColor.b2_colorSpringGreen;

	/** The `B2HexColor` value b2_colorSteelBlue: The SVG color steel blue, 0x4682B4. */
	public static inline final b2_colorSteelBlue:B2HexColor = B2HexColor.b2_colorSteelBlue;

	/** The `B2HexColor` value b2_colorTan: The SVG color tan, 0xD2B48C. */
	public static inline final b2_colorTan:B2HexColor = B2HexColor.b2_colorTan;

	/** The `B2HexColor` value b2_colorTeal: The SVG color teal, 0x008080. */
	public static inline final b2_colorTeal:B2HexColor = B2HexColor.b2_colorTeal;

	/** The `B2HexColor` value b2_colorThistle: The SVG color thistle, 0xD8BFD8. */
	public static inline final b2_colorThistle:B2HexColor = B2HexColor.b2_colorThistle;

	/** The `B2HexColor` value b2_colorTomato: The SVG color tomato, 0xFF6347. */
	public static inline final b2_colorTomato:B2HexColor = B2HexColor.b2_colorTomato;

	/** The `B2HexColor` value b2_colorTurquoise: The SVG color turquoise, 0x40E0D0. */
	public static inline final b2_colorTurquoise:B2HexColor = B2HexColor.b2_colorTurquoise;

	/** The `B2HexColor` value b2_colorViolet: The SVG color violet, 0xEE82EE. */
	public static inline final b2_colorViolet:B2HexColor = B2HexColor.b2_colorViolet;

	/** The `B2HexColor` value b2_colorWheat: The SVG color wheat, 0xF5DEB3. */
	public static inline final b2_colorWheat:B2HexColor = B2HexColor.b2_colorWheat;

	/** The `B2HexColor` value b2_colorWhite: The SVG color white, 0xFFFFFF. */
	public static inline final b2_colorWhite:B2HexColor = B2HexColor.b2_colorWhite;

	/** The `B2HexColor` value b2_colorWhiteSmoke: The SVG color white smoke, 0xF5F5F5. */
	public static inline final b2_colorWhiteSmoke:B2HexColor = B2HexColor.b2_colorWhiteSmoke;

	/** The `B2HexColor` value b2_colorYellow: The SVG color yellow, 0xFFFF00. */
	public static inline final b2_colorYellow:B2HexColor = B2HexColor.b2_colorYellow;

	/** The `B2HexColor` value b2_colorYellowGreen: The SVG color yellow green, 0x9ACD32. */
	public static inline final b2_colorYellowGreen:B2HexColor = B2HexColor.b2_colorYellowGreen;

	/** The `B2HexColor` value b2_colorBox2DRed: The Box2D logo color red, 0xDC3132. */
	public static inline final b2_colorBox2DRed:B2HexColor = B2HexColor.b2_colorBox2DRed;

	/** The `B2HexColor` value b2_colorBox2DBlue: The Box2D logo color blue, 0x30AEBF. */
	public static inline final b2_colorBox2DBlue:B2HexColor = B2HexColor.b2_colorBox2DBlue;

	/** The `B2HexColor` value b2_colorBox2DGreen: The Box2D logo color green, 0x8CC924. */
	public static inline final b2_colorBox2DGreen:B2HexColor = B2HexColor.b2_colorBox2DGreen;

	/** The `B2HexColor` value b2_colorBox2DYellow: The Box2D logo color yellow, 0xFFEE8C. */
	public static inline final b2_colorBox2DYellow:B2HexColor = B2HexColor.b2_colorBox2DYellow;

	/** The `B2JointType` value b2_distanceJoint: Constrain the distance between two points. */
	public static inline final b2_distanceJoint:B2JointType = B2JointType.b2_distanceJoint;

	/** The `B2JointType` value b2_filterJoint: Filter collision between two bodies. */
	public static inline final b2_filterJoint:B2JointType = B2JointType.b2_filterJoint;

	/** The `B2JointType` value b2_motorJoint: Fully control the movement of a body. */
	public static inline final b2_motorJoint:B2JointType = B2JointType.b2_motorJoint;

	/** The `B2JointType` value b2_moverJoint: Control the movement of the dynamic character mover. */
	public static inline final b2_moverJoint:B2JointType = B2JointType.b2_moverJoint;

	/** The `B2JointType` value b2_pogoJoint: Ground interaction for the dynamic character mover. */
	public static inline final b2_pogoJoint:B2JointType = B2JointType.b2_pogoJoint;

	/** The `B2JointType` value b2_prismaticJoint: Slide along an axis. */
	public static inline final b2_prismaticJoint:B2JointType = B2JointType.b2_prismaticJoint;

	/** The `B2JointType` value b2_revoluteJoint: Rotate around a pivot. */
	public static inline final b2_revoluteJoint:B2JointType = B2JointType.b2_revoluteJoint;

	/** The `B2JointType` value b2_weldJoint: Bring two bodies together with some flex. */
	public static inline final b2_weldJoint:B2JointType = B2JointType.b2_weldJoint;

	/** The `B2JointType` value b2_wheelJoint: Wheel spins with shock absorber. */
	public static inline final b2_wheelJoint:B2JointType = B2JointType.b2_wheelJoint;

	/** The `B2ShapeType` value b2_circleShape: A circle with an offset. */
	public static inline final b2_circleShape:B2ShapeType = B2ShapeType.b2_circleShape;

	/** The `B2ShapeType` value b2_capsuleShape: A capsule is an extruded circle. */
	public static inline final b2_capsuleShape:B2ShapeType = B2ShapeType.b2_capsuleShape;

	/** The `B2ShapeType` value b2_segmentShape: A line segment. */
	public static inline final b2_segmentShape:B2ShapeType = B2ShapeType.b2_segmentShape;

	/** The `B2ShapeType` value b2_polygonShape: A convex polygon. */
	public static inline final b2_polygonShape:B2ShapeType = B2ShapeType.b2_polygonShape;

	/** The `B2ShapeType` value b2_chainSegmentShape: A line segment owned by a chain shape. */
	public static inline final b2_chainSegmentShape:B2ShapeType = B2ShapeType.b2_chainSegmentShape;

	/** The `B2ShapeType` value b2_shapeTypeCount: The number of shape types. */
	public static inline final b2_shapeTypeCount:B2ShapeType = B2ShapeType.b2_shapeTypeCount;

	/** The `B2TOIState` value b2_toiStateUnknown: The computation didn't finish or hasn't run. */
	public static inline final b2_toiStateUnknown:B2TOIState = B2TOIState.b2_toiStateUnknown;

	/** The `B2TOIState` value b2_toiStateFailed: The root finder failed, and the fraction is the last time known to be safe. */
	public static inline final b2_toiStateFailed:B2TOIState = B2TOIState.b2_toiStateFailed;

	/** The `B2TOIState` value b2_toiStateOverlapped: The shapes already overlap at the start of the sweep, and the fraction is 0. */
	public static inline final b2_toiStateOverlapped:B2TOIState = B2TOIState.b2_toiStateOverlapped;

	/** The `B2TOIState` value b2_toiStateHit: The shapes come within the target separation, and the fraction is when. */
	public static inline final b2_toiStateHit:B2TOIState = B2TOIState.b2_toiStateHit;

	/** The `B2TOIState` value b2_toiStateSeparated: The shapes stay separated for the whole sweep, and the fraction is the sweep's end. */
	public static inline final b2_toiStateSeparated:B2TOIState = B2TOIState.b2_toiStateSeparated;

	// base.h

	/** Returns the total bytes currently allocated by Box2D.

		@return  The allocated bytes. */
	public static function b2GetByteCount():Int {
		throw "not built yet";
	}

	/** Replaces the default function that receives Box2D's log messages.

		@param logFcn  The function that receives each log message. Must not be null. */
	public static function b2SetLogCallback(logFcn:B2LogCallbackFcn):Void {
		throw "not built yet";
	}

	/** Returns the version of Box2D.

		@param out  Optional. The `B2Version` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Version`, which is `out` when provided. */
	public static function b2GetVersion(?out:B2Version):B2Version {
		throw "not built yet";
	}

	/** Returns whether the library was built with `BOX2D_DOUBLE_PRECISION` (large world mode).

		@return  True when built with double precision. */
	public static function b2IsDoublePrecision():Bool {
		throw "not built yet";
	}

	/** Returns whether the current CPU has the AVX2 instruction set.

		@return  True when AVX2 is available. */
	public static function b2IsAVX2Available():Bool {
		throw "not built yet";
	}

	/** Returns the current system tick count.

		The tick unit depends on the platform. Pass the value to `b2GetMilliseconds` to measure elapsed time.

		@return  The tick count. */
	public static function b2GetTicks():haxe.Int64 {
		throw "not built yet";
	}

	/** Returns the milliseconds that have passed since an earlier tick count.

		@param ticks  A tick count returned by `b2GetTicks`.
		@return  The elapsed time, in milliseconds. */
	public static function b2GetMilliseconds(ticks:haxe.Int64):Float {
		throw "not built yet";
	}

	/** Returns the milliseconds that have passed since an earlier tick count, and replaces that count with the current one.

		@param ticks  A one-element array holding a tick count returned by `b2GetTicks`. The call stores the current tick count at index 0.
		@return  The elapsed time, in milliseconds. */
	public static function b2GetMillisecondsAndReset(ticks:Array<haxe.Int64>):Float {
		throw "not built yet";
	}

	/** Returns the djb2 hash of bytes, for determinism testing.

		Hash a series of buffers by passing each result as the next `hash`. Start with `B2_HASH_INIT`.

		@param hash  The starting hash value, `B2_HASH_INIT` for the first buffer.
		@param data  The bytes to hash, read from index 0.
		@param count  The number of bytes to hash.
		@return  The hash, as an unsigned 32-bit value held in an `Int`. */
	public static function b2Hash(hash:Int, data:haxe.io.Bytes, count:Int):Int {
		throw "not built yet";
	}

	// math_functions.h

	/** Returns whether a number is finite.

		@param a  The number.
		@return  False when the number is NaN or infinity. */
	public static function b2IsValidFloat(a:Float):Bool {
		throw "not built yet";
	}

	/** Returns whether both components of a vector are finite.

		@param v  The vector.
		@return  False when a component is NaN or infinity. */
	public static function b2IsValidVec2(v:B2Vec2):Bool {
		throw "not built yet";
	}

	/** Returns whether a rotation is finite and normalized.

		@param q  The rotation.
		@return  False when a component is NaN or infinity, or the rotation is not normalized. */
	public static function b2IsValidRot(q:B2Rot):Bool {
		throw "not built yet";
	}

	/** Returns whether a transform is finite and its rotation is normalized.

		@param t  The transform.
		@return  False when a component is NaN or infinity, or the rotation is not normalized. */
	public static function b2IsValidTransform(t:B2Transform):Bool {
		throw "not built yet";
	}

	/** Returns whether a bounding box is finite and its upper bound is not below its lower bound.

		@param aabb  The bounding box.
		@return  False when a component is NaN or infinity, or the upper bound is below the lower bound in either axis. */
	public static function b2IsValidAABB(aabb:B2AABB):Bool {
		throw "not built yet";
	}

	/** Returns whether a plane is finite and its normal is a unit vector.

		@param a  The plane.
		@return  False when the plane's normal is not a unit vector, or a component is NaN or infinity. */
	public static function b2IsValidPlane(a:B2Plane):Bool {
		throw "not built yet";
	}

	/** Returns whether a world position is finite.

		@param p  The world position.
		@return  False when a component is NaN or infinity. */
	public static function b2IsValidPos(p:B2Pos):Bool {
		throw "not built yet";
	}

	/** Returns whether a world transform is finite and its rotation is normalized.

		@param t  The world transform.
		@return  False when a component is NaN or infinity, or the rotation is not normalized. */
	public static function b2IsValidWorldTransform(t:B2WorldTransform):Bool {
		throw "not built yet";
	}

	/** Returns the smaller of two integers.

		@param a  The first integer.
		@param b  The second integer.
		@return  The smaller integer. */
	public static function b2MinInt(a:Int, b:Int):Int {
		throw "not built yet";
	}

	/** Returns the larger of two integers.

		@param a  The first integer.
		@param b  The second integer.
		@return  The larger integer. */
	public static function b2MaxInt(a:Int, b:Int):Int {
		throw "not built yet";
	}

	/** Returns the absolute value of an integer.

		@param a  The integer.
		@return  The absolute value. */
	public static function b2AbsInt(a:Int):Int {
		throw "not built yet";
	}

	/** Returns an integer limited to a range.

		@param a  The integer.
		@param lower  The lower bound.
		@param upper  The upper bound.
		@return  The integer, or the nearest bound when it lies outside the range. */
	public static function b2ClampInt(a:Int, lower:Int, upper:Int):Int {
		throw "not built yet";
	}

	/** Returns the integer division of a numerator by a denominator, rounded up.

		@param numerator  The numerator. Must not be negative.
		@param denominator  The denominator. Must be greater than zero.
		@return  The quotient, rounded up. */
	public static function b2CeilingInt(numerator:Int, denominator:Int):Int {
		throw "not built yet";
	}

	/** Returns the smaller of two floats.

		@param a  The first float.
		@param b  The second float.
		@return  The smaller float. */
	public static function b2MinFloat(a:Float, b:Float):Float {
		throw "not built yet";
	}

	/** Returns the larger of two floats.

		@param a  The first float.
		@param b  The second float.
		@return  The larger float. */
	public static function b2MaxFloat(a:Float, b:Float):Float {
		throw "not built yet";
	}

	/** Returns the absolute value of a float.

		@param a  The float.
		@return  The absolute value. */
	public static function b2AbsFloat(a:Float):Float {
		throw "not built yet";
	}

	/** Returns a float limited to a range.

		@param a  The float.
		@param lower  The lower bound.
		@param upper  The upper bound.
		@return  The float, or the nearest bound when it lies outside the range. */
	public static function b2ClampFloat(a:Float, lower:Float, upper:Float):Float {
		throw "not built yet";
	}

	/** Returns an approximate arctangent of `y / x`, in radians within [-pi, pi].

		Box2D computes this itself, so the result is the same on every platform, which `Math.atan2` does not guarantee. The error is up to about 0.0023 degrees. Returns 0 when both arguments are 0.

		@param y  The y coordinate.
		@param x  The x coordinate.
		@return  The angle, in radians. */
	public static function b2Atan2(y:Float, x:Float):Float {
		throw "not built yet";
	}

	/** Returns the cosine and sine of an angle, computed so the result is the same on every platform.

		@param radians  The angle, in radians.
		@param out  Optional. The `B2CosSin` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2CosSin`, which is `out` when provided. */
	public static function b2ComputeCosSin(radians:Float, ?out:B2CosSin):B2CosSin {
		throw "not built yet";
	}

	/** Returns the dot product of two vectors.

		@param a  The first vector.
		@param b  The second vector.
		@return  The dot product. */
	public static function b2Dot(a:B2Vec2, b:B2Vec2):Float {
		throw "not built yet";
	}

	/** Returns the cross product of two vectors, a scalar in 2D.

		@param a  The first vector.
		@param b  The second vector.
		@return  The cross product, `a.x * b.y - a.y * b.x`. */
	public static function b2Cross(a:B2Vec2, b:B2Vec2):Float {
		throw "not built yet";
	}

	/** Returns the cross product of a vector and a scalar, a vector in 2D.

		@param v  The vector.
		@param s  The scalar.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. It holds `(s * v.y, -s * v.x)`. */
	public static function b2CrossVS(v:B2Vec2, s:Float, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the cross product of a scalar and a vector, a vector in 2D.

		@param s  The scalar.
		@param v  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. It holds `(-s * v.y, s * v.x)`. */
	public static function b2CrossSV(s:Float, v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the vector rotated 90 degrees counter-clockwise, which is `b2CrossSV(1, v)`.

		@param v  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. It holds `(-v.y, v.x)`. */
	public static function b2LeftPerp(v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the vector rotated 90 degrees clockwise, which is `b2CrossVS(v, 1)`.

		@param v  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. It holds `(v.y, -v.x)`. */
	public static function b2RightPerp(v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the sum of two vectors.

		@param a  The first vector.
		@param b  The second vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Add(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the difference `a - b` of two vectors.

		@param a  The vector to subtract from.
		@param b  The vector to subtract.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Sub(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the negation of a vector.

		@param a  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Neg(a:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the point between two vectors at a fraction of the way from the first to the second.

		@param a  The vector at `t` of 0.
		@param b  The vector at `t` of 1.
		@param t  The fraction, 0 to 1.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Lerp(a:B2Vec2, b:B2Vec2, t:Float, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the component-wise product of two vectors.

		@param a  The first vector.
		@param b  The second vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Mul(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns a vector scaled by a scalar.

		@param s  The scalar.
		@param v  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2MulSV(s:Float, v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns `a + s * b`.

		@param a  The vector to add to.
		@param s  The scalar.
		@param b  The vector to scale.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2MulAdd(a:B2Vec2, s:Float, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns `a - s * b`.

		@param a  The vector to subtract from.
		@param s  The scalar.
		@param b  The vector to scale.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2MulSub(a:B2Vec2, s:Float, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the absolute value of each component of a vector.

		@param a  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Abs(a:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the smaller of each component of two vectors.

		@param a  The first vector.
		@param b  The second vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Min(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the larger of each component of two vectors.

		@param a  The first vector.
		@param b  The second vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Max(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns a vector with each component limited to the range between the matching components of two vectors.

		@param v  The vector.
		@param a  The lower bound vector.
		@param b  The upper bound vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Clamp(v:B2Vec2, a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the length of a vector.

		@param v  The vector.
		@return  The length. */
	public static function b2Length(v:B2Vec2):Float {
		throw "not built yet";
	}

	/** Returns the distance between two points.

		@param a  The first point.
		@param b  The second point.
		@return  The distance. */
	public static function b2Distance(a:B2Vec2, b:B2Vec2):Float {
		throw "not built yet";
	}

	/** Returns a vector scaled to length 1.

		Returns the zero vector when the length is too small to scale.

		@param a  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Normalize(a:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns whether a vector has length 1, within a small tolerance.

		@param a  The vector.
		@return  True when the vector is normalized. */
	public static function b2IsNormalized(a:B2Vec2):Bool {
		throw "not built yet";
	}

	/** Returns a vector scaled to length 1, and stores the vector's original length.

		Returns the zero vector, with a length of 0, when the length is too small to scale.

		@param length  A one-element array. The call stores the original length at index 0.
		@param a  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2GetLengthAndNormalize(length:Array<Float>, a:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns a rotation scaled to unit magnitude.

		@param q  The rotation.
		@param out  Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Rot`, which is `out` when provided. */
	public static function b2NormalizeRot(q:B2Rot, ?out:B2Rot):B2Rot {
		throw "not built yet";
	}

	/** Returns a rotation advanced by an angular displacement.

		The result is normalized.

		@param q1  The initial rotation.
		@param deltaAngle  The angular displacement, in radians.
		@param out  Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Rot`, which is `out` when provided. */
	public static function b2IntegrateRotation(q1:B2Rot, deltaAngle:Float, ?out:B2Rot):B2Rot {
		throw "not built yet";
	}

	/** Returns the squared length of a vector.

		@param v  The vector.
		@return  The squared length. */
	public static function b2LengthSquared(v:B2Vec2):Float {
		throw "not built yet";
	}

	/** Returns the squared distance between two points.

		@param a  The first point.
		@param b  The second point.
		@return  The squared distance. */
	public static function b2DistanceSquared(a:B2Vec2, b:B2Vec2):Float {
		throw "not built yet";
	}

	/** Returns the rotation for an angle.

		@param radians  The angle, in radians.
		@param out  Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Rot`, which is `out` when provided. */
	public static function b2MakeRot(radians:Float, ?out:B2Rot):B2Rot {
		throw "not built yet";
	}

	/** Returns the rotation whose x-axis is a unit vector.

		@param unitVector  The unit vector, which must be normalized.
		@param out  Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Rot`, which is `out` when provided. */
	public static function b2MakeRotFromUnitVector(unitVector:B2Vec2, ?out:B2Rot):B2Rot {
		throw "not built yet";
	}

	/** Returns the rotation from one unit vector to another.

		@param v1  The first unit vector.
		@param v2  The second unit vector.
		@param out  Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Rot`, which is `out` when provided. */
	public static function b2ComputeRotationBetweenUnitVectors(v1:B2Vec2, v2:B2Vec2, ?out:B2Rot):B2Rot {
		throw "not built yet";
	}

	/** Returns whether a rotation has unit magnitude, within a small tolerance.

		@param q  The rotation.
		@return  True when the rotation is normalized. */
	public static function b2IsNormalizedRot(q:B2Rot):Bool {
		throw "not built yet";
	}

	/** Returns the inverse of a rotation.

		@param a  The rotation.
		@param out  Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Rot`, which is `out` when provided. */
	public static function b2InvertRot(a:B2Rot, ?out:B2Rot):B2Rot {
		throw "not built yet";
	}

	/** Returns the normalized linear interpolation between two rotations.

		@param q1  The rotation at `t` of 0.
		@param q2  The rotation at `t` of 1.
		@param t  The fraction, 0 to 1.
		@param out  Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Rot`, which is `out` when provided. */
	public static function b2NLerp(q1:B2Rot, q2:B2Rot, t:Float, ?out:B2Rot):B2Rot {
		throw "not built yet";
	}

	/** Returns the angular velocity that rotates from one rotation to another over a time step.

		@param q1  The initial rotation.
		@param q2  The final rotation.
		@param inv_h  The inverse of the time step, in 1/seconds.
		@return  The angular velocity, in radians per second. */
	public static function b2ComputeAngularVelocity(q1:B2Rot, q2:B2Rot, inv_h:Float):Float {
		throw "not built yet";
	}

	/** Returns the angle of a rotation, in radians within [-pi, pi].

		@param q  The rotation.
		@return  The angle, in radians. */
	public static function b2Rot_GetAngle(q:B2Rot):Float {
		throw "not built yet";
	}

	/** Returns the x-axis of a rotation.

		@param q  The rotation.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Rot_GetXAxis(q:B2Rot, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the y-axis of a rotation.

		@param q  The rotation.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Rot_GetYAxis(q:B2Rot, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the product `q * r` of two rotations.

		@param q  The left rotation.
		@param r  The right rotation.
		@param out  Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Rot`, which is `out` when provided. */
	public static function b2MulRot(q:B2Rot, r:B2Rot, ?out:B2Rot):B2Rot {
		throw "not built yet";
	}

	/** Returns the product `inv(a) * b` of two rotations.

		The result rotates a vector in frame `b` into a vector in frame `a`.

		@param a  The rotation to invert.
		@param b  The rotation to multiply by.
		@param out  Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Rot`, which is `out` when provided. */
	public static function b2InvMulRot(a:B2Rot, b:B2Rot, ?out:B2Rot):B2Rot {
		throw "not built yet";
	}

	/** Returns the angle of one rotation relative to another, in radians.

		@param a  The reference rotation.
		@param b  The rotation to measure.
		@return  The angle of `b` relative to `a`, in radians within [-pi, pi]. */
	public static function b2RelativeAngle(a:B2Rot, b:B2Rot):Float {
		throw "not built yet";
	}

	/** Returns an angle brought into the range [-pi, pi].

		The angle's magnitude should stay below 10000 radians. Unwind angles regularly.

		@param radians  The angle, in radians.
		@return  The equivalent angle, in radians. */
	public static function b2UnwindAngle(radians:Float):Float {
		throw "not built yet";
	}

	/** Returns a vector rotated by a rotation.

		@param q  The rotation.
		@param v  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2RotateVector(q:B2Rot, v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns a vector rotated by the inverse of a rotation.

		@param q  The rotation to invert.
		@param v  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2InvRotateVector(q:B2Rot, v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns a point transformed by a transform, for example from local space to world space.

		@param t  The transform.
		@param p  The point.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2TransformPoint(t:B2Transform, p:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns a point transformed by the inverse of a transform, for example from world space to local space.

		@param t  The transform to invert.
		@param p  The point.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2InvTransformPoint(t:B2Transform, p:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the product of two transforms.

		Applied to a point local to frame `B`, the result converts the point to frame `A`'s space, then into the world. This equals `A.q.Rot(B.q.Rot(v1) + B.p) + A.p`.

		@param A  The outer transform.
		@param B  The inner transform.
		@param out  Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Transform`, which is `out` when provided. */
	public static function b2MulTransforms(A:B2Transform, B:B2Transform, ?out:B2Transform):B2Transform {
		throw "not built yet";
	}

	/** Returns the transform that converts a point local to frame `B` into a point local to frame `A`.

		The result is `A.q' * B.q * v1 + A.q' * (B.p - A.p)`.

		@param A  The transform of frame `A`.
		@param B  The transform of frame `B`.
		@param out  Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Transform`, which is `out` when provided. */
	public static function b2InvMulTransforms(A:B2Transform, B:B2Transform, ?out:B2Transform):B2Transform {
		throw "not built yet";
	}

	/** Returns a vector as a world position.

		Returns a copy of the vector in single precision.

		@param v  The vector.
		@param out  Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Pos`, which is `out` when provided. */
	public static function b2ToPos(v:B2Vec2, ?out:B2Pos):B2Pos {
		throw "not built yet";
	}

	/** Returns a world position as a vector.

		Returns a copy of the position in single precision.

		@param p  The world position.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2ToVec2(p:B2Pos, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns a world coordinate narrowed to a float, rounded toward negative infinity.

		Use with `b2RoundUpFloat` to build a float box that always contains double precision bounds. In single precision, the value is returned unchanged.

		@param x  The world coordinate.
		@return  The coordinate, rounded down. */
	public static function b2RoundDownFloat(x:Float):Float {
		throw "not built yet";
	}

	/** Returns a world coordinate narrowed to a float, rounded toward positive infinity.

		Use with `b2RoundDownFloat` to build a float box that always contains double precision bounds. In single precision, the value is returned unchanged.

		@param x  The world coordinate.
		@return  The coordinate, rounded up. */
	public static function b2RoundUpFloat(x:Float):Float {
		throw "not built yet";
	}

	/** Returns the difference `a - b` of two world positions as a vector.

		@param a  The position to subtract from.
		@param b  The position to subtract.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2SubPos(a:B2Pos, b:B2Pos, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns a world position moved by a vector.

		@param p  The world position.
		@param d  The offset.
		@param out  Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Pos`, which is `out` when provided. */
	public static function b2OffsetPos(p:B2Pos, d:B2Vec2, ?out:B2Pos):B2Pos {
		throw "not built yet";
	}

	/** Returns the world position between two positions at a fraction of the way from the first to the second.

		@param a  The position at `t` of 0.
		@param b  The position at `t` of 1.
		@param t  The fraction, 0 to 1.
		@param out  Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Pos`, which is `out` when provided. */
	public static function b2LerpPos(a:B2Pos, b:B2Pos, t:Float, ?out:B2Pos):B2Pos {
		throw "not built yet";
	}

	/** Returns a local point transformed to a world position.

		@param t  The world transform.
		@param p  The local point.
		@param out  Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Pos`, which is `out` when provided. */
	public static function b2TransformWorldPoint(t:B2WorldTransform, p:B2Vec2, ?out:B2Pos):B2Pos {
		throw "not built yet";
	}

	/** Returns a world position transformed to a point local to a world transform.

		@param t  The world transform.
		@param p  The world position.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2InvTransformWorldPoint(t:B2WorldTransform, p:B2Pos, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the transform of frame `B` relative to frame `A`.

		@param A  The world transform of frame `A`.
		@param B  The world transform of frame `B`.
		@param out  Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Transform`, which is `out` when provided. */
	public static function b2InvMulWorldTransforms(A:B2WorldTransform, B:B2WorldTransform, ?out:B2Transform):B2Transform {
		throw "not built yet";
	}

	/** Returns a local transform converted into world space by a world transform.

		@param A  The world transform.
		@param B  The local transform.
		@param out  Optional. The `B2WorldTransform` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2WorldTransform`, which is `out` when provided. */
	public static function b2MulWorldTransforms(A:B2WorldTransform, B:B2Transform, ?out:B2WorldTransform):B2WorldTransform {
		throw "not built yet";
	}

	/** Returns a world transform expressed relative to a base position.

		@param t  The world transform.
		@param base  The base world position.
		@param out  Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Transform`, which is `out` when provided. */
	public static function b2ToRelativeTransform(t:B2WorldTransform, base:B2Pos, ?out:B2Transform):B2Transform {
		throw "not built yet";
	}

	/** Returns a transform as a world transform.

		The conversion loses nothing.

		@param t  The transform.
		@param out  Optional. The `B2WorldTransform` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2WorldTransform`, which is `out` when provided. */
	public static function b2MakeWorldTransform(t:B2Transform, ?out:B2WorldTransform):B2WorldTransform {
		throw "not built yet";
	}

	/** Returns a 2-by-2 matrix multiplied by a vector.

		@param A  The matrix.
		@param v  The vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2MulMV(A:B2Mat22, v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the inverse of a 2-by-2 matrix.

		Returns the zero matrix when the matrix is singular.

		@param A  The matrix.
		@param out  Optional. The `B2Mat22` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Mat22`, which is `out` when provided. */
	public static function b2GetInverse22(A:B2Mat22, ?out:B2Mat22):B2Mat22 {
		throw "not built yet";
	}

	/** Returns the solution `x` of `A * x = b`.

		Cheaper than computing the inverse when solving once. Returns the zero vector when the matrix is singular.

		@param A  The matrix.
		@param b  The right-hand side column vector.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2Solve22(A:B2Mat22, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns whether one bounding box fully contains another.

		@param a  The containing bounding box.
		@param b  The bounding box to test.
		@return  True when `a` contains `b`. */
	public static function b2AABB_Contains(a:B2AABB, b:B2AABB):Bool {
		throw "not built yet";
	}

	/** Returns the center of a bounding box.

		@param a  The bounding box.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2AABB_Center(a:B2AABB, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the half-widths of a bounding box.

		@param a  The bounding box.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2Vec2`, which is `out` when provided. */
	public static function b2AABB_Extents(a:B2AABB, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the smallest bounding box that contains two bounding boxes.

		@param a  The first bounding box.
		@param b  The second bounding box.
		@param out  Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2AABB`, which is `out` when provided. */
	public static function b2AABB_Union(a:B2AABB, b:B2AABB, ?out:B2AABB):B2AABB {
		throw "not built yet";
	}

	/** Returns whether two bounding boxes overlap.

		@param a  The first bounding box.
		@param b  The second bounding box.
		@return  True when the bounding boxes overlap. */
	public static function b2AABB_Overlaps(a:B2AABB, b:B2AABB):Bool {
		throw "not built yet";
	}

	/** Returns the bounding box of circles of one radius centered on points.

		@param points  The circle centers, read from index 0 up to `count`.
		@param count  The number of points. Must be greater than zero.
		@param radius  The radius of every circle.
		@param out  Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The `B2AABB`, which is `out` when provided. */
	public static function b2MakeAABB(points:Array<B2Vec2>, count:Int, radius:Float, ?out:B2AABB):B2AABB {
		throw "not built yet";
	}

	/** Returns the signed separation of a point from a plane.

		@param plane  The plane.
		@param point  The point.
		@return  The distance along the plane's normal, positive on the normal's side. */
	public static function b2PlaneSeparation(plane:B2Plane, point:B2Vec2):Float {
		throw "not built yet";
	}

	/** Returns the new velocity of a one-dimensional mass-spring-damper that drives toward a position of zero.

		Compute the new position with `position += timeStep * newVelocity`. The solution is stable because it uses implicit integration, and needs no transcendental functions.

		@param hertz  The spring frequency, in hertz.
		@param dampingRatio  The damping ratio, where 1 is critical damping.
		@param position  The current position.
		@param velocity  The current velocity.
		@param timeStep  The time step, in seconds.
		@return  The new velocity. */
	public static function b2SpringDamper(hertz:Float, dampingRatio:Float, position:Float, velocity:Float, timeStep:Float):Float {
		throw "not built yet";
	}

	/** Sets the length units per meter, for programs whose units are not meters.

		Box2D tunes its internal tolerances and thresholds for meters, and scales them by this value. Lengths are never scaled otherwise, so every length sent to and returned from Box2D is in the program's units. A good value is the height of the player character, such as 32 for a character 32 pixels high. Gravity, density and forces then need values suited to those units.

		_Note that this must be called once at startup, before any other Box2D call._ The default is 1.

		@param lengthUnits  The length units per meter. Must be finite and greater than zero. */
	public static function b2SetLengthUnitsPerMeter(lengthUnits:Float):Void {
		throw "not built yet";
	}

	/** Returns the length units per meter.

		@return  The length units per meter. The default is 1. */
	public static function b2GetLengthUnitsPerMeter():Float {
		throw "not built yet";
	}

	// collision.h

	/** Returns whether a ray cast input has finite values and a `maxFraction` from 0 up to `B2_HUGE`.

		@param input  The ray cast input to check.
		@return  True when the input is valid, false when it holds a NaN, an infinity or an out of range `maxFraction`. */
	public static function b2IsValidRay(input:B2RayCastInput):Bool {
		throw "not built yet";
	}

	/** Makes a convex polygon from a convex hull.

		The hull must come directly from `b2ComputeHull`. A hull that is not valid fails Box2D's assertion in a debug build, and a hull with fewer than 3 points produces a square with a half-width of 0.5. Do not fill in the hull's fields by hand.

		@param hull  The hull, computed by `b2ComputeHull`.
		@param radius  The rounding radius of the polygon, in length units. Zero makes sharp corners.
		@param out  Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The polygon. */
	public static function b2MakePolygon(hull:B2Hull, radius:Float, ?out:B2Polygon):B2Polygon {
		throw "not built yet";
	}

	/** Makes a convex polygon from a convex hull, moved and rotated by an offset.

		The hull must come directly from `b2ComputeHull`. A hull that is not valid fails Box2D's assertion in a debug build, and a hull with fewer than 3 points produces a square with a half-width of 0.5.

		@param hull  The hull, computed by `b2ComputeHull`.
		@param position  The offset of the polygon, in length units.
		@param rotation  The rotation of the polygon.
		@param out  Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The polygon, with sharp corners. */
	public static function b2MakeOffsetPolygon(hull:B2Hull, position:B2Vec2, rotation:B2Rot, ?out:B2Polygon):B2Polygon {
		throw "not built yet";
	}

	/** Makes a rounded convex polygon from a convex hull, moved and rotated by an offset.

		The hull must come directly from `b2ComputeHull`. A hull that is not valid fails Box2D's assertion in a debug build, and a hull with fewer than 3 points produces a square with a half-width of 0.5.

		@param hull  The hull, computed by `b2ComputeHull`.
		@param position  The offset of the polygon, in length units.
		@param rotation  The rotation of the polygon.
		@param radius  The rounding radius of the polygon, in length units.
		@param out  Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The polygon. */
	public static function b2MakeOffsetRoundedPolygon(hull:B2Hull, position:B2Vec2, rotation:B2Rot, radius:Float, ?out:B2Polygon):B2Polygon {
		throw "not built yet";
	}

	/** Makes a square polygon centered on the origin, without a convex hull.

		@param halfWidth  The half-width of the square, in length units.
		@param out  Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The polygon. */
	public static function b2MakeSquare(halfWidth:Float, ?out:B2Polygon):B2Polygon {
		throw "not built yet";
	}

	/** Makes a box polygon centered on the origin, without a convex hull.

		@param halfWidth  The half-width along the x-axis, in length units.
		@param halfHeight  The half-height along the y-axis, in length units.
		@param out  Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The polygon. */
	public static function b2MakeBox(halfWidth:Float, halfHeight:Float, ?out:B2Polygon):B2Polygon {
		throw "not built yet";
	}

	/** Makes a box polygon with rounded corners centered on the origin, without a convex hull.

		@param halfWidth  The half-width along the x-axis, in length units.
		@param halfHeight  The half-height along the y-axis, in length units.
		@param radius  The rounding radius, in length units. The rounding extends beyond the half-width and half-height.
		@param out  Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The polygon. */
	public static function b2MakeRoundedBox(halfWidth:Float, halfHeight:Float, radius:Float, ?out:B2Polygon):B2Polygon {
		throw "not built yet";
	}

	/** Makes a box polygon moved and rotated by an offset, without a convex hull.

		@param halfWidth  The half-width along the box's x-axis, in length units.
		@param halfHeight  The half-height along the box's y-axis, in length units.
		@param center  The local center of the box, in length units.
		@param rotation  The local rotation of the box.
		@param out  Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The polygon. */
	public static function b2MakeOffsetBox(halfWidth:Float, halfHeight:Float, center:B2Vec2, rotation:B2Rot, ?out:B2Polygon):B2Polygon {
		throw "not built yet";
	}

	/** Makes a box polygon with rounded corners, moved and rotated by an offset, without a convex hull.

		@param halfWidth  The half-width along the box's x-axis, in length units.
		@param halfHeight  The half-height along the box's y-axis, in length units.
		@param center  The local center of the box, in length units.
		@param rotation  The local rotation of the box.
		@param radius  The rounding radius, in length units. The rounding extends beyond the half-width and half-height.
		@param out  Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The polygon. */
	public static function b2MakeOffsetRoundedBox(halfWidth:Float, halfHeight:Float, center:B2Vec2, rotation:B2Rot, radius:Float, ?out:B2Polygon):B2Polygon {
		throw "not built yet";
	}

	/** Returns a polygon moved by a transform. Useful for moving a shape from one body to another.

		@param transform  The transform to apply.
		@param polygon  The polygon to transform.
		@param out  Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The transformed polygon. */
	public static function b2TransformPolygon(transform:B2Transform, polygon:B2Polygon, ?out:B2Polygon):B2Polygon {
		throw "not built yet";
	}

	/** Computes the mass, center of mass and rotational inertia of a circle.

		@param shape  The circle.
		@param density  The density, in kilograms per square meter.
		@param out  Optional. The `B2MassData` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The mass data. */
	public static function b2ComputeCircleMass(shape:B2Circle, density:Float, ?out:B2MassData):B2MassData {
		throw "not built yet";
	}

	/** Computes the mass, center of mass and rotational inertia of a capsule.

		@param shape  The capsule.
		@param density  The density, in kilograms per square meter.
		@param out  Optional. The `B2MassData` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The mass data. */
	public static function b2ComputeCapsuleMass(shape:B2Capsule, density:Float, ?out:B2MassData):B2MassData {
		throw "not built yet";
	}

	/** Computes the mass, center of mass and rotational inertia of a polygon.

		@param shape  The polygon.
		@param density  The density, in kilograms per square meter.
		@param out  Optional. The `B2MassData` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The mass data. */
	public static function b2ComputePolygonMass(shape:B2Polygon, density:Float, ?out:B2MassData):B2MassData {
		throw "not built yet";
	}

	/** Computes the bounding box of a transformed circle.

		@param shape  The circle, in its local space.
		@param transform  The world transform of the shape.
		@param out  Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The axis-aligned bounding box in world space. */
	public static function b2ComputeCircleBounds(shape:B2Circle, transform:B2WorldTransform, ?out:B2AABB):B2AABB {
		throw "not built yet";
	}

	/** Computes the bounding box of a transformed capsule.

		@param shape  The capsule, in its local space.
		@param transform  The world transform of the shape.
		@param out  Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The axis-aligned bounding box in world space. */
	public static function b2ComputeCapsuleBounds(shape:B2Capsule, transform:B2WorldTransform, ?out:B2AABB):B2AABB {
		throw "not built yet";
	}

	/** Computes the bounding box of a transformed polygon.

		@param shape  The polygon, in its local space.
		@param transform  The world transform of the shape.
		@param out  Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The axis-aligned bounding box in world space. */
	public static function b2ComputePolygonBounds(shape:B2Polygon, transform:B2WorldTransform, ?out:B2AABB):B2AABB {
		throw "not built yet";
	}

	/** Computes the bounding box of a transformed line segment.

		@param shape  The line segment, in its local space.
		@param transform  The world transform of the shape.
		@param out  Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The axis-aligned bounding box in world space. */
	public static function b2ComputeSegmentBounds(shape:B2Segment, transform:B2WorldTransform, ?out:B2AABB):B2AABB {
		throw "not built yet";
	}

	/** Tests whether a point overlaps a circle, in the shape's local space.

		@param shape  The circle.
		@param point  The point, in the shape's local space.
		@return  True when the point is inside the shape. */
	public static function b2PointInCircle(shape:B2Circle, point:B2Vec2):Bool {
		throw "not built yet";
	}

	/** Tests whether a point overlaps a capsule, in the shape's local space.

		@param shape  The capsule.
		@param point  The point, in the shape's local space.
		@return  True when the point is inside the shape. */
	public static function b2PointInCapsule(shape:B2Capsule, point:B2Vec2):Bool {
		throw "not built yet";
	}

	/** Tests whether a point overlaps a convex polygon, in the shape's local space.

		@param shape  The convex polygon.
		@param point  The point, in the shape's local space.
		@return  True when the point is inside the shape. */
	public static function b2PointInPolygon(shape:B2Polygon, point:B2Vec2):Bool {
		throw "not built yet";
	}

	/** Casts a ray against a circle, in the shape's local space.

		@param shape  The circle.
		@param input  The ray, in the shape's local space.
		@param out  Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The cast output. `hit` is false when the ray misses. */
	public static function b2CastRayCircle(shape:B2Circle, input:B2RayCastInput, ?out:B2CastOutput):B2CastOutput {
		throw "not built yet";
	}

	/** Casts a ray against a capsule, in the shape's local space.

		@param shape  The capsule.
		@param input  The ray, in the shape's local space.
		@param out  Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The cast output. `hit` is false when the ray misses. */
	public static function b2CastRayCapsule(shape:B2Capsule, input:B2RayCastInput, ?out:B2CastOutput):B2CastOutput {
		throw "not built yet";
	}

	/** Casts a ray against a line segment, in the segment's local space. The segment may be one-sided.

		@param shape  The line segment.
		@param input  The ray, in the segment's local space.
		@param oneSided  When true, a hit from the left side of the segment counts as a miss.
		@param out  Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The cast output. `hit` is false when the ray misses. */
	public static function b2CastRaySegment(shape:B2Segment, input:B2RayCastInput, oneSided:Bool, ?out:B2CastOutput):B2CastOutput {
		throw "not built yet";
	}

	/** Casts a ray against a polygon, in the shape's local space.

		@param shape  The polygon.
		@param input  The ray, in the shape's local space.
		@param out  Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The cast output. `hit` is false when the ray misses. */
	public static function b2CastRayPolygon(shape:B2Polygon, input:B2RayCastInput, ?out:B2CastOutput):B2CastOutput {
		throw "not built yet";
	}

	/** Casts a moving shape against a circle, in the shape's local space.

		@param shape  The shape that stays in place.
		@param input  The moving shape, its translation and its `maxFraction`.
		@param out  Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The cast output. `hit` is false when the moving shape misses. */
	public static function b2CastShapeCircle(shape:B2Circle, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput {
		throw "not built yet";
	}

	/** Casts a moving shape against a capsule, in the shape's local space.

		@param shape  The shape that stays in place.
		@param input  The moving shape, its translation and its `maxFraction`.
		@param out  Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The cast output. `hit` is false when the moving shape misses. */
	public static function b2CastShapeCapsule(shape:B2Capsule, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput {
		throw "not built yet";
	}

	/** Casts a moving shape against a line segment, in the shape's local space.

		@param shape  The shape that stays in place.
		@param input  The moving shape, its translation and its `maxFraction`.
		@param out  Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The cast output. `hit` is false when the moving shape misses. */
	public static function b2CastShapeSegment(shape:B2Segment, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput {
		throw "not built yet";
	}

	/** Casts a moving shape against a convex polygon, in the shape's local space.

		@param shape  The shape that stays in place.
		@param input  The moving shape, its translation and its `maxFraction`.
		@param out  Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The cast output. `hit` is false when the moving shape misses. */
	public static function b2CastShapePolygon(shape:B2Polygon, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput {
		throw "not built yet";
	}

	/** Computes the convex hull of a set of points.

		Fails when all the points are very close together, when all the points lie on a line, or when `count` is outside that range. Points that are close together are welded and collinear points are removed. Do not modify a hull once it is computed.

		@param points  The points. Read from index 0 up to `count`.
		@param count  The number of points. Must be at least 3 and at most `B2_MAX_POLYGON_VERTICES`.
		@param out  Optional. The `B2Hull` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The hull. Its `count` is 0 when the computation fails. */
	public static function b2ComputeHull(points:Array<B2Vec2>, count:Int, ?out:B2Hull):B2Hull {
		throw "not built yet";
	}

	/** Returns whether a hull is valid, meaning convex and without collinear points.

		_Note that this check is expensive and is meant for debugging, not for runtime use._

		@param hull  The hull to check.
		@return  True when the hull is valid. */
	public static function b2ValidateHull(hull:B2Hull):Bool {
		throw "not built yet";
	}

	/** Computes the closest points between two line segments, clamping at the end points.

		@param p1  The first end point of the first segment.
		@param q1  The second end point of the first segment.
		@param p2  The first end point of the second segment.
		@param q2  The second end point of the second segment.
		@param out  Optional. The `B2SegmentDistanceResult` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The closest point on each segment, the fractions along each segment and the squared distance between the points. */
	public static function b2ComputeSegmentDistance(p1:B2Vec2, q1:B2Vec2, p2:B2Vec2, q2:B2Vec2, ?out:B2SegmentDistanceResult):B2SegmentDistanceResult {
		throw "not built yet";
	}

	/** Computes the closest points between two shapes, each represented as a point cloud.

		@param input  The two proxies, the transform of proxy B in proxy A's frame and whether the proxy radii count.
		@param cache  The simplex cache. Updated by the call, so a later call with a nearby transform starts faster. Set its `count` to 0 on the first call.
		@param simplexes  Optional. Receives the algorithm's simplexes, for debugging, from index 0. Elements it holds are reused, and missing ones are made.
		@param simplexCapacity  Optional. The most simplexes to store; 0 when omitted.
		@param out  Optional. The `B2DistanceOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The closest points on each proxy, the distance, and the iteration and simplex counts. */
	public static function b2ComputeShapeDistance(input:B2DistanceInput, cache:B2SimplexCache, ?simplexes:Array<B2Simplex>, simplexCapacity = 0,
			?out:B2DistanceOutput):B2DistanceOutput {
		throw "not built yet";
	}

	/** Casts shape B, moving by a translation, against shape A, which stays in place.

		The hit point and normal are in shape A's frame. Shapes that already touch produce a `fraction` of 0.

		@param input  The two proxies, the transform of proxy B in proxy A's frame, the translation of B, `maxFraction` and `canEncroach`.
		@param out  Optional. The `B2CastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The cast output, in shape A's frame. `hit` is false when B misses A. */
	public static function b2CastShape(input:B2ShapeCastPairInput, ?out:B2CastOutput):B2CastOutput {
		throw "not built yet";
	}

	/** Makes a proxy for the overlap, shape cast and distance functions. The points are copied.

		@param points  The points. Read from index 0 up to `count`.
		@param count  The number of points. At most `B2_MAX_POLYGON_VERTICES`, and a larger count is clamped to it.
		@param radius  The radius around the points, in length units.
		@param out  Optional. The `B2ShapeProxy` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The proxy. */
	public static function b2MakeProxy(points:Array<B2Vec2>, count:Int, radius:Float, ?out:B2ShapeProxy):B2ShapeProxy {
		throw "not built yet";
	}

	/** Makes a proxy for the overlap, shape cast and distance functions, with its points moved and rotated by an offset. The points are copied.

		@param points  The points. Read from index 0 up to `count`.
		@param count  The number of points. At most `B2_MAX_POLYGON_VERTICES`, and a larger count is clamped to it.
		@param radius  The radius around the points, in length units.
		@param position  The offset of the points, in length units.
		@param rotation  The rotation of the points.
		@param out  Optional. The `B2ShapeProxy` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The proxy. */
	public static function b2MakeOffsetProxy(points:Array<B2Vec2>, count:Int, radius:Float, position:B2Vec2, rotation:B2Rot, ?out:B2ShapeProxy):B2ShapeProxy {
		throw "not built yet";
	}

	/** Evaluates the transform of a sweep at a time.

		@param sweep  The sweep, holding the center of mass and rotation at the start and the end.
		@param time  The time as a fraction from 0 (the start) to 1 (the end).
		@param out  Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The transform of the body's origin at that time. */
	public static function b2GetSweepTransform(sweep:B2Sweep, time:Float, ?out:B2Transform):B2Transform {
		throw "not built yet";
	}

	/** Computes the upper bound on the time before two moving shapes penetrate.

		Time is a fraction from 0 to `maxFraction`. The computation uses a swept separating axis and can miss intermediate collisions where the shapes pass without penetrating. Call it again when the time interval changes.

		@param input  The two proxies, their sweeps and the interval `maxFraction`.
		@param out  Optional. The `B2TOIOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The output state and the time fraction. */
	public static function b2ComputeTimeOfImpact(input:B2TOIInput, ?out:B2TOIOutput):B2TOIOutput {
		throw "not built yet";
	}

	/** Computes the contact manifold between two circles.

		@param circleA  The first circle. Shape A, in its local space.
		@param circleB  The second circle. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollideCircles(circleA:B2Circle, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between a capsule and a circle.

		@param capsuleA  The capsule. Shape A, in its local space.
		@param circleB  The circle. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollideCapsuleAndCircle(capsuleA:B2Capsule, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between a segment and a circle.

		@param segmentA  The segment. Shape A, in its local space.
		@param circleB  The circle. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollideSegmentAndCircle(segmentA:B2Segment, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between a polygon and a circle.

		@param polygonA  The polygon. Shape A, in its local space.
		@param circleB  The circle. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollidePolygonAndCircle(polygonA:B2Polygon, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between two capsules.

		@param capsuleA  The first capsule. Shape A, in its local space.
		@param capsuleB  The second capsule. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollideCapsules(capsuleA:B2Capsule, capsuleB:B2Capsule, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between a segment and a capsule.

		@param segmentA  The segment. Shape A, in its local space.
		@param capsuleB  The capsule. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollideSegmentAndCapsule(segmentA:B2Segment, capsuleB:B2Capsule, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between a polygon and a capsule.

		@param polygonA  The polygon. Shape A, in its local space.
		@param capsuleB  The capsule. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollidePolygonAndCapsule(polygonA:B2Polygon, capsuleB:B2Capsule, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between two polygons.

		@param polygonA  The first polygon. Shape A, in its local space.
		@param polygonB  The second polygon. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollidePolygons(polygonA:B2Polygon, polygonB:B2Polygon, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between a segment and a polygon.

		@param segmentA  The segment. Shape A, in its local space.
		@param polygonB  The polygon. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollideSegmentAndPolygon(segmentA:B2Segment, polygonB:B2Polygon, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between a chain segment and a circle.

		@param segmentA  The chain segment. Shape A, in its local space.
		@param circleB  The circle. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollideChainSegmentAndCircle(segmentA:B2ChainSegment, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between a chain segment and a capsule.

		@param segmentA  The chain segment. Shape A, in its local space.
		@param capsuleB  The capsule. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param cache  The simplex cache, updated by the call. Set its `count` to 0 on the first call.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollideChainSegmentAndCapsule(segmentA:B2ChainSegment, capsuleB:B2Capsule, xf:B2Transform, cache:B2SimplexCache,
			?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	/** Computes the contact manifold between a chain segment and a polygon, which may be rounded.

		@param segmentA  The chain segment. Shape A, in its local space.
		@param polygonB  The polygon. Shape B, in its local space.
		@param xf  The transform of shape B in shape A's frame.
		@param cache  The simplex cache, updated by the call. Set its `count` to 0 on the first call.
		@param out  Optional. The `B2LocalManifold` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact manifold in shape A's frame, with a `pointCount` of 0 when the shapes are too far apart to touch. */
	public static function b2CollideChainSegmentAndPolygon(segmentA:B2ChainSegment, polygonB:B2Polygon, xf:B2Transform, cache:B2SimplexCache,
			?out:B2LocalManifold):B2LocalManifold {
		throw "not built yet";
	}

	// types.h

	/** Returns a world definition set to Box2D's defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2WorldDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The world definition. */
	public static function b2DefaultWorldDef(?out:B2WorldDef):B2WorldDef {
		throw "not built yet";
	}

	/** Returns a body definition set to Box2D's defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2BodyDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The body definition. */
	public static function b2DefaultBodyDef(?out:B2BodyDef):B2BodyDef {
		throw "not built yet";
	}

	/** Returns a collision filter set to Box2D's defaults.

		@param out  Optional. The `B2Filter` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The filter, with `categoryBits` 1, `maskBits` of all ones and `groupIndex` 0. */
	public static function b2DefaultFilter(?out:B2Filter):B2Filter {
		throw "not built yet";
	}

	/** Returns a query filter set to Box2D's defaults.

		@param out  Optional. The `B2QueryFilter` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The query filter, with `categoryBits` 1 and `maskBits` of all ones. */
	public static function b2DefaultQueryFilter(?out:B2QueryFilter):B2QueryFilter {
		throw "not built yet";
	}

	/** Returns a surface material set to Box2D's defaults.

		@param out  Optional. The `B2SurfaceMaterial` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The surface material. */
	public static function b2DefaultSurfaceMaterial(?out:B2SurfaceMaterial):B2SurfaceMaterial {
		throw "not built yet";
	}

	/** Returns a shape definition set to Box2D's defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2ShapeDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The shape definition. */
	public static function b2DefaultShapeDef(?out:B2ShapeDef):B2ShapeDef {
		throw "not built yet";
	}

	/** Returns a chain definition set to Box2D's defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2ChainDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The chain definition. */
	public static function b2DefaultChainDef(?out:B2ChainDef):B2ChainDef {
		throw "not built yet";
	}

	/** Returns a distance joint definition set to Box2D's defaults.

		Joint definitions have `B2JointDef` as their `base`, with its own defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2DistanceJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The distance joint definition. */
	public static function b2DefaultDistanceJointDef(?out:B2DistanceJointDef):B2DistanceJointDef {
		throw "not built yet";
	}

	/** Returns a filter joint definition set to Box2D's defaults.

		Joint definitions have `B2JointDef` as their `base`, with its own defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2FilterJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The filter joint definition. */
	public static function b2DefaultFilterJointDef(?out:B2FilterJointDef):B2FilterJointDef {
		throw "not built yet";
	}

	/** Returns a motor joint definition set to Box2D's defaults.

		Joint definitions have `B2JointDef` as their `base`, with its own defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2MotorJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The motor joint definition. */
	public static function b2DefaultMotorJointDef(?out:B2MotorJointDef):B2MotorJointDef {
		throw "not built yet";
	}

	/** Returns a prismatic joint definition set to Box2D's defaults.

		Joint definitions have `B2JointDef` as their `base`, with its own defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2PrismaticJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The prismatic joint definition. */
	public static function b2DefaultPrismaticJointDef(?out:B2PrismaticJointDef):B2PrismaticJointDef {
		throw "not built yet";
	}

	/** Returns a revolute joint definition set to Box2D's defaults.

		Joint definitions have `B2JointDef` as their `base`, with its own defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2RevoluteJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The revolute joint definition. */
	public static function b2DefaultRevoluteJointDef(?out:B2RevoluteJointDef):B2RevoluteJointDef {
		throw "not built yet";
	}

	/** Returns a weld joint definition set to Box2D's defaults.

		Joint definitions have `B2JointDef` as their `base`, with its own defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2WeldJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The weld joint definition. */
	public static function b2DefaultWeldJointDef(?out:B2WeldJointDef):B2WeldJointDef {
		throw "not built yet";
	}

	/** Returns a wheel joint definition set to Box2D's defaults.

		Joint definitions have `B2JointDef` as their `base`, with its own defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2WheelJointDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The wheel joint definition. */
	public static function b2DefaultWheelJointDef(?out:B2WheelJointDef):B2WheelJointDef {
		throw "not built yet";
	}

	/** Returns a explosion definition set to Box2D's defaults.

		Make a definition with this call rather than with zeros, which are not its defaults.

		@param out  Optional. The `B2ExplosionDef` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The explosion definition. */
	public static function b2DefaultExplosionDef(?out:B2ExplosionDef):B2ExplosionDef {
		throw "not built yet";
	}

	/** Returns the debug draw color of a constraint graph color slot.

		The last slot, `B2_GRAPH_COLOR_COUNT` minus 1, is the overflow color.

		@param index  The color slot, from 0 up to `B2_GRAPH_COLOR_COUNT` minus 1.
		@return  The color, as a hex value. */
	public static function b2GetGraphColor(index:Int):B2HexColor {
		throw "not built yet";
	}

	/** Returns a debug draw interface set to Box2D's defaults, so a program can implement a subset of the drawing callbacks.

		@param out  Optional. The `B2DebugDraw` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The debug draw interface. Each drawing callback is an empty function, `drawingBounds` covers the whole world, `forceScale` and `jointScale` are 1, and `drawShapes` is true. */
	public static function b2DefaultDebugDraw(?out:B2DebugDraw):B2DebugDraw {
		throw "not built yet";
	}

	// box2d.h

	/** Creates a world for rigid body simulation.

		A world contains bodies, shapes and constraints. Up to `B2_MAX_WORLDS` worlds can exist at once. Each world is independent of the others.

		Invalid values in the definition are rejected and logged, and the null world id is returned.

		@param def  The world's definition. Make it with `b2DefaultWorldDef`. The definition is not retained.
		@param out  Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new world's id. */
	public static function b2CreateWorld(def:B2WorldDef, ?out:B2WorldId):B2WorldId {
		throw "not built yet";
	}

	/** Destroys a world, with all its bodies, shapes and joints.

		@param worldId  The world. */
	public static function b2DestroyWorld(worldId:B2WorldId):Void {
		throw "not built yet";
	}

	/** Returns whether a world id refers to a world that exists.

		Detects an id left over from a world that was destroyed. A null world id is not valid.

		@param id  The world id to check.
		@return  True when the world exists. */
	public static function b2World_IsValid(id:B2WorldId):Bool {
		throw "not built yet";
	}

	/** Simulates a world for one time step.

		Performs collision detection, integration and constraint solution. Body and contact events for the step are available afterward. The events are replaced by the next step.

		_Note that the time step should be a fixed number, usually 1/60 of a second._

		@param worldId  The world to simulate.
		@param timeStep  The time to simulate, in seconds.
		@param subStepCount  The number of sub-steps in the step. More sub-steps increase accuracy. Usually 4. */
	public static function b2World_Step(worldId:B2WorldId, timeStep:Float, subStepCount:Int):Void {
		throw "not built yet";
	}

	/** Draws the world's shapes and other debug data through a debug draw object.

		The object's callbacks receive each primitive to draw, and its flags choose which kinds of data are drawn.

		@param worldId  The world.
		@param draw  The debug draw object, with its callbacks and flags. */
	public static function b2World_Draw(worldId:B2WorldId, draw:B2DebugDraw):Void {
		throw "not built yet";
	}

	/** Returns the world bounds, the union of the bounds of all shapes.

		@param worldId  The world.
		@param out  Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The bounds, in world coordinates. */
	public static function b2World_GetBounds(worldId:B2WorldId, ?out:B2AABB):B2AABB {
		throw "not built yet";
	}

	/** Returns the body events from the most recent time step.

		The event data is valid until the next step. Copy anything the program keeps after that.

		@param worldId  The world.
		@param out  Optional. The `B2BodyEvents` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The body events. */
	public static function b2World_GetBodyEvents(worldId:B2WorldId, ?out:B2BodyEvents):B2BodyEvents {
		throw "not built yet";
	}

	/** Returns the sensor events from the most recent time step.

		The event data is valid until the next step. Copy anything the program keeps after that.

		@param worldId  The world.
		@param out  Optional. The `B2SensorEvents` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The sensor events. */
	public static function b2World_GetSensorEvents(worldId:B2WorldId, ?out:B2SensorEvents):B2SensorEvents {
		throw "not built yet";
	}

	/** Returns the contact events from the most recent time step.

		The event data is valid until the next step. Copy anything the program keeps after that.

		@param worldId  The world.
		@param out  Optional. The `B2ContactEvents` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact events. */
	public static function b2World_GetContactEvents(worldId:B2WorldId, ?out:B2ContactEvents):B2ContactEvents {
		throw "not built yet";
	}

	/** Returns the joint events from the most recent time step.

		The event data is valid until the next step. Copy anything the program keeps after that.

		@param worldId  The world.
		@param out  Optional. The `B2JointEvents` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The joint events. */
	public static function b2World_GetJointEvents(worldId:B2WorldId, ?out:B2JointEvents):B2JointEvents {
		throw "not built yet";
	}

	/** Calls a callback for each shape whose bounds may overlap a box.

		Shapes are reported when their bounds overlap the box. The shapes themselves may not overlap it. The box is relative to the origin, which keeps the test precise far from the world origin in large world mode. Near the world origin, provide `b2Pos_zero` and a box in world coordinates.

		@param worldId  The world.
		@param origin  The origin the box is relative to.
		@param aabb  The box, relative to the origin.
		@param filter  The filter that chooses which shapes are reported.
		@param fcn  The callback, called for each shape found. Returning false stops the query.
		@param context  A value passed to the callback.
		@param out  Optional. The `B2TreeStats` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  Counters of the tree traversal. */
	public static function b2World_OverlapAABB(worldId:B2WorldId, origin:B2Pos, aabb:B2AABB, filter:B2QueryFilter, fcn:B2OverlapResultCallbackFcn,
			context:Dynamic, ?out:B2TreeStats):B2TreeStats {
		throw "not built yet";
	}

	/** Calls a callback for each shape that overlaps a shape proxy.

		The proxy points are relative to the origin. Near the world origin, provide `b2Pos_zero` and points in world coordinates.

		@param worldId  The world.
		@param origin  The origin the proxy's points are relative to.
		@param proxy  The proxy, a convex point cloud with a radius.
		@param filter  The filter that chooses which shapes are reported.
		@param fcn  The callback, called for each shape found. Returning false stops the query.
		@param context  A value passed to the callback.
		@param out  Optional. The `B2TreeStats` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  Counters of the tree traversal. */
	public static function b2World_OverlapShape(worldId:B2WorldId, origin:B2Pos, proxy:B2ShapeProxy, filter:B2QueryFilter, fcn:B2OverlapResultCallbackFcn,
			context:Dynamic, ?out:B2TreeStats):B2TreeStats {
		throw "not built yet";
	}

	/** Casts a ray into the world and calls a callback for each shape in its path.

		The callback chooses whether the cast finds the closest hit, any hit or several hits, by the value it returns. The callback may receive shapes in any order. See `b2World_CastRayClosest` for finding the closest hit alone.

		@param worldId  The world to cast the ray against.
		@param origin  The start point of the ray.
		@param translation  The vector from the ray's start point to its end point.
		@param filter  The filter that chooses which shapes the ray can hit.
		@param fcn  The callback, called for each hit. It returns -1 to ignore the shape, 0 to stop, the hit's fraction to clip the cast to the closest hit, or 1 to continue.
		@param context  A value passed to the callback.
		@param out  Optional. The `B2TreeStats` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  Counters of the tree traversal. */
	public static function b2World_CastRay(worldId:B2WorldId, origin:B2Pos, translation:B2Vec2, filter:B2QueryFilter, fcn:B2CastResultCallbackFcn,
			context:Dynamic, ?out:B2TreeStats):B2TreeStats {
		throw "not built yet";
	}

	/** Casts a ray into the world and returns the closest hit.

		Ignores shapes that contain the ray's start point. Allows no custom filtering. See `b2World_CastRay` for a callback that chooses what to keep.

		@param worldId  The world.
		@param origin  The start point of the ray.
		@param translation  The vector from the ray's start point to its end point.
		@param filter  The filter that chooses which shapes the ray can hit.
		@param out  Optional. The `B2RayResult` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The hit, with its `hit` field false when the ray hit no shape. */
	public static function b2World_CastRayClosest(worldId:B2WorldId, origin:B2Pos, translation:B2Vec2, filter:B2QueryFilter, ?out:B2RayResult):B2RayResult {
		throw "not built yet";
	}

	/** Casts a shape proxy through the world and calls a callback for each shape in its path.

		Works as `b2World_CastRay` does, with a shape in place of a point. The proxy points are relative to the origin. The points the callback receives are world positions.

		@param worldId  The world.
		@param origin  The origin the proxy's points are relative to.
		@param proxy  The proxy, a convex point cloud with a radius.
		@param translation  The vector the proxy moves along.
		@param filter  The filter that chooses which shapes the proxy can hit.
		@param fcn  The callback, called for each hit. It returns -1 to ignore the shape, 0 to stop, the hit's fraction to clip the cast to the closest hit, or 1 to continue.
		@param context  A value passed to the callback.
		@param out  Optional. The `B2TreeStats` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  Counters of the tree traversal. */
	public static function b2World_CastShape(worldId:B2WorldId, origin:B2Pos, proxy:B2ShapeProxy, translation:B2Vec2, filter:B2QueryFilter,
			fcn:B2CastResultCallbackFcn, context:Dynamic, ?out:B2TreeStats):B2TreeStats {
		throw "not built yet";
	}

	/** Sets whether bodies in the world can fall asleep.

		A program that doesn't need sleeping gains some performance by disabling it for the whole world. The default is set by `B2WorldDef.enableSleep`.

		@param worldId  The world.
		@param flag  True to let bodies sleep. */
	public static function b2World_EnableSleeping(worldId:B2WorldId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether bodies in the world can fall asleep.

		@param worldId  The world.
		@return  True when sleeping is enabled. */
	public static function b2World_IsSleepingEnabled(worldId:B2WorldId):Bool {
		throw "not built yet";
	}

	/** Sets whether continuous collision between dynamic and static bodies is on.

		Continuous collision keeps fast bodies from passing through static ones. The performance gain from disabling it is small. The default is set by `B2WorldDef.enableContinuous`.

		@param worldId  The world.
		@param flag  True to enable continuous collision. */
	public static function b2World_EnableContinuous(worldId:B2WorldId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether continuous collision is on.

		@param worldId  The world.
		@return  True when continuous collision is enabled. */
	public static function b2World_IsContinuousEnabled(worldId:B2WorldId):Bool {
		throw "not built yet";
	}

	/** Sets the speed below which a collision doesn't bounce.

		A very small value keeps bodies from sleeping. The default is set by `B2WorldDef.restitutionThreshold`.

		@param worldId  The world.
		@param value  The threshold, usually in meters per second. */
	public static function b2World_SetRestitutionThreshold(worldId:B2WorldId, value:Float):Void {
		throw "not built yet";
	}

	/** Returns the speed below which a collision doesn't bounce.

		@param worldId  The world.
		@return  The threshold, usually in meters per second. */
	public static function b2World_GetRestitutionThreshold(worldId:B2WorldId):Float {
		throw "not built yet";
	}

	/** Sets the number of iterations of the restitution solver.

		The value is limited by `B2_MAX_RESTITUTION_ITERATIONS`.

		@param worldId  The world.
		@param iterations  The iteration count. */
	public static function b2World_SetRestitutionIterations(worldId:B2WorldId, iterations:Int):Void {
		throw "not built yet";
	}

	/** Returns the number of iterations of the restitution solver.

		@param worldId  The world.
		@return  The iteration count. */
	public static function b2World_GetRestitutionIterations(worldId:B2WorldId):Int {
		throw "not built yet";
	}

	/** Sets whether restitution propagates through a stack of bodies.

		The default is set by `B2WorldDef.enableRestitutionPropagation`.

		@param worldId  The world.
		@param flag  True to enable propagation. */
	public static function b2World_EnableRestitutionPropagation(worldId:B2WorldId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether restitution propagation is on.

		@param worldId  The world.
		@return  True when propagation is enabled. */
	public static function b2World_IsRestitutionPropagationEnabled(worldId:B2WorldId):Bool {
		throw "not built yet";
	}

	/** Sets the collision speed that generates a hit event.

		The default is set by `B2WorldDef.hitEventThreshold`. Hit events are listed in `B2ContactEvents`.

		@param worldId  The world.
		@param value  The threshold, usually in meters per second. */
	public static function b2World_SetHitEventThreshold(worldId:B2WorldId, value:Float):Void {
		throw "not built yet";
	}

	/** Returns the collision speed that generates a hit event.

		@param worldId  The world.
		@return  The threshold, usually in meters per second. */
	public static function b2World_GetHitEventThreshold(worldId:B2WorldId):Float {
		throw "not built yet";
	}

	/** Registers the callback that decides whether two shapes collide.

		Optional. The callback is called when the broad phase finds a pair of shapes that may collide. It adds to the shapes' filters.

		@param worldId  The world.
		@param fcn  The callback. When null, the callback is removed.
		@param context  A value passed to the callback. */
	public static function b2World_SetCustomFilterCallback(worldId:B2WorldId, fcn:B2CustomFilterCallbackFcn, context:Dynamic):Void {
		throw "not built yet";
	}

	/** Registers the callbacks called before a contact is solved and before continuous collision.

		Optional. The pre-solve callback can disable a contact for a step. The callbacks run during the step, so they must not change the world.

		@param worldId  The world.
		@param preSolveFcn  The pre-solve callback. When null, it is removed.
		@param preContinuousFcn  The pre-continuous callback. When null, it is removed.
		@param context  A value passed to the callbacks. */
	public static function b2World_SetPreSolveCallback(worldId:B2WorldId, preSolveFcn:B2PreSolveCallbackFcn, preContinuousFcn:B2PreContinuousCallbackFcn,
			context:Dynamic):Void {
		throw "not built yet";
	}

	/** Sets the gravity vector of the world.

		Box2D has no up direction. The program chooses one. The default is set by `B2WorldDef.gravity`.

		@param worldId  The world.
		@param gravity  The gravity, usually in meters per second squared. */
	public static function b2World_SetGravity(worldId:B2WorldId, gravity:B2Vec2):Void {
		throw "not built yet";
	}

	/** Returns the gravity vector of the world.

		@param worldId  The world.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The gravity, usually in meters per second squared. */
	public static function b2World_GetGravity(worldId:B2WorldId, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Applies a radial explosion to the bodies around a point.

		@param worldId  The world.
		@param explosionDef  The explosion's position, radius, falloff and strength. */
	public static function b2World_Explode(worldId:B2WorldId, explosionDef:B2ExplosionDef):Void {
		throw "not built yet";
	}

	/** Sets the contact tuning parameters of the world.

		_Note that this is an advanced feature._

		@param worldId  The world.
		@param hertz  The contact stiffness, in cycles per second.
		@param dampingRatio  The contact bounciness, with 1 being critical damping. Non-dimensional.
		@param pushSpeed  The largest speed at which a contact constraint pushes bodies apart, usually in meters per second. */
	public static function b2World_SetContactTuning(worldId:B2WorldId, hertz:Float, dampingRatio:Float, pushSpeed:Float):Void {
		throw "not built yet";
	}

	/** Reads the contact tuning parameters of the world.

		Each parameter is stored at index 0 of its array.

		@param worldId  The world.
		@param hertz  Receives the contact stiffness, in cycles per second.
		@param dampingRatio  Receives the contact damping ratio.
		@param pushSpeed  Receives the largest push speed, usually in meters per second. */
	public static function b2World_GetContactTuning(worldId:B2WorldId, hertz:Array<Float>, dampingRatio:Array<Float>, pushSpeed:Array<Float>):Void {
		throw "not built yet";
	}

	/** Sets the distance within which a contact's points are reused.

		Zero disables contact point recycling.

		@param worldId  The world.
		@param recycleDistance  The distance, usually in meters. */
	public static function b2World_SetContactRecycleDistance(worldId:B2WorldId, recycleDistance:Float):Void {
		throw "not built yet";
	}

	/** Returns the distance within which a contact's points are reused.

		@param worldId  The world.
		@return  The distance, usually in meters. */
	public static function b2World_GetContactRecycleDistance(worldId:B2WorldId):Float {
		throw "not built yet";
	}

	/** Sets the largest speed a body can have.

		@param worldId  The world.
		@param maximumLinearSpeed  The speed, usually in meters per second. */
	public static function b2World_SetMaxLinearSpeed(worldId:B2WorldId, maximumLinearSpeed:Float):Void {
		throw "not built yet";
	}

	/** Returns the largest speed a body can have.

		@param worldId  The world.
		@return  The speed, usually in meters per second. */
	public static function b2World_GetMaxLinearSpeed(worldId:B2WorldId):Float {
		throw "not built yet";
	}

	/** Sets whether constraints are warm started.

		Meant for testing. Disabling warm starting greatly reduces stability and gains no performance.

		@param worldId  The world.
		@param flag  True to enable warm starting. */
	public static function b2World_EnableWarmStarting(worldId:B2WorldId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether constraints are warm started.

		@param worldId  The world.
		@return  True when warm starting is enabled. */
	public static function b2World_IsWarmStartingEnabled(worldId:B2WorldId):Bool {
		throw "not built yet";
	}

	/** Sets whether the solver uses SSE2 even where AVX2 is available.

		Meant for testing.

		@param worldId  The world.
		@param flag  True to use SSE2. */
	public static function b2World_EnableSSE2Fallback(worldId:B2WorldId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns the number of awake bodies.

		@param worldId  The world.
		@return  The count of awake bodies. */
	public static function b2World_GetAwakeBodyCount(worldId:B2WorldId):Int {
		throw "not built yet";
	}

	/** Returns the timings of the most recent step.

		@param worldId  The world.
		@param out  Optional. The `B2Profile` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The profile, with times in milliseconds. */
	public static function b2World_GetProfile(worldId:B2WorldId, ?out:B2Profile):B2Profile {
		throw "not built yet";
	}

	/** Returns the world's counters and sizes.

		@param worldId  The world.
		@param out  Optional. The `B2Counters` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The counters. */
	public static function b2World_GetCounters(worldId:B2WorldId, ?out:B2Counters):B2Counters {
		throw "not built yet";
	}

	/** Returns the largest sizes the world has reached.

		Provide the result in a `B2WorldDef` to avoid allocations and copies while the program runs.

		@param worldId  The world.
		@param out  Optional. The `B2Capacity` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The capacities. */
	public static function b2World_GetMaxCapacity(worldId:B2WorldId, ?out:B2Capacity):B2Capacity {
		throw "not built yet";
	}

	/** Sets the value stored in the world.

		@param worldId  The world.
		@param userData  Any value. */
	public static function b2World_SetUserData(worldId:B2WorldId, userData:Dynamic):Void {
		throw "not built yet";
	}

	/** Returns the value stored in the world.

		@param worldId  The world.
		@return  The value, as it was set. */
	public static function b2World_GetUserData(worldId:B2WorldId):Dynamic {
		throw "not built yet";
	}

	/** Sets the callback that mixes two shapes' friction.

		The callback replaces the default mixing.

		@param worldId  The world.
		@param callback  The callback. When null, the default mixing returns. */
	public static function b2World_SetFrictionCallback(worldId:B2WorldId, callback:B2FrictionCallbackFcn):Void {
		throw "not built yet";
	}

	/** Sets the callback that mixes two shapes' restitution.

		The callback replaces the default mixing.

		@param worldId  The world.
		@param callback  The callback. When null, the default mixing returns. */
	public static function b2World_SetRestitutionCallback(worldId:B2WorldId, callback:B2RestitutionCallbackFcn):Void {
		throw "not built yet";
	}

	/** Sets the number of workers a step spreads its work across.

		The count is clamped to the range [1, `B2_MAX_WORKERS`]. A count above 1 runs Box2D's own threads, and a count of 1 runs the step on the calling thread. The call is refused while the world is locked.

		_Note that in a page the module runs one worker, whatever the count._

		@param worldId  The world.
		@param count  The number of workers. */
	public static function b2World_SetWorkerCount(worldId:B2WorldId, count:Int):Void {
		throw "not built yet";
	}

	/** Returns the number of workers a step spreads its work across.

		Returns 0 when the world id is not valid.

		_Note that in a page the module runs one worker, whatever the count._

		@param worldId  The world.
		@return  The number of workers. */
	public static function b2World_GetWorkerCount(worldId:B2WorldId):Int {
		throw "not built yet";
	}

	/** Rebuilds the broad phase tree of static shapes.

		Meant for Box2D's own testing.

		@param worldId  The world. */
	public static function b2World_RebuildStaticTree(worldId:B2WorldId):Void {
		throw "not built yet";
	}

	/** Returns a hash of the world's simulation state.

		Use it to detect that two simulations differ, for example in rollback resimulation.

		@param worldId  The world.
		@return  The hash. */
	public static function b2World_GetStateHash(worldId:B2WorldId):haxe.Int64 {
		throw "not built yet";
	}

	/** Writes a snapshot of the world's simulation state into a buffer.

		Call with an image whose capacity is 0 to learn the size needed, then again with a buffer of at least that size. Call between steps. Callbacks and user data are not part of a snapshot.

		@param worldId  The world to snapshot.
		@param image  The buffer to write into.
		@param capacity  The size of the buffer, in bytes.
		@return  The number of bytes the snapshot needs. Nothing is written when that exceeds the capacity. 0 when the world is in the middle of a step. */
	public static function b2World_GetSnapshot(worldId:B2WorldId, image:haxe.io.Bytes, capacity:Int):Int {
		throw "not built yet";
	}

	/** Restores a world's simulation state from a snapshot.

		Ids from this world stay valid for objects that existed when the snapshot was written. Callbacks and the worker count are kept. User data on shapes, bodies and joints is cleared.

		@param worldId  The world to restore.
		@param image  A snapshot written by `b2World_GetSnapshot`.
		@param size  The size of the snapshot, in bytes.
		@return  True on success. When the image is rejected, for a bad magic number, version or layout, the world is unchanged. When a corrupt image is found after the rebuild starts, false is returned and the world is unusable, so the program must destroy it. */
	public static function b2World_RestoreFromSnapshot(worldId:B2WorldId, image:haxe.io.Bytes, size:Int):Bool {
		throw "not built yet";
	}

	/** Creates a world from a snapshot.

		Mainly useful for replay. The callbacks are the defaults.

		@param image  A snapshot written by `b2World_GetSnapshot`.
		@param size  The size of the snapshot, in bytes.
		@param workerCount  The new world's number of workers. 0 runs one worker. In a page the module runs one worker, whatever the count.
		@param out  Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new world's id, or `b2_nullWorldId` on failure. */
	public static function b2CreateWorldFromSnapshot(image:haxe.io.Bytes, size:Int, workerCount:Int, ?out:B2WorldId):B2WorldId {
		throw "not built yet";
	}

	/** Creates a rigid body in a world.

		The definition is not retained. A body has no shapes until `b2CreateCircleShape` and the other shape calls add them. Refused and logged during a callback.

		```haxe
		var bodyDef = Box2D.b2DefaultBodyDef();
		var bodyId = Box2D.b2CreateBody(worldId, bodyDef);
		```

		@param worldId  The world.
		@param def  The body's definition. Make it with `b2DefaultBodyDef`.
		@param out  Optional. The `B2BodyId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new body's id. */
	public static function b2CreateBody(worldId:B2WorldId, def:B2BodyDef, ?out:B2BodyId):B2BodyId {
		throw "not built yet";
	}

	/** Destroys a body, with all its shapes and joints.

		The ids of the body's shapes and joints are not valid afterward.

		@param bodyId  The body. */
	public static function b2DestroyBody(bodyId:B2BodyId):Void {
		throw "not built yet";
	}

	/** Returns whether a body id refers to a body that exists.

		Detects an id left over from a body that was destroyed. A null body id is not valid.

		@param id  The body id to check.
		@return  True when the body exists. */
	public static function b2Body_IsValid(id:B2BodyId):Bool {
		throw "not built yet";
	}

	/** Returns the body's type: static, kinematic or dynamic.

		@param bodyId  The body.
		@return  The type. */
	public static function b2Body_GetType(bodyId:B2BodyId):B2BodyType {
		throw "not built yet";
	}

	/** Changes the body's type.

		Expensive. The mass properties are recomputed, whether or not automatic mass is on.

		@param bodyId  The body.
		@param type  The new type. */
	public static function b2Body_SetType(bodyId:B2BodyId, type:B2BodyType):Void {
		throw "not built yet";
	}

	/** Sets the body's name.

		A name longer than `B2_NAME_LENGTH` characters is cut. A null name clears it.

		@param bodyId  The body.
		@param name  The name, for debugging. */
	public static function b2Body_SetName(bodyId:B2BodyId, name:String):Void {
		throw "not built yet";
	}

	/** Returns the body's name.

		@param bodyId  The body.
		@return  The name, empty when none was set. */
	public static function b2Body_GetName(bodyId:B2BodyId):String {
		throw "not built yet";
	}

	/** Sets the value stored in the body.

		@param bodyId  The body.
		@param userData  Any value. */
	public static function b2Body_SetUserData(bodyId:B2BodyId, userData:Dynamic):Void {
		throw "not built yet";
	}

	/** Returns the value stored in the body.

		@param bodyId  The body.
		@return  The value, as it was set. */
	public static function b2Body_GetUserData(bodyId:B2BodyId):Dynamic {
		throw "not built yet";
	}

	/** Returns the position of the body's origin in the world.

		@param bodyId  The body.
		@param out  Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The position. */
	public static function b2Body_GetPosition(bodyId:B2BodyId, ?out:B2Pos):B2Pos {
		throw "not built yet";
	}

	/** Returns the body's rotation in the world.

		@param bodyId  The body.
		@param out  Optional. The `B2Rot` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The rotation, a cosine and sine pair. */
	public static function b2Body_GetRotation(bodyId:B2BodyId, ?out:B2Rot):B2Rot {
		throw "not built yet";
	}

	/** Returns the body's transform in the world.

		@param bodyId  The body.
		@param out  Optional. The `B2WorldTransform` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The transform. */
	public static function b2Body_GetTransform(bodyId:B2BodyId, ?out:B2WorldTransform):B2WorldTransform {
		throw "not built yet";
	}

	/** Moves the body to a position and rotation in the world.

		The body teleports, which is fairly expensive. Prefer creating the body with its intended transform, in `B2BodyDef.position` and `B2BodyDef.rotation`. Refused and logged while the world is locked, during a step or in a callback.

		@param bodyId  The body.
		@param position  The new position of the body's origin.
		@param rotation  The new rotation. */
	public static function b2Body_SetTransform(bodyId:B2BodyId, position:B2Pos, rotation:B2Rot):Void {
		throw "not built yet";
	}

	/** Returns a world point in the body's local space.

		@param bodyId  The body.
		@param worldPoint  The point in world coordinates.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The point in the body's local space. */
	public static function b2Body_GetLocalPoint(bodyId:B2BodyId, worldPoint:B2Pos, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns a point of the body's local space in the world.

		@param bodyId  The body.
		@param localPoint  The point in the body's local space.
		@param out  Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The point in world coordinates. */
	public static function b2Body_GetWorldPoint(bodyId:B2BodyId, localPoint:B2Vec2, ?out:B2Pos):B2Pos {
		throw "not built yet";
	}

	/** Returns a world vector in the body's local space.

		@param bodyId  The body.
		@param worldVector  The vector in world coordinates.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The vector in the body's local space. */
	public static function b2Body_GetLocalVector(bodyId:B2BodyId, worldVector:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns a vector of the body's local space in the world.

		@param bodyId  The body.
		@param localVector  The vector in the body's local space.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The vector in world coordinates. */
	public static function b2Body_GetWorldVector(bodyId:B2BodyId, localVector:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the linear velocity of the body's center of mass.

		@param bodyId  The body.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The velocity, usually in meters per second. */
	public static function b2Body_GetLinearVelocity(bodyId:B2BodyId, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the body's angular velocity.

		@param bodyId  The body.
		@return  The velocity, in radians per second. */
	public static function b2Body_GetAngularVelocity(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Sets the linear velocity of the body's center of mass.

		@param bodyId  The body.
		@param linearVelocity  The velocity, usually in meters per second. */
	public static function b2Body_SetLinearVelocity(bodyId:B2BodyId, linearVelocity:B2Vec2):Void {
		throw "not built yet";
	}

	/** Sets the body's angular velocity.

		@param bodyId  The body.
		@param angularVelocity  The velocity, in radians per second. */
	public static function b2Body_SetAngularVelocity(bodyId:B2BodyId, angularVelocity:Float):Void {
		throw "not built yet";
	}

	/** Sets the body's velocity to reach a transform after a time step.

		The result is close to the target but may not be exact. Meant for kinematic bodies. The target is not applied when the needed velocity is below the sleep threshold and the body is asleep.

		@param bodyId  The body.
		@param target  The transform to reach at the end of the next step.
		@param timeStep  The time step of the next call to `b2World_Step`, in seconds.
		@param wake  True to wake the body. */
	public static function b2Body_SetTargetTransform(bodyId:B2BodyId, target:B2WorldTransform, timeStep:Float, wake:Bool):Void {
		throw "not built yet";
	}

	/** Returns the velocity of a point fixed to the body, in the body's local space.

		@param bodyId  The body.
		@param localPoint  The point in the body's local space.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The velocity, usually in meters per second. */
	public static function b2Body_GetLocalPointVelocity(bodyId:B2BodyId, localPoint:B2Vec2, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the velocity of a point fixed to the body, in world coordinates.

		@param bodyId  The body.
		@param worldPoint  The point in world coordinates.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The velocity, usually in meters per second. */
	public static function b2Body_GetWorldPointVelocity(bodyId:B2BodyId, worldPoint:B2Pos, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Applies a force at a point in the world.

		A force away from the center of mass also produces a torque and changes the angular velocity. The force is ignored when the body is not awake. The force lasts until the next step.

		@param bodyId  The body.
		@param force  The force in world coordinates, usually in newtons.
		@param point  The point of application, in world coordinates.
		@param wake  True to wake the body. */
	public static function b2Body_ApplyForce(bodyId:B2BodyId, force:B2Vec2, point:B2Pos, wake:Bool):Void {
		throw "not built yet";
	}

	/** Applies a force to the body's center of mass.

		The force is ignored when the body is not awake. The force lasts until the next step.

		@param bodyId  The body.
		@param force  The force in world coordinates, usually in newtons.
		@param wake  True to wake the body. */
	public static function b2Body_ApplyForceToCenter(bodyId:B2BodyId, force:B2Vec2, wake:Bool):Void {
		throw "not built yet";
	}

	/** Applies a torque to the body.

		The angular velocity changes and the linear velocity doesn't. The torque is ignored when the body is not awake.

		@param bodyId  The body.
		@param torque  The torque about the z axis, out of the screen, usually in newton meters.
		@param wake  True to wake the body. */
	public static function b2Body_ApplyTorque(bodyId:B2BodyId, torque:Float, wake:Bool):Void {
		throw "not built yet";
	}

	/** Removes the force and torque applied to the body.

		Forces and torques are cleared after each step. The call is for removing the effect of earlier force calls before the step.

		@param bodyId  The body. */
	public static function b2Body_ClearForces(bodyId:B2BodyId):Void {
		throw "not built yet";
	}

	/** Applies an impulse at a point in the world.

		The velocity changes at once. The angular velocity changes too when the point is away from the center of mass. The impulse is ignored when the body is not awake.

		_Note that an impulse is for one-shot use. A steady push works better as a force with the sub-stepping solver._

		@param bodyId  The body.
		@param impulse  The impulse in world coordinates, usually in newton seconds.
		@param point  The point of application, in world coordinates.
		@param wake  True to wake the body. */
	public static function b2Body_ApplyLinearImpulse(bodyId:B2BodyId, impulse:B2Vec2, point:B2Pos, wake:Bool):Void {
		throw "not built yet";
	}

	/** Applies an impulse to the body's center of mass.

		The velocity changes at once. The impulse is ignored when the body is not awake.

		_Note that an impulse is for one-shot use. A steady push works better as a force with the sub-stepping solver._

		@param bodyId  The body.
		@param impulse  The impulse in world coordinates, usually in newton seconds.
		@param wake  True to wake the body. */
	public static function b2Body_ApplyLinearImpulseToCenter(bodyId:B2BodyId, impulse:B2Vec2, wake:Bool):Void {
		throw "not built yet";
	}

	/** Applies an angular impulse to the body.

		The impulse is ignored when the body is not awake.

		_Note that an impulse is for one-shot use. A steady turn works better as a torque with the sub-stepping solver._

		@param bodyId  The body.
		@param impulse  The angular impulse, usually in kilogram meters squared per second.
		@param wake  True to wake the body. */
	public static function b2Body_ApplyAngularImpulse(bodyId:B2BodyId, impulse:Float, wake:Bool):Void {
		throw "not built yet";
	}

	/** Returns the body's mass.

		@param bodyId  The body.
		@return  The mass, usually in kilograms. */
	public static function b2Body_GetMass(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Returns the body's rotational inertia.

		@param bodyId  The body.
		@return  The inertia, usually in kilogram meters squared. */
	public static function b2Body_GetRotationalInertia(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Returns the body's center of mass in its local space.

		@param bodyId  The body.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The center of mass. */
	public static function b2Body_GetLocalCenter(bodyId:B2BodyId, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the body's center of mass in the world.

		@param bodyId  The body.
		@param out  Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The center of mass, in world coordinates. */
	public static function b2Body_GetWorldCenter(bodyId:B2BodyId, ?out:B2Pos):B2Pos {
		throw "not built yet";
	}

	/** Overrides the body's mass properties.

		Box2D normally computes them from the shapes and their density. Adding or removing a shape, or changing the body's type, discards the override. When motion locks fix rotation, the rotational inertia stays zero and the value provided is ignored.

		@param bodyId  The body.
		@param massData  The mass, center of mass and rotational inertia. */
	public static function b2Body_SetMassData(bodyId:B2BodyId, massData:B2MassData):Void {
		throw "not built yet";
	}

	/** Returns the body's mass data.

		@param bodyId  The body.
		@param out  Optional. The `B2MassData` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The mass, center of mass and rotational inertia. */
	public static function b2Body_GetMassData(bodyId:B2BodyId, ?out:B2MassData):B2MassData {
		throw "not built yet";
	}

	/** Recomputes the body's mass properties from its shapes.

		Needed to undo an override from `b2Body_SetMassData`, or when automatic mass computation is off. Call it for a body of any type. Sensor shapes may have mass.

		@param bodyId  The body. */
	public static function b2Body_UpdateMassFromShapes(bodyId:B2BodyId):Void {
		throw "not built yet";
	}

	/** Sets the body's linear damping.

		Normally set in `B2BodyDef` before the body is created.

		@param bodyId  The body.
		@param linearDamping  The damping, non-negative. */
	public static function b2Body_SetLinearDamping(bodyId:B2BodyId, linearDamping:Float):Void {
		throw "not built yet";
	}

	/** Returns the body's linear damping.

		@param bodyId  The body.
		@return  The damping. */
	public static function b2Body_GetLinearDamping(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Sets the body's angular damping.

		Normally set in `B2BodyDef` before the body is created.

		@param bodyId  The body.
		@param angularDamping  The damping, non-negative. */
	public static function b2Body_SetAngularDamping(bodyId:B2BodyId, angularDamping:Float):Void {
		throw "not built yet";
	}

	/** Returns the body's angular damping.

		@param bodyId  The body.
		@return  The damping. */
	public static function b2Body_GetAngularDamping(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Sets the factor that scales gravity on the body.

		Normally set in `B2BodyDef.gravityScale` before the body is created.

		@param bodyId  The body.
		@param gravityScale  The factor, 1 for full gravity. */
	public static function b2Body_SetGravityScale(bodyId:B2BodyId, gravityScale:Float):Void {
		throw "not built yet";
	}

	/** Returns the factor that scales gravity on the body.

		@param bodyId  The body.
		@return  The factor. */
	public static function b2Body_GetGravityScale(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Returns whether the body is awake.

		@param bodyId  The body.
		@return  True when the body is awake. */
	public static function b2Body_IsAwake(bodyId:B2BodyId):Bool {
		throw "not built yet";
	}

	/** Wakes the body, or puts it to sleep.

		Waking a body wakes the whole island of bodies touching it. Putting a body to sleep puts that whole island to sleep, which can be expensive. Refused and logged while the world is locked, during a step or in a callback.

		@param bodyId  The body.
		@param awake  True to wake the body, false to put it to sleep. */
	public static function b2Body_SetAwake(bodyId:B2BodyId, awake:Bool):Void {
		throw "not built yet";
	}

	/** Wakes the bodies touching the body.

		Works for static bodies.

		@param bodyId  The body. */
	public static function b2Body_WakeTouching(bodyId:B2BodyId):Void {
		throw "not built yet";
	}

	/** Sets whether the body can fall asleep.

		Disabling sleep wakes the body and its island.

		@param bodyId  The body.
		@param enableSleep  True to let the body sleep. */
	public static function b2Body_EnableSleeping(bodyId:B2BodyId, enableSleep:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the body can fall asleep.

		@param bodyId  The body.
		@return  True when sleeping is enabled. */
	public static function b2Body_IsSleepingEnabled(bodyId:B2BodyId):Bool {
		throw "not built yet";
	}

	/** Sets the speed below which the body can fall asleep.

		@param bodyId  The body.
		@param sleepThreshold  The threshold, usually in meters per second. */
	public static function b2Body_SetSleepThreshold(bodyId:B2BodyId, sleepThreshold:Float):Void {
		throw "not built yet";
	}

	/** Returns the speed below which the body can fall asleep.

		@param bodyId  The body.
		@return  The threshold, usually in meters per second. */
	public static function b2Body_GetSleepThreshold(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Sets the body's continuous collision safety factor.

		A smaller factor is safer and can cause hitching. The recommended range is [0.01, 0.5].

		@param bodyId  The body.
		@param safetyFactor  The factor, non-dimensional. */
	public static function b2Body_SetSafetyFactor(bodyId:B2BodyId, safetyFactor:Float):Void {
		throw "not built yet";
	}

	/** Returns the body's continuous collision safety factor.

		@param bodyId  The body.
		@return  The factor, non-dimensional. */
	public static function b2Body_GetSafetyFactor(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Returns whether the body is enabled.

		@param bodyId  The body.
		@return  True when the body is enabled. */
	public static function b2Body_IsEnabled(bodyId:B2BodyId):Bool {
		throw "not built yet";
	}

	/** Removes the body from the simulation.

		Expensive. The body keeps its shapes and joints, and `b2Body_Enable` adds it back.

		@param bodyId  The body. */
	public static function b2Body_Disable(bodyId:B2BodyId):Void {
		throw "not built yet";
	}

	/** Adds a disabled body back to the simulation.

		Expensive.

		@param bodyId  The body. */
	public static function b2Body_Enable(bodyId:B2BodyId):Void {
		throw "not built yet";
	}

	/** Sets which motions of the body are locked.

		The mass properties are recomputed, since a locked rotation sets the rotational inertia to zero.

		@param bodyId  The body.
		@param locks  The locks. */
	public static function b2Body_SetMotionLocks(bodyId:B2BodyId, locks:B2MotionLocks):Void {
		throw "not built yet";
	}

	/** Returns which motions of the body are locked.

		@param bodyId  The body.
		@param out  Optional. The `B2MotionLocks` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The locks. */
	public static function b2Body_GetMotionLocks(bodyId:B2BodyId, ?out:B2MotionLocks):B2MotionLocks {
		throw "not built yet";
	}

	/** Sets whether the body is a bullet.

		A bullet gets continuous collision against dynamic and kinematic bodies, but not against other bullets. Only dynamic bodies can be bullets.

		@param bodyId  The body.
		@param flag  True to make the body a bullet. */
	public static function b2Body_SetBullet(bodyId:B2BodyId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the body is a bullet.

		@param bodyId  The body.
		@return  True when the body is a bullet. */
	public static function b2Body_IsBullet(bodyId:B2BodyId):Bool {
		throw "not built yet";
	}

	/** Sets whether the body's contacts reuse their manifolds when the body moves slightly.

		Recycling saves work. Disabling it can avoid ghost collisions on characters, at the cost of more work each step. Contacts that exist keep their setting. Contacts created after the call use the new one. The default is set by `B2BodyDef.enableContactRecycling`.

		@param bodyId  The body.
		@param flag  True to enable contact recycling. */
	public static function b2Body_EnableContactRecycling(bodyId:B2BodyId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the body's contacts reuse their manifolds.

		@param bodyId  The body.
		@return  True when contact recycling is enabled. */
	public static function b2Body_IsContactRecyclingEnabled(bodyId:B2BodyId):Bool {
		throw "not built yet";
	}

	/** Sets whether all the body's shapes generate contact events.

		Each shape's setting is `B2ShapeDef.enableContactEvents`. _Note that changing this while the world runs can leave begin and end touch events unpaired._

		@param bodyId  The body.
		@param flag  True to enable contact events. */
	public static function b2Body_EnableContactEvents(bodyId:B2BodyId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Sets whether all the body's shapes generate hit events.

		Each shape's setting is `B2ShapeDef.enableHitEvents`.

		@param bodyId  The body.
		@param flag  True to enable hit events. */
	public static function b2Body_EnableHitEvents(bodyId:B2BodyId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns the world that holds the body.

		@param bodyId  The body.
		@param out  Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The world's id. */
	public static function b2Body_GetWorld(bodyId:B2BodyId, ?out:B2WorldId):B2WorldId {
		throw "not built yet";
	}

	/** Returns the number of shapes on the body.

		@param bodyId  The body.
		@return  The count of shapes. */
	public static function b2Body_GetShapeCount(bodyId:B2BodyId):Int {
		throw "not built yet";
	}

	/** Fills an array with the ids of the body's shapes, up to a capacity.

		A capacity of `b2Body_GetShapeCount` holds them all.

		@param bodyId  The body.
		@param shapeArray  The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
		@param capacity  The most to store.
		@return  The number of ids stored in the array. */
	public static function b2Body_GetShapes(bodyId:B2BodyId, shapeArray:Array<B2ShapeId>, capacity:Int):Int {
		throw "not built yet";
	}

	/** Returns the number of joints on the body.

		@param bodyId  The body.
		@return  The count of joints. */
	public static function b2Body_GetJointCount(bodyId:B2BodyId):Int {
		throw "not built yet";
	}

	/** Fills an array with the ids of the body's joints, up to a capacity.

		A capacity of `b2Body_GetJointCount` holds them all.

		@param bodyId  The body.
		@param jointArray  The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
		@param capacity  The most to store.
		@return  The number of ids stored in the array. */
	public static function b2Body_GetJoints(bodyId:B2BodyId, jointArray:Array<B2JointId>, capacity:Int):Int {
		throw "not built yet";
	}

	/** Returns the capacity needed to read all the touching contacts of the body.

		@param bodyId  The body.
		@return  The capacity. */
	public static function b2Body_GetContactCapacity(bodyId:B2BodyId):Int {
		throw "not built yet";
	}

	/** Fills an array with the body's touching contacts, up to a capacity.

		Box2D uses speculative collision, so some contact points may be separated.

		_Note that only the elements below the returned count are valid._

		@param bodyId  The body.
		@param contactData  The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
		@param capacity  The most to store.
		@return  The number of contacts stored in the array. */
	public static function b2Body_GetContactData(bodyId:B2BodyId, contactData:Array<B2ContactData>, capacity:Int):Int {
		throw "not built yet";
	}

	/** Returns the world bounds of all the body's shapes.

		The bounds may not contain the body's origin. When the body has no shapes, the bounds are empty and centered on the origin.

		@param bodyId  The body.
		@param out  Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The bounds, in world coordinates. */
	public static function b2Body_ComputeBounds(bodyId:B2BodyId, ?out:B2AABB):B2AABB {
		throw "not built yet";
	}

	/** Returns the smallest distance from any point on the body's shapes to its center of mass.

		@param bodyId  The body.
		@return  The distance. */
	public static function b2Body_GetMinExtent(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Returns the largest distance from any point on the body's shapes to its center of mass.

		@param bodyId  The body.
		@return  The distance. */
	public static function b2Body_GetMaxExtent(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Returns an upper bound on the distance from any point on the body's shapes to the body's origin.

		@param bodyId  The body.
		@return  The distance, conservative. */
	public static function b2Body_GetMaxExtentFromOrigin(bodyId:B2BodyId):Float {
		throw "not built yet";
	}

	/** Creates a circle shape and attaches it to a body.

		The shape definition and the circle are copied. Contacts are created at the next step.

		Returns `b2_nullShapeId` when the circle is invalid.

		@param bodyId  The body to attach the shape to.
		@param def  The shape's definition.
		@param circle  The circle, in the body's local space.
		@param out  Optional. The `B2ShapeId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new shape's id, or `b2_nullShapeId` when the circle is invalid. */
	public static function b2CreateCircleShape(bodyId:B2BodyId, def:B2ShapeDef, circle:B2Circle, ?out:B2ShapeId):B2ShapeId {
		throw "not built yet";
	}

	/** Creates a line segment shape and attaches it to a body.

		The shape definition and the segment are copied. Contacts are created at the next step.

		@param bodyId  The body to attach the shape to.
		@param def  The shape's definition.
		@param segment  The segment, in the body's local space.
		@param out  Optional. The `B2ShapeId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new shape's id, or `b2_nullShapeId` when the segment is too short. */
	public static function b2CreateSegmentShape(bodyId:B2BodyId, def:B2ShapeDef, segment:B2Segment, ?out:B2ShapeId):B2ShapeId {
		throw "not built yet";
	}

	/** Creates a loose chain segment shape and attaches it to a body.

		The shape definition and the chain segment are copied. Contacts are created at the next step.

		The segment belongs to no chain, so `b2Shape_GetParentChain` returns `b2_nullChainId` for it. Its `chainId` field is ignored.

		A loose chain segment uses more memory than the segments of a chain made by `b2CreateChain`, which is preferred.

		@param bodyId  The body to attach the shape to.
		@param def  The shape's definition.
		@param chainSegment  The chain segment, in the body's local space.
		@param out  Optional. The `B2ShapeId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new shape's id, or `b2_nullShapeId` when the segment is too short. */
	public static function b2CreateChainSegmentShape(bodyId:B2BodyId, def:B2ShapeDef, chainSegment:B2ChainSegment, ?out:B2ShapeId):B2ShapeId {
		throw "not built yet";
	}

	/** Creates a capsule shape and attaches it to a body.

		The shape definition and the capsule are copied. Contacts are created at the next step.

		@param bodyId  The body to attach the shape to.
		@param def  The shape's definition.
		@param capsule  The capsule, in the body's local space.
		@param out  Optional. The `B2ShapeId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new shape's id, or `b2_nullShapeId` when the capsule's length is too small. */
	public static function b2CreateCapsuleShape(bodyId:B2BodyId, def:B2ShapeDef, capsule:B2Capsule, ?out:B2ShapeId):B2ShapeId {
		throw "not built yet";
	}

	/** Creates a convex polygon shape and attaches it to a body.

		The shape definition and the polygon are copied. Contacts are created at the next step.

		Returns `b2_nullShapeId` when the polygon is invalid.

		@param bodyId  The body to attach the shape to.
		@param def  The shape's definition.
		@param polygon  The polygon, in the body's local space.
		@param out  Optional. The `B2ShapeId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new shape's id, or `b2_nullShapeId` when the polygon is invalid. */
	public static function b2CreatePolygonShape(bodyId:B2BodyId, def:B2ShapeDef, polygon:B2Polygon, ?out:B2ShapeId):B2ShapeId {
		throw "not built yet";
	}

	/** Destroys a shape.

		Destroying several shapes of one body with `updateBodyMass` false, then calling `b2Body_UpdateMassFromShapes` once, costs less than updating the body's mass at each destruction.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param updateBodyMass  Whether to update the body's mass data now. */
	public static function b2DestroyShape(shapeId:B2ShapeId, updateBodyMass:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether a shape id refers to a shape that exists.

		Validates up to 64K allocations.

		@param id  The shape id.
		@return  True when the shape exists. */
	public static function b2Shape_IsValid(id:B2ShapeId):Bool {
		throw "not built yet";
	}

	/** Returns the type of a shape.

		@param shapeId  The shape.
		@return  The shape's type. */
	public static function b2Shape_GetType(shapeId:B2ShapeId):B2ShapeType {
		throw "not built yet";
	}

	/** Returns the id of the body a shape is attached to.

		@param shapeId  The shape.
		@param out  Optional. The `B2BodyId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The body's id. */
	public static function b2Shape_GetBody(shapeId:B2ShapeId, ?out:B2BodyId):B2BodyId {
		throw "not built yet";
	}

	/** Returns the id of the world that owns a shape.

		@param shapeId  The shape.
		@param out  Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The world's id. */
	public static function b2Shape_GetWorld(shapeId:B2ShapeId, ?out:B2WorldId):B2WorldId {
		throw "not built yet";
	}

	/** Returns whether a shape is a sensor.

		A shape can't be changed between sensor and solid after creation, since that would break the contract for sensor events.

		@param shapeId  The shape.
		@return  True when the shape is a sensor. */
	public static function b2Shape_IsSensor(shapeId:B2ShapeId):Bool {
		throw "not built yet";
	}

	/** Sets the user data of a shape.

		@param shapeId  The shape.
		@param userData  Any Haxe value, returned as set by `b2Shape_GetUserData`. */
	public static function b2Shape_SetUserData(shapeId:B2ShapeId, userData:Dynamic):Void {
		throw "not built yet";
	}

	/** Returns the user data of a shape.

		Useful for finding the program's object from a shape id received in an event or a query.

		@param shapeId  The shape.
		@return  The value set by `b2Shape_SetUserData`, or null when none was set. */
	public static function b2Shape_GetUserData(shapeId:B2ShapeId):Dynamic {
		throw "not built yet";
	}

	/** Sets the mass density of a shape, in kg/m^2.

		Updating the body's mass data is optional. See `B2ShapeDef` for the density and `b2Body_UpdateMassFromShapes` for updating the mass later.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param density  The density in kg/m^2, zero or more.
		@param updateBodyMass  Whether to update the body's mass data now. */
	public static function b2Shape_SetDensity(shapeId:B2ShapeId, density:Float, updateBodyMass:Bool):Void {
		throw "not built yet";
	}

	/** Returns the mass density of a shape, in kg/m^2.

		@param shapeId  The shape.
		@return  The density. */
	public static function b2Shape_GetDensity(shapeId:B2ShapeId):Float {
		throw "not built yet";
	}

	/** Sets the friction of a shape.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param friction  The friction coefficient, zero or more. */
	public static function b2Shape_SetFriction(shapeId:B2ShapeId, friction:Float):Void {
		throw "not built yet";
	}

	/** Returns the friction of a shape.

		@param shapeId  The shape.
		@return  The friction coefficient. */
	public static function b2Shape_GetFriction(shapeId:B2ShapeId):Float {
		throw "not built yet";
	}

	/** Sets the restitution (bounciness) of a shape.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param restitution  The restitution, normally from 0 to 1. */
	public static function b2Shape_SetRestitution(shapeId:B2ShapeId, restitution:Float):Void {
		throw "not built yet";
	}

	/** Returns the restitution (bounciness) of a shape.

		@param shapeId  The shape.
		@return  The restitution. */
	public static function b2Shape_GetRestitution(shapeId:B2ShapeId):Float {
		throw "not built yet";
	}

	/** Sets the user material identifier of a shape.

		Box2D passes the identifier through to the program's callbacks and doesn't interpret it.

		@param shapeId  The shape.
		@param material  The identifier. */
	public static function b2Shape_SetUserMaterial(shapeId:B2ShapeId, material:haxe.Int64):Void {
		throw "not built yet";
	}

	/** Returns the user material identifier of a shape.

		@param shapeId  The shape.
		@return  The identifier. */
	public static function b2Shape_GetUserMaterial(shapeId:B2ShapeId):haxe.Int64 {
		throw "not built yet";
	}

	/** Sets the surface material of a shape.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param surfaceMaterial  The new surface material. */
	public static function b2Shape_SetSurfaceMaterial(shapeId:B2ShapeId, surfaceMaterial:B2SurfaceMaterial):Void {
		throw "not built yet";
	}

	/** Returns the surface material of a shape.

		@param shapeId  The shape.
		@param out  Optional. The `B2SurfaceMaterial` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The surface material. */
	public static function b2Shape_GetSurfaceMaterial(shapeId:B2ShapeId, ?out:B2SurfaceMaterial):B2SurfaceMaterial {
		throw "not built yet";
	}

	/** Returns the collision filter of a shape.

		@param shapeId  The shape.
		@param out  Optional. The `B2Filter` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The filter. */
	public static function b2Shape_GetFilter(shapeId:B2ShapeId, ?out:B2Filter):B2Filter {
		throw "not built yet";
	}

	/** Sets the collision filter of a shape.

		Costs almost as much as recreating the shape. Contacts that no longer pass the filter are destroyed at once. New contacts are created at the next step, and the sensor overlaps are updated then too.

		See `B2ShapeDef` for the filter.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param filter  The new filter. */
	public static function b2Shape_SetFilter(shapeId:B2ShapeId, filter:B2Filter):Void {
		throw "not built yet";
	}

	/** Sets whether a shape generates sensor events.

		See `B2ShapeDef`'s `enableSensorEvents`.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param flag  True to generate sensor events. */
	public static function b2Shape_EnableSensorEvents(shapeId:B2ShapeId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether a shape generates sensor events.

		@param shapeId  The shape.
		@return  True when sensor events are enabled. */
	public static function b2Shape_AreSensorEventsEnabled(shapeId:B2ShapeId):Bool {
		throw "not built yet";
	}

	/** Sets whether a shape generates contact begin and end events.

		Applies to shapes on kinematic and dynamic bodies, and is ignored for sensors.

		_Note that changing this while contacts exist may lose begin and end events._

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param flag  True to generate contact events. */
	public static function b2Shape_EnableContactEvents(shapeId:B2ShapeId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether a shape generates contact begin and end events.

		@param shapeId  The shape.
		@return  True when contact events are enabled. */
	public static function b2Shape_AreContactEventsEnabled(shapeId:B2ShapeId):Bool {
		throw "not built yet";
	}

	/** Sets whether a shape calls the pre-solve callback.

		Applies to shapes on dynamic bodies, and is ignored for sensors. Pre-solve calls are expensive and, as the solver is multithreaded, must be handled with care. See `b2PreSolveCallbackFcn`.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param flag  True to call the pre-solve callback. */
	public static function b2Shape_EnablePreSolveEvents(shapeId:B2ShapeId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether a shape calls the pre-solve callback.

		@param shapeId  The shape.
		@return  True when pre-solve events are enabled. */
	public static function b2Shape_ArePreSolveEventsEnabled(shapeId:B2ShapeId):Bool {
		throw "not built yet";
	}

	/** Sets whether a shape generates contact hit events.

		Ignored for sensors. A hit is reported when the approach speed exceeds `B2WorldDef`'s `hitEventThreshold`.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param flag  True to generate hit events. */
	public static function b2Shape_EnableHitEvents(shapeId:B2ShapeId, flag:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether a shape generates contact hit events.

		@param shapeId  The shape.
		@return  True when hit events are enabled. */
	public static function b2Shape_AreHitEventsEnabled(shapeId:B2ShapeId):Bool {
		throw "not built yet";
	}

	/** Returns whether a world point overlaps a shape.

		@param shapeId  The shape.
		@param point  The point, in world space.
		@return  True when the point is inside the shape. */
	public static function b2Shape_TestPoint(shapeId:B2ShapeId, point:B2Pos):Bool {
		throw "not built yet";
	}

	/** Casts a ray against a single shape.

		The ray starts at the origin and extends by the translation. The output point is a world position.

		@param shapeId  The shape.
		@param origin  The ray's start, in world space.
		@param translation  The ray's displacement, in meters.
		@param out  Optional. The `B2WorldCastOutput` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The cast result. */
	public static function b2Shape_CastRay(shapeId:B2ShapeId, origin:B2Pos, translation:B2Vec2, ?out:B2WorldCastOutput):B2WorldCastOutput {
		throw "not built yet";
	}

	/** Returns a copy of the circle of a circle shape.

		Asserts that the shape is a circle.

		@param shapeId  The shape.
		@param out  Optional. The `B2Circle` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The circle, in the body's local space. */
	public static function b2Shape_GetCircle(shapeId:B2ShapeId, ?out:B2Circle):B2Circle {
		throw "not built yet";
	}

	/** Returns a copy of the segment of a segment shape.

		Asserts that the shape is a segment.

		@param shapeId  The shape.
		@param out  Optional. The `B2Segment` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The segment, in the body's local space. */
	public static function b2Shape_GetSegment(shapeId:B2ShapeId, ?out:B2Segment):B2Segment {
		throw "not built yet";
	}

	/** Returns a copy of the chain segment of a chain segment shape.

		Chain segment shapes come from chains and from `b2CreateChainSegmentShape`. Asserts that the shape is a chain segment.

		@param shapeId  The shape.
		@param out  Optional. The `B2ChainSegment` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The chain segment, in the body's local space. */
	public static function b2Shape_GetChainSegment(shapeId:B2ShapeId, ?out:B2ChainSegment):B2ChainSegment {
		throw "not built yet";
	}

	/** Returns a copy of the capsule of a capsule shape.

		Asserts that the shape is a capsule.

		@param shapeId  The shape.
		@param out  Optional. The `B2Capsule` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The capsule, in the body's local space. */
	public static function b2Shape_GetCapsule(shapeId:B2ShapeId, ?out:B2Capsule):B2Capsule {
		throw "not built yet";
	}

	/** Returns a copy of the convex polygon of a polygon shape.

		Asserts that the shape is a polygon.

		@param shapeId  The shape.
		@param out  Optional. The `B2Polygon` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The polygon, in the body's local space. */
	public static function b2Shape_GetPolygon(shapeId:B2ShapeId, ?out:B2Polygon):B2Polygon {
		throw "not built yet";
	}

	/** Changes a shape into a circle, or updates its circle.

		The body's mass data is not updated. See `b2Body_UpdateMassFromShapes`.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param circle  The circle, in the body's local space. */
	public static function b2Shape_SetCircle(shapeId:B2ShapeId, circle:B2Circle):Void {
		throw "not built yet";
	}

	/** Changes a shape into a capsule, or updates its capsule.

		The body's mass data is not updated. See `b2Body_UpdateMassFromShapes`.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param capsule  The capsule, in the body's local space. */
	public static function b2Shape_SetCapsule(shapeId:B2ShapeId, capsule:B2Capsule):Void {
		throw "not built yet";
	}

	/** Changes a shape into a segment, or updates its segment.

		The body's mass data is not updated. See `b2Body_UpdateMassFromShapes`.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param segment  The segment, in the body's local space. */
	public static function b2Shape_SetSegment(shapeId:B2ShapeId, segment:B2Segment):Void {
		throw "not built yet";
	}

	/** Changes a shape into a polygon, or updates its polygon.

		The body's mass data is not updated. See `b2Body_UpdateMassFromShapes`.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param polygon  The polygon, in the body's local space. */
	public static function b2Shape_SetPolygon(shapeId:B2ShapeId, polygon:B2Polygon):Void {
		throw "not built yet";
	}

	/** Changes a shape into a loose chain segment, or updates its chain segment.

		The shape then belongs to no chain. Asserts when the shape is a chain segment owned by a chain.

		The body's mass data is not updated. See `b2Body_UpdateMassFromShapes`.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param chainSegment  The chain segment, in the body's local space. */
	public static function b2Shape_SetChainSegment(shapeId:B2ShapeId, chainSegment:B2ChainSegment):Void {
		throw "not built yet";
	}

	/** Returns the chain a chain segment shape belongs to.

		@param shapeId  The shape.
		@param out  Optional. The `B2ChainId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The chain's id, or `b2_nullChainId` when the shape isn't a chain segment of a chain. */
	public static function b2Shape_GetParentChain(shapeId:B2ShapeId, ?out:B2ChainId):B2ChainId {
		throw "not built yet";
	}

	/** Returns the capacity needed to retrieve all the touching contacts of a shape.

		Pass the result as the capacity of `b2Shape_GetContactData`.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@return  The number of contacts on the shape's body, which is at least the number of touching contacts of the shape. Returns 0 for a sensor shape. */
	public static function b2Shape_GetContactCapacity(shapeId:B2ShapeId):Int {
		throw "not built yet";
	}

	/** Fills an array with the touching contacts of a shape.

		The shape is `shapeIdA` or `shapeIdB` in each contact. Box2D collides speculatively, so some contact points may be separated.

		Returns 0 for a sensor shape.

		_Note that only the elements before the returned count are valid._

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The shape.
		@param contactData  The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
		@param capacity  The most to store.
		@return  The number of elements filled. */
	public static function b2Shape_GetContactData(shapeId:B2ShapeId, contactData:Array<B2ContactData>, capacity:Int):Int {
		throw "not built yet";
	}

	/** Returns the capacity needed to retrieve all the shapes overlapping a sensor shape.

		Returns 0 when the shape isn't a sensor.

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The sensor shape.
		@return  The capacity `b2Shape_GetSensorData` needs to return every overlap. */
	public static function b2Shape_GetSensorCapacity(shapeId:B2ShapeId):Int {
		throw "not built yet";
	}

	/** Fills an array with the shapes that overlapped a sensor shape at the previous step.

		Returns 0 when the shape isn't a sensor.

		_Note that the overlaps may include destroyed shapes, so confirm each with `b2Shape_IsValid`. Only the elements before the returned count are valid._

		Refused while the world is stepping, such as from a callback.

		@param shapeId  The sensor shape.
		@param visitorIds  The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
		@param capacity  The most to store.
		@return  The number of elements filled. */
	public static function b2Shape_GetSensorData(shapeId:B2ShapeId, visitorIds:Array<B2ShapeId>, capacity:Int):Int {
		throw "not built yet";
	}

	/** Returns the current bounding box of a shape, in world space.

		@param shapeId  The shape.
		@param out  Optional. The `B2AABB` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The bounding box. */
	public static function b2Shape_GetBounds(shapeId:B2ShapeId, ?out:B2AABB):B2AABB {
		throw "not built yet";
	}

	/** Computes the mass data of a shape from its geometry and density.

		@param shapeId  The shape.
		@param out  Optional. The `B2MassData` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The mass data, in the body's local space. */
	public static function b2Shape_ComputeMassData(shapeId:B2ShapeId, ?out:B2MassData):B2MassData {
		throw "not built yet";
	}

	/** Returns the point on a shape closest to a target point.

		The target and the result are world positions.

		@param shapeId  The shape.
		@param target  The target point, in world space.
		@param out  Optional. The `B2Pos` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The closest point, in world space. */
	public static function b2Shape_GetClosestPoint(shapeId:B2ShapeId, target:B2Pos, ?out:B2Pos):B2Pos {
		throw "not built yet";
	}

	/** Applies a wind force to the body of a shape, using the density of air.

		The force depends on the shape's area projected along the wind direction and on the shape's velocity relative to the wind. Applies to circle, capsule and polygon shapes on dynamic bodies.

		@param shapeId  The shape.
		@param wind  The wind velocity, in world space.
		@param drag  The drag coefficient, for the force that opposes the relative velocity.
		@param lift  The lift coefficient, for the force perpendicular to the relative velocity.
		@param wake  Whether to wake the body when it sleeps. */
	public static function b2Shape_ApplyWind(shapeId:B2ShapeId, wind:B2Vec2, drag:Float, lift:Float, wake:Bool):Void {
		throw "not built yet";
	}

	/** Creates a chain shape and attaches it to a body.

		The chain makes one chain segment shape for each segment, with ghost vertices at its ends and at the seam of a loop. See `B2ChainDef` for the points and the materials.

		Refused while the world is stepping, such as from a callback.

		@param bodyId  The body to attach the chain to.
		@param def  The chain's definition.
		@param out  Optional. The `B2ChainId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new chain's id. */
	public static function b2CreateChain(bodyId:B2BodyId, def:B2ChainDef, ?out:B2ChainId):B2ChainId {
		throw "not built yet";
	}

	/** Destroys a chain shape and its segment shapes.

		Refused while the world is stepping, such as from a callback.

		@param chainId  The chain. */
	public static function b2DestroyChain(chainId:B2ChainId):Void {
		throw "not built yet";
	}

	/** Returns the id of the world that owns a chain shape.

		@param chainId  The chain.
		@param out  Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The world's id. */
	public static function b2Chain_GetWorld(chainId:B2ChainId, ?out:B2WorldId):B2WorldId {
		throw "not built yet";
	}

	/** Returns the number of segments of a chain shape.

		@param chainId  The chain.
		@return  The segment count. */
	public static function b2Chain_GetSegmentCount(chainId:B2ChainId):Int {
		throw "not built yet";
	}

	/** Fills an array with the segment shape ids of a chain shape.

		Refused while the world is stepping, such as from a callback.

		@param chainId  The chain.
		@param segmentArray  The array to fill from index 0. Elements it holds are reused, and missing ones are made, so an empty array serves.
		@param capacity  The most to store.
		@return  The number of elements filled. */
	public static function b2Chain_GetSegments(chainId:B2ChainId, segmentArray:Array<B2ShapeId>, capacity:Int):Int {
		throw "not built yet";
	}

	/** Sets the surface material of every segment of a chain shape.

		Refused while the world is stepping, such as from a callback.

		@param chainId  The chain.
		@param material  The surface material. */
	public static function b2Chain_SetAllSurfaceMaterials(chainId:B2ChainId, material:B2SurfaceMaterial):Void {
		throw "not built yet";
	}

	/** Sets the surface material of one segment of a chain shape.

		Refused while the world is stepping, such as from a callback.

		@param chainId  The chain.
		@param material  The surface material, copied into the segment.
		@param segmentIndex  The index of the segment, from 0 up to the segment count. */
	public static function b2Chain_SetSurfaceMaterial(chainId:B2ChainId, material:B2SurfaceMaterial, segmentIndex:Int):Void {
		throw "not built yet";
	}

	/** Returns the surface material of one segment of a chain shape.

		@param chainId  The chain.
		@param segmentIndex  The index of the segment, from 0 up to the segment count.
		@param out  Optional. The `B2SurfaceMaterial` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The surface material. */
	public static function b2Chain_GetSurfaceMaterial(chainId:B2ChainId, segmentIndex:Int, ?out:B2SurfaceMaterial):B2SurfaceMaterial {
		throw "not built yet";
	}

	/** Returns whether a chain id refers to a chain shape that exists.

		Validates up to 64K allocations.

		@param id  The chain id.
		@return  True when the chain exists. */
	public static function b2Chain_IsValid(id:B2ChainId):Bool {
		throw "not built yet";
	}

	/** Destroys a joint.

		Refused while the world is stepping, such as from a callback.

		@param jointId  The joint. */
	public static function b2DestroyJoint(jointId:B2JointId):Void {
		throw "not built yet";
	}

	/** Returns whether a joint id refers to a joint that exists.

		Validates up to 64K allocations.

		@param id  The joint id.
		@return  True when the joint exists. */
	public static function b2Joint_IsValid(id:B2JointId):Bool {
		throw "not built yet";
	}

	/** Returns the type of a joint.

		@param jointId  The joint.
		@return  The joint's type. */
	public static function b2Joint_GetType(jointId:B2JointId):B2JointType {
		throw "not built yet";
	}

	/** Returns the id of body A of a joint.

		@param jointId  The joint.
		@param out  Optional. The `B2BodyId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  Body A's id. */
	public static function b2Joint_GetBodyA(jointId:B2JointId, ?out:B2BodyId):B2BodyId {
		throw "not built yet";
	}

	/** Returns the id of body B of a joint.

		@param jointId  The joint.
		@param out  Optional. The `B2BodyId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  Body B's id. */
	public static function b2Joint_GetBodyB(jointId:B2JointId, ?out:B2BodyId):B2BodyId {
		throw "not built yet";
	}

	/** Returns the id of the world that owns a joint.

		@param jointId  The joint.
		@param out  Optional. The `B2WorldId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The world's id. */
	public static function b2Joint_GetWorld(jointId:B2JointId, ?out:B2WorldId):B2WorldId {
		throw "not built yet";
	}

	/** Sets the frame of a joint on body A.

		The frame is a position and rotation in body A's local space.

		@param jointId  The joint.
		@param localFrame  The frame, in body A's local space. */
	public static function b2Joint_SetLocalFrameA(jointId:B2JointId, localFrame:B2Transform):Void {
		throw "not built yet";
	}

	/** Returns the frame of a joint on body A.

		@param jointId  The joint.
		@param out  Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The frame, in body A's local space. */
	public static function b2Joint_GetLocalFrameA(jointId:B2JointId, ?out:B2Transform):B2Transform {
		throw "not built yet";
	}

	/** Sets the frame of a joint on body B.

		The frame is a position and rotation in body B's local space.

		@param jointId  The joint.
		@param localFrame  The frame, in body B's local space. */
	public static function b2Joint_SetLocalFrameB(jointId:B2JointId, localFrame:B2Transform):Void {
		throw "not built yet";
	}

	/** Returns the frame of a joint on body B.

		@param jointId  The joint.
		@param out  Optional. The `B2Transform` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The frame, in body B's local space. */
	public static function b2Joint_GetLocalFrameB(jointId:B2JointId, ?out:B2Transform):B2Transform {
		throw "not built yet";
	}

	/** Sets whether the bodies of a joint collide with each other.

		Refused while the world is stepping, such as from a callback.

		@param jointId  The joint.
		@param shouldCollide  True to let the connected bodies collide. */
	public static function b2Joint_SetCollideConnected(jointId:B2JointId, shouldCollide:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the bodies of a joint collide with each other.

		@param jointId  The joint.
		@return  True when the connected bodies collide. */
	public static function b2Joint_GetCollideConnected(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Sets the user data of a joint.

		@param jointId  The joint.
		@param userData  Any Haxe value, returned as set by `b2Joint_GetUserData`. */
	public static function b2Joint_SetUserData(jointId:B2JointId, userData:Dynamic):Void {
		throw "not built yet";
	}

	/** Returns the user data of a joint.

		@param jointId  The joint.
		@return  The value set by `b2Joint_SetUserData`, or null when none was set. */
	public static function b2Joint_GetUserData(jointId:B2JointId):Dynamic {
		throw "not built yet";
	}

	/** Wakes the bodies of a joint.

		@param jointId  The joint. */
	public static function b2Joint_WakeBodies(jointId:B2JointId):Void {
		throw "not built yet";
	}

	/** Returns the constraint force of a joint, in newtons.

		The force is the one applied at the last step.

		@param jointId  The joint.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The force. */
	public static function b2Joint_GetConstraintForce(jointId:B2JointId, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Returns the constraint torque of a joint, in newton-meters.

		The torque is the one applied at the last step.

		@param jointId  The joint.
		@return  The torque. */
	public static function b2Joint_GetConstraintTorque(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the current linear separation error of a joint, in meters.

		Movement the joint allows, such as sliding along a prismatic joint's axis, is not counted as error.

		@param jointId  The joint.
		@return  The linear error. */
	public static function b2Joint_GetLinearSeparation(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the current angular separation error of a joint, in radians.

		Movement the joint allows, such as the rotation of a revolute joint, is not counted as error.

		@param jointId  The joint.
		@return  The angular error. */
	public static function b2Joint_GetAngularSeparation(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the stiffness and damping of a joint's constraint.

		An advanced feature. Both values must be zero or more.

		@param jointId  The joint.
		@param hertz  The stiffness, in hertz (cycles per second).
		@param dampingRatio  The damping ratio, without a unit, where one is critical damping. */
	public static function b2Joint_SetConstraintTuning(jointId:B2JointId, hertz:Float, dampingRatio:Float):Void {
		throw "not built yet";
	}

	/** Reads the stiffness and damping of a joint's constraint.

		An advanced feature.

		@param jointId  The joint.
		@param hertz  A one-element array that receives the stiffness at index 0, in hertz.
		@param dampingRatio  A one-element array that receives the damping ratio at index 0. */
	public static function b2Joint_GetConstraintTuning(jointId:B2JointId, hertz:Array<Float>, dampingRatio:Array<Float>):Void {
		throw "not built yet";
	}

	/** Sets the force above which a joint reports a joint event, in newtons.

		The threshold must be zero or more.

		@param jointId  The joint.
		@param threshold  The force threshold. */
	public static function b2Joint_SetForceThreshold(jointId:B2JointId, threshold:Float):Void {
		throw "not built yet";
	}

	/** Returns the force above which a joint reports a joint event, in newtons.

		@param jointId  The joint.
		@return  The force threshold. */
	public static function b2Joint_GetForceThreshold(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the torque above which a joint reports a joint event, in newton-meters.

		The threshold must be zero or more.

		@param jointId  The joint.
		@param threshold  The torque threshold. */
	public static function b2Joint_SetTorqueThreshold(jointId:B2JointId, threshold:Float):Void {
		throw "not built yet";
	}

	/** Returns the torque above which a joint reports a joint event, in newton-meters.

		@param jointId  The joint.
		@return  The torque threshold. */
	public static function b2Joint_GetTorqueThreshold(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Creates a distance joint between two bodies and returns its id.

		The joint keeps a point on body A and a point on body B a set distance apart, and works as a rope or a spring. See `B2DistanceJointDef` for the settings.

		Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.

		@param worldId  The world.
		@param def  The joint's definition, read during the call.
		@param out  Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new joint's id. */
	public static function b2CreateDistanceJoint(worldId:B2WorldId, def:B2DistanceJointDef, ?out:B2JointId):B2JointId {
		throw "not built yet";
	}

	/** Sets the distance joint's rest length, in meters.

		The length is clamped to between `B2_LINEAR_SLOP` and `B2_HUGE`. The joint's accumulated impulses reset to zero.

		@param jointId  The distance joint.
		@param length  The new rest length, in meters. */
	public static function b2DistanceJoint_SetRestLength(jointId:B2JointId, length:Float):Void {
		throw "not built yet";
	}

	/** Returns the distance joint's rest length, in meters.

		@param jointId  The distance joint.
		@return  The rest length. */
	public static function b2DistanceJoint_GetRestLength(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets whether the distance joint works as a spring.

		When disabled, the joint is rigid at its rest length.

		@param jointId  The distance joint.
		@param enableSpring  True to enable the spring, false to make the joint rigid. */
	public static function b2DistanceJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the distance joint works as a spring.

		@param jointId  The distance joint.
		@return  True when the spring is enabled. */
	public static function b2DistanceJoint_IsSpringEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Sets the range of force the distance joint's spring can exert, in newtons.

		The lower force limits the tension the spring can sustain, and the upper force limits the compression. A lower force above the upper force is swapped with it.

		@param jointId  The distance joint.
		@param lowerForce  The lowest spring force, in newtons.
		@param upperForce  The highest spring force, in newtons. */
	public static function b2DistanceJoint_SetSpringForceRange(jointId:B2JointId, lowerForce:Float, upperForce:Float):Void {
		throw "not built yet";
	}

	/** Reads the range of force the distance joint's spring can exert, in newtons.

		@param jointId  The distance joint.
		@param lowerForce  A one-element array that receives the lowest spring force at index 0.
		@param upperForce  A one-element array that receives the highest spring force at index 0. */
	public static function b2DistanceJoint_GetSpringForceRange(jointId:B2JointId, lowerForce:Array<Float>, upperForce:Array<Float>):Void {
		throw "not built yet";
	}

	/** Sets the distance joint's spring stiffness, in hertz (cycles per second).

		@param jointId  The distance joint.
		@param hertz  The spring stiffness, in hertz. */
	public static function b2DistanceJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void {
		throw "not built yet";
	}

	/** Sets the distance joint's spring damping ratio, which has no unit.

		A ratio of 1 is critical damping.

		@param jointId  The distance joint.
		@param dampingRatio  The spring damping ratio. */
	public static function b2DistanceJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		throw "not built yet";
	}

	/** Returns the distance joint's spring stiffness, in hertz (cycles per second).

		@param jointId  The distance joint.
		@return  The spring stiffness, in hertz. */
	public static function b2DistanceJoint_GetSpringHertz(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the distance joint's spring damping ratio, which has no unit.

		@param jointId  The distance joint.
		@return  The spring damping ratio. */
	public static function b2DistanceJoint_GetSpringDampingRatio(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the force the distance joint's spring applied in the last step, in newtons.

		Returns 0 when the spring is disabled.

		@param jointId  The distance joint.
		@return  The spring force. */
	public static function b2DistanceJoint_GetSpringForce(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets whether the distance joint enforces its minimum and maximum lengths.

		_Note that the limits only act while the spring is enabled. A rigid joint stays at its rest length and ignores them._

		@param jointId  The distance joint.
		@param enableLimit  True to enforce the limits. */
	public static function b2DistanceJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the distance joint enforces its minimum and maximum lengths.

		@param jointId  The distance joint.
		@return  True when the limits are enabled. */
	public static function b2DistanceJoint_IsLimitEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Sets the distance joint's minimum and maximum lengths, in meters.

		Both lengths are clamped to between `B2_LINEAR_SLOP` and `B2_HUGE`, and a minimum above the maximum is swapped with it.

		@param jointId  The distance joint.
		@param minLength  The minimum length, in meters.
		@param maxLength  The maximum length, in meters. */
	public static function b2DistanceJoint_SetLimits(jointId:B2JointId, minLength:Float, maxLength:Float):Void {
		throw "not built yet";
	}

	/** Returns the distance joint's minimum length, in meters.

		@param jointId  The distance joint.
		@return  The minimum length. */
	public static function b2DistanceJoint_GetLowerLimit(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the distance joint's maximum length, in meters.

		@param jointId  The distance joint.
		@return  The maximum length. */
	public static function b2DistanceJoint_GetUpperLimit(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the current distance between the distance joint's two anchor points, in meters.

		Returns 0 when the world is locked, as during a step.

		@param jointId  The distance joint.
		@return  The current length. */
	public static function b2DistanceJoint_GetCurrentLength(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets whether the distance joint's motor is enabled.

		The motor drives the joint's length at its target speed. A change of state resets the motor's accumulated impulse.

		@param jointId  The distance joint.
		@param enableMotor  True to enable the motor. */
	public static function b2DistanceJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the distance joint's motor is enabled.

		@param jointId  The distance joint.
		@return  True when the motor is enabled. */
	public static function b2DistanceJoint_IsMotorEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Sets the speed the distance joint's motor drives the length at, usually in meters per second.

		@param jointId  The distance joint.
		@param motorSpeed  The target speed, usually in meters per second. */
	public static function b2DistanceJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void {
		throw "not built yet";
	}

	/** Returns the speed the distance joint's motor drives the length at, usually in meters per second.

		@param jointId  The distance joint.
		@return  The target speed. */
	public static function b2DistanceJoint_GetTargetMotorSpeed(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the largest force the distance joint's motor can apply, usually in newtons.

		@param jointId  The distance joint.
		@param force  The largest motor force, usually in newtons. */
	public static function b2DistanceJoint_SetMaxMotorForce(jointId:B2JointId, force:Float):Void {
		throw "not built yet";
	}

	/** Returns the largest force the distance joint's motor can apply, usually in newtons.

		@param jointId  The distance joint.
		@return  The largest motor force. */
	public static function b2DistanceJoint_GetMaxMotorForce(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the force the distance joint's motor applied in the last step, usually in newtons.

		@param jointId  The distance joint.
		@return  The motor force. */
	public static function b2DistanceJoint_GetCurrentMotorForce(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Creates a filter joint between two bodies and returns its id.

		The joint disables collision between the two bodies and keeps them in the same simulation island. See `B2FilterJointDef` for the settings.

		Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.

		@param worldId  The world.
		@param def  The joint's definition, read during the call.
		@param out  Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new joint's id. */
	public static function b2CreateFilterJoint(worldId:B2WorldId, def:B2FilterJointDef, ?out:B2JointId):B2JointId {
		throw "not built yet";
	}

	/** Creates a motor joint between two bodies and returns its id.

		The joint drives the relative velocity or the relative transform of the two bodies. With a velocity of zero it acts like top-down friction. See `B2MotorJointDef` for the settings.

		Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.

		@param worldId  The world.
		@param def  The joint's definition, read during the call.
		@param out  Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new joint's id. */
	public static function b2CreateMotorJoint(worldId:B2WorldId, def:B2MotorJointDef, ?out:B2JointId):B2JointId {
		throw "not built yet";
	}

	/** Sets the relative linear velocity the motor joint drives toward, in meters per second.

		@param jointId  The motor joint.
		@param velocity  The desired relative linear velocity, in meters per second. */
	public static function b2MotorJoint_SetLinearVelocity(jointId:B2JointId, velocity:B2Vec2):Void {
		throw "not built yet";
	}

	/** Returns the relative linear velocity the motor joint drives toward, in meters per second.

		@param jointId  The motor joint.
		@param out  Optional. The `B2Vec2` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The desired relative linear velocity. */
	public static function b2MotorJoint_GetLinearVelocity(jointId:B2JointId, ?out:B2Vec2):B2Vec2 {
		throw "not built yet";
	}

	/** Sets the relative angular velocity the motor joint drives toward, in radians per second.

		@param jointId  The motor joint.
		@param velocity  The desired relative angular velocity, in radians per second. */
	public static function b2MotorJoint_SetAngularVelocity(jointId:B2JointId, velocity:Float):Void {
		throw "not built yet";
	}

	/** Returns the relative angular velocity the motor joint drives toward, in radians per second.

		@param jointId  The motor joint.
		@return  The desired relative angular velocity. */
	public static function b2MotorJoint_GetAngularVelocity(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the largest force the motor joint applies to reach its linear velocity, in newtons.

		@param jointId  The motor joint.
		@param maxForce  The largest force, in newtons. */
	public static function b2MotorJoint_SetMaxVelocityForce(jointId:B2JointId, maxForce:Float):Void {
		throw "not built yet";
	}

	/** Returns the largest force the motor joint applies to reach its linear velocity, in newtons.

		@param jointId  The motor joint.
		@return  The largest force. */
	public static function b2MotorJoint_GetMaxVelocityForce(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the largest torque the motor joint applies to reach its angular velocity, in newton-meters.

		@param jointId  The motor joint.
		@param maxTorque  The largest torque, in newton-meters. */
	public static function b2MotorJoint_SetMaxVelocityTorque(jointId:B2JointId, maxTorque:Float):Void {
		throw "not built yet";
	}

	/** Returns the largest torque the motor joint applies to reach its angular velocity, in newton-meters.

		@param jointId  The motor joint.
		@return  The largest torque. */
	public static function b2MotorJoint_GetMaxVelocityTorque(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the stiffness of the motor joint's linear spring, in hertz.

		The linear spring drives the relative position toward the joint frames coinciding.

		@param jointId  The motor joint.
		@param hertz  The linear spring stiffness, in hertz. */
	public static function b2MotorJoint_SetLinearHertz(jointId:B2JointId, hertz:Float):Void {
		throw "not built yet";
	}

	/** Returns the stiffness of the motor joint's linear spring, in hertz.

		@param jointId  The motor joint.
		@return  The linear spring stiffness, in hertz. */
	public static function b2MotorJoint_GetLinearHertz(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the damping ratio of the motor joint's linear spring, which has no unit.

		A ratio of 1 is critical damping.

		@param jointId  The motor joint.
		@param damping  The linear spring damping ratio. */
	public static function b2MotorJoint_SetLinearDampingRatio(jointId:B2JointId, damping:Float):Void {
		throw "not built yet";
	}

	/** Returns the damping ratio of the motor joint's linear spring, which has no unit.

		@param jointId  The motor joint.
		@return  The linear spring damping ratio. */
	public static function b2MotorJoint_GetLinearDampingRatio(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the stiffness of the motor joint's angular spring, in hertz.

		The angular spring drives the relative rotation toward the joint frames aligning.

		@param jointId  The motor joint.
		@param hertz  The angular spring stiffness, in hertz. */
	public static function b2MotorJoint_SetAngularHertz(jointId:B2JointId, hertz:Float):Void {
		throw "not built yet";
	}

	/** Returns the stiffness of the motor joint's angular spring, in hertz.

		@param jointId  The motor joint.
		@return  The angular spring stiffness, in hertz. */
	public static function b2MotorJoint_GetAngularHertz(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the damping ratio of the motor joint's angular spring, which has no unit.

		A ratio of 1 is critical damping.

		@param jointId  The motor joint.
		@param damping  The angular spring damping ratio. */
	public static function b2MotorJoint_SetAngularDampingRatio(jointId:B2JointId, damping:Float):Void {
		throw "not built yet";
	}

	/** Returns the damping ratio of the motor joint's angular spring, which has no unit.

		@param jointId  The motor joint.
		@return  The angular spring damping ratio. */
	public static function b2MotorJoint_GetAngularDampingRatio(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the largest force the motor joint's linear spring applies, in newtons.

		A negative force is clamped to 0.

		@param jointId  The motor joint.
		@param maxForce  The largest spring force, in newtons. */
	public static function b2MotorJoint_SetMaxSpringForce(jointId:B2JointId, maxForce:Float):Void {
		throw "not built yet";
	}

	/** Returns the largest force the motor joint's linear spring applies, in newtons.

		@param jointId  The motor joint.
		@return  The largest spring force. */
	public static function b2MotorJoint_GetMaxSpringForce(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the largest torque the motor joint's angular spring applies, in newton-meters.

		A negative torque is clamped to 0.

		@param jointId  The motor joint.
		@param maxTorque  The largest spring torque, in newton-meters. */
	public static function b2MotorJoint_SetMaxSpringTorque(jointId:B2JointId, maxTorque:Float):Void {
		throw "not built yet";
	}

	/** Returns the largest torque the motor joint's angular spring applies, in newton-meters.

		@param jointId  The motor joint.
		@return  The largest spring torque. */
	public static function b2MotorJoint_GetMaxSpringTorque(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Creates a prismatic (slider) joint between two bodies and returns its id.

		Body B slides along the x-axis of frame A and can not rotate relative to body A. See `B2PrismaticJointDef` for the settings.

		Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.

		@param worldId  The world.
		@param def  The joint's definition, read during the call.
		@param out  Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new joint's id. */
	public static function b2CreatePrismaticJoint(worldId:B2WorldId, def:B2PrismaticJointDef, ?out:B2JointId):B2JointId {
		throw "not built yet";
	}

	/** Sets whether the prismatic joint's spring is enabled.

		The spring drives the joint's translation toward its target translation. A change of state resets the spring's accumulated impulse.

		@param jointId  The prismatic joint.
		@param enableSpring  True to enable the spring. */
	public static function b2PrismaticJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the prismatic joint's spring is enabled.

		@param jointId  The prismatic joint.
		@return  True when the spring is enabled. */
	public static function b2PrismaticJoint_IsSpringEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Sets the prismatic joint's spring stiffness, in hertz (cycles per second).

		The stiffness should usually be less than a quarter of the simulation rate. At 60 hertz, that is 15 hertz or less.

		@param jointId  The prismatic joint.
		@param hertz  The spring stiffness, in hertz. */
	public static function b2PrismaticJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void {
		throw "not built yet";
	}

	/** Returns the prismatic joint's spring stiffness, in hertz (cycles per second).

		@param jointId  The prismatic joint.
		@return  The spring stiffness, in hertz. */
	public static function b2PrismaticJoint_GetSpringHertz(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the prismatic joint's spring damping ratio, which has no unit.

		A ratio of 1 is critical damping.

		@param jointId  The prismatic joint.
		@param dampingRatio  The spring damping ratio. */
	public static function b2PrismaticJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		throw "not built yet";
	}

	/** Returns the prismatic joint's spring damping ratio, which has no unit.

		@param jointId  The prismatic joint.
		@return  The spring damping ratio. */
	public static function b2PrismaticJoint_GetSpringDampingRatio(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the translation the prismatic joint's spring drives toward, usually in meters.

		@param jointId  The prismatic joint.
		@param translation  The target translation, usually in meters. */
	public static function b2PrismaticJoint_SetTargetTranslation(jointId:B2JointId, translation:Float):Void {
		throw "not built yet";
	}

	/** Returns the translation the prismatic joint's spring drives toward, usually in meters.

		@param jointId  The prismatic joint.
		@return  The target translation. */
	public static function b2PrismaticJoint_GetTargetTranslation(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets whether the prismatic joint enforces its translation limits.

		A change of state resets the limit's accumulated impulses.

		@param jointId  The prismatic joint.
		@param enableLimit  True to enforce the limits. */
	public static function b2PrismaticJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the prismatic joint enforces its translation limits.

		@param jointId  The prismatic joint.
		@return  True when the limits are enabled. */
	public static function b2PrismaticJoint_IsLimitEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Returns the prismatic joint's lower translation limit, in meters.

		@param jointId  The prismatic joint.
		@return  The lower limit. */
	public static function b2PrismaticJoint_GetLowerLimit(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the prismatic joint's upper translation limit, in meters.

		@param jointId  The prismatic joint.
		@return  The upper limit. */
	public static function b2PrismaticJoint_GetUpperLimit(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the prismatic joint's lower and upper translation limits, in meters.

		A lower limit above the upper limit is swapped with it.

		@param jointId  The prismatic joint.
		@param lower  The lower limit, in meters.
		@param upper  The upper limit, in meters. */
	public static function b2PrismaticJoint_SetLimits(jointId:B2JointId, lower:Float, upper:Float):Void {
		throw "not built yet";
	}

	/** Sets whether the prismatic joint's motor is enabled.

		The motor drives the joint along its axis at its target speed. A change of state resets the motor's accumulated impulse.

		@param jointId  The prismatic joint.
		@param enableMotor  True to enable the motor. */
	public static function b2PrismaticJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the prismatic joint's motor is enabled.

		@param jointId  The prismatic joint.
		@return  True when the motor is enabled. */
	public static function b2PrismaticJoint_IsMotorEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Sets the speed the prismatic joint's motor drives the joint along its axis at, usually in meters per second.

		@param jointId  The prismatic joint.
		@param motorSpeed  The target speed, usually in meters per second. */
	public static function b2PrismaticJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void {
		throw "not built yet";
	}

	/** Returns the speed the prismatic joint's motor drives the joint along its axis at, usually in meters per second.

		@param jointId  The prismatic joint.
		@return  The target speed. */
	public static function b2PrismaticJoint_GetTargetMotorSpeed(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the largest force the prismatic joint's motor can apply, usually in newtons.

		@param jointId  The prismatic joint.
		@param force  The largest motor force, usually in newtons. */
	public static function b2PrismaticJoint_SetMaxMotorForce(jointId:B2JointId, force:Float):Void {
		throw "not built yet";
	}

	/** Returns the largest force the prismatic joint's motor can apply, usually in newtons.

		@param jointId  The prismatic joint.
		@return  The largest motor force. */
	public static function b2PrismaticJoint_GetMaxMotorForce(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the prismatic joint's current translation along its axis, usually in meters.

		The translation is zero when the origins of the two joint frames coincide in the world.

		@param jointId  The prismatic joint.
		@return  The current translation. */
	public static function b2PrismaticJoint_GetCurrentTranslation(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the prismatic joint's current translation speed along its axis, usually in meters per second.

		@param jointId  The prismatic joint.
		@return  The current speed. */
	public static function b2PrismaticJoint_GetCurrentSpeed(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the force the prismatic joint's motor applied in the last step, usually in newtons.

		@param jointId  The prismatic joint.
		@return  The motor force. */
	public static function b2PrismaticJoint_GetCurrentMotorForce(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Creates a revolute joint between two bodies and returns its id.

		A point on body B is fixed to a point on body A, and the bodies rotate freely relative to each other. See `B2RevoluteJointDef` for the settings.

		Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.

		@param worldId  The world.
		@param def  The joint's definition, read during the call.
		@param out  Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new joint's id. */
	public static function b2CreateRevoluteJoint(worldId:B2WorldId, def:B2RevoluteJointDef, ?out:B2JointId):B2JointId {
		throw "not built yet";
	}

	/** Sets whether the revolute joint's spring is enabled.

		The spring drives the joint's angle toward its target angle. A change of state resets the spring's accumulated impulse.

		@param jointId  The revolute joint.
		@param enableSpring  True to enable the spring. */
	public static function b2RevoluteJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the revolute joint's spring is enabled.

		@param jointId  The revolute joint.
		@return  True when the spring is enabled. */
	public static function b2RevoluteJoint_IsSpringEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Sets the revolute joint's spring stiffness, in hertz (cycles per second).

		@param jointId  The revolute joint.
		@param hertz  The spring stiffness, in hertz. */
	public static function b2RevoluteJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void {
		throw "not built yet";
	}

	/** Returns the revolute joint's spring stiffness, in hertz (cycles per second).

		@param jointId  The revolute joint.
		@return  The spring stiffness, in hertz. */
	public static function b2RevoluteJoint_GetSpringHertz(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the revolute joint's spring damping ratio, which has no unit.

		A ratio of 1 is critical damping.

		@param jointId  The revolute joint.
		@param dampingRatio  The spring damping ratio. */
	public static function b2RevoluteJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		throw "not built yet";
	}

	/** Returns the revolute joint's spring damping ratio, which has no unit.

		@param jointId  The revolute joint.
		@return  The spring damping ratio. */
	public static function b2RevoluteJoint_GetSpringDampingRatio(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the angle the revolute joint's spring drives toward, in radians.

		@param jointId  The revolute joint.
		@param angle  The target angle, in radians. */
	public static function b2RevoluteJoint_SetTargetAngle(jointId:B2JointId, angle:Float):Void {
		throw "not built yet";
	}

	/** Returns the angle the revolute joint's spring drives toward, in radians.

		@param jointId  The revolute joint.
		@return  The target angle, in radians. */
	public static function b2RevoluteJoint_GetTargetAngle(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets whether the revolute joint enforces its angle limits.

		A change of state resets the limit's accumulated impulses.

		@param jointId  The revolute joint.
		@param enableLimit  True to enforce the limits. */
	public static function b2RevoluteJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the revolute joint enforces its angle limits.

		@param jointId  The revolute joint.
		@return  True when the limits are enabled. */
	public static function b2RevoluteJoint_IsLimitEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Returns the revolute joint's lower angle limit, in radians.

		@param jointId  The revolute joint.
		@return  The lower limit. */
	public static function b2RevoluteJoint_GetLowerLimit(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the revolute joint's upper angle limit, in radians.

		@param jointId  The revolute joint.
		@return  The upper limit. */
	public static function b2RevoluteJoint_GetUpperLimit(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the revolute joint's lower and upper angle limits, in radians.

		Both limits are clamped to between -0.99 * `B2_PI` and 0.99 * `B2_PI`, and a lower limit above the upper limit is swapped with it.

		@param jointId  The revolute joint.
		@param lower  The lower limit, in radians.
		@param upper  The upper limit, in radians. */
	public static function b2RevoluteJoint_SetLimits(jointId:B2JointId, lower:Float, upper:Float):Void {
		throw "not built yet";
	}

	/** Sets whether the revolute joint's motor is enabled.

		The motor drives the joint angle at its target speed. A change of state resets the motor's accumulated impulse.

		@param jointId  The revolute joint.
		@param enableMotor  True to enable the motor. */
	public static function b2RevoluteJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the revolute joint's motor is enabled.

		@param jointId  The revolute joint.
		@return  True when the motor is enabled. */
	public static function b2RevoluteJoint_IsMotorEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Sets the speed the revolute joint's motor drives the joint angle at, in radians per second.

		@param jointId  The revolute joint.
		@param motorSpeed  The target speed, in radians per second. Positive turns body B counterclockwise relative to body A. */
	public static function b2RevoluteJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void {
		throw "not built yet";
	}

	/** Returns the speed the revolute joint's motor drives the joint angle at, in radians per second.

		@param jointId  The revolute joint.
		@return  The target speed. */
	public static function b2RevoluteJoint_GetTargetMotorSpeed(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the largest torque the revolute joint's motor can apply, usually in newton-meters.

		@param jointId  The revolute joint.
		@param torque  The largest motor torque, usually in newton-meters. */
	public static function b2RevoluteJoint_SetMaxMotorTorque(jointId:B2JointId, torque:Float):Void {
		throw "not built yet";
	}

	/** Returns the largest torque the revolute joint's motor can apply, usually in newton-meters.

		@param jointId  The revolute joint.
		@return  The largest motor torque. */
	public static function b2RevoluteJoint_GetMaxMotorTorque(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the revolute joint's current angle, in radians.

		The angle is the relative rotation of the two joint frames.

		@param jointId  The revolute joint.
		@return  The current angle, in radians. */
	public static function b2RevoluteJoint_GetCurrentAngle(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the revolute joint's current angular speed, in radians per second.

		@param jointId  The revolute joint.
		@return  The current speed, in radians per second. */
	public static function b2RevoluteJoint_GetCurrentSpeed(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the torque the revolute joint's motor applied in the last step, usually in newton-meters.

		@param jointId  The revolute joint.
		@return  The motor torque. */
	public static function b2RevoluteJoint_GetCurrentMotorTorque(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Creates a weld joint between two bodies and returns its id.

		The joint connects the two bodies rigidly, and its springs mimic soft-body simulation. See `B2WeldJointDef` for the settings.

		Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.

		@param worldId  The world.
		@param def  The joint's definition, read during the call.
		@param out  Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new joint's id. */
	public static function b2CreateWeldJoint(worldId:B2WorldId, def:B2WeldJointDef, ?out:B2JointId):B2JointId {
		throw "not built yet";
	}

	/** Sets the weld joint's linear stiffness, in hertz.

		A stiffness of 0 makes the linear constraint rigid.

		@param jointId  The weld joint.
		@param hertz  The linear stiffness, in hertz. */
	public static function b2WeldJoint_SetLinearHertz(jointId:B2JointId, hertz:Float):Void {
		throw "not built yet";
	}

	/** Returns the weld joint's linear stiffness, in hertz.

		@param jointId  The weld joint.
		@return  The linear stiffness, in hertz. */
	public static function b2WeldJoint_GetLinearHertz(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the weld joint's linear damping ratio, which has no unit.

		@param jointId  The weld joint.
		@param dampingRatio  The linear damping ratio. */
	public static function b2WeldJoint_SetLinearDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		throw "not built yet";
	}

	/** Returns the weld joint's linear damping ratio, which has no unit.

		@param jointId  The weld joint.
		@return  The linear damping ratio. */
	public static function b2WeldJoint_GetLinearDampingRatio(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the weld joint's angular stiffness, in hertz.

		A stiffness of 0 makes the angular constraint rigid.

		@param jointId  The weld joint.
		@param hertz  The angular stiffness, in hertz. */
	public static function b2WeldJoint_SetAngularHertz(jointId:B2JointId, hertz:Float):Void {
		throw "not built yet";
	}

	/** Returns the weld joint's angular stiffness, in hertz.

		@param jointId  The weld joint.
		@return  The angular stiffness, in hertz. */
	public static function b2WeldJoint_GetAngularHertz(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the weld joint's angular damping ratio, which has no unit.

		@param jointId  The weld joint.
		@param dampingRatio  The angular damping ratio. */
	public static function b2WeldJoint_SetAngularDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		throw "not built yet";
	}

	/** Returns the weld joint's angular damping ratio, which has no unit.

		@param jointId  The weld joint.
		@return  The angular damping ratio. */
	public static function b2WeldJoint_GetAngularDampingRatio(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Creates a wheel joint between two bodies and returns its id.

		Body B is a wheel that rotates freely and slides along the x-axis of frame A. See `B2WheelJointDef` for the settings.

		Wakes both bodies when either is asleep. When the joint's `collideConnected` is false, the contacts that already exist between the two bodies are destroyed. Returns a null joint id when the world is locked, as during a step, or when the definition is invalid.

		@param worldId  The world.
		@param def  The joint's definition, read during the call.
		@param out  Optional. The `B2JointId` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The new joint's id. */
	public static function b2CreateWheelJoint(worldId:B2WorldId, def:B2WheelJointDef, ?out:B2JointId):B2JointId {
		throw "not built yet";
	}

	/** Sets whether the wheel joint's spring is enabled.

		The spring acts along the joint's axis, as a suspension does. A change of state resets the spring's accumulated impulse.

		@param jointId  The wheel joint.
		@param enableSpring  True to enable the spring. */
	public static function b2WheelJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the wheel joint's spring is enabled.

		@param jointId  The wheel joint.
		@return  True when the spring is enabled. */
	public static function b2WheelJoint_IsSpringEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Sets the wheel joint's spring stiffness, in hertz (cycles per second).

		@param jointId  The wheel joint.
		@param hertz  The spring stiffness, in hertz. */
	public static function b2WheelJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void {
		throw "not built yet";
	}

	/** Returns the wheel joint's spring stiffness, in hertz (cycles per second).

		@param jointId  The wheel joint.
		@return  The spring stiffness, in hertz. */
	public static function b2WheelJoint_GetSpringHertz(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the wheel joint's spring damping ratio, which has no unit.

		A ratio of 1 is critical damping.

		@param jointId  The wheel joint.
		@param dampingRatio  The spring damping ratio. */
	public static function b2WheelJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		throw "not built yet";
	}

	/** Returns the wheel joint's spring damping ratio, which has no unit.

		@param jointId  The wheel joint.
		@return  The spring damping ratio. */
	public static function b2WheelJoint_GetSpringDampingRatio(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets whether the wheel joint enforces its translation limits.

		A change of state resets the limit's accumulated impulses.

		@param jointId  The wheel joint.
		@param enableLimit  True to enforce the limits. */
	public static function b2WheelJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the wheel joint enforces its translation limits.

		@param jointId  The wheel joint.
		@return  True when the limits are enabled. */
	public static function b2WheelJoint_IsLimitEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Returns the wheel joint's lower translation limit, in meters.

		@param jointId  The wheel joint.
		@return  The lower limit. */
	public static function b2WheelJoint_GetLowerLimit(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the wheel joint's upper translation limit, in meters.

		@param jointId  The wheel joint.
		@return  The upper limit. */
	public static function b2WheelJoint_GetUpperLimit(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the wheel joint's lower and upper translation limits, in meters.

		A lower limit above the upper limit is swapped with it.

		@param jointId  The wheel joint.
		@param lower  The lower limit, in meters.
		@param upper  The upper limit, in meters. */
	public static function b2WheelJoint_SetLimits(jointId:B2JointId, lower:Float, upper:Float):Void {
		throw "not built yet";
	}

	/** Sets whether the wheel joint's motor is enabled.

		The motor drives the wheel's rotation at its target speed. A change of state resets the motor's accumulated impulse.

		@param jointId  The wheel joint.
		@param enableMotor  True to enable the motor. */
	public static function b2WheelJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void {
		throw "not built yet";
	}

	/** Returns whether the wheel joint's motor is enabled.

		@param jointId  The wheel joint.
		@return  True when the motor is enabled. */
	public static function b2WheelJoint_IsMotorEnabled(jointId:B2JointId):Bool {
		throw "not built yet";
	}

	/** Sets the speed the wheel joint's motor drives the wheel's rotation at, in radians per second.

		@param jointId  The wheel joint.
		@param motorSpeed  The target speed, in radians per second. Positive turns body B counterclockwise relative to body A, so a wheel rolling toward +x on level ground needs a negative speed. */
	public static function b2WheelJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void {
		throw "not built yet";
	}

	/** Returns the speed the wheel joint's motor drives the wheel's rotation at, in radians per second.

		@param jointId  The wheel joint.
		@return  The target speed. */
	public static function b2WheelJoint_GetTargetMotorSpeed(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Sets the largest torque the wheel joint's motor can apply, usually in newton-meters.

		@param jointId  The wheel joint.
		@param torque  The largest motor torque, usually in newton-meters. */
	public static function b2WheelJoint_SetMaxMotorTorque(jointId:B2JointId, torque:Float):Void {
		throw "not built yet";
	}

	/** Returns the largest torque the wheel joint's motor can apply, usually in newton-meters.

		@param jointId  The wheel joint.
		@return  The largest motor torque. */
	public static function b2WheelJoint_GetMaxMotorTorque(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns the torque the wheel joint's motor applied in the last step, usually in newton-meters.

		@param jointId  The wheel joint.
		@return  The motor torque. */
	public static function b2WheelJoint_GetCurrentMotorTorque(jointId:B2JointId):Float {
		throw "not built yet";
	}

	/** Returns whether a contact id refers to a contact that still exists.

		A contact id can become orphaned when its contact ends. Check it with this call before using it in other contact calls.

		@param id  The contact id.
		@return  True when the contact exists. */
	public static function b2Contact_IsValid(id:B2ContactId):Bool {
		throw "not built yet";
	}

	/** Returns the data of a contact: its id, its two shapes and its manifold.

		The manifold is a copy of the contact's and may have no points when the shapes are not touching. The contact id must be valid.

		@param contactId  The contact.
		@param out  Optional. The `B2ContactData` to fill in place, its objects and arrays reused; a new one when omitted.
		@return  The contact's data. */
	public static function b2Contact_GetData(contactId:B2ContactId, ?out:B2ContactData):B2ContactData {
		throw "not built yet";
	}
	#end

	/** Copies `box2d.wasm` into a JavaScript build's output directory, from a line in the build's hxml.

		@param directory  The directory, relative to the build's working directory. */
	public static macro function copyWasm(directory:String):haxe.macro.Expr {
		throw "not built yet";
	}
}
