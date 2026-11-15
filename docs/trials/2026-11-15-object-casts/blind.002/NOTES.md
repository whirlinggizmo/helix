# Notes

## Compile errors
None. It compiled on the first build.

## Warnings logged
- `TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()`.
  I had called it after `EndDrawing()`. I moved the call to just before `EndDrawing()` on the last frame, and shot.png saved.

## Guesses
- The first build ran past the tool's 120 s limit and was moved to the background, so I read its output from the output file. That is the only reason the first run isn't shown directly.
- Both sticks are disabled (`enabled: false`) so only the two buttons are drawn. The task didn't say, and the default would add two sticks.
- Title x is the panel center minus half of `MeasureText("PAUSED", 40)`. I took "30 pixels below its top" to mean the text's top edge.
- Swatches: I took "across the panel's middle" to mean vertically centered on the panel, so y = 225 - 24.
- The outline "toggles between its color and white" is a bool flipped on each press of `GAMEPAD_BUTTON_MIDDLE_RIGHT`, read on slot 0.
- Frame counting: the screenshot is taken on frame N (the Nth drawn frame), before `EndDrawing()`, then the loop breaks.
- I didn't test button presses, so the "II" toggle and "OK" close are unverified.
