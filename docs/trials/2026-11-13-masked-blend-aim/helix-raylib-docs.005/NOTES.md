# Notes

## Compile errors, in order
1. `LoadModel`, `LoadModelAnimations` and `TakeScreenshot`: "Not supported. Use ...Async". Changed to `LoadModelAsync`, `LoadModelAnimationsAsync`, `TakeScreenshotAsync`. The main loop draws "Loading..." until the callbacks have delivered the four models and the animations.

## No call in raylib / extras
- None missing: the masked blend (`UpdateModelAnimationMasked`, `GetModelBoneMask`) and `LoadModelFromModels` cover it. The four parts are merged into one model, one skeleton (the part with most bones).
- Aim alone uses raylib's `UpdateModelAnimation` on the merged model.

## Guesses
- Mask root is "Abdomen" (waist), with `BLEND_ROTATION_MODEL` so the upper body keeps the aim's facing while the hips follow the run. Trying "Torso" looked no closer to the aim-alone pose.
- Animation names are char[32], so "CharacterArmature|Idle_Gun_Pointing" arrives cut to 31 chars; matched on the first 31.
- Animation rate 30 frames/s (a guess; frames are fractional, time based). Ease is smoothstep over 0.2 s.
- Camera at (0,1.2,5) looking at (0,1,0); she faces +Z (toward it).
- Screenshots: `--shots --frames=180` (run at frame 50, aim at 110, aim alone at 170) writes shot_run.png, shot_aim.png, shot_aim_alone.png. A toggles aim-alone live.

## Expect not to work
- In the blended screenshot the chest looks turned about 20° more to her right than in the aim-alone one; I could not tell whether that is the blend or the aim pose itself.
- Which of the screenshots' frames fall mid-ease was not checked at the ease boundaries.
