# Notes

## Compile errors, in order
1. `LoadModel`, `LoadModelAnimations`, `TakeScreenshot`: "Not supported. Use ...Async". Switched to `LoadModelAsync`, `LoadModelAnimationsAsync`, `TakeScreenshotAsync` with callbacks.
2. `runDemo(): Not supported in a function used as a value` (I had moved the main loop into a function called from a load callback). Moved the render loop back into `main` and poll a `scratch == null` loading loop until the callbacks have fired.

## API gaps
- raylib 5.5 has no call to blend two animations or to apply a bone mask. I load `Animations.glb` twice. The second copy is scratch: each frame I sample Run and Sword_Slash (interpolating between frames), convert to local space, blend the upper-body bones, rebuild model-space poses, write them into scratch `Run`'s `framePoses[0]`, and call `UpdateModelAnimation(model, scratch, 0)` for each of the four models.
- No way to pass a frame time (only integer frames), so I sample the source poses by hand.

## Guesses
- `framePoses` are model-space (I convert to local using `parent` indices; the result looks right in the screenshots).
- Animation rate 60 fps, looping over frameCount-1 frames (from the raylib log: 51 frames = 0.8333 s).
- "Upper body" = Abdomen, Torso, Chest and their descendants. Hips, legs and feet always run.
- Slash ease: smoothstep over 0.15 s in and 0.15 s out, inside the slash's own duration (1.0667 s).
- Camera at (1.8, 1.4, 3.0) looking at (0, 0.85, 0); assumed she faces +Z.
- With `--frames`, time steps 1/60 s per frame. Screenshots (`shot_before.png`, `shot_mid.png`, `shot_out.png`) are written to the working directory only in that mode.

## Expect not to work
- Not checked: the Space key (only `--auto` was run).
- The slash reads clearly only in motion; the mid-slash still looks like a body turn with arms in front.
- Pressing Space during a slash is ignored.
