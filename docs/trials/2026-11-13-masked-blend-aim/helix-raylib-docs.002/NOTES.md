# Notes

## Compile errors, in order
1. `LoadModel: Not supported. Use LoadModelAsync(...)` -> used `LoadModelAsync` with callbacks; the main loop runs until all four models are in.
2. `LoadModelAnimations: Not supported. Use LoadModelAnimationsAsync` -> same.
3. `Unknown identifier: UpdateModelAnimationEx` -> used `UpdateModelAnimation(model, anim, Std.int(frame))` for the aim-alone pose.
4. `TakeScreenshot: Not supported. Use TakeScreenshotAsync` -> used that.

## No call for what the task asks
- None missing. The four models are merged with `LoadModelFromModels` (skeleton = the first model to load) and posed with `UpdateModelAnimationMasked`.

## Guesses
- Bone names were found by printing `model.bones[i].name` (Hips -> Abdomen -> Torso -> Chest...). Mask root is `"Abdomen"`: the legs hang off `Body`, so Hips and the legs stay on the run.
- `BLEND_ROTATION_MODEL`, so the upper body keeps the aim's facing (chest and arm to the camera) instead of turning with the run's hips. Docs' wording only; confirmed by the screenshots.
- Both animations are advanced from one shared clock at 60 frames/second (frame = time*60 mod frameCount), so the run is in step whether aiming or not.
- Ease is linear over 0.2 s (blend moves by dt/0.2 toward 0 or 1).
- Camera at (0, 1.1, 4.5) looking at (0, 0.95, 0), assuming she faces +Z; she does face the camera in the screenshots.
- Async load callbacks fire from the main loop (they did).
- Non-merged `UpdateModelAnimation` takes an Int frame; the aim alone is not interpolated between frames.

## Usage
`./native/Main [--auto] [--frames=N] [--shots]`. `--shots` uses a fixed 1/60 s step and a scripted run: shot_run.png (frame 29), aim on at 31, shot_aim.png (frame 90), aim alone from 100, shot_aim_alone.png (frame 130). Use `--frames=140`.

## Expect not to work
- Screenshot is async; I trust the files appear (they did).
- Aim alone is a screenshot-only mode, not reachable from the keyboard.
- Blend is linear, so the ease has slight velocity jumps at its ends.
