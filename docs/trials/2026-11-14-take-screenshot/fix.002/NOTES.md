# Notes

## Compile errors
None.

## Warnings logged
1. `TakeScreenshot: shot.png: Screenshot could not be saved: EndDrawing wasn't called after TakeScreenshot. Call TakeScreenshot before the frame's EndDrawing.`
   Moved the `TakeScreenshot("shot.png")` call to just before `EndDrawing()` on the last frame (break after EndDrawing).

## Guesses
None. The async loaders were left as written; they finished well before frame 120 and shot.png shows panel, title and prompt.
