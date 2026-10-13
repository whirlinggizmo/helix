package helix.render3d;

/** What a stage holds: a transform in a tree, and its kind's data (a model's mesh, material and tint; a light). Made by the static
	constructors and never subclassed; a node only draws or lights, and game state lives elsewhere, the node its view (docs/DECISIONS.md, 61).
	Its transform is a position, a rotation (a unit quaternion, set from angles or by lookAt) and a scale, relative to its parent; its world
	matrix is worked out when a stage draws it, only after it or a node above it changed. */
class Node {
	var kind:NodeKind;
	var parent:Null<Node>;
	var children:Array<Node> = [];
	var visible = true;
	var px = 0.;
	var py = 0.;
	var pz = 0.;
	var qx = 0.;
	var qy = 0.;
	var qz = 0.;
	var qw = 1.;
	var sx = 1.;
	var sy = 1.;
	var sz = 1.;
	var mesh:Null<Mesh>;
	var material:Null<Material>;
	var tint = 0xffffffff;
	var lightOf:Null<Light>;
	var local = new Mat4();
	var world = new Mat4();
	var localDirty = true;

	function new(kind:NodeKind) {
		this.kind = kind;
	}

	/** A node that only holds others: their common transform. */
	public static function group():Node
		return new Node(Group);

	/** A model: mesh drawn with material, tinted (0xRRGGBBAA, white for none; its alpha below 255 makes it see-through). */
	public static function model(mesh:Mesh, material:Material, tint = 0xffffffff):Node {
		var node = new Node(Model);
		node.mesh = mesh;
		node.material = material;
		node.tint = tint;
		return node;
	}

	/** A light, shining from this node's place and orientation. */
	public static function light(light:Light):Node {
		var node = new Node(LightNode);
		node.lightOf = light;
		return node;
	}

	/** Its kind. */
	public function getKind():NodeKind
		return kind;

	/** A model's mesh; null for another kind. */
	public function getMesh():Null<Mesh>
		return mesh;

	/** A model's material; null for another kind. */
	public function getMaterial():Null<Material>
		return material;

	/** Gives a model another material. False for another kind. */
	public function setMaterial(value:Material):Bool {
		if (kind != Model)
			return false;
		material = value;
		return true;
	}

	/** A model's tint, 0xRRGGBBAA. */
	public function getTint():Int
		return tint;

	/** Sets a model's tint, 0xRRGGBBAA. */
	public function setTint(value:Int):Void
		tint = value;

	/** A light node's light; null for another kind. */
	public function getLight():Null<Light>
		return lightOf;

	/** Whether it and its children are drawn. */
	public function isVisible():Bool
		return visible;

	/** Shows or hides it and its children. */
	public function setVisible(value:Bool):Void {
		// Hidden, it isn't brought up to date as its parent moves: shown again, it is.
		if (value && !visible)
			localDirty = true;
		visible = value;
	}

	/** Its parent, or null. */
	public function getParent():Null<Node>
		return parent;

	/** How many children it has. */
	public function getChildCount():Int
		return children.length;

	/** Its child at index, in drawing order; null past the end. */
	public function getChild(index:Int):Null<Node>
		return index >= 0 && index < children.length ? children[index] : null;

	/** Makes child its last child, taking it from any parent it had. False for itself or one of its own ancestors. */
	public function add(child:Node):Bool {
		var at:Null<Node> = this;
		while (at != null) {
			if (at == child)
				return false;
			at = at.parent;
		}
		if (child.parent != null)
			child.parent.children.remove(child);
		child.parent = this;
		children.push(child);
		child.localDirty = true;
		return true;
	}

	/** Takes child from its children. False when it isn't one. */
	public function remove(child:Node):Bool {
		if (child.parent != this)
			return false;
		children.remove(child);
		child.parent = null;
		child.localDirty = true;
		return true;
	}

	/** Its position's x, relative to its parent. */
	public function getX():Float
		return px;

	/** Its position's y. */
	public function getY():Float
		return py;

	/** Its position's z. */
	public function getZ():Float
		return pz;

	/** Places it at x, y, z, relative to its parent. */
	public function setPosition(x:Float, y:Float, z:Float):Void {
		px = x;
		py = y;
		pz = z;
		localDirty = true;
	}

	/** Turns it by angles in radians about x, then y, then z, relative to its parent. */
	public function setRotation(x:Float, y:Float, z:Float):Void {
		var cx = Math.cos(x / 2),
			sx = Math.sin(x / 2),
			cy = Math.cos(y / 2),
			sy = Math.sin(y / 2),
			cz = Math.cos(z / 2),
			sz = Math.sin(z / 2);
		qx = sx * cy * cz - cx * sy * sz;
		qy = cx * sy * cz + sx * cy * sz;
		qz = cx * cy * sz - sx * sy * cz;
		qw = cx * cy * cz + sx * sy * sz;
		localDirty = true;
	}

	/** Scales it along its own x, y and z. */
	public function setScale(x:Float, y:Float, z:Float):Void {
		sx = x;
		sy = y;
		sz = z;
		localDirty = true;
	}

	/** Turns it so its -z looks from its position at x, y, z, up (0, 1, 0 by default) giving the roll; positions relative to its parent. False,
		changing nothing, when the point is its position or up is along the view. */
	public function lookAt(x:Float, y:Float, z:Float, upX = 0., upY = 1., upZ = 0.):Bool {
		// Its z axis points away from the target; x is up across z; y is z across x.
		var zx = px - x, zy = py - y, zz = pz - z, zl = Math.sqrt(zx * zx + zy * zy + zz * zz);
		if (zl == 0)
			return false;
		zx /= zl;
		zy /= zl;
		zz /= zl;
		var xx = upY * zz - upZ * zy,
			xy = upZ * zx - upX * zz,
			xz = upX * zy - upY * zx,
			xl = Math.sqrt(xx * xx + xy * xy + xz * xz);
		if (xl < 1e-12)
			return false;
		xx /= xl;
		xy /= xl;
		xz /= xl;
		var yx = zy * xz - zz * xy,
			yy = zz * xx - zx * xz,
			yz = zx * xy - zy * xx;
		// The rotation matrix's columns are x, y and z: its quaternion (Shepperd's method).
		var trace = xx + yy + zz;
		if (trace > 0) {
			var s = Math.sqrt(trace + 1) * 2;
			qw = s / 4;
			qx = (yz - zy) / s;
			qy = (zx - xz) / s;
			qz = (xy - yx) / s;
		} else if (xx > yy && xx > zz) {
			var s = Math.sqrt(1 + xx - yy - zz) * 2;
			qw = (yz - zy) / s;
			qx = s / 4;
			qy = (yx + xy) / s;
			qz = (zx + xz) / s;
		} else if (yy > zz) {
			var s = Math.sqrt(1 + yy - xx - zz) * 2;
			qw = (zx - xz) / s;
			qx = (yx + xy) / s;
			qy = s / 4;
			qz = (zy + yz) / s;
		} else {
			var s = Math.sqrt(1 + zz - xx - yy) * 2;
			qw = (xy - yx) / s;
			qx = (zx + xz) / s;
			qy = (zy + yz) / s;
			qz = s / 4;
		}
		localDirty = true;
		return true;
	}

	/** Its world matrix as the last update left it (Stage3D.draw updates it). */
	public function getWorldMatrix():Mat4
		return world;

	/** Brings its world matrix up to date from parentWorld when it or its parent changed; whether it changed. A stage calls this as it walks. */
	@:allow(helix.render3d.Stage3D)
	function update(parentWorld:Null<Mat4>, parentChanged:Bool):Bool {
		if (!localDirty && !parentChanged)
			return false;
		if (localDirty) {
			local.setTransform(px, py, pz, qx, qy, qz, qw, sx, sy, sz);
			localDirty = false;
		}
		if (parentWorld == null)
			world.setFrom(local);
		else
			world.setProduct(parentWorld, local);
		return true;
	}
}

/** What a node is. */
enum abstract NodeKind(Int) {
	/** Holds other nodes. */
	var Group = 0;

	/** A mesh drawn with a material. */
	var Model = 1;

	/** A light. */
	var LightNode = 2;
}
