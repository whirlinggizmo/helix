# Notes

## Compile errors
None. The original Main.hx built cleanly.

## Warnings logged
1. `TakeScreenshot: shot.png: Screenshot could not be saved: EndDrawing wasn't called after TakeScreenshot. Call TakeScreenshot before the frame's EndDrawing.`
   Changed: on the last frame, `TakeScreenshot("shot.png")` is now called before `EndDrawing()` instead of after. The loop breaks after `EndDrawing()`.

## Guesses
- None significant. The warning text said what to do. I did not change the async loaders, which finished well before frame 120.
