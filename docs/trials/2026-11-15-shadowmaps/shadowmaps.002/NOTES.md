# Notes

## Compile errors and fixes
1. `LoadShader` replaced by `LoadCompiledShaderAsync("shaders/shadowmap.shader", cb)` (first attempt omitted the callback: "Not enough arguments").
2. `LoadModel`: "Not supported. Use LoadModelAsync" -> used `LoadModelAsync`.
3. `LoadModelAnimations`: "Not supported" -> `LoadModelAnimationsAsync` (returns `Array<ModelAnimation>`; no animCount out-param).
4. `UnloadModelAnimations(anims)`: "Not enough arguments, expected animCount" -> pass `robotAnimations.length`.
5. `run(): Not supported in a function used as a value.` My first structure nested the whole game loop (`run`) inside the async callbacks. Changed: callbacks only assign variables, and `main` runs a "Loading..." `while` loop until all three have arrived, then the main loop.

## Guesses / unsure
- Shader: copied glsl330 files unchanged; didn't know whether helix wants a different GLSL version (e.g. 100/120/300 es) for JS/WebGL.
- Structs: `new Vector3(x,y,z)`, `new Camera3D()` with field assignment; passing a Vector3/Vector4/Int/Matrix straight to `SetShaderValue` (C takes a pointer) is a guess, compiled OK.
- `rlGetMatrixModelview()`/`rlGetMatrixProjection()` imported via `Rlgl.*`, called right after `BeginMode3D` inside texture mode as in the example. Compiles; unsure they are valid in the JS backend, and unsure the returned Matrix is a copy (not live) — I use them after EndMode3D.
- Replaced `rlEnableShader / rlActiveTextureSlot(10) / rlEnableTexture / rlSetUniform` with `SetShaderValueTexture(shader, shadowMapLoc, shadowMap.depth)` as per the doc. Unsure of timing: I call it before `BeginMode3D(cam)` as the doc example does; unsure what texture unit it uses or whether it must be re-called after each BeginMode3D / for both models' materials sharing the shader.
- `LoadShadowmapRenderTexture` depth is 0..1 in `.r`, stored bottom-row-first; the shader samples with the same `fragPosLightSpace` (NDC*0.5+0.5) as the example, so I assumed no y flip is needed.
- Point-sampled + clamped by default; the example's shader does its own PCF so that fits. Outside the map clamp edge gives depth value there, not "lit" — unchanged from example behavior (which used GL defaults, repeat/linear maybe).
- Robot textures/material shader: `robot.materials[i].shader = shadowShader` (assigning a shared Shader to several materials).
- Main loop kept as `while(!WindowShouldClose())`; unsure how it runs in a JS browser build (blocking?). Async loads rely on the loading loop calling `BeginDrawing/EndDrawing` to let callbacks fire.
- `SetShaderValue` int for `shadowMapResolution` passed as plain Int.
- `TakeScreenshot` kept; unsure it exists/works on JS.

## API suggestions
- Make the error for sync functions say how to restructure the main loop; the "not supported in a function used as a value" message is unclear.
- Doc example for Shadowmaps could say where to use `rlGetMatrixModelview` (Rlgl) and which import brings it in.
- A helper for the common load-everything-then-loop startup (e.g. a join of several async loads) would remove boilerplate.
- Document the texture slot `SetShaderValueTexture` uses and whether it persists across frames.
- `SetShaderValue` overloads taking Vector3/Vector4/Int/Float typed would be clearer than the type enum.
