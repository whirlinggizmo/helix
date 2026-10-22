package helix.render2d;

/** Drawing kept on a node (docs/DISPLAY_MODEL.md): Flash's graphics, as calls named as Batch2D's (rect, frame, roundedRect, circle,
	circleLines, line, polygon, polygonLines, drawText), each taking its own color (0xAARRGGBB), so there is no fill to begin or end. The calls
	are kept in order, in the node's own units, and drawn each frame where the node is, turned, scaled and faded with it; clear takes them away.
	Calling clear and drawing again in update is immediate drawing, as Flash games did it. Not culled; picked by the box around what it holds. */
class Drawing2D extends Node2D {
	// The calls in order: each its kind, its numbers from its place in numbers, its color, and for text, its text in texts.
	var kinds:Array<DrawingKind> = [];
	var starts:Array<Int> = [];
	var numbers:Array<Float> = [];
	var colors:Array<Int> = [];
	var texts:Array<String> = [];
	var aligns:Array<Align2D> = [];
	var fonts:Array<Null<Font2D>> = [];
	var triangles:Array<Null<Array<Int>>> = [];
	var points:Array<Null<Array<Float>>> = [];
	// The box around the shapes held, in its own units (text measured as it's drawn).
	@:allow(helix.render2d.Stage2D)
	var left = Math.POSITIVE_INFINITY;
	@:allow(helix.render2d.Stage2D)
	var top = Math.POSITIVE_INFINITY;
	@:allow(helix.render2d.Stage2D)
	var right = Math.NEGATIVE_INFINITY;
	@:allow(helix.render2d.Stage2D)
	var bottom = Math.NEGATIVE_INFINITY;

	/** A drawing holding nothing yet. */
	public function new()
		super();

	/** How many calls it holds. */
	public var callCount(get, never):Int;

	function get_callCount():Int
		return kinds.length;

	/** Takes everything drawn away. */
	public function clear():Void {
		kinds.resize(0);
		starts.resize(0);
		numbers.resize(0);
		colors.resize(0);
		texts.resize(0);
		aligns.resize(0);
		fonts.resize(0);
		triangles.resize(0);
		points.resize(0);
		left = top = Math.POSITIVE_INFINITY;
		right = bottom = Math.NEGATIVE_INFINITY;
	}

	/** A filled rectangle, top-left at x, y, w x h. */
	public function rect(x:Float, y:Float, w:Float, h:Float, color:Int):Void {
		add(Rect, [x, y, w, h], color);
		include(x, y, x + w, y + h);
	}

	/** A rectangle's outline drawn inside its bounds, width wide. */
	public function frame(x:Float, y:Float, w:Float, h:Float, width:Float, color:Int):Void {
		add(Frame, [x, y, w, h, width], color);
		include(x, y, x + w, y + h);
	}

	/** A filled rectangle with corners of radius (clamped to half the shorter side). */
	public function roundedRect(x:Float, y:Float, w:Float, h:Float, radius:Float, color:Int):Void {
		add(RoundedRect, [x, y, w, h, radius], color);
		include(x, y, x + w, y + h);
	}

	/** A filled circle centered on x, y. */
	public function circle(x:Float, y:Float, radius:Float, color:Int):Void {
		add(Circle, [x, y, radius], color);
		include(x - radius, y - radius, x + radius, y + radius);
	}

	/** A circle's outline width wide, centered on the circle of radius around x, y. */
	public function circleLines(x:Float, y:Float, radius:Float, width:Float, color:Int):Void {
		add(CircleLines, [x, y, radius, width], color);
		var reach = radius + width / 2;
		include(x - reach, y - reach, x + reach, y + reach);
	}

	/** A segment width wide from x0, y0 to x1, y1, square ended. */
	public function line(x0:Float, y0:Float, x1:Float, y1:Float, width:Float, color:Int):Void {
		add(Line, [x0, y0, x1, y1, width], color);
		var half = width / 2;
		include(Math.min(x0, x1) - half, Math.min(y0, y1) - half, Math.max(x0, x1) + half, Math.max(y0, y1) + half);
	}

	/** A filled polygon through points (x and y in turn, copied; at least 3 points, convex or not, not crossing itself). False, holding
		nothing more, for fewer than 3 points or one that can't be filled. */
	public function polygon(points:Array<Float>, color:Int):Bool {
		if (points.length < 6 || points.length % 2 != 0)
			return false;
		var made = Polygon2D.triangulate(points);
		if (made.length == 0)
			return false;
		add(Polygon, [], color);
		this.points[this.points.length - 1] = points.copy();
		triangles[triangles.length - 1] = made;
		includePoints(points, 0);
		return true;
	}

	/** A polygon's outline through points (copied), closed, width wide centered on its edges. False, holding nothing more, for fewer than 2
		points. */
	public function polygonLines(points:Array<Float>, width:Float, color:Int):Bool {
		if (points.length < 4 || points.length % 2 != 0)
			return false;
		add(PolygonLines, [width], color);
		this.points[this.points.length - 1] = points.copy();
		// A miter can reach twice the width past a corner.
		includePoints(points, width * 2);
		return true;
	}

	/** One line of text, its top at y and x its left edge, center or right edge by align, size tall, in font (null for the batch's). */
	public function drawText(text:String, x:Float, y:Float, size:Float, color:Int, align:Align2D = Left, ?font:Font2D):Void {
		add(Text, [x, y, size], color);
		texts[texts.length - 1] = text;
		aligns[aligns.length - 1] = align;
		fonts[fonts.length - 1] = font;
	}

	// A call of kind with its numbers and color.
	function add(kind:DrawingKind, values:Array<Float>, color:Int):Void {
		kinds.push(kind);
		starts.push(numbers.length);
		for (v in values)
			numbers.push(v);
		colors.push(color);
		texts.push(null);
		aligns.push(Left);
		fonts.push(null);
		triangles.push(null);
		points.push(null);
	}

	function include(x0:Float, y0:Float, x1:Float, y1:Float):Void {
		left = Math.min(left, x0);
		top = Math.min(top, y0);
		right = Math.max(right, x1);
		bottom = Math.max(bottom, y1);
	}

	function includePoints(points:Array<Float>, reach:Float):Void {
		var k = 0;
		while (k < points.length) {
			include(points[k] - reach, points[k + 1] - reach, points[k] + reach, points[k + 1] + reach);
			k += 2;
		}
	}

	// Draws every call into batch, its transform set to this node's by the walk.

	@:allow(helix.render2d.Stage2D)
	function replay(batch:Batch2D):Void {
		for (i in 0...kinds.length) {
			var at = starts[i], n = numbers, c = colors[i];
			switch kinds[i] {
				case Rect:
					batch.rect(n[at], n[at + 1], n[at + 2], n[at + 3], c);
				case Frame:
					batch.frame(n[at], n[at + 1], n[at + 2], n[at + 3], n[at + 4], c);
				case RoundedRect:
					batch.roundedRect(n[at], n[at + 1], n[at + 2], n[at + 3], n[at + 4], c);
				case Circle:
					batch.circle(n[at], n[at + 1], n[at + 2], c);
				case CircleLines:
					batch.circleLines(n[at], n[at + 1], n[at + 2], n[at + 3], c);
				case Line:
					batch.line(n[at], n[at + 1], n[at + 2], n[at + 3], n[at + 4], c);
				case Polygon:
					batch.polygon(points[i], c, triangles[i]);
				case PolygonLines:
					batch.polygonLines(points[i], n[at], c);
				case Text:
					batch.drawText(texts[i], n[at], n[at + 1], n[at + 2], c, aligns[i], fonts[i]);
			}
		}
	}

	// Whether own point x, y is inside the box around what it holds, text measured in font (the batch's last, for text without its own).

	@:allow(helix.render2d.Stage2D)
	function holds(x:Float, y:Float, font:Null<Font2D>):Bool {
		if (x >= left && x <= right && y >= top && y <= bottom)
			return true;
		for (i in 0...kinds.length)
			if (kinds[i] == Text) {
				var f = fonts[i] != null ? fonts[i] : font;
				if (f == null)
					continue;
				var at = starts[i],
					size = numbers[at + 2],
					w = f.measure(texts[i], size);
				var x0 = numbers[at] - (aligns[i] == Center ? w / 2 : aligns[i] == Right ? w : 0),
					y0 = numbers[at + 1];
				if (x >= x0 && x <= x0 + w && y >= y0 && y <= y0 + size)
					return true;
			}
		return false;
	}
}

/** What a Drawing2D call draws. */
private enum abstract DrawingKind(Int) {
	var Rect;
	var Frame;
	var RoundedRect;
	var Circle;
	var CircleLines;
	var Line;
	var Polygon;
	var PolygonLines;
	var Text;
}
