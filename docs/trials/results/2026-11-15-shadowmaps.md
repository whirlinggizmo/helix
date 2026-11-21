# Library trial: raylib's shadowmap example through Shadowmaps (2026-11-15)

What its entrants were given is in `docs/trials/2026-11-15-shadowmaps/` at commit `7b0b153`, the paths below under it.

Whether agents can port raylib's own `shaders_shadowmap` example with the Shadowmaps extra's draft (`LoadShadowmapRenderTexture` and
`UnloadShadowmapRenderTexture`, the example's own two functions, in place of the rlgl calls they're made of), learning it from its doc
comments alone. Two fresh Sonnet agents, each a `claude -p` in a directory of its own outside any repository, in the blind trials'
sandbox (`run_entrant.py --trial`), were given the brief (`module/brief.md`), the task (`task.md`) and the extra as tried
(`module/docs/api`), not built, compiling for JavaScript (`build.hxml`). Both compiled, in 12 and 7 turns,
about a minute and $0.24 and $0.20. Both kept the example's shaders unchanged and bound the depth with `SetShaderValueTexture`, as the
doc says.

## What it found

| finding (both agents unless noted) | to do |
|---|---|
| Which texture unit `SetShaderValueTexture` binds the depth to, and whether it stays bound across frames | said in the doc comments |
| `rlGetMatrixModelview` and `rlGetMatrixProjection` come from `Rlgl`, which the doc's example doesn't import | the example imports it |
| The robot and the shader loaded with their Async forms, the loop waiting on them | the Assets extra's ensure |
