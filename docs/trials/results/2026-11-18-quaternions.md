# Library trial: a Vector4 that isn't a Quaternion (2026-11-18)

What its entrants were given is in `docs/trials/2026-11-18-quaternions/` at commit `7b0b153`, the paths below under it.

Whether agents writing raylib's quaternion code get past helix-raylib's `Vector4` and `Quaternion` being two types, where C's
`Quaternion` is a `Vector4` (DECISIONS 79). Three fresh Sonnet agents, each a `claude -p` in a directory of its own outside any
repository, in the blind trials' sandbox (`run_entrant.py --trial`), were given the brief (`plain/brief.md`) and the task (`task.md`):
three cubes stepping through four keyed orientations, one blended along the shortest arc, one by its four numbers straight and
normalized, one snapped, each tinted by a shader taking its orientation as a vec4 uniform, building natively against helix at
`77f2948`. The brief names `raylib.h`, `raymath.h` and `rlgl.h` as classes and says nothing of the change.

| entrant | cost | time | turns | tokens in | tokens out | met the change |
|---|---|---|---|---|---|---|
| 1 | $0.19 | 3.8 min | 11 | 344,092 | 4,947 | no: its keys were `Quaternion`s from the start |
| 2 | $0.19 | 1.9 min | 12 | 347,858 | 4,552 | no: its keys were `Quaternion`s from the start |
| 3 | $0.23 | 2.2 min | 13 | 404,381 | 6,277 | yes: `Vector4 should be Quaternion`, the keys retyped in one change |

Each built, ran and met the task in its shot, the three readouts alike. Entrant 1 left its program running in the background when it
was done, and the sandbox refused its `pkill`, so its session stayed open until the program was stopped at 10.7 minutes; its time is
its work's.

## What it found

| finding | to do |
|---|---|
| The one entrant that typed the keys `Vector4` (1 of 3) met `Vector4 should be Quaternion` and retyped them in one change, without a guess. The middle cube was `QuaternionNlerp` for all three, none reaching for `Vector4Lerp` | nothing: the two types stand |
| Two of three reached for a `create` on the structs (`Quaternion.create`, `Vector3.create`, `Camera3D.create`) and wrote `new` after the error. One read `Class<helix.math.Vector3> has no field create` as the wrong `Vector3` and imported `helix.raylib.Vector3` again | nothing for now, as `new` was each one's next step: no `create` and no refusal, as a second API to mirror isn't wanted. If the habit keeps coming up, a helix-raylib macro turns `X.create(...)` into `new X(...)` |
| Each met `LoadShader`'s or `LoadShaderFromMemory`'s refusal and followed it to `LoadCompiledShader` (3 of 3) | nothing: as in the earlier trials |
| One guessed `SetShaderValue` takes an `Array<Float>` for a vec4, and it did | nothing |
| An entrant's program left running holds its session open | the templates' briefs say to run the program in the foreground |
