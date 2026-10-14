package helix.render3d;

/** What a stage holds: a transform in a tree, and its kind's data (a model's mesh, material and tint; a sprite's texture, region, size, facing
	and alpha mode; a light; a camera). Made by the static
	constructors and never subclassed; a node only draws or lights, and game state lives elsewhere, the node its view (docs/DECISIONS.md, 61).
	Its transform is a position, a rotation (a unit quaternion, set from angles or by lookAt) and a scale, relative to its parent; its world
	matrix is worked out when a stage draws it, only after it or a node above it changed. */
class Node {
	var kind:NodeKind;
	var name = "";
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
	var cameraOf:Null<Camera3D>;
	var texture:Null<helix.render2d.Texture2D>;
	var regionX = 0.;
	var regionY = 0.;
	var regionWidth = 0.;
	var regionHeight = 0.;
	var spriteWidth = 1.;
	var spriteHeight = 1.;
	var pivotX = .5;
	var pivotY = .5;
	var facing:SpriteFacing = Camera;
	var alphaMode:SpriteAlpha = Blend;
	var cutoff = .5;
	var local = new Mat4();
	var world = new Mat4();
	var localDirty = true;

	function new(kind:NodeKind) {
		this.kind = kind;
	}

	/** A group: a node that draws nothing, only a transform for its children (an empty in Blender, a dummy in 3ds Max, a null in Cinema 4D).
		Any node can have children; use a group when the parent shouldn't itself be a model or a light: a handle that moves or hides a set of
		things together, or a pivot to turn them about. */
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

	/** A camera, seeing from this node's place down its -z, its +y up (its scale ignored): parent it to what it should follow, or aim it with
		lookAt. The camera is drawn through as any (Stage3D.draw, Batch3D.begin), and while it is on this node its view is the node's; a camera
		on another node moves here. */
	public static function camera(camera:Camera3D):Node {
		var node = new Node(CameraNode);
		if (camera.node != null)
			camera.node.cameraOf = null;
		camera.node = node;
		node.cameraOf = camera;
		return node;
	}

	/** A sprite: texture (null for none yet: it draws nothing) on a quad 1 x 1 world units, centered on its position, facing the camera, blended
		by its alpha, unlit, tinted (0xRRGGBBAA, sRGB, as 2D sprites are). Its scale scales it; its rotation turns it only when its facing is its
		own (Ground, Free). */
	public static function sprite(texture:Null<helix.render2d.Texture2D>, tint = 0xffffffff):Node {
		var node = new Node(SpriteNode);
		node.texture = texture;
		node.tint = tint;
		return node;
	}

	/** A sprite's texture, or null. */
	public function getTexture():Null<helix.render2d.Texture2D>
		return texture;

	/** Gives a sprite a texture (null for none: it draws nothing). False for another kind. */
	public function setTexture(value:Null<helix.render2d.Texture2D>):Bool {
		if (kind != SpriteNode)
			return false;
		texture = value;
		return true;
	}

	/** A sprite's region of its texture, in texels from its top-left; a width or height of 0 or less (the default) shows the whole texture.
		False for another kind. */
	public function setRegion(x:Float, y:Float, width:Float, height:Float):Bool {
		if (kind != SpriteNode)
			return false;
		regionX = x;
		regionY = y;
		regionWidth = width;
		regionHeight = height;
		return true;
	}

	/** A sprite's region: x, y, width, height in texels (a width or height of 0 or less: the whole texture). */
	public function getRegion():Array<Float>
		return [regionX, regionY, regionWidth, regionHeight];

	/** A sprite's size in world units, before its scale (1 x 1 by default). */
	public function getSpriteWidth():Float
		return spriteWidth;

	/** A sprite's height in world units, before its scale. */
	public function getSpriteHeight():Float
		return spriteHeight;

	/** Sizes a sprite, in world units before its scale. False for another kind, or a size below 0. */
	public function setSpriteSize(width:Float, height:Float):Bool {
		if (kind != SpriteNode || !(width >= 0 && height >= 0))
			return false;
		spriteWidth = width;
		spriteHeight = height;
		return true;
	}

	/** The point of a sprite at its position, which it turns and scales about, as a fraction of its size: 0, 0 its top-left, 1, 1 its
		bottom-right (0.5, 0.5, its center, by default). False for another kind. */
	public function setPivot(x:Float, y:Float):Bool {
		if (kind != SpriteNode)
			return false;
		pivotX = x;
		pivotY = y;
		return true;
	}

	/** A sprite's pivot's x fraction. */
	public function getPivotX():Float
		return pivotX;

	/** A sprite's pivot's y fraction. */
	public function getPivotY():Float
		return pivotY;

	/** How a sprite faces. */
	public function getFacing():SpriteFacing
		return facing;

	/** Sets how a sprite faces. False for another kind. */
	public function setFacing(value:SpriteFacing):Bool {
		if (kind != SpriteNode)
			return false;
		facing = value;
		return true;
	}

	/** How a sprite's texels' alpha is used. */
	public function getAlphaMode():SpriteAlpha
		return alphaMode;

	/** The alpha below which a Mask sprite's texels are cut out (0..1). */
	public function getAlphaCutoff():Float
		return cutoff;

	/** Sets how a sprite uses its texels' alpha, and a Mask's cutoff (0..1, 0.5 by default). False for another kind or a cutoff outside 0..1. */
	public function setAlphaMode(mode:SpriteAlpha, cutoff = .5):Bool {
		if (kind != SpriteNode || !(cutoff >= 0 && cutoff <= 1))
			return false;
		alphaMode = mode;
		this.cutoff = cutoff;
		return true;
	}

	/** Its kind. */
	public function getKind():NodeKind
		return kind;

	/** Its name: a model file's node name, or what the game gave it; "" for none. */
	public function getName():String
		return name;

	/** Names it. */
	public function setName(value:String):Void
		name = value;

	/** The first node named name below it (depth first, in drawing order), or null: for picking out a part of a loaded model (its wheels, a
		lamp), once, and keeping the node. Never a path. */
	public function find(name:String):Null<Node> {
		for (child in children) {
			if (child.name == name)
				return child;
			var found = child.find(name);
			if (found != null)
				return found;
		}
		return null;
	}

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

	/** A camera node's camera; null for another kind, or a camera since moved to another node. */
	public function getCamera():Null<Camera3D>
		return cameraOf;

	/** Its world matrix as it is now, into out: its own transform and every one above it, worked out afresh without touching what a stage keeps
		(a camera node's view is found so before the stage's walk). */
	public function computeWorld(out:Mat4):Void {
		out.setTransform(px, py, pz, qx, qy, qz, qw, sx, sy, sz);
		var at = parent, above = new Mat4(), product = new Mat4();
		// Two scratch matrices a call: a chain of parents is short, and a camera asks once a draw.
		while (at != null) {
			above.setTransform(at.px, at.py, at.pz, at.qx, at.qy, at.qz, at.qw, at.sx, at.sy, at.sz);
			product.setProduct(above, out);
			out.setFrom(product);
			at = at.parent;
		}
	}

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

	/** Turns it by the unit quaternion x, y, z, w, relative to its parent (normalized here; the identity for a zero one). */
	public function setQuaternion(x:Float, y:Float, z:Float, w:Float):Void {
		var length = Math.sqrt(x * x + y * y + z * z + w * w);
		if (length == 0) {
			qx = qy = qz = 0;
			qw = 1;
		} else {
			qx = x / length;
			qy = y / length;
			qz = z / length;
			qw = w / length;
		}
		localDirty = true;
	}

	/** Places, turns and scales it by a matrix (16 floats, column-major) relative to its parent, taken apart into translation, rotation and
		scale; a shear is lost. False, changing nothing, for one of the wrong length or with a zero scale. */
	public function setMatrix(m:Array<Float>):Bool {
		if (m.length != 16)
			return false;
		var ax = Math.sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2]),
			ay = Math.sqrt(m[4] * m[4] + m[5] * m[5] + m[6] * m[6]),
			az = Math.sqrt(m[8] * m[8] + m[9] * m[9] + m[10] * m[10]);
		if (ax == 0 || ay == 0 || az == 0)
			return false;
		// A mirroring matrix: one axis negated.
		var det = m[0] * (m[5] * m[10] - m[9] * m[6]) - m[4] * (m[1] * m[10] - m[9] * m[2]) + m[8] * (m[1] * m[6] - m[5] * m[2]);
		if (det < 0)
			ax = -ax;
		px = m[12];
		py = m[13];
		pz = m[14];
		sx = ax;
		sy = ay;
		sz = az;
		// The rotation's columns are the axes over their scales: its quaternion (Shepperd's method).
		var xx = m[0] / ax,
			xy = m[1] / ax,
			xz = m[2] / ax,
			yx = m[4] / ay,
			yy = m[5] / ay,
			yz = m[6] / ay,
			zx = m[8] / az,
			zy = m[9] / az,
			zz = m[10] / az;
		var trace = xx + yy + zz;
		if (trace > 0) {
			var s = Math.sqrt(trace + 1) * 2;
			setQuaternion((yz - zy) / s, (zx - xz) / s, (xy - yx) / s, s / 4);
		} else if (xx > yy && xx > zz) {
			var s = Math.sqrt(1 + xx - yy - zz) * 2;
			setQuaternion(s / 4, (yx + xy) / s, (zx + xz) / s, (yz - zy) / s);
		} else if (yy > zz) {
			var s = Math.sqrt(1 + yy - xx - zz) * 2;
			setQuaternion((yx + xy) / s, s / 4, (zy + yz) / s, (zx - xz) / s);
		} else {
			var s = Math.sqrt(1 + zz - xx - yy) * 2;
			setQuaternion((zx + xz) / s, (zy + yz) / s, s / 4, (xy - yx) / s);
		}
		return true;
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
	/** Draws nothing: a transform for its children. */
	var Group = 0;

	/** A mesh drawn with a material. */
	var Model = 1;

	/** A light. */
	var LightNode = 2;

	/** A camera's place and aim. */
	var CameraNode = 3;

	/** A textured quad: a sprite. */
	var SpriteNode = 4;
}

/** How a 3D sprite faces. */
enum abstract SpriteFacing(Int) to Int {
	/** The camera, square to its view: a coin, a glow, a particle. */
	var Camera = 0;

	/** The camera, turning about y and staying upright: a tree, a character drawn flat. */
	var Upright = 1;

	/** Flat, its texture's top toward its node's -z, facing its node's +y (the ground's up, unturned): a decal, a shadow blob. */
	var Ground = 2;

	/** As its node is turned: in the node's x-y plane, facing its +z. A sign. */
	var Free = 3;
}

/** How a 3D sprite uses its texels' alpha. */
enum abstract SpriteAlpha(Int) to Int {
	/** Ignored: drawn solid, with the opaque models. */
	var Opaque = 0;

	/** Texels below a cutoff are cut out, the rest solid: leaves, fences. Drawn with the opaque models. */
	var Mask = 1;

	/** Blended by it, among the see-through models back to front. */
	var Blend = 2;

	/** Added, times it, after everything else: light, fire, glows. */
	var Add = 3;
}
