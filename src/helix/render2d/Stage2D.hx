package helix.render2d;

import helix.render2d.Node2D.Node2DKind;

/** A retained 2D scene: nodes under a root, drawn into a Batch2D by draw(batch, camera). A draw walks the tree as it is now, depth first, a
	parent before its children and children in order, so later ones draw over earlier ones (each world transform worked out only where something
	changed); it skips the nodes whose bounds are outside the camera's view, and draws the rest through the batch, which joins alike ones into
	runs. A frame composes its stages in the order it draws them: a backdrop, the world, then a HUD, each through its own camera. */
class Stage2D {
	var root = Node2D.group();
	var stack:Array<Node2D> = [];
	var stackChanged:Array<Bool> = [];

	// On the walk's stack after a clipping node's children: its clip ends there.
	static final clipEnd = Node2D.group();

	// The clipping nodes a pick is inside, outermost first.
	var pickClips:Array<Node2D> = [];
	var count = 0;
	var left = 0.;
	var top = 0.;
	var right = 0.;
	var bottom = 0.;
	var time = 0.;
	// The clock at the last draw: emitters advance by the difference.
	var drawnTime = Math.NaN;
	var dt = 0.;
	// The font a text without its own was last drawn in (the batch's), for picking it by its block.
	var lastFont:Null<Font2D>;

	/** An empty stage. */
	public function new() {}

	/** The node everything on the stage hangs from. */
	public function getRoot():Node2D
		return root;

	/** Adds node to the stage, as the root's last child: drawn over what is there. */
	public function add(node:Node2D):Bool
		return root.add(node);

	/** Takes node from the stage's root. */
	public function remove(node:Node2D):Bool
		return root.remove(node);

	/** The stage's clock, seconds: what the app last set. */
	public function getTime():Float
		return time;

	/** Sets the stage's clock; its emitters advance by how far it moved since the last draw. */
	public function setTime(seconds:Float):Void
		time = seconds;

	/** Nodes drawn by the last draw (in view). */
	public function getDrawnCount():Int
		return count;

	/** Draws the stage into batch (begun in this frame), through camera, in its viewport; the batch is left seen through camera, with no
		transform. Node world transforms are up to date after it, for toLocalX and the like. */
	public function draw(batch:Batch2D, camera:Camera2D):Void {
		batch.setCamera(camera);
		lastFont = batch.getFont();
		var x0 = camera.screenToWorldX(camera.getViewportX()),
			y0 = camera.screenToWorldY(camera.getViewportY()),
			x1 = camera.screenToWorldX(camera.getViewportX() + camera.getViewportWidth()),
			y1 = camera.screenToWorldY(camera.getViewportY() + camera.getViewportHeight());
		left = Math.min(x0, x1);
		right = Math.max(x0, x1);
		top = Math.min(y0, y1);
		bottom = Math.max(y0, y1);
		count = 0;
		dt = Math.isNaN(drawnTime) ? 0 : Math.max(0, time - drawnTime);
		drawnTime = time;
		var rootChanged = root.update(false);
		// Children are pushed last first, so they pop in order.
		stack.resize(0);
		stackChanged.resize(0);
		var i = root.children.length;
		while (i-- > 0) {
			stack.push(root.children[i]);
			stackChanged.push(rootChanged);
		}
		while (stack.length > 0) {
			var node = stack.pop(), parentChanged = stackChanged.pop();
			if (node == clipEnd) {
				batch.popClip();
				continue;
			}
			if (!node.enabled)
				continue;
			var changed = node.update(parentChanged);
			// Hidden, its own output is skipped (an emitter still moves on); it stays placed, and its children are drawn.
			if (!node.visible) {
				if (node.kind == Emitter)
					node.emitterOf.advance(dt, node.wx, node.wy, 0);
			} else if (node.kind != Group)
				drawNode(batch, node);
			if (node.clipWidth >= 0) {
				batch.setTransform(node.wa, node.wb, node.wc, node.wd, node.wx, node.wy);
				batch.pushClip(0, 0, node.clipWidth, node.clipHeight);
				stack.push(clipEnd);
				stackChanged.push(false);
			}
			var j = node.children.length;
			while (j-- > 0) {
				stack.push(node.children[j]);
				stackChanged.push(changed);
			}
		}
		batch.resetTransform();
	}

	// Draws node in its own units through its world transform, unless its bounds are out of view.
	function drawNode(batch:Batch2D, node:Node2D):Void {
		var half = node.outline / 2, x = 0., y = 0., w = 0., h = 0.;
		switch node.kind {
			case Sprite | Rectangle:
				w = node.getWidth();
				h = node.getHeight();
				x = -node.pivotX * w - half;
				y = -node.pivotY * h - half;
				w += half * 2;
				h += half * 2;
				if (node.kind == Sprite && (node.texture == null || w <= 0 || h <= 0))
					return;
			case Circle:
				x = y = -node.radius - half;
				w = h = (node.radius + half) * 2;
			case Line | Polygon:
				var p = node.points;
				var minX = p[0], minY = p[1], maxX = p[0], maxY = p[1], k = 2;
				while (k < p.length) {
					minX = Math.min(minX, p[k]);
					maxX = Math.max(maxX, p[k]);
					minY = Math.min(minY, p[k + 1]);
					maxY = Math.max(maxY, p[k + 1]);
					k += 2;
				}
				// A miter can reach twice the width past a corner.
				var reach = node.kind == Polygon ? node.outline * 2 : half;
				x = minX - reach;
				y = minY - reach;
				w = maxX - minX + reach * 2;
				h = maxY - minY + reach * 2;
			case Text:
				var font = node.font == null ? batch.getFont() : node.font;
				w = node.wrapWidth > 0 ? node.wrapWidth : Text2D.measure(font, node.content, node.textSize);
				h = node.getTextHeight(font);
				x = node.align == Center ? -w / 2 : node.align == Right ? -w : 0;
			case Emitter:
				// Not culled: particles reach past where it is.
				var e = node.emitterOf;
				e.advance(dt, node.wx, node.wy, 0);
				count++;
				batch.resetTransform();
				batch.emitter(e);
				return;
			case Group:
				return;
		}
		if (!inView(node, x, y, w, h))
			return;
		count++;
		batch.setTransform(node.wa, node.wb, node.wc, node.wd, node.wx, node.wy);
		var o = node.outline;
		switch node.kind {
			case Sprite:
				var t = node.texture, tw = t.getWidth(), th = t.getHeight();
				var sx = node.sourceWidth > 0 && node.sourceHeight > 0 ? node.sourceX : 0.,
					sy = node.sourceWidth > 0 && node.sourceHeight > 0 ? node.sourceY : 0.;
				if (node.isNineSlice())
					batch.nineSlice(t, x, y, w, h, node.sliceLeft, node.sliceTop, node.sliceRight, node.sliceBottom, node.color, sx, sy,
						node.getSourceWidth(), node.getSourceHeight());
				else {
					batch.useTexture(t);
					batch.quad(x, y, w, h, sx / tw, sy / th, (sx + node.getSourceWidth()) / tw, (sy + node.getSourceHeight()) / th, node.color);
				}
			case Rectangle:
				if (o > 0)
					batch.frame(x, y, w, h, o, node.color);
				else
					batch.rect(x, y, w, h, node.color);
			case Circle:
				if (o > 0)
					batch.circleLines(0, 0, node.radius + o / 2, o, node.color);
				else
					batch.circle(0, 0, node.radius, node.color);
			case Line:
				var p = node.points;
				batch.line(p[0], p[1], p[2], p[3], o, node.color);
			case Polygon:
				if (o > 0)
					batch.polygonLines(node.points, o, node.color);
				else
					batch.polygon(node.points, node.color, node.triangles);
			case Text:
				if (node.wrapWidth > 0)
					Text2D.drawWrapped(batch, node.content, 0, 0, node.textSize, node.wrapWidth, node.color, node.align, node.lineHeight, node.font);
				else
					Text2D.draw(batch, node.content, 0, 0, node.textSize, node.color, node.align, node.font);
			case Group | Emitter:
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
		passed over, an unpickable one is passed while its children are hit, a hidden one is hit. World transforms are brought up to date; the
		node's own point is node.toLocalX(camera.screenToWorldX(x), camera.screenToWorldY(y)). */
	public function pick(camera:Camera2D, x:Float, y:Float):Null<Node2D> {
		if (!(x >= camera.getViewportX()
			&& x < camera.getViewportX() + camera.getViewportWidth()
			&& y >= camera.getViewportY()
			&& y < camera.getViewportY() + camera.getViewportHeight()))
			return null;
		var wx = camera.screenToWorldX(x),
			wy = camera.screenToWorldY(y),
			hit:Null<Node2D> = null;
		var rootChanged = root.update(false);
		stack.resize(0);
		stackChanged.resize(0);
		var i = root.children.length;
		while (i-- > 0) {
			stack.push(root.children[i]);
			stackChanged.push(rootChanged);
		}
		pickClips.resize(0);
		while (stack.length > 0) {
			var node = stack.pop(), parentChanged = stackChanged.pop();
			if (node == clipEnd) {
				pickClips.pop();
				continue;
			}
			if (!node.enabled)
				continue;
			var changed = node.update(parentChanged);
			if (node.pickable && insideClips(wx, wy) && hits(node, node.toLocalX(wx, wy), node.toLocalY(wx, wy)))
				hit = node;
			if (node.clipWidth >= 0) {
				pickClips.push(node);
				stack.push(clipEnd);
				stackChanged.push(false);
			}
			var j = node.children.length;
			while (j-- > 0) {
				stack.push(node.children[j]);
				stackChanged.push(changed);
			}
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

	// Whether node's own point x, y is on what it draws.
	function hits(node:Node2D, x:Float, y:Float):Bool {
		var o = node.outline, half = o / 2;
		switch node.kind {
			case Sprite | Rectangle:
				if (node.kind == Sprite && node.texture == null)
					return false;
				var w = node.getWidth(),
					h = node.getHeight(),
					left = -node.pivotX * w,
					top = -node.pivotY * h;
				var outside = x < left - half || x > left + w + half || y < top - half || y > top + h + half;
				if (outside)
					return false;
				// An outlined rectangle is its frame: not inside it.
				return node.kind == Sprite || o <= 0 || x < left + half || x > left + w - half || y < top + half || y > top + h - half;
			case Circle:
				var d = Math.sqrt(x * x + y * y);
				return o > 0 ? Math.abs(d - node.radius - half) <= half : d <= node.radius;
			case Line:
				var p = node.points;
				return segment(x, y, p[0], p[1], p[2], p[3]) <= Math.max(half, .5);
			case Polygon:
				var p = node.points, n = p.length >> 1;
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
			case Text:
				var font = node.font != null ? node.font : lastFont;
				if (font == null)
					return false;
				var w = node.wrapWidth > 0 ? node.wrapWidth : Text2D.measure(font, node.content, node.textSize),
					left = node.align == Center ? -w / 2 : node.align == Right ? -w : 0;
				return x >= left && x <= left + w && y >= 0 && y <= node.getTextHeight(font);
			case Emitter | Group:
				return false;
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
