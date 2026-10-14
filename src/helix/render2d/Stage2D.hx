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
	var count = 0;
	var left = 0.;
	var top = 0.;
	var right = 0.;
	var bottom = 0.;
	var time = 0.;
	// The clock at the last draw: emitters advance by the difference.
	var drawnTime = Math.NaN;
	var dt = 0.;

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
			if (!node.enabled)
				continue;
			var changed = node.update(parentChanged);
			// Hidden, its own output is skipped (an emitter still moves on); it stays placed, and its children are drawn.
			if (!node.visible) {
				if (node.kind == Emitter)
					node.emitterOf.advance(dt, node.wx, node.wy, 0);
			} else if (node.kind != Group)
				drawNode(batch, node);
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
				w = Text2D.measure(font, node.content, node.textSize);
				h = node.textSize;
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
				batch.useTexture(t);
				batch.quad(x, y, w, h, sx / tw, sy / th, (sx + node.getSourceWidth()) / tw, (sy + node.getSourceHeight()) / th, node.color);
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
}
