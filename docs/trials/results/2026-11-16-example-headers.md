# Library trial: whether agents reach for raylib's example headers (2026-11-16)

What its entrants were given is in `docs/trials/2026-11-16-example-headers/` at commit `7b0b153`, the paths below under it.

Whether agents writing a raylib program reach for `rlights.h` and `reasings.h`, the headers raylib's examples include, when nothing
points them there. Three fresh Sonnet agents, each a `claude -p` in a directory of its own outside any repository, in the blind trials'
sandbox (`run_entrant.py --trial`), were given the brief (`plain/brief.md`) and the task (`task.md`): a scene lit by two point lights
that switch on and off, and a ball crossing with a bounce and returning with a smooth ease, building natively against helix at
`91318c0`. The brief names `raylib.h`, `raymath.h` and `rlgl.h` as classes and no extras. raylib's C examples were given as raylib
ships them, both headers among them, and `helix.raylib.Rlights` was in the library, unnamed.

| entrant | cost | time | turns | tokens in | tokens out | lights | easing |
|---|---|---|---|---|---|---|---|
| 1 | $0.21 | 2.0 min | 11 | 318,623 | 6,084 | its own shader, uniform arrays | its own `bounceOut` and ease in-out |
| 2 | $0.21 | 1.9 min | 12 | 350,504 | 6,319 | its own shader, uniform arrays | its own `bounceOut` and sine ease |
| 3 | $0.21 | 1.9 min | 11 | 313,947 | 5,939 | its own shader, a uniform each | its own `bounceOut` and `easeInOut` |

Each built, ran and met the task in its shot. Each met one compile error, `LoadShader`'s refusal, and followed it to
`LoadCompiledShader`.

## What it found

| finding | to do |
|---|---|
| None imported `Rlights` or wrote `CreateLight`, though all three read raylib's lighting example, which includes `rlights.h`, before writing (3 of 3). Two said why: "rlights.h is a C helper", "rather than the rlights.h struct" | `Rlights` becomes part of the Lighting extra |
| None looked for `reasings.h`. Each wrote its curves, one noting "raylib's easings.h is not in the API" (3 of 3) | no `Reasings`: the curves are `helix.math.Interpolate`'s |
