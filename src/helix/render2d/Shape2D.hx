package helix.render2d;

import helix.font.Font;
import helix.math.Bounds2D;
import helix.render2d.ShapeShading2D;
import helix.render2d.ShapeForm2D;

/** A flat shape in a color (0xAARRGGBB), filled or outlined: a rectangle (its corners square or rounded), a circle, a line or a polygon, made by
	the static constructors, as they differ only in their geometry (form says which). Each form reads the values it uses: a rectangle its size,
	pivot and corner radius, a circle its radius, a line and a polygon their points; the others' are kept but not drawn. */
@:allow(helix.render2d.Renderer2D)
class Shape2D extends Node2D {
	var givenWidth = 0.;
	var givenHeight = 0.;
	var pointList:Array<Float> = [];
	var triangles:Array<Int> = [];
	var outlineWidth = 0.;
	var circleRadius = 0.;
	var corners = 0.;

	function new(form:ShapeForm2D, color:Int) {
		super();
		this.form = form;
		this.color = color;
	}

	/** A filled rectangle width x height (below 0 is 0), its top-left at its position (pivot 0, 0). */
	public static function rectangle(width:Float, height:Float, color = 0xffffffff):Shape2D {
		var shape = new Shape2D(Rectangle, color);
		shape.setSize(width, height);
		return shape;
	}

	/** A filled circle of radius (below 0 is 0), centered on its position. */
	public static function circle(radius:Float, color = 0xffffffff):Shape2D {
		var shape = new Shape2D(Circle, color);
		shape.radius = radius;
		return shape;
	}

	/** A line from x0, y0 to x1, y1 in its own units, as wide as its outline (1 to start). */
	public static function line(x0:Float, y0:Float, x1:Float, y1:Float, color = 0xffffffff):Shape2D {
		var shape = new Shape2D(Line, color);
		shape.pointList = [x0, y0, x1, y1];
		shape.outlineWidth = 1;
		return shape;
	}

	/** A filled polygon through points in its own units (x and y in turn, copied; at least 3 points, convex or not, not crossing itself). Null
		for fewer than 3 points or an odd count. */
	public static function polygon(points:Array<Float>, color = 0xffffffff):Null<Shape2D> {
		var shape = new Shape2D(Polygon, color);
		return shape.setPoints(points) ? shape : null;
	}

	/** Which shape it is. */
	public var form(default, null):ShapeForm2D;

	/** Its color, 0xAARRGGBB: a shaded rectangle's at its start (its left edge, or its top). */
	public var color:Int = 0xffffffff;

	/** How a filled rectangle is colored: Flat in color (the start), or shaded from color to endColor across or down it, each channel
		linearly (alpha too, so a ramp to the same color at alpha 0 fades it out). An outlined rectangle and the other forms are drawn flat. */
	public var shading:ShapeShading2D = Flat;

	/** The color a shaded rectangle reaches at its end (its right edge, or its bottom), 0xAARRGGBB. (0xffffffff to start.) */
	public var endColor:Int = 0xffffffff;

	/** A rectangle's width, in its own units. */
	public var width(get, never):Float;

	function get_width():Float
		return givenWidth;

	/** A rectangle's height, in its own units. */
	public var height(get, never):Float;

	function get_height():Float
		return givenHeight;

	/** Sizes a rectangle, in its own units; below 0 is 0. */
	public function setSize(width:Float, height:Float):Void {
		givenWidth = width > 0 ? width : 0;
		givenHeight = height > 0 ? height : 0;
	}

	/** Sets the point of a rectangle at its position, which it turns and scales about, as a fraction of its size: 0, 0 its top-left (the
		start), 1, 1 its bottom-right. */
	public function setPivot(x:Float, y:Float):Void {
		pivotX = x;
		pivotY = y;
	}

	/** A rectangle's pivot's x fraction. */
	public var pivotX(default, null):Float = 0.;

	/** A rectangle's pivot's y fraction. */
	public var pivotY(default, null):Float = 0.;

	/** A circle's radius, in its own units. At least 0 (below 0, or NaN, is 0). */
	public var radius(get, set):Float;

	function get_radius():Float
		return circleRadius;

	function set_radius(value:Float):Float {
		circleRadius = value > 0 ? value : 0;
		return circleRadius;
	}

	/** A rectangle's corners' radius, in its own units, 0 for square (the start): drawn at most half its shorter side; outlined, the outline's
		middle follows the corners; picked by its rounded shape. At least 0 (below 0, or NaN, is 0). */
	public var cornerRadius(get, set):Float;

	function get_cornerRadius():Float
		return corners;

	function set_cornerRadius(value:Float):Float {
		corners = value > 0 ? value : 0;
		return corners;
	}

	/** Its outline's width, in its own units, centered on its edge: 0 draws a rectangle, circle or polygon filled (the start), and is a line's
		width (1 to start; 0 draws nothing). At least 0 (below 0, or NaN, is 0). */
	public var outline(get, set):Float;

	function get_outline():Float
		return outlineWidth;

	function set_outline(value:Float):Float {
		outlineWidth = value > 0 ? value : 0;
		return outlineWidth;
	}

	/** A polygon's points or a line's ends, x and y in turn (a copy); empty for a rectangle or circle. */
	public var points(get, never):Array<Float>;

	function get_points():Array<Float>
		return pointList.copy();

	/** Gives a polygon new points (as polygon() takes them, copied) or a line new ends (4 floats). False, changing nothing, for a rectangle or
		circle or a wrong count. */
	public function setPoints(value:Array<Float>):Bool {
		if (form == Line && value.length == 4) {
			pointList = value.copy();
			return true;
		}
		if (form != Polygon || value.length < 6 || value.length % 2 != 0)
			return false;
		pointList = value.copy();
		triangles = Polygon2D.triangulate(pointList);
		return true;
	}

	override function measureOwn(font:Null<Font>, out:Bounds2D):Bool {
		var half = outlineWidth / 2;
		switch form {
			case Rectangle:
				var w = givenWidth, h = givenHeight;
				out.set(-pivotX * w - half, -pivotY * h - half, (1 - pivotX) * w + half, (1 - pivotY) * h + half);
			case Circle:
				out.set(-circleRadius - half, -circleRadius - half, circleRadius + half, circleRadius + half);
			case Line | Polygon:
				var p = pointList;
				out.clear();
				var k = 0;
				while (k < p.length) {
					out.expand(p[k], p[k + 1]);
					k += 2;
				}
				// A miter can reach twice the width past a corner.
				var reach = form == Polygon ? outlineWidth * 2 : half;
				out.set(out.minX - reach, out.minY - reach, out.maxX + reach, out.maxY + reach);
		}
		return true;
	}
}
