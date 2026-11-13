# Library trial: masked blend (2026-11-13)

Whether agents use `extras.Models`' masked blend (`UpdateModelAnimationMasked`, `GetModelBoneMask`) correctly from its doc comments,
and what they write without it. Six fresh Sonnet agents, each a `claude -p` in a directory of its own outside any repository, in the
blind trials' sandbox (`run_entrant.py --trial`), were given [the task](task.md): the Wardens character's four parts running in place,
slashing from the waist up while her legs keep running, eased in and out over 0.15 seconds, built natively and checked by screenshots.
Three had [the control's brief](control/brief.md), raylib 5.5's headers and examples alone (`helix-raylib-blind.001` to `.003`). Three had
[the module's brief](module/brief.md), the same with one line pointing at `extras.Models` and its doc comments as tried
([module/docs/extras/Models.hx](module/docs/extras/Models.hx)) (`helix-raylib-docs.001` to `.003`). They built against
helix at the masked blend's commit. Each run's program and notes are in the folder named for it.

| run | took | blend | per frame |
|---|---|---|---|
| docs.001, .002, .003 | 2 min each, 10 to 14 turns, $0.20 to $0.24 | `LoadModelFromModels`, a mask from Abdomen made once, `UpdateModelAnimationMasked` | allocates nothing |
| blind.001 | 3 min, 16 turns, $0.32 | by hand, relative to the parents: correct | a transform a bone, several arrays |
| blind.002 | 2 min, 11 turns, $0.23 | by hand, the poses in the model mixed: the upper body ignores the hips' bob | a transform a bone |
| blind.003 | 2 min, 13 turns, $0.24 | by hand, as blind.002, written into the run's own first frame | a transform a bone |

Given the module, the runs cost less on each measure, in the mean of three: $0.220 against $0.262 (16% less), 5,881 output tokens
against 8,632 (32%), 32,264 input tokens written to the cache against 35,436 (9%) and 322,936 read from it against 338,590 (5%), 12.0
turns against 13.3, 124 seconds against 144, and 110 lines of program against 160. All three were correct, and one of the three
without it.

Every run met the task by its screenshots. All six guessed the animations' rate (24, 30 or 60 frames a second) until raylib's log
showed it, which isn't the extra's. No run given the module guessed at what its calls do.

The masked blend's slash reads weakly from the front. Each bone is blended relative to its parent, and the upper body turns with the
run's hips, which face aside: the swing goes aside. Rendered beside the authored `Sword_Slash` at the same frames, the swing is there.
blind.002 and .003, mixing the poses in the model, keep the slash's facing on top of the run's legs, twisted at the waist.

## What it found, and what changed

| finding | change |
|---|---|
| Which bone the upper body starts at: `GetModelBoneMask`'s `boneName` said "the spine's for the upper body", and her bones have no Spine. All three read the bone names and took Abdomen | the parameter is `maskRootBoneName`, the mask's root, distinct from the skeleton's root. Its doc says it and every bone below it are weighted 1, and names no bone: which bone is the rig's. A mask of another shape is an array the program fills itself |
| The masked bones turn with the run's hips, and a slash or an aim meant to face ahead turns aside | `UpdateModelAnimationMasked` takes a rotation space: `BLEND_ROTATION_LOCAL`, the default, or `BLEND_ROTATION_MODEL`, the masked bones keeping the second animation's facing. Tried in [a second round](../2026-11-13-masked-blend-aim) |
| An animation's or a bone's name cut to 31 bytes, as raylib's struct holds it: the verifying program asked for `Idle_Gun_Pointing` and found nothing | helix-raylib keeps names whole. The parity programs cut the names they print to raylib's 31 bytes. Tried in the second round, its aim named whole |
