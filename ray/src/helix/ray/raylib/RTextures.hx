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
