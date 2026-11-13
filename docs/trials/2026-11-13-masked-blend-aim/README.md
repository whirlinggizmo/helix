# Library trial: masked blend, rotation in the model (2026-11-13)

The second round of [the masked blend's trial](../2026-11-13-masked-blend): whether agents choose `UpdateModelAnimationMasked`'s
`BLEND_ROTATION_MODEL` when the upper body must keep its own facing, and whether an animation's whole name finds it. Three fresh Sonnet
agents, run as the first round's were (`run_entrant.py --trial`), were given [the task](task.md): the Wardens character running to her
left (`Run_Left`) while her upper body aims at the camera (`CharacterArmature|Idle_Gun_Pointing`, 36 bytes, named whole in the task),
with [the module's brief](module/brief.md) and `extras.Models`' doc comments as tried ([module/docs/extras/Models.hx](module/docs/extras/Models.hx)).
They built against helix with the rotation space and whole names, before either was committed. A third round,
`helix-raylib-docs.004` to `.006`, ran the same task on the doc comments as committed ([module-final](module-final)): the refusals
reworded, the blend clamped to [0, 1], and each parameter named in its own words.

| run | took | blend |
|---|---|---|
| docs.001 | 2 min, 14 turns, $0.24 | `BLEND_ROTATION_MODEL`, the mask from Abdomen |
| docs.002 | 2 min, 13 turns, $0.24 | as docs.001 |
| docs.003 | 2 min, 15 turns, $0.24 | as docs.001, after trying Torso as the mask root |
| docs.004 | 2 min, 14 turns, $0.22 | as docs.001 |
| docs.005 | 2 min, 14 turns, $0.25 | as docs.001, after trying Torso; the aim matched on its first 31 characters |
| docs.006 | 2 min, 14 turns, $0.24 | as docs.001 |

Each chose `BLEND_ROTATION_MODEL` from its doc, as the run turns her hips aside and the aim faces the camera, and found the aim by its
whole name. In every aiming screenshot her chest and arm face the camera as the aim alone has them, her legs running to her left.
docs.003 and docs.005 saw her chest turned a little, about 20°, from the aim alone's. Measured bone by bone, every masked bone has the
aim's own rotation, 0.0° from the aim alone at two frames, and the hips, unmasked, are the run's, 62.8° from the aim's: the chest faces
as the aim's does, placed on hips turned and set aside.

docs.005 read raylib's `char name[32]` and matched the aim on its first 31 characters, which finds the whole name as well.

Outside the extra, each guessed the animations' rate (30 or 60 frames a second) as the first round's did, and docs.002 reached for
raylib 6's `UpdateModelAnimationEx`, which the brief's raylib 5.5 hasn't.

## What it found, and what changed

Nothing in the extra: no run guessed at `BLEND_ROTATION_MODEL` or the mask.
