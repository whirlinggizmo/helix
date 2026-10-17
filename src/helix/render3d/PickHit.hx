package helix.render3d;

/** What a pick hit (Stage3D.pick): the node, how far along the ray, the point in the world and in the node's own space, and the surface's
	normal there in the world, facing back along the ray. */
class PickHit {
	var node:Null<Node3D>;
	var distance = 0.;
	var point = [0., 0, 0];
	var local = [0., 0, 0];
	var normal = [0., 0, 0];

	/** No hit yet. */
	public function new() {}

	/** The node hit (a model, a sprite or a text), or null for no hit. */
	public function getNode():Null<Node3D>
		return node;

	/** How far along the ray, in world units from its start (a camera's near plane). */
	public function getDistance():Float
		return distance;

	/** Where in the world, axis 0 (x), 1 (y) or 2 (z). */
	public function getPoint(axis:Int):Float
		return point[axis];

	/** Where in the node's own space (a skinned model's as posed), axis 0, 1 or 2. */
	public function getLocalPoint(axis:Int):Float
		return local[axis];

	/** The surface's normal in the world, a unit vector facing back along the ray, axis 0, 1 or 2. */
	public function getNormal(axis:Int):Float
		return normal[axis];

	@:allow(helix.render3d.Stage3D)
	@:allow(helix.render3d.Sprites3D)
	function record(node:Node3D, distance:Float, px:Float, py:Float, pz:Float, lx:Float, ly:Float, lz:Float, nx:Float, ny:Float, nz:Float):Void {
		this.node = node;
		this.distance = distance;
		point[0] = px;
		point[1] = py;
		point[2] = pz;
		local[0] = lx;
		local[1] = ly;
		local[2] = lz;
		normal[0] = nx;
		normal[1] = ny;
		normal[2] = nz;
	}

	@:allow(helix.render3d.Stage3D)
	function clear():Void
		node = null;
}
