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
import helix.ray.raylib.RAsync.*;
#end

/** Holds raylib's rtextures (textures, render textures and colors), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RTextures {
	#if !macro
	// ---- Textures ----

	/** raylib's texture load, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadTextureAsync` loads it.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void)")
	static function LoadTexture(fileName:String):Texture2D {
		throw "LoadTexture is unimplemented";
	}

	// The texture of an image file `LoadTextureAsync` brought in. A file loaded again shares its first load's texture, and the image goes
	// to the GPU when first drawn.

	static function loadTexture(fileName:String):Texture2D {
		var path = normalize(fileName);
		var image = Runtime.image(path);
		if (image == null) {
			Runtime.log(4, 'LoadTextureAsync: $path couldn\'t be read');
			return new Texture2D();
		}
		return new Texture2D(Textures.fromImage(path, image), image.width, image.height);
	}

	/** Frees a texture: one load of its file, the GPU's copy with the last.

		@param texture  The texture. */
	static function UnloadTexture(texture:Texture2D):Void {
		if (texture.id != 0)
			Textures.release(texture.id);
		texture.id = 0;
	}

	/** Returns whether a texture was loaded.

		@param texture  The texture.
		@return  True when it holds an image. */
	static function IsTextureValid(texture:Texture2D):Bool {
		return texture.id != 0;
	}

	/** Draws a texture, its top-left corner at a point.

		@param texture  The texture.
		@param posX  The x.
		@param posY  The y.
		@param tint  The color it is multiplied by; `WHITE` keeps it as it is. */
	static function DrawTexture(texture:Texture2D, posX:Int, posY:Int, tint:Color):Void {
		DrawTexturePro(texture, new Rectangle(0, 0, texture.width, texture.height), new Rectangle(posX, posY, texture.width, texture.height), new Vector2(),
			0, tint);
	}

	/** Draws a texture, its top-left corner at a point.

		@param texture  The texture.
		@param position  The point.
		@param tint  The color it is multiplied by. */
	static function DrawTextureV(texture:Texture2D, position:Vector2, tint:Color):Void {
		DrawTexturePro(texture, new Rectangle(0, 0, texture.width, texture.height), new Rectangle(position.x, position.y, texture.width, texture.height),
			new Vector2(), 0, tint);
	}

	/** Draws a texture turned about its top-left corner and scaled.

		@param texture  The texture.
		@param position  The top-left corner.
		@param rotation  Clockwise, in degrees.
		@param scale  The scale.
		@param tint  The color it is multiplied by. */
	static function DrawTextureEx(texture:Texture2D, position:Vector2, rotation:Float, scale:Float, tint:Color):Void {
		DrawTexturePro(texture, new Rectangle(0, 0, texture.width, texture.height),
			new Rectangle(position.x, position.y, texture.width * scale, texture.height * scale), new Vector2(), rotation, tint);
	}

	/** Draws part of a texture. A negative source width or height flips it.

		@param texture  The texture.
		@param source  The part, in the texture's pixels.
		@param position  Where its top-left corner goes.
		@param tint  The color it is multiplied by. */
	static function DrawTextureRec(texture:Texture2D, source:Rectangle, position:Vector2, tint:Color):Void {
		DrawTexturePro(texture, source, new Rectangle(position.x, position.y, Math.abs(source.width), Math.abs(source.height)), new Vector2(), 0, tint);
	}

	/** Draws part of a texture into a rectangle, turned about an origin. A negative source width or height flips it.

		@param texture  The texture.
		@param source  The part, in the texture's pixels.
		@param dest  Where it goes; its x and y are where the origin lands.
		@param origin  The point it turns about, from dest's top-left corner.
		@param rotation  Clockwise, in degrees.
		@param tint  The color it is multiplied by. */
	static function DrawTexturePro(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void {
		if (texture.id == 0 || texture.width == 0 || texture.height == 0)
			return;
		var u0 = source.x / texture.width, v0 = source.y / texture.height;
		var u1 = (source.x + Math.abs(source.width)) / texture.width,
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
		var angle = rotation * Math.PI / 180,
			c = Math.cos(angle),
			s = Math.sin(angle);
		var xs = [-origin.x, dest.width - origin.x],
			ys = [-origin.y, dest.height - origin.y];
		if (texture.flipped) {
			v0 = 1 - v0;
			v1 = 1 - v1;
		}
		var handle = Textures.handle(texture.id);
		var corner = (i:Int, j:Int, u:Float, v:Float) -> flat(handle, dest.x + xs[i] * c - ys[j] * s, dest.y + xs[i] * s + ys[j] * c, u, v, tint);
		corner(0, 0, u0, v0);
		corner(0, 1, u0, v1);
		corner(1, 1, u1, v1);
		corner(0, 0, u0, v0);
		corner(1, 1, u1, v1);
		corner(1, 0, u1, v0);
	}

	// ---- Colors ----

	/** Returns a color as four numbers, 0 to 1 each.

		@param color  The color.
		@return  Red, green, blue and alpha as x, y, z and w. */
	static function ColorNormalize(color:Color):Vector4 {
		return new Vector4(color.r / 255, color.g / 255, color.b / 255, color.a / 255);
	}

	/** Returns a color from four numbers, 0 to 1 each.

		@param normalized  Red, green, blue and alpha as x, y, z and w.
		@return  The color. */
	static function ColorFromNormalized(normalized:Vector4):Color {
		return new Color(Std.int(normalized.x * 255), Std.int(normalized.y * 255), Std.int(normalized.z * 255), Std.int(normalized.w * 255));
	}

	/** Returns a color with its alpha scaled.

		@param color  The color.
		@param alpha  0 (clear) to 1 (as it is).
		@return  The new color. */
	static function Fade(color:Color, alpha:Float):Color {
		return ColorAlpha(color, alpha);
	}

	/** Returns a color with an alpha.

		@param color  The color.
		@param alpha  0 (clear) to 1 (opaque).
		@return  The new color. */
	static function ColorAlpha(color:Color, alpha:Float):Color {
		var a = alpha < 0 ? 0. : alpha > 1 ? 1. : alpha;
		return new Color(color.r, color.g, color.b, Std.int(255 * a));
	}

	/** Returns whether two colors are the same, alpha too.

		@param col1  One color.
		@param col2  The other.
		@return  True when red, green, blue and alpha are each equal. */
	static function ColorIsEqual(col1:Color, col2:Color):Bool {
		return col1.r == col2.r && col1.g == col2.g && col1.b == col2.b && col1.a == col2.a;
	}

	/** Returns a color as one number, 0xRRGGBBAA.

		@param color  The color.
		@return  Red in the top byte, alpha in the bottom; a red of 128 or more makes it negative. */
	static function ColorToInt(color:Color):Int {
		return ((color.r & 255) << 24) | ((color.g & 255) << 16) | ((color.b & 255) << 8) | (color.a & 255);
	}

	/** Returns a color's hue, saturation and value.

		@param color  The color; its alpha is ignored.
		@return  The hue in degrees, 0 to 360, as x; the saturation and value, 0 to 1 each, as y and z. A gray's hue and saturation are 0. */
	static function ColorToHSV(color:Color):Vector3 {
		var hsv = new Vector3();
		var r = f32(color.r / 255),
			g = f32(color.g / 255),
			b = f32(color.b / 255);
		var min = r < g ? r : g;
		min = min < b ? min : b;
		var max = r > g ? r : g;
		max = max > b ? max : b;
		hsv.z = max;
		var delta = f32(max - min);
		if (delta < f32(0.00001))
			return hsv;
		if (max > 0)
			hsv.y = f32(delta / max);
		else {
			hsv.x = Math.NaN;
			return hsv;
		}
		if (r >= max)
			hsv.x = f32(f32(g - b) / delta);
		else if (g >= max)
			hsv.x = f32(2 + f32(f32(b - r) / delta));
		else
			hsv.x = f32(4 + f32(f32(r - g) / delta));
		hsv.x = f32(hsv.x * 60);
		if (hsv.x < 0)
			hsv.x = f32(hsv.x + 360);
		return hsv;
	}

	/** Returns the color of a hue, saturation and value; its alpha is 255.

		@param hue  The hue, in degrees, 0 to 360.
		@param saturation  0 (gray) to 1.
		@param value  0 (black) to 1.
		@return  The color. */
	static function ColorFromHSV(hue:Float, saturation:Float, value:Float):Color {
		hue = f32(hue);
		saturation = f32(saturation);
		value = f32(value);
		var channel = (offset:Float) -> {
			var k = f32(offset + f32(hue / 60)) % 6;
			var t = f32(4 - k);
			k = t < k ? t : k;
			k = k < 1 ? k : 1;
			k = k > 0 ? k : 0;
			return byte(f32(f32(value - f32(f32(value * saturation) * k)) * 255));
		}
		return new Color(channel(5), channel(3), channel(1), 255);
	}

	/** Returns a color multiplied by another, channel by channel.

		@param color  The color.
		@param tint  The color it is multiplied by; `WHITE` keeps it as it is.
		@return  The new color. */
	static function ColorTint(color:Color, tint:Color):Color {
		var times = (a:Int, b:Int) -> Std.int(a * b / 255) & 255;
		return new Color(times(color.r, tint.r), times(color.g, tint.g), times(color.b, tint.b), times(color.a, tint.a));
	}

	/** Returns a color made darker or lighter; its alpha is kept.

		@param color  The color.
		@param factor  -1 (black) to 1 (white); 0 keeps it as it is.
		@return  The new color. */
	static function ColorBrightness(color:Color, factor:Float):Color {
		factor = f32(factor);
		if (factor > 1)
			factor = 1;
		else if (factor < -1)
			factor = -1;
		var channel = if (factor < 0) {
			var scale = f32(1 + factor);
			(c:Int) -> byte(f32(c * scale));
		} else(c:Int) -> byte(f32(f32((255 - c) * factor) + c));
		return new Color(channel(color.r), channel(color.g), channel(color.b), color.a);
	}

	/** Returns a color with more or less contrast about the middle gray; its alpha is kept.

		@param color  The color.
		@param contrast  -1 (all middle gray) to 1; 0 keeps it as it is.
		@return  The new color. */
	static function ColorContrast(color:Color, contrast:Float):Color {
		contrast = f32(contrast);
		if (contrast < -1)
			contrast = -1;
		else if (contrast > 1)
			contrast = 1;
		contrast = f32(1 + contrast);
		contrast = f32(contrast * contrast);
		var channel = (c:Int) -> {
			var p = f32(f32(f32(f32(f32(c / 255) - 0.5) * contrast) + 0.5) * 255);
			return byte(p < 0 ? 0 : p > 255 ? 255 : p);
		}
		return new Color(channel(color.r), channel(color.g), channel(color.b), color.a);
	}

	/** Returns a color drawn over another: the source, multiplied by a tint, blended into the destination by its alpha.

		@param dst  The color underneath.
		@param src  The color drawn over it.
		@param tint  The color the source is multiplied by; `WHITE` keeps it as it is.
		@return  The blend. */
	static function ColorAlphaBlend(dst:Color, src:Color, tint:Color):Color {
		var tinted = (s:Int, t:Int) -> ((s * (t + 1)) >> 8) & 255;
		var sr = tinted(src.r, tint.r),
			sg = tinted(src.g, tint.g),
			sb = tinted(src.b, tint.b),
			sa = tinted(src.a, tint.a);
		if (sa == 0)
			return new Color(dst.r, dst.g, dst.b, dst.a);
		if (sa == 255)
			return new Color(sr, sg, sb, sa);
		var alpha = sa + 1;
		var outA = ((alpha * 256 + dst.a * (256 - alpha)) >> 8) & 255;
		var channel = (s:Int, d:Int) -> (Std.int((s * alpha * 256 + d * dst.a * (256 - alpha)) / outA) >> 8) & 255;
		return new Color(channel(sr, dst.r), channel(sg, dst.g), channel(sb, dst.b), outA);
	}

	/** Returns a color part way from one color to another.

		@param color1  The color at 0.
		@param color2  The color at 1.
		@param factor  How far, 0 to 1.
		@return  The color between them. */
	static function ColorLerp(color1:Color, color2:Color, factor:Float):Color {
		factor = f32(factor);
		if (factor < 0)
			factor = 0;
		else if (factor > 1)
			factor = 1;
		var rest = f32(1 - factor);
		var channel = (a:Int, b:Int) -> byte(f32(f32(rest * a) + f32(factor * b)));
		return new Color(channel(color1.r, color2.r), channel(color1.g, color2.g), channel(color1.b, color2.b), channel(color1.a, color2.a));
	}

	/** Returns the color of one number, 0xRRGGBBAA.

		@param hexValue  Red in the top byte, alpha in the bottom.
		@return  The color. */
	static function GetColor(hexValue:Int):Color {
		return new Color((hexValue >>> 24) & 255, (hexValue >> 16) & 255, (hexValue >> 8) & 255, hexValue & 255);
	}

	/** Returns how many bytes an image's pixels take in a format.

		@param width  The width, in pixels.
		@param height  The height.
		@param format  The format (`PIXELFORMAT_*`).
		@return  The bytes; a compressed format smaller than 4 by 4 pixels takes a whole block, 8 or 16 bytes, and an unknown format 0. */
	static function GetPixelDataSize(width:Int, height:Int, format:Int):Int {
		var bits = switch format {
			case PIXELFORMAT_UNCOMPRESSED_GRAYSCALE: 8;
			case PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA | PIXELFORMAT_UNCOMPRESSED_R5G6B5 | PIXELFORMAT_UNCOMPRESSED_R5G5B5A1 | PIXELFORMAT_UNCOMPRESSED_R4G4B4A4: 16;
			case PIXELFORMAT_UNCOMPRESSED_R8G8B8A8: 32;
			case PIXELFORMAT_UNCOMPRESSED_R8G8B8: 24;
			case PIXELFORMAT_UNCOMPRESSED_R32: 32;
			case PIXELFORMAT_UNCOMPRESSED_R32G32B32: 32 * 3;
			case PIXELFORMAT_UNCOMPRESSED_R32G32B32A32: 32 * 4;
			case PIXELFORMAT_UNCOMPRESSED_R16: 16;
			case PIXELFORMAT_UNCOMPRESSED_R16G16B16: 16 * 3;
			case PIXELFORMAT_UNCOMPRESSED_R16G16B16A16: 16 * 4;
			case PIXELFORMAT_COMPRESSED_DXT1_RGB | PIXELFORMAT_COMPRESSED_DXT1_RGBA | PIXELFORMAT_COMPRESSED_ETC1_RGB | PIXELFORMAT_COMPRESSED_ETC2_RGB |
				PIXELFORMAT_COMPRESSED_PVRT_RGB | PIXELFORMAT_COMPRESSED_PVRT_RGBA: 4;
			case PIXELFORMAT_COMPRESSED_DXT3_RGBA | PIXELFORMAT_COMPRESSED_DXT5_RGBA | PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA |
				PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA: 8;
			case PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA: 2;
			case _: 0;
		}
		var size = Std.int(bits / 8 * width * height);
		if (width < 4 && height < 4) {
			if (format >= PIXELFORMAT_COMPRESSED_DXT1_RGB && format < PIXELFORMAT_COMPRESSED_DXT3_RGBA)
				size = 8;
			else if (format >= PIXELFORMAT_COMPRESSED_DXT3_RGBA && format < PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA)
				size = 16;
		}
		return size;
	}

	// raylib's color math is in single precision: a number rounded to the nearest float, as each of its operations rounds.
	static inline function f32(x:Float):Float {
		return haxe.io.FPHelper.i32ToFloat(haxe.io.FPHelper.floatToI32(x));
	}

	// A number as raylib's (unsigned char) cast makes it: truncated, its low 8 bits.
	static inline function byte(x:Float):Int {
		return Std.int(x) & 255;
	}

	// ---- Render textures ----

	/** Makes a texture to draw into, with depth.

		@param width  Its width, in pixels.
		@param height  Its height.
		@return  The render texture. */
	static function LoadRenderTexture(width:Int, height:Int):RenderTexture2D {
		var target = Runtime.graphics.createRenderTarget(width, height);
		var texture = new Texture2D(Textures.fromHandle(target), width, height);
		texture.flipped = true;
		return new RenderTexture(target, texture, new Texture2D(0, width, height));
	}

	/** Returns whether a render texture was made.

		@param target  The render texture.
		@return  True when it was. */
	static function IsRenderTextureValid(target:RenderTexture2D):Bool {
		return target.id != 0;
	}

	/** Frees a render texture.

		@param target  The render texture. */
	static function UnloadRenderTexture(target:RenderTexture2D):Void {
		if (target.texture.id != 0)
			Textures.release(target.texture.id);
		target.id = 0;
		target.texture.id = 0;
	}

	/** Draws into a render texture until `EndTextureMode`. Unlike raylib's, what was drawn into it in an earlier frame isn't kept: each
		frame's drawing into it starts cleared, to clear black unless `ClearBackground` gives a color.

		@param target  The render texture. */
	static function BeginTextureMode(target:RenderTexture2D):Void {
		Runtime.frame.toTarget(target.id, target.texture.width, target.texture.height);
	}

	/** Goes back to drawing on the screen. */
	static function EndTextureMode():Void {
		Runtime.frame.toScreen();
	}

	/** Sets how a texture is sampled when drawn larger or smaller: `TEXTURE_FILTER_POINT`, raylib's default, takes the nearest texel,
		and the others blend the nearest four, as `TEXTURE_FILTER_BILINEAR` does (there are no mipmaps here).

		@param texture  The texture.
		@param filter  The filter (`TEXTURE_FILTER_*`). */
	static function SetTextureFilter(texture:Texture2D, filter:Int):Void {
		Textures.setSampling(texture.id, new helix.platform.Sampling(filter == TEXTURE_FILTER_POINT ? Nearest : Linear));
	}

	// ---- Images, as far as fonts need them ----

	/** Makes a texture of an image. Its pixels are 8-bit grayscale, grayscale and alpha, RGB or RGBA (`PIXELFORMAT_UNCOMPRESSED_*`);
		another format gives no texture, and says so.

		@param image  The image.
		@return  The texture. */
	static function LoadTextureFromImage(image:Image):Texture2D {
		var pixels = rgba(image);
		if (pixels == null) {
			Runtime.log(LOG_WARNING, 'LoadTextureFromImage: pixel format ${image.format} isn\'t in helix-ray yet');
			return new Texture2D();
		}
		var texture = new Texture2D(Textures.fromImage("", new helix.services.images.Image("", image.width, image.height, pixels)), image.width, image.height);
		return texture;
	}

	/** Frees an image's pixels.

		@param image  The image. */
	static function UnloadImage(image:Image):Void {
		image.data = null;
	}

	// An image's pixels as 8-bit RGBA, or null for a format not read here.
	static function rgba(image:Image):Null<haxe.io.Bytes> {
		var data:Null<haxe.io.Bytes> = image.data,
			count = image.width * image.height;
		if (data == null)
			return null;
		var channels = switch image.format {
			case PIXELFORMAT_UNCOMPRESSED_GRAYSCALE: 1;
			case PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA: 2;
			case PIXELFORMAT_UNCOMPRESSED_R8G8B8: 3;
			case PIXELFORMAT_UNCOMPRESSED_R8G8B8A8: 4;
			case _: 0;
		}
		if (channels == 0 || data.length < count * channels)
			return null;
		var pixels = haxe.io.Bytes.alloc(count * 4);
		for (i in 0...count) {
			var at = i * channels;
			var r = data.get(at),
				g = channels >= 3 ? data.get(at + 1) : r,
				b = channels >= 3 ? data.get(at + 2) : r;
			var a = channels == 2 ? data.get(at + 1) : channels == 4 ? data.get(at + 3) : 255;
			pixels.set(i * 4, r);
			pixels.set(i * 4 + 1, g);
			pixels.set(i * 4 + 2, b);
			pixels.set(i * 4 + 3, a);
		}
		return pixels;
	}
	#end
}
