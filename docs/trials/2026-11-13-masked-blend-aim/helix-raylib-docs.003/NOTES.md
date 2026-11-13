# Notes

## Compile errors, in order
1. `LoadModel: Not supported. Use LoadModelAsync` -> load the four models with `LoadModelAsync` callbacks; the loop draws "Loading..." until all arrive.
2. `LoadModelAnimations: Not supported` -> `LoadModelAnimationsAsync`.
3. `TakeScreenshot: Not supported` -> `TakeScreenshotAsync`.

## No call in raylib/extras
- Masked blending of two animations: extras' `UpdateModelAnimationMasked` + `GetModelBoneMask`.
- Four models on one skeleton posed alike: extras' `LoadModelFromModels(parts, legs)` merges them into one model.

## Guesses
- Mask root is bone `Abdomen` (read from the glb node names; hips and below keep running). I also tried `Torso`; no visible difference.
- `BLEND_ROTATION_MODEL`, so the upper body keeps the aim's facing instead of turning with the run's hips.
- Skeleton for the merge: the Legs model (all four share the rig).
- Animation frame = time * 30 (guess at the glTF sample rate); fractional frames go to the masked call, the aim-alone view uses integer frames.
- Aim ease: 0.2 s linear ramp passed through smoothstep.
- Camera at (0,1.2,4.5) looking at (0,1,0); assumed she faces +Z.
- `--shots` is my extra flag: scripted run (frame 80 shot), aim from frame 90 (shot at 170), aim-alone with legs still from 180 (shot at 200). Use `--shots --frames=210`.

## Expect not to work / doubts
- In the aiming screenshot her chest looks turned somewhat away from the camera compared with the aim-alone shot, so the chest/arm may not match the aim exactly.
- Frame rate of the run cycle is a guess, so it may not look "in step" at the intended speed.
