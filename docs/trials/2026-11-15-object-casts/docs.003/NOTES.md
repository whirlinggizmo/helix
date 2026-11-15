# Notes

## Compile errors
None. The first build and every later one compiled cleanly.

## Warnings logged
- `TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()`.
  I had called `TakeScreenshot` after `EndDrawing()`. I moved it to just before `EndDrawing()` on the last frame.
  The saved shot still shows the virtual buttons.

## Guesses
- With `EnableVirtualGamepad` options, the default two floating sticks also appeared in the screenshot.
  The task asked for buttons only, so I set `left` and `right` to `{enabled: false}`.
- Button centers: (740, 60) for "II" and (740, 390) for "OK", which is 60 px in from the window edges.
- "Centered, 30 px below the panel's top" for the title: I centered it by `MeasureText("PAUSED", 40)` and drew it at panel top + 30.
- Swatches: vertically centered on the panel's middle (y 201 to 249).
- `--frames=N` is parsed from `Sys.args()`.
- The "OK" press is read with `IsGamepadButtonPressed(0, ...)`, assuming the virtual gamepad is in slot 0.
  I never pressed the buttons, so neither action was tested.
