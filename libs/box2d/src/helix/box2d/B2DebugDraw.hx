package helix.box2d;

/** The functions and options `b2World_Draw` uses to draw a world. The program sets the functions it wants and Box2D calls them with world coordinates, so a program shifts into its own camera frame inside them. Make one with `b2DefaultDebugDraw`, whose functions do nothing, so a program may set only some of them. */
class B2DebugDraw {
	/** Draws the outline of a closed polygon. Box2D calls it when drawing weld joints, once for the box of each joint frame. `transform` is the joint frame in the world, `vertices` are in that frame in counter-clockwise order from index 0 up to `vertexCount`, and `color` is the color to draw with. `context` is the debug draw object's `context`. */
	public var DrawPolygonFcn:(transform:B2WorldTransform, vertices:Array<B2Vec2>, vertexCount:Int, color:B2HexColor, context:Dynamic) -> Void;

	/** Draws a filled polygon. Box2D calls it for each polygon shape when `drawShapes` is true. `transform` is the body's transform in the world, `vertices` are in the body's frame in counter-clockwise order from index 0 up to `vertexCount`, `radius` rounds its corners (0 for none), and `color` is the color to draw with. `context` is the debug draw object's `context`. */
	public var DrawSolidPolygonFcn:(transform:B2WorldTransform, vertices:Array<B2Vec2>, vertexCount:Int, radius:Float, color:B2HexColor,
		context:Dynamic) -> Void;

	/** Draws the outline of a circle. Box2D calls it when drawing revolute joints. `center` is the circle's center in the world, `radius` its radius, and `color` the color to draw with. `context` is the debug draw object's `context`. */
	public var DrawCircleFcn:(center:B2Pos, radius:Float, color:B2HexColor, context:Dynamic) -> Void;

	/** Draws a filled circle. Box2D calls it for each circle shape when `drawShapes` is true. `transform` is the body's transform in the world, `center` is the circle's center in the body's frame, `radius` its radius, and `color` the color to draw with. `context` is the debug draw object's `context`. */
	public var DrawSolidCircleFcn:(transform:B2WorldTransform, center:B2Vec2, radius:Float, color:B2HexColor, context:Dynamic) -> Void;

	/** Draws a filled capsule. Box2D calls it for each capsule shape when `drawShapes` is true. `p1` and `p2` are the centers of the two semicircles in the world, `radius` is their radius, and `color` is the color to draw with. `context` is the debug draw object's `context`. */
	public var DrawSolidCapsuleFcn:(p1:B2Pos, p2:B2Pos, radius:Float, color:B2HexColor, context:Dynamic) -> Void;

	/** Draws a line segment. Box2D calls it for segment and chain segment shapes when `drawShapes` is true, and for joints, chain normals, the movement of the center of mass and force arrows when their options are on. `p1` and `p2` are the end points in the world, and `color` is the color to draw with. `context` is the debug draw object's `context`. */
	public var DrawLineFcn:(p1:B2Pos, p2:B2Pos, color:B2HexColor, context:Dynamic) -> Void;

	/** Draws the axes of a transform, with a length of the program's choosing. Box2D calls it for the center of mass of each dynamic body when `drawMass` is true. `transform` is the center of mass and rotation in the world. `context` is the debug draw object's `context`. */
	public var DrawTransformFcn:(transform:B2WorldTransform, context:Dynamic) -> Void;

	/** Draws a point. Box2D calls it for the ends of chain segments, joint anchors and contact points when their options are on. `p` is the point in the world, `size` is its size, and `color` is the color to draw with. `context` is the debug draw object's `context`. */
	public var DrawPointFcn:(p:B2Pos, size:Float, color:B2HexColor, context:Dynamic) -> Void;

	/** Draws text. Box2D calls it for body names, masses, contact features and forces, and joint forces when their options are on. `p` is the text's position in the world, `s` is the text, and `color` is the color to draw with. `context` is the debug draw object's `context`. */
	public var DrawStringFcn:(p:B2Pos, s:String, color:B2HexColor, context:Dynamic) -> Void;

	/** Draws a bounding box. Box2D calls it for each shape's box when `drawBounds` is true, and for each island's box when `drawIslands` is true. `aabb` is the box in the world, and `color` is the color to draw with. `context` is the debug draw object's `context`. */
	public var DrawBoundsFcn:(aabb:B2AABB, color:B2HexColor, context:Dynamic) -> Void;

	/** The part of the world to draw. Shapes outside it are skipped, and an empty box draws nothing. Defaults to the whole world. */
	public var drawingBounds:B2AABB;

	/** The scale of the arrows drawn for forces. Defaults to 1. */
	public var forceScale:Float;

	/** The scale of everything drawn for joints. Defaults to 1. */
	public var jointScale:Float;

	/** Whether contact points are drawn. Defaults to false. */
	public var drawContacts:Bool;

	/** Whether contact points are drawn at anchor A rather than anchor B. Defaults to false. */
	public var drawAnchorA:Bool;

	/** Whether shapes are drawn. Defaults to true. */
	public var drawShapes:Bool;

	/** Whether the normals of chain shape segments are drawn. Defaults to false. */
	public var drawChainNormals:Bool;

	/** Whether joints are drawn. Defaults to false. */
	public var drawJoints:Bool;

	/** Whether extra information is drawn for joints, such as limits and forces. Defaults to false. */
	public var drawJointExtras:Bool;

	/** Whether the bounding boxes of shapes are drawn. Defaults to false. */
	public var drawBounds:Bool;

	/** Whether the mass and center of mass of dynamic bodies are drawn. Defaults to false. */
	public var drawMass:Bool;

	/** Whether body names are drawn. Defaults to false. */
	public var drawBodyNames:Bool;

	/** Whether contacts and joints are colored by the solver's constraint graph color. Defaults to false. */
	public var drawGraphColors:Bool;

	/** Whether the feature ids of contact points are drawn. Defaults to false. */
	public var drawContactFeatures:Bool;

	/** Whether contact normals are drawn. Defaults to false. */
	public var drawContactNormals:Bool;

	/** Whether the normal forces of contacts are drawn. Defaults to false. */
	public var drawContactForces:Bool;

	/** Whether the friction forces of contacts are drawn. Defaults to false. */
	public var drawFrictionForces:Bool;

	/** Whether simulation islands are drawn as bounding boxes. Defaults to false. */
	public var drawIslands:Bool;

	/** Any Haxe value the program keeps with the debug draw object, passed to each drawing function as `context` and returned as set. Defaults to null. */
	public var context:Dynamic;

	/** Creates one holding Box2D's defaults, as `b2DefaultDebugDraw()` returns. */
	public function new() {
		throw "not built yet";
	}
}
