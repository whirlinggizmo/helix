package helix.raylib.modules;

#if !macro
import helix.math.MathTools;
import helix.raylib.*;
import helix.raylib.internal.Runtime;
#end

/** Provides helix-raylib's texture fills, written here and forwarded by `helix.raylib.extras.Textures` (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RTextureFills {
	#if !macro
	/** Draws part of a texture as a fill: drawn at dest's size and shown up to the amount, in the direction. A radial fill turns
		about dest's middle, starts straight up and sweeps the whole circle. See `DrawTextureFillEx` for a radial fill's origin, start and
		sweep.

		@param texture  The texture.
		@param source  The part of the texture, in pixels.
		@param dest  Where the fill is drawn, in pixels.
		@param amount  How full, clamped to [0, 1].
		@param fillDirection  A `TEXTURE_FILL_` value.
		@param tint  The tint. */
	static function DrawTextureFill(texture:Texture2D, source:Rectangle, dest:Rectangle, amount:Float, fillDirection:Int, tint:Color):Void {
		fill(texture, source, dest, amount, fillDirection, dest.width / 2, dest.height / 2, 0, 360, tint);
	}

	/** Draws part of a texture as a fill, as `DrawTextureFill` does, a radial fill turning about an origin, starting at an angle and
		sweeping part of the circle: a gauge's half circle about its hub, say. A fill across or down ignores the origin and the angles.

		@param texture  The texture.
		@param source  The part of the texture, in pixels.
		@param dest  Where the fill is drawn, in pixels.
		@param amount  How full, clamped to [0, 1].
		@param fillDirection  A `TEXTURE_FILL_` value.
		@param origin  The point a radial fill turns about, from dest's top-left, in pixels, as `DrawTexturePro`'s origin.
		@param startAngle  Where a radial fill starts, in degrees clockwise from straight up, wrapped to [0, 360).
		@param fillDegrees  How far a full radial fill sweeps, in degrees, clamped to [0, 360].
		@param tint  The tint. */
	static function DrawTextureFillEx(texture:Texture2D, source:Rectangle, dest:Rectangle, amount:Float, fillDirection:Int, origin:Vector2, startAngle:Float,
			fillDegrees:Float, tint:Color):Void {
		fill(texture, source, dest, amount, fillDirection, origin.x, origin.y, startAngle, fillDegrees, tint);
	}

	/** Returns the middle of a fill's moving edge, for drawing something there: froth on a liquid, a thermometer's tip, a needle.
		At an amount of 0 the edge is at the fill's start, and at 1 at its far end. A radial fill's edge runs out from the point the fill
		turns about: x and y are that point, and z the edge's angle, in degrees clockwise from straight up. See `GetTextureFillEdgeEx`
		for a radial fill's origin, start and sweep.

		@param dest  Where the fill is drawn, in pixels.
		@param amount  How full, clamped to [0, 1].
		@param fillDirection  A `TEXTURE_FILL_` value.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  out, or the new vector: x and y in screen pixels, as dest's, z a radial fill's angle and 0 for the others. */
	static function GetTextureFillEdge(dest:Rectangle, amount:Float, fillDirection:Int, ?out:Vector3):Vector3 {
		return edge(dest, amount, fillDirection, dest.width / 2, dest.height / 2, 0, 360, out);
	}

	/** Returns the middle of a fill's moving edge, as `GetTextureFillEdge` does, for a radial fill turning about an origin, starting
		at an angle and sweeping part of the circle.

		@param dest  Where the fill is drawn, in pixels.
		@param amount  How full, clamped to [0, 1].
		@param fillDirection  A `TEXTURE_FILL_` value.
		@param origin  The point a radial fill turns about, from dest's top-left, in pixels, as `DrawTexturePro`'s origin.
		@param startAngle  Where a radial fill starts, in degrees clockwise from straight up, wrapped to [0, 360).
		@param fillDegrees  How far a full radial fill sweeps, in degrees, clamped to [0, 360].
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  out, or the new vector. */
	static function GetTextureFillEdgeEx(dest:Rectangle, amount:Float, fillDirection:Int, origin:Vector2, startAngle:Float, fillDegrees:Float,
			?out:Vector3):Vector3 {
		return edge(dest, amount, fillDirection, origin.x, origin.y, startAngle, fillDegrees, out);
	}

	// The fill directions (Textures' TEXTURE_FILL_ values), as the section reads them.
	static inline final LEFT_TO_RIGHT = 0;
	static inline final RIGHT_TO_LEFT = 1;
	static inline final TOP_TO_BOTTOM = 2;
	static inline final BOTTOM_TO_TOP = 3;
	static inline final CLOCKWISE = 4;
	static inline final COUNTER_CLOCKWISE = 5;

	// The polygon a radial fill clips dest to (clipped), its x and y in dest's pixels from its top-left, kept from draw to draw.
	static var polygon:Null<Array<Float>>;
	static var clipped:Null<Array<Float>>;

	// An angle in degrees wrapped to [0, 360).
	static function wrap(degrees:Float):Float {
		var wrapped = degrees % 360;
		return wrapped < 0 ? wrapped + 360 : wrapped;
	}

	// A fill as DrawTextureFillEx draws it, the origin from dest's top-left.
	static function fill(texture:Texture2D, source:Rectangle, dest:Rectangle, amount:Float, fillDirection:Int, originX:Float, originY:Float, startAngle:Float,
			fillDegrees:Float, tint:Color):Void {
		if (texture.id == 0 || texture.width == 0 || texture.height == 0 || dest.width <= 0 || dest.height <= 0)
			return;
		amount = MathTools.clamp(amount, 0, 1);
		if (amount == 0)
			return;
		// The source's texture coordinates at dest's left, right, top and bottom: a negative width or height flips it.
		var u0 = source.x / texture.width,
			u1 = (source.x + Math.abs(source.width)) / texture.width;
		var v0 = source.y / texture.height,
			v1 = (source.y + Math.abs(source.height)) / texture.height;
		if (source.width < 0) {
			var t = u0;
			u0 = u1;
			u1 = t;
		}
		if (source.height < 0) {
			var t = v0;
			v0 = v1;
			v1 = t;
		}
		var w = dest.width, h = dest.height;
		if (fillDirection != CLOCKWISE && fillDirection != COUNTER_CLOCKWISE) {
			var x0 = 0., y0 = 0., x1 = w, y1 = h;
			switch fillDirection {
				case LEFT_TO_RIGHT:
					x1 = w * amount;
				case RIGHT_TO_LEFT:
					x0 = w * (1 - amount);
				case TOP_TO_BOTTOM:
					y1 = h * amount;
				case BOTTOM_TO_TOP:
					y0 = h * (1 - amount);
				case _:
					return;
			}
			RTextureDraws.place(texture, dest, new Vector2(0, 0), 0, tint);
			RTextureDraws.cell(x0, y0, x1, y1, u0 + (u1 - u0) * x0 / w, v0 + (v1 - v0) * y0 / h, u0 + (u1 - u0) * x1 / w, v0 + (v1 - v0) * y1 / h);
			return;
		}
		var sweep = MathTools.clamp(fillDegrees, 0, 360) * amount;
		if (sweep <= 0)
			return;
		var from = wrap(startAngle);
		if (fillDirection == COUNTER_CLOCKWISE)
			from -= sweep;
		// A wedge of more than half a circle isn't convex: drawn as two halves.
		var wedges = sweep > 180 ? 2 : 1;
		var part = sweep / wedges;
		var handle = helix.raylib.internal.Textures.handle(texture.id);
		for (k in 0...wedges) {
			var points = wedge(w, h, originX, originY, from + k * part, from + (k + 1) * part);
			var n = Std.int(points.length / 2);
			inline function u(i:Int):Float
				return u0 + (u1 - u0) * points[i * 2] / w;
			inline function v(i:Int):Float
				return v0 + (v1 - v0) * points[i * 2 + 1] / h;
			for (i in 1...n - 1)
				RTextureDraws.triangle(handle, dest.x
					+ points[0], dest.y
					+ points[1], u(0), v(0), dest.x
					+ points[i * 2], dest.y
					+ points[i * 2 + 1], u(i),
					v(i), dest.x
					+ points[(i + 1) * 2], dest.y
					+ points[(i + 1) * 2 + 1], u(i + 1), v(i + 1), tint);
		}
	}

	// dest's rectangle, (0, 0) to (w, h), cut to the wedge about the origin from one angle clockwise to another at most 180 degrees on,
	// as a convex polygon's points (x, y, x, y...), in order around it. Clipped by the two half planes the wedge's sides bound
	// (Sutherland and Hodgman's clip).
	static function wedge(w:Float, h:Float, originX:Float, originY:Float, fromDegrees:Float, toDegrees:Float):Array<Float> {
		if (polygon == null) {
			polygon = [];
			clipped = [];
		}
		var points = polygon;
		points.resize(0);
		points.push(0);
		points.push(0);
		points.push(w);
		points.push(0);
		points.push(w);
		points.push(h);
		points.push(0);
		points.push(h);
		// The sides' directions on the screen, y down: straight up turned clockwise.
		var a = fromDegrees * Math.PI / 180, b = toDegrees * Math.PI / 180;
		points = clip(points, originX, originY, Math.sin(a), -Math.cos(a), 1);
		points = clip(points, originX, originY, Math.sin(b), -Math.cos(b), -1);
		return points;
	}

	// A convex polygon cut to the half plane on one side of the line through (ox, oy) along (dx, dy): clockwise of it on the screen for a
	// side of 1, counterclockwise for -1. Swaps the two kept arrays.
	static function clip(points:Array<Float>, ox:Float, oy:Float, dx:Float, dy:Float, side:Float):Array<Float> {
		var out = points == polygon ? clipped : polygon;
		out.resize(0);
		var n = Std.int(points.length / 2);
		inline function inside(i:Int):Float
			return side * (dx * (points[i * 2 + 1] - oy) - dy * (points[i * 2] - ox));
		for (i in 0...n) {
			var j = (i + 1) % n;
			var si = inside(i), sj = inside(j);
			if (si >= 0) {
				out.push(points[i * 2]);
				out.push(points[i * 2 + 1]);
			}
			if ((si >= 0) != (sj >= 0)) {
				var t = si / (si - sj);
				out.push(points[i * 2] + (points[j * 2] - points[i * 2]) * t);
				out.push(points[i * 2 + 1] + (points[j * 2 + 1] - points[i * 2 + 1]) * t);
			}
		}
		return out;
	}

	// A fill's edge as GetTextureFillEdgeEx returns it, the origin from dest's top-left.
	static function edge(dest:Rectangle, amount:Float, fillDirection:Int, originX:Float, originY:Float, startAngle:Float, fillDegrees:Float,
			out:Null<Vector3>):Vector3 {
		if (out == null)
			out = new Vector3(0, 0, 0);
		amount = MathTools.clamp(amount, 0, 1);
		out.x = dest.x + dest.width / 2;
		out.y = dest.y + dest.height / 2;
		out.z = 0;
		switch fillDirection {
			case LEFT_TO_RIGHT:
				out.x = dest.x + dest.width * amount;
			case RIGHT_TO_LEFT:
				out.x = dest.x + dest.width * (1 - amount);
			case TOP_TO_BOTTOM:
				out.y = dest.y + dest.height * amount;
			case BOTTOM_TO_TOP:
				out.y = dest.y + dest.height * (1 - amount);
			case CLOCKWISE | COUNTER_CLOCKWISE:
				var sweep = MathTools.clamp(fillDegrees, 0, 360) * amount;
				out.x = dest.x + originX;
				out.y = dest.y + originY;
				out.z = wrap(fillDirection == CLOCKWISE ? wrap(startAngle) + sweep : wrap(startAngle) - sweep);
			case _:
		}
		return out;
	}
	#end
}
