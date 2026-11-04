# Notes

## Compile errors, in order
1. `Main.hx:5: Type not found : Model` → added `import helix.raylib.*;` (types live in helix.raylib, functions in Raylib.*).
2. `LoadModel: Synchronous loading is not supported. See LoadModelAsync(...) in helix.raylib.extras.Models` → added `import helix.raylib.extras.Models.*;` and switched to `LoadModelAsync("assets/robot.glb", m -> model = m)`.
3. `LoadModelAnimations: Not enough arguments, expected animCount` (reported with #2) → I guessed `LoadModelAnimationsAsync(file, a -> anims = a)` returning `Array<ModelAnimation>`. It compiled on the first try, so the guess was right. Draw code is guarded with `model != null && anims.length > 0` since loads finish later.

## Where the debug docs left me unsure / guessing
- Pose per copy: the skeleton and posed bounds are "as the last UpdateModelAnimation posed it", and there is one Model. I assumed that for the five copies I must call UpdateModelAnimation, then draw the model, skeleton and bounds, then pose the next copy, all in the same frame. The docs never say this. If the Debug functions cache the pose lazily, this would be wrong.
- Whether the bounds/skeleton are drawn when the model is hidden (H): I assumed yes, since the task asks for it, and I call them independently of DrawModel.
- Whether the Debug calls need an `UpdateModelAnimation` first for non-animated models: the doc says it draws the bind pose, so fine.
- Font size: the docs give no guidance on a size for 1280x720. I picked 28 (DrawFPS's 20 felt small, and 4 lines at 28 is about 150 px of 720). Judgment only.
- Target: I passed `targetFps: 30` explicitly, in addition to `SetTargetFPS(30)`. The docs say 0 follows SetTargetFPS, so this is redundant but safe. The doc doesn't say what `DrawFrameStats` (the non-Ex one) uses.
- Style literal `{fontSize: 28, ...}` relies on @:structInit anonymous-structure coercion; it compiled.
- Not sure whether Fade(BLACK, 0.5) is the right background for readability; copied from the doc example.

## What I'd change in the API
- Take a pose/animation-frame argument (or an optional ModelAnimation + frame) in DrawModelSkeleton / DrawModelBoundingBoxPosed so they don't depend on hidden "last UpdateModelAnimation" state, which matters for multi-copy drawing.
- Doc the multi-copy case explicitly, with an example.
- Give DrawFrameStats a size suggestion (e.g. a note: ~fontSize = height/30 for a window) and say whether targetFps follows SetTargetFPS in DrawFrameStats too.
- Mention in the Debug docs that Model/Animation loading is async (Models.LoadModelAsync, LoadModelAnimationsAsync) so the names are discoverable.
