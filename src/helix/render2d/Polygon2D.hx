package helix.render2d;

/** Simple polygons as points, x and y in turn: filled by triangulating them (convex or not), outlined by mitered strips. */
class Polygon2D {
	/** Twice the signed area of the polygon through points: above 0 when its points go clockwise on screen (y down). */
	public static function doubleArea(points:Array<Float>):Float {
		var n = points.length >> 1, area = 0.;
		for (i in 0...n) {
			var j = (i + 1) % n;
			area += points[i * 2] * points[j * 2 + 1] - points[j * 2] * points[i * 2 + 1];
		}
		return area;
	}

	/** The triangles filling the simple polygon through points (at least 3, not crossing itself), as indices of points, three a triangle, by ear
		clipping; either winding. A polygon that crosses itself is filled as far as clipping gets. */
	public static function triangulate(points:Array<Float>):Array<Int> {
		var n = points.length >> 1, out = [];
		if (n < 3)
			return out;
		var left = [for (i in 0...n) i], clockwise = doubleArea(points) > 0;
		// Twice the area of a, b, c, positive when they turn the polygon's way.
		inline function turn(a:Int, b:Int, c:Int):Float {
			var v = (points[b * 2]
				- points[a * 2]) * (points[c * 2 + 1] - points[a * 2 + 1])
				- (points[b * 2 + 1] - points[a * 2 + 1]) * (points[c * 2] - points[a * 2]);
			return clockwise ? v : -v;
		}
		function inside(p:Int, a:Int, b:Int, c:Int):Bool
			return turn(a, b, p) >= 0 && turn(b, c, p) >= 0 && turn(c, a, p) >= 0;
		var misses = 0, i = 0;
		while (left.length > 3 && misses < left.length) {
			var m = left.length,
				a = left[(i + m - 1) % m],
				b = left[i % m],
				c = left[(i + 1) % m];
			var ear = turn(a, b, c) > 0;
			if (ear)
				for (p in left)
					if (p != a && p != b && p != c && inside(p, a, b, c)) {
						ear = false;
						break;
					}
			if (ear) {
				out.push(a);
				out.push(b);
				out.push(c);
				left.splice(i % m, 1);
				misses = 0;
			} else {
				i++;
				misses++;
			}
			i %= left.length;
		}
		if (left.length == 3) {
			out.push(left[0]);
			out.push(left[1]);
			out.push(left[2]);
		}
		return out;
	}
}
