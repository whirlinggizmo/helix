# Notes

## Compile errors (in order)
1. `Main.hx:17: Not enough arguments, expected animCount:Array<Int>` on `LoadModelAnimations(file)`. The C out-parameter `int *animCount` is an `Array<Int>` here, so I passed `[0]`. The returned array's `.length` was used for the count.

## Warnings logged
1. `WARNING: TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()`. I had called it after `EndDrawing()`. I moved it before `EndDrawing()` on the last frame.

## Guesses
- The four body parts are separate models. I assumed they share the skeleton of Animations.glb, so I call `UpdateModelAnimation` on each with the same Idle frame. The result looks right.
- The animation advances one frame per rendered frame (60 fps), wrapping at the clip's frameCount.
- Orbit speed is 0.3 rad/s, the camera is 6 m out horizontally and 3 up, and it looks at (0,1,0).
- The floor is a 20x20 plane in GRAY with a SKYBLUE background.
- The panel is stretched to 360x120 with DrawTexturePro (not 9-patch). The title is at (24, y+40) with spacing 2.
- `music.looping = true` is set as a field on Music, which I assumed is how looping is done.
- With `--frames=N`, the screenshot is taken on frame N before EndDrawing.
