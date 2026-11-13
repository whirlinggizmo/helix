# Notes

## Compile errors, in order
1. `LoadModel`, `LoadModelAnimations`: "Not supported. Use LoadModelAsync / LoadModelAnimationsAsync" -> switched to the Async calls with callbacks; the main loop shows "Loading..." until all four models and the animations have arrived.
2. `TakeScreenshot`: "Not supported. Use TakeScreenshotAsync" -> used that.

## No call for it
- Nothing missing: the extras' `LoadModelFromModels`, `GetModelBoneMask` and `UpdateModelAnimationMasked` cover the merged character and the legs/upper-body split.

## Guesses
- Animation rate: first guessed 30 fps, then read 60 fps from raylib's log (65 frames = 1.0667 s); slash length is (frameCount-1)/60 s.
- Mask root bone "Abdomen" (printed bone list: Root, Body, Hips, Abdomen, Torso, ...). Hips and legs stay on Run; Abdomen and everything below it take the slash.
- Merged model: `LoadModelFromModels(parts, body)` with the first loaded part that has bones as skeleton (load order is not guaranteed); all four share one skeleton, so any works.
- Blend = min(1, t/0.15, (dur-t)/0.15), linear.
- With `--frames`, delta time is fixed at 1/60 for reproducible shots; screenshots at frame 30 (before), mid-slash and ~0.075 s before the slash ends (easing out), named `shot_<frame>.png`. Frame counts include the loading frames.
- Camera at (2.5,1.6,4) looking at (0,0.9,0); she faces somewhat to the left of the camera in the screenshots, not squarely to it.

## Expect not to work
- No sword, so the slash reads only as the arms/torso swing; the readout shows idle/playing with percent.
- Space during a slash is ignored (no retrigger).
