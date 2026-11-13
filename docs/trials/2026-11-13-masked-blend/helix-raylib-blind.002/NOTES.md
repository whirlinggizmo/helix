# Notes

## Compile errors, in order
1. `LoadModel: Not supported. Use LoadModelAsync` -> used `LoadModelAsync` with callbacks; main loop draws "Loading..." until all four models and the animations arrive (they arrive within 2 frames).
2. `LoadModelAnimations: Not supported` -> `LoadModelAnimationsAsync`, same loading loop.
3. `TakeScreenshot: Not supported` (x3) -> `TakeScreenshotAsync`.

## No raylib call for what the task asks
- Per-bone animation blending / masking: none in raylib. I write a blended pose into `framePoses[0]` of an unused animation (anims[0], same 62-bone skeleton) each frame, then call `UpdateModelAnimation(model, thatAnim, 0)` on each of the four models. Bones under Abdomen (bone 3) are slerp/lerped run->slash by weight; Root, Body, Hips, legs and foot IK bones stay on Run.

## Guesses
- Animation sample rate 60 fps (log says 65 frames = 1.0667 s); slash length = 64/60 s, run loops over 50 frames (51 frames = 0.8333 s, last duplicates first).
- "Waist up" = descendants of Abdomen. Hips stay running.
- Ease: smoothstep over 0.15 s at start and over the last 0.15 s of the slash.
- Fixed timestep 1/60 per frame instead of GetFrameTime, for determinism.
- Camera at (2.6,1.6,4.2) assuming she faces +Z.
- Slash restarts are ignored while one plays. With `--auto`, a slash fires every 2 s (first at 2 s).
- Screenshots (only when `--frames=N` is given): shot_before.png (frame 90), shot_mid.png (150), shot_out.png (178) -- written to the cwd; run with `--auto --frames=200`.

## Expected not to work
- Sword is not drawn (not required). Space is untested interactively (only --auto was run).
