package helix.render2d;

import helix.render2d.Shape2D.ShapeShading2D;
import helix.font.Font;

/** What draws and picks a tree of 2D nodes (docs/DISPLAY_MODEL.md): the stage's (StageService) and each View2D's, never a game's, which puts
	nodes on the stage or in a view. A draw walks the tree under root as it is now, depth first, a parent before its children and children
	in order, so later ones draw over earlier ones (each world transform worked out only where something changed); it skips the nodes whose
	bounds are outside the camera's view, and draws the rest through the batch, which joins alike ones into runs. */
class Renderer2D {
	// The tree in drawing order (depth first, the root's children down), each node's parent's place in it (-1 for the root's children) and the
	// place just past its last descendant, remade when the root's count of adds and removes moves; beside each, the node as its kind (null
	// for another), its class asked once here, not each walk. Every walk then goes down the order.
	var builtStructure = -1;
	var order:Array<Node2D> = [];
	var parentOf:Array<Int> = [];
	var endOf:Array<Int> = [];
	var moved:Array<Bool> = [];
	var sprites:Array<Null<Sprite2D>> = [];
	var shapes:Array<Null<Shape2D>> = [];
	var texts:Array<Null<Text2D>> = [];
	// Whether each node in the order is paused, itself or by a node above it: its emitters held still.
	var frozen:Array<Bool> = [];
	// Each node's alpha times its parent's, from the batch's alpha as the draw began (a view's, nested).
	var alphas:Array<Float> = [];
	// The camera the walk draws through, which a view it reaches shows its tree inside.
	var walkCamera:Null<Camera2D>;
	// The places where the clips a walk is inside end, innermost last; and for a pick, the clipping nodes, outermost first.
	var clipEnds:Array<Int> = [];
	var pickClips:Array<Node2D> = [];
	var count = 0;
	var left = 0.;
	var top = 0.;
	var right = 0.;
	var bottom = 0.;
	// The clock at the last draw: emitters advance by the difference.
	var drawnTime = Math.NaN;
	var dt = 0.;
	// The font a text without its own was last drawn in (the batch's), for picking it by its block.
	var lastFont:Null<Font>;

	/** An empty stage, or one drawing root's children (a View2D's tree). */
	public function new(?root:Node2D) {
		this.root = root == null ? new Node2D() : root;
	}

	/** The node everything on the stage hangs from. */
	public var root(default, null):Node2D;

	/** Adds node to the stage, as the root's last child: drawn over what is there. */
	public function add(node:Node2D):Bool
		return root.addChild(node);

	/** Takes node from the stage's root. */
	public function remove(node:Node2D):Bool
		return root.removeChild(node);

	/** The stage's clock, seconds: what the app last set. Its emitters advance by how far it moved since the last draw. */
	public var time:Float = 0.;

	/** The font a text without its own was last drawn in (the batch's), or null before a draw. */
	public var font(get, never):Null<Font>;

	function get_font():Null<Font>
		return lastFont;

	/** Nodes drawn by the last draw (in view). */
	public var drawnNodeCount(get, never):Int;

	function get_drawnNodeCount():Int
		return count;

	/** Draws the stage into batch (begun in this frame), through camera, in its viewport, its sprites through their effects at the stage's time
		(batch.time is set to it); the batch is left seen through camera, with no transform and no effect. Node world transforms are up to date
		after it, for toLocalX and the like. */
	public function draw(batch:Batch2D, camera:Camera2D):Void {
		batch.camera = camera;
		batch.time = time;
		walkCamera = camera;
		lastFont = batch.font;
		var x0 = camera.screenToWorldX(camera.viewportX),
			y0 = camera.screenToWorldY(camera.viewportY),
			x1 = camera.screenToWorldX(camera.viewportX + camera.viewportWidth),
			y1 = camera.screenToWorldY(camera.viewportY + camera.viewportHeight);
		left = Math.min(x0, x1);
		right = Math.max(x0, x1);
		top = Math.min(y0, y1);
		bottom = Math.max(y0, y1);
		count = 0;
		dt = Math.isNaN(drawnTime) ? 0 : Math.max(0, time - drawnTime);
		drawnTime = time;
		var rootChanged = walkStart();
		var incoming = batch.alpha, base = incoming * root.alpha;
		var n = order.length, i = 0;
		while (i < n) {
			while (clipEnds.length > 0 && clipEnds[clipEnds.length - 1] <= i) {
				clipEnds.pop();
				batch.popClip();
			}
			var node = order[i], p = parentOf[i];
			if (!node.enabled) {
				i = endOf[i];
				continue;
			}
			moved[i] = node.updateWorld(p < 0 ? rootChanged : moved[p]);
			frozen[i] = node.paused || (p >= 0 ? frozen[p] : root.paused);
			alphas[i] = node.alpha * (p >= 0 ? alphas[p] : base);
			batch.alpha = alphas[i];
			// Hidden, its own output is skipped (an emitter still moves on); it stays placed, and its children are drawn.
			if (node.visible)
				drawNode(batch, i);
			else
				node.drawOwn(batch, walkCamera, time, dt, frozen[i], false);
			if (node.clipWidth >= 0) {
				batch.setTransform(node.wa, node.wb, node.wc, node.wd, node.wx, node.wy);
				batch.pushClip(0, 0, node.clipWidth, node.clipHeight);
				clipEnds.push(endOf[i]);
			}
			i++;
		}
		while (clipEnds.length > 0) {
			clipEnds.pop();
			batch.popClip();
		}
		batch.effect = null;
		batch.alpha = incoming;
		batch.resetTransform();
	}

	// Before a walk: the order remade if the tree's shape changed, and the root brought up to date; whether it moved.
	function walkStart():Bool {
		if (builtStructure != root.structure)
			rebuild();
		moved.resize(order.length);
		frozen.resize(order.length);
		alphas.resize(order.length);
		clipEnds.resize(0);
		return root.updateWorld(false);
	}

	// The tree in drawing order and each node as its kind, again: after an add or a remove anywhere under the root.
	function rebuild():Void {
		order.resize(0);
		parentOf.resize(0);
		endOf.resize(0);
		sprites.resize(0);
		shapes.resize(0);
		texts.resize(0);
		for (i in 0...root.childCount)
			list(root.getChild(i), -1);
		builtStructure = root.structure;
	}

	// node and what's under it into the order, after its parent at parent.
	function list(node:Node2D, parent:Int):Void {
		var at = order.length;
		order.push(node);
		parentOf.push(parent);
		endOf.push(0);
		sprites.push(Std.downcast(node, Sprite2D));
		shapes.push(Std.downcast(node, Shape2D));
		texts.push(Std.downcast(node, Text2D));
		for (i in 0...node.childCount)
			list(node.getChild(i), at);
		endOf[at] = order.length;
	}

	// What a node measures into as it's drawn (Node2D.measureOwn).
	var box = new helix.math.Bounds2D();

	// Draws the node at place i in its own units through its world transform, unless its bounds are out of view.
	function drawNode(batch:Batch2D, i:Int):Void {
		var node = order[i],
			sprite = sprites[i],
			shape = shapes[i],
			text = texts[i];
		if (sprite == null && shape == null && text == null) {
			// A kind that draws itself (an emitter, a drawing, a view), not culled; a group draws nothing.
			batch.effect = null;
			if (node.drawOwn(batch, walkCamera, time, dt, frozen[i], true))
				count++;
			return;
		}
		// Its own box, as computeBounds measures it (Node2D.measureOwn): nothing to draw (a sprite without a texture) or out of view, skipped.
		if (!node.measureOwn(batch.font, box))
			return;
		var x = box.minX, y = box.minY, w = box.maxX - box.minX, h = box.maxY - box.minY;
		if (!inView(node, x, y, w, h))
			return;
		count++;
		batch.effect = sprite != null ? sprite.effect : null;
		batch.setTransform(node.wa, node.wb, node.wc, node.wd, node.wx, node.wy);
		if (sprite != null) {
			var t = sprite.texture, tw = t.width, th = t.height;
			batch.samplingOverride = sprite.sampling;
			var sx = sprite.drawnRegionX(), sy = sprite.drawnRegionY();
			if (sprite.frame != null)
				batch.frameQuad(t, sprite.frame, x, y, w, h, sprite.tint);
			else if (sprite.nineSlice)
				batch.nineSlice(t, x, y, w, h, sprite.sliceLeft, sprite.sliceTop, sprite.sliceRight, sprite.sliceBottom, sprite.tint, sx, sy,
					sprite.regionWidth, sprite.regionHeight);
			else {
				batch.useTexture(t);
				batch.quad(x, y, w, h, sx / tw, sy / th, (sx + sprite.regionWidth) / tw, (sy + sprite.regionHeight) / th, sprite.tint);
			}
			batch.samplingOverride = null;
		} else if (shape != null) {
			var o = shape.outlineWidth;
			switch shape.form {
				case Rectangle:
					// Outlined, the corners' arcs are the outline's middle: their radius half the outline more outside.
					var r = Math.min(shape.corners, Math.min(shape.givenWidth, shape.givenHeight) / 2);
					if (o > 0)
						batch.roundedFrame(x, y, w, h, r > 0 ? r + o / 2 : 0, o, shape.color);
					else if (shape.shading != Flat)
						batch.gradientRect(x, y, w, h, r, shape.color, shape.endColor, shape.shading == Down);
					else
						batch.roundedRect(x, y, w, h, r, shape.color);
				case Circle:
					if (o > 0)
						batch.circleLines(0, 0, shape.circleRadius + o / 2, o, shape.color);
					else
						batch.circle(0, 0, shape.circleRadius, shape.color);
				case Line:
					var p = shape.pointList;
					if (o > 0)
						batch.line(p[0], p[1], p[2], p[3], o, shape.color);
				case Polygon:
					if (o > 0)
						batch.polygonLines(shape.pointList, o, shape.color);
					else
						batch.polygon(shape.pointList, shape.color, shape.triangles);
			}
		} else if (text != null) {
			if (text.wrapWidth > 0)
				batch.drawTextWrapped(text.text, 0, 0, text.textSize, text.wrapWidth, text.color, text.align, text.lineHeight, text.font);
			else
				batch.drawText(text.text, 0, 0, text.textSize, text.color, text.align, text.font);
		}
	}

	// Whether the box x, y, w, h of node's own units, placed by its world transform, reaches into the camera's view.
	function inView(node:Node2D, x:Float, y:Float, w:Float, h:Float):Bool {
		// The box's center and half extents, carried to the world: the extents by the transform's absolute values.
		var cx = x + w / 2, cy = y + h / 2, hw = w / 2, hh = h / 2;
		var wx = node.wa * cx + node.wc * cy + node.wx,
			wy = node.wb * cx + node.wd * cy + node.wy,
			ex = Math.abs(node.wa) * hw + Math.abs(node.wc) * hh,
			ey = Math.abs(node.wb) * hw + Math.abs(node.wd) * hh;
		return wx + ex >= left && wx - ex <= right && wy + ey >= top && wy - ey <= bottom;
	}

	/** The topmost (last drawn) node under framebuffer pixel x, y (from the top-left, as the pointer is) seen through camera, or null for none
		(or a point outside camera's viewport). Each kind is hit by its own area as drawn: a sprite or filled rectangle its rectangle, a filled
		circle its disc, a filled polygon its inside (even-odd), an outlined shape or a line its stroke, a text its block (a text without a font of
		its own once a draw has given one). Emitters and groups aren't hit. The flags hold as in a draw: a disabled node and all under it are
		passed over, as is a paused one (Node.paused), an unpickable one is passed while its children are hit, a hidden one is hit; a
		View2D picks inside the tree it shows, where it was last drawn, and a View3D is noted for the stage to try after the 2D. World transforms are brought up to date; the
		node's own point is node.toLocalX(camera.screenToWorldX(x), camera.screenToWorldY(y)). */
	public function pick(camera:Camera2D, x:Float, y:Float):Null<Node2D> {
		if (root.paused
			|| !(x >= camera.viewportX
				&& x < camera.viewportX + camera.viewportWidth
				&& y >= camera.viewportY
				&& y < camera.viewportY + camera.viewportHeight))
			return null;
		var wx = camera.screenToWorldX(x),
			wy = camera.screenToWorldY(y),
			hit:Null<Node2D> = null;
		var rootChanged = walkStart();
		pickClips.resize(0);
		var n = order.length, i = 0;
		while (i < n) {
			while (clipEnds.length > 0 && clipEnds[clipEnds.length - 1] <= i) {
				clipEnds.pop();
				pickClips.pop();
			}
			var node = order[i], p = parentOf[i];
			if (!node.enabled) {
				i = endOf[i];
				continue;
			}
			moved[i] = node.updateWorld(p < 0 ? rootChanged : moved[p]);
			if (node.paused) {
				// Paused: nothing under it is picked (a level frozen under a menu).
				i = endOf[i];
				continue;
			}
			if (node.picksOwn) {
				if (insideClips(wx, wy)) {
					var inside = node.pickOwn(x, y, node.toLocalX(wx, wy), node.toLocalY(wx, wy), lastFont);
					if (inside != null)
						hit = inside;
				}
			} else if (node.pickable && insideClips(wx, wy) && hits(i, node.toLocalX(wx, wy), node.toLocalY(wx, wy)))
				hit = node;
			if (node.clipWidth >= 0) {
				pickClips.push(node);
				clipEnds.push(endOf[i]);
			}
			i++;
		}
		return hit;
	}

	// Whether world point x, y is inside every clip the walk is in (a node scrolled out of a list's window isn't picked).
	function insideClips(x:Float, y:Float):Bool {
		for (c in pickClips) {
			var lx = c.toLocalX(x, y), ly = c.toLocalY(x, y);
			if (!(lx >= 0 && lx <= c.clipWidth && ly >= 0 && ly <= c.clipHeight))
				return false;
		}
		return true;
	}

	// Whether x, y is inside the rectangle left, top, w x h with corners of radius: within the rectangle, and within radius of the nearest
	// point of it radius in from its edges.
	static function insideRounded(x:Float, y:Float, left:Float, top:Float, w:Float, h:Float, radius:Float):Bool {
		if (x < left || x > left + w || y < top || y > top + h)
			return false;
		var cx = Math.max(left + radius, Math.min(x, left + w - radius)),
			cy = Math.max(top + radius, Math.min(y, top + h - radius));
		return (x - cx) * (x - cx) + (y - cy) * (y - cy) <= radius * radius;
	}

	// Whether the own point x, y of the node at place i is on what it draws.
	function hits(i:Int, x:Float, y:Float):Bool {
		var sprite = sprites[i], shape = shapes[i], text = texts[i];
		if (sprite != null) {
			if (sprite.texture == null)
				return false;
			var w = sprite.width, h = sprite.height;
			return insideRounded(x, y, -sprite.pivotX * w, -sprite.pivotY * h, w, h, 0);
		}
		if (text != null) {
			var font = text.font != null ? text.font : lastFont;
			if (font == null)
				return false;
			var w = text.measureWidth(font),
				left = text.align == Center ? -w / 2 : text.align == Right ? -w : 0;
			return x >= left && x <= left + w && y >= 0 && y <= text.measureHeight(font);
		}
		if (shape == null)
			return false;
		var o = shape.outlineWidth, half = o / 2;
		switch shape.form {
			case Rectangle:
				var w = shape.givenWidth,
					h = shape.givenHeight,
					left = -shape.pivotX * w,
					top = -shape.pivotY * h,
					r = Math.min(shape.corners, Math.min(w, h) / 2);
				if (!insideRounded(x, y, left - half, top - half, w + o, h + o, r > 0 ? r + half : 0))
					return false;
				// An outlined rectangle is its frame: not inside it.
				return o <= 0 || !insideRounded(x, y, left + half, top + half, w - o, h - o, Math.max(0, r - half));
			case Circle:
				var d = Math.sqrt(x * x + y * y);
				return o > 0 ? Math.abs(d - shape.circleRadius - half) <= half : d <= shape.circleRadius;
			case Line:
				var p = shape.pointList;
				return segment(x, y, p[0], p[1], p[2], p[3]) <= Math.max(half, .5);
			case Polygon:
				var p = shape.pointList, n = p.length >> 1;
				if (o > 0) {
					for (k in 0...n)
						if (segment(x, y, p[k * 2], p[k * 2 + 1], p[((k + 1) % n) * 2], p[((k + 1) % n) * 2 + 1]) <= half)
							return true;
					return false;
				}
				// Even-odd: crossings of a ray to the right.
				var inside = false, j = n - 1;
				for (k in 0...n) {
					var ax = p[k * 2], ay = p[k * 2 + 1], bx = p[j * 2], by = p[j * 2 + 1];
					if ((ay > y) != (by > y) && x < (bx - ax) * (y - ay) / (by - ay) + ax)
						inside = !inside;
					j = k;
				}
				return inside;
		}
	}

	// How far x, y is from the segment a to b.
	static function segment(x:Float, y:Float, ax:Float, ay:Float, bx:Float, by:Float):Float {
		var dx = bx - ax, dy = by - ay, l = dx * dx + dy * dy;
		var t = l > 0 ? Math.max(0, Math.min(1, ((x - ax) * dx + (y - ay) * dy) / l)) : 0;
		var px = ax + dx * t - x, py = ay + dy * t - y;
		return Math.sqrt(px * px + py * py);
	}
}
