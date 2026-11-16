# Shadowmaps

[Back to the library](README.md)

## Shadowmaps

*class* in [`engines/raylib/src/helix/raylib/extras/Shadowmaps.hx`](../src/helix/raylib/extras/Shadowmaps.hx), `import helix.raylib.extras.Shadowmaps;`

Provides raylib's shadowmap example's render texture: a depth buffer a shader can sample, which `BeginTextureMode` draws into. See `Lighting.BeginShadowMode` for shadows the lit shaders receive without a shader of the program's own. Imported apart: `import helix.raylib.extras.Shadowmaps.*;`. The example `engines/raylib/examples/extras/shadowmaps` is raylib's, written with it.

```haxe
import helix.raylib.Rlgl.*; // rlGetMatrixModelview, rlGetMatrixProjection

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
```

### shadowmaps: raylib's shadowmap example's render texture of depth alone

```haxe
static function LoadShadowmapRenderTexture(width:Int, height:Int):RenderTexture2D
static function UnloadShadowmapRenderTexture(target:RenderTexture2D):Void
```

- `LoadShadowmapRenderTexture`: Returns a render texture of depth alone, raylib's shadowmap example's `LoadShadowmapRenderTexture`. Its `depth` is a texture of the depth drawn into it, 0 nearest to 1 farthest, read from a shader's `.r`, stored bottom row first as raylib's render textures are. Its `texture` is empty: what a draw colors is dropped.
  - `width`: The width, in texels.
  - `height`: The height, in texels.
  - returns: The render texture, the program's until `UnloadShadowmapRenderTexture`.

  Bind `depth` to a shader with `SetShaderValueTexture`, which takes the place of the example's `rlEnableTexture` and `rlSetUniform`: it binds `depth` to the sampler the location names, a texture unit of its own, so the example's unit 10 isn't needed. It stays bound to the shader for every draw after, frame after frame, until `SetShaderValueTexture` sets another. A draw into this render texture reads the white texture in place of its `depth` set so, as a pass can't read the depth it draws.

  `depth` is read point-sampled whatever `SetTextureFilter` sets, and clamped at its edges until `SetTextureWrap` sets another wrap.
- `UnloadShadowmapRenderTexture`: Frees a render texture `LoadShadowmapRenderTexture` made, raylib's shadowmap example's `UnloadShadowmapRenderTexture`, its depth with it, as `UnloadRenderTexture` does.
  - `target`: The render texture.
