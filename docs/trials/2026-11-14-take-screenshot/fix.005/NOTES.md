# Notes

## Compile errors
None. The original Main.hx built without errors.

## Warnings logged
- `TakeScreenshot: shot.png: Screenshots are generated during EndDrawing()`: no shot.png was saved. I moved the `TakeScreenshot` call to just before `EndDrawing()` on the last frame. The rerun logged no warnings.

## Guesses
- None significant. The prompt blinks as 30 frames on, 30 off (1 s cycle). The final frame (120) falls in the "on" half, so the prompt shows in shot.png.
