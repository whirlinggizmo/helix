package helix.math;

/** Provides packing rectangles into an area, as stb_rect_pack 1.01 does (public domain, Sean Barrett), which raylib packs its font
	atlases with: a skyline, each rectangle placed as low as it goes and then as far left, the tallest first. */
class RectPacker2D {
	/** Places rectangles in an area.

		@param width  The area's width.
		@param height  The area's height.
		@param sizes  Each rectangle's width and height, flat: width, height, width, height.
		@return  Each rectangle's place, flat, in the same order: x, y, and 1 when it was placed or 0 when it didn't fit. A rectangle with
			no width or height is placed at 0, 0. */
	public static function pack(width:Int, height:Int, sizes:Array<Int>):Array<Int> {
		var count = sizes.length >> 1;
		var nodes = [for (_ in 0...count) new Node(0, 0)];
		for (i in 0...count - 1)
			nodes[i].next = nodes[i + 1];
		var free = count > 0 ? nodes[0] : null;
		var active = new Node(0, 0);
		active.next = new Node(width, 1 << 30);
		// stb_rect_pack rounds widths up to a step that keeps a node for each rectangle enough.
		var align = count > 0 ? Std.int((width + count - 1) / count) : 1;
		// Tallest first, then widest; ties keep their order.
		var order = [for (i in 0...count) i];
		order.sort((a, b) -> {
			var taller = sizes[b * 2 + 1] - sizes[a * 2 + 1],
				wider = sizes[b * 2] - sizes[a * 2];
			return taller != 0 ? taller : wider != 0 ? wider : a - b;
		});
		var places = [for (_ in 0...count * 3) 0];
		for (i in order) {
			var w = sizes[i * 2], h = sizes[i * 2 + 1];
			places[i * 3 + 2] = 1;
			if (w == 0 || h == 0)
				continue;
			// The lowest place along the skyline, the leftmost of those.
			var aligned = w + align - 1;
			aligned -= aligned % align;
			var bestY = 1 << 30,
				best:Null<Node> = null,
				bestPrev:Null<Node> = null;
			if (aligned <= width && h <= height) {
				var prev:Null<Node> = null, node = active;
				while (node.x + aligned <= width) {
					var y = highest(node, node.x + aligned);
					if (y < bestY) {
						bestY = y;
						best = node;
						bestPrev = prev;
					}
					prev = node;
					node = node.next;
				}
			}
			if (best == null || bestY + h > height || free == null) {
				places[i * 3 + 2] = 0;
				continue;
			}
			var x = best.x;
			// The skyline rises over the new rectangle: a node at its top, and the nodes it covers freed.
			var added = free;
			free = added.next;
			added.x = x;
			added.y = bestY + h;
			if (bestPrev == null)
				active = added;
			else
				bestPrev.next = added;
			var cur = best;
			while (cur.next != null && cur.next.x <= x + aligned) {
				var next = cur.next;
				cur.next = free;
				free = cur;
				cur = next;
			}
			added.next = cur;
			if (cur.x < x + aligned)
				cur.x = x + aligned;
			places[i * 3] = x;
			places[i * 3 + 1] = bestY;
		}
		return places;
	}

	// The skyline's highest point from a node to an x.
	static function highest(first:Node, end:Int):Int {
		var node = first, y = 0;
		while (node.x < end) {
			if (node.y > y)
				y = node.y;
			node = node.next;
		}
		return y;
	}
}

/** Represents a step of the skyline: from its x to the next node's, at its height. */
private class Node {
	/** Gets or sets where the step starts. */
	public var x:Int;

	/** Gets or sets the skyline's height there. */
	public var y:Int;

	/** Gets or sets the next step, or the next free node. */
	public var next:Null<Node> = null;

	/** Creates a step.

		@param x  Where it starts.
		@param y  Its height. */
	public function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}
}
