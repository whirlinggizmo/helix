package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
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
import helix.ray.raylib.HelixRay.*;
#end

/** Holds raylib's rshapes (2D shapes and their collisions), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RShapes {
	#if !macro
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

	/** Draws a filled triangle; its points go counterclockwise, as raylib's do.

		@param v1  The first point.
		@param v2  The second point.
		@param v3  The third point.
		@param color  The color. */
	static function DrawTriangle(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void {
		var w = Runtime.frame.white;
		flat(w, v1.x, v1.y, 0, 0, color);
		flat(w, v2.x, v2.y, 0, 0, color);
		flat(w, v3.x, v3.y, 0, 0, color);
	}

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
	#end
}
