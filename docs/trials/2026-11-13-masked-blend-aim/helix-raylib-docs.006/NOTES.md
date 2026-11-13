# Notes

## Compile errors, in order
1. `LoadModel: Not supported. Use LoadModelAsync(...)` -> used `LoadModelAsync` with callbacks, pumped frames until all four parts arrived.
2. `LoadModelAnimations: Not supported. Use LoadModelAnimationsAsync` -> same.
3. `TakeScreenshot: Not supported. Use TakeScreenshotAsync` -> used `TakeScreenshotAsync`.

## No call in raylib/extras for what the task asks
- Nothing missing: the four parts are merged with `LoadModelFromModels(parts, body)`, and the aim over the run is `UpdateModelAnimationMasked` with `GetModelBoneMask(model, "Abdomen")`.
- The ease is mine: a 0.2 s linear ramp of `blend`, smoothstepped.

## Guesses
- Mask root `Abdomen` (bones: Root, Body, Hips, Abdomen, Torso, Chest...). Hips stay on the run; everything from the abdomen up takes the aim.
- `BLEND_ROTATION_MODEL`, so the chest and arm keep the aim's facing rather than turning with the run's torso.
- Animation frame rate: 60 frames a second (the load log's frame counts / durations agree). Both animations advance on the same clock and wrap with `%`.
- Camera at (0,1.1,4.5) looking at (0,1,0); she faces +Z, toward it.
- Aim-alone pose: `UpdateModelAnimation(model, aim, frame)`.
- With `--frames=N` the program is scripted and uses a fixed dt of 1/60: aim on from frame 40, aim alone from frame 120, screenshots at frames 30/100/150 (`shot_run.png`, `shot_aim.png`, `shot_aim_alone.png`). Needs N > 150. Without `--frames`, Space / `--auto` work as the task says, with real frame time.

## Expect not to work / unverified
- Space key and `--auto` toggling were not exercised in a run; only the scripted path was screenshotted.
- The 0.2 s ease was not inspected frame by frame.
- Her hips and chest in the masked pose sit a little differently from the aim alone (hips follow the run), as intended.
