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

/** Holds raylib's rtext (text in the default font), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
class RText {
	#if !macro
	// ---- Text ----

	/** Draws text in raylib's default font. A size under 10 is drawn at 10, and letters are a tenth of the size apart.

		@param text  The text; "\n" starts a line.
		@param posX  The left edge.
		@param posY  The top edge.
		@param fontSize  The height of a line, in pixels.
		@param color  The color. */
	public static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void {
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		var spacing = Std.int(fontSize / DefaultFont.HEIGHT),
			scale = fontSize / DefaultFont.HEIGHT;
		var font = defaultFont();
		var x = 0., y = 0.;
		for (code in new haxe.iterators.StringIteratorUnicode(text)) {
			if (code == "\n".code) {
				y += fontSize + 2;
				x = 0;
				continue;
			}
			var index = glyph(code);
			var w = DefaultFont.WIDTHS[index];
			if (code != " ".code && code != "\t".code) {
				var gx = fontRecs[index * 2], gy = fontRecs[index * 2 + 1];
				DrawTexturePro(font, new Rectangle(gx, gy, w, DefaultFont.HEIGHT), new Rectangle(posX + x, posY + y, w * scale, fontSize), new Vector2(), 0,
					color);
			}
			x += w * scale + spacing;
		}
	}

	/** Returns the width text is drawn at by `DrawText`, its widest line's.

		@param text  The text.
		@param fontSize  The height of a line, in pixels.
		@return  The width, in pixels. */
	public static function MeasureText(text:String, fontSize:Int):Int {
		if (text.length == 0)
			return 0;
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		var spacing = Std.int(fontSize / DefaultFont.HEIGHT),
			scale = fontSize / DefaultFont.HEIGHT;
		var width = 0., widest = 0., count = 0, most = 0;
		for (code in new haxe.iterators.StringIteratorUnicode(text)) {
			count++;
			if (code == "\n".code) {
				if (width > widest)
					widest = width;
				width = 0;
				count = 0;
			} else
				width += DefaultFont.WIDTHS[glyph(code)];
			if (count > most)
				most = count;
		}
		if (width > widest)
			widest = width;
		return Std.int(widest * scale + (most - 1) * spacing);
	}

	/** Draws the frames a second, as "60 FPS", in green.

		@param posX  The left edge.
		@param posY  The top edge. */
	public static function DrawFPS(posX:Int, posY:Int):Void {
		var fps = GetFPS();
		var color = fps < 15 ? RED : fps < 30 ? ORANGE : LIME;
		DrawText('${fps < 10 ? " " : ""}$fps FPS', posX, posY, 20, color);
	}
	#end
}
