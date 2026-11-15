# Notes

## Compile errors and fixes
1. `LoadCompiledShaderAsync` "Not enough arguments, expected loaded, failed": it is callback-based; I had used it like `LoadShader`.
2. `LoadModel`: "Not supported. Use LoadModelAsync" -> used `LoadModelAsync(file, m -> robot = m)`.
3. `LoadModelAnimations`: "Not supported. Use LoadModelAnimationsAsync" -> same; returns `Array<ModelAnimation>`, no animCount out-param.
4. `UnloadModelAnimations` needed the `animCount` arg, so I pass `anims.length` (odd with an array).
5. "runLoop(): Not supported in a function used as a value" and "EndDrawing: Not supported in a function used as a value": the frame loop (BeginDrawing/EndDrawing) cannot live in a helper function or inside a load callback. I kept the loop in `main` and assigned the loaded resources to nullable locals from the callbacks, with a "Loading..." loop in `main` before the real loop that waits for them.

## Guesses / unsure
- Shader loaded from `shaders/shadowmap.shader`, compiled from the unchanged GLSL 330 files (copied as-is; no changes needed, since the shadow map's depth is sampled with `.r`).
- Pointer params of `SetShaderValue` are passed as plain values (Vector3, Vector4, Int); it compiled, but I don't know what the runtime accepts.
- `SetShaderValueTexture(shader, shadowMapLoc, shadowMap.depth)` replaces `rlActiveTextureSlot/rlEnableTexture/rlSetUniform`. I assumed it picks the slot itself and that it is bound for the following draws, and that `rlEnableShader` is not needed.
- `rlGetMatrixModelview`/`rlGetMatrixProjection` are used from `Rlgl` as the Shadowmaps doc shows; I assumed they return the light's matrices inside `BeginMode3D` on the texture target.
- `Camera3D`/`Vector3` built with `new` (args order guessed); `cam.position` passed directly instead of a copy.
- Robot path is `resources/models/robot.glb` (asset not copied; only shaders were asked for).
- `DrawScene` is a static function (fine, it has no frame calls).
- The `UpdateModelAnimation` frame arg is Int.

## API changes I'd suggest
- Allow a blocking frame loop after async loads (or provide `WaitForLoads`/an awaitable) rather than polling nullable locals.
- Allow the frame loop in a helper function.
- `UnloadModelAnimations` should not need a count in Haxe.
- Shadowmaps doc could state when the depth binding takes effect and which texture slot it uses.
