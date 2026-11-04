# Notes

## Compile errors, in order
1. `Main.hx:5 Type not found : Model` — added `import helix.raylib.*;` (types live there, as the Debug docs import).
2. `LoadModel: Synchronous loading is not supported ... LoadModelAsync(...) in helix.raylib.extras.Models` — switched to `LoadModelAsync` with callback; added `import helix.raylib.extras.Models.*;`. Model is now `Null<Model>` and drawing is skipped until loaded.
3. `LoadModelAnimations: Not enough arguments, expected animCount` — replaced with `LoadModelAnimationsAsync(file, cb)`, a guess at the name/signature (callback gets Array<ModelAnimation>). It compiled, so the guess was right.

(The first compile after fixing 3 was clean.)

## Unsure / guessed in the debug docs
- Skeleton/posed bounds depend on "last UpdateModelAnimation". With five copies of one Model, I call UpdateModelAnimation per copy right before drawing it (pose, draw, skeleton, bounds). I'm guessing the debug functions read the pose at call time, not cached at draw time.
- Whether DrawModelSkeleton/BoundingBoxPosed need the model loaded/animations finished: I guard on null.
- `fontSize: 28` for 1280x720 is my guess at "comfortable"; no guidance on scale. DrawFPS is 20.
- `targetFps: 30` set explicitly although SetTargetFPS(30) is called (default 0 would follow it); explicit seemed safer.
- Whether the struct literal `{fontSize: .., targetFps: ..}` works with Fade() colors—it compiled.
- Task says "Three characters" but then five copies; I used five.
- Animation frame advance: frame as Float, passed as Std.int; unsure whether UpdateModelAnimation takes a float frame.
- Bounds "posed": whether scale/position apply to the box as DrawModel does; assumed yes per docs.

## API suggestions
- Put the full list of Debug types in one import (Model etc. need `helix.raylib.*`; Debug docs don't say so).
- A DrawModelDebug(model, pos, scale, {skeleton, bounds}) helper, or a note on multi-instance use.
- State in docs whether the pose is read at call time and how to handle many instances sharing one Model.
- Doc a recommended fontSize relative to window height, or a scale-aware overload.
- Mention that async loaders exist in the Debug/Models docs.
