package helix.collision;

/** 2D collision tests in floats, the same on every target (sums, products and square roots round alike everywhere; nothing transcendental):
	overlaps of rectangles (x, y the top-left, width and height), circles and convex polygons (points as flat x, y pairs, in either winding);
	points inside them; segments and rays against them, with where and the normal (Hit2D); sweeps, a shape moved by dx, dy until it meets
	another; and a box moved and slid over a grid of solid tiles (Move2D). Touching edges don't overlap. Polygon tests are the separating axis
	theorem, so a concave polygon is split into convex ones first. A SpatialHash2D narrows which pairs to test. */
class Collide2D {
	/** Whether two rectangles overlap. */
	public static function rectRect(ax:Float, ay:Float, aw:Float, ah:Float, bx:Float, by:Float, bw:Float, bh:Float):Bool
		return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;

	/** Whether two circles overlap. */
	public static function circleCircle(ax:Float, ay:Float, ar:Float, bx:Float, by:Float, br:Float):Bool {
		var dx = bx - ax, dy = by - ay, r = ar + br;
		return dx * dx + dy * dy < r * r;
	}

	/** Whether a rectangle and a circle overlap. */
	public static function rectCircle(rx:Float, ry:Float, rw:Float, rh:Float, cx:Float, cy:Float, r:Float):Bool {
		var nx = cx < rx ? rx : cx > rx + rw ? rx + rw : cx,
			ny = cy < ry ? ry : cy > ry + rh ? ry + rh : cy;
		var dx = cx - nx, dy = cy - ny;
		return dx * dx + dy * dy < r * r;
	}

	/** Whether the point is inside the rectangle (on its left or top edge counts, its right or bottom doesn't). */
	public static function pointInRect(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool
		return px >= rx && px < rx + rw && py >= ry && py < ry + rh;

	/** Whether the point is inside the circle. */
	public static function pointInCircle(px:Float, py:Float, cx:Float, cy:Float, r:Float):Bool {
		var dx = px - cx, dy = py - cy;
		return dx * dx + dy * dy < r * r;
	}

	/** Whether the point is inside the polygon (convex or not, by crossings). */
	public static function pointInPolygon(px:Float, py:Float, points:Array<Float>):Bool {
		var n = points.length >> 1, inside = false, j = n - 1;
		for (i in 0...n) {
			var xi = points[i * 2],
				yi = points[i * 2 + 1],
				xj = points[j * 2],
				yj = points[j * 2 + 1];
			if ((yi > py) != (yj > py) && px < (xj - xi) * (py - yi) / (yj - yi) + xi)
				inside = !inside;
			j = i;
		}
		return inside;
	}

	/** Whether two convex polygons overlap (the separating axis theorem). With hit, its normal is the way to move a out of b by its depth, the
		least such move. */
	public static function polygonPolygon(a:Array<Float>, b:Array<Float>, ?hit:Hit2D):Bool {
		var least = Math.POSITIVE_INFINITY, nx = 0., ny = 0.;
		for (pass in 0...2) {
			var edges = pass == 0 ? a : b, n = edges.length >> 1;
			for (i in 0...n) {
				var j = (i + 1) % n;
				// The edge's normal, as an axis; both polygons projected onto it.
				var ex = edges[j * 2] - edges[i * 2],
					ey = edges[j * 2 + 1] - edges[i * 2 + 1];
				var len = Math.sqrt(ex * ex + ey * ey);
				if (len == 0)
					continue;
				var ax = -ey / len, ay = ex / len;
				var aMin = Math.POSITIVE_INFINITY,
					aMax = Math.NEGATIVE_INFINITY,
					bMin = Math.POSITIVE_INFINITY,
					bMax = Math.NEGATIVE_INFINITY;
				var k = 0;
				while (k < a.length) {
					var p = a[k] * ax + a[k + 1] * ay;
					if (p < aMin)
						aMin = p;
					if (p > aMax)
						aMax = p;
					k += 2;
				}
				k = 0;
				while (k < b.length) {
					var p = b[k] * ax + b[k + 1] * ay;
					if (p < bMin)
						bMin = p;
					if (p > bMax)
						bMax = p;
					k += 2;
				}
				if (aMax <= bMin || bMax <= aMin)
					return false;
				var overlap = Math.min(aMax - bMin, bMax - aMin);
				if (overlap < least) {
					least = overlap;
					// Out of b: away from b's middle along the axis.
					var aMid = (aMin + aMax) / 2, bMid = (bMin + bMax) / 2;
					var sign = aMid < bMid ? -1 : 1;
					nx = ax * sign;
					ny = ay * sign;
				}
			}
		}
		if (hit != null) {
			hit.reset();
			hit.normalX = nx;
			hit.normalY = ny;
			hit.depth = least;
		}
		return true;
	}

	/** Whether a convex polygon and a circle overlap. */
	public static function polygonCircle(points:Array<Float>, cx:Float, cy:Float, r:Float):Bool {
		if (pointInPolygon(cx, cy, points))
			return true;
		var n = points.length >> 1;
		for (i in 0...n) {
			var j = (i + 1) % n;
			if (segmentDistanceSquared(points[i * 2], points[i * 2 + 1], points[j * 2], points[j * 2 + 1], cx, cy) < r * r)
				return true;
		}
		return false;
	}

	/** Whether a rectangle and a convex polygon overlap. */
	public static function rectPolygon(rx:Float, ry:Float, rw:Float, rh:Float, points:Array<Float>, ?hit:Hit2D):Bool
		return polygonPolygon([rx, ry, rx + rw, ry, rx + rw, ry + rh, rx, ry + rh], points, hit);

	/** The square of the distance from a point to a segment. */
	public static function segmentDistanceSquared(ax:Float, ay:Float, bx:Float, by:Float, px:Float, py:Float):Float {
		var dx = bx - ax, dy = by - ay, len = dx * dx + dy * dy;
		var t = len == 0 ? 0 : ((px - ax) * dx + (py - ay) * dy) / len;
		t = t < 0 ? 0 : t > 1 ? 1 : t;
		var qx = ax + dx * t - px, qy = ay + dy * t - py;
		return qx * qx + qy * qy;
	}

	/** Whether segment a to b crosses segment c to d (not when they only touch or lie along each other); with hit, where along a to b (time)
		and the point. */
	public static function segmentSegment(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, dx:Float, dy:Float, ?hit:Hit2D):Bool {
		var rx = bx - ax, ry = by - ay, sx = dx - cx, sy = dy - cy;
		var cross = rx * sy - ry * sx;
		if (cross == 0)
			return false;
		var qx = cx - ax, qy = cy - ay;
		var t = (qx * sy - qy * sx) / cross, u = (qx * ry - qy * rx) / cross;
		if (t <= 0 || t >= 1 || u <= 0 || u >= 1)
			return false;
		if (hit != null) {
			hit.reset();
			hit.time = t;
			hit.x = ax + rx * t;
			hit.y = ay + ry * t;
			var len = Math.sqrt(sx * sx + sy * sy);
			// The crossed segment's normal, facing the way the first came from.
			var nx = -sy / len, ny = sx / len;
			if (nx * rx + ny * ry > 0) {
				nx = -nx;
				ny = -ny;
			}
			hit.normalX = nx;
			hit.normalY = ny;
		}
		return true;
	}

	/** Whether the ray from ox, oy along dx, dy (its whole length: time 1 is its end) meets the rectangle: into hit the time, point and
		normal (0, 0 and time 0 from inside). */
	public static function rayRect(ox:Float, oy:Float, dx:Float, dy:Float, rx:Float, ry:Float, rw:Float, rh:Float, hit:Hit2D):Bool {
		var tMin = 0., tMax = 1., nx = 0., ny = 0.;
		for (axis in 0...2) {
			var o = axis == 0 ? ox : oy,
				d = axis == 0 ? dx : dy,
				lo = axis == 0 ? rx : ry,
				hi = axis == 0 ? rx + rw : ry + rh;
			if (d == 0) {
				if (o < lo || o > hi)
					return false;
				continue;
			}
			var inv = 1 / d, t1 = (lo - o) * inv, t2 = (hi - o) * inv, n = -1.;
			if (t1 > t2) {
				var t = t1;
				t1 = t2;
				t2 = t;
				n = 1;
			}
			if (t1 > tMin) {
				tMin = t1;
				nx = axis == 0 ? n : 0;
				ny = axis == 1 ? n : 0;
			}
			if (t2 < tMax)
				tMax = t2;
			if (tMin > tMax)
				return false;
		}
		hit.reset();
		hit.time = tMin;
		hit.x = ox + dx * tMin;
		hit.y = oy + dy * tMin;
		hit.normalX = nx;
		hit.normalY = ny;
		return true;
	}

	/** Whether the ray from ox, oy along dx, dy (time 1 its end) meets the circle: into hit the time, point and normal (time 0 and no normal
		from inside). */
	public static function rayCircle(ox:Float, oy:Float, dx:Float, dy:Float, cx:Float, cy:Float, r:Float, hit:Hit2D):Bool {
		var fx = ox - cx, fy = oy - cy;
		if (fx * fx + fy * fy < r * r) {
			hit.reset();
			hit.x = ox;
			hit.y = oy;
			return true;
		}
		var a = dx * dx + dy * dy;
		if (a == 0)
			return false;
		var b = 2 * (fx * dx + fy * dy), c = fx * fx + fy * fy - r * r;
		var disc = b * b - 4 * a * c;
		if (disc < 0)
			return false;
		var t = (-b - Math.sqrt(disc)) / (2 * a);
		if (t < 0 || t > 1)
			return false;
		hit.reset();
		hit.time = t;
		hit.x = ox + dx * t;
		hit.y = oy + dy * t;
		hit.normalX = (hit.x - cx) / r;
		hit.normalY = (hit.y - cy) / r;
		return true;
	}

	/** Whether rectangle a, moved by dx, dy, meets rectangle b on the way: into hit the time of the meeting, a's top-left then, and the normal
		(a already overlapping b: time 0, no normal). */
	public static function sweepRectRect(ax:Float, ay:Float, aw:Float, ah:Float, dx:Float, dy:Float, bx:Float, by:Float, bw:Float, bh:Float, hit:Hit2D):Bool {
		if (rectRect(ax, ay, aw, ah, bx, by, bw, bh)) {
			hit.reset();
			hit.x = ax;
			hit.y = ay;
			return true;
		}
		// a's corner as a ray against b grown by a's size (their Minkowski sum).
		return rayRect(ax, ay, dx, dy, bx - aw, by - ah, bw + aw, bh + ah, hit);
	}

	/** Whether circle a, moved by dx, dy, meets circle b on the way: into hit the time, a's center then, and the normal. */
	public static function sweepCircleCircle(ax:Float, ay:Float, ar:Float, dx:Float, dy:Float, bx:Float, by:Float, br:Float, hit:Hit2D):Bool
		return rayCircle(ax, ay, dx, dy, bx, by, ar + br, hit);

	/** Moves the box at x, y (its top-left), width by height, by dx, dy over a grid of tiles of tileSize, each solid or not by solid(column,
		row), sliding along what it meets: first across, stopped at a solid tile's side, then down or up the same; into out the place it ended and
		which sides met a solid. A box starting inside a solid tile is left where it is on that axis. */
	public static function moveAndSlide(x:Float, y:Float, width:Float, height:Float, dx:Float, dy:Float, tileSize:Float, solid:(Int, Int) -> Bool,
			out:Move2D):Move2D {
		out.left = out.right = out.top = out.bottom = false;
		var eps = 1e-6;
		// Across: the rows the box spans now, the columns its new span covers; the nearest solid the way it moves stops it.
		var nx = x + dx;
		if (dx != 0) {
			var row0 = Math.floor(y / tileSize),
				row1 = Math.floor((y + height - eps) / tileSize);
			var col0 = Math.floor(nx / tileSize),
				col1 = Math.floor((nx + width - eps) / tileSize);
			if (dx > 0) {
				// From the column past its leading edge now to the one its leading edge reaches.
				var col = Math.floor((x + width - eps) / tileSize) + 1;
				while (col <= col1) {
					if (columnSolid(col, row0, row1, solid)) {
						nx = col * tileSize - width;
						out.right = true;
						break;
					}
					col++;
				}
			} else {
				var col = Math.floor(x / tileSize) - 1;
				while (col >= col0) {
					if (columnSolid(col, row0, row1, solid)) {
						nx = (col + 1) * tileSize;
						out.left = true;
						break;
					}
					col--;
				}
			}
		}
		// Then down or up, at the new x.
		var ny = y + dy;
		if (dy != 0) {
			var col0 = Math.floor(nx / tileSize),
				col1 = Math.floor((nx + width - eps) / tileSize);
			var row0 = Math.floor(ny / tileSize),
				row1 = Math.floor((ny + height - eps) / tileSize);
			if (dy > 0) {
				var row = Math.floor((y + height - eps) / tileSize) + 1;
				while (row <= row1) {
					if (rowSolid(row, col0, col1, solid)) {
						ny = row * tileSize - height;
						out.bottom = true;
						break;
					}
					row++;
				}
			} else {
				var row = Math.floor(y / tileSize) - 1;
				while (row >= row0) {
					if (rowSolid(row, col0, col1, solid)) {
						ny = (row + 1) * tileSize;
						out.top = true;
						break;
					}
					row--;
				}
			}
		}
		out.x = nx;
		out.y = ny;
		return out;
	}

	static function columnSolid(col:Int, row0:Int, row1:Int, solid:(Int, Int) -> Bool):Bool {
		for (row in row0...row1 + 1)
			if (solid(col, row))
				return true;
		return false;
	}

	static function rowSolid(row:Int, col0:Int, col1:Int, solid:(Int, Int) -> Bool):Bool {
		for (col in col0...col1 + 1)
			if (solid(col, row))
				return true;
		return false;
	}
}
