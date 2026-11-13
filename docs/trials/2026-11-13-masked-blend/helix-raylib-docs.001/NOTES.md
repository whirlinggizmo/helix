# Notes

## Compile errors, in order
1. `LoadModel`, `LoadModelAnimations`: "Not supported. Use LoadModelAsync / LoadModelAnimationsAsync". Switched to the async calls with callbacks; the main loop draws "Loading..." until the four models and animations have arrived.
2. `TakeScreenshot` (x3): "Not supported. Use TakeScreenshotAsync". Switched to it.

## No call in raylib / extras for what the task asks
- Nothing missing: `UpdateModelAnimationMasked` + `GetModelBoneMask` cover the legs-run / upper-body-slash split, `LoadModelFromModels` merges the four parts.

## Guesses
- Mask root bone `"Abdomen"` (a child of `Hips`, as are the legs), so hips + legs keep running. Bone names read from the glb's strings, not from a doc.
- Animation rate 24 fps (the log shows 65 frames = 1.0667 s for Sword_Slash). Run frame advances at 24 fps and wraps over its 51 frames, continuous during slashes.
- Ease: smoothstep of min(t/0.15, (dur-t)/0.15) as the `blend`.
- Fixed dt of 1/60 per frame instead of GetFrameTime, so runs are deterministic.
- `LoadModelFromModels(parts, parts[0])`: skeleton from whichever part loaded first (all share one skeleton).
- Camera at (1.5, 1.4, 4) looking at (0,1,0); assumes she faces +Z.
- `--shots` flag (mine): starts a slash at frame 30 and saves shot_before/mid/out.png. Screenshots are async, so `--frames` must run a few frames past the last shot (200 is fine; 140 lost the last one).

## Expect not to work
- Readout shows "playing N%" while slashing, "idle" otherwise. Frame count with `--frames=N` counts only frames after loading finishes.
- No sword is drawn; the slash on screen is a subtle arm swing from this camera angle.
