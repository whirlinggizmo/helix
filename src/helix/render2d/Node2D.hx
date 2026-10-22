package helix.render2d;

import helix.scene.Node;
import helix.font.Font;

/** What a Renderer2D holds: a transform in a tree, with children of its own kind. A bare one is a group: it draws nothing, only a transform for
	its children (an empty in Blender, a dummy in 3ds Max, a null in Cinema 4D), a handle that moves or hides a set of things together, or a
	pivot to turn them about. The framework's kinds are its classes (Sprite2D, Shape2D, Text2D, Particles2D), each holding only its own data;
	a game never subclasses one, and game state lives elsewhere, the node its view (docs/DECISIONS.md, 61 and 130). Its transform is a
	position, a rotation in radians (clockwise on screen, y growing down) and a scale, relative to its parent; its world transform is worked
	out when a stage draws it, only after it or a node above it changed. Any node can clip its children (setClip). */
@:allow(helix.render2d.Renderer2D)
class Node2D extends Node {
	var px = 0.;
	var py = 0.;
	var angle = 0.;
	var sx = 1.;
	var sy = 1.;
	var localDirty = true;
	// At a tree's top, counted up by every addChild and removeChild below it: a stage keeps its drawing order until its root's count moves.
	var structure = 0;

	// The world transform: a point x, y of its own is at wa * x + wc * y + wx, wb * x + wd * y + wy.
	var wa = 1.;
	var wb = 0.;
	var wc = 0.;
	var wd = 1.;
	var wx = 0.;
	var wy = 0.;

	/** How opaque it and everything under it are drawn, 0 (not seen) to 1, multiplied down the tree: fading a group fades its children, as a
		Flash display object's alpha did. Clamped to 0..1; 1 to start. Particles aren't faded by it. */
	public var alpha(default, set):Float = 1.;

	function set_alpha(value:Float):Float {
		alpha = value > 0 ? (value < 1 ? value : 1) : 0;
		return alpha;
	}

	// A kind that draws itself, not the walk (an emitter, a drawing, a view: each linked only into a program that makes one): into batch,
	// through camera, at the walk's time with dt since its last draw, held still when frozen (under a paused node), shown only when shown (an
	// emitter moves on hidden too). Whether it is one; a group isn't.

	@:allow(helix.render2d.Renderer2D)
	function drawOwn(batch:Batch2D, camera:Camera2D, time:Float, dt:Float, frozen:Bool, shown:Bool):Bool
		return false;

	// Whether it picks itself (pickOwn) rather than by the walk's areas for its kind.
	@:allow(helix.render2d.Renderer2D)
	var picksOwn(get, never):Bool;

	function get_picksOwn():Bool
		return false;

	// A kind that picks itself: what it has under framebuffer pixel x, y (its own point lx, ly; font for text without its own), itself or a
	// node it shows, or null.

	@:allow(helix.render2d.Renderer2D)
	function pickOwn(x:Float, y:Float, lx:Float, ly:Float, font:Null<Font>):Null<Node2D>
		return null;

	/** A group at the origin, unturned and unscaled, with no children. */
	public function new()
		super();

	/** Its parent, or null at a tree's top. Assigning a node makes this its last child as that node's addChild does, keeping this one's
		local transform (addChildInPlace keeps the world one); assigning null takes it from its parent as the parent's removeChild does. A
		node under itself or one of its own descendants is refused, leaving the tree as it was. */
	public var parent(get, set):Null<Node2D>;

	function get_parent():Null<Node2D>
		return cast parentNode;

	function set_parent(value:Null<Node2D>):Null<Node2D> {
		if (value != null)
			value.addChild(this);
		else if (parentNode != null)
			get_parent().removeChild(this);
		return get_parent();
	}

	/** Its child at index, in drawing order; null past the end. */
	override public function getChild(index:Int):Null<Node2D>
		return cast super.getChild(index);

	/** The first node named name below it (depth first, in drawing order), or null: found once and kept, never a path. */
	override public function find(name:String):Null<Node2D>
		return cast super.find(name);

	override function set_enabled(value:Bool):Bool {
		// Off, it isn't brought up to date as its parent moves: on again, it is.
		if (value && !enabled)
			localDirty = true;
		super.set_enabled(value);
		return value;
	}

	/** Makes child its last child (drawn over the others), taking it from any parent it had, keeping child's local transform: it moves
		with this node as it sat under its old parent (a hat onto a head joint). addChildInPlace keeps its world transform instead. False,
		changing nothing, for itself or one of its own ancestors. */
	public function addChild(child:Node2D):Bool {
		var from = child.parent;
		if (!link(child))
			return false;
		if (from != null)
			from.changed();
		changed();
		child.localDirty = true;
		return true;
	}

	/** Puts child under this node without it moving: its world transform is kept and its local one recomputed from this node's (a dropped
		sword picked up by a hand). addChild keeps the child's local transform instead (a hat onto a head joint). A shear the two
		transforms make together is lost. False, changing nothing, for itself or one of its own ancestors, or this scaled to nothing. */
	public function addChildInPlace(child:Node2D):Bool {
		if (!canLink(child))
			return false;
		var c = worldOf(child), p = worldOf(this);
		var det = p[0] * p[3] - p[1] * p[2];
		if (det == 0 || !Math.isFinite(det))
			return false;
		// The parent's inverse times the child's world: the child's new local transform.
		var ia = p[3] / det,
			ib = -p[1] / det,
			ic = -p[2] / det,
			id = p[0] / det;
		var ix = -(ia * p[4] + ic * p[5]), iy = -(ib * p[4] + id * p[5]);
		var la = ia * c[0] + ic * c[1], lb = ib * c[0] + id * c[1];
		var lc = ia * c[2] + ic * c[3], ld = ib * c[2] + id * c[3];
		var lx = ia * c[4] + ic * c[5] + ix, ly = ib * c[4] + id * c[5] + iy;
		addChild(child);
		child.px = lx;
		child.py = ly;
		child.angle = Math.atan2(lb, la);
		child.sx = Math.sqrt(la * la + lb * lb);
		var cos = Math.cos(child.angle), sin = Math.sin(child.angle);
		child.sy = cos * ld - sin * lc;
		child.localDirty = true;
		return true;
	}

	/** Takes child from its children. False when it isn't one. */
	public function removeChild(child:Node2D):Bool {
		if (!unlink(child))
			return false;
		changed();
		child.localDirty = true;
		return true;
	}

	// Its tree's shape changed: counted at the top.
	function changed():Void {
		var top:Node2D = this;
		while (top.parentNode != null)
			top = cast top.parentNode;
		top.structure++;
	}

	// node's world transform as it is now, a, b, c, d, x, y (as update keeps it), worked out afresh from its own and every one above it.
	static function worldOf(node:Node2D):Array<Float> {
		var w = [1., 0., 0., 1., 0., 0.];
		var at = node;
		while (at != null) {
			var cos = Math.cos(at.angle), sin = Math.sin(at.angle);
			var la = cos * at.sx,
				lb = sin * at.sx,
				lc = -sin * at.sy,
				ld = cos * at.sy;
			w = [
				la * w[0] + lc * w[1],
				lb * w[0] + ld * w[1],
				la * w[2] + lc * w[3],
				lb * w[2] + ld * w[3],
				la * w[4] + lc * w[5] + at.px,
				lb * w[4] + ld * w[5] + at.py
			];
			at = at.parent;
		}
		return w;
	}

	/** Whether its children are clipped (setClip). */
	public var clipping(get, never):Bool;

	function get_clipping():Bool
		return clipWidth >= 0;

	/** The clip's width in its own units, or -1 without one. */
	public var clipWidth(default, null):Float = -1.;

	/** The clip's height in its own units, or -1 without one. */
	public var clipHeight(default, null):Float = -1.;

	/** Clips its children (drawn and picked) to the rectangle width x height from its own origin, in its own units: a scrolling list's window. A
		turned node clips to the turned rectangle's bounds. Its own output isn't clipped. False, changing nothing, for a size below 0. */
	public function setClip(width:Float, height:Float):Bool {
		if (!(width >= 0 && height >= 0))
			return false;
		clipWidth = width;
		clipHeight = height;
		return true;
	}

	/** Stops clipping its children. */
	public function clearClip():Void
		clipWidth = clipHeight = -1;

	/** Its position's x, relative to its parent. */
	public var x(get, set):Float;

	function get_x():Float
		return px;

	function set_x(value:Float):Float {
		px = value;
		localDirty = true;
		return value;
	}

	/** Its position's y, relative to its parent (down the screen). */
	public var y(get, set):Float;

	function get_y():Float
		return py;

	function set_y(value:Float):Float {
		py = value;
		localDirty = true;
		return value;
	}

	/** Places it at x, y, relative to its parent. */
	public function setPosition(x:Float, y:Float):Void {
		px = x;
		py = y;
		localDirty = true;
	}

	/** Its rotation in radians, clockwise on screen, relative to its parent. */
	public var rotation(get, set):Float;

	function get_rotation():Float
		return angle;

	function set_rotation(radians:Float):Float {
		angle = radians;
		localDirty = true;
		return radians;
	}

	/** Its scale along its own x; a negative scale mirrors it. */
	public var scaleX(get, set):Float;

	function get_scaleX():Float
		return sx;

	function set_scaleX(value:Float):Float {
		sx = value;
		localDirty = true;
		return value;
	}

	/** Its scale along its own y; a negative scale mirrors it. */
	public var scaleY(get, set):Float;

	function get_scaleY():Float
		return sy;

	function set_scaleY(value:Float):Float {
		sy = value;
		localDirty = true;
		return value;
	}

	/** Scales it along its own x and y; a negative scale mirrors it. */
	public function setScale(x:Float, y:Float):Void {
		sx = x;
		sy = y;
		localDirty = true;
	}

	/** The world x of its own point x, y, as the last draw placed it. */
	public function toWorldX(x:Float, y:Float):Float
		return wa * x + wc * y + wx;

	/** The world y of its own point x, y, as the last draw placed it. */
	public function toWorldY(x:Float, y:Float):Float
		return wb * x + wd * y + wy;

	/** The x in its own units of world point x, y, as the last draw placed it; NaN when it is scaled to nothing. */
	public function toLocalX(x:Float, y:Float):Float {
		var det = wa * wd - wb * wc;
		return (wd * (x - wx) - wc * (y - wy)) / det;
	}

	/** The y in its own units of world point x, y, as the last draw placed it; NaN when it is scaled to nothing. */
	public function toLocalY(x:Float, y:Float):Float {
		var det = wa * wd - wb * wc;
		return (wa * (y - wy) - wb * (x - wx)) / det;
	}

	/** Brings its world transform up to date from its parent's when it or its parent changed; whether it changed. A stage calls this as it walks. */
	function updateWorld(parentChanged:Bool):Bool {
		if (!localDirty && !parentChanged)
			return false;
		localDirty = false;
		var c = Math.cos(angle), s = Math.sin(angle);
		// Scale, then turn, then place: its own transform.
		var la = c * sx, lb = s * sx, lc = -s * sy, ld = c * sy;
		var p:Null<Node2D> = cast parentNode;
		if (p == null) {
			wa = la;
			wb = lb;
			wc = lc;
			wd = ld;
			wx = px;
			wy = py;
		} else {
			wa = p.wa * la + p.wc * lb;
			wb = p.wb * la + p.wd * lb;
			wc = p.wa * lc + p.wc * ld;
			wd = p.wb * lc + p.wd * ld;
			wx = p.wa * px + p.wc * py + p.wx;
			wy = p.wb * px + p.wd * py + p.wy;
		}
		return true;
	}
}
