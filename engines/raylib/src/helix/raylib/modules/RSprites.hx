package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
#end

/** Provides helix-raylib's instanced texture draw, written here and forwarded by `helix.raylib.extras.Sprites` (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RSprites {
	#if !macro
	/** Draws one part of a texture many times in one call, each copy placed by its own matrix. See `DrawTexturePro` for drawing a single copy.

		Each copy is what `DrawTexturePro` draws, in the batch's order, so the copies join the frame's sprite run and cost what the same
		draws would.

		A copy is the part, `source.width` by `source.height` pixels with its top left at the origin, taken through its matrix as
		`Vector2Transform` applies one. The fields read are `m0`, `m4` and `m12` across, and `m1`, `m5` and `m13` down.

		`MatrixTranslate` places a copy, `MatrixRotateZ` turns it about its top left and `MatrixScale` sizes it. Their products do all three.

		A negative `source.width` or `source.height` flips the part.

		Nothing is drawn when the texture's id, width or height is 0.

		@param texture  The texture.
		@param source  The part of it, in pixels.
		@param transforms  Each copy's matrix.
		@param tint  The tint, every copy's. */
	static function DrawTextureInstanced(texture:Texture2D, source:Rectangle, transforms:Array<Matrix>, tint:Color):Void {
		if (texture.id == 0 || texture.width == 0 || texture.height == 0)
			return;
		var w = Math.abs(source.width), h = Math.abs(source.height);
		var u0 = source.x / texture.width, v0 = source.y / texture.height;
		var u1 = (source.x + w) / texture.width,
			v1 = (source.y + h) / texture.height;
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
		if (texture.flipped) {
			v0 = 1 - v0;
			v1 = 1 - v1;
		}
		var handle = Textures.handle(texture.id);
		for (m in transforms) {
			// The corners (0, 0), (0, h), (w, h) and (w, 0) through the matrix, in DrawTexturePro's order.
			var ax = m.m12, ay = m.m13;
			var bx = m.m4 * h + m.m12, by = m.m5 * h + m.m13;
			var cx = m.m0 * w + m.m4 * h + m.m12,
				cy = m.m1 * w + m.m5 * h + m.m13;
			var ex = m.m0 * w + m.m12, ey = m.m1 * w + m.m13;
			Runtime.frame.quad(handle, ax, ay, bx, by, cx, cy, ex, ey, u0, v0, u1, v1, tint);
		}
	}
	#end
}
