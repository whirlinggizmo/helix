# Notes

## Compile errors
None. The original Main.hx built cleanly.

## Warnings logged
1. `WARNING: TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()`
   Changed: call `TakeScreenshot("shot.png")` on the last frame before `EndDrawing()` (it was after), then break after `EndDrawing()`.
   Result: "Screenshot taken successfully".

## Guesses
None. (Checked shot.png: panel, title and prompt all appear; the prompt happened to be visible on frame 120.)
