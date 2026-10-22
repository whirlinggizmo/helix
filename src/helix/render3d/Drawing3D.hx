package helix.render3d;

/** 3D drawing kept on a node (docs/DISPLAY_MODEL.md): Drawing2D's counterpart, as calls named as Batch3D's (line, triangle, cube,
	cubeWires, sphere, grid), each taking its own color (0xAARRGGBB), kept in order in the node's own units and drawn each frame where the node
	is, after the tree's opaque models and depth-tested against them, before what's seen through (smoke, glyphs), solid shapes shaded by Batch3D's fixed light; clear takes them away. Calling
	clear and drawing again in update is immediate drawing (a debug line, a path, a grid under a scene). Not lit by the tree's lights, not
	culled, not picked. */
class Drawing3D extends Node3D {
	var kinds:Array<Drawing3DKind> = [];
	var starts:Array<Int> = [];
	var numbers:Array<Float> = [];
	var colors:Array<Int> = [];

	/** A drawing holding nothing yet. */
	public function new()
		super();

	/** How many calls it holds. */
	public var callCount(get, never):Int;

	function get_callCount():Int
		return kinds.length;

	/** Takes everything drawn away. */
	public function clear():Void {
		kinds.resize(0);
		starts.resize(0);
		numbers.resize(0);
		colors.resize(0);
	}

	/** A segment between two points. */
	public function line(x0:Float, y0:Float, z0:Float, x1:Float, y1:Float, z1:Float, color:Int):Void
		add(Line, [x0, y0, z0, x1, y1, z1], color);

	/** A filled triangle through three points, unshaded. */
	public function triangle(x0:Float, y0:Float, z0:Float, x1:Float, y1:Float, z1:Float, x2:Float, y2:Float, z2:Float, color:Int):Void
		add(Triangle, [x0, y0, z0, x1, y1, z1, x2, y2, z2], color);

	/** A solid box centered on x, y, z, width x height x depth, its faces shaded. */
	public function cube(x:Float, y:Float, z:Float, width:Float, height:Float, depth:Float, color:Int):Void
		add(Cube, [x, y, z, width, height, depth], color);

	/** A box's edges, centered on x, y, z, width x height x depth. */
	public function cubeWires(x:Float, y:Float, z:Float, width:Float, height:Float, depth:Float, color:Int):Void
		add(CubeWires, [x, y, z, width, height, depth], color);

	/** A solid sphere centered on x, y, z, shaded, of rings by slices. */
	public function sphere(x:Float, y:Float, z:Float, radius:Float, color:Int, rings = 16, slices = 24):Void
		add(Sphere, [x, y, z, radius, rings, slices], color);

	/** A square grid on the ground plane (y 0), slices by slices cells of spacing, centered on the origin. */
	public function grid(slices:Int, spacing:Float, color:Int):Void
		add(Grid, [slices, spacing], color);

	function add(kind:Drawing3DKind, values:Array<Float>, color:Int):Void {
		kinds.push(kind);
		starts.push(numbers.length);
		for (v in values)
			numbers.push(v);
		colors.push(color);
	}

	override function get_drawsOwn():Bool
		return true;

	// Its calls into the renderer's shared batch, where it is: the first drawing of the frame begins the batch (made then if it isn't yet),
	// the last ends it.
	override function drawOwn(camera:Camera3D, renderer:Renderer3D, first:Bool, last:Bool):Void {
		var batch:Null<Batch3D> = renderer.ownBatch;
		if (batch == null) {
			var made = new Batch3D(@:privateAccess renderer.gpu);
			renderer.ownBatch = made;
			renderer.ownBatchDestroy = () -> made.destroy();
			batch = made;
		}
		if (first)
			batch.begin(camera);
		if (callCount > 0) {
			batch.setTransform(worldMatrix);
			replay(batch);
		}
		if (last)
			batch.end();
	}

	// Draws every call into batch, its transform set to this node's world matrix.
	function replay(batch:Batch3D):Void {
		var n = numbers;
		for (i in 0...kinds.length) {
			var at = starts[i], c = colors[i];
			switch kinds[i] {
				case Line:
					batch.line(n[at], n[at + 1], n[at + 2], n[at + 3], n[at + 4], n[at + 5], c);
				case Triangle:
					batch.triangle(n[at], n[at + 1], n[at + 2], n[at + 3], n[at + 4], n[at + 5], n[at + 6], n[at + 7], n[at + 8], c);
				case Cube:
					batch.cube(n[at], n[at + 1], n[at + 2], n[at + 3], n[at + 4], n[at + 5], c);
				case CubeWires:
					batch.cubeWires(n[at], n[at + 1], n[at + 2], n[at + 3], n[at + 4], n[at + 5], c);
				case Sphere:
					batch.sphere(n[at], n[at + 1], n[at + 2], n[at + 3], c, Std.int(n[at + 4]), Std.int(n[at + 5]));
				case Grid:
					batch.grid(Std.int(n[at]), n[at + 1], c);
			}
		}
	}
}

/** What a Drawing3D call draws. */
private enum abstract Drawing3DKind(Int) {
	var Line;
	var Triangle;
	var Cube;
	var CubeWires;
	var Sphere;
	var Grid;
}
