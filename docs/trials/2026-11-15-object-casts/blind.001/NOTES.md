# Notes

## Compile errors
None. The first build compiled cleanly.

## Warnings logged
1. `WARNING: TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()`
   I had called `TakeScreenshot` after `EndDrawing()`. I moved it to just before `EndDrawing()`, so the virtual buttons (drawn in EndDrawing) are in the shot. The warning is gone and `shot.png` is saved.

## Guesses
- The first `haxe build.hxml` ran longer than the 120 s tool timeout (the first C++ compile); I just waited for it.
- Panel is placed at (190, 95); title y = 95 + 30 = 125, centered with `MeasureText`.
- Swatch row is vertically centered on the panel (y = 201), starting at x = 248.
- Button positions are (740, 60) and (740, 390), 60 px in from the right, top and bottom edges. Both sticks are disabled so only the buttons show.
- Buttons are read with `IsGamepadButtonPressed(0, ...)`. I did not test pressing them, because there is no input in the run.
- `--frames=N` is parsed from `Sys.args()`.
