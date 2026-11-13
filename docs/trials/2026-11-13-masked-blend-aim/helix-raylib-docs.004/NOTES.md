# Notes

## Compile errors, in order
1. `LoadModel` / `LoadModelAnimations`: "Not supported. Use LoadModelAsync / LoadModelAnimationsAsync". Switched to the async calls and polled in a loop until the callbacks had fired (they fired within 3 frames).
2. `TakeScreenshot`: "Not supported. Use TakeScreenshotAsync". Switched.

## No call for what the task asks
- None missing. Extras `LoadModelFromModels` (merge 4 parts, skeleton = body), `GetModelBoneMask` and `UpdateModelAnimationMasked` did the job.

## Guesses
- Mask root is `Abdomen` (bone names found by printing them): Hips and legs keep the run, waist up takes the aim.
- `BLEND_ROTATION_MODEL`, so the masked bones keep the aim's own facing (chest/arm to the camera) rather than turning with the run's hips.
- Animation rate guessed at 30 frames/s, passed as fractional frames.
- Ease is smoothstep over 0.2 s, driven by `GetFrameTime`.
- Camera at (0,1.1,4.5) looking at (0,0.95,0), fov 40; assumed she faces +Z.
- Aim-alone pose uses `UpdateModelAnimation` with the aim animation only (integer frames).
- Screenshots are taken with `--shots` (frames 30, 90, 150: `shot_run.png`, `shot_aim.png`, `shot_aim_alone.png`); e.g. `./native/Main --shots --frames=160`. In `--shots` the aim turns on at frame 40 and aim-alone at 100.

## Expect not to work / caveats
- Running without `--shots` never shows the aim-alone pose.
- The aim's hips/legs-twist under `BLEND_ROTATION_MODEL` looks slightly twisted at the waist in the aim screenshot.
