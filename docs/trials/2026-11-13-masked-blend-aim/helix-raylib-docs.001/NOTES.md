# Notes

## Compile errors, in order
1. `LoadModel`, `LoadModelAnimations`: "Not supported", use the `...Async` forms. Changed to `LoadModelAsync` / `LoadModelAnimationsAsync` with callbacks; a loop drawing "Loading..." waits until all five have arrived.
2. `ModelAnimation has no field animFPS` (my own invention). Removed; frames are advanced at 30 fps.
3. `TakeScreenshot`: "Not supported", use `TakeScreenshotAsync`. Changed.

## No call for what the task asks
- Nothing blends two animations in raylib; used the extras' `UpdateModelAnimationMasked` with `GetModelBoneMask(model, "Abdomen")` (waist up; Hips and legs stay on Run_Left) and `BLEND_ROTATION_MODEL` so the chest keeps the aim's facing.
- Four models on one skeleton: merged with `LoadModelFromModels(parts, body)` into one model, posed once.

## Guesses
- Mask root "Abdomen" (first bone above Hips' children in the spine; bone list printed once, Hips=2, Abdomen=3).
- Animations are 30 fps (read off frame counts vs. durations in the load log); not read from the file.
- `BLEND_ROTATION_MODEL` rather than LOCAL, since the run turns the body sideways and the aim must face the camera.
- Ease: linear ramp over 0.2 s, passed through smoothstep.
- Frame times are fixed 1/60 s steps, not GetFrameTime.
- Screenshots are taken at frames 30 (run), 150 (aim; needs `--auto`, toggles at 2 s), and frames-1 (aim pose alone, whole body in Idle_Gun_Pointing, forced for the last 10 frames). Screenshot files land in the working directory: shot_run.png, shot_aim.png, shot_aimonly.png. Run as `./native/Main --auto --frames=200`.

## Expect not to work
- Without `--auto` the aim screenshot shows no aim (no Space press). The aim-alone shot is only produced when frames >= 30.
- Run_Left and Idle_Gun_Pointing have different frame counts (51 / 103); each wraps on its own, so the aim loops at its own rate.
- The aim at the instant of toggling was checked only in stills, not for pops.
