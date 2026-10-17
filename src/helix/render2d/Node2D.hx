package helix.render2d;

import helix.render2d.Text2D.Align2D;

/** What a Stage2D holds: a transform in a tree, and its kind's data (a sprite's texture and region, a shape, a line of text). Made by the static
	constructors and never subclassed; a node only draws, and game state lives elsewhere, the node its view (docs/DECISIONS.md, 61). Its
	transform is a position, a rotation in radians (clockwise on screen, y growing down) and a scale, relative to its parent; its world transform
	is worked out when a stage draws it, only after it or a node above it changed. Colors are 0xRRGGBBAA. */
@:allow(helix.render2d.Stage2D)
class Node2D {
	var parentNode:Null<Node2D>;
	var children:Array<Node2D> = [];
	var sliceLeft = 0.;
	var sliceTop = 0.;
	var sliceRight = 0.;
	var sliceBottom = 0.;
	var px = 0.;
	var py = 0.;
	var angle = 0.;
	var sx = 1.;
	var sy = 1.;
	var texture:Null<Texture2D>;
	var sourceX = 0.;
	var sourceY = 0.;
	var sourceWidth = 0.;
	var sourceHeight = 0.;
	var givenWidth = 0.;
	var givenHeight = 0.;
	var radius = 0.;
	var points:Array<Float> = [];
	var triangles:Array<Int> = [];
	var outline = 0.;
	var cornerRadius = 0.;
	var content = "";
	var textSize = 16.;
	var font:Null<Font2D>;
	var align:Align2D = Left;
	var emitterOf:Null<helix.particles.Emitter>;
	var localDirty = true;

	// The world transform: a point x, y of its own is at wa * x + wc * y + wx, wb * x + wd * y + wy.
	var wa = 1.;
	var wb = 0.;
	var wc = 0.;
	var wd = 1.;
	var wx = 0.;
	var wy = 0.;

	function new(kind:Node2DKind) {
		this.kind = kind;
	}

	/** A group: a node that draws nothing, only a transform for its children (an empty in Blender, a dummy in 3ds Max, a null in Cinema 4D).
		Any node can have children; use a group when the parent shouldn't itself be a sprite, a shape or text: a handle that moves or hides a set of
		things together, or a pivot to turn them about. */
	public static function group():Node2D
		return new Node2D(Group);

	/** A sprite of texture (null for none yet: it draws nothing), the whole texture at its size in texels, turning about its center. */
	public static function sprite(texture:Null<Texture2D>):Node2D {
		var node = new Node2D(Sprite);
		node.texture = texture;
		node.pivotX = node.pivotY = .5;
		return node;
	}

	/** A filled rectangle width x height, its top-left at its position (pivot 0, 0). */
	public static function rectangle(width:Float, height:Float, color = 0xffffffff):Node2D {
		var node = new Node2D(Rectangle);
		node.givenWidth = Math.max(0, width);
		node.givenHeight = Math.max(0, height);
		node.color = color;
		return node;
	}

	/** A filled circle of radius, centered on its position. */
	public static function circle(radius:Float, color = 0xffffffff):Node2D {
		var node = new Node2D(Circle);
		node.radius = Math.max(0, radius);
		node.color = color;
		return node;
	}

	/** A line from x0, y0 to x1, y1 in its own units, as wide as its outline (1 until setOutline). */
	public static function line(x0:Float, y0:Float, x1:Float, y1:Float, color = 0xffffffff):Node2D {
		var node = new Node2D(Line);
		node.points = [x0, y0, x1, y1];
		node.outline = 1;
		node.color = color;
		return node;
	}

	/** A filled polygon through points in its own units (x and y in turn, copied; at least 3 points, convex or not, not crossing itself). Null
		for fewer than 3 points or an odd count. */
	public static function polygon(points:Array<Float>, color = 0xffffffff):Null<Node2D> {
		if (points.length < 6 || points.length % 2 != 0)
			return null;
		var node = new Node2D(Polygon);
		node.points = points.copy();
		node.triangles = Polygon2D.triangulate(node.points);
		node.color = color;
		return node;
	}

	/** One line of text, size world units tall (ascent to descent), in font (null: the drawing batch's built-in one); its position is the top
		of the text and, by align, its left edge, center or right edge. Not pickable until pickable is set: a label lets the pointer through to
		what it's on. */
	public static function text(value:String, size = 16., color = 0xffffffff, align:Align2D = Left, ?font:Font2D):Node2D {
		var node = new Node2D(Text);
		node.content = value;
		node.textSize = size;
		node.color = color;
		node.align = align;
		node.font = font;
		node.pickable = false;
		return node;
	}

	/** An emitter of particles (helix.particles.Emitter, made flat for 2D), placed here: it spawns where this node is in the world, and the
		stage advances it by its clock (Stage2D.setTime) each draw. Its particles draw at its place in the stage's order, through the GPU. */
	public static function emitter(emitter:helix.particles.Emitter):Node2D {
		var node = new Node2D(Emitter);
		node.emitterOf = emitter;
		return node;
	}

	/** An emitter node's emitter; null for another kind. */
	public function getEmitter():Null<helix.particles.Emitter>
		return emitterOf;

	/** Its kind. */
	public var kind(default, null):Node2DKind;

	/** Its name, what the game gave it; "" for none. */
	public var name:String = "";

	/** The first node named name below it (depth first, in drawing order), or null: found once and kept, never a path. */
	public function find(name:String):Null<Node2D> {
		for (child in children) {
			if (child.name == name)
				return child;
			var found = child.find(name);
			if (found != null)
				return found;
		}
		return null;
	}

	/** Its color: what a sprite's texels are multiplied by (white leaves them as they are), a shape's or text's color. */
	public var color:Int = 0xffffffff;

	/** A sprite's texture, or null. */
	public function getTexture():Null<Texture2D>
		return texture;

	/** Gives a sprite a texture (null for none: it draws nothing). False for another kind. */
	public function setTexture(value:Null<Texture2D>):Bool {
		if (kind != Sprite)
			return false;
		texture = value;
		return true;
	}

	/** A sprite's region of its texture, in texels from its top-left; a width or height of 0 or less (the default) shows the whole texture.
		False for another kind. */
	public function setRegion(x:Float, y:Float, width:Float, height:Float):Bool {
		if (kind != Sprite)
			return false;
		sourceX = x;
		sourceY = y;
		sourceWidth = width;
		sourceHeight = height;
		return true;
	}

	/** A sprite's region's left, in texels. */
	public var regionX(get, never):Float;

	function get_regionX():Float
		return sourceX;

	/** A sprite's region's top, in texels. */
	public var regionY(get, never):Float;

	function get_regionY():Float
		return sourceY;

	/** A sprite's region's width in texels: what was set, or else its texture's (0 without one). */
	public var regionWidth(get, never):Float;

	function get_regionWidth():Float
		return sourceWidth > 0 && sourceHeight > 0 ? sourceWidth : texture == null ? 0 : texture.width;

	/** A sprite's region's height in texels: what was set, or else its texture's (0 without one). */
	public var regionHeight(get, never):Float;

	function get_regionHeight():Float
		return sourceWidth > 0 && sourceHeight > 0 ? sourceHeight : texture == null ? 0 : texture.height;

	/** The width it draws at, in its own units: a rectangle's, or a sprite's as set, else its region's in texels. */
	public var width(get, never):Float;

	function get_width():Float
		return kind == Sprite && !(givenWidth > 0 && givenHeight > 0) ? this.regionWidth : givenWidth;

	/** The height it draws at, in its own units: a rectangle's, or a sprite's as set, else its region's in texels. */
	public var height(get, never):Float;

	function get_height():Float
		return kind == Sprite && !(givenWidth > 0 && givenHeight > 0) ? this.regionHeight : givenHeight;

	/** Sizes a sprite or a rectangle, in its own units; for a sprite, a width or height of 0 or less goes back to its region's size. False for
		another kind, or a rectangle's size below 0. */
	public function setSize(width:Float, height:Float):Bool {
		if (kind != Sprite && (kind != Rectangle || !(width >= 0 && height >= 0)))
			return false;
		this.givenWidth = width;
		this.givenHeight = height;
		return true;
	}

	/** The point of a sprite or rectangle at its position, which it turns and scales about, as a fraction of its size: 0, 0 its top-left, 1,
		1 its bottom-right. */
	public var pivotX(default, null):Float = 0.;

	/** The pivot's y fraction. */
	public var pivotY(default, null):Float = 0.;

	/** Sets a sprite's or rectangle's pivot. False for another kind. */
	public function setPivot(x:Float, y:Float):Bool {
		if (kind != Sprite && kind != Rectangle)
			return false;
		pivotX = x;
		pivotY = y;
		return true;
	}

	/** A circle's radius; 0 for another kind. */
	public function getRadius():Float
		return radius;

	/** Sets a circle's radius. False for another kind or a radius below 0. */
	public function setRadius(value:Float):Bool {
		if (kind != Circle || !(value >= 0))
			return false;
		radius = value;
		return true;
	}

	/** A polygon's points or a line's ends, x and y in turn (a copy); empty for another kind. */
	public function getPoints():Array<Float>
		return points.copy();

	/** Gives a polygon new points (as polygon() takes them) or a line new ends (4 floats). False for another kind or a wrong count. */
	public function setPoints(value:Array<Float>):Bool {
		if (kind == Line && value.length == 4) {
			points = value.copy();
			return true;
		}
		if (kind != Polygon || value.length < 6 || value.length % 2 != 0)
			return false;
		points = value.copy();
		triangles = Polygon2D.triangulate(points);
		return true;
	}

	/** A rectangle's corners' radius, in its own units; 0 for square (and for another kind). */
	public function getCornerRadius():Float
		return cornerRadius;

	/** Rounds a rectangle's corners to radius (drawn at most half its shorter side; outlined, the outline's middle follows the corners), and
		picks it by its rounded shape. False for another kind or a radius below 0. */
	public function setCornerRadius(radius:Float):Bool {
		if (kind != Rectangle || !(radius >= 0))
			return false;
		cornerRadius = radius;
		return true;
	}

	/** A shape's outline width, in its own units; 0 for filled. */
	public function getOutline():Float
		return outline;

	/** Draws a rectangle, circle or polygon as its outline, width wide centered on its edge, or filled for 0; a line's width. False for another
		kind or a width below 0 (0 for a line). */
	public function setOutline(width:Float):Bool {
		if ((kind != Rectangle && kind != Circle && kind != Polygon && kind != Line) || !(width >= 0) || (kind == Line && width == 0))
			return false;
		outline = width;
		return true;
	}

	/** A text node's text; "" for another kind. */
	public function getText():String
		return content;

	/** Sets a text node's text. False for another kind. */
	public function setText(value:String):Bool {
		if (kind != Text)
			return false;
		content = value;
		return true;
	}

	/** A text node's size, world units tall. */
	public function getTextSize():Float
		return textSize;

	/** Sets a text node's size. False for another kind or a size of 0 or less. */
	public function setTextSize(value:Float):Bool {
		if (kind != Text || !(value > 0))
			return false;
		textSize = value;
		return true;
	}

	/** A text node's font, or null for the drawing batch's built-in one. */
	public function getFont():Null<Font2D>
		return font;

	/** Sets a text node's font (null: the batch's built-in one). False for another kind. */
	public function setFont(value:Null<Font2D>):Bool {
		if (kind != Text)
			return false;
		font = value;
		return true;
	}

	/** A text node's alignment. */
	public function getAlign():Align2D
		return align;

	/** Aligns a text node's text on its position: Left, Center or Right. False for another kind. */
	public function setAlign(value:Align2D):Bool {
		if (kind != Text)
			return false;
		align = value;
		return true;
	}

	/** Draws a sprite as a nine-slice frame (Batch2D.nineSlice): its region's corners left, top, right and bottom texels in from its edges keep
		their size as it's sized, its edges and middle stretch. All 0 (the start) draws it stretched whole. False for another kind or an inset
		below 0. */
	public function setNineSlice(left:Float, top:Float, right:Float, bottom:Float):Bool {
		if (kind != Sprite || !(left >= 0 && top >= 0 && right >= 0 && bottom >= 0))
			return false;
		sliceLeft = left;
		sliceTop = top;
		sliceRight = right;
		sliceBottom = bottom;
		return true;
	}

	/** A nine-slice's left inset, texels. */
	public var nineSliceLeft(get, never):Float;

	function get_nineSliceLeft():Float
		return sliceLeft;

	/** A nine-slice's top inset, texels. */
	public var nineSliceTop(get, never):Float;

	function get_nineSliceTop():Float
		return sliceTop;

	/** A nine-slice's right inset, texels. */
	public var nineSliceRight(get, never):Float;

	function get_nineSliceRight():Float
		return sliceRight;

	/** A nine-slice's bottom inset, texels. */
	public var nineSliceBottom(get, never):Float;

	function get_nineSliceBottom():Float
		return sliceBottom;

	/** Whether a sprite draws as a nine-slice frame. */
	public var nineSlice(get, never):Bool;

	function get_nineSlice():Bool
		return sliceLeft > 0 || sliceTop > 0 || sliceRight > 0 || sliceBottom > 0;

	/** A text's wrap width in its own units: 0 for one line. */
	public var wrapWidth(default, null):Float = 0.;

	/** A wrapped text's lines apart, times its size. */
	public var lineHeight(default, null):Float = 1.25;

	/** Wraps a text to width in its own units (Text2D.wrap), its lines lineHeight times its size apart; 0 for one line. False for another kind, a
		width below 0 or a line height of 0 or less. */
	public function setWrapWidth(width:Float, lineHeight = 1.25):Bool {
		if (kind != Text || !(width >= 0) || !(lineHeight > 0))
			return false;
		wrapWidth = width;
		this.lineHeight = lineHeight;
		return true;
	}

	/** A text's height in its own units as drawn: its size, or its wrapped lines' (with font, the font it's drawn in). */
	public function getTextHeight(font:Font2D):Float {
		if (kind != Text)
			return 0;
		if (wrapWidth <= 0)
			return textSize;
		var lines = Text2D.wrap(font, content, textSize, wrapWidth).length;
		return textSize * (1 + lineHeight * (lines - 1));
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

	/** Whether it takes part at all: off, it and everything under it are skipped by drawing, picking and updates (an emitter under it isn't
		moved on), as if it weren't in the tree. The only flag that reaches its children; theirs are kept, so enabling it brings each back as
		set. On to start. */
	public var enabled(default, set):Bool = true;

	function set_enabled(value:Bool):Bool {
		// Off, it isn't brought up to date as its parent moves: on again, it is.
		if (value && !enabled)
			localDirty = true;
		enabled = value;
		return value;
	}

	/** Whether its own output is drawn: off, a sprite, shape, text or emitter isn't drawn (an emitter still moves on); it stays
		placed, and its children are as they are. On to start. */
	public var visible:Bool = true;

	/** Whether a pick can hit its own output: off, the ray passes through it, though its children can still be hit. Drawing doesn't matter to
		it: hidden and pickable is a hit area. On to start, but for text. */
	public var pickable:Bool = true;

	/** Its parent, or null at a tree's top. Assigning a node makes this its last child as that node's addChild does, keeping this one's
		local transform (addChildInPlace keeps the world one); assigning null takes it from its parent as the parent's removeChild does. A
		node under itself or one of its own descendants is refused, leaving the tree as it was. */
	public var parent(get, set):Null<Node2D>;

	function get_parent():Null<Node2D>
		return parentNode;

	function set_parent(value:Null<Node2D>):Null<Node2D> {
		if (value != null)
			value.addChild(this);
		else if (parentNode != null)
			parentNode.removeChild(this);
		return parentNode;
	}

	/** How many children it has. */
	public var childCount(get, never):Int;

	function get_childCount():Int
		return children.length;

	/** Its child at index, in drawing order; null past the end. */
	public function getChild(index:Int):Null<Node2D>
		return index >= 0 && index < children.length ? children[index] : null;

	/** Makes child its last child (drawn over the others), taking it from any parent it had, keeping child's local transform: it moves
		with this node as it sat under its old parent (a hat onto a head joint). addChildInPlace keeps its world transform instead. False,
		changing nothing, for itself or one of its own ancestors. */
	public function addChild(child:Node2D):Bool {
		var at:Null<Node2D> = this;
		while (at != null) {
			if (at == child)
				return false;
			at = at.parentNode;
		}
		if (child.parentNode != null)
			child.parentNode.children.remove(child);
		child.parentNode = this;
		children.push(child);
		child.localDirty = true;
		return true;
	}

	/** Puts child under this node without it moving: its world transform is kept and its local one recomputed from this node's (a dropped
		sword picked up by a hand). addChild keeps the child's local transform instead (a hat onto a head joint). A shear the two
		transforms make together is lost. False, changing nothing, for itself or one of its own ancestors, or this scaled to nothing. */
	public function addChildInPlace(child:Node2D):Bool {
		var at:Null<Node2D> = this;
		while (at != null) {
			if (at == child)
				return false;
			at = at.parentNode;
		}
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
			at = at.parentNode;
		}
		return w;
	}

	/** Takes child from its children. False when it isn't one. */
	public function removeChild(child:Node2D):Bool {
		if (child.parentNode != this)
			return false;
		children.remove(child);
		child.parentNode = null;
		child.localDirty = true;
		return true;
	}

	/** Its position's x, relative to its parent. */
	public var x(get, never):Float;

	function get_x():Float
		return px;

	/** Its position's y. */
	public var y(get, never):Float;

	function get_y():Float
		return py;

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

	/** Its scale along its own x. */
	public var scaleX(get, never):Float;

	function get_scaleX():Float
		return sx;

	/** Its scale along its own y. */
	public var scaleY(get, never):Float;

	function get_scaleY():Float
		return sy;

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
	function update(parentChanged:Bool):Bool {
		if (!localDirty && !parentChanged)
			return false;
		localDirty = false;
		var c = Math.cos(angle), s = Math.sin(angle);
		// Scale, then turn, then place: its own transform.
		var la = c * sx, lb = s * sx, lc = -s * sy, ld = c * sy;
		if (parentNode == null) {
			wa = la;
			wb = lb;
			wc = lc;
			wd = ld;
			wx = px;
			wy = py;
		} else {
			var p = parentNode;
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

/** What a 2D node is. */
enum abstract Node2DKind(Int) {
	/** Draws nothing: a transform for its children. */
	var Group = 0;

	/** A texture, or a region of one. */
	var Sprite = 1;

	/** A rectangle, filled or outlined, its corners square or rounded. */
	var Rectangle = 2;

	/** A circle, filled or outlined. */
	var Circle = 3;

	/** A line segment. */
	var Line = 4;

	/** A polygon, filled or outlined. */
	var Polygon = 5;

	/** A line of text. */
	var Text = 6;

	/** A particle emitter's place. */
	var Emitter = 7;
}
