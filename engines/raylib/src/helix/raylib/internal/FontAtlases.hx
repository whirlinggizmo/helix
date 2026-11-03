package helix.raylib.internal;

import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RTextures.*;

/** Keeps the image each font's texture is made from, for `ExportFontAsCode`, which reads its atlas through it.

	A program naming `ExportFontAsCode` links this class, and its start sets `RText.keepingAtlas`, so every font from the first on keeps its
	image; a program not naming it keeps none, as raylib keeps no font's pixels on the CPU. */
@:noCompletion
@:allow(helix.raylib)
class FontAtlases {
	static function __init__():Void {
		helix.raylib.modules.RText.keepingAtlas = keep;
	}

	// Keeps the image a font's texture was made from.
	static function keep(font:Font, image:Image):Void {
		font.atlas = image;
		font.atlasTexture = font.texture.id;
	}

	/** Returns a font's texture's pixels as raylib's `LoadImageFromTexture` reads them back from the GPU, in the texture's format: the
		image the texture was made from, or the texture's own in memory (RGBA) made its format; an empty image, as raylib's for a texture
		it can't read, for one on the GPU alone.

		@param font  The font.
		@return  The pixels, an image of their own. */
	public static function atlasOf(font:Font):Image {
		var texture = font.texture;
		if (texture == null)
			return new Image();
		if (font.atlas != null && font.atlasTexture == texture.id && font.atlas.format == texture.format) {
			var a = font.atlas;
			return new Image(a.data, a.width, a.height, 1, a.format);
		}
		var memory = Textures.onGpu(texture.id) == 0 ? Textures.imageOf(texture.id) : null;
		if (memory == null) {
			Runtime.log(LOG_WARNING, 'TEXTURE: [ID ${texture.id}] Failed to retrieve pixel data');
			return new Image();
		}
		var image = new Image(memory.pixels, memory.width, memory.height, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
		if (texture.format == PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA || texture.format == PIXELFORMAT_UNCOMPRESSED_GRAYSCALE) {
			// Gray textures are white with their gray in red: taken back as they were sent.
			var alpha = texture.format == PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA,
				count = image.width * image.height;
			var out = haxe.io.Bytes.alloc(count * (alpha ? 2 : 1));
			for (i in 0...count) {
				out.set(alpha ? i * 2 : i, memory.pixels.get(i * 4));
				if (alpha)
					out.set(i * 2 + 1, memory.pixels.get(i * 4 + 3));
			}
			return new Image(out, image.width, image.height, 1, texture.format);
		}
		ImageFormat(image, texture.format);
		return image;
	}
}
