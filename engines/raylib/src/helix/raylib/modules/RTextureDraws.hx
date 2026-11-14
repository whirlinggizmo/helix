package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Runtime;
#end

/** Provides helix-raylib's tiled draw, nine-patch with repeating edges and textured polygon, written here and forwarded by
	`helix.raylib.extras.Textures` (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RTextureDraws {
	#if !macro
	/** Draws part of a texture repeated across dest, the last copies cut where they reach dest's far sides, as raylib's
		`DrawTexturePro` draws one copy.

		@param texture  The texture.
		@param source  The part of the texture repeated, in pixels.
		@param dest  Where the copies are drawn, in pixels.
		@param origin  The point dest rotates about, from its top-left, in pixels.
		@param rotation  The rotation, in degrees clockwise.
		@param scale  Each copy's size, a multiple of source's.
		@param tint  The tint. */
	static function DrawTextureTiled(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, scale:Float, tint:Color):Void {
		if (texture.id == 0 || texture.width == 0 || texture.height == 0 || scale <= 0)
			return;
		var tileWidth = Math.abs(source.width) * scale,
			tileHeight = Math.abs(source.height) * scale;
		if (tileWidth <= 0 || tileHeight <= 0)
			return;
		place(texture, dest, origin, rotation, tint);
		var u0 = source.x / texture.width, v0 = source.y / texture.height;
		var u1 = (source.x + source.width) / texture.width,
			v1 = (source.y + source.height) / texture.height;
		if (source.width < 0) {
			u0 = (source.x - source.width) / texture.width;
			u1 = source.x / texture.width;
		}
		if (source.height < 0) {
			v0 = (source.y - source.height) / texture.height;
			v1 = source.y / texture.height;
		}
		var y = 0.;
		while (y < dest.height) {
			var bottom = Math.min(y + tileHeight, dest.height);
			var vEnd = v0 + (v1 - v0) * (bottom - y) / tileHeight;
			var x = 0.;
			while (x < dest.width) {
				var right = Math.min(x + tileWidth, dest.width);
				cell(x, y, right, bottom, u0, v0, u0 + (u1 - u0) * (right - x) / tileWidth, vEnd);
				x = right;
			}
			y = bottom;
		}
	}

	/** Draws a nine-patch, as raylib's `DrawTextureNPatch` does, its middle and edges stretched or repeated along each axis: a rope
		frame whose twists repeat along its sides.

		@param texture  The texture.
		@param nPatchInfo  The patch and its borders.
		@param dest  Where the patch is drawn, in pixels.
		@param origin  The point dest rotates about, from its top-left, in pixels.
		@param rotation  The rotation, in degrees clockwise.
		@param horizontalPatchMode  How the middle and edges fill dest across: `NPATCH_MODE_STRETCH`, `NPATCH_MODE_TILE` or `NPATCH_MODE_TILE_FIT`.
		@param verticalPatchMode  How the middle and edges fill dest down, as `horizontalPatchMode`.
		@param tint  The tint. */
	static function DrawTextureNPatchEx(texture:Texture2D, nPatchInfo:NPatchInfo, dest:Rectangle, origin:Vector2, rotation:Float, horizontalPatchMode:Int,
			verticalPatchMode:Int, tint:Color):Void {
		drawPatch(texture, nPatchInfo, dest, origin, rotation, horizontalPatchMode, verticalPatchMode, tint, null);
	}

	/** Draws a texture inside a polygon: a portrait in a hexagon, a ground texture on a hill. Each point is drawn with the texture at its
		texture coordinate, the points joined to center as a triangle fan. The polygon is closed from the last point back to the first.

		@param texture  The texture.
		@param center  The fan's middle, in pixels, drawn with the texture's middle.
		@param points  The polygon's points, in pixels, in order around it.
		@param texcoords  Each point's texture coordinate, from (0, 0) at the texture's top-left to (1, 1) at its bottom-right.
		@param pointCount  How many points are drawn, each counted once.
		@param tint  The tint. */
	static function DrawTexturePoly(texture:Texture2D, center:Vector2, points:Array<Vector2>, texcoords:Array<Vector2>, pointCount:Int, tint:Color):Void {
		if (texture.id == 0 || pointCount < 2)
			return;
		var count = Std.int(Math.min(pointCount, Math.min(points.length, texcoords.length)));
		var handle = helix.raylib.internal.Textures.handle(texture.id);
		inline function v(t:Float):Float
			return texture.flipped ? 1 - t : t;
		for (i in 0...count) {
			var a = points[i], b = points[(i + 1) % count];
			var ta = texcoords[i], tb = texcoords[(i + 1) % count];
			triangle(handle, center.x, center.y, 0.5, v(0.5), a.x, a.y, ta.x, v(ta.y), b.x, b.y, tb.x, v(tb.y), tint);
		}
	}

	// A triangle of immediate vertices, put counterclockwise on the screen as raylib's triangles go, as a clockwise one is culled.
	static function triangle(handle:Int, ax:Float, ay:Float, au:Float, av:Float, bx:Float, by:Float, bu:Float, bv:Float, cx:Float, cy:Float, cu:Float,
			cv:Float, tint:Color):Void {
		var frame = Runtime.frame;
		frame.vertex(handle, helix.raylib.internal.Frame.TRIANGLES, ax, ay, 0, au, av, tint);
		// Clockwise on the screen, y down, when the cross product of a to b and a to c is positive.
		if ((bx - ax) * (cy - ay) - (by - ay) * (cx - ax) > 0) {
			frame.vertex(handle, helix.raylib.internal.Frame.TRIANGLES, cx, cy, 0, cu, cv, tint);
			frame.vertex(handle, helix.raylib.internal.Frame.TRIANGLES, bx, by, 0, bu, bv, tint);
		} else {
			frame.vertex(handle, helix.raylib.internal.Frame.TRIANGLES, bx, by, 0, bu, bv, tint);
			frame.vertex(handle, helix.raylib.internal.Frame.TRIANGLES, cx, cy, 0, cu, cv, tint);
		}
	}

	// A patch as DrawTextureNPatchEx draws it, and only its part inside clip when given (dest's own pixels, from its top-left, unrotated):
	// GuiSkins' fill shown up to the filled part. Its borders, layout and shrinking are DrawTextureNPatch's.
	static function drawPatch(texture:Texture2D, nPatchInfo:NPatchInfo, dest:Rectangle, origin:Vector2, rotation:Float, horizontalPatchMode:Int,
			verticalPatchMode:Int, tint:Color, clip:Null<Rectangle>):Void {
		if (texture.id <= 0 || texture.width == 0 || texture.height == 0)
			return;
		if (clip == null && horizontalPatchMode == TEXTURE_PATCH_STRETCH && verticalPatchMode == TEXTURE_PATCH_STRETCH) {
			RTextures.DrawTextureNPatch(texture, nPatchInfo, dest, origin, rotation, tint);
			return;
		}
		var layout = nPatchInfo.layout;
		var source = nPatchInfo.source;
		var sourceX = source.x, sourceY = source.y;
		var sourceWidth = Math.abs(source.width),
			sourceHeight = Math.abs(source.height);
		if (source.width < 0)
			sourceX -= sourceWidth;
		if (source.height < 0)
			sourceY -= sourceHeight;
		var patchWidth = Std.int(dest.width) <= 0 ? 0. : dest.width,
			patchHeight = Std.int(dest.height) <= 0 ? 0. : dest.height;
		if (layout == NPATCH_THREE_PATCH_HORIZONTAL)
			patchHeight = sourceHeight;
		if (layout == NPATCH_THREE_PATCH_VERTICAL)
			patchWidth = sourceWidth;
		// A three-patch's borders across its length alone: the whole source the other way.
		var left:Float = layout == NPATCH_THREE_PATCH_VERTICAL ? 0 : nPatchInfo.left,
			right:Float = layout == NPATCH_THREE_PATCH_VERTICAL ? 0 : nPatchInfo.right,
			top:Float = layout == NPATCH_THREE_PATCH_HORIZONTAL ? 0 : nPatchInfo.top,
			bottom:Float = layout == NPATCH_THREE_PATCH_HORIZONTAL ? 0 : nPatchInfo.bottom;
		if (patchColumns == null) {
			patchColumns = [];
			patchRows = [];
		}
		var columns = segments(patchWidth, left, right, sourceX / texture.width, sourceWidth / texture.width, sourceWidth, horizontalPatchMode, patchColumns);
		var rows = segments(patchHeight, top, bottom, sourceY / texture.height, sourceHeight / texture.height, sourceHeight, verticalPatchMode, patchRows);
		place(texture, dest, origin, rotation, tint);
		var j = 0;
		while (j < rows.length) {
			var i = 0;
			while (i < columns.length) {
				var x0 = columns[i],
					x1 = columns[i + 1],
					u0 = columns[i + 2],
					u1 = columns[i + 3];
				var y0 = rows[j], y1 = rows[j + 1], v0 = rows[j + 2], v1 = rows[j + 3];
				if (clip != null) {
					var cx0 = Math.max(x0, clip.x),
						cx1 = Math.min(x1, clip.x + clip.width);
					var cy0 = Math.max(y0, clip.y),
						cy1 = Math.min(y1, clip.y + clip.height);
					if (cx0 < cx1 && cy0 < cy1) {
						var du = (u1 - u0) / (x1 - x0),
							dv = (v1 - v0) / (y1 - y0);
						cell(cx0, cy0, cx1, cy1, u0 + du * (cx0 - x0), v0 + dv * (cy0 - y0), u0 + du * (cx1 - x0), v0 + dv * (cy1 - y0));
					}
				} else
					cell(x0, y0, x1, y1, u0, v0, u1, v1);
				i += 4;
			}
			j += 4;
		}
	}

	// One axis of a patch, into out, as runs of four numbers: where a piece starts and ends in dest, and where on the texture (0 to 1). The borders
	// shrink to fit a length shorter than both, dropping the middle, as DrawTextureNPatch's do; the middle is stretched, or repeated at
	// its own size (cut at the far border) or a whole number of times.
	static function segments(length:Float, first:Float, last:Float, start:Float, span:Float, texels:Float, mode:Int, out:Array<Float>):Array<Float> {
		out.resize(0);
		if (length <= 0 || texels <= 0)
			return out;
		var middle = true;
		if (length <= first + last) {
			middle = false;
			if (first + last > 0) {
				first = first / (first + last) * length;
				last = length - first;
			}
		}
		var texel = span / texels;
		var middleStart = start + first * texel,
			middleEnd = start + span - last * texel;
		inline function piece(a:Float, b:Float, ua:Float, ub:Float)
			if (b > a) {
				out.push(a);
				out.push(b);
				out.push(ua);
				out.push(ub);
			}
		piece(0, first, start, middleStart);
		if (middle) {
			var from = first, to = length - last;
			var tile = texels - first - last;
			if (mode == TEXTURE_PATCH_STRETCH || tile <= 0)
				piece(from, to, middleStart, middleEnd);
			else if (mode == TEXTURE_PATCH_TILE_FIT) {
				var count = Std.int(Math.max(1, Math.round((to - from) / tile)));
				var size = (to - from) / count;
				for (k in 0...count)
					piece(from + k * size, k == count - 1 ? to : from + (k + 1) * size, middleStart, middleEnd);
			} else {
				var at = from;
				while (at < to) {
					var end = Math.min(at + tile, to);
					piece(at, end, middleStart, middleStart + (middleEnd - middleStart) * (end - at) / tile);
					at = end;
				}
			}
		}
		piece(length - last, length, middleEnd, start + span);
		return out;
	}

	// NPATCH_MODE_STRETCH and NPATCH_MODE_TILE_FIT (Textures'), as the sections read them.
	static inline final TEXTURE_PATCH_STRETCH = 0;
	static inline final TEXTURE_PATCH_TILE_FIT = 2;

	// Where cell puts its quads (place): dest's top-left, turned about an origin, with a texture's handle and flip and the tint.
	static var placeHandle:Int;
	static var placeFlipped:Bool;
	static var placeX:Float;
	static var placeY:Float;
	static var placeOriginX:Float;
	static var placeOriginY:Float;
	static var placeCos:Float;
	static var placeSin:Float;
	static var placeTint:Color;
	// A patch's columns and rows (segments), kept from draw to draw.
	static var patchColumns:Null<Array<Float>>;
	static var patchRows:Null<Array<Float>>;

	// Sets where cell puts its quads.
	static function place(texture:Texture2D, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void {
		placeHandle = helix.raylib.internal.Textures.handle(texture.id);
		placeFlipped = texture.flipped;
		placeX = dest.x;
		placeY = dest.y;
		placeOriginX = origin.x;
		placeOriginY = origin.y;
		placeCos = 1;
		placeSin = 0;
		if (rotation != 0) {
			var angle = rotation * Math.PI / 180;
			placeCos = Math.cos(angle);
			placeSin = Math.sin(angle);
		}
		placeTint = tint;
	}

	// A quad from (x0, y0) to (x1, y1) in dest's pixels, from its top-left, showing the texture from (u0, v0) to (u1, v1), as place set.
	static function cell(x0:Float, y0:Float, x1:Float, y1:Float, u0:Float, v0:Float, u1:Float, v1:Float):Void {
		if (placeFlipped) {
			v0 = 1 - v0;
			v1 = 1 - v1;
		}
		var c = placeCos, s = placeSin, x = placeX, y = placeY;
		var ax = x0 - placeOriginX,
			ay = y0 - placeOriginY,
			bx = x1 - placeOriginX,
			by = y1 - placeOriginY;
		Runtime.frame.quad(placeHandle, x
			+ ax * c
			- ay * s, y
			+ ax * s
			+ ay * c, x
			+ ax * c
			- by * s, y
			+ ax * s
			+ by * c, x
			+ bx * c
			- by * s,
			y
			+ bx * s
			+ by * c, x
			+ bx * c
			- ay * s, y
			+ bx * s
			+ ay * c, u0, v0, u1, v1, placeTint);
	}
	#end
}
