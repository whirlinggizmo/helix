# Notes

## Compile errors
None. The first build compiled cleanly.

## Warnings logged
1. `TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()`.
   Changed: call `TakeScreenshot` just before `EndDrawing()` on the last frame, not after it.

## Guesses
- Passed `[0]` (an Array<Int>) as the `int *animCount` out-param of `LoadModelAnimations`; it worked.
- Each of the four body-part models is posed with the same animation (shared skeleton assumed); it looked correct.
- Picked the animation whose name is exactly `CharacterArmature|Idle` and advance one frame per tick.
- Used a 20x20 `DrawPlane` as the gray floor, orbit speed 0.2 rad/s, camera target (0,1,0).
- Loading happens in the main loop once `EnsureAssetsAsync` calls back, with a "Loading..." text meanwhile.
- Panel title placed at (20, 758-120) i.e. 20px right, 38px down within the panel; font spacing 2.
- Sound/music could not be verified (no audio in the test display).
