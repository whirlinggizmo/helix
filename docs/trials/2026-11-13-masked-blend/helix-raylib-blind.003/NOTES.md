# Notes

## Compile errors (in order)
1. `LoadModel`, `LoadModelAnimations`, `TakeScreenshot`: "Not supported", use the `*Async` variants. Changed to `LoadModelAsync`, `LoadModelAnimationsAsync` (waiting in a draw loop until all callbacks fired) and `TakeScreenshotAsync`.

## API had no call for what the task asks
- raylib 5.5 has no animation blending or masked (upper/lower body) playback. I sample the Run and Sword_Slash `framePoses` myself (lerp/slerp between frames), blend per bone (bones under `Abdomen` get the slash weight, the rest stay on Run), write the result into `run.framePoses[0]` and call `UpdateModelAnimation(model, run, 0)` on each of the four models.

## Guesses
- Animation durations (Run 0.8333s, Sword_Slash 1.0667s) were read from the glb's JSON; frames are assumed evenly spread over `frameCount-1` intervals across that duration.
- Upper body = `Abdomen` and its descendants; `Hips`, `Body`, legs and feet stay on Run.
- Ease is smoothstep over 0.15s at start and end of the slash (weight reaches 0 as the clip ends). Overlapping auto trigger is ignored while a slash plays.
- Extra args: `--shots=a,b,c` saves `shot_N.png` at those frame numbers. With `--frames`, time steps a fixed 1/60s.

## Expect not to work
- Mutating `framePoses` through the Haxe wrapper worked in screenshots, but I did not verify it is free of copying costs. The slash ends in a slightly different pose than Run's upper body only via the ease; the sword is not drawn.
