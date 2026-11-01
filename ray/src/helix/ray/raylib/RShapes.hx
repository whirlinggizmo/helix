package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.math.Bounds2D;
import helix.geometry.Geometry2D;
import helix.math.Interpolate;
import helix.math.Vector2D;
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
import helix.ray.Rlgl.*;
import helix.ray.raylib.RRlgl.*;
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
	// As rshapes.c draws them, through rlgl: the same vertices, in the same order, with the same color, normal and texture state. A
	// filled shape is drawn with the shapes texture, as raylib's quads; an outline is drawn with lines one pixel wide.

	/** Draws one pixel.

		@param posX  The x.
		@param posY  The y.
		@param color  The color. */
	static function DrawPixel(posX:Int, posY:Int, color:Color):Void {
		DrawPixelV(new Vector2(posX, posY), color);
	}

	/** Draws one pixel.

		@param position  The position.
		@param color  The color. */
	static function DrawPixelV(position:Vector2, color:Color):Void {
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		rlNormal3f(0, 0, 1);
		rlColor4ub(color.r, color.g, color.b, color.a);
		shapeVertex(shapeU0, shapeV0, position.x, position.y);
		shapeVertex(shapeU0, shapeV1, position.x, position.y + 1);
		shapeVertex(shapeU1, shapeV1, position.x + 1, position.y + 1);
		shapeVertex(shapeU1, shapeV0, position.x + 1, position.y);
		rlEnd();
		rlSetTexture(0);
	}

	/** Draws a line one pixel wide.

		@param startPosX  The start's x.
		@param startPosY  The start's y.
		@param endPosX  The end's x.
		@param endPosY  The end's y.
		@param color  The color. */
	static function DrawLine(startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void {
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		rlVertex2f(startPosX, startPosY);
		rlVertex2f(endPosX, endPosY);
		rlEnd();
	}

	/** Draws a line one pixel wide.

		@param startPos  The start.
		@param endPos  The end.
		@param color  The color. */
	static function DrawLineV(startPos:Vector2, endPos:Vector2, color:Color):Void {
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		rlVertex2f(startPos.x, startPos.y);
		rlVertex2f(endPos.x, endPos.y);
		rlEnd();
	}

	/** Draws a line of a thickness.

		@param startPos  The start.
		@param endPos  The end.
		@param thick  The thickness, in pixels; 0 or less draws nothing.
		@param color  The color. */
	static function DrawLineEx(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void {
		var dx = endPos.x - startPos.x, dy = endPos.y - startPos.y;
		var length = Math.sqrt(dx * dx + dy * dy);
		if (length > 0 && thick > 0) {
			var scale = thick / (2 * length);
			strip(startPos, endPos, -scale * dy, scale * dx, color);
		}
	}

	/** Draws lines one pixel wide from each point to the next.

		@param points  The points.
		@param pointCount  How many of them to draw through, 2 or more.
		@param color  The color. */
	static function DrawLineStrip(points:Array<Vector2>, pointCount:Int, color:Color):Void {
		if (pointCount < 2)
			return;
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		for (i in 0...pointCount - 1) {
			rlVertex2f(points[i].x, points[i].y);
			rlVertex2f(points[i + 1].x, points[i + 1].y);
		}
		rlEnd();
	}

	/** Draws a line of a thickness that eases in and out from start to end, as an S.

		@param startPos  The start.
		@param endPos  The end.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawLineBezier(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void {
		var previousX = startPos.x, previousY = startPos.y;
		var points = [for (i in 0...2 * SPLINE_SEGMENT_DIVISIONS + 2) new Vector2()];
		for (i in 1...SPLINE_SEGMENT_DIVISIONS + 1) {
			// raylib eases the line's y alone, cubically in and out.
			var currentY = easeCubicInOut(i, startPos.y, endPos.y - startPos.y, SPLINE_SEGMENT_DIVISIONS);
			var currentX = previousX + (endPos.x - startPos.x) / SPLINE_SEGMENT_DIVISIONS;
			var dy = currentY - previousY, dx = currentX - previousX;
			var size = .5 * thick / Math.sqrt(dx * dx + dy * dy);
			if (i == 1) {
				points[0].x = previousX + dy * size;
				points[0].y = previousY - dx * size;
				points[1].x = previousX - dy * size;
				points[1].y = previousY + dx * size;
			}
			points[2 * i + 1].x = currentX - dy * size;
			points[2 * i + 1].y = currentY + dx * size;
			points[2 * i].x = currentX + dy * size;
			points[2 * i].y = currentY - dx * size;
			previousX = currentX;
			previousY = currentY;
		}
		DrawTriangleStrip(points, 2 * SPLINE_SEGMENT_DIVISIONS + 2, color);
	}

	/** Draws a dashed line one pixel wide: dashes of a length with gaps of another between them, from the start; the last dash stops at
		the end.

		@param startPos  The start.
		@param endPos  The end.
		@param dashSize  Each dash's length, in pixels; 0 or less, or a line shorter than a dash and a gap, draws the line solid.
		@param spaceSize  Each gap's length, in pixels.
		@param color  The color. */
	static function DrawLineDashed(startPos:Vector2, endPos:Vector2, dashSize:Int, spaceSize:Int, color:Color):Void {
		var dx = endPos.x - startPos.x, dy = endPos.y - startPos.y;
		var lineLength = Math.sqrt(dx * dx + dy * dy);
		if (lineLength < dashSize + spaceSize || dashSize <= 0) {
			DrawLineV(startPos, endPos, color);
			return;
		}
		var invLineLength = 1 / lineLength;
		var dirX = dx * invLineLength, dirY = dy * invLineLength;
		var currentX = startPos.x,
			currentY = startPos.y,
			distanceTraveled = 0.;
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		while (distanceTraveled < lineLength) {
			var dashEndDist = distanceTraveled + dashSize;
			if (dashEndDist > lineLength)
				dashEndDist = lineLength;
			rlVertex2f(currentX, currentY);
			rlVertex2f(startPos.x + dashEndDist * dirX, startPos.y + dashEndDist * dirY);
			distanceTraveled = dashEndDist + spaceSize;
			currentX = startPos.x + distanceTraveled * dirX;
			currentY = startPos.y + distanceTraveled * dirY;
		}
		rlEnd();
	}

	/** Draws a filled circle.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radius  The radius; 0 or less draws nothing.
		@param color  The color. */
	static function DrawCircle(centerX:Int, centerY:Int, radius:Float, color:Color):Void {
		DrawCircleV(new Vector2(centerX, centerY), radius, color);
	}

	/** Draws a filled circle.

		@param center  The center.
		@param radius  The radius; 0 or less draws nothing.
		@param color  The color. */
	static function DrawCircleV(center:Vector2, radius:Float, color:Color):Void {
		DrawCircleSector(center, radius, 0, 360, 36, color);
	}

	/** Draws a filled slice of a circle, clockwise from one angle to another.

		@param center  The center.
		@param radius  The radius; 0 or less draws nothing.
		@param startAngle  The angle it starts at, in degrees from the right.
		@param endAngle  The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
		@param segments  How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
		@param color  The color. */
	static function DrawCircleSector(center:Vector2, radius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void {
		if (startAngle == endAngle || radius <= 0)
			return;
		if (endAngle < startAngle) {
			var t = startAngle;
			startAngle = endAngle;
			endAngle = t;
		}
		if (endAngle - startAngle >= 360)
			endAngle = startAngle + 360;
		segments = arcSegments(radius, startAngle, endAngle, segments);
		var stepLength = (endAngle - startAngle) / segments,
			angle = startAngle;
		var cx = center.x, cy = center.y;
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		// Each quad is two segments.
		for (i in 0...Std.int(segments / 2)) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			shapeVertex(shapeU0, shapeV0, cx, cy);
			shapeVertex(shapeU1, shapeV0, arcX(cx, angle + stepLength * 2, radius), arcY(cy, angle + stepLength * 2, radius));
			shapeVertex(shapeU1, shapeV1, arcX(cx, angle + stepLength, radius), arcY(cy, angle + stepLength, radius));
			shapeVertex(shapeU0, shapeV1, arcX(cx, angle, radius), arcY(cy, angle, radius));
			angle += stepLength * 2;
		}
		// An odd segment left over is a quad of its own, its last corner the center again.
		if (segments % 2 == 1) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			shapeVertex(shapeU0, shapeV0, cx, cy);
			shapeVertex(shapeU1, shapeV1, arcX(cx, angle + stepLength, radius), arcY(cy, angle + stepLength, radius));
			shapeVertex(shapeU0, shapeV1, arcX(cx, angle, radius), arcY(cy, angle, radius));
			shapeVertex(shapeU1, shapeV0, cx, cy);
		}
		rlEnd();
		rlSetTexture(0);
	}

	/** Draws a slice of a circle's outline, one pixel wide, with lines from the center to its ends; a whole turn has none.

		@param center  The center.
		@param radius  The radius; 0 or less draws nothing.
		@param startAngle  The angle it starts at, in degrees from the right.
		@param endAngle  The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
		@param segments  How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
		@param color  The color. */
	static function DrawCircleSectorLines(center:Vector2, radius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void {
		if (startAngle == endAngle || radius <= 0)
			return;
		if (endAngle < startAngle) {
			var t = startAngle;
			startAngle = endAngle;
			endAngle = t;
		}
		var showCapLines = true;
		if (endAngle - startAngle >= 360) {
			showCapLines = false;
			endAngle = startAngle + 360;
		}
		segments = arcSegments(radius, startAngle, endAngle, segments);
		var stepLength = (endAngle - startAngle) / segments,
			angle = startAngle;
		var cx = center.x, cy = center.y;
		rlBegin(RL_LINES);
		if (showCapLines) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex2f(cx, cy);
			rlVertex2f(arcX(cx, angle, radius), arcY(cy, angle, radius));
		}
		for (i in 0...segments) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex2f(arcX(cx, angle, radius), arcY(cy, angle, radius));
			rlVertex2f(arcX(cx, angle + stepLength, radius), arcY(cy, angle + stepLength, radius));
			angle += stepLength;
		}
		if (showCapLines) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex2f(cx, cy);
			rlVertex2f(arcX(cx, angle, radius), arcY(cy, angle, radius));
		}
		rlEnd();
	}

	/** Draws a slice of a circle's outline of a thickness, inside it, or outside it for a negative thickness, with its edges from the
		center to its ends that thick too; a whole turn drawn outside has none.

		@param center  The center.
		@param radius  The radius; 0 or less draws nothing.
		@param startAngle  The angle it starts at, in degrees from the right.
		@param endAngle  The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
		@param segments  How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
		@param thick  The outline's thickness, measured across its curve's straight edges; one so thick it meets itself fills the slice.
		@param color  The color. */
	static function DrawCircleSectorLinesEx(center:Vector2, radius:Float, startAngle:Float, endAngle:Float, segments:Int, thick:Float, color:Color):Void {
		if (startAngle == endAngle || radius <= 0)
			return;
		if (endAngle < startAngle) {
			var t = startAngle;
			startAngle = endAngle;
			endAngle = t;
		}
		var showCapLines = true;
		if (endAngle - startAngle >= 360) {
			showCapLines = thick >= 0;
			endAngle = startAngle + 360;
		}
		segments = arcSegments(radius, startAngle, endAngle, segments);
		var stepLength = (endAngle - startAngle) / segments,
			angle = startAngle;
		// The curve is a polygon, so the thickness is widened to stay as thick across its straight edges.
		var apothem = radius * Math.cos(DEG2RAD * ((endAngle - startAngle) / 2) / segments);
		var radiusThick = thick * (radius / apothem);
		var outerRadius = radius, innerRadius = radius - radiusThick;
		if (thick >= 0) {
			if (thick >= innerRadius) {
				DrawCircleSector(center, radius, startAngle, endAngle, segments, color);
				return;
			}
		} else {
			var t = outerRadius;
			outerRadius = innerRadius;
			innerRadius = t;
		}
		inline function at(angle:Float, r:Float):Vector2
			return new Vector2(arcX(center.x, angle, r), arcY(center.y, angle, r));
		inline function lerp(a:Vector2, b:Vector2, t:Float):Vector2
			return new Vector2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
		inline function turned(v:Vector2, by:Float):Vector2
			return new Vector2(Math.cos(by) * v.x - Math.sin(by) * v.y, Math.sin(by) * v.x + Math.cos(by) * v.y);
		// The caps' corners, as raylib's sketch names them: C0 to C2 along the start's edge, C3 to C5 along the end's.
		var c0 = new Vector2(),
			c1 = new Vector2(),
			c2 = new Vector2(),
			c3 = new Vector2(),
			c4 = new Vector2(),
			c5 = new Vector2();
		// The steps along the curve before C1 and, when the caps' inner corner S1 is outside the circle, before C0.
		var stepsBeforeC1 = 0, s1OutsideOfCircle = false, stepsBeforeC0 = 0;
		if (showCapLines) {
			if (thick >= 0) {
				c2 = at(startAngle, innerRadius);
				c5 = at(endAngle, innerRadius);
				// C1 and C4 are on the inner edge, the thickness in from the start's and the end's edges.
				var c1Angle = RAD2DEG * Math.asin(thick / innerRadius);
				if (c1Angle / stepLength >= segments) {
					DrawCircleSector(center, radius, startAngle, endAngle, segments, color);
					return;
				}
				stepsBeforeC1 = Std.int(c1Angle / stepLength);
				var vertexAngleBeforeC1 = stepLength * stepsBeforeC1,
					vertexAngleAfterC1 = stepLength * (stepsBeforeC1 + 1);
				var p1 = new Vector2(Math.cos(DEG2RAD * vertexAngleBeforeC1) * innerRadius, Math.sin(DEG2RAD * vertexAngleBeforeC1) * innerRadius);
				var p2 = new Vector2(Math.cos(DEG2RAD * vertexAngleAfterC1) * innerRadius, Math.sin(DEG2RAD * vertexAngleAfterC1) * innerRadius);
				var t = (p1.y - thick) / (p1.y - p2.y);
				c1 = lerp(at(startAngle + vertexAngleBeforeC1, innerRadius), at(startAngle + vertexAngleAfterC1, innerRadius), t);
				c4 = lerp(at(endAngle - vertexAngleBeforeC1, innerRadius), at(endAngle - vertexAngleAfterC1, innerRadius), t);
				// S1, where the caps' inner edges meet, goes out from the center as the slice widens.
				var innerAngleBetweenCapEnds = ((endAngle - 90) - (startAngle + 90)) / 2;
				var s1Length = thick / Math.cos(DEG2RAD * innerAngleBetweenCapEnds);
				if (innerAngleBetweenCapEnds < 90 && s1Length <= innerRadius) {
					c0 = at((endAngle + startAngle) / 2, s1Length);
					c3 = c0;
					p1 = new Vector2(c1.x - center.x, c1.y - center.y);
					p2 = new Vector2(c0.x - center.x, c0.y - center.y);
					var dot = p1.x * p2.x + p1.y * p2.y,
						det = p1.x * p2.y - p1.y * p2.x;
					// C1 and C4 past S1: the caps cover the whole slice.
					if (Math.atan2(det, dot) < 0) {
						DrawCircleSector(center, radius, startAngle, endAngle, segments, color);
						return;
					}
				} else {
					if (endAngle - startAngle <= 180) {
						DrawCircleSector(center, radius, startAngle, endAngle, segments, color);
						return;
					}
					// S1 outside the circle: the caps' inner edges stop at the curve, at C0 and C3.
					s1OutsideOfCircle = true;
					stepsBeforeC0 = Std.int((180 + RAD2DEG * Math.asin(thick / -innerRadius)) / stepLength);
					var vertexAngleBeforeC0 = stepLength * stepsBeforeC0,
						vertexAngleAfterC0 = stepLength * (stepsBeforeC0 + 1);
					p1 = new Vector2(Math.cos(DEG2RAD * vertexAngleBeforeC0) * innerRadius, Math.sin(DEG2RAD * vertexAngleBeforeC0) * innerRadius);
					p2 = new Vector2(Math.cos(DEG2RAD * vertexAngleAfterC0) * innerRadius, Math.sin(DEG2RAD * vertexAngleAfterC0) * innerRadius);
					t = (p1.y - thick) / (p1.y - p2.y);
					c0 = lerp(at(startAngle + vertexAngleBeforeC0, innerRadius), at(startAngle + vertexAngleAfterC0, innerRadius), t);
					c3 = lerp(at(endAngle - vertexAngleBeforeC0, innerRadius), at(endAngle - vertexAngleAfterC0, innerRadius), t);
				}
			} else {
				var outerAngleBetweenCapEnds = ((endAngle + 90) - (startAngle - 90)) / 2;
				var s1Length = thick / Math.cos(DEG2RAD * outerAngleBetweenCapEnds);
				c0 = at(180 + (endAngle + startAngle) / 2, s1Length);
				c3 = c0;
				c2 = at(startAngle, outerRadius);
				c5 = at(endAngle, outerRadius);
				// Turned so the start is at 0 degrees about the center.
				var c0Turned = turned(new Vector2(c0.x - center.x, c0.y - center.y), -DEG2RAD * startAngle);
				var circleVertex1 = turned(new Vector2(c2.x - center.x, c2.y - center.y), -DEG2RAD * startAngle);
				var circleVertex2 = turned(new Vector2(Math.cos(DEG2RAD * (startAngle + stepLength)) * outerRadius,
					Math.sin(DEG2RAD * (startAngle + stepLength)) * outerRadius),
					-DEG2RAD * startAngle);
				// Where the curve's first edge meets the line across from C0.
				var rise = circleVertex1.y - circleVertex2.y,
					run = circleVertex1.x - circleVertex2.x;
				var c1Run = ((c0Turned.y - circleVertex1.y) / rise) * run;
				var c1DistanceFromC0 = (circleVertex1.x + c1Run) - c0Turned.x;
				c1 = new Vector2(c0.x + Math.cos(DEG2RAD * startAngle) * c1DistanceFromC0, c0.y + Math.sin(DEG2RAD * startAngle) * c1DistanceFromC0);
				c4 = new Vector2(c0.x + Math.cos(DEG2RAD * endAngle) * c1DistanceFromC0, c0.y + Math.sin(DEG2RAD * endAngle) * c1DistanceFromC0);
				if (c1DistanceFromC0 < 0) {
					// The caps cross each other: all four meet where the end's first edge crosses C1 to C2.
					var circleVertex3 = turned(new Vector2(c5.x - center.x, c5.y - center.y), -DEG2RAD * startAngle);
					var circleVertex4 = turned(new Vector2(Math.cos(DEG2RAD * (endAngle - stepLength)) * outerRadius,
						Math.sin(DEG2RAD * (endAngle - stepLength)) * outerRadius),
						-DEG2RAD * startAngle);
					var c1Turned = new Vector2(c0Turned.x + c1DistanceFromC0, c0Turned.y);
					circleVertex1 = new Vector2(circleVertex1.x - circleVertex2.x, circleVertex1.y - circleVertex2.y);
					circleVertex3 = new Vector2(circleVertex3.x - circleVertex2.x, circleVertex3.y - circleVertex2.y);
					circleVertex4 = new Vector2(circleVertex4.x - circleVertex2.x, circleVertex4.y - circleVertex2.y);
					c1Turned = new Vector2(c1Turned.x - circleVertex2.x, c1Turned.y - circleVertex2.y);
					var theta = Math.atan2(circleVertex1.y, circleVertex1.x);
					circleVertex1 = turned(circleVertex1, -theta);
					circleVertex3 = turned(circleVertex3, -theta);
					circleVertex4 = turned(circleVertex4, -theta);
					c1Turned = turned(c1Turned, -theta);
					rise = circleVertex3.y - circleVertex4.y;
					run = circleVertex3.x - circleVertex4.x;
					var targetX = circleVertex3.x + (-circleVertex3.y / rise) * run;
					var t = (c1Turned.x - targetX) / (c1Turned.x - circleVertex1.x);
					c1 = lerp(c1, c2, t);
					c4 = c1;
					c0 = c1;
					c3 = c1;
				}
				// Swapped for the winding.
				var temp = c0;
				c0 = c2;
				c2 = temp;
				temp = c3;
				c3 = c5;
				c5 = temp;
			}
		}
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		rlColor4ub(color.r, color.g, color.b, color.a);
		// The curve, then the caps, then what fills between the caps and the curve.
		for (i in 0...segments) {
			outlineQuad(at(angle, outerRadius), at(angle, innerRadius), at(angle + stepLength, innerRadius), at(angle + stepLength, outerRadius));
			angle += stepLength;
		}
		if (showCapLines) {
			outlineQuad(center, c0, c1, c2);
			outlineQuad(center, c5, c4, c3);
			if (thick >= 0) {
				if (stepsBeforeC1 > 0) {
					angle = 0;
					for (i in 0...Std.int(stepsBeforeC1 / 2)) {
						outlineQuad(c1, at(startAngle + (angle + stepLength * 2), innerRadius), at(startAngle + (angle + stepLength), innerRadius),
							at(startAngle + angle, innerRadius));
						outlineQuad(c4, at(endAngle - angle, innerRadius), at(endAngle - (angle + stepLength), innerRadius),
							at(endAngle - (angle + stepLength * 2), innerRadius));
						angle += stepLength * 2;
					}
					if (stepsBeforeC1 % 2 == 1) {
						outlineQuad(c1, c1, at(startAngle + (angle + stepLength), innerRadius), at(startAngle + angle, innerRadius));
						outlineQuad(c4, c4, at(endAngle - angle, innerRadius), at(endAngle - (angle + stepLength), innerRadius));
					}
				}
				if (s1OutsideOfCircle) {
					var verticesBetweenC0andC3 = (segments - stepsBeforeC0 * 2) - 1;
					if (verticesBetweenC0andC3 == 0)
						outlineQuad(center, center, c3, c0);
					else {
						outlineQuad(center, center, at(startAngle + stepLength * (stepsBeforeC0 + 1), innerRadius), c0);
						outlineQuad(center, center, c3, at(endAngle - stepLength * (stepsBeforeC0 + 1), innerRadius));
						verticesBetweenC0andC3 -= 1;
						angle = startAngle + stepLength * (stepsBeforeC0 + 1);
						for (i in 0...Std.int(verticesBetweenC0andC3 / 2)) {
							outlineQuad(center, at(angle + stepLength * 2, innerRadius), at(angle + stepLength, innerRadius), at(angle, innerRadius));
							angle += stepLength * 2;
						}
						if (verticesBetweenC0andC3 % 2 == 1)
							outlineQuad(center, center, at(angle + stepLength, innerRadius), at(angle, innerRadius));
					}
				}
			}
		}
		rlEnd();
		rlSetTexture(0);
	}

	/** Draws a filled circle that blends from one color at its center to another at its edge.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radius  The radius.
		@param inner  The color at the center.
		@param outer  The color at the edge. */
	static function DrawCircleGradient(centerX:Int, centerY:Int, radius:Float, inner:Color, outer:Color):Void {
		rlBegin(RL_TRIANGLES);
		var i = 0;
		while (i < 360) {
			rlColor4ub(inner.r, inner.g, inner.b, inner.a);
			rlVertex2f(centerX, centerY);
			rlColor4ub(outer.r, outer.g, outer.b, outer.a);
			rlVertex2f(arcX(centerX, i + 10, radius), arcY(centerY, i + 10, radius));
			rlColor4ub(outer.r, outer.g, outer.b, outer.a);
			rlVertex2f(arcX(centerX, i, radius), arcY(centerY, i, radius));
			i += 10;
		}
		rlEnd();
	}

	/** Draws a circle's outline, one pixel wide.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radius  The radius.
		@param color  The color. */
	static function DrawCircleLines(centerX:Int, centerY:Int, radius:Float, color:Color):Void {
		DrawCircleLinesV(new Vector2(centerX, centerY), radius, color);
	}

	/** Draws a circle's outline, one pixel wide.

		@param center  The center.
		@param radius  The radius.
		@param color  The color. */
	static function DrawCircleLinesV(center:Vector2, radius:Float, color:Color):Void {
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		// 36 lines, one every 10 degrees.
		var i = 0;
		while (i < 360) {
			rlVertex2f(arcX(center.x, i, radius), arcY(center.y, i, radius));
			rlVertex2f(arcX(center.x, i + 10, radius), arcY(center.y, i + 10, radius));
			i += 10;
		}
		rlEnd();
	}

	/** Draws a circle's outline of a thickness, inside it: a ring of 36 segments from the radius less the thickness to the radius.

		@param center  The center.
		@param radius  The radius.
		@param thick  The thickness; more than the radius draws a filled circle, and a negative one an outline that thick outside it.
		@param color  The color. */
	static function DrawCircleLinesEx(center:Vector2, radius:Float, thick:Float, color:Color):Void {
		DrawRing(center, radius - thick, radius, 0, 360, 36, color);
	}

	/** Draws a filled ellipse.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radiusH  The radius across.
		@param radiusV  The radius up and down.
		@param color  The color. */
	static function DrawEllipse(centerX:Int, centerY:Int, radiusH:Float, radiusV:Float, color:Color):Void {
		DrawEllipseV(new Vector2(centerX, centerY), radiusH, radiusV, color);
	}

	/** Draws a filled ellipse.

		@param center  The center.
		@param radiusH  The radius across.
		@param radiusV  The radius up and down.
		@param color  The color. */
	static function DrawEllipseV(center:Vector2, radiusH:Float, radiusV:Float, color:Color):Void {
		rlBegin(RL_TRIANGLES);
		var i = 0;
		while (i < 360) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex2f(center.x, center.y);
			rlVertex2f(arcX(center.x, i + 10, radiusH), arcY(center.y, i + 10, radiusV));
			rlVertex2f(arcX(center.x, i, radiusH), arcY(center.y, i, radiusV));
			i += 10;
		}
		rlEnd();
	}

	/** Draws an ellipse's outline, one pixel wide.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radiusH  The radius across.
		@param radiusV  The radius up and down.
		@param color  The color. */
	static function DrawEllipseLines(centerX:Int, centerY:Int, radiusH:Float, radiusV:Float, color:Color):Void {
		DrawEllipseLinesV(new Vector2(centerX, centerY), radiusH, radiusV, color);
	}

	/** Draws an ellipse's outline, one pixel wide.

		@param center  The center.
		@param radiusH  The radius across.
		@param radiusV  The radius up and down.
		@param color  The color. */
	static function DrawEllipseLinesV(center:Vector2, radiusH:Float, radiusV:Float, color:Color):Void {
		rlBegin(RL_LINES);
		var i = 0;
		while (i < 360) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex2f(arcX(center.x, i + 10, radiusH), arcY(center.y, i + 10, radiusV));
			rlVertex2f(arcX(center.x, i, radiusH), arcY(center.y, i, radiusV));
			i += 10;
		}
		rlEnd();
	}

	/** Draws an ellipse's outline of a thickness, inside it, or outside it for a negative thickness: 36 segments, each radius less the
		thickness to the radius.

		@param center  The center.
		@param radiusH  The radius across.
		@param radiusV  The radius up and down.
		@param thick  The thickness; as much as either radius draws a filled ellipse.
		@param color  The color. */
	static function DrawEllipseLinesEx(center:Vector2, radiusH:Float, radiusV:Float, thick:Float, color:Color):Void {
		var outerRadiusH = radiusH,
			innerRadiusH = radiusH - thick,
			outerRadiusV = radiusV,
			innerRadiusV = radiusV - thick;
		if (thick >= 0) {
			if (innerRadiusH <= 0 || innerRadiusV <= 0) {
				DrawEllipseV(center, radiusH, radiusV, color);
				return;
			}
		} else {
			var t = outerRadiusH;
			outerRadiusH = innerRadiusH;
			innerRadiusH = t;
			t = outerRadiusV;
			outerRadiusV = innerRadiusV;
			innerRadiusV = t;
		}
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		rlColor4ub(color.r, color.g, color.b, color.a);
		var i = 0;
		while (i < 360) {
			shapeVertex(shapeU0, shapeV0, arcX(center.x, i, innerRadiusH), arcY(center.y, i, innerRadiusV));
			shapeVertex(shapeU0, shapeV1, arcX(center.x, i + 10, innerRadiusH), arcY(center.y, i + 10, innerRadiusV));
			shapeVertex(shapeU1, shapeV1, arcX(center.x, i + 10, outerRadiusH), arcY(center.y, i + 10, outerRadiusV));
			shapeVertex(shapeU1, shapeV0, arcX(center.x, i, outerRadiusH), arcY(center.y, i, outerRadiusV));
			i += 10;
		}
		rlEnd();
		rlSetTexture(0);
	}

	/** Draws a filled ring, or a slice of one, clockwise from one angle to another.

		@param center  The center.
		@param innerRadius  The radius of its hole; 0 or less draws a slice of a circle.
		@param outerRadius  The radius of its edge; the larger of the two is taken as the edge, and an edge of 0 or less draws nothing.
		@param startAngle  The angle it starts at, in degrees from the right.
		@param endAngle  The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
		@param segments  How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
		@param color  The color. */
	static function DrawRing(center:Vector2, innerRadius:Float, outerRadius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void {
		if (startAngle == endAngle)
			return;
		if (outerRadius < innerRadius) {
			var t = outerRadius;
			outerRadius = innerRadius;
			innerRadius = t;
		}
		if (outerRadius <= 0)
			return;
		if (endAngle < startAngle) {
			var t = startAngle;
			startAngle = endAngle;
			endAngle = t;
		}
		if (endAngle - startAngle >= 360)
			endAngle = startAngle + 360;
		segments = arcSegments(outerRadius, startAngle, endAngle, segments);
		if (innerRadius <= 0) {
			DrawCircleSector(center, outerRadius, startAngle, endAngle, segments, color);
			return;
		}
		var stepLength = (endAngle - startAngle) / segments,
			angle = startAngle;
		var cx = center.x, cy = center.y;
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		for (i in 0...segments) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			shapeVertex(shapeU0, shapeV1, arcX(cx, angle, outerRadius), arcY(cy, angle, outerRadius));
			shapeVertex(shapeU0, shapeV0, arcX(cx, angle, innerRadius), arcY(cy, angle, innerRadius));
			shapeVertex(shapeU1, shapeV0, arcX(cx, angle + stepLength, innerRadius), arcY(cy, angle + stepLength, innerRadius));
			shapeVertex(shapeU1, shapeV1, arcX(cx, angle + stepLength, outerRadius), arcY(cy, angle + stepLength, outerRadius));
			angle += stepLength;
		}
		rlEnd();
		rlSetTexture(0);
	}

	/** Draws a ring's outline, or a slice of one, one pixel wide, with lines across its ends; a whole turn has none.

		@param center  The center.
		@param innerRadius  The radius of its hole; 0 or less draws a slice of a circle.
		@param outerRadius  The radius of its edge; the larger of the two is taken as the edge, and an edge of 0 or less draws nothing.
		@param startAngle  The angle it starts at, in degrees from the right.
		@param endAngle  The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
		@param segments  How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
		@param color  The color. */
	static function DrawRingLines(center:Vector2, innerRadius:Float, outerRadius:Float, startAngle:Float, endAngle:Float, segments:Int, color:Color):Void {
		if (startAngle == endAngle)
			return;
		if (outerRadius < innerRadius) {
			var t = outerRadius;
			outerRadius = innerRadius;
			innerRadius = t;
		}
		if (outerRadius <= 0)
			return;
		if (endAngle < startAngle) {
			var t = startAngle;
			startAngle = endAngle;
			endAngle = t;
		}
		var showCapLines = true;
		if (endAngle - startAngle >= 360) {
			showCapLines = false;
			endAngle = startAngle + 360;
		}
		segments = arcSegments(outerRadius, startAngle, endAngle, segments);
		if (innerRadius <= 0) {
			DrawCircleSectorLines(center, outerRadius, startAngle, endAngle, segments, color);
			return;
		}
		var stepLength = (endAngle - startAngle) / segments,
			angle = startAngle;
		var cx = center.x, cy = center.y;
		rlBegin(RL_LINES);
		if (showCapLines) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex2f(arcX(cx, angle, outerRadius), arcY(cy, angle, outerRadius));
			rlVertex2f(arcX(cx, angle, innerRadius), arcY(cy, angle, innerRadius));
		}
		for (i in 0...segments) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex2f(arcX(cx, angle, outerRadius), arcY(cy, angle, outerRadius));
			rlVertex2f(arcX(cx, angle + stepLength, outerRadius), arcY(cy, angle + stepLength, outerRadius));
			rlVertex2f(arcX(cx, angle, innerRadius), arcY(cy, angle, innerRadius));
			rlVertex2f(arcX(cx, angle + stepLength, innerRadius), arcY(cy, angle + stepLength, innerRadius));
			angle += stepLength;
		}
		if (showCapLines) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex2f(arcX(cx, angle, outerRadius), arcY(cy, angle, outerRadius));
			rlVertex2f(arcX(cx, angle, innerRadius), arcY(cy, angle, innerRadius));
		}
		rlEnd();
	}

	/** Draws a ring's outline, or a slice of one, of a thickness: inside its edge and outside its hole, or the other way for a negative
		thickness, with its ends that thick too; a whole turn drawn outside has no ends.

		@param center  The center.
		@param innerRadius  The radius of its hole; 0 or less draws a slice of a circle (`DrawCircleSectorLinesEx`) for a negative
			thickness.
		@param outerRadius  The radius of its edge; the larger of the two is taken as the edge, and an edge of 0 or less draws nothing.
		@param startAngle  The angle it starts at, in degrees from the right.
		@param endAngle  The angle it ends at; the same as the start draws nothing, and more than a turn past it draws one turn.
		@param segments  How many straight edges make its curve; fewer than one for each 90 degrees picks enough for a smooth curve.
		@param thick  The outline's thickness, measured across its curve's straight edges; one so thick it meets itself fills the ring.
		@param color  The color. */
	static function DrawRingLinesEx(center:Vector2, innerRadius:Float, outerRadius:Float, startAngle:Float, endAngle:Float, segments:Int, thick:Float,
			color:Color):Void {
		if (startAngle == endAngle)
			return;
		if (outerRadius < innerRadius) {
			var t = outerRadius;
			outerRadius = innerRadius;
			innerRadius = t;
		}
		if (outerRadius <= 0)
			return;
		if (endAngle < startAngle) {
			var t = startAngle;
			startAngle = endAngle;
			endAngle = t;
		}
		var showCapLines = true;
		if (endAngle - startAngle >= 360) {
			showCapLines = thick >= 0;
			endAngle = startAngle + 360;
		}
		segments = arcSegments(outerRadius, startAngle, endAngle, segments);
		var stepLength = (endAngle - startAngle) / segments;
		// The curve is a polygon, so the thickness is widened to stay as thick across its straight edges.
		var apothem = outerRadius * Math.cos(DEG2RAD * ((endAngle - startAngle) / 2) / segments);
		var radiusThick = thick * (outerRadius / apothem);
		// Two rings are drawn, so four radii, farthest first: outerOuterRadius, innerOuterRadius, outerInnerRadius, innerInnerRadius.
		var innerOuterRadius = 0.,
			outerOuterRadius = 0.,
			innerInnerRadius = 0.,
			outerInnerRadius = 0.;
		if (thick >= 0) {
			innerRadius = Math.max(0, innerRadius);
			if (radiusThick > (outerRadius - innerRadius) / 2) {
				DrawRing(center, innerRadius, outerRadius, startAngle, endAngle, segments, color);
				return;
			}
			innerInnerRadius = innerRadius;
			outerInnerRadius = innerInnerRadius + radiusThick;
			outerOuterRadius = outerRadius;
			innerOuterRadius = outerOuterRadius - radiusThick;
		} else {
			if (innerRadius <= 0) {
				DrawCircleSectorLinesEx(center, outerRadius, startAngle, endAngle, segments, thick, color);
				return;
			}
			outerInnerRadius = innerRadius;
			innerInnerRadius = Math.max(0, outerInnerRadius + radiusThick);
			innerOuterRadius = outerRadius;
			outerOuterRadius = innerOuterRadius - radiusThick;
		}
		inline function at(angle:Float, r:Float):Vector2
			return new Vector2(arcX(center.x, angle, r), arcY(center.y, angle, r));
		inline function lerp(a:Vector2, b:Vector2, t:Float):Vector2
			return new Vector2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
		// For a thickness of 0 or more: the steps along each curve the caps cover, and where the caps' last edges cross the curves.
		var stepsBeforeInner = 0, stepsBeforeOuter = 0, tInner = 0., tOuter = 0., innerAnglesCrossEachOther = false;
		// For a negative one: the caps' outer corners, and where the caps cross each other, if they do.
		var cap1SecondInnerVertex = new Vector2(),
			cap1SecondOuterVertex = new Vector2(),
			cap2SecondInnerVertex = new Vector2(),
			cap2SecondOuterVertex = new Vector2();
		var capsIntersect = false, capIntersectionVertex = new Vector2();
		if (showCapLines) {
			if (thick >= 0) {
				// The angles of arcs the thickness long along the inner and outer curves.
				var cap1InnerAngleEnd = RAD2DEG * (thick / outerInnerRadius);
				var cap1OuterAngleEnd = RAD2DEG * (thick / innerOuterRadius);
				if (endAngle - startAngle < cap1OuterAngleEnd * 2) {
					DrawRing(center, innerRadius, outerRadius, startAngle, endAngle, segments, color);
					return;
				}
				if (endAngle - startAngle < cap1InnerAngleEnd * 2)
					innerAnglesCrossEachOther = true;
				stepsBeforeInner = Std.int(cap1InnerAngleEnd / stepLength);
				stepsBeforeOuter = Std.int(cap1OuterAngleEnd / stepLength);
				// Where each arc's end crosses the curve's edge it falls on, the arc's end turned to 0 degrees about the center.
				var beforeInnerY = Math.sin(DEG2RAD * (stepsBeforeInner * stepLength - cap1InnerAngleEnd)) * outerInnerRadius;
				var afterInnerY = Math.sin(DEG2RAD * ((stepsBeforeInner + 1) * stepLength - cap1InnerAngleEnd)) * outerInnerRadius;
				tInner = beforeInnerY / (beforeInnerY - afterInnerY);
				var beforeOuterY = Math.sin(DEG2RAD * (stepsBeforeOuter * stepLength - cap1OuterAngleEnd)) * innerOuterRadius;
				var afterOuterY = Math.sin(DEG2RAD * ((stepsBeforeOuter + 1) * stepLength - cap1OuterAngleEnd)) * innerOuterRadius;
				tOuter = beforeOuterY / (beforeOuterY - afterOuterY);
			} else {
				// Cap 1 on the start, cap 2 on the end, in raylib's sketch: I0, I1 and I2 on the inner side, O0, O1 and O2 on the outer,
				// first with the center at the origin and the start at 0 degrees.
				var cap1O0 = new Vector2(outerOuterRadius, 0);
				var cap1O1 = new Vector2(Math.cos(DEG2RAD * stepLength) * outerOuterRadius, Math.sin(DEG2RAD * stepLength) * outerOuterRadius);
				var tOuterCap = (cap1O1.y - thick) / cap1O1.y;
				var cap1O2 = new Vector2(cap1O1.x + (cap1O0.x - cap1O1.x) * tOuterCap, thick);
				var capLongEdgeLength = outerOuterRadius - innerInnerRadius;
				var cap1I2 = new Vector2(cap1O2.x - capLongEdgeLength, thick);
				var span = endAngle - startAngle;
				var cap2O0 = new Vector2(Math.cos(DEG2RAD * span) * outerOuterRadius, Math.sin(DEG2RAD * span) * outerOuterRadius);
				var cap2O1 = new Vector2(Math.cos(DEG2RAD * (endAngle - startAngle - stepLength)) * outerOuterRadius,
					Math.sin(DEG2RAD * (endAngle - startAngle - stepLength)) * outerOuterRadius);
				var cap2O2 = lerp(cap2O1, cap2O0, tOuterCap);
				var cap2I0 = new Vector2(Math.cos(DEG2RAD * span) * innerInnerRadius, Math.sin(DEG2RAD * span) * innerInnerRadius);
				var cap2I2 = new Vector2(cap2O2.x - Math.cos(DEG2RAD * span) * capLongEdgeLength, cap2O2.y - Math.sin(DEG2RAD * span) * capLongEdgeLength);
				// Where cap 2's long edge crosses cap 1's.
				var tCapLongEdgeCross = -1.;
				if (cap2I2.y - cap2O2.y != 0) {
					tCapLongEdgeCross = (cap2I2.y - thick) / (cap2I2.y - cap2O2.y);
					if (tCapLongEdgeCross >= 0 && tCapLongEdgeCross <= 1)
						capsIntersect = true;
				}
				// Turned so cap 1's I0 to I2 is upright; only x is wanted.
				var rotateBy = -DEG2RAD * stepLength / 2;
				var cosres = Math.cos(rotateBy), sinres = Math.sin(rotateBy);
				inline function turnedX(v:Vector2):Float
					return v.x * cosres - v.y * sinres;
				var cap1I2x = turnedX(cap1I2),
					cap1O2x = turnedX(cap1O2),
					cap2I0x = turnedX(cap2I0),
					cap2I2x = turnedX(cap2I2),
					cap2O0x = turnedX(cap2O0),
					cap2O2x = turnedX(cap2O2);
				var tCrossInner = -1.;
				if (cap2I0x - cap2I2x != 0)
					tCrossInner = (cap2I0x - cap1I2x) / (cap2I0x - cap2I2x);
				if (innerInnerRadius <= 0)
					tCrossInner = 0;
				var tCrossOuter = -1.;
				if (cap2O0x - cap2O2x != 0)
					tCrossOuter = (cap2O0x - cap1O2x) / (cap2O0x - cap2O2x);
				// The corners where they are drawn.
				cap1O0 = at(startAngle, outerOuterRadius);
				cap1O1 = at(startAngle + stepLength, outerOuterRadius);
				cap1O2 = lerp(cap1O1, cap1O0, tOuterCap);
				cap2O0 = at(endAngle, outerOuterRadius);
				cap2O1 = at(endAngle - stepLength, outerOuterRadius);
				cap2O2 = lerp(cap2O1, cap2O0, tOuterCap);
				cap1I2 = new Vector2(cap1O2.x - Math.cos(DEG2RAD * startAngle) * capLongEdgeLength,
					cap1O2.y - Math.sin(DEG2RAD * startAngle) * capLongEdgeLength);
				cap2I0 = at(endAngle, innerInnerRadius);
				cap2I2 = new Vector2(cap2O2.x - Math.cos(DEG2RAD * endAngle) * capLongEdgeLength, cap2O2.y - Math.sin(DEG2RAD * endAngle) * capLongEdgeLength);
				if (capsIntersect) {
					capIntersectionVertex = lerp(cap2I2, cap2O2, tCapLongEdgeCross);
					cap2I2 = lerp(cap2I0, cap2I2, tCrossInner);
					cap1I2 = cap2I2;
				} else if (tCrossOuter >= 0 && tCrossOuter <= 1) {
					cap2O2 = lerp(cap2O0, cap2O2, tCrossOuter);
					cap1O2 = cap2O2;
					cap2I2 = lerp(cap2I0, cap2I2, tCrossInner);
					cap1I2 = cap2I2;
				}
				cap1SecondInnerVertex = cap1I2;
				cap1SecondOuterVertex = cap1O2;
				cap2SecondInnerVertex = cap2I2;
				cap2SecondOuterVertex = cap2O2;
			}
		}
		var angle = startAngle;
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		rlColor4ub(color.r, color.g, color.b, color.a);
		// The inner ring and the outer ring, then the caps.
		for (i in 0...segments) {
			outlineQuad(at(angle, outerInnerRadius), at(angle, innerInnerRadius), at(angle + stepLength, innerInnerRadius),
				at(angle + stepLength, outerInnerRadius));
			outlineQuad(at(angle, outerOuterRadius), at(angle, innerOuterRadius), at(angle + stepLength, innerOuterRadius),
				at(angle + stepLength, outerOuterRadius));
			angle += stepLength;
		}
		if (showCapLines) {
			if (thick >= 0) {
				angle = 0;
				for (i in 0...stepsBeforeOuter) {
					outlineQuad(at(startAngle + angle, outerInnerRadius), at(startAngle + angle + stepLength, outerInnerRadius),
						at(startAngle + angle + stepLength, innerOuterRadius), at(startAngle + angle, innerOuterRadius));
					outlineQuad(at(endAngle - angle, outerInnerRadius), at(endAngle - angle, innerOuterRadius),
						at(endAngle - angle - stepLength, innerOuterRadius), at(endAngle - angle - stepLength, outerInnerRadius));
					angle += stepLength;
				}
				// stepsBeforeOuter steps are drawn from each end.
				var totalStepsLeft = segments - stepsBeforeOuter * 2;
				var innerStepsLeft = stepsBeforeInner - stepsBeforeOuter;
				var cap1OuterVertexBeforeEnd = at(startAngle + angle, innerOuterRadius);
				var cap1OuterVertexAfterEnd = at(startAngle + angle + stepLength, innerOuterRadius);
				var cap1InnerVertexBeforeEnd = at(startAngle + angle + innerStepsLeft * stepLength, outerInnerRadius);
				var cap1InnerVertexAfterEnd = at(startAngle + angle + (innerStepsLeft + 1) * stepLength, outerInnerRadius);
				var cap1InnerVertexEnd = lerp(cap1InnerVertexBeforeEnd, cap1InnerVertexAfterEnd, tInner);
				var cap1OuterVertexEnd = lerp(cap1OuterVertexBeforeEnd, cap1OuterVertexAfterEnd, tOuter);
				var cap2OuterVertexBeforeEnd = at(endAngle - angle, innerOuterRadius);
				var cap2OuterVertexAfterEnd = at(endAngle - angle - stepLength, innerOuterRadius);
				var cap2InnerVertexBeforeEnd = at(endAngle - angle - innerStepsLeft * stepLength, outerInnerRadius);
				var cap2InnerVertexAfterEnd = at(endAngle - angle - (innerStepsLeft + 1) * stepLength, outerInnerRadius);
				var cap2InnerVertexEnd = lerp(cap2InnerVertexBeforeEnd, cap2InnerVertexAfterEnd, tInner);
				var cap2OuterVertexEnd = lerp(cap2OuterVertexBeforeEnd, cap2OuterVertexAfterEnd, tOuter);
				var stepsCount = innerAnglesCrossEachOther ? Std.int(totalStepsLeft / 2) : innerStepsLeft;
				for (i in 0...Std.int(stepsCount / 2)) {
					outlineQuad(cap1OuterVertexBeforeEnd, at(startAngle + angle, outerInnerRadius), at(startAngle + angle + stepLength, outerInnerRadius),
						at(startAngle + angle + stepLength * 2, outerInnerRadius));
					outlineQuad(cap2OuterVertexBeforeEnd, at(endAngle - angle - stepLength * 2, outerInnerRadius),
						at(endAngle - angle - stepLength, outerInnerRadius), at(endAngle - angle, outerInnerRadius));
					angle += stepLength * 2;
				}
				if (stepsCount % 2 == 1) {
					outlineQuad(cap1OuterVertexBeforeEnd, cap1OuterVertexBeforeEnd, at(startAngle + angle, outerInnerRadius),
						at(startAngle + angle + stepLength, outerInnerRadius));
					outlineQuad(cap2OuterVertexBeforeEnd, cap2OuterVertexBeforeEnd, at(endAngle - angle - stepLength, outerInnerRadius),
						at(endAngle - angle, outerInnerRadius));
					angle += stepLength;
				}
				if (innerAnglesCrossEachOther) {
					// The caps' inner ends pass each other: they stop where the caps' last edges cross.
					var a = new Vector2(cap1OuterVertexEnd.x - cap1InnerVertexEnd.x, cap1OuterVertexEnd.y - cap1InnerVertexEnd.y);
					var b = new Vector2(cap2InnerVertexEnd.x - cap1InnerVertexEnd.x, cap2InnerVertexEnd.y - cap1InnerVertexEnd.y);
					var c = new Vector2(cap2OuterVertexEnd.x - cap1InnerVertexEnd.x, cap2OuterVertexEnd.y - cap1InnerVertexEnd.y);
					var rotateBy = -Math.atan2(a.y, a.x);
					var start = Math.sin(rotateBy) * b.x + Math.cos(rotateBy) * b.y;
					var end = Math.sin(rotateBy) * c.x + Math.cos(rotateBy) * c.y;
					var intersection = lerp(cap2InnerVertexEnd, cap2OuterVertexEnd, start / (start - end));
					if (segments % 2 == 0) {
						// An odd number of vertices: one in the middle.
						var middleInnerVertex = at(startAngle + angle, outerInnerRadius);
						outlineQuad(intersection, cap1OuterVertexEnd, cap1OuterVertexBeforeEnd, middleInnerVertex);
						outlineQuad(intersection, middleInnerVertex, cap2OuterVertexBeforeEnd, cap2OuterVertexEnd);
					} else {
						// An even number: two in the middle, and a triangle between the caps.
						var middleInnerVertex1 = at(startAngle + angle, outerInnerRadius),
							middleInnerVertex2 = at(endAngle - angle, outerInnerRadius);
						outlineQuad(intersection, cap1OuterVertexEnd, cap1OuterVertexBeforeEnd, middleInnerVertex1);
						outlineQuad(intersection, middleInnerVertex2, cap2OuterVertexBeforeEnd, cap2OuterVertexEnd);
						outlineQuad(intersection, intersection, middleInnerVertex1, middleInnerVertex2);
					}
				} else {
					outlineQuad(cap1OuterVertexBeforeEnd, cap1InnerVertexBeforeEnd, cap1InnerVertexEnd, cap1OuterVertexEnd);
					outlineQuad(cap2OuterVertexBeforeEnd, cap2OuterVertexEnd, cap2InnerVertexEnd, cap2InnerVertexBeforeEnd);
				}
			} else {
				outlineQuad(at(startAngle, innerInnerRadius), at(startAngle, outerOuterRadius), cap1SecondOuterVertex, cap1SecondInnerVertex);
				outlineQuad(at(endAngle, innerInnerRadius), cap2SecondInnerVertex, cap2SecondOuterVertex, at(endAngle, outerOuterRadius));
				if (capsIntersect) {
					outlineQuad(cap1SecondInnerVertex, cap1SecondInnerVertex, cap1SecondOuterVertex, capIntersectionVertex);
					outlineQuad(cap2SecondInnerVertex, capIntersectionVertex, cap2SecondOuterVertex, cap2SecondInnerVertex);
				}
			}
		}
		rlEnd();
		// raylib 6.2's leaves the shapes texture set, as here.
	}

	/** Draws a filled rectangle.

		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	static function DrawRectangle(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void {
		DrawRectangleV(new Vector2(posX, posY), new Vector2(width, height), color);
	}

	/** Draws a filled rectangle.

		@param position  The top-left corner.
		@param size  The width and height.
		@param color  The color. */
	static function DrawRectangleV(position:Vector2, size:Vector2, color:Color):Void {
		DrawRectanglePro(new Rectangle(position.x, position.y, size.x, size.y), new Vector2(0, 0), 0, color);
	}

	/** Draws a filled rectangle.

		@param rec  The rectangle.
		@param color  The color. */
	static function DrawRectangleRec(rec:Rectangle, color:Color):Void {
		DrawRectanglePro(rec, new Vector2(0, 0), 0, color);
	}

	/** Draws a filled rectangle turned about a point of it.

		@param rec  The rectangle; its x and y are where the point is drawn.
		@param origin  The point it turns about, from its top-left corner.
		@param rotation  The turn, in degrees clockwise.
		@param color  The color. */
	static function DrawRectanglePro(rec:Rectangle, origin:Vector2, rotation:Float, color:Color):Void {
		var topLeftX, topLeftY, topRightX, topRightY, bottomLeftX, bottomLeftY, bottomRightX, bottomRightY;
		if (rotation == 0) {
			var x = rec.x - origin.x, y = rec.y - origin.y;
			topLeftX = x;
			topLeftY = y;
			topRightX = x + rec.width;
			topRightY = y;
			bottomLeftX = x;
			bottomLeftY = y + rec.height;
			bottomRightX = x + rec.width;
			bottomRightY = y + rec.height;
		} else {
			var sinRotation = Math.sin(rotation * DEG2RAD),
				cosRotation = Math.cos(rotation * DEG2RAD);
			var x = rec.x, y = rec.y, dx = -origin.x, dy = -origin.y;
			topLeftX = x + dx * cosRotation - dy * sinRotation;
			topLeftY = y + dx * sinRotation + dy * cosRotation;
			topRightX = x + (dx + rec.width) * cosRotation - dy * sinRotation;
			topRightY = y + (dx + rec.width) * sinRotation + dy * cosRotation;
			bottomLeftX = x + dx * cosRotation - (dy + rec.height) * sinRotation;
			bottomLeftY = y + dx * sinRotation + (dy + rec.height) * cosRotation;
			bottomRightX = x + (dx + rec.width) * cosRotation - (dy + rec.height) * sinRotation;
			bottomRightY = y + (dx + rec.width) * sinRotation + (dy + rec.height) * cosRotation;
		}
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		rlNormal3f(0, 0, 1);
		rlColor4ub(color.r, color.g, color.b, color.a);
		shapeVertex(shapeU0, shapeV0, topLeftX, topLeftY);
		shapeVertex(shapeU0, shapeV1, bottomLeftX, bottomLeftY);
		shapeVertex(shapeU1, shapeV1, bottomRightX, bottomRightY);
		shapeVertex(shapeU1, shapeV0, topRightX, topRightY);
		rlEnd();
		rlSetTexture(0);
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
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		rlNormal3f(0, 0, 1);
		rlColor4ub(topLeft.r, topLeft.g, topLeft.b, topLeft.a);
		shapeVertex(shapeU0, shapeV0, rec.x, rec.y);
		rlColor4ub(bottomLeft.r, bottomLeft.g, bottomLeft.b, bottomLeft.a);
		shapeVertex(shapeU0, shapeV1, rec.x, rec.y + rec.height);
		rlColor4ub(topRight.r, topRight.g, topRight.b, topRight.a);
		shapeVertex(shapeU1, shapeV1, rec.x + rec.width, rec.y + rec.height);
		rlColor4ub(bottomRight.r, bottomRight.g, bottomRight.b, bottomRight.a);
		shapeVertex(shapeU1, shapeV0, rec.x + rec.width, rec.y);
		rlEnd();
		rlSetTexture(0);
	}

	/** Draws a rectangle's outline, one pixel wide, its lines through the centers of its edge pixels.

		The lines are half a pixel inside the edges, by the matrix `rlPushMatrix` and its kin set (`rlGetMatrixTransform`); a 2D camera's
		zoom isn't counted, so under a camera they are half a unit inside.

		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	static function DrawRectangleLines(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void {
		var mat = rlGetMatrixTransform();
		var xOffset = .5 / mat.m0, yOffset = .5 / mat.m5;
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		rlVertex2f(posX + xOffset, posY + yOffset);
		rlVertex2f(posX + width - xOffset, posY + yOffset);
		rlVertex2f(posX + width - xOffset, posY + yOffset);
		rlVertex2f(posX + width - xOffset, posY + height - yOffset);
		rlVertex2f(posX + width - xOffset, posY + height - yOffset);
		rlVertex2f(posX + xOffset, posY + height - yOffset);
		rlVertex2f(posX + xOffset, posY + height - yOffset);
		rlVertex2f(posX + xOffset, posY + yOffset);
		rlEnd();
	}

	/** Draws a rectangle's outline of a thickness, inside it, or outside it for a negative thickness.

		@param rec  The rectangle.
		@param lineThick  The lines' thickness; more than half the rectangle's width or height is half its shorter side, and 0 or less
			draws the outline that thick outside the rectangle (bars of no width, for 0).
		@param color  The color. */
	static function DrawRectangleLinesEx(rec:Rectangle, lineThick:Float, color:Color):Void {
		if (lineThick > rec.width / 2 || lineThick > rec.height / 2) {
			if (rec.width >= rec.height)
				lineThick = rec.height / 2;
			else if (rec.width <= rec.height)
				lineThick = rec.width / 2;
		}
		if (lineThick > 0) {
			// The top and bottom across the whole width, the left and right between them.
			DrawRectangleRec(new Rectangle(rec.x, rec.y, rec.width, lineThick), color);
			DrawRectangleRec(new Rectangle(rec.x, rec.y - lineThick + rec.height, rec.width, lineThick), color);
			DrawRectangleRec(new Rectangle(rec.x, rec.y + lineThick, lineThick, rec.height - lineThick * 2), color);
			DrawRectangleRec(new Rectangle(rec.x - lineThick + rec.width, rec.y + lineThick, lineThick, rec.height - lineThick * 2), color);
		} else {
			// Outside: the top and bottom across the whole width and both sides, the left and right beside the rectangle.
			lineThick *= -1;
			DrawRectangleRec(new Rectangle(rec.x - lineThick, rec.y - lineThick, rec.width + lineThick * 2, lineThick), color);
			DrawRectangleRec(new Rectangle(rec.x - lineThick, rec.y + rec.height, rec.width + lineThick * 2, lineThick), color);
			DrawRectangleRec(new Rectangle(rec.x - lineThick, rec.y, lineThick, rec.height), color);
			DrawRectangleRec(new Rectangle(rec.x + rec.width, rec.y, lineThick, rec.height), color);
		}
	}

	/** Draws a filled rectangle with rounded corners.

		@param rec  The rectangle.
		@param roundness  How round its corners are: 0 for square, 1 for a radius of half its shorter side.
		@param segments  How many straight edges make each corner's curve; fewer than 1 picks enough for a smooth curve.
		@param color  The color. */
	static function DrawRectangleRounded(rec:Rectangle, roundness:Float, segments:Int, color:Color):Void {
		if (roundness <= 0) {
			DrawRectangleRec(rec, color);
			return;
		}
		if (roundness >= 1)
			roundness = 1;
		var radius = rec.width > rec.height ? rec.height * roundness / 2 : rec.width * roundness / 2;
		if (radius <= 0)
			return;
		if (segments < 1) {
			segments = Std.int(Math.fceil(2 * Math.PI / smoothAngle(radius) / 4));
			if (segments <= 0)
				segments = 4;
		}
		var stepLength = 90 / segments;
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
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		// The corners: top-left, top-right, bottom-right, bottom-left, each quad two segments.
		for (k in 0...4) {
			var angle = CORNER_ANGLES[k], cx = px[8 + k], cy = py[8 + k];
			for (i in 0...Std.int(segments / 2)) {
				rlColor4ub(color.r, color.g, color.b, color.a);
				shapeVertex(shapeU0, shapeV0, cx, cy);
				shapeVertex(shapeU1, shapeV0, arcX(cx, angle + stepLength * 2, radius), arcY(cy, angle + stepLength * 2, radius));
				shapeVertex(shapeU1, shapeV1, arcX(cx, angle + stepLength, radius), arcY(cy, angle + stepLength, radius));
				shapeVertex(shapeU0, shapeV1, arcX(cx, angle, radius), arcY(cy, angle, radius));
				angle += stepLength * 2;
			}
			if (segments % 2 == 1) {
				rlColor4ub(color.r, color.g, color.b, color.a);
				shapeVertex(shapeU0, shapeV0, cx, cy);
				shapeVertex(shapeU1, shapeV1, arcX(cx, angle + stepLength, radius), arcY(cy, angle + stepLength, radius));
				shapeVertex(shapeU0, shapeV1, arcX(cx, angle, radius), arcY(cy, angle, radius));
				shapeVertex(shapeU1, shapeV0, cx, cy);
			}
		}
		// The top, right, bottom, left and middle rectangles.
		for (p in [[0, 8, 9, 1], [2, 9, 10, 3], [11, 5, 4, 10], [7, 6, 11, 8], [8, 11, 10, 9]]) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			shapeVertex(shapeU0, shapeV0, px[p[0]], py[p[0]]);
			shapeVertex(shapeU0, shapeV1, px[p[1]], py[p[1]]);
			shapeVertex(shapeU1, shapeV1, px[p[2]], py[p[2]]);
			shapeVertex(shapeU1, shapeV0, px[p[3]], py[p[3]]);
		}
		rlEnd();
		rlSetTexture(0);
	}

	/** Draws a rounded rectangle's outline, one pixel wide, its lines through the centers of its edge pixels.

		@param rec  The rectangle.
		@param roundness  How round its corners are: 0 or less for square (`DrawRectangleLines`, the rectangle cut to whole pixels), 1 for
			a radius of half its shorter side.
		@param segments  How many straight edges make each corner's curve; fewer than 1 picks enough for a smooth curve.
		@param color  The color. */
	static function DrawRectangleRoundedLines(rec:Rectangle, roundness:Float, segments:Int, color:Color):Void {
		if (roundness <= 0) {
			DrawRectangleLines(Std.int(rec.x), Std.int(rec.y), Std.int(rec.width), Std.int(rec.height), color);
			return;
		}
		if (roundness >= 1)
			roundness = 1;
		var radius = rec.width > rec.height ? rec.height * roundness / 2 : rec.width * roundness / 2;
		if (radius <= 0)
			return;
		if (segments < 1) {
			segments = Std.int(Math.fceil(2 * Math.PI / smoothAngle(radius) / 4));
			if (segments <= 0)
				segments = 4;
		}
		var stepLength = 90 / segments;
		var x0 = rec.x + radius + .5,
			x1 = rec.x + rec.width - radius - .5,
			x2 = rec.x + rec.width - .5,
			x3 = rec.x + .5;
		var y0 = rec.y + .5,
			y1 = rec.y + radius + .5,
			y2 = rec.y + rec.height - radius - .5,
			y3 = rec.y + rec.height - .5;
		// P0 to P7 around the edge from the top's left end, and the corners' centers.
		var px = [x0, x1, x2, x2, x1, x0, x3, x3],
			py = [y0, y0, y1, y2, y3, y3, y2, y1];
		var centersX = [x0, x1, x1, x0], centersY = [y1, y1, y2, y2];
		rlBegin(RL_LINES);
		// The corners first: top-left, top-right, bottom-right, bottom-left; then the four sides.
		for (k in 0...4) {
			var angle = CORNER_ANGLES[k], cx = centersX[k], cy = centersY[k];
			for (i in 0...segments) {
				rlColor4ub(color.r, color.g, color.b, color.a);
				rlVertex2f(arcX(cx, angle, radius), arcY(cy, angle, radius));
				rlVertex2f(arcX(cx, angle + stepLength, radius), arcY(cy, angle + stepLength, radius));
				angle += stepLength;
			}
		}
		var i = 0;
		while (i < 8) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex2f(px[i], py[i]);
			rlVertex2f(px[i + 1], py[i + 1]);
			i += 2;
		}
		rlEnd();
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
			// Around the rectangle grown by the thickness, which is never more than half its size: 5.5's bars and 6.2's are the same.
			DrawRectangleLinesEx(new Rectangle(rec.x - lineThick, rec.y - lineThick, rec.width + 2 * lineThick, rec.height + 2 * lineThick), lineThick, color);
			return;
		}
		if (roundness >= 1)
			roundness = 1;
		var radius = rec.width > rec.height ? rec.height * roundness / 2 : rec.width * roundness / 2;
		if (radius <= 0)
			return;
		if (segments < 4) {
			segments = Std.int(Math.fceil(2 * Math.PI / smoothAngle(radius)) / 2);
			if (segments <= 0)
				segments = 4;
		}
		var stepLength = 90 / segments,
			outerRadius = radius + lineThick,
			innerRadius = radius;
		var x = rec.x, y = rec.y, r = rec.x + rec.width, b = rec.y + rec.height, t = lineThick;
		// The sixteen points of raylib's sketch: P0 to P7 around the outer edge from the top's left end, P8 to P15 the inner edge's.
		var px = [
			x + innerRadius, r - innerRadius, r + t, r + t, r - innerRadius, x + innerRadius, x - t, x - t,
			x + innerRadius, r - innerRadius,     r,     r, r - innerRadius, x + innerRadius,     x,     x
		];
		var py = [
			y - t, y - t, y + innerRadius, b - innerRadius, b + t, b + t, b - innerRadius, y + innerRadius,
			    y,     y, y + innerRadius, b - innerRadius,     b,     b, b - innerRadius, y + innerRadius
		];
		var centersX = [x + innerRadius, r - innerRadius, r - innerRadius, x + innerRadius],
			centersY = [y + innerRadius, y + innerRadius, b - innerRadius, b - innerRadius];
		if (lineThick > 1) {
			rlSetTexture(GetShapesTexture().id);
			rlBegin(RL_QUADS);
			// The corners first: top-left, top-right, bottom-right, bottom-left.
			for (k in 0...4) {
				var angle = CORNER_ANGLES[k],
					cx = centersX[k],
					cy = centersY[k];
				for (i in 0...segments) {
					rlColor4ub(color.r, color.g, color.b, color.a);
					shapeVertex(shapeU0, shapeV0, arcX(cx, angle, innerRadius), arcY(cy, angle, innerRadius));
					shapeVertex(shapeU1, shapeV0, arcX(cx, angle + stepLength, innerRadius), arcY(cy, angle + stepLength, innerRadius));
					shapeVertex(shapeU1, shapeV1, arcX(cx, angle + stepLength, outerRadius), arcY(cy, angle + stepLength, outerRadius));
					shapeVertex(shapeU0, shapeV1, arcX(cx, angle, outerRadius), arcY(cy, angle, outerRadius));
					angle += stepLength;
				}
			}
			// The top, right, bottom and left sides.
			for (p in [[0, 8, 9, 1], [2, 10, 11, 3], [13, 5, 4, 12], [15, 7, 6, 14]]) {
				rlColor4ub(color.r, color.g, color.b, color.a);
				shapeVertex(shapeU0, shapeV0, px[p[0]], py[p[0]]);
				shapeVertex(shapeU0, shapeV1, px[p[1]], py[p[1]]);
				shapeVertex(shapeU1, shapeV1, px[p[2]], py[p[2]]);
				shapeVertex(shapeU1, shapeV0, px[p[3]], py[p[3]]);
			}
			rlEnd();
			rlSetTexture(0);
		} else {
			rlBegin(RL_LINES);
			// The corners' outer curves, then the four sides.
			for (k in 0...4) {
				var angle = CORNER_ANGLES[k],
					cx = centersX[k],
					cy = centersY[k];
				for (i in 0...segments) {
					rlColor4ub(color.r, color.g, color.b, color.a);
					rlVertex2f(arcX(cx, angle, outerRadius), arcY(cy, angle, outerRadius));
					rlVertex2f(arcX(cx, angle + stepLength, outerRadius), arcY(cy, angle + stepLength, outerRadius));
					angle += stepLength;
				}
			}
			var i = 0;
			while (i < 8) {
				rlColor4ub(color.r, color.g, color.b, color.a);
				rlVertex2f(px[i], py[i]);
				rlVertex2f(px[i + 1], py[i + 1]);
				i += 2;
			}
			rlEnd();
		}
	}

	/** Draws a filled triangle.

		Its points must go counterclockwise on the screen, as raylib's must: a triangle whose points go clockwise faces away, and isn't
		drawn while back faces are culled (`rlEnableBackfaceCulling`, the default).

		@param v1  The first point.
		@param v2  The second point.
		@param v3  The third point.
		@param color  The color. */
	static function DrawTriangle(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void {
		DrawTriangleGradient(v1, v2, v3, color, color, color);
	}

	/** Draws a filled triangle that blends between a color at each point.

		Its points must go counterclockwise on the screen, as `DrawTriangle`'s must.

		@param v1  The first point.
		@param v2  The second point.
		@param v3  The third point.
		@param c1  The first point's color.
		@param c2  The second point's color.
		@param c3  The third point's color. */
	static function DrawTriangleGradient(v1:Vector2, v2:Vector2, v3:Vector2, c1:Color, c2:Color, c3:Color):Void {
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		rlNormal3f(0, 0, 1);
		rlColor4ub(c1.r, c1.g, c1.b, c1.a);
		shapeVertex(shapeU0, shapeV0, v1.x, v1.y);
		rlColor4ub(c2.r, c2.g, c2.b, c2.a);
		shapeVertex(shapeU0, shapeV1, v2.x, v2.y);
		rlColor4ub(c3.r, c3.g, c3.b, c3.a);
		shapeVertex(shapeU1, shapeV1, v3.x, v3.y);
		rlColor4ub(c3.r, c3.g, c3.b, c3.a);
		shapeVertex(shapeU1, shapeV0, v3.x, v3.y);
		rlEnd();
		rlSetTexture(0);
	}

	/** Draws a triangle's outline, one pixel wide.

		@param v1  The first point.
		@param v2  The second point.
		@param v3  The third point.
		@param color  The color. */
	static function DrawTriangleLines(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void {
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		rlVertex2f(v1.x, v1.y);
		rlVertex2f(v2.x, v2.y);
		rlVertex2f(v2.x, v2.y);
		rlVertex2f(v3.x, v3.y);
		rlVertex2f(v3.x, v3.y);
		rlVertex2f(v1.x, v1.y);
		rlEnd();
	}

	/** Draws a triangle's outline of a thickness, inside it, or outside it for a negative thickness: the triangle less a copy of it
		shrunk about its incenter, so each side is as thick.

		Its points must go counterclockwise on the screen, as `DrawTriangle`'s must.

		@param v1  The first point.
		@param v2  The second point.
		@param v3  The third point.
		@param thick  The thickness; as much as the radius of the circle inside it draws it filled.
		@param color  The color. */
	static function DrawTriangleLinesEx(v1:Vector2, v2:Vector2, v3:Vector2, thick:Float, color:Color):Void {
		var e1x = v2.x - v3.x, e1y = v2.y - v3.y;
		var e2x = v3.x - v1.x, e2y = v3.y - v1.y;
		var e3x = v1.x - v2.x, e3y = v1.y - v2.y;
		var e1Length = Math.sqrt(e1x * e1x + e1y * e1y),
			e2Length = Math.sqrt(e2x * e2x + e2y * e2y),
			e3Length = Math.sqrt(e3x * e3x + e3y * e3y);
		var perimeter = e1Length + e2Length + e3Length;
		var semiperimeter = perimeter / 2;
		// The incenter, the same distance from each edge, and the inradius, that distance.
		var incenterX = (e1Length * v1.x + e2Length * v2.x + e3Length * v3.x) / perimeter,
			incenterY = (e1Length * v1.y + e2Length * v2.y + e3Length * v3.y) / perimeter;
		var inradius = Math.sqrt(((semiperimeter - e1Length) * (semiperimeter - e2Length) * (semiperimeter - e3Length)) / semiperimeter);
		var scale = 1 - thick / inradius;
		if (scale <= 0) {
			DrawTriangle(v1, v2, v3, color);
			return;
		}
		var v4 = new Vector2(incenterX + (v1.x - incenterX) * scale, incenterY + (v1.y - incenterY) * scale);
		var v5 = new Vector2(incenterX + (v2.x - incenterX) * scale, incenterY + (v2.y - incenterY) * scale);
		var v6 = new Vector2(incenterX + (v3.x - incenterX) * scale, incenterY + (v3.y - incenterY) * scale);
		// Outside: the inner and outer corners swapped, for the winding.
		if (thick < 0) {
			var temp = v1;
			v1 = v4;
			v4 = temp;
			temp = v2;
			v2 = v5;
			v5 = temp;
			temp = v3;
			v3 = v6;
			v6 = temp;
		}
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		rlColor4ub(color.r, color.g, color.b, color.a);
		// Edge 3, edge 1, edge 2.
		for (q in [[v1, v2, v5, v4], [v2, v3, v6, v5], [v3, v1, v4, v6]]) {
			shapeVertex(shapeU0, shapeV0, q[0].x, q[0].y);
			shapeVertex(shapeU0, shapeV1, q[1].x, q[1].y);
			shapeVertex(shapeU1, shapeV1, q[2].x, q[2].y);
			shapeVertex(shapeU1, shapeV0, q[3].x, q[3].y);
		}
		rlEnd();
		rlSetTexture(0);
	}

	/** Draws filled triangles that all share the first point, each from it to the next two points.

		The points after the first must go counterclockwise on the screen, as `DrawTriangle`'s must.

		@param points  The points, the shared one first.
		@param pointCount  How many of them to draw, 3 or more.
		@param color  The color. */
	static function DrawTriangleFan(points:Array<Vector2>, pointCount:Int, color:Color):Void {
		if (pointCount < 3)
			return;
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		rlColor4ub(color.r, color.g, color.b, color.a);
		for (i in 1...pointCount - 1) {
			shapeVertex(shapeU0, shapeV0, points[0].x, points[0].y);
			shapeVertex(shapeU0, shapeV1, points[i].x, points[i].y);
			shapeVertex(shapeU1, shapeV1, points[i + 1].x, points[i + 1].y);
			shapeVertex(shapeU1, shapeV0, points[i + 1].x, points[i + 1].y);
		}
		rlEnd();
		rlSetTexture(0);
	}

	/** Draws filled triangles, each from a point to the two before it.

		@param points  The points.
		@param pointCount  How many of them to draw, 3 or more.
		@param color  The color. */
	static function DrawTriangleStrip(points:Array<Vector2>, pointCount:Int, color:Color):Void {
		if (pointCount < 3)
			return;
		rlBegin(RL_TRIANGLES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		for (i in 2...pointCount) {
			if (i % 2 == 0) {
				rlVertex2f(points[i].x, points[i].y);
				rlVertex2f(points[i - 2].x, points[i - 2].y);
				rlVertex2f(points[i - 1].x, points[i - 1].y);
			} else {
				rlVertex2f(points[i].x, points[i].y);
				rlVertex2f(points[i - 1].x, points[i - 1].y);
				rlVertex2f(points[i - 2].x, points[i - 2].y);
			}
		}
		rlEnd();
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
		var centralAngle = rotation * DEG2RAD,
			angleStep = 360 / sides * DEG2RAD;
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		for (i in 0...sides) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			var nextAngle = centralAngle + angleStep;
			shapeVertex(shapeU0, shapeV0, center.x, center.y);
			shapeVertex(shapeU0, shapeV1, center.x + Math.cos(centralAngle) * radius, center.y + Math.sin(centralAngle) * radius);
			shapeVertex(shapeU1, shapeV0, center.x + Math.cos(nextAngle) * radius, center.y + Math.sin(nextAngle) * radius);
			shapeVertex(shapeU1, shapeV1, center.x + Math.cos(centralAngle) * radius, center.y + Math.sin(centralAngle) * radius);
			centralAngle = nextAngle;
		}
		rlEnd();
		rlSetTexture(0);
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
		var centralAngle = rotation * DEG2RAD,
			angleStep = 360 / sides * DEG2RAD;
		rlBegin(RL_LINES);
		for (i in 0...sides) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex2f(center.x + Math.cos(centralAngle) * radius, center.y + Math.sin(centralAngle) * radius);
			rlVertex2f(center.x + Math.cos(centralAngle + angleStep) * radius, center.y + Math.sin(centralAngle + angleStep) * radius);
			centralAngle += angleStep;
		}
		rlEnd();
	}

	/** Draws a regular polygon's outline of a thickness, inside it, or outside it for a negative thickness.

		@param center  The center.
		@param sides  How many sides it has, 3 or more.
		@param radius  The distance from the center to each corner.
		@param rotation  The turn of its first corner from the right, in degrees clockwise.
		@param lineThick  The lines' thickness, measured across each side; past the center it fills the polygon, and a negative thickness
			draws the outline that thick outside it.
		@param color  The color. */
	static function DrawPolyLinesEx(center:Vector2, sides:Int, radius:Float, rotation:Float, lineThick:Float, color:Color):Void {
		if (sides < 3)
			sides = 3;
		var centralAngle = rotation * DEG2RAD,
			exteriorAngle = 360 / sides * DEG2RAD;
		var apothem = radius * Math.cos(DEG2RAD * 180 / sides);
		var outerRadius = 0., innerRadius = 0.;
		if (lineThick >= 0) {
			outerRadius = radius;
			innerRadius = Math.max(0, radius - lineThick * (radius / apothem));
		} else {
			lineThick *= -1;
			outerRadius = radius + lineThick * (radius / apothem);
			innerRadius = radius;
		}
		var cx = center.x, cy = center.y;
		rlSetTexture(GetShapesTexture().id);
		rlBegin(RL_QUADS);
		for (i in 0...sides) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			var nextAngle = centralAngle + exteriorAngle;
			shapeVertex(shapeU0, shapeV1, cx + Math.cos(centralAngle) * outerRadius, cy + Math.sin(centralAngle) * outerRadius);
			shapeVertex(shapeU0, shapeV0, cx + Math.cos(centralAngle) * innerRadius, cy + Math.sin(centralAngle) * innerRadius);
			shapeVertex(shapeU1, shapeV1, cx + Math.cos(nextAngle) * innerRadius, cy + Math.sin(nextAngle) * innerRadius);
			shapeVertex(shapeU1, shapeV0, cx + Math.cos(nextAngle) * outerRadius, cy + Math.sin(nextAngle) * outerRadius);
			centralAngle = nextAngle;
		}
		rlEnd();
		rlSetTexture(0);
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
		// A piece of no length keeps the scale of the piece before it, as raylib's does.
		var scale = 0.;
		for (i in 0...pointCount - 1) {
			var dx = points[i + 1].x - points[i].x,
				dy = points[i + 1].y - points[i].y;
			var length = Math.sqrt(dx * dx + dy * dy);
			if (length > 0)
				scale = thick / (2 * length);
			strip(points[i], points[i + 1], -scale * dy, scale * dx, color);
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
		var dy = 0., dx = 0., size = 0.;
		var currentX = 0., currentY = 0.;
		var vertices = [for (i in 0...2 * SPLINE_SEGMENT_DIVISIONS + 2) new Vector2()];
		for (i in 0...pointCount - 3) {
			var p1 = points[i],
				p2 = points[i + 1],
				p3 = points[i + 2],
				p4 = points[i + 3];
			var a0 = (-p1.x + 3 * p2.x - 3 * p3.x + p4.x) / 6,
				a1 = (3 * p1.x - 6 * p2.x + 3 * p3.x) / 6,
				a2 = (-3 * p1.x + 3 * p3.x) / 6,
				a3 = (p1.x + 4 * p2.x + p3.x) / 6;
			var b0 = (-p1.y + 3 * p2.y - 3 * p3.y + p4.y) / 6,
				b1 = (3 * p1.y - 6 * p2.y + 3 * p3.y) / 6,
				b2 = (-3 * p1.y + 3 * p3.y) / 6,
				b3 = (p1.y + 4 * p2.y + p3.y) / 6;
			currentX = a3;
			currentY = b3;
			if (i == 0)
				DrawCircleV(new Vector2(currentX, currentY), thick / 2, color);
			if (i > 0) {
				vertices[0].x = currentX + dy * size;
				vertices[0].y = currentY - dx * size;
				vertices[1].x = currentX - dy * size;
				vertices[1].y = currentY + dx * size;
			}
			for (j in 1...SPLINE_SEGMENT_DIVISIONS + 1) {
				var t = j / SPLINE_SEGMENT_DIVISIONS;
				var nextX = a3 + t * (a2 + t * (a1 + t * a0)),
					nextY = b3 + t * (b2 + t * (b1 + t * b0));
				dy = nextY - currentY;
				dx = nextX - currentX;
				size = .5 * thick / Math.sqrt(dx * dx + dy * dy);
				if (i == 0 && j == 1) {
					vertices[0].x = currentX + dy * size;
					vertices[0].y = currentY - dx * size;
					vertices[1].x = currentX - dy * size;
					vertices[1].y = currentY + dx * size;
				}
				vertices[2 * j + 1].x = nextX - dy * size;
				vertices[2 * j + 1].y = nextY + dx * size;
				vertices[2 * j].x = nextX + dy * size;
				vertices[2 * j].y = nextY - dx * size;
				currentX = nextX;
				currentY = nextY;
			}
			DrawTriangleStrip(vertices, 2 * SPLINE_SEGMENT_DIVISIONS + 2, color);
		}
		DrawCircleV(new Vector2(currentX, currentY), thick / 2, color);
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
		var dy = 0., dx = 0., size = 0.;
		var currentX = points[1].x, currentY = points[1].y;
		var vertices = [for (i in 0...2 * SPLINE_SEGMENT_DIVISIONS + 2) new Vector2()];
		DrawCircleV(new Vector2(currentX, currentY), thick / 2, color);
		for (i in 0...pointCount - 3) {
			var p1 = points[i],
				p2 = points[i + 1],
				p3 = points[i + 2],
				p4 = points[i + 3];
			if (i > 0) {
				vertices[0].x = currentX + dy * size;
				vertices[0].y = currentY - dx * size;
				vertices[1].x = currentX - dy * size;
				vertices[1].y = currentY + dx * size;
			}
			for (j in 1...SPLINE_SEGMENT_DIVISIONS + 1) {
				var t = j / SPLINE_SEGMENT_DIVISIONS;
				var q0 = (-1 * t * t * t) + (2 * t * t) + (-1 * t),
					q1 = (3 * t * t * t) + (-5 * t * t) + 2,
					q2 = (-3 * t * t * t) + (4 * t * t) + t,
					q3 = t * t * t - t * t;
				var nextX = .5 * ((p1.x * q0) + (p2.x * q1) + (p3.x * q2) + (p4.x * q3)),
					nextY = .5 * ((p1.y * q0) + (p2.y * q1) + (p3.y * q2) + (p4.y * q3));
				dy = nextY - currentY;
				dx = nextX - currentX;
				size = (.5 * thick) / Math.sqrt(dx * dx + dy * dy);
				if (i == 0 && j == 1) {
					vertices[0].x = currentX + dy * size;
					vertices[0].y = currentY - dx * size;
					vertices[1].x = currentX - dy * size;
					vertices[1].y = currentY + dx * size;
				}
				vertices[2 * j + 1].x = nextX - dy * size;
				vertices[2 * j + 1].y = nextY + dx * size;
				vertices[2 * j].x = nextX + dy * size;
				vertices[2 * j].y = nextY - dx * size;
				currentX = nextX;
				currentY = nextY;
			}
			DrawTriangleStrip(vertices, 2 * SPLINE_SEGMENT_DIVISIONS + 2, color);
		}
		DrawCircleV(new Vector2(currentX, currentY), thick / 2, color);
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
		@param thick  The thickness, in pixels; 0 or less draws nothing.
		@param color  The color. */
	static function DrawSplineSegmentLinear(p1:Vector2, p2:Vector2, thick:Float, color:Color):Void {
		var dx = p2.x - p1.x, dy = p2.y - p1.y;
		var length = Math.sqrt(dx * dx + dy * dy);
		if (length > 0 && thick > 0) {
			var scale = thick / (2 * length);
			strip(p1, p2, -scale * dy, scale * dx, color);
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
		var a0 = (-p1.x + 3 * p2.x - 3 * p3.x + p4.x) / 6,
			a1 = (3 * p1.x - 6 * p2.x + 3 * p3.x) / 6,
			a2 = (-3 * p1.x + 3 * p3.x) / 6,
			a3 = (p1.x + 4 * p2.x + p3.x) / 6;
		var b0 = (-p1.y + 3 * p2.y - 3 * p3.y + p4.y) / 6,
			b1 = (3 * p1.y - 6 * p2.y + 3 * p3.y) / 6,
			b2 = (-3 * p1.y + 3 * p3.y) / 6,
			b3 = (p1.y + 4 * p2.y + p3.y) / 6;
		curve(a3, b3, 0, t -> a3 + t * (a2 + t * (a1 + t * a0)), t -> b3 + t * (b2 + t * (b1 + t * b0)), thick, color);
	}

	/** Draws one piece of a Catmull-Rom spline of a thickness, through the middle two of four points.

		@param p1  The first point, which steers it.
		@param p2  The start.
		@param p3  The end.
		@param p4  The fourth point, which steers it.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineSegmentCatmullRom(p1:Vector2, p2:Vector2, p3:Vector2, p4:Vector2, thick:Float, color:Color):Void {
		inline function q0(t:Float)
			return (-1 * t * t * t) + (2 * t * t) + (-1 * t);
		inline function q1(t:Float)
			return (3 * t * t * t) + (-5 * t * t) + 2;
		inline function q2(t:Float)
			return (-3 * t * t * t) + (4 * t * t) + t;
		inline function q3(t:Float)
			return t * t * t - t * t;
		// raylib's starts from the first point, which steers it, not from the second, where it starts.
		curve(p1.x, p1.y, 0, t -> .5 * ((p1.x * q0(t)) + (p2.x * q1(t)) + (p3.x * q2(t)) + (p4.x * q3(t))),
			t -> .5 * ((p1.y * q0(t)) + (p2.y * q1(t)) + (p3.y * q2(t)) + (p4.y * q3(t))), thick, color);
	}

	/** Draws a quadratic Bezier curve of a thickness.

		@param p1  The start.
		@param c2  The control point.
		@param p3  The end.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineSegmentBezierQuadratic(p1:Vector2, c2:Vector2, p3:Vector2, thick:Float, color:Color):Void {
		curve(p1.x, p1.y, 1, t -> Math.pow(1 - t, 2) * p1.x + 2 * (1 - t) * t * c2.x + Math.pow(t, 2) * p3.x,
			t -> Math.pow(1 - t, 2) * p1.y + 2 * (1 - t) * t * c2.y + Math.pow(t, 2) * p3.y, thick, color);
	}

	/** Draws a cubic Bezier curve of a thickness.

		@param p1  The start.
		@param c2  The start's control point.
		@param c3  The end's control point.
		@param p4  The end.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	static function DrawSplineSegmentBezierCubic(p1:Vector2, c2:Vector2, c3:Vector2, p4:Vector2, thick:Float, color:Color):Void {
		curve(p1.x, p1.y, 1, t -> Math.pow(1 - t, 3) * p1.x
			+ 3 * Math.pow(1 - t, 2) * t * c2.x
			+ 3 * (1 - t) * Math.pow(t, 2) * c3.x
			+ Math.pow(t, 3) * p4.x,
			t -> Math.pow(1 - t, 3) * p1.y
				+ 3 * Math.pow(1 - t, 2) * t * c2.y
				+ 3 * (1 - t) * Math.pow(t, 2) * c3.y
				+ Math.pow(t, 3) * p4.y, thick, color);
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

	/** Returns a point on a quadratic Bezier curve: `GetSplinePointBezierQuad` by raylib 6's name for it.

		@param startPos  The start.
		@param controlPos  The control point.
		@param endPos  The end.
		@param t  How far along, 0 at the start to 1 at the end.
		@return  The point. */
	static function GetSplinePointBezierQuadratic(startPos:Vector2, controlPos:Vector2, endPos:Vector2, t:Float):Vector2 {
		return new Vector2(Interpolate.quadraticBezier(startPos.x, controlPos.x, endPos.x, t),
			Interpolate.quadraticBezier(startPos.y, controlPos.y, endPos.y, t));
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
		var at = new Vector2D();
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
	// raylib's SMOOTH_CIRCLE_ERROR_RATE and SPLINE_SEGMENT_DIVISIONS, and the angles its rounded rectangles' corners start at.
	static inline final SMOOTH_CIRCLE_ERROR_RATE = .5;
	static inline final SPLINE_SEGMENT_DIVISIONS = 24;
	static final CORNER_ANGLES = [180., 270., 0., 90.];

	// A vertex at a texture coordinate, as raylib's rlTexCoord2f and rlVertex2f pairs.
	static inline function shapeVertex(u:Float, v:Float, x:Float, y:Float):Void {
		rlTexCoord2f(u, v);
		rlVertex2f(x, y);
	}

	// One quad of raylib 6's thick outlines, its texture coordinates from the shapes texture's bottom-left, up, across and down.
	static inline function outlineQuad(a:Vector2, b:Vector2, c:Vector2, d:Vector2):Void {
		shapeVertex(shapeU0, shapeV1, a.x, a.y);
		shapeVertex(shapeU0, shapeV0, b.x, b.y);
		shapeVertex(shapeU1, shapeV0, c.x, c.y);
		shapeVertex(shapeU1, shapeV1, d.x, d.y);
	}

	// A point on a circle about a center, at an angle in degrees.
	static inline function arcX(cx:Float, angle:Float, radius:Float):Float {
		return cx + Math.cos(DEG2RAD * angle) * radius;
	}

	static inline function arcY(cy:Float, angle:Float, radius:Float):Float {
		return cy + Math.sin(DEG2RAD * angle) * radius;
	}

	// The widest angle between an arc's segments that keeps it within SMOOTH_CIRCLE_ERROR_RATE of the circle.
	static function smoothAngle(radius:Float):Float {
		return Math.acos(2 * Math.pow(1 - SMOOTH_CIRCLE_ERROR_RATE / radius, 2) - 1);
	}

	// How many segments raylib gives an arc: those asked for, unless that is fewer than one for each 90 degrees, when it picks enough
	// to keep within its error rate, rounded up.
	static function arcSegments(radius:Float, startAngle:Float, endAngle:Float, segments:Int):Int {
		var minSegments = Std.int(Math.fceil((endAngle - startAngle) / 90));
		if (segments >= minSegments)
			return segments;
		segments = Std.int(Math.fceil((endAngle - startAngle) * (2 * Math.PI / smoothAngle(radius)) / 360));
		return segments <= 0 ? minSegments : segments;
	}

	// raylib's EaseCubicInOut, for DrawLineBezier: from b at t 0 to b + c at t d.
	static function easeCubicInOut(t:Float, b:Float, c:Float, d:Float):Float {
		t /= .5 * d;
		if (t < 1)
			return .5 * c * t * t * t + b;
		t -= 2;
		return .5 * c * (t * t * t + 2) + b;
	}

	// A straight piece of a line, as raylib's four-point triangle strips: from a to b, rx and ry its half-thickness across.
	static function strip(a:Vector2, b:Vector2, rx:Float, ry:Float, color:Color):Void {
		DrawTriangleStrip([
			new Vector2(a.x - rx, a.y - ry),
			new Vector2(a.x + rx, a.y + ry),
			new Vector2(b.x - rx, b.y - ry),
			new Vector2(b.x + rx, b.y + ry)
		], 4, color);
	}

	// A curved spline segment of a thickness, as raylib draws each: a strip along the curve from a start, through the point at each
	// twenty-fourth of the way. The Bezier curves start at the first division, from their start; the B-spline and Catmull-Rom at the
	// start of the curve itself, whose first step, of no length, raylib's next step writes over.
	static function curve(startX:Float, startY:Float, first:Int, atX:Float->Float, atY:Float->Float, thick:Float, color:Color):Void {
		var points = [for (i in 0...2 * SPLINE_SEGMENT_DIVISIONS + 2) new Vector2()];
		var currentX = startX, currentY = startY;
		for (i in first...SPLINE_SEGMENT_DIVISIONS + 1) {
			var t = i / SPLINE_SEGMENT_DIVISIONS;
			var nextX = atX(t), nextY = atY(t);
			var dy = nextY - currentY, dx = nextX - currentX;
			var size = .5 * thick / Math.sqrt(dx * dx + dy * dy);
			if (i == 1) {
				points[0].x = currentX + dy * size;
				points[0].y = currentY - dx * size;
				points[1].x = currentX - dy * size;
				points[1].y = currentY + dx * size;
			}
			points[2 * i + 1].x = nextX - dy * size;
			points[2 * i + 1].y = nextY + dx * size;
			points[2 * i].x = nextX + dy * size;
			points[2 * i].y = nextY - dx * size;
			currentX = nextX;
			currentY = nextY;
		}
		DrawTriangleStrip(points, 2 * SPLINE_SEGMENT_DIVISIONS + 2, color);
	}
	#end
}
