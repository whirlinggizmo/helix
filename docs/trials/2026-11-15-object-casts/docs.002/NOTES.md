# Notes

## Compile errors
None. The first build compiled as written.

## Warnings logged
1. `WARNING: TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()`
   - Changed: `TakeScreenshot` is now called before `EndDrawing()` on the last frame, then the loop breaks after `EndDrawing()`.
   - The screenshot is saved and shows both buttons.

## Guesses
- With no `left`/`right` options, the virtual gamepad drew two default sticks. The task asks for only the two buttons, so I set both sticks to `enabled: false`.
- I read "II" as the label of `GAMEPAD_BUTTON_MIDDLE_RIGHT` and "OK" as that of `GAMEPAD_BUTTON_RIGHT_FACE_DOWN`, both at radius 40.
- Button centers: (740, 60) and (740, 390), 60 px in from the edges.
- "Across the panel's middle" read as the swatches' vertical center at the panel's center (y 225).
- Both buttons are read with `IsGamepadButtonPressed(0, ...)`.
- The outline toggle is untested: no touch was injected.
