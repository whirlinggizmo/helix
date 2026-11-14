# Notes

## Compile errors
None. It built on the first try, and again after adding the second font.

## Warnings logged
None. Only INFO lines were logged.

## Guesses
- The docs list only async loaders (`LoadFontExAsync`, `LoadTextureAsync`), so I used them. Drawing waits until they have answered.
- I loaded the font twice, at 64 and at 24 pixels, so the prompt is drawn at its native size.
- The blink is `Std.int(GetTime()) % 2 == 0`, so the prompt is on for one second and off for one second.
- The prompt sits 30 px below the title's bottom edge (y = 120 + 64 + 30). The task didn't give the gap.
- Text spacing is 0.
- The panel is drawn at (190, 95), which centers a 420 x 260 box in 800 x 450.
- `--frames=N` is parsed from `Sys.args()`. `TakeScreenshot` is called on frame N before `EndDrawing`.
