# Notes

## Compile errors, in order
1. `LoadModel: Not supported. Use LoadModelAsync(...)` -> loaded the four models with `LoadModelAsync`, and spin a "Loading..." draw loop until the callbacks fire.
2. `LoadModelAnimations: Not supported` -> `LoadModelAnimationsAsync`, same wait.
3. `TakeScreenshot: Not supported` -> `TakeScreenshotAsync`.

## No call in raylib / extras
- Masked blending: used extras `UpdateModelAnimationMasked`. Merging four parts: `LoadModelFromModels(parts, body)`.

## Guesses
- Upper-body mask root: bone `"Abdomen"` (names read from the glb; Hips -> Abdomen -> Torso/Chest, legs under Hips). Not verified against the hierarchy beyond names.
- Animation rate 60 fps (first guessed 30; raylib's log showed Run 51 frames = 0.833 s).
- Ease: smoothstep over 0.15 s in/out, blend weight on the whole mask; slash frame = elapsed*60.
- Run looped by fractional frame, `(t*60) % frameCount`.
- With `--frames=N` the step is fixed at 1/60 s; screenshots at frames 60 (before), 152 (mid), 180 (easing out), assuming `--auto`.
- Readout percentage is slash time / duration.

## Expect not to work
- Screenshot frames are tuned for `--auto`; without it only frame 60 is meaningful.
- Facing/camera direction judged by eye from screenshots.
