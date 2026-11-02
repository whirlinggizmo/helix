package helix.render;

/** Shapes made of triangles in a plane, for both batches: each triangle handed to `emit`, curves cut into as many segments as keep their
	edge within a quarter of a pixel at `scale` pixels a unit. Strokes are centered on their edges; a polyline's ends are square, cut at
	its points, and its corners mitered, or bevelled where the miter would reach past twice the thickness. */
@:noCompletion
@:allow(helix.render)
class Tessellator2D {
	/** Receives each triangle's corners. */
	var emit:(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float) -> Void;

	/** Pixels a unit, where the shapes are drawn: what a curve's segments are counted by. */
	var scale = 1.;

	// A path's distinct points, each segment's direction, and each point's offsets, kept between calls.
	final xs:Array<Float> = [];
	final ys:Array<Float> = [];
	final dxs:Array<Float> = [];
	final dys:Array<Float> = [];
	final outline:Array<Float> = [];

	function new(emit:(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float) -> Void) {
		this.emit = emit;
	}

	/** The segments a whole circle of a radius takes, so its edge strays at most a quarter of a pixel from the curve. */
	function segments(radius:Float):Int {
		var pixels = Math.abs(radius * scale);
		if (pixels <= .25)
			return 4;
		var n = Math.ceil(Math.PI / Math.acos(1 - .25 / pixels));
		return n < 4 ? 4 : n > 1024 ? 1024 : n;
	}

	function rectangle(x:Float, y:Float, width:Float, height:Float):Void {
		emit(x, y, x + width, y, x + width, y + height);
		emit(x, y, x + width, y + height, x, y + height);
	}

	/** A line between two points, its ends square and cut at the points. */
	function line(x0:Float, y0:Float, x1:Float, y1:Float, thickness:Float):Void {
		var dx = x1 - x0, dy = y1 - y0, length = Math.sqrt(dx * dx + dy * dy);
		if (length <= 0 || thickness <= 0)
			return;
		var nx = -dy / length * thickness / 2,
			ny = dx / length * thickness / 2;
		emit(x0 + nx, y0 + ny, x1 + nx, y1 + ny, x1 - nx, y1 - ny);
		emit(x0 + nx, y0 + ny, x1 - nx, y1 - ny, x0 - nx, y0 - ny);
	}

	/** A path through points, x and y each, open or closed. */
	function stroke(points:Array<Float>, closed:Bool, thickness:Float):Void {
		xs.resize(0);
		ys.resize(0);
		var k = 0;
		while (k + 1 < points.length) {
			var x = points[k], y = points[k + 1];
			if (xs.length == 0 || x != xs[xs.length - 1] || y != ys[ys.length - 1]) {
				xs.push(x);
				ys.push(y);
			}
			k += 2;
		}
		if (closed && xs.length > 1 && xs[0] == xs[xs.length - 1] && ys[0] == ys[ys.length - 1]) {
			xs.pop();
			ys.pop();
		}
		var n = xs.length, h = thickness / 2;
		if (n < 2 || h <= 0)
			return;
		if (n == 2)
			closed = false;
		var count = closed ? n : n - 1;
		dxs.resize(0);
		dys.resize(0);
		for (i in 0...count) {
			var j = (i + 1) % n,
				dx = xs[j] - xs[i],
				dy = ys[j] - ys[i],
				length = Math.sqrt(dx * dx + dy * dy);
			dxs.push(dx / length);
			dys.push(dy / length);
		}
		// Each segment a band; each corner joined on its outer side, mitered or bevelled.
		for (i in 0...count) {
			var j = (i + 1) % n, nx = -dys[i] * h, ny = dxs[i] * h;
			var ax = xs[i], ay = ys[i], bx = xs[j], by = ys[j];
			emit(ax + nx, ay + ny, bx + nx, by + ny, bx - nx, by - ny);
			emit(ax + nx, ay + ny, bx - nx, by - ny, ax - nx, ay - ny);
		}
		for (i in (closed ? 0 : 1)...(closed ? n : n - 1)) {
			var a = (i + count - 1) % count, b = i % count;
			var turn = dxs[a] * dys[b] - dys[a] * dxs[b];
			if (Math.abs(turn) < 1e-9 && dxs[a] * dxs[b] + dys[a] * dys[b] > 0)
				continue;
			// The outer side: away from where the path turns.
			var side = turn > 0 ? -1 : 1;
			var ax = -dys[a] * h * side,
				ay = dxs[a] * h * side,
				bx = -dys[b] * h * side,
				by = dxs[b] * h * side;
			var x = xs[i], y = ys[i];
			// The miter's tip: along the bisector of the two normals, as far as the bands' outer edges meet.
			var mx = ax + bx, my = ay + by, m = Math.sqrt(mx * mx + my * my);
			var cos = m / (2 * h);
			if (cos > 1e-6 && h / cos <= 2 * thickness) {
				var reach = h / cos / m;
				var tx = x + mx * reach, ty = y + my * reach;
				emit(x, y, x + ax, y + ay, tx, ty);
				emit(x, y, tx, ty, x + bx, y + by);
			} else
				emit(x, y, x + ax, y + ay, x + bx, y + by);
		}
	}

	/** Whether a polygon's edges cross: any two that aren't neighbors meeting. */
	static function crosses(points:Array<Float>):Bool {
		var n = points.length >> 1;
		inline function side(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Float
			return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
		for (i in 0...n) {
			var i2 = (i + 1) % n;
			for (j in i + 1...n) {
				var j2 = (j + 1) % n;
				if (j == i2 || j2 == i)
					continue;
				var ax = points[i * 2],
					ay = points[i * 2 + 1],
					bx = points[i2 * 2],
					by = points[i2 * 2 + 1];
				var cx = points[j * 2],
					cy = points[j * 2 + 1],
					dx = points[j2 * 2],
					dy = points[j2 * 2 + 1];
				var d1 = side(ax, ay, bx, by, cx, cy),
					d2 = side(ax, ay, bx, by, dx, dy);
				var d3 = side(cx, cy, dx, dy, ax, ay),
					d4 = side(cx, cy, dx, dy, bx, by);
				if ((d1 > 0 && d2 < 0 || d1 < 0 && d2 > 0) && (d3 > 0 && d4 < 0 || d3 < 0 && d4 > 0))
					return true;
			}
		}
		return false;
	}

	/** The triangles filling a simple polygon, convex or not, by ear clipping, as indices of its points; either way round. */
	static function triangulate(points:Array<Float>):Array<Int> {
		var n = points.length >> 1, out = [];
		if (n < 3)
			return out;
		var area = 0.;
		for (i in 0...n) {
			var j = (i + 1) % n;
			area += points[i * 2] * points[j * 2 + 1] - points[j * 2] * points[i * 2 + 1];
		}
		var left = [for (i in 0...n) i], clockwise = area > 0;
		inline function turn(a:Int, b:Int, c:Int):Float {
			var v = (points[b * 2]
				- points[a * 2]) * (points[c * 2 + 1] - points[a * 2 + 1])
				- (points[b * 2 + 1] - points[a * 2 + 1]) * (points[c * 2] - points[a * 2]);
			return clockwise ? v : -v;
		}
		var misses = 0, i = 0;
		while (left.length > 3 && misses < left.length) {
			var m = left.length,
				a = left[(i + m - 1) % m],
				b = left[i % m],
				c = left[(i + 1) % m];
			var ear = turn(a, b, c) > 0;
			if (ear)
				for (p in left)
					if (p != a && p != b && p != c && turn(a, b, p) >= 0 && turn(b, c, p) >= 0 && turn(c, a, p) >= 0) {
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

	/** Fills a polygon; false, drawing nothing, when its edges cross. */
	function fillPolygon(points:Array<Float>):Bool {
		if (points.length < 6)
			return true;
		if (crosses(points))
			return false;
		var t = triangulate(points), i = 0;
		while (i + 2 < t.length) {
			var a = t[i] * 2, b = t[i + 1] * 2, c = t[i + 2] * 2;
			emit(points[a], points[a + 1], points[b], points[b + 1], points[c], points[c + 1]);
			i += 3;
		}
		return true;
	}

	/** The outline of a rectangle with rounded corners into `outline`: clockwise on screen from the top-left corner's arc. */
	function rounded(x:Float, y:Float, width:Float, height:Float, radius:Float):Void {
		var r = Math.max(0, Math.min(radius, Math.min(width, height) / 2));
		var steps = Std.int(Math.max(1, Math.ceil(segments(r) / 4)));
		outline.resize(0);
		for (corner in 0...4) {
			var cx = corner == 0 || corner == 3 ? x + r : x + width - r,
				cy = corner < 2 ? y + r : y + height - r;
			var start = Math.PI + corner * Math.PI / 2;
			for (i in 0...steps + 1) {
				var a = start + i * Math.PI / 2 / steps;
				outline.push(cx + Math.cos(a) * r);
				outline.push(cy + Math.sin(a) * r);
			}
		}
	}

	function fillRounded(x:Float, y:Float, width:Float, height:Float, radius:Float):Void {
		rounded(x, y, width, height, radius);
		fan(x + width / 2, y + height / 2, outline);
	}

	function strokeRounded(x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float):Void {
		rounded(x, y, width, height, radius);
		stroke(outline.copy(), true, thickness);
	}

	/** An ellipse's outline into `outline`, its axes across and down. */
	function ellipse(x:Float, y:Float, radiusX:Float, radiusY:Float):Void {
		var n = segments(Math.max(Math.abs(radiusX), Math.abs(radiusY)));
		outline.resize(0);
		for (i in 0...n) {
			var a = i * Math.PI * 2 / n;
			outline.push(x + Math.cos(a) * radiusX);
			outline.push(y + Math.sin(a) * radiusY);
		}
	}

	function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float):Void {
		ellipse(x, y, radiusX, radiusY);
		fan(x, y, outline);
	}

	/** A ring between two ellipses, a thickness apart, centered on one. */
	function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float):Void {
		var n = segments(Math.max(Math.abs(radiusX), Math.abs(radiusY)) + thickness / 2),
			h = thickness / 2;
		var ox = radiusX + h,
			oy = radiusY + h,
			ix = Math.max(0, radiusX - h),
			iy = Math.max(0, radiusY - h);
		for (i in 0...n) {
			var a = i * Math.PI * 2 / n, b = (i + 1) * Math.PI * 2 / n;
			var ca = Math.cos(a),
				sa = Math.sin(a),
				cb = Math.cos(b),
				sb = Math.sin(b);
			emit(x + ca * ix, y + sa * iy, x + ca * ox, y + sa * oy, x + cb * ox, y + sb * oy);
			emit(x + ca * ix, y + sa * iy, x + cb * ox, y + sb * oy, x + cb * ix, y + sb * iy);
		}
	}

	// Triangles from a center to each edge of a closed outline.
	function fan(x:Float, y:Float, points:Array<Float>):Void {
		var n = points.length >> 1;
		for (i in 0...n) {
			var j = (i + 1) % n;
			emit(x, y, points[i * 2], points[i * 2 + 1], points[j * 2], points[j * 2 + 1]);
		}
	}
}
