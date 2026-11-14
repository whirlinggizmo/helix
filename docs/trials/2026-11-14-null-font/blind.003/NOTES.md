# Notes

## Compile errors (in order)
1. `LoadTexture: Not supported. Use LoadTextureAsync` — switched to `LoadTextureAsync` with a callback that stores the texture.
2. `LoadFontEx: Not supported. Use LoadFontExAsync` (64 px) — switched to `LoadFontExAsync`, callback stores the font.
3. Same for the 24 px font.
4. `TakeScreenshot: Not supported. Use TakeScreenshotAsync` — switched; after calling it, the program keeps drawing the scene until the `done` callback fires, then exits.

## Warnings logged
None. The run logged only INFO lines.

## Problems found while running (not logged)
- First `shot.png` was all black: after calling `TakeScreenshotAsync` I looped on empty Begin/EndDrawing, so the capture saw a blank frame. Fixed by redrawing the full scene in that wait loop (scene drawing is now a `draw` function).
- The blink was hidden on frame 120 with `(frame-1)%60<30`, so the prompt was missing from the screenshot. Changed to `frame%60<30`.

## Guesses
- The async loaders' callbacks fire while the main loop runs, so I draw only a blank background until all three assets have arrived, and count frames from then.
- `codepoints` of `null` with count 0 gives the default character set (95 glyphs logged).
- Letter spacing 2 for `MeasureTextEx` and `DrawTextEx`; the task didn't specify it.
- The prompt sits 30 px below the title's bottom edge (y = 214).
- The blink is on for 30 frames, off for 30.
- "Centered" means `(800 - measured width) / 2`, rounded.
- The dark background is `Color(18, 18, 24)`.
