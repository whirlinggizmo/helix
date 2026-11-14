# Notes

## Compile errors
None; the original built cleanly.

## Warnings logged
- `WARNING: TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()`
  Moved the `TakeScreenshot("shot.png")` call on the last frame to before `EndDrawing()`. The warning is gone and shot.png is written.

## Guesses
- Assumed the screenshot call has to come before `EndDrawing()` in this build (taken from the warning text).
- Left the async loaders as they were; they finished before frame 120 in the run.
