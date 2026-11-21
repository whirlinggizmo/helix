# Library trial: the Lighting extra's shadows, emission and alpha cutoff (2026-11-15)

What its entrants were given is in `docs/trials/2026-11-15-lighting-shadows/` at commit `7b0b153`, the paths below under it.

Whether agents can light a scene with shadows, a glow and cut-out leaves from the Lighting extra's draft calls, learning them from their
doc comments alone: `SetLightShadows` and `ShadowOptions`, `BeginShadowMode` and `EndShadowMode`, `SetMaterialEmissive` and
`GetMaterialEmissive`, `SetMaterialAlphaCutoff` and `GetMaterialAlphaCutoff`. Two fresh Sonnet agents, each a `claude -p` in a directory
of its own outside any repository, in the blind trials' sandbox (`run_entrant.py --trial`), were given the brief (`module/brief.md`),
the task (`task.md`) (a yard at dusk: a sun with two cascades, a lantern's point-light shadows, grass swaying in its own vertex shader,
cut-out leaves and a hit flash) and the extra as tried (`module/docs/api`), its new calls not built, compiling for
JavaScript (`build.hxml`). Both compiled, in 11 and 10 turns, about a minute and $0.24 each.

## What it found

| finding (both agents unless noted) | to do |
|---|---|
| A pass per shadowed light: both drew the yard once for the sun and again for the lantern | one `BeginShadowMode` for every shadowed light of a shader, the casters drawn once and replayed into each light's maps |
| A program's own lit shader (the grass) gets lights and shadows only if every light is created on it too, as rlights binds a light to one shader | open: lights shared across shaders |
| A light's range and intensity set by uniform names (`"lights[1].range"`), the index guessed | `SetLightRange` and `SetLightIntensity` |
| A hit flash set on every material of four parts each frame | `SetModelEmissive`, for all of a model's materials |
| Whether a shadow pass goes before `BeginDrawing` or within it; whether `pbr.glsl` declares `emissiveColor` and `alphaCutoff`; how a custom vertex stage gets the world position | said in the doc comments |
| `LoadModel` and `LoadModelAnimations` refused for their Async forms | the Assets extra's ensure |
