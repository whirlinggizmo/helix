package helix.ray.internal;

/** Packs rectangles into an area as raylib's font atlas does with stb_rect_pack 1.01 (public domain, Sean Barrett): its skyline with
	the bottom-left heuristic, tallest first, a node for each rectangle. */
@:noCompletion
class RectPack {
	/** Places rectangles.

		@param width  The area's width.
		@param height  The area's height.
		@param sizes  Each rectangle's width and height.
		@return  Each rectangle's x, y, and 1 when it was placed or 0 when it didn't fit; an empty one is placed at 0, 0. */
	public static function pack(width:Int, height:Int, sizes:Array<Array<Int>>):Array<Array<Int>> {
		var count = sizes.length;
		var nodes = [for (_ in 0...count) new Node(0, 0)];
		for (i in 0...count - 1)
			nodes[i].next = nodes[i + 1];
		var free = count > 0 ? nodes[0] : null;
		var end = new Node(width, 1 << 30);
		var active = new Node(0, 0);
		active.next = end;
		var align = count > 0 ? Std.int((width + count - 1) / count) : 1;
		// Tallest first, then widest; ties keep their order.
		var order = [for (i in 0...count) i];
		order.sort((a, b) -> sizes[a][1] != sizes[b][1] ? sizes[b][1] - sizes[a][1] : sizes[a][0] != sizes[b][0] ? sizes[b][0] - sizes[a][0] : a - b);
		var places = [for (_ in 0...count) [0, 0, 1]];
		for (i in order) {
			var w = sizes[i][0], h = sizes[i][1];
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
					var y = lowest(node, node.x, aligned);
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
				places[i] = [0, 0, 0];
				continue;
			}
			var x = best.x;
			// The skyline rises over the new rectangle: a node at its top, those it covers freed.
			var added = free;
			free = added.next;
			added.x = x;
			added.y = bestY + h;
			var cur = best;
			if (cur.x < x) {
				var next = cur.next;
				cur.next = added;
				cur = next;
			} else if (bestPrev == null)
				active = added;
			else
				bestPrev.next = added;
			while (cur.next != null && cur.next.x <= x + aligned) {
				var next = cur.next;
				cur.next = free;
				free = cur;
				cur = next;
			}
			added.next = cur;
			if (cur.x < x + aligned)
				cur.x = x + aligned;
			places[i] = [x, bestY, 1];
		}
		return places;
	}

	// The skyline's highest point under x0 to x0 + width, from the node the span starts on.
	static function lowest(first:Node, x0:Int, width:Int):Int {
		var node = first, x1 = x0 + width, y = 0;
		while (node.x < x1) {
			if (node.y > y)
				y = node.y;
			node = node.next;
		}
		return y;
	}
}

private class Node {
	public var x:Int;
	public var y:Int;
	public var next:Null<Node> = null;

	public function new(x:Int, y:Int) {
		this.x = x;
		this.y = y;
	}
}
