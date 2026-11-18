# Library trial: whether agents use the Lighting extra and the tweens when handed them (2026-11-17)

Whether agents writing a raylib program use the Lighting extra's lights and the tweens when the brief names them and hands over their
pages. Three fresh Sonnet agents, each a `claude -p` in a directory of its own outside any repository, in the blind trials' sandbox
(`run_entrant.py --trial`), were given [the brief](extras/brief.md) and [the task](task.md), building natively against helix at
`d3258a1`. The task is [the example headers trial's](../2026-11-16-example-headers/results.md), word for word: a scene lit by two point
lights that switch on and off, and a ball crossing with a bounce and returning with a smooth ease. The brief names the two extras and
says "use what helps". The pages given were the Lighting extra's, the tweens' (helix-raylib's and helix-tweens'), helix-math's types
(for `Ease`) and helix-raylib's types, beside raylib's headers and C examples.

| entrant | cost | time | turns | tokens in | tokens out | lights | easing |
|---|---|---|---|---|---|---|---|
| 1 | $0.23 | 1.6 min | 10 | 317,774 | 3,595 | `LoadLightingShader`, `CreateLight` | a `TweenSequence` of two `Vector3Tween`s |
| 2 | $0.24 | 1.5 min | 11 | 370,665 | 3,584 | `LoadLightingShader`, `CreateLight` | a `TweenSequence` of two `Vector3Tween`s |
| 3 | $0.24 | 1.6 min | 10 | 321,919 | 3,853 | `LoadLightingShader`, `CreateLight` | a `TweenSequence` of two `FloatTween`s |

Each built, ran and met the task in its shot. None wrote a shader or a curve. Against the example headers trial, where each entrant
wrote both: about 40% fewer tokens written (3,584 to 3,853 against 5,939 to 6,319), 20 to 30 seconds less, and 2 to 3 cents more, the
pages read costing what the writing saved. None pressed W or R, and none watched the ball past its first crossing. Both forms of the
ball's sequence were stepped through three cycles on the interpreter after, and each holds the task's path.

## What it found

| finding | to do |
|---|---|
| All three lit the scene with `LoadLightingShader` and `CreateLight`, set `enabled` and `position` on the light, and called no `UpdateLightValues` (3 of 3). No compile error and no warning in the extra | none |
| All three moved the ball with a `TweenSequence`: `append`, `appendDelay`, `repeatCount = -1`, `Ease.outBounce` and `Ease.inOutSine`, stepped by the program's own `update` (3 of 3). No compile error in the tweens. None read helix-math's page: the tweens' samples carried `Ease` (one searched the page for `Ease`) | none |
| `Vector3Zero` was an unknown identifier until `Raymath` was imported (2 of 3). The Lighting page's samples write `Vector3Zero()` | the Lighting page's samples write a `new Vector3(0, 0, 0)` |
| Two `FloatTween`s in a sequence have no one value to read. The entrant picked between them, `back.time > 0 ? back.value : ballX.value`, guessing that a sequence puts its tweens back at their start on a repeat (1 of 3) | to decide |
| Two `Vector3Tween`s in a sequence were given one `out`, guessing that only the tween the sequence is in writes to it (2 of 3) | to decide, with the row above |
| The white light was moved with a `new Vector3` a frame (2 of 3); one set the three fields | none: raylib's habit |
