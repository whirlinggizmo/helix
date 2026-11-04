package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.Matrix3D;
import helix.raylib.internal.DefaultFont;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Models;
import helix.raylib.internal.Mipmaps;
import helix.raylib.internal.Pixels;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RAudio.*;
import helix.raylib.modules.RMath.*;
#end

/** Holds raylib's rtextures (textures, render textures and colors), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RTextures {
	#if !macro
	// ---- Textures ----

	/** raylib's texture load, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadTextureAsync` loads it.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadTexture: Synchronous loading is not supported. See LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)")
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

	/** Lets go of a texture (docs/DECISIONS.md 25): the program's hold from its load, its id set to 0. The texture is freed, the GPU's
		copy with it, when nothing else holds it: another load of its file, or a material map given it, keeps it until that lets go. Given
		a map's texture (`map.texture`), as `UnloadTexture(model.materials[0].maps[0].texture)` frees one a program gave a map without
		keeping it, it lets go of one hold and leaves the map's id: the map draws it while anything holds it, and lets go in turn when its
		material is freed.

		@param texture  The texture. */
	static function UnloadTexture(texture:Texture2D):Void {
		Models.unloadTexture(texture);
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
		quad(texture, 0, 0, texture.width, texture.height, posX, posY, texture.width, texture.height, 0, 0, 0, tint);
	}

	/** Draws a texture, its top-left corner at a point.

		@param texture  The texture.
		@param position  The point.
		@param tint  The color it is multiplied by. */
	static function DrawTextureV(texture:Texture2D, position:Vector2, tint:Color):Void {
		quad(texture, 0, 0, texture.width, texture.height, position.x, position.y, texture.width, texture.height, 0, 0, 0, tint);
	}

	/** Draws a texture turned about its top-left corner and scaled.

		@param texture  The texture.
		@param position  The top-left corner.
		@param rotation  Clockwise, in degrees.
		@param scale  The scale.
		@param tint  The color it is multiplied by. */
	static function DrawTextureEx(texture:Texture2D, position:Vector2, rotation:Float, scale:Float, tint:Color):Void {
		quad(texture, 0, 0, texture.width, texture.height, position.x, position.y, texture.width * scale, texture.height * scale, 0, 0, rotation, tint);
	}

	/** Draws part of a texture. A negative source width or height flips it.

		@param texture  The texture.
		@param source  The part, in the texture's pixels.
		@param position  Where its top-left corner goes.
		@param tint  The color it is multiplied by. */
	static function DrawTextureRec(texture:Texture2D, source:Rectangle, position:Vector2, tint:Color):Void {
		quad(texture, source.x, source.y, source.width, source.height, position.x, position.y, Math.abs(source.width), Math.abs(source.height), 0, 0, 0, tint);
	}

	/** Draws part of a texture into a rectangle, turned about an origin. A negative source width or height flips it.

		@param texture  The texture.
		@param source  The part, in the texture's pixels.
		@param dest  Where it goes; its x and y are where the origin lands.
		@param origin  The point it turns about, from dest's top-left corner.
		@param rotation  Clockwise, in degrees.
		@param tint  The color it is multiplied by. */
	static function DrawTexturePro(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void {
		quad(texture, source.x, source.y, source.width, source.height, dest.x, dest.y, dest.width, dest.height, origin.x, origin.y, rotation, tint);
	}

	// Part of a texture into a rectangle turned about an origin, as DrawTexturePro draws it, from numbers alone so a draw allocates nothing.
	static function quad(texture:Texture2D, sx:Float, sy:Float, sw:Float, sh:Float, dx:Float, dy:Float, dw:Float, dh:Float, ox:Float, oy:Float,
			rotation:Float, tint:Color):Void {
		if (texture.id == 0 || texture.width == 0 || texture.height == 0)
			return;
		var u0 = sx / texture.width, v0 = sy / texture.height;
		var u1 = (sx + Math.abs(sw)) / texture.width,
			v1 = (sy + Math.abs(sh)) / texture.height;
		if (sw < 0) {
			var t = u0;
			u0 = u1;
			u1 = t;
		}
		if (sh < 0) {
			var t = v0;
			v0 = v1;
			v1 = t;
		}
		if (texture.flipped) {
			v0 = 1 - v0;
			v1 = 1 - v1;
		}
		// The corners from the origin, turned: unturned, the sine and cosine aren't computed.
		var x0 = -ox, x1 = dw - ox, y0 = -oy, y1 = dh - oy;
		var c = 1., s = 0.;
		if (rotation != 0) {
			var angle = rotation * Math.PI / 180;
			c = Math.cos(angle);
			s = Math.sin(angle);
		}
		var handle = Textures.handle(texture.id);
		var ax = dx + x0 * c - y0 * s, ay = dy + x0 * s + y0 * c;
		var bx = dx + x0 * c - y1 * s, by = dy + x0 * s + y1 * c;
		var cx = dx + x1 * c - y1 * s, cy = dy + x1 * s + y1 * c;
		var ex = dx + x1 * c - y0 * s, ey = dy + x1 * s + y0 * c;
		var f = Runtime.frame;
		f.vertex(handle, Frame.QUADS, ax, ay, 0, u0, v0, tint);
		f.vertex(handle, Frame.QUADS, bx, by, 0, u0, v1, tint);
		f.vertex(handle, Frame.QUADS, cx, cy, 0, u1, v1, tint);
		f.vertex(handle, Frame.QUADS, ex, ey, 0, u1, v0, tint);
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
		@return  The bytes; a compressed format smaller than 4 by 4 pixels takes a whole block, 8 or 16 bytes. An unknown format, a width
			or height of 0 or less, and a size of 2 GB or more (with a warning) give 0. */
	static function GetPixelDataSize(width:Int, height:Int, format:Int):Int {
		if (width <= 0 || height <= 0)
			return 0;
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
		// In whole bits, as raylib's 64-bit integers: exact below 2^53.
		var bytes = Math.ffloor(1. * width * height * bits / 8);
		if (bytes >= 2147483647) {
			Runtime.log(LOG_WARNING, "Requested image size is larger than 2GB, it can not be allocated");
			return 0;
		}
		var size = Std.int(bytes);
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
		return Pixels.f32(x);
	}

	// A number as raylib's (unsigned char) cast makes it: truncated, its low 8 bits.
	static inline function byte(x:Float):Int {
		return Std.int(x) & 255;
	}

	// ---- Render textures ----

	/** Makes a texture to draw into, with depth, 8-bit RGBA.

		@param width  Its width, in pixels.
		@param height  Its height.
		@return  The render texture. */
	static function LoadRenderTexture(width:Int, height:Int):RenderTexture2D {
		// raylib 5.5's render textures: a depth buffer and one sample, however the window is multisampled.
		var target = Runtime.graphics.createRenderTarget(width, height, helix.platform.TextureFormat.Rgba8, true, 1);
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
		Models.unloadTexture(target.texture);
		target.id = 0;
		target.texture.id = 0;
	}

	/** Draws into a render texture until `EndTextureMode`, over what it holds: what was drawn into it before, in this frame or an earlier
		one, stays until `ClearBackground` clears it, as raylib's does. A render texture never drawn into holds transparent black.

		@param target  The render texture. */
	static function BeginTextureMode(target:RenderTexture2D):Void {
		Runtime.frame.toTarget(target.id, target.texture.width, target.texture.height);
	}

	/** Goes back to drawing on the screen. */
	static function EndTextureMode():Void {
		Runtime.frame.toScreen();
	}

	/** Sets how a texture is sampled when drawn larger or smaller, as raylib's GL does, by whether the texture has mipmaps
		(`texture.mipmaps`, as this copy of it says): `TEXTURE_FILTER_POINT`, raylib's default, takes the nearest texel (of the nearest
		mipmap); `TEXTURE_FILTER_BILINEAR` blends the nearest four (of the nearest mipmap); `TEXTURE_FILTER_TRILINEAR` blends the nearest
		four of the two nearest mipmaps, or, without mipmaps, is `TEXTURE_FILTER_BILINEAR`, with a warning. `TEXTURE_FILTER_ANISOTROPIC_4X`,
		`8X` and `16X` read up to that many texels along a surface seen at a slant, leaving the filter as it was; the GPU uses it only with
		`TEXTURE_FILTER_TRILINEAR` on a mipmapped texture. A cubemap (`LoadTextureCubemap`) is left unchanged: raylib's binds it as a 2D texture, which GL refuses.

		@param texture  The texture.
		@param filter  The filter (`TEXTURE_FILTER_*`). */
	static function SetTextureFilter(texture:Texture2D, filter:Int):Void {
		var mipmapped = texture.mipmaps > 1,
			sampling = Textures.samplingOfId(texture.id);
		switch filter {
			case TEXTURE_FILTER_POINT:
				sampling = sampling.withFilter(Nearest).withMipmapFilter(mipmapped ? Nearest : None);
			case TEXTURE_FILTER_BILINEAR:
				sampling = sampling.withFilter(Linear).withMipmapFilter(mipmapped ? Nearest : None);
			case TEXTURE_FILTER_TRILINEAR:
				if (!mipmapped)
					Runtime.log(LOG_WARNING, 'TEXTURE: [ID ${texture.id}] No mipmaps available for TRILINEAR texture filtering');
				sampling = sampling.withFilter(Linear).withMipmapFilter(mipmapped ? Linear : None);
			case TEXTURE_FILTER_ANISOTROPIC_4X:
				sampling = sampling.withAnisotropy(4);
			case TEXTURE_FILTER_ANISOTROPIC_8X:
				sampling = sampling.withAnisotropy(8);
			case TEXTURE_FILTER_ANISOTROPIC_16X:
				sampling = sampling.withAnisotropy(16);
			case _:
				return;
		}
		Textures.setSampling(texture.id, sampling);
	}

	/** Makes a texture's mipmaps, down to 1 by 1, as raylib's does with GL's `glGenerateMipmap`: each level the rounded average of the
		2 by 2 above it, made on the CPU, so the same on every target. `texture.mipmaps` becomes their count. The texture's filter is left
		as it was: `SetTextureFilter` after it reads them. A texture already drawn gets them from its pixels read back from the GPU, and
		draws asked for before it this frame don't; a render texture's and a cubemap's can't be made, with a warning.

		@param texture  The texture. */
	static function GenTextureMipmaps(texture:Texture2D):Void {
		if (texture.id <= 0)
			return;
		if (texture.flipped || Textures.isCube(texture.id)) {
			Runtime.log(LOG_WARNING, 'TEXTURE: [ID ${texture.id}] Failed to generate mipmaps');
			return;
		}
		Textures.generateMipmaps(texture.id);
		var largest = texture.width > texture.height ? texture.width : texture.height;
		texture.mipmaps = 1 + Math.floor(Math.log(largest) / Math.log(2));
		Runtime.log(LOG_INFO, 'TEXTURE: [ID ${texture.id}] Mipmaps generated automatically, total: ${texture.mipmaps}');
	}

	// ---- Images: loading and exporting ----

	/** raylib's image load, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadImageAsync` loads it.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadImage: Synchronous loading is not supported. See LoadImageAsync(fileName:String, loaded:Image->Void, ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)")
	static function LoadImage(fileName:String):Image {
		throw "LoadImage is unimplemented";
	}

	/** raylib's load of an image's raw pixels, which waits for the file. A page can't wait, so a call doesn't compile on any target:
		`LoadImageRawAsync` loads it.

		@param fileName  The file.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param format  The pixel format (`PIXELFORMAT_*`).
		@param headerSize  The bytes before the pixels.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadImageRaw: Synchronous loading is not supported. See LoadImageRawAsync(fileName:String, width:Int, height:Int, format:Int, headerSize:Int, loaded:Image->Void, ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)")
	static function LoadImageRaw(fileName:String, width:Int, height:Int, format:Int, headerSize:Int):Image {
		throw "LoadImageRaw is unimplemented";
	}

	/** raylib's decode of an image file's bytes, which returns the image. Images are decoded asynchronously here, so a call doesn't
		compile on any target: `LoadImageFromMemoryAsync` decodes it.

		@param fileType  The file's extension, ".png".
		@param fileData  The file's bytes.
		@param dataSize  How many.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadImageFromMemory: Images are decoded asynchronously. See LoadImageFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image->Void, ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)")
	static function LoadImageFromMemory(fileType:String, fileData:haxe.io.Bytes, dataSize:Int):Image {
		throw "LoadImageFromMemory is unimplemented";
	}

	/** raylib's load of an animated image's frames, which waits for the file. A page can't wait, so a call doesn't compile on any target:
		`LoadImageAnimAsync` loads them.

		@param fileName  The file.
		@param frames  Would be set to how many frames.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadImageAnim: Synchronous loading is not supported. See LoadImageAnimAsync(fileName:String, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)")
	static function LoadImageAnim(fileName:String, frames:Array<Int>):Image {
		throw "LoadImageAnim is unimplemented";
	}

	/** raylib's decode of an animated image file's bytes, which returns its frames. Images are decoded asynchronously here, so a call
		doesn't compile on any target: `LoadImageAnimFromMemoryAsync` decodes them.

		@param fileType  The file's extension, ".gif".
		@param fileData  The file's bytes.
		@param dataSize  How many.
		@param frames  Would be set to how many frames.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadImageAnimFromMemory: Images are decoded asynchronously. See LoadImageAnimFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)")
	static function LoadImageAnimFromMemory(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, frames:Array<Int>):Image {
		throw "LoadImageAnimFromMemory is unimplemented";
	}

	/** raylib's read of a texture back from the GPU, which waits for it. A texture is read back asynchronously here, so a call doesn't
		compile on any target: `LoadImageFromTextureAsync` reads it.

		@param texture  The texture.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadImageFromTexture: A texture is read back asynchronously. See LoadImageFromTextureAsync(texture:Texture2D, loaded:Image->Void, ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)")
	static function LoadImageFromTexture(texture:Texture2D):Image {
		throw "LoadImageFromTexture is unimplemented";
	}

	/** raylib's read of the screen, which waits for the GPU. The screen is read back asynchronously here, as a frame ends, so a call
		doesn't compile on any target: `LoadImageFromScreenAsync` reads it.

		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadImageFromScreen: The screen is read back asynchronously. See LoadImageFromScreenAsync(loaded:Image->Void, ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)")
	static function LoadImageFromScreen():Image {
		throw "LoadImageFromScreen is unimplemented";
	}

	/** Returns whether an image holds pixels: data, a size, a format and a mipmap level.

		@param image  The image.
		@return  True when it does. */
	static function IsImageValid(image:Image):Bool {
		return image.data != null && image.width > 0 && image.height > 0 && image.format > 0 && image.mipmaps > 0;
	}

	/** Frees an image's pixels.

		@param image  The image. */
	static function UnloadImage(image:Image):Void {
		image.data = null;
	}

	/** raylib's image export, done when it returns. A file is kept later, once written, so a call doesn't compile on any target:
		`ExportImageAsync` writes it and answers.

		@param image  The image.
		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("ExportImage: A file is written later, or is refused. See ExportImageAsync(image:Image, fileName:String, ?done:Void->Void, ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)")
	static function ExportImage(image:Image, fileName:String):Bool {
		throw "ExportImage is unimplemented";
	}

	/** Returns an image encoded as a file in memory: ".png" alone, as raylib's. Like raylib's, an image's bytes are read as 8-bit gray,
		gray and alpha, RGB or RGBA by its format, and as RGBA for any other format, which a 16-bit format has too few of: those it lacks
		read as 0.

		@param image  The image.
		@param fileType  ".png" or ".PNG".
		@param fileSize  Its first element is set to the file's size, 0 for none.
		@return  The file, or null for another type or an empty image. */
	static function ExportImageToMemory(image:Image, fileType:String, fileSize:Array<Int>):haxe.io.Bytes {
		if (fileSize != null)
			fileSize[0] = 0;
		if (image.width == 0 || image.height == 0 || image.data == null)
			return null;
		if (fileType != ".png" && fileType != ".PNG")
			return null;
		var channels = channelsOf(image.format);
		var file = helix.formats.png.PngFile.write(image.width, image.height, channels, padded(image.data, image.width * image.height * channels));
		if (fileSize != null)
			fileSize[0] = file.length;
		return file;
	}

	/** raylib's export of an image as code, done when it returns. A file is kept later, once written, so a call doesn't compile on any target:
		`ExportImageAsCodeAsync` writes it and answers.

		@param image  The image.
		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("ExportImageAsCode: A file is written later, or is refused. See ExportImageAsCodeAsync(image:Image, fileName:String, ?done:Void->Void, ?failed:String->Void) in helix.raylib.extras.Textures (import helix.raylib.extras.Textures.*;)")
	static function ExportImageAsCode(image:Image, fileName:String):Bool {
		throw "ExportImageAsCode is unimplemented";
	}

	// ExportImageAsCodeAsync's text, as raylib's writes it.
	static function imageAsCode(image:Image, fileName:String):String {
		var dataSize = GetPixelDataSize(image.width, image.height, image.format);
		var text = new StringBuf();
		text.add("////////////////////////////////////////////////////////////////////////////////////////\n");
		text.add("//                                                                                    //\n");
		text.add("// ImageAsCode exporter v1.0 - Image pixel data exported as an array of bytes         //\n");
		text.add("//                                                                                    //\n");
		text.add("// more info and bugs-report:  github.com/raysan5/raylib                              //\n");
		text.add("// feedback and support:       ray[at]raylib.com                                      //\n");
		text.add("//                                                                                    //\n");
		text.add("// Copyright (c) 2018-2024 Ramon Santamaria (@raysan5)                                //\n");
		text.add("//                                                                                    //\n");
		text.add("////////////////////////////////////////////////////////////////////////////////////////\n\n");
		var name = new StringBuf(), base = GetFileNameWithoutExt(fileName);
		for (i in 0...base.length) {
			var c = StringTools.fastCodeAt(base, i);
			name.addChar(c >= "a".code && c <= "z".code ? c - 32 : c);
		}
		var varName = name.toString();
		text.add("// Image data information\n");
		text.add('#define ${varName}_WIDTH    ${image.width}\n');
		text.add('#define ${varName}_HEIGHT   ${image.height}\n');
		text.add('#define ${varName}_FORMAT   ${image.format}          // raylib internal pixel format\n\n');
		text.add('static unsigned char ${varName}_DATA[$dataSize] = { ');
		var data = image.data;
		inline function at(i:Int):String
			return StringTools.hex(data != null && i >= 0 && i < data.length ? data.get(i) : 0).toLowerCase();
		for (i in 0...dataSize - 1)
			text.add(i % 20 == 0 ? '0x${at(i)},\n' : '0x${at(i)}, ');
		text.add('0x${at(dataSize - 1)} };\n');
		return text.toString();
	}

	// ExportImage's file: PNG, QOI or the raw pixels, by the name's extension; null, with raylib's warning for QOI's formats, for none.
	static function encodeImage(image:Image, fileName:String):Null<haxe.io.Bytes> {
		var count = image.width * image.height;
		if (IsFileExtension(fileName, ".png")) {
			var channels = channelsOf(image.format);
			var pixels = channels == 4
				&& image.format != PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 ? Pixels.colors(image.data, image.width, image.height, image.format) : image.data;
			return helix.formats.png.PngFile.write(image.width, image.height, channels, padded(pixels, count * channels));
		}
		if (IsFileExtension(fileName, ".qoi")) {
			var channels = image.format == PIXELFORMAT_UNCOMPRESSED_R8G8B8 ? 3 : image.format == PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 ? 4 : 0;
			if (channels == 0) {
				Runtime.log(LOG_WARNING, "IMAGE: Image pixel format must be R8G8B8 or R8G8B8A8");
				return null;
			}
			return helix.formats.qoi.QoiFile.write(image.width, image.height, channels, padded(image.data, count * channels));
		}
		if (IsFileExtension(fileName, ".raw"))
			return padded(image.data, GetPixelDataSize(image.width, image.height, image.format));
		return null;
	}

	// The channels raylib's PNG export writes a format with: its own for the 8-bit formats, else 4.
	static function channelsOf(format:Int):Int {
		return switch format {
			case PIXELFORMAT_UNCOMPRESSED_GRAYSCALE: 1;
			case PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA: 2;
			case PIXELFORMAT_UNCOMPRESSED_R8G8B8: 3;
			case _: 4;
		}
	}

	// Bytes of a size: these, cut or followed by zeros.
	static function padded(bytes:haxe.io.Bytes, size:Int):haxe.io.Bytes {
		if (bytes.length == size)
			return bytes;
		var out = haxe.io.Bytes.alloc(size);
		out.fill(0, size, 0);
		out.blit(0, bytes, 0, bytes.length < size ? bytes.length : size);
		return out;
	}

	// ---- Images: made ----

	/** Returns an image of one color, RGBA.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param color  The color.
		@return  The image. */
	static function GenImageColor(width:Int, height:Int, color:Color):Image {
		return rgbaImage(helix.services.images.Image.filled(width, height, Pixels.argb(Pixels.ofColor(color))));
	}

	/** Returns a gradient from one color to another, RGBA.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param direction  The direction, in degrees: 0 top to bottom, 90 left to right.
		@param start  The color it starts from.
		@param end  The color it ends at.
		@return  The image. */
	static function GenImageGradientLinear(width:Int, height:Int, direction:Int, start:Color, end:Color):Image {
		var radians = f32(f32((90 - direction) / 180) * f32(3.14159));
		return rgbaImage(helix.services.images.Image.gradientLinear(width, height, radians, Pixels.argb(Pixels.ofColor(start)),
			Pixels.argb(Pixels.ofColor(end))));
	}

	/** Returns a round gradient out from the middle, RGBA.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param density  How far the inner color holds, 0 (the middle alone) to 1 (out to the nearer edge).
		@param inner  The color in the middle.
		@param outer  The color at the edge and beyond.
		@return  The image. */
	static function GenImageGradientRadial(width:Int, height:Int, density:Float, inner:Color, outer:Color):Image {
		return rgbaImage(helix.services.images.Image.gradientRadial(width, height, density, Pixels.argb(Pixels.ofColor(inner)),
			Pixels.argb(Pixels.ofColor(outer))));
	}

	/** Returns a square gradient out from the middle, RGBA.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param density  How far the inner color holds, 0 (the middle alone) to 1 (out to the edges).
		@param inner  The color in the middle.
		@param outer  The color at the edges.
		@return  The image. */
	static function GenImageGradientSquare(width:Int, height:Int, density:Float, inner:Color, outer:Color):Image {
		return rgbaImage(helix.services.images.Image.gradientSquare(width, height, density, Pixels.argb(Pixels.ofColor(inner)),
			Pixels.argb(Pixels.ofColor(outer))));
	}

	/** Returns a checkerboard of two colors, RGBA. A square size under 1 is taken as 1, where raylib's divides by zero.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param checksX  Each square's width, in pixels.
		@param checksY  Each square's height, in pixels.
		@param col1  The top-left square's color.
		@param col2  The color of the squares beside it.
		@return  The image. */
	static function GenImageChecked(width:Int, height:Int, checksX:Int, checksY:Int, col1:Color, col2:Color):Image {
		return rgbaImage(helix.services.images.Image.checked(width, height, checksX, checksY, Pixels.argb(Pixels.ofColor(col1)),
			Pixels.argb(Pixels.ofColor(col2))));
	}

	/** Returns white noise, RGBA: each pixel white or black, drawn from `GetRandomValue`, one number a pixel, so `SetRandomSeed` repeats it.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param factor  The chance of white, 0 to 1.
		@return  The image. */
	static function GenImageWhiteNoise(width:Int, height:Int, factor:Float):Image {
		return rgbaImage(helix.services.images.Image.whiteNoise(width, height, factor, RCore.random));
	}

	/** Returns Perlin noise in gray, RGBA: stb_perlin's fractal noise, 6 octaves.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param offsetX  How far it is moved left, in pixels.
		@param offsetY  How far it is moved up, in pixels.
		@param scale  How much of the noise it shows: larger is finer.
		@return  The image. */
	static function GenImagePerlinNoise(width:Int, height:Int, offsetX:Int, offsetY:Int, scale:Float):Image {
		return rgbaImage(helix.services.images.Image.perlinNoise(width, height, offsetX, offsetY, scale));
	}

	/** Returns cellular noise in gray, RGBA: each pixel's distance to the nearest of points scattered one a tile, drawn from
		`GetRandomValue`, so `SetRandomSeed` repeats it. A tile size under 1 is taken as 1, where raylib's divides by zero.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param tileSize  The tiles' size, in pixels: bigger is bigger cells.
		@return  The image. */
	static function GenImageCellular(width:Int, height:Int, tileSize:Int):Image {
		return rgbaImage(helix.services.images.Image.cellular(width, height, tileSize, RCore.random));
	}

	/** Returns an image of text's bytes, grayscale: its UTF-8, a byte a pixel, rows top first, the rest black.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param text  The text; null gives a black image.
		@return  The image. */
	static function GenImageText(width:Int, height:Int, text:String):Image {
		var size = width * height, data = haxe.io.Bytes.alloc(size);
		data.fill(0, size, 0);
		if (text != null) {
			var bytes = haxe.io.Bytes.ofString(text);
			data.blit(0, bytes, 0, bytes.length > size ? size : bytes.length);
		}
		return new Image(data, width, height, 1, PIXELFORMAT_UNCOMPRESSED_GRAYSCALE);
	}

	// An image of helix-services' pixels, RGBA, which it keeps.
	static function rgbaImage(image:helix.services.images.Image):Image {
		return new Image(image.pixels, image.width, image.height, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
	}

	// ---- Images: changed ----

	/** Returns a copy of an image, its mipmaps too.

		@param image  The image.
		@return  The copy. */
	static function ImageCopy(image:Image):Image {
		var width = image.width, height = image.height, size = 0;
		for (_ in 0...image.mipmaps) {
			size += GetPixelDataSize(width, height, image.format);
			width = Std.int(width / 2);
			height = Std.int(height / 2);
			if (width < 1)
				width = 1;
			if (height < 1)
				height = 1;
		}
		var data = haxe.io.Bytes.alloc(size > 0 ? size : 0);
		data.fill(0, data.length, 0);
		copyBytes(data, 0, image.data, 0, data.length);
		return new Image(data, image.width, image.height, image.mipmaps, image.format);
	}

	/** Returns a rectangle of an image, in its format. A rectangle not wholly inside the image, of no size, or of a compressed image
		gives an empty image, with a warning.

		@param image  The image.
		@param rec  The rectangle, in pixels, cut to whole pixels.
		@return  The image. */
	static function ImageFromImage(image:Image, rec:Rectangle):Image {
		var result = new Image();
		if (image.data == null || image.width == 0 || image.height == 0)
			return result;
		if (image.format >= Pixels.COMPRESSED) {
			Runtime.log(LOG_WARNING, "IMAGE: Image manipulation not supported for compressed formats");
			return result;
		}
		var rx = f32(rec.x),
			ry = f32(rec.y),
			rw = f32(rec.width),
			rh = f32(rec.height);
		var x = Std.int(rx),
			y = Std.int(ry),
			width = Std.int(rw),
			height = Std.int(rh);
		if (!(rx >= 0 && ry >= 0 && rw > 0 && rh > 0 && x + width <= image.width && y + height <= image.height)) {
			Runtime.log(LOG_WARNING, "IMAGE: ImageFromImage(), rectangle provided not valid");
			return result;
		}
		var bytesPerPixel = GetPixelDataSize(1, 1, image.format);
		var data = haxe.io.Bytes.alloc(width * height * bytesPerPixel);
		data.fill(0, data.length, 0);
		for (row in 0...height)
			copyBytes(data, row * width * bytesPerPixel, image.data, ((row + y) * image.width + x) * bytesPerPixel, width * bytesPerPixel);
		return new Image(data, width, height, 1, image.format);
	}

	/** Returns one channel of an image as grayscale: 0 red, 1 green, 2 blue, 3 alpha. A channel the format lacks is taken as raylib takes
		it, with its warning: a one-channel format's only channel, gray and alpha's alpha, an RGB format's red.

		@param image  The image.
		@param selectedChannel  The channel.
		@return  The image. */
	static function ImageFromChannel(image:Image, selectedChannel:Int):Image {
		var result = new Image();
		if (image.data == null || image.width == 0 || image.height == 0)
			return result;
		var format = image.format;
		if (selectedChannel < 0) {
			Runtime.log(LOG_WARNING, "Channel cannot be negative. Setting channel to 0.");
			selectedChannel = 0;
		}
		if (format == PIXELFORMAT_UNCOMPRESSED_GRAYSCALE
			|| format == PIXELFORMAT_UNCOMPRESSED_R32
			|| format == PIXELFORMAT_UNCOMPRESSED_R16) {
			if (selectedChannel > 0) {
				Runtime.log(LOG_WARNING, "This image has only 1 channel. Setting channel to it.");
				selectedChannel = 0;
			}
		} else if (format == PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA) {
			if (selectedChannel > 1) {
				Runtime.log(LOG_WARNING, "This image has only 2 channels. Setting channel to alpha.");
				selectedChannel = 1;
			}
		} else if (format == PIXELFORMAT_UNCOMPRESSED_R5G6B5
			|| format == PIXELFORMAT_UNCOMPRESSED_R8G8B8
			|| format == PIXELFORMAT_UNCOMPRESSED_R32G32B32
			|| format == PIXELFORMAT_UNCOMPRESSED_R16G16B16) {
			if (selectedChannel > 2) {
				Runtime.log(LOG_WARNING, "This image has only 3 channels. Setting channel to red.");
				selectedChannel = 0;
			}
		}
		if (selectedChannel > 3) {
			Runtime.log(LOG_WARNING, "ImageFromChannel supports channels 0 to 3 (rgba). Setting channel to alpha.");
			selectedChannel = 3;
		}
		var count = image.width * image.height,
			pixels = haxe.io.Bytes.alloc(count),
			data = image.data,
			c = selectedChannel;
		pixels.fill(0, count, 0);
		if (format >= Pixels.COMPRESSED)
			Runtime.log(LOG_WARNING, "IMAGE: Pixel data retrieval not supported for compressed image formats");
		else
			for (i in 0...count) {
				var value:Float = switch format {
					case PIXELFORMAT_UNCOMPRESSED_GRAYSCALE: f32(data.get(i + c) / 255);
					case PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA: f32(data.get(i * 2 + c) / 255);
					case PIXELFORMAT_UNCOMPRESSED_R5G5B5A1:
						var p = data.getUInt16(i * 2);
						c == 0 ? f32((p >> 11) * ONE_31) : c == 1 ? f32(((p >> 6) & 31) * ONE_31) : c == 2 ? f32(((p >> 1) & 31) * ONE_31) : (p & 1) == 0 ? 0 : 1;
					case PIXELFORMAT_UNCOMPRESSED_R5G6B5:
						var p = data.getUInt16(i * 2);
						c == 0 ? f32((p >> 11) * ONE_31) : c == 1 ? f32(((p >> 5) & 63) * ONE_63) : c == 2 ? f32((p & 31) * ONE_31) : -1;
					case PIXELFORMAT_UNCOMPRESSED_R4G4B4A4:
						var p = data.getUInt16(i * 2);
						f32(((p >> (12 - 4 * c)) & 15) * ONE_15);
					case PIXELFORMAT_UNCOMPRESSED_R8G8B8A8: f32(data.get(i * 4 + c) / 255);
					case PIXELFORMAT_UNCOMPRESSED_R8G8B8: f32(data.get(i * 3 + c) / 255);
					case PIXELFORMAT_UNCOMPRESSED_R32: data.getFloat(i * 4);
					case PIXELFORMAT_UNCOMPRESSED_R32G32B32: data.getFloat((i * 3 + c) * 4);
					case PIXELFORMAT_UNCOMPRESSED_R32G32B32A32: data.getFloat((i * 4 + c) * 4);
					case PIXELFORMAT_UNCOMPRESSED_R16: Pixels.halfToFloat(data.getUInt16(i * 2));
					case PIXELFORMAT_UNCOMPRESSED_R16G16B16: Pixels.halfToFloat(data.getUInt16((i * 3 + c) * 2));
					case PIXELFORMAT_UNCOMPRESSED_R16G16B16A16: Pixels.halfToFloat(data.getUInt16((i * 4 + c) * 2));
					case _: -1;
				}
				pixels.set(i, byte(f32(value * 255)));
			}
		result.data = pixels;
		result.width = image.width;
		result.height = image.height;
		result.mipmaps = 1;
		result.format = PIXELFORMAT_UNCOMPRESSED_GRAYSCALE;
		return result;
	}

	/** Returns text in raylib's default font, as an image, RGBA. A size under 10 is drawn at 10, letters a tenth of the size apart.

		@param text  The text.
		@param fontSize  The height of a line, in pixels.
		@param color  The color.
		@return  The image. */
	static function ImageText(text:String, fontSize:Int, color:Color):Image {
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		return ImageTextEx(GetFontDefault(), text, fontSize, Std.int(fontSize / DefaultFont.HEIGHT), color);
	}

	/** Returns text in a font, as an image, RGBA, laid out as raylib's: at the font's size, each glyph's image drawn tinted, then scaled
		to the size, nearest for the default font. A newline starts a line one and a half of the font's size down, though the image's
		height counts each line as the size and `SetTextLineSpacing`'s spacing, as raylib's does. Another font is scaled by
		`ImageResize`, which isn't raylib's.

		@param font  The font, its glyphs' images drawn.
		@param text  The text; null gives an empty image.
		@param fontSize  The height of a line, in pixels.
		@param spacing  The space between letters, at the font's size.
		@param tint  The color the glyphs are multiplied by.
		@return  The image. */
	static function ImageTextEx(font:Font, text:String, fontSize:Float, spacing:Float, tint:Color):Image {
		if (text == null)
			return new Image();
		spacing = f32(spacing);
		var imSize = MeasureTextEx(font, text, font.baseSize, spacing);
		var textSize = MeasureTextEx(font, text, fontSize, spacing);
		var imText = GenImageColor(Std.int(imSize.x), Std.int(imSize.y), BLANK);
		var x = 0, y = 0;
		for (codepoint in new haxe.iterators.StringIteratorUnicode(text)) {
			var index = GetGlyphIndex(font, codepoint);
			if (codepoint == "\n".code) {
				y += font.baseSize + Std.int(font.baseSize / 2);
				x = 0;
				continue;
			}
			var glyph = font.glyphs[index], rec = font.recs[index];
			if (codepoint != " ".code && codepoint != "\t".code && glyph.image != null)
				ImageDraw(imText, glyph.image, new Rectangle(0, 0, glyph.image.width, glyph.image.height),
					new Rectangle(x + glyph.offsetX, y + glyph.offsetY, rec.width, rec.height), tint);
			if (glyph.advanceX == 0)
				x += Std.int(f32(f32(rec.width) + spacing));
			else
				x += glyph.advanceX + Std.int(spacing);
		}
		if (textSize.y != imSize.y) {
			var scaleFactor = f32(textSize.y / imSize.y);
			Runtime.log(LOG_INFO, TextFormat("IMAGE: Text scaled by factor: %f", scaleFactor));
			var width = Std.int(f32(imSize.x * scaleFactor)),
				height = Std.int(f32(imSize.y * scaleFactor));
			if (font.texture.id == GetFontDefault().texture.id)
				ImageResizeNN(imText, width, height);
			else
				ImageResize(imText, width, height);
		}
		return imText;
	}

	/** Converts an image to another pixel format, through floats as raylib's does: to grayscale by luminance (0.299 red, 0.587 green,
		0.114 blue), R32 and R16 to their luminance, 16-bit channels rounded. An image with mipmaps has them made again.

		@param image  The image.
		@param newFormat  The format (`PIXELFORMAT_UNCOMPRESSED_*`); a compressed one is refused, with a warning. */
	static function ImageFormat(image:Image, newFormat:Int):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		if (newFormat == 0 || image.format == newFormat)
			return;
		if (image.format >= Pixels.COMPRESSED || newFormat >= Pixels.COMPRESSED) {
			Runtime.log(LOG_WARNING, "IMAGE: Data format is compressed, can not be converted");
			return;
		}
		var count = image.width * image.height;
		var pixels = Pixels.normalized(image.data, count, image.format);
		image.format = newFormat;
		image.data = Pixels.formatted(pixels, count, newFormat);
		if (image.mipmaps > 1) {
			image.mipmaps = 1;
			if (image.data != null)
				ImageMipmaps(image);
		}
	}

	/** Puts an image on the smallest canvas whose sides are powers of two, at its top-left.

		@param image  The image.
		@param fill  The color of the canvas around it. */
	static function ImageToPOT(image:Image, fill:Color):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		var width = 1, height = 1;
		while (width < image.width)
			width <<= 1;
		while (height < image.height)
			height <<= 1;
		if (width != image.width || height != image.height)
			ImageResizeCanvas(image, width, height, 0, 0, fill);
	}

	/** Crops an image to a rectangle, cut to the image; one whose corner is past the image's right or bottom edge leaves it unchanged,
		with a warning. Its mipmaps are dropped, as raylib's are, though its mipmap count is kept.

		@param image  The image.
		@param crop  The rectangle, in pixels. */
	static function ImageCrop(image:Image, crop:Rectangle):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		var x = f32(crop.x),
			y = f32(crop.y),
			width = f32(crop.width),
			height = f32(crop.height);
		if (x < 0) {
			width = f32(width + x);
			x = 0;
		}
		if (y < 0) {
			height = f32(height + y);
			y = 0;
		}
		if (f32(x + width) > image.width)
			width = f32(image.width - x);
		if (f32(y + height) > image.height)
			height = f32(image.height - y);
		if (x > image.width || y > image.height) {
			Runtime.log(LOG_WARNING, "IMAGE: Failed to crop, rectangle out of bounds");
			return;
		}
		if (image.mipmaps > 1)
			Runtime.log(LOG_WARNING, "Image manipulation only applied to base mipmap level");
		if (image.format >= Pixels.COMPRESSED) {
			Runtime.log(LOG_WARNING, "Image manipulation not supported for compressed formats");
			return;
		}
		var bytesPerPixel = GetPixelDataSize(1, 1, image.format);
		var w = Std.int(width), h = Std.int(height), row = w * bytesPerPixel;
		var cropped = haxe.io.Bytes.alloc(w > 0 && h > 0 ? w * h * bytesPerPixel : 0), offset = 0;
		cropped.fill(0, cropped.length, 0);
		// raylib's rows run from the top's whole pixel to the bottom's; those past the cropped size are dropped.
		for (r in Std.int(y)...Std.int(f32(y + height))) {
			if (offset + row > cropped.length)
				break;
			copyBytes(cropped, offset, image.data, (r * image.width + Std.int(x)) * bytesPerPixel, row);
			offset += row;
		}
		image.data = cropped;
		image.width = w;
		image.height = h;
	}

	/** Crops an image to the pixels whose alpha is over a threshold, when any is.

		@param image  The image.
		@param threshold  The threshold, 0 to 1. */
	static function ImageAlphaCrop(image:Image, threshold:Float):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		var crop = GetImageAlphaBorder(image, threshold);
		if (Std.int(crop.width) != 0 && Std.int(crop.height) != 0)
			ImageCrop(image, crop);
	}

	/** Sets every pixel whose alpha is at or under a threshold to a color, as raylib's does for its formats with alpha: gray and alpha,
		R5G5B5A1 (the alpha bit against a threshold of 0.5; the color's channels, unscaled, are cut to 5 bits), R4G4B4A4 (likewise to 4
		bits), RGBA and its 32-bit and 16-bit float forms. Another format is unchanged.

		@param image  The image.
		@param color  The color.
		@param threshold  The threshold, 0 to 1. */
	static function ImageAlphaClear(image:Image, color:Color, threshold:Float):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		if (image.mipmaps > 1)
			Runtime.log(LOG_WARNING, "Image manipulation only applied to base mipmap level");
		if (image.format >= Pixels.COMPRESSED) {
			Runtime.log(LOG_WARNING, "Image manipulation not supported for compressed formats");
			return;
		}
		threshold = f32(threshold);
		var data = image.data, count = image.width * image.height;
		var r = color.r & 255,
			g = color.g & 255,
			b = color.b & 255,
			a = color.a & 255;
		switch image.format {
			case PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA:
				var limit = byte(f32(threshold * 255));
				for (i in 0...count)
					if (data.get(i * 2 + 1) <= limit) {
						data.set(i * 2, r);
						data.set(i * 2 + 1, a);
					}
			case PIXELFORMAT_UNCOMPRESSED_R5G5B5A1:
				var limit = threshold < 0.5 ? 0 : 1;
				var value = (byte(Pixels.round(f32(r * 31))) << 11 | byte(Pixels.round(f32(g * 31))) << 6 | byte(Pixels.round(f32(b * 31))) << 1 | (a < 128 ? 0 : 1)) & 0xFFFF;
				for (i in 0...count)
					if ((data.getUInt16(i * 2) & 1) <= limit)
						data.setUInt16(i * 2, value);
			case PIXELFORMAT_UNCOMPRESSED_R4G4B4A4:
				var limit = byte(f32(threshold * 15));
				var value = (byte(Pixels.round(f32(r * 15))) << 12 | byte(Pixels.round(f32(g * 15))) << 8 | byte(Pixels.round(f32(b * 15))) << 4 | byte(Pixels.round(f32(a * 15)))) & 0xFFFF;
				for (i in 0...count)
					if ((data.getUInt16(i * 2) & 15) <= limit)
						data.setUInt16(i * 2, value);
			case PIXELFORMAT_UNCOMPRESSED_R8G8B8A8:
				new helix.services.images.Image("", image.width, image.height, data).clearAlpha(Pixels.argb(Pixels.ofColor(color)), threshold);
			case PIXELFORMAT_UNCOMPRESSED_R32G32B32A32:
				for (i in 0...count)
					if (data.getFloat(i * 16 + 12) <= threshold) {
						data.setFloat(i * 16, f32(r / 255));
						data.setFloat(i * 16 + 4, f32(g / 255));
						data.setFloat(i * 16 + 8, f32(b / 255));
						data.setFloat(i * 16 + 12, f32(a / 255));
					}
			case PIXELFORMAT_UNCOMPRESSED_R16G16B16A16:
				for (i in 0...count)
					if (Pixels.halfToFloat(data.getUInt16(i * 8 + 6)) <= threshold) {
						data.setUInt16(i * 8, Pixels.floatToHalf(f32(r / 255)));
						data.setUInt16(i * 8 + 2, Pixels.floatToHalf(f32(g / 255)));
						data.setUInt16(i * 8 + 4, Pixels.floatToHalf(f32(b / 255)));
						data.setUInt16(i * 8 + 6, Pixels.floatToHalf(f32(a / 255)));
					}
			case _:
		}
	}

	/** Sets an image's alpha from another image of the same size, its grayscale: a grayscale image becomes gray and alpha, any other
		RGBA. A mask of another size changes nothing, with a warning.

		@param image  The image.
		@param alphaMask  The mask. */
	static function ImageAlphaMask(image:Image, alphaMask:Image):Void {
		if (image.width != alphaMask.width || image.height != alphaMask.height) {
			Runtime.log(LOG_WARNING, "IMAGE: Alpha mask must be same size as image");
			return;
		}
		if (image.format >= Pixels.COMPRESSED) {
			Runtime.log(LOG_WARNING, "IMAGE: Alpha mask can not be applied to compressed data formats");
			return;
		}
		var mask = ImageCopy(alphaMask);
		if (mask.format != PIXELFORMAT_UNCOMPRESSED_GRAYSCALE)
			ImageFormat(mask, PIXELFORMAT_UNCOMPRESSED_GRAYSCALE);
		if (image.data == null || mask.data == null)
			return;
		var count = image.width * image.height;
		if (image.format == PIXELFORMAT_UNCOMPRESSED_GRAYSCALE) {
			var data = haxe.io.Bytes.alloc(count * 2);
			for (i in 0...count) {
				data.set(i * 2, image.data.get(i));
				data.set(i * 2 + 1, mask.data.get(i));
			}
			image.data = data;
			image.format = PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA;
		} else {
			if (image.format != PIXELFORMAT_UNCOMPRESSED_R8G8B8A8)
				ImageFormat(image, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
			for (i in 0...count)
				image.data.set(i * 4 + 3, mask.data.get(i));
		}
	}

	/** Multiplies each pixel's red, green and blue by its alpha, rounding down; the image keeps its format.

		@param image  The image. */
	static function ImageAlphaPremultiply(image:Image):Void {
		throughColors(image, pixels -> pixels.premultiplyAlpha());
	}

	/** Blurs an image, as raylib's does: an approximate Gaussian, four passes of a box blur across and down, over premultiplied alpha,
		each channel taken back from it no higher than 255. A box reaching past the image's last pixel reads 0 there, where raylib's reads
		past its pixels.

		@param image  The image.
		@param blurSize  How far each box reaches either side of a pixel, in pixels. */
	static function ImageBlurGaussian(image:Image, blurSize:Int):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		ImageAlphaPremultiply(image);
		var width = image.width, height = image.height, count = width * height;
		var pixels = Pixels.colors(image.data, width, height, image.format);
		var a = new haxe.ds.Vector<Float>(count * 4),
			b = new haxe.ds.Vector<Float>(count * 4),
			sums = new haxe.ds.Vector<Float>(4);
		for (i in 0...count * 4)
			a[i] = pixels.get(i);
		inline function read(v:haxe.ds.Vector<Float>, pixel:Int, k:Int):Float
			return pixel >= 0 && pixel < count ? v[pixel * 4 + k] : 0;
		for (_ in 0...4) {
			for (row in 0...height) {
				var size = blurSize;
				for (k in 0...4) {
					var s = 0.;
					for (i in 0...blurSize)
						s = f32(s + read(a, row * width + i, k));
					sums[k] = s;
				}
				for (x in 0...width) {
					if (x - blurSize - 1 >= 0) {
						for (k in 0...4)
							sums[k] = f32(sums[k] - a[(row * width + x - blurSize - 1) * 4 + k]);
						size--;
					}
					if (x + blurSize < width) {
						for (k in 0...4)
							sums[k] = f32(sums[k] + a[(row * width + x + blurSize) * 4 + k]);
						size++;
					}
					for (k in 0...4)
						b[(row * width + x) * 4 + k] = f32(sums[k] / size);
				}
			}
			for (col in 0...width) {
				var size = blurSize;
				for (k in 0...4) {
					var s = 0.;
					for (i in 0...blurSize)
						s = f32(s + read(b, i * width + col, k));
					sums[k] = s;
				}
				for (y in 0...height) {
					if (y - blurSize - 1 >= 0) {
						for (k in 0...4)
							sums[k] = f32(sums[k] - b[((y - blurSize - 1) * width + col) * 4 + k]);
						size--;
					}
					if (y + blurSize < height) {
						for (k in 0...4)
							sums[k] = f32(sums[k] + b[((y + blurSize) * width + col) * 4 + k]);
						size++;
					}
					for (k in 0...4)
						a[(y * width + col) * 4 + k] = byte(f32(sums[k] / size));
				}
			}
		}
		for (i in 0...count) {
			var w = a[i * 4 + 3];
			if (w == 0)
				pixels.setInt32(i * 4, 0);
			else if (w <= 255) {
				var alpha = f32(w / 255);
				pixels.set(i * 4, byte(Math.min(f32(a[i * 4] / alpha), 255)));
				pixels.set(i * 4 + 1, byte(Math.min(f32(a[i * 4 + 1] / alpha), 255)));
				pixels.set(i * 4 + 2, byte(Math.min(f32(a[i * 4 + 2] / alpha), 255)));
				pixels.set(i * 4 + 3, byte(w));
			}
		}
		backToFormat(image, pixels);
	}

	/** Applies a square kernel to an image, as raylib's does: each channel, alpha too, the sum of the pixels around it as fractions times
		the weights, clamped to 0 to 1. A pixel past an edge is taken from the edge. A count that isn't square changes nothing, with a
		warning.

		@param image  The image.
		@param kernel  The weights, rows top first.
		@param kernelSize  How many: 9 for 3 by 3, 25 for 5 by 5. */
	static function ImageKernelConvolution(image:Image, kernel:Array<Float>, kernelSize:Int):Void {
		if (image.data == null || image.width == 0 || image.height == 0 || kernel == null)
			return;
		var kernelWidth = Std.int(f32(Math.sqrt(f32(kernelSize))));
		if (kernelWidth * kernelWidth != kernelSize) {
			Runtime.log(LOG_WARNING, "IMAGE: Convolution kernel must be square to be applied");
			return;
		}
		var width = image.width, height = image.height, count = width * height;
		var pixels = Pixels.colors(image.data, width, height, image.format);
		var weights = new haxe.ds.Vector<Float>(kernelSize),
			result = haxe.io.Bytes.alloc(count * 4),
			sums = new haxe.ds.Vector<Float>(4);
		for (i in 0...kernelSize)
			weights[i] = f32(kernel[i]);
		var half = Std.int(kernelWidth / 2), start = -half, end = kernelWidth % 2 == 0 ? half : half + 1;
		// raylib's x walks the rows and y the columns.
		for (x in 0...height)
			for (y in 0...width) {
				for (k in 0...4)
					sums[k] = 0;
				for (xk in start...end) {
					var row = x + xk;
					if (row < 0)
						row = 0;
					if (row > height - 1)
						row = height - 1;
					for (yk in start...end) {
						var col = y + yk;
						if (col < 0)
							col = 0;
						if (col > width - 1)
							col = width - 1;
						var t = kernelWidth * (xk + half) + yk + half,
							index = width * row + col;
						for (k in 0...4)
							sums[k] = f32(sums[k] + f32(f32(pixels.get(index * 4 + k) / 255) * weights[t]));
					}
				}
				for (k in 0...4) {
					var s = sums[k];
					result.set((width * x + y) * 4 + k, byte(f32((s < 0 ? 0 : s > 1 ? 1 : s) * 255)));
				}
			}
		backToFormat(image, result);
	}

	/** Resizes an image. Unlike raylib's, whose `stb_image_resize2` this library doesn't have, it is helix-services' `Bicubic` (Catmull-Rom,
		alpha-weighted), so the pixels aren't raylib's; an 8-bit format is resized in its channels, any other through RGBA, as raylib's.

		@param image  The image.
		@param newWidth  The width, in pixels.
		@param newHeight  The height, in pixels. */
	static function ImageResize(image:Image, newWidth:Int, newHeight:Int):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		var format = image.format,
			count = image.width * image.height,
			data = image.data;
		var channels = switch format {
			case PIXELFORMAT_UNCOMPRESSED_GRAYSCALE: 1;
			case PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA: 2;
			case PIXELFORMAT_UNCOMPRESSED_R8G8B8: 3;
			case PIXELFORMAT_UNCOMPRESSED_R8G8B8A8: 4;
			case _: 0;
		}
		if (channels == 0) {
			var resized = new helix.services.images.Image("", image.width, image.height,
				Pixels.colors(data, image.width, image.height, format)).resize(newWidth, newHeight, Bicubic);
			image.data = resized.pixels;
			image.width = newWidth;
			image.height = newHeight;
			image.format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
			ImageFormat(image, format);
			return;
		}
		// An 8-bit format's channels as RGBA, resized, and taken back.
		var rgba = haxe.io.Bytes.alloc(count * 4);
		for (i in 0...count)
			rgba.setInt32(i * 4, switch channels {
				case 1: Pixels.pack(data.get(i), data.get(i), data.get(i), 255);
				case 2: Pixels.pack(data.get(i * 2), data.get(i * 2), data.get(i * 2), data.get(i * 2 + 1));
				case 3: Pixels.pack(data.get(i * 3), data.get(i * 3 + 1), data.get(i * 3 + 2), 255);
				case _: data.getInt32(i * 4);
			});
		var resized = new helix.services.images.Image("", image.width, image.height, rgba).resize(newWidth, newHeight, Bicubic).pixels;
		var size = resized.length >> 2,
			output = channels == 4 ? resized : haxe.io.Bytes.alloc(size * channels);
		if (channels != 4)
			for (i in 0...size)
				for (k in 0...channels)
					output.set(i * channels + k, resized.get(i * 4 + (channels == 2 && k == 1 ? 3 : k)));
		image.data = output;
		image.width = newWidth;
		image.height = newHeight;
	}

	/** Resizes an image to the nearest pixels, as raylib's does, through RGBA; it keeps its format.

		@param image  The image.
		@param newWidth  The width, in pixels.
		@param newHeight  The height, in pixels. */
	static function ImageResizeNN(image:Image, newWidth:Int, newHeight:Int):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		var format = image.format;
		var resized = new helix.services.images.Image("", image.width, image.height,
			Pixels.colors(image.data, image.width, image.height, format)).resize(newWidth, newHeight, Nearest);
		image.data = resized.pixels;
		image.width = newWidth;
		image.height = newHeight;
		image.format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
		ImageFormat(image, format);
	}

	/** Puts an image on a canvas of another size, in its format: the canvas filled with a color as `SetPixelColor` writes it (a float
		format's canvas stays zero), the image at an offset, what falls outside cropped. A canvas the image's size leaves it unchanged.

		@param image  The image.
		@param newWidth  The canvas's width, in pixels.
		@param newHeight  The canvas's height, in pixels.
		@param offsetX  Where the image's left edge goes; negative crops its left.
		@param offsetY  Where its top edge goes.
		@param fill  The canvas's color. */
	static function ImageResizeCanvas(image:Image, newWidth:Int, newHeight:Int, offsetX:Int, offsetY:Int, fill:Color):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		if (image.mipmaps > 1)
			Runtime.log(LOG_WARNING, "Image manipulation only applied to base mipmap level");
		if (image.format >= Pixels.COMPRESSED) {
			Runtime.log(LOG_WARNING, "Image manipulation not supported for compressed formats");
			return;
		}
		if (newWidth == image.width && newHeight == image.height)
			return;
		var srcX = 0, srcY = 0, srcWidth = image.width, srcHeight = image.height, dstX = offsetX, dstY = offsetY;
		if (offsetX < 0) {
			srcX = -offsetX;
			srcWidth += offsetX;
			dstX = 0;
		} else if (offsetX + image.width > newWidth)
			srcWidth = newWidth - offsetX;
		if (offsetY < 0) {
			srcY = -offsetY;
			srcHeight += offsetY;
			dstY = 0;
		} else if (offsetY + image.height > newHeight)
			srcHeight = newHeight - offsetY;
		if (newWidth < srcWidth)
			srcWidth = newWidth;
		if (newHeight < srcHeight)
			srcHeight = newHeight;
		var bytesPerPixel = GetPixelDataSize(1, 1, image.format),
			size = newWidth * newHeight * bytesPerPixel;
		var resized = haxe.io.Bytes.alloc(size > 0 ? size : 0);
		resized.fill(0, resized.length, 0);
		if (resized.length >= bytesPerPixel && bytesPerPixel > 0) {
			Pixels.setColor(resized, 0, Pixels.ofColor(fill), image.format, false);
			for (x in 1...newWidth)
				resized.blit(x * bytesPerPixel, resized, 0, bytesPerPixel);
			for (y in 1...newHeight)
				resized.blit(y * newWidth * bytesPerPixel, resized, 0, newWidth * bytesPerPixel);
		}
		var offset = (dstY * newWidth + dstX) * bytesPerPixel;
		if (srcWidth > 0)
			for (y in 0...srcHeight) {
				copyBytes(resized, offset, image.data, ((y + srcY) * image.width + srcX) * bytesPerPixel, srcWidth * bytesPerPixel);
				offset += newWidth * bytesPerPixel;
			}
		image.data = resized;
		image.width = newWidth;
		image.height = newHeight;
	}

	/** Makes an image's mipmaps, down to 1 by 1, after its pixels, in its format; levels it has are kept. Each is made by `ImageResize`
		from the last, so they aren't raylib's.

		@param image  The image. */
	static function ImageMipmaps(image:Image):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		var mipCount = 1, mipWidth = image.width, mipHeight = image.height;
		var mipSize = GetPixelDataSize(mipWidth, mipHeight, image.format);
		while (mipWidth != 1 || mipHeight != 1) {
			if (mipWidth != 1)
				mipWidth = Std.int(mipWidth / 2);
			if (mipHeight != 1)
				mipHeight = Std.int(mipHeight / 2);
			if (mipWidth < 1)
				mipWidth = 1;
			if (mipHeight < 1)
				mipHeight = 1;
			mipCount++;
			mipSize += GetPixelDataSize(mipWidth, mipHeight, image.format);
		}
		if (image.mipmaps >= mipCount) {
			Runtime.log(LOG_WARNING, "IMAGE: Mipmaps already available");
			return;
		}
		var all = haxe.io.Bytes.alloc(mipSize);
		all.fill(0, mipSize, 0);
		copyBytes(all, 0, image.data, 0, mipSize);
		image.data = all;
		mipWidth = image.width;
		mipHeight = image.height;
		mipSize = GetPixelDataSize(mipWidth, mipHeight, image.format);
		var next = 0, copy = ImageCopy(image);
		for (i in 1...mipCount) {
			next += mipSize;
			mipWidth = Std.int(mipWidth / 2);
			mipHeight = Std.int(mipHeight / 2);
			if (mipWidth < 1)
				mipWidth = 1;
			if (mipHeight < 1)
				mipHeight = 1;
			mipSize = GetPixelDataSize(mipWidth, mipHeight, image.format);
			if (i < image.mipmaps)
				continue;
			ImageResize(copy, mipWidth, mipHeight);
			copyBytes(all, next, copy.data, 0, mipSize);
		}
		image.mipmaps = mipCount;
	}

	/** Dithers an image to 16 bits a pixel or fewer (Floyd-Steinberg), as raylib's does: R5G6B5, R5G5B5A1 or R4G4B4A4 when the bits
		are one of those, else format 0 with the bits packed in 16, and a warning. More than 16 bits changes nothing, with a warning.

		@param image  The image.
		@param rBpp  Red's bits.
		@param gBpp  Green's bits.
		@param bBpp  Blue's bits.
		@param aBpp  Alpha's bits. */
	static function ImageDither(image:Image, rBpp:Int, gBpp:Int, bBpp:Int, aBpp:Int):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		if (image.format >= Pixels.COMPRESSED) {
			Runtime.log(LOG_WARNING, "IMAGE: Compressed data formats can not be dithered");
			return;
		}
		var total = rBpp + gBpp + bBpp + aBpp;
		if (total > 16) {
			Runtime.log(LOG_WARNING, 'IMAGE: Unsupported dithering bpps (${total}bpp), only 16bpp or lower modes supported');
			return;
		}
		var width = image.width, height = image.height;
		var pixels = Pixels.colors(image.data, width, height, image.format);
		if (image.format != PIXELFORMAT_UNCOMPRESSED_R8G8B8 && image.format != PIXELFORMAT_UNCOMPRESSED_R8G8B8A8)
			Runtime.log(LOG_WARNING, "IMAGE: Format is already 16bpp or lower, dithering could have no effect");
		if (rBpp == 5 && gBpp == 6 && bBpp == 5 && aBpp == 0)
			image.format = PIXELFORMAT_UNCOMPRESSED_R5G6B5;
		else if (rBpp == 5 && gBpp == 5 && bBpp == 5 && aBpp == 1)
			image.format = PIXELFORMAT_UNCOMPRESSED_R5G5B5A1;
		else if (rBpp == 4 && gBpp == 4 && bBpp == 4 && aBpp == 4)
			image.format = PIXELFORMAT_UNCOMPRESSED_R4G4B4A4;
		else {
			image.format = 0;
			Runtime.log(LOG_WARNING, 'IMAGE: Unsupported dithered OpenGL internal format: ${total}bpp (R${rBpp}G${gBpp}B${bBpp}A${aBpp})');
		}
		var data = haxe.io.Bytes.alloc(width * height * 2);
		inline function spread(at:Int, error:Int, weight:Float) {
			var v = pixels.get(at) + Std.int(f32(f32(error * weight) / 16));
			pixels.set(at, v < 255 ? v : 255);
		}
		for (y in 0...height)
			for (x in 0...width) {
				var at = (y * width + x) * 4;
				var r = pixels.get(at) >> (8 - rBpp),
					g = pixels.get(at + 1) >> (8 - gBpp),
					b = pixels.get(at + 2) >> (8 - bBpp),
					a = pixels.get(at + 3) >> (8 - aBpp);
				var errors = [
					pixels.get(at) - (r << (8 - rBpp)),
					pixels.get(at + 1) - (g << (8 - gBpp)),
					pixels.get(at + 2) - (b << (8 - bBpp))
				];
				pixels.setInt32(at, Pixels.pack(r, g, b, a));
				for (k in 0...3) {
					if (x < width - 1)
						spread(at + 4 + k, errors[k], 7);
					if (x > 0 && y < height - 1)
						spread(at + (width - 1) * 4 + k, errors[k], 3);
					if (y < height - 1)
						spread(at + width * 4 + k, errors[k], 5);
					if (x < width - 1 && y < height - 1)
						spread(at + (width + 1) * 4 + k, errors[k], 1);
				}
				data.setUInt16((y * width + x) * 2, ((r & 255) << (gBpp + bBpp + aBpp) | (g & 255) << (bBpp + aBpp) | (b & 255) << aBpp | (a & 255)) & 0xFFFF);
			}
		image.data = data;
	}

	/** Turns an image upside down, in its format. Its mipmaps are dropped, as raylib's are, though its mipmap count is kept.

		@param image  The image. */
	static function ImageFlipVertical(image:Image):Void {
		if (!manipulable(image))
			return;
		var bytesPerPixel = GetPixelDataSize(1, 1, image.format),
			row = image.width * bytesPerPixel;
		var flipped = haxe.io.Bytes.alloc(row * image.height);
		for (i in 0...image.height)
			copyBytes(flipped, i * row, image.data, (image.height - 1 - i) * row, row);
		image.data = flipped;
	}

	/** Mirrors an image left to right, in its format. Its mipmaps are dropped, as raylib's are, though its mipmap count is kept.

		@param image  The image. */
	static function ImageFlipHorizontal(image:Image):Void {
		if (!manipulable(image))
			return;
		var bytesPerPixel = GetPixelDataSize(1, 1, image.format),
			width = image.width;
		var flipped = haxe.io.Bytes.alloc(width * image.height * bytesPerPixel);
		for (y in 0...image.height)
			for (x in 0...width)
				flipped.blit((y * width + x) * bytesPerPixel, image.data, (y * width + width - 1 - x) * bytesPerPixel, bytesPerPixel);
		image.data = flipped;
	}

	/** Turns an image by an angle, on a canvas big enough to hold it, clear around it: each byte of a pixel blends the four it falls
		between, as raylib's does in every format.

		@param image  The image.
		@param degrees  The angle, in degrees clockwise. */
	static function ImageRotate(image:Image, degrees:Int):Void {
		if (!manipulable(image))
			return;
		var rad = f32(f32(degrees * f32(PI)) / 180);
		var sinRadius = f32(Math.sin(rad)), cosRadius = f32(Math.cos(rad));
		var oldWidth = image.width, oldHeight = image.height;
		var width = Std.int(f32(Math.abs(f32(oldWidth * cosRadius)) + Math.abs(f32(oldHeight * sinRadius))));
		var height = Std.int(f32(Math.abs(f32(oldHeight * cosRadius)) + Math.abs(f32(oldWidth * sinRadius))));
		var bytesPerPixel = GetPixelDataSize(1, 1, image.format),
			data = image.data;
		var rotated = haxe.io.Bytes.alloc(width * height * bytesPerPixel);
		rotated.fill(0, rotated.length, 0);
		var halfW = f32(width / 2),
			halfH = f32(height / 2),
			oldHalfW = f32(oldWidth / 2),
			oldHalfH = f32(oldHeight / 2);
		for (y in 0...height) {
			var dy = f32(y - halfH);
			for (x in 0...width) {
				var dx = f32(x - halfW);
				var oldX = f32(f32(f32(dx * cosRadius) + f32(dy * sinRadius)) + oldHalfW);
				var oldY = f32(f32(f32(dy * cosRadius) - f32(dx * sinRadius)) + oldHalfH);
				if (oldX >= 0 && oldX < oldWidth && oldY >= 0 && oldY < oldHeight) {
					var x1 = Std.int(Math.floor(oldX)),
						y1 = Std.int(Math.floor(oldY));
					var x2 = x1 + 1 < oldWidth - 1 ? x1 + 1 : oldWidth - 1,
						y2 = y1 + 1 < oldHeight - 1 ? y1 + 1 : oldHeight - 1;
					var px = f32(oldX - x1),
						py = f32(oldY - y1),
						qx = f32(1 - px),
						qy = f32(1 - py);
					var a1 = (y1 * oldWidth + x1) * bytesPerPixel,
						a2 = (y1 * oldWidth + x2) * bytesPerPixel,
						a3 = (y2 * oldWidth + x1) * bytesPerPixel,
						a4 = (y2 * oldWidth + x2) * bytesPerPixel,
						at = (y * width + x) * bytesPerPixel;
					for (i in 0...bytesPerPixel) {
						var v = f32(f32(f32(f32(data.get(a1 + i) * qx) * qy) + f32(f32(data.get(a2 + i) * px) * qy)) + f32(f32(data.get(a3 + i) * qx) * py));
						rotated.set(at + i, byte(f32(v + f32(f32(data.get(a4 + i) * px) * py))));
					}
				}
			}
		}
		image.data = rotated;
		image.width = width;
		image.height = height;
	}

	/** Turns an image a quarter turn clockwise, in its format.

		@param image  The image. */
	static function ImageRotateCW(image:Image):Void {
		if (!manipulable(image))
			return;
		var bytesPerPixel = GetPixelDataSize(1, 1, image.format),
			width = image.width,
			height = image.height;
		var rotated = haxe.io.Bytes.alloc(width * height * bytesPerPixel);
		for (y in 0...height)
			for (x in 0...width)
				rotated.blit((x * height + (height - y - 1)) * bytesPerPixel, image.data, (y * width + x) * bytesPerPixel, bytesPerPixel);
		image.data = rotated;
		image.width = height;
		image.height = width;
	}

	/** Turns an image a quarter turn counterclockwise, in its format.

		@param image  The image. */
	static function ImageRotateCCW(image:Image):Void {
		if (!manipulable(image))
			return;
		var bytesPerPixel = GetPixelDataSize(1, 1, image.format),
			width = image.width,
			height = image.height;
		var rotated = haxe.io.Bytes.alloc(width * height * bytesPerPixel);
		for (y in 0...height)
			for (x in 0...width)
				rotated.blit((x * height + y) * bytesPerPixel, image.data, (y * width + (width - x - 1)) * bytesPerPixel, bytesPerPixel);
		image.data = rotated;
		image.width = height;
		image.height = width;
	}

	/** Multiplies each pixel by a color, channel by channel, alpha too; the image keeps its format.

		@param image  The image.
		@param color  The color; `WHITE` keeps it unchanged. */
	static function ImageColorTint(image:Image, color:Color):Void {
		throughColors(image, pixels -> pixels.tint(Pixels.argb(Pixels.ofColor(color))));
	}

	/** Inverts each pixel's red, green and blue; the image keeps its format.

		@param image  The image. */
	static function ImageColorInvert(image:Image):Void {
		throughColors(image, pixels -> pixels.invert());
	}

	/** Makes an image grayscale, as raylib's does: it becomes `PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`, its alpha dropped.

		@param image  The image. */
	static function ImageColorGrayscale(image:Image):Void {
		ImageFormat(image, PIXELFORMAT_UNCOMPRESSED_GRAYSCALE);
	}

	/** Changes an image's contrast; the image keeps its format.

		@param image  The image.
		@param contrast  -100 (all mid-gray) to 100; 0 leaves it unchanged. */
	static function ImageColorContrast(image:Image, contrast:Float):Void {
		throughColors(image, pixels -> pixels.contrast(contrast));
	}

	/** Changes an image's brightness, adding to red, green and blue; the image keeps its format. A channel taken below 0 becomes 1, as
		raylib's does.

		@param image  The image.
		@param brightness  -255 to 255. */
	static function ImageColorBrightness(image:Image, brightness:Int):Void {
		throughColors(image, pixels -> pixels.brighten(brightness));
	}

	/** Changes every pixel of one color to another; the image keeps its format.

		@param image  The image.
		@param color  The color changed, alpha too.
		@param replace  The color it becomes. */
	static function ImageColorReplace(image:Image, color:Color, replace:Color):Void {
		throughColors(image, pixels -> pixels.replaceColor(Pixels.argb(Pixels.ofColor(color)), Pixels.argb(Pixels.ofColor(replace))));
	}

	/** Returns an image's pixels as colors, as raylib's reads each format: a 5-bit channel times 8, a 6-bit times 4, a 4-bit times 17; R32
		and R16 as red alone.

		@param image  The image.
		@return  The colors, rows top first, or null for an image 0 wide or high. */
	static function LoadImageColors(image:Image):Array<Color> {
		if (image.width == 0 || image.height == 0)
			return null;
		var pixels = Pixels.colors(image.data, image.width, image.height, image.format);
		return [for (i in 0...image.width * image.height) Pixels.toColor(pixels.getInt32(i * 4))];
	}

	/** Returns an image's colors, each once, in the order first met; clear pixels are skipped.

		@param image  The image.
		@param maxPaletteSize  The most colors.
		@param colorCount  Its first element is set to how many colors were found.
		@return  `maxPaletteSize` colors, those found first, the rest `BLANK`; null for an image 0 wide or high. */
	static function LoadImagePalette(image:Image, maxPaletteSize:Int, colorCount:Array<Int>):Array<Color> {
		var palette:Array<Color> = null, count = 0;
		if (image.width != 0 && image.height != 0) {
			var pixels = Pixels.colors(image.data, image.width, image.height, image.format);
			var found = new helix.services.images.Image("", image.width, image.height, pixels).getPalette(maxPaletteSize);
			count = found.length;
			palette = [
				for (i in 0...maxPaletteSize)
					i < count ? new Color((found[i] >> 16) & 255, (found[i] >> 8) & 255, found[i] & 255, (found[i] >>> 24) & 255) : new Color(0, 0, 0, 0)
			];
			if (count >= maxPaletteSize)
				Runtime.log(LOG_WARNING, 'IMAGE: Palette is greater than $maxPaletteSize colors');
		}
		if (colorCount != null)
			colorCount[0] = count;
		return palette;
	}

	/** Frees colors `LoadImageColors` gave. There is nothing to free here.

		@param colors  The colors. */
	static function UnloadImageColors(colors:Array<Color>):Void {}

	/** Frees colors `LoadImagePalette` gave. There is nothing to free here.

		@param colors  The colors. */
	static function UnloadImagePalette(colors:Array<Color>):Void {}

	/** Returns the smallest rectangle holding every pixel whose alpha is over a threshold.

		@param image  The image.
		@param threshold  The threshold, 0 to 1.
		@return  The rectangle, in pixels; all zero when no pixel is over it. */
	static function GetImageAlphaBorder(image:Image, threshold:Float):Rectangle {
		if (image.width == 0 || image.height == 0)
			return new Rectangle();
		var pixels = Pixels.colors(image.data, image.width, image.height, image.format);
		var border = new helix.services.images.Image("", image.width, image.height, pixels).getAlphaBorder(threshold);
		return border.isEmpty ? new Rectangle() : new Rectangle(border.minX, border.minY, border.width, border.height);
	}

	/** Returns a pixel's color, as `LoadImageColors` reads it. A pixel outside the image is clear black, with a warning.

		@param image  The image.
		@param x  The pixel's column.
		@param y  Its row.
		@return  The color. */
	static function GetImageColor(image:Image, x:Int, y:Int):Color {
		if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
			Runtime.log(LOG_WARNING, 'Requested image pixel ($x, $y) out of bounds');
			return new Color(0, 0, 0, 0);
		}
		var i = y * image.width + x;
		return switch image.format {
			case f if (f >= PIXELFORMAT_UNCOMPRESSED_GRAYSCALE && f < Pixels.COMPRESSED):
				Pixels.toColor(Pixels.loadColor(image.data, i, f));
			case _:
				Runtime.log(LOG_WARNING, "Compressed image format does not support color reading");
				new Color(0, 0, 0, 0);
		}
	}

	// ---- Images: drawn into ----

	/** Fills an image with a color, in its format, as `ImageDrawPixel` writes it.

		@param dst  The image.
		@param color  The color. */
	static function ImageClearBackground(dst:Image, color:Color):Void {
		if (dst.data == null || dst.width == 0 || dst.height == 0)
			return;
		ImageDrawPixel(dst, 0, 0, color);
		var bytesPerPixel = GetPixelDataSize(1, 1, dst.format);
		for (i in 1...dst.width * dst.height)
			dst.data.blit(i * bytesPerPixel, dst.data, 0, bytesPerPixel);
	}

	/** Sets a pixel, in the image's format: grayscale by luminance, a 16-bit format's channels rounded, R5G5B5A1's alpha bit set over an
		alpha of 50. One outside the image is skipped.

		@param dst  The image.
		@param posX  The pixel's column.
		@param posY  Its row.
		@param color  The color. */
	static function ImageDrawPixel(dst:Image, posX:Int, posY:Int, color:Color):Void {
		if (dst.data == null || posX < 0 || posX >= dst.width || posY < 0 || posY >= dst.height)
			return;
		Pixels.setColor(dst.data, (posY * dst.width + posX) * GetPixelDataSize(1, 1, dst.format), Pixels.ofColor(color), dst.format, true);
	}

	/** Sets a pixel, as `ImageDrawPixel` does, its position cut to whole pixels.

		@param dst  The image.
		@param position  The pixel.
		@param color  The color. */
	static function ImageDrawPixelV(dst:Image, position:Vector2, color:Color):Void {
		ImageDrawPixel(dst, Std.int(f32(position.x)), Std.int(f32(position.y)), color);
	}

	/** Draws a line one pixel wide, from its start to its end, both drawn.

		@param dst  The image.
		@param startPosX  The start's column.
		@param startPosY  The start's row.
		@param endPosX  The end's column.
		@param endPosY  The end's row.
		@param color  The color. */
	static function ImageDrawLine(dst:Image, startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void {
		shape(dst, color, (pixels, c) -> pixels.drawLine(startPosX, startPosY, endPosX, endPosY, c));
	}

	/** Draws a line one pixel wide, its ends rounded to whole pixels.

		@param dst  The image.
		@param start  The start.
		@param end  The end.
		@param color  The color. */
	static function ImageDrawLineV(dst:Image, start:Vector2, end:Vector2, color:Color):Void {
		ImageDrawLine(dst, Std.int(f32(f32(start.x) + 0.5)), Std.int(f32(f32(start.y) + 0.5)), Std.int(f32(f32(end.x) + 0.5)), Std.int(f32(f32(end.y) + 0.5)),
			color);
	}

	/** Draws a line of a thickness: as many lines as it is thick, side by side, below and above the line for a line more across than
		down, right and left of it otherwise (the odd one out below or right). Its ends are rounded to whole pixels; a line from a pixel
		to itself draws nothing.

		@param dst  The image.
		@param start  The start.
		@param end  The end.
		@param thick  The thickness, in pixels; less than 1 draws the line alone.
		@param color  The color. */
	static function ImageDrawLineEx(dst:Image, start:Vector2, end:Vector2, thick:Int, color:Color):Void {
		shape(dst, color, (pixels, c) -> pixels.drawThickLine(start.x, start.y, end.x, end.y, thick, c));
	}

	/** Fills a circle, each row as wide either side of the middle.

		@param dst  The image.
		@param centerX  The middle's column.
		@param centerY  The middle's row.
		@param radius  The radius, in pixels.
		@param color  The color. */
	static function ImageDrawCircle(dst:Image, centerX:Int, centerY:Int, radius:Int, color:Color):Void {
		shape(dst, color, (pixels, c) -> pixels.drawCircle(centerX, centerY, radius, c));
	}

	/** Fills a circle, its middle cut to whole pixels.

		@param dst  The image.
		@param center  The middle.
		@param radius  The radius, in pixels.
		@param color  The color. */
	static function ImageDrawCircleV(dst:Image, center:Vector2, radius:Int, color:Color):Void {
		ImageDrawCircle(dst, Std.int(f32(center.x)), Std.int(f32(center.y)), radius, color);
	}

	/** Outlines a circle, one pixel wide.

		@param dst  The image.
		@param centerX  The middle's column.
		@param centerY  The middle's row.
		@param radius  The radius, in pixels.
		@param color  The color. */
	static function ImageDrawCircleLines(dst:Image, centerX:Int, centerY:Int, radius:Int, color:Color):Void {
		shape(dst, color, (pixels, c) -> pixels.drawCircleLines(centerX, centerY, radius, c));
	}

	/** Outlines a circle, one pixel wide, its middle cut to whole pixels.

		@param dst  The image.
		@param center  The middle.
		@param radius  The radius, in pixels.
		@param color  The color. */
	static function ImageDrawCircleLinesV(dst:Image, center:Vector2, radius:Int, color:Color):Void {
		ImageDrawCircleLines(dst, Std.int(f32(center.x)), Std.int(f32(center.y)), radius, color);
	}

	/** Fills a rectangle; what falls outside the image is skipped.

		@param dst  The image.
		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param color  The color. */
	static function ImageDrawRectangle(dst:Image, posX:Int, posY:Int, width:Int, height:Int, color:Color):Void {
		ImageDrawRectangleRec(dst, new Rectangle(posX, posY, width, height), color);
	}

	/** Fills a rectangle, its corner and size cut to whole pixels.

		@param dst  The image.
		@param position  The top-left corner.
		@param size  The width and height.
		@param color  The color. */
	static function ImageDrawRectangleV(dst:Image, position:Vector2, size:Vector2, color:Color):Void {
		ImageDrawRectangle(dst, Std.int(f32(position.x)), Std.int(f32(position.y)), Std.int(f32(size.x)), Std.int(f32(size.y)), color);
	}

	/** Fills a rectangle, as raylib's does: cut to the image, then to whole pixels; one 0 wide still sets its top-left pixel.

		@param dst  The image.
		@param rec  The rectangle, in pixels.
		@param color  The color. */
	static function ImageDrawRectangleRec(dst:Image, rec:Rectangle, color:Color):Void {
		if (dst.data == null || dst.width == 0 || dst.height == 0)
			return;
		var x = f32(rec.x),
			y = f32(rec.y),
			width = f32(rec.width),
			height = f32(rec.height);
		if (x < 0) {
			width = f32(width + x);
			x = 0;
		}
		if (y < 0) {
			height = f32(height + y);
			y = 0;
		}
		if (width < 0)
			width = 0;
		if (height < 0)
			height = 0;
		if (f32(x + width) >= dst.width)
			width = f32(dst.width - x);
		if (f32(y + height) >= dst.height)
			height = f32(dst.height - y);
		if (x >= dst.width || y >= dst.height)
			return;
		if (f32(x + width) <= 0 || f32(y + height) <= 0)
			return;
		var sx = Std.int(x),
			sy = Std.int(y),
			bytesPerPixel = GetPixelDataSize(1, 1, dst.format);
		ImageDrawPixel(dst, sx, sy, color);
		var first = (sy * dst.width + sx) * bytesPerPixel, w = Std.int(width);
		for (i in 1...w)
			dst.data.blit(first + i * bytesPerPixel, dst.data, first, bytesPerPixel);
		for (j in 1...Std.int(height))
			dst.data.blit(first + j * dst.width * bytesPerPixel, dst.data, first, bytesPerPixel * w);
	}

	/** Outlines a rectangle, the outline inside it: its top and bottom across its whole width, its sides between them.

		@param dst  The image.
		@param rec  The rectangle, in pixels, cut to whole pixels.
		@param thick  The outline's thickness, in pixels.
		@param color  The color. */
	static function ImageDrawRectangleLines(dst:Image, rec:Rectangle, thick:Int, color:Color):Void {
		var x = f32(rec.x),
			y = f32(rec.y),
			width = f32(rec.width),
			height = f32(rec.height);
		ImageDrawRectangle(dst, Std.int(x), Std.int(y), Std.int(width), thick, color);
		ImageDrawRectangle(dst, Std.int(x), Std.int(f32(y + thick)), thick, Std.int(f32(height - thick * 2)), color);
		ImageDrawRectangle(dst, Std.int(f32(f32(x + width) - thick)), Std.int(f32(y + thick)), thick, Std.int(f32(height - thick * 2)), color);
		ImageDrawRectangle(dst, Std.int(x), Std.int(f32(f32(y + height) - thick)), Std.int(width), thick, color);
	}

	/** Fills a triangle; its corners may go either way round.

		@param dst  The image.
		@param v1  The first corner.
		@param v2  The second corner.
		@param v3  The third corner.
		@param color  The color. */
	static function ImageDrawTriangle(dst:Image, v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void {
		shape(dst, color, (pixels, c) -> pixels.drawTriangle(v1.x, v1.y, v2.x, v2.y, v3.x, v3.y, c, c, c));
	}

	/** Fills a triangle, each corner its own color, blended across it as raylib's does: each channel by the pixel's weights, each
		rounded down, so three corners of one color may not give it exactly.

		@param dst  The image.
		@param v1  The first corner.
		@param v2  The second corner.
		@param v3  The third corner.
		@param c1  The first corner's color.
		@param c2  The second corner's color.
		@param c3  The third corner's color. */
	static function ImageDrawTriangleEx(dst:Image, v1:Vector2, v2:Vector2, v3:Vector2, c1:Color, c2:Color, c3:Color):Void {
		var ax = f32(v1.x), ay = f32(v1.y), bx = f32(v2.x), by = f32(v2.y), cx = f32(v3.x), cy = f32(v3.y);
		var xMin = Std.int(ax < bx ? (ax < cx ? ax : cx) : (bx < cx ? bx : cx)),
			yMin = Std.int(ay < by ? (ay < cy ? ay : cy) : (by < cy ? by : cy));
		var xMax = Std.int(ax > bx ? (ax > cx ? ax : cx) : (bx > cx ? bx : cx)),
			yMax = Std.int(ay > by ? (ay > cy ? ay : cy) : (by > cy ? by : cy));
		if (xMin < 0)
			xMin = 0;
		if (yMin < 0)
			yMin = 0;
		if (xMax > dst.width)
			xMax = dst.width;
		if (yMax > dst.height)
			yMax = dst.height;
		var flip = f32(f32(f32(bx - ax) * f32(cy - ay)) - f32(f32(cx - ax) * f32(by - ay))) > 0 ? -1 : 1;
		var w1XStep = Std.int(f32(cy - by)) * flip,
			w1YStep = Std.int(f32(bx - cx)) * flip;
		var w2XStep = Std.int(f32(ay - cy)) * flip,
			w2YStep = Std.int(f32(cx - ax)) * flip;
		var w3XStep = Std.int(f32(by - ay)) * flip,
			w3YStep = Std.int(f32(ax - bx)) * flip;
		var w1Row = Std.int(f32(f32(f32(xMin - bx) * w1XStep) + f32(w1YStep * f32(yMin - by))));
		var w2Row = Std.int(f32(f32(f32(xMin - cx) * w2XStep) + f32(w2YStep * f32(yMin - cy))));
		var w3Row = Std.int(f32(f32(f32(xMin - ax) * w3XStep) + f32(w3YStep * f32(yMin - ay))));
		var wInvSum = f32(255 / f32(w1Row + w2Row + w3Row));
		var a = Pixels.ofColor(c1),
			b = Pixels.ofColor(c2),
			c = Pixels.ofColor(c3);
		var bytesPerPixel = GetPixelDataSize(1, 1, dst.format);
		for (y in yMin...yMax + 1) {
			var w1 = w1Row, w2 = w2Row, w3 = w3Row;
			for (x in xMin...xMax + 1) {
				if ((w1 | w2 | w3) >= 0 && dst.data != null && x < dst.width && y < dst.height) {
					var k1 = byte(f32(f32(w1) * wInvSum)),
						k2 = byte(f32(f32(w2) * wInvSum)),
						k3 = byte(f32(f32(w3) * wInvSum));
					inline function channel(shift:Int):Int
						return Std.int((((a >>> shift) & 255) * k1 + ((b >>> shift) & 255) * k2 + ((c >>> shift) & 255) * k3) / 255) & 255;
					Pixels.setColor(dst.data, (y * dst.width + x) * bytesPerPixel, Pixels.pack(channel(0), channel(8), channel(16), channel(24)), dst.format,
						true);
				}
				w1 += w1XStep;
				w2 += w2XStep;
				w3 += w3XStep;
			}
			w1Row += w1YStep;
			w2Row += w2YStep;
			w3Row += w3YStep;
		}
	}

	/** Outlines a triangle with three `ImageDrawLine`s, its corners cut to whole pixels.

		@param dst  The image.
		@param v1  The first corner.
		@param v2  The second corner.
		@param v3  The third corner.
		@param color  The color. */
	static function ImageDrawTriangleLines(dst:Image, v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void {
		shape(dst, color, (pixels, c) -> pixels.drawTriangleLines(v1.x, v1.y, v2.x, v2.y, v3.x, v3.y, c));
	}

	/** Fills a fan of triangles, each from the first point to the next two.

		@param dst  The image.
		@param points  The points, the first the fan's middle.
		@param pointCount  How many; under 3 draws nothing.
		@param color  The color. */
	static function ImageDrawTriangleFan(dst:Image, points:Array<Vector2>, pointCount:Int, color:Color):Void {
		if (pointCount >= 3)
			for (i in 1...pointCount - 1)
				ImageDrawTriangle(dst, points[0], points[i], points[i + 1], color);
	}

	/** Fills a strip of triangles, each of three points in a row.

		@param dst  The image.
		@param points  The points.
		@param pointCount  How many; under 3 draws nothing.
		@param color  The color. */
	static function ImageDrawTriangleStrip(dst:Image, points:Array<Vector2>, pointCount:Int, color:Color):Void {
		if (pointCount >= 3)
			for (i in 2...pointCount)
				if (i % 2 == 0)
					ImageDrawTriangle(dst, points[i], points[i - 2], points[i - 1], color);
				else
					ImageDrawTriangle(dst, points[i], points[i - 1], points[i - 2], color);
	}

	/** Draws a rectangle of one image into a rectangle of another, tinted, blended over (raylib's `ColorAlphaBlend`), in their formats.
		A source with no alpha under an opaque tint is copied, the tint's color ignored, as raylib's is; a float destination is unchanged,
		as `SetPixelColor` writes none. A source rectangle of another whole-pixel size than the destination's is first resized by
		`ImageResize`, which isn't raylib's. Their mipmaps are drawn too, when both have them.

		@param dst  The image drawn into.
		@param src  The image drawn from.
		@param srcRec  The source rectangle, in its pixels, cut to it.
		@param dstRec  The destination rectangle.
		@param tint  The color the source is multiplied by; `WHITE` keeps it unchanged. */
	static function ImageDraw(dst:Image, src:Image, srcRec:Rectangle, dstRec:Rectangle, tint:Color):Void {
		drawImage(dst, 0, src, srcRec, dstRec, tint);
	}

	// ImageDraw into the level of dst whose pixels start at a byte: raylib's pointer into a mipmapped image.
	static function drawImage(dst:Image, dstStart:Int, src:Image, srcRec:Rectangle, dstRec:Rectangle, tint:Color):Void {
		if (dst.data == null || dst.width == 0 || dst.height == 0 || src.data == null || src.width == 0 || src.height == 0)
			return;
		if (dst.format >= Pixels.COMPRESSED) {
			Runtime.log(LOG_WARNING, "Image drawing not supported for compressed formats");
			return;
		}
		var sx = f32(srcRec.x),
			sy = f32(srcRec.y),
			sw = f32(srcRec.width),
			sh = f32(srcRec.height);
		var dx = f32(dstRec.x),
			dy = f32(dstRec.y),
			dw = f32(dstRec.width),
			dh = f32(dstRec.height);
		if (sx < 0) {
			sw = f32(sw + sx);
			sx = 0;
		}
		if (sy < 0) {
			sh = f32(sh + sy);
			sy = 0;
		}
		if (f32(sx + sw) > src.width)
			sw = f32(src.width - sx);
		if (f32(sy + sh) > src.height)
			sh = f32(src.height - sy);
		var from = src;
		if (Std.int(sw) != Std.int(dw) || Std.int(sh) != Std.int(dh)) {
			from = ImageFromImage(src, new Rectangle(sx, sy, sw, sh));
			ImageResize(from, Std.int(dw), Std.int(dh));
			sx = 0;
			sy = 0;
			sw = from.width;
			sh = from.height;
		}
		if (dx < 0) {
			sx = f32(sx - dx);
			sw = f32(sw + dx);
			dx = 0;
		} else if (f32(dx + sw) > dst.width)
			sw = f32(dst.width - dx);
		if (dy < 0) {
			sy = f32(sy - dy);
			sh = f32(sh + dy);
			dy = 0;
		} else if (f32(dy + sh) > dst.height)
			sh = f32(dst.height - dy);
		if (dst.width < sw)
			sw = dst.width;
		if (dst.height < sh)
			sh = dst.height;
		var t = Pixels.ofColor(tint);
		var opaque = from.format == PIXELFORMAT_UNCOMPRESSED_GRAYSCALE
			|| from.format == PIXELFORMAT_UNCOMPRESSED_R5G6B5
			|| from.format == PIXELFORMAT_UNCOMPRESSED_R8G8B8
			|| from.format == PIXELFORMAT_UNCOMPRESSED_R32
			|| from.format == PIXELFORMAT_UNCOMPRESSED_R32G32B32
			|| from.format == PIXELFORMAT_UNCOMPRESSED_R16
			|| from.format == PIXELFORMAT_UNCOMPRESSED_R16G16B16;
		var blendRequired = !((tint.a & 255) == 255 && opaque);
		var strideDst = GetPixelDataSize(dst.width, 1, dst.format),
			bytesPerPixelDst = Std.int(strideDst / dst.width);
		var strideSrc = GetPixelDataSize(from.width, 1, from.format),
			bytesPerPixelSrc = Std.int(strideSrc / from.width);
		var srcBase = (Std.int(sy) * from.width + Std.int(sx)) * bytesPerPixelSrc,
			dstBase = dstStart + (Std.int(dy) * dst.width + Std.int(dx)) * bytesPerPixelDst;
		var rows = Std.int(sh),
			columns = Std.int(sw),
			source = from.data,
			target = dst.data;
		for (_ in 0...rows) {
			if (!blendRequired && from.format == dst.format)
				copyBytes(target, dstBase, source, srcBase, columns * bytesPerPixelSrc);
			else {
				var s = srcBase, d = dstBase;
				for (_ in 0...columns) {
					var colSrc = Pixels.getColor(source, s, from.format);
					var color = blendRequired ? Pixels.blend(Pixels.getColor(target, d, dst.format), colSrc, t) : colSrc;
					Pixels.setColor(target, d, color, dst.format, false);
					d += bytesPerPixelDst;
					s += bytesPerPixelSrc;
				}
			}
			srcBase += strideSrc;
			dstBase += strideDst;
		}
		if (dst.mipmaps > 1 && src.mipmaps > 1) {
			var level = new Image(dst.data, Std.int(dst.width / 2), Std.int(dst.height / 2), dst.mipmaps - 1, dst.format);
			var skip = GetPixelDataSize(src.width, src.height, src.format);
			if (skip >= src.data.length)
				return;
			var srcLevel = new Image(src.data.sub(skip, src.data.length - skip), Std.int(src.width / 2), Std.int(src.height / 2), src.mipmaps - 1, src.format);
			drawImage(level, dstStart + GetPixelDataSize(dst.width, dst.height, dst.format), srcLevel,
				new Rectangle(f32(sx / 2), f32(sy / 2), f32(sw / 2), f32(sh / 2)), new Rectangle(f32(dx / 2), f32(dy / 2), f32(dw / 2), f32(dh / 2)), tint);
		}
	}

	/** Draws text in raylib's default font into an image, letters 1 pixel apart, as `ImageDrawTextEx` draws it.

		@param dst  The image.
		@param text  The text.
		@param posX  The left edge.
		@param posY  The top edge.
		@param fontSize  The height of a line, in pixels.
		@param color  The color. */
	static function ImageDrawText(dst:Image, text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void {
		ImageDrawTextEx(dst, GetFontDefault(), text, new Vector2(posX, posY), fontSize, 1, color);
	}

	/** Draws text in a font into an image: `ImageTextEx`'s image, drawn at a point.

		@param dst  The image.
		@param font  The font.
		@param text  The text.
		@param position  The top-left corner.
		@param fontSize  The height of a line, in pixels.
		@param spacing  The space between letters, at the font's size.
		@param tint  The color. */
	static function ImageDrawTextEx(dst:Image, font:Font, text:String, position:Vector2, fontSize:Float, spacing:Float, tint:Color):Void {
		var imText = ImageTextEx(font, text, fontSize, spacing, tint);
		ImageDraw(dst, imText, new Rectangle(0, 0, imText.width, imText.height), new Rectangle(position.x, position.y, imText.width, imText.height), WHITE);
	}

	// ---- Images: what the functions share ----
	static final ONE_31 = f32(1 / 31);
	static final ONE_63 = f32(1 / 63);
	static final ONE_15 = f32(1 / 15);

	// Copies bytes, as much of them as both have; what the source lacks is left as it is.
	static function copyBytes(dst:haxe.io.Bytes, dstAt:Int, src:Null<haxe.io.Bytes>, srcAt:Int, length:Int):Void {
		if (src == null || length <= 0)
			return;
		if (srcAt < 0) {
			dstAt -= srcAt;
			length += srcAt;
			srcAt = 0;
		}
		if (dstAt < 0) {
			srcAt -= dstAt;
			length += dstAt;
			dstAt = 0;
		}
		if (srcAt + length > src.length)
			length = src.length - srcAt;
		if (dstAt + length > dst.length)
			length = dst.length - dstAt;
		if (length > 0)
			dst.blit(dstAt, src, srcAt, length);
	}

	// Whether raylib's byte-moving functions act on an image: it has pixels and isn't compressed, which is refused with a warning.
	static function manipulable(image:Image):Bool {
		if (image.data == null || image.width == 0 || image.height == 0)
			return false;
		if (image.mipmaps > 1)
			Runtime.log(LOG_WARNING, "Image manipulation only applied to base mipmap level");
		if (image.format >= Pixels.COMPRESSED) {
			Runtime.log(LOG_WARNING, "Image manipulation not supported for compressed formats");
			return false;
		}
		return true;
	}

	// raylib's change through colors: the image read as RGBA, changed by helix-services, and written back in its format.
	static function throughColors(image:Image, change:helix.services.images.Image->Void):Void {
		if (image.data == null || image.width == 0 || image.height == 0)
			return;
		var pixels = Pixels.colors(image.data, image.width, image.height, image.format);
		change(new helix.services.images.Image("", image.width, image.height, pixels));
		backToFormat(image, pixels);
	}

	// An image's pixels replaced by RGBA ones, then converted back to its format.
	static function backToFormat(image:Image, pixels:haxe.io.Bytes):Void {
		var format = image.format;
		image.data = pixels;
		image.format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
		ImageFormat(image, format);
	}

	// A shape drawn by helix-services: into an RGBA image's pixels; another format's pixels the shape covers, found on an RGBA mask, are
	// each written as ImageDrawPixel writes them, as raylib's shapes are drawn pixel by pixel in one color.
	static function shape(dst:Image, color:Color, draw:(helix.services.images.Image, Int) -> Void):Void {
		if (dst.data == null || dst.width <= 0 || dst.height <= 0)
			return;
		var count = dst.width * dst.height;
		if (dst.format == PIXELFORMAT_UNCOMPRESSED_R8G8B8A8) {
			draw(new helix.services.images.Image("", dst.width, dst.height, dst.data), Pixels.argb(Pixels.ofColor(color)));
			return;
		}
		var mask = haxe.io.Bytes.alloc(count * 4);
		mask.fill(0, mask.length, 0);
		draw(new helix.services.images.Image("", dst.width, dst.height, mask), 0xffffffff);
		var rgba = Pixels.ofColor(color),
			bytesPerPixel = GetPixelDataSize(1, 1, dst.format);
		for (i in 0...count)
			if (mask.get(i * 4 + 3) != 0)
				Pixels.setColor(dst.data, i * bytesPerPixel, rgba, dst.format, true);
	}

	// ---- Images as textures ----

	/** Makes a texture of an image, in any uncompressed format: its pixels go to the GPU as RGBA when first drawn, its mipmaps too when it
		has them (`ImageMipmaps`), filtered through them, trilinear, as raylib sets it.
		Its format is the image's, as raylib's is, so a grayscale image's texture says `PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`. A compressed
		format gives no texture, with a warning.

		@param image  The image.
		@return  The texture. */
	static function LoadTextureFromImage(image:Image):Texture2D {
		if (image.width == 0 || image.height == 0 || image.data == null) {
			Runtime.log(LOG_WARNING, "IMAGE: Data is not valid to load texture");
			return new Texture2D();
		}
		if (image.format >= Pixels.COMPRESSED || image.format < PIXELFORMAT_UNCOMPRESSED_GRAYSCALE) {
			Runtime.log(LOG_WARNING, 'TEXTURE: Pixel format ${image.format} can\'t be loaded here');
			return new Texture2D();
		}
		var pixels = Pixels.colors(image.data, image.width, image.height, image.format);
		// Its mipmaps, each after the last in its data, made RGBA as its top level is.
		var levels = [], at = GetPixelDataSize(image.width, image.height, image.format), w = image.width, h = image.height;
		for (_ in 1...image.mipmaps) {
			w = w > 1 ? w >> 1 : 1;
			h = h > 1 ? h >> 1 : 1;
			var size = GetPixelDataSize(w, h, image.format);
			if (at + size > image.data.length)
				break;
			levels.push(Pixels.colors(image.data.sub(at, size), w, h, image.format));
			at += size;
		}
		var id = Textures.fromImage("", new helix.services.images.Image("", image.width, image.height, pixels), levels.length > 0 ? levels : null);
		// A texture with mipmaps is filtered through them, trilinear, as rlLoadTexture sets it.
		if (levels.length > 0)
			Textures.setSampling(id, Textures.samplingOfId(id).withFilter(Linear).withMipmapFilter(Linear));
		return new Texture2D(id, image.width, image.height, levels.length + 1, image.format);
	}

	/** Makes a cubemap of an image, its six faces laid out as raylib's layouts lay them: `CUBEMAP_LAYOUT_LINE_VERTICAL` (a column, +X,
		-X, +Y, -Y, +Z, -Z from the top), `CUBEMAP_LAYOUT_LINE_HORIZONTAL` (a row, in that order from the left),
		`CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR` (3 faces wide, 4 high: +Y, +X, -Y and -X down the middle column, +Z left of +X and -Z right
		of it) or `CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE` (4 wide, 3 high: +Y at the top of the second column, then -X, +Z, +X, -Z
		across, then -Y below +Z), each face's rows top first as GL's cube faces take them; `CUBEMAP_LAYOUT_AUTO_DETECT` takes the layout
		from the image's shape. A face is the image's height over 6 (a column), its width over 6 (a row), over 3 (3 by 4) or over 4 (4 by 3).

		As raylib's: a column is read as it is, the face size squared times 6 pixels from the image's first, row after row, so an image
		not 1 face by 6 is read across its rows; the other layouts draw each face onto magenta (`ImageDraw`), a translucent pixel blended
		over it, a face partly past the image's edge its part inside stretched to the face, and one wholly past it left magenta (raylib's
		divides by zero). A shape `CUBEMAP_LAYOUT_AUTO_DETECT` doesn't know gives no cubemap,
		with a warning. Its format is the image's, its pixels RGBA on the GPU, sampled linearly as rlgl's cubemaps are. An image with
		mipmaps gives a cubemap with mipmaps, sampled through them: a column's from the image's levels, read as its first is; the other
		layouts' made from each face, as GL's `glGenerateMipmap` makes them, where raylib 6.2's are magenta (5.5's are magenta whatever the
		image). Where raylib's differs, it makes an empty GL cubemap: a face size of 0 (an image too small for its layout, or a layout raylib
		doesn't have) gives none here, as do a compressed format and an image too small for the column it is read as, with a warning.

		The cubemap is a `Texture2D`'s record: a material's `MATERIAL_MAP_CUBEMAP`, `MATERIAL_MAP_IRRADIANCE` or `MATERIAL_MAP_PREFILTER`
		binds it to a shader's `samplerCube` (`DrawMesh`), as does `SetShaderValueTexture`; drawn as a 2D texture, it draws nothing.
		`UnloadTexture` lets go of it, and it is counted as any texture is (docs/DECISIONS.md 25).

		@param image  The image.
		@param layout  The layout (`CUBEMAP_LAYOUT_*`).
		@return  The cubemap; id 0 for none. */
	static function LoadTextureCubemap(image:Image, layout:Int):TextureCubemap {
		var size = 0;
		if (layout == CUBEMAP_LAYOUT_AUTO_DETECT) {
			if (image.width > image.height) {
				if (Std.int(image.width / 6) == image.height) {
					layout = CUBEMAP_LAYOUT_LINE_HORIZONTAL;
					size = Std.int(image.width / 6);
				} else if (Std.int(image.width / 4) == Std.int(image.height / 3)) {
					layout = CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE;
					size = Std.int(image.width / 4);
				}
			} else if (image.height > image.width) {
				if (Std.int(image.height / 6) == image.width) {
					layout = CUBEMAP_LAYOUT_LINE_VERTICAL;
					size = Std.int(image.height / 6);
				} else if (Std.int(image.width / 3) == Std.int(image.height / 4)) {
					layout = CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR;
					size = Std.int(image.width / 3);
				}
			}
		} else
			size = switch layout {
				case CUBEMAP_LAYOUT_LINE_VERTICAL: Std.int(image.height / 6);
				case CUBEMAP_LAYOUT_LINE_HORIZONTAL: Std.int(image.width / 6);
				case CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR: Std.int(image.width / 3);
				case CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE: Std.int(image.width / 4);
				case _: 0;
			}
		if (layout == CUBEMAP_LAYOUT_AUTO_DETECT) {
			Runtime.log(LOG_WARNING, "IMAGE: Failed to detect cubemap image layout");
			return new Texture2D(0, 0, 0, 0, 0);
		}
		var failed = new Texture2D(0, size, size, 0, 0);
		if (size < 1 || image.data == null || image.format >= Pixels.COMPRESSED || image.format < PIXELFORMAT_UNCOMPRESSED_GRAYSCALE) {
			Runtime.log(LOG_WARNING, "TEXTURE: Failed to load cubemap texture");
			return failed;
		}
		var faceBytes = size * size * 4;
		// Its levels, each 6 faces of RGBA: a cube's chain goes down to 1 by 1.
		var most = 1, side = size;
		while (side > 1) {
			side >>= 1;
			most++;
		}
		var levels:Array<haxe.io.Bytes> = [];
		if (layout == CUBEMAP_LAYOUT_LINE_VERTICAL) {
			// rlLoadTextureCubemap reads the image's bytes as they come, level after level.
			var pixels = new haxe.io.BytesBuffer(), w = image.width, h = image.height, at = 0;
			for (_ in 0...(image.mipmaps < 1 ? 1 : image.mipmaps)) {
				var bytes = GetPixelDataSize(w, h, image.format);
				if (at + bytes > image.data.length)
					break;
				pixels.add(Pixels.colors(image.data.sub(at, bytes), w * h, 1, image.format));
				at += bytes;
				w = w > 1 ? w >> 1 : 1;
				h = h > 1 ? h >> 1 : 1;
			}
			var all = pixels.getBytes(), read = 0;
			side = size;
			for (level in 0...(image.mipmaps < 1 ? 1 : image.mipmaps > most ? most : image.mipmaps)) {
				var bytes = side * side * 4 * 6;
				if (read + bytes > all.length)
					break;
				levels.push(all.sub(read, bytes));
				read += bytes;
				side = side > 1 ? side >> 1 : 1;
			}
			if (levels.length == 0) {
				Runtime.log(LOG_WARNING, "TEXTURE: Failed to load cubemap texture");
				return failed;
			}
		} else {
			var origins = switch layout {
				case CUBEMAP_LAYOUT_LINE_HORIZONTAL: [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [5, 0]];
				case CUBEMAP_LAYOUT_CROSS_THREE_BY_FOUR: [[1, 1], [1, 3], [1, 0], [1, 2], [0, 1], [2, 1]];
				case _: [[2, 1], [0, 1], [1, 0], [1, 2], [1, 1], [3, 1]];
			}
			var faces = GenImageColor(size, size * 6, MAGENTA);
			ImageFormat(faces, image.format);
			for (i => o in origins)
				ImageDraw(faces, image, new Rectangle(o[0] * size, o[1] * size, size, size), new Rectangle(0, size * i, size, size), WHITE);
			var top = Pixels.colors(faces.data, size, size * 6, faces.format);
			levels.push(top);
			if (image.mipmaps > 1) {
				var chains = [for (i in 0...6) Mipmaps.build(size, size, top.sub(i * faceBytes, faceBytes))];
				for (level in 0...most - 1) {
					var level6 = new haxe.io.BytesBuffer();
					for (chain in chains)
						level6.add(chain[level]);
					levels.push(level6.getBytes());
				}
			}
		}
		var id = Textures.fromCube(size, levels);
		Runtime.log(LOG_INFO, 'TEXTURE: [ID $id] Cubemap texture loaded successfully (${size}x$size)');
		return new Texture2D(id, size, size, levels.length, image.format);
	}

	/** Replaces a texture's pixels, as raylib's does on the GPU. The pixels are in the texture's format (`texture.format`), rows top
		first, its width by its height. Draws asked for before it this frame in a render texture drawn into since, or on the screen, show
		the new pixels too, as rlgl's batch drawn after it does; those in render textures drawn into before it keep the old. A render
		texture's, a cubemap's, a compressed format's and pixels too few for the texture change nothing (raylib's reads past them), with a
		warning.

		@param texture  The texture.
		@param pixels  The pixels: their bytes (`haxe.io.Bytes`), or an array of `Color` (R8G8B8A8's bytes, as raylib's `Color *` is). */
	static function UpdateTexture(texture:Texture2D, pixels:Dynamic):Void {
		updateRectangle(texture, 0, 0, texture.width, texture.height, pixels);
	}

	/** Replaces a rectangle of a texture's pixels, as `UpdateTexture` does the whole. A rectangle not inside the texture changes nothing,
		as GL refuses it.

		@param texture  The texture.
		@param rec  The rectangle, in pixels from the texture's top-left corner; its numbers are cut to whole pixels.
		@param pixels  The rectangle's pixels, rows top first, in the texture's format: bytes, or an array of `Color`. */
	static function UpdateTextureRec(texture:Texture2D, rec:Rectangle, pixels:Dynamic):Void {
		updateRectangle(texture, Std.int(rec.x), Std.int(rec.y), Std.int(rec.width), Std.int(rec.height), pixels);
	}

	// rlUpdateTexture: a rectangle of a texture's pixels in its format, made RGBA and replaced.
	static function updateRectangle(texture:Texture2D, x:Int, y:Int, width:Int, height:Int, pixels:Dynamic):Void {
		if (texture.id <= 0 || pixels == null)
			return;
		if (texture.flipped
			|| Textures.isCube(texture.id)
			|| texture.format >= Pixels.COMPRESSED
			|| texture.format < PIXELFORMAT_UNCOMPRESSED_GRAYSCALE) {
			Runtime.log(LOG_WARNING, 'TEXTURE: [ID ${texture.id}] Failed to update for current texture format (${texture.format})');
			return;
		}
		if (x < 0 || y < 0 || width <= 0 || height <= 0 || x + width > texture.width || y + height > texture.height)
			return;
		var bytes:haxe.io.Bytes = null;
		if (Std.isOfType(pixels, haxe.io.Bytes))
			bytes = pixels;
		else if (Std.isOfType(pixels, Array)) {
			var colors:Array<Color> = pixels;
			bytes = haxe.io.Bytes.alloc(colors.length * 4);
			for (i => c in colors) {
				bytes.set(i * 4, c.r);
				bytes.set(i * 4 + 1, c.g);
				bytes.set(i * 4 + 2, c.b);
				bytes.set(i * 4 + 3, c.a);
			}
		}
		if (bytes == null || bytes.length < GetPixelDataSize(width, height, texture.format)) {
			Runtime.log(LOG_WARNING, 'TEXTURE: [ID ${texture.id}] Failed to update: fewer pixels than the rectangle');
			return;
		}
		Textures.update(texture.id, x, y, width, height, Pixels.colors(bytes, width, height, texture.format));
	}

	/** Sets how a texture wraps past its edges: `TEXTURE_WRAP_REPEAT` (raylib's default), `TEXTURE_WRAP_CLAMP` or
		`TEXTURE_WRAP_MIRROR_REPEAT`. `TEXTURE_WRAP_MIRROR_CLAMP` isn't here, and leaves it unchanged, with a warning. A cubemap is left unchanged.

		@param texture  The texture.
		@param wrap  The wrap (`TEXTURE_WRAP_*`). */
	static function SetTextureWrap(texture:Texture2D, wrap:Int):Void {
		var mode:helix.platform.Wrap = switch wrap {
			case TEXTURE_WRAP_REPEAT: Repeat;
			case TEXTURE_WRAP_CLAMP: Clamp;
			case TEXTURE_WRAP_MIRROR_REPEAT: Mirror;
			case TEXTURE_WRAP_MIRROR_CLAMP:
				Runtime.log(LOG_WARNING, 'TEXTURE: [ID ${texture.id}] TEXTURE_WRAP_MIRROR_CLAMP isn\'t supported here');
				return;
			case _: return;
		}
		Textures.setSampling(texture.id, Textures.samplingOfId(texture.id).withWrap(mode, mode));
	}

	/** Draws a texture as a nine-patch (or a three-patch) into a rectangle, turned about an origin, as raylib's does: its corners kept,
		its edges and middle stretched; a rectangle smaller than the borders shrinks them and drops the middle.

		@param texture  The texture.
		@param nPatchInfo  The patch: its rectangle on the texture, its borders and its layout (`NPATCH_*`).
		@param dest  Where it goes; its x and y are where the origin lands.
		@param origin  The point it turns about, from dest's top-left corner.
		@param rotation  Clockwise, in degrees.
		@param tint  The color it is multiplied by. */
	static function DrawTextureNPatch(texture:Texture2D, nPatchInfo:NPatchInfo, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void {
		if (texture.id <= 0)
			return;
		var width:Float = texture.width, height:Float = texture.height;
		var patchWidth = Std.int(dest.width) <= 0 ? 0. : dest.width,
			patchHeight = Std.int(dest.height) <= 0 ? 0. : dest.height;
		var source = nPatchInfo.source, sourceX = source.x, sourceY = source.y;
		if (source.width < 0)
			sourceX -= source.width;
		if (source.height < 0)
			sourceY -= source.height;
		if (nPatchInfo.layout == NPATCH_THREE_PATCH_HORIZONTAL)
			patchHeight = source.height;
		if (nPatchInfo.layout == NPATCH_THREE_PATCH_VERTICAL)
			patchWidth = source.width;
		var drawCenter = true, drawMiddle = true;
		var leftBorder:Float = nPatchInfo.left,
			topBorder:Float = nPatchInfo.top,
			rightBorder:Float = nPatchInfo.right,
			bottomBorder:Float = nPatchInfo.bottom;
		if (patchWidth <= leftBorder + rightBorder && nPatchInfo.layout != NPATCH_THREE_PATCH_VERTICAL) {
			drawCenter = false;
			leftBorder = leftBorder / (leftBorder + rightBorder) * patchWidth;
			rightBorder = patchWidth - leftBorder;
		}
		if (patchHeight <= topBorder + bottomBorder && nPatchInfo.layout != NPATCH_THREE_PATCH_HORIZONTAL) {
			drawMiddle = false;
			topBorder = topBorder / (topBorder + bottomBorder) * patchHeight;
			bottomBorder = patchHeight - topBorder;
		}
		// The patch's columns and rows: its outer and inner edges, where they are drawn and where they are on the texture.
		var xs = [0, leftBorder, patchWidth - rightBorder, patchWidth],
			ys = [0, topBorder, patchHeight - bottomBorder, patchHeight];
		var us = [
			sourceX / width,
			(sourceX + leftBorder) / width,
			(sourceX + source.width - rightBorder) / width,
			(sourceX + source.width) / width
		];
		var vs = [
			sourceY / height,
			(sourceY + topBorder) / height,
			(sourceY + source.height - bottomBorder) / height,
			(sourceY + source.height) / height
		];
		if (texture.flipped)
			vs = [for (v in vs) 1 - v];
		var angle = rotation * Math.PI / 180,
			c = Math.cos(angle),
			s = Math.sin(angle);
		var handle = Textures.handle(texture.id);
		inline function corner(i:Int, j:Int) {
			var px = xs[i] - origin.x, py = ys[j] - origin.y;
			flat(handle, dest.x + px * c - py * s, dest.y + px * s + py * c, us[i], vs[j], tint);
		}
		// A quad from column i0 to i1 and row j0 to j1, as rlgl's two triangles.
		inline function quad(i0:Int, j0:Int, i1:Int, j1:Int) {
			corner(i0, j1);
			corner(i1, j1);
			corner(i1, j0);
			corner(i0, j1);
			corner(i1, j0);
			corner(i0, j0);
		}
		switch nPatchInfo.layout {
			case NPATCH_NINE_PATCH:
				for (row in 0...3) {
					if (row == 1 && !drawMiddle)
						continue;
					quad(0, row, 1, row + 1);
					if (drawCenter)
						quad(1, row, 2, row + 1);
					quad(2, row, 3, row + 1);
				}
			case NPATCH_THREE_PATCH_VERTICAL:
				quad(0, 0, 3, 1);
				if (drawCenter)
					quad(0, 1, 3, 2);
				quad(0, 2, 3, 3);
			case NPATCH_THREE_PATCH_HORIZONTAL:
				quad(0, 0, 1, 3);
				if (drawCenter)
					quad(1, 0, 2, 3);
				quad(2, 0, 3, 3);
			case _:
		}
	}

	// ---- Pixels ----

	/** Returns one pixel's color from pixels in a format, as raylib's does: 16-bit channels widened by integers, floats times 255.
		raylib takes a pointer to the pixel; here it is the pixels and the pixel's first byte.

		@param srcPtr  The pixels.
		@param format  Their format (`PIXELFORMAT_UNCOMPRESSED_*`).
		@param offset  Optional. The pixel's first byte; 0 when omitted.
		@return  The color; clear black for a compressed format. */
	static function GetPixelColor(srcPtr:haxe.io.Bytes, format:Int, offset:Int = 0):Color {
		return Pixels.toColor(Pixels.getColor(srcPtr, offset, format));
	}

	/** Writes one pixel's color into pixels in a format, as raylib's does: grayscale by luminance, 16-bit channels rounded; a float
		format is left unchanged. raylib takes a pointer to the pixel; here it is the pixels and the pixel's first byte.

		@param dstPtr  The pixels.
		@param color  The color.
		@param format  Their format (`PIXELFORMAT_UNCOMPRESSED_*`).
		@param offset  Optional. The pixel's first byte; 0 when omitted. */
	static function SetPixelColor(dstPtr:haxe.io.Bytes, color:Color, format:Int, offset:Int = 0):Void {
		Pixels.setColor(dstPtr, offset, Pixels.ofColor(color), format, false);
	}
	#end
}
