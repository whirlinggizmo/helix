package helix.raylib.extras;

import helix.raylib.*;

/** Provides raylib's shadowmap example's render texture: a depth buffer a shader can sample, which `BeginTextureMode` draws into. See
	`Lighting.BeginShadowMode` for shadows the lit shaders receive without a shader of the program's own.

	```haxe
	var shadowMap = LoadShadowmapRenderTexture(1024, 1024);
	// each frame
	BeginTextureMode(shadowMap);
	ClearBackground(WHITE);
	BeginMode3D(lightCamera);
	var lightView = rlGetMatrixModelview(), lightProjection = rlGetMatrixProjection();
	DrawScene();
	EndMode3D();
	EndTextureMode();
	SetShaderValueMatrix(shader, lightVPLoc, MatrixMultiply(lightView, lightProjection));
	SetShaderValueTexture(shader, shadowMapLoc, shadowMap.depth);
	BeginMode3D(camera);
	DrawScene();
	EndMode3D();
	``` */
class Shadowmaps {
	/** Returns a render texture of depth alone, raylib's shadowmap example's `LoadShadowmapRenderTexture`. Its `depth` is a texture of
		the depth drawn into it, 0 nearest to 1 farthest, read from a shader's `.r`, stored bottom row first as raylib's render textures
		are. Its `texture` is empty: what a draw colors is dropped.

		Bind `depth` to a shader with `SetShaderValueTexture`, which takes the place of the example's `rlEnableTexture` and
		`rlSetUniform`. It is read point-sampled, clamped at its edges, until `SetTextureFilter` and `SetTextureWrap` say otherwise.

		@param width  The width, in texels.
		@param height  The height, in texels.
		@return  The render texture, the program's until `UnloadShadowmapRenderTexture`. */
	public static function LoadShadowmapRenderTexture(width:Int, height:Int):RenderTexture2D {
		throw "not built yet";
	}

	/** Frees a render texture `LoadShadowmapRenderTexture` made, raylib's shadowmap example's `UnloadShadowmapRenderTexture`.

		@param target  The render texture. */
	public static function UnloadShadowmapRenderTexture(target:RenderTexture2D):Void {
		throw "not built yet";
	}
}
