# Notes

## Compile errors
1. `LoadModel` / `LoadModelAnimations`: "Not supported", use the `*Async` forms. Switched both to callbacks; the frame loop shows "loading..." until all 6 loads (4 models, animations, grass shader) finish.
2. `LoadCompiledShaderAsync(path)`: needs a `loaded` callback (and optional `failed`). Added one.

## Guesses / unsure
- Whether `Light` has a `.position` field (I use `lantern.position` for the lantern sphere); it compiled.
- `SetLightShadows` for a point light: I passed `{mapSize: 1024}` only; unsure whether `distance` or the light's `range` sets its reach. I set range via `SetShaderValue(..."lights[1].range")`.
- Cascades: `cascades: 2` and `distance: 30` for the sun; docs don't say whether `distance` is measured from the camera along its view or radially.
- `BeginShadowMode` once per shadowed light, drawing the full scene each time (sun, then lantern). I assumed no pass-per-cascade call is needed. Unsure whether two shadow passes per frame are allowed, or whether the passes must precede `BeginDrawing`.
- Shadow passes happen before `BeginDrawing`; unclear if that is allowed or needed.
- `UpdateLightValues` is called each frame for both lights even though they don't move; unsure whether it's needed after `SetLightShadows` or after setting range/intensity uniforms.
- `lights[N].range`/`intensity` set once with SetShaderValue after load, before `CreateLight`; unsure whether `CreateLight` or `UpdateLightValues` resets them.
- Hit flash: `SetMaterialEmissive(m, WHITE, 1.0)` on every material of every warden part each frame (0 when idle). Does intensity 1 over a lit surface read as "white"? Unclear; emissive adds, so a dark pixel becomes white but a bright one clips, which is probably fine.
- Whether the emissive set on a material is kept by `UpdateModelAnimation` or by `DrawModel` of a shared material.
- Alpha cutoff: the leaf texture uses BLANK background (alpha 0); cutoff 0.5. The pbr shader is assumed to pass `fragTexCoord` in its shadow variant; the leaf plane's mesh comes from `GenMeshPlane`, which has texcoords.
- Grass shader: its own `.vs`/`.fs` includes `pbr.glsl` and calls `helixPbr`. The `uniform float time` is set by me each frame. It does not declare `alphaCutoff`/`emissiveColor`; unsure whether including pbr.glsl already declares them. The `.vs` passes `fragTexCoord` so a cutoff (0 here) could work. Does the shadow variant use the same `time` uniform value? The doc says the same uniforms as the draw, so I set it once on grassShader.
- The grass shader needs `viewPos` — I set `locs[SHADER_LOC_VECTOR_VIEW]`; unsure whether a CompileShaderFile shader gets that loc automatically, and whether `ambient` must be set on it too (I didn't set it on the grass shader; lights are per-shader so I also didn't `CreateLight` on it). This is a big unknown: how do lights created with `pbr` reach `grassShader`? Probably need `CreateLight` on each shader, with SetLightShadows on each. Not done.
- Grass blades are one-sided triangles; backface culling would hide half of them. Not handled.
- Leaf card is rotated through `model.transform` with MatrixRotateX; same unknown about whether shadow pass honours it ("posed and placed the same").

## What I'd change in the API
- Lights are per-shader. A scene with the PBR shader plus a custom shader needs every light created and shadowed on each; a way to share lights (or `AddLightToShader`) would help.
- `BeginShadowMode` per light with the whole scene redrawn twice is clumsy; a variant taking several lights, or a single `BeginShadowMode(shader, camera)` covering all shadowed lights, would halve the draw code.
- A `SetLightRange` / `SetLightIntensity` function instead of string-named uniforms.
- Hit flash: a per-model/per-draw tint-emissive (not per-material, since the warden has 4 models with many materials).
- Say in the docs whether the lit shaders' `ambient` etc. is needed on custom shaders, and whether `emissiveColor`/`alphaCutoff` are declared by the include.
