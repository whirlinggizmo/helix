package helix.debug;

import helix.math.Bounds2D;
import helix.render2d.Batch2D;
import helix.render2d.Camera2D;
import helix.render2d.Drawing2D;
import helix.render2d.HitArea2D;
import helix.render2d.Node2D;
import helix.render2d.Renderer2D;
import helix.render2d.Stage;

/** What picks test and what drawing culls by, drawn over a 2D tree for finding why a click misses: add it to the tree to look at (on the
	stage, or in the tree a View2D shows) last, so it's over the rest, at its origin, unturned and unscaled. Each frame it draws every shown
	node's own box, square to the tree, as computeBounds measures it and drawing culls by it (boundsColor), and for each node a pick can hit,
	what the pick tests (hitColor): its hitArea, or its kind's own shape (a sprite's or text's rectangle, a circle's disc or ring, a line's or
	outline's stroke, a polygon's inside, a drawing's extent and texts). Nothing is drawn for what a pick doesn't test (a group without a hit
	area, an emitter; a view picks inside the tree it shows, which an overlay of its own shows). The flags hold as for a pick: a hidden node
	and everything under it are left out, an unpickable one's gets no pick shape. A clipping node's clip, which also limits a pick, isn't
	drawn. Never picked. */
@:access(helix.render2d.Node2D)
@:access(helix.render2d.HitArea2D)
class PickOverlay2D extends Drawing2D {
	var refreshedAt = Math.NaN;
	var box = new Bounds2D();
	var outlines:Array<Array<Float>> = [];

	/** An overlay drawing hit shapes in hitColor (green unless given) and boxes in boundsColor (orange unless given), lineWidth wide (1 unless
		given), in the tree's units. */
	public function new(hitColor = 0xff33ff66, boundsColor = 0xffffa020, lineWidth = 1.) {
		super();
		this.hitColor = hitColor;
		this.boundsColor = boundsColor;
		this.lineWidth = lineWidth;
		pickable = false;
	}

	/** Whether it draws what a pick tests on each node it can hit. On to start. */
	public var pickShapes = true;

	/** Whether it draws each shown node's own box, square to the tree (an AABB: what drawing culls by). On to start. */
	public var drawBounds = true;

	/** The color of what each node is hit by, 0xAARRGGBB. */
	public var hitColor:Int;

	/** The color of each node's box, 0xAARRGGBB. */
	public var boundsColor:Int;

	/** How wide its lines are, in the tree's units. */
	public var lineWidth:Float;

	// Each frame as it's drawn: the tree it's in looked at again.
	override function drawOwn(batch:Batch2D, camera:Camera2D, time:Float, dt:Float, frozen:Bool, shown:Bool):Bool {
		if (refreshedAt != time) {
			refreshedAt = time;
			refresh();
		}
		return super.drawOwn(batch, camera, time, dt, frozen, shown);
	}

	// Draws the tree from its root: the topmost node above this one.
	function refresh():Void {
		clear();
		var root:Node2D = this;
		while (root.parent != null)
			root = root.parent;
		visit(root, true, Stage.instance != null ? Stage.font : null);
	}

	function visit(node:Node2D, hittable:Bool, font:Null<helix.font.Font>):Void {
		if (node == this || !node.visible)
			return;
		hittable = hittable && node.pickable;
		var shaped = pickShapes && hittable;
		box.clear();
		if (node.measureOwn(font, box)) {
			// Its box square to the tree: the corners of its own placed, and the box around them.
			var x0 = Math.POSITIVE_INFINITY,
				y0 = Math.POSITIVE_INFINITY,
				x1 = Math.NEGATIVE_INFINITY,
				y1 = Math.NEGATIVE_INFINITY;
			for (corner in 0...4) {
				var lx = corner & 1 == 0 ? box.minX : box.maxX,
					ly = corner < 2 ? box.minY : box.maxY;
				var x = placeX(node, lx, ly), y = placeY(node, lx, ly);
				x0 = Math.min(x0, x);
				y0 = Math.min(y0, y);
				x1 = Math.max(x1, x);
				y1 = Math.max(y1, y);
			}
			if (drawBounds)
				frame(x0, y0, x1 - x0, y1 - y0, lineWidth, boundsColor);
		}
		var area = node.hitArea;
		if (shaped && area == null) {
			// What a pick tests by its kind, as the renderer's pick has it.
			Renderer2D.pickOutlines(node, font, outlines);
			for (local in outlines)
				polygonLines([
					for (k in 0...local.length)
						k % 2 == 0 ? placeX(node, local[k], local[k + 1]) : placeY(node, local[k - 1], local[k])
				], lineWidth, hitColor);
		} else if (shaped) {
			if (area.round) {
				var points = [];
				for (k in 0...32) {
					var angle = k / 32 * Math.PI * 2,
						lx = area.x + Math.cos(angle) * area.width,
						ly = area.y + Math.sin(angle) * area.width;
					points.push(placeX(node, lx, ly));
					points.push(placeY(node, lx, ly));
				}
				polygonLines(points, lineWidth, hitColor);
			} else
				outline(node, area.x, area.y, area.width, area.height);
		}
		for (i in 0...node.childCount)
			visit(node.getChild(i), hittable, font);
	}

	// node's own rectangle x, y, w x h placed in the tree, outlined in hitColor.
	function outline(node:Node2D, x:Float, y:Float, w:Float, h:Float):Void
		polygonLines([
			placeX(node, x, y),
			placeY(node, x, y),
			placeX(node, x + w, y),
			placeY(node, x + w, y),
			placeX(node, x + w, y + h),
			placeY(node, x + w, y + h),
			placeX(node, x, y + h),
			placeY(node, x, y + h)
		], lineWidth, hitColor);

	// node's own point x, y in the tree's units, by its world transform.
	static inline function placeX(node:Node2D, x:Float, y:Float):Float
		return node.wa * x + node.wc * y + node.wx;

	static inline function placeY(node:Node2D, x:Float, y:Float):Float
		return node.wb * x + node.wd * y + node.wy;
}
