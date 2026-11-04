# Library trial: debug drawing (2026-11-04)

Whether agents can look at an animated model with `extras.Debug` (its skeleton as posed, its posed bounds, the frame's cost), learning it
from its doc comments alone. Two fresh Sonnet agents, each a `claude -p` in a scratch directory outside any repository, were given
[the task](task.md) (an animation inspector for raylib's robot: skeleton, posed bounds, wires, the model hidden, five copies at different
frames, the frame's cost judged against 30 frames a second) and the API as it was tried ([api-as-tried](api-as-tried)), its functions
not yet built. Both compiled cleanly in 10 turns, about 40 seconds and $0.12 each. Their programs and notes are in `agent-1/` and
`agent-2/`. Neither misused the debug API.

## What it found, and what changed

| finding (both agents unless noted) | change |
|---|---|
| Five copies of one model: both posed each copy, drew it, then its skeleton and box, but weren't sure the debug calls read the pose at the call | the docs say they draw the pose the model has at the call, as `DrawModel` does; agent 2's alternative (an animation and frame given to each call) would repeat `UpdateModelAnimation` |
| The frame stats' size for a 1280 x 720 window: both picked 28 and called it a guess | `FrameStatsStyle.fontSize` is `Null<Int>`, null by default for a size scaled to the window (a 36th of its height, 20 at 720 lines) |
| Both set `targetFps: 30` beside `SetTargetFPS(30)`, unsure the stats follow it | the simple form's doc says it's the `Ex` form with the style's defaults, which follow `SetTargetFPS` |
| `Type not found : Model`: raylib's types need `import helix.raylib.*;`, which both added after the error (as both agents of the skins trial did) | the compiler says so: helix-raylib adds "Model is helix.raylib.Model: import helix.raylib.*;" beside the error (e398669) |
| A combined `DrawModelDebug(model, position, scale, {skeleton, bounds})` (agent 1) | not taken: the three calls compose, one line each |

Decided with the user before the trial: a style struct (`FrameStatsStyle`) for `DrawFrameStatsEx` rather than more arguments, its colors
named for raylib's target (`onTargetColor`, `belowTargetColor`, `farBelowTargetColor`) and judged against `targetFps`, 0 for
`SetTargetFPS`'s target or the monitor's refresh rate; the stats shown chosen by its fields (frames a second, frame time, draw calls,
triangles, state changes); the simple `DrawFrameStats(posX, posY, fontSize)` kept beside it, as `DrawText` beside `DrawTextEx`.
