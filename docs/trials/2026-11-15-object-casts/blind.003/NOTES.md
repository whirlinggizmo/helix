# Notes

## Compile errors
None. Main.hx compiled on the first build.

## Warnings logged
- `TakeScreenshot: shot.png: Screenshot could not be saved: Screenshots are generated during EndDrawing()`
  when I called TakeScreenshot after EndDrawing. Moved the call to just before EndDrawing on the last frame; it then saved.

## Guesses
- Used `new Color(r,g,b,a)`, `new Vector2`, `new Rectangle` constructors (not documented in what I was allowed to read).
- Disabled both virtual sticks (`enabled: false`): the default floating stick hints showed in the first screenshot and the task only asks for buttons.
- Button centers (740, 60) and (740, 390): 60 px in from the right edge, the top edge and the bottom edge.
- Swatch row vertically centered on the panel's middle.
- Title x centered with MeasureText.
- Screenshot is taken before EndDrawing on the last frame; the virtual gamepad is still in it.
