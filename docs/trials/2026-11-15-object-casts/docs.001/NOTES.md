# Notes

## Compile errors
None. The build passed first time (and again after each edit).

## Warnings logged
- First run: `WARNING: TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()`.
  I had called TakeScreenshot after EndDrawing. Moved it before EndDrawing on the last frame, then break after EndDrawing. No warnings after.

## Guesses
- With no stick options the virtual gamepad draws two default sticks, which the task doesn't list. I disabled both (`left`/`right` `enabled: false`).
- Whether the screenshot, called before EndDrawing, includes the buttons (drawn at EndDrawing): it does, per shot.png.
- Swatch row vertically centered on the panel's middle (y 225), so top at 201.
- Used `new Color(r,g,b)` for colors, and object literals for Rectangle and button options.
- Button positions: (740, 60) and (740, 390), i.e. 60 px in from the right/top/bottom edges.
- Slot 0 for the virtual gamepad; buttons are read with IsGamepadButtonPressed(0, ...).
