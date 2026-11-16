package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.internal.Program;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
#end

/** Provides raylib's shadowmap example's render texture, written here and forwarded by `helix.raylib.extras.Shadowmaps`
	(`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
@:access(helix.raylib.internal.Frame)
class RShadowmaps {
	#if !macro
	/** Returns a render texture of depth alone, raylib's shadowmap example's `LoadShadowmapRenderTexture`. Its `depth` is a texture of
		the depth drawn into it, 0 nearest to 1 farthest, read from a shader's `.r`, stored bottom row first as raylib's render textures
		are. Its `texture` is empty: what a draw colors is dropped.

		Bind `depth` to a shader with `SetShaderValueTexture`, which takes the place of the example's `rlEnableTexture` and
		`rlSetUniform`: it binds `depth` to the sampler the location names, a texture unit of its own, so the example's unit 10 isn't
		needed. It stays bound to the shader for every draw after, frame after frame, until `SetShaderValueTexture` sets another. A draw
		into this render texture reads the white texture in place of its `depth` set so, as a pass can't read the depth it draws.

		`depth` is read point-sampled whatever `SetTextureFilter` sets, and clamped at its edges until `SetTextureWrap` sets another
		wrap.

		@param width  The width, in texels.
		@param height  The height, in texels.
		@return  The render texture, the program's until `UnloadShadowmapRenderTexture`. */
	static function LoadShadowmapRenderTexture(width:Int, height:Int):RenderTexture2D {
		// One sample, as raylib's render textures have; bottom row first, as raylib's are on GL; its color unread.
		var target = Runtime.graphics.createRenderTarget(width, height, helix.platform.TextureFormat.Rgba8, Texture, 1, true);
		var gpu = Runtime.graphics.getRenderTargetDepth(target);
		if (depths == null) {
			depths = new Map();
			// A shader's texture is found as SetShaderValueTexture finds it, but for the depth of the render texture drawn into, which
			// is none, read as the white texture: the platform refuses a pass's own depth. SetShaderValueTexture and the Lighting
			// extra's shadows (ShadowSlots) set Program.resolve only when it's unset, so they keep this one.
			Program.resolve = id -> {
				var gpu = Textures.handle(id),
					own = depths.get(Runtime.frame.pass.target);
				return own != null && gpu == own ? 0 : gpu;
			};
			RTextures.unloadShadowmap = UnloadShadowmapRenderTexture;
		}
		depths.set(target, gpu);
		var depth = new Texture2D(Textures.fromHandle(gpu), width, height);
		depth.rendered = true;
		return new RenderTexture(target, new Texture2D(0, width, height), depth);
	}

	/** Frees a render texture `LoadShadowmapRenderTexture` made, raylib's shadowmap example's `UnloadShadowmapRenderTexture`, its depth
		with it, as `UnloadRenderTexture` does.

		@param target  The render texture. */
	static function UnloadShadowmapRenderTexture(target:RenderTexture2D):Void {
		if (target.id == 0 || depths == null || !depths.exists(target.id))
			return;
		depths.remove(target.id);
		Textures.forgetHandle(target.depth.id);
		Runtime.graphics.disposeTexture(target.id);
		target.id = 0;
		target.depth.id = 0;
	}

	// Each shadowmap render texture's depth texture, by its render target's handle, for Program.resolve. Made by the first load.
	static var depths:Null<Map<Int, Int>>;
	#end
}
