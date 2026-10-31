package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.math.Bounds2D;
import helix.math.Geometry2D;
import helix.math.Interpolate;
import helix.math.Point2D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.raylib.RCore.*;
import helix.ray.raylib.RShapes.*;
import helix.ray.raylib.RTextures.*;
import helix.ray.raylib.RText.*;
import helix.ray.raylib.RModels.*;
import helix.ray.raylib.RAudio.*;
import helix.ray.raylib.RMath.*;
import helix.ray.raylib.RAsync.*;
#end

/** Holds raylib's rshapes (2D shapes and their collisions), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RShapes {
	#if !macro
	// ---- Shapes texture ----

	/** Sets the texture and the part of it the filled shapes draw with, as one white pixel of a font's texture lets shapes and text
		share a draw. A texture with no id, or an empty rectangle, goes back to the white pixel shapes draw with at first.

		@param texture  The texture.
		@param source  The part of it, in pixels. */
	static function SetShapesTexture(texture:Texture2D, source:Rectangle):Void {
		if (texture.id == 0 || source.width == 0 || source.height == 0) {
			texShapes = null;
			texShapesRec = new Rectangle(0, 0, 1, 1);
		} else {
			texShapes = texture;
			texShapesRec = new Rectangle(source.x, source.y, source.width, source.height);
		}
		var w = texShapes == null ? 1 : texShapes.width,
			h = texShapes == null ? 1 : texShapes.height;
		shapeU0 = texShapesRec.x / w;
		shapeV0 = texShapesRec.y / h;
		shapeU1 = (texShapesRec.x + texShapesRec.width) / w;
		shapeV1 = (texShapesRec.y + texShapesRec.height) / h;
	}

	/** Returns the texture the filled shapes draw with: a white pixel unless `SetShapesTexture` set another.

		@return  The texture. */
	static function GetShapesTexture():Texture2D {
		if (texShapes != null)
			return texShapes;
		if (whiteTexture == null || Textures.handle(whiteTexture.id) != Runtime.frame.white)
			whiteTexture = new Texture2D(Textures.fromHandle(Runtime.frame.white), 1, 1);
		return whiteTexture;
	}

	/** Returns the part of the shapes texture the filled shapes draw with.

		@return  The rectangle, in pixels. */
	static function GetShapesTextureRectangle():Rectangle {
		return new Rectangle(texShapesRec.x, texShapesRec.y, texShapesRec.width, texShapesRec.height);
	}

	// ---- Shapes ----

	/** Draws one pixel.

		@param posX  The x.
		@param posY  The y.
		@param color  The color. */
	static function DrawPixel(posX:Int, posY:Int, color:Color):Void {
		quad(posX, posY, 1, 1, color);
	}

	/** Draws one pixel.

		@param position  The position.
		@param color  The color. */
	static function DrawPixelV(position:Vector2, color:Color):Void {
		quad(position.x, position.y, 1, 1, color);
	}

	/** Draws a line one pixel wide.

		@param startPosX  The start's x.
		@param startPosY  The start's y.
		@param endPosX  The end's x.
		@param endPosY  The end's y.
		@param color  The color. */
	static function DrawLine(startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void {
		line(startPosX + .5, startPosY + .5, endPosX + .5, endPosY + .5, 1, color);
	}

	/** Draws a line one pixel wide.

		@param startPos  The start.
		@param endPos  The end.
		@param color  The color. */
	static function DrawLineV(startPos:Vector2, endPos:Vector2, color:Color):Void {
		line(startPos.x, startPos.y, endPos.x, endPos.y, 1, color);
	}

	/** Draws a line of a thickness.

		@param startPos  The start.
		@param endPos  The end.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawLineEx(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void {
		line(startPos.x, startPos.y, endPos.x, endPos.y, thick, color);
	}

	/** Draws lines one pixel wide from each point to the next.

		@param points  The points.
		@param pointCount  How many of them to draw through, 2 or more.
		@param color  The color. */
	static function DrawLineStrip(points:Array<Vector2>, pointCount:Int, color:Color):Void {
		if (pointCount < 2)
			return;
		for (i in 0...pointCount - 1)
			line(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y, 1, color);
	}

	/** Draws a line of a thickness that eases in and out from start to end, as an S.

		@param startPos  The start.
		@param endPos  The end.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawLineBezier(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void {
		var px = startPos.x, py = startPos.y;
		var points = [for (i in 0...2 * SPLINE_SEGMENT_DIVISIONS + 2) new Vector2()];
		for (i in 1...SPLINE_SEGMENT_DIVISIONS + 1) {
			var cy = easeCubicInOut(i, startPos.y, endPos.y - startPos.y, SPLINE_SEGMENT_DIVISIONS);
			var cx = px + (endPos.x - startPos.x) / SPLINE_SEGMENT_DIVISIONS;
			var dy = cy - py, dx = cx - px, size = .5 * thick / Math.sqrt(dx * dx + dy * dy);
			if (i == 1) {
				points[0].x = px + dy * size;
				points[0].y = py - dx * size;
				points[1].x = px - dy * size;
				points[1].y = py + dx * size;
			}
			points[2 * i + 1].x = cx - dy * size;
			points[2 * i + 1].y = cy + dx * size;
			points[2 * i].x = cx + dy * size;
			points[2 * i].y = cy - dx * size;
			px = cx;
			py = cy;
		}
		DrawTriangleStrip(points, points.length, color);
	}

	/** Draws a filled circle.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radius  The radius.
		@param color  The color. */
	static function DrawCircle(centerX:Int, centerY:Int, radius:Float, color:Color):Void {
		circle(centerX, centerY, radius, color);
	}

	/** Draws a filled circle.

		@param center  The center.
		@param radius  The radius.
		@param color  The color. */
	static function DrawCircleV(center:Vector2, radius:Float, color:Color):Void {
		circle(center.x, center.y, radius, color);
	}

	/** Draws a filled slice of a circle, clockwise from one angle to another.

		@param center  The center.
		@param radius  The radius.
		@param startAngle  The angle it starts at, in degrees from the right.
		@param endAngle  The angle it ends at.
		@param segments  How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
		@param color  The color. */
	static function DrawCircleSector(center:Vector2, radius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void {
		if (radius <= 0)
			radius = .1;
		if (endAngle < startAngle) {
			var t = startAngle;
			startAngle = endAngle;
			endAngle = t;
		}
		segments = arcSegments(radius, startAngle, endAngle, segments);
		var step = (endAngle - startAngle) / segments, angle = startAngle;
		var cx = center.x, cy = center.y;
		for (i in 0...Std.int(segments / 2)) {
			corner(cx, cy, 0, color);
			corner(arcX(cx, angle + step * 2, radius), arcY(cy, angle + step * 2, radius), 3, color);
			corner(arcX(cx, angle + step, radius), arcY(cy, angle + step, radius), 2, color);
			corner(arcX(cx, angle, radius), arcY(cy, angle, radius), 1, color);
			angle += step * 2;
		}
		if (segments % 2 == 1) {
			corner(cx, cy, 0, color);
			corner(arcX(cx, angle + step, radius), arcY(cy, angle + step, radius), 2, color);
			corner(arcX(cx, angle, radius), arcY(cy, angle, radius), 1, color);
			corner(cx, cy, 3, color);
		}
	}

	/** Draws a slice of a circle's outline, one pixel wide, with lines from the center to its ends.

		@param center  The center.
		@param radius  The radius.
		@param startAngle  The angle it starts at, in degrees from the right.
		@param endAngle  The angle it ends at.
		@param segments  How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
		@param color  The color. */
	static function DrawCircleSectorLines(center:Vector2, radius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void {
		if (radius <= 0)
			radius = .1;
		if (endAngle < startAngle) {
			var t = startAngle;
			startAngle = endAngle;
			endAngle = t;
		}
		segments = arcSegments(radius, startAngle, endAngle, segments);
		var step = (endAngle - startAngle) / segments, angle = startAngle;
		var cx = center.x, cy = center.y;
		line(cx, cy, arcX(cx, angle, radius), arcY(cy, angle, radius), 1, color);
		for (i in 0...segments) {
			line(arcX(cx, angle, radius), arcY(cy, angle, radius), arcX(cx, angle + step, radius), arcY(cy, angle + step, radius), 1, color);
			angle += step;
		}
		line(cx, cy, arcX(cx, angle, radius), arcY(cy, angle, radius), 1, color);
	}

	/** Draws a filled circle that blends from one color at its center to another at its edge.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radius  The radius.
		@param inner  The color at the center.
		@param outer  The color at the edge. */
	static function DrawCircleGradient(centerX:Int, centerY:Int, radius:Float, inner:Color, outer:Color):Void {
		var t = Runtime.frame.white;
		var i = 0;
		while (i < 360) {
			flat(t, centerX, centerY, 0, 0, inner);
			flat(t, arcX(centerX, i + 10, radius), arcY(centerY, i + 10, radius), 0, 0, outer);
			flat(t, arcX(centerX, i, radius), arcY(centerY, i, radius), 0, 0, outer);
			i += 10;
		}
	}

	/** Draws a circle's outline, one pixel wide.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radius  The radius.
		@param color  The color. */
	static function DrawCircleLines(centerX:Int, centerY:Int, radius:Float, color:Color):Void {
		ring(centerX, centerY, radius, color);
	}

	/** Draws a circle's outline, one pixel wide.

		@param center  The center.
		@param radius  The radius.
		@param color  The color. */
	static function DrawCircleLinesV(center:Vector2, radius:Float, color:Color):Void {
		ring(center.x, center.y, radius, color);
	}

	/** Draws a filled ellipse.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radiusH  The radius across.
		@param radiusV  The radius up and down.
		@param color  The color. */
	static function DrawEllipse(centerX:Int, centerY:Int, radiusH:Float, radiusV:Float, color:Color):Void {
		var t = Runtime.frame.white;
		var i = 0;
		while (i < 360) {
			flat(t, centerX, centerY, 0, 0, color);
			flat(t, arcX(centerX, i + 10, radiusH), arcY(centerY, i + 10, radiusV), 0, 0, color);
			flat(t, arcX(centerX, i, radiusH), arcY(centerY, i, radiusV), 0, 0, color);
			i += 10;
		}
	}

	/** Draws an ellipse's outline, one pixel wide.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radiusH  The radius across.
		@param radiusV  The radius up and down.
		@param color  The color. */
	static function DrawEllipseLines(centerX:Int, centerY:Int, radiusH:Float, radiusV:Float, color:Color):Void {
		var i = 0;
		while (i < 360) {
			line(arcX(centerX, i + 10, radiusH), arcY(centerY, i + 10, radiusV), arcX(centerX, i, radiusH), arcY(centerY, i, radiusV), 1, color);
			i += 10;
		}
	}

	/** Draws a filled ring, or a slice of one, clockwise from one angle to another.

		@param center  The center.
		@param innerRadius  The radius of its hole; 0 or less draws a slice of a circle.
		@param outerRadius  The radius of its edge.
		@param startAngle  The angle it starts at, in degrees from the right.
		@param endAngle  The angle it ends at; the same as the start draws nothing.
		@param segments  How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
		@param color  The color. */
	static function DrawRing(center:Vector2, innerRadius:Float, outerRadius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void {
		if (startAngle == endAngle)
			return;
		if (outerRadius < innerRadius) {
			var t = outerRadius;
			outerRadius = innerRadius;
			innerRadius = t;
			if (outerRadius <= 0)
				outerRadius = .1;
		}
		if (endAngle < startAngle) {
			var t = startAngle;
			startAngle = endAngle;
			endAngle = t;
		}
		segments = arcSegments(outerRadius, startAngle, endAngle, segments);
		if (innerRadius <= 0) {
			DrawCircleSector(center, outerRadius, startAngle, endAngle, segments, color);
			return;
		}
		var step = (endAngle - startAngle) / segments, angle = startAngle;
		var cx = center.x, cy = center.y;
		for (i in 0...segments) {
			corner(arcX(cx, angle, outerRadius), arcY(cy, angle, outerRadius), 1, color);
			corner(arcX(cx, angle, innerRadius), arcY(cy, angle, innerRadius), 0, color);
			corner(arcX(cx, angle + step, innerRadius), arcY(cy, angle + step, innerRadius), 3, color);
			corner(arcX(cx, angle + step, outerRadius), arcY(cy, angle + step, outerRadius), 2, color);
			angle += step;
		}
	}

	/** Draws a ring's outline, or a slice of one, one pixel wide.

		@param center  The center.
		@param innerRadius  The radius of its hole; 0 or less draws a slice of a circle.
		@param outerRadius  The radius of its edge.
		@param startAngle  The angle it starts at, in degrees from the right.
		@param endAngle  The angle it ends at; the same as the start draws nothing.
		@param segments  How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
		@param color  The color. */
	static function DrawRingLines(center:Vector2, innerRadius:Float, outerRadius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void {
		if (startAngle == endAngle)
			return;
		if (outerRadius < innerRadius) {
			var t = outerRadius;
			outerRadius = innerRadius;
			innerRadius = t;
			if (outerRadius <= 0)
				outerRadius = .1;
		}
		if (endAngle < startAngle) {
			var t = startAngle;
			startAngle = endAngle;
			endAngle = t;
		}
		segments = arcSegments(outerRadius, startAngle, endAngle, segments);
		if (innerRadius <= 0) {
			DrawCircleSectorLines(center, outerRadius, startAngle, endAngle, segments, color);
			return;
		}
		var step = (endAngle - startAngle) / segments, angle = startAngle;
		var cx = center.x, cy = center.y;
		line(arcX(cx, angle, outerRadius), arcY(cy, angle, outerRadius), arcX(cx, angle, innerRadius), arcY(cy, angle, innerRadius), 1, color);
		for (i in 0...segments) {
			line(arcX(cx, angle, outerRadius), arcY(cy, angle, outerRadius), arcX(cx, angle + step, outerRadius), arcY(cy, angle + step, outerRadius), 1,
				color);
			line(arcX(cx, angle, innerRadius), arcY(cy, angle, innerRadius), arcX(cx, angle + step, innerRadius), arcY(cy, angle + step, innerRadius), 1,
				color);
			angle += step;
		}
		line(arcX(cx, angle, outerRadius), arcY(cy, angle, outerRadius), arcX(cx, angle, innerRadius), arcY(cy, angle, innerRadius), 1, color);
	}

	/** Draws a filled rectangle.

		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	static function DrawRectangle(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void {
		quad(posX, posY, width, height, color);
	}

	/** Draws a filled rectangle.

		@param position  The top-left corner.
		@param size  The width and height.
		@param color  The color. */
	static function DrawRectangleV(position:Vector2, size:Vector2, color:Color):Void {
		quad(position.x, position.y, size.x, size.y, color);
	}

	/** Draws a filled rectangle.

		@param rec  The rectangle.
		@param color  The color. */
	static function DrawRectangleRec(rec:Rectangle, color:Color):Void {
		quad(rec.x, rec.y, rec.width, rec.height, color);
	}

	/** Draws a filled rectangle turned about a point of it.

		@param rec  The rectangle; its x and y are where the point is drawn.
		@param origin  The point it turns about, from its top-left corner.
		@param rotation  The turn, in degrees clockwise.
		@param color  The color. */
	static function DrawRectanglePro(rec:Rectangle, origin:Vector2, rotation:Float, color:Color):Void {
		// The corners from the top-left one counterclockwise, as raylib's quad takes them, before and after turning about the origin.
		var xs = [-origin.x, -origin.x, rec.width - origin.x, rec.width - origin.x];
		var ys = [-origin.y, rec.height - origin.y, rec.height - origin.y, -origin.y];
		var s = rotation == 0 ? 0 : Math.sin(rotation * DEG2RAD),
			c = rotation == 0 ? 1 : Math.cos(rotation * DEG2RAD);
		for (k in 0...4)
			corner(rec.x + xs[k] * c - ys[k] * s, rec.y + xs[k] * s + ys[k] * c, k, color);
	}

	/** Draws a filled rectangle that blends from one color at its top to another at its bottom.

		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width.
		@param height  The height.
		@param top  The color at the top.
		@param bottom  The color at the bottom. */
	static function DrawRectangleGradientV(posX:Int, posY:Int, width:Int, height:Int, top:Color, bottom:Color):Void {
		DrawRectangleGradientEx(new Rectangle(posX, posY, width, height), top, bottom, bottom, top);
	}

	/** Draws a filled rectangle that blends from one color at its left to another at its right.

		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width.
		@param height  The height.
		@param left  The color at the left.
		@param right  The color at the right. */
	static function DrawRectangleGradientH(posX:Int, posY:Int, width:Int, height:Int, left:Color, right:Color):Void {
		DrawRectangleGradientEx(new Rectangle(posX, posY, width, height), left, left, right, right);
	}

	/** Draws a filled rectangle that blends between a color at each corner. As in raylib 5.5, `topRight` colors the bottom-right corner
		and `bottomRight` the top-right one.

		@param rec  The rectangle.
		@param topLeft  The top-left corner's color.
		@param bottomLeft  The bottom-left corner's color.
		@param topRight  The bottom-right corner's color.
		@param bottomRight  The top-right corner's color. */
	static function DrawRectangleGradientEx(rec:Rectangle, topLeft:Color, bottomLeft:Color, topRight:Color, bottomRight:Color):Void {
		corner(rec.x, rec.y, 0, topLeft);
		corner(rec.x, rec.y + rec.height, 1, bottomLeft);
		corner(rec.x + rec.width, rec.y + rec.height, 2, topRight);
		corner(rec.x + rec.width, rec.y, 3, bottomRight);
	}

	/** Draws a rectangle's outline, one pixel wide.

		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	static function DrawRectangleLines(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void {
		frame(posX, posY, width, height, 1, color);
	}

	/** Draws a rectangle's outline, its lines inside it.

		@param rec  The rectangle.
		@param lineThick  The lines' thickness.
		@param color  The color. */
	static function DrawRectangleLinesEx(rec:Rectangle, lineThick:Float, color:Color):Void {
		frame(rec.x, rec.y, rec.width, rec.height, lineThick, color);
	}

	/** Draws a filled rectangle with rounded corners.

		@param rec  The rectangle.
		@param roundness  How round its corners are: 0 for square, 1 for a radius of half its shorter side.
		@param segments  How many straight edges make each corner's curve; fewer than 4 picks enough for a smooth curve.
		@param color  The color. */
	static function DrawRectangleRounded(rec:Rectangle, roundness:Float, segments:Int, color:Color):Void {
		if (roundness <= 0 || rec.width < 1 || rec.height < 1) {
			DrawRectangleRec(rec, color);
			return;
		}
		if (roundness >= 1)
			roundness = 1;
		var radius = rec.width > rec.height ? rec.height * roundness / 2 : rec.width * roundness / 2;
		if (radius <= 0)
			return;
		if (segments < 4) {
			segments = Std.int(Math.ceil(2 * Math.PI / smoothAngle(radius)) / 4);
			if (segments <= 0)
				segments = 4;
		}
		var step = 90 / segments;
		var x = rec.x, y = rec.y, r = rec.x + rec.width, b = rec.y + rec.height;
		// The twelve points of raylib's sketch: P0 to P7 around the edge from the top's left end, P8 to P11 the corners' centers.
		var px = [
			x + radius,
			r - radius,
			r,
			r,
			r - radius,
			x + radius,
			x,
			x,
			x + radius,
			r - radius,
			r - radius,
			x + radius
		];
		var py = [
			y,
			y,
			y + radius,
			b - radius,
			b,
			b,
			b - radius,
			y + radius,
			y + radius,
			y + radius,
			b - radius,
			b - radius
		];
		for (k in 0...4) {
			var angle = CORNER_ANGLES[k], cx = px[8 + k], cy = py[8 + k];
			for (i in 0...Std.int(segments / 2)) {
				corner(cx, cy, 0, color);
				corner(arcX(cx, angle + step * 2, radius), arcY(cy, angle + step * 2, radius), 3, color);
				corner(arcX(cx, angle + step, radius), arcY(cy, angle + step, radius), 2, color);
				corner(arcX(cx, angle, radius), arcY(cy, angle, radius), 1, color);
				angle += step * 2;
			}
			if (segments % 2 == 1) {
				corner(cx, cy, 0, color);
				corner(arcX(cx, angle + step, radius), arcY(cy, angle + step, radius), 2, color);
				corner(arcX(cx, angle, radius), arcY(cy, angle, radius), 1, color);
				corner(cx, cy, 3, color);
			}
		}
		for (i => p in [0, 8, 9, 1, 2, 9, 10, 3, 11, 5, 4, 10, 7, 6, 11, 8, 8, 11, 10, 9])
			corner(px[p], py[p], i % 4, color);
	}

	/** Draws a rounded rectangle's outline, one pixel wide.

		@param rec  The rectangle.
		@param roundness  How round its corners are: 0 for square, 1 for a radius of half its shorter side.
		@param segments  How many straight edges make each corner's curve; fewer than 4 picks enough for a smooth curve.
		@param color  The color. */
	static function DrawRectangleRoundedLines(rec:Rectangle, roundness:Float, segments:Int, color:Color):Void {
		DrawRectangleRoundedLinesEx(rec, roundness, segments, 1, color);
	}

	/** Draws a rounded rectangle's outline, its lines outside it.

		@param rec  The rectangle.
		@param roundness  How round its corners are: 0 for square, 1 for a radius of half its shorter side.
		@param segments  How many straight edges make each corner's curve; fewer than 4 picks enough for a smooth curve.
		@param lineThick  The lines' thickness; 1 or less draws them one pixel wide.
		@param color  The color. */
	static function DrawRectangleRoundedLinesEx(rec:Rectangle, roundness:Float, segments:Int, lineThick:Float, color:Color):Void {
		if (lineThick < 0)
			lineThick = 0;
		if (roundness <= 0) {
			DrawRectangleLinesEx(new Rectangle(rec.x - lineThick, rec.y - lineThick, rec.width + 2 * lineThick, rec.height + 2 * lineThick), lineThick, color);
			return;
		}
		if (roundness >= 1)
			roundness = 1;
		var radius = rec.width > rec.height ? rec.height * roundness / 2 : rec.width * roundness / 2;
		if (radius <= 0)
			return;
		if (segments < 4) {
			segments = Std.int(Math.ceil(2 * Math.PI / smoothAngle(radius)) / 2);
			if (segments <= 0)
				segments = 4;
		}
		var step = 90 / segments, outer = radius + lineThick, inner = radius;
		var x = rec.x, y = rec.y, r = rec.x + rec.width, b = rec.y + rec.height, t = lineThick;
		// The sixteen points of raylib's sketch: P0 to P7 around the outer edge from the top's left end, P8 to P15 the inner edge's.
		var px = [
			x + inner, r - inner, r + t, r + t, r - inner, x + inner, x - t, x - t,
			x + inner, r - inner,     r,     r, r - inner, x + inner,     x,     x
		];
		var py = [
			y - t, y - t, y + inner, b - inner, b + t, b + t, b - inner, y + inner,
			    y,     y, y + inner, b - inner,     b,     b, b - inner, y + inner
		];
		var centersX = [x + inner, r - inner, r - inner, x + inner],
			centersY = [y + inner, y + inner, b - inner, b - inner];
		if (lineThick > 1) {
			for (k in 0...4) {
				var angle = CORNER_ANGLES[k],
					cx = centersX[k],
					cy = centersY[k];
				for (i in 0...segments) {
					corner(arcX(cx, angle, inner), arcY(cy, angle, inner), 0, color);
					corner(arcX(cx, angle + step, inner), arcY(cy, angle + step, inner), 3, color);
					corner(arcX(cx, angle + step, outer), arcY(cy, angle + step, outer), 2, color);
					corner(arcX(cx, angle, outer), arcY(cy, angle, outer), 1, color);
					angle += step;
				}
			}
			for (i => p in [0, 8, 9, 1, 2, 10, 11, 3, 13, 5, 4, 12, 15, 7, 6, 14])
				corner(px[p], py[p], i % 4, color);
		} else {
			for (k in 0...4) {
				var angle = CORNER_ANGLES[k],
					cx = centersX[k],
					cy = centersY[k];
				for (i in 0...segments) {
					line(arcX(cx, angle, outer), arcY(cy, angle, outer), arcX(cx, angle + step, outer), arcY(cy, angle + step, outer), 1, color);
					angle += step;
				}
			}
			var i = 0;
			while (i < 8) {
				line(px[i], py[i], px[i + 1], py[i + 1], 1, color);
				i += 2;
			}
		}
	}

	/** Draws a filled triangle; its points go counterclockwise, as raylib's do.

		@param v1  The first point.
		@param v2  The second point.
		@param v3  The third point.
		@param color  The color. */
	static function DrawTriangle(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void {
		corner(v1.x, v1.y, 0, color);
		corner(v2.x, v2.y, 1, color);
		corner(v2.x, v2.y, 2, color);
		corner(v3.x, v3.y, 3, color);
	}

	/** Draws a triangle's outline, one pixel wide.

		@param v1  The first point.
		@param v2  The second point.
		@param v3  The third point.
		@param color  The color. */
	static function DrawTriangleLines(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void {
		line(v1.x, v1.y, v2.x, v2.y, 1, color);
		line(v2.x, v2.y, v3.x, v3.y, 1, color);
		line(v3.x, v3.y, v1.x, v1.y, 1, color);
	}

	/** Draws filled triangles that all share the first point, each from it to the next two points; they go counterclockwise.

		@param points  The points, the shared one first.
		@param pointCount  How many of them to draw, 3 or more.
		@param color  The color. */
	static function DrawTriangleFan(points:Array<Vector2>, pointCount:Int, color:Color):Void {
		if (pointCount < 3)
			return;
		for (i in 1...pointCount - 1) {
			corner(points[0].x, points[0].y, 0, color);
			corner(points[i].x, points[i].y, 1, color);
			corner(points[i + 1].x, points[i + 1].y, 2, color);
			corner(points[i + 1].x, points[i + 1].y, 3, color);
		}
	}

	/** Draws filled triangles, each from a point to the two before it.

		@param points  The points.
		@param pointCount  How many of them to draw, 3 or more.
		@param color  The color. */
	static function DrawTriangleStrip(points:Array<Vector2>, pointCount:Int, color:Color):Void {
		if (pointCount < 3)
			return;
		var t = Runtime.frame.white;
		for (i in 2...pointCount) {
			var a = points[i], b = points[i % 2 == 0 ? i - 2 : i - 1], c = points[i % 2 == 0 ? i - 1 : i - 2];
			flat(t, a.x, a.y, 0, 0, color);
			flat(t, b.x, b.y, 0, 0, color);
			flat(t, c.x, c.y, 0, 0, color);
		}
	}

	/** Draws a filled regular polygon.

		@param center  The center.
		@param sides  How many sides it has, 3 or more.
		@param radius  The distance from the center to each corner.
		@param rotation  The turn of its first corner from the right, in degrees clockwise.
		@param color  The color. */
	static function DrawPoly(center:Vector2, sides:Int, radius:Float, rotation:Float, color:Color):Void {
		if (sides < 3)
			sides = 3;
		var angle = rotation * DEG2RAD, step = 360 / sides * DEG2RAD;
		for (i in 0...sides) {
			var next = angle + step;
			corner(center.x, center.y, 0, color);
			corner(center.x + Math.cos(angle) * radius, center.y + Math.sin(angle) * radius, 1, color);
			corner(center.x + Math.cos(next) * radius, center.y + Math.sin(next) * radius, 3, color);
			corner(center.x + Math.cos(angle) * radius, center.y + Math.sin(angle) * radius, 2, color);
			angle = next;
		}
	}

	/** Draws a regular polygon's outline, one pixel wide.

		@param center  The center.
		@param sides  How many sides it has, 3 or more.
		@param radius  The distance from the center to each corner.
		@param rotation  The turn of its first corner from the right, in degrees clockwise.
		@param color  The color. */
	static function DrawPolyLines(center:Vector2, sides:Int, radius:Float, rotation:Float, color:Color):Void {
		if (sides < 3)
			sides = 3;
		var angle = rotation * DEG2RAD, step = 360 / sides * DEG2RAD;
		for (i in 0...sides) {
			line(center.x
				+ Math.cos(angle) * radius, center.y
				+ Math.sin(angle) * radius, center.x
				+ Math.cos(angle + step) * radius,
				center.y
				+ Math.sin(angle + step) * radius, 1, color);
			angle += step;
		}
	}

	/** Draws a regular polygon's outline, its lines inside it.

		@param center  The center.
		@param sides  How many sides it has, 3 or more.
		@param radius  The distance from the center to each corner.
		@param rotation  The turn of its first corner from the right, in degrees clockwise.
		@param lineThick  The lines' thickness.
		@param color  The color. */
	static function DrawPolyLinesEx(center:Vector2, sides:Int, radius:Float, rotation:Float, lineThick:Float, color:Color):Void {
		if (sides < 3)
			sides = 3;
		var angle = rotation * DEG2RAD, step = 360 / sides * DEG2RAD;
		// As raylib's: the step is already in radians, and is turned into radians again.
		var inner = radius - lineThick * Math.cos(DEG2RAD * step / 2);
		var cx = center.x, cy = center.y;
		for (i in 0...sides) {
			var next = angle + step;
			corner(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius, 1, color);
			corner(cx + Math.cos(angle) * inner, cy + Math.sin(angle) * inner, 0, color);
			corner(cx + Math.cos(next) * inner, cy + Math.sin(next) * inner, 2, color);
			corner(cx + Math.cos(next) * radius, cy + Math.sin(next) * radius, 3, color);
			angle = next;
		}
	}

	// ---- Splines ----

	/** Draws straight lines of a thickness from each point to the next.

		@param points  The points.
		@param pointCount  How many of them to draw through, 2 or more.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineLinear(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void {
		if (pointCount < 2)
			return;
		var scale = 0.;
		for (i in 0...pointCount - 1) {
			var dx = points[i + 1].x - points[i].x,
				dy = points[i + 1].y - points[i].y,
				length = Math.sqrt(dx * dx + dy * dy);
			if (length > 0)
				scale = thick / (2 * length);
			band(points[i], points[i + 1], -scale * dy, scale * dx, color);
		}
	}

	/** Draws a B-spline of a thickness through points, with round ends; it passes near the points rather than through them.

		@param points  The points.
		@param pointCount  How many of them to draw through, 4 or more.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineBasis(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void {
		if (pointCount < 4)
			return;
		var dx = 0., dy = 0., size = 0.;
		var current = new Vector2();
		var vertices = [for (i in 0...2 * SPLINE_SEGMENT_DIVISIONS + 2) new Vector2()];
		for (i in 0...pointCount - 3) {
			var p1 = points[i],
				p2 = points[i + 1],
				p3 = points[i + 2],
				p4 = points[i + 3];
			current = GetSplinePointBasis(p1, p2, p3, p4, 0);
			if (i == 0)
				DrawCircleV(current, thick / 2, color);
			if (i > 0) {
				vertices[0].x = current.x + dy * size;
				vertices[0].y = current.y - dx * size;
				vertices[1].x = current.x - dy * size;
				vertices[1].y = current.y + dx * size;
			}
			for (j in 1...SPLINE_SEGMENT_DIVISIONS + 1) {
				var t = j / SPLINE_SEGMENT_DIVISIONS;
				var next = GetSplinePointBasis(p1, p2, p3, p4, t);
				dy = next.y - current.y;
				dx = next.x - current.x;
				size = .5 * thick / Math.sqrt(dx * dx + dy * dy);
				if (i == 0 && j == 1) {
					vertices[0].x = current.x + dy * size;
					vertices[0].y = current.y - dx * size;
					vertices[1].x = current.x - dy * size;
					vertices[1].y = current.y + dx * size;
				}
				vertices[2 * j + 1].x = next.x - dy * size;
				vertices[2 * j + 1].y = next.y + dx * size;
				vertices[2 * j].x = next.x + dy * size;
				vertices[2 * j].y = next.y - dx * size;
				current = next;
			}
			DrawTriangleStrip(vertices, vertices.length, color);
		}
		DrawCircleV(current, thick / 2, color);
	}

	/** Draws a Catmull-Rom spline of a thickness through points, with round ends; it passes through all but the first and last, which
		only steer it.

		@param points  The points.
		@param pointCount  How many of them to draw through, 4 or more.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineCatmullRom(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void {
		if (pointCount < 4)
			return;
		var dx = 0., dy = 0., size = 0.;
		var current = points[1];
		var vertices = [for (i in 0...2 * SPLINE_SEGMENT_DIVISIONS + 2) new Vector2()];
		DrawCircleV(current, thick / 2, color);
		for (i in 0...pointCount - 3) {
			var p1 = points[i],
				p2 = points[i + 1],
				p3 = points[i + 2],
				p4 = points[i + 3];
			if (i > 0) {
				vertices[0].x = current.x + dy * size;
				vertices[0].y = current.y - dx * size;
				vertices[1].x = current.x - dy * size;
				vertices[1].y = current.y + dx * size;
			}
			for (j in 1...SPLINE_SEGMENT_DIVISIONS + 1) {
				var next = GetSplinePointCatmullRom(p1, p2, p3, p4, j / SPLINE_SEGMENT_DIVISIONS);
				dy = next.y - current.y;
				dx = next.x - current.x;
				size = .5 * thick / Math.sqrt(dx * dx + dy * dy);
				if (i == 0 && j == 1) {
					vertices[0].x = current.x + dy * size;
					vertices[0].y = current.y - dx * size;
					vertices[1].x = current.x - dy * size;
					vertices[1].y = current.y + dx * size;
				}
				vertices[2 * j + 1].x = next.x - dy * size;
				vertices[2 * j + 1].y = next.y + dx * size;
				vertices[2 * j].x = next.x + dy * size;
				vertices[2 * j].y = next.y - dx * size;
				current = next;
			}
			DrawTriangleStrip(vertices, vertices.length, color);
		}
		DrawCircleV(current, thick / 2, color);
	}

	/** Draws quadratic Bezier curves of a thickness, one after another: points, then a control point between each two.

		@param points  The points: start, control, end, then a control and an end for each further curve.
		@param pointCount  How many of them to draw through, 3 or more.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineBezierQuadratic(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void {
		if (pointCount < 3)
			return;
		var i = 0;
		while (i < pointCount - 2) {
			DrawSplineSegmentBezierQuadratic(points[i], points[i + 1], points[i + 2], thick, color);
			i += 2;
		}
	}

	/** Draws cubic Bezier curves of a thickness, one after another: points, then two control points between each two.

		@param points  The points: start, two controls, end, then two controls and an end for each further curve.
		@param pointCount  How many of them to draw through, 4 or more.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineBezierCubic(points:Array<Vector2>, pointCount:Int, thick:Float, color:Color):Void {
		if (pointCount < 4)
			return;
		var i = 0;
		while (i < pointCount - 3) {
			DrawSplineSegmentBezierCubic(points[i], points[i + 1], points[i + 2], points[i + 3], thick, color);
			i += 3;
		}
	}

	/** Draws a straight line of a thickness.

		@param p1  The start.
		@param p2  The end.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineSegmentLinear(p1:Vector2, p2:Vector2, thick:Float, color:Color):Void {
		var dx = p2.x - p1.x,
			dy = p2.y - p1.y,
			length = Math.sqrt(dx * dx + dy * dy);
		if (length > 0 && thick > 0) {
			var scale = thick / (2 * length);
			band(p1, p2, -scale * dy, scale * dx, color);
		}
	}

	/** Draws one piece of a B-spline of a thickness, between the middle two of four points.

		@param p1  The first point.
		@param p2  The second.
		@param p3  The third.
		@param p4  The fourth.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineSegmentBasis(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, thick:Float, color:Color):Void {
		segment(GetSplinePointBasis(p1, p2, p3, p4, 0), t -> GetSplinePointBasis(p1, p2, p3, p4, t), 0, thick, color);
	}

	/** Draws one piece of a Catmull-Rom spline of a thickness, through the middle two of four points.

		@param p1  The first point, which steers it.
		@param p2  The start.
		@param p3  The end.
		@param p4  The fourth point, which steers it.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineSegmentCatmullRom(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, thick:Float, color:Color):Void {
		segment(p1, t -> GetSplinePointCatmullRom(p1, p2, p3, p4, t), 0, thick, color);
	}

	/** Draws a quadratic Bezier curve of a thickness.

		@param p1  The start.
		@param c2  The control point.
		@param p3  The end.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineSegmentBezierQuadratic(p1:Vector2, c2:Vector2, p3:Vector2, thick:Float, color:Color):Void {
		segment(p1, t -> GetSplinePointBezierQuad(p1, c2, p3, t), 1, thick, color);
	}

	/** Draws a cubic Bezier curve of a thickness.

		@param p1  The start.
		@param c2  The start's control point.
		@param c3  The end's control point.
		@param p4  The end.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineSegmentBezierCubic(p1:Vector2, c2:Vector2, c3:Vector2, p4:Vector2, thick:Float, color:Color):Void {
		segment(p1, t -> GetSplinePointBezierCubic(p1, c2, c3, p4, t), 1, thick, color);
	}

	/** Returns a point on a straight line.

		@param startPos  The start.
		@param endPos  The end.
		@param t  How far along, 0 at the start to 1 at the end.
		@return  The point. */
	static function GetSplinePointLinear(startPos:Vector2, endPos:Vector2, t:Float):Vector2 {
		return new Vector2(startPos.x * (1 - t) + endPos.x * t, startPos.y * (1 - t) + endPos.y * t);
	}

	/** Returns a point on one piece of a B-spline, between the middle two of four points.

		@param p1  The first point.
		@param p2  The second.
		@param p3  The third.
		@param p4  The fourth.
		@param t  How far along, 0 at the start to 1 at the end.
		@return  The point. */
	static function GetSplinePointBasis(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, t:Float):Vector2 {
		return new Vector2(Interpolate.bSpline(p1.x, p2.x, p3.x, p4.x, t), Interpolate.bSpline(p1.y, p2.y, p3.y, p4.y, t));
	}

	/** Returns a point on one piece of a Catmull-Rom spline, through the middle two of four points.

		@param p1  The first point, which steers it.
		@param p2  The start.
		@param p3  The end.
		@param p4  The fourth point, which steers it.
		@param t  How far along, 0 at the start to 1 at the end.
		@return  The point. */
	static function GetSplinePointCatmullRom(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, t:Float):Vector2 {
		return new Vector2(Interpolate.catmullRom(p1.x, p2.x, p3.x, p4.x, t), Interpolate.catmullRom(p1.y, p2.y, p3.y, p4.y, t));
	}

	/** Returns a point on a quadratic Bezier curve.

		@param p1  The start.
		@param c2  The control point.
		@param p3  The end.
		@param t  How far along, 0 at the start to 1 at the end.
		@return  The point. */
	static function GetSplinePointBezierQuad(p1:Vector2, c2:Vector2, p3:Vector2, t:Float):Vector2 {
		return new Vector2(Interpolate.quadraticBezier(p1.x, c2.x, p3.x, t), Interpolate.quadraticBezier(p1.y, c2.y, p3.y, t));
	}

	/** Returns a point on a cubic Bezier curve.

		@param p1  The start.
		@param c2  The start's control point.
		@param c3  The end's control point.
		@param p4  The end.
		@param t  How far along, 0 at the start to 1 at the end.
		@return  The point. */
	static function GetSplinePointBezierCubic(p1:Vector2, c2:Vector2, c3:Vector2, p4:Vector2, t:Float):Vector2 {
		return new Vector2(Interpolate.cubicBezier(p1.x, c2.x, c3.x, p4.x, t), Interpolate.cubicBezier(p1.y, c2.y, c3.y, p4.y, t));
	}

	// ---- Collisions ----

	/** Returns whether two rectangles overlap.

		@param rec1  One rectangle.
		@param rec2  The other.
		@return  True when they overlap. */
	static function CheckCollisionRecs(rec1:Rectangle, rec2:Rectangle):Bool {
		return rec1.x < rec2.x + rec2.width && rec1.x + rec1.width > rec2.x && rec1.y < rec2.y + rec2.height && rec1.y + rec1.height > rec2.y;
	}

	/** Returns whether two circles overlap.

		@param center1  One circle's center.
		@param radius1  Its radius.
		@param center2  The other's center.
		@param radius2  Its radius.
		@return  True when they overlap. */
	static function CheckCollisionCircles(center1:Vector2, radius1:Float, center2:Vector2, radius2:Float):Bool {
		var dx = center2.x - center1.x, dy = center2.y - center1.y;
		return dx * dx + dy * dy <= (radius1 + radius2) * (radius1 + radius2);
	}

	/** Returns whether a circle and a rectangle overlap.

		@param center  The circle's center.
		@param radius  Its radius.
		@param rec  The rectangle.
		@return  True when they overlap. */
	static function CheckCollisionCircleRec(center:Vector2, radius:Float, rec:Rectangle):Bool {
		var x = Math.max(rec.x, Math.min(center.x, rec.x + rec.width)),
			y = Math.max(rec.y, Math.min(center.y, rec.y + rec.height));
		var dx = center.x - x, dy = center.y - y;
		return dx * dx + dy * dy <= radius * radius;
	}

	/** Returns whether a circle and a line between two points touch.

		@param center  The circle's center.
		@param radius  Its radius.
		@param p1  The line's start.
		@param p2  Its end.
		@return  True when they touch. */
	static function CheckCollisionCircleLine(center:Vector2, radius:Float, p1:Vector2, p2:Vector2):Bool {
		return Geometry2D.intersectsCircleSegment(center.x, center.y, radius, p1.x, p1.y, p2.x, p2.y);
	}

	/** Returns whether a point is inside a rectangle.

		@param point  The point.
		@param rec  The rectangle.
		@return  True when it is inside. */
	static function CheckCollisionPointRec(point:Vector2, rec:Rectangle):Bool {
		return point.x >= rec.x && point.x < rec.x + rec.width && point.y >= rec.y && point.y < rec.y + rec.height;
	}

	/** Returns whether a point is inside a circle.

		@param point  The point.
		@param center  The circle's center.
		@param radius  Its radius.
		@return  True when it is inside. */
	static function CheckCollisionPointCircle(point:Vector2, center:Vector2, radius:Float):Bool {
		return CheckCollisionCircles(point, 0, center, radius);
	}

	/** Returns whether a point is inside a triangle; a point on its edge isn't.

		@param point  The point.
		@param p1  The triangle's first point.
		@param p2  Its second.
		@param p3  Its third.
		@return  True when it is inside. */
	static function CheckCollisionPointTriangle(point:Vector2, p1:Vector2, p2:Vector2, p3:Vector2):Bool {
		return Geometry2D.isPointInTriangle(point.x, point.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
	}

	/** Returns whether a point is on a line between two points, within a margin.

		@param point  The point.
		@param p1  The line's start.
		@param p2  Its end.
		@param threshold  How far from the line the point may be, in pixels.
		@return  True when it is on it. */
	static function CheckCollisionPointLine(point:Vector2, p1:Vector2, p2:Vector2, threshold:Int):Bool {
		var dxc = point.x - p1.x,
			dyc = point.y - p1.y,
			dxl = p2.x - p1.x,
			dyl = p2.y - p1.y;
		var cross = dxc * dyl - dyc * dxl;
		if (Math.abs(cross) >= threshold * Math.max(Math.abs(dxl), Math.abs(dyl)))
			return false;
		if (Math.abs(dxl) >= Math.abs(dyl))
			return dxl > 0 ? p1.x <= point.x && point.x <= p2.x : p2.x <= point.x && point.x <= p1.x;
		return dyl > 0 ? p1.y <= point.y && point.y <= p2.y : p2.y <= point.y && point.y <= p1.y;
	}

	/** Returns whether a point is inside a polygon.

		@param point  The point.
		@param points  The polygon's corners, in order.
		@param pointCount  How many of them it has, 3 or more.
		@return  True when it is inside. */
	static function CheckCollisionPointPoly(point:Vector2, points:Array<Vector2>, pointCount:Int):Bool {
		return Geometry2D.isPointInPolygon(point.x, point.y, [for (i in 0...pointCount) for (axis in [points[i].x, points[i].y]) axis]);
	}

	/** Returns whether two lines, each between two points, cross, and where.

		@param startPos1  One line's start.
		@param endPos1  Its end.
		@param startPos2  The other's start.
		@param endPos2  Its end.
		@param collisionPoint  Set to where they cross, when they do; null leaves it out.
		@return  True when they cross. */
	static function CheckCollisionLines(startPos1:Vector2, endPos1:Vector2, startPos2:Vector2, endPos2:Vector2, collisionPoint:Vector2):Bool {
		var at = new Point2D();
		if (!Geometry2D.intersectSegments(startPos1.x, startPos1.y, endPos1.x, endPos1.y, startPos2.x, startPos2.y, endPos2.x, endPos2.y, at))
			return false;
		if (collisionPoint != null) {
			collisionPoint.x = at.x;
			collisionPoint.y = at.y;
		}
		return true;
	}

	/** Returns where two rectangles overlap.

		@param rec1  One rectangle.
		@param rec2  The other.
		@return  The overlap, or an empty rectangle at 0, 0 when they don't. */
	static function GetCollisionRec(rec1:Rectangle, rec2:Rectangle):Rectangle {
		var overlap = new Bounds2D().set(rec1.x, rec1.y, rec1.x + rec1.width, rec1.y + rec1.height)
			.intersection(new Bounds2D().set(rec2.x, rec2.y, rec2.x + rec2.width, rec2.y + rec2.height));
		// raylib's: rectangles that only touch don't overlap.
		return overlap.width > 0
			&& overlap.height > 0 ? new Rectangle(overlap.minX, overlap.minY, overlap.width, overlap.height) : new Rectangle();
	}

	// ---- What the shapes share ----
	// The texture the filled shapes draw with and the part of it, as raylib's texShapes and texShapesRec: null for the frame's white
	// pixel, which `GetShapesTexture` wraps as a texture when asked. The part's corners are kept as texture coordinates.
	static var texShapes:Null<Texture2D> = null;
	static var texShapesRec = new Rectangle(0, 0, 1, 1);
	static var whiteTexture:Null<Texture2D> = null;
	static var shapeU0 = 0.;
	static var shapeV0 = 0.;
	static var shapeU1 = 1.;
	static var shapeV1 = 1.;
	// raylib's SPLINE_SEGMENT_DIVISIONS and the angles its rounded rectangles' corners start at.
	static inline final SPLINE_SEGMENT_DIVISIONS = 24;
	static final CORNER_ANGLES = [180., 270., 0., 90.];
	// raylib's RL_QUADS: each corner is held until its quad's fourth comes, and the quad is drawn as two triangles, 0 1 2 and 0 2 3.
	static final quadX = [0., 0., 0., 0.];
	static final quadY = [0., 0., 0., 0.];
	static final quadK = [0, 0, 0, 0];
	static final quadColors:Array<Color> = [null, null, null, null];
	static var quadCorners = 0;

	static function shapesTexture():Int {
		return texShapes == null ? Runtime.frame.white : Textures.handle(texShapes.id);
	}

	// A vertex of a filled shape, at one of its part of the shapes texture's corners: 0 top-left, 1 bottom-left, 2 bottom-right, 3 top-right.
	static function shapeVertex(texture:Int, x:Float, y:Float, k:Int, color:Color):Void {
		flat(texture, x, y, k == 2 || k == 3 ? shapeU1 : shapeU0, k == 1 || k == 2 ? shapeV1 : shapeV0, color);
	}

	// A corner of one of raylib's quads, k the shapes texture's corner it is given.
	static function corner(x:Float, y:Float, k:Int, color:Color):Void {
		var n = quadCorners;
		quadX[n] = x;
		quadY[n] = y;
		quadK[n] = k;
		quadColors[n] = color;
		if (n < 3) {
			quadCorners = n + 1;
			return;
		}
		quadCorners = 0;
		var t = shapesTexture();
		for (i in [0, 1, 2, 0, 2, 3])
			shapeVertex(t, quadX[i], quadY[i], quadK[i], quadColors[i]);
	}

	// A point on a circle about a center, at an angle in degrees.
	static inline function arcX(cx:Float, angle:Float, radius:Float):Float {
		return cx + Math.cos(DEG2RAD * angle) * radius;
	}

	static inline function arcY(cy:Float, angle:Float, radius:Float):Float {
		return cy + Math.sin(DEG2RAD * angle) * radius;
	}

	// The widest angle between an arc's segments that keeps it within raylib's SMOOTH_CIRCLE_ERROR_RATE (half a pixel) of the circle.
	static function smoothAngle(radius:Float):Float {
		return Math.acos(2 * Math.pow(1 - .5 / radius, 2) - 1);
	}

	// How many segments raylib gives an arc: those asked for, unless that is fewer than one for each 90 degrees, when it picks enough
	// to keep within its error rate.
	static function arcSegments(radius:Float, startAngle:Float, endAngle:Float, segments:Int):Int {
		var least = Math.ceil((endAngle - startAngle) / 90);
		if (segments >= least)
			return segments;
		var n = Std.int((endAngle - startAngle) * Math.ceil(2 * Math.PI / smoothAngle(radius)) / 360);
		return n <= 0 ? least : n;
	}

	// A straight piece of a line, as raylib's four-point triangle strips: from a to b, r its half-thickness across.
	static function band(a:Vector2, b:Vector2, rx:Float, ry:Float, color:Color):Void {
		DrawTriangleStrip([
			new Vector2(a.x - rx, a.y - ry),
			new Vector2(a.x + rx, a.y + ry),
			new Vector2(b.x - rx, b.y - ry),
			new Vector2(b.x + rx, b.y + ry)
		], 4, color);
	}

	// A curved piece of a spline of a thickness, as raylib draws each: a strip along the curve from where it starts, through the point
	// at each twenty-fourth of the way. The Bezier curves start at the first division, the B-spline and Catmull-Rom at the start itself.
	static function segment(start:Vector2, at:Float->Vector2, first:Int, thick:Float, color:Color):Void {
		var points = [for (i in 0...2 * SPLINE_SEGMENT_DIVISIONS + 2) new Vector2()];
		var current = start;
		for (i in first...SPLINE_SEGMENT_DIVISIONS + 1) {
			var next = at(i / SPLINE_SEGMENT_DIVISIONS);
			var dy = next.y - current.y,
				dx = next.x - current.x,
				size = .5 * thick / Math.sqrt(dx * dx + dy * dy);
			if (i == 1) {
				points[0].x = current.x + dy * size;
				points[0].y = current.y - dx * size;
				points[1].x = current.x - dy * size;
				points[1].y = current.y + dx * size;
			}
			points[2 * i + 1].x = next.x - dy * size;
			points[2 * i + 1].y = next.y + dx * size;
			points[2 * i].x = next.x + dy * size;
			points[2 * i].y = next.y - dx * size;
			current = next;
		}
		DrawTriangleStrip(points, points.length, color);
	}

	// raylib's cubic easing in and out, which DrawLineBezier eases its line's y by.
	static function easeCubicInOut(t:Float, b:Float, c:Float, d:Float):Float {
		t /= .5 * d;
		if (t < 1)
			return .5 * c * t * t * t + b;
		t -= 2;
		return .5 * c * (t * t * t + 2) + b;
	}

	// Whether a crossing is off a line along one axis, as raylib's CheckCollisionLines tests it: a line flat along that axis is never.
	#end
}
