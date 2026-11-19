package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RTextures.*;
#end

/** Provides helix-raylib's render texture fitted to the screen, written here and forwarded by `helix.raylib.extras.Textures`
	(`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RRenderTextureFit {
	#if !macro
	/** Draws a render texture fitted to the screen: as large as fits, its aspect kept, centered with bars beside or above it, and the
		right way up. Drawn between `BeginDrawing` and `EndDrawing`, outside the render texture's `BeginTextureMode`.

		@param target  The render texture.
		@param integerScale  Whether its size is a whole multiple of the render texture's, for pixel art. A screen smaller than the render
			texture shrinks it all the same.
		@param tint  The tint. */
	static function DrawRenderTextureFit(target:RenderTexture2D, integerScale:Bool, tint:Color):Void {
		var texture = target.texture;
		fit(texture.width, texture.height, integerScale);
		RTextures.quad(texture, 0, 0, texture.width, -texture.height, fitX, fitY, texture.width * fitScale, texture.height * fitScale, 0, 0, 0, tint);
	}

	/** Sets the mouse's offset and scale (raylib's `SetMouseOffset` and `SetMouseScale`) to a render texture drawn by
		`DrawRenderTextureFit`. `GetMousePosition` and raygui's controls then read the mouse in the render texture's pixels. Set again
		when the window's size changes, or each frame.

		@param target  The render texture.
		@param integerScale  Whether its size is a whole multiple of the render texture's, as provided to `DrawRenderTextureFit`. */
	static function SetMouseRenderTextureFit(target:RenderTexture2D, integerScale:Bool):Void {
		fit(target.texture.width, target.texture.height, integerScale);
		if (fitScale <= 0)
			return;
		SetMouseOffset(-Math.round(fitX), -Math.round(fitY));
		SetMouseScale(1 / fitScale, 1 / fitScale);
	}

	/** Returns where `DrawRenderTextureFit` draws a render texture on the screen.

		@param target  The render texture.
		@param integerScale  Whether its size is a whole multiple of the render texture's.
		@param out  Optional. The rectangle to fill; a new one when omitted.
		@return  out, or the new rectangle, in screen pixels. */
	static function GetRenderTextureFitRectangle(target:RenderTexture2D, integerScale:Bool, ?out:Rectangle):Rectangle {
		if (out == null)
			out = new Rectangle(0, 0, 0, 0);
		fit(target.texture.width, target.texture.height, integerScale);
		out.x = fitX;
		out.y = fitY;
		out.width = target.texture.width * fitScale;
		out.height = target.texture.height * fitScale;
		return out;
	}

	// Where fit last put a render texture: its top-left on the screen, and its scale.
	static var fitX:Float;
	static var fitY:Float;
	static var fitScale:Float;

	// Finds where a render texture of a size is drawn fitted to the screen: a whole scale when asked, and when the screen holds one.
	static function fit(width:Int, height:Int, integerScale:Bool):Void {
		var screenWidth = GetScreenWidth(), screenHeight = GetScreenHeight();
		fitScale = width <= 0 || height <= 0 ? 0 : Math.min(screenWidth / width, screenHeight / height);
		if (integerScale && fitScale >= 1)
			fitScale = Math.ffloor(fitScale);
		fitX = Math.ffloor((screenWidth - width * fitScale) / 2);
		fitY = Math.ffloor((screenHeight - height * fitScale) / 2);
	}
	#end
}
