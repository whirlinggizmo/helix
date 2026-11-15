# Notes

## Compile errors
1. `LoadCompiledShaderAsync` "not enough arguments": it needs a `loaded` callback. Used `LoadCompiledShaderAsync(path, s -> ...)`.
2. `LoadModel` / `LoadModelAnimations` "Not supported": switched to `LoadModelAsync` / `LoadModelAnimationsAsync` with callbacks; the frame loop waits (`ready < 6`) before drawing the scene.

## Guesses / unsure
- `SetLightShadows` call timing: assumed once after `CreateLight`, before the first frame, with a point light's `mapSize` 1024 (six maps).
- Whether `BeginShadowMode` needs one pass per shadowed light (I did two: sun then lantern, each drawing the full scene) or one pass covers all lights. The docs say "a light's shadow pass", so I did one each.
- Does the shadow pass draw grass through the grass shader (sway)? The doc says each draw runs its own shader's vertex stage, so I draw `grass` in both passes. Grass's `fragTexCoord` is passed so cutoffs would work.
- Light indices for `lights[N].range`: assumed index = creation order (sun 0, lantern 1).
- `SetMaterialEmissive` on every material of each warden part every frame (intensity 1 vs 0). Unsure whether it's per-draw state or persistent (doc: "set white for one draw"); and 0.8 in the example vs 1 here — "1 adds the color itself" so 1 is full white add.
- `SetMaterialAlphaCutoff` for the leaf: 0.5, set once, on the material (not the shader). Albedo alpha = texture alpha times color alpha.
- The custom grass shader includes `pbr.glsl` and calls `helixPbr`; assumed it already applies shadows (shadows.glsl not included) and that `time` is my own uniform. Assumed the shadow variant of my vertex shader works with only the outputs I wrote; it applies `matModel` itself, and I undo it for `mvp` (hacky: `mvp*(inverse(matModel)*world)`).
- Cascades: `cascades: 2`, `distance: 30` per the task.
- Animation frame: advanced one frame per tick at 60fps, `frame % frameCount`.
- No lantern bulb light-casting issue: a lit sphere is drawn at the lantern outside the shadow pass so it doesn't shadow its own light.

## What I'd change in the API
- `SetLightShadows` / `BeginShadowMode` / `EndShadowMode` take the light each time; one `BeginShadowMode` pass for all shadowed lights would avoid drawing the scene twice.
- Say how a custom shader gets world-space position vs. `mvp` for sway without inverting `matModel`.
- Say whether emissive is state or per-draw, and whether it's cleared automatically.
- State light indexing for `lights[N]` names.
