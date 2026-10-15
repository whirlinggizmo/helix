package helix.render2d;

import helix.render2d.Text2D.Align2D;

/** What a Stage2D holds: a transform in a tree, and its kind's data (a sprite's texture and region, a shape, a line of text). Made by the static
	constructors and never subclassed; a node only draws, and game state lives elsewhere, the node its view (docs/DECISIONS.md, 61). Its
	transform is a position, a rotation in radians (clockwise on screen, y growing down) and a scale, relative to its parent; its world transform
	is worked out when a stage draws it, only after it or a node above it changed. Colors are 0xRRGGBBAA. */
@:allow(helix.render2d.Stage2D)
class Node2D {
	var kind:Node2DKind;
	var name = "";
	var parent:Null<Node2D>;
	var children:Array<Node2D> = [];
	var enabled = true;
	var clipWidth = -1.;
	var sliceLeft = 0.;
	var sliceTop = 0.;
	var sliceRight = 0.;
	var sliceBottom = 0.;
	var wrapWidth = 0.;
	var lineHeight = 1.25;
	var clipHeight = -1.;
	var visible = true;
	var pickable = true;
	var px = 0.;
	var py = 0.;
	var angle = 0.;
	var sx = 1.;
	var sy = 1.;
	var color = 0xffffffff;
	var texture:Null<Texture2D>;
	var sourceX = 0.;
	var sourceY = 0.;
	var sourceWidth = 0.;
	var sourceHeight = 0.;
	var width = 0.;
	var height = 0.;
	var pivotX = 0.;
	var pivotY = 0.;
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
		node.width = Math.max(0, width);
		node.height = Math.max(0, height);
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
		of the text and, by align, its left edge, center or right edge. Not pickable until setPickable(true): a label lets the pointer through to
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
	public function getKind():Node2DKind
		return kind;

	/** Its name, what the game gave it; "" for none. */
	public function getName():String
		return name;

	/** Names it. */
	public function setName(value:String):Void
		name = value;

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
	public function getColor():Int
		return color;

	/** Sets its color. */
	public function setColor(value:Int):Void
		color = value;

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
	public function getRegionX():Float
		return sourceX;

	/** A sprite's region's top, in texels. */
	public function getRegionY():Float
		return sourceY;

	/** A sprite's region's width in texels: what was set, or else its texture's (0 without one). */
	public function getRegionWidth():Float
		return sourceWidth > 0 && sourceHeight > 0 ? sourceWidth : texture == null ? 0 : texture.getWidth();

	/** A sprite's region's height in texels: what was set, or else its texture's (0 without one). */
	public function getRegionHeight():Float
		return sourceWidth > 0 && sourceHeight > 0 ? sourceHeight : texture == null ? 0 : texture.getHeight();

	/** The width it draws at, in its own units: a rectangle's, or a sprite's as set, else its region's in texels. */
	public function getWidth():Float
		return kind == Sprite && !(width > 0 && height > 0) ? getRegionWidth() : width;

	/** The height it draws at, in its own units: a rectangle's, or a sprite's as set, else its region's in texels. */
	public function getHeight():Float
		return kind == Sprite && !(width > 0 && height > 0) ? getRegionHeight() : height;

	/** Sizes a sprite or a rectangle, in its own units; for a sprite, a width or height of 0 or less goes back to its region's size. False for
		another kind, or a rectangle's size below 0. */
	public function setSize(width:Float, height:Float):Bool {
		if (kind != Sprite && (kind != Rectangle || !(width >= 0 && height >= 0)))
			return false;
		this.width = width;
		this.height = height;
		return true;
	}

	/** The point of a sprite or rectangle at its position, which it turns and scales about, as a fraction of its size: 0, 0 its top-left, 1, 1
		its bottom-right. */
	public function getPivotX():Float
		return pivotX;

	/** The pivot's y fraction. */
	public function getPivotY():Float
		return pivotY;

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

	/** Whether a sprite draws as a nine-slice frame. */
	public function isNineSlice():Bool
		return sliceLeft > 0 || sliceTop > 0 || sliceRight > 0 || sliceBottom > 0;

	/** A text's wrap width in its own units: 0 for one line. */
	public function getWrapWidth():Float
		return wrapWidth;

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
	public function isClipping():Bool
		return clipWidth >= 0;

	/** The clip's width in its own units, or -1 without one. */
	public function getClipWidth():Float
		return clipWidth;

	/** The clip's height in its own units, or -1 without one. */
	public function getClipHeight():Float
		return clipHeight;

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
	public function isEnabled():Bool
		return enabled;

	/** Turns it, and everything under it, on or off (isEnabled). */
	public function setEnabled(value:Bool):Void {
		// Off, it isn't brought up to date as its parent moves: on again, it is.
		if (value && !enabled)
			localDirty = true;
		enabled = value;
	}

	/** Whether its own output is drawn: off, a sprite, shape, text or emitter isn't drawn (an emitter still moves on) isn't drawn; it stays placed, and its children are as they are. On to start. */
	public function isVisible():Bool
		return visible;

	/** Shows or hides its own output (isVisible). */
	public function setVisible(value:Bool):Void
		visible = value;

	/** Whether a pick can hit its own output: off, the ray passes through it, though its children can still be hit. Drawing doesn't matter
		to it: hidden and pickable is a hit area. On to start, but for text. */
	public function isPickable():Bool
		return pickable;

	/** Lets picks hit its own output, or not (isPickable). */
	public function setPickable(value:Bool):Void
		pickable = value;

	/** Its parent, or null. */
	public function getParent():Null<Node2D>
		return parent;

	/** How many children it has. */
	public function getChildCount():Int
		return children.length;

	/** Its child at index, in drawing order; null past the end. */
	public function getChild(index:Int):Null<Node2D>
		return index >= 0 && index < children.length ? children[index] : null;

	/** Makes child its last child (drawn over the others), taking it from any parent it had. False for itself or one of its own ancestors. */
	public function add(child:Node2D):Bool {
		var at:Null<Node2D> = this;
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
	public function remove(child:Node2D):Bool {
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

	/** Places it at x, y, relative to its parent. */
	public function setPosition(x:Float, y:Float):Void {
		px = x;
		py = y;
		localDirty = true;
	}

	/** Its rotation in radians, clockwise on screen, relative to its parent. */
	public function getRotation():Float
		return angle;

	/** Turns it to radians, clockwise on screen, relative to its parent. */
	public function setRotation(radians:Float):Void {
		angle = radians;
		localDirty = true;
	}

	/** Its scale along its own x. */
	public function getScaleX():Float
		return sx;

	/** Its scale along its own y. */
	public function getScaleY():Float
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
		if (parent == null) {
			wa = la;
			wb = lb;
			wc = lc;
			wd = ld;
			wx = px;
			wy = py;
		} else {
			var p = parent;
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
